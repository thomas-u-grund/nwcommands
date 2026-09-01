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
* is a required-option-combination failure (error 198, Stata's own
* reserved code for this, per unw_defs.ado's registry); an out-of-range
* egoid()/alterid() is rejected with the new errNodeNotFound (485), the
* same code an invalid ego()/alter() name uses, not silently treated as
* an empty result (BUGFIX: this used to fall through with no error at
* all - _rc==0 and a missing r(value) - confirmed directly before this
* fix). BUGFIX (error-code coherence, found alongside the above): all
* four of these used to raise the bare literal `error 3000' - Stata's
* OWN reserved code for "Mata compile-time error", producing a
* confusing extra "Mata compile-time error" line alongside this
* command's real message on every single one of these failures
* (confirmed directly, matching the exact anti-pattern nwsimmelian.ado's
* own comment already identified and fixed for an unrelated case) -
* fixed to use 198/errNodeNotFound as appropriate instead.
capture noisily nwvalue flobusiness
assert _rc == 198

capture noisily nwvalue flobusiness, egoid(999) alterid(1)
assert _rc == 485

capture noisily nwvalue flobusiness, egoid(1) alterid(999)
assert _rc == 485

capture noisily nwvalue flobusiness, egoid(0) alterid(1)
assert _rc == 198
