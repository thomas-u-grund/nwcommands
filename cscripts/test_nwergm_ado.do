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
nwclear
nw2set, mat((0,1,0\1,0,1\0,1,1)) name(twomode)
capture noisily nwergm twomode, edges
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
* scope, unset (missing) for an MPLE-only fit (native/Mata dispatch
* never runs at all for MPLE - documented as "method(mcmle) only").
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
qui nwergm unet10, edges hamming(refnet10) method(mcmle) mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2)
assert _rc == 0
assert e(native) == 0

qui nwergm unet10, edges hamming(refnet10)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert missing(e(native))

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
* must never change a fit's numeric result. Reuses unet10/refnet10 from
* the e(native)==0 case just above (edges+hamming forces the Mata
* fallback path, since hamming is the one term family not yet ported to
* the native backend - see nwergm.ado's own spcache build-up comment -
* so this actually exercises ErgmGraph::shared_partners()'s cached vs.
* uncached branches, unlike a native-eligible model where the Mata cache
* would never be consulted at all).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(unet10b) labs(A,B,C,D,E)
nwset, mat((0,1,0,0,1\1,0,0,1,0\0,0,0,1,1\0,1,1,0,0\1,0,1,0,0)) undirected name(refnet10b) labs(A,B,C,D,E)

set seed 2024
qui nwergm unet10b, edges gwesp(.3) hamming(refnet10b) mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2)
assert _rc == 0
assert e(native) == 0
assert e(spcache) == 0
tempname __b_nocache
matrix `__b_nocache' = e(b)

set seed 2024
qui nwergm unet10b, edges gwesp(.3) hamming(refnet10b) mcmcburnin(300) mcmcinterval(20) mcmcsamplesize(300) mcmleiterations(2) spcache
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

qui nwergm curvedgwespnet, edges gwespfree(0.7)
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
* directed networks and networks under 3 nodes are rejected;
* method(mcmle) is rejected (curved MCMLE not yet implemented).
capture noisily nwergm curvedgwespnet, edges gwesp(0.5) gwespfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwespnet, edges esp(1 2) gwespfree(0.7)
assert _rc == 198
capture noisily nwergm curvedgwespnet, edges gwespfree(0.7) method(mcmle)
assert _rc == 198

nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) directed name(tinydirnet)
capture noisily nwergm tinydirnet, edges gwespfree(0.7)
assert _rc == 198

nwclear
nwset, mat((0,1\1,0)) undirected name(tinynet2)
capture noisily nwergm tinynet2, edges gwespfree(0.7)
assert _rc == 198
di "=== gwespfree() error paths (combined with gwesp()/esp(), directed, too few nodes, method(mcmle)) all verified ==="

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

qui nwergm curvedcombonet, edges triangle gwespfree(0.7)
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

qui nwergm curvedgwdegreenet, edges gwdegreefree(0.7)
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
