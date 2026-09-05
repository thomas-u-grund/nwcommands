cscript
nwclear

do unw_core.do

set obs 4
gen x = "A"
gen y = "B"
gen z = _n
replace y = "C" in 2

nwfromedge x y
nwsummarize
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"A,B,C"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"A B C"'

assert reldif( r(density)        , .3333333333333333 ) <  1E-8
assert         r(arcs_value)    == 2
assert         r(arcs)          == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3
assert         r(id)            == 1

nwclear
set obs 4
gen x = 1
gen y = 2
replace y = 3 in 2
nwfromedge x y, undirected
nwsummarize

assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"n1,n2,n3"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3"'

assert reldif( r(density)        , .6666666666666666 ) <  1E-8
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3
assert         r(id)            == 1


nwclear
set obs 4
gen x = 4
gen y = 2
replace y = 3 in 2
nwfromedge x y, undirected
nwsummarize
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"n2,n3,n4"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n2 n3 n4"'

assert reldif( r(density)        , .6666666666666666 ) <  1E-8
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3
assert         r(id)            == 1


nwclear
set obs 4
gen x = "Thomas Grund"
gen y = "Georg Simmel"
gen z = _n
replace y = "C" in 2

nwfromedge x y
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"C,Georg Simmel,Thomas Grund"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"C Georg_Simmel Thomas_Grund"'

// Auto-symmetrize detection: nwfromedge should auto-detect a fully
// reciprocal edgelist and declare the network undirected WITHOUT the
// explicit undirected option (nwfromedge's own auto-detect block calls
// "nwsym, check" and compares r(is_symmetric) to the documented string
// "true" - this was silently never firing before the sparse-backend
// migration's fixes, since r(is_symmetric) was actually stored numeric
// at the time; separately, this exercise also depends on _nwsyntax's
// own `directed' export not clobbering nwfromedge's own option-parsing
// locals of the same name, fixed via _nwsyntax's other() prefixing).
nwclear
clear
input str1 ego str1 alter
"A" "B"
"B" "A"
"B" "C"
"C" "B"
end
nwfromedge ego alter, name(symnet)
_nwsyntax symnet
assert `"`directed'"' == `"false"'
mata: assert(`netobj'->check_symmetry() == 1)

// Zero-weight triplets mean "no tie", matching every dense `edge'
// matrix's own convention (get_arcs_count()/get_edges_count() both
// explicitly exclude *e==0 cells) - a real regression risk specific to
// the sparse-native construction path (set_edge_from_triplets() has no
// implicit all-zero background the way J(n,n,0) does, so an explicit
// zero-weight row must be dropped, not stored as a real tie). A node
// whose only tie carries value 0 must end up isolated, not connected.
nwclear
clear
input ego alter value
1 2 1
4 2 0
end
nwfromedge ego alter value, name(zeronet)
_nwsyntax zeronet
mata: assert(`netobj'->degree(3) == 0)

* an explicit name() collision must error unless replace is given
* (mirrors nwset.ado's own identical fix) - nwfromedge is a separate
* creation path from nwset's own mat()/varlist forms (nwset's own
* `edgelist' option dispatches here), with its own independent
* nwvalidate-based collision handling that needed the same fix.
* zeronet (3 nodes: 1,2,4) still exists from the block above.
clear
input ego alter
1 2
2 3
3 4
end
capture nwfromedge ego alter, name(zeronet)
assert _rc == 483  // errNWsExists - consolidated from the old ad-hoc 6099 during the error-code coherence pass
nwsummarize zeronet
assert r(nodes) == 3

nwfromedge ego alter, name(zeronet) replace
assert _rc == 0
nwsummarize zeronet
assert r(nodes) == 4

* labprefix() (renamed from prefix() during harmonisation, to avoid
* colliding with nwrecode's unrelated network-naming prefix()): default
* auto-generated numeric node labels are "n"-prefixed; labprefix()
* overrides that prefix when labs() is not given.
clear
input ego alter
1 2
2 3
end
nwfromedge ego alter, name(labpreftest)
nwsummarize labpreftest
assert `"`r(labs)'"' == `"n1,n2,n3"'

clear
input ego alter
1 2
2 3
end
nwfromedge ego alter, name(labpreftest2) labprefix(p)
nwsummarize labpreftest2
assert `"`r(labs)'"' == `"p1,p2,p3"'

* twomode (harmonisation phase): an exact alias for nw2fromedge, added so
* two-mode edgelist import is reachable from nwfromedge directly, mirroring
* nwset.ado's own twomode option (which also forwards to nw2fromedge).
* Confirms it produces byte-identical results to calling nw2fromedge
* directly, on nw2fromedge's own first certified worked example.
nwclear
set obs 2
gen x = 1
gen y = 1
replace y = 2 in 2
nwfromedge x y, twomode name(viatwomode)
nwsummarize viatwomode
assert `"`r(mode2)'"'    == `"true"'
assert `"`r(labs)'"'     == `"n1,n2,n3"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert         r(nodes)         == 3
assert         r(edges)         == 2

* directed/undirected/forcedirected/forceundirected are rejected when
* combined with twomode - a two-mode network is inherently undirected.
nwclear
set obs 2
gen x = 1
gen y = 1
replace y = 2 in 2
capture noisily nwfromedge x y, twomode directed name(bad)
assert _rc == 198

* --- BUGFIX regression: a self-loop row (ego==alter) in the SOURCE edge
* list used to survive permanently into the sparse CSR structure
* (set_edge_from_triplets(), unw_core.do), even though this network's
* own declared selfloop policy is false (the default) - unlike the
* DENSE edge-matrix path (set_selfloop()/ensure_dense_built() both
* blank the diagonal via `_diag(e,.)' when isselfloop==0), the newer
* sparse-native construction path had no equivalent exclusion, so
* has_edge(i,i)/neighbors(i) wrongly reported a phantom self-tie for
* that node FOREVER, while get_matrix()/get_matrix_mod() correctly hid
* it once materialized fresh from the dense reconstruction - the two
* representations silently disagreed. Found via a real `nwwebuse
* glasgow' network (which has a genuine self-loop row in its own raw
* edge list): calculate_triadcensus() returned fractional triad counts
* (e.g. 14.667 instead of an integer) because Pass B's hub/neighbor
* enumeration treated a node as tied to itself, corrupting its own
* canonicalization logic - nwclustering's transitivity was silently
* wrong too (.798 instead of the correct .479), since it also relies on
* the sparse-native neighbor accessors. Fixed by defaulting
* `isselfloop' to 0 when still missing at construction time (none of
* this method's three callers - nwfromedge/nw2project/nwattime - ever
* set it beforehand) and filtering ego==alter rows out alongside the
* existing zero-weight filter.
nwclear
clear
set obs 3
gen x = "P"
gen y = "Q"
replace x = "Q" in 2
replace y = "R" in 2
replace x = "S" in 3
replace y = "S" in 3
nwfromedge x y, name(selfloopedge)
nwsummarize selfloopedge
assert r(arcs) == 2
assert r(selfloops) == 0
_nwsyntax selfloopedge
mata:
__any_selfloop = 0
for (__i=1; __i<=`nodes'; __i++) {
	if (`netobj'->has_edge(__i,__i)) __any_selfloop = 1
}
st_numscalar("any_selfloop", __any_selfloop)
end
assert any_selfloop == 0
di "=== nwfromedge: self-loop row correctly excluded from sparse structure REGRESSION VERIFIED ==="

* --- BUGFIX regression (adversarial-input pressure test): if every
* single row's own ego/alter id was missing, egen group() leaves the
* dictionary's own _id missing too, so the merge still matches
* (missing-to-missing, not dropped) and fromvar/tovar end up missing
* for every row rather than being removed - sum(fromvar) if fromvar!=.
* then succeeds with r(N)==0/r(max) missing, and that missing value
* used to be passed as a Mata J() dimension argument, crashing with a
* raw "argument out of range" (r3300) instead of a clean message.
nwclear
clear
set obs 3
gen x = .
gen y = .
capture noisily nwfromedge x y
assert _rc == 2000
di "=== nwfromedge: all-missing ids REGRESSION VERIFIED ==="




