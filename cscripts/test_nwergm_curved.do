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
