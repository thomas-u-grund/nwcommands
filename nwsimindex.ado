
capture program drop nwsimindex
program nwsimindex, rclass
	version 12
	syntax [anything(name=netname)][, measure(string) name(string) xvars replace force]

	local measure = lower("`measure'")
	if "`measure'" == "" {
		local measure "jaccard"
	}
	_opts_oneof "common jaccard dice cosine adamicadar" "measure" "`measure'" 6556

	_nwsyntax `netname'
	local __wasdir = ("`directed'" == "true")
	_nwmissnote `netname', quiet
	local __nmiss = r(nmissing)
	_nwvaluednote `netname'
	if r(shown) == 1 {
		noi di `"`r(msg)'"'
	}
	_nwdenseguard, command(nwsimindex) nodes(`nodes') copies(5) alternative(The result is a network with a tie for every pair of nodes. Compute it for a part of the network (nwsubset, nwego, nwkeepnodes) or take the ties with nwtoedge, compress into other software.) `force'

	if "`name'" == "" {
		local name "simindex"
	}
	// replace, when given, reuses the exact requested name (drop then
	// recreate) rather than silently auto-incrementing to a different one
	// - the ordinary, non-surprising meaning of "replace" elsewhere in this
	// package (e.g. nwkcore's generate()/replace). nwvalidate's own
	// r(validname) auto-increments unconditionally on a name collision,
	// which is only applied here when replace was NOT given.
	// the input cannot receive the result: it would be dropped before or while the result is formed
	_nwtargetcheck `name', source(`netname') given(0)
	local __replacing 0
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		local __replacing = ("`replace'" != "")
		if "`replace'" == "" {
			di "{txt}{p 0 0 2}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use.{p_end}"
			local name = r(validname)
		}
	}

	tempname __nw_sim
	mata: `__nw_sim' = `netobj'->calculate_similarity_index("`measure'")

	// node names go to nwset in a Mata variable (a long Stata option string gets blanks inserted, see GOTCHA.md)
	tempname __nw_names
	mata: `__nw_names' = `netobj'->get_nodenames()
	// The old network under replace is dropped only here, after everything has been read from the source: a drop moves
	// the stored networks, so that netobj would point to another network (and a failed computation keeps the old one).
	if `__replacing' capture nwdrop `name'
	nwset, mat(`__nw_sim') name(`name') undirected nodenames(`__nw_names')
	mata: mata drop `__nw_sim' `__nw_names'

	_nwsyntax `name'
	mata: `netobj'->set_valued(1)

	return scalar nodes = `nodes'
	return local measure "`measure'"
	return local netname "`name'"

	di "{hline 40}"
	di "{txt}  Similarity network: {res}`name'"
	di "{txt}  Measure: {res}`measure'"
	di "{txt}  Nodes: {res}`nodes'"
	di "{hline 40}"
	if `__wasdir' {
		di "{txt}{p 4 4 2}(directed network: the neighbours of a node are the nodes it sends ties to and the nodes it receives ties from){p_end}"
	}
	else {
		di "{txt}{p 4 4 2}(undirected network){p_end}"
	}
	if `__nmiss' > 0 {
		di "{txt}{p 4 4 2}(`__nmiss' missing ties treated as 0){p_end}"
	}

	if "`xvars'" != "" {
		nwload `name', keepuser
	}
end
