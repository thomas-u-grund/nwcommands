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
nw_datasync mynet1
assert _nwnode[1] == "n1"



