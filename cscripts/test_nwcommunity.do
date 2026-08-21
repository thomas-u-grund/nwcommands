cscript

do unw_core.do

// Two triangles {A,B,C} and {D,E,F} joined by a single bridge edge C-D.
// Hand-verified: m=7 edges, Q of the true 2-triangle partition = 5/14.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected labs(A,B,C,D,E,F) name(bridge)

nwcommunity bridge
assert r(communities) == 2
assert reldif(r(modularity), .35714285714285715) < 1E-8
assert _community[1] == _community[2]
assert _community[2] == _community[3]
assert _community[4] == _community[5]
assert _community[5] == _community[6]
assert _community[1] != _community[4]

// Two fully disconnected triangles: optimal partition is forced (any merge or
// split is strictly modularity-decreasing), hand-verified Q = 0.5.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected labs(A,B,C,D,E,F) name(disconnected)
nwcommunity disconnected, replace
assert r(communities) == 2
assert reldif(r(modularity), .5) < 1E-8
assert _community[1] == _community[2]
assert _community[2] == _community[3]
assert _community[4] == _community[5]
assert _community[5] == _community[6]
assert _community[1] != _community[4]

// Sanity bound: Q must be within [-1,1]
assert r(modularity) >= -1 & r(modularity) <= 1

// Round-trip: nwmodularity on nwcommunity's own output must reproduce the same Q
nwmodularity disconnected, group(_community)
assert reldif(r(modularity), .5) < 1E-8
assert r(communities) == 2

// Directed networks require symmetrize
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(dirnet)
capture nwcommunity dirnet
assert _rc != 0
nwcommunity dirnet, symmetrize
assert r(communities) >= 1

* --- netlist regression: see test_nwcomponents.do's identical
* comment - the same copy-pasted already-exists check had the same
* bug here, found while building nwconcor.ado's netlist support.
nwclear
nwset, mat((0,1\1,0)) name(nA) undirected
nwset, mat((0,1\1,0)) name(nB) undirected
nwcommunity nA nB, generate(mynetlistcomm)
assert _rc == 0
capture confirm variable mynetlistcomm1, exact
assert _rc == 0
capture confirm variable mynetlistcomm2, exact
assert _rc == 0
