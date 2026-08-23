cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 

tempfile f
nwsave `f'

nwclear
nwset
assert `r(networks)' == 0

nwuse `f'.nwdta
nwset
assert `r(networks)' != 0

