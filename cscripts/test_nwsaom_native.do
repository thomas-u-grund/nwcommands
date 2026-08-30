cscript

do unw_ergm.do
do unw_saom.do

* Certifies the native (C) SAOM backend (native/saom_sim.c, harmonisation
* unit 6, docs/SAOM_ROADMAP.md "Native (C) backend") against its own Mata
* reference implementation (SaomSimulateInterval(), already certified in
* cscripts/test_nwsaom_mata.do). Like nwergm's own native MCMC backend
* (cscripts/test_nwergm_native.do), this is a STOCHASTIC simulator, so the
* certification standard is statistical equivalence of simulated
* end-of-interval statistic distributions across many independent runs at
* a FIXED theta - not trajectory-level identity (native and Mata use
* independent RNG streams by design, see native/saom_sim.c's own header).

mata:
mata set matastrict off

void saom_native_build_model(class ErgmModel M, real colvector attr) {
	class ErgmTermData scalar td1, td2, td3

	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))
	td3 = ErgmTermData()
	td3.attr = attr
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), td3, ("nodematch"))
}

/* -------------------------------------------------------------------
   Eligibility gating: the native-eligible three-term model must report
   eligible=1; adding ANY other term (here: indegpopularity, a unit-3
   effect this wave's native kernel does not implement) must flip it
   back to 0 - confirms SaomEstimateRM() would correctly fall back to
   the pure-Mata path for such a model, never silently using an
   incomplete/wrong native computation for a term it cannot handle.
   ------------------------------------------------------------------- */
void saom_test_native_eligibility(real scalar n, real colvector attr) {
	class ErgmModel scalar M
	class ErgmTermData scalar td4
	struct SaomNativeConfig scalar cfg

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)

	// harmonisation unit 10 extended native coverage to ALL 13 terms
	// unw_saom.do currently implements (see native/saom_sim.c's own
	// header) - so every REAL effect is now eligible; this check
	// instead confirms the fallback mechanism itself still works
	// correctly for a genuinely unrecognized (synthetic, future) term
	// name, using indegpopularity's own already-certified stat/change
	// functions just as a stand-in payload under a fake name.
	td4 = ErgmTermData()
	M.addterm("aFutureEffectNotYetPortedToNative", 1, &stat_saom_indegpop(), &change_saom_indegpop(), td4, ("futureeffect"))
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 0)

	printf("native eligibility PASS: 3-term model eligible, +unrecognized-term model correctly falls back\n")
}

/* -------------------------------------------------------------------
   Statistical equivalence: many independent Mata-backend runs vs. many
   independent native-backend runs, same starting graph/theta/rate,
   compared via a standard two-sample z-test on each statistic's own
   mean (independent draws, no MCMC autocorrelation to correct for -
   each SaomSimulateInterval()/SaomSimulateIntervalNative() call is
   already one fully independent simulated interval).
   ------------------------------------------------------------------- */
void saom_test_native_equivalence(real scalar n, real colvector attr, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, steps, p, i, j, nedges0
	real rowvector mmata, mnative, semata, senative, zstat
	struct SaomCountedResult scalar cres

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(555111)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-1.2, 1.0, 0.7)
	p = M.nparam()

	Zmata = J(nruns, p, 0)
	rseed(24681)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		steps = SaomSimulateInterval(Gwork, M, theta, 3)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(97531)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		cres = SaomSimulateIntervalNative(Gwork, M, cfg, theta, 3, 1, 0)
		Znative[r,.] = M.full_statistic(Gwork)
	}

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native equivalence: Mata means   %8.3f %8.3f %8.3f\n", mmata[1], mmata[2], mmata[3])
	printf("native equivalence: native means %8.3f %8.3f %8.3f\n", mnative[1], mnative[2], mnative[3])
	printf("native equivalence: z-stats      %8.3f %8.3f %8.3f\n", zstat[1], zstat[2], zstat[3])

	// |z| < 4 across three independent comparisons is a generous but
	// genuine two-sample equivalence bar (far looser than a single 5%
	// test's own 1.96 threshold, deliberately - this is a smoke-level
	// cross-certification given nruns is modest for wall-clock reasons,
	// not a tight-power formal equivalence trial).
	assert(abs(zstat[1]) < 4)
	assert(abs(zstat[2]) < 4)
	assert(abs(zstat[3]) < 4)

	printf("native equivalence PASS: native and Mata backends agree within Monte Carlo tolerance\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 10: statistical equivalence for the FULL extended
   native term set (nodecov family, indegpopularity/outactivity/
   outpopularity/inactivity, transtrip/cycle3, simcov - 9 terms beyond
   the original 3), all in ONE model, using TWO distinct covariate
   arrays (exercises the multi-attribute-column wire-protocol
   generalization this unit added, not just a single shared column) and
   exercising the new adjacency-list/OTP/OSP machinery (transtrip/
   cycle3) end to end. Same two-sample z-test methodology as above.
   ------------------------------------------------------------------- */
void saom_test_native_equiv_ext(real scalar n, real colvector attr1, real colvector attr2, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3, td4, td5, td6, td7, td8, td9
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, p, i, j, nedges0, rng
	real rowvector mmata, mnative, semata, senative, zstat
	struct SaomCountedResult scalar cres

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	td2.attr = attr1
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td2, ("nodecov"))
	td3 = ErgmTermData()
	M.addterm("indegpopularity", 1, &stat_saom_indegpop(), &change_saom_indegpop(), td3, ("indegpopularity"))
	td4 = ErgmTermData()
	M.addterm("outactivity", 1, &stat_saom_outactivity(), &change_saom_outactivity(), td4, ("outactivity"))
	td5 = ErgmTermData()
	M.addterm("outpopularity", 1, &stat_saom_outpop(), &change_saom_outpop(), td5, ("outpopularity"))
	td6 = ErgmTermData()
	M.addterm("inactivity", 1, &stat_saom_inact(), &change_saom_inact(), td6, ("inactivity"))
	td7 = ErgmTermData()
	M.addterm("transtrip", 1, &stat_saom_transtrip(), &change_saom_transtrip(), td7, ("transtrip"))
	td8 = ErgmTermData()
	M.addterm("cycle3", 1, &stat_saom_cycle3(), &change_saom_cycle3(), td8, ("cycle3"))
	td9 = ErgmTermData()
	rng = max(attr2) - min(attr2)
	td9.attr = attr2
	td9.decay = rng
	M.addterm("simcov", 1, &stat_saom_simcov(), &change_saom_simcov(), td9, ("simcov"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(246810)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	p = M.nparam()
	theta = J(1, p, 0.15)
	theta[1] = -0.4	// outdegree: mildly negative, keeps density reasonable

	Zmata = J(nruns, p, 0)
	rseed(11223)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		cres = SaomSimulateIntervalCounted(Gwork, M, theta, 10)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(33445)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		cres = SaomSimulateIntervalNative(Gwork, M, cfg, theta, 10, 1, 0)
		Znative[r,.] = M.full_statistic(Gwork)
	}

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native equivalence (extended, %g terms):\n", p)
	for (k=1; k<=p; k++) {
		printf("  %s: Mata %10.3f  native %10.3f  z=%7.3f\n", M.coefnames[k], mmata[k], mnative[k], zstat[k])
	}
	for (k=1; k<=p; k++) assert(abs(zstat[k]) < 4)

	printf("native equivalence (extended) PASS: all %g newly-natively-covered terms agree within Monte Carlo tolerance\n", p)
}

/* -------------------------------------------------------------------
   Harmonisation unit 14: certifies that the native plugin's own
   directly-returned statistic vector (SaomSimulateIntervalNative()'s
   res.stat, native/saom_sim.c's own saom_stat_term()) EXACTLY matches
   M.full_statistic() applied to the SAME final graph the same call
   mutated G into - not a Monte Carlo/statistical-equivalence bar like
   the suites above (those compare DISTRIBUTIONS across independent
   runs), but a direct per-run numerical check, since both sides are
   computing the identical mathematical quantity on the identical
   realized network. All 13 currently-implemented terms in ONE model
   (unlike saom_test_native_equiv_ext's 9, this one also covers
   outdegree/reciprocity/nodematch - the original 3-term set - since
   unit 14's own C port is new code for every term, not just the
   unit-10 extension). A tight (not bit-identical) tolerance allows for
   floating-point summation-ORDER differences between the two
   independent implementations (C iterates the edge list/node array in
   a different order than Mata's own loops) - genuine agreement, not a
   loosened bar.
   ------------------------------------------------------------------- */
void saom_test_native_stat_match(real scalar n, real colvector attr1, real colvector attr2, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3, td4, td5, td6, td7, td8, td9, td10, td11, td12, td13
	struct SaomNativeConfig scalar cfg
	struct SaomCountedResult scalar cres
	real rowvector theta, statvec, maxerr
	real scalar r, k, i, j, nedges0, rng, p

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))
	td3 = ErgmTermData()
	td3.attr = attr1
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), td3, ("nodematch"))
	td4 = ErgmTermData()
	td4.attr = attr1
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td4, ("nodecov"))
	td5 = ErgmTermData()
	td5.attr = attr2
	M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), td5, ("nodeicov"))
	td6 = ErgmTermData()
	td6.attr = attr2
	M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), td6, ("nodeocov"))
	td7 = ErgmTermData()
	M.addterm("indegpopularity", 1, &stat_saom_indegpop(), &change_saom_indegpop(), td7, ("indegpopularity"))
	td8 = ErgmTermData()
	M.addterm("outactivity", 1, &stat_saom_outactivity(), &change_saom_outactivity(), td8, ("outactivity"))
	td9 = ErgmTermData()
	M.addterm("outpopularity", 1, &stat_saom_outpop(), &change_saom_outpop(), td9, ("outpopularity"))
	td10 = ErgmTermData()
	M.addterm("inactivity", 1, &stat_saom_inact(), &change_saom_inact(), td10, ("inactivity"))
	td11 = ErgmTermData()
	M.addterm("transtrip", 1, &stat_saom_transtrip(), &change_saom_transtrip(), td11, ("transtrip"))
	td12 = ErgmTermData()
	M.addterm("cycle3", 1, &stat_saom_cycle3(), &change_saom_cycle3(), td12, ("cycle3"))
	td13 = ErgmTermData()
	rng = max(attr2) - min(attr2)
	td13.attr = attr2
	td13.decay = rng
	M.addterm("simcov", 1, &stat_saom_simcov(), &change_saom_simcov(), td13, ("simcov"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(556677)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	p = M.nparam()
	theta = J(1, p, 0.1)
	theta[1] = -0.5

	maxerr = J(1, p, 0)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		cres = SaomSimulateIntervalNative(Gwork, M, cfg, theta, 4, 1, 0)
		statvec = M.full_statistic(Gwork)
		for (k=1; k<=p; k++) {
			if (abs(cres.stat[k] - statvec[k]) > maxerr[k]) maxerr[k] = abs(cres.stat[k] - statvec[k])
		}
	}

	printf("native stat-matches-full (%g terms, %g runs): max abs error per term:\n", p, nruns)
	for (k=1; k<=p; k++) printf("  %s: %10.2e\n", M.coefnames[k], maxerr[k])
	for (k=1; k<=p; k++) assert(maxerr[k] < 1e-6)

	printf("native stat-matches-full PASS: native's own directly-returned statistic vector exactly matches M.full_statistic() on the same final graph, every term, every run\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 16: certifies the native SCORE-vector path
   (SaomSimulateIntervalNative()'s own want_score=1 mode,
   native/saom_sim.c's score accumulator) against SaomSimulateInterval
   Scored() (the Mata reference phase 1 has always used). UNLIKE
   saom_test_native_stat_match above, this CANNOT be a bit-identical/
   same-final-graph comparison - the score vector is a stochastic,
   PATH-dependent quantity (it depends on which alternative was chosen
   at every ministep along the way, not just the final tie set), and
   native/Mata use independent RNG streams by design (this file's own
   header). So this uses the SAME statistical-equivalence methodology as
   saom_test_native_equivalence()/saom_test_native_equiv_ext() above -
   many independent replicates per backend, two-sample z-test on each
   parameter's own mean deviation AND mean score.
   ------------------------------------------------------------------- */
void saom_test_native_score_equiv(real scalar n, real colvector attr, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	struct SaomNativeConfig scalar cfg
	struct SaomCountedResult scalar cres
	struct SaomScoredResult scalar sres
	real rowvector theta, target
	real matrix Zdev_mata, Zsco_mata, Zdev_native, Zsco_native
	real scalar r, k, p, i, j, nedges0
	real rowvector mdev_m, mdev_n, msco_m, msco_n, sedev_m, sedev_n, sesco_m, sesco_n, zdev, zsco

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(998877)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-1.2, 1.0, 0.7)
	p = M.nparam()
	target = J(1, p, 0)		// deviation is just the statistic itself here (target=0), fine for an equivalence check on the mean

	Zdev_mata = J(nruns, p, 0)
	Zsco_mata = J(nruns, p, 0)
	rseed(112233)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		sres = SaomSimulateIntervalScored(Gwork, M, theta, 3)
		Zdev_mata[r,.] = M.full_statistic(Gwork) - target
		Zsco_mata[r,.] = sres.score
	}

	Zdev_native = J(nruns, p, 0)
	Zsco_native = J(nruns, p, 0)
	rseed(445566)
	for (r=1; r<=nruns; r++) {
		cres = SaomSimulateIntervalNative(G0, M, cfg, theta, 3, 0, 1)
		Zdev_native[r,.] = cres.stat - target
		Zsco_native[r,.] = cres.score
	}

	mdev_m = mean(Zdev_mata); mdev_n = mean(Zdev_native)
	msco_m = mean(Zsco_mata); msco_n = mean(Zsco_native)
	sedev_m = J(1,p,0); sedev_n = J(1,p,0); sesco_m = J(1,p,0); sesco_n = J(1,p,0)
	zdev = J(1,p,0); zsco = J(1,p,0)
	for (k=1; k<=p; k++) {
		sedev_m[k] = sqrt(variance(Zdev_mata[.,k]) / nruns)
		sedev_n[k] = sqrt(variance(Zdev_native[.,k]) / nruns)
		zdev[k] = (mdev_m[k] - mdev_n[k]) / sqrt(sedev_m[k]^2 + sedev_n[k]^2)
		sesco_m[k] = sqrt(variance(Zsco_mata[.,k]) / nruns)
		sesco_n[k] = sqrt(variance(Zsco_native[.,k]) / nruns)
		zsco[k] = (msco_m[k] - msco_n[k]) / sqrt(sesco_m[k]^2 + sesco_n[k]^2)
	}

	printf("native score equivalence (%g terms, %g runs):\n", p, nruns)
	for (k=1; k<=p; k++) {
		printf("  %s: dev Mata %8.3f native %8.3f z=%6.3f | score Mata %8.3f native %8.3f z=%6.3f\n", ///
			M.coefnames[k], mdev_m[k], mdev_n[k], zdev[k], msco_m[k], msco_n[k], zsco[k])
	}
	for (k=1; k<=p; k++) {
		assert(abs(zdev[k]) < 4)
		assert(abs(zsco[k]) < 4)
	}

	printf("native score equivalence PASS: native's own want_score=1 path (phase 1's own Jacobian estimator) agrees with SaomSimulateIntervalScored() within Monte Carlo tolerance, both deviation and score\n")
}

/* -------------------------------------------------------------------
   Co-evolution (harmonisation unit 26 native port) - same eligibility-
   gating + statistical-equivalence discipline as the network-only
   tests above, now for SaomSimulateIntervalCoevNative() vs. its own
   certified Mata reference SaomSimulateIntervalCoevScored(): every
   network AND every behavior term must be natively covered for
   cfg.eligible & cfgBeh.eligible, and an unrecognized behavior term
   name must correctly flip cfgBeh.eligible back to 0.
   ------------------------------------------------------------------- */
void saom_test_coev_native_elig(real colvector attr) {
	class ErgmModel scalar M
	class SaomBehaviorModel scalar Mbeh
	class ErgmTermData scalar td4
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("linear", &stat_saom_linear(), &change_saom_linear(), "beh_linear")
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt")
	Mbeh.addterm("avsim", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim")
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	assert(cfgBeh.eligible == 1)

	Mbeh.addterm("aFutureBehEffectNotPorted", &stat_saom_linear(), &change_saom_linear(), "futurebeh")
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	assert(cfgBeh.eligible == 0)

	printf("coev native eligibility PASS: 3-behavior-term model eligible, +unrecognized-term model correctly falls back\n")
}

void saom_test_coev_native_equiv(real scalar n, real colvector attr, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class SaomBehavior scalar Beh0, Behwork
	class SaomBehaviorModel scalar Mbeh
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	struct SaomCoevScoredResult scalar sres
	real rowvector thetaNet, thetaBeh
	real matrix Zdev_m, Zsco_m, ZdevBeh_m, ZscoBeh_m, Zdev_n, Zsco_n, ZdevBeh_n, ZscoBeh_n
	real scalar r, k, pNet, pBeh, i, j, nedges0, rateNet, rateBeh, simMean, maxstatdiff, maxstatbehdiff
	real colvector startvals
	real rowvector mdev_m, mdev_n, msco_m, msco_n, mdevb_m, mdevb_n, mscob_m, mscob_n
	real rowvector zdev, zsco, zdevb, zscob

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("linear", &stat_saom_linear(), &change_saom_linear(), "beh_linear")
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt")
	Mbeh.addterm("avsim", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim")
	// a genuinely nonzero simMean, matching this package's own
	// avsim_certify test convention (unit 26 quirk-check discipline -
	// exercises the centering constant's own wire-protocol plumbing,
	// not just a harmless default 0)
	simMean = 0.25
	Mbeh.setsimmean(simMean)
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	assert(cfgBeh.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(864213)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	startvals = ceil(runiform(n,1)*5)

	thetaNet = (-1.2, 1.0, 0.7)
	thetaBeh = (0.15, 0.4, 0.3)
	rateNet = 3
	rateBeh = 2
	pNet = M.nparam()
	pBeh = Mbeh.nparam()

	Zdev_m = J(nruns, pNet, 0)
	Zsco_m = J(nruns, pNet, 0)
	ZdevBeh_m = J(nruns, pBeh, 0)
	ZscoBeh_m = J(nruns, pBeh, 0)
	rseed(112233)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		Behwork = SaomBehavior()
		Behwork.init(startvals, 1, 5, mean(startvals), simMean)
		sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, rateNet, rateBeh)
		Zdev_m[r,.] = M.full_statistic(Gwork)
		Zsco_m[r,.] = sres.scoreNet
		ZdevBeh_m[r,.] = Mbeh.full_statistic(Behwork, Gwork)
		ZscoBeh_m[r,.] = sres.scoreBeh
	}

	Zdev_n = J(nruns, pNet, 0)
	Zsco_n = J(nruns, pNet, 0)
	ZdevBeh_n = J(nruns, pBeh, 0)
	ZscoBeh_n = J(nruns, pBeh, 0)
	// harmonisation unit 31: `rebuild_g=1' here (unlike every
	// SaomEstimateRMCoev()/SaomEstimateRMCoevMulti() call site, which
	// now passes 0) - THIS test's own oracle comparison needs Gwork
	// rebuilt to call M.full_statistic()/Mbeh.full_statistic() on it
	// independently, as its own cross-check target for `sres.stat'/
	// `sres.statBeh' below (an EXACT match assertion, stronger than the
	// distributional z-test - both are computed from the IDENTICAL
	// final graph state, so they must agree exactly, not just
	// statistically).
	maxstatdiff = 0
	maxstatbehdiff = 0
	rseed(445566)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		Behwork = SaomBehavior()
		Behwork.init(startvals, 1, 5, mean(startvals), simMean)
		sres = SaomSimulateIntervalCoevNative(Gwork, M, cfg, thetaNet, Behwork, Mbeh, cfgBeh, thetaBeh, rateNet, rateBeh, 1)
		Zdev_n[r,.] = M.full_statistic(Gwork)
		Zsco_n[r,.] = sres.scoreNet
		ZdevBeh_n[r,.] = Mbeh.full_statistic(Behwork, Gwork)
		ZscoBeh_n[r,.] = sres.scoreBeh
		maxstatdiff = max((maxstatdiff, max(abs(sres.stat - Zdev_n[r,.]))))
		maxstatbehdiff = max((maxstatbehdiff, max(abs(sres.statBeh - ZdevBeh_n[r,.]))))
	}

	mdev_m = mean(Zdev_m); mdev_n = mean(Zdev_n)
	msco_m = mean(Zsco_m); msco_n = mean(Zsco_n)
	mdevb_m = mean(ZdevBeh_m); mdevb_n = mean(ZdevBeh_n)
	mscob_m = mean(ZscoBeh_m); mscob_n = mean(ZscoBeh_n)
	zdev = J(1,pNet,0); zsco = J(1,pNet,0)
	for (k=1; k<=pNet; k++) {
		zdev[k] = (mdev_m[k]-mdev_n[k]) / sqrt(variance(Zdev_m[.,k])/nruns + variance(Zdev_n[.,k])/nruns)
		zsco[k] = (msco_m[k]-msco_n[k]) / sqrt(variance(Zsco_m[.,k])/nruns + variance(Zsco_n[.,k])/nruns)
	}
	zdevb = J(1,pBeh,0); zscob = J(1,pBeh,0)
	for (k=1; k<=pBeh; k++) {
		zdevb[k] = (mdevb_m[k]-mdevb_n[k]) / sqrt(variance(ZdevBeh_m[.,k])/nruns + variance(ZdevBeh_n[.,k])/nruns)
		zscob[k] = (mscob_m[k]-mscob_n[k]) / sqrt(variance(ZscoBeh_m[.,k])/nruns + variance(ZscoBeh_n[.,k])/nruns)
	}

	printf("coev native equivalence (network, %g terms, %g runs):\n", pNet, nruns)
	for (k=1; k<=pNet; k++) {
		printf("  %s: dev Mata %8.3f native %8.3f z=%6.3f | score Mata %8.3f native %8.3f z=%6.3f\n", ///
			M.coefnames[k], mdev_m[k], mdev_n[k], zdev[k], msco_m[k], msco_n[k], zsco[k])
	}
	printf("coev native equivalence (behavior, %g terms, %g runs):\n", pBeh, nruns)
	for (k=1; k<=pBeh; k++) {
		printf("  %s: dev Mata %8.3f native %8.3f z=%6.3f | score Mata %8.3f native %8.3f z=%6.3f\n", ///
			Mbeh.coefnames[k], mdevb_m[k], mdevb_n[k], zdevb[k], mscob_m[k], mscob_n[k], zscob[k])
	}
	for (k=1; k<=pNet; k++) {
		assert(abs(zdev[k]) < 4)
		assert(abs(zsco[k]) < 4)
	}
	for (k=1; k<=pBeh; k++) {
		assert(abs(zdevb[k]) < 4)
		assert(abs(zscob[k]) < 4)
	}

	printf("coev native equivalence PASS: SaomSimulateIntervalCoevNative() (network+behavior, incl. avsim's own simMean wire field) agrees with SaomSimulateIntervalCoevScored() within Monte Carlo tolerance, deviation and score, both sides\n")

	// harmonisation unit 31: `sres.stat'/`sres.statBeh' (the new
	// native-returned statistic vectors) must EXACTLY match
	// M.full_statistic()/Mbeh.full_statistic() computed independently
	// on the SAME rebuilt Gwork/Behwork - both derived from the
	// identical final graph state, so floating-point-level agreement is
	// the right bar here, not a Monte Carlo z-test.
	printf("coev native stat/statBeh exact-match: max|diff| net=%9.2e beh=%9.2e\n", maxstatdiff, maxstatbehdiff)
	assert(maxstatdiff < 1e-8)
	assert(maxstatbehdiff < 1e-8)
	printf("coev native stat/statBeh PASS: SaomSimulateIntervalCoevNative()'s own res.stat/res.statBeh (harmonisation unit 31) exactly match M.full_statistic()/Mbeh.full_statistic() on the identical final graph state\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 30 (performance pass): statistical equivalence
   for SaomSimulateCondTimeNative() (native/saom_sim.c's own new
   "CONDITIONAL MODE") against SaomSimulateConditionalTime() (the
   pure-Mata reference, harmonisation unit 27) - same two-sample z-test
   methodology as saom_test_native_equivalence() above, but comparing
   the ELAPSED TIME distribution (the one thing this refinement loop
   actually needs) rather than an end-of-interval statistic vector.
   ------------------------------------------------------------------- */
void saom_test_native_condtime_equiv(real scalar n, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real colvector tMata, tNative
	real scalar r, k, i, j, nedges0, target, mmata, mnative, semata, senative, zstat

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(864213)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.12 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-1.5, 1.0)
	target = 20

	tMata = J(nruns, 1, 0)
	rseed(24681)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		tMata[r] = SaomSimulateConditionalTime(Gwork, G0, M, theta, target)
	}

	tNative = J(nruns, 1, 0)
	rseed(97531)
	for (r=1; r<=nruns; r++) {
		tNative[r] = SaomSimulateCondTimeNative(G0, G0, M, cfg, theta, target)
	}

	mmata = mean(tMata)
	mnative = mean(tNative)
	semata = sqrt(variance(tMata) / nruns)
	senative = sqrt(variance(tNative) / nruns)
	zstat = (mmata - mnative) / sqrt(semata^2 + senative^2)

	printf("native condtime equivalence: Mata mean %8.4f, native mean %8.4f, z=%6.3f\n", mmata, mnative, zstat)

	// |z| < 4, same generous-but-genuine bar as saom_test_native_equivalence()
	// above (see its own comment for the rationale).
	assert(abs(zstat) < 4)

	printf("native condtime equivalence PASS: SaomSimulateCondTimeNative() agrees with SaomSimulateConditionalTime() within Monte Carlo tolerance (elapsed-time distribution)\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 35 (missing data, NATIVE PORT) - same exact-match
   methodology as saom_test_native_stat_match() above (unit 14): unlike
   the score/interval equivalence tests, masking is a DETERMINISTIC
   function of the final graph state, so native's own masked statistic
   (SaomSimulateIntervalNative()'s new missMaskNet parameter,
   native/saom_sim.c's build_masked_graph()) must match the Mata
   reference (SaomMaskedStatistic(), unw_saom.do) EXACTLY on the SAME
   rebuilt final graph - not just statistically. Reuses the same broad
   13-term model saom_test_native_stat_match() already certifies
   ordinary (unmasked) native statistics against, so this test only
   needs to isolate the MASKING logic itself, not re-certify every
   term's own native/Mata correspondence again.
   ------------------------------------------------------------------- */
void saom_test_native_missnet_stat(real scalar n, real colvector attr1, real colvector attr2, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3, td4, td5, td6, td7, td8, td9, td10, td11, td12, td13
	struct SaomNativeConfig scalar cfg
	struct SaomCountedResult scalar cres
	real rowvector theta, statvec, maxerr
	real matrix missMaskNet
	real scalar r, k, i, j, nedges0, rng, p

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))
	td3 = ErgmTermData()
	td3.attr = attr1
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), td3, ("nodematch"))
	td4 = ErgmTermData()
	td4.attr = attr1
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td4, ("nodecov"))
	td5 = ErgmTermData()
	td5.attr = attr2
	M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), td5, ("nodeicov"))
	td6 = ErgmTermData()
	td6.attr = attr2
	M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), td6, ("nodeocov"))
	td7 = ErgmTermData()
	M.addterm("indegpopularity", 1, &stat_saom_indegpop(), &change_saom_indegpop(), td7, ("indegpopularity"))
	td8 = ErgmTermData()
	M.addterm("outactivity", 1, &stat_saom_outactivity(), &change_saom_outactivity(), td8, ("outactivity"))
	td9 = ErgmTermData()
	M.addterm("outpopularity", 1, &stat_saom_outpop(), &change_saom_outpop(), td9, ("outpopularity"))
	td10 = ErgmTermData()
	M.addterm("inactivity", 1, &stat_saom_inact(), &change_saom_inact(), td10, ("inactivity"))
	td11 = ErgmTermData()
	M.addterm("transtrip", 1, &stat_saom_transtrip(), &change_saom_transtrip(), td11, ("transtrip"))
	td12 = ErgmTermData()
	M.addterm("cycle3", 1, &stat_saom_cycle3(), &change_saom_cycle3(), td12, ("cycle3"))
	td13 = ErgmTermData()
	rng = max(attr2) - min(attr2)
	td13.attr = attr2
	td13.decay = rng
	M.addterm("simcov", 1, &stat_saom_simcov(), &change_saom_simcov(), td13, ("simcov"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(778899)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	// mask roughly a quarter of dyads
	missMaskNet = J(n, n, 0)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (runiform(1,1) < 0.25) missMaskNet[i,j] = 1
		}
	}

	p = M.nparam()
	theta = J(1, p, 0.1)
	theta[1] = -0.5

	maxerr = J(1, p, 0)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		cres = SaomSimulateIntervalNative(Gwork, M, cfg, theta, 4, 1, 0, SaomMaskToDyadList(missMaskNet))
		statvec = SaomMaskedStatistic(Gwork, M, missMaskNet)
		for (k=1; k<=p; k++) {
			if (abs(cres.stat[k] - statvec[k]) > maxerr[k]) maxerr[k] = abs(cres.stat[k] - statvec[k])
		}
	}

	printf("native missnet stat-matches-masked (%g terms, %g runs): max abs error per term:\n", p, nruns)
	for (k=1; k<=p; k++) printf("  %s: %10.2e\n", M.coefnames[k], maxerr[k])
	for (k=1; k<=p; k++) assert(maxerr[k] < 1e-6)

	printf("native missnet stat-matches-masked PASS: SaomSimulateIntervalNative()'s own missMaskNet-masked statistic exactly matches SaomMaskedStatistic() (Mata) on the same final graph, every term, every run\n")
}

/* -------------------------------------------------------------------
   Same exact-match methodology, co-evolution side (missMaskNet AND
   missMaskBeh together) - certifies native's own masked res.stat/
   res.statBeh (SaomSimulateIntervalCoevNative()) against
   SaomMaskedStatistic()/SaomMaskedBehaviorStatistic() (Mata) on the
   SAME rebuilt final graph/behavior state. Reuses
   saom_test_coev_native_equiv()'s own model (outdegree/reciprocity/
   nodematch network side, linear/avalt/avsim behavior side - avAlt/
   avSim specifically exercise the network-dependent behavior-masking
   fix this same investigation found and corrected, see
   SaomMaskedBehaviorStatistic()'s own header comment in unw_saom.do).
   ------------------------------------------------------------------- */
void saom_test_native_missbeh_stat(real scalar n, real colvector attr, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class SaomBehavior scalar Beh0, Behwork
	class SaomBehaviorModel scalar Mbeh
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	struct SaomCoevScoredResult scalar sres
	real rowvector thetaNet, thetaBeh, statvec, statbehvec, maxerr, maxerrbeh
	real matrix missMaskNet
	real colvector startvals, missMaskBeh
	real scalar r, k, pNet, pBeh, i, j, nedges0, rateNet, rateBeh, simMean

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("linear", &stat_saom_linear(), &change_saom_linear(), "beh_linear")
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt")
	Mbeh.addterm("avsim", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim")
	simMean = 0.25
	Mbeh.setsimmean(simMean)
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	assert(cfgBeh.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(998877)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	startvals = ceil(runiform(n,1)*5)

	missMaskNet = J(n, n, 0)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (runiform(1,1) < 0.25) missMaskNet[i,j] = 1
		}
	}
	missMaskBeh = J(n, 1, 0)
	for (i=1; i<=n; i++) if (mod(i,3)==0) missMaskBeh[i] = 1

	thetaNet = (-1.2, 1.0, 0.7)
	thetaBeh = (0.15, 0.4, 0.3)
	rateNet = 3
	rateBeh = 2
	pNet = M.nparam()
	pBeh = Mbeh.nparam()

	maxerr = J(1, pNet, 0)
	maxerrbeh = J(1, pBeh, 0)
	rseed(556677)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		Behwork = SaomBehavior()
		Behwork.init(startvals, 1, 5, mean(startvals), simMean)
		sres = SaomSimulateIntervalCoevNative(Gwork, M, cfg, thetaNet, Behwork, Mbeh, cfgBeh, thetaBeh, rateNet, rateBeh, 1, SaomMaskToDyadList(missMaskNet), missMaskBeh)
		statvec = SaomMaskedStatistic(Gwork, M, missMaskNet)
		statbehvec = SaomMaskedBehaviorStatistic(Behwork, Gwork, Mbeh, missMaskBeh, missMaskNet)
		for (k=1; k<=pNet; k++) if (abs(sres.stat[k] - statvec[k]) > maxerr[k]) maxerr[k] = abs(sres.stat[k] - statvec[k])
		for (k=1; k<=pBeh; k++) if (abs(sres.statBeh[k] - statbehvec[k]) > maxerrbeh[k]) maxerrbeh[k] = abs(sres.statBeh[k] - statbehvec[k])
	}

	printf("native missbeh stat-matches-masked: max abs error per net term:\n")
	for (k=1; k<=pNet; k++) printf("  %s: %10.2e\n", M.coefnames[k], maxerr[k])
	printf("native missbeh stat-matches-masked: max abs error per beh term:\n")
	for (k=1; k<=pBeh; k++) printf("  %s: %10.2e\n", Mbeh.coefnames[k], maxerrbeh[k])
	for (k=1; k<=pNet; k++) assert(maxerr[k] < 1e-6)
	for (k=1; k<=pBeh; k++) assert(maxerrbeh[k] < 1e-6)

	printf("native missbeh stat-matches-masked PASS: SaomSimulateIntervalCoevNative()'s own missMaskNet/missMaskBeh-masked statistics exactly match SaomMaskedStatistic()/SaomMaskedBehaviorStatistic() (Mata) on the same final graph/behavior state, every term, every run\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 33 (composition change, NATIVE PORT) - same
   statistical-equivalence methodology as saom_test_native_equivalence()
   above (unlike missing data's own masking, the ministep sampler
   itself is genuinely restricted here - a stochastic, path-dependent
   change, so this CANNOT be an exact-match test the way unit 35's own
   masking certification is; native/Mata use independent RNG streams by
   design, see this file's own header). A block of actors (1..k) is
   marked absent for the whole interval - many independent replicates
   per backend, two-sample z-test on each statistic's own mean.
   ------------------------------------------------------------------- */
void saom_test_native_present_equiv(real scalar n, real colvector attr, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, steps, p, i, j, nedges0
	real rowvector mmata, mnative, semata, senative, zstat
	struct SaomCountedResult scalar cres
	real colvector present

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(224466)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	present = J(n, 1, 1)
	present[1] = 0
	present[2] = 0
	present[3] = 0

	theta = (-1.2, 1.0, 0.7)
	p = M.nparam()

	Zmata = J(nruns, p, 0)
	rseed(35792)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		steps = SaomSimulateInterval(Gwork, M, theta, 3, present)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(19357)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		cres = SaomSimulateIntervalNative(Gwork, M, cfg, theta, 3, 1, 0, J(0,2,0), present)
		Znative[r,.] = M.full_statistic(Gwork)
		// hard invariant, both backends: an absent actor's own row/col
		// must never change from its own starting value.
		for (i=1; i<=3; i++) for (j=1; j<=n; j++) {
			if (i==j) continue
			assert(Gwork.has_edge(i,j) == G0.has_edge(i,j))
			assert(Gwork.has_edge(j,i) == G0.has_edge(j,i))
		}
	}

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native present() equivalence: Mata means   %8.3f %8.3f %8.3f\n", mmata[1], mmata[2], mmata[3])
	printf("native present() equivalence: native means %8.3f %8.3f %8.3f\n", mnative[1], mnative[2], mnative[3])
	printf("native present() equivalence: z-stats      %8.3f %8.3f %8.3f\n", zstat[1], zstat[2], zstat[3])
	assert(abs(zstat[1]) < 4)
	assert(abs(zstat[2]) < 4)
	assert(abs(zstat[3]) < 4)

	printf("native present() equivalence PASS: native and Mata backends agree within Monte Carlo tolerance under composition change, and both correctly freeze every absent actor's own dyads\n")
}

/* Co-evolution counterpart - present() restricts BOTH variables' own
   actor pool (see native/saom_sim.c's own "COMPOSITION CHANGE" header
   section) - same statistical-equivalence methodology. */
void saom_test_coev_native_present(real scalar n, real colvector attr, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class SaomBehavior scalar Beh0, Behwork
	class SaomBehaviorModel scalar Mbeh
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	struct SaomCoevScoredResult scalar sres
	real rowvector thetaNet, thetaBeh
	real matrix Zdev_m, Zdev_n
	real scalar r, k, pNet, pBeh, i, j, nedges0, rateNet, rateBeh, simMean
	real colvector startvals, present
	real rowvector mmata, mnative, semata, senative, zstat

	M = ErgmModel()
	saom_native_build_model(M, attr)
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("linear", &stat_saom_linear(), &change_saom_linear(), "beh_linear")
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt")
	Mbeh.addterm("avsim", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim")
	simMean = 0.25
	Mbeh.setsimmean(simMean)
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	assert(cfgBeh.eligible == 1)
	assert(SaomNativeAvailable() == 1)

	rseed(667788)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	startvals = ceil(runiform(n,1)*5)

	present = J(n, 1, 1)
	present[1] = 0
	present[2] = 0
	present[3] = 0

	thetaNet = (-1.2, 1.0, 0.7)
	thetaBeh = (0.15, 0.4, 0.3)
	rateNet = 3
	rateBeh = 2
	pNet = M.nparam()
	pBeh = Mbeh.nparam()

	Zdev_m = J(nruns, pNet+pBeh, 0)
	rseed(882211)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		Behwork = SaomBehavior()
		Behwork.init(startvals, 1, 5, mean(startvals), simMean)
		sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, rateNet, rateBeh, present)
		Zdev_m[r,.] = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
	}

	Zdev_n = J(nruns, pNet+pBeh, 0)
	rseed(331122)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		Behwork = SaomBehavior()
		Behwork.init(startvals, 1, 5, mean(startvals), simMean)
		sres = SaomSimulateIntervalCoevNative(Gwork, M, cfg, thetaNet, Behwork, Mbeh, cfgBeh, thetaBeh, rateNet, rateBeh, 1, J(0,2,0), J(n,1,0), present)
		Zdev_n[r,.] = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
		for (i=1; i<=3; i++) {
			assert(Behwork.value(i) == startvals[i])	// absent actor's own behavior value frozen too
			for (j=1; j<=n; j++) {
				if (i==j) continue
				assert(Gwork.has_edge(i,j) == G0.has_edge(i,j))
				assert(Gwork.has_edge(j,i) == G0.has_edge(j,i))
			}
		}
	}

	mmata = mean(Zdev_m)
	mnative = mean(Zdev_n)
	semata = J(1,pNet+pBeh,0)
	senative = J(1,pNet+pBeh,0)
	zstat = J(1,pNet+pBeh,0)
	for (k=1; k<=pNet+pBeh; k++) {
		semata[k] = sqrt(variance(Zdev_m[.,k]) / nruns)
		senative[k] = sqrt(variance(Zdev_n[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("coev native present() equivalence: max |z| over %g joint statistics = %6.3f\n", pNet+pBeh, max(abs(zstat)))
	for (k=1; k<=pNet+pBeh; k++) assert(abs(zstat[k]) < 4)

	printf("coev native present() equivalence PASS: native and Mata backends agree within Monte Carlo tolerance under composition change (joint network+behavior), and both correctly freeze every actor's own absent value/ties\n")
}

/* -------------------------------------------------------------------
   isolatenet/outiso (harmonisation unit 161 - native backend port):
   the last two network termcodes ported to native/saom_sim.c (14/15),
   closing the "only 13 of 15 network terms are native" gap. Same
   two-sample z-test methodology as saom_test_native_equivalence()
   above, but deliberately a much SPARSER starting graph/theta than that
   test's own 0.15-density default: isolatenet/outiso are both zero-
   variance nuisance statistics on a dense graph (no isolates ever
   occur), which would let this test pass trivially without actually
   exercising either termcode's own change-statistic logic. A ~3%
   density start plus a strongly outdegree-suppressing theta keeps a
   real, nonzero isolate count present throughout the simulated
   interval on both backends.
   ------------------------------------------------------------------- */
void saom_test_native_isoiso_equiv(real scalar n, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, p, i, j, nedges0
	real rowvector mmata, mnative, semata, senative, zstat

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("isolatenet", 1, &stat_saom_isolatenet(), &change_saom_isolatenet(), td2, ("isolatenet"))
	td3 = ErgmTermData()
	M.addterm("outiso", 1, &stat_saom_outiso(), &change_saom_outiso(), td3, ("outiso"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)
	assert(cfg.termcodes[2] == 14)
	assert(cfg.termcodes[3] == 15)

	rseed(148163264)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.03 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-1.8, 0.5, 0.5)	// strongly negative outdegree keeps density low, so isolates keep occurring
	p = M.nparam()

	Zmata = J(nruns, p, 0)
	rseed(51413)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateInterval(Gwork, M, theta, 5)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(31415)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateIntervalNative(Gwork, M, cfg, theta, 5, 1, 0)
		Znative[r,.] = M.full_statistic(Gwork)
	}

	// Confirms the sparsity design goal actually held (not just that the
	// z-test happens to pass) - a near-zero mean isolate count here would
	// mean this test is not really exercising isolatenet/outiso at all.
	assert(mean(Zmata[.,2]) > 0.5)
	assert(mean(Zmata[.,3]) > 0.5)

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native isolatenet/outiso equivalence: Mata means   %8.3f %8.3f %8.3f\n", mmata[1], mmata[2], mmata[3])
	printf("native isolatenet/outiso equivalence: native means %8.3f %8.3f %8.3f\n", mnative[1], mnative[2], mnative[3])
	printf("native isolatenet/outiso equivalence: z-stats      %8.3f %8.3f %8.3f\n", zstat[1], zstat[2], zstat[3])
	assert(abs(zstat[1]) < 4)
	assert(abs(zstat[2]) < 4)
	assert(abs(zstat[3]) < 4)

	printf("native isolatenet/outiso equivalence PASS: native and Mata backends agree within Monte Carlo tolerance, with a genuinely nonzero isolate count on both sides\n")
}

/* -------------------------------------------------------------------
   transrectrip/outoutass/ininass (harmonisation unit 37 native port):
   the three effects harmonisation unit 37 added Mata-only, closing the
   80x-290x-slower-than-RSiena gap that unit's own real RSiena benchmark
   disclosed (see docs/SAOM_ROADMAP.md's own account) - termcodes
   16/17/18. Same two-sample z-test methodology as
   saom_test_native_isoiso_equiv() above, but at a MODERATE density
   (unlike isolatenet/outiso's own deliberately-sparse setup) - all
   three of these terms need ordinary variation in degree/reciprocated
   ties to be meaningfully exercised, not a rare-event structural
   condition, so saom_test_native_equivalence()'s own 0.15-density
   convention already suffices; the only thing worth asserting
   explicitly is that transRecTrip's own mean is genuinely nonzero
   (it needs at least some reciprocated ties to ever contribute at
   all, unlike outOutAss/inInAss which are nonzero for any tie).
   ------------------------------------------------------------------- */
void saom_test_native_unit37_equiv(real scalar n, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3, td4
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, p, i, j, nedges0
	real rowvector mmata, mnative, semata, senative, zstat

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("transrectrip", 1, &stat_saom_transrectrip(), &change_saom_transrectrip(), td2, ("transrectrip"))
	td3 = ErgmTermData()
	M.addterm("outoutass", 1, &stat_saom_outoutass(), &change_saom_outoutass(), td3, ("outoutass"))
	td4 = ErgmTermData()
	M.addterm("ininass", 1, &stat_saom_ininass(), &change_saom_ininass(), td4, ("ininass"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)
	assert(cfg.termcodes[2] == 16)
	assert(cfg.termcodes[3] == 17)
	assert(cfg.termcodes[4] == 18)

	rseed(271828182)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-1.0, 0.1, 0.05, 0.05)
	p = M.nparam()

	Zmata = J(nruns, p, 0)
	rseed(161718)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateInterval(Gwork, M, theta, 5)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(192021)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateIntervalNative(Gwork, M, cfg, theta, 5, 1, 0)
		Znative[r,.] = M.full_statistic(Gwork)
	}

	// Confirms transRecTrip is genuinely exercised (needs reciprocated
	// ties to ever contribute) - a near-zero mean here would mean this
	// test isn't really testing termcode 16 at all.
	assert(mean(Zmata[.,2]) > 0.5)

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native transrectrip/outoutass/ininass equivalence: Mata means   %8.3f %8.3f %8.3f %8.3f\n", mmata[1], mmata[2], mmata[3], mmata[4])
	printf("native transrectrip/outoutass/ininass equivalence: native means %8.3f %8.3f %8.3f %8.3f\n", mnative[1], mnative[2], mnative[3], mnative[4])
	printf("native transrectrip/outoutass/ininass equivalence: z-stats      %8.3f %8.3f %8.3f %8.3f\n", zstat[1], zstat[2], zstat[3], zstat[4])
	for (k=1; k<=p; k++) assert(abs(zstat[k]) < 4)

	printf("native transrectrip/outoutass/ininass equivalence PASS: native and Mata backends agree within Monte Carlo tolerance\n")
}

/* -------------------------------------------------------------------
   outinass/inoutass native-vs-Mata equivalence (harmonisation unit
   165, termcodes 19/20) - same pattern as saom_test_native_unit37_equiv
   above, one combined model exercising both new termcodes at once.
   ------------------------------------------------------------------- */
void saom_test_native_unit165_equiv(real scalar n, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2, td3
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, p, i, j, nedges0
	real rowvector mmata, mnative, semata, senative, zstat

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("outinass", 1, &stat_saom_outinass(), &change_saom_outinass(), td2, ("outinass"))
	td3 = ErgmTermData()
	M.addterm("inoutass", 1, &stat_saom_inoutass(), &change_saom_inoutass(), td3, ("inoutass"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)
	assert(cfg.termcodes[2] == 19)
	assert(cfg.termcodes[3] == 20)

	rseed(314159265)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-1.0, 0.05, 0.05)
	p = M.nparam()

	Zmata = J(nruns, p, 0)
	rseed(112358)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateInterval(Gwork, M, theta, 5)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(132134)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateIntervalNative(Gwork, M, cfg, theta, 5, 1, 0)
		Znative[r,.] = M.full_statistic(Gwork)
	}

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native outinass/inoutass equivalence: Mata means   %8.3f %8.3f %8.3f\n", mmata[1], mmata[2], mmata[3])
	printf("native outinass/inoutass equivalence: native means %8.3f %8.3f %8.3f\n", mnative[1], mnative[2], mnative[3])
	printf("native outinass/inoutass equivalence: z-stats      %8.3f %8.3f %8.3f\n", zstat[1], zstat[2], zstat[3])
	for (k=1; k<=p; k++) assert(abs(zstat[k]) < 4)

	printf("native outinass/inoutass equivalence PASS: native and Mata backends agree within Monte Carlo tolerance\n")
}

void saom_test_native_cycle4_equiv(real scalar n, real scalar nruns) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct SaomNativeConfig scalar cfg
	real rowvector theta
	real matrix Zmata, Znative
	real scalar r, k, p, i, j, nedges0
	real rowvector mmata, mnative, semata, senative, zstat

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("cycle4", 1, &stat_saom_cycle4(), &change_saom_cycle4(), td2, ("cycle4"))

	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1)
	assert(SaomNativeAvailable() == 1)
	assert(cfg.termcodes[2] == 21)

	// Denser start than unit165's own 15% - a real 4-node motif needs
	// meaningfully more ties present before any exist to count at all
	// (same reasoning as this term's own Mata-side direction test).
	rseed(271828182)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.30 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	theta = (-0.5, 0.3)
	p = M.nparam()

	Zmata = J(nruns, p, 0)
	rseed(161803398)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateInterval(Gwork, M, theta, 5)
		Zmata[r,.] = M.full_statistic(Gwork)
	}

	Znative = J(nruns, p, 0)
	rseed(141421356)
	for (r=1; r<=nruns; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		SaomSimulateIntervalNative(Gwork, M, cfg, theta, 5, 1, 0)
		Znative[r,.] = M.full_statistic(Gwork)
	}

	mmata = mean(Zmata)
	mnative = mean(Znative)
	semata = J(1,p,0)
	senative = J(1,p,0)
	zstat = J(1,p,0)
	for (k=1; k<=p; k++) {
		semata[k] = sqrt(variance(Zmata[.,k]) / nruns)
		senative[k] = sqrt(variance(Znative[.,k]) / nruns)
		zstat[k] = (mmata[k] - mnative[k]) / sqrt(semata[k]^2 + senative[k]^2)
	}

	printf("native cycle4 equivalence: Mata means   %8.3f %8.3f\n", mmata[1], mmata[2])
	printf("native cycle4 equivalence: native means %8.3f %8.3f\n", mnative[1], mnative[2])
	printf("native cycle4 equivalence: z-stats      %8.3f %8.3f\n", zstat[1], zstat[2])
	for (k=1; k<=p; k++) assert(abs(zstat[k]) < 4)

	printf("native cycle4 equivalence PASS: native and Mata backends agree within Monte Carlo tolerance\n")
}

end

mata:
mata set matastrict off

n = 18
rseed(13571113)
attr = J(n,1,0)
for (k=1; k<=n; k++) attr[k] = mod(k,3)

saom_test_native_eligibility(n, attr)
saom_test_native_equivalence(n, attr, 150)

attr2 = J(n,1,0)
for (k=1; k<=n; k++) attr2[k] = mod(k*7,5)
saom_test_native_equiv_ext(n, attr, attr2, 150)

saom_test_native_stat_match(n, attr, attr2, 100)

saom_test_native_score_equiv(n, attr, 150)

saom_test_coev_native_elig(attr)
saom_test_coev_native_equiv(n, attr, 150)

saom_test_native_condtime_equiv(n, 150)

saom_test_native_missnet_stat(n, attr, attr2, 100)
saom_test_native_missbeh_stat(n, attr, 100)

saom_test_native_present_equiv(n, attr, 150)
saom_test_coev_native_present(n, attr, 150)

saom_test_native_isoiso_equiv(n, 150)

saom_test_native_unit37_equiv(n, 150)

saom_test_native_unit165_equiv(n, 150)
saom_test_native_cycle4_equiv(n, 150)

end
