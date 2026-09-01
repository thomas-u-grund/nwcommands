cscript

do unw_core.do
do unw_ergm.do

* Certifies nwergm.ado itself (the Stata-facing eclass command), on top
* of unw_ergm.do's own already-certified Mata internals
* (test_nwergm_statistics.do/changestat.do/mple.do/mcmc.do/mcmle.do):
* the NWdef->ErgmGraph bridge, term-option parsing, network-type
* validation, MPLE-vs-MCMLE dispatch, and eclass result posting.

* --- MPLE path: edges-only on a 5-node undirected network with
* density exactly 0.5 (5 ties / 10 dyads) - the exact MPLE is
* logit(0.5) = 0 (same hand-derivable case as test_nwergm_mple.do,
* now exercised through the actual command rather than Mata directly).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(mynet) labs(A,B,C,D,E)
gen sex = .
replace sex = 1 in 1
replace sex = 1 in 2
replace sex = 2 in 3
replace sex = 2 in 4
replace sex = 1 in 5

qui nwergm mynet, edges
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert `"`e(cmd)'"' == "nwergm"
assert e(nodes) == 5
assert e(ties) == 5
assert abs(_b[edges]) < 1e-6

* --- MPLE with nodematch(): two coefficients, still dyad-independent
* (method still auto-selects mple).
qui nwergm mynet, edges nodematch(sex)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert colsof(e(b)) == 2

* --- method(mple) explicit request on a dyad-DEPENDENT model prints a
* pseudolikelihood-not-MLE note and still reports mple results (not an
* error) - exercised on a directed network with mutual.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(mydirnet) labs(A,B,C,D,E)
qui nwergm mydirnet, edges mutual method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"

* --- MCMLE path (default method for a dyad-dependent model): same
* directed network, edges+mutual. A real reciprocity effect exists in
* this hand-built network (a fully mutual triangle among the first
* three nodes plus more), so MCMLE should converge to a genuinely
* positive mutual coefficient - not just "runs without erroring".
set seed 999
qui nwergm mydirnet, edges mutual mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert `"`e(method)'"' == "mcmle"
assert e(converged) == 1
assert e(mcmle_iterations) > 0 & e(mcmle_iterations) <= 15
assert _b[mutual] > 1
assert `"`e(proposal)'"' == "tnt"

* --- proposal(uniform) also runs and converges (both proposals are
* certified at the Mata level already - this just confirms the .ado
* correctly threads the option through).
set seed 998
qui nwergm mydirnet, edges mutual proposal(uniform) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert `"`e(proposal)'"' == "uniform"

* --- network-type rejections: two-mode, temporal-adjacent (valued
* here, since this package's temporal groundwork doesn't yet have a
* trivial one-line "make a temporal network" test fixture elsewhere -
* valued is exercised directly below), and the term/network-type
* mismatches (mutual/nodeicov/nodeocov require directed; gwesp/
* gwodegree/gwidegree have their own directedness requirements).
* two-mode (bipartite): harmonisation unit 155 Stage 1 replaced the old
* blanket rejection with real (if narrow, edges-only) support - see
* cscripts/test_nwergm_bipartite.do for the dedicated mechanics-level
* certification of this. Kept here only as the .ado-level regression
* guard: edges-only now succeeds (closed-form check: 3x3 affiliation
* matrix, 5 ties / 9 cross-mode dyads, logit(5/9) = ln(5/4)), while any
* other term is still explicitly rejected (no bipartite-family term
* exists yet beyond edges).
nwclear
nw2set, mat((0,1,0\1,0,1\0,1,1)) name(twomode)
qui nwergm twomode, edges
assert _rc == 0
assert e(nodes) == 6
assert e(ties) == 5
assert reldif(_b[edges], ln(5/4)) < 1e-6
capture noisily nwergm twomode, edges triangle
assert _rc != 0

nwclear
nwset, mat((0,2,0\2,0,3\0,3,0)) name(wnet)
capture noisily nwergm wnet, edges
assert _rc != 0

nwclear
nwset, mat((0,1\1,0)) undirected name(unet)
capture noisily nwergm unet, edges mutual
assert _rc != 0
capture noisily nwergm unet, edges nodeicov(sex)
assert _rc != 0
capture noisily nwergm unet, edges gwodegree(.5)
assert _rc != 0

nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed name(dnet2)
capture noisily nwergm dnet2, edges gwesp(.5)
assert _rc != 0

* --- edges is required.
nwclear
nwset, mat((0,1\1,0)) undirected name(unet2)
capture noisily nwergm unet2, mutual
assert _rc != 0

* --- edgecov(): dyadic covariate taken from another loaded network's
* own tie values, on the same node set.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(basenet3) labs(A,B,C,D,E)
nwset, mat((0,3,1,4,2\3,0,2,1,5\1,2,0,3,1\4,1,3,0,2\2,5,1,2,0)) undirected name(covnet) labs(A,B,C,D,E)
qui nwergm basenet3, edges edgecov(covnet)
assert _rc == 0
assert colsof(e(b)) == 2

* --- gwesp()/gwdegree() run to completion (fixed decay, MCMLE path -
* both dyad-dependent) and report finite, non-degenerate results.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(basenet4) labs(A,B,C,D,E)
set seed 1001
qui nwergm basenet4, edges gwesp(.5) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(10)
assert _rc == 0
assert `"`e(method)'"' == "mcmle"
mata: assert(!missing(st_matrix("e(b)")))

* --- term-expansion wave 3 wiring (harmonisation unit 91): nodefactor/
* nodeofactor/nodeifactor/kstar/ostar/istar/degrange/odegrange/
* idegrange threaded through nwergm.ado's own option parsing (already
* brute-force certified at the Mata level in
* cscripts/test_nwergm_termexpansion3.do - this just exercises the
* .ado construction blocks that build ErgmTermData from Stata options).
* This exact end-to-end .ado path caught a real, previously-undetected
* bug: `mata: if (cond) stmt' used as a bare Stata-inline one-liner
* (not inside a `mata\...\end' block) is not reliably parseable by
* Mata's interactive reader, even for the most trivial case - it fails
* with "unexpected end of line"/"<istmt> incomplete". This affected
* nodefactor()'s own base-level-drop logic too (unit 90), latent and
* undetected until this wiring test was written, since no .ado-level
* wiring test previously exercised nodefactor() either. Fixed by
* replacing the inline `if' at all three call sites with a single
* assignment to the new, control-flow-free-at-the-call-site
* `_ergm_drop_base_level()' Mata function (unw_ergm.do).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet3) labs(A,B,C,D,E)
gen byte grp = mod(_n,2)
set seed 2001
qui nwergm unet3, edges nodefactor(grp) kstar(2 3) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 4

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet4) labs(A,B,C,D,E)
set seed 2002
qui nwergm unet4, edges degrange(0 2) degrangeto(2 .) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 3

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet3) labs(A,B,C,D,E)
gen byte grp2 = mod(_n,2)
set seed 2003
qui nwergm dnet3, edges nodeofactor(grp2) nodeifactor(grp2) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet4) labs(A,B,C,D,E)
set seed 2004
qui nwergm dnet4, edges ostar(2) istar(2) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 3

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet5) labs(A,B,C,D,E)
set seed 2005
qui nwergm dnet5, edges odegrange(0 1) odegrangeto(1 .) idegrange(0 1) idegrangeto(1 .) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 5

* --- directed/undirected mismatch guards for the wave-3 options fire.
nwclear
nwset, mat((0,1\1,0)) undirected name(unet5)
capture noisily nwergm unet5, edges nodeofactor(id)
assert _rc != 0
capture noisily nwergm unet5, edges ostar(2)
assert _rc != 0
capture noisily nwergm unet5, edges odegrange(0)
assert _rc != 0

nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed name(dnet6)
capture noisily nwergm dnet6, edges kstar(2)
assert _rc != 0
capture noisily nwergm dnet6, edges degrange(0)
assert _rc != 0

* --- term-expansion wave 4 wiring (harmonisation unit 91 continuation):
* esp(d)/dsp(d), fixed non-geometric shared-partner-count terms
* (undirected/UTP scope only, matching gwesp/gwdsp), threaded through
* nwergm.ado's own option parsing - already brute-force certified at
* the Mata level in cscripts/test_nwergm_termexpansion4.do.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet6) labs(A,B,C,D,E)
set seed 2006
qui nwergm unet6, edges esp(0 1 2) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 4

* Deliberately a single, non-exhaustive dsp() value (not dsp(0 1 2)):
* requesting every achievable shared-partner value on a tiny network
* makes the dsp columns sum to an exact constant per row (a toggle
* just moves shared-partner mass between bins, so an EXHAUSTIVE d-range
* is perfectly collinear - the same modeling pitfall unit 90 fixed for
* nodefactor()'s base level, but here it is on the MODELER to avoid by
* not requesting an exhaustive range, matching R ergm's own convention
* (dsp/esp do not auto-drop a level the way nodefactor()/nodeofactor()/
* nodeifactor() do) - not a code bug, confirmed via direct inspection
* of build_mple_data()'s own design matrix on this exact network.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet7) labs(A,B,C,D,E)
set seed 2007
qui nwergm unet7, edges dsp(1) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 2

* --- term-expansion wave 5 wiring (harmonisation unit 91 continuation):
* gwesp()/gwdsp()/gwnsp()/esp()/dsp() now support DIRECTED networks too
* via R ergm's own default directed shared-partner definition (OTP) -
* nwergm.ado sets td.sptype="OTP" automatically whenever the network is
* directed. This directly supersedes the old guard-rejection test that
* used to live here (esp()/dsp() on a directed network used to error;
* now it succeeds). Already brute-force certified at the Mata level
* (against a brute-force common-neighbor scan AND ErgmCertifyChangeStat)
* in cscripts/test_nwergm_termexpansion5.do.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet7) labs(A,B,C,D,E)
set seed 2008
qui nwergm dnet7, edges gwesp(.5) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 2

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet8) labs(A,B,C,D,E)
set seed 2009
qui nwergm dnet8, edges gwdsp(.5) gwnsp(.5) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 3

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet9) labs(A,B,C,D,E)
set seed 2010
qui nwergm dnet9, edges esp(1) dsp(1) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 3

* --- term-expansion wave 6 wiring (harmonisation unit 91 continuation):
* transitiveties/cyclicalties, directed only, built on wave 5's OTP
* machinery - already brute-force certified at the Mata level in
* cscripts/test_nwergm_termexpansion6.do.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet10) labs(A,B,C,D,E)
set seed 2011
qui nwergm dnet10, edges transitiveties cyclicalties mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(3)
assert _rc == 0
assert colsof(e(b)) == 3

nwclear
nwset, mat((0,1\1,0)) undirected name(unet8)
capture noisily nwergm unet8, edges transitiveties
assert _rc != 0
capture noisily nwergm unet8, edges cyclicalties
assert _rc != 0

* --- term-expansion wave 7 wiring (harmonisation unit 91 continuation):
* hamming(netname), sender, receiver - already brute-force certified at
* the Mata level in cscripts/test_nwergm_termexpansion7.do.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(basenet5) labs(A,B,C,D,E)
nwset, mat((0,1,0,0,1\1,0,0,1,0\0,0,0,1,1\0,1,1,0,0\1,0,1,0,0)) undirected name(refnet5) labs(A,B,C,D,E)
qui nwergm basenet5, edges hamming(refnet5)
assert _rc == 0
assert colsof(e(b)) == 2

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet11) labs(A,B,C,D,E)
qui nwergm dnet11, edges sender receiver
assert _rc == 0
assert colsof(e(b)) == 9

* --- directed/undirected mismatch guard for sender/receiver fires.
nwclear
nwset, mat((0,1\1,0)) undirected name(unet9)
capture noisily nwergm unet9, edges sender
assert _rc != 0
capture noisily nwergm unet9, edges receiver
assert _rc != 0

* --- e(native) (harmonisation unit 92): 1 for a native-eligible MCMLE
* model, 0 for an MCMLE model outside the native backend's current
* scope. Harmonisation unit 145 extended native routing to the MPLE
* design-matrix build too (ErgmNativeBuildMPLEData()) - e(native) is
* now ALWAYS set after an MPLE fit as well (1 if native was used to
* build the design matrix, 0 if the model's own terms fell outside
* native's coverage and Mata's build_mple_data() ran instead), not left
* missing as it was before that unit.
* Deliberately a genuinely ASYMMETRIC directed adjacency here, not the
* package's usual symmetric hand-built network reused as directed
* elsewhere in this file - a symmetric matrix loaded as directed makes
* every dyad automatically "mutual", making mutual's own MPLE design
* column EXACTLY collinear with edges' own (the same class of
* collinearity unit 91 wave 4's own dsp() caveat documents) and
* `_rmcoll`/`logit` fails with "no observations" (r(2000)) - confirmed
* directly while first authoring this exact test.
nwclear
nwset, mat((0,1,1,0,0\0,0,1,0,0\1,0,0,1,0\0,0,0,0,1\0,0,0,0,0)) directed name(dnet12) labs(A,B,C,D,E)
qui nwergm dnet12, edges mutual mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2)
assert _rc == 0
assert e(native) == 1

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet10) labs(A,B,C,D,E)
nwset, mat((0,1,0,0,1\1,0,0,1,0\0,0,0,1,1\0,1,1,0,0\1,0,1,0,0)) undirected name(refnet10) labs(A,B,C,D,E)
// harmonisation unit 160 made edgecov()/hamming() native-eligible too
// (the last remaining gap in the "move all effects to C" migration) -
// this used to be the "0" demonstration case (hamming forced Mata);
// now every term is native-eligible, `nonative' is the only way left
// to deliberately force the Mata backend on a real fit.
qui nwergm unet10, edges hamming(refnet10) method(mcmle) mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2)
assert _rc == 0
assert e(native) == 1

qui nwergm unet10, edges hamming(refnet10) nonative method(mcmle) mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2)
assert _rc == 0
assert e(native) == 0
di "=== nonative correctly forces the Mata backend even on a native-eligible model (unit 160) ==="

qui nwergm unet10, edges hamming(refnet10)
assert _rc == 0
assert `"`e(method)'"' == "mple"
// hamming() is native-eligible as of unit 160 (see above) - the design
// matrix itself is now built natively on this MPLE path too.
assert e(native) == 1

* --- e(native) == 1 for an MPLE fit whose own terms ARE all native-
* eligible (harmonisation unit 145): the design matrix itself is built
* natively, bit-identical to Mata's own build_mple_data() (certified
* directly - max(abs(D_native - D_mata)) == 0 on a real network, not
* merely "close enough" the way a stochastic MCMC comparison must be,
* since MPLE from a fixed design matrix is entirely deterministic).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet11) labs(A,B,C,D,E)
gen sex11 = .
replace sex11 = 1 in 1
replace sex11 = 1 in 2
replace sex11 = 2 in 3
replace sex11 = 2 in 4
replace sex11 = 1 in 5
qui nwergm unet11, edges nodematch(sex11) method(mple)
assert _rc == 0
assert e(native) == 1
di "=== e(native) correctly reflects native-vs-Mata routing on the MPLE path (unit 145) ==="

* moderate-severity pass, stat_models group: a fully edgeless (zero-tie)
* network's MPLE fit - an outcome that never varies - used to crash
* with a bare, uncaptured "r(2000);" and NO explanatory text at all,
* unlike this command's otherwise consistently friendly "{err}..."
* validation messages. Also confirms the caller's own dataset survives
* untouched (the fix must `restore' before raising the error, not
* after - the same ordering bug already fixed once in nwrename.ado).
nwclear
nwset, mat((0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0)) undirected labs(A,B,C,D) name(edgeless)
gen mydata = 1
capture noisily nwergm edgeless, edges
assert _rc == 2000
assert _N == 4
assert mydata[1] == 1
di "=== edgeless-network MPLE-crash REGRESSION VERIFIED ==="

* --- spcache (docs/CERTIFICATION.md unit 132): the incremental
* shared-partner cache is a pure performance optimization - enabling it
* must never change a fit's numeric result. Reuses unet10/refnet10;
* used to rely on edges+hamming forcing the Mata fallback path on its
* own (hamming was the one term family not yet ported to the native
* backend) to exercise ErgmGraph::shared_partners()'s cached vs.
* uncached branches - harmonisation unit 160 made hamming native-
* eligible too, so `nonative' now does that forcing explicitly instead
* (every term is native-eligible as of that unit, so there is no longer
* a term that forces Mata on its own).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet10b) labs(A,B,C,D,E)
nwset, mat((0,1,0,0,1\1,0,0,1,0\0,0,0,1,1\0,1,1,0,0\1,0,1,0,0)) undirected name(refnet10b) labs(A,B,C,D,E)

set seed 2024
qui nwergm unet10b, edges gwesp(.3) hamming(refnet10b) nonative mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2)
assert _rc == 0
assert e(native) == 0
assert e(spcache) == 0
tempname __b_nocache
matrix `__b_nocache' = e(b)

set seed 2024
qui nwergm unet10b, edges gwesp(.3) hamming(refnet10b) nonative mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2) spcache
assert _rc == 0
assert e(native) == 0
assert e(spcache) == 1
tempname __b_cache
matrix `__b_cache' = e(b)

mata: assert(max(abs(st_matrix("`__b_nocache'") - st_matrix("`__b_cache'"))) == 0)
di "=== spcache: identical seed produces byte-identical coefficients with/without the cache ==="

* spcache is a no-op (with an explanatory note, not silence) on a
* directed network - the cache only implements the undirected
* shared-partner definition. (dnet7/dnet12 are not reused from earlier
* in this file - intervening nwclear calls already dropped them.)
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(dnet7b) labs(A,B,C,D,E)
qui nwergm dnet7b, edges gwesp(.5) mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2) spcache
assert _rc == 0
assert e(spcache) == 0

* spcache is a no-op (with an explanatory note) when no term that could
* use it was requested.
nwclear
nwset, mat((0,1,1,0,0\0,0,1,0,0\1,0,0,1,0\0,0,0,0,1\0,0,0,0,0)) directed name(dnet12b) labs(A,B,C,D,E)
qui nwergm dnet12b, edges mutual mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2) spcache
assert _rc == 0
assert e(spcache) == 0
di "=== spcache: no-op paths (directed, no relevant term) verified; simulate wiring certified separately in cscripts/test_nwergm_simulate.do ==="

* --- gwespfree() (harmonisation unit 136): the first user-facing
* consumer of the curved-parameter numerics built in units 133-135.
* MPLE only for now (curved MCMLE is a separate, not-yet-done item).
* Fits directly in theta-space via ErgmCurvedMPLEFit()'s own damped
* Newton-Raphson (unw_ergm.do) - certified here against a REAL
* independent R `ergm(net ~ edges + gwesp(0.7, fixed=FALSE),
* estimate="MPLE")' fit (ergm 4.12.0) on a deliberately clique-heavy
* 15-node network, chosen specifically because a random Erdos-Renyi
* network at several sizes (5, 12, 14, 20 nodes, all independently
* tried during this unit's own development) left decay essentially
* unidentified in BOTH R and nwergm alike (both landing near the
* decay=0 boundary, a genuine property of curved GWESP on sparse/small
* networks that R's own documentation already warns about, not a bug
* in either implementation) - this network's own dense, overlapping
* triangle structure gives decay real, checkable identification
* instead. Reasonably generous but still meaningful tolerances (1e-2),
* since this is a different exact optimization path (damped
* Newton-Raphson vs R's own BFGS) converging to the same MLE, not a
* bit-identical reproduction.
nwclear
nwset, mat((0,1,0,1,1,0,0,0,0,0,0,0,0,0,0 \ ///
1,0,1,1,1,1,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,1,1,0,1,0,0,1,0,0,0,0,0 \ ///
1,1,1,0,1,0,0,0,1,0,0,0,0,0,0 \ ///
1,1,1,1,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,0,0,0,1,1,1,1,0,0,1,0,0 \ ///
0,0,1,0,0,1,0,0,0,1,0,0,0,1,0 \ ///
0,0,0,0,0,1,0,0,1,0,0,0,0,0,1 \ ///
0,0,0,1,0,1,0,1,0,1,1,0,0,0,0 \ ///
0,0,1,0,0,1,1,0,1,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,1,0,0,1,1,1,1 \ ///
0,0,0,0,0,0,0,0,0,0,1,0,1,0,1 \ ///
0,0,0,0,0,1,0,0,0,0,1,1,0,0,1 \ ///
0,0,0,0,0,0,1,0,0,0,1,0,0,0,0 \ ///
0,0,0,0,0,0,0,1,0,0,1,1,1,0,0)) undirected name(curvedgwespnet)

qui nwergm curvedgwespnet, edges gwespfree(0.7) method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwesp(0.7, fixed=FALSE), estimate="MPLE"):
* edges=-1.7644740226 gwesp=0.2686248283 gwesp.decay=4.1538188381
assert reldif(_b[edges], -1.7644740226) < 1e-2
assert reldif(_b[gwesp_weight], 0.2686248283) < 1e-2
assert reldif(_b[gwesp_decay], 4.1538188381) < 1e-2
di "=== curved gwesp MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- error paths: gwesp()/esp() cannot combine with gwespfree();
* networks under 3 nodes are rejected (directed or not - harmonisation
* unit 170 lifted the last type()-specific directed restriction, so
* `tinydirnet' below - a 3-node directed network - is now a genuine
* success case, not an error one; only the SEPARATE 2-node too-few-
* nodes check below still errors on a directed network).
capture noisily nwergm curvedgwespnet, edges gwesp(0.5) gwespfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwespnet, edges esp(1 2) gwespfree(0.7)
assert _rc == 198

* method(mcmle) for a curved term now RUNS (previously rejected outright
* with error 198 - curved MCMLE now implemented via the Hummel/Hunter/
* Handcock (2012) steplength, done directly in theta-space as of
* harmonisation unit 180; see nwergm.ado's own gwespfree() gate comment
* and docs/ERGM_ROADMAP.md for the full account). `curvedgwespnet' is
* THIS package's own documented known-pathological network (see this
* file's earlier gwespfree() MPLE block and docs/ERGM_ROADMAP.md's own
* extensive account - R's own reference implementation independently
* fails outright on it too, "did not mix at all"), so at the
* deliberately tiny budget below either a real result (_rc==0) or this
* package's own explicit, documented degeneracy refusal (_rc==430,
* nwergm.ado's own curved-vcov guard) is a CORRECT outcome - what this
* test actually certifies is that the command no longer hard-rejects
* with error 198 before ever attempting the fit, not that this specific
* hard network converges at this tiny a budget.
capture qui nwergm curvedgwespnet, edges gwespfree(0.7) method(mcmle) mcmleiterations(3) mcmcsamplesize(500) mcmcburnin(500)
assert _rc == 0 | _rc == 430
if _rc == 0 {
	assert `"`e(method)'"' == "mcmle"
	assert e(curved) == 1
	assert colsof(e(b)) == 3
}

nwclear
nwset, mat((0,1\1,0)) directed name(tinydirnet2)
capture noisily nwergm tinydirnet2, edges gwespfree(0.7)
assert _rc == 198

nwclear
nwset, mat((0,1\1,0)) undirected name(tinynet2)
capture noisily nwergm tinynet2, edges gwespfree(0.7)
assert _rc == 198
di "=== gwespfree() error paths (combined with gwesp()/esp(), too few nodes) verified; method(mcmle) now succeeds ==="

* --- gwespfree() on a DIRECTED network, all five type() definitions
* (harmonisation unit 169 shipped type(OTP) alone; unit 170 widened it
* to ITP/OSP/ISP/RTP) - the first directed curved gwesp-FAMILY term
* (distinct from gwodegreefree()/gwidegreefree()'s own degree-family
* directed extension, unit 141). Reuses stat_esp()/change_esp()'s
* existing td.sptype dispatch to the already-certified directed
* shared_partners_otp/itp/osp/isp/rtp() machinery (unit 91) directly -
* no new statistic/change code, only registration/validation
* boilerplate plus one new bound function, ergm_graph_max_sp_dir()
* (unw_ergm.do, takes sptype), mirroring unit 145's own
* ties-only-vs-all-dyads reasoning (this bound only has to cover ESP's
* tied-dyads-only case, unlike the undirected bound shared with
* gwdspfree()). Each type certified against a REAL independent R
* ergm(net ~ edges + gwesp(0.7, fixed=FALSE, type=...), estimate=
* "MPLE") fit (ergm 4.12.0) on its own random 15-node directed
* network, found well-identified via a seeded search over Erdos-Renyi
* draws (unlike gwespfree()'s own undirected certification network
* above, which needed a deliberately clique-heavy structure).
*
* RTP surfaced a genuine, confirmed UPSTREAM R BUG along the way
* (statnet/ergm issue #656, unfixed in the installed ergm 4.12.0):
* `summary()`/MPLE/MCMC for esp(type="RTP")/gwesp(type="RTP") return
* WRONG values whenever R's shared-partner cache is enabled (the
* default) - `espRTP_change()` reads its own focal-dyad cache entry
* with the DIRECTED getter `GETDDMUI()` instead of the UNDIRECTED
* `GETUDMUI()` every other read in that same macro uses (the RTP cache
* itself is keyed by UNORDERED dyad), silently returning 0 whenever
* tail > head. Found by hand-deriving RTP from R's own documented rule
* ("k is an RTP shared partner of (i,j) iff i<->k<->j", matching
* `unw_ergm.do`'s own `shared_partners_rtp()`, already independently
* brute-force certified in `cscripts/test_nwergm_termexpansion9.do`)
* and discovering it disagreed with R's own DEFAULT (cached) output on
* a 15-node random network (24/23/8/1 vs 31/16/8/1 across esp levels
* 0-3) despite matching R's own small hand-built cases exactly - the
* asymmetry (RTP is mathematically symmetric, i<->k<->j does not care
* about tail/head order, so a real definitional difference could never
* produce an ODD count of mismatched dyads) was the tell that this was
* an implementation quirk, not a genuine alternate definition. R's own
* `term.options=list(cache.sp=FALSE)` reproduces nwergm's numbers
* EXACTLY (confirmed on the same network), which is the reference this
* unit's own RTP certification below uses - nwergm's implementation
* needed no change at all, it was already correct.
nwclear
nwset, mat((0,1,0,0,0,0,1,0,0,0,1,1,0,0,0 \ ///
0,0,0,0,0,0,0,1,0,1,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,1,0,1,0,0,0 \ ///
0,0,0,0,0,0,0,0,1,1,1,0,0,1,0 \ ///
1,1,0,0,0,1,1,0,0,0,0,0,0,0,0 \ ///
0,1,0,0,0,0,0,0,0,1,1,1,0,0,0 \ ///
0,1,1,1,0,0,0,0,1,0,0,0,0,1,1 \ ///
0,1,0,0,0,0,0,0,1,1,0,0,0,1,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,1,0,0,0,0,0,0,1 \ ///
0,1,0,0,0,1,0,0,0,0,0,0,0,0,0 \ ///
0,0,1,0,1,0,0,0,0,1,0,1,0,0,0 \ ///
0,0,0,0,0,1,1,0,0,0,0,1,0,0,0 \ ///
0,0,1,0,0,0,1,0,0,0,0,0,0,0,0)) directed name(curvedgwespotpnet)

qui nwergm curvedgwespotpnet, edges gwespfree(0.7) method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwesp(0.7, fixed=FALSE, type="OTP"), estimate="MPLE"):
* edges=-0.774572031566 gwesp.OTP=-0.383231481801 gwesp.OTP.decay=1.559802008526
assert reldif(_b[edges], -0.774572031566) < 1e-2
assert reldif(_b[gwesp_weight], -0.383231481801) < 1e-2
assert reldif(_b[gwesp_decay], 1.559802008526) < 1e-2
di "=== directed curved gwesp (type(OTP)) MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* type() explicitly set to its own default (OTP) must behave identically
* to leaving it unset - not silently reinterpreted or double-applied.
qui nwergm curvedgwespotpnet, edges gwespfree(0.7) type(otp) method(mple)
assert _rc == 0
assert reldif(_b[edges], -0.774572031566) < 1e-2
di "=== gwespfree() type(otp) explicit matches the default-type() fit ==="

* --- type(ITP): also confirms a directed network under 3 nodes is now
* a genuine SUCCESS case (harmonisation unit 170 lifted the last
* type()-scoped directed restriction gwespfree() had).
nwclear
nwset, mat((0,0,1,0,0,0,0,0,1,0,0,0,1,1,0 \ ///
0,0,0,1,1,0,0,0,1,0,0,1,0,0,0 \ ///
0,0,0,0,0,0,1,0,0,0,0,0,1,0,0 \ ///
1,1,0,0,0,0,0,0,1,0,1,0,1,1,1 \ ///
1,0,0,1,0,0,1,0,0,0,0,0,0,0,1 \ ///
0,0,0,0,1,0,0,0,0,0,0,0,0,0,0 \ ///
1,1,1,0,0,1,0,0,0,0,1,0,0,0,0 \ ///
0,1,0,0,0,0,0,0,0,0,1,0,0,0,1 \ ///
0,1,1,1,1,0,0,1,0,1,0,0,0,0,0 \ ///
0,0,1,0,0,0,0,0,0,0,1,1,0,0,0 \ ///
0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 \ ///
0,0,0,0,1,1,0,1,1,0,0,0,0,0,0 \ ///
0,0,0,0,1,0,0,1,0,0,1,0,0,0,0 \ ///
1,0,0,0,0,0,1,0,1,1,0,0,0,0,0 \ ///
1,0,0,0,1,1,1,0,0,1,0,0,0,0,0)) directed name(curvedgwespitpnet)
qui nwergm curvedgwespitpnet, edges gwespfree(0.7) type(itp) method(mple)
assert _rc == 0
assert e(curved) == 1
* R ergm(net ~ edges + gwesp(0.7, fixed=FALSE, type="ITP"), estimate="MPLE"):
* edges=-1.1843108076164 gwesp.ITP=0.0783287451981 gwesp.ITP.decay=1.0363753950930
assert reldif(_b[edges], -1.1843108076164) < 1e-2
assert reldif(_b[gwesp_weight], 0.0783287451981) < 1e-2
assert reldif(_b[gwesp_decay], 1.0363753950930) < 1e-2
di "=== directed curved gwesp (type(ITP)) MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- type(OSP) ---
nwclear
nwset, mat((0,0,0,0,0,0,0,0,0,0,0,1,0,0,0 \ ///
1,0,1,0,1,0,1,0,1,0,0,0,0,0,0 \ ///
1,1,0,1,1,0,1,0,0,0,1,0,0,1,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,1,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,1,0,1 \ ///
0,0,0,0,1,0,0,0,0,0,0,1,0,0,1 \ ///
0,0,0,0,0,1,0,1,0,0,0,0,0,0,0 \ ///
0,0,1,0,0,0,0,0,0,0,1,0,0,0,1 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,1,0,0 \ ///
1,1,0,0,0,0,1,0,0,0,0,1,1,0,0 \ ///
0,0,0,0,1,0,0,0,0,0,0,1,0,0,0 \ ///
0,0,0,0,1,0,0,0,0,0,1,0,0,0,0 \ ///
1,0,0,1,0,0,0,1,0,0,0,1,0,0,0 \ ///
0,0,0,0,0,1,1,0,0,1,0,1,1,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) directed name(curvedgwespospnet)
qui nwergm curvedgwespospnet, edges gwespfree(0.7) type(osp) method(mple)
assert _rc == 0
assert e(curved) == 1
* R ergm(net ~ edges + gwesp(0.7, fixed=FALSE, type="OSP"), estimate="MPLE"):
* edges=-1.2010984053674 gwesp.OSP=-0.1411842264149 gwesp.OSP.decay=0.0914151348972
assert reldif(_b[edges], -1.2010984053674) < 1e-2
assert reldif(_b[gwesp_weight], -0.1411842264149) < 1e-2
assert reldif(_b[gwesp_decay], 0.0914151348972) < 1e-2
di "=== directed curved gwesp (type(OSP)) MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- type(ISP) ---
nwclear
nwset, mat((0,0,0,0,0,0,0,0,0,0,1,0,0,1,0 \ ///
0,0,0,0,0,1,0,0,0,1,0,0,0,0,0 \ ///
0,0,0,0,1,0,0,1,0,0,1,0,0,0,0 \ ///
1,0,0,0,0,1,0,0,0,1,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,1,0,1,0,0,1 \ ///
0,0,0,0,0,0,1,0,0,1,0,0,1,0,0 \ ///
0,0,0,0,0,0,0,0,1,0,0,0,0,0,0 \ ///
0,1,0,0,0,0,0,0,0,0,0,1,0,0,0 \ ///
1,0,1,0,0,0,0,0,0,0,0,0,0,1,0 \ ///
1,0,0,0,0,0,0,0,0,0,1,0,0,0,0 \ ///
0,0,0,0,0,1,0,1,0,0,0,0,0,0,0 \ ///
0,0,0,0,0,1,0,0,0,0,0,0,0,0,0 \ ///
1,0,1,0,0,1,0,0,0,0,0,0,0,1,1 \ ///
0,0,0,0,0,1,0,0,1,1,0,0,0,0,0 \ ///
0,0,1,1,1,0,0,0,0,0,1,0,0,0,0)) directed name(curvedgwespispnet)
qui nwergm curvedgwespispnet, edges gwespfree(0.7) type(isp) method(mple)
assert _rc == 0
assert e(curved) == 1
* R ergm(net ~ edges + gwesp(0.7, fixed=FALSE, type="ISP"), estimate="MPLE"):
* edges=-0.941839200227 gwesp.ISP=-0.637263544824 gwesp.ISP.decay=0.126430000963
assert reldif(_b[edges], -0.941839200227) < 1e-2
assert reldif(_b[gwesp_weight], -0.637263544824) < 1e-2
assert reldif(_b[gwesp_decay], 0.126430000963) < 1e-2
di "=== directed curved gwesp (type(ISP)) MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- type(RTP) - see the header comment above this block for the real
* R/ergm#656 upstream caching bug this certification's own target
* value deliberately routes around (term.options=list(cache.sp=FALSE)
* in R, matching nwergm's already-correct uncached computation).
nwclear
nwset, mat((0,0,0,0,0,0,0,1,0,0,0,0,1,0,0 \ ///
0,0,1,1,1,0,1,0,0,0,0,0,1,1,1 \ ///
0,1,0,0,1,0,0,0,0,0,1,0,0,0,0 \ ///
0,0,1,0,0,0,0,0,1,1,1,0,0,0,1 \ ///
0,1,1,0,0,0,0,0,0,0,0,0,1,0,0 \ ///
0,0,0,1,0,0,1,1,0,0,0,1,0,0,0 \ ///
0,0,0,0,0,1,0,0,1,0,0,0,0,0,0 \ ///
0,0,0,0,0,1,0,0,0,0,0,0,0,0,0 \ ///
0,0,0,1,1,0,1,0,0,1,1,0,0,1,0 \ ///
0,1,0,1,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,0,1,1,0,0,0,0,1,0,0,0,0,1,0 \ ///
0,0,0,0,0,0,0,0,0,0,1,0,0,0,1 \ ///
1,1,0,0,1,0,0,1,0,0,1,0,0,0,1 \ ///
0,1,0,1,0,0,0,0,1,0,1,0,0,0,1 \ ///
0,1,0,1,0,0,0,0,0,0,0,0,1,1,0)) directed name(curvedgwesprtpnet)
qui nwergm curvedgwesprtpnet, edges gwespfree(0.7) type(rtp) method(mple)
assert _rc == 0
assert e(curved) == 1
* R ergm(net ~ edges + gwesp(0.7, fixed=FALSE, type="RTP"), estimate="MPLE",
* control=control.ergm(term.options=list(cache.sp=FALSE))) - see comment above:
* edges=-1.876354144764 gwesp.RTP=0.820834175933 gwesp.RTP.decay=0.208024541683
assert reldif(_b[edges], -1.876354144764) < 1e-2
assert reldif(_b[gwesp_weight], 0.820834175933) < 1e-2
assert reldif(_b[gwesp_decay], 0.208024541683) < 1e-2
di "=== directed curved gwesp (type(RTP)) MPLE fit matches an independent R ergm fit (cache.sp=FALSE) to within 1e-2 relative difference ==="

* --- gwespfree() combined with ANOTHER dyad-dependent term (triangle) -
* nothing in nwergm.ado forbids this (only gwesp()/esp() are forbidden,
* since they would be redundant/collinear with gwespfree() itself), and
* the joint Newton-Raphson fit is fully general (fits every coefficient,
* ordinary and curved, in one loop regardless of what else is present).
* This combined model happens to be poorly identified on this exact
* network (R's own independent ergm(net ~ edges + triangle +
* gwesp(0.7,fixed=FALSE), estimate="MPLE") fit ALSO lands decay at its
* own zero boundary, 2.49e-10 - a genuine property of this specific
* model/network combination, not a bug) - found during development
* that the fitting loop's own graceful-boundary-stop behavior (added
* specifically because of this exact case: exhausting every
* backtracking halving without finding an improving, alpha-positive
* step is the correct signal to clamp decay at its floor and stop, not
* to accept an invalid step and cascade to missing) needed certifying
* directly, not just asserted to exist. Checks: runs to completion
* (does not error, does not return missing coefficients), reports
* e(curved)==1 and the right column count, and decay lands at (or very
* near) its own documented floor - matching R's own qualitative
* boundary behavior on this network, not a numeric-agreement claim
* (which would not be a meaningful thing to certify for a poorly
* identified model in the first place).
nwclear
nwset, mat((0,1,0,1,1,0,0,0,0,0,0,0,0,0,0 \ ///
1,0,1,1,1,1,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,1,1,0,1,0,0,1,0,0,0,0,0 \ ///
1,1,1,0,1,0,0,0,1,0,0,0,0,0,0 \ ///
1,1,1,1,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,0,0,0,1,1,1,1,0,0,1,0,0 \ ///
0,0,1,0,0,1,0,0,0,1,0,0,0,1,0 \ ///
0,0,0,0,0,1,0,0,1,0,0,0,0,0,1 \ ///
0,0,0,1,0,1,0,1,0,1,1,0,0,0,0 \ ///
0,0,1,0,0,1,1,0,1,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,1,0,0,1,1,1,1 \ ///
0,0,0,0,0,0,0,0,0,0,1,0,1,0,1 \ ///
0,0,0,0,0,1,0,0,0,0,1,1,0,0,1 \ ///
0,0,0,0,0,0,1,0,0,0,1,0,0,0,0 \ ///
0,0,0,0,0,0,0,1,0,0,1,1,1,0,0)) undirected name(curvedcombonet)

qui nwergm curvedcombonet, edges triangle gwespfree(0.7) method(mple)
assert _rc == 0
assert e(curved) == 1
assert colsof(e(b)) == 4
mata: assert(!missing(st_matrix("e(b)")))
assert _b[gwesp_decay] < 1e-4
di "=== gwespfree() combined with another dyad-dependent term (triangle) runs to completion, does not produce missing coefficients, and correctly hits the decay floor on this genuinely near-degenerate model ==="

* --- gwdegreefree() (harmonisation unit 139): extends the SAME curved-
* MPLE machinery from gwesp to gwdegree - reuses ErgmCurvedMPLEFit()
* and ErgmModel::theta_coefnames() unchanged, only the underlying
* statistic/change function family differs (stat_degree()/
* change_degree(), registered under name "degree" so
* theta_coefnames() picks the right "gwdegree_weight"/"gwdegree_decay"
* display names rather than defaulting to the gwesp pair). Certified
* against a REAL independent R ergm(net ~ edges + gwdegree(0.7,
* fixed=FALSE), estimate="MPLE") fit (ergm 4.12.0) on a deliberately
* hub-and-spoke 15-node network (chosen for real degree variation,
* mirroring gwespfree()'s own need for a deliberately-structured
* network rather than a random draw - a first random Erdos-Renyi-style
* attempt on the SAME clique-heavy network gwespfree() itself uses was
* independently flagged nonidentifiable by R, matching that unit's own
* documented pattern exactly).
nwclear
nwset, mat((0,1,0,0,0,0,0,1,1,0,1,0,0,1,0 \ ///
1,0,0,0,1,1,0,1,0,0,0,0,0,0,1 \ ///
0,0,0,0,0,1,0,1,0,0,0,1,1,0,0 \ ///
0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 \ ///
0,1,0,0,0,0,0,0,1,0,0,0,0,0,1 \ ///
0,1,1,0,0,0,0,0,1,0,0,0,1,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
1,1,1,1,0,0,0,0,0,0,0,0,0,0,0 \ ///
1,0,0,0,1,1,0,0,0,0,0,1,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
1,0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,0,1,0,0,0,0,0,1,0,0,0,0,0,0 \ ///
0,0,1,0,0,1,0,0,0,0,0,0,0,0,0 \ ///
1,0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,0,1,0,0,0,0,0,0,0,0,0,0)) undirected name(curvedgwdegreenet)

qui nwergm curvedgwdegreenet, edges gwdegreefree(0.7) method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwdegree(0.7, fixed=FALSE), estimate="MPLE"):
* edges=-0.7219873636 gwdegree=-1.4449411293 gwdegree.decay=0.6204714141
assert reldif(_b[edges], -0.7219873636) < 1e-2
assert reldif(_b[gwdegree_weight], -1.4449411293) < 1e-2
assert reldif(_b[gwdegree_decay], 0.6204714141) < 1e-2
di "=== curved gwdegree MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- error paths: mutual exclusivity with gwdegree()/degree() and
* with gwespfree() itself (v1 scope: at most one curved term).
capture noisily nwergm curvedgwdegreenet, edges gwdegree(0.5) gwdegreefree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwdegreenet, edges degree(1 2) gwdegreefree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwdegreenet, edges gwespfree(0.7) gwdegreefree(0.7)
assert _rc == 198
di "=== gwdegreefree() error paths (combined with gwdegree()/degree()/gwespfree()) all verified ==="

* --- gwdspfree() (harmonisation unit 140): extends curved MPLE from
* gwesp/gwdegree to gwdsp, reusing stat_dsp()/change_dsp() directly.
* Certified against a REAL independent R ergm(net ~ edges +
* gwdsp(0.7, fixed=FALSE), estimate="MPLE") fit (ergm 4.12.0) - this
* one landed well-identified on the SAME clique-heavy 15-node network
* gwespfree() itself uses (unlike gwesp/gwdegree, no separate
* network-hunting needed this time).
nwclear
nwset, mat((0,1,0,1,1,0,0,0,0,0,0,0,0,0,0 \ ///
1,0,1,1,1,1,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,1,1,0,1,0,0,1,0,0,0,0,0 \ ///
1,1,1,0,1,0,0,0,1,0,0,0,0,0,0 \ ///
1,1,1,1,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,1,0,0,0,0,1,1,1,1,0,0,1,0,0 \ ///
0,0,1,0,0,1,0,0,0,1,0,0,0,1,0 \ ///
0,0,0,0,0,1,0,0,1,0,0,0,0,0,1 \ ///
0,0,0,1,0,1,0,1,0,1,1,0,0,0,0 \ ///
0,0,1,0,0,1,1,0,1,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,1,0,0,1,1,1,1 \ ///
0,0,0,0,0,0,0,0,0,0,1,0,1,0,1 \ ///
0,0,0,0,0,1,0,0,0,0,1,1,0,0,1 \ ///
0,0,0,0,0,0,1,0,0,0,1,0,0,0,0 \ ///
0,0,0,0,0,0,0,1,0,0,1,1,1,0,0)) undirected name(curvedgwdspnet)

qui nwergm curvedgwdspnet, edges gwdspfree(0.7) method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwdsp(0.7, fixed=FALSE), estimate="MPLE"):
* edges=4.2563394667 gwdsp=-0.8569971371 gwdsp.decay=1.3420561410
assert reldif(_b[edges], 4.2563394667) < 1e-2
assert reldif(_b[gwdsp_weight], -0.8569971371) < 1e-2
assert reldif(_b[gwdsp_decay], 1.3420561410) < 1e-2
di "=== curved gwdsp MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- error paths: mutual exclusivity with gwdsp()/dsp()/other curved
* terms.
capture noisily nwergm curvedgwdspnet, edges gwdsp(0.5) gwdspfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwdspnet, edges dsp(1 2) gwdspfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwdspnet, edges gwespfree(0.7) gwdspfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwdspnet, edges gwdegreefree(0.7) gwdspfree(0.7)
assert _rc == 198
di "=== gwdspfree() error paths (combined with gwdsp()/dsp()/gwespfree()/gwdegreefree()) all verified ==="

* --- gwnspfree() (harmonisation unit 152): the last of the five
* fixed-decay GW terms to gain a curved counterpart, deferred out of
* units 136-141's own mechanical-reuse pass because gwnsp itself has no
* standalone per-count statistic to reuse - stat_gwnsp() was only ever
* a thin composition (stat_gwdsp()-stat_gwesp()). This unit added
* stat_nsp()/change_nsp() (nsp(d)=dsp(d)-esp(d), a definitional
* tautology - a dyad with d shared partners is either tied, esp's own
* domain, or untied, nsp's own domain, never both/neither - certified
* against an independent direct-enumeration oracle in unw_ergm.do's own
* development before use here). Certified against a REAL independent R
* ergm(net ~ edges + gwnsp(0.7, fixed=FALSE), estimate="MPLE") fit
* (ergm 4.12.0) - NEITHER the gwespfree()/gwdspfree() clique-heavy
* network NOR a hub-and-spoke network NOR plain random networks at two
* different sizes gave real decay identification for gwnsp specifically
* (R itself independently flagged the clique-heavy network's own fit
* "nonidentifiable"; the others all landed decay at its own ~0
* boundary) - a genuine, disclosed property of this specific curved
* term, not a bug, matching gwesp's/gwdegree's own precedent that some
* structures leave a given curved term's decay unidentified in BOTH
* implementations alike. A network with two OVERLAPPING dense clusters
* (sharing several nodes) gives real shared-partner-count VARIATION
* specifically among UNTIED dyads - the population gwnsp's own decay
* needs to see spread in - and was well-identified on the first such
* attempt.
nwclear
nwset, mat((0,0,0,1,0,0,1,0,0,0,0,0,0,0,0 \ ///
0,0,1,1,0,0,1,1,0,0,0,0,0,0,0 \ ///
0,1,0,0,0,1,0,1,0,0,0,0,0,1,0 \ ///
1,1,0,0,1,1,0,0,0,0,0,0,0,0,0 \ ///
0,0,0,1,0,1,0,0,0,0,0,0,0,0,0 \ ///
0,0,1,1,1,0,1,0,1,0,1,0,1,0,0 \ ///
1,1,0,0,0,1,0,1,0,1,1,1,1,0,0 \ ///
0,1,1,0,0,0,1,0,1,1,0,1,1,0,0 \ ///
0,0,0,0,0,1,0,1,0,1,1,1,0,0,0 \ ///
0,0,0,0,0,0,1,1,1,0,0,1,1,0,0 \ ///
0,0,0,0,0,1,1,0,1,0,0,1,1,0,0 \ ///
0,0,0,0,0,0,1,1,1,1,1,0,1,0,0 \ ///
0,0,0,0,0,1,1,1,0,1,1,1,0,0,0 \ ///
0,0,1,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) undirected name(curvedgwnspnet)

qui nwergm curvedgwnspnet, edges gwnspfree(0.7) method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwnsp(0.7, fixed=FALSE), estimate="MPLE"):
* edges=0.06503318563 gwnsp=-0.42084251863 gwnsp.decay=0.81839862293
assert reldif(_b[edges], 0.06503318563) < 1e-2
assert reldif(_b[gwnsp_weight], -0.42084251863) < 1e-2
assert reldif(_b[gwnsp_decay], 0.81839862293) < 1e-2
di "=== curved gwnsp MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- error paths: mutual exclusivity with gwnsp()/other curved terms.
* No standalone nsp() option exists (unlike esp()/dsp()), so unlike the
* other four curved terms there is no third "combined with the plain
* per-count option" case to check here.
capture noisily nwergm curvedgwnspnet, edges gwnsp(0.5) gwnspfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwnspnet, edges gwespfree(0.7) gwnspfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwnspnet, edges gwdspfree(0.7) gwnspfree(0.7)
assert _rc == 198
di "=== gwnspfree() error paths (combined with gwnsp()/gwespfree()/gwdspfree()) all verified ==="

* --- gwodegreefree()/gwidegreefree() (harmonisation unit 141): the
* first DIRECTED curved terms, reusing stat_odegree()/change_odegree()
* and stat_idegree()/change_idegree() directly. Certified against
* REAL independent R ergm(net ~ edges + gwodegree/gwidegree(0.7,
* fixed=FALSE), estimate="MPLE") fits (ergm 4.12.0) on a random
* 15-node directed network - both well-identified on the first
* attempt, no separate network-hunting needed (unlike gwesp/gwdegree
* earlier in this same file).
nwclear
nwset, mat((0,0,1,0,1,1,0,1,0,0,1,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,1,0,0,1 \ ///
1,0,0,0,0,0,0,0,0,0,1,0,1,0,0 \ ///
0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 \ ///
0,0,0,0,0,1,0,0,0,0,0,1,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,1,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,1,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,1,0,1 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 \ ///
1,0,0,0,0,0,0,0,1,0,0,0,0,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ ///
0,0,1,0,0,0,0,0,0,0,0,0,0,0,1 \ ///
0,0,0,0,1,0,0,0,0,0,1,0,0,0,1 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,1,0,0 \ ///
0,0,0,0,0,0,0,0,0,0,0,0,1,0,0)) directed name(curvedgwodegreenet)

qui nwergm curvedgwodegreenet, edges gwodegreefree(0.7) method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwodegree(0.7, fixed=FALSE), estimate="MPLE"):
* edges=-2.10539653504 gwodegree=1.25844151033 gwodegree.decay=0.03366907151
assert reldif(_b[edges], -2.10539653504) < 1e-2
assert reldif(_b[gwodegree_weight], 1.25844151033) < 1e-2
assert reldif(_b[gwodegree_decay], 0.03366907151) < 1e-2
di "=== curved gwodegree MPLE fit matches an independent R ergm fit ==="

qui nwergm curvedgwodegreenet, edges gwidegreefree(0.7) method(mple)
assert _rc == 0
assert e(curved) == 1
assert colsof(e(b)) == 3
* R ergm(net ~ edges + gwidegree(0.7, fixed=FALSE), estimate="MPLE"):
* edges=-1.4969743157 gwidegree=-0.8228829163 gwidegree.decay=0.9472255024
assert reldif(_b[edges], -1.4969743157) < 1e-2
assert reldif(_b[gwidegree_weight], -0.8228829163) < 1e-2
assert reldif(_b[gwidegree_decay], 0.9472255024) < 1e-2
di "=== curved gwidegree MPLE fit matches an independent R ergm fit to within 1e-2 relative difference ==="

* --- error paths: undirected rejection, mutual exclusivity. No
* nwclear here - curvedgwodegreenet (set up above) is reused below,
* alongside this new undirnet3.
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(undirnet3)
capture noisily nwergm undirnet3, edges gwodegreefree(0.7)
assert _rc == 198
capture noisily nwergm undirnet3, edges gwidegreefree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwodegreenet, edges gwodegreefree(0.7) gwidegreefree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwodegreenet, edges gwespfree(0.7) gwodegreefree(0.7)
assert _rc == 198
di "=== gwodegreefree()/gwidegreefree() error paths (undirected rejection, mutual exclusivity) all verified ==="

* --- offset() (harmonisation unit 183): holds a named coefficient
* fixed at a user-supplied value rather than estimating it, matching R
* ergm's own offset() formula wrapper - certified directly against a
* REAL independent R ergm 4.12.0 fit (`net ~ edges + offset(triangle)`,
* offset.coef=0.3) on this same 10-node/10-tie network, both
* estimate="MPLE" and estimate="MLE": MPLE matches to <1e-4 relative
* difference (deterministic given the graph, same as every other MPLE
* certification in this file); MCMLE matches within the ~7%-13% Monte
* Carlo tolerance this project's own `mutual` MCMLE certification
* already established as the right standard for two independent
* stochastic estimators (R's own vcov() uses a completely different
* RNG stream). Both R fits report the offset coefficient at EXACTLY
* the given value with SE exactly 0 (confirmed directly, not assumed) -
* matched here too.
nwclear
nwset, mat((0,0,0,1,0,0,0,0,1,0 \ ///
0,0,0,0,0,0,1,0,0,0 \ ///
0,0,0,1,0,0,0,1,0,0 \ ///
1,0,1,0,1,0,0,0,0,0 \ ///
0,0,0,1,0,0,0,0,0,1 \ ///
0,0,0,0,0,0,0,1,1,0 \ ///
0,1,0,0,0,0,0,0,0,0 \ ///
0,0,1,0,0,1,0,0,1,0 \ ///
1,0,0,0,0,1,0,1,0,0 \ ///
0,0,0,0,1,0,0,0,0,0)) undirected name(offsetnet)

qui nwergm offsetnet, edges triangle offset(triangle 0.3) method(mple)
assert _rc == 0
* R ergm(net ~ edges + offset(triangle), offset.coef=0.3, estimate="MPLE"):
* edges=-1.344545, SE(edges)=0.3591732; offset(triangle)=0.3, SE=0
assert reldif(_b[edges], -1.344545) < 1e-3
matrix offV_mple = e(V)
assert reldif(sqrt(offV_mple[1,1]), 0.3591732) < 1e-3
assert _b[triangle] == 0.3
assert offV_mple[2,2] == 0
assert offV_mple[1,2] == 0 & offV_mple[2,1] == 0
di "=== offset() MPLE fit matches an independent R ergm fit to within 1e-3 relative difference; offset coefficient/SE/vcov row-col exactly as R reports them ==="

qui nwergm offsetnet, edges triangle offset(triangle 0.3) method(mcmle) mcmleiterations(20)
assert _rc == 0
assert e(converged) == 1
* R ergm(..., estimate="MLE", control=control.ergm(seed=7, MCMLE.maxit=20)):
* edges=-1.371041 (Monte Carlo tolerance vs. an independent R fit -
* this project's own established ~7%-13% standard for two independent
* stochastic MCMLE estimators, not the <1e-2 bar used for deterministic
* MPLE fits above)
assert reldif(_b[edges], -1.371041) < 0.15
assert _b[triangle] == 0.3
matrix offV_mcmle = e(V)
assert offV_mcmle[2,2] == 0
assert offV_mcmle[1,2] == 0 & offV_mcmle[2,1] == 0
di "=== offset() MCMLE fit matches an independent R ergm fit within Monte Carlo tolerance; offset coefficient/SE/vcov row-col exactly as R reports them ==="

* --- error paths
capture noisily nwergm offsetnet, edges triangle offset(nosuchcoef 0.3)
assert _rc == 198
capture noisily nwergm offsetnet, edges triangle offset(triangle notanumber)
assert _rc == 198
capture noisily nwergm offsetnet, edges triangle offset(triangle)
assert _rc == 198
capture noisily nwergm offsetnet, edges triangle offset(triangle 0.3 triangle 0.5)
assert _rc == 198
capture noisily nwergm offsetnet, edges offset(edges 1)
assert _rc == 198
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) undirected name(tinycurvednet)
capture noisily nwergm tinycurvednet, edges gwespfree(0.7) offset(gwesp_weight 0.5)
assert _rc == 198
di "=== offset() error paths (unknown coefname, non-numeric value, odd token count, duplicate coefname, fixing every coefficient, curved model) all verified ==="
