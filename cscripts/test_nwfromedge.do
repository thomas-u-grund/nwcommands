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
// at the time; separately, this exercise also depends on nw_syntax's
// own `directed' export not clobbering nwfromedge's own option-parsing
// locals of the same name, fixed via nw_syntax's other() prefixing).
nwclear
clear
input str1 ego str1 alter
"A" "B"
"B" "A"
"B" "C"
"C" "B"
end
nwfromedge ego alter, name(symnet)
nw_syntax symnet
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
nw_syntax zeronet
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
assert _rc == 6099
nwsummarize zeronet
assert r(nodes) == 3

nwfromedge ego alter, name(zeronet) replace
assert _rc == 0
nwsummarize zeronet
assert r(nodes) == 4




