cscript

do unw_core.do

nwclear
nwrandom 10, prob(1) name(mynet1)
// nwcollapse (like nwtoedge, which it calls internally) is a consumer,
// not a generator - it has no xvars option of its own and assumes the
// network is already materialized as Stata variables, unlike every
// generator command above it in this chain. Explicit nwload needed
// now that generators no longer auto-load by default.
nwload mynet1
nwreplace mynet1[1,3] = 0
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"mynet1"'
assert `"`r(name)'"'     == `"mynet1"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4,n5,n6,n7,n8,n9,n10"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4 n5 n6 n7 n8 n9 n10"'

assert reldif( r(density)        , .9888888888888889 ) <  1E-8
assert         r(arcs_value)    == 89
assert         r(arcs)          == 89
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 10
assert         r(selfloops)     == 0
assert         r(nodes)         == 10
assert         r(id)            == 1


gen x = _n
replace x = 1 in 2
nwcollapse (max) mynet1, by(x)

nwsummarize
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"mynet1"'
assert `"`r(name)'"'     == `"mynet1"'
assert `"`r(labs)'"'     == `"n10,n3,n4,n5,n6,n7,n8,n9,new_n1"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n10 n3 n4 n5 n6 n7 n8 n9 new_n1"'

assert         r(nodes)         == 9
assert         r(density)       == 1
// This first collapse happens to leave a symmetric (every remaining
// pair tied both ways) result, which nwsummarize reports as undirected
// (r(edges)/r(edges_sum), not r(arcs)/r(arcs_value)) - unlike the
// original network above and the two further collapses below, both of
// which stay directed. A pre-existing test-authoring bug: this used to
// check r(arcs)/r(arcs_value) == 72 (double-counting each undirected
// edge once per direction), never actually reached before nwcollapse's
// own (unrelated) xvars-consistency fix elsewhere in this file let the
// test run this far for the first time.
assert         r(edges_sum)     == 36
assert         r(edges)         == 36
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 9
assert         r(selfloops)     == 0
assert         r(id)            == 2


nwclear
nwrandom 10, prob(1) name(mynet1)
nwreplace mynet1[1,3] = 0

gen x = _n
replace x = 1 in 2
nwcollapse (min) mynet1, by(x)
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"mynet1"'
assert `"`r(name)'"'     == `"mynet1"'
assert `"`r(labs)'"'     == `"n10,n3,n4,n5,n6,n7,n8,n9,new_n1"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n10 n3 n4 n5 n6 n7 n8 n9 new_n1"'

assert reldif( r(density)        , .9861111111111112 ) <  1E-8
assert         r(arcs_value)    == 71
assert         r(arcs)          == 71
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 9
assert         r(selfloops)     == 0
assert         r(nodes)         == 9
assert         r(id)            == 2

nwclear
nwrandom 10, prob(1) name(mynet1)
nwreplace mynet1[1,4] = 0

gen x = _n
replace x = 1 if _n < 4
nwcollapse (min) mynet1, by(x)
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"mynet1"'
assert `"`r(name)'"'     == `"mynet1"'
assert `"`r(labs)'"'     == `"n10,n4,n5,n6,n7,n8,n9,new_n1"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n10 n4 n5 n6 n7 n8 n9 new_n1"'

assert reldif( r(density)        , .9821428571428571 ) <  1E-8
assert         r(arcs_value)    == 55
assert         r(arcs)          == 55
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 8
assert         r(selfloops)     == 0
assert         r(nodes)         == 8
assert         r(id)            == 2

* moderate-severity pass, manipulation_transform group: collapsing a
* two-mode network used to silently produce a result reported as an
* ordinary one-mode network (mode2 flipped from true to false), with no
* error or warning. Now rejected outright.
nwclear
set obs 4
gen ego="Peter"
gen alter="LiU"
replace ego="Thomas" in 2
replace alter="LiU" in 2
replace ego="Peter" in 3
replace alter="Oxford" in 3
replace ego="Thomas" in 4
replace alter="Oxford" in 4
nw2fromedge ego alter, name(twomodenet)
nwload twomodenet
gen grp = mod(_n,2)
capture noisily nwcollapse (max) twomodenet, by(grp)
assert _rc == 6088
di "=== two-mode rejection REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwcollapse (max) nonexistent, by(grp)
assert _rc == 482

