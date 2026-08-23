cscript

do unw_core.do

nwclear
nwset, mat((0,1,0\0,0,0\0,0,0)) name(mynet)
nwvalue mynet[1,2]
assert `r(value)' == 1

nwvalue mynet[2,1]
assert `r(value)' == 0

nwtranspose mynet
nwvalue mynet[1,2]
assert `r(value)' != 1

nwvalue mynet[2,1]
assert `r(value)' != 0







