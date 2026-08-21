cscript

do unw_core.do

/*
	Distance-family sparse-migration regression test (sparse-backend
	migration, item 2 of 2 - calculate_distances()/calculate_distance_pair()/
	calculate_distances_without(), feeding nwgeodesic/nwcloseness/nwreach/
	nwbridges/nwpath). All expected values below were captured from the
	prior dense implementation (Brute_dist()/Dijkstra_dist()/the old
	matrix-power calculate_distance_pair()/the old dense-pointer-mutating
	calculate_distances_without()) via direct probe BEFORE migrating, then
	re-verified byte-identical against the new sparse implementation - a
	dense-vs-sparse regression, not values assumed correct in the abstract.
*/

* Undirected, unvalued: triangle {1,2,3}, disconnected pair {4,5}, isolate {6}
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,0\0,0,0,1,0,0\0,0,0,0,0,0)) undirected
mata: D1brute = nw.nws.pdefs[1]->calculate_distances(0, "brute")
mata: D1dijkstra = nw.nws.pdefs[1]->calculate_distances(1, "dijkstra")
mata: assert(D1brute[1,1] == .)
mata: assert(D1brute[2,1] == 1)
mata: assert(D1brute[3,1] == 1)
mata: assert(D1brute[3,2] == 1)
mata: assert(D1brute[4,1] == .)
mata: assert(D1brute[5,4] == 1)
mata: assert(D1brute[6,1] == .)
mata: assert(D1dijkstra[1,1] == 0)
mata: assert(D1dijkstra[2,1] == 1)
mata: assert(D1dijkstra[4,1] == .)
mata: assert(D1dijkstra[6,6] == 0)
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(1,4) == -1)
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(1,3) == 1)
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(1,6) == -1)

* Directed, valued 4-cycle: 1->2 (w=2), 2->3 (w=3), 3->4 (w=1), 4->1 (w=1)
nwclear
nwset, mat((0,2,0,0\0,0,3,0\0,0,0,1\1,0,0,0)) directed
mata: D2brute = nw.nws.pdefs[1]->calculate_distances(0, "brute")
mata: D2dijkstra = nw.nws.pdefs[1]->calculate_distances(1, "dijkstra")
mata: assert(D2brute[1,1] == .)
mata: assert(D2brute[1,2] == 1)
mata: assert(D2brute[1,3] == 2)
mata: assert(D2brute[1,4] == 3)
mata: assert(D2brute[2,1] == 3)
mata: assert(reldif(D2dijkstra[1,2], .5) < 1E-8)
mata: assert(reldif(D2dijkstra[1,3], .8333333333333) < 1E-6)
mata: assert(reldif(D2dijkstra[1,4], 1.833333333333) < 1E-6)
mata: assert(reldif(D2dijkstra[2,1], 2.333333333333) < 1E-6)
mata: assert(D2dijkstra[1,1] == 0)
* calculate_distance_pair() is always unweighted (hop count), regardless
* of the network being valued - respects directedness (forward only)
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(1,3) == 2)
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(3,1) == 2)
* alpha=0: every positive tie costs 1 (unweighted), even via the
* "dijkstra" alg path - matches the brute hop-count matrix exactly
mata: D2dijkstra0 = nw.nws.pdefs[1]->calculate_distances(0, "dijkstra")
mata: assert(D2dijkstra0[1,2] == 1)
mata: assert(D2dijkstra0[1,3] == 2)
mata: assert(D2dijkstra0[1,4] == 3)

* calculate_distance_pair(i,i): shortest CYCLE back to i, not trivially 0,
* when no direct self-loop edge exists (verified against the prior dense
* matrix-power implementation, which found this the same way via its own
* squared-matrix diagonal)
nwclear
nwset, mat((0,1,1,0\1,0,0,0\0,1,0,0\0,0,0,0)) directed
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(1,1) == 2)

* calculate_distances_without(): undirected path graph 1-2-3-4-5 (a tree -
* removing any single edge always disconnects, so every adjacent pair
* must come back -1)
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected
mata: DW1 = nw.nws.pdefs[1]->calculate_distances_without()
mata: assert(DW1[2,1] == -1)
mata: assert(DW1[3,2] == -1)
mata: assert(DW1[4,3] == -1)
mata: assert(DW1[5,4] == -1)
mata: assert(DW1[1,1] == 0)

* calculate_distances_without(): pure directed 3-cycle 1->2->3->1, each
* node has exactly one out-edge, so removing it always disconnects
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed
mata: DW2 = nw.nws.pdefs[1]->calculate_distances_without()
mata: assert(DW2[1,2] == -1)
mata: assert(DW2[2,3] == -1)
mata: assert(DW2[3,1] == -1)

* calculate_distances_without(): the old dense implementation zeroed BOTH
* edge[i,j] AND edge[j,i] before recomputing - this asymmetric case (a
* genuinely distinct reverse arc 2->1 alongside 1->2, plus an alternate
* route 1->3->2) proves the sparse forward-only exclusion still matches:
* removing 1->2 (and the unrelated 2->1) still finds the alternate path.
nwclear
nwset, mat((0,1,1,0\1,0,0,0\0,1,0,0\0,0,0,0)) directed
mata: DW3 = nw.nws.pdefs[1]->calculate_distances_without()
mata: assert(DW3[1,2] == 2)
mata: assert(DW3[2,1] == -1)
mata: assert(DW3[3,2] == -1)

* calculate_distances_without() on a genuine self-loop edge: a directed
* network with a self-loop at node 1, a mutual tie 1<->2, and a dead-end
* 1->3. Excluding the self-loop itself must still find the real 1->2->1
* return path (distance 2) - NOT trivially 0, and not the direct
* self-loop's own distance of 1 (that's what calculate_distance_pair(1,1)
* returns standalone, when the self-loop edge is NOT excluded).
nwclear
nwset, mat((1,1,1\1,0,0\0,0,0)) directed selfloop
mata: DW4 = nw.nws.pdefs[1]->calculate_distances_without()
mata: assert(DW4[1,1] == 2)
mata: assert(DW4[1,2] == -1)
mata: assert(DW4[1,3] == -1)
mata: assert(nw.nws.pdefs[1]->calculate_distance_pair(1,1) == 1)

* edge_dense_built stays 0 throughout every one of the above sparse-native
* distance computations - the whole point of this migration
nwclear
nwset, mat(J(2,2,0)) name(sparsedistnet) directed labs(N1,N2)
mata:
p5 = nw.nws.pdefs[nw.nws.get_index_of("sparsedistnet")]
p5->create_by_name(("n1","n2","n3"))
ego5 = (1\2\3)
alter5 = (2\3\1)
val5 = (1\1\1)
p5->set_edge_from_triplets(ego5, alter5, val5, 1)
p5->set_selfloop(0)
assert(p5->edge_dense_built == 0)
D5 = p5->calculate_distances(0, "brute")
assert(p5->edge_dense_built == 0)
dp5 = p5->calculate_distance_pair(1,2)
assert(p5->edge_dense_built == 0)
DW5 = p5->calculate_distances_without()
assert(p5->edge_dense_built == 0)
end
