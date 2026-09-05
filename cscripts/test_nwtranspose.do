cscript

do unw_core.do

nwclear
nwset, mat((0,1,0\0,0,0\0,0,0)) name(mynet)
nwvalue mynet[1,2]
assert `r(value)' == 1

nwvalue mynet[2,1]
assert `r(value)' == 0

nwtranspose mynet
nwvalue mynet[1,2]
assert `r(value)' != 1

nwvalue mynet[2,1]
assert `r(value)' != 0








* --- alpha-audit regression: generate() on a colliding name used to
* silently corrupt the pre-existing network of that name (nwduplicate's
* own silent auto-rename left this command operating on the wrong
* network) - now errors unless replace() is given, matching nwsubset's
* own established collision convention.
nwclear
nwset, mat((0,1\0,0)) name(net1)
nwset, mat((1,0\0,1)) name(net2)
capture noisily nwtranspose net1, generate(net2)
assert _rc == 483  // errNWsExists - consolidated from the old ad-hoc 6099 during the error-code coherence pass
nwvalue net2[2,1]
assert r(value) == 0
nwtranspose net1, generate(net2) replace
nwvalue net2[2,1]
assert r(value) == 1
di "=== generate() collision REGRESSION VERIFIED ==="

* moderate-severity pass, generators_derived group: naming consistency -
* every other command in this group uses name() to name a new output
* network; nwtranspose alone used generate(). Added name() as a working
* alias, kept generate() for backward compatibility.
nwclear
nwset, mat((0,1,0\0,0,1\0,0,0)) name(net3) directed
nwtranspose net3, name(net3_t)
assert _rc == 0
capture noisily nwtranspose net3, generate(a) name(b)
assert _rc == 198
di "=== name()/generate() alias REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwtranspose nonexistent
assert _rc == 482
