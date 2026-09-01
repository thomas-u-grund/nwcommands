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


















* --- alpha-audit regression: ntimes()>1 used to crash unconditionally
* (a stray, undeclared stub() option in the recursive self-call, r198)
* and, separately, silently dropped weights() even once that crash was
* fixed. Both confirmed fixed directly.
nwclear
set seed 42
nwring 10, k(2) ntimes(2) weights(0,0,1)
assert _rc == 0
nwsummarize ring_1
assert r(maxval) == 3
nwsummarize ring_2
assert r(maxval) == 3
di "=== ntimes()>1 + weights() REGRESSION VERIFIED ==="

* moderate-severity pass, generators_structural group: r(netlist) parity
* with nwrandom (the only sibling generator that already exposed it).
nwclear
nwring 10, k(2)
assert `"`r(netlist)'"' == `"ring"'
nwclear
nwring 10, k(2) ntimes(3)
assert `"`r(netlist)'"' == `"ring_1 ring_2 ring_3"'

* --- failure paths: k() is a required option (rejected by Stata's own
* syntax parser without it); an explicit, caller-chosen name() that
* collides with an already-loaded network is rejected (unlike the
* default unnamed case, which auto-increments - "ring", "ring_1", ...).
capture noisily nwring 10
assert _rc != 0

nwclear
nwring 10, k(2) name(explicitring)
capture noisily nwring 10, k(2) name(explicitring)
assert _rc != 0
di "=== r(netlist) REGRESSION VERIFIED ==="
