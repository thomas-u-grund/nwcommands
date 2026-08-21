cscript

do unw_core.do

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nw2toedge
assert _N == 24

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
gen x = _n
replace x = x + 100 if _nwmode == "2"
nw2toedge , egovars(x) altervars(x)
sum x_ego
assert `r(min)' >= 100

nwclear
nw2set, mat(J(6,4,1)) name(mynet) 
gen x = _n
replace x = x + 100 if _nwmode == "2"
nw2toedge , egovars(x) altervars(x) ego(ich) alter(du)
gen x = _n

