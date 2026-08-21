*! Date        : 24aug2014
*! Version     : 1.0
*! Author      : Thomas Grund, Linkoping University
*! Email	   : contact@nwcommands.org

capture program drop nwdropnodes
program nwdropnodes 
	version 9
	syntax [anything(name=netname)] [, xvars nodes(string) keepmat(string) attributes(varlist) netonly generate(string)]
	capture numlist "`nodes'"
	if _rc == 0 {
		local nodelist = "`r(numlist)'"
	}
	else {
		local nodelist "`nodes'"
	}	
	
	// _nwsyntax only re-exports 4 locals (netobj/id/netname/networks) -
	// this file also needs `nodes' (node count), which only nw_syntax
	// itself provides; the option-supplied `nodes' local (the node
	// list to drop) is already fully consumed into `nodelist' above,
	// before this call would overwrite it with the node count.
	nw_syntax `netname', max(1)

	if "`generate'" != "" {
		nwduplicate `netname', name(`generate') xvars
		nw_syntax `generate', max(1)
	}
	
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

	// was reading the legacy pre-2016 $nw_<id>/$nwlabs_<id> globals,
	// which the modern netobj/NWdef architecture never populates (empty
	// for any network created the modern way) - nwname's own r(vars)/
	// r(labs) are the direct modern equivalents (confirmed via
	// get_nodesvar_string()/get_labs() in unw_core.do). r(vars) is
	// already space-separated, matching the `: word `i' of `vars''
	// extraction below; r(labs) is comma-separated (this package's
	// established convention elsewhere), converted to space-separated
	// here to match that same extraction pattern.
	nwname `netname'
	local vars "`r(vars)'"
	local newvars ""

	local labs = subinstr("`r(labs)'", ",", " ", .)
	local newlabs ""
	
	// get new vars and new labs
	local i = 0
	
	if "`keepmat'" == "" {
		local keepmat = "keepmat"
		mata: `keepmat' = J(`nodes',1,1)
		foreach onenode in `nodelist' {
			if `onenode' <= `nodes' {
				mata: `keepmat'[`onenode',1] = 0
			}
		}
	}
	else {
		mata: keepmatSize = rows(`keepmat')
		mata: st_numscalar("r(keepmatsize)", keepmatSize)
		if `r(keepmatsize)' != `nodes' {
			mata: `keepmat' = J(`nodes',1,1)
			di "{txt}Warning: Mata matrix {bf:keepmat} has the wrong size; no nodes dropped."
		}
	}
	
	foreach onevar in `vars' {
		local i = `i' + 1
		local onelab : word `i' of `labs'
		mata: st_numscalar("r(include)", `keepmat'[`i',1])
		if ("`r(include)'" == "1") {
			local newvars "`newvars' `onevar'"
			// comma-separated, not space-separated - this is what
			// eventually reaches nwrandom's own labs() option (via
			// nwreplacemat's size-changing path), which expects the
			// same comma-separated format nwname's own r(labs)
			// uses (confirmed directly: nwrandom's labs() silently
			// treats a bare space-separated list as a single label
			// for the first node, auto-generating default "n2"/"n3"-
			// style labels for the rest, rather than erroring - a
			// separate, genuinely silent bug in nwrandom.ado itself,
			// not fixed here since this file does not need to pass
			// it a malformed value to begin with).
			if "`newlabs'" == "" {
				local newlabs "`onelab'"
			}
			else {
				local newlabs "`newlabs',`onelab'"
			}
		}
		mata: st_rclear()
	}
		
	// generate new matrix and replace network with this new matrix
	tempname keepnet
	tempname keepvector
	nwtomata `netname', mat(`keepnet')
	mata: `keepvector' = `keepmat'
	mata: `keepnet' = select(`keepnet', `keepvector')
	mata: `keepvector' = `keepvector''
	mata: `keepnet' = select(`keepnet', `keepvector')
	nwreplacemat `netname', newmat(`keepnet') `netonly' labs(`newlabs') vars(`newvars') `xvars'

	// deal with attributes that should be synced with the smaller network
	if "`attributes'" != "" {
		foreach attr of varlist `attributes' {
			mata: attr = st_data((1,`nodes'), st_varindex("`attr'"))
			mata: subattr = select(attr, `keepvector'')
			mata: st_view(attrview=.,(1,sum(`keepvector')), "`attr'")
			replace `attr' = .
			mata: attrview[.,.] = subattr
		}
		mata: mata drop attr subattr
	}
	mata: mata drop `keepnet' `keepvector'
	mata: st_rclear()
	nwcompressobs
end


*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
