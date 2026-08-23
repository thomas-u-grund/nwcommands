cscript

do unw_core.do

nwclear
nwrandom 10, prob(1) name(mynet1)
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
assert         r(arcs_value)    == 72
assert         r(arcs)          == 72
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

