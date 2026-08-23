cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 
nwset
assert `r(networks)' == 1
gen x = "test"
nwpreserve

nwclear
nwset
assert `r(networks)' == 0
assert `=_N' == 0

nwrestore
assert `=_N' == 7
assert x[1] == "test"

