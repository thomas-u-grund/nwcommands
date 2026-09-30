* Multiplex SAOM, Stage 1 certification (two co-evolving networks, no
* cross-network effects) - see docs/SAOM_ROADMAP.md's own multiplex
* entry for the full scoping account. Direct Mata-level test, following
* this project's own established convention (cscripts/test_nwsaom_mata.do)
* of certifying new estimator machinery via SaomSimulateInterval-generated
* synthetic data with a KNOWN true theta, before any .ado-level wiring.

clear all
* run from the repository root, like the other cscripts (a hardcoded cd to
* the main checkout here used to test that checkout's Mata code instead)
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
* Data (2026-10-01): with both rates estimated (unconditional Method of
* Moments, as RSiena does for two dependent variables) the 6-actor toy
* networks used here before no longer identify a model. Network 1 is
* friendship (glasgow waves 1-2), network 2 an "advice" network generated
* from it below (seeded, so the same every run). RSiena 1.6.6 reference,
* mean of five seeds (projname=NULL, default algorithm = unconditional),
* on exactly these matrices, crprod in both directions:
*   friendship rate 6.753 (1.549), outdegree -2.311 (.140), reciprocity
*   2.317 (.240), advice: .640 (.432); advice rate 1.825 (.303), outdegree
*   -1.841 (.195), reciprocity 1.784 (.428), friendship: .765 (.709).
* RSiena's crprod targets are lagged: sum(x1(t2) * x2(t1)) = 43 and
* sum(x2(t2) * x1(t1)) = 66 here, as nwsaom's.
nwwebuse glasgow, nwclear
nwtomata glasgow1, mat(__mpF1)
nwtomata glasgow2, mat(__mpF2)
set seed 20261001
mata: __mpA1 = __mpF1 :* (runiform(50, 50) :< 0.7)
mata: __mpA1 = (__mpA1 + (runiform(50, 50) :< 0.005)) :> 0
mata: _diag(__mpA1, 0)
mata: __mpA2 = __mpA1 :* (runiform(50, 50) :< 0.8)
mata: __mpA2 = (__mpA2 + __mpF2 :* (1 :- __mpA1) :* (runiform(50, 50) :< 0.4) + (runiform(50, 50) :< 0.003)) :> 0
mata: _diag(__mpA2, 0)
mata: assert(sum(__mpA1) == 98 & sum(__mpA2) == 118 & sum(__mpA1 :!= __mpA2) == 64)
nwset, mat(__mpA1) directed name(advice1)
nwset, mat(__mpA2) directed name(advice2)

nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(advice1) netbwave2(advice2) crprod crprodb k0(50) k3(1000) seed(12345)

assert colsof(e(b)) == 6
assert rowsof(e(V)) == 6 & colsof(e(V)) == 6
capture program drop _mp_check
program define _mp_check
	args label est se rs rse
	di as text %-18s "`label'" "  nwsaom " %8.3f `est' " (" %6.3f `se' ")   RSiena " %8.3f `rs' " (" %6.3f `rse' ")"
	assert abs(`est' - `rs') < 0.5 * `rse'
	assert `se' > 0.5*`rse' & `se' < 2*`rse'
end
matrix __b = e(b)
matrix __V = e(V)
local __rs  "-2.311 2.317 0.640 -1.841 1.784 0.765"
local __rse "0.140 0.240 0.432 0.195 0.428 0.709"
local __nm : colnames __b
forvalues j = 1/6 {
	_mp_check `: word `j' of `__nm'' __b[1,`j'] sqrt(__V[`j',`j']) `: word `j' of `__rs'' `: word `j' of `__rse''
}
_mp_check rate1 e(rate1) e(rate1_se) 6.753 1.549
_mp_check rate2 e(rate2) e(rate2_se) 1.825 0.303
assert e(tconv_max) < 0.3

di as text "test_nwsaom_multiplex.do ado-level PASS: nwsaom multiplex (both rates estimated) matches RSiena on the friendship/advice example"

di as text "{hline}"
di as text "test_nwsaom_multiplex.do: ALL TESTS PASSED"
di as text "{hline}"
