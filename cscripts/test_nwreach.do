cscript

do unw_core.do

nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
nwreach mynet
nwsummarize _reach
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"_reach"'
assert `"`r(name)'"'     == `"_reach"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4"'

assert reldif( r(density)        , .5                ) <  1E-8
assert         r(arcs_value)    == 6
assert         r(arcs)          == 6
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 4
assert         r(selfloops)     == 0
assert         r(nodes)         == 4
assert         r(id)            == 2

nwreach mynet, name(reachsym) sym
nwsummarize reachsym
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"reachsym"'
assert `"`r(name)'"'     == `"reachsym"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4"'

assert         r(density)       == 1
assert         r(edges_sum)     == 6
assert         r(edges)         == 6
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 4
assert         r(selfloops)     == 0
assert         r(nodes)         == 4
assert         r(id)            == 3

* --- alpha-audit regression: nwreach used to silently fail (r99, no
* message) whenever the dataset already had a variable named
* _eccentricity from a prior nwgeodesic ..., xvars call, because
* nwgeodesic's own eccentricity-guard used to run even when xvars
* wasn't requested (nwreach's own internal call never sets xvars) -
* see nwgeodesic's own identical regression case for the root-cause fix.
nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
nwgeodesic mynet, xvars
capture noisily nwreach mynet
assert _rc == 0
di "=== pre-existing eccvar REGRESSION VERIFIED ==="

* moderate-severity pass, paths_distance group: nwreach used to silently
* overwrite/destroy any pre-existing network under its target name with
* zero warning - unlike every sibling command in the group, which
* requires nwreplace before overwriting.
nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(net1) undirected labs(A,B,C)
nwduplicate net1, name(_reach)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(net2) undirected labs(X,Y,Z)
capture noisily nwreach net2
assert _rc == 99
nwsummarize _reach
assert r(nodes) == 3
nwreach net2, nwreplace
assert _rc == 0
di "=== silent-overwrite REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwreach nonexistent
assert _rc == 482
