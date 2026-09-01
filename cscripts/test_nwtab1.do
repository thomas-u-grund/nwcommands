cscript

do unw_core.do

nwclear
set obs 10
gen x = _n
gen y = 1
gen value = 1
nwset x y value, edgelist name(mynet)

nwtabulate mynet, matcell(m)
assert 		m[1,1] == 81
assert 		m[2,1] == 9
assert      r(r) == 2


nwclear
set obs 10
gen x = _n
gen y = 1
gen value = 1
replace value = 2 if _n > 7
nwset x y value, edgelist name(mynet)

nwtabulate mynet, matcell(m)
assert 		m[1,1] == 81
assert 		m[2,1] == 6
assert 		m[3,1] == 3

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482). Reached
* through the public nwtabulate() dispatcher, not a direct nwtab1 call
* - nwtab1 is a companion program defined inside nwtabulate.ado, not
* independently callable outside that dispatch (confirmed directly:
* even after a prior successful nwtabulate call in the same session, a
* bare "nwtab1 ..." still raises a plain "command unrecognized").
capture noisily nwtabulate nonexistent
assert _rc == 482
