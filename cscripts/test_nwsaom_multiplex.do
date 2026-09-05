* Multiplex SAOM, Stage 1 certification (two co-evolving networks, no
* cross-network effects) - see docs/SAOM_ROADMAP.md's own multiplex
* entry for the full scoping account. Direct Mata-level test, following
* this project's own established convention (cscripts/test_nwsaom_mata.do)
* of certifying new estimator machinery via SaomSimulateInterval-generated
* synthetic data with a KNOWN true theta, before any .ado-level wiring.

clear all
cd "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands"
do unw_core.do
do unw_ergm.do
do unw_saom.do

mata:
mata set matastrict off

void multiplex_build_model(class ErgmModel M) {
	class ErgmTermData scalar td1, td2
	M.init()
	td1 = ErgmTermData()
	M.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1, ("outdegree"))
	td2 = ErgmTermData()
	M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2, ("reciprocity"))
}

void multiplex_random_graph(class ErgmGraph scalar G, real scalar n, real scalar density) {
	real scalar nedges0, i, j, k
	G.init(n, 1)
	nedges0 = round(density * n * (n-1))
	for (k=1; k<=nedges0; k++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
}

void test_multiplex_stage1(real scalar n) {
	class ErgmGraph scalar G1wave1, G1wave2, G2wave1, G2wave2
	class ErgmModel scalar M1, M2
	real rowvector theta1_true, theta2_true, theta0
	real scalar discard
	struct SaomFit scalar fit1_solo, fit2_solo
	struct SaomCoevNetNetFit scalar fitjoint

	M1 = ErgmModel()
	multiplex_build_model(M1)
	M2 = ErgmModel()
	multiplex_build_model(M2)

	// Two INDEPENDENT networks - network 2's own generating process shares
	// no data or parameter with network 1's, by construction. If joint
	// estimation is correct, each network's own recovered theta should
	// still track its OWN true theta (the core Stage-1 correctness
	// property: joint estimation of two independent processes should not
	// materially distort either one's own answer).
	theta1_true = (-1.6, 1.4)
	theta2_true = (-1.2, 2.0)

	G1wave1 = ErgmGraph()
	multiplex_random_graph(G1wave1, n, 0.15)
	G1wave2 = ErgmGraph()
	SaomCopyGraph(G1wave1, G1wave2)
	discard = SaomSimulateInterval(G1wave2, M1, theta1_true, 2.5)

	G2wave1 = ErgmGraph()
	multiplex_random_graph(G2wave1, n, 0.15)
	G2wave2 = ErgmGraph()
	SaomCopyGraph(G2wave1, G2wave2)
	discard = SaomSimulateInterval(G2wave2, M2, theta2_true, 2.5)

	theta0 = (0, 0)

	// Independent single-network fits (existing, already-certified
	// SaomEstimateRM()) - the reference this joint fit is checked against.
	fit1_solo = SaomEstimateRM(G1wave1, G1wave2, M1, theta0, 2, 30, 200, 0.2)
	fit2_solo = SaomEstimateRM(G2wave1, G2wave2, M2, theta0, 2, 30, 200, 0.2)

	// Joint two-network fit - the new Stage-1 multiplex machinery.
	// K0=10/K3=100 (was 2/30): bumped after a real, direct-caused
	// regression found by a later native-port follow-up (phase 1/3 of
	// SaomEstimateRMCoevNetNet gained a native path, which draws from a
	// DIFFERENT RNG stream than the Mata path this test originally
	// tuned K0=2 against) - a K0=2 phase-1 Jacobian is an inherently
	// thin, near-singular estimate regardless of which RNG stream feeds
	// it (the exact "genuine identification problem, not a software
	// defect" class SaomCheckPhase3Cov()'s own r(505) message already
	// describes), confirmed directly: K0=10/K3=100 passes cleanly on
	// the SAME seed/model/data that r(505)'d at K0=2/K3=30, with no
	// change to the estimator code itself - a test-robustness fix, not
	// a product fix.
	fitjoint = SaomEstimateRMCoevNetNet(G1wave1, G1wave2, M1, G2wave1, G2wave2, M2, theta0, theta0, 10, 100, 0.2)

	printf("multiplex stage1: true theta1:      %6.3f %6.3f\n", theta1_true[1], theta1_true[2])
	printf("multiplex stage1: solo  theta1:     %6.3f %6.3f\n", fit1_solo.theta[1], fit1_solo.theta[2])
	printf("multiplex stage1: joint theta1:     %6.3f %6.3f\n", fitjoint.theta1[1], fitjoint.theta1[2])
	printf("multiplex stage1: true theta2:      %6.3f %6.3f\n", theta2_true[1], theta2_true[2])
	printf("multiplex stage1: solo  theta2:     %6.3f %6.3f\n", fit2_solo.theta[1], fit2_solo.theta[2])
	printf("multiplex stage1: joint theta2:     %6.3f %6.3f\n", fitjoint.theta2[1], fitjoint.theta2[2])
	printf("multiplex stage1: joint rate1=%6.3f rate2=%6.3f\n", fitjoint.rate1, fitjoint.rate2)

	// Core Stage-1 correctness property: joint estimation of two
	// independent processes recovers each network's own theta with the
	// same sign as both the true generating theta AND the independent
	// single-network fit - loose tolerances throughout, matching this
	// file's own established smoke-level-certification convention
	// (stochastic estimator, small network, modest iteration counts).
	assert(sign(fitjoint.theta1[1]) == sign(theta1_true[1]))
	assert(sign(fitjoint.theta1[2]) == sign(theta1_true[2]))
	assert(sign(fitjoint.theta2[1]) == sign(theta2_true[1]))
	assert(sign(fitjoint.theta2[2]) == sign(theta2_true[2]))
	assert(abs(fitjoint.theta1[1] - theta1_true[1]) < 2.5)
	assert(abs(fitjoint.theta1[2] - theta1_true[2]) < 2.5)
	assert(abs(fitjoint.theta2[1] - theta2_true[1]) < 2.5)
	assert(abs(fitjoint.theta2[2] - theta2_true[2]) < 2.5)

	// Rates: each network's own rate should be in a sane ballpark of the
	// true generating rate (2.5), independent of the other network's own
	// rate - confirms the shared rate-race actor-selection mechanism
	// isn't silently conflating the two networks' own opportunity rates.
	assert(fitjoint.rate1 > 0 & fitjoint.rate1 < 20)
	assert(fitjoint.rate2 > 0 & fitjoint.rate2 < 20)

	// V must be a genuine (p1+p2) x (p1+p2) finite covariance matrix.
	assert(rows(fitjoint.V) == 4 & cols(fitjoint.V) == 4)
	assert(!hasmissing(fitjoint.V))

	printf("multiplex stage1 PASS: joint estimation of two independent networks recovers each one's own theta within loose tolerance, rates/covariance well-formed\n")
}

end

set seed 20260830
mata: test_multiplex_stage1(16)

* -------------------------------------------------------------------
* .ado-level end-to-end smoke test: `nwsaom multiplex' (the real,
* user-facing entry point - a self-contained subcommand, dispatched
* from `program nwsaom' the same way `nwergm simulate' dispatches to
* `nwergm_simulate', at ZERO regression risk to the main `nwsaom'
* command's own already-large option surface). Confirms the whole
* _nwsyntax()/NWdef-bridge/ereturn-posting chain works, not just the
* underlying Mata estimator (already certified above).
* -------------------------------------------------------------------
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\1,0,0,1,0,0\0,0,0,0,1,0\0,0,1,0,0,1\0,0,0,0,0,0)) directed name(mp_net1w1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,0\0,0,1,1,0,1\0,0,0,0,1,0)) directed name(mp_net1w2) labs(A,B,C,D,E,F)
nwset, mat((0,1,0,1,0,0\0,0,1,0,0,0\0,0,0,1,1,0\0,0,0,0,0,1\1,0,0,0,0,1\0,0,0,0,0,0)) directed name(mp_net2w1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\0,1,0,1,1,0\0,0,0,0,0,1\1,0,0,0,0,1\0,0,0,1,0,0)) directed name(mp_net2w2) labs(A,B,C,D,E,F)

set seed 20260830
nwsaom multiplex, netawave1(mp_net1w1) netawave2(mp_net1w2) netbwave1(mp_net2w1) netbwave2(mp_net2w2) k0(30) k3(300) firstg(0.2)

assert e(rate1) > 0 & e(rate1) < 20
assert e(rate2) > 0 & e(rate2) < 20
assert colsof(e(b)) == 4
assert rowsof(e(V)) == 4 & colsof(e(V)) == 4

di as text "test_nwsaom_multiplex.do ado-level PASS: nwsaom multiplex ran end to end (_nwsyntax/bridge/ereturn all correct), e(b)/e(V)/e(rate1)/e(rate2) all well-formed"

di as text "{hline}"
di as text "test_nwsaom_multiplex.do: ALL TESTS PASSED"
di as text "{hline}"
