cscript

do unw_core.do

// Two triangles {A,B,C} and {D,E,F} joined by a single bridge edge C-D.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected labs(A,B,C,D,E,F) name(bridge)

// Exact algebraic identity: scoring a single all-in-one-group partition
// always gives Q = 0, for any network.
gen onegroup = 1
nwmodularity bridge, group(onegroup)
assert r(communities) == 1
assert r(modularity) == 0

// The true 2-triangle partition, hand-verified Q = 5/14.
gen truegroup = 1 in 1/3
replace truegroup = 2 in 4/6
nwmodularity bridge, group(truegroup)
assert r(communities) == 2
assert reldif(r(modularity), .35714285714285715) < 1E-8

// A deliberately bad partition (splitting one triangle across groups) must
// score strictly lower than the true partition.
gen badgroup = 1 in 1/2
replace badgroup = 2 in 3/6
nwmodularity bridge, group(badgroup)
assert r(modularity) < .35714285714285715

// Directed networks require symmetrize
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(dirnet)
gen g = _n
capture nwmodularity dirnet, group(g)
assert _rc != 0
nwmodularity dirnet, group(g) symmetrize
assert r(communities) == 3
