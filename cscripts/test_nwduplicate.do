cscript

do unw_core.do

nwclear
nwrandom 4, density(1) name(mynet) labs(x1,x2,x3,x4)
nwduplicate
nwset

assert `"`r(nets)'"' == `" mynet mynet_copy"'
assert         r(networks) == 2

drop _all
nwload mynet_copy
capture confirm variable x1
assert _rc == 0

