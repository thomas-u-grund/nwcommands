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

* --- failure paths: `using' is a required argument (rejected by
* Stata's own syntax parser without it); a genuinely nonexistent file
* is rejected via nwuse's own "could not load" error (601).
capture noisily nwappend
assert _rc != 0

capture noisily nwappend using nonexistent_file_xyz_123
assert _rc == 601


