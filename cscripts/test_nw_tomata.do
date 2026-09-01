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

* --- failure path: a misspelled/nonexistent network name is rejected
* with this command's own clean error (482, see nw_tomata.ado's own
* header comment), not a raw Mata "subscript invalid" (r3301) crash.
capture noisily nw_tomata bogusnet123, mat(z2)
assert _rc == 482





