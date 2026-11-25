
capture program drop nwload
program nwload
	syntax [anything(name=netname)][, xvars overwrite labelonly force viewon viewoff nocurrent generate(string) keepuser]
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
		
	// Variables that nwload creates carry the characteristic [nwload]; only
	// those are ever dropped. Any other variable with the name of a node is
	// the user's: it is not overwritten without option -overwrite-. One that
	// already holds exactly what nwload would write (a network declared from
	// variables with nwset varlist) is left as it is and stays the user's.
	// This is checked before anything is changed.
	// (Done in Mata: the list of node variables of a large network does
	// not fit in a macro.)
	capture mata: mata drop __nwl_keep
	mata: __nwl_keep = J(1, 0, "")
	if "`labelonly'" == "" & "`overwrite'" == "" {
		mata: __nwl_keep = _nwload_clash(`netobj', "`nw_nodename'")
		if `__nwl_nclash' > 0 & "`keepuser'" != "" {
			// (option of the commands that load a network for you, their option xvars: they carry on, and your
			// variables stay as they are)
			local __nwl_more ""
			if `__nwl_nclash' > 1 local __nwl_more " (and `=`__nwl_nclash'-1' more)"
			noisily di "{txt}{p 0 0 2}(note: variable {res:`__nwl_first'} already defined`__nwl_more'; your variables are kept and the network is not loaded into variables; {bf:nwload `netname', overwrite} loads it){p_end}"
			local labelonly "labelonly"
		}
		else if `__nwl_nclash' > 0 {
			local __nwl_more ""
			if `__nwl_nclash' > 1 local __nwl_more " (and `=`__nwl_nclash'-1' more)"
			di "{err}{p 0 0 2}variable `__nwl_first' already defined`__nwl_more'; nwload would overwrite it{p_end}"
			di "{err}    rename it, declare the network with other names ({bf:nwset ..., vars()}),"
			di "{err}    or specify option {bf:overwrite}"
			capture mata: mata drop __nwl_keep
			exit 110
		}
	}

	// drop the variables of the network loaded before (only one network
	// is loaded at a time). Exact names only: -capture drop- alone would
	// also delete a user's variable that a name abbreviates. Say so when
	// another network's variables are replaced.
	local __nwl_target "`netname'"
	mata: st_local("__nwl_prev", `nws'.get_current_name())
	local __nwl_dropped 0
	if "`__nwl_prev'" != "" {
		_nwsyntax `__nwl_prev'
		mata: st_local("__nwl_dropped", strofreal(_nwload_dropall(`netobj'->get_nodesvar(), __nwl_keep)))
		// _nwsyntax resets the caller's netname and netobj
		_nwsyntax `__nwl_target'
		local netname "`__nwl_target'"
	}
	if `__nwl_dropped' & "`__nwl_prev'" != "`netname'" {
		di "{txt}{p 0 0 2}(variables of network {res:`__nwl_prev'} dropped; nwload loads one network at a time){p_end}"
	}

	// the variables of this network that are written anew: copies that
	// nwload made before, and with -overwrite- every variable of these names
	if "`labelonly'" == "" {
		if "`overwrite'" == "" mata: (void) _nwload_dropall(`netobj'->get_nodesvar(), __nwl_keep)
		else mata: _nwload_dropany(`netobj'->get_nodesvar())
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
		// (the variables in __nwl_keep hold these values already and are left alone)
		mata: _nwload_store(`netobj', __nwl_keep)
		mata: _nwload_mark(`netobj'->nodesvar, "`netname'", __nwl_keep)

		order `nw_nodename' 
		if "`istemporal'" == "true" {
			di "{txt}{p 0 0 2}(note: network {bf:`netname'} is temporal; the variables hold its ties aggregated over all times. {bf:nwtoedge `netname', time} lists the times.){p_end}"
		}
		
		// connect edge matrix as view to dataset
		if "`viewon'" != "" {
			mata: st_view(`netobj'->edge, (1::(`netobj'->get_nodes())), `netobj'->nodesvar)
			di "{txt}(Adjacency matrix is now view on dataset)" 
		}
	}
	capture order  `nw_nodename' `nw_included'
	capture mata: mata drop __nwl_keep
	capture confirm number 0
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
capture mata: mata drop _nwload_dropany()
capture mata: mata drop _nwload_clash()
capture mata: mata drop _nwload_same()
capture mata: mata drop _nwload_mark()
capture mata: mata drop _nwload_store()
mata:
// Variables that nwload creates carry the characteristic [nwload] (the
// network's name), so that they can be told from variables of the user
// that happen to have a node's name, also after some were renamed.
// Drop the existing variables among v that carry the mark (but not those
// in keep); 1 if any.
real scalar _nwload_dropall(string rowvector v, string rowvector keep)
{
	real scalar i
	string rowvector d
	d = J(1, 0, "")
	for (i = 1; i <= cols(v); i++) {
		if (_st_varindex(v[i]) != .) {
			if (st_global(v[i] + "[nwload]") != "" & !anyof(keep, v[i])) d = (d, v[i])
		}
	}
	if (cols(d) == 0) return(0)
	st_dropvar(d)
	return(1)
}
// drop every existing variable among v (option overwrite)
void _nwload_dropany(string rowvector v)
{
	real scalar i
	for (i = 1; i <= cols(v); i++) {
		if (_st_varindex(v[i]) != .) st_dropvar(v[i])
	}
}
// Node variables of network p that exist without the mark. Those that hold
// the network's own values are returned; the others are counted (local
// __nwl_nclash, with the first name in __nwl_first).
string rowvector _nwload_clash(pointer(class nw_def scalar) scalar p, string scalar nodevar)
{
	real scalar i, n
	string scalar first
	string rowvector v, same
	real rowvector cand
	v = p->get_nodesvar()
	cand = J(1, 0, .)
	for (i = 1; i <= cols(v); i++) {
		if (_st_varindex(v[i]) != .) {
			if (st_global(v[i] + "[nwload]") == "") cand = (cand, i)
		}
	}
	same = J(1, 0, "")
	n = 0
	first = ""
	if (cols(cand) > 0) {
		same = _nwload_same(p, nodevar, cand)
		for (i = 1; i <= cols(cand); i++) {
			if (!anyof(same, v[cand[i]])) {
				n++
				if (first == "") first = v[cand[i]]
			}
		}
	}
	st_local("__nwl_nclash", strofreal(n))
	st_local("__nwl_first", first)
	return(same)
}
// The variables (columns cand of the node variables of p) that hold the
// column of the adjacency matrix in the rows of the nodes (found by the
// node names in nodevar; by position when that variable is blank or
// absent) and are missing in every other row.
string rowvector _nwload_same(pointer(class nw_def scalar) scalar p, string scalar nodevar, real rowvector cand)
{
	real scalar i, j, k, n, named
	real matrix M
	real colvector rowof, x, other, ok
	string colvector id
	string rowvector v, nm, same
	transmorphic A

	v = p->get_nodesvar()
	nm = p->get_nodenames()
	n = cols(nm)
	same = J(1, 0, "")
	if (cols(v) != n | st_nobs() < n | n == 0) return(same)
	for (k = 1; k <= cols(cand); k++) {
		if (!st_isnumvar(v[cand[k]])) return(same)
	}
	rowof = (1::n)
	named = 0
	if (_st_varindex(nodevar) != .) {
		if (st_isstrvar(nodevar)) {
			id = st_sdata(., nodevar)
			named = any(id :!= "")
		}
	}
	if (named) {
		A = asarray_create()
		for (i = 1; i <= rows(id); i++) {
			if (id[i] != "") {
				// a name in two rows: asarray keeps 0, which no node may have
				if (asarray_contains(A, id[i])) asarray(A, id[i], 0)
				else asarray(A, id[i], i)
			}
		}
		for (i = 1; i <= n; i++) {
			if (!asarray_contains(A, nm[i])) return(same)
			rowof[i] = asarray(A, nm[i])
			if (rowof[i] == 0) return(same)
		}
	}
	M = *(p->get_matrix())
	if (rows(M) != n | cols(M) != n) return(same)
	other = J(st_nobs(), 1, 1)
	other[rowof] = J(n, 1, 0)
	for (k = 1; k <= cols(cand); k++) {
		j = cand[k]
		x = st_data(., v[j])
		if (any(other :& (x :< .))) continue
		x = x[rowof]
		ok = (x :== M[., j]) :| (x :== floatround(M[., j]))
		// without self-loops the diagonal holds no tie: 0 or missing
		if (!(p->is_selfloop() == "true")) ok[j] = (x[j] == 0 | x[j] >= .)
		if (all(ok)) same = (same, v[j])
	}
	return(same)
}
// write the adjacency matrix into the node variables, except those in keep
void _nwload_store(pointer(class nw_def scalar) scalar p, string rowvector keep)
{
	real scalar i
	real rowvector cols_w
	string rowvector v
	real matrix M

	v = p->get_nodesvar()
	if (cols(keep) == 0) {
		st_store((1::(p->get_nodes())), v, *(p->get_matrix()))
		return
	}
	cols_w = J(1, 0, .)
	for (i = 1; i <= cols(v); i++) {
		if (!anyof(keep, v[i])) cols_w = (cols_w, i)
	}
	if (cols(cols_w) == 0) return
	M = *(p->get_matrix())
	st_store((1::(p->get_nodes())), v[cols_w], M[., cols_w])
}
void _nwload_mark(string rowvector v, string scalar name, string rowvector keep)
{
	real scalar i
	for (i = 1; i <= cols(v); i++) {
		if (_st_varindex(v[i]) != . & !anyof(keep, v[i])) st_global(v[i] + "[nwload]", name)
	}
}
end

