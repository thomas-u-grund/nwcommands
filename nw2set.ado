
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
		nwset `varlist', `options' bipartite `xvars' labsfromvar(`rownames') name(`name') labs(`labs') vars(`vars')
		capture drop `varlist'
		capture drop `rownames'
		nw_syntax
		mata: `netobj'->set_description_mode1("M")
		mata: `netobj'->set_description_mode2("N")
		_nwdatasync
		unw_defs
		capture drop if `nw_nodename' == ""
	}
end
	
	
	
	
	
