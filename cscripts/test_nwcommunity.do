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


* --- algorithm(labelprop) (harmonisation unit 64): label propagation
* (Raghavan, Albert & Kumar 2007), a cheap majority-vote alternative to
* Louvain with no modularity optimization. Reuses the exact same
* two-triangles-plus-bridge network as this file's own first Louvain
* test - a genuinely random algorithm (see nwcommunity.ado's own
* Algorithm section for why the randomization is load-bearing, not
* incidental: a fixed-order/deterministic-tiebreak version was tried
* first and found to collapse this exact network into one community).
* Label propagation has NO guarantee of finding a good partition
* (unlike Louvain's modularity-monotonic search) - confirmed directly
* by scanning seed(1) through seed(30) on this exact network: roughly
* a quarter of seeds converge to one single collapsed community rather
* than the two genuine triangles, an honest, expected property of the
* algorithm itself, not a bug. seed(1) is one of the seeds confirmed
* (by that same scan) to converge correctly and reproducibly - used
* here to certify that a correct split CAN be found and is exactly
* reproduced given the same seed, not to claim the algorithm always
* succeeds.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected labs(A,B,C,D,E,F) name(bridge2)
nwcommunity bridge2, algorithm(labelprop) seed(1) generate(lpcomm)
assert _rc == 0
assert r(communities) == 2
assert lpcomm[1] == lpcomm[2]
assert lpcomm[2] == lpcomm[3]
assert lpcomm[4] == lpcomm[5]
assert lpcomm[5] == lpcomm[6]
assert lpcomm[1] != lpcomm[4]

* same seed -> identical result (reproducibility)
nwcommunity bridge2, algorithm(labelprop) seed(1) generate(lpcomm2)
assert lpcomm == lpcomm2

* r(modularity) is still computed via the same calculate_modularity()
* used for Louvain (cross-checking the found partition, not trusting
* any running score internal to label propagation itself, which has
* none) - sanity-bounded, not asserted at a fixed value, since label
* propagation is not guaranteed to find the modularity-optimal
* partition the way this bridge network's Louvain result happens to.
assert r(modularity) >= -1 & r(modularity) <= 1

* invalid algorithm() value errors cleanly
capture nwcommunity bridge2, algorithm(bogus)
assert _rc != 0

* algorithm(labelprop) still requires symmetrize for directed networks,
* exactly like the default algorithm(louvain).
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(dirnet2)
capture nwcommunity dirnet2, algorithm(labelprop)
assert _rc != 0
nwcommunity dirnet2, algorithm(labelprop) symmetrize seed(1)
assert r(communities) >= 1

* PERFORMANCE/CORRECTNESS FIX: `tab ..., matrow() matcell()' (used to
* build r(comm_sizeid)) crashes outright ("too many values", r134, or
* a matsize-driven r915 for a slightly smaller count) once a network
* has enough distinct communities - confirmed directly: Louvain on a
* sparse n=10,000 random graph genuinely finds 4,322 communities, not
* a pathological case (large sparse graphs commonly lack strong
* community structure). The later `matrix rownames = <huge token
* list>' line has the same class of failure one level down. A sparse
* 2,000-node random network (well past the smaller end of that limit,
* confirmed directly) reliably produces well over 1,000 communities
* here, without needing a slower n=10,000 network in this test file.
nwclear
set seed 1
nwrandom 2000, prob(.001) undirected name(bignet2k)
nwcommunity bignet2k, generate(_bc) replace silent
assert _rc == 0
assert r(communities) > 500


* --- alpha-audit regression: measure(binary|valued) is forwarded to
* the community search itself correctly, but the reported r(modularity)
* used to be a no-op (calculate_modularity() hardcoded valued=1
* regardless of measure()) - same root cause and same reference network
* as nwmodularity's own identical regression (test_nwmodularity.do).
* On this network, community structure (the 2 triangles) is identical
* under either measure, so both partitions have 2 communities - but the
* reported Q values must genuinely differ between them.
nwclear
nwset, mat((0,5,5,0,0,0\5,0,5,0,0,0\5,5,0,1,0,0\0,0,1,0,5,5\0,0,0,5,0,5\0,0,0,5,5,0)) undirected labs(A,B,C,D,E,F) name(wbridge)
nwcommunity wbridge, measure(valued) generate(cval) silent
assert r(communities) == 2
assert reldif(r(modularity), .467741935) < 1E-6
nwcommunity wbridge, measure(binary) generate(cbin) silent
assert r(communities) == 2
assert reldif(r(modularity), .357142857) < 1E-6

* moderate-severity pass, community_spectral group: resolution() had no
* input validation - zero/negative values pushed r(modularity) well
* outside its own normal [-1,1] range (e.g. resolution(-1) yielded 2).
capture noisily nwcommunity wbridge, resolution(-1) generate(rneg) silent
assert _rc == 198
capture noisily nwcommunity wbridge, resolution(0) generate(rzero) silent
assert _rc == 198
di "=== resolution() validation REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwcommunity nonexistent
assert _rc == 482
