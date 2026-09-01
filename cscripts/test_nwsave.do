cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 

tempfile f
nwsave `f'

nwclear
nwset
assert `r(networks)' == 0

nwuse `f'.nwdta
nwset
assert `r(networks)' != 0

* --- failure path: saving to a filename that already exists without
* `replace' is rejected (ordinary Stata `save' semantics, propagated
* through unchanged) - and succeeds once `replace' is given.
nwclear
nwrandom 5, prob(1) name(mynet2)
tempfile g
nwsave `g'
capture noisily nwsave `g'
assert _rc != 0

* --- regression: a failed save used to abort nwsave before it restored
* the caller's own in-memory dataset, leaving stray internal columns
* (_nw_running etc.) behind - confirmed here that the dataset in memory
* is unaffected by the failed attempt (still just the plain nwrandom
* network, no _nw_* leftovers), and that a corrected retry with
* `replace' still works afterwards rather than tripping over that debris.
capture confirm variable _nw_running
assert _rc != 0
qui nwset
assert `"`r(nets)'"' == `" mynet2"'

nwsave `g', replace
assert _rc == 0

