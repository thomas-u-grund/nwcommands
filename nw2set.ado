
capture program drop nw2set
program nw2set
	syntax [varlist (default=none)][, edgelist name(string) rownames(varname) vars(string) xvars labs(string) clear nwclear *]
	set more off

	// `clear'/`nwclear' were previously wildcard-swallowed into `options' rather
	// than declared directly, so these checks always tested an undefined local
	// and neither ever ran - the option was silently accepted and did nothing at
	// all, in both the edgelist and varlist branches below. Declared explicitly
	// now and handled once, here, as a side effect before dispatch - mirroring
	// nwset.ado's own established clear/nwclear-before-creation convention (see
	// its own comment at the equivalent point) rather than forwarding through
	// `options' to nwset, which would have silently dropped it entirely on the
	// edgelist branch (nw2fromedge/nwfromedge accept a differently-named
	// `noclear' option, not `clear'/`nwclear').
	if "`clear'" != "" {
		nwdrop _all, netonly
	}
	if "`nwclear'" != "" {
		nwclear
	}
	if "`generate'" == "" {
		local generate = "_modeid"
	}

	if "`edgelist'" != "" {
		nw2fromedge `varlist', `xvars' name(`name')
		exit
	}
	else {
		// the other variables of the data describe the rows of the matrix, that is the nodes of the second mode: their
		// values are saved here and put back on those nodes' observations at the end
		local __nw2other ""
		if "`varlist'" != "" {
			qui ds
			local __nw2all `r(varlist)'
			local __nw2drop `varlist' `rownames' _nwnode _nwmode _nwinclude _nwlabel
			local __nw2other : list __nw2all - __nw2drop
		}
		tempfile __nw2data
		if "`__nw2other'" != "" {
			preserve
			keep `__nw2other'
			qui save `"`__nw2data'"'
			restore
		}
		nwset `varlist', `options' bipartite `xvars' labsfromvar(`rownames') name(`name') labs(`labs') vars(`vars')
		capture drop `varlist'
		capture drop `rownames'
		_nwsyntax
		mata: `netobj'->set_description_mode1("M")
		mata: `netobj'->set_description_mode2("N")
		_nwdatasync
		unw_defs
		capture drop if `nw_nodename' == ""
		if "`__nw2other'" != "" {
			_nwsyntax
			local __nw2cols : word count `varlist'
			tempfile __nw2keyed
			preserve
			qui use `"`__nw2data'"', clear
			tempvar __nw2obs
			qui gen long `__nw2obs' = _n + `__nw2cols'
			qui drop if `__nw2obs' > `nodes'
			qui gen str244 `nw_nodename' = ""
			mata: st_sstore(., "`nw_nodename'", (`netobj'->get_nodenames()')[st_data(., "`__nw2obs'")])
			qui compress `nw_nodename'
			drop `__nw2obs'
			qui save `"`__nw2keyed'"'
			restore
			// merge fills only the missing values of the node rows; the order of the observations is kept
			tempvar __nw2order
			qui gen long `__nw2order' = _n
			qui merge m:1 `nw_nodename' using `"`__nw2keyed'"', update nogen keep(master match match_update match_conflict)
			sort `__nw2order'
		}
	}
end
	
	
	
	
	
