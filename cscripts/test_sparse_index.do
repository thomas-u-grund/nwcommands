cscript

do unw_core.do

/*
	Sparse-index regression test (nwcommands sparse-backend migration,
	Commit 1/2). Verifies the new NWdef sparse accessors (neighbors(),
	neighbors_in(), degree(), degree_in(), has_edge(), edge_weight(),
	edgelist()) against dense-matrix ground truth across the cases flagged
	as gaps in the architecture report (self-loops, empty network, complete
	graph), plus cache-invalidation behavior and a dual-mode proof that a
	BFS written purely against neighbors() reproduces calculate_components()
	exactly - the concrete precondition for migrating calculate_components()
	itself in Commit 3.
*/

capture mata: mata drop bfs_components()
mata:
real matrix bfs_components(pointer(class nw_def scalar) scalar p){
	real scalar n, ncomp, start, cur, j, qn
	real matrix visited, comp, queue, nb

	n = p->get_nodes()
	visited = J(n,1,0)
	comp = J(n,1,0)
	ncomp = 0

	for (start=1; start<=n; start++){
		if (visited[start,1]==0){
			ncomp = ncomp + 1
			queue = start
			visited[start,1] = 1
			comp[start,1] = ncomp
			while (rows(queue) > 0){
				cur = queue[1,1]
				qn = rows(queue)
				if (qn > 1){
					queue = queue[(2::qn),1]
				}
				else {
					queue = J(0,1,0)
				}
				nb = p->neighbors(cur)
				for (j=1; j<=rows(nb); j++){
					if (visited[nb[j,1],1]==0){
						visited[nb[j,1],1] = 1
						comp[nb[j,1],1] = ncomp
						queue = queue \ nb[j,1]
					}
				}
			}
		}
	}
	return(comp)
}
end

// --- directed, weighted: neighbors/degree/has_edge/edge_weight/edgelist vs dense truth ---
nwclear
nwset, mat((0,4,0,0\0,0,2,0\0,0,0,1\3,0,0,0)) name(dirnet) directed labs(A,B,C,D)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("dirnet")]
match_out = J(1,4,.)
match_in  = J(1,4,.)
for (i=1;i<=4;i++){
	dense_out = selectindex((*p->get_matrix())[i,.] :!= 0 :& (*p->get_matrix())[i,.] :!= .)'
	dense_in  = selectindex((*p->get_matrix())[.,i]' :!= 0 :& (*p->get_matrix())[.,i]' :!= .)'
	match_out[1,i] = (sort(p->neighbors(i),1) == sort(dense_out,1)) & (p->degree(i)==rows(dense_out))
	match_in[1,i]  = (sort(p->neighbors_in(i),1) == sort(dense_in,1)) & (p->degree_in(i)==rows(dense_in))
}
st_numscalar("r(out_ok)", min(match_out))
st_numscalar("r(in_ok)", min(match_in))
st_numscalar("r(he12)", p->has_edge(1,2))
st_numscalar("r(he21)", p->has_edge(2,1))
st_numscalar("r(w12)", p->edge_weight(1,2))
st_numscalar("r(w41)", p->edge_weight(4,1))
st_numscalar("r(w13)", p->edge_weight(1,3))
el = p->edgelist()
st_numscalar("r(el_rows)", rows(el))
st_numscalar("r(el_wsum)", sum(el[.,3]))
end
assert r(out_ok) == 1
assert r(in_ok)  == 1
assert r(he12) == 1
assert r(he21) == 0
assert r(w12) == 4
assert r(w41) == 3
assert r(w13) == 0
assert r(el_rows) == 4
assert r(el_wsum) == 10

// --- undirected: neighbors() == neighbors_in() ---
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(undirnet) undirected labs(X,Y,Z)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("undirnet")]
st_numscalar("r(match)", sort(p->neighbors(1),1) == sort(p->neighbors_in(1),1))
st_numscalar("r(deg)", p->degree(1))
end
assert r(match) == 1
assert r(deg) == 2

// --- empty network (0 edges) ---
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(emptynet) labs(P,Q,R)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("emptynet")]
st_numscalar("r(deg)", p->degree(1))
st_numscalar("r(rows)", rows(p->edgelist()))
end
assert r(deg) == 0
assert r(rows) == 0

// --- self-loop: node 1 has a tie to itself ---
nwclear
nwset, mat((1,1,0\0,0,1\0,0,0)) name(selfloopnet) directed selfloop labs(A,B,C)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("selfloopnet")]
st_numscalar("r(deg1)", p->degree(1))
st_numscalar("r(he11)", p->has_edge(1,1))
st_numscalar("r(w11)", p->edge_weight(1,1))
end
assert r(deg1) == 2
assert r(he11) == 1
assert r(w11) == 1

// --- complete graph K5 ---
nwclear
nwset, mat((J(5,5,1) - I(5))) name(k5) undirected labs(N1,N2,N3,N4,N5)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("k5")]
ok = 1
for (i=1;i<=5;i++){
	ok = ok & (p->degree(i)==4)
}
st_numscalar("r(k5ok)", ok)
st_numscalar("r(k5rows)", rows(p->edgelist()))
end
assert r(k5ok) == 1
assert r(k5rows) == 20

// --- non-consecutive/non-numeric node IDs via nwfromedge ---
nwclear
set obs 4
gen ego = "alpha"
gen alter = "gamma"
replace ego = "beta" in 2
replace alter = "delta" in 2
replace ego = "gamma" in 3
replace alter = "alpha" in 3
replace ego = "delta" in 4
replace alter = "beta" in 4
nwfromedge ego alter, name(strnet) directed
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("strnet")]
st_numscalar("r(nodes)", p->get_nodes())
st_numscalar("r(edges)", rows(p->edgelist()))
end
assert r(nodes) == 4
assert r(edges) == 4

// --- dual-mode: BFS-via-neighbors() reproduces calculate_components() exactly ---
// three components: path A-B-C, isolate D, pair E-F
nwclear
nwset, mat((0,1,0,0,0,0\1,0,1,0,0,0\0,1,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,1\0,0,0,0,1,0)) name(compnet) undirected labs(A,B,C,D,E,F)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("compnet")]
dense_comp = p->calculate_components()
bfs_comp = bfs_components(p)
st_numscalar("r(ncomp_dense)", max(dense_comp))
st_numscalar("r(ncomp_bfs)", max(bfs_comp))
st_numscalar("r(match_ab)", bfs_comp[1,1]==bfs_comp[2,1])
st_numscalar("r(match_bc)", bfs_comp[2,1]==bfs_comp[3,1])
st_numscalar("r(sep_ad)", bfs_comp[1,1]!=bfs_comp[4,1])
st_numscalar("r(sep_de)", bfs_comp[4,1]!=bfs_comp[5,1])
st_numscalar("r(match_ef)", bfs_comp[5,1]==bfs_comp[6,1])
// same partition structure as calculate_components(), pairwise
st_numscalar("r(agree_ab)", (dense_comp[1,1]==dense_comp[2,1]) == (bfs_comp[1,1]==bfs_comp[2,1]))
st_numscalar("r(agree_ad)", (dense_comp[1,1]==dense_comp[4,1]) == (bfs_comp[1,1]==bfs_comp[4,1]))
st_numscalar("r(agree_ef)", (dense_comp[5,1]==dense_comp[6,1]) == (bfs_comp[5,1]==bfs_comp[6,1]))
end
assert r(ncomp_dense) == 3
assert r(ncomp_bfs) == 3
assert r(match_ab) == 1
assert r(match_bc) == 1
assert r(sep_ad) == 1
assert r(sep_de) == 1
assert r(match_ef) == 1
assert r(agree_ab) == 1
assert r(agree_ad) == 1
assert r(agree_ef) == 1

// --- cache invalidation: structural mutation (nwaddnodes) ---
nwclear
nwset, mat((0,5\0,0)) name(mutnet) directed labs(M,N)
nwaddnodes mutnet, nodenames(O)
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("mutnet")]
st_numscalar("r(nodes)", p->get_nodes())
st_numscalar("r(deg1)", p->degree(1))
st_numscalar("r(deg3)", p->degree(3))
end
assert r(nodes) == 3
assert r(deg1) == 1
assert r(deg3) == 0

// --- cache invalidation: raw-pointer mutation via nwreplace ---
nwreplace mutnet[1,3] = 9
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("mutnet")]
st_numscalar("r(deg1)", p->degree(1))
end
assert r(deg1) == 2

/*
	Regression test for a real bug found in this session's Commit 5
	regression sweep: build_sparse_index() allocated its internal `rowidx'
	scratch array (used to build the directed reverse/in-neighbor index)
	with `n' (node count) rows instead of `nnz' (edge count) rows. Every
	hand-built fixture above happens to have nnz <= n, so none of them
	exercised the out-of-bounds write. A directed network denser than
	nnz == n (average degree > 1) is required to catch it - this one has
	n=20, nnz=380 (a full directed graph, average out-degree 19).
*/
nwclear
set obs 20
nwrandom 20, density(1) name(densenet) directed
mata:
p = nw.nws.pdefs[nw.nws.get_index_of("densenet")]
el = p->edgelist()
st_numscalar("r(n)", p->get_nodes())
st_numscalar("r(nnz)", rows(el))
ok = 1
for (i=1; i<=20; i++){
	dense_in = selectindex((*p->get_matrix())[.,i]' :!= 0 :& (*p->get_matrix())[.,i]' :!= .)'
	ok = ok & (sort(p->neighbors_in(i),1) == sort(dense_in,1))
}
st_numscalar("r(match)", ok)
end
assert r(n) == 20
assert r(nnz) == 380
assert r(match) == 1
