cscript

clear mata
do unw_core.do
set more off

nwclear
nwring 20, k(2)
nwdegree
sum _indegree
assert         r(sum)   == 80
assert         r(max)   == 4
assert         r(min)   == 4
assert         r(sd)    == 0
assert         r(Var)   == 0
assert         r(mean)  == 4
assert         r(sum_w) == 20
assert         r(N)     == 20

nwclear
nwring 20, k(3)
nwdegree
sum _indegree
assert         r(sum)   == 120
assert         r(max)   == 6
assert         r(min)   == 6
assert         r(sd)    == 0
assert         r(Var)   == 0
assert         r(mean)  == 6
assert         r(sum_w) == 20
assert         r(N)     == 20

nwclear
nwring 20, k(3) weights(0,1)
nwdegree, alpha(1)
sum _instrength
assert         r(sum)   == 240
assert         r(max)   == 12
assert         r(min)   == 12
assert         r(sd)    == 0
assert         r(Var)   == 0
assert         r(mean)  == 12
assert         r(sum_w) == 20
assert         r(N)     == 20

















