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

