
capture program drop nwkcomponents
program nwkcomponents, rclass
	version 12
	syntax [anything(name=netname)][, k(int 2) GENerate(string) replace NOMatrix silent force]
	set more off

	if `k' < 1 {
		di "{err}k() must be at least 1; k(1) is exactly a connected component - use {help nwcomponents} for that case."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	local __vnquiet = cond(c(noisily) == 0 | "`silent'" != "", "quiet", "")
	local __vndone 0
	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		if `__vndone' == 0 {
			_nwvaluednote `netname_temp', `__vnquiet'
			if r(shown) == 1 {
				noi di `"`r(msg)'"'
				local __vndone 1
			}
		}
		_nwtimeguard, command(nwkcomponents) nodes(`nodes') model(power) base(39) exponent(2.6) alternative(k-components need a vertex-connectivity (max-flow) search at every level. Use nwcomponents or nwkcore for a network of this size, or look at a part of the network (nwsubset).) `force'

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

		tempname __nw_kcomp __nw_sizes __nw_kcompnum
		mata: `__nw_kcomp' = `netobj'->calculate_kcomponents(`k')
		mata: `__nw_sizes' = rowsum(`__nw_kcomp')
		mata: st_numscalar("nw_nkcomp", rows(`__nw_kcomp'))
		// (Stata stores the matrix in time growing with the square of the number of nodes: about a minute at
		// 100,000 nodes; nomatrix leaves it out)
		if "`nomatrix'" == "" {
			mata: st_matrix("nw_kcompmatrix", (rows(`__nw_kcomp') > 0 ? `__nw_kcomp' : J(1, `nodes', 0)))
		}
		mata: `__nw_kcompnum' = (rows(`__nw_kcomp') > 0 ? editvalue(colmax(`__nw_kcomp' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture confirm new variable `netgenerate'`i'
		if _rc capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_kcompnum')
		mata: mata drop `__nw_kcomp' `__nw_sizes' `__nw_kcompnum'

		return scalar kcomponents = nw_nkcomp
		if "`nomatrix'" == "" {
			return matrix kcomp_matrix = nw_kcompmatrix
		}
		local lkcomp = nw_nkcomp

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `k'-components: {res}`lkcomp'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
