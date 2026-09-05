cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet) labs(p1, p2, p3)
nwnode, ego("p2")

* --- failure paths: neither ego() nor egoid() given (err 99, this
* command's own explicit guard); egoid() out of the valid 1..nodes
* range (err 99); a name that isn't a loaded network (error 482, via
* _nwsyntax).
capture noisily nwnode
assert _rc == 99

capture noisily nwnode, egoid(999)
assert _rc == 99

capture noisily nwnode, egoid(0)
assert _rc == 99

capture noisily nwnode nonexistent, ego("p2")
assert _rc == 482






