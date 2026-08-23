cscript

do unw_core.do
nwrandom 5, prob(.2) 
nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte)
nwsummarize

assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"random"'
assert `"`r(name)'"'     == `"random"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4,n5,Thomas Grund,Peter,Mathilde Turcotte"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4 n5 Thomas_Grund Peter Mathilde_Turcotte"'


nwclear
nwrandom 5, prob(.2) name(mynet)
nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte) generate(newnet)
nwsummarize mynet
assert         r(nodes)         == 5

nwsummarize newnet
assert         r(nodes)         == 8
