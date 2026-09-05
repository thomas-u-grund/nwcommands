
capture program drop nwclique
program nwclique, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace minsize(int 3) silent]
	set more off

	if `minsize' < 1 {
		di "{err}minsize() must be a positive integer."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_cliquenum"
		}

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyntax `netname_temp'

		tempname __nw_cliq __nw_sizes __nw_cliqnum
		mata: `__nw_cliq' = `netobj'->calculate_cliques_filtered(`minsize')
		mata: `__nw_sizes' = rowsum(`__nw_cliq')
		mata: st_numscalar("nw_ncliques", rows(`__nw_cliq'))
		mata: st_matrix("nw_cliquematrix", (rows(`__nw_cliq') > 0 ? `__nw_cliq' : J(1, `nodes', 0)))
		mata: `__nw_cliqnum' = (rows(`__nw_cliq') > 0 ? editvalue(colmax(`__nw_cliq' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_store((1::`nodes'), "`netgenerate'`k'", `__nw_cliqnum')
		mata: mata drop `__nw_cliq' `__nw_sizes' `__nw_cliqnum'

		return scalar cliques = nw_ncliques
		return matrix clique_matrix = nw_cliquematrix
		local lcliques = nw_ncliques

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal cliques (size >= `minsize'): {res}`lcliques'"
			noi sum `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
