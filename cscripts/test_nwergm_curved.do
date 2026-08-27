cscript

do unw_ergm.do

* Certifies the theta -> eta curved-decay map/gradient
* (ergm_gwdecay_map()/ergm_gwdecay_gradient(), unw_ergm.do, harmonisation
* unit 133 - first slice of curved-parameter support, NOT yet wired into
* ErgmTermData/ErgmModel/MPLE/MCMLE). Reference values transcribed
* directly from the installed R `ergm' package's own internal
* `ergm:::ergm_GWDECAY' object (ergm 4.12.0, confirmed by direct
* inspection - see this unit's own build-up comment in unw_ergm.do for
* the exact R session transcript and the real ambiguity it resolved:
* ergm_GWDECAY's second free parameter is alpha itself, not log(alpha)).
*
* Two independent (theta_w, alpha, n) cases, deliberately including one
* negative theta_w (a plausible real fitted coefficient, not just a
* convenient positive toy value) to catch a sign error a single
* all-positive case could hide.

mata:
mata set matastrict off

// case 1: theta_w=0.8, alpha=1.3, n=6
eta1 = ergm_gwdecay_map(0.8, 1.3, 6)
grad1 = ergm_gwdecay_gradient(0.8, 1.3, 6)

// R: ergm:::ergm_GWDECAY$map(c(0.8,1.3), 6)
ref_eta1 = (0.80000000000000, 1.38197456557279, 1.80534255928984, 2.11332931456596, 2.33737988719596, 2.50036955553681)
// R: ergm:::ergm_GWDECAY$gradient(c(0.8,1.3), 6) - row 1 = d/d(theta_w), row 2 = d/d(alpha)
ref_grad1 = (1, 1.72746820696599, 2.256678199112296, 2.641661643207456, 2.92172485899495, 3.12546194442101 \ ///
             0, 0.21802543442721, 0.535238578138696, 0.881382293461455, 1.21712702404598, 1.52243154549173)

st_numscalar("max_eta1_diff", max(abs(eta1 - ref_eta1)))
st_numscalar("max_grad1_diff", max(abs(grad1 - ref_grad1)))

// case 2: theta_w=-1.5 (negative - a real fitted coefficient can be
// negative), alpha=0.4, n=4
eta2 = ergm_gwdecay_map(-1.5, 0.4, 4)
grad2 = ergm_gwdecay_gradient(-1.5, 0.4, 4)

// R: ergm:::ergm_GWDECAY$map(c(-1.5,0.4), 4)
ref_eta2 = (-1.50000000000000, -1.99451993094654, -2.15755323901546, -2.21130205251427)
// R: ergm:::ergm_GWDECAY$gradient(c(-1.5,0.4), 4)
ref_grad2 = (1, 1.32967995396436, 1.43836882601030, 1.47420136834285 \ ///
             0, -1.00548006905346, -1.66845331480871, -1.99630679851900)

st_numscalar("max_eta2_diff", max(abs(eta2 - ref_eta2)))
st_numscalar("max_grad2_diff", max(abs(grad2 - ref_grad2)))

// identity check: fixing alpha and taking the resulting eta vector as
// coefficients on esp(1..n) should reproduce the SAME statistic value
// v1's own existing fixed-decay stat_gwesp()/gw_kernel() already
// compute directly - i.e. the curved map, at a fixed alpha, is
// mathematically the fixed-decay term's own per-count decomposition,
// not a different formula that merely happens to look similar. Checked
// on a hand-built 5-node network with a real triangle (so shared-
// partner counts of both 1 and 2 actually occur), comparing
// sum_k(eta_k * esp_count_k) against stat_gwesp()'s own single
// combined value at the same decay.
g = ErgmGraph()
g.init(5, 0)
g.toggle(1,2)
g.toggle(1,3)
g.toggle(2,3)
g.toggle(3,4)
g.toggle(4,5)

td = ErgmTermData()
td.decay = 0.7
direct_gwesp = stat_gwesp(g, td)

// exact-count esp(k) statistics via the already-certified fixed esp()
// term machinery (td.decay reused as a plain scalar - esp() doesn't
// read decay at all, only gw_kernel()-based terms do).
maxd = g.n - 2
tdesp = ErgmTermData()
tdesp.levels = (1..maxd)'
esp_counts = stat_esp(g, tdesp)
eta_fixed = ergm_gwdecay_map(1, 0.7, maxd)
reconstructed_gwesp = sum(eta_fixed :* esp_counts)
st_numscalar("gwesp_identity_diff", abs(direct_gwesp - reconstructed_gwesp))
end

assert max_eta1_diff < 1e-9
assert max_grad1_diff < 1e-9
di "=== curved-decay map/gradient (case 1: theta_w=0.8, alpha=1.3) match R's ergm_GWDECAY to 1e-9 ==="

assert max_eta2_diff < 1e-9
assert max_grad2_diff < 1e-9
di "=== curved-decay map/gradient (case 2: theta_w=-1.5, alpha=0.4) match R's ergm_GWDECAY to 1e-9 ==="

assert gwesp_identity_diff < 1e-9
di "=== curved-decay map at a fixed alpha reproduces v1's own fixed-decay stat_gwesp() via the esp(k) decomposition ==="

* --- ErgmModel-level theta<->eta assembly (harmonisation unit 134):
* generalizes the single-term map/gradient above to a full, possibly-
* mixed model via ErgmModel::theta_to_eta()/theta_to_eta_jacobian().
* NOT yet consumed by MPLE/MCMLE/nwergm.ado - this certifies the
* assembly mechanics themselves in isolation.

mata:
mata set matastrict off

// case A: a model with NO curved terms (edges + nodecov, both
// ordinary) - ntheta() must equal nparam() exactly, theta_to_eta()
// must be the identity, theta_to_eta_jacobian() must be the identity
// matrix. This is the "curved-parameter support changes nothing for
// an ordinary model" regression guard - the single most important
// property for a feature being added on top of already-shipped,
// already-certified estimation code.
Ma = ErgmModel()
Ma.init()
Ma.addterm("edges", 1, &stat_edges(), &change_edges(), ErgmTermData(), ("edges"))
Ma.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), ErgmTermData(), ("nodecov_age"))

thetaA = (1.2, -0.4)
st_numscalar("ntheta_eq_nparam_A", (Ma.ntheta() == Ma.nparam()))
st_numscalar("theta_to_eta_identity_diff", max(abs(Ma.theta_to_eta(thetaA) - thetaA)))
JacA = Ma.theta_to_eta_jacobian(thetaA)
st_numscalar("jacobian_identity_diff", max(abs(JacA - I(2))))

// case B: a MIXED model - edges (ordinary, 1 theta/eta) + a curved
// term with npar=4 (standing in for a curved gwesp with maxd=4, using
// the actual esp() statistic/change functions - the real term this
// will wire to later, not a placeholder). ntheta() must be 1+2=3
// (edges' own 1, plus the curved term's fixed 2), NOT 1+4=5.
Mb = ErgmModel()
Mb.init()
Mb.addterm("edges", 1, &stat_edges(), &change_edges(), ErgmTermData(), ("edges"))
tdb = ErgmTermData()
tdb.levels = (1\2\3\4)
Mb.addterm("esp", 4, &stat_esp(), &change_esp(), tdb, ("esp_1","esp_2","esp_3","esp_4"))
Mb.mark_curved()

st_numscalar("ntheta_B", Mb.ntheta())
st_numscalar("nparam_B", Mb.nparam())

// theta = (edges_coef, curved_weight, curved_alpha) = (1.5, 0.8, 1.3) -
// SAME (weight, alpha) as unit 133's own certified case 1, so the
// curved block of eta/Jacobian below must match those exact reference
// values, not just "some" plausible-looking numbers.
thetaB = (1.5, 0.8, 1.3)
etaB = Mb.theta_to_eta(thetaB)
JacB = Mb.theta_to_eta_jacobian(thetaB)

ref_eta_curved_block = (0.80000000000000, 1.38197456557279, 1.80534255928984, 2.11332931456596)
st_numscalar("etaB_edges_diff", abs(etaB[1] - 1.5))
st_numscalar("etaB_curved_block_diff", max(abs(etaB[(2..5)] - ref_eta_curved_block)))

ref_grad_curved_block = (1, 1.72746820696599, 2.256678199112296, 2.641661643207456 \ ///
                          0, 0.21802543442721, 0.535238578138696, 0.881382293461455)
st_numscalar("jacB_edges_row_diff", max(abs(JacB[1,.] - (1,0,0))))
st_numscalar("jacB_curved_block_diff", max(abs(JacB[(2..5),(2..3)] - ref_grad_curved_block')))
st_numscalar("jacB_offblock_diff", max(abs(JacB[(2..5),1])) + max(abs(JacB[1,(2..3)])))
end

assert ntheta_eq_nparam_A == 1
assert theta_to_eta_identity_diff < 1e-12
assert jacobian_identity_diff < 1e-12
di "=== ErgmModel curved assembly is a strict no-op for an all-ordinary model (identity map, identity Jacobian) ==="

assert ntheta_B == 3
assert nparam_B == 5
assert etaB_edges_diff < 1e-12
assert etaB_curved_block_diff < 1e-9
assert jacB_edges_row_diff < 1e-12
assert jacB_curved_block_diff < 1e-9
assert jacB_offblock_diff < 1e-12
di "=== ErgmModel correctly assembles a mixed (ordinary + curved) model's theta<->eta map and block-diagonal Jacobian ==="

* --- ErgmModel::project_eta_to_theta() (harmonisation unit 135): the
* Gauss-Newton projection step curved MPLE/MCMLE will both reduce to.
* Three checks, reusing Mb/thetaB/etaB from the assembly test above
* (same Mata session, mata set matastrict off).

mata:
mata set matastrict off

// check 1: an all-ORDINARY model's own projection is an exact
// pass-through regardless of W/theta_start/maxit - no iteration ever
// runs for a non-curved block.
proj_A = Ma.project_eta_to_theta(thetaA, I(2), J(1,2,0), 1, 1e-10)
st_numscalar("proj_A_diff", max(abs(proj_A - thetaA)))

// check 2: EXACT recovery when the target is exactly reachable (i.e.
// eta_target = theta_to_eta(true_theta) with no noise at all) -
// starting from a DELIBERATELY different guess, with an arbitrary
// (identity) weight matrix - since the target is exactly on the
// curved manifold, ANY positive-definite weight matrix should drive
// the residual to exactly zero, recovering true_theta itself, not
// merely some other point that happens to weight the same.
theta_start_B = (0, 0.3, 0.5)
proj_B = Mb.project_eta_to_theta(etaB, I(5), theta_start_B, 50, 1e-12)
st_numscalar("proj_B_diff", max(abs(proj_B - thetaB)))

// check 3: GLS stationarity (first-order condition) under a target
// that does NOT exactly lie on the curved manifold (real noise added)
// and a genuinely non-identity weight matrix (different weights per
// eta column) - there is no independently-known "right answer" here,
// so this checks INTERNAL consistency of the optimizer's own stopping
// point instead: at convergence, the weighted gradient of the
// objective w.r.t. the curved block's own theta, J' W (target-map(theta)),
// must be ~0 (the textbook GLS/weighted-least-squares normal equation).
noisy_target = etaB + (0, 0.05, -0.03, 0.04, -0.02)
Wdiag = diag((1, 2, 5, 3, 1))
proj_C = Mb.project_eta_to_theta(noisy_target, Wdiag, theta_start_B, 200, 1e-14)
resid_C = noisy_target[(2..5)] - ergm_gwdecay_map(proj_C[2], proj_C[3], 4)
Jb_C = ergm_gwdecay_gradient(proj_C[2], proj_C[3], 4)'
Wb_C = Wdiag[(2..5),(2..5)]
stationarity_C = Jb_C' * Wb_C * resid_C'
st_numscalar("stationarity_C_max", max(abs(stationarity_C)))
st_numscalar("proj_C_edges_diff", abs(proj_C[1] - noisy_target[1]))
end

assert proj_A_diff < 1e-12
di "=== project_eta_to_theta() is an exact pass-through for an all-ordinary model ==="

assert proj_B_diff < 1e-6
di "=== project_eta_to_theta() exactly recovers the true theta when its target eta is exactly reachable, from a different starting point ==="

assert stationarity_C_max < 1e-8
assert proj_C_edges_diff < 1e-12
di "=== project_eta_to_theta() satisfies the GLS stationarity condition under noise and a non-identity weight matrix (and still passes the ordinary block through exactly) ==="

* --- ErgmMCMLE() curved-model MECHANICAL wiring (harmonisation unit
* 138): NOT a "converges reliably" claim - direct testing on two real
* networks found the underlying MCMC chain can be driven into a
* degenerate (0% acceptance) state even with the backtracking fix
* above, a genuinely deeper outer-loop step-length problem not yet
* solved (see docs/CERTIFICATION.md unit 138 and docs/ERGM_ROADMAP.md
* for the full account) - nwergm.ado deliberately does NOT expose
* method(mcmle) for gwespfree() models as a result. This checks only
* that the plumbing itself is mechanically correct and does not crash:
* ErgmMCMLE()'s own per-iteration eta->theta snap-back populates
* fit.coef_theta at the right dimension (ntheta(), not nparam()),
* fit.coef stays at the full eta dimension throughout, and calling it
* on a genuine curved model does not error - real, valuable coverage
* distinct from (and honestly scoped below) a statistical-reliability
* claim.
mata:
mata set matastrict off

gm = ErgmGraph()
gm.init(5, 0)
gm.toggle(1,2)
gm.toggle(1,3)
gm.toggle(2,3)
gm.toggle(3,4)
gm.toggle(4,5)

tdm = ErgmTermData()
maxdm = 3
tdm.levels = (1..maxdm)'
Mm = ErgmModel()
Mm.init()
Mm.addterm("edges", 1, &stat_edges(), &change_edges(), ErgmTermData(), ("edges"))
Mm.addterm("esp", maxdm, &stat_esp(), &change_esp(), tdm, J(1,maxdm,"x"))
Mm.mark_curved()

theta_c0_m = (0, 0, 0.7)
eta0_m = Mm.theta_to_eta(theta_c0_m)
st_numscalar("mcmle_ntheta", Mm.ntheta())
st_numscalar("mcmle_nparam", Mm.nparam())

fit_m = ErgmMCMLE(Mm, gm, eta0_m, 2, 50, 5, 50, &ergm_propose_uniform(), 0, theta_c0_m)
st_numscalar("mcmle_coef_theta_len", cols(fit_m.coef_theta))
st_numscalar("mcmle_coef_len", cols(fit_m.coef))
st_numscalar("mcmle_ran_ok", 1)
end

assert mcmle_ntheta == 3
assert mcmle_nparam == 4
assert mcmle_coef_theta_len == 3
assert mcmle_coef_len == 4
assert mcmle_ran_ok == 1
di "=== ErgmMCMLE() curved-model plumbing is mechanically correct (right dimensions, no crash) - a scoping note, not a statistical-reliability claim ==="
