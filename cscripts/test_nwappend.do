cscript

clear mata
mata: mata desc
do unw_core.do
unw_defs

tempfile mynet1
nwrandom 10, prob(.3) name(mynet1)
nwsave `mynet1', replace

nwrandom 10, prob(.8) name(mynet2)
capture nwappend using `mynet1'
assert _rc != 0

nwset
assert `"`r(nets)'"' == `" mynet1 mynet2"'
assert         r(networks) == 2

nwdrop mynet1
capture nwappend using `mynet1'
assert _rc == 0

nwset
assert `"`r(nets)'"' == `" mynet2 mynet1"'
assert         r(networks) == 2

nwappend using `mynet1', force

nwset
assert `"`r(nets)'"' == `" mynet2 mynet1 mynet1_1"'
assert         r(networks) == 3


