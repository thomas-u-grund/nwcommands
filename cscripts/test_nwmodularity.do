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

// PERFORMANCE/CORRECTNESS FIX: scoring a partition with enough
// distinct groups used to crash outright ("too many values", r134,
// or a matsize-driven r915 for a slightly smaller count) - `tab ...,
// matrow() matcell()' and a later `matrix rownames = <huge token
// list>' line both routed the group count through a Stata command-
// line/matsize limit that a real network's own community structure
// can easily exceed (confirmed directly: Louvain on a sparse
// n=10,000 random graph genuinely finds 4,322 communities, not a
// pathological case). 2,000 singleton groups (well past the smaller
// end of that limit, confirmed directly) is enough to reproduce the
// crash without needing a large random network in this test file.
nwclear
set seed 1
nwrandom 2000, prob(.01) undirected name(manygroups)
nwload
gen g = _n
nwmodularity manygroups, group(g)
assert _rc == 0
assert r(communities) == 2000


* --- alpha-audit regression: measure(binary|valued) was a complete
* no-op - calculate_modularity() in unw_core.do hardcoded valued=1
* regardless of what the caller requested, so measure(binary) silently
* scored the raw weighted network instead. Hand-computed on a 6-node
* two-triangle-plus-bridge network with strong (5) intra-triangle ties
* and one weak (1) bridge tie: dichotomizing to binary changes Q from
* .467741935 to .357142857 - these must now genuinely differ.
nwclear
nwset, mat((0,5,5,0,0,0\5,0,5,0,0,0\5,5,0,1,0,0\0,0,1,0,5,5\0,0,0,5,0,5\0,0,0,5,5,0)) undirected labs(A,B,C,D,E,F) name(wbridge)
gen truegrp = 1 in 1/3
replace truegrp = 2 in 4/6
nwmodularity wbridge, group(truegrp) measure(valued)
assert reldif(r(modularity), .467741935) < 1E-6
nwmodularity wbridge, group(truegrp) measure(binary)
assert reldif(r(modularity), .357142857) < 1E-6

* moderate-severity pass, community_spectral group: nwmodularity had no
* silent option at all, unlike its closest siblings nwcommunity/
* nwspectral.
capture noisily nwmodularity wbridge, group(truegrp) measure(binary) silent
assert _rc == 0
di "=== silent option REGRESSION VERIFIED ==="

* moderate-severity pass, community_spectral group: resolution() had no
* input validation - same fix as nwcommunity's own identical option.
capture noisily nwmodularity wbridge, group(truegrp) resolution(-1) silent
assert _rc == 198
di "=== resolution() validation REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwmodularity nonexistent, group(truegrp)
assert _rc == 482
