cscript

clear mata
do unw_core.do
set more off

* nwlambda: n x n edge (line) connectivity matrix - Borgatti, Everett &
* Shirey's (1990) own foundation for "lambda sets". Certified against
* 3 hand-computable cases (matching this project's own established
* certification discipline for every other cohesive-subgroup command),
* plus one end-to-end lambda-set extraction via nwhierarchy's own
* existing disnet()/linkage() machinery (no new clustering code needed -
* single linkage on the lambda matrix recovers lambda sets exactly,
* via the Gomory-Hu-tree equivalence between pairwise min-cuts and
* single-linkage hierarchical clustering).

* --- path graph A-B-C: only one edge-disjoint path between any pair
* (removing the single "middle" edge disconnects the other two nodes).
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(path3) labs(A,B,C)
nwlambda path3, name(lam1)
nw_syntax lam1
mata: st_numscalar("__ab", (*`netobj'->get_matrix())[1,2])
mata: st_numscalar("__bc", (*`netobj'->get_matrix())[2,3])
mata: st_numscalar("__ac", (*`netobj'->get_matrix())[1,3])
assert __ab == 1
assert __bc == 1
assert __ac == 1
scalar drop __ab __bc __ac

* --- triangle: every pair has 2 edge-disjoint paths (the direct edge
* plus the two-hop path through the third node).
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri3) labs(A,B,C)
nwlambda tri3, name(lam2)
nw_syntax lam2
mata: st_numscalar("__ab2", (*`netobj'->get_matrix())[1,2])
mata: st_numscalar("__bc2", (*`netobj'->get_matrix())[2,3])
mata: st_numscalar("__ac2", (*`netobj'->get_matrix())[1,3])
assert __ab2 == 2
assert __bc2 == 2
assert __ac2 == 2
scalar drop __ab2 __bc2 __ac2

* --- two triangles {A,B,C}/{D,E,F} joined by a single bridge edge C-D:
* within-triangle pairs have lambda=2, any pair straddling the bridge
* has lambda=1 (the single bridge edge is the only route) - a classic
* hand-derivable example already used elsewhere in this project's own
* certification history (nwcohesion's own identical test network).
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(bridge6) labs(A,B,C,D,E,F)
nwlambda bridge6, name(lam3)
nw_syntax lam3
mata: st_numscalar("__ab3", (*`netobj'->get_matrix())[1,2])
mata: st_numscalar("__cd3", (*`netobj'->get_matrix())[3,4])
mata: st_numscalar("__af3", (*`netobj'->get_matrix())[1,6])
mata: st_numscalar("__de3", (*`netobj'->get_matrix())[4,5])
assert __ab3 == 2
assert __cd3 == 1
assert __af3 == 1
assert __de3 == 2
scalar drop __ab3 __cd3 __af3 __de3
di "=== nwlambda hand-computable lambda-matrix cases REGRESSION VERIFIED ==="

* --- end-to-end lambda-set extraction: single-linkage hierarchical
* clustering on a lambda-derived dissimilarity (via nwhierarchy's own
* existing disnet()/linkage() machinery - reused as-is, no new
* clustering code) recovers the two obvious lambda sets exactly.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(bridge6b) labs(A,B,C,D,E,F)
nwlambda bridge6b, name(lamb)
nw_syntax lamb
mata: __maxlam = max(*`netobj'->get_matrix())
mata: __dissim = __maxlam :- *`netobj'->get_matrix()
mata: _diag(__dissim, 0)
mata: `netobj'->set_selfloop(1)
mata: `netobj'->set_edge(__dissim)
mata: mata drop __maxlam __dissim

nwhierarchy, disnet(lamb) linkage(singlelinkage) groups(2) generate(lamgroup)
qui sum lamgroup if _n<=3
local g1 = r(mean)
local sd1 = r(sd)
qui sum lamgroup if _n>3
local g2 = r(mean)
local sd2 = r(sd)
assert `g1' != `g2'
assert `sd1' == 0
assert `sd2' == 0
di "=== nwlambda + nwhierarchy end-to-end lambda-set extraction REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwlambda nonexistent
assert _rc == 482
