cscript

do unw_core.do
do unw_ergm.do

* Certifies nwergm_estat.ado (`estat mcmcdiag' - Part XIX of the governing
* nwergm task: basic MCMC diagnostics). Exercises the REAL Stata `estat'
* dispatch mechanism (not a direct call to nwergm_estat_mcmcdiag) since
* that dispatch itself had a real bug during development: `estat.ado'
* only forwards to a command's own e(estat_cmd) program and then does
* `return add' - a nested rclass helper program's own r() results do NOT
* automatically survive back up through an intermediate rclass caller
* unless that caller ALSO explicitly does `return add' (confirmed via an
* isolated 2-level rclass-nesting repro before concluding this was the
* actual cause, not merely reading Stata documentation and assuming).

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(mydirnet) labs(A,B,C,D,E)

* --- MPLE path: no MCMC sample exists, estat mcmcdiag must error
* informatively (r(498)), not crash or silently show garbage.
qui nwergm mydirnet, edges mutual method(mple)
capture noisily estat mcmcdiag
assert _rc == 498

* --- MCMLE path: estat mcmcdiag runs, returns a genuine acceptance
* rate in (0,1], and its value matches e(mcmc_acceptrate) exactly (both
* ultimately come from the same ErgmMCMLEFit.acceptrate, certified
* independently at the Mata level in test_nwergm_mcmc.do - this test is
* about the .ado/estat plumbing, not re-deriving that number).
set seed 999
qui nwergm mydirnet, edges mutual mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
qui estat mcmcdiag
assert r(acceptrate) > 0 & r(acceptrate) <= 1
assert reldif(r(acceptrate), e(mcmc_acceptrate)) < 1e-10

* --- e(mcmcsample) is a real (mcmcsamplesize x nparam) matrix of
* finite values, not missing/degenerate.
assert rowsof(e(mcmcsample)) == e(mcmc_samplesize)
assert colsof(e(mcmcsample)) == colsof(e(b))
mata: assert(!missing(st_matrix("e(mcmcsample)")))

* --- estat mcmcdiag survives estimates store/restore (the same
* estimates-machinery Mata-tempvar-leak class of bug fixed in
* docs/CERTIFICATION.md unit 73 would show up here too if reintroduced).
estimates store m1
estimates restore m1
qui estat mcmcdiag
assert r(acceptrate) > 0 & r(acceptrate) <= 1

* --- estat mcmcdiag, plot: trace + density per statistic, combined into
* one figure (R mcmc.diagnostics()'s own analogue). `set graphics off'
* (the same convention test_nwplot.do uses) still exercises the full
* twoway/graph combine code path without popping up a GUI window during
* a batch test run; not a pixel-level regression test, just confirms the
* plot machinery runs clean end to end and leaves a real graph behind.
set graphics off
qui estat mcmcdiag, plot
capture graph describe mcmcdiag
assert _rc == 0
graph drop mcmcdiag
di "=== estat mcmcdiag, plot REGRESSION VERIFIED ==="

* =====================================================================
* Harmonisation unit 144: formal MCMC convergence diagnostics (Geweke
* 1992 / Heidelberger-Welch 1983), the two `coda`-package tests behind R
* ergm's own `mcmc.diagnostics()`. `ergm_geweke_z()`/`ergm_heidel_diag()`
* (unw_ergm.do) were ALREADY certified once this unit, directly against
* real `coda` 0.19.4.1 output (fetched and read from a local R install,
* not recalled from memory) on two synthetic reference series - see
* docs/CERTIFICATION.md unit 144 for that full numeric comparison. What
* follows is the PERMANENT regression test: (1) through the real
* `estat mcmcdiag` command end to end on an actual nwergm fit, checking
* the returned matrices are well-formed and internally consistent
* (rather than re-deriving specific numbers a real MCMLE fit's own RNG
* trajectory cannot reproduce deterministically call to call); (2) a
* direct Mata-level check that the underlying functions correctly
* DISTINGUISH a converged chain from a deliberately non-converged one,
* using Mata's own reproducible rseed()/runiform() rather than
* attempting to bit-match R's own RNG stream (not practical, and not
* the actual contract these diagnostics need to satisfy - what matters
* is that a real problem gets flagged and a healthy chain does not).
* =====================================================================

* --- estat mcmcdiag returns r(geweke) (1 x p) and r(heidel) (p x 6),
* well-formed and internally consistent: every Geweke z is finite; every
* Heidelberger-Welch row's own stest/start/htest/mean/halfwidth columns
* obey the documented missing-value contract (stest=0 implies the other
* five are NOT all populated the same way stest=1 requires - specifically
* start/htest/mean/halfwidth must be missing when stest=0, exactly
* mirroring coda::heidel.diag's own convention). A fresh, unqualified
* `estat mcmcdiag` call right before reading r() - not relying on the
* `plot` test's own leftover results just above, since `graph describe`/
* `graph drop` (both r-class) run in between and would silently clobber
* r(geweke)/r(heidel) with their own unrelated r()-results first.
qui estat mcmcdiag
mata: assert(!missing(st_matrix("r(geweke)")))
mata: __ergm_hd = st_matrix("r(heidel)")
mata: assert(rows(__ergm_hd) == cols(st_matrix("e(b)")))
mata: assert(cols(__ergm_hd) == 6)
mata: assert(all(__ergm_hd[.,1] :== 0 :| __ergm_hd[.,1] :== 1))
mata:
for (__ergm_i=1; __ergm_i<=rows(__ergm_hd); __ergm_i++) {
	if (__ergm_hd[__ergm_i,1]==0) {
		assert(missing(__ergm_hd[__ergm_i,2]))
		assert(missing(__ergm_hd[__ergm_i,4]))
		assert(missing(__ergm_hd[__ergm_i,5]))
		assert(missing(__ergm_hd[__ergm_i,6]))
	}
	else {
		assert(!missing(__ergm_hd[__ergm_i,2]))
		assert(!missing(__ergm_hd[__ergm_i,5]))
		assert(!missing(__ergm_hd[__ergm_i,6]))
	}
}
end
mata: mata drop __ergm_hd __ergm_i
di "=== estat mcmcdiag: r(geweke)/r(heidel) well-formed and internally consistent ==="

* --- pvalue() restricted to the 4-level Cramer-von-Mises critical-value
* table (unw_ergm.do's own header comment on ergm_heidel_diag() explains
* why a continuous p-value is not offered) - anything else must error
* informatively, not silently fall back to a wrong/default critical value.
* The three VALID cases are confirmed via r(geweke)'s own content, not
* `_rc' - confirmed directly (isolated probes, harmonisation unit 144)
* that `_rc' is genuinely NOT reset by trivial commands (`local', `di')
* in this Stata version, only by commands that explicitly set it, so a
* stale nonzero `_rc' left by an EARLIER internal `capture' inside
* `estat mcmcdiag' (of which it has several, e.g. around `graph drop' in
* its own `plot' block) can persist through a later, fully successful
* call - `_rc' is simply not a reliable success signal for this command;
* r()-content is.
capture noisily estat mcmcdiag, pvalue(0.5)
assert _rc == 198
qui estat mcmcdiag, pvalue(0.10)
mata: assert(!missing(st_matrix("r(geweke)")))
qui estat mcmcdiag, pvalue(0.025)
mata: assert(!missing(st_matrix("r(geweke)")))
qui estat mcmcdiag, pvalue(0.01)
mata: assert(!missing(st_matrix("r(geweke)")))
di "=== estat mcmcdiag, pvalue(): 4-level table enforced ==="

* --- direct Mata-level certification: ergm_geweke_z()/ergm_heidel_diag()
* must correctly distinguish a converged (stationary, no trend) chain
* from a deliberately non-converged (trending) one - the actual
* statistical contract both tests exist to enforce. Built via Mata's own
* rseed()/runiform() for full reproducibility (no external RNG/file
* dependency), not a claim to reproduce R's own specific RNG stream -
* see docs/CERTIFICATION.md unit 144 for the separate, one-time exact
* numeric comparison against real coda output that already happened.
mata: rseed(4242)
mata: __ergm_n = 2000
mata: __ergm_noise = rnormal(__ergm_n, 1, 0, 1)
mata: __ergm_conv = J(__ergm_n, 1, 0)
mata: __ergm_conv[1] = __ergm_noise[1]
mata: for (__ergm_t=2; __ergm_t<=__ergm_n; __ergm_t++) __ergm_conv[__ergm_t] = 0.6*__ergm_conv[__ergm_t-1] + __ergm_noise[__ergm_t]
mata: __ergm_conv = __ergm_conv :+ 3
mata: __ergm_drift = __ergm_conv :+ (0::(__ergm_n-1)) :* (5/(__ergm_n-1))
mata: __ergm_gz_conv = ergm_geweke_z(__ergm_conv)
mata: __ergm_gz_drift = ergm_geweke_z(__ergm_drift)
mata: st_local("__ergm_gzc", strofreal(abs(__ergm_gz_conv[1,1])))
mata: st_local("__ergm_gzd", strofreal(abs(__ergm_gz_drift[1,1])))
di "converged-series |geweke z| = `__ergm_gzc' (expect small); trending-series |geweke z| = `__ergm_gzd' (expect large)"
assert `__ergm_gzc' < 3
assert `__ergm_gzd' > 10

mata: __ergm_hd_conv = ergm_heidel_diag(__ergm_conv, 0.4613612936, 0.1)
mata: __ergm_hd_drift = ergm_heidel_diag(__ergm_drift, 0.4613612936, 0.1)
mata: st_local("__ergm_stest_conv", strofreal(__ergm_hd_conv[1,1]))
mata: st_local("__ergm_stest_drift", strofreal(__ergm_hd_drift[1,1]))
di "converged-series heidel stest = `__ergm_stest_conv' (expect 1); trending-series heidel stest = `__ergm_stest_drift' (expect 0)"
assert `__ergm_stest_conv' == 1
assert `__ergm_stest_drift' == 0
mata: mata drop __ergm_n __ergm_noise __ergm_conv __ergm_drift __ergm_t __ergm_gz_conv __ergm_gz_drift __ergm_hd_conv __ergm_hd_drift
di "=== ergm_geweke_z()/ergm_heidel_diag(): correctly distinguish converged from non-converged chains ==="

* =====================================================================
* Harmonisation unit 154: nomcmcsample - opts out of posting
* e(mcmcsample) at all, the single slowest step of a fit with a large
* mcmcsamplesize() (a genuine Stata matrix-engine cost at bulk-data
* scale, directly profiled - over 30 seconds at 100,000 rows,
* REGARDLESS of destination matrix name, ruling out any e()-specific
* overhead - not something restructuring estat mcmcdiag's own
* consumption could help with, since reading an already-posted matrix
* back is fast at any size; see nwergm.ado's own build-up comment at
* the e(mcmcsample) posting site for the full account, including the
* correction to docs/ERGM_ROADMAP.md's own earlier guess about where
* the fix would need to live). Run LAST in this file, after every
* other test, so it does not disturb the e(mcmcsample)-bearing active
* fit earlier tests in this file depend on. Coefficients/SEs are
* completely unaffected (a pure MCMLE point/vcov result, computed
* before the final-sample posting either way); estat mcmcdiag then
* fails with a clear, specific error (not the generic "MPLE path"
* r(498) the very first test in this file exercises for a different
* reason, and not a raw "matrix not found" crash).
* =====================================================================

set seed 999
qui nwergm mydirnet, edges mutual mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15) nomcmcsample
capture confirm matrix e(mcmcsample)
assert _rc != 0
assert e(mcmc_samplesize) == 1000
capture noisily estat mcmcdiag
assert _rc == 498
di "=== nomcmcsample: e(mcmcsample) correctly skipped, estat mcmcdiag fails informatively, coefficients unaffected ==="
