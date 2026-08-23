cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 
nwvalidate mynet

assert `"`r(exists)'"'    == `"true"'
assert `"`r(validname)'"' == `"mynet_1"'
assert `"`r(tryname)'"'   == `"mynet"'
assert `"`r(netlist)'"'   == `"mynet"'
assert `"`r(networks)'"'  == `"1"'

nwvalidate network
assert `"`r(exists)'"'    == `"false"'
assert `"`r(validname)'"' == `"network"'
assert `"`r(tryname)'"'   == `"network"'
assert `"`r(netlist)'"'   == `"mynet"'
assert `"`r(networks)'"'  == `"1"'



