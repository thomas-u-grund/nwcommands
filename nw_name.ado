capture program drop nw_name
program nw_name
	version 9
	syntax [anything(name=netname)], [id(string) new2mode(string) newvalued(string) newselfloop(string) newlabsfromvar(varname) newvars(string) newtitle(string) newcaption(string) newname(string) newdirected(string) newmodes(string) newmode1desc(string) newmode2desc(string) newprovenance(string) ]
	
	nw_syntax `netname'
	
	unw_defs
	
	mata: st_rclear()
	
	local nets wordcount("`netname'")
	if `nets' > 1 {
		di "{err}only one {it:netname} allowed"
		error 6055
	}
	mata: st_local("number", strofreal(nw.nws.get_number()))

	if ("`netname'" == "" & "`id'" == ""){
		local id = `number'
	}
	if "`netname'" == "" {
		mata: st_local("netname", nw.nws.pdefs[`id']->get_name())
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
			mata: nw.nws.pdefs[`id']->set_directed(1)
		}
		if "`newdirected'" == "false" {
			mata: nw.nws.pdefs[`id']->set_directed(0)
		}
	}
	if "`newvalued'" != "" {
		if "`newvalued'" == "true" {
			mata: nw.nws.pdefs[`id']->set_valued(1)
		}
		if "`newvalued'" == "false" {
			mata: nw.nws.pdefs[`id']->set_valued(0)
		}
	}
	if "`new2mode'" != "" {
		if "`new2mode'" == "true" {
			mata: nw.nws.pdefs[`id']->set_2mode(1)
		}
		if "`new2mode'" == "false" {
			mata: nw.nws.pdefs[`id']->set_2mode(0)
		}
	}
	if "`newlabsfromvar'" != "" {
		mata: nw.nws.pdefs[`id']->set_nodes((st_sdata((1::(nw.nws.pdefs[`id']->get_nodes())), "`newlabsfromvar'"))')		
		mata: nw.nws.pdefs[`id']->set_nodesvar(strtoname(nw.nws.pdefs[`id']->get_nodenames()))
	}
	if "`newtitle'" != "" {
		mata: nw.nws.pdefs[`id']->set_label("`newtitle'")
	}
	if "`newcaption'" != "" {
		mata: nw.nws.pdefs[`id']->set_caption("`newcaption'")
	}
	if "`newselfloop'" != "" {
		if "`newselfloop'" == "true" {
			mata: nw.nws.pdefs[`id']->set_selfloop(1)
		}
		if "`newselfloop'" == "false" {
			mata: nw.nws.pdefs[`id']->set_selfloop(0)
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
		mata: nw.nws.pdefs[`id']->set_modes_from_labeled_string(`"`newmodes'"')
	}
	if "`newmode1desc'" != "" {
		mata: nw.nws.pdefs[`id']->set_description_mode1(`"`newmode1desc'"')
	}
	if "`newmode2desc'" != "" {
		mata: nw.nws.pdefs[`id']->set_description_mode2(`"`newmode2desc'"')
	}
	if "`newprovenance'" != "" {
		mata: nw.nws.pdefs[`id']->set_provenance(`"`newprovenance'"')
	}

	mata: st_numscalar("r(id)", `id')
	mata: st_global("r(netname)", nw.nws.pdefs[`id']->get_name())
	mata: st_global("r(vars)", nw.nws.pdefs[`id']->get_nodesvar_string())
	mata: st_numscalar("r(nodes)", nw.nws.pdefs[`id']->get_nodes())
	mata: st_global("r(mode2)", nw.nws.pdefs[`id']->is_2mode())
	mata: st_global("r(selfloop)", nw.nws.pdefs[`id']->is_selfloop())
	mata: st_numscalar("r(selfloops)", nw.nws.pdefs[`id']->get_selfloops_number())
	mata: st_global("r(directed)", nw.nws.pdefs[`id']->is_directed())
	mata: st_global("r(valued)", nw.nws.pdefs[`id']->is_valued())
	mata: st_global("r(title)", nw.nws.pdefs[`id']->get_label())
	mata: st_global("r(caption)", nw.nws.pdefs[`id']->get_caption())
	mata: st_numscalar("r(missing_edges)", nw.nws.pdefs[`id']->get_missing_edges())
	//!! Should r(labs) have real labels?
	mata: st_global("r(labs)", invtokens(nw.nws.pdefs[`id']->get_nodenames(),","))
	mata: st_global("r(modes)", nw.nws.pdefs[`id']->get_modes_labeled_string())
	mata: st_numscalar("r(nodes1)", nw.nws.pdefs[`id']->get_nodes_mode1())
	mata: st_numscalar("r(nodes2)", nw.nws.pdefs[`id']->get_nodes_mode2())
	mata: st_global("r(mode1desc)", nw.nws.pdefs[`id']->get_description_mode1())
	mata: st_global("r(mode2desc)", nw.nws.pdefs[`id']->get_description_mode2())
	mata: st_global("r(provenance)", nw.nws.pdefs[`id']->get_provenance())
end

