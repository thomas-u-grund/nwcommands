cscript

do unw_ergm.do

/*
	Certifies the native (C) MCMC backend (harmonisation unit 83,
	docs/CERTIFICATION.md) against its own Mata reference implementation,
	per this unit's own explicit "correctness before speed" and "full
	MCMC cross-certification" requirements:

	(1) ErgmNativeSetup() eligibility is exactly what the model's own
	    term list should produce - accept edges/mutual/nodematch/gwesp,
	    reject anything else (nodecov used as the reject probe).
	(2) The native and Mata backends, run on the SAME starting network at
	    the SAME theta with the SAME burnin/interval/samplesize, produce
	    statistically indistinguishable sampled sufficient-statistic
	    distributions - not identical trajectories (the two backends use
	    independent RNG streams by design, see native/ergm_mcmc.c's own
	    header comment), but means that agree within several Monte Carlo
	    standard errors. Covered for both a directed dyad-independent
	    model (edges+mutual+nodematch) and an undirected GWESP model
	    (edges+gwesp), i.e. exactly the two term-family shapes the
	    R-vs-Stata benchmark suite (dev/ergm_benchmark_r_vs_stata/)
	    exercises.
	(3) After a native call, G's own rebuilt state is self-consistent:
	    M.full_statistic(G) recomputed from scratch on the rebuilt graph
	    exactly matches the native run's own last reported statistic row
	    - i.e. the edge list the plugin wrote back is genuinely the same
	    network the reported statistics describe, not just numbers that
	    happen to look plausible.
*/

mata:
mata set matastrict off

// --- (1) eligibility ---
void test_eligibility(){
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3, td4, td5
	real colvector attr

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	M = ErgmModel()
	M.init()
	td2 = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td2, ("edges"))
	td3 = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td3, ("mutual"))
	assert(ErgmNativeSetup(M, 2) == 1)
	assert(M.native_enabled == 1)

	attr = (0\1\0\1\0)
	M = ErgmModel()
	M.init()
	td4 = ErgmTermData()
	td4.attr = attr
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td4, ("gwesp_0.5"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	// nodecov is NOT in the native term set - must be rejected
	M = ErgmModel()
	M.init()
	td5 = ErgmTermData()
	td5.attr = attr
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td5, ("nodecov_age"))
	assert(ErgmNativeSetup(M, 1) == 0)
	assert(M.native_enabled == 0)

	printf("test_eligibility: OK\n")
}
test_eligibility()

// --- shared network builders (deterministic, no RNG - both backends
//     must start from an IDENTICAL graph for the equivalence check to
//     be meaningful) ---
void build_directed(class ErgmGraph G, real scalar n, real scalar deg) {
	real scalar i, e, j
	for (i=1; i<=n; i++) {
		for (e=1; e<=deg; e++) {
			j = mod(i + e*7 + 3, n) + 1
			if (j != i & !G.has_edge(i,j)) G.toggle(i,j)
		}
	}
}
void build_undirected(class ErgmGraph G, real scalar n, real scalar deg) {
	real scalar i, e, j
	for (i=1; i<=n; i++) {
		for (e=1; e<=deg; e++) {
			j = mod(i + e*5 + 2, n) + 1
			if (j != i & !G.has_edge(i,j)) G.toggle(i,j)
		}
	}
}

// --- (2)/(3): statistical equivalence + post-call self-consistency ---
void test_equivalence(string scalar label, real scalar n, real scalar deg,
		real scalar directed, class ErgmModel scalar M, real rowvector theta,
		real scalar burnin, real scalar interval, real scalar samplesize,
		real scalar tol_sd_mult){

	class ErgmGraph scalar Gmata, Gnative
	real matrix samp_mata, samp_native
	real rowvector mean_mata, mean_native, sd_mata, sd_native, se, obs
	real scalar k, p, ok, checkstat

	Gmata = ErgmGraph()
	Gmata.init(n, directed)
	Gnative = ErgmGraph()
	Gnative.init(n, directed)
	if (directed) {
		build_directed(Gmata, n, deg)
		build_directed(Gnative, n, deg)
	}
	else {
		build_undirected(Gmata, n, deg)
		build_undirected(Gnative, n, deg)
	}

	M.native_enabled = 0
	samp_mata = ErgmMCMCSample(M, Gmata, theta, burnin, interval, samplesize, &ergm_propose_tnt())

	assert(ErgmNativeSetup(M, 2) == 1)
	samp_native = ErgmMCMCSample(M, Gnative, theta, burnin, interval, samplesize, &ergm_propose_tnt())
	M.native_enabled = 0

	// MCMC draws are autocorrelated (thinned by `interval', not fully
	// decorrelated) - a naive sd/sqrt(samplesize) badly UNDERSTATES the
	// true Monte Carlo error of the mean here, exactly the same
	// consideration ErgmMCMLE()'s own final variance step already
	// accounts for via ergm_lag1_autocorr()/the "(1+rho)/(1-rho)"
	// inflation factor - reused here rather than inventing a new,
	// untested tolerance rule for this test alone.
	real rowvector rho_mata, rho_native, infl_mata, infl_native
	p = cols(theta)
	mean_mata = mean(samp_mata)
	mean_native = mean(samp_native)
	sd_mata = sqrt(diagonal(variance(samp_mata)))'
	sd_native = sqrt(diagonal(variance(samp_native)))'
	rho_mata = ergm_lag1_autocorr(samp_mata)
	rho_native = ergm_lag1_autocorr(samp_native)
	infl_mata = (1 :+ rho_mata) :/ (1 :- rho_mata)
	infl_native = (1 :+ rho_native) :/ (1 :- rho_native)
	se = sqrt((sd_mata:^2 :* infl_mata + sd_native:^2 :* infl_native) :/ samplesize)

	printf("%s: mata_mean=", label)
	for (k=1; k<=p; k++) printf("%9.4f ", mean_mata[k])
	printf(" native_mean=")
	for (k=1; k<=p; k++) printf("%9.4f ", mean_native[k])
	printf(" se=")
	for (k=1; k<=p; k++) printf("%7.4f ", se[k])
	printf("\n")

	for (k=1; k<=p; k++) {
		assert(abs(mean_mata[k] - mean_native[k]) < tol_sd_mult * se[k])
	}

	// self-consistency: rebuilt Gnative's own from-scratch statistic
	// must exactly match the native run's own last reported row
	obs = M.full_statistic(Gnative)
	checkstat = max(abs(obs - samp_native[samplesize, .]))
	assert(checkstat < 1e-6)

	printf("%s: OK (self-consistency max diff = %9.2e)\n", label, checkstat)
}

// --- directed: edges + mutual + nodematch ---
void run_directed_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdn
	real colvector attr
	real scalar n, i

	n = 80
	attr = J(n, 1, 0)
	for (i=1; i<=n; i++) attr[i] = mod(i, 2)

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdn = ErgmTermData()
	tdn.attr = attr
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), tdn, ("nodematch_x"))

	test_equivalence("directed edges+mutual+nodematch", n, 4, 1, M,
		(-2.2, 0.4, 0.3), 2000, 5, 2000, 6)
}
run_directed_test()

// --- undirected: edges + gwesp ---
void run_gwesp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdg
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))

	test_equivalence("undirected edges+gwesp", n, 4, 0, M,
		(-2.0, 0.3), 2000, 5, 2000, 6)
}
run_gwesp_test()

end
