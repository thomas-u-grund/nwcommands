cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet)

nwrandom 5, prob(1) name(a)

nwds
assert `"`r(netlist)'"' == `"mynet a"'

nwds, alpha
assert `"`r(netlist)'"' == `"a mynet"'

nwds m*
assert `"`r(netlist)'"' == `"mynet"'





