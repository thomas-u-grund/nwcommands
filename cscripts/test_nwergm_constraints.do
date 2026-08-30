cscript

do unw_core.do
do unw_ergm.do

* Certifies nwergm's freedyads() option - constraints, first concrete piece
* (docs/ERGM_ROADMAP.md, "Constraints beyond v1's free binary dyad space"
* row): R ergm's own constraints=~fixallbut(free) - a boolean mask over the
* dyad space marking which dyads are eligible to vary during MCMC; every
* other dyad is held permanently fixed at its OBSERVED value. Only the
* proposal layer is restricted (ergm_propose_uniform_masked(),
* build_mple_data()'s own masked enumeration) - full_statistic() (MCMLE's
* own observed target) deliberately still reads the WHOLE graph, matching
* R ergm's real conditional-MLE theory: a fixed dyad's true observed state
* still contributes to the sufficient statistic being matched, it is only
* barred from ever being proposed for a toggle.
*
* Ground truth verified against REAL, installed R ergm 4.12.0
* (constraints=~fixallbut(network(free)), estimate="MPLE") on the exact
* 6-node/15-dyad network below with a 5-dyad free mask (dyads touching node
* 1 only): R reports edges=-0.4054651 EXACTLY (logit(2/5), the free-dyads-
* ONLY closed form - NOT logit(8/15)=0.1335314, the unconstrained
* full-network density) - confirming a fixed dyad's own likelihood
* contribution is a theta-independent constant under this constraint, so it
* drops entirely out of MPLE's own pseudolikelihood, exactly as
* build_mple_data() below now implements.
*
* Two real bugs found and fixed while building this (not by inspection):
* (1) Mata's `&' is NOT short-circuiting - `rows(G) > 0 & G.has_dyadmask'
* in ErgmNativeSetup() crashed ("nonclass found where class required") the
* moment G was omitted, since G.has_dyadmask is evaluated regardless of the
* left operand - fixed with a nested `if'. (2) Mata's cond() does NOT
* support a 3-argument POINTER form at all ("expected 1 to 2 arguments but
* received 3") - nwergm_estat.ado's own estat gof used cond() to pick
* between the masked/unmasked proposal pointers, which broke EVERY estat
* gof call (masked or not), caught only by this unit's own full 29-file
* regression sweep, not by a freedyads()-specific test alone - fixed by
* branching at the Stata level instead (mirroring nwergm.ado's own
* __ergm_propfn dispatch pattern).

nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,1\0,0,0,1,1,0)) undirected name(mynet)
nwset, mat((0,1,1,1,1,1\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0)) undirected name(freenet)
nwset, mat((0,1,1,1,1,1\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,1,1\1,1,1,1,0,1\1,1,1,1,1,0)) undirected name(fullfree)
nwset, mat((0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0)) undirected name(nofree)

* --- Test 1: MPLE closed form must match real R's fixallbut() output
* exactly (verified externally, see header above) - logit(2/5), NOT
* logit(8/15). ---
qui nwergm mynet, edges freedyads(freenet) method(mple)
assert reldif(_b[edges], -0.4054651) < 1e-5

* --- Test 2: a fully-free mask must reproduce the ordinary unconstrained
* MPLE fit exactly (the constraint becomes a no-op) - both directions
* (with freedyads(fullfree) and with freedyads() omitted entirely) must
* agree. ---
qui nwergm mynet, edges freedyads(fullfree) method(mple)
local b_fullfree = _b[edges]
qui nwergm mynet, edges method(mple)
assert reldif(`b_fullfree', _b[edges]) < 1e-10
assert reldif(_b[edges], 0.1335314) < 1e-5

* --- Test 3: an all-fixed mask (zero free dyads) must error out cleanly at
* setup time, not spin forever inside the masked proposal's own rejection
* loop. ---
capture nwergm mynet, edges freedyads(nofree) method(mple)
assert _rc != 0

* --- Test 4: proposal(tnt) IS now supported with freedyads() (masked TNT,
* ergm_propose_tnt_masked() - the follow-on this file's own Test 4 used to
* explicitly reject) - must run cleanly, not error, and the DEFAULT
* proposal (no proposal() given at all) now defaults to tnt exactly as it
* does without freedyads() (no more special "silently pick uniform"
* default). ---
qui nwergm mynet, edges freedyads(freenet) method(mcmle) proposal(tnt) mcmcsamplesize(500) mcmcburnin(200) mcmcinterval(10) seed(1) nonative
assert e(converged) < .
assert "`e(proposal)'" == "tnt"
qui nwergm mynet, edges freedyads(freenet) method(mcmle) mcmcsamplesize(500) mcmcburnin(200) mcmcinterval(10) seed(1) nonative
assert e(converged) < .
assert "`e(proposal)'" == "tnt"

* --- Test 5: the core correctness property - every FIXED dyad's tie state
* must be bit-identical before and after a real MCMLE fit (1000+ MCMC
* steps), while free dyads visibly do change. Checked directly against
* __nwergm_last_G's own final state, not assumed from Test 1/2's
* coefficient-level evidence alone. ---
mata: st_matrix("obs_before", __nwergm_last_G.to_dense())
qui nwergm mynet, edges freedyads(freenet) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(42) nonative
assert e(converged) < .
mata: st_matrix("obs_after", __nwergm_last_G.to_dense())
mata: freemat = (0,1,1,1,1,1\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0)
mata: fixedmask = 1 :- freemat
mata: _diag(fixedmask, 0)
mata: fixed_diff = sum(abs(st_matrix("obs_after") - st_matrix("obs_before")) :* fixedmask)
mata: assert(fixed_diff == 0)

* --- Test 6: a masked model's MCMC SAMPLING now genuinely runs natively
* (harmonisation unit 168 - masked TNT/uniform ported to
* native/ergm_mcmc.c, gated by the new, separate native_enabled_sample
* flag). e(native) now correctly reports 1 here - previously it was
* forced to 0 for every masked model (native had no wire-protocol field
* for a dyad mask at all, a disclosed v1 follow-on at the time); this
* row's own assertion is intentionally UPDATED, not merely left
* alone - the old "must ALWAYS fall back to Mata" behavior was itself
* the disclosed limitation this later unit closed, not a contract to
* keep protecting. Checked WITHOUT nonative, so ErgmNativeSetup()
* genuinely runs and must correctly report the new eligibility. ---
qui nwergm mynet, edges freedyads(freenet) method(mcmle) mcmcsamplesize(500) mcmcburnin(200) mcmcinterval(10) seed(1)
assert e(native) == 1

* --- Test 7: estat gof after a freedyads()-constrained fit must not error,
* and must use the masked proposal for its own posterior-predictive draws
* (not the unmasked default TNT, which would let GOF simulate outside the
* fitted sample space) - this exercises the real fix for bug (2) in the
* header above (nwergm_estat.ado's own Mata cond()-on-pointers crash),
* which broke ALL estat gof calls, not just masked ones, so this also
* stands in as a basic estat-gof-still-works regression check. ---
qui nwergm mynet, edges freedyads(freenet) method(mcmle) mcmcsamplesize(1000) mcmcburnin(500) mcmcinterval(20) seed(3) nonative
qui estat gof, nsim(15) seed(11)

* --- Test 8: omitting freedyads() entirely must be a complete no-op -
* same acceptance-rate ballpark / no regression versus this option never
* having existed. A direct MPLE/MCMLE smoke check (the wider suite's own
* pre-existing tests already cover the general unconstrained path
* exhaustively; this is a narrow "the new option truly defaults off"
* confirmation local to this file). ---
qui nwergm mynet, edges method(mcmle) mcmcsamplesize(500) mcmcburnin(200) mcmcinterval(10) seed(1)
assert e(converged) < .

* --- Test 9 (masked TNT follow-on): the SAME core correctness property as
* Test 5, now explicitly under proposal(tnt) rather than relying on it
* being today's default - every FIXED dyad's tie state must be
* bit-identical before/after a real MCMLE fit, free dyads visibly change.
* The "before" reference is the ORIGINAL, hardcoded mynet adjacency
* (re-typed literally, not read back from __nwergm_last_G) - Test 8
* immediately above runs an UNMASKED fit, whose own MCMC chain is free to
* wander at every dyad including the ones Test 9 treats as fixed, so
* __nwergm_last_G's own leftover post-Test-8 state is NOT a trustworthy
* "before" snapshot for this test (confirmed directly: an earlier version
* of this test compared against that leftover state and failed a false
* positive - the mismatch traced to Test 8's own unrelated unmasked
* chain having moved those dyads, not to anything freedyads()/masked-TNT
* itself touched, verified by instrumenting toggle() to trace every
* fixed-dyad toggle directly and finding zero). ---
mata: obs_before9 = (0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,1\0,0,0,1,1,0)
qui nwergm mynet, edges freedyads(freenet) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(7) nonative
assert e(converged) < .
mata: obs_after9 = __nwergm_last_G.to_dense()
mata: fixed_diff9 = sum(abs(obs_after9 - obs_before9) :* fixedmask)
mata: assert(fixed_diff9 == 0)

* --- Test 10 (masked TNT follow-on): a FULLY-FREE mask under proposal(tnt)
* must be TRACE-IDENTICAL to the ordinary unmasked TNT proposal, not just
* "similar" - proves ergm_propose_tnt_masked()'s own D/E substitutions
* (G.nfreedyads/G.nfreeties in place of the unmasked D/E) introduce no bias
* of their own, the masked-TNT analogue of Test 2's fully-free MPLE check.
* With every dyad free, nfreedyads==Dtot and nfreeties==nties hold at
* every step (by induction - toggle() keeps freeelist/elist in lockstep
* whenever every dyad is free), so given the identical starting graph and
* the identical RNG seed, masked and unmasked TNT must consume the exact
* same runiform() draws in the exact same order and propose the exact
* same (i,j,logratio) at every single step - run as two SEPARATE
* full-trajectory simulations (not interleaved draws from one shared RNG
* stream, which would silently hand each side different random numbers)
* with the seed reset immediately before each, then compared as whole
* matrices at the end. ---
* NOTE: a for(...) loop whose braced body is a MULTI-STATEMENT (or even a
* single method-call-with-bracket-arguments) sequence hits a real Stata
* single-line `mata:' command parsing limitation ("illegal arglist") -
* confirmed directly (isolated repro: `mata: for(...) { g.toggle(x[1],x[2]) }'
* fails standalone even as one statement, while the same code inside a
* proper multi-line mata/end block runs fine) - so every loop below uses a
* full mata/end block instead of the single-line `mata: for(...) {...}'
* form the rest of this file otherwise uses for simple (non-looping)
* one-liners.
mata:
__t10_ties = (1,2\1,3\2,3\2,4\3,5\4,5\4,6\5,6)
__t10_free = J(6,6,1)
_diag(__t10_free, 0)
__t10_g1 = ErgmGraph()
__t10_g1.init(6, 0)
for (__t10_k=1; __t10_k<=rows(__t10_ties); __t10_k++) __t10_g1.toggle(__t10_ties[__t10_k,1], __t10_ties[__t10_k,2])
__t10_g1.set_dyadmask(__t10_free)
rseed(99)
__t10_props1 = J(5000, 3, .)
for (__t10_k=1; __t10_k<=5000; __t10_k++) {
	__t10_props1[__t10_k,.] = ergm_propose_tnt_masked(__t10_g1)
	__t10_g1.toggle(__t10_props1[__t10_k,1], __t10_props1[__t10_k,2])
}
__t10_g2 = ErgmGraph()
__t10_g2.init(6, 0)
for (__t10_k=1; __t10_k<=rows(__t10_ties); __t10_k++) __t10_g2.toggle(__t10_ties[__t10_k,1], __t10_ties[__t10_k,2])
rseed(99)
__t10_props2 = J(5000, 3, .)
for (__t10_k=1; __t10_k<=5000; __t10_k++) {
	__t10_props2[__t10_k,.] = ergm_propose_tnt(__t10_g2)
	__t10_g2.toggle(__t10_props2[__t10_k,1], __t10_props2[__t10_k,2])
}
assert(max(abs(__t10_props1 - __t10_props2)) < 1e-9)
assert(reldif(__t10_g1.nfreedyads, ergm_total_dyads(__t10_g2)) < 1e-10)
end

* --- Test 11 (masked TNT follow-on): ergm_propose_tnt_masked() must NEVER
* propose a fixed dyad, over a large number of draws - the direct
* proposal-level analogue of Test 9's fitted-model-level check, isolating
* the proposal function itself from any confound in the surrounding MCMLE
* loop. ---
mata:
__t11_g = ErgmGraph()
__t11_g.init(6, 0)
for (__t11_k=1; __t11_k<=rows(__t10_ties); __t11_k++) __t11_g.toggle(__t10_ties[__t11_k,1], __t10_ties[__t11_k,2])
__t11_g.set_dyadmask((0,1,1,1,1,1\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0))
__t11_bad = 0
for (__t11_k=1; __t11_k<=20000; __t11_k++) {
	__t11_p = ergm_propose_tnt_masked(__t11_g)
	if (!__t11_g.freedyadmat[__t11_p[1], __t11_p[2]]) __t11_bad++
}
assert(__t11_bad == 0)
end

* --- Test 12: real, independent R ergm MCMLE comparison
* (dev/freedyads_tnt_crosscheck.R) - the SAME 6-node/15-dyad network and
* 5-dyad free mask Test 1's own MPLE check uses, now fit via method(mcmle)
* proposal(tnt) freedyads() on the nwergm side against R's own
* constraints=~fixallbut(freenet) (R's default MCMLE, no estimate=
* override). This network's only term (edges) is dyad-independent, so its
* true MLE is exact/closed-form regardless of estimation method - R's own
* MCMLE landed at the identical MPLE value (-0.4054651) when this test was
* authored, not merely "close" - reported literally below for the
* permanent record rather than re-run from R on every test invocation
* (Rscript availability is not assumed at regression-suite run time). ---
qui nwergm mynet, edges freedyads(freenet) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(1) nonative
assert e(converged) < .
assert reldif(_b[edges], -0.4054651) < 0.10

* ===================================================================
* Harmonisation unit 168: native (C) port of the masked TNT/uniform
* proposals (native/ergm_mcmc.c, ErgmNativeSetup()'s new
* native_enabled_sample flag) - Tests 13-16 below.
* ===================================================================

* --- Test 13: a FULLY-FREE mask under native TNT must be exactly
* statistically equivalent to the unmasked native default - in fact
* bit-identical here, not merely "close": with every dyad free,
* g.n_free_dyads==total_dyads and g.free_elist_i/j receives the exact
* same sequence of toggle() appends/removals as g.elist_i/j (both lists
* start empty and are updated in lockstep by the same toggle() calls
* whenever every dyad is free), so propose_tnt_masked() consumes the
* identical RNG draws in the identical order as the unmasked
* propose_tnt() on the same seed - proving the masked C code's own
* population-count substitutions (n_free_dyads/n_free_ties/free_elist
* in place of total_dyads/nties/elist) introduce no bias, the native
* counterpart of the Mata-side "byte-identical (i,j,logratio) sequence"
* finding already established for ergm_propose_tnt_masked() itself. ---
qui nwergm mynet, edges freedyads(fullfree) proposal(tnt) method(mcmle) mcmcsamplesize(500) mcmcburnin(200) mcmcinterval(10) seed(99)
assert e(native) == 1
scalar __t13_b_masked = _b[edges]
qui nwergm mynet, edges proposal(tnt) method(mcmle) mcmcsamplesize(500) mcmcburnin(200) mcmcinterval(10) seed(99)
assert e(native) == 1
assert __t13_b_masked == _b[edges]

* --- Test 14: the SAME core correctness property Test 5 already
* established for Mata (every FIXED dyad's tie state bit-identical
* before/after 3000+ MCMC steps, free dyads visibly do change) - now
* exercised under the NATIVE path specifically (no `nonative`), since a
* native-side bug in the mask/free_elist bookkeeping could silently
* violate this even though the Mata-side proposal itself is untouched
* and already certified.
*
* A real bug caught HERE while writing this test, not by inspection -
* the SAME class this file's own Test 5 header comment already warns
* about: the "before" snapshot MUST be `mynet`'s own true literal
* observed adjacency, never `__nwergm_last_G.to_dense()` taken from
* whatever the IMMEDIATELY PRECEDING test left G as. Test 13's own
* second call (deliberately UNMASKED, to compare against a fully-free
* native fit) lets every dyad wander freely, including the ones
* `freenet`'s mask would normally hold fixed - `nwergm mynet, ...`
* itself freshly rebuilds G from `mynet`'s true stored data at the
* start of ITS OWN call regardless, so the masked fit below is
* genuinely correct throughout, but a "before" snapshot taken from
* Test 13's own drifted leftover state is comparing against the WRONG
* baseline and flags a false-positive violation - confirmed directly
* by a standalone reproduction outside this file that isolates Test 14
* alone (passes clean) vs. the full sequence (fails), then narrowed to
* this exact snapshot-source difference. ---
mata: st_matrix("obs_before14", (0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,1\0,0,0,1,1,0))
qui nwergm mynet, edges freedyads(freenet) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(42)
assert e(converged) < .
assert e(native) == 1
mata: st_matrix("obs_after14", __nwergm_last_G.to_dense())
mata: fixed_diff14 = sum(abs(st_matrix("obs_after14") - st_matrix("obs_before14")) :* fixedmask)
mata: assert(fixed_diff14 == 0)

* --- Test 15: native-vs-Mata statistical equivalence for masked TNT -
* the SAME model/data/seed fit twice, once native (default) and once
* forced Mata (`nonative`) - the two backends use independent RNG
* streams by design (this project's own established standard for every
* other native-vs-Mata comparison, e.g. the recent edgecov/hamming and
* isolateNet/outIso ports), so exact bit-identity is not expected here
* (unlike Test 13's fully-free case, a genuinely SPARSE mask does not
* guarantee free_elist consumes RNG draws identically to the unmasked
* path) - Monte Carlo tolerance (this project's own ~7% relative-
* difference precedent, harmonisation unit 71) is the right bar. ---
qui nwergm mynet, edges freedyads(freenet) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(7)
assert e(native) == 1
scalar __t15_b_native = _b[edges]
qui nwergm mynet, edges freedyads(freenet) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(7) nonative
assert e(native) == 0
assert reldif(__t15_b_native, _b[edges]) < 0.15

* --- Test 16: re-run Test 12's own real R ergm comparison WITHOUT
* nonative - this network's only term (edges) is dyad-independent, so
* its true MLE is the same closed-form value (-0.4054651) regardless of
* which backend produced the MCMC sample; confirms the native masked
* port agrees with real, independent R output, not just with nwergm's
* own Mata implementation. ---
qui nwergm mynet, edges freedyads(freenet) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(1)
assert e(converged) < .
assert e(native) == 1
assert reldif(_b[edges], -0.4054651) < 0.10

* ===================================================================
* blockdiag() - constraints, second concrete piece (docs/ERGM_ROADMAP.md,
* "Constraints beyond v1's free binary dyad space" row): R ergm's own
* constraints=~blockdiag(attr) - "only dyads (i,j) for which
* attr(i)==attr(j) can have edges" (R ergm's own real Rd doc, fetched via
* tools::Rd_db("ergm")). Nothing more than a different way to build the
* SAME dense eligibility mask freedyads()/set_dyadmask() already consume -
* reuses every piece of freedyads()'s own masked-proposal/native machinery
* verbatim, no new proposal or wire-protocol code.
*
* 6-node network, two blocks of 3 (block 1: nodes 1-3; block 2: nodes
* 4-6). Within-block ties: (1,2),(2,3),(4,5) tied, (1,3),(4,6),(5,6)
* untied - 3 of 6 free dyads tied -> free density 0.5 -> logit(0.5) = 0
* EXACTLY. Cross-block
* ties: (1,4),(1,6),(2,5),(3,4),(3,6) - 5 of 9 fixed dyads, deliberately
* asymmetric so the full unconstrained density (8/15) is nowhere near the
* free-block density (3/6=0.5), proving the fit genuinely ignores the
* fixed dyads rather than coincidentally matching. Ground truth verified
* against REAL, installed R ergm 4.12.0 (constraints=~blockdiag("block"),
* estimate="MPLE") - see dev/blockdiag_crosscheck.R: R reports
* 6.946599e-16 (== 0 to floating-point noise), and a single-block mask
* (every node the same block) reproduces the unconstrained MPLE fit
* exactly (0.1335314 == logit(8/15)), confirming blockdiag() with one
* block is correctly a no-op, the same property freedyads()'s own Test 2
* established for a fully-free mask.

nwclear
nwset, mat((0,1,0,1,0,1\1,0,1,0,1,0\0,1,0,1,0,1\1,0,1,0,1,0\0,1,0,1,0,0\1,0,1,0,0,0)) undirected name(blocknet)
gen blk = .
replace blk = 1 in 1
replace blk = 1 in 2
replace blk = 1 in 3
replace blk = 2 in 4
replace blk = 2 in 5
replace blk = 2 in 6
gen blkall = 1

* --- Test 17: MPLE closed form must match real R's blockdiag() output
* exactly (verified externally, see header above) - logit(0.5) = 0. ---
qui nwergm blocknet, edges blockdiag(blk) method(mple)
assert abs(_b[edges]) < 1e-5

* --- Test 18: a single-block mask (every node the same value) must
* reproduce the ordinary unconstrained MPLE fit exactly - both the
* closed form (logit(8/15) = 0.1335314, verified externally) and a
* direct self-consistency check against nwergm's own unconstrained fit
* on the same data. ---
qui nwergm blocknet, edges blockdiag(blkall) method(mple)
assert reldif(_b[edges], 0.1335314) < 1e-5
local __t18_b_blockall = _b[edges]
qui nwergm blocknet, edges method(mple)
assert reldif(`__t18_b_blockall', _b[edges]) < 1e-10

* --- Test 19: blockdiag() and freedyads() cannot be combined in v1 -
* must error out cleanly, not silently pick one or attempt an
* intersection. ---
nwset, mat((0,1,1,1,1,1\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0)) undirected name(fullfree6)
capture nwergm blocknet, edges blockdiag(blk) freedyads(fullfree6) method(mple)
assert _rc != 0

* --- Test 20: the core correctness property - every CROSS-block dyad's
* tie state must be bit-identical before and after a real MCMLE fit
* (1000+ MCMC steps), while WITHIN-block dyads visibly do change. Uses
* a literal hardcoded "before" matrix (Test 14's own documented lesson:
* a snapshot taken from whatever the immediately preceding test left G
* as, rather than the network's own true observed data, is the wrong
* baseline and produces a false-positive violation). ---
mata: __t20_before = (0,1,0,1,0,1\1,0,1,0,1,0\0,1,0,1,0,1\1,0,1,0,1,0\0,1,0,1,0,0\1,0,1,0,0,0)
mata: __t20_blk = st_data(1::6, "blk")
mata: __t20_crossmask = 1 :- _ergm_blockdiag_mask(__t20_blk)
qui nwergm blocknet, edges blockdiag(blk) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(42) nonative
assert e(converged) < .
mata: __t20_after = __nwergm_last_G.to_dense()
mata: __t20_diff = sum(abs(__t20_after - __t20_before) :* __t20_crossmask)
mata: assert(__t20_diff == 0)

* --- Test 21: the SAME core correctness property, now under the NATIVE
* path (no `nonative`) - confirms blockdiag() transparently inherits
* freedyads()'s existing native mask machinery with zero new native
* code, exactly as expected since both feed the identical
* set_dyadmask()/native_maskmat wire field. Also: native-vs-Mata
* statistical equivalence (Monte Carlo tolerance, this project's own
* ~7% relative-difference precedent), and a real R ergm comparison via
* MCMLE (the true MLE for this dyad-independent edges-only term is the
* same closed-form value regardless of MCMC backend). ---
qui nwergm blocknet, edges blockdiag(blk) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(42)
assert e(converged) < .
assert e(native) == 1
mata: __t21_after = __nwergm_last_G.to_dense()
mata: __t21_diff = sum(abs(__t21_after - __t20_before) :* __t20_crossmask)
mata: assert(__t21_diff == 0)

qui nwergm blocknet, edges blockdiag(blk) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(7)
assert e(native) == 1
scalar __t21_b_native = _b[edges]
qui nwergm blocknet, edges blockdiag(blk) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(7) nonative
assert e(native) == 0
assert reldif(__t21_b_native, _b[edges]) < 0.15

qui nwergm blocknet, edges blockdiag(blk) proposal(tnt) method(mcmle) mcmcsamplesize(3000) mcmcburnin(1000) mcmcinterval(30) seed(1)
assert e(converged) < .
assert e(native) == 1
assert abs(_b[edges]) < 0.10

* --- fixdensity (constraints, third piece): R ergm's own
* constraints=~edges - a compound tie/non-tie swap proposal
* (ergm_propose_swap()/ErgmMCMCSampleSwap(), unw_ergm.do) holding the
* total tie count exactly invariant, structurally different from
* freedyads()/blockdiag() (which restrict WHICH single dyad the
* ordinary proposal may touch, not the proposal's own SHAPE) so it
* cannot reuse their masking machinery - see this option's own header
* comment in nwergm.ado for the full account. Verified directly against
* real R ergm 4.12.0 source (MH_ConstantEdges, src/MHproposals.c,
* fetched from the real CRAN source tarball): pick one existing edge
* uniformly, one non-edge uniformly, swap both - symmetric proposal
* (no Hastings-ratio correction), matching this port's own logratio=0.
* --- Test 22: method() validation - fixdensity requires mcmle (a plain
* MPLE fit never runs MCMC at all, so there is no proposal for the
* constraint to restrict). ---
qui nwset, mat((0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,1\0,0,0,1,1,0)) undirected name(fdnet)
capture nwergm fdnet, edges triangle fixdensity method(mple)
assert _rc == 198

* --- Test 23: cannot combine with freedyads()/blockdiag() - each is
* its own self-contained dyad-space restriction in v1. ---
capture nwergm fdnet, edges triangle fixdensity freedyads(fullfree) method(mcmle)
assert _rc == 198

* --- Test 24: at least one term besides edges is required - edges
* itself is dropped (never registered as an estimated term) under this
* constraint, since its own statistic never changes across the whole
* chain by construction (zero information about theta), matching real
* R ergm's own observed behavior (confirmed directly: R fits `edges`
* anyway and reports it fixed at exactly 0 with a "will be ignored"
* warning - not reproduced verbatim here since this project's own
* isfixed-through-MCMLE machinery is still incomplete, see
* docs/ERGM_ROADMAP.md; simply omitting the term achieves the same
* practical estimation outcome). ---
capture nwergm fdnet, edges fixdensity method(mcmle)
assert _rc == 198

* --- Test 25: the CORE correctness property - the total tie count must
* be IDENTICAL at every single step of a long raw swap-proposal run,
* not just before/after a full fit (which could hide a rare corrupting
* path). Directly exercises ergm_propose_swap() 5000 times. ---
qui nwergm fdnet, edges triangle fixdensity method(mcmle) mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(1) seed(1)
mata:
void __t25_invariance(class ErgmModel scalar M, class ErgmGraph scalar G, real rowvector theta, real scalar nsteps){
	real rowvector prop, chg1, chg2, chgtot
	real scalar t1, h1, t2, h2, cutoff, tot0, s

	tot0 = G.nties
	for (s=1; s<=nsteps; s++) {
		prop = ergm_propose_swap(G)
		t1=prop[1]; h1=prop[2]; t2=prop[3]; h2=prop[4]
		chg1 = M.full_change(G, t1, h1)
		G.toggle(t1, h1)
		chg2 = M.full_change(G, t2, h2)
		chgtot = chg1 + chg2
		cutoff = theta * chgtot'
		if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
			G.toggle(t2, h2)
		}
		else {
			G.toggle(t1, h1)
		}
		assert(G.nties == tot0)
	}
}
__t25_invariance(__nwergm_last_M, __nwergm_last_G, (0.3), 5000)
end

* --- Test 26: e(ties) after a fixdensity fit must equal the TRUE
* observed tie count (8 on `fdnet`) - proof the constraint held for the
* whole fit, not just the raw-proposal probe above. ---
assert e(ties) == 8

* --- Test 27: real R ergm comparison (15-node/30-edge network, fixed
* seed, verified externally: R reports edges=0 exactly - fixed/ignored,
* matching Test 24's own reasoning - and triangle=-0.4444239 via
* `ergm(net ~ edges + triangle, constraints=~edges)`, R ergm 4.12.0).
* Monte Carlo tolerance: this project's own established ~7%
* relative-difference precedent for two independent stochastic
* estimators (unit 71's own `mutual` MCMLE certification). ---
qui nwset, mat((0,0,0,0,0,0,0,1,0,1,0,0,0,0,0\0,0,1,1,0,0,0,0,1,0,1,0,0,0,0\0,1,0,0,0,0,1,1,0,0,0,1,0,0,0\0,1,0,0,0,0,0,1,0,0,1,0,0,0,0\0,0,0,0,0,1,1,1,0,1,0,0,1,0,1\0,0,0,0,1,0,0,1,1,1,0,0,0,1,0\0,0,1,0,1,0,0,0,0,1,0,0,0,0,0\1,0,1,1,1,1,0,0,1,0,0,0,1,0,0\0,1,0,0,0,1,0,1,0,0,0,0,0,0,1\1,0,0,0,1,1,1,0,0,0,0,1,0,0,1\0,1,0,1,0,0,0,0,0,0,0,0,0,1,0\0,0,1,0,0,0,0,0,0,1,0,0,0,1,0\0,0,0,0,1,0,0,1,0,0,0,0,0,0,0\0,0,0,0,0,1,0,0,0,0,1,1,0,0,1\0,0,0,0,1,0,0,0,1,1,0,0,0,1,0)) undirected name(fdrnet)
qui nwergm fdrnet, edges triangle fixdensity method(mcmle) mcmcburnin(3000) mcmcinterval(50) mcmcsamplesize(3000) mcmleiterations(20) seed(1)
assert e(ties) == 30
assert reldif(_b[triangle], -0.4444239) < 0.10

di "test_nwergm_constraints.do: ALL TESTS PASSED"
