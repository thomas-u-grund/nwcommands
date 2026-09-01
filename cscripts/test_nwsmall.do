cscript

clear mata
do unw_core.do
set more off

nwclear
nwsmall 20, k(2) prob(.0)
mata: z = (*nw.nws.pdefs[1]->get_matrix())[1,8]
mata: st_numscalar("z", z)
assert z == 0

nwclear
nwsmall 20, k(2) shortcuts(3)

nwclear
nwsmall 20, k(2) prob(0.0) weights(0,0,1)
nwvalue small[1,2]
assert r(value) == 3











* --- regression guard: name() was declared nowhere in this command's
* own syntax line despite the body already referencing it (defaulting
* to the hardcoded "small" every time, silently ignoring any name()
* a caller tried to pass) - found while restoring nwgenerate's own
* small() shortcut, which depends on this actually working. Checked
* directly: the requested name must be honoured, not silently replaced
* with the old hardcoded default.
nwclear
nwsmall 15, k(2) prob(.0) name(mysmallnet)
assert _rc == 0
nwname mysmallnet
assert _rc == 0
capture noisily nwname small
assert _rc != 0

* --- alpha-audit regression: ntimes()>1 used to crash unconditionally
* (a stray, undeclared stub() option in the recursive self-call, r198)
* and, separately, silently dropped weights() even once that crash was
* fixed. Both confirmed fixed directly.
nwclear
set seed 42
nwsmall 10, k(2) prob(.1) ntimes(2) weights(0,0,1)
assert _rc == 0
nwsummarize small_1
assert r(maxval) == 3
nwsummarize small_2
assert r(maxval) == 3
di "=== ntimes()>1 + weights() REGRESSION VERIFIED ==="

* moderate-severity pass, generators_structural group: r(netlist) parity
* with nwrandom (the only sibling generator that already exposed it).
nwclear
nwsmall 10, k(2) prob(.1)
assert `"`r(netlist)'"' == `"small"'
nwclear
nwsmall 10, k(2) prob(.1) ntimes(3)
assert `"`r(netlist)'"' == `"small_1 small_2 small_3"'
di "=== r(netlist) REGRESSION VERIFIED ==="

* --- failure paths (BUGFIX: all three of these used to print their own
* clear error message and then either fall through to actually
* generating a network anyway, or silently do nothing - either way
* returning _rc==0 as if nothing were wrong, confirmed directly before
* this fix): neither prob() nor shortcuts() given; prob() out of the
* valid [0,1] range; a name that isn't a loaded network (via k()'s own
* nw_syntax passthrough inside the ntimes()==1 non-recursive path is
* not applicable here since nwsmall is a pure generator with no network
* argument - the relevant failure is the option validation above).
nwclear
capture noisily nwsmall 10, k(2)
assert _rc != 0
qui nwset
assert r(networks) == 0

capture noisily nwsmall 10, k(2) prob(1.5)
assert _rc != 0
qui nwset
assert r(networks) == 0

capture noisily nwsmall 10, k(2) prob(-.1)
assert _rc != 0
qui nwset
assert r(networks) == 0

* --- failure path (BUGFIX: used to print the message and fall through
* to actually generating an unweighted network anyway, returning
* _rc==0 as if nothing were wrong - confirmed directly before this
* fix, same as the identical bug in nwrandom/nwring/nwpref/nwdyadprob).
capture noisily nwsmall 10, k(2) prob(.2) weights(abc,def)
assert _rc != 0
