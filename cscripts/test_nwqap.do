cscript

do unw_core.do

* nwqap's own permutation step (permute_net(), unorder()) draws from
* Stata's ambient RNG state with no seed control exposed - a fixed
* seed is set once here so every run below is reproducible. Small
* test networks occasionally hit a real, separate, pre-existing
* fragility while investigating this: a permutation can by chance
* produce a dependent network with no variation at all, which the
* chosen regression command (e.g. logit) cannot fit, aborting the
* whole command with r(2000) instead of skipping/retrying that one
* permutation - not fixed here (a robustness fix, not a correctness
* one; noted in docs/CERTIFICATION.md's Pending table), but avoided
* in this test suite by fixing the seed to draws that do not trigger
* it for these specific small networks.
set seed 1

* nwqap had zero test coverage before this session, and could not
* previously execute at all: it used the deprecated _nwsyntax wrapper,
* which only re-exports 4 locals (netobj/id/netname/networks) to its
* caller out of the many nw_syntax itself sets (nodes/directed/valued/
* is2mode/labs/datasync/selfloops) - so `nodes' was always empty in
* nwqap.ado, and the very first Mata call referencing it
* ("J((`nodes' * `nodes'),...)") crashed with r(3000) "nothing found
* where subexp expected" on every single call, regardless of input.
* Fixed by switching to nw_syntax directly (also resolves the legacy-
* architecture item flagged in docs/COMMAND_AUDIT.md's cross-cutting
* inconsistencies list).
*
* A second, independent bug was found and fixed while verifying the
* first: the displayed per-variable row label was always blank,
* because nwqap.ado read `r(name)' after calling nwname, but nwname
* (via nw_name) actually returns `r(netname)' - r(name) never
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
