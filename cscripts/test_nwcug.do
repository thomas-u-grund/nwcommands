cscript

do unw_core.do

* --- Two disjoint K5 cliques (10 nodes, 20 edges, density=20/45=.4444)
* -> 2 components. At this density, random ER graphs on 10 nodes should
* essentially always be a single connected component (well above the
* ln(n)/n connectivity threshold), so the observed value is provably more
* fragmented than any random draw at the same density - a fully
* deterministic certification case (sd_null=0 at 500 reps).
mata: A = J(10,10,0)
mata: A[1::5,1::5] = J(5,5,1) - I(5)
mata: A[6::10,6::10] = J(5,5,1) - I(5)
nwclear
nwset, mat(A)
nwname, newname(twoclique)

qui nwcomponents twoclique, generate(_component)
assert r(components) == 2

nwcug twoclique, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(500) seed(20260821)
assert r(obs) == 2
assert r(reps) == 500
assert r(mean_null) == 1
assert r(sd_null) == 0
assert r(p_greater) == 0
assert r(p_less) == 1
assert r(p) == 0

* reproducibility: identical seed -> identical results
nwcug twoclique, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(500) seed(20260821)
assert r(p_greater) == 0
assert r(mean_null) == 1


* --- sanity bounds: p-values must lie in [0,1] and reps must match request,
* on a milder, less deterministic case (5 disjoint pairs, 10 nodes, 5
* edges, density=5/45=.1111 - well below the connectivity threshold, so
* both observed and random draws are typically fragmented; not expected
* to be "significant" either way, just well-behaved)
nwclear
nwset, mat((0,1,0,0,0,0,0,0,0,0\1,0,0,0,0,0,0,0,0,0\0,0,0,1,0,0,0,0,0,0\0,0,1,0,0,0,0,0,0,0\0,0,0,0,0,1,0,0,0,0\0,0,0,0,1,0,0,0,0,0\0,0,0,0,0,0,0,1,0,0\0,0,0,0,0,0,1,0,0,0\0,0,0,0,0,0,0,0,0,1\0,0,0,0,0,0,0,0,1,0)) name(fragnet) undirected

qui nwcomponents fragnet, generate(_component) replace
assert r(components) == 5

nwcug fragnet, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(200) seed(20260821) silent
assert r(obs) == 5
assert r(reps) == 200
assert r(p_greater) >= 0 & r(p_greater) <= 1
assert r(p_less) >= 0 & r(p_less) <= 1
assert r(p) >= 0 & r(p) <= 1
assert r(mean_null) > 0
assert r(sd_null) >= 0


* --- tail() option validity
capture nwcug fragnet, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(10) tail(bogus)
assert _rc != 0

nwcug fragnet, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(50) seed(1) tail(upper) silent
assert r(p_greater) >= 0 & r(p_greater) <= 1

nwcug fragnet, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(50) seed(1) tail(lower) silent
assert r(p_less) >= 0 & r(p_less) <= 1


* --- invalid rname() errors cleanly (stat() ran but never returned r(bogusname))
capture nwcug fragnet, stat(nwcomponents ##net##, generate(_component) replace) rname(bogusname) reps(10)
assert _rc != 0


* --- condition(census): dyad-census/reciprocity-conditioned draws
* (harmonisation unit 62), wired against nwrandom's own pre-existing
* census() conditioning (dyadcensusGenerator()) - previously only
* density-conditioned draws were available. A 4-node directed network
* with a hand-built, exactly-known dyad census: 1-2 mutual (1->2,
* 2->1), 1->3 and 2->4 asymmetric, the remaining 3 dyads (1-4, 2-3,
* 3-4) null. 6 total dyads (4*3/2), so mutual=1/asym=2/null=3,
* reciprocity = mutual/(mutual+asym) = 1/3 exactly.
nwclear
nwset, mat((0,1,1,0\1,0,0,1\0,0,0,0\0,0,0,0)) directed name(dyadnet)
qui nwdyads dyadnet
assert r(_100) == 1
assert r(_010) == 2
assert r(_001) == 3
assert reldif(r(reciprocity), 1/3) < 1E-8

* condition(census) draws must preserve the EXACT dyad census every
* single draw (dyadcensusGenerator() places exactly the requested
* mutual/asym counts, just at randomly-chosen dyads) - so reciprocity,
* computed identically on every draw, is deterministically constant:
* sd_null exactly 0, mean_null exactly equal to the observed value,
* p_greater/p_less both exactly 1 (every draw ties the observed value,
* satisfying both ">= observed" and "<= observed"). This is a much
* stronger, structure-independent certification of condition(census)
* than checking any one arbitrary stat()'s null distribution shape.
nwcug dyadnet, stat(nwdyads ##net##) rname(reciprocity) reps(100) seed(20260822) condition(census)
assert reldif(r(obs), 1/3) < 1E-8
assert r(sd_null) < 1E-10
assert reldif(r(mean_null), 1/3) < 1E-8
assert r(p_greater) == 1
assert r(p_less) == 1

* condition(census) on an undirected network is rejected explicitly -
* mutual/asymmetric/null dyad types have no meaning without direction.
nwclear
nwset, mat((0,1,1,0\1,0,0,1\1,0,0,0\0,1,0,0)) undirected name(undirnet)
capture nwcug undirnet, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(10) condition(census)
assert _rc != 0

* invalid condition() value errors cleanly.
capture nwcug dyadnet, stat(nwdyads ##net##) rname(reciprocity) reps(10) condition(bogus)
assert _rc != 0

* condition(density) (the default, and passed explicitly) still behaves
* exactly as before - no regression from adding condition().
mata: A2 = J(10,10,0)
mata: A2[1::5,1::5] = J(5,5,1) - I(5)
mata: A2[6::10,6::10] = J(5,5,1) - I(5)
nwclear
nwset, mat(A2)
nwname, newname(twoclique2)
nwcug twoclique2, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(500) seed(20260821) condition(density)
assert r(mean_null) == 1
assert r(sd_null) == 0


* --- alpha-audit regression: a 1-node network has 0 possible dyads, so
* its own density is undefined (missing) - previously passed straight
* through to nwrandom's density() option, which never terminates when
* asked to hit a missing target density. Confirmed hanging indefinitely
* (100% CPU, no error, no timeout) before this fix; must now error
* immediately and cleanly instead.
nwclear
nwset, mat((0)) name(singlenetcug) undirected
capture noisily nwcug singlenetcug, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(10)
assert _rc != 0
di "=== SINGLE-NODE DENSITY-CONDITIONED HANG REGRESSION VERIFIED ==="

* moderate-severity pass, stat_models group: a misspelled/nonexistent
* network name used to crash with a raw Mata error (r3301) instead of a
* clean message.
nwclear
nwrandom 5, prob(.5) name(realnetcug)
capture noisily nwcug typobogus, stat(nwcomponents ##net##, generate(_component) replace) rname(x) reps(2)
assert _rc == 482
di "=== misspelled network name REGRESSION VERIFIED ==="

* --- plot(): draws a histogram of the null draws with a reference line
* at the observed value, without disturbing the caller's own dataset
* (reuses the twoclique network from the top of this script; a fresh
* variable "canary" confirms the active dataset survives plot()'s own
* internal preserve/restore intact).
nwclear
nwset, mat(A)
nwname, newname(twoclique2)
clear
set obs 3
gen canary = _n
nwcug twoclique2, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(50) seed(1) plot name(cugplottest)
assert _rc == 0
assert _N == 3
assert canary[1] == 1 & canary[2] == 2 & canary[3] == 3
capture graph drop cugplottest
di "=== nwcug plot() OK ==="

* --- BUGFIX regression (adversarial-input pressure test): reps() was
* never validated - reps(0) silently "succeeded" with a meaningless
* result (a concrete-looking but undefined p=1), and any negative
* reps() crashed with a raw "argument out of range" (r3300) trying to
* allocate a negative-length Mata vector.
capture noisily nwcug twoclique2, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(0)
assert _rc == 198
capture noisily nwcug twoclique2, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(-5)
assert _rc == 198
capture noisily nwcug twoclique2, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(1)
assert _rc == 198
di "=== nwcug: reps() validation REGRESSION VERIFIED ==="
