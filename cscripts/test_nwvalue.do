cscript

do unw_core.do
nwwebuse florentine
nwvalue flobusiness, ego("medici") alter("pazzi")
return list
assert `"`r(alter)'"'    == `"pazzi"'
assert `"`r(ego)'"'      == `"medici"'
assert `"`r(netlist)'"'  == `"flobusiness"'
assert `"`r(networks)'"' == `"1"'

assert         r(value)       == 1
assert         r(alter_id)    == 10
assert         r(ego_id)      == 9
assert         r(alter_valid) == 1
assert         r(ego_valid)   == 1
assert         r(id)          == 1

capture nwvalue flobusiness, ego(9) alter(2)
assert _rc != 0


capture nwvalue flobusiness, egoid(9) alterid(2)

assert `"`r(alter)'"'    == `"albizzi"'
assert `"`r(ego)'"'      == `"medici"'
assert `"`r(netlist)'"'  == `"flobusiness"'
assert `"`r(networks)'"' == `"1"'

assert         r(alter_id) == 2
assert         r(ego_id)   == 9
assert         r(value)    == 0
assert         r(id)       == 1
