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

* --- failure paths: neither ego()/alter() nor egoid()/alterid() given
* (error 3000, this command's own explicit guard); an out-of-range
* egoid()/alterid() is rejected the same way as an invalid ego()/
* alter() name, not silently treated as an empty result (BUGFIX: this
* used to fall through with no error at all - _rc==0 and a missing
* r(value) - confirmed directly before this fix).
capture noisily nwvalue flobusiness
assert _rc == 3000

capture noisily nwvalue flobusiness, egoid(999) alterid(1)
assert _rc == 3000

capture noisily nwvalue flobusiness, egoid(1) alterid(999)
assert _rc == 3000

capture noisily nwvalue flobusiness, egoid(0) alterid(1)
assert _rc == 3000
