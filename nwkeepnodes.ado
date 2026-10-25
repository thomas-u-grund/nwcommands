capture program drop nwkeepnodes
program nwkeepnodes 
	version 9
	syntax [anything(name=netname)] [, nodes(string) generate(passthru) attributes(passthru) *]

	// BUGFIX: omitting both nodes() and keepmat() entirely used to be
	// silently interpreted as "keep nothing" (an empty keep-list), which
	// then crashed deep inside nwdropnodes.ado's own Mata code trying to
	// build a genuinely empty network. `keepmat()' isn't declared as its
	// own option here - it's absorbed into the trailing `*' wildcard and
	// forwarded to nwdropnodes as-is - so checked for via a substring
	// match on the raw forwarded option text.
	if "`nodes'" == "" & strpos(`"`options'"', "keepmat(") == 0 {
		di "{err}Specify {bf:nodes()} or {bf:keepmat()} - which nodes to keep."
		error 198
	}

	capture numlist "`nodes'"
	if _rc == 0 {
		local nodelist = "`r(numlist)'"
	}
	else {
		local nodelist "`nodes'"
	}	
	
	// _nwsyntax only re-exports 4 locals (netobj/id/netname/networks) -
	// this file also needs `nodes' (node count, used below); the
	// option-supplied `nodes' local (the node list to *keep*) is
	// already fully consumed into `nodelist' above, before this call
	// would overwrite it with the node count - same fix, same
	// reasoning as nwdropnodes.ado's own identical bug.
	_nwsyntax `netname', max(1)
	
	local newnodelist ""
	foreach onenode in `nodelist' {
		capture confirm integer number `onenode'
		if _rc != 0 {
			_nwnodeid `netname', nodelab(`onenode')
			local newnodelist "`newnodelist' `r(nodeid)'"
		}
		else {
			local newnodelist "`newnodelist' `onenode'"
		}
	}
	local nodelist "`newnodelist'"
		
	// The nodes to keep go to nwdropnodes as a 0/1 vector in Mata (keepmat()). The list of all the OTHER nodes used to
	// be built as a macro (nodes(1 2 3 ...)): 110,000 characters at 20,000 nodes, over Stata/BE's 264,408 characters
	// from about 48,000 nodes, and a subinstr per kept node on it.
	if strpos(`"`options'"', "keepmat(") > 0 {
		nwdropnodes `netname', `generate' `attributes' `options'
	}
	else {
		tempname __kn_keep
		mata: `__kn_keep' = J(`nodes', 1, 0)
		foreach j in `nodelist' {
			if `j' >= 1 & `j' <= `nodes' {
				mata: `__kn_keep'[`j'] = 1
			}
		}
		nwdropnodes `netname', keepmat(`__kn_keep') `generate' `attributes' `options'
		capture mata: mata drop `__kn_keep'
	}
end




*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
