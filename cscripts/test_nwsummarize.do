cscript

do unw_core.do

set obs 4
gen x = 1
gen y = 0
gen z = 0
nwset x y z

nwsummarize
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"x,y,z"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"x y z"'

assert         r(nodes)         == 3
assert reldif( r(density)        , .3333333333333333 ) <  1E-8
assert         r(arcs_value)    == 2
assert         r(arcs)          == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(id)            == 1

nwsym
nwsummarize, detail

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"x,y,z"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"x y z"'

assert         r(nodes)         == 3
assert         r(reciprocity)   == 1
assert         r(transitivity)  == 0
assert reldif( r(density)        , .6666666666666666 ) <  1E-8
assert         r(dg_central)    == 1
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(id)            == 1

tempfile f
nwsummarize, save(`f')
use `f', clear
assert edges[1] == 2

nwsummarize, mat
