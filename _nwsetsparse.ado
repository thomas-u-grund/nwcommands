*! _nwsetsparse: create a network from a Mata list of ties (ego, alter, value) without an n x n matrix
*! The counterpart of "nwset, mat()" for large networks: same node labels, same data handling, same checks;
*! the ties are given as an (ties x 3) Mata matrix of node numbers and values. For an undirected network the
*! list holds each tie in both directions.
capture program drop _nwsetsparse
program _nwsetsparse
	syntax , TRIplets(string) NODes(integer) NAME(string) [NODENAMES(string) labs(string) undirected selfloop]

	unw_defs
	capture mata: `nw'
	if (_rc != 0) {
		mata: `nw' = nws_create()
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
		error `errNWsExists'
	}

	tempname __nwnodenames
	if `"`labs'"' != "" {
		mata: `__nwnodenames' = (get_nodenames_from_string(`"`labs'"', `nodes', "`cDftNodepref'"))'
	}
	else {
		mata: `__nwnodenames' = (J(`nodes',1,"`cDftNodepref'") + get_node_suffix(`nodes'))'
		if "`nodenames'" == "" {
			mata: `__nwnodenames' = nw_rowlabels_or(`__nwnodenames', "`nw_nodename'", `nws'.pdefs)
		}
	}
	mata: st_rclear()
	mata: `nws'.add("`name'")
	_nwsyntax `name'
	mata: `netobj'->create_by_name_sparse(`__nwnodenames')
	mata: `netobj'->set_name("`name'")
	mata: `netobj'->set_selfloop("`selfloop'" == "selfloop")
	mata: `netobj'->set_edge_from_triplets(`triplets'[.,1], `triplets'[.,2], `triplets'[.,3], "`undirected'" == "")
	mata: `netobj'->set_directed("`undirected'" == "")
	if "`nodenames'" != "" {
		mata: `netobj'->set_nodenames(`nodenames')
		mata: `netobj'->update_nodesvar()
	}
	if "`undirected'" != "" {
		nwsym `name'
	}
	mata: `netobj'->set_valued(`netobj'->check_valued())
	mata: nw_align_to_rows(`netobj', "`nw_nodename'", `nws'.pdefs)
	_nwdatasync
	capture mata: mata drop `__nwnodenames'
end
