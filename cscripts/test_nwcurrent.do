cscript

do unw_core.do

nwclear
nwrandom 10, prob(.1) name(mynet1)
nwrandom 10, prob(.1) name(mynet2)

nwcurrent
assert r(current) == "mynet2"

nwcurrent mynet1
assert r(current) == "mynet1"

nwcurrent mynet1, id(2)
assert r(current) == "mynet2"

nwcurrent mynet1, id(1)
assert r(current) == "mynet1"

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482), before ever
* reaching make_current_from_name().
capture noisily nwcurrent nonexistent
assert _rc == 482

nwclear
capture noisily nwcurrent
assert _rc != 0




