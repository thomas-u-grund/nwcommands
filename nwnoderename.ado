
capture program drop nwnoderename
program nwnoderename	
	syntax [anything(name=netname)], old(string) new(string)
	_nwsyntax `netname'
	_nwdatasync `netname'
	unw_defs
	
	// the node variables of the network (nwload) before the rename: the
	// variable of the node is renamed only when all of them are in the data
	// (otherwise a variable of that name is the user's own)
	tempname __nrvars
	mata: `__nrvars' = `netobj'->get_nodesvar()
	mata: st_local("__nr_oldvar", (cols(`__nrvars') == cols(`netobj'->get_nodenames()) & anyof(`netobj'->get_nodenames(), "`old'")) ? `__nrvars'[(selectindex(`netobj'->get_nodenames() :== "`old'"))[1]] : "")
	mata: st_local("__nr_allvars", strofreal(cols(`__nrvars') > 0 & all(_st_varindex(`__nrvars') :< .)))
	mata: st_numscalar("r(success)", (*`netobj').rename_nodename("`old'", "`new'"))

	if `r(success)' == 1 {
		// the label of the node's row changes; no row is added
		qui replace `nw_nodename' = "`new'" if `nw_nodename' == "`old'"
		if "`__nr_oldvar'" != "" & `__nr_allvars' {
			mata: st_local("__nr_newvar", (`netobj'->get_nodesvar())[(selectindex(`netobj'->get_nodenames() :== "`new'"))[1]])
			capture confirm new variable `__nr_newvar'
			if _rc == 0 & "`__nr_newvar'" != "`__nr_oldvar'" rename `__nr_oldvar' `__nr_newvar'
		}
		capture mata: mata drop `__nrvars'
		_nwdatasync `netname'
		mata: st_numscalar("r(success)", 1)
	}
	else{
		di "{err}Old name not found or new name invalid."
		mata: st_numscalar("r(success)", 0)
		error 198
	}
end

