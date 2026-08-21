cscript

do unw_core.do

* nwkeepnodes had zero test coverage and was completely non-functional
* before this harmonisation unit - it delegates to nwdropnodes (by
* computing the complement of the requested keep-list and passing that
* to nwdropnodes), so it was blocked by exactly the same `_nwsyntax`/
* missing-`nodes'-local bug fixed there (see test_nwdropnodes.do's own
* header comment for the full explanation) - `_nwsyntax` only re-
* exports 4 locals, not `nodes' (the node count), which this file's
* own `forvalues i = 1/`nodes''` loop (building the complement list)
* needs directly. Switched to `nw_syntax`, the same fix, same
* reasoning as nwdropnodes.ado's identical bug.

* --- 4-node undirected chain A-B-C-D. Keeping nodes 1,3,4 (A,C,D) is
* the complement of dropping node 2 (B) - same expected result as
* test_nwdropnodes.do's own first case, verified via the opposite
* (keep-list) interface.
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwkeepnodes net1, nodes(1 3 4)
assert _rc == 0
nwname net1
assert r(nodes) == 3
assert `"`r(labs)'"' == `"A,C,D"'
nwtomata net1, mat(M)
mata: assert(M[1,2] == 0)
mata: assert(M[2,3] == 1)

* --- keeping by node label (not just integer index).
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net2) undirected labs(A,B,C,D)
nwkeepnodes net2, nodes(A C D)
assert _rc == 0
nwname net2
assert `"`r(labs)'"' == `"A,C,D"'

* --- keeping a proper subset of a 5-node cycle A-B-C-D-E-A: keeping
* A, C, E (the complement of dropping B, D) matches
* test_nwdropnodes.do's own multi-drop case exactly - only the direct
* A-E edge survives.
nwclear
nwset, mat((0,1,0,0,1\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\1,0,0,1,0)) name(net3) undirected labs(A,B,C,D,E)
nwkeepnodes net3, nodes(1 3 5)
assert _rc == 0
nwname net3
assert r(nodes) == 3
assert `"`r(labs)'"' == `"A,C,E"'
nwtomata net3, mat(M2)
mata: assert(M2[1,2] == 0)
mata: assert(M2[1,3] == 1)
mata: assert(M2[2,3] == 0)

* --- directed networks: keeping A, C, D from a directed chain
* A->B->C->D (dropping B) must leave A isolated and C->D intact, and
* the network must still be recognized as directed afterward.
nwclear
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\0,0,0,0)) name(dnet) directed labs(A,B,C,D)
nwkeepnodes dnet, nodes(1 3 4)
assert _rc == 0
nwname dnet
assert `"`r(directed)'"' == `"true"'
assert `"`r(labs)'"' == `"A,C,D"'
nwtomata dnet, mat(M3)
mata: assert(sum(M3[1,.]) == 0)
mata: assert(M3[2,3] == 1)
