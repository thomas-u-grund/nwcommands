
capture program drop nwcohesion
program nwcohesion, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent force]
	set more off

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		_nwtimeguard, command(nwcohesion) nodes(`nodes') model(power) base(27) exponent(2.1) alternative(The cohesion hierarchy needs a vertex-connectivity search at every level. Use nwcomponents or nwkcore for a network of this size, or look at a part of the network (nwsubset).) `force'

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		capture confirm variable `netgenerate'`i', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`i'} already exists; specify {bf:replace}"
			err 99
		}

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
