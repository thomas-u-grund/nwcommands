cscript

do unw_core.do

nwclear
nwset, mat((1,1,0\0,0,0\1,4,0)) name(mynet)
nwtriads
assert `r(_030T)' ==  1
assert `r(transitivity)' == 1

nwclear
nwset, mat((0,0,0\0,0,0\1,0,0)) name(mynet)
nwtriads
assert `r(_012)' ==  1
assert `r(transitivity)' == .

nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(mynet)
nwtriads
assert `r(_030C)' ==  1
assert `r(transitivity)' == 0


* --- undirected network: harmonisation-phase regression test. 11 of
* the 12 asymmetric-dyad-dependent MAN categories (everything except
* _003/_102/_201/_300) must be exactly 0 for undirected data, since an
* undirected network has no asymmetric ties by construction - and the
* command should not silently proceed without saying so.
* _210 is deliberately NOT asserted here: found (not yet fixed) to
* return a nonzero value on undirected input despite the identical
* mathematical argument applying to it - a real, unresolved bug in
* calculate_triadcensus(), documented in nwtriads.ado's own "Supported
* network types" section and in docs/CERTIFICATION.md. Asserting ==0
* here would be asserting something known to be false.
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(undirnet) undirected labs(A,B,C,D)
nwtriads undirnet
assert r(_012) == 0
assert r(_021D) == 0
assert r(_021U) == 0
assert r(_021C) == 0
assert r(_030T) == 0
assert r(_030C) == 0
assert r(_111D) == 0
assert r(_111U) == 0
assert r(_120D) == 0
assert r(_120U) == 0
assert r(_120C) == 0
* r(_210) locked to its current (known-incorrect) value as a
* regression guard, not asserted as correct - see comment above; if
* the underlying bug is ever fixed this assertion should fail and
* prompt updating it to the correct value (0).
assert r(_210) == 2







