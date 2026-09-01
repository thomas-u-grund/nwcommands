cscript

clear mata
do unw_core.do
set more off

* nwmotifs: the 4-node undirected motif/graphlet census, via
* NWdef::calculate_motif4() (classifies every induced 4-node subgraph
* by (edge count, sorted degree sequence) - a COMPLETE invariant at
* n=4, verified by hand for all 11 non-isomorphic 4-vertex graphs, so
* no general graph-isomorphism check is needed). Certified against 6
* dedicated 4-node networks, each hand-built to contain EXACTLY one of
* the 6 connected shapes and nothing else, plus a disconnected/empty
* case and a larger network's own exhaustive C(n,4) accounting check -
* the same certification discipline nwtriads' own 16-category census
* already established one dimension down.

* --- path P4: A-B-C-D (open chain, degrees 1,2,2,1)
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(m_path) labs(A,B,C,D)
nwmotifs m_path, silent
assert r(path) == 1
assert r(star) == 0 & r(cycle) == 0 & r(paw) == 0 & r(diamond) == 0 & r(k4) == 0 & r(disconnected) == 0
di "=== nwmotifs: path P4 REGRESSION VERIFIED ==="

* --- star K1,3: A tied to B,C,D; B/C/D mutually untied (degrees 3,1,1,1)
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(m_star) labs(A,B,C,D)
nwmotifs m_star, silent
assert r(star) == 1
assert r(path) == 0 & r(cycle) == 0 & r(paw) == 0 & r(diamond) == 0 & r(k4) == 0 & r(disconnected) == 0
di "=== nwmotifs: star K1,3 REGRESSION VERIFIED ==="

* --- cycle C4: A-B-C-D-A (square, all degrees 2)
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(m_cycle) labs(A,B,C,D)
nwmotifs m_cycle, silent
assert r(cycle) == 1
assert r(path) == 0 & r(star) == 0 & r(paw) == 0 & r(diamond) == 0 & r(k4) == 0 & r(disconnected) == 0
di "=== nwmotifs: cycle C4 REGRESSION VERIFIED ==="

* --- paw: triangle A-B-C plus a pendant tie D-A (degrees 3,2,2,1)
nwset, mat((0,1,1,1\1,0,1,0\1,1,0,0\1,0,0,0)) name(m_paw) labs(A,B,C,D)
nwmotifs m_paw, silent
assert r(paw) == 1
assert r(path) == 0 & r(star) == 0 & r(cycle) == 0 & r(diamond) == 0 & r(k4) == 0 & r(disconnected) == 0
di "=== nwmotifs: paw REGRESSION VERIFIED ==="

* --- diamond: K4 minus one edge (C-D missing; degrees 3,3,2,2)
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,0\1,1,0,0)) name(m_diamond) labs(A,B,C,D)
nwmotifs m_diamond, silent
assert r(diamond) == 1
assert r(path) == 0 & r(star) == 0 & r(cycle) == 0 & r(paw) == 0 & r(k4) == 0 & r(disconnected) == 0
di "=== nwmotifs: diamond REGRESSION VERIFIED ==="

* --- K4: complete graph on 4 nodes
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(m_k4) labs(A,B,C,D)
nwmotifs m_k4, silent
assert r(k4) == 1
assert r(path) == 0 & r(star) == 0 & r(cycle) == 0 & r(paw) == 0 & r(diamond) == 0 & r(disconnected) == 0
di "=== nwmotifs: K4 REGRESSION VERIFIED ==="

* --- disconnected residual bucket: an empty 4-node graph (0 edges),
* and a triangle+isolate (3 edges, degrees 2,2,2,0) - BOTH must land in
* the disconnected bucket, since neither is one of the 6 connected shapes.
nwset, mat((0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0)) name(m_empty) labs(A,B,C,D)
nwmotifs m_empty, silent
assert r(disconnected) == 1
assert r(path) == 0 & r(star) == 0 & r(cycle) == 0 & r(paw) == 0 & r(diamond) == 0 & r(k4) == 0

nwset, mat((0,1,1,0\1,0,1,0\1,1,0,0\0,0,0,0)) name(m_triiso) labs(A,B,C,D)
nwmotifs m_triiso, silent
assert r(disconnected) == 1
assert r(path) == 0 & r(star) == 0 & r(cycle) == 0 & r(paw) == 0 & r(diamond) == 0 & r(k4) == 0
di "=== nwmotifs: disconnected residual bucket REGRESSION VERIFIED ==="

* --- exhaustive accounting: on a 5-node network, the 7 counts must sum
* to exactly C(5,4) = 5, matching nwtriads' own "every case accounted
* for" certification convention one dimension up.
nwset, mat((0,1,0,1,0\1,0,1,0,0\0,1,0,1,1\1,0,1,0,0\0,0,1,0,0)) name(m_five) labs(A,B,C,D,E)
nwmotifs m_five, silent
local total = r(path)+r(star)+r(cycle)+r(paw)+r(diamond)+r(k4)+r(disconnected)
assert `total' == 5
di "=== nwmotifs: C(n,4) exhaustive accounting REGRESSION VERIFIED ==="

* --- composition with nwcug's existing generic significance-testing
* machinery: nwmotifs needs NO purpose-built permutation test of its
* own - as long as it reports its counts via ordinary r() scalars (as
* it does above), nwcug's own stat()/##net##/rname() template mechanism
* already works against it unmodified, the same "compose with existing
* infrastructure" pattern this session's nwlambda+nwhierarchy work
* already established. Just confirming it runs cleanly end-to-end and
* returns a well-formed p-value - not re-testing nwcug's own machinery.
* (m_five's own cycle count, computed above, is 1 - the single 4-node
* subset {A,B,C,D} forms a 4-cycle; verified by hand: the other 4
* subsets are 2 paths, 1 star, and 1 disconnected case.)
set seed 54321
qui nwcug m_five, stat(nwmotifs ##net##, silent) rname(cycle) reps(50) silent
assert r(reps) == 50
assert r(p) >= 0 & r(p) <= 1
assert r(obs) == 1
di "=== nwmotifs: composition with nwcug REGRESSION VERIFIED ==="

* --- plot(): a bar chart of the 7 motif-category counts, via the same
* preserve/rebuild-a-plotting-dataset/restore convention nwcug's own
* plot() and nwtriads' own plot() (added the same session) already use.
* Certified for exactly what those tests already certify: it runs
* cleanly and does not disturb the caller's own active dataset - not
* re-testing graph rendering itself.
clear
set obs 3
gen canary = _n
nwmotifs m_cycle, plot name(nwmotifsplottest) silent
assert _rc == 0
assert _N == 3
assert canary[1] == 1 & canary[2] == 2 & canary[3] == 3
capture graph drop nwmotifsplottest
di "=== nwmotifs plot() OK ==="

* --- error handling: fewer than 4 nodes.
nwset, mat((0,1,0\1,0,1\0,1,0)) name(m_toosmall) labs(A,B,C)
capture nwmotifs m_toosmall
assert _rc == 6556
di "=== nwmotifs error handling REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwmotifs nonexistent
assert _rc == 482
