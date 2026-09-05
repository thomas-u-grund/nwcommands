cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet)

nwrandom 5, prob(1) name(a)

nwds
assert `"`r(netlist)'"' == `"mynet a"'

nwds, alpha
assert `"`r(netlist)'"' == `"a mynet"'

nwds m*
assert `"`r(netlist)'"' == `"mynet"'

* moderate-severity pass, misc_analysis group: `not' was captured but
* never referenced anywhere in the program body - r(netlist) used to be
* identical whether or not it was specified.
nwds mynet, not
assert `"`r(netlist)'"' == `"a"'

nwds a, not
assert `"`r(netlist)'"' == `"mynet"'

nwds, not
assert `"`r(netlist)'"' == `""'

nwds mynet, not alpha
assert `"`r(netlist)'"' == `"a"'
di "=== nwds not-option REGRESSION VERIFIED ==="

* --- failure paths: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482, unw_defs.ado's
* own errNWsNotFound), not silently treated as an empty match.
capture noisily nwds nonexistent
assert _rc == 482

capture noisily nwds nonexistent, not
assert _rc == 482

nwclear
capture noisily nwds
assert _rc == 482


