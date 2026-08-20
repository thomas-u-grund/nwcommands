cscript

do unw_core.do

/*
	Sparse-backend Commit 7: NWdef::set_edge_from_triplets() builds the
	CSR/CSC index directly from an edge triplet list, WITHOUT ever
	allocating the N x N `edge' matrix - the actual fix for the O(N^2)
	creation bottleneck identified in this session's architecture report
	(nwfromedge.ado's make_matrix(), which unconditionally allocates
	J(nodes,nodes,0) regardless of edge count). NWdef::ensure_dense_built()
	then lazily materializes `edge' on first genuine demand (any
	get_matrix*() call), guarded by nw_max_dense_nodes (unw_defs.ado) with
	an informative error above it rather than silently exhausting memory -
	so every existing dense-matrix-consuming command keeps working
	unchanged on a sparse-natively-built network up to that size, and
	commands that only ever use the sparse-native accessors (neighbors(),
	degree(), calculate_components(), etc.) can operate on networks with no
	such limit at all, per this test's third case.
*/

// small network: sparse construction, then forced dense materialization
// must reproduce the same adjacency exactly.
nwclear
nwset, mat(J(2,2,0)) name(trip) directed labs(N1,N2)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("trip")]
p->create_by_name(("A","B","C","D","E","F"))
ego = (1\1\2\3\4\4\5)
alter = (2\3\3\4\5\6\6)
weight = (1\1\1\1\1\1\1)
p->set_edge_from_triplets(ego, alter, weight, 1)
st_numscalar("r(dense_before)", p->edge_dense_built)
st_numscalar("r(el_rows)", rows(p->edgelist()))
st_numscalar("r(deg1)", p->degree(1))
st_numscalar("r(degin3)", p->degree_in(3))
st_numscalar("r(he46)", p->has_edge(4,6))
st_numscalar("r(he64)", p->has_edge(6,4))
m = *p->get_matrix()
st_numscalar("r(dense_after)", p->edge_dense_built)
st_numscalar("r(m12)", m[1,2])
st_numscalar("r(m23)", m[2,3])
st_numscalar("r(msum)", sum(m :!= 0 :& m :!= .))
comp = p->calculate_components()
st_numscalar("r(ncomp)", max(comp))
end
assert r(dense_before) == 0
assert r(el_rows) == 7
assert r(deg1) == 2
assert r(degin3) == 2
assert r(he46) == 1
assert r(he64) == 0
assert r(dense_after) == 1
assert r(m12) == 1
assert r(m23) == 1
assert r(msum) == 7
assert r(ncomp) == 1

// zero-edge triplet build: must not error, must materialize an all-zero
// dense matrix on demand.
nwclear
nwset, mat(J(2,2,0)) name(empty) directed labs(N1,N2)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("empty")]
p->create_by_name(("X","Y","Z"))
p->set_edge_from_triplets(J(0,1,0), J(0,1,0), J(0,1,0), 1)
st_numscalar("r(deg1)", p->degree(1))
st_numscalar("r(elrows)", rows(p->edgelist()))
m = *p->get_matrix()
st_numscalar("r(msum)", sum(m :!= 0 :& m :!= .))
end
assert r(deg1) == 0
assert r(elrows) == 0
assert r(msum) == 0

// large network (25,000 nodes, above nw_max_dense_nodes=20,000): sparse
// accessors must work with the dense matrix never built; forcing
// materialization must fail with the documented informative error, not a
// silent multi-gigabyte allocation attempt.
nwclear
nwset, mat(J(2,2,0)) name(bignet) directed labs(N1,N2)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("bignet")]
p->create_by_name("n" :+ strofreal((1..25000)))
ego = (1::25000)
alter = (2::25001)
alter[25000,1] = 1
weight = J(25000,1,1)
p->set_edge_from_triplets(ego, alter, weight, 1)
st_numscalar("r(dense)", p->edge_dense_built)
st_numscalar("r(deg1)", p->degree(1))
end
assert r(dense) == 0
assert r(deg1) == 1
capture mata: m = *nw.nws.pdefs[nw.nws.get_index_of("bignet")]->get_matrix()
assert _rc == 484
