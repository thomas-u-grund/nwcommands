cscript

do unw_core.do
nwrandom 5, prob(1) name(mynet1)

drop _all
set obs 2
gen ego = "A"
gen alter = "B"

nwfromedge ego alter
assert _nwnode[1] == "A"

nwload mynet1
assert _nwnode[1] == "n1"

gen x = _n
gsort - x

assert _nwnode[1] != "n1"
_nwdatasync mynet1
assert _nwnode[1] == "n1"

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily _nwdatasync nonexistent
assert _rc == 482



