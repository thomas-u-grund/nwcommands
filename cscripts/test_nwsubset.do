cscript

do unw_core.do

nwclear
nwrandom 10, prob(1) name(mynet)
nwreplace mynet[1,3] = 0

nwsubset mynet if _n != 1, name(sub)
nwsummarize sub
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"sub"'
assert `"`r(name)'"'     == `"sub"'
assert `"`r(labs)'"'     == `"n2,n3,n4,n5,n6,n7,n8,n9,n10"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n2 n3 n4 n5 n6 n7 n8 n9 n10"'

assert         r(density)       == 1
assert         r(arcs_value)    == 72
assert         r(arcs)          == 72
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 9
assert         r(selfloops)     == 0
assert         r(nodes)         == 9
assert         r(id)            == 2

nwsubset mynet if _n != 2, name(sub) replace
nwsummarize sub

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"sub"'
assert `"`r(name)'"'     == `"sub"'
assert `"`r(labs)'"'     == `"n1,n3,n4,n5,n6,n7,n8,n9,n10"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n3 n4 n5 n6 n7 n8 n9 n10"'

assert reldif( r(density)        , .9861111111111112 ) <  1E-8
assert         r(arcs_value)    == 71
assert         r(arcs)          == 71
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 9
assert         r(selfloops)     == 0
assert         r(nodes)         == 9
assert         r(id)            == 2


* --- alpha-audit regression: no-if call (documented "simply generates
* a duplicate") used to crash (r198); an if-condition matching zero
* nodes used to crash with an uncontrolled Mata error (r3300) instead
* of a clean message. Both fixed.
nwclear
nwrandom 5, prob(.5) name(dupbase)
capture noisily nwsubset dupbase, name(dupfull)
assert _rc == 0
nwset
assert r(networks) == 2

nwclear
nwrandom 5, prob(.5) name(zeronet)
capture noisily nwsubset zeronet if _n>100, name(subzero)
assert _rc == 198
nwset
assert r(networks) == 1
di "=== no-if / zero-node REGRESSION VERIFIED ==="

* moderate-severity pass, generators_derived group: nwsubset's own
* DEFAULT name (netname_sub, when name() is unspecified) used to
* hard-error on collision instead of auto-incrementing like every
* sibling in this group; an explicit, caller-chosen name() still
* requires replace on a genuine collision (now enforced by nwduplicate).
nwclear
nwrandom 6, prob(.5) name(mynet)
nwsubset mynet if _n<=4
assert _rc == 0
nwsubset mynet if _n<=3
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" mynet mynet_sub mynet_sub_1"'

nwclear
nwrandom 6, prob(.5) name(mynet2)
nwsubset mynet2 if _n<=4, name(fixedname)
assert _rc == 0
capture noisily nwsubset mynet2 if _n<=3, name(fixedname)
assert _rc == 483
nwsubset mynet2 if _n<=3, name(fixedname) replace
assert _rc == 0
di "=== default-name auto-increment / explicit-name collision REGRESSION VERIFIED ==="
