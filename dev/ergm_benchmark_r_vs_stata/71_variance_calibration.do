/*
	71_variance_calibration.do -- multi-seed calibration check for the
	existing lag-1 variance estimator vs. the new AR(p)/Yule-Walker
	estimator (harmonisation unit 86, docs/CERTIFICATION.md, phase B).

	Methodology: refit the SAME observed network many times at different
	seeds, and for each fit's own final MCMC sample, compute BOTH
	variance estimates (existing lag-1 `(1+rho)/(1-rho)' and the new
	AR(p)-via-Yule-Walker one). A well-calibrated estimator's own AVERAGE
	reported variance across seeds should match the ACROSS-SEED empirical
	variance of the fitted coefficients themselves (the ground truth for
	calibration - not a hand-derived analytic value, since MCMLE is
	itself stochastic). Run on both the small, well-mixing 30-node
	edges+mutual benchmark (where lag-1 already won against batch-means,
	unit 80 - the new estimator must not regress this case) and the
	500-node sparse GWESP benchmark (where unit 84-85's own 5-seed probe
	found nodematch's empirical spread ~10x its own reported lag-1 SE -
	the case this unit exists to fix).
*/

do "unw_ergm.do"

mata:
mata set matastrict off

real scalar ergm_ar_yw_infl(real colvector x, real scalar pmax){
	real scalar n, gamma0, k, j, p, best_aic, best_sigma2, sigma2, aic, sumphi, base
	real colvector acf, phi, r
	real matrix R

	n = rows(x)
	gamma0 = variance(x) * (n-1) / n
	if (gamma0 <= 0) return(1)

	acf = J(pmax, 1, 0)
	for (k=1; k<=pmax; k++) acf[k] = (x[1::(n-k)]' * x[(k+1)::n]) / n / gamma0

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
	if (sumphi >= 1) sumphi = 0.999
	return( (best_sigma2 / (1-sumphi)^2) / gamma0 )
}

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
	Refits (M,G) `nseeds' times, seeds `seedbase'..`seedbase'+nseeds-1.
	Prints, per parameter: across-seed empirical SD of the fitted coef
	(ground truth), mean reported SD under lag-1, mean reported SD under
	the new AR-YW estimator - a well-calibrated estimator's own mean
	reported SD should be close to the empirical SD.
*/
/*
	Genuine Erdos-Renyi random construction (NOT the deterministic
	modular-offset builder the microbenchmark scripts use, which is fine
	for pure TIMING measurements but statistically degenerate here - it
	produces near-zero mutual/reciprocated ties by construction, an
	edge-of-parameter-space case that sent an early draft of this script's
	own "mutual" coefficient diverging toward -6 to -7 rather than a
	genuinely estimable value, which had nothing to do with either
	variance estimator being compared). Each ordered (directed) or
	unordered (undirected) pair gets an independent Bernoulli(p) draw -
	an ordinary random graph a MUTUAL or GWESP term has real, finite
	information about.
*/
void build_net_fixed(class ErgmGraph G, real scalar n, real scalar p, real scalar directed, real scalar buildseed){
	real scalar i, j
	rseed(buildseed)
	G.init(n, directed)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (!directed & j<i) continue
			if (runiform(1,1) < p) G.toggle(i,j)
		}
	}
}

void calibration_sweep(class ErgmModel scalar M,
		real scalar n, real scalar dens, real scalar directed, real scalar buildseed,
		real rowvector theta0, real scalar burnin, real scalar interval,
		real scalar samplesize, real scalar nseeds, real scalar seedbase,
		string scalar label){

	class ErgmGraph scalar G
	struct ErgmMCMLEFit scalar fit
	real matrix coefs, sd_lag1, sd_arwy
	real scalar s, p, k
	real matrix samp, D
	real rowvector rho, infl_lag1, infl_arwy
	real matrix V

	p = cols(theta0)
	coefs = J(nseeds, p, 0)
	sd_lag1 = J(nseeds, p, 0)
	sd_arwy = J(nseeds, p, 0)

	// native backend (unit 83) if the model is eligible - keeps this
	// multi-seed sweep fast enough to run routinely
	ErgmNativeSetup(M, 2)

	for (s=1; s<=nseeds; s++) {
		G = ErgmGraph()
		build_net_fixed(G, n, dens, directed, buildseed)   // SAME observed network every seed - only the MCMC's own RNG stream differs
		rseed(seedbase + s)
		fit = ErgmMCMLE(M, G, theta0, 20, burnin, interval, samplesize, &ergm_propose_tnt(), 0)
		coefs[s,.] = fit.coef

		samp = fit.finalsample
		D = samp :- mean(samp)
		V = variance(samp)

		rho = ergm_lag1_autocorr(samp)
		infl_lag1 = (1 :+ rho) :/ (1 :- rho)
		infl_arwy = ergm_spectral0_ar(D)

		for (k=1; k<=p; k++) {
			sd_lag1[s,k] = sqrt(V[k,k] * infl_lag1[k] / samplesize)
			sd_arwy[s,k] = sqrt(V[k,k] * infl_arwy[k] / samplesize)
		}
	}

	printf("\n=== %s (%g seeds) ===\n", label, nseeds)
	for (s=1; s<=nseeds; s++) {
		printf("  seed %g: coef=", s)
		for (k=1; k<=p; k++) printf("%9.5f ", coefs[s,k])
		printf(" lag1sd=")
		for (k=1; k<=p; k++) printf("%8.5f ", sd_lag1[s,k])
		printf(" arwysd=")
		for (k=1; k<=p; k++) printf("%8.5f ", sd_arwy[s,k])
		printf("\n")
	}
	for (k=1; k<=p; k++) {
		printf("param %g: empirical_sd=%8.5f  mean_lag1_sd=%8.5f (ratio %5.2f)  mean_arwy_sd=%8.5f (ratio %5.2f)\n",
			k, sqrt(variance(coefs[.,k])), mean(sd_lag1[.,k]),
			sqrt(variance(coefs[.,k]))/mean(sd_lag1[.,k]),
			mean(sd_arwy[.,k]), sqrt(variance(coefs[.,k]))/mean(sd_arwy[.,k]))
	}
}

// --- Case 1: small, well-mixing 30-node directed edges+mutual (must not regress) ---
void run_case1(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))

	calibration_sweep(M, 30, 0.15, 1, 555, (-2.0, 0.3), 3000, 50, 3000, 15, 6000,
		"30-node directed edges+mutual (small, well-mixing)")
}
run_case1()

// --- Case 2: 100-node undirected GWESP - the harder mixing case ---
void run_case2(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdg

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))

	calibration_sweep(M, 100, 0.05, 0, 777, (-2.0, 0.3), 3000, 50, 3000, 15, 7000,
		"100-node undirected edges+gwesp (harder mixing)")
}
run_case2()

end
