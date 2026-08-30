
capture program drop nwnclique
program nwnclique, rclass
	version 12
	syntax [anything(name=netname)][, n(int 2) GENerate(string) replace minsize(int 3) silent]
	set more off

	if `n' < 2 {
		di "{err}n() must be at least 2; n(1) is exactly a clique - use {help nwclique} for that case."
		error 198
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
			local netgenerate = "_ncliquenum"
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

		tempname __nw_nclq __nw_sizes __nw_nclqnum
		mata: `__nw_nclq' = `netobj'->calculate_nclique_filtered(`n', `minsize')
		mata: `__nw_sizes' = rowsum(`__nw_nclq')
		mata: st_numscalar("nw_nncliq", rows(`__nw_nclq'))
		mata: st_matrix("nw_ncliquematrix", (rows(`__nw_nclq') > 0 ? `__nw_nclq' : J(1, `nodes', 0)))
		mata: `__nw_nclqnum' = (rows(`__nw_nclq') > 0 ? editvalue(colmax(`__nw_nclq' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_nclqnum')
		mata: mata drop `__nw_nclq' `__nw_sizes' `__nw_nclqnum'

		return scalar ncliques = nw_nncliq
		return matrix nclique_matrix = nw_ncliquematrix
		local lncliq = nw_nncliq

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `n'-cliques (size >= `minsize'): {res}`lncliq'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
