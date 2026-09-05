cscript

clear mata
do unw_core.do
set more off

nwclear
// nwpref relies on Mata's RNG (prefattach()) with no seed control in this
// test previously, making results dependent on undocumented ambient RNG
// state rather than being a reproducible regression test. Pinned explicitly.
// (nwpref.ado already self-pins `version 9` internally as an ado program,
// so no do-file-level version statement is needed/wanted here.)
set seed 123
nwpref 20
nwdegree, generate(_outdegree _indegree)
sum _indegree
// Recalibrated (harmonisation phase, found while restoring nwgenerate's
// own pref() shortcut): these assertions were silently calibrated
// against nwdegree.ado's own pre-existing indegree/outdegree swap bug
// (see docs/CERTIFICATION.md's own nwdegree fix) - the variable named
// "_indegree" used to actually hold OUTdegree values (bounded, small,
// since every new node forms exactly m=2 outgoing ties), which is why
// max==2 looked plausible. With that bug fixed, "_indegree" now
// correctly holds real preferential-attachment indegree (unbounded,
// rich-get-richer - one heavily-preferred node can accumulate far more
// than m incoming ties) - confirmed directly with the same seed (123)
// against BOTH the fixed and the since-reverted-for-comparison nwdegree
// code before recalibrating, not assumed. The total (r(sum)) is
// unaffected, since swapping which column is called what does not
// change the total edge count either way.
assert         r(sum)   == 38
assert         r(max)   == 19
assert         r(min)   == 0
assert reldif( r(sd)     , 5.8480766068853782 ) <  1E-8
assert reldif( r(Var)    , 34.200000000000003 ) <  1E-8
assert reldif( r(mean)   , 1.899999999999999  ) <  1E-8
assert         r(sum_w) == 20
assert         r(N)     == 20

nwclear
set seed 123
nwpref 20, weights(0,0,1)
nwsummarize
assert r(minval) ==  0
assert r(maxval) == 3












* --- regression guard: the final nwset call referenced an undefined
* local `prefname' (a plain typo for `name', the local this command's
* own syntax line actually declares) - a caller's own name() was
* silently discarded and the network always got nwset's own generic
* default name instead. Found while restoring nwgenerate's own pref()
* shortcut, which depends on this actually working.
nwclear
nwpref 15, m0(2) m(2) name(myprefnet)
assert _rc == 0
nwname myprefnet
assert _rc == 0

* --- alpha-audit regression: ntimes()>1's recursive self-call never
* forwarded weights() - every generated network silently came back
* unweighted (plain 0/1) regardless of the requested weights().
nwclear
set seed 42
nwpref 10, ntimes(2) weights(0,0,1)
nwsummarize pref_1
assert r(maxval) == 3
nwsummarize pref_2
assert r(maxval) == 3
di "=== ntimes()>1 + weights() REGRESSION VERIFIED ==="

* moderate-severity pass, generators_structural group: r(netlist) parity
* with nwrandom (the only sibling generator that already exposed it).
nwclear
nwpref 10
assert `"`r(netlist)'"' == `"pref"'
nwclear
nwpref 10, ntimes(3)
assert `"`r(netlist)'"' == `"pref_1 pref_2 pref_3"'
di "=== r(netlist) REGRESSION VERIFIED ==="

* --- failure paths: nodes must be > 1 (this command's own explicit
* guard, error 125); an explicit, caller-chosen name() that collides
* with an already-loaded network is rejected (unlike the default
* unnamed case, which auto-increments).
capture noisily nwpref 1
assert _rc == 125

capture noisily nwpref 0
assert _rc == 125

nwclear
nwpref 10, name(explicitpref)
capture noisily nwpref 10, name(explicitpref)
assert _rc != 0

* --- failure path (BUGFIX: used to print the message and fall through
* to actually generating an unweighted network anyway, returning
* _rc==0 as if nothing were wrong - confirmed directly before this
* fix, same as the identical bug in nwrandom/nwring/nwsmall/nwdyadprob).
nwclear
capture noisily nwpref 10, weights(abc,def)
assert _rc != 0
