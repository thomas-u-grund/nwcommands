
capture program drop nwload
program nwload
	syntax [anything(name=netname)][, xvars overwrite labelonly force viewon viewoff nocurrent generate(string)]
	unw_defs
	_nwsyntax `netname', max(1)
	nwname `netname'

	if "`xvars'" != "" {
		_nwdatasync `netname'
		exit
	}
	
	if "`generate'" == "" {
		local generate "`nw_included'"
	}
	// maybe it is already a view
	mata: st_numscalar("r(isview)", isview(*`netobj'->get_matrix()))
	if (`r(isview)' == 1) {
		di "{txt}Network is already a view."
		exit
	}
	
	if (`r(nodes)' > 1000 & "`force'"=="") {
		local labelonly "labelonly"
	}
	
	if (`=`c(k)' + `r(nodes)'' >= `c(max_k_theory)'  & "`force'"=="") {
		local labelonly "labelonly"
	}
	
	if (`r(nodes)' > 1000 & "`force'" == "" & "`labelonly'" == "") {
		exit
	}
	
	if (`=`c(k)' + `r(nodes)'' >= `c(max_k_theory)' & "`force'" == "" & "`labelonly'" == "") {
		exit
	}

	// unconnect edge list from view to the dataset
	if "`viewoff'" != "" {
		_nwdatasync `netname'
		mata: `netobj'->set_edge(st_data((1::(`netobj'->get_nodes())), `netobj'->nodesvar))
	}
	
	// maybe it is already a view
	mata: st_numscalar("r(isview)", isview(*`netobj'->get_matrix()))
	if (`r(isview)' == 1) {
		_nwdatasync `netname'
		exit
	}
		
	// drop the variables used for the current network
	mata: `nws'.drop_current_nodesvar()
	
	// make network the current network
	// Per Stata's own [P] syntax convention for a "no"-prefixed toggle:
	// declaring `nocurrent' in the option list makes Stata define a
	// local named after the STEM - `current', not `nocurrent' - set to
	// the literal string "nocurrent" when the caller passes the
	// option, empty otherwise. `nocurrent' itself is never populated at
	// all, so checking it here always evaluated true regardless of
	// whether the option was passed (see nwbetween.ado/nwevcent.ado,
	// which had the identical bug - confirmed directly against a
	// minimal, isolated test program). Fixed to check `current' instead.
	if "`current'" == "" {
		mata: `nws'.make_current_from_name("`netname'")
	}
	
	_nwdatasync `netname', generate(`generate') `overwrite'
	
	if "`labelonly'" == "" {	
		mata: `nws'.generate_current_nodesvar()
		_nwsyntax `netname'
		mata: st_store((1::(`netobj'->get_nodes())),`netobj'->nodesvar,(*`netobj'->get_matrix())) 

		order `nw_nodename' 
		
		// connect edge matrix as view to dataset
		if "`viewon'" != "" {
			mata: st_view(`netobj'->edge, (1::(`netobj'->get_nodes())), `netobj'->nodesvar)
			di "{txt}(Adjacency matrix is now view on dataset)" 
		}
	}
	capture order  `nw_nodename' `nw_included'
end

capture mata: mata drop get_string_from_vector()
mata:
string scalar get_string_from_vector(string rowvector v){
	real scalar i
	string scalar s
	
	for(i = 1; i<= cols(v); i++){
		s = s + " " + v[i]
	}
	return(s)
}
end

