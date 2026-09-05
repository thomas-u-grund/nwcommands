cscript

do unw_core.do

* r(netlist)/r(networks) below are NOT nwvalidate's own documented
* results (see nwvalidate.sthlp's own "Stored results" - only
* r(exists)/r(tryname)/r(validname)) - they were nwrandom's own
* leftover r() state, incidentally still visible only because
* nwvalidate.ado happens to poke its own r() macros directly via Mata
* rather than going through a `return clear'-triggering dispatch.
* That incidental survival is NOT a documented cross-command contract
* and is not guaranteed to survive every possible internal call chain
* (e.g. through nwload/_nwdatasync's own, much deeper internal r()
* bookkeeping) - dropped from this test accordingly; only nwvalidate's
* own actual, documented stored results are asserted below.
nwclear
nwrandom 7, density(1) name(mynet)
nwvalidate mynet

assert `"`r(exists)'"'    == `"true"'
assert `"`r(validname)'"' == `"mynet_1"'
assert `"`r(tryname)'"'   == `"mynet"'

nwvalidate network
assert `"`r(exists)'"'    == `"false"'
assert `"`r(validname)'"' == `"network"'
assert `"`r(tryname)'"'   == `"network"'

* --- failure path: `netname' is a required positional argument -
* calling with none is rejected by Stata's own syntax parser, not
* silently treated as an empty string.
capture noisily nwvalidate
assert _rc != 0



