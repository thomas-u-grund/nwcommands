
capture program drop nwnclique
program nwnclique, rclass
	version 12
	syntax [anything(name=netname)][, n(int 2) GENerate(string) replace minsize(int 3) MAXcliques(real 100000) COUNTonly NOMatrix MAXTime(real 60) silent]
	set more off

	if `n' < 2 {
		di "{err}n() must be at least 2; n(1) is exactly a clique - use {help nwclique} for that case."
		error 198
	}

	if `minsize' < 1 {
		di "{err}minsize() must be a positive integer."
		error 198
	}
	if `maxcliques' < 1 {
		di "{err}maxcliques() must be a positive number."
		error 198
	}
	if `maxtime' <= 0 {
		di "{err}maxtime() must be a positive number."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		if "`generate'" == "" & "`countonly'" == "" {
			noi di "{err}option {bf:generate()} required (or {bf:countonly})."
			error 198
		}
		local netgenerate "`generate'"

		if "`netgenerate'" != "" {
			capture confirm variable `netgenerate'`i', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`netgenerate'`i'} already exists; specify {bf:replace}"
				err 99
			}
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

		tempname __nw_nclq __nw_sizes __nw_nclqnum
		mata: nwg_enum_reset(`maxcliques', `=("`countonly'" != "")', `maxtime', `=("`nomatrix'" != "")')
		mata: `__nw_nclq' = `netobj'->calculate_nclique_filtered(`n', `minsize')
		mata: nwg_enum_summary(`__nw_nclq')
		if "`countonly'" != "" {
			mata: st_numscalar("nw_nnwnclique", nwg_enum_count)
			mata: st_numscalar("nw_maxnwnclique", nwg_enum_max)
			mata: st_matrix("nw_tabnwnclique", nwg_enum_hist)
			mata: mata drop `__nw_nclq'
			mata: nwg_enum_reset(., .)
			return scalar ncliques = nw_nnwnclique
			return scalar maxsize = nw_maxnwnclique
			matrix colnames nw_tabnwnclique = size count
			return matrix size_table = nw_tabnwnclique
			local lcount = nw_nnwnclique
			if "`silent'" == "" {
				noi di "{hline 40}"
				noi di "{txt}  Network name: {res}`netname_temp'"
				noi di "{txt}  Maximal `n'-cliques (size >= `minsize'): {res}`lcount'"
				noi di " "
			}
			local i = `=`i' + 1'
			continue
		}
		if "`nomatrix'" != "" {
			// no sets-by-nodes matrix (it needs memory for sets x nodes numbers): the per-node
			// variable and the counts only
			mata: st_numscalar("nw_nnwnclique", nwg_enum_count)
			mata: st_numscalar("nw_maxnwnclique", nwg_enum_max)
			mata: st_matrix("nw_tabnwnclique", nwg_enum_hist)
			capture drop `netgenerate'`i'
			gen `netgenerate'`i' = .
			mata: st_store((1::`nodes'), "`netgenerate'`i'", nwg_enum_nodevar)
			mata: mata drop `__nw_nclq'
			mata: nwg_enum_reset(., .)
			return scalar ncliques = nw_nnwnclique
			return scalar maxsize = nw_maxnwnclique
			matrix colnames nw_tabnwnclique = size count
			return matrix size_table = nw_tabnwnclique
			local lcount = nw_nnwnclique
			capture confirm variable `netgenerate'`i', exact
			if "`silent'" == "" {
				noi di "{hline 40}"
				noi di "{txt}  Network name: {res}`netname_temp'"
				noi di "{txt}  Maximal sets (size >= `minsize'): {res}`lcount'"
				noi sum `netgenerate'`i'
				noi di " "
			}
			local i = `=`i' + 1'
			continue
		}
		mata: nwg_enum_reset(., .)
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
