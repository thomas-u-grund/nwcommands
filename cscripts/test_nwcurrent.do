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




