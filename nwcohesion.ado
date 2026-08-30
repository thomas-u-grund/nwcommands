
capture program drop nwcohesion
program nwcohesion, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent]
	set more off

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_cohesion"
		}

		capture confirm variable `netgenerate'`i', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`i'} already exists; specify {bf:replace}"
			err 99
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_hier __nw_cohnum
		mata: `__nw_hier' = `netobj'->calculate_cohesion_hierarchy()
		mata: st_numscalar("nw_nblocks", rows(`__nw_hier'))
		mata: st_matrix("nw_cohesionmatrix", `__nw_hier'[.,2..cols(`__nw_hier')])
		mata: st_matrix("nw_cohesionlevels", `__nw_hier'[.,1])
		mata: `__nw_cohnum' = colmax(`__nw_hier'[.,2..cols(`__nw_hier')] :* `__nw_hier'[.,1])'

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_cohnum')
		mata: mata drop `__nw_hier' `__nw_cohnum'

		return scalar blocks = nw_nblocks
		return matrix cohesion_matrix = nw_cohesionmatrix
		return matrix cohesion_levels = nw_cohesionlevels
		local lblocks = nw_nblocks

		// see nwbrokerage.ado's own header comment: the "already exists"
		// probe above leaves _rc stale even after a fully successful
		// run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Cohesive blocks found: {res}`lblocks'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
