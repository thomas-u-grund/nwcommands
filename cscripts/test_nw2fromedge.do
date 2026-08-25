cscript
nwclear

do unw_core.do

set obs 2
gen x = 1
gen y = 1
replace y = 2 in 2
nw2fromedge x y
nwsummarize

assert `"`r(mode2)'"'    == `"true"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"n1,n2,n3"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3"'

assert 		   r(density)       == 1
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 5
assert         r(selfloops)     == 0
assert         r(nodes)         == 3
assert         r(id)            == 1


nwclear
set obs 3
gen x = "A"
gen y = "A"
replace y = "z" in 2
replace x = "B" in 2
nw2fromedge x y
nwsummarize

assert `"`r(mode2)'"'    == `"true"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(labs)'"'      == `"m1_A,m1_B,m2_A,m2_z"'

assert         r(nodes2)        == 2
assert         r(nodes1)        == 2
assert reldif( r(density)        , .5                ) <  1E-8
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 8
assert         r(selfloops)     == 0
assert         r(nodes)         == 4
assert         r(id)            == 1




