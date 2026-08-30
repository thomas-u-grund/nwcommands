
capture program drop nwsimindex
program nwsimindex, rclass
	version 12
	syntax [anything(name=netname)][, measure(string) name(string) xvars replace]

	local measure = lower("`measure'")
	if "`measure'" == "" {
		local measure "jaccard"
	}
	_opts_oneof "common jaccard dice cosine adamicadar" "measure" "`measure'" 6556

	nw_syntax `netname'

	if "`name'" == "" {
		local name "simindex"
	}
	// replace, when given, reuses the exact requested name (drop then
	// recreate) rather than silently auto-incrementing to a different one
	// - the ordinary, non-surprising meaning of "replace" elsewhere in this
	// package (e.g. nwkcore's generate()/replace). nw_validate's own
	// r(validname) auto-increments unconditionally on a name collision,
	// which is only applied here when replace was NOT given.
	nw_validate `name'
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

	nwset, mat(`__nw_sim') name(`name') undirected labs(`labs')
	mata: mata drop `__nw_sim'

	nw_syntax `name'
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
