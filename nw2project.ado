
capture program drop nw2project
program nw2project, rclass
	version 12
	syntax [anything(name=netname)], PROJECT(integer) [name(string) stat(string) xvars replace]

	if `project' != 1 & `project' != 2 {
		di "{err}project() must be 1 or 2"
		error 198
	}

	local stat = lower("`stat'")
	if "`stat'" == "" {
		local stat "minmax"
	}
	_opts_oneof "min max minmax sum mean count binary jaccard cosine" "stat" "`stat'" 6556

	nw_syntax `netname'

	if "`is2mode'" != "true" {
		di "{err}Network {bf:`netname'} is not a two-mode network; nw2project requires a two-mode network (see {help nw2set})."
		error 198
	}

	if "`name'" == "" {
		local name "project"
	}
	// replace, when given, reuses the exact requested name (drop then
	// recreate) rather than silently auto-incrementing to a different one.
	// nwvalidate's own r(validname) auto-increments unconditionally on a
	// name collision; unconditionally taking it (as this line used to)
	// meant replace never actually replaced anything - name was already
	// switched to the incremented name before the "if replace" block
	// below even ran, so that block dropped a network that was never
	// going to be reused anyway. Found and fixed while building
	// nwsimindex, which had copied this same pattern - see its own
	// docs/CERTIFICATION.md entry.
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

	tempname __nw_names __nw_edges

	mata: `__nw_names' = nw2project_names(`netobj', `project')
	mata: `__nw_edges' = nw2project_edges(`netobj', `project', "`stat'")

	mata: st_numscalar("nodes", cols(`__nw_names'))
	mata: st_numscalar("ties", rows(`__nw_edges'))

	// captured from the SOURCE network's own netobj before it is
	// reassigned to the newly-created projected network below - a
	// projected network otherwise records no trace of what it was
	// projected from the moment nw2project returns (Part 4/roadmap
	// provenance gap).
	local srcname "`netname'"
	mata: st_local("srcmodedesc", `project' == 1 ? `netobj'->get_description_mode1() : `netobj'->get_description_mode2())
	// deliberately no literal apostrophes/quotes around `srcname' below
	// (an earlier version wrote "network '`srcname''") - a literal
	// embedded apostrophe survives one round of compound-quoting but
	// corrupts the string once it passes through further macro
	// re-expansion (nwname forwarding its full `0' to _nwname), found
	// via a direct probe: the provenance note silently truncated mid-
	// string and even clobbered unrelated option text following it.
	local provnote "projected from network `srcname', mode `project'"
	if "`srcmodedesc'" != "" {
		local provnote "`provnote' (`srcmodedesc')"
	}
	local provnote "`provnote', stat=`stat'"

	mata: nw.nws.add("`name'")
	nw_syntax `name'
	mata: `netobj'->create_by_name_sparse(`__nw_names')
	// BUGFIX: create_by_name_sparse() calls zap() internally (wiping
	// every field, including `name', back to blank - see its own header
	// comment in unw_core.do), and nothing here re-set it afterward, so
	// the projected network's own internal name field stayed blank even
	// though nw.nws's separate container-level name list correctly said
	// "`name'" existed. Explicit-netname code paths never noticed
	// (they resolve names via the container list, not this field), but
	// any *bare*/"current network" code path does read this field
	// directly (pcurrent->get_name()) - confirmed via a direct probe:
	// nwsave's own internal bare nwload call crashed with "subscript
	// invalid" trying to index pdefs[0] after get_index_of_current()
	// silently found no match. nwset.ado's own create_by_name() call
	// (the dense sibling of this sparse method) already re-sets the
	// name immediately afterward for exactly this reason - mirrored here.
	mata: `netobj'->set_name("`name'")
	mata: `netobj'->set_directed(0)
	mata: `netobj'->set_edge_from_triplets(`__nw_edges'[.,1], `__nw_edges'[.,2], `__nw_edges'[.,3], 0)
	mata: `netobj'->set_valued(1)
	mata: `netobj'->set_provenance(`"`provnote'"')

	mata: mata drop `__nw_names' `__nw_edges'

	return scalar nodes = nodes
	return scalar ties = ties

	di "{hline 40}"
	di "{txt}  Projected network: {res}`name'"
	di "{txt}  Level: {res}`project'"
	// A bare local-macro-style reference to r(nodes) here would treat
	// "r(nodes)" as a LOCAL MACRO NAME to look up, not an r-class scalar
	// reference, so it silently expands to "" (Stata does not error on an
	// undefined local) - that was the original bug. An expression-
	// substitution reference to r(nodes) is not the fix either: a
	// "return scalar" statement only PUBLISHES r() to the caller when
	// this program actually exits, so r(nodes) reads as missing from
	// inside the same program body that just set it (confirmed via an
	// isolated repro before settling on this fix - a subtlety worth
	// remembering). The underlying Stata scalars "nodes"/"ties" set via
	// st_numscalar() above ARE immediately readable within this scope, so
	// reference those directly instead of the not-yet-published
	// r()-result.
	di "{txt}  Nodes: {res}`=nodes'"
	di "{txt}  Ties: {res}`=ties'"

	if "`xvars'" != "" {
		nwload `name'
	}
end

capture mata: mata drop nw2project_sel()
capture mata: mata drop nw2project_names()
capture mata: mata drop nw2project_edges()
capture mata: mata drop nw2project_edges_dense()
capture mata: mata drop nw2project_edges_sparse()
mata:

/*
	Global node indices (column vector, 1..n) of the nodes at the requested
	two-mode level. modes is a string ROW vector, so selectindex() (which
	preserves input orientation) returns a row vector too - transposed here
	to the column-vector convention nw2project_edges() indexes throughout.
*/
real matrix nw2project_sel(pointer(class nw_def scalar) scalar p, real scalar level){
	return(selectindex(p->get_modes() :== strofreal(level))')
}

string rowvector nw2project_names(pointer(class nw_def scalar) scalar p, real scalar level){
	real matrix sel
	sel = nw2project_sel(p, level)
	return(p->get_nodenames()[1, sel'])
}

/*
	Standard bipartite-projection algorithm: for each selected-level node i,
	visit its other-level neighbors q; for each q, visit q's same-level
	neighbors j (i's "co-members" via q) and accumulate the requested
	statistic over every (i,j) pair that shares at least one such q.
	Complexity is O(sum_i deg(i) * avg_deg(neighbor)) - the standard,
	expected cost for this algorithm (same as igraph/NetworkX bipartite
	projection), not O(n^2): a sparse affiliation network yields a cheap
	projection regardless of how many total nodes exist at the far level.
	Returns an nout x 3 (ego_local, alter_local, weight) matrix using local
	1..nsel indices into nw2project_names()'s output, symmetric (each pair
	appears twice, (a,b) and (b,a)) since a projection is always undirected.

	DISPATCH: the neighbor-walk above accumulates six statistics per
	*visited* (oa,ob) pair, but where those accumulators live matters a
	lot at scale. Below dispatches on nsel (the number of selected-level
	nodes, not the total network size) between two accumulator strategies
	- see nw2project_edges_dense()/_sparse()'s own headers for why neither
	one is a strict improvement on the other:
	  - DENSE (six nsel x nsel matrices, direct array indexing): fast per
	    access, but memory cost is a hard O(nsel^2) regardless of how many
	    pairs actually end up co-occurring - unsafe once nsel gets large
	    (6 * 10,000^2 * 8 bytes = 4.8GB).
	  - SPARSE (one Mata associative array keyed on the pair): memory and
	    final-collection cost track the number of actually co-occurring
	    pairs, not nsel^2, but each access costs a hash lookup plus a
	    fresh row-vector allocation - measured directly to be roughly 40%
	    SLOWER than the dense path on a benchmark scenario with a small
	    nsel (1,000) and a near-complete projection (999,000 of a possible
	    999,000 ties): 292.23s sparse vs 205.94s dense, same data, same
	    machine. The sparse path exists for the opposite regime the dense
	    path can't safely reach at all (large nsel, sparse co-occurrence,
	    the case this whole function's own header comment above assumes)
	    - not to replace the dense path.
	NSEL_DENSE_LIMIT is chosen so the dense path's own worst-case memory
	(6 * NSEL_DENSE_LIMIT^2 * 8 bytes) stays under ~500MB.
*/
real matrix nw2project_edges(pointer(class nw_def scalar) scalar p, real scalar level, string scalar stat){
	real scalar nsel, NSEL_DENSE_LIMIT

	nsel = rows(nw2project_sel(p, level))
	NSEL_DENSE_LIMIT = 3000

	if (nsel <= NSEL_DENSE_LIMIT){
		return(nw2project_edges_dense(p, level, stat))
	}
	else {
		return(nw2project_edges_sparse(p, level, stat))
	}
}

real matrix nw2project_edges_dense(pointer(class nw_def scalar) scalar p, real scalar level, string scalar stat){
	real scalar nsel, valued, oa, ob, oi, oq, k, l, wiq, wjq, thismin, val, nout
	real matrix sel, localidx, nb, nb2, degvec
	real matrix minval, maxval, sumval, cntval, minmaxval, sharedcount
	real matrix ego_tmp, alter_tmp, weight_tmp, out

	sel = nw2project_sel(p, level)
	nsel = rows(sel)
	valued = p->is_valued_boolean()

	localidx = J(p->get_nodes(), 1, 0)
	for (oa=1; oa<=nsel; oa++){
		localidx[sel[oa,1], 1] = oa
	}

	minval = J(nsel, nsel, .)
	maxval = J(nsel, nsel, .)
	minmaxval = J(nsel, nsel, .)
	sumval = J(nsel, nsel, 0)
	cntval = J(nsel, nsel, 0)
	sharedcount = J(nsel, nsel, 0)
	// far-level (affiliation) degree of each selected node - the shared
	// set of neighbors visited below is the same "other mode" set this
	// counts, so both jaccard's union term and cosine's normalizer reuse
	// exactly the same neighbor lists nw2project_edges already builds,
	// not a second pass over the network.
	degvec = J(nsel, 1, 0)

	for (oa=1; oa<=nsel; oa++){
		oi = sel[oa,1]
		nb = p->neighbors(oi)
		degvec[oa,1] = rows(nb)
		for (k=1; k<=rows(nb); k++){
			oq = nb[k,1]
			wiq = p->edge_weight(oi, oq)
			nb2 = p->neighbors(oq)
			for (l=1; l<=rows(nb2); l++){
				ob = localidx[nb2[l,1], 1]
				if (ob > oa){
					wjq = p->edge_weight(nb2[l,1], oq)
					sharedcount[oa,ob] = sharedcount[oa,ob] + 1
					sumval[oa,ob] = sumval[oa,ob] + wiq + wjq
					cntval[oa,ob] = cntval[oa,ob] + 2
					if (minval[oa,ob] == . | wiq < minval[oa,ob]) minval[oa,ob] = wiq
					if (minval[oa,ob] == . | wjq < minval[oa,ob]) minval[oa,ob] = wjq
					if (maxval[oa,ob] == . | wiq > maxval[oa,ob]) maxval[oa,ob] = wiq
					if (maxval[oa,ob] == . | wjq > maxval[oa,ob]) maxval[oa,ob] = wjq
					thismin = min((wiq,wjq))
					if (minmaxval[oa,ob] == . | thismin > minmaxval[oa,ob]) minmaxval[oa,ob] = thismin
				}
			}
		}
	}

	ego_tmp = J(nsel*nsel, 1, 0)
	alter_tmp = J(nsel*nsel, 1, 0)
	weight_tmp = J(nsel*nsel, 1, 0)
	nout = 0

	for (oa=1; oa<=nsel; oa++){
		for (ob=(oa+1); ob<=nsel; ob++){
			if (sharedcount[oa,ob] > 0){
				// count/binary/jaccard/cosine are pure shared-neighbor-
				// structure statistics - defined the same way whether the
				// source network is valued or not (unlike min/max/sum/
				// mean/minmax, which only make sense on tie *values* and
				// so keep falling back to the plain shared count on an
				// unvalued source, exactly as before). Checked first so a
				// valued network can still request them explicitly.
				if (stat == "count"){
					val = sharedcount[oa,ob]
				}
				else if (stat == "binary"){
					val = 1
				}
				else if (stat == "jaccard"){
					val = sharedcount[oa,ob] / (degvec[oa,1] + degvec[ob,1] - sharedcount[oa,ob])
				}
				else if (stat == "cosine"){
					val = sharedcount[oa,ob] / sqrt(degvec[oa,1] * degvec[ob,1])
				}
				else if (!valued){
					val = sharedcount[oa,ob]
				}
				else if (stat == "min"){
					val = minval[oa,ob]
				}
				else if (stat == "max"){
					val = maxval[oa,ob]
				}
				else if (stat == "sum"){
					val = sumval[oa,ob]
				}
				else if (stat == "mean"){
					val = sumval[oa,ob] / cntval[oa,ob]
				}
				else {
					val = minmaxval[oa,ob]
				}
				nout = nout + 1
				ego_tmp[nout,1] = oa
				alter_tmp[nout,1] = ob
				weight_tmp[nout,1] = val
				nout = nout + 1
				ego_tmp[nout,1] = ob
				alter_tmp[nout,1] = oa
				weight_tmp[nout,1] = val
			}
		}
	}

	if (nout == 0){
		return(J(0,3,0))
	}
	out = J(nout,3,0)
	out[.,1] = ego_tmp[(1::nout),1]
	out[.,2] = alter_tmp[(1::nout),1]
	out[.,3] = weight_tmp[(1::nout),1]
	return(out)
}

/*
	Same algorithm and identical statistic definitions as
	nw2project_edges_dense() (see nw2project_edges()'s own dispatch-header
	comment above for why this variant exists at all) - the six
	nsel x nsel dense accumulator matrices are replaced with a single
	Mata associative array (asarray()) keyed on the pair (oa,ob), oa<ob,
	each value a 1x6 row vector holding (sharedcount, minval, maxval,
	sumval, cntval, minmaxval) for that pair. Both the accumulation loop
	and the final collection loop below now cost proportional to the
	number of pairs that actually co-occur (asarray_elements(AS)), not
	nsel^2 - the right tradeoff once nsel is large enough that the dense
	path's own O(nsel^2) memory footprint becomes unsafe, on the
	(documented, see this function's own header) assumption that a
	two-mode network with that many selected-level nodes has a genuinely
	sparse - not near-complete - projection.
*/
real matrix nw2project_edges_sparse(pointer(class nw_def scalar) scalar p, real scalar level, string scalar stat){
	real scalar nsel, valued, oa, ob, oi, oq, k, l, wiq, wjq, thismin, val, nout, nkeys, kk
	real matrix sel, localidx, nb, nb2, degvec
	real matrix ego_tmp, alter_tmp, weight_tmp, out, keys, statvec
	transmorphic AS

	sel = nw2project_sel(p, level)
	nsel = rows(sel)
	valued = p->is_valued_boolean()

	localidx = J(p->get_nodes(), 1, 0)
	for (oa=1; oa<=nsel; oa++){
		localidx[sel[oa,1], 1] = oa
	}

	AS = asarray_create("real", 2)

	// far-level (affiliation) degree of each selected node - the shared
	// set of neighbors visited below is the same "other mode" set this
	// counts, so both jaccard's union term and cosine's normalizer reuse
	// exactly the same neighbor lists this function already builds, not
	// a second pass over the network.
	degvec = J(nsel, 1, 0)

	for (oa=1; oa<=nsel; oa++){
		oi = sel[oa,1]
		nb = p->neighbors(oi)
		degvec[oa,1] = rows(nb)
		for (k=1; k<=rows(nb); k++){
			oq = nb[k,1]
			wiq = p->edge_weight(oi, oq)
			nb2 = p->neighbors(oq)
			for (l=1; l<=rows(nb2); l++){
				ob = localidx[nb2[l,1], 1]
				if (ob > oa){
					wjq = p->edge_weight(nb2[l,1], oq)
					if (asarray_contains(AS, (oa,ob))){
						statvec = asarray(AS, (oa,ob))
					}
					else {
						statvec = (0, ., ., 0, 0, .)
					}
					statvec[1] = statvec[1] + 1
					statvec[4] = statvec[4] + wiq + wjq
					statvec[5] = statvec[5] + 2
					if (statvec[2] == . | wiq < statvec[2]) statvec[2] = wiq
					if (statvec[2] == . | wjq < statvec[2]) statvec[2] = wjq
					if (statvec[3] == . | wiq > statvec[3]) statvec[3] = wiq
					if (statvec[3] == . | wjq > statvec[3]) statvec[3] = wjq
					thismin = min((wiq,wjq))
					if (statvec[6] == . | thismin > statvec[6]) statvec[6] = thismin
					asarray(AS, (oa,ob), statvec)
				}
			}
		}
	}

	nkeys = asarray_elements(AS)
	if (nkeys == 0){
		return(J(0,3,0))
	}
	keys = asarray_keys(AS)

	ego_tmp = J(nkeys*2, 1, 0)
	alter_tmp = J(nkeys*2, 1, 0)
	weight_tmp = J(nkeys*2, 1, 0)
	nout = 0

	for (kk=1; kk<=nkeys; kk++){
		oa = keys[kk,1]
		ob = keys[kk,2]
		statvec = asarray(AS, (oa,ob))
		// count/binary/jaccard/cosine are pure shared-neighbor-
		// structure statistics - defined the same way whether the
		// source network is valued or not (unlike min/max/sum/
		// mean/minmax, which only make sense on tie *values* and
		// so keep falling back to the plain shared count on an
		// unvalued source, exactly as before). Checked first so a
		// valued network can still request them explicitly.
		if (stat == "count"){
			val = statvec[1]
		}
		else if (stat == "binary"){
			val = 1
		}
		else if (stat == "jaccard"){
			val = statvec[1] / (degvec[oa,1] + degvec[ob,1] - statvec[1])
		}
		else if (stat == "cosine"){
			val = statvec[1] / sqrt(degvec[oa,1] * degvec[ob,1])
		}
		else if (!valued){
			val = statvec[1]
		}
		else if (stat == "min"){
			val = statvec[2]
		}
		else if (stat == "max"){
			val = statvec[3]
		}
		else if (stat == "sum"){
			val = statvec[4]
		}
		else if (stat == "mean"){
			val = statvec[4] / statvec[5]
		}
		else {
			val = statvec[6]
		}
		nout = nout + 1
		ego_tmp[nout,1] = oa
		alter_tmp[nout,1] = ob
		weight_tmp[nout,1] = val
		nout = nout + 1
		ego_tmp[nout,1] = ob
		alter_tmp[nout,1] = oa
		weight_tmp[nout,1] = val
	}

	out = J(nout,3,0)
	out[.,1] = ego_tmp[(1::nout),1]
	out[.,2] = alter_tmp[(1::nout),1]
	out[.,3] = weight_tmp[(1::nout),1]
	return(out)
}
end
