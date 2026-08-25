cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet)
nw_tomata, mat(z)
assert `"`r(adj_copy)'"' == `"z"'
assert `"`r(adj)'"'      == `"(*nw.nws.pdefs[1]->get_matrix())"'
assert `"`r(netobj)'"'   == `"nw.nws.pdefs[1]"'
assert `"`r(netname)'"'  == `"mynet"'

mata: assert(`r(adj)'[1,2] == 1)

mata: `r(adj_copy)'[1,2] = 99
mata: assert(`r(adj)'[1,2] == 1)





