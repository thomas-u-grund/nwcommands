
capture program drop nwbetween
program nwbetween
	syntax [anything(name=netname)], [replace GENerate(string) nosym standardize silent weighted alpha(real 1)]

	// This command's own doc has always described netlist (multi-network)
	// behavior ("In case, betweenness centrality is calculated for z
	// networks at the same time... the command generates the variables
	// varname_z, one for each network"), but the code never actually
	// implemented it: nw_syntax was called with no max() override (so
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
	nw_syntax `netname', max(9999)
	local totalnetworks = `networks'

	if "`generate'" == "" {
		local generate "_between"
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'
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
			di "{err}Variable {bf:`netgenerate'} already exists; use {bf:replace} or {bf:generate()}"
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
			nw_syntax
		}

		if "`weighted'" != "" {
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

		if "`standardize'" != "" {
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
		if "`standardize'" != "" {
			noi di "{txt}    (standardized)"
		}
		if "`silent'" == "" {
			noi sum `netgenerate'
		}
		mata: st_numscalar("r(bw_central)", sum(J(`nodes',1,max(st_data((1::`nodes'), "`netgenerate'"))) :- st_data((1::`nodes'), "`netgenerate'")) / ((`nodes' - 2) * (`nodes' - 1) * (`nodes' - 1)))
	}
end

