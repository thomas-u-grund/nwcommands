
capture program drop nwnclan
program nwnclan, rclass
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

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		if "`generate'" == "" {
			di "{err}option {bf:generate()} required."
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
		_nwsyntax `netname_temp'

		tempname __nw_nclan __nw_sizes __nw_nclannum
		mata: `__nw_nclan' = `netobj'->calculate_nclan_filtered(`n', `minsize')
		mata: `__nw_sizes' = rowsum(`__nw_nclan')
		mata: st_numscalar("nw_nnclan", rows(`__nw_nclan'))
		mata: st_matrix("nw_nclanmatrix", (rows(`__nw_nclan') > 0 ? `__nw_nclan' : J(1, `nodes', 0)))
		mata: `__nw_nclannum' = (rows(`__nw_nclan') > 0 ? editvalue(colmax(`__nw_nclan' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_nclannum')
		mata: mata drop `__nw_nclan' `__nw_sizes' `__nw_nclannum'

		return scalar nclans = nw_nnclan
		return matrix nclan_matrix = nw_nclanmatrix
		local lnclan = nw_nnclan

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `n'-clans (size >= `minsize'): {res}`lnclan'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
