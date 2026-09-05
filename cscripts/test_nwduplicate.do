cscript

do unw_core.do

nwclear
nwrandom 4, density(1) name(mynet) labs(x1,x2,x3,x4)
nwduplicate
nwset

assert `"`r(nets)'"' == `" mynet mynet_copy"'
assert         r(networks) == 2

drop _all
nwload mynet_copy
capture confirm variable x1
assert _rc == 0

* moderate-severity pass, generators_structural group: an explicit,
* colliding name() used to silently auto-rename ("fixedcopy" ->
* "fixedcopy_1") instead of erroring like every sibling generator
* (nwrandom/nwpref/nwlattice/nwring/nwsmall) - and there was no
* `replace' option to make overwriting possible on purpose.
nwclear
nwrandom 6, prob(.5) name(dn3)
nwduplicate dn3, name(fixedcopy)
assert _rc == 0
capture noisily nwduplicate dn3, name(fixedcopy)
assert _rc == 483
nwduplicate dn3, name(fixedcopy) replace
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" dn3 fixedcopy"'
di "=== explicit name() collision REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwduplicate nonexistent
assert _rc == 482

