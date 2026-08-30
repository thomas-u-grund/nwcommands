
capture program drop nwkcomponents
program nwkcomponents, rclass
	version 12
	syntax [anything(name=netname)][, k(int 2) GENerate(string) replace silent]
	set more off

	if `k' < 1 {
		di "{err}k() must be at least 1; k(1) is exactly a connected component - use {help nwcomponents} for that case."
		error 198
	}

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_kcompnum"
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

		tempname __nw_kcomp __nw_sizes __nw_kcompnum
		mata: `__nw_kcomp' = `netobj'->calculate_kcomponents(`k')
		mata: `__nw_sizes' = rowsum(`__nw_kcomp')
		mata: st_numscalar("nw_nkcomp", rows(`__nw_kcomp'))
		mata: st_matrix("nw_kcompmatrix", (rows(`__nw_kcomp') > 0 ? `__nw_kcomp' : J(1, `nodes', 0)))
		mata: `__nw_kcompnum' = (rows(`__nw_kcomp') > 0 ? editvalue(colmax(`__nw_kcomp' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_kcompnum')
		mata: mata drop `__nw_kcomp' `__nw_sizes' `__nw_kcompnum'

		return scalar kcomponents = nw_nkcomp
		return matrix kcomp_matrix = nw_kcompmatrix
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
