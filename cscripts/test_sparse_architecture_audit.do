cscript

do unw_core.do

* General validation-stage audit (harmonisation unit 67): a systematic
* scan of every NWdef method in unw_core.do that reads or writes the
* bare `edge' field directly (rather than through a get_matrix*()
* accessor, which already guards via ensure_dense_built()) found four
* methods missing that guard, unlike every other such method in the
* class - a real architecture-adoption gap the sparse-backend migration
* (docs/SPARSE_BACKEND.md) had already fixed for check_symmetry()/
* symmetrize() and this session's own earlier keep_nodes()/drop_nodes()
* fix (harmonisation unit 59) missed these four:
*   - clean_matrix_2mode() (nw2fromedge.ado's own two-mode cleanup
*     step) - has a LIVE caller, but was only "accidentally safe"
*     because that caller always calls symmetrize() first (via its own
*     hardcoded `undirected' nwsym step), which itself already calls
*     ensure_dense_built() - not a designed guarantee. Confirmed via a
*     direct probe (below) that a genuinely sparse-native two-mode
*     network, built and cleaned WITHOUT going through nwsym first,
*     would have thrown a Mata conformability error (J(0,0,0) :+ an
*     n x n matrix) before this fix.
*   - connect_edge() and add_node() - no live caller (connect_edge) or
*     only nwaddnodes.ado's own already-broken-for-an-unrelated-reason
*     rewrite (add_node) at the time of this fix, but both would have
*     silently indexed into or concatenated onto an empty/wrong-sized
*     matrix for any future sparse-native caller.
*   - dumper() - a debug-only utility (no .ado command calls it), would
*     have silently printed "no edges" for every node on a sparse-
*     native network instead of reflecting reality.
* All four fixed identically: an ensure_dense_built() call added as the
* first line of the method body, matching the convention every other
* dense-touching NWdef method already follows.

* --- clean_matrix_2mode() on a genuinely sparse-native two-mode
* network (built via create_by_name_sparse()+set_edge_from_triplets(),
* never touching nwsym/symmetrize() at all - the exact scenario that
* would have crashed before this fix). Mode 1 = {A,B,C}, mode 2 =
* {D,E}, ties A-D, A-E, B-D, C-E. After cleaning, every same-mode dyad
* (A-B, A-C, B-C, D-E) must be missing; every cross-mode dyad must
* show its correct 0/1 tie value.
mata:
p = &(nw_def())
p->create_by_name_sparse(("A","B","C","D","E"))
p->set_name("sparsetwomode")
ego = (1\1\2\3)
alter = (4\5\4\5)
val = (1\1\1\1)
p->set_edge_from_triplets(ego, alter, val, 0)
p->set_selfloop(0)
p->set_2mode(1)
p->set_modes(("1","1","1","2","2"))
p->clean_matrix_2mode()
m = p->get_matrix_copy()
assert(m[1,2] == .)
assert(m[1,3] == .)
assert(m[2,3] == .)
assert(m[4,5] == .)
assert(m[1,4] == 1)
assert(m[1,5] == 1)
assert(m[2,4] == 1)
assert(m[2,5] == 0)
assert(m[3,4] == 0)
assert(m[3,5] == 1)
end
di "CLEAN_MATRIX_2MODE SPARSE-NATIVE PROBE PASSED"

* --- add_node() on a genuinely sparse-native network: must correctly
* extend the (previously never-materialized) dense matrix by one
* isolated row/column, not silently produce a wrong-sized result.
mata:
p2 = &(nw_def())
p2->create_by_name_sparse(("X","Y","Z"))
ego2 = (1\2)
alter2 = (2\3)
val2 = (1\1)
p2->set_edge_from_triplets(ego2, alter2, val2, 0)
p2->set_selfloop(0)
p2->add_node("W")
assert(p2->get_nodes() == 4)
m2 = p2->get_matrix_copy()
assert(rows(m2) == 4)
assert(cols(m2) == 4)
assert(m2[1,2] == 1)
assert(m2[2,3] == 1)
assert(sum(m2[4,.]) == 0)
assert(sum(m2[.,4]) == 0)
end
di "ADD_NODE SPARSE-NATIVE PROBE PASSED"

* --- connect_edge() on a genuinely sparse-native network: must
* correctly write into the (previously never-materialized) dense
* matrix, symmetrically for an undirected network.
mata:
p3 = &(nw_def())
p3->create_by_name_sparse(("P","Q","R"))
ego3 = J(0,1,0)
alter3 = J(0,1,0)
val3 = J(0,1,0)
p3->set_edge_from_triplets(ego3, alter3, val3, 0)
p3->set_selfloop(0)
p3->set_directed(0)
p3->connect_edge(1, (2,3))
m3 = p3->get_matrix_copy()
assert(m3[1,2] == 1)
assert(m3[1,3] == 1)
assert(m3[2,1] == 1)
assert(m3[3,1] == 1)
end
di "CONNECT_EDGE SPARSE-NATIVE PROBE PASSED"

* --- dumper() on a sparse-native network must not error (a debug-only
* utility - not checking its printed output content, only that it
* completes without crashing on a network whose `edge' was never
* materialized before this call).
mata:
p4 = &(nw_def())
p4->create_by_name_sparse(("M","N"))
ego4 = (1)
alter4 = (2)
val4 = (1)
p4->set_edge_from_triplets(ego4, alter4, val4, 0)
p4->set_selfloop(0)
p4->dumper("  ")
end
di "DUMPER SPARSE-NATIVE PROBE PASSED (no crash)"
