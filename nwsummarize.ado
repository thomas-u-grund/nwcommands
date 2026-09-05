
capture program drop nwsummarize
program nwsummarize
	version 9
	syntax [anything(name=netname)][, mat matonly detail save(string asis) silent ]
	set more off
	nw_syntax `netname', max(100000)

	
	if "`detail'" != "" {
		local add "indg_central outdg_central dg_central transitivity reciprocity"
	}
	tempname memhold
	if `"`save'"' != "" {
		postfile `memhold' str20 name str10 directed id nodes minval maxval edges arcs density `add' using `"`save'"', replace
	}
	foreach onenet in `netname' {
		nwinf `onenet', `mat' `matonly' `detail' `silent'
		if `"`save'"' != "" {
			if "`r(directed)'" == "false" {
				if "`detail'" == "" {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (`r(edges)') (.) (`r(density)')
				}
				else {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (`r(edges)') (.) (`r(density)') (.) (.) (`r(dg_central)') (`r(transitivity)') (`r(reciprocity)')
				}
			}
			else {
				if "`detail'" == "" {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (.) (`r(arcs)') (`r(density)')
				}
				else {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (.) (`r(arcs)') (`r(density)') (`r(indg_central)') (`r(outdg_central)') (.) (`r(transitivity)') (`r(reciprocity)')
				}
			}
		}
	}
	
	if `"`save'"' != "" {
		postclose `memhold'
	}
end
	

capture program drop nwinf
program nwinf
	version 9
	syntax [anything(name=netname)], [id(string) mat matonly detail silent]
	nw_syntax `netname', max(1)
	local localdirected `directed'
	
	// BUGFIX: was `thisname' throughout - undefined anywhere in this
	// file (confirmed via grep), so it was always empty, and each of
	// these three calls silently fell back to operating on whichever
	// network happened to be CURRENT rather than the actual requested
	// target (`netname', captured by this program's own syntax line
	// above) - reciprocity/transitivity/centralization came back
	// silently wrong (matching the current network's own values, not
	// the target's) whenever the target wasn't already current. Basic
	// stats (nodes/arcs/density) were unaffected, since those don't go
	// through this block.
	if "`detail'" != "" {
		qui nwdyads `netname'
		local reciprocity = `r(reciprocity)'
		qui nwtriads `netname'
		local transitivity = `r(transitivity)'
		qui nwdegree `netname', silent
		if ("`localdirected'"=="false"){
			local central = `r(dg_central)'
		}
		else {
			local incentral = `r(indg_central)'
			local outcentral = `r(outdg_central)'
		}
	}
	
	mata: st_rclear()
	
	_nwname `netname'
	
	mata: st_global("r(name)", "`netname'")
	mata: st_global("r(netname)", "`netname'")
	mata: st_numscalar("r(minval)", `netobj'->get_minimum())
	mata: st_numscalar("r(maxval)", `netobj'->get_maximum())
	mata: st_global("r(mode2)", `netobj'->is_2mode())
	mata: st_global("r(valued)", `netobj'->is_valued())
	
	if (r(directed)=="false"){
		mata: st_numscalar("r(edges)", `netobj'->get_edges_count())
		mata: st_numscalar("r(edges_sum)", `netobj'->get_edges_sum())
		mata: st_numscalar("r(dg_central)", `central')
	}
	else {
		mata: st_numscalar("r(arcs)", `netobj'->get_arcs_count())
		mata: st_numscalar("r(arcs_value)", `netobj'->get_arcs_sum())
		mata: st_numscalar("r(indg_central)", `incentral')
		mata: st_numscalar("r(outdg_central)", `outcentral')
	}
	mata: st_numscalar("r(density)", `netobj'->get_density())
	mata: st_numscalar("r(transitivity)", `transitivity')
	mata: st_numscalar("r(reciprocity)", `reciprocity')
	mata: st_numscalar("r(nodes)", `netobj'->get_nodes())	
		
	if "`r(mode2)'" == "true" {
		mata: st_numscalar("r(nodes1)", `netobj'->get_nodes_mode1())
		mata: st_numscalar("r(nodes2)", `netobj'->get_nodes_mode2())
		mata: st_global("r(mode1_desc)", `netobj'->get_description_mode1())
		mata: st_global("r(mode2_desc)", `netobj'->get_description_mode2())
	}
	mata: st_global("r(provenance)", `netobj'->get_provenance())
	mata: st_global("r(temporal)", `netobj'->is_temporal())
	if "`r(temporal)'" == "true" {
		mata: st_global("r(temporaltype)", `netobj'->get_temporal_type())
	}

	if "`matonly'" == "" & "`silent'" == "" {
		di "{hline 50}"
		di "{txt}   Network name: {res} `r(name)'"
		di "{txt}   Network id: {res} `r(id)'"
		di "{txt}   Directed: {res}`r(directed)'"
		di "{txt}   Valued: {res}`r(valued)'"
		di "{txt}   Two-mode: {res}`r(mode2)'"
		di "{txt}   Nodes: {res}`r(nodes)'"
		if "`r(mode2)'" == "true" {
			di "{txt}      Level 1: {res}`r(nodes1)' {txt}(`r(mode1_desc)')" 
			di "{txt}      Level 2: {res}`r(nodes2)' {txt}(`r(mode2_desc)')"
		}
		di "{txt}   Selfloop: {res}`r(selfloop)'"
		if ("`r(selfloop)'" == "true") {
			di "{txt}    Number of selfloops: {res}`r(selfloops)'"
		}
		if (r(directed) == "false"){
			di "{txt}   Edges: {res}`r(edges)'"
		}
		if (r(directed) == "true"){
			di "{txt}   Arcs: {res}`r(arcs)'"
		}
		di "{txt}   Minimum value: {res} `=round(`r(minval)',0.001)'"
		di "{txt}   Maximum value: {res} `=round(`r(maxval)',0.001)'"
		di "{txt}   Density: {res} `=round(`r(density)',0.001)'"
		di "{txt}   Temporal: {res}`r(temporal)'"
		if "`r(temporal)'" == "true" {
			di "{txt}      Temporal type: {res}`r(temporaltype)'"
		}
		if `"`r(provenance)'"' != "" {
			di "{txt}   Provenance: {res} `r(provenance)'"
		}

		if "`detail'" != "" {
			di "{txt}   Reciprocity: {res} `=round(`r(reciprocity)',0.001)'"
			di "{txt}   Transitivity: {res} `=round(`r(transitivity)',0.001)'"
			if (r(directed) == "false"){
				di "{txt}   Degree centralization: {res}`=round(`r(dg_central)',0.001)'"
			}
			if (r(directed) == "true"){
				di "{txt}   Indegree centralization:: {res}`=round(`r(indg_central)',0.001)'"
				di "{txt}   Outdegree centralization:: {res}`=round(`r(outdg_central)',0.001)'"
			}
		}
	}
	
	if "`mat'`matonly'" !=""{
		mata: *`netobj'->get_matrix()
	}
end
