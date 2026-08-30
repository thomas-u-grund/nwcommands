cscript

do unw_ergm.do

/*
	Certifies the native (C) MCMC backend (harmonisation unit 83,
	docs/CERTIFICATION.md) against its own Mata reference implementation,
	per this unit's own explicit "correctness before speed" and "full
	MCMC cross-certification" requirements.

	Extended (harmonisation unit 91 follow-on, "move all effects to C" -
	relaxing the original narrow four-term scope per explicit user
	instruction, since mixing gwesp with any other term used to force
	the WHOLE model back onto the Mata sampler): the native term set now
	also covers the full dyad-independent attribute/factor family
	(nodecov/nodeicov/nodeocov/absdist/nodematch_diff/nodefactor/
	nodeofactor/nodeifactor/sender/receiver/nodemix), the GW-degree
	family (gwdegree/gwodegree/gwidegree), the full degree-COUNT family,
	the undirected shared-partner family (gwdsp/gwnsp/esp/dsp/triangle),
	the full DIRECTED shared-partner family under R ergm's OTP default
	(unit 92 wave 4) - gwesp/gwdsp/gwnsp/esp/dsp plus
	ctriple/transitiveties/cyclicalties - and (this update) the
	remaining four directed shared-partner definitions, ITP/OSP/ISP/RTP,
	for gwesp/gwdsp/gwnsp/esp/dsp, and (harmonisation unit 160) the
	dyadic-covariate family `edgecov`/`hamming` - see unw_ergm.do's own
	ErgmNativeSetup() header comment for the complete current list.
	`triangle`/`ctriple`/`edgecov`, each used as the "reject probe" at
	various earlier points as the native term set grew, are now ALL
	native-eligible - every term this package implements is. The only
	remaining fallback reason is exceeding the native backend's own
	fixed capacity limits (maxcols/maxattr/maxcovmat), used as this
	test's own reject probe instead (see the MAXCOVMAT-overflow case
	below).

	(1) ErgmNativeSetup() eligibility is exactly what the model's own
	    term list should produce - accept every currently-native term
	    (individually and mixed together in one model, which the
	    original narrow-scope version of this test never needed to
	    check since every native term used to be dyad-independent or
	    gwesp alone), including directed (OTP) gwesp/gwdsp/gwnsp/esp/dsp,
	    ctriple/transitiveties/cyclicalties (unit 92 wave 4), and
	    edgecov/hamming (unit 160); and reject a model that exceeds the
	    native backend's own fixed capacity limits.
	(2) The native and Mata backends, run on the SAME starting network at
	    the SAME theta with the SAME burnin/interval/samplesize, produce
	    statistically indistinguishable sampled sufficient-statistic
	    distributions - not identical trajectories (the two backends use
	    independent RNG streams by design, see native/ergm_mcmc.c's own
	    header comment), but means that agree within several Monte Carlo
	    standard errors. Covered for the original two term-family shapes
	    (directed dyad-independent edges+mutual+nodematch; undirected
	    gwesp) PLUS a representative case from each newly-native family:
	    a mixed gwesp+nodefactor+nodecov model (exactly the "gwesp mixed
	    with another term" case that used to force a full Mata fallback,
	    now the primary motivation for this whole unit), nodemix,
	    nodematch_diff, and the three GW-degree variants.
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
	class ErgmTermData scalar td1, td2, td3, td4, td5, td6, td7, tdmany
	real colvector attr
	real scalar i

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

	// directed (OTP) gwesp is now ALSO native-eligible (unit 92 wave 4) -
	// this used to be the "must be rejected" case that caught the
	// wrongly-accepted bug this unit's earlier wave found and fixed;
	// now that OTP has its own dedicated native termcode (32), it must
	// be accepted, and cscripts/test_nwergm_native.do's equivalence
	// suite below is what actually certifies the OTP formula itself.
	M = ErgmModel()
	M.init()
	td6 = ErgmTermData()
	td6.decay = 0.5
	td6.sptype = "OTP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td6, ("gwesp_0.5"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	// nodecov IS now in the native term set (unlike the original
	// narrow-scope version of this test) - a mixed gwesp+nodecov model
	// (exactly the case that used to force a full Mata fallback) must
	// be accepted.
	M = ErgmModel()
	M.init()
	td5 = ErgmTermData()
	td5.decay = 0.5
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td5, ("gwesp_0.5"))
	td7 = ErgmTermData()
	td7.attr = attr
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td7, ("nodecov_age"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	// harmonisation unit 160: edgecov/hamming are now native-eligible too
	// (the last remaining gap in the "move all effects to C" migration -
	// see unw_ergm.do's own ErgmNativeSetup() header comment) - must be
	// ACCEPTED, individually and mixed with an ordinary attribute term,
	// and must populate the new covmat wire fields correctly.
	M = ErgmModel()
	M.init()
	td5 = ErgmTermData()
	td5.edgecovmat = J(5,5,0.3)
	M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), td5, ("edgecov"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)
	assert(cols(M.native_covmatstack) == 5)
	assert(M.native_covidx[1] == 1)

	M = ErgmModel()
	M.init()
	td5 = ErgmTermData()
	td5.edgecovmat = (0,1,0,1,0) \ (1,0,1,0,1) \ (0,1,0,1,0) \ (1,0,1,0,1) \ (0,1,0,1,0)
	M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), td5, ("hamming"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	// mixed model: edgecov + hamming + an ordinary attribute term in the
	// SAME model - two DISTINCT covmat blocks must be registered (not
	// collapsed into one), each with its own 1-based covidx, alongside
	// nodecov's own ordinary attrmat slot - exercises native_covidx/
	// native_attridx staying independently correct when both mechanisms
	// are in play together.
	M = ErgmModel()
	M.init()
	td5 = ErgmTermData()
	td5.edgecovmat = J(5,5,0.3)
	M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), td5, ("edgecov"))
	td6 = ErgmTermData()
	td6.edgecovmat = (0,1,0,1,0) \ (1,0,1,0,1) \ (0,1,0,1,0) \ (1,0,1,0,1) \ (0,1,0,1,0)
	M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), td6, ("hamming"))
	td7 = ErgmTermData()
	td7.attr = attr
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td7, ("nodecov_age"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)
	assert(cols(M.native_covmatstack) == 10)
	assert(M.native_covidx[1] == 1)
	assert(M.native_covidx[2] == 2)
	assert(M.native_covidx[3] == 0)
	assert(M.native_attridx[3] == 1)

	// exceeding native's own fixed MAXCOVMAT capacity (8, native/
	// ergm_mcmc.c) must still fall back to Mata gracefully, exactly like
	// exceeding maxattr/maxcols already does elsewhere in this file -
	// the only genuine remaining fallback reason now that every term is
	// individually native-eligible.
	M = ErgmModel()
	M.init()
	for (i=1; i<=9; i++) {
		tdmany = ErgmTermData()
		tdmany.edgecovmat = J(5,5,0.1*i)
		M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), tdmany, ("edgecov"+strofreal(i)))
	}
	assert(ErgmNativeSetup(M, 1) == 0)
	assert(M.native_enabled == 0)

	// term-expansion waves 8-9 (ITP/OSP/ISP/RTP directed shared-partner
	// types): all four now have their own dedicated native termcodes
	// (40-59, via ErgmNativeSPCode()) alongside OTP (32-36) and
	// blank/UTP (4/27-30) - a gwesp/gwdsp/gwnsp/esp/dsp term carrying
	// any of these five sptype values must be ACCEPTED (this used to be
	// the "must reject" bailout-probe case when only OTP was native;
	// now that every directed type has a dedicated termcode, rejecting
	// any of them would be the bug).
	M = ErgmModel()
	M.init()
	td6 = ErgmTermData()
	td6.decay = 0.5
	td6.sptype = "ITP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td6, ("gwesp_0.5"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	M = ErgmModel()
	M.init()
	td6 = ErgmTermData()
	td6.decay = 0.5
	td6.sptype = "OSP"
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), td6, ("gwdsp_0.5"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	M = ErgmModel()
	M.init()
	td6 = ErgmTermData()
	td6.levels = (1)
	td6.sptype = "ISP"
	M.addterm("dsp", 1, &stat_dsp(), &change_dsp(), td6, ("dsp1"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

	M = ErgmModel()
	M.init()
	td6 = ErgmTermData()
	td6.decay = 0.5
	td6.sptype = "RTP"
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), td6, ("gwnsp_0.5"))
	assert(ErgmNativeSetup(M, 1) == 1)
	assert(M.native_enabled == 1)

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
	// a genuinely SATURATED statistic (e.g. a degree-range term whose
	// threshold every node satisfies in every single visited state, on
	// both chains) has EXACTLY zero variance/se - a real, if unlikely,
	// possibility for some (network, term, theta) combinations, not
	// just a hypothetical: hit directly while authoring this suite's
	// own odegrange/idegrange test with a saturated range. A strict
	// `< tol_sd_mult*0' comparison fails even on an EXACT match (0 < 0
	// is false), so floor `se' at a tiny epsilon - genuine disagreement
	// on an otherwise-saturated statistic (which would mean a real
	// native/Mata formula divergence) still fails clearly, since any
	// real discrepancy there is astronomically larger than 1e-8.
	se = se :+ 1e-8

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
	// must match the native run's own last reported row. A pure 1e-6
	// ABSOLUTE tolerance (this test's original bound, calibrated on
	// edges/mutual/nodematch/gwesp - integer-valued or, for gwesp on
	// that one run, coincidentally near machine precision) turned out
	// too tight once the GW-degree family was added (harmonisation unit
	// 91 follow-on): comparing a value ACCUMULATED INCREMENTALLY in C
	// (chg[] summed once per accepted toggle, ~12,000 times across a
	// full burnin+sampling run) against the SAME statistic RECOMPUTED
	// FROM SCRATCH in Mata is comparing two independent floating-point
	// call paths through exp()/pow() - C's libm and Mata's own internal
	// math are not guaranteed bit-identical, and even a per-call bias
	// on the order of 1e-9 compounds roughly LINEARLY (not as sqrt(n),
	// since the bias is systematic, not random noise) across thousands
	// of calls into a real, expected, non-bug discrepancy - confirmed
	// directly: gwdegree measured at 3.57e-05 absolute against a
	// statistic of magnitude ~145 (a RELATIVE error of ~2.5e-7, nowhere
	// near what an actual formula bug would produce). A relative
	// component (1e-6 of the statistic's own magnitude) is added to the
	// original absolute bound - this preserves the exact same tight
	// 1e-6 guarantee for near-zero/integer-valued statistics
	// (edges/mutual/nodematch keep no less strict a check than before)
	// while giving real-valued GW-family statistics the margin their
	// own accumulation error profile genuinely needs, with several
	// times the observed drift still comfortably inside the bound (so a
	// genuine formula bug - which would show up as a percent-level or
	// larger discrepancy, six orders of magnitude bigger - is still
	// caught).
	obs = M.full_statistic(Gnative)
	checkstat = max(abs(obs - samp_native[samplesize, .]))
	assert(checkstat < 1e-6 + 1e-6 * max(abs(obs)))

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

// --- undirected: edges + gwesp + nodefactor + nodecov, MIXED in one
//     model - exactly the case this whole unit exists to fix (gwesp
//     used to force a full Mata fallback the instant ANY other term,
//     however simple, was mixed in). ---
void run_mixed_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdg, tdf, tdc
	real colvector cat, cov
	real scalar n, i

	n = 80
	cat = J(n, 1, 0)
	cov = J(n, 1, 0)
	for (i=1; i<=n; i++) {
		cat[i] = mod(i, 3)
		cov[i] = mod(i, 7) - 3
	}

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))
	tdf = ErgmTermData()
	tdf.attr = cat
	tdf.levels = (0\1\2)
	M.addterm("nodefactor", 3, &stat_nodefactor(), &change_nodefactor(), tdf, ("nf0","nf1","nf2"))
	tdc = ErgmTermData()
	tdc.attr = cov
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), tdc, ("nodecov_x"))

	test_equivalence("undirected gwesp+nodefactor+nodecov (mixed)", n, 4, 0, M,
		(-2.0, 0.3, 0.1, -0.05, 0.02, 0.01), 2000, 5, 2000, 6)
}
run_mixed_test()

// --- undirected: edges + nodemix (full categorical mixing matrix) ---
void run_nodemix_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdx
	real colvector cat
	real matrix pairs
	real scalar n, i

	n = 80
	cat = J(n, 1, 0)
	for (i=1; i<=n; i++) cat[i] = mod(i, 3)
	pairs = (0,0 \ 0,1 \ 0,2 \ 1,1 \ 1,2 \ 2,2)

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdx = ErgmTermData()
	tdx.attr = cat
	tdx.levelpairs = pairs
	M.addterm("nodemix", 6, &stat_nodemix(), &change_nodemix(), tdx, ("mx1","mx2","mx3","mx4","mx5","mx6"))

	test_equivalence("undirected edges+nodemix", n, 4, 0, M,
		(-2.5, 0.2, -0.1, 0.15, 0.05, -0.2, 0.1), 2000, 5, 2000, 6)
}
run_nodemix_test()

// --- undirected: edges + nodematch_diff (differential homophily) ---
void run_nodematchdiff_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdd
	real colvector cat
	real scalar n, i

	n = 80
	cat = J(n, 1, 0)
	for (i=1; i<=n; i++) cat[i] = mod(i, 3)

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdd = ErgmTermData()
	tdd.attr = cat
	tdd.levels = (0\1\2)
	M.addterm("nodematch_diff", 3, &stat_nodematch_diff(), &change_nodematch_diff(), tdd, ("nmd0","nmd1","nmd2"))

	test_equivalence("undirected edges+nodematch_diff", n, 4, 0, M,
		(-2.5, 0.3, 0.2, 0.4), 2000, 5, 2000, 6)
}
run_nodematchdiff_test()

// --- undirected: edges + gwdegree ---
void run_gwdegree_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdg
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdg = ErgmTermData()
	tdg.decay = 0.6
	M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), tdg, ("gwdegree_0.6"))

	test_equivalence("undirected edges+gwdegree", n, 4, 0, M,
		(-2.0, 0.2), 2000, 5, 2000, 6)
}
run_gwdegree_test()

// --- directed: edges + mutual + gwodegree + gwidegree ---
void run_gwoidegree_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdo, tdi
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdo = ErgmTermData()
	tdo.decay = 0.5
	M.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), tdo, ("gwodegree_0.5"))
	tdi = ErgmTermData()
	tdi.decay = 0.5
	M.addterm("gwidegree", 1, &stat_gwidegree(), &change_gwidegree(), tdi, ("gwidegree_0.5"))

	test_equivalence("directed edges+mutual+gwodegree+gwidegree", n, 4, 1, M,
		(-2.2, 0.4, 0.15, 0.15), 2000, 5, 2000, 6)
}
run_gwoidegree_test()

// --- degree-count family (harmonisation unit 92 continuation): needed
//     no new attribute-array plumbing, just the outdeg/indeg
//     bookkeeping already added for gwodegree/gwidegree above plus two
//     direct C ports (_ergm_choose()->ergm_choose(),
//     _ergm_inrange()->in_range()). ---

// --- undirected: edges + degree(2,3) + concurrent ---
void run_degree_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdd, tdc
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdd = ErgmTermData()
	tdd.levels = (2\3)
	M.addterm("degree", 2, &stat_degree(), &change_degree(), tdd, ("deg2","deg3"))
	tdc = ErgmTermData()
	M.addterm("concurrent", 1, &stat_concurrent(), &change_concurrent(), tdc, ("concurrent"))

	test_equivalence("undirected edges+degree(2,3)+concurrent", n, 4, 0, M,
		(-2.0, 0.2, 0.1, 0.05), 2000, 5, 2000, 6)
}
run_degree_test()

// --- directed: edges + mutual + odegree(2) + idegree(2) ---
void run_odegree_idegree_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdo, tdi
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdo = ErgmTermData()
	tdo.levels = (2)
	M.addterm("odegree", 1, &stat_odegree(), &change_odegree(), tdo, ("odeg2"))
	tdi = ErgmTermData()
	tdi.levels = (2)
	M.addterm("idegree", 1, &stat_idegree(), &change_idegree(), tdi, ("ideg2"))

	test_equivalence("directed edges+mutual+odegree(2)+idegree(2)", n, 4, 1, M,
		(-2.2, 0.4, 0.1, 0.1), 2000, 5, 2000, 6)
}
run_odegree_idegree_test()

// --- undirected: edges + kstar(2,3) ---
void run_kstar_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdk
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdk = ErgmTermData()
	tdk.levels = (2\3)
	M.addterm("kstar", 2, &stat_kstar(), &change_kstar(), tdk, ("k2","k3"))

	test_equivalence("undirected edges+kstar(2,3)", n, 4, 0, M,
		(-2.0, 0.05, -0.01), 2000, 5, 2000, 6)
}
run_kstar_test()

// --- directed: edges + mutual + ostar(2) + istar(2) ---
void run_ostar_istar_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdo, tdi
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdo = ErgmTermData()
	tdo.levels = (2)
	M.addterm("ostar", 1, &stat_ostar(), &change_ostar(), tdo, ("ostar2"))
	tdi = ErgmTermData()
	tdi.levels = (2)
	M.addterm("istar", 1, &stat_istar(), &change_istar(), tdi, ("istar2"))

	test_equivalence("directed edges+mutual+ostar(2)+istar(2)", n, 4, 1, M,
		(-2.2, 0.4, 0.05, 0.05), 2000, 5, 2000, 6)
}
run_ostar_istar_test()

// --- undirected: edges + degrange(0,2) (an open-ended upper bound,
//     the "to=." sentinel-marshalling case) ---
void run_degrange_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdr
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdr = ErgmTermData()
	tdr.levelpairs = (0,2 \ 2,.)
	M.addterm("degrange", 2, &stat_degrange(), &change_degrange(), tdr, ("dr1","dr2"))

	test_equivalence("undirected edges+degrange(0,2 / 2,.)", n, 4, 0, M,
		(-2.0, 0.1, 0.15), 2000, 5, 2000, 6)
}
run_degrange_test()

// --- directed: edges + mutual + odegrange(0,1) + idegrange(0,1) - i.e.
//     out-/in-ISOLATE counts, a genuinely variable statistic across the
//     chain (deliberately NOT an open-ended-upper-bound range like
//     (1,.): on this network/degree combination that range is SATURATED
//     - every node has out-/in-degree >= 1 in EVERY visited state, a
//     literally zero-variance statistic that breaks the SE-based
//     tolerance check below with a strict 0 < 0 comparison, confirmed
//     directly by an earlier version of this test hitting exactly that
//     failure mode: mata_mean=native_mean=80.0000 (=n) with se=0.0000
//     exactly - not a functional bug, a degenerate test-design choice,
//     fixed by picking a range with real within-chain variability
//     instead). ---
void run_odegrange_idegrange_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdo, tdi
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdo = ErgmTermData()
	tdo.levelpairs = (0,1)
	M.addterm("odegrange", 1, &stat_odegrange(), &change_odegrange(), tdo, ("odr0"))
	tdi = ErgmTermData()
	tdi.levelpairs = (0,1)
	M.addterm("idegrange", 1, &stat_idegrange(), &change_idegrange(), tdi, ("idr0"))

	test_equivalence("directed edges+mutual+odegrange(0,1)+idegrange(0,1)", n, 4, 1, M,
		(-2.2, 0.4, 0.1, 0.1), 2000, 5, 2000, 6)
}
run_odegrange_idegrange_test()

// --- undirected shared-partner family beyond gwesp (harmonisation
//     unit 92, wave 3): gwdsp/gwnsp/esp/dsp/triangle. All reuse the
//     EXISTING adj[]/common_neighbors() infrastructure gwesp already
//     built - no new graph representation needed, only new change-
//     statistic formulas (direct ports of their own Mata change_*()
//     functions). Directed (OTP) variants and ctriple/transitiveties/
//     cyclicalties remain a documented follow-on (need a genuinely new
//     directed-adjacency structure in C, not yet built). ---

// --- undirected: edges + gwesp + gwdsp + gwnsp (mixed - exercises the
//     gwnsp = gwdsp - gwesp composition dispatch in native/ergm_mcmc.c
//     too, not just in Mata) ---
void run_gwdsp_gwnsp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdg, tdd, tdn
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))
	tdd = ErgmTermData()
	tdd.decay = 0.5
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), tdd, ("gwdsp_0.5"))
	tdn = ErgmTermData()
	tdn.decay = 0.5
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), tdn, ("gwnsp_0.5"))

	test_equivalence("undirected edges+gwesp+gwdsp+gwnsp (mixed)", n, 4, 0, M,
		(-2.0, 0.2, 0.02, 0.02), 2000, 5, 2000, 6)
}
run_gwdsp_gwnsp_test()

// --- undirected: edges + esp(0,1,2) + dsp(1) ---
void run_esp_dsp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tde3, tdd1
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tde3 = ErgmTermData()
	tde3.levels = (0\1\2)
	M.addterm("esp", 3, &stat_esp(), &change_esp(), tde3, ("esp0","esp1","esp2"))
	tdd1 = ErgmTermData()
	tdd1.levels = (1)
	M.addterm("dsp", 1, &stat_dsp(), &change_dsp(), tdd1, ("dsp1"))

	test_equivalence("undirected edges+esp(0,1,2)+dsp(1)", n, 4, 0, M,
		(-2.0, 0.05, 0.05, 0.05, 0.02), 2000, 5, 2000, 6)
}
run_esp_dsp_test()

// --- undirected: edges + triangle ---
void run_triangle_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdt
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdt = ErgmTermData()
	M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), tdt, ("triangle"))

	test_equivalence("undirected edges+triangle", n, 4, 0, M,
		(-2.0, 0.05), 2000, 5, 2000, 6)
}
run_triangle_test()

// --- directed shared-partner family (harmonisation unit 92, wave 4):
//     the OTP mode of gwesp/gwdsp/gwnsp/esp/dsp (`td.sptype = "OTP"',
//     exactly how nwergm.ado sets it for a directed network) plus
//     ctriple/transitiveties/cyclicalties, all backed by the new
//     outadj[]/inadj[]/common_neighbors_otp() infrastructure in
//     native/ergm_mcmc.c. ---

// --- directed: edges + mutual + gwesp(OTP) ---
void run_gwesp_otp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdg
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	tdg.sptype = "OTP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))

	test_equivalence("directed edges+mutual+gwesp(OTP)", n, 4, 1, M,
		(-2.2, 0.4, 0.2), 2000, 5, 2000, 6)
}
run_gwesp_otp_test()

// --- directed: edges + mutual + gwdsp(OTP) + gwnsp(OTP) (mixed -
//     exercises the change_gwdsp_otp()-minus-change_gwesp_otp()
//     composition dispatch for gwnsp's own OTP mode too) ---
void run_gwdsp_gwnsp_otp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdd, tdn
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdd = ErgmTermData()
	tdd.decay = 0.5
	tdd.sptype = "OTP"
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), tdd, ("gwdsp_0.5"))
	tdn = ErgmTermData()
	tdn.decay = 0.5
	tdn.sptype = "OTP"
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), tdn, ("gwnsp_0.5"))

	test_equivalence("directed edges+mutual+gwdsp(OTP)+gwnsp(OTP) (mixed)", n, 4, 1, M,
		(-2.2, 0.4, 0.02, 0.02), 2000, 5, 2000, 6)
}
run_gwdsp_gwnsp_otp_test()

// --- directed: edges + mutual + esp(OTP)(0,1) + dsp(OTP)(1) ---
void run_esp_dsp_otp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tde2, tdd1
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tde2 = ErgmTermData()
	tde2.levels = (0\1)
	tde2.sptype = "OTP"
	M.addterm("esp", 2, &stat_esp(), &change_esp(), tde2, ("esp0","esp1"))
	tdd1 = ErgmTermData()
	tdd1.levels = (1)
	tdd1.sptype = "OTP"
	M.addterm("dsp", 1, &stat_dsp(), &change_dsp(), tdd1, ("dsp1"))

	test_equivalence("directed edges+mutual+esp(OTP)(0,1)+dsp(OTP)(1)", n, 4, 1, M,
		(-2.2, 0.4, 0.05, 0.05, 0.02), 2000, 5, 2000, 6)
}
run_esp_dsp_otp_test()

// --- directed: edges + mutual + ctriple ---
void run_ctriple_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdc
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdc = ErgmTermData()
	M.addterm("ctriple", 1, &stat_ctriple(), &change_ctriple(), tdc, ("ctriple"))

	test_equivalence("directed edges+mutual+ctriple", n, 4, 1, M,
		(-2.2, 0.4, 0.05), 2000, 5, 2000, 6)
}
run_ctriple_test()

// --- directed: edges + mutual + transitiveties + cyclicalties ---
void run_transties_cycties_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdt, tdc
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdt = ErgmTermData()
	M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), tdt, ("transitiveties"))
	tdc = ErgmTermData()
	M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), tdc, ("cyclicalties"))

	test_equivalence("directed edges+mutual+transitiveties+cyclicalties", n, 4, 1, M,
		(-2.2, 0.4, 0.1, 0.1), 2000, 5, 2000, 6)
}
run_transties_cycties_test()

// --- ITP/OSP/ISP/RTP native expansion (this update): the four
//     remaining directed shared-partner definitions, backed by
//     common_neighbors_itp()/_osp()/_isp()/_rtp() and their own
//     change_*_TYPE() functions in native/ergm_mcmc.c, all reusing
//     wave 4's own outadj[]/inadj[] - no new graph-level state. One
//     representative equivalence case per type, each mixing the
//     shared-partner term with edges+mutual exactly like the OTP cases
//     above, plus one esp/dsp case (RTP only, as the newest and
//     structurally most different of the four - its own htedge gate is
//     the part most likely to silently diverge between the Mata and
//     native ports if either were transcribed wrong). ---

// --- directed: edges + mutual + gwesp(ITP) ---
void run_gwesp_itp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdg
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	tdg.sptype = "ITP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))

	test_equivalence("directed edges+mutual+gwesp(ITP)", n, 4, 1, M,
		(-2.2, 0.4, 0.2), 2000, 5, 2000, 6)
}
run_gwesp_itp_test()

// --- directed: edges + mutual + gwdsp(OSP) + gwnsp(OSP) (mixed) ---
void run_gwdsp_gwnsp_osp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdd, tdn
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdd = ErgmTermData()
	tdd.decay = 0.5
	tdd.sptype = "OSP"
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), tdd, ("gwdsp_0.5"))
	tdn = ErgmTermData()
	tdn.decay = 0.5
	tdn.sptype = "OSP"
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), tdn, ("gwnsp_0.5"))

	test_equivalence("directed edges+mutual+gwdsp(OSP)+gwnsp(OSP) (mixed)", n, 4, 1, M,
		(-2.2, 0.4, 0.02, 0.02), 2000, 5, 2000, 6)
}
run_gwdsp_gwnsp_osp_test()

// --- directed: edges + mutual + esp(ISP)(0,1) + dsp(ISP)(1) ---
void run_esp_dsp_isp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tde2, tdd1
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tde2 = ErgmTermData()
	tde2.levels = (0\1)
	tde2.sptype = "ISP"
	M.addterm("esp", 2, &stat_esp(), &change_esp(), tde2, ("esp0","esp1"))
	tdd1 = ErgmTermData()
	tdd1.levels = (1)
	tdd1.sptype = "ISP"
	M.addterm("dsp", 1, &stat_dsp(), &change_dsp(), tdd1, ("dsp1"))

	test_equivalence("directed edges+mutual+esp(ISP)(0,1)+dsp(ISP)(1)", n, 4, 1, M,
		(-2.2, 0.4, 0.05, 0.05, 0.02), 2000, 5, 2000, 6)
}
run_esp_dsp_isp_test()

// --- directed: edges + mutual + gwesp(RTP) - RTP's own htedge gate
//     (toggling i->j only affects other dyads when j->i already
//     exists) is the part most likely to silently diverge between the
//     Mata and native ports, so this is the single most important
//     equivalence case in this whole added block. ---
void run_gwesp_rtp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdg
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdg = ErgmTermData()
	tdg.decay = 0.5
	tdg.sptype = "RTP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tdg, ("gwesp_0.5"))

	test_equivalence("directed edges+mutual+gwesp(RTP)", n, 4, 1, M,
		(-2.2, 0.4, 0.2), 2000, 5, 2000, 6)
}
run_gwesp_rtp_test()

// --- directed: edges + mutual + gwdsp(RTP) + gwnsp(RTP) (mixed) ---
void run_gwdsp_gwnsp_rtp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdd, tdn
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdd = ErgmTermData()
	tdd.decay = 0.5
	tdd.sptype = "RTP"
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), tdd, ("gwdsp_0.5"))
	tdn = ErgmTermData()
	tdn.decay = 0.5
	tdn.sptype = "RTP"
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), tdn, ("gwnsp_0.5"))

	test_equivalence("directed edges+mutual+gwdsp(RTP)+gwnsp(RTP) (mixed)", n, 4, 1, M,
		(-2.2, 0.4, 0.02, 0.02), 2000, 5, 2000, 6)
}
run_gwdsp_gwnsp_rtp_test()

// --- directed: edges + mutual + esp(RTP)(0,1) + dsp(RTP)(1) ---
void run_esp_dsp_rtp_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tde2, tdd1
	real scalar n

	n = 80
	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tde2 = ErgmTermData()
	tde2.levels = (0\1)
	tde2.sptype = "RTP"
	M.addterm("esp", 2, &stat_esp(), &change_esp(), tde2, ("esp0","esp1"))
	tdd1 = ErgmTermData()
	tdd1.levels = (1)
	tdd1.sptype = "RTP"
	M.addterm("dsp", 1, &stat_dsp(), &change_dsp(), tdd1, ("dsp1"))

	test_equivalence("directed edges+mutual+esp(RTP)(0,1)+dsp(RTP)(1)", n, 4, 1, M,
		(-2.2, 0.4, 0.05, 0.05, 0.02), 2000, 5, 2000, 6)
}
run_esp_dsp_rtp_test()

// --- harmonisation unit 160: edgecov/hamming, the last remaining gap
//     in the native migration, ported to native/ergm_mcmc.c via a new
//     dedicated "covmat" wire mechanism (native_covidx/
//     native_covmatstack on ErgmModel) since a dense n x n dyadic
//     covariate matrix is a genuinely different shape from every
//     per-node attribute array native already handles. Mixed with
//     mutual (dyad-dependent) and nodecov (an ordinary attrmat-based
//     term) in one model - exercises native_covidx and native_attridx
//     staying independently correct side by side, and edgecov's own
//     TWO distinct reference matrices (edgecov's continuous covariate,
//     hamming's separate 0/1 reference) getting two separate covmat
//     blocks rather than being collapsed into one.
void run_edgecov_hamming_test(){
	class ErgmModel scalar M
	class ErgmTermData scalar tde, tdm, tdec, tdhm, tdn
	real scalar n, i, j
	real matrix covmat, refmat
	real colvector attr

	n = 80
	covmat = J(n, n, 0)
	refmat = J(n, n, 0)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			covmat[i,j] = mod(i+j, 3)
			refmat[i,j] = mod(i+j, 2)
		}
	}
	attr = mod((1::n), 4)

	M = ErgmModel()
	M.init()
	tde = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), tde, ("edges"))
	tdm = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), tdm, ("mutual"))
	tdec = ErgmTermData()
	tdec.edgecovmat = covmat
	M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), tdec, ("edgecov"))
	tdhm = ErgmTermData()
	tdhm.edgecovmat = refmat
	M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), tdhm, ("hamming"))
	tdn = ErgmTermData()
	tdn.attr = attr
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), tdn, ("nodecov"))

	test_equivalence("directed edges+mutual+edgecov+hamming+nodecov (mixed, unit 160)", n, 4, 1, M,
		(-2.5, 0.4, 0.05, 0.02, 0.01), 2000, 5, 2000, 6)
}
run_edgecov_hamming_test()

end
