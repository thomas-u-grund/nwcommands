* Certifies estat mcmcdiag's effective sample size against coda.
* ESS = n*var(x)/spectrum0.ar(x), as coda::effectiveSize(). Reference
* values: coda 0.19 effectiveSize() on e(mcmcsample) of this exact fit
* (Faux Mesa High, edges + nodematch(grade race) + gwesp(.25),
* seed(12345), mcmcinterval(1000), mcmcburnin(20000)):
* 277.8 262.0 317.8 291.8. The lag-1 AR(1) formula used before gave
* 472-539 on the same chain.
clear all
set more off
nwwebuse mesa, nwclear
encode race, generate(racen)
qui nwergm mesa, edges nodematch(grade racen) gwesp(.25) seed(12345) ///
	mcmcinterval(1000) mcmcburnin(20000)
qui estat mcmcdiag
matrix E = r(ess)
matrix R = (277.8, 262.0, 317.8, 291.8)
forvalues k = 1/4 {
	assert abs(E[1,`k'] - R[1,`k']) / R[1,`k'] < 0.01
}
* estat gof defaults follow the fit's MCMC settings (as R's gof.ergm)
qui estat gof, seed(1) nsim(5)
di "test_nwergm_ess.do: ALL TESTS PASSED"
