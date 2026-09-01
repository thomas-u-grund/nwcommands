cscript

clear mata
do unw_core.do
set more off

nwclear
nwdyadprob, mat(J(5,5,1)) name(mynet)
nwvalue mynet[1,2]
assert r(value) == 1

nwdyadprob mynet
nwvalue mynet[1,2]
assert r(value) == 1










* --- alpha-audit regression: weights() was documented ("generates a
* weighted network") but never referenced anywhere in the program body
* - a complete no-op. Now implemented for the mat()-based path (the
* same rdiscrete()-based pattern nwrandom.ado/nwpref.ado already use);
* the density()-based path gives a clear error instead of silently
* ignoring weights(), pending its own dedicated implementation.
nwclear
set seed 100
mata: probmat = J(6,6,1)
nwdyadprob, mat(probmat) weights(0,0,1) name(w1) xvars undirected
nwsummarize w1
assert r(minval) == 3
assert r(maxval) == 3

nwclear
set seed 100
nwset, mat(J(8,8,5)) name(wbase)
capture noisily nwdyadprob wbase, weights(0.01 0.99) density(0.3) name(w2)
assert _rc == 198
di "=== weights() REGRESSION VERIFIED ==="

* moderate-severity pass, generators_derived group: mat() as a literal
* Mata expression (not an existing variable name) combined with
* undirected used to crash ("invalid lval", r3000) - the code tried to
* mutate mat()'s own raw text in place via lowertriangle(), which only
* works when it names a real, assignable Mata variable.
nwclear
capture noisily nwdyadprob, mat(J(5,5,.5)) name(undirtest) undirected xvars
assert _rc == 0
di "=== mat() literal expression + undirected REGRESSION VERIFIED ==="

* --- failure path (BUGFIX: used to print the message and fall through
* to actually generating an unweighted network anyway, returning
* _rc==0 as if nothing were wrong - confirmed directly before this
* fix, same as the identical bug in nwrandom/nwring/nwsmall/nwpref).
nwclear
capture noisily nwdyadprob, mat(J(5,5,.5)) name(wtest) weights(abc,def)
assert _rc != 0
