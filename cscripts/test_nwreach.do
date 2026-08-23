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
