capture program drop nwinduced
program nwinduced, rclass
	version 12
	syntax [anything(name=netname)], MEASURE(string) [GENerate(string) replace silent]

	_opts_oneof "degree betweenness closeness evcent" "measure" "`measure'" 6556

	_nwsyntax `netname', max(1)

	// Directed networks are supported for betweenness/closeness/evcent
	// (each already produces exactly one clean per-node output
	// variable under generate() regardless of directedness - confirmed
	// directly, not assumed). Only measure(degree) is restricted:
	// nwdegree itself splits into two separate variables
	// (_outdegree/_indegree) on a directed network, so "induced degree"
	// would force a choice between separate in-/out-degree induced
	// scores with no single obviously-right answer without a real
	// design decision - disclosed clearly rather than silently guessed
	// at (docs/INDUCED_CENTRALITY_ROADMAP.md's own scope-question 2).
	if "`directed'" == "true" & "`measure'" == "degree" {
		di as err "nwinduced, measure(degree) does not support directed networks - nwdegree itself splits into separate outdegree/indegree variables when directed, and induced degree would need a choice between them with no single obviously-right answer. measure(betweenness/closeness/evcent) all support directed networks directly - see docs/INDUCED_CENTRALITY_ROADMAP.md."
		error 198
	}

	if "`generate'" == "" {
		local generate "_induced"
	}
	local endogvar "`generate'_endog"
	local inducedvar "`generate'_induced"
	local exogvar "`generate'_exog"

	foreach v in `endogvar' `inducedvar' `exogvar' {
		capture confirm variable `v', exact
		if _rc == 0 & "`replace'" == "" {
			di as err "{err}Variable {bf:`v'} already exists; specify {bf:replace}"
			err 99
		}
	}

	// Map measure() to the real command + the single output variable
	// name that command uses under an explicit generate() - all four
	// candidates confirmed to produce exactly ONE variable under
	// generate() on an undirected network (nwdegree splits into two,
	// out/in, only when directed - excluded above; nwcloseness's own
	// generate() takes 3 names, closeness/farness/nearness together -
	// only the first, closeness itself, is used here).
	if "`measure'" == "degree" {
		local measurecmd "nwdegree"
		local measureopt "generate(__nwind_c)"
	}
	if "`measure'" == "betweenness" {
		local measurecmd "nwbetween"
		local measureopt "generate(__nwind_c)"
	}
	if "`measure'" == "closeness" {
		local measurecmd "nwcloseness"
		local measureopt "generate(__nwind_c __nwind_f __nwind_n)"
	}
	if "`measure'" == "evcent" {
		local measurecmd "nwevcent"
		local measureopt "generate(__nwind_c)"
	}

	local origname `netname'
	local n `nodes'

	// --- endogenous(v) = C(v) itself, on the full network as-is.
	preserve
	nwload `origname', xvars
	capture drop __nwind_c __nwind_f __nwind_n
	// `silent' is deliberately NOT passed here - not every candidate
	// command supports it (nwcloseness/nwevcent do not, confirmed
	// directly: nwcloseness raises "option silent not allowed" if
	// given one). `qui' already suppresses all display output
	// regardless, so this is not needed for suppression, only for
	// commands that happen to support it - simpler and more robust to
	// rely on `qui' alone uniformly across all four candidates.
	qui `measurecmd' `origname', `measureopt'
	tempname endogvals
	mata: `endogvals' = st_data((1::`n'), "__nwind_c")
	// BUGFIX (caught before this ever shipped): a bare Mata identifier
	// does NOT automatically see a same-named Stata scalar - Mata has
	// its own separate namespace, and `st_numscalar("name", value)'
	// only WRITES a Stata scalar, it doesn't also make that name
	// visible as a Mata variable. Using `st_local()' instead - which
	// writes an actual STATA LOCAL MACRO - lets `` `fullsum' '' expand
	// to a literal number via ordinary Stata macro substitution before
	// Mata ever parses the line, avoiding the cross-namespace
	// confusion entirely (confirmed the bare-scalar-name version fails
	// with "not found" the first time this file was run).
	mata: st_local("fullsum", strofreal(sum(`endogvals')))
	restore

	// --- induced(v) = fullsum(C) - sum(C on the network with v removed),
	// looped over every node. Each iteration builds a fresh, temporary
	// subgraph network (copy_subgraph_into(), the same primitive
	// nwneighbor's own subnet() option already uses), runs the chosen
	// measure command on it, sums the result over the remaining n-1
	// nodes, then drops the temporary network before the next
	// iteration - `preserve'/`restore' around each iteration keeps the
	// Stata dataset itself from accumulating state across iterations;
	// the temporary network registration is cleaned up explicitly
	// (preserve/restore does not touch the separate Mata network
	// registry at all).
	tempname inducedvals
	mata: `inducedvals' = J(`n', 1, .)
	forvalues v = 1/`n' {
		preserve
		// BUGFIX (caught before this ever ran, not after): `netobj' is
		// just this program's own local macro, set by the LAST
		// `_nwsyntax' call - by the end of the PREVIOUS loop iteration
		// it still points at that iteration's own (already-dropped)
		// `__nwind_sub' network, not back at the real source network.
		// `preserve'/`restore' only save/restore the Stata DATASET, not
		// this ado program's own local macros or Mata's separate
		// network registry, so `netobj' does not revert on its own -
		// must re-resolve the real source network explicitly at the
		// TOP of every iteration, before capturing it as `__nwind_src'.
		_nwsyntax `origname', max(1)
		tempname __nwind_src __nwind_sel
		mata: `__nwind_src' = `netobj'
		mata: `__nwind_sel' = J(1, `n', 1)
		mata: `__nwind_sel'[`v'] = 0
		mata: nw.nws.add("__nwind_sub")
		_nwsyntax __nwind_sub
		mata: `__nwind_src'->copy_subgraph_into(`netobj', `__nwind_sel')
		mata: `netobj'->set_name("__nwind_sub")
		mata: mata drop `__nwind_sel' `__nwind_src'
		nwload __nwind_sub, xvars
		capture drop __nwind_c __nwind_f __nwind_n
		capture qui `measurecmd' __nwind_sub, `measureopt'
		if _rc == 0 {
			mata: st_local("subsum", strofreal(sum(st_data((1::(`n'-1)), "__nwind_c"))))
		}
		else {
			// A leave-one-out subgraph with fewer than 2 nodes (n<=2
			// originally), or one the chosen measure itself cannot run
			// on (e.g. betweenness needs at least 2 nodes to have any
			// path at all) - reported as missing for this node, not a
			// hard failure for the whole command, matching this
			// package's own "insufficient structure -> missing, not an
			// error" convention (e.g. nwclustering's degree-undefined
			// case).
			local subsum = .
		}
		nwdrop __nwind_sub
		mata: `inducedvals'[`v'] = `fullsum' - `subsum'
		restore
	}

	// --- exogenous(v) = induced(v) - endogenous(v).
	nwload `origname', xvars
	capture drop `endogvar' `inducedvar' `exogvar'
	qui gen `endogvar' = .
	qui gen `inducedvar' = .
	qui gen `exogvar' = .
	mata: st_store((1::`n'), "`endogvar'", `endogvals')
	mata: st_store((1::`n'), "`inducedvar'", `inducedvals')
	mata: st_store((1::`n'), "`exogvar'", `inducedvals' :- `endogvals')
	mata: mata drop `endogvals' `inducedvals'
	capture drop __nwind_c __nwind_f __nwind_n

	return local measure "`measure'"
	return local name "`origname'"
	return local endogenous "`endogvar'"
	return local induced "`inducedvar'"
	return local exogenous "`exogvar'"

	// _rc left stale from the "capture drop"/"capture confirm" calls
	// above - reset explicitly (see nwbrokerage.ado's own header
	// comment for the general pattern this follows).
	capture confirm number 1

	if "`silent'" == "" {
		di ""
		di "{hline 40}"
		di "{txt}  Network name: {res}`origname'"
		di "{txt}  Measure: {res}`measure'"
		di "{hline 40}"
		di "{txt}    Endogenous: {res}`endogvar'"
		di "{txt}    Induced:    {res}`inducedvar'"
		di "{txt}    Exogenous:  {res}`exogvar'"
		noi sum `endogvar' `inducedvar' `exogvar'
	}
end
