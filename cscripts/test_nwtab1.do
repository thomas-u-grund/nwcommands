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
