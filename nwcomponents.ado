
capture program drop nwcomponents
program nwcomponents, rclass
	version 9
	syntax [anything(name=netname)][, lgc GENerate(string) replace silent]
	set more off

	_nwsyntax `netname', max(9999)
	
	if `networks' > 1 {
		local k = 1
	}
	
	qui foreach netname_temp in `netname' {
		nwname `netname_temp'
		local nodes = r(nodes)

		if "`generate'" == "" {
			if "`lgc'" == "" {
				local generate = "_component"
			}
			else {
				local generate = "_lgc"
			}
		}
		
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
		_nwsyntax `netname_temp'
		mata: st_store((1::`nodes'),"`generate'`k'", `netobj'->calculate_components())

		qui tab `generate'`k', matrow(comp_id) matcell(comp_size)
		
		mata: comp_id = st_matrix("comp_id")
		mata: comp_number = rows(comp_id)
		mata: comp_size = st_matrix("comp_size")
		mata: comp_share = comp_size :/ (sum(comp_size))
		mata: comp_sizeid = J(comp_number, 3, 0)
		mata: comp_sizeid[.,1] = comp_size
		mata: comp_sizeid[.,2] = comp_id
		mata: comp_sizeid[.,3] = comp_share
		mata: comp_sizeid = sort(comp_sizeid, -1)
		mata: st_numscalar("components", comp_number)
		mata: st_matrix("comp_sizeid", comp_sizeid)
			
		matrix colnames comp_sizeid = size compid share
	
		local rowlabs ""
			
		return scalar components = components
		local lcomp = components
		
		forvalues i = 1/`=components'{
			local rowlabs "`rowlabs' comp`i'"
		}
		matrix rownames comp_sizeid = `rowlabs'
		return matrix comp_sizeid = comp_sizeid
		mata: mata drop comp_number comp_share comp_id comp_size comp_sizeid

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
			tab `generate'`k', matcell(freqs) matrow(comps)
			local freqs_max = 1
			local freqs_all = rowsof(freqs)
			forvalues i = 1/`freqs_all' {
				if freqs[`freqs_max',1] < freqs[`i',1] {
					local freqs_max = `i'
				}
			}
			local comps_lgc = comps[`freqs_max',1]
			replace `generate'`k' = 0 if `generate'`k' != `comps_lgc' & `generate'`k' != .
			replace `generate'`k' = 1 if `generate'`k' == `comps_lgc' & `generate'`k' != .	
		}
		if "`silent'" == "" {
			noi tab `generate'`k'
			noi di " "
			noi di " "
		}
		local k = `=`k' + 1'
		
	}
end
