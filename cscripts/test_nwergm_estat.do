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
