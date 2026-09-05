cscript

clear mata
mata: mata desc
do unw_core.do
unw_defs

set more off

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = 0
gen v4 = 0
nwset v*, name("mynet1")

drop _all
nwload
assert v2[3] == 1

gen z = _N - _n
sort z
nwload
assert v2[3] == 1

nwclear
nwset, mat(J(6,6,2)) name("mynet2")
_nwsyntax
mata: `netobj'->edge[3,1]=999

nwload mynet2
assert `cDftNodepref'1[3] == 999

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwload nonexistent
assert _rc == 482

