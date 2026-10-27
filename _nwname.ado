capture program drop _nwname
program _nwname
	version 9
	// `newvars(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (a fully dead,
	// undocumented no-op; confirmed via grep across the whole package -
	// nothing ever passed it either).
	syntax [anything(name=netname)], [id(string) new2mode(string) newvalued(string) newselfloop(string) newlabsfromvar(varname) newtitle(string) newcaption(string) newname(string) newdirected(string) newmodes(string) newmode1desc(string) newmode2desc(string) newprovenance(string) skipcheck]

	// BUGFIX: `id()' was completely non-functional - _nwsyntax.ado's own
	// unprefixed `c_local id `r(id)'' side effect immediately clobbered
	// this program's own `id' local with whatever id _nwsyntax resolved
	// (the CURRENT network's id, since `netname' is blank in the
	// id()-only call pattern) before the caller-supplied id() was ever
	// consulted below - `nwname, id(N)' always silently acted on the
	// current network regardless of N. Preserved into `optid' before the
	// clobbering call, then restored immediately after, matching how
	// nwcurrent.ado (the same group's own sibling command) avoids this
	// exact trap by consuming its own `id' local BEFORE calling
	// _nwsyntax at all.
	local optid `id'
	_nwsyntax `netname'
	local id `optid'

	unw_defs
	
	mata: st_rclear()
	
	local nets wordcount("`netname'")
	if `nets' > 1 {
		di "{err}only one {it:netname} allowed"
		error 6055
	}
	mata: st_local("number", strofreal(__nw.nws.get_number()))

	if ("`netname'" == "" & "`id'" == ""){
		local id = `number'
	}
	if "`netname'" == "" {
		mata: st_local("netname", __nw.nws.pdefs[`id']->get_name())
	}
	if "`id'" == "" {
		mata: st_local("id", strofreal(`nws'.get_index_of("`netname'")))
	}
	
	if "`newname'" != "" {
		nwvalidate `newname'
		if "`r(exists)'" == "true" {
			noi di "{txt}network name {bf:`newname'} already exists; newname changed to {bf:`r(validname)'}"
		}
		mata: `nws'.rename("`netname'", "`r(validname)'")
	}
	if "`newdirected'" != "" {
		if "`newdirected'" == "true" {
			mata: __nw.nws.pdefs[`id']->set_directed(1)
		}
		if "`newdirected'" == "false" {
			mata: __nw.nws.pdefs[`id']->set_directed(0)
		}
	}
	if "`newvalued'" != "" {
		if "`newvalued'" == "true" {
			mata: __nw.nws.pdefs[`id']->set_valued(1)
		}
		if "`newvalued'" == "false" {
			mata: __nw.nws.pdefs[`id']->set_valued(0)
		}
	}
	if "`new2mode'" != "" {
		if "`new2mode'" == "true" {
			mata: __nw.nws.pdefs[`id']->set_2mode(1)
		}
		if "`new2mode'" == "false" {
			mata: __nw.nws.pdefs[`id']->set_2mode(0)
		}
	}
	if "`newlabsfromvar'" != "" {
		mata: __nw.nws.pdefs[`id']->set_nodes((st_sdata((1::(__nw.nws.pdefs[`id']->get_nodes())), "`newlabsfromvar'"))')		
		mata: __nw.nws.pdefs[`id']->set_nodesvar(strtoname(__nw.nws.pdefs[`id']->get_nodenames()))
	}
	if "`newtitle'" != "" {
		mata: __nw.nws.pdefs[`id']->set_label("`newtitle'")
	}
	if "`newcaption'" != "" {
		mata: __nw.nws.pdefs[`id']->set_caption("`newcaption'")
	}
	if "`newselfloop'" != "" {
		if "`newselfloop'" == "true" {
			mata: __nw.nws.pdefs[`id']->set_selfloop(1)
		}
		if "`newselfloop'" == "false" {
			mata: __nw.nws.pdefs[`id']->set_selfloop(0)
		}
	}
	// was silently missing entirely: mode membership (which node is
	// mode 1 vs mode 2, as opposed to the bare is2mode() yes/no flag
	// above) had no setter reachable from outside the class at all, so
	// nwsave/nwuse had no way to round-trip it - confirmed directly
	// that a saved-and-reloaded two-mode network lost its actual mode
	// partition every time despite is2mode itself surviving correctly.
	// A blank newmodes() is a deliberate no-op (see
	// set_modes_from_labeled_string()'s own header comment in
	// unw_core.do), so reloading a .nwdta saved before this fix existed
	// behaves exactly as it always has - no attempt to retroactively
	// recover data that was genuinely never saved.
	if "`newmodes'" != "" {
		mata: __nw.nws.pdefs[`id']->set_modes_from_labeled_string(`"`newmodes'"')
	}
	if "`newmode1desc'" != "" {
		mata: __nw.nws.pdefs[`id']->set_description_mode1(`"`newmode1desc'"')
	}
	if "`newmode2desc'" != "" {
		mata: __nw.nws.pdefs[`id']->set_description_mode2(`"`newmode2desc'"')
	}
	if "`newprovenance'" != "" {
		mata: __nw.nws.pdefs[`id']->set_provenance(`"`newprovenance'"')
	}

	// A network can only be declared two-mode when it is bipartite: both modes must hold nodes and no tie may join two
	// nodes of the same mode (igraph::is_bipartite with the declared types).  nwuse restores older files that carry no
	// modes and passes skipcheck.
	if "`new2mode'" == "true" & "`skipcheck'" == "" {
		qui mata: (void) __nw.nws.pdefs[`id']->get_modes()
		mata: st_local("__n1", strofreal(__nw.nws.pdefs[`id']->get_nodes_mode1()))
		mata: st_local("__n2", strofreal(__nw.nws.pdefs[`id']->get_nodes_mode2()))
		mata: st_local("__bad", strofreal(__nw.nws.pdefs[`id']->count_samemode_ties()))
		if `__n1' == 0 | `__n2' == 0 {
			mata: __nw.nws.pdefs[`id']->set_2mode(0)
			di "{err}Network {bf:`netname'} cannot be declared two-mode: only `=cond(`__n2' == 0, "mode 1", "mode 2")' has nodes. Give the mode of every node with {bf:newmodes()} in the same call, or build the network with {bf:nwset, twomode} or {bf:nw2fromedge}."
			error 459
		}
		if `__bad' > 0 {
			mata: __nw.nws.pdefs[`id']->set_2mode(0)
			di "{err}Network {bf:`netname'} cannot be declared two-mode: `__bad' ties join two nodes of the same mode."
			error 459
		}
	}

	mata: st_numscalar("r(id)", `id')
	mata: st_global("r(netname)", __nw.nws.pdefs[`id']->get_name())
	// Naming consistency (moderate-severity pass, information_census
	// group): nwdyads/nwtriads use `r(name)' for the identical "which
	// network is this result about" concept; nwname used `r(netname)'
	// only. Added as an alias rather than renaming, so existing callers
	// of either name keep working.
	mata: st_global("r(name)", __nw.nws.pdefs[`id']->get_name())
	mata: st_global("r(vars)", __nw.nws.pdefs[`id']->get_nodesvar_string())
	mata: st_numscalar("r(nodes)", __nw.nws.pdefs[`id']->get_nodes())
	mata: st_global("r(mode2)", __nw.nws.pdefs[`id']->is_2mode())
	mata: st_global("r(selfloop)", __nw.nws.pdefs[`id']->is_selfloop())
	mata: st_numscalar("r(selfloops)", __nw.nws.pdefs[`id']->get_selfloops_number())
	mata: st_global("r(directed)", __nw.nws.pdefs[`id']->is_directed())
	mata: st_global("r(valued)", __nw.nws.pdefs[`id']->is_valued())
	mata: st_global("r(title)", __nw.nws.pdefs[`id']->get_label())
	mata: st_global("r(caption)", __nw.nws.pdefs[`id']->get_caption())
	mata: st_numscalar("r(missing_edges)", __nw.nws.pdefs[`id']->get_missing_edges())
	//!! Should r(labs) have real labels?
	mata: st_global("r(labs)", nw_labs_string(__nw.nws.pdefs[`id']->get_nodenames()))
	mata: st_global("r(modes)", __nw.nws.pdefs[`id']->get_modes_labeled_string())
	mata: st_numscalar("r(nodes1)", __nw.nws.pdefs[`id']->get_nodes_mode1())
	mata: st_numscalar("r(nodes2)", __nw.nws.pdefs[`id']->get_nodes_mode2())
	mata: st_global("r(mode1desc)", __nw.nws.pdefs[`id']->get_description_mode1())
	mata: st_global("r(mode2desc)", __nw.nws.pdefs[`id']->get_description_mode2())
	mata: st_global("r(provenance)", __nw.nws.pdefs[`id']->get_provenance())
	mata: st_global("r(temporal)", __nw.nws.pdefs[`id']->is_temporal())
	mata: st_global("r(temporaltype)", __nw.nws.pdefs[`id']->get_temporal_type())
	mata: st_global("r(timevar)", __nw.nws.pdefs[`id']->get_timevar())
	mata: st_global("r(startvar)", __nw.nws.pdefs[`id']->get_startvar())
	mata: st_global("r(endvar)", __nw.nws.pdefs[`id']->get_endvar())
	mata: st_global("r(eventtimevar)", __nw.nws.pdefs[`id']->get_eventtimevar())
end

