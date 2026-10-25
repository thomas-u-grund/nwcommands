*! Date        : 24aug2014
*! Version     : 1.0
*! Author      : Thomas Grund, Linkoping University
*! Email	   : thomas.u.grund@gmail.com

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
	// this file also needs `nodes' (node count), which only _nwsyntax
	// itself provides; the option-supplied `nodes' local (the node
	// list to drop) is already fully consumed into `nodelist' above,
	// before this call would overwrite it with the node count.
	_nwsyntax `netname', max(1)

	if "`generate'" != "" {
		nwduplicate `netname', name(`generate')
		_nwsyntax `generate', max(1)
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

	// BUGFIX: dropping every node of a network (or the only node of a
	// single-node network) used to crash deep inside Mata - `select()'
	// on an all-zero selector produces a degenerate, genuinely empty
	// result that this file's own downstream matrix-building code was
	// never designed to handle, surfacing as a raw "conformability
	// error" (r3200) or "subscript invalid" (r3301) depending on the
	// exact shape involved, rather than a clear, expected error. This
	// package does not support a genuine 0-node network anywhere else
	// either, so guarded here with a clean message instead of attempting
	// to add that support just for this one command.
	mata: st_numscalar("r(keepcount)", sum(`keepmat'))
	if `r(keepcount)' == 0 {
		di "{err}Cannot drop every node of a network - at least one node must remain."
		error 198
	}

	// the node names of the remaining network go to nwreplacemat in a Mata variable: a long Stata option
	// string gets blanks inserted by Stata (every 5,292 characters), which corrupted node names above ~900 nodes
	tempname newnames
	mata: `newnames' = select(`netobj'->get_nodenames(), `keepmat'')
	// a two-mode network stays two-mode: the mode of every surviving node and the level labels are put back
	// after nwreplacemat has rebuilt the network (nwreplacemat sets neither)
	local __dn2 = ("`is2mode'" == "true")
	tempname dnmodes dnd1 dnd2
	if `__dn2' {
		mata: `dnmodes' = select(`netobj'->get_modes(), `keepmat'')
		mata: `dnd1' = `netobj'->get_description_mode1()
		mata: `dnd2' = `netobj'->get_description_mode2()
	}

	// BUGFIX: attribute values used to be read via st_data() AFTER
	// nwreplacemat (below) had already run - but nwreplacemat physically
	// reorders the dataset's own rows to match the new, post-drop node
	// order (confirmed directly: dropping node 2 of A/B/C/D moves the
	// surviving rows to [A,C,D], with the dropped node B moved to the
	// end) - it does not touch unrelated attached Stata variables like
	// `attributes()' itself, so those rode along with whatever the
	// underlying row-reordering mechanism did, landing in the NEW
	// (post-drop) row order by the time they were read. `keepvector'
	// (the select mask used to build subattr), by contrast, was built
	// against the OLD (pre-drop) row order and never updated - so
	// selecting an already-reordered attribute column with an
	// old-order mask paired every surviving node with the WRONG
	// neighbor's original value (confirmed: dropping node B from
	// A-B-C-D left C holding D's original value and D holding the
	// just-dropped B's own value, instead of each node keeping its own).
	// Fixed by reading each attribute's values in the genuinely OLD
	// (pre-drop, pre-reorder) row order - before nwreplacemat ever
	// runs - so they are read at the same point in time `keepvector'
	// itself was built against.
	tempname attrstash
	if "`attributes'" != "" {
		local attri = 0
		foreach attr of varlist `attributes' {
			local attri = `attri' + 1
			mata: `attrstash'`attri' = st_data((1,`nodes'), st_varindex("`attr'"))
		}
	}

	// generate new matrix and replace network with this new matrix
	tempname keepnet
	tempname keepvector
	// the matrix of the remaining network (for a network held as stored ties it is written tie by tie: the
	// n x n matrix of the full network is not built)
	_nwsyntax `netname'
	mata: `keepvector' = `keepmat'
	mata: st_local("__dnsparse", strofreal(nw_ties_only(`netobj') & sum(`keepvector') < `nodes' & "`netonly'" == ""))
	if `__dnsparse' {
		// a network held as stored ties stays so: the ties between the nodes that remain are the new network
		mata: `keepnet' = nw_dropnodes_triplets(`netobj', `keepvector')
		mata: `keepvector' = `keepvector''
		nwreplacemat `netname', triplets(`keepnet') labsmata(`newnames') `xvars'
	}
	else {
		mata: `keepnet' = nw_dropnodes_matrix(`netobj', `keepvector')
		mata: `keepvector' = `keepvector''
		nwreplacemat `netname', newmat(`keepnet') `netonly' labsmata(`newnames') `xvars'
	}
	mata: mata drop `newnames'
	if `__dn2' {
		_nwsyntax `netname'
		mata: `netobj'->set_2mode(1)
		mata: `netobj'->set_modes(`dnmodes')
		mata: `netobj'->set_description_mode1(`dnd1')
		mata: `netobj'->set_description_mode2(`dnd2')
		mata: st_local("__dnn1", strofreal(`netobj'->get_nodes_mode1()))
		mata: st_local("__dnn2", strofreal(`netobj'->get_nodes_mode2()))
		mata: mata drop `dnmodes' `dnd1' `dnd2'
		if `__dnn1' == 0 | `__dnn2' == 0 {
			di "{txt}(note: all nodes of one mode were dropped; {bf:`netname'} is still declared two-mode but one level is empty)"
		}
	}

	// deal with attributes that should be synced with the smaller network
	if "`attributes'" != "" {
		local attri = 0
		foreach attr of varlist `attributes' {
			local attri = `attri' + 1
			mata: subattr = select(`attrstash'`attri', `keepvector'')
			mata: st_view(attrview=.,(1,sum(`keepvector')), "`attr'")
			replace `attr' = .
			mata: attrview[.,.] = subattr
			mata: mata drop `attrstash'`attri'
		}
		mata: mata drop subattr
	}
	mata: mata drop `keepnet' `keepvector'
	mata: st_rclear()
	nwcompressobs
end


*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
