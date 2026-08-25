cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 

tempfile f
nwsave `f'
nwclear
nwset
assert         r(networks) == 0

capture nwuse `f'
nwset
assert `"`r(nets)'"' == `" mynet"'
assert         r(networks) == 1

capture nwuse `f'
assert _rc != 0

nwwebuse florentine, nwappend
assert _rc == 0
nwset

assert `"`r(nets)'"' == `" mynet flobusiness flomarriage"'

assert         r(networks) == 3

