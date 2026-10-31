
capture program drop nwkplex
program nwkplex, rclass
	version 12
	syntax [anything(name=netname)][, k(int 2) GENerate(string) replace minsize(int -1) MAXPlexes(real 100000) COUNTonly NOMatrix MAXTime(real 60) silent]
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
	if `maxplexes' < 1 {
		di "{err}maxplexes() must be a positive number."
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
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'

		tempname __nw_kplex __nw_sizes __nw_kplexnum
		mata: nwg_enum_reset(`maxplexes', `=("`countonly'" != "")', `maxtime', `=("`nomatrix'" != "")')
		mata: `__nw_kplex' = `netobj'->calculate_kplex_filtered(`k', `minsize')
		mata: nwg_enum_summary(`__nw_kplex')
		if "`countonly'" != "" {
			mata: st_numscalar("nw_nnwkplex", nwg_enum_count)
			mata: st_numscalar("nw_maxnwkplex", nwg_enum_max)
			mata: st_matrix("nw_tabnwkplex", nwg_enum_hist)
			mata: mata drop `__nw_kplex'
			mata: nwg_enum_reset(., .)
			return scalar kplexes = nw_nnwkplex
			return scalar maxsize = nw_maxnwkplex
			matrix colnames nw_tabnwkplex = size count
			return matrix size_table = nw_tabnwkplex
			local lcount = nw_nnwkplex
			if "`silent'" == "" {
				noi di "{hline 40}"
				noi di "{txt}  Network name: {res}`netname_temp'"
				noi di "{txt}  Maximal `k'-plexes (size >= `minsize'): {res}`lcount'"
				noi di " "
			}
			local i = `=`i' + 1'
			continue
		}
		if "`nomatrix'" != "" {
			// no sets-by-nodes matrix (it needs memory for sets x nodes numbers): the per-node
			// variable and the counts only
			mata: st_numscalar("nw_nnwkplex", nwg_enum_count)
			mata: st_numscalar("nw_maxnwkplex", nwg_enum_max)
			mata: st_matrix("nw_tabnwkplex", nwg_enum_hist)
			capture confirm new variable `netgenerate'`i'
			if _rc capture drop `netgenerate'`i'
			gen `netgenerate'`i' = .
			mata: st_store((1::`nodes'), "`netgenerate'`i'", nwg_enum_nodevar)
			mata: mata drop `__nw_kplex'
			mata: nwg_enum_reset(., .)
			return scalar kplexes = nw_nnwkplex
			return scalar maxsize = nw_maxnwkplex
			matrix colnames nw_tabnwkplex = size count
			return matrix size_table = nw_tabnwkplex
			local lcount = nw_nnwkplex
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
		mata: `__nw_sizes' = rowsum(`__nw_kplex')
		mata: st_numscalar("nw_nkplex", rows(`__nw_kplex'))
		mata: st_matrix("nw_kplexmatrix", (rows(`__nw_kplex') > 0 ? `__nw_kplex' : J(1, `nodes', 0)))
		mata: `__nw_kplexnum' = (rows(`__nw_kplex') > 0 ? editvalue(colmax(`__nw_kplex' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture confirm new variable `netgenerate'`i'
		if _rc capture drop `netgenerate'`i'
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
