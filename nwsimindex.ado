
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
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
			local name = r(validname)
		}
		else {
			capture nwdrop `name'
		}
	}

	tempname __nw_sim
	mata: `__nw_sim' = `netobj'->calculate_similarity_index("`measure'")

	// node names go to nwset in a Mata variable (a long Stata option string gets blanks inserted, see GOTCHA.md)
	tempname __nw_names
	mata: `__nw_names' = `netobj'->get_nodenames()
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

	if "`xvars'" != "" {
		nwload `name'
	}
end
