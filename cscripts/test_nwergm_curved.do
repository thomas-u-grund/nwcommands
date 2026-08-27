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
