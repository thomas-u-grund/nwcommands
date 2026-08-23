cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet1) 
nwreplace mynet1[2,3] = 99
nwvalue mynet1[2,3]
assert         r(value) == 99

nwreplace mynet1[.,3] = 55
nwvalue mynet1[1,3]
assert         r(value) == 55

nwreplace mynet1 = 77 ifego _n < 3
nwvalue mynet1[1,2]
assert r(value) == 77

nwvalue mynet1[4,5]
assert r(value) == 1

nwreplace mynet1 = 88 ifalter _n > 3
nwvalue mynet1[1,4]
assert r(value) == 88


nwrandom 7, density(1) name(mynet2)
nwreplace mynet1 = mynet2 * exp(mynet1)
nwvalue mynet1[2,3]
assert         r(value) < 2.76e+33
assert         r(value) > 2.74e+33

gen x = 2
nwreplace mynet1 = mynet1 * x * 2
nwvalue mynet1[2,3]
assert         r(value) < 1.104e+34
assert         r(value) > 1.102e+34
