cscript

clear mata
do unw_core.do
set more off

* nwmaxflow: max-flow value + minimum cut between two nodes, via
* NWdef::calculate_maxflow() (a direct, generic Edmonds-Karp - the same
* bfs_augment() primitive already used by calculate_lambda()'s pairwise
* edge connectivity and vertex_connectivity()'s node-split reduction).
* Certified against a classic textbook "diamond" example, both weighted
* (real capacities) and unweighted (capacity 1 per tie).

* diamond: A->B cap2, A->C cap1, B->D cap1, B->C cap1, C->D cap2.
* Weighted max-flow(A,D) = 3 (A-B-D:1, A-B-C-D:1, A-C-D:1).
* Unweighted max-flow(A,D) = 2 (two edge-disjoint paths A-B-D, A-C-D).
nwclear
nwset, mat((0,2,1,0\0,0,1,1\0,0,0,2\0,0,0,0)) name(flownet) directed valued labs(A,B,C,D)

nwmaxflow flownet, source(A) sink(D) weighted generate(cutside)
assert r(maxflow) == 3
assert r(cutedges) >= 1

nwmaxflow flownet, source(A) sink(D) generate(cutside2)
assert r(maxflow) == 2

* the cut side variable must actually mark a genuine source/sink split
* (source itself always on the source side, sink never on it).
qui sum cutside if _n == 1
assert r(mean) == 1
qui sum cutside if _n == 4
assert r(mean) == 0

* error handling: unknown node, source==sink.
capture nwmaxflow flownet, source(bogus) sink(D)
assert _rc == 99
capture nwmaxflow flownet, source(A) sink(A)
assert _rc == 198

di "=== nwmaxflow hand-computable cases REGRESSION VERIFIED ==="
