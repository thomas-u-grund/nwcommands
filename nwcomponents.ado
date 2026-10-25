
capture program drop nwcomponents
program nwcomponents, rclass
	version 9
	syntax [anything(name=netname)][, lgc GENerate(string) replace silent]
	set more off

	_nwsyntax `netname', max(9999)

	// generate() is required (suite-wide generate()-required style
	// decision, 2026-09-05): nwcomponents' whole purpose is producing
	// this variable, so - matching Stata's own egen/predict convention -
	// there is no default name to silently fall back to. Checked once
	// here rather than inside the netlist loop below, since that loop
	// reassigns `generate' in place on its first iteration - checking
	// inside it would only ever catch an omitted generate() on network 1.
	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}

	if `networks' > 1 {
		local k = 1
	}
	
	qui foreach netname_temp in `netname' {
		nwname `netname_temp'
		local nodes = r(nodes)

		// Checks the exact suffixed name this iteration is about to
		// create, not the bare stem - Stata's own variable-name
		// abbreviation would otherwise let `confirm variable
		// _component' match an already-existing `_component1' on a
		// later netlist iteration, falsely blocking that iteration
		// even though its own target name is still free. Found while
		// building nwconcor.ado's netlist support (same underlying
		// bug in the same copy-pasted pattern - see its own certified
		// row).
		capture confirm variable `generate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`generate'`k'} already exists; specify {bf:replace}"
			err 99
		}
		
		capture drop `generate'`k'
		gen `generate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'
		mata: st_store((1::`nodes'),"`generate'`k'", `netobj'->calculate_components())

		// Stata's tabulate stops at 1,000 distinct values (r(134)) and a matrix row-name list of thousands of
		// tokens blows the command-line limit, so a network with more components than that (any sparse network of
		// a few thousand nodes) made this command fail after the components had been found: the sizes are now
		// counted in Mata and the row names set through the matrix API.
		mata: __nwcc_vals = st_data((1::`nodes'), "`generate'`k'")
		mata: __nwcc_sorted = sort(__nwcc_vals, 1)
		mata: __nwcc_info = panelsetup(__nwcc_sorted, 1)
		mata: comp_number = rows(__nwcc_info)
		mata: comp_id = __nwcc_sorted[__nwcc_info[.,1]]
		mata: comp_size = __nwcc_info[.,2] :- __nwcc_info[.,1] :+ 1
		mata: comp_share = comp_size :/ (sum(comp_size))
		mata: comp_sizeid = J(comp_number, 3, 0)
		mata: comp_sizeid[.,1] = comp_size
		mata: comp_sizeid[.,2] = comp_id
		mata: comp_sizeid[.,3] = comp_share
		mata: comp_sizeid = sort(comp_sizeid, (-1, 2))
		mata: st_numscalar("components", comp_number)
		mata: st_matrix("comp_sizeid", comp_sizeid)
		// the (first) largest component, for the lgc option
		mata: st_numscalar("__nwcc_lgc", comp_id[selectindex(comp_size :== max(comp_size))[1]])

		matrix colnames comp_sizeid = size compid share

		return scalar components = components
		local lcomp = components

		mata: __nwcc_stripe = J(comp_number, 2, "")
		mata: __nwcc_stripe[., 2] = "comp" :+ strofreal((1::comp_number))
		mata: st_matrixrowstripe("comp_sizeid", __nwcc_stripe)
		return matrix comp_sizeid = comp_sizeid
		mata: mata drop comp_number comp_share comp_id comp_size comp_sizeid __nwcc_vals __nwcc_sorted __nwcc_info __nwcc_stripe

		// Consistency (moderate-severity pass, cohesion_subgroups group):
		// every sibling command in this group (nwclique/nwkcomponents/
		// nwkcore/nwkplex/nwnclan/nwnclique/nwcohesion) already offers
		// `silent' to suppress this same per-network display; nwcomponents
		// was the only one that didn't.
		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Components: {res}`lcomp'"
		}

		qui if "`lgc'" != "" {
			local comps_lgc = scalar(__nwcc_lgc)
			replace `generate'`k' = 0 if `generate'`k' != `comps_lgc' & `generate'`k' != .
			replace `generate'`k' = 1 if `generate'`k' == `comps_lgc' & `generate'`k' != .	
		}
		if "`silent'" == "" {
			if `lcomp' <= 1000 {
				noi tab `generate'`k'
			}
			else {
				noi di "{txt}  (the table of the `lcomp' components is not shown; sizes are in r(comp_sizeid))"
			}
			noi di " "
			noi di " "
		}
		local k = `=`k' + 1'
		
	}
end
