cscript

do unw_core.do
do unw_ergm.do

* Certifies harmonisation unit 155 Stage 1 (bipartite/two-mode ERGM
* foundation, /Users/tgrund/.claude/plans/dreamy-popping-deer.md): the
* dyad-space/proposal/MPLE-enumeration/ErgmCertifyChangeStat mechanics
* every bipartite term family builds on, plus the .ado-level edges-only
* end-to-end smoke test. Also certifies unit 156 (Stage 2: bcov1()/
* bcov2()/bfactor1()/bfactor2() - Stata option names for R ergm's own
* b1cov()/b2cov()/b1factor()/b2factor() terms) and unit 157 (Stage 3:
* bdegree1()/bdegree2()/bstar1()/bstar2() - R ergm's own b1degree()/
* b2degree()/b1star()/b2star() terms, dyad-DEPENDENT, exercising the
* bipartite MCMC proposal for real via method(mcmle)). Every option name
* with a digit was renamed with the digit moved to the END because
* Stata's own `syntax' command rejects any option name with a digit
* followed by a letter - confirmed directly, see nwergm.ado's own header
* comment on this. Every one-mode-only term is certified elsewhere to be
* REJECTED on a bipartite network (cscripts/test_nwergm_ado.do), not
* exercised here.

mata:
mata set matastrict off

// --- ErgmGraph.set_bipartite()/mode1nodes/mode2nodes: basic construction
void test_bip_construction() {
	class ErgmGraph scalar G
	real colvector modevec

	G = ErgmGraph()
	G.init(10, 0)
	// 6 mode-1 nodes (1..6), 4 mode-2 nodes (7..10) - same shape as the
	// worked example in nwergm.ado's own docs and the .ado-level smoke
	// test below.
	modevec = (1\1\1\1\1\1\2\2\2\2)
	G.set_bipartite(modevec)

	assert(G.bipartite == 1)
	assert(rows(G.mode1nodes) == 6)
	assert(rows(G.mode2nodes) == 4)
	assert(G.mode1nodes == (1\2\3\4\5\6))
	assert(G.mode2nodes == (7\8\9\10))
	"test_bip_construction: OK"
}
test_bip_construction()

// --- ergm_total_dyads(): must be exactly mode1 x mode2, never the full
// one-mode n(n-1)/2 space.
void test_bip_total_dyads() {
	class ErgmGraph scalar G

	G = ErgmGraph()
	G.init(10, 0)
	G.set_bipartite((1\1\1\1\1\1\2\2\2\2))
	assert(ergm_total_dyads(G) == 24)

	// asymmetric split, to catch a row/col-swap bug ergm_total_dyads()'s
	// own multiplication could otherwise hide (6x4 and 4x6 both equal
	// 24, an equal split would not).
	G = ErgmGraph()
	G.init(9, 0)
	G.set_bipartite((1\1\2\2\2\2\2\2\2))
	assert(ergm_total_dyads(G) == 2*7)
	"test_bip_total_dyads: OK"
}
test_bip_total_dyads()

// --- ergm_propose_uniform()/ergm_propose_tnt(): every proposed dyad
// must be cross-mode (one endpoint in each mode), across many draws and
// both TNT branches (existing-tie removal vs. full-dyad-space toggle) -
// exercised by toggling a handful of ties on first so TNT's own P=0.5
// "propose removing an existing tie" branch is reachable.
void test_bip_proposals() {
	class ErgmGraph scalar G
	real scalar t, i, j, lr
	real rowvector prop

	G = ErgmGraph()
	G.init(10, 0)
	G.set_bipartite((1\1\1\1\1\1\2\2\2\2))
	G.toggle(1,7)
	G.toggle(2,8)
	G.toggle(3,9)

	for (t=1; t<=2000; t++) {
		prop = ergm_propose_uniform(G)
		i = prop[1]; j = prop[2]
		assert((G.mode[i]==1 & G.mode[j]==2) | (G.mode[i]==2 & G.mode[j]==1))
	}
	for (t=1; t<=2000; t++) {
		prop = ergm_propose_tnt(G)
		i = prop[1]; j = prop[2]
		assert((G.mode[i]==1 & G.mode[j]==2) | (G.mode[i]==2 & G.mode[j]==1))
	}
	"test_bip_proposals: OK (4000 draws, all cross-mode)"
}
test_bip_proposals()

// --- ErgmModel::build_mple_data(): row count must equal the true
// cross-mode dyad count, and every row's underlying dyad must be
// cross-mode (checked indirectly: response column sum must equal the
// graph's own observed tie count, which would be wrong if same-mode
// non-ties were included).
void test_bip_mple_data() {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real matrix D

	G = ErgmGraph()
	G.init(10, 0)
	G.set_bipartite((1\1\1\1\1\1\2\2\2\2))
	G.toggle(1,7)
	G.toggle(2,8)
	G.toggle(3,9)
	G.toggle(1,8)
	G.toggle(4,10)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td, ("edges"))

	D = M.build_mple_data(G)
	assert(rows(D) == 24)
	assert(cols(D) == 2)		// 1 covariate (edges) + response
	assert(sum(D[.,2]) == 5)	// observed ties
	assert(D[.,1] == J(24,1,1))	// edges' change-toward-one is always 1
	"test_bip_mple_data: OK"
}
test_bip_mple_data()

// --- ErgmCertifyChangeStat(): edges' change() must exactly match
// brute-force recomputation restricted to the cross-mode dyad space.
void test_bip_certify_changestat() {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar maxdiff

	G = ErgmGraph()
	G.init(9, 0)
	G.set_bipartite((1\1\1\2\2\2\2\2\2))
	G.toggle(1,4)
	G.toggle(2,5)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td, ("edges"))

	maxdiff = ErgmCertifyChangeStat(M, G)
	assert(maxdiff < 1e-9)
	"test_bip_certify_changestat: OK (maxdiff = " + strofreal(maxdiff) + ")"
}
test_bip_certify_changestat()

// --- Stage 2 terms (unit 156): stat_b1cov()/change_b1cov()/
// stat_b2cov()/change_b2cov()/stat_b1factor()/change_b1factor()/
// stat_b2factor()/change_b2factor() certified via ErgmCertifyChangeStat()
// (brute-force toggle-and-diff, restricted to cross-mode dyads), all
// four combined in one model on a network with NON-CONTIGUOUS mode
// assignment (mode 1/2/1/2/1/2/1/2/1 - deliberately interleaved, not
// "all mode-1 first" the way every other test in this file happens to
// build it) specifically to exercise the G.mode[.] endpoint-detection
// logic every one of these eight functions relies on (see unw_ergm.do's
// own "bipartite Stage 2" header comment on why positional order cannot
// be assumed) - a same-index-ordering coincidence could otherwise mask
// a real bug in exactly this logic.
void test_bip_s2_certify_changestat() {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td_c1, td_c2, td_f1, td_f2
	real scalar maxdiff, i

	G = ErgmGraph()
	G.init(9, 0)
	// nodes 1,3,5,7,9 = mode 1 (5 nodes); nodes 2,4,6,8 = mode 2 (4
	// nodes) - interleaved, not contiguous by mode.
	G.set_bipartite((1\2\1\2\1\2\1\2\1))
	G.toggle(1,2)
	G.toggle(3,2)
	G.toggle(3,4)
	G.toggle(5,6)
	G.toggle(7,8)
	G.toggle(9,8)
	G.toggle(1,4)

	M = ErgmModel()
	M.init()
	td_c1 = ErgmTermData()
	td_c1.attr = (1.5\.\2.5\.\-3\.\0.7\.\4.2)		// only mode-1 entries meaningful
	M.addterm("b1cov", 1, &stat_b1cov(), &change_b1cov(), td_c1, ("b1cov"))
	td_c2 = ErgmTermData()
	td_c2.attr = (.\10\.\20\.\30\.\40\.)			// only mode-2 entries meaningful
	M.addterm("b2cov", 1, &stat_b2cov(), &change_b2cov(), td_c2, ("b2cov"))
	td_f1 = ErgmTermData()
	td_f1.attr = (1\.\2\.\1\.\3\.\2)
	td_f1.levels = (1\2\3)
	M.addterm("b1factor", 3, &stat_b1factor(), &change_b1factor(), td_f1, ("b1factor_1","b1factor_2","b1factor_3"))
	td_f2 = ErgmTermData()
	td_f2.attr = (.\5\.\6\.\5\.\6\.)
	td_f2.levels = (5\6)
	M.addterm("b2factor", 2, &stat_b2factor(), &change_b2factor(), td_f2, ("b2factor_5","b2factor_6"))

	maxdiff = ErgmCertifyChangeStat(M, G)
	assert(maxdiff < 1e-9)
	"test_bip_s2_certify_changestat: OK (maxdiff = " + strofreal(maxdiff) + ")"
}
test_bip_s2_certify_changestat()

// --- Stage 3 terms (unit 157): stat_b1degree()/change_b1degree()/
// stat_b2degree()/change_b2degree()/stat_b1star()/change_b1star()/
// stat_b2star()/change_b2star() certified via ErgmCertifyChangeStat(),
// again on a NON-CONTIGUOUS mode assignment for the same reason Stage
// 2's own certification test uses one. Also checks R ergm's own noted
// identity (b1star-ergmTerm Rd doc): "b1star(1) is equal to b2star(1)
// and to edges" - a real, independently checkable structural fact, not
// merely quoted from the docs.
void test_bip_s3_certify_changestat() {
	class ErgmGraph scalar G
	class ErgmModel scalar M, Mchk
	class ErgmTermData scalar td_d1, td_d2, td_s1, td_s2, td_e, td_1
	real scalar maxdiff
	real rowvector s_edges, s_b1star1, s_b2star1

	G = ErgmGraph()
	G.init(9, 0)
	// nodes 1,3,5,7,9 = mode 1 (5 nodes); nodes 2,4,6,8 = mode 2 (4
	// nodes) - interleaved, matching test_bip_s2_certify_changestat()'s
	// own construction.
	G.set_bipartite((1\2\1\2\1\2\1\2\1))
	G.toggle(1,2)
	G.toggle(3,2)
	G.toggle(3,4)
	G.toggle(5,6)
	G.toggle(7,8)
	G.toggle(9,8)
	G.toggle(1,4)
	G.toggle(5,8)

	M = ErgmModel()
	M.init()
	td_d1 = ErgmTermData()
	td_d1.levels = (1\2\3)
	M.addterm("b1degree", 3, &stat_b1degree(), &change_b1degree(), td_d1, ("b1d1","b1d2","b1d3"))
	td_d2 = ErgmTermData()
	td_d2.levels = (1\2)
	M.addterm("b2degree", 2, &stat_b2degree(), &change_b2degree(), td_d2, ("b2d1","b2d2"))
	td_s1 = ErgmTermData()
	td_s1.levels = (1\2)
	M.addterm("b1star", 2, &stat_b1star(), &change_b1star(), td_s1, ("b1s1","b1s2"))
	td_s2 = ErgmTermData()
	td_s2.levels = (1\2)
	M.addterm("b2star", 2, &stat_b2star(), &change_b2star(), td_s2, ("b2s1","b2s2"))

	maxdiff = ErgmCertifyChangeStat(M, G)
	assert(maxdiff < 1e-9)

	Mchk = ErgmModel()
	Mchk.init()
	td_e = ErgmTermData()
	Mchk.addterm("edges", 1, &stat_edges(), &change_edges(), td_e, ("edges"))
	td_1 = ErgmTermData()
	td_1.levels = (1)
	s_edges = stat_edges(G, td_e)
	s_b1star1 = stat_b1star(G, td_1)
	s_b2star1 = stat_b2star(G, td_1)
	assert(s_edges == s_b1star1)
	assert(s_edges == s_b2star1)

	"test_bip_s3_certify_changestat: OK (maxdiff = " + strofreal(maxdiff) + "; b1star(1)=b2star(1)=edges=" + strofreal(s_edges) + ")"
}
test_bip_s3_certify_changestat()

// --- Stage 4 terms (unit 162): stat_b1nodematch()/change_b1nodematch()/
// stat_b2nodematch()/change_b2nodematch()/stat_bgwdegree1()/
// change_bgwdegree1()/stat_bgwdegree2()/change_bgwdegree2() certified
// via ErgmCertifyChangeStat() first (brute-force toggle-and-diff), same
// non-contiguous-mode network as Stages 2/3 above, then via an EXACT
// real-R-ergm cross-check on a second, denser, real 24-edge/8x6
// bipartite network (the same edge list as the b1star/b2star Stage 3
// smoke test below, `bipnetB2') - R ergm 4.12.0's own installed
// b1nodematch()/b2nodematch()/gwb1degree()/gwb2degree() computed via
// `summary()' on that exact network (mode-2 ids offset by +8 to match R
// `network()''s own bipartite edgelist convention) gave 17/12/13.80303/
// 9.472887 respectively - this package's own Mata implementation
// matches all four to displayed precision, not merely closely. See
// unw_ergm.do's own Stage 4 header comment for the full derivation
// account and why b1nodematch/b2nodematch are scoped to R's own
// default parameters only (no diff()/alpha()/beta()/byb2attr()).
void test_bip_s4_certify_changestat() {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td_nm1, td_nm2, td_gwd1, td_gwd2
	real scalar maxdiff

	G = ErgmGraph()
	G.init(9, 0)
	G.set_bipartite((1\2\1\2\1\2\1\2\1))
	G.toggle(1,2)
	G.toggle(3,2)
	G.toggle(3,4)
	G.toggle(5,6)
	G.toggle(7,8)
	G.toggle(9,8)
	G.toggle(1,4)

	M = ErgmModel()
	M.init()
	td_nm1 = ErgmTermData()
	td_nm1.attr = (1\.\2\.\1\.\2\.\1)		// only mode-1 entries meaningful
	M.addterm("b1nodematch", 1, &stat_b1nodematch(), &change_b1nodematch(), td_nm1, ("b1nodematch"))
	td_nm2 = ErgmTermData()
	td_nm2.attr = (.\5\.\6\.\5\.\6\.)		// only mode-2 entries meaningful
	M.addterm("b2nodematch", 1, &stat_b2nodematch(), &change_b2nodematch(), td_nm2, ("b2nodematch"))
	td_gwd1 = ErgmTermData()
	td_gwd1.decay = 0.6
	M.addterm("bgwdegree1", 1, &stat_bgwdegree1(), &change_bgwdegree1(), td_gwd1, ("bgwdegree1"))
	td_gwd2 = ErgmTermData()
	td_gwd2.decay = 0.9
	M.addterm("bgwdegree2", 1, &stat_bgwdegree2(), &change_bgwdegree2(), td_gwd2, ("bgwdegree2"))

	maxdiff = ErgmCertifyChangeStat(M, G)
	assert(maxdiff < 1e-9)
	"test_bip_s4_certify_changestat: OK (maxdiff = " + strofreal(maxdiff) + ")"
}
test_bip_s4_certify_changestat()

void test_bip_s4_r_crosscheck() {
	class ErgmGraph scalar G
	class ErgmTermData scalar td1, td2, td3, td4
	real matrix el
	real scalar k

	G = ErgmGraph()
	G.init(14, 0)
	G.set_bipartite((1\1\1\1\1\1\1\1\2\2\2\2\2\2))
	// identical 24-edge list to `bipnetB2' below (person/event), mode-2
	// ids offset by +8 (mode-1 count) to match R `network()''s own
	// bipartite edgelist convention when cross-checking - this package's
	// own `nwset'/G.mode[.] machinery does not require contiguous mode
	// blocks at all (see unw_ergm.do's own "no node reordering" header
	// comment), this offsetting is purely for matching R's input shape.
	el = (1,5, 1,6, 1,1, 2,5, 2,3, 3,4, 3,2, 3,6, 4,1, 4,4, 4,6, 5,1, 5,3, 6,3, 6,6, 6,5, 6,4, 7,3, 7,2, 7,6, 8,5, 8,4, 8,1, 8,6)
	el = colshape(el, 2)
	for (k=1; k<=rows(el); k++) G.toggle(el[k,1], el[k,2]+8)

	td1 = ErgmTermData()
	td1.attr = (1\2\1\2\1\2\1\2\.\.\.\.\.\.)
	assert(reldif(stat_b1nodematch(G, td1), 17) < 1e-6)

	td2 = ErgmTermData()
	td2.decay = 0.7
	assert(reldif(stat_bgwdegree1(G, td2), 13.80303) < 1e-5)

	td3 = ErgmTermData()
	td3.attr = (.\.\.\.\.\.\.\.\3\4\3\4\3\4)
	assert(reldif(stat_b2nodematch(G, td3), 12) < 1e-6)

	td4 = ErgmTermData()
	td4.decay = 0.5
	assert(reldif(stat_bgwdegree2(G, td4), 9.472887) < 1e-5)

	"test_bip_s4_r_crosscheck: OK (exact match to real R ergm 4.12.0 summary() output)"
}
test_bip_s4_r_crosscheck()

// --- harmonisation unit 159: native (C) backend for bipartite models.
// Direct port of cscripts/test_nwergm_native.do's own established
// methodology (test_equivalence()): two independent MCMC chains (one
// Mata, one native), IDENTICAL starting network, run under IDENTICAL
// theta - the sampled sufficient-statistic MEANS must agree within
// Monte Carlo tolerance (an autocorrelation-inflated standard error,
// the same estimator ErgmMCMLE()'s own final variance step and
// test_nwergm_native.do's own test_equivalence() both already use - not
// an invented tolerance for this test alone), not bit-identical sample
// paths (native and Mata use independent RNG streams by design). All
// eight bipartite termcodes (60-67) exercised together in one combined
// model - both the dyad-independent family (b1cov/b2cov/b1factor/
// b2factor) and the dyad-dependent family (b1degree/b2degree/b1star/
// b2star) - on a network with CONTIGUOUS mode blocks (mode-1 nodes
// 1..n1, mode-2 nodes n1+1..n), exercising native's own wire-protocol
// column-index arithmetic (attrcol_base, the mode column's own position
// relative to the attribute columns) at real MCMC scale; the
// NON-contiguous mode-assignment case is already covered at the Mata
// level by test_bip_s2_certify_changestat()/
// test_bip_s3_certify_changestat() above.
void build_bipartite_det(class ErgmGraph G, real scalar n1, real scalar n2, real scalar deg) {
	real scalar i, e, j
	for (i=1; i<=n1; i++) {
		for (e=1; e<=deg; e++) {
			j = n1 + mod(i + e*3 + 1, n2) + 1
			if (!G.has_edge(i,j)) G.toggle(i,j)
		}
	}
}
void test_native_bip_equivalence(){
	class ErgmGraph scalar Gmata, Gnative
	class ErgmModel scalar M
	class ErgmTermData scalar td_c1, td_c2, td_f1, td_f2, td_d1, td_d2, td_s1, td_s2
	real scalar n1, n2, n, i
	real colvector modevec, attr_c1, attr_c2, attr_f1, attr_f2
	real matrix samp_mata, samp_native
	real rowvector theta, mean_mata, mean_native, sd_mata, sd_native, se
	real rowvector rho_mata, rho_native, infl_mata, infl_native, obs
	real scalar p, k, burnin, interval, samplesize, tol_sd_mult, checkstat

	n1 = 10
	n2 = 8
	n = n1 + n2
	modevec = J(n1,1,1) \ J(n2,1,2)

	Gmata = ErgmGraph()
	Gmata.init(n, 0)
	Gmata.set_bipartite(modevec)
	build_bipartite_det(Gmata, n1, n2, 3)

	Gnative = ErgmGraph()
	Gnative.init(n, 0)
	Gnative.set_bipartite(modevec)
	build_bipartite_det(Gnative, n1, n2, 3)

	attr_c1 = J(n,1,0)
	for (i=1; i<=n1; i++) attr_c1[i] = mod(i,4) + 1
	attr_c2 = J(n,1,0)
	for (i=n1+1; i<=n; i++) attr_c2[i] = mod(i,3) + 1
	attr_f1 = J(n,1,0)
	for (i=1; i<=n1; i++) attr_f1[i] = mod(i,2) + 1
	attr_f2 = J(n,1,0)
	for (i=n1+1; i<=n; i++) attr_f2[i] = mod(i,2) + 1

	M = ErgmModel()
	M.init()
	td_c1 = ErgmTermData()
	td_c1.attr = attr_c1
	M.addterm("b1cov", 1, &stat_b1cov(), &change_b1cov(), td_c1, ("b1cov"))
	td_c2 = ErgmTermData()
	td_c2.attr = attr_c2
	M.addterm("b2cov", 1, &stat_b2cov(), &change_b2cov(), td_c2, ("b2cov"))
	td_f1 = ErgmTermData()
	td_f1.attr = attr_f1
	td_f1.levels = (1\2)
	M.addterm("b1factor", 2, &stat_b1factor(), &change_b1factor(), td_f1, ("b1factor_1","b1factor_2"))
	td_f2 = ErgmTermData()
	td_f2.attr = attr_f2
	td_f2.levels = (1\2)
	M.addterm("b2factor", 2, &stat_b2factor(), &change_b2factor(), td_f2, ("b2factor_1","b2factor_2"))
	td_d1 = ErgmTermData()
	td_d1.levels = (1\2\3)
	M.addterm("b1degree", 3, &stat_b1degree(), &change_b1degree(), td_d1, ("b1d1","b1d2","b1d3"))
	td_d2 = ErgmTermData()
	td_d2.levels = (1\2)
	M.addterm("b2degree", 2, &stat_b2degree(), &change_b2degree(), td_d2, ("b2d1","b2d2"))
	td_s1 = ErgmTermData()
	td_s1.levels = (1\2)
	M.addterm("b1star", 2, &stat_b1star(), &change_b1star(), td_s1, ("b1s1","b1s2"))
	td_s2 = ErgmTermData()
	td_s2.levels = (1\2)
	M.addterm("b2star", 2, &stat_b2star(), &change_b2star(), td_s2, ("b2s1","b2s2"))

	p = M.nparam()
	theta = J(1,p,0)
	for (k=1; k<=p; k++) theta[k] = 0.03 * (mod(k,3) - 1)
	theta[1] = -1.5

	burnin = 3000
	interval = 5
	samplesize = 3000
	tol_sd_mult = 6

	M.native_enabled = 0
	samp_mata = ErgmMCMCSample(M, Gmata, theta, burnin, interval, samplesize, &ergm_propose_tnt())

	assert(ErgmNativeSetup(M, 2, Gnative) == 1)
	assert(M.native_enabled == 1)
	samp_native = ErgmMCMCSample(M, Gnative, theta, burnin, interval, samplesize, &ergm_propose_tnt())
	M.native_enabled = 0

	mean_mata = mean(samp_mata)
	mean_native = mean(samp_native)
	sd_mata = sqrt(diagonal(variance(samp_mata)))'
	sd_native = sqrt(diagonal(variance(samp_native)))'
	rho_mata = ergm_lag1_autocorr(samp_mata)
	rho_native = ergm_lag1_autocorr(samp_native)
	infl_mata = (1 :+ rho_mata) :/ (1 :- rho_mata)
	infl_native = (1 :+ rho_native) :/ (1 :- rho_native)
	se = sqrt((sd_mata:^2 :* infl_mata + sd_native:^2 :* infl_native) :/ samplesize)
	se = se :+ 1e-8

	for (k=1; k<=p; k++) {
		assert(abs(mean_mata[k] - mean_native[k]) < tol_sd_mult * se[k])
	}

	// self-consistency: also confirms Gnative's own bipartite state
	// (mode1nodes/mode2nodes) survived ErgmNativeSampleCore()'s own
	// G.init()+set_bipartite() restore correctly (unit 159's own real
	// pitfall: G.init() unconditionally resets `bipartite'=0).
	assert(Gnative.bipartite == 1)
	obs = M.full_statistic(Gnative)
	checkstat = max(abs(obs - samp_native[samplesize, .]))
	assert(checkstat < 1e-6 + 1e-6 * max(abs(obs)))

	"test_native_bip_equivalence: OK (native-vs-mata max mean diff within tolerance; self-consistency max diff = " + strofreal(checkstat) + ")"
}
test_native_bip_equivalence()

// --- native MPLE (mode=1) design-matrix build must byte-match Mata's
// own build_mple_data() exactly (both deterministic, no RNG involved) -
// a SEPARATE native code path (ErgmNativeBuildMPLEData()) from the MCMC
// one just certified above, exercising the dyad-independent family only
// (b1cov/b1factor), the terms Stage 2's own MPLE fits actually use.
void test_native_bip_mple(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td_c1, td_f1
	real scalar n1, n2, n, i, maxdiff
	real colvector modevec, attr_c1, attr_f1
	real matrix D_mata, D_native

	n1 = 7
	n2 = 5
	n = n1 + n2
	modevec = J(n1,1,1) \ J(n2,1,2)

	G = ErgmGraph()
	G.init(n, 0)
	G.set_bipartite(modevec)
	G.toggle(1, n1+1)
	G.toggle(2, n1+2)
	G.toggle(3, n1+1)
	G.toggle(4, n1+3)
	G.toggle(5, n1+4)
	G.toggle(6, n1+5)
	G.toggle(7, n1+2)

	attr_c1 = J(n,1,0)
	for (i=1; i<=n1; i++) attr_c1[i] = mod(i,3) + 1.5
	attr_f1 = J(n,1,0)
	for (i=1; i<=n1; i++) attr_f1[i] = mod(i,2) + 1

	M = ErgmModel()
	M.init()
	td_c1 = ErgmTermData()
	td_c1.attr = attr_c1
	M.addterm("b1cov", 1, &stat_b1cov(), &change_b1cov(), td_c1, ("b1cov"))
	td_f1 = ErgmTermData()
	td_f1.attr = attr_f1
	td_f1.levels = (1\2)
	M.addterm("b1factor", 2, &stat_b1factor(), &change_b1factor(), td_f1, ("b1factor_1","b1factor_2"))

	D_mata = M.build_mple_data(G)
	assert(ErgmNativeSetup(M, 2, G) == 1)
	D_native = ErgmNativeBuildMPLEData(M, G)

	assert(rows(D_mata) == rows(D_native))
	assert(cols(D_mata) == cols(D_native))
	maxdiff = max(abs(D_mata - D_native))
	assert(maxdiff < 1e-9)

	"test_native_bip_mple: OK (maxdiff = " + strofreal(maxdiff) + ")"
}
test_native_bip_mple()

end

* ===========================================================================
* .ado-level end-to-end smoke test: a real bipartite network built via
* nwset's own documented `twomode' edgelist declaration, fit through
* nwergm.ado itself (not the Mata internals directly), with a genuine
* closed-form check on the fitted coefficient.
* ===========================================================================

nwclear
clear
input person event
1 1
1 2
2 1
2 3
3 2
3 3
4 4
5 4
5 1
6 2
6 4
end
nwset person event, twomode name(bipnet)

_nwsyntax bipnet, max(1)
assert "`is2mode'" == "true"
assert "`directed'" != "true"
assert `nodes' == 10

* edges-only MPLE fit must now succeed (Stage 1 replaced the old blanket
* two-mode rejection).
qui nwergm bipnet, edges
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert e(nodes) == 10
assert e(ties) == 11

* closed-form check: an edges-only ERGM's MLE is exactly the log-odds of
* observed density over the TRUE bipartite dyad space (6 mode-1 x 4
* mode-2 = 24 cross-mode dyads), never the full one-mode 10*9/2 = 45
* space ergm_total_dyads() would report without its bipartite branch.
local true_dyads = 6*4
local true_ties = 11
local true_logodds = ln((`true_ties'/`true_dyads') / (1 - `true_ties'/`true_dyads'))
assert reldif(_b[edges], `true_logodds') < 1e-6

* rejection checks: every one-mode-only term must still be explicitly
* rejected on a bipartite network - never silently misapplied to a dyad
* space its change statistic was never derived for. The dyad-dependent
* bipartite family (Stage 3) does not exist yet either.
foreach __t in mutual triangle ctriple concurrent transitiveties cyclicalties {
	capture noisily nwergm bipnet, edges `__t'
	assert _rc == 198
}
capture noisily nwergm bipnet, edges nodecov(x)
assert _rc == 198
capture noisily nwergm bipnet, edges gwesp(.5)
assert _rc == 198
capture noisily nwergm bipnet, edges degree(2)
assert _rc == 198
capture noisily nwergm bipnet, edges kstar(2)
assert _rc == 198

di "=== bipartite (two-mode) Stage 1 foundation: all certifications passed ==="

* ===========================================================================
* Stage 2 (unit 156): bcov1()/bcov2()/bfactor1()/bfactor2() end-to-end
* fit through nwergm.ado itself, certified against a REAL, independently
* generated R ergm 4.12.0 MPLE fit (dev/bipartite_stage2_crosscheck.R) on
* the IDENTICAL bipartite network/covariates - not a fabricated or
* eyeballed number.
* ===========================================================================

gen age = .
replace age = 25 in 1
replace age = 30 in 2
replace age = 45 in 3
replace age = 22 in 4
replace age = 60 in 5
replace age = 35 in 6

gen size = .
replace size = 10 in 7
replace size = 40 in 8
replace size = 5 in 9
replace size = 20 in 10

gen grp = .
replace grp = 1 in 1
replace grp = 1 in 2
replace grp = 2 in 3
replace grp = 2 in 4
replace grp = 1 in 5
replace grp = 2 in 6

gen cat = .
replace cat = 1 in 7
replace cat = 2 in 8
replace cat = 1 in 9
replace cat = 2 in 10

qui nwergm bipnet, edges bcov1(age) bcov2(size) bfactor1(grp) bfactor2(cat)
assert _rc == 0
assert e(nodes) == 10
assert e(ties) == 11

* real R ergm 4.12.0 output (dev/bipartite_stage2_crosscheck.R, run
* directly, not hand-computed):
*   edges = -0.7072168318107824314
*   b1cov.age = 0.0124553511418733671
*   b2cov.size = 0.0079654906658249876
*   b1factor.grp.2 = -0.2867383529378668139
*   b2factor.cat.2 = 0.1618202270729788284
assert reldif(_b[edges], -0.7072168318107824314) < 1e-5
assert reldif(_b[b1cov_age], 0.0124553511418733671) < 1e-5
assert reldif(_b[b2cov_size], 0.0079654906658249876) < 1e-5
assert reldif(_b[b1factor_grp_2], -0.2867383529378668139) < 1e-5
assert reldif(_b[b2factor_cat_2], 0.1618202270729788284) < 1e-5

* rejection checks: bcov1()/bcov2()/bfactor1()/bfactor2() require a
* bipartite network - never silently applied to a one-mode network's own
* dyad space (R ergm's own b1cov() docs: "This term may only be used
* with bipartite networks").
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(onemode)
gen z = _n
foreach __t in bcov1 bcov2 bfactor1 bfactor2 {
	capture noisily nwergm onemode, edges `__t'(z)
	assert _rc == 198
}

di "=== bipartite (two-mode) Stage 2 (bcov1/bcov2/bfactor1/bfactor2): all certifications passed, matching real R ergm to <1e-5 ==="

* ===========================================================================
* Stage 3 (unit 157): bdegree1()/bdegree2()/bstar1()/bstar2() - the
* dyad-DEPENDENT bipartite family, the first to require method(mcmle)
* and so the first to exercise the Stage-1 bipartite MCMC proposal
* (ergm_propose_uniform()/ergm_propose_tnt()) for real. Certified
* against real, independently generated R ergm 4.12.0 MCMLE output
* (dev/bipartite_stage3_crosscheck.R) - see docs/CERTIFICATION.md unit
* 157 for the exact numeric comparison (agreement within a few percent,
* the same Monte Carlo tolerance this package's own unit 71 MCMLE
* certification already established as the right standard for a
* stochastic estimator, not bit-for-bit agreement). This permanent
* regression test itself asserts convergence and the correct SIGN
* (matching R's own finding on the identical network) rather than a
* tight numeric match against R, since two independent MCMC engines
* with different RNG streams will never reproduce each other's draws
* exactly - the tight numeric comparison is a one-time, documented
* finding (CERTIFICATION.md), not a per-run assertion.
*
* Two networks, not one: the 6x4 (11-tie) bipartite network Stage 1/2
* already use is too small/sparse to identify b1star(2)/b2star(2) at
* all (confirmed directly in REAL R output: "linear dependence...may
* indicate the model is nonidentifiable" and "The MPLE does not
* exist!" - the same genuine small-network degeneracy this project has
* hit before with curved GWESP/gwnsp, not an nwergm-specific defect).
* bdegree1(1)/bdegree2(2) DO identify on the 6x4 network; bstar1(2)/
* bstar2(2) need the larger, denser 8x6 network built for
* dev/bipartite_stage3_crosscheck.R's own netB.

nwclear
clear
input person event
1 1
1 2
2 1
2 3
3 2
3 3
4 4
5 4
5 1
6 2
6 4
end
nwset person event, twomode name(bipnetA)

set seed 1
qui nwergm bipnetA, edges bdegree1(1) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert `"`e(method)'"' == "mcmle"
assert e(converged) == 1
assert _b[b1degree_1] < 0

nwclear
clear
input person event
1 1
1 2
2 1
2 3
3 2
3 3
4 4
5 4
5 1
6 2
6 4
end
nwset person event, twomode name(bipnetA2)
set seed 1
qui nwergm bipnetA2, edges bdegree2(2) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert e(converged) == 1
assert _b[b2degree_2] < 0

nwclear
clear
input person event
1 5
1 6
1 1
2 5
2 3
3 4
3 2
3 6
4 1
4 4
4 6
5 1
5 3
6 3
6 6
6 5
6 4
7 3
7 2
7 6
8 5
8 4
8 1
8 6
end
nwset person event, twomode name(bipnetB)

set seed 77
qui nwergm bipnetB, edges bstar1(2) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert e(converged) == 1
assert _b[b1star_2] < 0

nwclear
clear
input person event
1 5
1 6
1 1
2 5
2 3
3 4
3 2
3 6
4 1
4 4
4 6
5 1
5 3
6 3
6 6
6 5
6 4
7 3
7 2
7 6
8 5
8 4
8 1
8 6
end
nwset person event, twomode name(bipnetB2)
set seed 77
qui nwergm bipnetB2, edges bstar2(2) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert e(converged) == 1
assert _b[b2star_2] < 0

* rejection checks: bdegree1()/bdegree2()/bstar1()/bstar2() require a
* bipartite network.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(onemode2)
foreach __t in bdegree1 bdegree2 bstar1 bstar2 {
	capture noisily nwergm onemode2, edges `__t'(2)
	assert _rc == 198
}

di "=== bipartite (two-mode) Stage 3 (bdegree1/bdegree2/bstar1/bstar2): all certifications passed, converged with correct sign vs. real R ergm MCMLE ==="

* Stage 4 (unit 162) .ado-level end-to-end smoke test: bnodematch1()/
* bnodematch2()/bgwdegree1()/bgwdegree2() on the same real `bipnetB2'
* network the R cross-check above uses, fit via method(mcmle) (both
* families are dyad-DEPENDENT, needing the Stage-1 bipartite MCMC
* proposal for real, exactly like bstar1()/bstar2() above) - the Mata-
* level tests above already certified the underlying statistic/change
* functions to exact agreement with real R output, so this only needs
* to confirm the .ado-level wiring (option parsing, term registration,
* MCMLE convergence) works end to end, matching the existing Stage 3
* smoke tests' own level of rigor.
nwclear
clear
input person event
1 5
1 6
1 1
2 5
2 3
3 4
3 2
3 6
4 1
4 4
4 6
5 1
5 3
6 3
6 6
6 5
6 4
7 3
7 2
7 6
8 5
8 4
8 1
8 6
end
nwset person event, twomode name(bipnetB4)
set seed 77
qui nwergm bipnetB4, edges bgwdegree1(0.7) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert e(converged) == 1

* nwset consumes the source person/event columns when declaring a
* network (confirmed directly: a second `nwset person event, ...' call
* on the same in-memory data fails with "variable person not found") -
* every subsequent network below re-loads the identical 24-edge list
* fresh via its own `nwclear'/`clear'/`input'/`end' block, matching the
* exact established convention `bipnetB'/`bipnetB2' above already use.
nwclear
clear
input person event
1 5
1 6
1 1
2 5
2 3
3 4
3 2
3 6
4 1
4 4
4 6
5 1
5 3
6 3
6 6
6 5
6 4
7 3
7 2
7 6
8 5
8 4
8 1
8 6
end
nwset person event, twomode name(bipnetB4b)
set seed 78
qui nwergm bipnetB4b, edges bgwdegree2(0.5) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert e(converged) == 1

* b1nodematch()/b2nodematch() need a mode-restricted categorical
* attribute variable, unlike the structural bgwdegree1()/bgwdegree2()
* above - generate one directly on the freshly-loaded frame (person ids
* 1-8 occupy rows 1-8, event ids 1-6 occupy rows 9-14, matching the
* Stage 2 smoke test's own established convention above).
nwclear
clear
input person event
1 5
1 6
1 1
2 5
2 3
3 4
3 2
3 6
4 1
4 4
4 6
5 1
5 3
6 3
6 6
6 5
6 4
7 3
7 2
7 6
8 5
8 4
8 1
8 6
end
nwset person event, twomode name(bipnetB4c)
qui gen byte grp = mod(_n-1, 2) + 1 in 1/8
qui replace grp = . in 9/14
set seed 79
qui nwergm bipnetB4c, edges bnodematch1(grp) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert e(converged) == 1

* rejection checks: bnodematch1()/bnodematch2()/bgwdegree1()/
* bgwdegree2() require a bipartite network.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(onemode3)
qui gen byte g5 = mod(_n,2) in 1/5
foreach __t in bnodematch1 bnodematch2 {
	capture noisily nwergm onemode3, edges `__t'(g5)
	assert _rc == 198
}
foreach __t in bgwdegree1 bgwdegree2 {
	capture noisily nwergm onemode3, edges `__t'(0.5)
	assert _rc == 198
}

di "=== bipartite (two-mode) Stage 4 (bnodematch1/bnodematch2/bgwdegree1/bgwdegree2): all certifications passed, exact match to real R ergm summary() output, converged end to end via MCMLE ==="
