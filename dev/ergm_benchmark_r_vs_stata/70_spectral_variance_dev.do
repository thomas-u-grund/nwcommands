/*
	70_spectral_variance_dev.do -- development/validation script for
	harmonisation unit 86 (phase B, "inferential parity" - proper
	variance estimator), docs/CERTIFICATION.md.

	Statnet's own current R/mcmc_se.R (fresh GitHub check, August 2026)
	estimates the long-run Monte Carlo covariance of the sufficient
	statistics via `spectrum0.mvar()` (coda package): fit a multivariate
	AR model to the (thinned) MCMC series and evaluate its implied
	spectral density at frequency 0 - the standard "initial sequence"/AR
	approach to MCMC standard errors (Geyer 1992), generalizing far beyond
	a single lag-1 correction. It also computes and reports an explicit
	`neff = n/infl` - the SAME effective-sample-size concept units 84-85
	already added to nwergm's own convergence test, independently
	confirming that mechanism's own conceptual alignment with Statnet's
	real approach, not just this project's own invention.

	nwergm's own existing variance correction (`ergm_lag1_autocorr()',
	unit 80) is a single-lag AR(1) special case of this: for a true AR(1)
	series, the long-run-variance/sample-variance ratio is exactly
	(1+rho)/(1-rho), which is exactly the formula already in use. This
	script implements and validates a proper generalization - AIC-order-
	selected AR(p) per parameter dimension via Yule-Walker equations
	(matching R's own `ar()`/`ar.yw()` default method, which
	`spectrum0.ar`/`spectrum0.mvar` build on) - and empirically compares
	it against the existing lag-1 method on both the original small
	benchmark (where lag-1 already won against batch-means, unit 80) and
	the harder GWESP benchmarks where a real precision gap was found
	(units 84-85's own 5-seed probe: nodematch's across-seed spread was
	~10x its own reported SE on the 500-node benchmark).

	Per this project's own established discipline (batch-means vs lag-1,
	unit 80; shared-partner cache, unit 82): implement, test directly
	against real evidence, and adopt only if it wins - never assumed.
*/

do "unw_ergm.do"

mata:
mata set matastrict off

/*
	Fits AR(p) to a mean-centered univariate series x via Yule-Walker
	equations, selecting p by AIC among candidates 0..pmax (matching R's
	own `ar(x, method="yule-walker", aic=TRUE)' default behavior).
	Returns the long-run-variance/sample-variance inflation factor
	(`infl' - the SAME quantity `ergm_lag1_autocorr()'-based
	`(1+rho)/(1-rho)' already computes for the p=1 special case).
*/
real scalar ergm_ar_yw_infl(real colvector x, real scalar pmax){
	real scalar n, gamma0, k, j, p, best_aic, best_sigma2, sigma2, aic, sumphi, base
	real colvector acf, phi, r
	real matrix R

	n = rows(x)
	gamma0 = variance(x) * (n-1) / n   // population-style (divide by n) autocovariance at lag 0
	if (gamma0 <= 0) return(1)

	acf = J(pmax, 1, 0)
	for (k=1; k<=pmax; k++) {
		acf[k] = (x[1::(n-k)]' * x[(k+1)::n]) / n / gamma0
	}

	// order 0: white noise, infl=1
	best_aic = n * ln(gamma0)
	best_sigma2 = gamma0
	p = 0

	for (j=1; j<=pmax; j++) {
		R = J(j, j, 0)
		r = acf[1::j]
		for (k=1; k<=j; k++) {
			for (base=1; base<=j; base++) {
				R[k,base] = (k==base) ? 1 : acf[abs(k-base)]
			}
		}
		phi = invsym(R) * r
		sigma2 = gamma0 * (1 - r' * phi)
		if (sigma2 <= 0) continue
		aic = n * ln(sigma2) + 2*j
		if (aic < best_aic) {
			best_aic = aic
			best_sigma2 = sigma2
			p = j
			sumphi = sum(phi)
		}
	}

	if (p == 0) return(1)
	if (sumphi >= 1) sumphi = 0.999   // guard against a nonstationary fit at the selected order
	return( (best_sigma2 / (1-sumphi)^2) / gamma0 )
}

/*
	Applies ergm_ar_yw_infl() to every column of D (already-centered
	draws, e.g. samp :- obs), returning a rowvector of inflation factors -
	the direct drop-in replacement for
	`(1 :+ ergm_lag1_autocorr(D)) :/ (1 :- ergm_lag1_autocorr(D))'.
*/
real rowvector ergm_spectral0_ar(real matrix D){
	real scalar ncol, k, n, pmax
	real rowvector out

	ncol = cols(D)
	n = rows(D)
	pmax = floor(min((n-1, 10*log10(n))))
	if (pmax > 50) pmax = 50
	if (pmax < 1) pmax = 1
	out = J(1, ncol, 1)
	for (k=1; k<=ncol; k++) out[k] = ergm_ar_yw_infl(D[.,k], pmax)
	return(out)
}

/*
	Sanity check 1: exact AR(1) special case must reduce to the existing
	(1+rho)/(1-rho) formula (confirms the new estimator is a strict
	generalization, not merely inspired by the old one).
*/
void test_ar1_reduces_to_lag1(){
	real colvector x
	real scalar n, i, phi_true, infl_new, rho, infl_old

	rseed(9101)
	n = 20000
	phi_true = 0.6
	x = J(n, 1, 0)
	for (i=2; i<=n; i++) x[i] = phi_true*x[i-1] + rnormal(1,1,0,1)
	x = x :- mean(x)

	infl_new = ergm_ar_yw_infl(x, 20)
	rho = correlation((x[1::(n-1)], x[2::n]))[1,2]
	infl_old = (1+rho)/(1-rho)

	printf("AR(1) sanity: true phi=%4.2f  infl_new=%6.3f  infl_old(lag1)=%6.3f  analytic=%6.3f\n",
		phi_true, infl_new, infl_old, (1+phi_true)/(1-phi_true))
	assert(reldif(infl_new, infl_old) < 0.05)
}
test_ar1_reduces_to_lag1()

/*
	Sanity check 2: a true AR(2) series with negligible lag-1
	autocorrelation but real longer-range structure should be caught by
	the new estimator (infl clearly > 1) while the OLD lag-1-only method
	would report infl near 1 (falsely "no correction needed") - this is
	exactly the failure mode the new estimator exists to fix.
*/
void test_ar2_catches_lag1_miss(){
	real colvector x
	real scalar n, i, infl_new, rho, infl_old

	rseed(9102)
	n = 20000
	// phi1=0.05 (~zero lag-1 autocorrelation by construction), phi2=0.85
	// (strong lag-2 structure) - true model x_t = 0.05 x_{t-1} + 0.85 x_{t-2} + e_t
	x = J(n, 1, 0)
	for (i=3; i<=n; i++) x[i] = 0.05*x[i-1] + 0.85*x[i-2] + rnormal(1,1,0,1)
	x = x :- mean(x)

	infl_new = ergm_ar_yw_infl(x, 20)
	rho = correlation((x[1::(n-1)], x[2::n]))[1,2]
	infl_old = (1+rho)/(1-rho)

	printf("AR(2) sanity: lag1 rho=%6.3f  infl_new=%6.3f  infl_old(lag1-only)=%6.3f\n", rho, infl_new, infl_old)
	assert(infl_new > 3*infl_old)
}
test_ar2_catches_lag1_miss()

end
