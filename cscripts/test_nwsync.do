cscript

do unw_core.do

nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
nwload

nwreplace mynet[2,1] = 999
assert n1[2] == 999

replace n1 = 55
nwsync, fromstata

drop _all
nwload
assert n1[2] == 55

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwsync nonexistent
assert _rc == 482

