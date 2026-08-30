
capture program drop nwkplex
program nwkplex, rclass
	version 12
	syntax [anything(name=netname)][, k(int 2) GENerate(string) replace minsize(int -1) silent]
	set more off

	if `k' < 2 {
		di "{err}k() must be at least 2; a 1-plex is exactly a clique - use {help nwclique} for that case."
		error 198
	}

	if `minsize' < 0 {
		local minsize = `k' + 1
	}
	if `minsize' < 1 {
		di "{err}minsize() must be a positive integer."
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
			local netgenerate = "_kplexnum"
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

		tempname __nw_kplex __nw_sizes __nw_kplexnum
		mata: `__nw_kplex' = `netobj'->calculate_kplex_filtered(`k', `minsize')
		mata: `__nw_sizes' = rowsum(`__nw_kplex')
		mata: st_numscalar("nw_nkplex", rows(`__nw_kplex'))
		mata: st_matrix("nw_kplexmatrix", (rows(`__nw_kplex') > 0 ? `__nw_kplex' : J(1, `nodes', 0)))
		mata: `__nw_kplexnum' = (rows(`__nw_kplex') > 0 ? editvalue(colmax(`__nw_kplex' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_kplexnum')
		mata: mata drop `__nw_kplex' `__nw_sizes' `__nw_kplexnum'

		return scalar kplexes = nw_nkplex
		return matrix kplex_matrix = nw_kplexmatrix
		local lkplex = nw_nkplex

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `k'-plexes (size >= `minsize'): {res}`lkplex'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
