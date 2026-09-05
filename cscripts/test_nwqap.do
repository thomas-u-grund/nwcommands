cscript

do unw_core.do

* nwqap's own permutation step (permute_net(), unorder()) draws from
* Stata's ambient RNG state with no seed control exposed - a fixed
* seed is set once here so every run below is reproducible.
set seed 1

* nwqap had zero test coverage before this session, and could not
* previously execute at all: it used the deprecated _nwsyntax wrapper,
* which only re-exports 4 locals (netobj/id/netname/networks) to its
* caller out of the many _nwsyntax itself sets (nodes/directed/valued/
* is2mode/labs/datasync/selfloops) - so `nodes' was always empty in
* nwqap.ado, and the very first Mata call referencing it
* ("J((`nodes' * `nodes'),...)") crashed with r(3000) "nothing found
* where subexp expected" on every single call, regardless of input.
* Fixed by switching to _nwsyntax directly (also resolves the legacy-
* architecture item flagged in docs/COMMAND_AUDIT.md's cross-cutting
* inconsistencies list).
*
* A second, independent bug was found and fixed while verifying the
* first: the displayed per-variable row label was always blank,
* because nwqap.ado read `r(name)' after calling nwname, but nwname
* (via _nwname) actually returns `r(netname)' - r(name) never
* existed, so the label local was always empty. This only affected
* the printed table, not e(b)/e(pvalues) (Stata's own regression
* command sets those directly from the dataset's actual variable
* names, unaffected by nwqap's own display-label bookkeeping) - not
* independently regression-tested here for that reason, but the
* nwname/r(netname) contract itself is spot-checked below to guard
* against ever reintroducing the r(name)/r(netname) confusion.

* --- basic run: DV and IV both networks, must not crash (the
* headline fix). type(regress) with wdv = 2*iv1 exactly (every tie in
* wdv has weight exactly 2, matching iv1's 0/1 pattern) gives an
* exactly checkable coefficient: 2, with a ~0 intercept.
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(wdv) undirected labs(A,B,C,D,E)
nwqap wdv iv1, permutations(2) type(regress)
mat b = e(b)
assert reldif(b[1,1], 2) < 1e-6
assert abs(b[1,2]) < 1e-6

* --- weighted DV under the *default* type (logit): this is exactly
* the "silently mishandles weights" case the harmonisation brief
* flags - logit treats any nonzero tie value as a positive outcome
* (Stata's own documented behavior for logit, not something nwqap
* does), so the weighted network above and its plain binary
* equivalent (same nonzero pattern, weight 1 instead of 2) must give
* the IDENTICAL logit coefficient - demonstrating that tie strength
* really is discarded under the default type, which is exactly why
* nwqap now prints an explicit warning in this situation (not
* asserted here via text-capture, which isn't this suite's idiom;
* the underlying discard-of-weight behavior is what's being verified
* numerically instead).
nwclear
nwset, mat((0,1,0,1,1,0\1,0,1,0,0,1\0,1,0,1,0,0\1,0,1,0,1,1\1,0,0,1,0,0\0,1,0,1,0,0)) name(iv1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,1\1,0,0,1,1,0\1,0,0,1,1,0\0,1,1,0,0,1\0,1,1,0,0,0\1,0,0,1,0,0)) name(bindv) undirected labs(A,B,C,D,E,F)
nwqap bindv iv1, permutations(3)
mat b1 = e(b)
nwclear
nwset, mat((0,1,0,1,1,0\1,0,1,0,0,1\0,1,0,1,0,0\1,0,1,0,1,1\1,0,0,1,0,0\0,1,0,1,0,0)) name(iv1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,4,2,0,0,3\4,0,0,1,5,0\2,0,0,2,4,0\0,1,2,0,0,1\0,5,4,0,0,0\3,0,0,1,0,0)) name(wdv) undirected labs(A,B,C,D,E,F)
nwqap wdv iv1, permutations(3)
mat b2 = e(b)
assert reldif(b1[1,1], b2[1,1]) < 1e-6

* --- variable (not network) IV path: must not crash, must produce a
* one-column e(b) (nwexpand's own correctness is covered by
* cscripts/test_nwexpand.do - this only confirms the nwqap-side
* variable-IV plumbing runs end to end)
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(dv) undirected labs(A,B,C,D,E)
gen attr = _n
nwqap dv attr, permutations(2)
mat b3 = e(b)
assert colsof(b3) == 2

* --- nwname's r(netname) contract: the exact return name that
* nwqap.ado's row-label fix now reads (was previously misread as the
* nonexistent r(name), leaving every printed row label blank)
nwclear
nwset, mat((0,1\1,0)) name(labeltest)
nwname labeltest
assert `"`r(netname)'"' == `"labeltest"'

* --- permutation-degeneracy robustness: a permutation can by chance
* produce a fully degenerate (no-variation) dependent network, which
* the chosen regression command can't fit (e.g. logit's "outcome
* does not vary"). This used to abort the whole nwqap call with
* r(2000) on the very first degenerate draw - now it retries with a
* fresh permutation instead. seed 5 with this small, sparse 4-node
* pair is confirmed (by direct instrumentation while building the
* fix) to hit 4 degenerate draws across its 10 permutations - before
* the fix this would have crashed on the first one; now it must
* complete cleanly regardless.
nwclear
set seed 5
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(iv1) undirected labs(A,B,C,D)
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,0\0,0,0,0)) name(dv1) undirected labs(A,B,C,D)
nwqap dv1 iv1, permutations(10)
assert _rc == 0

* --- eclass integration: e(b)/e(V) posted via ereturn post (rather
* than left as bare st_matrix writes) so estimates store/estimates
* table/postestimation commands like test/lincom work normally.
* logit's own e(b) carries an equation name (its depvar) on its
* column stripe while regress's does not - a bare "matrix colnames"
* call preserves whatever equation name is already on a stripe
* rather than clearing it, so nwqap's own e(b)/e(V) previously ended
* up with mismatched stripes (one eq-qualified, one not) specifically
* under logit, crashing ereturn post with r(507) "name conflict" -
* not under regress, since regress's e(b) has no equation name to
* begin with. Fixed by explicitly blanking both stripes' equation
* names before assigning column/row names. Both regression families
* are exercised below so this never regresses silently for either
* one.
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(wdv) undirected labs(A,B,C,D,E)
nwqap wdv iv1, permutations(2) type(regress)
assert _rc == 0
assert e(N) == 20
assert e(permutations) == 2
assert `"`e(cmd)'"' == "nwqap"
assert `"`e(depvar)'"' == "wdv"
assert `"`e(qap_regcmd)'"' == "regress"
mat b = e(b)
mat V = e(V)
assert colsof(b) == 2
assert V[1,1] < .
assert V[2,2] < .
estimates store q_regress
qui test iv1
qui lincom iv1

nwclear
nwset, mat((0,1,0,1,1,0\1,0,1,0,0,1\0,1,0,1,0,0\1,0,1,0,1,1\1,0,0,1,0,0\0,1,0,1,0,0)) name(iv1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,1\1,0,0,1,1,0\1,0,0,1,1,0\0,1,1,0,0,1\0,1,1,0,0,0\1,0,0,1,0,0)) name(bindv) undirected labs(A,B,C,D,E,F)
nwqap bindv iv1, permutations(5) type(logit)
assert _rc == 0
assert `"`e(qap_regcmd)'"' == "logit"
mat b = e(b)
mat V = e(V)
assert colsof(b) == 2
estimates store q_logit
qui test iv1

estimates table q_regress q_logit
qui estimates restore q_regress
mat b3 = e(b)
assert reldif(b3[1,1], 2) < 1e-6

* --- predict(): a native postestimation `predict` cannot work after
* nwqap returns (see nwqap.ado's own header comment for why - the
* dyad-level dataset type() actually fits is gone by the time nwqap
* exits), so predict() captures type()'s own fitted values directly,
* at the one point internally where they're genuinely meaningful.
* Reusing the exact wdv=2*iv1 network from this file's very first test
* (type(regress), coefficient exactly 2, ~0 intercept) gives an
* EXACTLY checkable result: since the fit is a perfect noiseless
* linear relationship, the fitted network must reproduce the observed
* wdv network almost exactly (up to floating-point rounding of the
* regression coefficient itself), not merely "look plausible".
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(wdv) undirected labs(A,B,C,D,E)
nwqap wdv iv1, permutations(2) type(regress) predict(wdvfitted)
assert _rc == 0
capture _nwsyntax wdvfitted, other(_check)
assert _rc == 0
nwtomata wdvfitted, mat(fittedcheck)
mata: st_numscalar("maxdiff", max(abs(fittedcheck - (0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0))))
assert maxdiff < 1e-6
mata: mata drop fittedcheck

* diagonal is forced to a clean 0, not left holding predict()'s own
* (always-missing, since every IV is missing on the diagonal by
* construction) raw value.
nwtomata wdvfitted, mat(fittedcheck2)
mata: st_numscalar("diagsum", sum(abs(diagonal(fittedcheck2))))
assert diagsum == 0
mata: mata drop fittedcheck2

* logit's own default predict is Pr(y=1) - bounded in [0,1], unlike
* regress's unbounded fitted mean above; only a sanity-bound check is
* possible here (logit's MLE fit isn't hand-computable the way a
* perfect linear relationship is), which is exactly what's checked -
* not asserted equal to any specific hand-derived value.
nwclear
nwset, mat((0,1,0,1,1,0\1,0,1,0,0,1\0,1,0,1,0,0\1,0,1,0,1,1\1,0,0,1,0,0\0,1,0,1,0,0)) name(iv1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,1\1,0,0,1,1,0\1,0,0,1,1,0\0,1,1,0,0,1\0,1,1,0,0,0\1,0,0,1,0,0)) name(bindv) undirected labs(A,B,C,D,E,F)
nwqap bindv iv1, permutations(3) type(logit) predict(bindvfitted)
assert _rc == 0
nwtomata bindvfitted, mat(logitfitted)
mata: st_numscalar("minfit", min(logitfitted))
mata: st_numscalar("maxfit", max(logitfitted))
assert minfit >= 0 & minfit < .
assert maxfit <= 1
mata: mata drop logitfitted

* --- predict()'s name-collision handling matches every other
* network-creating command: a second call with the same predict()
* name auto-renames rather than silently overwriting.
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(wdv) undirected labs(A,B,C,D,E)
nwqap wdv iv1, permutations(2) type(regress) predict(wdvfitted)
assert _rc == 0
nwqap wdv iv1, permutations(2) type(regress) predict(wdvfitted)
assert _rc == 0
capture _nwsyntax wdvfitted_1, other(_check)
assert _rc == 0


* --- alpha-audit regression: when the FINAL, non-permuted, real-data
* regression itself cannot be fit (e.g. perfect prediction/separation),
* nwqap used to abort completely silently - only a bare "r(2000);"
* printed, no diagnostic text at all, since that specific call was
* never captured and (without detail) ran quietly, suppressing even
* Stata's own native error text. This is distinct from the existing
* degenerate-PERMUTATION-draw retry logic above, which only guards the
* permutation loop, not this final real-data fit. Must now fail with a
* real, nonzero, catchable _rc and an actual printed message.
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(qapdv) undirected labs(A,B,C,D,E)
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(qapiv) undirected labs(A,B,C,D,E)
capture noisily nwqap qapdv qapiv, permutations(2)
assert _rc != 0
di "=== SILENT-CRASH-ON-UNFITTABLE-REAL-DATA REGRESSION VERIFIED ==="

* moderate-severity pass, stat_models group: a misspelled/nonexistent
* network name used to crash with a raw Mata error (r3301) instead of a
* clean message.
nwclear
nwrandom 5, prob(.5) name(realnetqap)
capture noisily nwqap typobogus
assert _rc == 482
di "=== misspelled network name REGRESSION VERIFIED ==="

* --- plot(): one histogram-plus-reference-line panel per coefficient,
* without disturbing the caller's own dataset (nwqap already
* preserve/restores around its own permutation dataset; a fresh
* variable "canary" confirms that survives plot()'s own additional
* graph-building work on top of it intact).
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1plot) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(wdvplot) undirected labs(A,B,C,D,E)
clear
set obs 4
gen canary = _n
nwqap wdvplot iv1plot, permutations(20) type(regress) plot name(qapplottest)
assert _rc == 0
assert _N == 4
assert canary[1]==1 & canary[2]==2 & canary[3]==3 & canary[4]==4
capture graph drop qapplottest
di "=== nwqap plot() OK ==="


* --- qapspp: double semi-partialling (harmonisation unit 165,
* docs/ROADMAP.md's own tracked "QAPSPP as a second inference mode"
* gap). Real checks, not just "runs without error": (1) qapspp must
* NEVER change the model's own point estimates (e(b)) - it only changes
* how each coefficient's own p-value/variance is derived; (2) with a
* single independent variable there is nothing to partial out, so a
* bivariate regression's own slope is invariant to demeaning - qapspp's
* own coefficient must exactly match plain QAP's, not merely be close;
* (3) every returned p-value must be a real, bounded [0,1] probability,
* not a stray missing/out-of-range value, across a genuine 2-IV model.
nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1spp) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(wdvspp) undirected labs(A,B,C,D,E)

set seed 100
nwqap wdvspp iv1spp, permutations(100) type(regress)
mat b_plain_1iv = e(b)

set seed 100
nwqap wdvspp iv1spp, permutations(100) type(regress) qapspp
mat b_dsp_1iv = e(b)
mata: assert(mreldif(st_matrix("b_plain_1iv"), st_matrix("b_dsp_1iv")) < 1e-6)
di "=== qapspp: point estimates unchanged (single-IV) REGRESSION VERIFIED ==="

nwclear
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(iv1spp2) undirected labs(A,B,C,D,E)
nwset, mat((0,0,1,0,1\0,0,0,1,0\1,0,0,1,0\0,1,1,0,1\1,0,0,1,0)) name(iv2spp2) undirected labs(A,B,C,D,E)
nwset, mat((0,3,1,2,0\3,0,2,0,1\1,2,0,1,2\2,0,1,0,0\0,1,2,0,0)) name(wdvspp2) undirected labs(A,B,C,D,E)

nwqap wdvspp2 iv1spp2 iv2spp2, permutations(100) type(regress) qapspp
mat b_dsp_2iv = e(b)
mat p_dsp_2iv = e(pvalues)
mata: assert(all(st_matrix("p_dsp_2iv") :>= 0 :& st_matrix("p_dsp_2iv") :<= 1))

nwqap wdvspp2 iv1spp2 iv2spp2, permutations(20) type(regress)
mat b_plain_2iv = e(b)
mata: assert(mreldif(st_matrix("b_dsp_2iv"), st_matrix("b_plain_2iv")) < 1e-6)
di "=== qapspp: point estimates unchanged + valid p-values (multi-IV) REGRESSION VERIFIED ==="
