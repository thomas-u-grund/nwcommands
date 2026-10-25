
capture program drop nwbetween
program nwbetween
	syntax [anything(name=netname)], [replace GENerate(string) nosym standardize silent weighted BINary alpha(real 1) force TWOmode]

	// This command's own doc has always described netlist (multi-network)
	// behavior ("In case, betweenness centrality is calculated for z
	// networks at the same time... the command generates the variables
	// varname_z, one for each network"), but the code never actually
	// implemented it: _nwsyntax was called with no max() override (so
	// it defaulted to exactly one network), and "local k = 1" /
	// "local generate_all """ were vestigial scaffolding from an
	// abandoned attempt, referenced nowhere else in the body. Finished
	// rather than just documented as unsupported, matching the same
	// fix already made to nwdegree (NWCOMMANDS_COMMAND_STYLE.md's own
	// canonical netlist example). Single-network calls are unaffected:
	// default output variable names have no suffix, exactly as before.
	//
	// Separately, the pre-existing "already exists" guard was dead
	// code: "capture drop `generate'*" unconditionally deleted any
	// matching variable *before* the confirm check ran, so the check
	// could never fire, and there was no actual "replace" option in
	// syntax despite the error text telling users to pass one - the
	// command always silently overwrote existing variables regardless.
	// Fixed by adding a real replace option and making the guard gate
	// the drop, matching the working convention used elsewhere in this
	// package (e.g. nwdegree, nwkatz).
	_nwsyntax `netname', max(9999)
	local totalnetworks = `networks'
	if "`binary'" != "" & "`weighted'" != "" {
		di "{err}Options {bf:binary} and {bf:weighted} cannot be combined."
		error 198
	}

	// generate() is required (suite-wide generate()-required style
	// decision, 2026-09-05): nwbetween's whole purpose is producing this
	// variable, so - matching Stata's own egen/predict convention -
	// there is no default name to silently fall back to; a hidden
	// default is exactly how an existing variable gets unexpectedly
	// clobbered.
	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		// tie values: shortest paths with step cost 1/value^alpha on a valued network (weighted is redundant there);
		// binary ignores the values
		local __wtd = ("`weighted'" != "" | ("`valued'" == "true" & "`binary'" == ""))
		_nwtimeguard, command(nwbetween) nodes(`nodes') model(bfs) netobj(`netobj') rate(2.2e8) alternative(Betweenness needs one shortest-path search from every node. Compute it for a part of the network (nwsubset), or use nwdegree, nwpagerank or nwevcent, which scale to millions of ties.) `force'
		local oldnetname `netname_temp'

		local netgenerate "`generate'"
		if `totalnetworks' > 1 {
			local netgenerate "`netgenerate'_`netname_temp'"
		}

		// BUGFIX: nwbetween never synced the active dataset to the
		// target network before st_store()-ing into it below, unlike
		// every sibling command in this group (nwcloseness/nwdegree/
		// nwevcent all call `_nwsetobs'/`_nwdatasync' first) - a fresh
		// or differently-sized dataset (e.g. right after `clear', or
		// after working with a different network) crashed with a raw
		// "argument out of range" (r3300) the instant st_store() tried
		// to write into row `nodes' of a dataset with fewer rows than
		// that. Confirmed directly via an adversarial-input probe: a
		// bare `clear' followed immediately by `nwbetween' on any
		// network reproduced this every time.
		_nwsetobs `netname_temp'
		tempvar included
		_nwdatasync `netname_temp', generate(`included')

		capture confirm variable `netgenerate', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'} already exists; use {bf:replace} or {bf:generate()}"
			err 99
		}
		capture drop `netgenerate'
		generate `netgenerate' = .

		// Per Stata's own [P] syntax convention for a "no"-prefixed
		// toggle: declaring `nosym' in the option list makes Stata
		// define a local named after the STEM - `sym', not `nosym' -
		// set to the literal string "nosym" when the caller passes
		// the option, empty otherwise. `nosym' itself is never
		// populated at all, so checking it here always evaluated
		// true regardless of whether the option was passed, making
		// `nosym' a silent no-op ever since it was added - confirmed
		// directly against a minimal, isolated test program (see
		// nwevcent.ado, which had the identical bug). Fixed to check
		// `sym' instead.
		if "`sym'" == "" {
			nwsym `netname_temp', generate(`netname_temp'_symmetrized)
			_nwsyntax
		}

		if `__wtd' {
			// weighted (Dijkstra-based) betweenness has no native
			// backend yet - a documented follow-on, see
			// docs/NATIVE_GRAPH_LIBRARIES.md.
			mata: st_store((1::`nodes'),"`netgenerate'", `netobj'->calculate_betweenness_weighted(`alpha'))
		}
		else {
			// NativeGraphAvailable() (unw_core.do) transparently falls
			// back to the Mata implementation on any platform without a
			// compiled nwgraph.plugin/nwgraph_unix.plugin (currently:
			// everywhere except macOS) - see docs/NATIVE_GRAPH_LIBRARIES.md
			// and native/nwgraph.c's own header for the full account.
			mata: st_store((1::`nodes'),"`netgenerate'", NativeGraphAvailable() ? `netobj'->calculate_betweenness_native() : `netobj'->calculate_betweenness())
		}

		if "`twomode'" != "" {
			// Borgatti and Everett (1997): the largest possible betweenness of a node of a mode with n nodes, the other
			// mode having m nodes (a node that lies on every path between the other nodes of its mode): with
			// s = floor((n - 1) / m) and t = n - 1 - s m, (m^2 (s+1)^2 + m (s+1) (2t - s - 1) - t (2s - t + 3)) / 2
			if "`is2mode'" != "true" {
				noi di "{err}Option {bf:twomode} needs a two-mode network; `netname_temp' is one-mode."
				error 198
			}
			mata: __md = strtoreal(`netobj'->get_modes())'; __n1 = sum(__md :== 1); __n2 = sum(__md :== 2); st_store((1::`nodes'), "`netgenerate'", st_data((1::`nodes'), "`netgenerate'") :/ ((__md :== 1) :* nw_be_maxbetween(__n1, __n2) :+ (__md :== 2) :* nw_be_maxbetween(__n2, __n1)))
			mata: mata drop __md __n1 __n2
		}
		else if "`standardize'" != "" {
			if "`directed'" == "true" {
				qui replace `netgenerate'  = `netgenerate'  / ((`nodes' - 1) * (`nodes' - 2))
			}
			else {
				qui replace `netgenerate'   = `netgenerate' / ((`nodes' - 1) * (`nodes' - 2) / 2)
			}
		}

		if "`sym'" == "" {
			nwdrop `oldnetname'_symmetrized
			nwcurrent `oldnetname'
		}

		mata: st_rclear()

		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname_temp'"
		noi di "{hline 40}"
		noi di "{txt}    Betweenness centrality"
		if `__wtd' {
			noi di "{txt}    (shortest paths weighted by tie values: step cost 1/value^alpha, alpha = `alpha')"
		}
		if "`twomode'" != "" {
			noi di "{txt}    (standardized by the largest possible value in a two-mode network, Borgatti and Everett 1997)"
		}
		else if "`standardize'" != "" {
			noi di "{txt}    (standardized)"
		}
		if "`silent'" == "" {
			noi sum `netgenerate'
		}
		// Freeman's betweenness centralisation: sum(max - b_i) divided by
		// its maximum, (n-1)^2 (n-2) for raw directed scores (ordered
		// pairs) and (n-1)^2 (n-2) / 2 for raw undirected scores
		// (unordered pairs). `directed' describes the network that was
		// actually analysed (the symmetrised copy unless nosym).
		// The centralisation is taken from the raw scores, so undo
		// standardize if it was requested.
		local bwdiv = 1
		if "`directed'" != "true" local bwdiv = 2
		local bwscale = 1
		if "`standardize'" != "" {
			if "`directed'" == "true" local bwscale = (`nodes' - 1) * (`nodes' - 2)
			else local bwscale = (`nodes' - 1) * (`nodes' - 2) / 2
		}
		mata: st_numscalar("r(bw_central)", sum(J(`nodes',1,max(st_data((1::`nodes'), "`netgenerate'"))) :- st_data((1::`nodes'), "`netgenerate'")) * `bwscale' / ((`nodes' - 2) * (`nodes' - 1) * (`nodes' - 1) / `bwdiv'))
	}
end

