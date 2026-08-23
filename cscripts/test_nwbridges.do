cscript

clear mata
do unw_core.do
set more off
set obs 6
gen x = _n
gen y = 2
replace x = 1 in 2
replace y = 4 in 2
replace y = 5 in 1
replace x = 5 in 6
replace y = 1 in 6
nwset x y, edgelist


nwbridges

assert `"`r(bridges_type)'"' == `"global"'
assert `"`r(bridges)'"'      == `"5"'
assert `"`r(directed)'"'     == `"true"'
assert `"`r(name)'"'         == `"network"'
assert `"`r(netlist)'"'      == `"network"'
assert `"`r(networks)'"'     == `"1"'

nwbridges n*, nwreplace type(local)

assert `"`r(bridges_type)'"' == `"local"'
assert `"`r(bridges)'"'      == `"6"'
assert `"`r(directed)'"'     == `"true"'
assert `"`r(name)'"'         == `"network"'
assert `"`r(netlist)'"'      == `"network"'
assert `"`r(networks)'"'     == `"1"'

