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

* moderate-severity pass, import_export group: full/upper/compress/
* ignore2mode had no regression coverage at all before this.
nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nw2toedge, full
assert _N == 48

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nw2toedge, upper
assert _N == 24

nwclear
nw2set, mat((1,0,1,0 \ 0,1,0,1 \ 1,1,0,0 \ 0,0,1,1 \ 1,0,0,0 \ 0,1,1,0)) name(sparsenet)
nw2toedge, compress
assert _N == 11

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nw2toedge, ignore2mode
assert _rc == 0
capture confirm variable _nwmode_ego
assert _rc != 0
capture confirm variable _nwmode_alter
assert _rc != 0

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nw2toedge nonexistent
assert _rc == 482

