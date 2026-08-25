cscript

clear mata
do unw_core.do
set more off

nwclear
nw2set, mat(J(4,4,2)) 
nwsummarize

assert `"`r(mode2)'"'    == `"true"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4,n5,n6,n7,n8"'
assert `"`r(valued)'"'   == `"true"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4 n5 n6 n7 n8"'

assert 		   r(density)       == 1
assert         r(edges_sum)     == 32
assert         r(edges)         == 16
assert         r(maxval)        == 2
assert         r(minval)        == 2
assert         r(missing_edges) == 32
assert         r(selfloops)     == 0
assert         r(nodes)         == 8
assert         r(id)            == 1


nwclear
set obs 4
gen x = 1
gen y = 2
replace y = 3 in 2
nw2set x y, edgelist
nwsummarize

assert `"`r(mode2)'"'    == `"true"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"n1,n2,n3"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3"'

assert         r(nodes2)        == 2
assert         r(nodes1)        == 1
assert         r(nodes)         == 3
assert         r(density)       == 1
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 5
assert         r(selfloops)     == 0
assert         r(id)            == 1



nwclear
set obs 3
gen x = 1
gen y = 2
gen names = "A" 
replace names = "B" in 2
replace names = "C" in 3
replace y = 3 in 2
nw2set x y, rownames(names)
nwsummarize

assert `"`r(mode2)'"'    == `"true"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"x,y,A,B,C"'
assert `"`r(valued)'"'   == `"true"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"x y A B C"'

assert         r(nodes2)        == 3
assert         r(nodes1)        == 2
assert         r(nodes)         == 5
assert         r(density)       == 1
assert         r(edges_sum)     == 10
assert         r(edges)         == 6
assert         r(maxval)        == 3
assert         r(minval)        == 1
assert         r(missing_edges) == 13
assert         r(selfloops)     == 0
assert         r(id)            == 1






