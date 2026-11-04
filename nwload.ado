
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
	mata: st_numscalar("r(isview)", `netobj'->is_dense_built() ? isview(*`netobj'->get_matrix()) : 0)
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
	mata: st_numscalar("r(isview)", `netobj'->is_dense_built() ? isview(*`netobj'->get_matrix()) : 0)
	if (`r(isview)' == 1) {
		_nwdatasync `netname'
		exit
	}
		
	// drop the variables of the network loaded before (only one network
	// is loaded at a time). Exact names only: -capture drop- alone would
	// also delete a user's variable that a name abbreviates. The previous
	// network counts as loaded only when all of its node variables are
	// there; a single variable that happens to carry a node's name belongs
	// to the user. Say so when another network's variables are replaced,
	// which used to happen silently. (Done in Mata: the list of node
	// variables of a large network does not fit in a macro.)
	local __nwl_target "`netname'"
	mata: st_local("__nwl_prev", `nws'.get_current_name())
	local __nwl_dropped 0
	if "`__nwl_prev'" != "" {
		_nwsyntax `__nwl_prev'
		mata: st_local("__nwl_dropped", strofreal(_nwload_dropall(`netobj'->get_nodesvar())))
		// _nwsyntax resets the caller's netname and netobj
		_nwsyntax `__nwl_target'
		local netname "`__nwl_target'"
	}
	if `__nwl_dropped' & "`__nwl_prev'" != "`netname'" {
		di "{txt}(variables of network {res:`__nwl_prev'} dropped; nwload loads one network at a time)"
	}

	// a variable that is not part of a loaded network but has the name of
	// one of this network's node variables would be overwritten silently
	if "`labelonly'" == "" & "`overwrite'" == "" {
		mata: _nwload_clash(`netobj'->get_nodesvar())
		if `__nwl_nclash' > 0 {
			di "{err}variable `__nwl_first' already defined" _c
			if `__nwl_nclash' > 1 di "{err} (and `=`__nwl_nclash'-1' more)" _c
			di "{err}; nwload would overwrite it"
			di "{err}    rename it, declare the network with other names ({bf:nwset ..., vars()}),"
			di "{err}    or specify option {bf:overwrite}"
			exit 110
		}
	}

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


capture mata: mata drop _nwload_dropall()
capture mata: mata drop _nwload_clash()
mata:
// drop the variables v when all of them exist (exact names); 1 if dropped
real scalar _nwload_dropall(string rowvector v)
{
	real scalar i
	if (cols(v) == 0) return(0)
	for (i = 1; i <= cols(v); i++) {
		if (_st_varindex(v[i]) == .) return(0)
	}
	st_dropvar(v)
	return(1)
}
// number of existing variables among v (exact names) and the first one
void _nwload_clash(string rowvector v)
{
	real scalar i, n
	string scalar first
	n = 0
	first = ""
	for (i = 1; i <= cols(v); i++) {
		if (_st_varindex(v[i]) != .) {
			n++
			if (first == "") first = v[i]
		}
	}
	st_local("__nwl_nclash", strofreal(n))
	st_local("__nwl_first", first)
}
end
