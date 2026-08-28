cscript

do unw_ergm.do
do unw_saom.do

* Certifies unw_saom.do's ministep sampler, interval simulator, and
* Robbins-Monro estimator (harmonisation unit 1, docs/SAOM_ROADMAP.md).
* Pure-Mata, self-contained toy networks - same style as
* cscripts/test_nwergm_changestat.do. Certification here is (a)
* structural/boundary checks on the sampler itself, independent of
* estimation, and (b) a self-consistency recovery check: simulate
* synthetic wave-2 data under a KNOWN theta, confirm SaomEstimateRM
* recovers it from the same two waves. A SEPARATE, real cross-check
* against actual RSiena (on RSiena's own s501/s502 tutorial dataset, not
* a self-consistency check) lives in dev/saom_rsiena_crosscheck.R/.do -
* see docs/SAOM_ROADMAP.md's "External validation" entry for the result
* (correct sign/magnitude, ~10-20% low vs RSiena, likely from v1's
* simplified single-phase-2 gain schedule) and why this project's
* earlier "no RSiena was available" claim was wrong (never verified).

mata:
mata set matastrict off

void saom_build_model(class ErgmModel M, real colvector attr) {
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
   Unit 1a: structural/boundary check on the ministep sampler itself -
   independent of Robbins-Monro. A strongly negative outdegree
   coefficient (everything else 0) should drive an empty starting graph
   to stay very sparse; a strongly positive one should densify it
   substantially. This isolates SaomMinistep()/SaomSimulateInterval()
   from any estimator-level noise.
   ------------------------------------------------------------------- */
void saom_test_unit1a(real scalar n, real colvector attr) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	real rowvector theta_lo, theta_hi
	real scalar ties_lo, ties_hi, maxties, steps

	M = ErgmModel()
	saom_build_model(M, attr)
	maxties = n*(n-1)

	// rate chosen so n*rate opportunities is comparable to maxties -
	// otherwise even a maximally tie-favoring theta cannot reach high
	// density within one simulated time unit, regardless of theta (the
	// rate, not theta, would be the binding constraint - not what this
	// check is meant to test).
	G = ErgmGraph()
	G.init(n, 1)
	theta_lo = (-6, 0, 0)
	steps = SaomSimulateInterval(G, M, theta_lo, 15)
	ties_lo = G.nties
	assert(ties_lo / maxties < 0.15)

	G = ErgmGraph()
	G.init(n, 1)
	theta_hi = (6, 0, 0)
	steps = SaomSimulateInterval(G, M, theta_hi, 15)
	ties_hi = G.nties
	assert(ties_hi / maxties > 0.5)

	printf("unit 1a PASS: sparse-theta density %6.3f, dense-theta density %6.3f\n", ties_lo/maxties, ties_hi/maxties)
}

/* -------------------------------------------------------------------
   Unit 1b: reciprocity effect sanity check. At theta=(edges very
   negative, mutual very positive, nodematch 0), simulating from an
   EMPTY graph should produce a network whose ties are overwhelmingly
   reciprocated (mutual dyads), since any lone asymmetric tie is
   strongly penalized relative to completing it - a structural identity
   independent of Robbins-Monro.
   ------------------------------------------------------------------- */
void saom_test_unit1b(real scalar n, real colvector attr) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	real rowvector theta_recip
	real scalar recip_ties, single_ties, i, j, steps

	M = ErgmModel()
	saom_build_model(M, attr)

	G = ErgmGraph()
	G.init(n, 1)
	theta_recip = (-3, 5, 0)
	steps = SaomSimulateInterval(G, M, theta_recip, 15)

	recip_ties = 0
	single_ties = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (G.has_edge(i,j)) {
				if (G.has_edge(j,i)) recip_ties++
				else single_ties++
			}
		}
	}
	printf("unit 1b: reciprocated arc-endpoints %g, single-arc endpoints %g\n", recip_ties, single_ties)
	assert(recip_ties >= single_ties)
}

/* -------------------------------------------------------------------
   Unit 1c: Robbins-Monro recovery check. Simulate a synthetic wave 2
   from a real starting network (a random moderately sparse wave 1)
   under a KNOWN theta, then confirm SaomEstimateRM recovers a theta of
   the same sign and roughly the same order of magnitude from (wave1,
   wave2) alone. Loose tolerances throughout - this is a smoke-level
   statistical certification (stochastic estimator, small toy network,
   modest phase-2/3 iteration counts for runtime), not a tight
   precision check; a real RSiena cross-check remains an open item (see
   docs/SAOM_ROADMAP.md).
   ------------------------------------------------------------------- */
void saom_test_unit1c(real scalar n, real colvector attr) {
	class ErgmGraph scalar Gwave1, Gwave2
	class ErgmModel scalar M
	real rowvector theta_true, theta0
	real scalar nedges0, i, j, k, discard
	struct SaomFit scalar fit

	M = ErgmModel()
	saom_build_model(M, attr)

	Gwave1 = ErgmGraph()
	Gwave1.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !Gwave1.has_edge(i,j)) Gwave1.toggle(i,j)
	}

	theta_true = (-1.6, 1.4, 0.9)
	Gwave2 = ErgmGraph()
	SaomCopyGraph(Gwave1, Gwave2)
	discard = SaomSimulateInterval(Gwave2, M, theta_true, 2.5)

	theta0 = (0,0,0)
	fit = SaomEstimateRM(Gwave1, Gwave2, M, theta0, 2, 30, 200, 0.2)

	printf("unit 1c: true theta:      %6.3f %6.3f %6.3f\n", theta_true[1], theta_true[2], theta_true[3])
	printf("unit 1c: recovered theta: %6.3f %6.3f %6.3f\n", fit.theta[1], fit.theta[2], fit.theta[3])
	printf("unit 1c: phase-3 t-ratios: %6.3f %6.3f %6.3f\n", fit.tratio[1], fit.tratio[2], fit.tratio[3])
	printf("unit 1c: recovered rate: %6.3f (SE %6.3f, true 2.5) - harmonisation unit 27's own real-RSiena-verified conditional-refinement construction, not the closed-form starting value\n", fit.rate, fit.rate_se)

	assert(sign(fit.theta[1]) == sign(theta_true[1]))
	assert(sign(fit.theta[2]) == sign(theta_true[2]))
	assert(sign(fit.theta[3]) == sign(theta_true[3]))
	assert(abs(fit.theta[1] - theta_true[1]) < 2.0)
	assert(abs(fit.theta[2] - theta_true[2]) < 2.0)
	assert(abs(fit.theta[3] - theta_true[3]) < 2.0)
	// tightened from the old (0.5,6) closed-form-only bound (harmonisation
	// unit 27) - the refined rate should recover the TRUE generating rate
	// (2.5) much more closely than the closed-form starting value alone
	// (which was never guaranteed to be close to any particular true
	// rate, only a reasonable data-driven guess).
	assert(abs(fit.rate - 2.5) < 1.0)
	assert(fit.rate_se > 0)

	printf("unit 1c PASS: recovered theta within loose tolerance of true theta, refined rate within tight tolerance of the TRUE generating rate\n")
}

/* -------------------------------------------------------------------
   Unit 2: nodecov/nodeicov/nodeocov - direct reuse of nwergm's own
   change_nodecov()/change_nodeicov()/change_nodeocov() (see
   docs/SAOM_ARCHITECTURE.md's reuse argument - each is a genuine
   single-actor-local SAOM effect: nodeocov is the standard RSiena
   "ego" effect, nodeicov the standard "alter" effect, nodecov their
   combined sum). Certified here via the same boundary-check style as
   unit 1a/1b: a strongly positive nodeicov (alter) coefficient should
   make actor ties concentrate on high-covariate-value nodes.
   ------------------------------------------------------------------- */
void saom_build_model_cov(class ErgmModel M, real colvector attr, real colvector cov) {
	class ErgmTermData scalar td1, td2, td3, td4

	M.init()

	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))

	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	td3 = ErgmTermData()
	td3.attr = attr
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), td3, ("nodematch"))

	td4 = ErgmTermData()
	td4.attr = cov
	M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), td4, ("nodeicov"))
}

void saom_test_unit2(real scalar n, real colvector attr) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	real colvector cov
	real rowvector theta
	real scalar i, j, steps, tot_hi, tot_lo, nhi, nties

	cov = J(n,1,0)
	for (i=1; i<=n; i++) cov[i] = i	// increasing covariate, node n has the highest value
	nhi = ceil(n/2)			// "high covariate" = top half of nodes by cov value

	M = ErgmModel()
	saom_build_model_cov(M, attr, cov)

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-3, 0, 0, 2.5)	// outdegree, reciprocity, nodematch, nodeicov (alter) - strongly favors tying to high-cov alters
	steps = SaomSimulateInterval(G, M, theta, 15)

	tot_hi = 0
	tot_lo = 0
	nties = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (G.has_edge(i,j)) {
				nties++
				if (j > n - nhi) tot_hi++
				else tot_lo++
			}
		}
	}
	printf("unit 2: ties to high-cov alters %g, ties to low-cov alters %g (total %g)\n", tot_hi, tot_lo, nties)
	assert(nties > 0)
	assert(tot_hi > tot_lo)
	printf("unit 2 PASS: strong positive nodeicov (alter) coefficient concentrates ties on high-covariate alters\n")
}

/* -------------------------------------------------------------------
   Unit 3: freshly-derived popularity/activity effects
   (change_saom_indegpop/change_saom_outactivity, unw_saom.do) - NOT
   reused from unw_ergm.do, so certified the way genuinely new terms
   always are in this codebase: brute-force recomputation, here at the
   EGO level (actor i's own local statistic before/after the toggle),
   since these two effects' change() is actor-i-local by construction,
   not a delta of the whole-network stat_saom_X() (see unw_saom.do's
   own header comment on this asymmetry).
   ------------------------------------------------------------------- */
real scalar saom_ego_indegpop(class ErgmGraph scalar G, real scalar i) {
	real rowvector nb
	real scalar k, tot

	nb = G.neighbors_out(i)
	tot = 0
	for (k=1; k<=cols(nb); k++) tot = tot + sqrt(G.din[nb[k]])
	return(tot)
}

real scalar saom_ego_outactivity(class ErgmGraph scalar G, real scalar i) {
	return(G.degree_out(i)^2)
}

void saom_test_unit3_certify(real scalar n, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar t, i, j, before_pop, after_pop, before_act, after_act, pred_pop, pred_act, maxerr
	real rowvector chg

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	td = ErgmTermData()
	maxerr = 0

	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		before_pop = saom_ego_indegpop(G, i)
		before_act = saom_ego_outactivity(G, i)

		chg = change_saom_indegpop(G, i, j, td)
		pred_pop = before_pop + chg[1]
		chg = change_saom_outactivity(G, i, j, td)
		pred_act = before_act + chg[1]

		G.toggle(i, j)

		after_pop = saom_ego_indegpop(G, i)
		after_act = saom_ego_outactivity(G, i)

		if (abs(after_pop - pred_pop) > maxerr) maxerr = abs(after_pop - pred_pop)
		if (abs(after_act - pred_act) > maxerr) maxerr = abs(after_act - pred_act)
	}
	printf("unit 3 certify: max|ego-recompute - predicted| over 400 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 3 PASS: change_saom_indegpop()/change_saom_outactivity() match ego-level brute-force recomputation\n")
}

void saom_test_unit3_direction(real scalar n) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, i, sumsq_hi, sumsq_lo
	real colvector outdeg

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("outactivity", 1, &stat_saom_outactivity(), &change_saom_outactivity(), td2, ("outactivity"))

	// strongly positive outactivity: actors who already send ties should
	// send disproportionately MORE - i.e. out-degree variance should be
	// much higher than a comparable model with outactivity switched off
	// (theta=0), a "rich get richer" concentration signature.
	G = ErgmGraph()
	G.init(n, 1)
	theta = (-3, 1.2)
	steps = SaomSimulateInterval(G, M, theta, 15)
	outdeg = J(n,1,0)
	for (i=1; i<=n; i++) outdeg[i] = G.degree_out(i)
	sumsq_hi = variance(outdeg)

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-3, 0)
	steps = SaomSimulateInterval(G, M, theta, 15)
	for (i=1; i<=n; i++) outdeg[i] = G.degree_out(i)
	sumsq_lo = variance(outdeg)

	printf("unit 3 direction: out-degree variance with outactivity on %6.3f, off %6.3f\n", sumsq_hi, sumsq_lo)
	assert(sumsq_hi > sumsq_lo)
	printf("unit 3 PASS: positive outactivity coefficient concentrates out-degree (rich-get-richer)\n")
}

/* -------------------------------------------------------------------
   Unit 4: transitive triplets (change_saom_transtrip, unw_saom.do) -
   freshly derived, reusing ErgmGraph's own already-certified
   shared_partners_otp()/_osp()/_isp() PRIMITIVES (not term functions).
   Certified via independent ego-level brute-force recomputation of
   s_i(x) = sum_j sum_h x_ij*x_ih*x_hj, matching unit 3's own
   methodology exactly.
   ------------------------------------------------------------------- */
real scalar saom_ego_transtrip(class ErgmGraph scalar G, real scalar i) {
	real rowvector nb
	real scalar a, b, tot

	nb = G.neighbors_out(i)
	tot = 0
	for (a=1; a<=cols(nb); a++) {
		for (b=1; b<=cols(nb); b++) {
			if (a==b) continue
			if (G.has_edge(nb[b], nb[a])) tot++	// h=nb[b], j=nb[a]: need h->j
		}
	}
	return(tot)
}

void saom_test_unit4_certify(real scalar n, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar t, i, j, before, after, pred, maxerr
	real rowvector chg

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	td = ErgmTermData()
	maxerr = 0

	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		before = saom_ego_transtrip(G, i)
		chg = change_saom_transtrip(G, i, j, td)
		pred = before + chg[1]

		G.toggle(i, j)

		after = saom_ego_transtrip(G, i)
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 4 certify: max|ego-recompute - predicted| over 400 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 4 PASS: change_saom_transtrip() matches ego-level brute-force recomputation\n")
}

void saom_test_unit4_direction(real scalar n) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, tt_hi, tt_lo

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("transtrip", 1, &stat_saom_transtrip(), &change_saom_transtrip(), td2, ("transtrip"))

	// outdegree deliberately close to 0 (not strongly negative like
	// unit 1a/1b's boundary checks) - transitivity needs a genuinely
	// non-trivial number of existing ties to have any two-path
	// available to close in the first place; a too-sparse baseline
	// bootstraps too slowly for either condition to show a difference
	// within a reasonable simulated interval (found by direct trial:
	// theta=(-2,0.8) at rate 20 produced ZERO transitive triplets in
	// EITHER condition on n=16).
	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 1.2)
	steps = SaomSimulateInterval(G, M, theta, 40)
	tt_hi = stat_saom_transtrip(G, td2)[1]

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 0)
	steps = SaomSimulateInterval(G, M, theta, 40)
	tt_lo = stat_saom_transtrip(G, td2)[1]

	printf("unit 4 direction: transitive-triplet count with transtrip on %6.1f, off %6.1f\n", tt_hi, tt_lo)
	assert(tt_hi > tt_lo)
	printf("unit 4 PASS: positive transtrip coefficient increases triadic closure\n")
}

/* -------------------------------------------------------------------
   Unit 5: 3-cycles (change_saom_cycle3, unw_saom.do) - freshly
   derived, reusing shared_partners_otp() with SWAPPED argument order
   relative to unit 4 (see unw_saom.do's own header comment on this
   easy-to-get-backwards detail). Same ego-level brute-force
   certification methodology.
   ------------------------------------------------------------------- */
real scalar saom_ego_cycle3(class ErgmGraph scalar G, real scalar i) {
	real rowvector nbi, nbj
	real scalar a, b, j, h, tot

	nbi = G.neighbors_out(i)
	tot = 0
	for (a=1; a<=cols(nbi); a++) {
		j = nbi[a]
		nbj = G.neighbors_out(j)
		for (b=1; b<=cols(nbj); b++) {
			h = nbj[b]
			if (h==i) continue
			if (G.has_edge(h, i)) tot++
		}
	}
	return(tot)
}

void saom_test_unit5_certify(real scalar n, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar t, i, j, before, after, pred, maxerr
	real rowvector chg

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	td = ErgmTermData()
	maxerr = 0

	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		before = saom_ego_cycle3(G, i)
		chg = change_saom_cycle3(G, i, j, td)
		pred = before + chg[1]

		G.toggle(i, j)

		after = saom_ego_cycle3(G, i)
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 5 certify: max|ego-recompute - predicted| over 400 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 5 PASS: change_saom_cycle3() matches ego-level brute-force recomputation\n")
}

void saom_test_unit5_direction(real scalar n) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, c3_hi, c3_lo

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("cycle3", 1, &stat_saom_cycle3(), &change_saom_cycle3(), td2, ("cycle3"))

	// same reasoning as unit 4's own direction test: a near-zero
	// outdegree baseline (not strongly negative) so enough two-paths
	// exist for the cycle3 effect to have material to act on.
	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 1.5)
	steps = SaomSimulateInterval(G, M, theta, 40)
	c3_hi = stat_saom_cycle3(G, td2)[1]

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 0)
	steps = SaomSimulateInterval(G, M, theta, 40)
	c3_lo = stat_saom_cycle3(G, td2)[1]

	printf("unit 5 direction: 3-cycle count with cycle3 on %6.1f, off %6.1f\n", c3_hi, c3_lo)
	assert(c3_hi > c3_lo)
	printf("unit 5 PASS: positive cycle3 coefficient increases directed 3-cycle formation\n")
}

/* -------------------------------------------------------------------
   Unit 9: outpopularity/inactivity/simcov - each independently
   verified against real RSiena C++ source before implementation (see
   unw_saom.do's own header comments for the exact file/formula).
   Same ego-level brute-force certification methodology as units 3-5.
   ------------------------------------------------------------------- */
real scalar saom_ego_outpop(class ErgmGraph scalar G, real scalar i) {
	real rowvector nb
	real scalar k, tot

	nb = G.neighbors_out(i)
	tot = 0
	for (k=1; k<=cols(nb); k++) tot = tot + sqrt(G.dout[nb[k]])
	return(tot)
}

real scalar saom_ego_inact(class ErgmGraph scalar G, real scalar i) {
	return(G.degree_out(i) * sqrt(G.din[i]))
}

real scalar saom_ego_simcov(class ErgmGraph scalar G, real scalar i, real colvector attr, real scalar rng) {
	real rowvector nb
	real scalar k, tot

	nb = G.neighbors_out(i)
	tot = 0
	for (k=1; k<=cols(nb); k++) tot = tot + 1 - abs(attr[i] - attr[nb[k]])/rng
	return(tot)
}

void saom_test_unit9_certify(real scalar n, real scalar seed, real colvector attr) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar t, i, j, before, after, pred, maxerr_pop, maxerr_act, maxerr_sim, rng
	real rowvector chg

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	td = ErgmTermData()
	rng = max(attr) - min(attr)
	maxerr_pop = 0
	maxerr_act = 0
	maxerr_sim = 0

	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		before = saom_ego_outpop(G, i)
		chg = change_saom_outpop(G, i, j, td)
		pred = before + chg[1]
		G.toggle(i, j)
		after = saom_ego_outpop(G, i)
		if (abs(after-pred) > maxerr_pop) maxerr_pop = abs(after-pred)
		G.toggle(i, j)	// undo, so the three checks below start from the SAME pre-toggle state

		before = saom_ego_inact(G, i)
		chg = change_saom_inact(G, i, j, td)
		pred = before + chg[1]
		G.toggle(i, j)
		after = saom_ego_inact(G, i)
		if (abs(after-pred) > maxerr_act) maxerr_act = abs(after-pred)
		G.toggle(i, j)

		td.attr = attr
		td.decay = rng
		before = saom_ego_simcov(G, i, attr, rng)
		chg = change_saom_simcov(G, i, j, td)
		pred = before + chg[1]
		G.toggle(i, j)
		after = saom_ego_simcov(G, i, attr, rng)
		if (abs(after-pred) > maxerr_sim) maxerr_sim = abs(after-pred)
		// leave this one toggled (advances the graph state for the next iteration,
		// same "network keeps evolving across the 400 draws" pattern units 3-5 use)
	}
	printf("unit 9 certify: max errors - outpop %9.2e, inact %9.2e, simcov %9.2e\n", maxerr_pop, maxerr_act, maxerr_sim)
	assert(maxerr_pop < 1e-8)
	assert(maxerr_act < 1e-8)
	assert(maxerr_sim < 1e-8)
	printf("unit 9 PASS: change_saom_outpop()/inact()/simcov() match ego-level brute-force recomputation\n")
}

void saom_test_unit9_direction(real scalar n, real colvector attr) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, hi, lo

	// --- outpopularity direction: ties concentrate on high-outdegree alters
	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("outpopularity", 1, &stat_saom_outpop(), &change_saom_outpop(), td2, ("outpopularity"))

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 0.8)
	steps = SaomSimulateInterval(G, M, theta, 30)
	hi = stat_saom_outpop(G, td2)[1]

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 0)
	steps = SaomSimulateInterval(G, M, theta, 30)
	lo = stat_saom_outpop(G, td2)[1]

	printf("unit 9 direction (outpop): stat with effect on %8.2f, off %8.2f\n", hi, lo)
	assert(hi > lo)

	// --- simcov direction: strong positive coefficient concentrates ties
	// among actors with SIMILAR covariate values
	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	td2.attr = attr
	td2.decay = max(attr) - min(attr)
	M.addterm("simcov", 1, &stat_saom_simcov(), &change_saom_simcov(), td2, ("simcov"))

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 3)
	steps = SaomSimulateInterval(G, M, theta, 30)
	hi = stat_saom_simcov(G, td2)[1]

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-0.3, 0)
	steps = SaomSimulateInterval(G, M, theta, 30)
	lo = stat_saom_simcov(G, td2)[1]

	printf("unit 9 direction (simcov): stat with effect on %8.2f, off %8.2f\n", hi, lo)
	assert(hi > lo)

	printf("unit 9 PASS: positive outpopularity/simcov coefficients act in the expected direction\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 18: e(V) covariance matrix. Real RSiena's own
   sandwich formula (verified directly from RSiena's actual R source,
   see SaomEstimateRM()'s own header comment in unw_saom.do for the
   full derivation/citation - not re-derived here). This is a structural
   sanity check (symmetric, positive diagonal - i.e. every SE is a real,
   well-defined number) plus a plausibility bound (SEs should be the
   same rough ORDER OF MAGNITUDE as the coefficients themselves for a
   reasonably-sized/dense synthetic network, not wildly divergent) - the
   actual numerical correctness of the formula is certified separately,
   directly against real RSiena's own printed SE values on RSiena's own
   s50 tutorial data (dev/saom_rsiena_crosscheck.do/
   saom_waves_ado_test.do - both came back within a few percent of real
   RSiena's own reported standard errors for outdegree/reciprocity, on
   both the two-wave and three-wave paths).
   ------------------------------------------------------------------- */
void saom_test_unit18_cov(real scalar n) {
	class ErgmGraph scalar G1, G2
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct SaomFit scalar fit
	real scalar k, i, j, p

	G1 = ErgmGraph()
	G1.init(n, 1)
	for (k=1; k<=round(0.15*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G1.has_edge(i,j)) G1.toggle(i,j)
	}
	G2 = ErgmGraph()
	G2.init(n, 1)
	for (k=1; k<=round(0.20*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G2.has_edge(i,j)) G2.toggle(i,j)
	}

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	fit = SaomEstimateRM(G1, G2, M, J(1,2,0), 2, 30, 200, 0.2)
	p = M.nparam()

	printf("unit 18: theta %8.4f %8.4f\n", fit.theta[1], fit.theta[2])
	printf("unit 18: SE    %8.4f %8.4f\n", sqrt(fit.V[1,1]), sqrt(fit.V[2,2]))

	assert(rows(fit.V) == p & cols(fit.V) == p)
	assert(max(abs(fit.V - fit.V')) < 1e-6)		// symmetric
	for (k=1; k<=p; k++) assert(fit.V[k,k] > 0)		// every SE well-defined (real, positive variance)
	// plausibility bound: SE should be the same rough order of
	// magnitude as the coefficient itself, not wildly divergent (a
	// genuinely broken formula - e.g. wrong Jacobian scale - tends to
	// produce SEs orders of magnitude too large/small, not merely
	// somewhat off).
	for (k=1; k<=p; k++) assert(sqrt(fit.V[k,k]) < 20 * abs(fit.theta[k]) + 5)

	printf("unit 18 PASS: e(V) is symmetric with well-defined positive variances, plausible magnitude\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 22: GWESP reuse verification. DIRECT reuse of
   nwergm's own already-certified stat_gwesp()/change_gwesp()
   (unw_ergm.do, td.sptype="OTP" - verified against real RSiena source
   to match RSiena's own `gwespFF' effect exactly by name, definition,
   and kernel formula before wiring this at all, see
   docs/SAOM_ROADMAP.md's own account). Since change_gwesp() itself is
   already certified by nwergm's own test suite, this test's own job is
   different: certifying the WIRING (does M.addterm()/M.full_change()
   correctly thread td.decay/td.sptype through in a SAOM context, not
   just an ERGM one) - via the SAME "change function predicts the global
   statistic's own before/after difference" identity every other SAOM
   effect in this file is certified against, just measured against the
   GLOBAL stat_gwesp() (reused directly, no new "ego-level" helper
   needed) rather than an ego-local partial recomputation, since GWESP's
   own reused stat_gwesp() already computes exactly this.
   ------------------------------------------------------------------- */
/* -------------------------------------------------------------------
   Harmonisation unit 22 (corrected): certifying change_saom_gwesp().

   A REAL, non-obvious finding while building this test (worth keeping,
   not silently smoothed over): the standard "ego-level brute-force
   recomputation" methodology every OTHER SAOM-native effect in this
   file uses (units 3/4/5/9 - compare change_X()'s own prediction
   against directly toggling the graph and recomputing SOME local
   statistic's own before/after difference) does NOT apply to GWESP.
   Tried it first: defined s_i(x) = sum over i's own existing ties h of
   gw_kernel(OTP(i,h)) and checked change_saom_gwesp() against
   s_i(after)-s_i(before) - this FAILED (error ~3.0, nowhere near
   machine epsilon), because adding tie i->j can also change OTP(i,h)
   for i's OWN OTHER existing ties h (whenever j->h also exists - the
   exact same ripple nwergm's own change_gwesp_otp() "nb" loop
   computes). So even the ego-RESTRICTED statistic's own true gradient
   includes that ripple - meaning real RSiena's own actual ministep
   formula (`f(OTP(ego,alter))' alone, verified directly from
   GenericNetworkEffect.cpp) is NOT the exact gradient of ANY
   well-defined local statistic, ego-restricted or otherwise - a
   genuine, deliberate approximation in RSiena's own "Generic effect"
   framework, not a shortcut this port is taking. There is therefore no
   brute-force numerical target to certify against; the correct
   standard is DIRECT FIDELITY to RSiena's own documented formula
   (`f(OTP(ego,alter))', sign-flipped for deletion, matching this
   codebase's own established change-function sign convention) -
   verified below via a HAND-COMPUTED kernel value (the RSiena formula
   `exp(decay)*(1-(1-exp(-decay))^p)' written out directly in the test,
   not by calling gw_kernel() itself, so this is not merely checking
   the code against itself) on a graph with an INDEPENDENTLY-VERIFIABLE
   shared-partner count.
   ------------------------------------------------------------------- */
void saom_test_unit22_certify(real scalar n, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar decay, p, expected, got, i, j, k, otp_manual, m, h

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	for (k=1; k<=round(0.15*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
	td = ErgmTermData()
	decay = .69
	td.decay = decay

	// hand-verify shared_partners_otp() itself against a fully manual
	// count first (not trusting the primitive blindly, even though it
	// is independently certified elsewhere) for several random (i,j)
	// pairs, THEN check change_saom_gwesp() against a hand-written
	// (not gw_kernel()-calling) copy of RSiena's own exact formula.
	for (k=1; k<=100; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		otp_manual = 0
		for (m=1; m<=n; m++) {
			h = m
			if (h==i | h==j) continue
			if (G.has_edge(i,h) & G.has_edge(h,j)) otp_manual++
		}
		assert(otp_manual == G.shared_partners_otp(i,j))

		p = otp_manual
		expected = exp(decay) * (1 - (1-exp(-decay))^p)		// RSiena's own exact formula, written out directly here
		expected = G.has_edge(i,j) ? -expected : expected		// this codebase's own established sign convention (units 1-9)
		got = change_saom_gwesp(G, i, j, td)[1]
		assert(reldif(expected, got) < 1e-10 | abs(expected-got) < 1e-10)
	}
	printf("unit 22 certify: change_saom_gwesp() matches RSiena's own documented formula (f(OTP(ego,alter)), hand-verified shared-partner counts) over 100 checks\n")
	printf("unit 22 PASS: change_saom_gwesp() is a faithful transcription of real RSiena's own GenericNetworkEffect::calculateContribution() - NOT nwergm's full change_gwesp() (see unw_saom.do's own header comment for why those genuinely differ)\n")
}

/* NOTE on parameters: the CORRECTED change_saom_gwesp() (RSiena's own
   real, deliberately-simplified `f(OTP(ego,alter))' formula, no
   neighbor-ripple reinforcement) drives transitivity noticeably more
   WEAKLY per unit theta than the original, INCORRECT change_gwesp()
   reuse did (that one effectively double/triple-counted via its own
   "na"/"nb" loops) - a single modest-theta, single-realization check
   (theta=1.2, one simulated interval) turned out too noisy/underpowered
   to reliably show the correct direction, even though the formula
   itself is correct (verified separately, directly, via a stronger
   theta averaged over many replicates: 753.7 vs 16.6 with theta=3.0 vs
   0, n=20, 20 replicates - overwhelming). This version uses a
   stronger theta AND averages over several replicates so the
   assertion is genuinely robust, not tuned to pass once. */
void saom_test_unit22_direction(real scalar n) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, r, sum_hi, sum_lo, nrep

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	td2.decay = .69
	td2.sptype = "OTP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_saom_gwesp(), td2, ("gwesp"))

	rseed(2468)
	nrep = 8
	sum_hi = 0
	sum_lo = 0
	for (r=1; r<=nrep; r++) {
		G = ErgmGraph()
		G.init(n, 1)
		theta = (-1.0, 2.5)
		steps = SaomSimulateInterval(G, M, theta, 30)
		sum_hi = sum_hi + stat_gwesp(G, td2)[1]

		G = ErgmGraph()
		G.init(n, 1)
		theta = (-1.0, 0)
		steps = SaomSimulateInterval(G, M, theta, 30)
		sum_lo = sum_lo + stat_gwesp(G, td2)[1]
	}
	printf("unit 22 direction: avg gwesp statistic over %g replicates, effect on %8.2f, off %8.2f\n", nrep, sum_hi/nrep, sum_lo/nrep)
	assert(sum_hi/nrep > sum_lo/nrep)
	printf("unit 22 PASS: positive gwesp coefficient increases geometrically-weighted triadic closure\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 23: transTies. Ego-level restricted statistic:
   s_i(x) = sum over i's OWN existing ties h of indicator(OTP(i,h)>=1) -
   UNLIKE gwesp() (unit 22), this effect's own real RSiena ministep
   formula genuinely IS the exact gradient of this local statistic (see
   change_saom_transties()'s own header comment in unw_saom.do for why:
   TransitiveTiesEffect.cpp is its own dedicated class, not a "Generic
   effect" approximation) - so the STANDARD ego-level brute-force
   methodology every OTHER SAOM-native effect uses (units 3/4/5) is the
   right certification standard here, unlike unit 22's own genuinely
   different case. Tried and CONFIRMED to pass cleanly (not assumed) -
   see this test's own result.
   ------------------------------------------------------------------- */
real scalar saom_ego_transties(class ErgmGraph scalar G, real scalar i) {
	real rowvector nb
	real scalar m, h, tot

	nb = G.neighbors_out(i)
	tot = 0
	for (m=1; m<=cols(nb); m++) {
		h = nb[m]
		tot = tot + (G.shared_partners_otp(i,h) >= 1)
	}
	return(tot)
}

void saom_test_unit23_certify(real scalar n, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar t, i, j, before, after, pred, maxerr
	real rowvector chg

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	for (t=1; t<=round(0.15*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
	td = ErgmTermData()

	maxerr = 0
	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		before = saom_ego_transties(G, i)
		chg = change_saom_transties(G, i, j, td)
		pred = before + chg[1]

		G.toggle(i, j)

		after = saom_ego_transties(G, i)
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 23 certify: max|ego-recompute - predicted| over 400 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 23 PASS: change_saom_transties() matches ego-level brute-force recomputation (unlike gwesp(), this effect's real RSiena formula IS the exact ego-restricted gradient)\n")
}

void saom_test_unit23_direction(real scalar n) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, hi, lo

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("transties", 1, &stat_transitiveties(), &change_saom_transties(), td2, ("transties"))

	rseed(13579)
	G = ErgmGraph()
	G.init(n, 1)
	theta = (-1.2, 1.5)
	steps = SaomSimulateInterval(G, M, theta, 30)
	hi = stat_transitiveties(G, td2)[1]

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-1.2, 0)
	steps = SaomSimulateInterval(G, M, theta, 30)
	lo = stat_transitiveties(G, td2)[1]

	printf("unit 23 direction: transties statistic with effect on %8.2f, off %8.2f\n", hi, lo)
	assert(hi > lo)
	printf("unit 23 PASS: positive transties coefficient increases the count of transitive ties\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 25: balance. Three separate checks, matching the
   three genuinely distinct pieces unw_saom.do's own header comment
   derives: (1) saom_balance_mean() against an INDEPENDENT hand
   computation (not calling degree_in(), matching the GWESP lesson's own
   "don't trust the implementation's own helper" discipline), on TWO
   pooled graphs specifically to exercise real RSiena's own "sum
   numerators/denominators THEN divide once" pooling convention (not an
   average of per-graph ratios - a real, easy-to-get-wrong detail); (2)
   change_saom_balance() against the STANDARD ego-level brute-force
   methodology (expected to pass cleanly, like transTies unit 23, since
   BalanceEffect is its own dedicated RSiena class, not a "Generic
   effect" approximation like gwesp()); (3) a direction check.
   ------------------------------------------------------------------- */
void saom_test_unit25_meancheck() {
	class ErgmGraph scalar G1, G2
	pointer(class ErgmGraph scalar) rowvector Gb
	real scalar n, h, i, indeg, tempra, temprb, want, got

	n = 5
	G1 = ErgmGraph()
	G1.init(n, 1)
	G1.toggle(1,2)
	G1.toggle(1,3)
	G1.toggle(2,3)
	G1.toggle(3,4)
	G1.toggle(4,1)
	G1.toggle(4,5)
	G1.toggle(5,2)

	G2 = ErgmGraph()
	G2.init(n, 1)
	G2.toggle(2,1)
	G2.toggle(3,1)
	G2.toggle(1,4)
	G2.toggle(4,3)
	G2.toggle(5,3)
	G2.toggle(2,5)

	// Independent hand computation - deliberately re-walks has_edge()
	// directly rather than calling G.degree_in(), so this cannot pass
	// merely by agreeing with the implementation's own helper.
	tempra = 0
	temprb = 0
	Gb = (&G1, &G2)
	for (h=1; h<=n; h++) {
		indeg = 0
		for (i=1; i<=n; i++) {
			if (i==h) continue
			if (G1.has_edge(i,h)) indeg++
		}
		tempra = tempra + 2*indeg*((n-1)-indeg)
	}
	temprb = temprb + n*(n-1)*(n-2)
	for (h=1; h<=n; h++) {
		indeg = 0
		for (i=1; i<=n; i++) {
			if (i==h) continue
			if (G2.has_edge(i,h)) indeg++
		}
		tempra = tempra + 2*indeg*((n-1)-indeg)
	}
	temprb = temprb + n*(n-1)*(n-2)
	want = tempra/temprb

	got = saom_balance_mean(Gb)

	printf("unit 25 meancheck: hand-computed pooled balanceMean %9.6f, saom_balance_mean() %9.6f\n", want, got)
	assert(abs(got-want) < 1e-10)
	printf("unit 25 PASS: saom_balance_mean() matches independent hand computation, pooled by summing numerators/denominators across both graphs THEN dividing once (real RSiena's own calcBalmean() convention, not an average of per-graph ratios)\n")
}

real scalar saom_ego_balance(class ErgmGraph scalar G, real scalar i, class ErgmTermData scalar td) {
	real rowvector nb
	real scalar m, j, n, b0, D, tot

	n = G.n
	b0 = td.decay
	nb = G.neighbors_out(i)
	tot = 0
	for (m=1; m<=cols(nb); m++) {
		j = nb[m]
		D = (G.degree_out(i)-1) + (G.degree_out(j) - (G.has_edge(j,i)?1:0)) - 2*G.shared_partners_osp(i,j)
		tot = tot + ((n-2)*b0 - D)
	}
	return(tot)
}

void saom_test_unit25_certify(real scalar n, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar t, i, j, before, after, pred, maxerr
	real rowvector chg

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	for (t=1; t<=round(0.15*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
	td = ErgmTermData()
	td.decay = 0.37	// arbitrary fixed test constant - change_saom_balance()'s own correctness does not depend on b0's true data-derived value (saom_balance_mean() is certified separately above)

	maxerr = 0
	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue

		before = saom_ego_balance(G, i, td)
		chg = change_saom_balance(G, i, j, td)
		pred = before + chg[1]

		G.toggle(i, j)

		after = saom_ego_balance(G, i, td)
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 25 certify: max|ego-recompute - predicted| over 400 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 25 PASS: change_saom_balance() matches ego-level brute-force recomputation (BalanceEffect is its own dedicated RSiena class, not a Generic-effect approximation like gwesp())\n")
}

void saom_test_unit25_direction(real scalar n) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real rowvector theta
	real scalar steps, hi, lo

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	td2.decay = 0.5	// fixed test constant - direction check does not need the true data-derived balanceMean either
	M.addterm("balance", 1, &stat_saom_balance(), &change_saom_balance(), td2, ("balance"))

	rseed(24681357)
	G = ErgmGraph()
	G.init(n, 1)
	theta = (-1.2, 1.5)
	steps = SaomSimulateInterval(G, M, theta, 30)
	hi = stat_saom_balance(G, td2)[1]

	G = ErgmGraph()
	G.init(n, 1)
	theta = (-1.2, 0)
	steps = SaomSimulateInterval(G, M, theta, 30)
	lo = stat_saom_balance(G, td2)[1]

	printf("unit 25 direction: balance statistic with effect on %10.2f, off %10.2f\n", hi, lo)
	assert(hi > lo)
	printf("unit 25 PASS: positive balance coefficient increases the balance statistic (actors preferentially tie to alters with similar tie patterns toward third parties)\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 26: co-evolution (behavior side). See
   docs/SAOM_ROADMAP.md's own "Co-evolution" DESIGN section for the
   full RSiena source-verification account this test suite certifies
   against. Four checks: (1) linear shape's ministep delta against the
   RAW global statistic's own before/after difference (trivially
   additive, no ego-restriction subtlety); (2) quadratic shape's own
   ministep delta against a CENTERED statistic's own difference - NOT
   the raw one, a real, disclosed RSiena quirk (the ministep formula
   uses the centered value, egoStatistic() does not) kept exactly as
   real RSiena has it, with an explicit assertion that it does NOT also
   match the raw statistic's own difference, so a future edit that
   "fixes" this apparent inconsistency back toward internal consistency
   would break this test rather than silently drifting from real
   RSiena; (3) avAlt against the STANDARD ego-level brute-force
   methodology (myopic-actor restricted, like transties/balance/
   indegpopularity before it - changing actor i's own value also
   changes OTHER actors' own avAlt statistic whenever i is their alter,
   so the ministep delta is correctly restricted to actor i's own
   summand only); (4) a ministep-level direction check confirming a
   strong positive avAlt coefficient pulls a network-connected group's
   own behavior values together over repeated ministeps.
   ------------------------------------------------------------------- */
void saom_test_unit26_linear_certify(real scalar n, real scalar seed) {
	class SaomBehavior scalar Beh
	class ErgmGraph scalar G
	real scalar t, i, diff, before, after, pred, maxerr, v

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	Beh = SaomBehavior()
	Beh.init(ceil(runiform(n,1)*5), 1, 5, 3)

	maxerr = 0
	for (t=1; t<=200; t++) {
		i = ceil(runiform(1,1)*n)
		v = Beh.value(i)
		if (v <= Beh.minval) diff = 1
		else if (v >= Beh.maxval) diff = -1
		else diff = (runiform(1,1) > 0.5) ? 1 : -1

		before = stat_saom_linear(Beh, G)[1]
		pred = before + change_saom_linear(Beh, G, i, diff)
		Beh.setvalue(i, v + diff)
		after = stat_saom_linear(Beh, G)[1]
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 26 linear certify: max|global-recompute - predicted| over 200 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 26 PASS: change_saom_linear() matches the raw global statistic's own before/after difference exactly (no ego-restriction subtlety - linear shape is purely additive across actors)\n")
}

void saom_test_unit26_quad_certify(real scalar n, real scalar seed) {
	class SaomBehavior scalar Beh
	class ErgmGraph scalar G
	real scalar t, i, diff, beforeC, afterC, beforeR, afterR, predC, maxerrC, v, mn

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	Beh = SaomBehavior()
	Beh.init(ceil(runiform(n,1)*5), 1, 5, 3)
	mn = Beh.overallMean

	maxerrC = 0
	for (t=1; t<=200; t++) {
		i = ceil(runiform(1,1)*n)
		v = Beh.value(i)
		diff = 1
		if (v <= Beh.minval) diff = 1
		else if (v >= Beh.maxval) diff = -1
		else diff = (runiform(1,1) > 0.5) ? 1 : -1

		beforeC = sum((Beh.values :- mn) :* (Beh.values :- mn))
		predC = beforeC + change_saom_quadratic(Beh, G, i, diff)
		Beh.setvalue(i, v + diff)
		afterC = sum((Beh.values :- mn) :* (Beh.values :- mn))

		if (abs(afterC - predC) > maxerrC) maxerrC = abs(afterC - predC)
	}
	printf("unit 26 quadratic certify: max|centered-recompute - predicted| over 200 toggles = %9.2e\n", maxerrC)
	assert(maxerrC < 1e-8)
	printf("unit 26 PASS: change_saom_quadratic()'s ministep delta matches the CENTERED statistic's own before/after difference exactly (the formula it actually implements)\n")

	// Separate, explicit demonstration (not folded into the loop above,
	// for clarity) that the ministep delta does NOT equal the RAW
	// (uncentered) statistic's own difference whenever mean!=0 - the
	// real RSiena quirk, pinned down so a future "fix" toward internal
	// consistency would break this assertion rather than silently
	// drifting from real RSiena's own actual behavior.
	Beh = SaomBehavior()
	Beh.init((1\2\3\4\5), 1, 5, 3)		// overallMean = 3 != 0
	i = 1
	diff = 1
	beforeR = stat_saom_quadratic(Beh, G)[1]
	predC = change_saom_quadratic(Beh, G, i, diff)		// ministep delta, captured BEFORE mutating Beh (change_saom_quadratic() reads Beh's current state)
	Beh.setvalue(i, Beh.value(i) + diff)
	afterR = stat_saom_quadratic(Beh, G)[1]
	printf("unit 26 quadratic quirk-check: raw-scale actual change = %g, ministep delta = %g (genuinely different, as expected - both real RSiena's own construction, not a bug)\n", afterR-beforeR, predC)
	assert(abs((afterR - beforeR) - predC) > 1e-6)
	printf("unit 26 PASS: confirmed change_saom_quadratic()'s own ministep delta genuinely differs from the raw statistic's own difference when overallMean!=0, matching real RSiena's own documented (not internally 'fixed') behavior\n")
}

real scalar saom_ego_avalt(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i) {
	real rowvector nb

	nb = G.neighbors_out(i)
	if (cols(nb) == 0) return(0)
	return(Beh.value(i) * mean(Beh.values[nb']))
}

void saom_test_unit26_avalt_certify(real scalar n, real scalar seed) {
	class SaomBehavior scalar Beh
	class ErgmGraph scalar G
	real scalar t, i, diff, v, before, after, pred, maxerr

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	for (t=1; t<=round(0.2*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		diff = ceil(runiform(1,1)*n)
		if (i != diff & !G.has_edge(i,diff)) G.toggle(i, diff)
	}
	Beh = SaomBehavior()
	Beh.init(ceil(runiform(n,1)*5), 1, 5, 3)

	maxerr = 0
	for (t=1; t<=300; t++) {
		i = ceil(runiform(1,1)*n)
		v = Beh.value(i)
		if (v <= Beh.minval) diff = 1
		else if (v >= Beh.maxval) diff = -1
		else diff = (runiform(1,1) > 0.5) ? 1 : -1

		before = saom_ego_avalt(Beh, G, i)
		pred = before + change_saom_avalt(Beh, G, i, diff)
		Beh.setvalue(i, v + diff)
		after = saom_ego_avalt(Beh, G, i)
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 26 avalt certify: max|ego-recompute - predicted| over 300 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 26 PASS: change_saom_avalt() matches ego-level brute-force recomputation (myopic-actor restricted - changing i's own value also changes OTHER actors' own avAlt statistic whenever i is their alter, correctly excluded from this ministep's own delta)\n")
}

real scalar saom_ego_avsim(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i) {
	real rowvector nb
	real scalar od, vego, sumabs, k

	nb = G.neighbors_out(i)
	od = cols(nb)
	if (od == 0) return(0)
	vego = Beh.value(i)
	sumabs = 0
	for (k=1; k<=od; k++) sumabs = sumabs + abs(Beh.value(nb[k]) - vego)
	return(1 - (sumabs/Beh.range)/od - Beh.simMean)
}

void saom_test_unit26_avsim_certify(real scalar n, real scalar seed) {
	class SaomBehavior scalar Beh
	class ErgmGraph scalar G
	real scalar t, i, diff, v, before, after, pred, maxerr

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	for (t=1; t<=round(0.2*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		diff = ceil(runiform(1,1)*n)
		if (i != diff & !G.has_edge(i,diff)) G.toggle(i, diff)
	}
	Beh = SaomBehavior()
	// simMean != 0, so a certify pass here also confirms (implicitly)
	// that centering plays no role in the ministep delta - only in the
	// global statistic, exactly the same real, source-verified quirk
	// already documented for quadratic shape above (both terms of
	// Beh's own state matter, but simMean only ever enters egoStatistic,
	// never calculateChangeContribution - confirmed directly from
	// SimilarityEffect.cpp).
	Beh.init(ceil(runiform(n,1)*5), 1, 5, 3, 0.3)

	maxerr = 0
	for (t=1; t<=300; t++) {
		i = ceil(runiform(1,1)*n)
		v = Beh.value(i)
		if (v <= Beh.minval) diff = 1
		else if (v >= Beh.maxval) diff = -1
		else diff = (runiform(1,1) > 0.5) ? 1 : -1

		before = saom_ego_avsim(Beh, G, i)
		pred = before + change_saom_avsim(Beh, G, i, diff)
		Beh.setvalue(i, v + diff)
		after = saom_ego_avsim(Beh, G, i)
		if (abs(after - pred) > maxerr) maxerr = abs(after - pred)
	}
	printf("unit 26 avsim certify: max|ego-recompute - predicted| over 300 toggles = %9.2e\n", maxerr)
	assert(maxerr < 1e-8)
	printf("unit 26 PASS: change_saom_avsim() matches ego-level brute-force recomputation (myopic-actor restricted, centering excluded from the ministep delta exactly as real RSiena's own source has it)\n")
}

void saom_test_unit26_simmean_certify(real scalar n, real scalar seed) {
	// direct certification of saom_similarity_mean() itself against a
	// naive triple-loop recomputation of RSiena's own rangeAndSimilarity()
	// formula (pooled over every wave EXCEPT the last, every ordered
	// actor pair, sim(a,b)=1-|a-b|/range) - independent of the ministep/
	// egoStatistic checks above, which only ever certify that Beh.simMean
	// is USED correctly, not that it was COMPUTED correctly.
	real colvector w1, w2, w3
	pointer(real colvector) rowvector Behwaves
	real scalar range, naive, got, i, j, w
	pointer(real colvector) rowvector waveslist

	rseed(seed)
	w1 = ceil(runiform(n,1)*5)
	w2 = ceil(runiform(n,1)*5)
	w3 = ceil(runiform(n,1)*5)
	range = 5 - 1
	Behwaves = (&w1, &w2, &w3)

	naive = 0
	waveslist = (&w1, &w2)		// every wave EXCEPT the last (w3), real RSiena's own tmpmat[,-ncol(tmpmat)] convention
	for (w=1; w<=2; w++) {
		for (i=1; i<=n; i++) {
			for (j=1; j<=n; j++) {
				if (j == i) continue
				naive = naive + (1 - abs((*waveslist[w])[i] - (*waveslist[w])[j])/range)
			}
		}
	}
	naive = naive / (2*n*(n-1))

	got = saom_similarity_mean(Behwaves, range)
	printf("unit 26 simmean certify: naive = %9.6f, saom_similarity_mean() = %9.6f\n", naive, got)
	assert(abs(naive - got) < 1e-10)
	printf("unit 26 PASS: saom_similarity_mean() matches a naive triple-loop recomputation of RSiena's own rangeAndSimilarity() formula, pooled over every wave except the last\n")
}

void saom_test_unit26_ministep_dir(real scalar n) {
	class SaomBehavior scalar Beh
	class ErgmGraph scalar G
	class SaomBehaviorModel scalar Mbeh
	real rowvector theta
	real scalar i, t, picked, spreadHi, spreadLo

	rseed(975318)
	G = ErgmGraph()
	G.init(n, 1)
	// a single connected chain, so influence has somewhere to flow
	for (i=1; i<=n-1; i++) {
		G.toggle(i, i+1)
		G.toggle(i+1, i)
	}

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "avalt")

	// --- effect ON: strong positive avAlt coefficient ---
	Beh = SaomBehavior()
	Beh.init(ceil(runiform(n,1)*5), 1, 5, 3)
	theta = 3
	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		picked = SaomBehaviorMinistep(Beh, G, Mbeh, theta, i)
	}
	spreadHi = sqrt(variance(Beh.values))

	// --- effect OFF: theta=0, pure random walk ---
	rseed(975318)
	Beh = SaomBehavior()
	Beh.init(ceil(runiform(n,1)*5), 1, 5, 3)
	theta = 0
	for (t=1; t<=400; t++) {
		i = ceil(runiform(1,1)*n)
		picked = SaomBehaviorMinistep(Beh, G, Mbeh, theta, i)
	}
	spreadLo = sqrt(variance(Beh.values))

	printf("unit 26 direction: behavior SD after 400 ministeps with avalt on %6.3f, off %6.3f\n", spreadHi, spreadLo)
	assert(spreadHi < spreadLo)
	printf("unit 26 PASS: a strong positive avAlt coefficient pulls connected actors' own behavior values together (lower spread) relative to a pure random walk - the influence mechanism working as intended\n")
}

/* -------------------------------------------------------------------
   Joint (network + behavior) self-consistency recovery, matching the
   SAME standard unit 1c's own network-only estimator was certified
   against: simulate synthetic wave-2 data under a KNOWN joint theta,
   confirm SaomEstimateRMCoev() recovers it - not the ego-level
   brute-force methodology (that certifies the MINISTEP formulas above,
   already done), but the full three-phase estimator end to end.

   A REAL, disclosed finding from getting this test right, kept in the
   record rather than silently tuned away: an early attempt at n=20 (the
   same toy scale unit 1c's own network-only test uses successfully)
   made the joint estimator genuinely diverge for avAlt specifically
   (recovered coefficients off by two orders of magnitude, e.g. -145
   instead of a true value near 0.15). Directly diagnosed, not assumed
   fixed: the phase-1 Jacobian itself was confirmed well-conditioned
   (positive eigenvalues, sensible cross-term signs) and the simulator
   was confirmed to produce near-zero deviations when evaluated AT the
   true generating theta - ruling out a formula/scoring bug. The
   instability is a genuine small-sample identification problem specific
   to avAlt: with only ~10-20 total behavior ministep opportunities
   across a 20-actor network, Robbins-Monro's own iterative correction
   has too little signal to stay stable against avAlt's own
   self-reinforcing nonlinearity (a stronger pull begets a more
   deterministic ministep, which begets an even stronger apparent pull).
   At n=50 with proportionally more behavior activity, the identical code
   recovers sensible estimates with reasonable t-ratios - confirmed
   directly, not assumed - so this test uses n=50, not unit 1c's own
   n=16-20 scale.
   ------------------------------------------------------------------- */
void saom_test_unit26_coev_recover(real scalar n, real scalar seed) {
	class ErgmGraph scalar G1, G2
	class ErgmModel scalar M
	class SaomBehaviorModel scalar Mbeh
	class SaomBehavior scalar Beh
	class ErgmTermData scalar td1, td2
	struct SaomCoevResult scalar res
	struct SaomCoevFit scalar fit
	real rowvector thetaNetTrue, thetaBehTrue
	real colvector startvals, endvals
	real scalar i, j, t

	rseed(seed)
	G1 = ErgmGraph()
	G1.init(n, 1)
	for (t=1; t<=round(0.1*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G1.has_edge(i,j)) G1.toggle(i,j)
	}

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "avalt")

	startvals = ceil(runiform(n,1)*5)
	G2 = ErgmGraph()
	SaomCopyGraph(G1, G2)
	Beh = SaomBehavior()
	Beh.init(startvals, 1, 5, mean(startvals))

	thetaNetTrue = (-1.8, 0.6)
	thetaBehTrue = (0.1)
	res = SaomSimulateIntervalCoev(G2, M, thetaNetTrue, Beh, Mbeh, thetaBehTrue, 4, 3)
	endvals = Beh.values

	fit = SaomEstimateRMCoev(G1, G2, M, startvals, endvals, 1, 5, Mbeh, (0,0), (0), 100, 200, 0.2)

	printf("unit 26 coev recover: true thetaNet %6.3f %6.3f, recovered %6.3f %6.3f\n", thetaNetTrue[1], thetaNetTrue[2], fit.thetaNet[1], fit.thetaNet[2])
	printf("unit 26 coev recover: true thetaBeh %6.3f, recovered %6.3f\n", thetaBehTrue[1], fit.thetaBeh[1])
	printf("unit 26 coev recover: rateNet=%6.3f rateBeh=%6.3f\n", fit.rateNet, fit.rateBeh)

	assert(sign(fit.thetaNet[1]) == sign(thetaNetTrue[1]))
	assert(sign(fit.thetaNet[2]) == sign(thetaNetTrue[2]))
	assert(sign(fit.thetaBeh[1]) == sign(thetaBehTrue[1]))
	assert(abs(fit.thetaNet[1] - thetaNetTrue[1]) < 2.0)
	assert(abs(fit.thetaNet[2] - thetaNetTrue[2]) < 2.0)
	assert(abs(fit.thetaBeh[1] - thetaBehTrue[1]) < 2.0)
	assert(fit.rateNet > 0.5 & fit.rateNet < 10)
	assert(fit.rateBeh > 0.1 & fit.rateBeh < 10)

	printf("unit 26 PASS: SaomEstimateRMCoev() recovers the true joint (network+behavior) theta within loose tolerance, at a scale with enough behavior activity to identify avAlt reliably\n")
}

/* -------------------------------------------------------------------
   N-wave co-evolution (harmonisation unit 26, "extend it to N waves"
   per explicit user direction). Self-consistency recovery across
   THREE waves (two chained periods) - the co-evolution analogue of
   unit 17's own multi-wave recovery test, mirroring
   SaomEstimateRMMulti()'s own established "chain periods, pool theta
   by summation, keep rate per-period" pattern, now doubled across two
   variables (a separate network AND behavior rate per period).
   ------------------------------------------------------------------- */
void saom_test_unit26_coev_multi(real scalar n, real scalar seed) {
	class ErgmGraph scalar G1, G2, G3
	class ErgmModel scalar M
	class SaomBehaviorModel scalar Mbeh
	class SaomBehavior scalar Beh12, Beh23
	class ErgmTermData scalar td1, td2
	struct SaomCoevResult scalar res
	struct SaomCoevMultiFit scalar fit
	real rowvector thetaNetTrue, thetaBehTrue
	real colvector wave1vals, wave2vals, wave3vals
	pointer(class ErgmGraph scalar) rowvector Gwaves
	pointer(real colvector) rowvector Behwaves
	real scalar i, j, t

	rseed(seed)
	G1 = ErgmGraph()
	G1.init(n, 1)
	for (t=1; t<=round(0.1*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G1.has_edge(i,j)) G1.toggle(i,j)
	}

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	Mbeh = SaomBehaviorModel()
	Mbeh.init()
	Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "avalt")

	thetaNetTrue = (-1.8, 0.6)
	thetaBehTrue = (0.12)

	wave1vals = ceil(runiform(n,1)*5)

	// period 1: wave1 -> wave2
	G2 = ErgmGraph()
	SaomCopyGraph(G1, G2)
	Beh12 = SaomBehavior()
	Beh12.init(wave1vals, 1, 5, mean(wave1vals))
	res = SaomSimulateIntervalCoev(G2, M, thetaNetTrue, Beh12, Mbeh, thetaBehTrue, 4, 3)
	wave2vals = Beh12.values

	// period 2: wave2 -> wave3 (chained from wave2's own simulated end state)
	G3 = ErgmGraph()
	SaomCopyGraph(G2, G3)
	Beh23 = SaomBehavior()
	Beh23.init(wave2vals, 1, 5, mean(wave2vals))
	res = SaomSimulateIntervalCoev(G3, M, thetaNetTrue, Beh23, Mbeh, thetaBehTrue, 4, 3)
	wave3vals = Beh23.values

	Gwaves = (&G1, &G2, &G3)
	Behwaves = (&wave1vals, &wave2vals, &wave3vals)

	fit = SaomEstimateRMCoevMulti(Gwaves, M, Behwaves, 1, 5, Mbeh, (0,0), (0), 60, 150, 0.2)

	printf("unit 26 coev multi: true thetaNet %6.3f %6.3f, recovered %6.3f %6.3f\n", thetaNetTrue[1], thetaNetTrue[2], fit.thetaNet[1], fit.thetaNet[2])
	printf("unit 26 coev multi: true thetaBeh %6.3f, recovered %6.3f\n", thetaBehTrue[1], fit.thetaBeh[1])
	printf("unit 26 coev multi: ratesNet %6.3f %6.3f, ratesBeh %6.3f %6.3f\n", fit.ratesNet[1], fit.ratesNet[2], fit.ratesBeh[1], fit.ratesBeh[2])

	assert(sign(fit.thetaNet[1]) == sign(thetaNetTrue[1]))
	assert(sign(fit.thetaNet[2]) == sign(thetaNetTrue[2]))
	assert(sign(fit.thetaBeh[1]) == sign(thetaBehTrue[1]))
	assert(abs(fit.thetaNet[1] - thetaNetTrue[1]) < 2.0)
	assert(abs(fit.thetaNet[2] - thetaNetTrue[2]) < 2.0)
	assert(abs(fit.thetaBeh[1] - thetaBehTrue[1]) < 2.0)
	assert(fit.ratesNet[1] > 0.5 & fit.ratesNet[1] < 15)
	assert(fit.ratesNet[2] > 0.5 & fit.ratesNet[2] < 15)
	assert(fit.ratesBeh[1] > 0.1 & fit.ratesBeh[1] < 15)
	assert(fit.ratesBeh[2] > 0.1 & fit.ratesBeh[2] < 15)
	assert(cols(fit.ratesNet) == 2)
	assert(cols(fit.ratesBeh) == 2)
	assert(rows(fit.V) == 3 & cols(fit.V) == 3)

	printf("unit 26 PASS: SaomEstimateRMCoevMulti() recovers the true joint (network+behavior) theta within loose tolerance across 3 waves/2 chained periods, with separate per-period rates for both variables\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 33 (composition change - "joiners and leavers"):
   direct invariant check on SaomMinistep()/SaomSimulateInterval()/
   SaomSimulateIntervalScored()'s own new optional `present' parameter
   - an ABSENT actor's own dyads (as either row or column) must stay
   FROZEN at their starting value across the whole simulated interval,
   for every replicate, both simulators, not just "usually" - a hard
   invariant, checked exactly, not statistically.
   ------------------------------------------------------------------- */
void saom_test_unit33_presence(real scalar n, real scalar seed) {
	class ErgmGraph scalar G0, Gwork
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct SaomScoredResult scalar sres
	real colvector present
	real rowvector theta
	real scalar i, j, t, r, nedges0, steps

	rseed(seed)
	G0 = ErgmGraph()
	G0.init(n, 1)
	nedges0 = round(0.15 * n * (n-1))
	for (t=1; t<=nedges0; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	// mark actors 1, 2, and n absent (present=0) - everyone else present.
	present = J(n, 1, 1)
	present[1] = 0
	present[2] = 0
	present[n] = 0

	theta = (-1.0, 1.0)

	for (r=1; r<=100; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		steps = SaomSimulateInterval(Gwork, M, theta, 3, present)
		assert(steps > 0)
		for (i=1; i<=n; i++) {
			if (present[i] == 1) continue
			for (j=1; j<=n; j++) {
				if (i == j) continue
				assert(Gwork.has_edge(i,j) == G0.has_edge(i,j))
				assert(Gwork.has_edge(j,i) == G0.has_edge(j,i))
			}
		}
	}
	printf("unit 33 PASS: SaomSimulateInterval() with present() never toggles an absent actor's own dyads, over 100 replicates\n")

	for (r=1; r<=100; r++) {
		Gwork = ErgmGraph()
		SaomCopyGraph(G0, Gwork)
		sres = SaomSimulateIntervalScored(Gwork, M, theta, 3, present)
		assert(sres.steps > 0)
		assert(cols(sres.score) == M.nparam())
		for (i=1; i<=n; i++) {
			if (present[i] == 1) continue
			for (j=1; j<=n; j++) {
				if (i == j) continue
				assert(Gwork.has_edge(i,j) == G0.has_edge(i,j))
				assert(Gwork.has_edge(j,i) == G0.has_edge(j,i))
			}
		}
	}
	printf("unit 33 PASS: SaomSimulateIntervalScored() with present() never toggles an absent actor's own dyads, over 100 replicates\n")

	// backward-compatibility check: omitting `present' entirely still
	// behaves exactly as before (every pre-existing call site) - a
	// smoke check, not a new invariant.
	Gwork = ErgmGraph()
	SaomCopyGraph(G0, Gwork)
	steps = SaomSimulateInterval(Gwork, M, theta, 3)
	assert(steps > 0)
	printf("unit 33 PASS: SaomSimulateInterval()/SaomSimulateIntervalScored() omitting present() still work (backward compatible)\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 33: ground-truth recovery for SaomEstimateRM()
   WITH composition change - the standard methodology this whole
   project uses to certify an estimator (simulate wave2 from wave1
   under a KNOWN true theta via the already-certified
   SaomSimulateInterval(), now with `present' active throughout, then
   check the estimator recovers it), extended to also verify the
   absent actors' own dyads stay frozen in the GROUND-TRUTH simulation
   itself (not just in the isolated invariant check above).
   ------------------------------------------------------------------- */
void saom_test_unit33_recover(real scalar n, real scalar seed) {
	class ErgmGraph scalar G1, G2
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct SaomFit scalar fit
	real colvector present
	real rowvector thetaTrue
	real scalar i, j, t, steps

	rseed(seed)
	G1 = ErgmGraph()
	G1.init(n, 1)
	for (t=1; t<=round(0.12*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G1.has_edge(i,j)) G1.toggle(i,j)
	}

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	present = J(n, 1, 1)
	present[1] = 0
	present[n] = 0

	G2 = ErgmGraph()
	SaomCopyGraph(G1, G2)
	thetaTrue = (-1.5, 1.2)
	steps = SaomSimulateInterval(G2, M, thetaTrue, 4, present)
	assert(steps > 0)
	for (j=2; j<=n-1; j++) {
		assert(G2.has_edge(1,j) == G1.has_edge(1,j))
		assert(G2.has_edge(j,1) == G1.has_edge(j,1))
		assert(G2.has_edge(n,j) == G1.has_edge(n,j))
		assert(G2.has_edge(j,n) == G1.has_edge(j,n))
	}

	fit = SaomEstimateRM(G1, G2, M, (0,0), 5, 100, 200, 0.2, present)

	printf("unit 33 recover: true theta %6.3f %6.3f, recovered %6.3f %6.3f\n", thetaTrue[1], thetaTrue[2], fit.theta[1], fit.theta[2])
	printf("unit 33 recover: rate=%6.3f rate_se=%6.3f (expect rate_se==0, unrefined under composition change)\n", fit.rate, fit.rate_se)

	assert(sign(fit.theta[1]) == sign(thetaTrue[1]))
	assert(sign(fit.theta[2]) == sign(thetaTrue[2]))
	assert(abs(fit.theta[1] - thetaTrue[1]) < 1.5)
	assert(abs(fit.theta[2] - thetaTrue[2]) < 1.5)
	assert(fit.rate_se == 0)
	assert(fit.rate > 0)

	printf("unit 33 PASS: SaomEstimateRM() with present() recovers the true theta within loose tolerance, and correctly leaves the rate unrefined (composition change forces unconditional estimation)\n")
}

/* -------------------------------------------------------------------
   Harmonisation unit 33: ground-truth recovery for
   SaomEstimateRMMulti() (N-wave) WITH composition change - 3 waves/2
   periods, one actor absent for period 1 only (present at waves 1,2
   but not wave... - see the presentMat construction below), exercising
   the per-period `presentPd' derivation (present at BOTH endpoint
   waves) that SaomEstimateRMMulti() computes from the wave-indexed
   `presentMat' input.
   ------------------------------------------------------------------- */
void saom_test_unit33_recover_multi(real scalar n, real scalar seed) {
	class ErgmGraph scalar G1, G2, G3
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct SaomFit scalar fit
	pointer(class ErgmGraph scalar) rowvector Gwaves
	real matrix presentMat
	real rowvector thetaTrue
	real colvector present1
	real scalar i, j, t

	rseed(seed)
	G1 = ErgmGraph()
	G1.init(n, 1)
	for (t=1; t<=round(0.12*n*(n-1)); t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G1.has_edge(i,j)) G1.toggle(i,j)
	}

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))

	thetaTrue = (-1.4, 1.1)

	// actor 1 absent from wave 2 onward (present at wave 1 only) -
	// period 1 (wave1->wave2) therefore has actor 1 absent (present at
	// wave1=1 AND wave2=0 -> AND=0); period 2 (wave2->wave3) has actor 1
	// absent at BOTH endpoints too (0 AND 0 = 0) - absent for the WHOLE
	// simulated span from wave 2 onward, matching "left after wave 1".
	presentMat = J(n, 3, 1)
	presentMat[1,2] = 0
	presentMat[1,3] = 0

	present1 = presentMat[.,1] :* presentMat[.,2]		// period 1's own presence
	G2 = ErgmGraph()
	SaomCopyGraph(G1, G2)
	SaomSimulateInterval(G2, M, thetaTrue, 4, present1)
	// actor 1's own row/col frozen at wave1's own value going forward -
	// wave2's own data must show that (matches the "carry-forward"
	// convention this package documents, docs/SAOM_ROADMAP.md unit-33).

	G3 = ErgmGraph()
	SaomCopyGraph(G2, G3)
	SaomSimulateInterval(G3, M, thetaTrue, 4, present1)		// period 2: same presence (still absent)

	Gwaves = (&G1, &G2, &G3)
	fit = SaomEstimateRMMulti(Gwaves, M, (0,0), 80, 150, 0.2, presentMat)

	printf("unit 33 recover multi: true theta %6.3f %6.3f, recovered %6.3f %6.3f\n", thetaTrue[1], thetaTrue[2], fit.theta[1], fit.theta[2])
	printf("unit 33 recover multi: rates %6.3f %6.3f, rate_ses %6.3f %6.3f (expect both 0)\n", fit.rates[1], fit.rates[2], fit.rate_ses[1], fit.rate_ses[2])

	assert(sign(fit.theta[1]) == sign(thetaTrue[1]))
	assert(sign(fit.theta[2]) == sign(thetaTrue[2]))
	assert(abs(fit.theta[1] - thetaTrue[1]) < 1.5)
	assert(abs(fit.theta[2] - thetaTrue[2]) < 1.5)
	assert(fit.rate_ses[1] == 0 & fit.rate_ses[2] == 0)
	assert(fit.rates[1] > 0 & fit.rates[2] > 0)

	printf("unit 33 PASS: SaomEstimateRMMulti() with presentMat() recovers the true theta within loose tolerance across 3 waves/2 periods, correctly leaving both periods' own rates unrefined\n")
}

end

mata:
mata set matastrict off

n = 16
rseed(20260828)
attr = J(n,1,0)
for (k=1; k<=n; k++) attr[k] = mod(k,3)

saom_test_unit1a(n, attr)
saom_test_unit1b(n, attr)

rseed(31415926)
saom_test_unit1c(n, attr)

rseed(24681012)
saom_test_unit2(n, attr)

saom_test_unit3_certify(14, 13579)
saom_test_unit3_direction(16)

saom_test_unit4_certify(14, 24680)
saom_test_unit4_direction(16)

saom_test_unit5_certify(14, 97531)
saom_test_unit5_direction(16)

saom_test_unit9_certify(14, 112233, attr[1..14])
saom_test_unit9_direction(16, attr)

rseed(13571113)
saom_test_unit18_cov(20)

saom_test_unit22_certify(14, 24681357)
saom_test_unit22_direction(16)

saom_test_unit23_certify(14, 35791113)
saom_test_unit23_direction(16)

saom_test_unit25_meancheck()
saom_test_unit25_certify(14, 15935779)
saom_test_unit25_direction(16)

saom_test_unit26_linear_certify(14, 24681012)
saom_test_unit26_quad_certify(14, 13571113)
saom_test_unit26_avalt_certify(14, 97315115)
saom_test_unit26_avsim_certify(14, 24681012)
saom_test_unit26_simmean_certify(14, 13571113)
saom_test_unit26_ministep_dir(16)
saom_test_unit26_coev_recover(50, 42)
saom_test_unit26_coev_multi(30, 7)

saom_test_unit33_presence(20, 24681012)
saom_test_unit33_recover(30, 13571113)
saom_test_unit33_recover_multi(25, 97315115)

end
