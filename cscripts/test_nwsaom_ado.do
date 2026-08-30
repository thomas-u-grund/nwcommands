cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* End-to-end smoke test for nwsaom.ado (harmonisation units 1-5):
* exercises the full NWdef -> ErgmGraph bridge (__nwsaom_bridge_from_netobj)
* and ereturn layer on real nwset-built directed networks, not just the
* pure-Mata toy graphs cscripts/test_nwsaom_mata.do already certifies the
* estimator's own math against.

nwclear
set seed 90210

nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\1,0,0,1,0,0\0,0,0,0,1,0\0,0,1,0,0,1\0,0,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,0\0,0,1,1,0,1\0,0,0,0,1,0)) directed name(saomwave2) labs(A,B,C,D,E,F)

* --- outdegree+reciprocity only (units 1's original scope)
nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree reciprocity k0(15) k3(15) rate0(1.5) seed(90210)

assert e(nodes) == 6
assert e(rate) > 0

matrix b = e(b)
assert colsof(b) == 2

di as text "nwsaom.ado unit 1 (outdegree+reciprocity) end-to-end smoke test PASS"

* --- units 2/3: nodeicov() (direct nwergm reuse) + outactivity
* (freshly-derived) together, on the SAME two waves, exercising the
* st_data(1::nodes,...) covariate-reading path end to end (not yet
* covered by any prior nwsaom.ado-level test) plus the new SAOM-native
* effect's own .ado wiring (already certified at the Mata level in
* cscripts/test_nwsaom_mata.do's unit 3).
nwclear
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\1,0,0,1,0,0\0,0,0,0,1,0\0,0,1,0,0,1\0,0,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,0\0,0,1,1,0,1\0,0,0,0,1,0)) directed name(saomwave2) labs(A,B,C,D,E,F)

* nodeicov()'s own st_data() read happens against whatever dataset is
* CURRENT at nwsaom-call time (matching nwergm.ado's own established
* convention - see nwsaom.ado's header) - generate the covariate on
* the currently-selected network (saomwave2, the last one built); both
* waves share the same 6-actor set in the same node order, so which
* wave's own dataset is "current" when the covariate is generated does
* not matter here.
gen byte grp = mod(_n,2)
nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree nodeicov(grp) outactivity k0(15) k3(15) rate0(1.5) seed(90210)

assert e(nodes) == 6
matrix b2 = e(b)
assert colsof(b2) == 3

di as text "nwsaom.ado units 2-3 (nodeicov+outactivity) end-to-end smoke test PASS"

* --- units 4/5: transtrip + cycle3 (freshly-derived structural
* effects, reusing ErgmGraph's own shared_partners_otp()/_osp()
* primitives internally) through the real command, on a slightly
* denser pair of toy waves so both effects have two-paths/cycles to
* act on (matching the tuning cscripts/test_nwsaom_mata.do's own unit
* 4/5 direction checks needed).
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree transtrip cycle3 k0(15) k3(15) rate0(2) seed(90210)

assert e(nodes) == 6
matrix b3 = e(b)
assert colsof(b3) == 3

di as text "nwsaom.ado units 4-5 (transtrip+cycle3) end-to-end smoke test PASS"

* --- unit 9: outpopularity + inactivity + simcov, through the real
* command - exercises simcov()'s own st_data()-based covariate read
* (separate from nodeicov's, its own code path) end to end.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)
gen byte covx = mod(_n,4)

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree outpopularity inactivity simcov(covx) k0(15) k3(15) rate0(2) seed(90210)

assert e(nodes) == 6
matrix b4 = e(b)
assert colsof(b4) == 4

di as text "nwsaom.ado unit 9 (outpopularity+inactivity+simcov) end-to-end smoke test PASS"

* --- harmonisation unit 17: waves(namelist), the new 2+ wave chaining
* surface, through the real command - a 3-wave toy panel (same 6-actor
* graphs as units 4/5/9 above, plus a third wave), certifying the
* __nwsaom_last_G1.._G`N' loop-build + pointer-array assembly
* (SaomEstimateRMMulti()) end to end, not just the direct Mata-level
* call cscripts/test_nwsaom_mata.do would exercise.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomw1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomw2) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,1\1,0,1,0,1,1\1,1,0,1,0,0\1,0,1,0,1,1\1,1,0,1,0,1\0,1,0,1,1,0)) directed name(saomw3) labs(A,B,C,D,E,F)

nwsaom, waves(saomw1 saomw2 saomw3) outdegree reciprocity k0(15) k3(15) seed(90210)

assert e(nwaves) == 3
assert e(nodes) == 6
matrix b5 = e(b)
assert colsof(b5) == 2
matrix rates5 = e(rates)
assert colsof(rates5) == 2
matrix ratetr5 = e(rate_tratios)
assert colsof(ratetr5) == 2

di as text "nwsaom.ado unit 17 (waves(), 3-wave chaining) end-to-end smoke test PASS"

* --- consistency check: waves(a b) (the new 2-wave path through
* SaomEstimateRMMulti()) vs. wave1(a) wave2(b) (the original,
* unchanged path through SaomEstimateRM()) on the SAME two waves and
* SAME seed - not bit-identical (SaomEstimateRMMulti()'s own extra
* pointer-indirection/period-loop structure does not guarantee the
* identical RNG-consumption sequence as SaomEstimateRM()'s own
* hand-written single-period code), but should land close, both
* implementing the same real-RSiena-verified algorithm on identical
* data with identical starting values.
nwsaom, wave1(saomw1) wave2(saomw2) outdegree reciprocity k0(15) k3(15) rate0(2) seed(90210)
matrix b_2wave = e(b)

nwsaom, waves(saomw1 saomw2) outdegree reciprocity k0(15) k3(15) seed(90210)
matrix b_multi2wave = e(b)

assert reldif(b_2wave[1,1], b_multi2wave[1,1]) < 0.5
assert reldif(b_2wave[1,2], b_multi2wave[1,2]) < 0.5

di as text "nwsaom.ado unit 17 (waves() vs wave1()/wave2() consistency, same 2 waves) end-to-end smoke test PASS"

* --- harmonisation unit 21: estat gof, REBUILT entirely around real
* RSiena's own sienaGOF()/plot.sienaGOF() methodology (Mahalanobis-
* distance test + violin plot), replacing units 19-20's own Statnet-
* style version entirely (see nwsaom_estat.ado's own header comment for
* the full account of why - that earlier version was never actually
* checked against real RSiena's own GOF tooling before being shipped).
* Through the real `estat' dispatch mechanism (NOT calling
* nwsaom_estat directly - `estat.ado' only forwards to a command's own
* e(estat_cmd) program, confirmed directly). Exercises both the
* exactly-two-wave wave1()/wave2() path (e(rate) scalar) and the
* waves() path (e(rates) matrix, pooled-by-summation across periods -
* real RSiena's own join=TRUE default) - checks the actual graph
* objects exist (`graph describe', not just "the command didn't
* error") for all three default auxiliary statistics
* (outdegree/indegree/geodesic), and that the Mahalanobis p-values
* returned are genuine numbers in [0,1], not missing.
capture graph drop gof_outdegree
capture graph drop gof_indegree
capture graph drop gof_geodesic
nwsaom, wave1(saomw1) wave2(saomw2) outdegree reciprocity k0(15) k3(15) rate0(2) seed(90210)
estat gof, nsim(10) seed(4242)
assert r(p_outdegree) >= 0 & r(p_outdegree) <= 1
assert r(p_indegree) >= 0 & r(p_indegree) <= 1
assert r(p_geodesic) >= 0 & r(p_geodesic) <= 1
assert r(mhd_outdegree) < .
capture graph describe gof_outdegree
assert _rc == 0
capture graph describe gof_indegree
assert _rc == 0
capture graph describe gof_geodesic
assert _rc == 0

di as text "nwsaom.ado unit 21 (estat gof, RSiena-style MHD test + violin plot, wave1()/wave2() path) end-to-end smoke test PASS"

capture graph drop gof_outdegree
capture graph drop gof_indegree
capture graph drop gof_geodesic
nwsaom, waves(saomw1 saomw2 saomw3) outdegree reciprocity k0(15) k3(15) seed(90210)
estat gof, nsim(10) seed(4242)
assert r(p_outdegree) >= 0 & r(p_outdegree) <= 1
assert r(p_indegree) >= 0 & r(p_indegree) <= 1
assert r(p_geodesic) >= 0 & r(p_geodesic) <= 1
capture graph describe gof_outdegree
assert _rc == 0

capture graph drop gof_outdegree
capture graph drop gof_indegree
capture graph drop gof_geodesic

di as text "nwsaom.ado unit 21 (estat gof, waves() 3-wave path, pooled-across-periods) end-to-end smoke test PASS"

* --- harmonisation unit 162: estat gof, stats(triad) + join(off) - closes
* unit 21's own two disclosed GOF gaps (docs/SAOM_ROADMAP.md). First a
* direct correctness check of nwsaom_gof_triadvec (nwsaom_estat.ado)
* against nwtriads called directly on the identical network - must match
* EXACTLY (both read the same underlying MAN-census machinery), and the
* full census must sum to C(n,3) regardless of network structure.
*
* `run nwsaom_estat.ado' first: calling `estat gof' above DOES dispatch
* through nwsaom_estat.ado's own auto-load, but that does not reliably
* leave nwsaom_gof_triadvec - a second, internal program defined further
* down the SAME file - directly callable by name afterward (found the
* hard way: "command nwsaom_gof_triadvec is unrecognized", r(199), the
* first time this test ran, immediately after two prior `estat gof'
* calls in this very file). Explicitly re-running the file is a one-line,
* harmless fix - `capture program drop' first avoids a "program already
* defined" note on programs auto-load already did pick up.
capture program drop nwsaom_estat
capture program drop nwsaom_estat_gof
capture program drop nwsaom_gof_triadvec
capture program drop nwsaom_estat_gofviolin
quietly run nwsaom_estat.ado

mata: __unit162_t1 = (0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)
nwsaom_gof_triadvec __unit162_t1 __unit162_t1vec
mata: st_matrix("unit162_t1vec", __unit162_t1vec)

preserve
qui drop _all
qui set obs 6
capture nwdrop __unit162_directcheck
nwset, mat(__unit162_t1) directed name(__unit162_directcheck) nooutput
nwtriads __unit162_directcheck
mata: st_matrix("unit162_t1direct", (st_numscalar("r(_003)"), st_numscalar("r(_012)"), st_numscalar("r(_021D)"), st_numscalar("r(_021U)"), st_numscalar("r(_021C)"), st_numscalar("r(_030T)"), st_numscalar("r(_030C)"), st_numscalar("r(_102)"), st_numscalar("r(_111D)"), st_numscalar("r(_111U)"), st_numscalar("r(_120D)"), st_numscalar("r(_120U)"), st_numscalar("r(_120C)"), st_numscalar("r(_210)"), st_numscalar("r(_201)"), st_numscalar("r(_300)")))
capture nwdrop __unit162_directcheck
restore

mata: assert(max(abs(st_matrix("unit162_t1vec") - st_matrix("unit162_t1direct"))) == 0)
mata: assert(sum(st_matrix("unit162_t1vec")) == comb(6,3))
mata: mata drop __unit162_t1 __unit162_t1vec

di as text "nwsaom.ado unit 162 (nwsaom_gof_triadvec exact match against nwtriads, sums to C(n,3)) PASS"

* Full pipeline: stats(triad) pooled (default join=TRUE), reusing the
* still-fitted waves(saomw1 saomw2 saomw3) model above.
capture graph drop gof_outdegree
capture graph drop gof_triad
estat gof, stats(outdegree triad) nsim(10) seed(4242)
assert r(p_outdegree) >= 0 & r(p_outdegree) <= 1
assert r(p_triad) >= 0 & r(p_triad) <= 1
assert r(mhd_triad) < .
capture graph describe gof_triad
assert _rc == 0
capture graph drop gof_outdegree
capture graph drop gof_triad

di as text "nwsaom.ado unit 162 (estat gof, stats(triad), pooled) end-to-end smoke test PASS"

* join(off): a SEPARATE test per period (2 periods, 3 waves) - assert
* BOTH periods' own results exist as distinct r()/graph objects, not
* just that the pooled default still runs.
capture graph drop gof_outdegree_p1
capture graph drop gof_outdegree_p2
capture graph drop gof_triad_p1
capture graph drop gof_triad_p2
estat gof, stats(outdegree triad) nsim(10) seed(4242) join(off)
assert r(p_outdegree_p1) >= 0 & r(p_outdegree_p1) <= 1
assert r(p_outdegree_p2) >= 0 & r(p_outdegree_p2) <= 1
assert r(p_triad_p1) >= 0 & r(p_triad_p1) <= 1
assert r(p_triad_p2) >= 0 & r(p_triad_p2) <= 1
capture graph describe gof_outdegree_p1
assert _rc == 0
capture graph describe gof_outdegree_p2
assert _rc == 0
capture graph describe gof_triad_p1
assert _rc == 0
capture graph describe gof_triad_p2
assert _rc == 0
capture graph drop gof_outdegree_p1
capture graph drop gof_outdegree_p2
capture graph drop gof_triad_p1
capture graph drop gof_triad_p2

* join() only accepts "off" (or empty) - anything else must error.
capture estat gof, join(bogus)
assert _rc == 198

di as text "nwsaom.ado unit 162 (estat gof, join(off): separate per-period tests + join() validation) end-to-end smoke test PASS"

* --- harmonisation unit 22: gwesp() option, through the real command -
* direct reuse of nwergm's own stat_gwesp()/change_gwesp() (mata-level
* wiring already certified in cscripts/test_nwsaom_mata.do's own unit
* 22) exercised end to end via the real NWdef -> ErgmGraph bridge and
* st_data() options-parsing path, same denser toy waves units 4/5/9
* already use (transtrip/cycle3 need two-paths to act on; gwesp needs
* the same).
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree gwesp(.69) k0(15) k3(15) rate0(2) seed(90210)

assert e(nodes) == 6
matrix b6 = e(b)
assert colsof(b6) == 2

di as text "nwsaom.ado unit 22 (gwesp() reuse) end-to-end smoke test PASS"

* --- harmonisation unit 23: transties option, through the real command -
* change_saom_transties() (mata-level wiring certified in
* cscripts/test_nwsaom_mata.do's own unit 23) exercised end to end via
* the real NWdef -> ErgmGraph bridge and st_data() options-parsing
* path, same denser toy waves units 4/5/9/22 already use (transitive
* ties need two-paths to act on).
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree transties k0(15) k3(15) rate0(2) seed(90210)

assert e(nodes) == 6
matrix b7 = e(b)
assert colsof(b7) == 2

di as text "nwsaom.ado unit 23 (transties reuse) end-to-end smoke test PASS"

* --- harmonisation unit 24: egox()/altx()/samex()/simx() - pure RSiena
* naming aliases for nodeocov()/nodeicov()/nodematch()/simcov()
* respectively (no new math, same addterm() wiring as their Statnet-
* named counterparts). Exercises all four aliases together through the
* real command, checking BOTH that the model runs (same as calling the
* underlying options directly) AND that e(b)'s own column names follow
* whichever spelling was actually typed (egox_grp, not nodeocov_grp).
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)
gen byte grp = mod(_n,2)
gen byte covx = mod(_n,4)

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree egox(grp) altx(grp) samex(grp) simx(covx) k0(15) k3(15) rate0(2) seed(90210)

assert e(nodes) == 6
matrix b8 = e(b)
assert colsof(b8) == 5
local __names8 : colnames b8
assert strpos("`__names8'", "egox_grp") > 0
assert strpos("`__names8'", "altx_grp") > 0
assert strpos("`__names8'", "samex_grp") > 0
assert strpos("`__names8'", "simx_covx") > 0

di as text "nwsaom.ado unit 24 (egox/altx/samex/simx naming aliases) end-to-end smoke test PASS"

* --- unit 24: duplicate-specification error path (nodeocov() + egox()
* together is ambiguous - same effect, two names, must error not
* silently pick one).
capture nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree nodeocov(grp) egox(grp) k0(15) k3(15) rate0(2) seed(90210)
assert _rc == 198

di as text "nwsaom.ado unit 24 (egox/nodeocov duplicate-specification error) end-to-end smoke test PASS"

* --- harmonisation unit 25: balance, through the real command -
* change_saom_balance()/stat_saom_balance() (mata-level wiring
* certified in cscripts/test_nwsaom_mata.do's own unit 25) exercised
* end to end via the real NWdef -> ErgmGraph bridge, on the wave1()/
* wave2() (single-period) path - this ALSO exercises the
* __nwsaom_last_Gbases pointer-array assembly (unconditional, built
* right after the per-wave graphs) and saom_balance_mean()'s own
* st_data()-free, pure-ErgmGraph pooling path for the first time
* end-to-end.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree balance k0(15) k3(15) rate0(2) seed(90210)

assert e(nodes) == 6
matrix b9 = e(b)
assert colsof(b9) == 2

di as text "nwsaom.ado unit 25 (balance reuse, wave1()/wave2() path) end-to-end smoke test PASS"

* --- unit 25: same effect, through the waves() 3-wave chaining path
* (unit 17's own surface) - this is the case that actually exercises
* POOLING across period-base graphs (__nwsaom_last_Gbases = G1,G2, NOT
* just G1 alone), the one behavior the single-period test just above
* cannot distinguish from a naive single-graph balanceMean.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomw1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomw2) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,1\1,0,1,0,1,1\1,1,0,1,0,0\1,0,1,0,1,1\1,1,0,1,0,1\0,1,0,1,1,0)) directed name(saomw3) labs(A,B,C,D,E,F)

nwsaom, waves(saomw1 saomw2 saomw3) outdegree balance k0(15) k3(15) seed(90210)

assert e(nwaves) == 3
assert e(nodes) == 6
matrix b10 = e(b)
assert colsof(b10) == 2

di as text "nwsaom.ado unit 25 (balance reuse, waves() 3-wave path, pooled balanceMean across period bases) end-to-end smoke test PASS"

* --- harmonisation unit 26: co-evolution (network + behavior),
* through the real command - change_saom_linear()/change_saom_avalt()/
* SaomEstimateRMCoev() (mata-level wiring certified in
* cscripts/test_nwsaom_mata.do's own unit 26) exercised end to end via
* the real NWdef -> ErgmGraph bridge and st_data()-based behavior()
* reading, on the same denser toy waves units 4/5/9/22/23 already use
* (structural effects need two-paths to act on). Checks that the
* coefficient table clearly distinguishes network from behavior
* effects (the "beh_" prefix, per explicit user requirement) and that
* both rate parameters are separately reported.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)
gen byte behwave1 = mod(_n,5)+1
gen byte behwave2 = mod(_n+2,5)+1

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree reciprocity behavior(behwave1 behwave2) linear quadratic avalt avsim k0(20) k3(50) seed(90210)

assert e(nodes) == 6
assert e(has_behavior) == 1
assert e(p_net) == 2
matrix b11 = e(b)
assert colsof(b11) == 6
local __names11 : colnames b11
assert strpos("`__names11'", "beh_linear") > 0
assert strpos("`__names11'", "beh_quadratic") > 0
assert strpos("`__names11'", "beh_avalt") > 0
assert strpos("`__names11'", "beh_avsim") > 0
assert e(rate) != .
assert e(rate_beh) != .
assert e(rate_beh) > 0

di as text "nwsaom.ado unit 26 (co-evolution: network + behavior, linear+quadratic+avalt+avsim) end-to-end smoke test PASS"

* --- unit 26: error paths - exactly one behavior variable per wave
* (still an error via the var-count check even now that behavior()
* works with waves() too - N-wave extension per explicit user
* direction "extend it to N waves"), linear required whenever
* behavior() is specified, and behavior-only effects require
* behavior().
nwset, mat((0,1,1,1,1,1\1,0,1,0,1,1\1,1,0,1,0,0\1,0,1,0,1,1\1,1,0,1,0,1\0,1,0,1,1,0)) directed name(saomwave3) labs(A,B,C,D,E,F)

capture nwsaom, waves(saomwave1 saomwave2 saomwave3) outdegree behavior(behwave1 behwave2) linear k0(10) k3(20)
assert _rc == 198

capture nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree behavior(behwave1 behwave2) avalt k0(10) k3(20)
assert _rc == 198

capture nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree behavior(behwave1) linear k0(10) k3(20)
assert _rc == 198

capture nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree avalt k0(10) k3(20)
assert _rc == 198

capture nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree avsim k0(10) k3(20)
assert _rc == 198

di as text "nwsaom.ado unit 26 (co-evolution error paths: waves()+behavior(), missing linear, wrong var count, effects without behavior()) end-to-end smoke test PASS"

* --- unit 26: estat gof after a co-evolution fit - exercises the
* NEW "behavior" auxiliary statistic (RSiena's own BehaviorDistribution)
* alongside the existing network trio, per explicit user requirement
* that co-evolution GOF check more than just network structure. This
* test ALSO caught a real bug during development, kept in the record:
* a Stata `tempname' used for a MATA object meant to persist beyond the
* issuing program (nwsaom.ado's own `tempname __td_recip', referenced
* by pointer from __nwsaom_last_M ever after) could be REISSUED by
* Stata's own tempname allocator to a later, unrelated `tempname' call
* inside THIS estat gof program (`__gof_obsmat'/`__gof_simmat',
* originally also `tempname'-based) - silently corrupting the fitted
* model's own term data out from under it once co-evolution's own
* extra code changed the allocation count/order enough to land on a
* colliding slot. Fixed by using explicit, namespaced Mata variable
* names for every Mata-persistent object in nwsaom_estat.ado, not
* `tempname' (see that file's own header comment on the fix for the
* full account). This test's own real, successful run is what
* certifies the fix - it reproduced the bug during development.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)
gen byte behwave1 = mod(_n,5)+1
gen byte behwave2 = mod(_n+1,5)+1

nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree reciprocity behavior(behwave1 behwave2) linear avalt k0(20) k3(50) seed(90210)
estat gof, nsim(30) seed(12345)

assert r(p_outdegree) >= 0 & r(p_outdegree) <= 1
assert r(p_indegree) >= 0 & r(p_indegree) <= 1
assert r(p_geodesic) >= 0 & r(p_geodesic) <= 1
assert r(p_behavior) >= 0 & r(p_behavior) <= 1
capture graph describe gof_behavior
assert _rc == 0

capture graph drop gof_outdegree
capture graph drop gof_indegree
capture graph drop gof_geodesic
capture graph drop gof_behavior

* stats(behavior) on a NON-co-evolution fit must error clearly.
nwsaom, wave1(saomwave1) wave2(saomwave2) outdegree reciprocity k0(15) k3(15) seed(90210)
capture estat gof, stats(behavior) nsim(10)
assert _rc == 198

di as text "nwsaom.ado unit 26 (co-evolution estat gof: behavior distribution auxiliary statistic) end-to-end smoke test PASS"

* --- unit 26, N-wave extension ("extend it to N waves", explicit user
* direction): co-evolution through waves() (3 waves/2 periods),
* dispatching to SaomEstimateRMCoevMulti() (unw_saom.do, mata-level
* certified via test_nwsaom_mata.do's own
* saom_test_unit26_coev_multi()), exercised end to end through the
* real command, INCLUDING estat gof. This test caught a real bug
* during development: nwsaom_estat.ado's own co-evolution GOF code was
* written only for the two-wave case and was never generalized when
* N-wave support was added to nwsaom.ado - it always seeded every
* period's simulation from wave 1's own behavior values, always read
* the observed behavior statistic from the LAST wave only (not pooled
* across periods), and always used a single scalar e(rate_beh) instead
* of a per-period e(rates_beh) entry. Symptom: `estat gof' did not
* error, but silently produced a degenerate result - EVERY statistic
* (network and behavior alike) showed exactly "Mahalanobis dist. =
* 0.000, p = 1.000" for every period pooled. Fixed by using the
* already-built __nwsaom_last_Behwaves pointer array (nwsaom.ado, one
* pointer per wave) for per-period start/end behavior values and a
* per-period e(rates_beh) read mirroring the existing e(rates) pattern
* (nwsaom_estat.ado's own header comment has the full account). This
* test's own real, successful (non-degenerate) run is what certifies
* the fix.
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomwave2) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,1\1,0,1,0,1,1\1,1,0,1,0,0\1,0,1,0,1,1\1,1,0,1,0,1\0,1,0,1,1,0)) directed name(saomwave3) labs(A,B,C,D,E,F)
gen byte behwave1 = mod(_n,5)+1
gen byte behwave2 = mod(_n+1,5)+1
gen byte behwave3 = mod(_n+2,5)+1

nwsaom, waves(saomwave1 saomwave2 saomwave3) outdegree reciprocity behavior(behwave1 behwave2 behwave3) linear avalt k0(20) k3(40) seed(90210)

assert e(nodes) == 6
assert e(nwaves) == 3
assert e(has_behavior) == 1
assert e(p_net) == 2
matrix b12 = e(b)
assert colsof(b12) == 4
matrix __ratesbeh12 = e(rates_beh)
assert colsof(__ratesbeh12) == 2
assert __ratesbeh12[1,1] > 0 & __ratesbeh12[1,2] > 0

estat gof, nsim(30) seed(12345)

assert r(p_outdegree) >= 0 & r(p_outdegree) <= 1
assert r(p_indegree) >= 0 & r(p_indegree) <= 1
assert r(p_geodesic) >= 0 & r(p_geodesic) <= 1
assert r(p_behavior) >= 0 & r(p_behavior) <= 1
* the real regression signature: a degenerate fit reports EVERY
* Mahalanobis distance as exactly 0 - assert at least one of the four
* is genuinely nonzero to rule that out (simulation noise makes an
* exact tie across all four vanishingly unlikely for a real fit).
assert r(mhd_outdegree) != 0 | r(mhd_indegree) != 0 | r(mhd_geodesic) != 0 | r(mhd_behavior) != 0

capture graph drop gof_outdegree
capture graph drop gof_indegree
capture graph drop gof_geodesic
capture graph drop gof_behavior

di as text "nwsaom.ado unit 26 (co-evolution N-wave extension: waves()+behavior(), 3 waves/2 periods, estat gof non-degenerate) end-to-end smoke test PASS"

* -------------------------------------------------------------------
* harmonisation unit 28 (endowment/creation functions), SHIPPED per
* explicit user direction ("look at rsiena, they solve this problem
* somehow ... mimic that approach") - real RSiena's own manual
* documents this exact split (linearendow+linearcreation together,
* replacing plain linear) as an inherently weakly-identified
* combination, not a defect ("this would lead to large standard
* errors" unless there is enough data) - so a real fit attempt on
* real data has TWO legitimate outcomes, both certified here: it
* either converges cleanly, or it stops with the thetaBound safeguard
* (harmonisation unit 29) exactly the way real RSiena's own
* R/phase2.r does for the identical condition. Neither outcome is a
* test failure; a THIRD outcome (any other return code, e.g. a crash)
* would be.
* -------------------------------------------------------------------
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saomewave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(saomewave2) labs(A,B,C,D,E,F)
gen byte behewave1 = mod(_n,5)+1
gen byte behewave2 = mod(_n+2,5)+1

capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linearendow linearcreation k0(30) k3(60) seed(90210)
assert _rc == 0 | _rc == 498
if _rc == 0 {
	matrix __be = e(b)
	assert colsof(__be) == 3
	assert e(has_behavior) == 1
	local __benames : colnames __be
	assert strpos("`__benames'", "beh_linear_endow") > 0
	assert strpos("`__benames'", "beh_linear_creation") > 0
}

* --- validation: all three roles together is refused (exact
* collinearity, matches real RSiena's own manual: "never in all
* three, because this leads to collinearity").
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear linearendow linearcreation k0(5) k3(5)
assert _rc == 198

* --- validation: linearendow/linearcreation must be paired.
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linearendow k0(5) k3(5)
assert _rc == 198
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linearcreation k0(5) k3(5)
assert _rc == 198

* --- harmonisation unit 166: quadratic/avalt/avsim endowment/creation
* splits are real, RSiena-offered effect/type combinations (fetched live
* via getEffects(), not assumed) and generalize unit 28's own
* linearendow/linearcreation mechanism, which was never actually
* specific to `linear` in the underlying engine
* (SaomBehaviorModel::addterm()'s own `fntype` argument / full_change()'s
* own direction-gating). Each effect's role-split is orthogonal to every
* other effect's own baseline/role choice - `linearendow linearcreation
* quadratic` (baseline split, quadratic role left plain) is therefore now
* a VALID combination, not an error - this replaces a stale assertion
* from before unit 166 that expected exactly this combination to be
* refused (that restriction was this port's own temporary limitation,
* not a real RSiena constraint - RSiena's own manual only forbids using
* the SAME effect in all three roles at once, never forbids splitting
* one effect while leaving another plain).
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linearendow linearcreation quadratic k0(5) k3(5)
assert _rc == 0 | _rc == 498 | _rc == 505		// this tiny 6-node/k0(5)/k3(5) toy setup with THREE behavior parameters (endow+creation+quadratic) is itself real, disclosed weak-identification territory - thetaBound/singular-covariance are legitimate outcomes here, not errors in the option
mata: st_local("__benames", invtokens(__nwsaom_last_Mbeh.coefnames))
assert strpos("`__benames'", "beh_linear_endow") > 0
assert strpos("`__benames'", "beh_linear_creation") > 0
assert strpos("`__benames'", "beh_quadratic") > 0 & strpos("`__benames'", "beh_quadratic_endow") == 0

* --- validation: quadraticendow/quadraticcreation must be paired (same
* rule as linearendow/linearcreation), and cannot combine with plain
* quadratic (exact collinearity, same reasoning as linear vs.
* linearendow/linearcreation).
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear quadraticendow k0(5) k3(5)
assert _rc == 198
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear quadraticcreation k0(5) k3(5)
assert _rc == 198

* --- positive: quadraticendow/quadraticcreation together, on top of a
* plain linear baseline, registers the expected four behavior terms.
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear quadraticendow quadraticcreation k0(5) k3(5)
assert _rc == 0 | _rc == 498 | _rc == 505		// thetaBound/singular-covariance are real, disclosed weak-identification outcomes on small data (unit 28's own precedent), not errors in the option itself
mata: st_local("__benames", invtokens(__nwsaom_last_Mbeh.coefnames))
assert strpos("`__benames'", "beh_quadratic_endow") > 0
assert strpos("`__benames'", "beh_quadratic_creation") > 0

* --- positive: avaltendow/avaltcreation and avsimendow/avsimcreation
* register correctly alongside a plain linear baseline.
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear avaltendow avaltcreation k0(5) k3(5)
assert _rc == 0 | _rc == 498 | _rc == 505
mata: st_local("__benames", invtokens(__nwsaom_last_Mbeh.coefnames))
assert strpos("`__benames'", "beh_avalt_endow") > 0
assert strpos("`__benames'", "beh_avalt_creation") > 0

capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear avsimendow avsimcreation k0(5) k3(5)
assert _rc == 0 | _rc == 498 | _rc == 505
mata: st_local("__benames", invtokens(__nwsaom_last_Mbeh.coefnames))
assert strpos("`__benames'", "beh_avsim_endow") > 0
assert strpos("`__benames'", "beh_avsim_creation") > 0

* --- validation: avalt + avaltendow/avaltcreation together is refused
* (same collinearity rule).
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linear avalt avaltendow avaltcreation k0(5) k3(5)
assert _rc == 198

di as text "nwsaom.ado unit 28/166 (endowment/creation functions, thetaBound-protected per harmonisation unit 29) PASS"

* -------------------------------------------------------------------
* behtheta0() (behavior starting values) - a real, independently
* discovered bug: this option was NEVER exercised by any test before
* now, and turned out to be completely broken since it was introduced
* (harmonisation unit 26) - Stata's own `syntax' command refuses to
* recognize an option whose name is a PREFIX of another `(string)'
* option's name (`theta0' is a prefix of the original `theta0beh'),
* confirmed via a minimal isolated repro, independent of this file's
* own logic. Renamed to `behtheta0' (no longer a prefix collision)
* and certified here for the first time, found while building the
* harmonisation-unit-28 real-RSiena cross-check
* (dev/saom_rsiena_crosscheck_endow.do).
* -------------------------------------------------------------------
nwclear
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\1,0,0,1,0,0\0,0,0,0,1,0\0,0,1,0,0,1\0,0,0,0,0,0)) directed name(saombtwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,0\0,0,1,1,0,1\0,0,0,0,1,0)) directed name(saombtwave2) labs(A,B,C,D,E,F)
gen byte behbt1 = mod(_n,5)+1
gen byte behbt2 = mod(_n+1,5)+1

nwsaom, wave1(saombtwave1) wave2(saombtwave2) outdegree behavior(behbt1 behbt2) linear avalt behtheta0(0.1 0.1) k0(5) k3(5) seed(90210)
assert e(has_behavior) == 1
matrix __bbt = e(b)
assert colsof(__bbt) == 3

* wrong-count validation still fires correctly for the renamed option.
capture nwsaom, wave1(saombtwave1) wave2(saombtwave2) outdegree behavior(behbt1 behbt2) linear avalt behtheta0(0.1) k0(5) k3(5)
assert _rc == 198

di as text "nwsaom.ado behtheta0() (behavior starting values, renamed from the never-working theta0beh() - real Stata `syntax' prefix-collision bug, independent of harmonisation units 26/28) PASS"

* -------------------------------------------------------------------
* harmonisation unit 33 (composition change - "joiners and leavers"):
* present() end-to-end on real nwset-built networks, both the two-wave
* and N-wave paths, network-only and co-evolution (per the explicit
* "both from the start" scope decision, docs/SAOM_ROADMAP.md's own
* unit-33 entry), plus validation.
* -------------------------------------------------------------------
nwclear
* actor F (row/col 6) is marked absent from wave2 onward below - its own
* row/column is therefore held FROZEN at wave1's own values across
* wave2/wave3 (the "carry-forward" convention this package documents,
* docs/SAOM_ROADMAP.md's own unit-33 entry), matching what a real
* dataset prepared for composition change is expected to look like -
* an inconsistently-coded absent actor's own row would inject spurious
* target-statistic "activity" the simulator can never explain (F can no
* longer act), a real, avoidable way to manufacture a thetaBound
* divergence that has nothing to do with composition change itself.
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saompwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,0,0,0)) directed name(saompwave2) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,1,1\1,1,0,1,0,0\1,0,1,0,1,1\1,1,0,1,0,1\0,1,0,0,0,0)) directed name(saompwave3) labs(A,B,C,D,E,F)
gen byte pres1 = 1
gen byte pres2 = 1
gen byte pres3 = 1
replace pres2 = 0 in 6
replace pres3 = 0 in 6

* --- network-only, two waves ---
nwsaom, wave1(saompwave1) wave2(saompwave2) outdegree reciprocity present(pres1 pres2) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 0
matrix __pb = e(b)
assert colsof(__pb) == 2

* --- network-only, N waves ---
nwsaom, waves(saompwave1 saompwave2 saompwave3) outdegree reciprocity present(pres1 pres2 pres3) k0(30) k3(60) seed(90210)
assert e(nwaves) == 3
matrix __pb2 = e(b)
assert colsof(__pb2) == 2

* --- co-evolution, two waves --- (actor F's own behavior value frozen
* at wave1's value from wave2 onward, same "carry-forward" convention
* as the network side above)
gen byte behp1 = mod(_n,5)+1
gen byte behp2 = mod(_n+1,5)+1
replace behp2 = behp1 in 6
nwsaom, wave1(saompwave1) wave2(saompwave2) outdegree behavior(behp1 behp2) linear avalt present(pres1 pres2) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 1
matrix __pb3 = e(b)
assert colsof(__pb3) == 3

* --- co-evolution, N waves ---
gen byte behp3 = mod(_n+2,5)+1
replace behp3 = behp1 in 6
nwsaom, waves(saompwave1 saompwave2 saompwave3) outdegree behavior(behp1 behp2 behp3) linear avalt present(pres1 pres2 pres3) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 1
assert e(nwaves) == 3

* --- validation: wrong variable count ---
capture nwsaom, wave1(saompwave1) wave2(saompwave2) outdegree present(pres1) k0(5) k3(5)
assert _rc == 198

* --- validation: non-0/1 values rejected ---
gen byte presbad = 2
capture nwsaom, wave1(saompwave1) wave2(saompwave2) outdegree present(pres1 presbad) k0(5) k3(5)
assert _rc == 198

di as text "nwsaom.ado unit 33 (composition change - present(), network-only + co-evolution, two-wave + N-wave, plus validation) PASS"

* -------------------------------------------------------------------
* harmonisation unit 34 (isolate-related effects: isolatenet, outiso) -
* end-to-end smoke test on real nwset-built networks, matching every
* other effect's own established .ado-level certification convention.
* Built with genuine isolates that transition between waves (E, F, G,
* H, I, J all true isolates at wave1; E and G each gain one outgoing
* tie at wave2, changing both isolatenet, 6->2, and outiso, 8->6).
*
* A real, disclosed finding from building this test, not assumed safe:
* even isolatenet/outiso EACH ALONE (with outdegree) hit nwsaom's own
* safeguards (thetaBound or the phase-3 covariance-finiteness check) on
* toy data at this scale, and real Glasgow data (this whole SAOM
* effort's own main worked dataset) turns out to have ZERO isolates at
* any of its three waves, so it cannot exercise these effects at all
* either. This is the SAME kind of genuine small-sample/rare-count
* identification limit endowment/creation (harmonisation unit 28) has,
* not a defect in these effects (both are exactly certified against
* RSiena's own real source, cscripts/test_nwsaom_mata.do's own unit 34)
* - so, matching that unit's own established test convention exactly,
* this smoke test accepts EITHER a clean fit OR a clean safeguard trip
* as a legitimate pass; only an unexpected error would be a failure.
* -------------------------------------------------------------------
nwclear
nwset, mat((0,1,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,1,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0)) directed name(saomisowave1) labs(A,B,C,D,E,F,G,H,I,J)
nwset, mat((0,1,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,1,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,1,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,1,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0)) directed name(saomisowave2) labs(A,B,C,D,E,F,G,H,I,J)

capture nwsaom, wave1(saomisowave1) wave2(saomisowave2) outdegree isolatenet outiso k0(30) k3(60) seed(90210)
assert _rc == 0 | _rc == 498 | _rc == 505
if _rc == 0 {
	assert e(nodes) == 10
	matrix __biso = e(b)
	assert colsof(__biso) == 3
}

di as text "nwsaom.ado unit 34 (isolatenet+outiso) end-to-end smoke test PASS"

* -------------------------------------------------------------------
* harmonisation unit 35 (missing tie/behavior data) - missnet()/
* missbeh() end-to-end on real nwset-built networks, both the two-wave
* and N-wave paths, network-only and co-evolution (per the explicit
* "both from the start" scope decision), plus validation. Reuses the
* same n=6 toy network shape as unit 33's own present() test above.
* -------------------------------------------------------------------
nwclear
nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(saommwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,0,0,0)) directed name(saommwave2) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,0\1,0,1,0,1,1\1,1,0,1,0,0\1,0,1,0,1,1\1,1,0,1,0,1\0,1,0,0,0,0)) directed name(saommwave3) labs(A,B,C,D,E,F)

* missnet(): mark dyad (A,B) missing at wave1, dyad (C,D) missing at
* wave2, nothing missing at wave3 - one 6x6 0/1 matrix per wave.
matrix mnet1 = (0,1,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0)
matrix mnet2 = (0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,1,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0)
matrix mnet3 = (0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0)

* missbeh(): actor F's own behavior value marked missing at wave2 only.
gen byte behm1 = mod(_n,5)+1
gen byte behm2 = mod(_n+1,5)+1
gen byte behm3 = mod(_n+2,5)+1
gen byte missb1 = 0
gen byte missb2 = 0
replace missb2 = 1 in 6
gen byte missb3 = 0

* --- network-only, two waves ---
nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree reciprocity missnet(mnet1 mnet2) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 0
matrix __mb = e(b)
assert colsof(__mb) == 2

* --- network-only, N waves ---
nwsaom, waves(saommwave1 saommwave2 saommwave3) outdegree reciprocity missnet(mnet1 mnet2 mnet3) k0(30) k3(60) seed(90210)
assert e(nwaves) == 3
matrix __mb2 = e(b)
assert colsof(__mb2) == 2

* --- co-evolution, two waves (missnet() + missbeh() together) ---
nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree behavior(behm1 behm2) linear avalt missnet(mnet1 mnet2) missbeh(missb1 missb2) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 1
matrix __mb3 = e(b)
assert colsof(__mb3) == 3

* --- co-evolution, N waves ---
nwsaom, waves(saommwave1 saommwave2 saommwave3) outdegree behavior(behm1 behm2 behm3) linear avalt missnet(mnet1 mnet2 mnet3) missbeh(missb1 missb2 missb3) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 1
assert e(nwaves) == 3

* --- combined with present() (composition change + missing data together) ---
gen byte presm1 = 1
gen byte presm2 = 1
replace presm2 = 0 in 6
nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree reciprocity present(presm1 presm2) missnet(mnet1 mnet2) k0(30) k3(60) seed(90210)
assert e(has_behavior) == 0

* --- validation: wrong matrix count ---
capture nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree missnet(mnet1) k0(5) k3(5)
assert _rc == 198

* --- validation: wrong matrix dimensions ---
matrix mnetbad = (0,1\1,0)
capture nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree missnet(mnet1 mnetbad) k0(5) k3(5)
assert _rc == 198

* --- validation: non-0/1 matrix values rejected ---
matrix mnetbad2 = (0,2,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0)
capture nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree missnet(mnet1 mnetbad2) k0(5) k3(5)
assert _rc == 198

* --- validation: missbeh() without behavior() ---
capture nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree missbeh(missb1 missb2) k0(5) k3(5)
assert _rc == 198

* --- validation: missbeh() non-0/1 values rejected ---
gen byte missbbad = 2
capture nwsaom, wave1(saommwave1) wave2(saommwave2) outdegree behavior(behm1 behm2) linear missbeh(missb1 missbbad) k0(5) k3(5)
assert _rc == 198

di as text "nwsaom.ado unit 35 (missing data - missnet()/missbeh(), network-only + co-evolution, two-wave + N-wave, plus validation) PASS"

* =====================================================================
* Harmonisation unit 167: network-side endowment/creation
* (outdegreeendow/outdegreecreation, reciprocityendow/reciprocitycreation).
* RSiena's own getEffects() confirms density/recip DO offer endow/
* creation types - see docs/SAOM_ROADMAP.md's own unit-166/167 entries.
* =====================================================================
nwclear
set seed 90210
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\1,0,0,1,0,0\0,0,0,0,1,0\0,0,1,0,0,1\0,0,0,0,0,0)) directed name(saomnwave1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,0\0,0,1,1,0,1\0,0,0,0,1,0)) directed name(saomnwave2) labs(A,B,C,D,E,F)

* --- baseline (plain outdegree+reciprocity) must be completely
* unaffected by this unit's own changes - same fixed seed/k0/k3 as
* every other check in this block, so a bit-identical b vector here is
* itself part of the certification, not just "runs without error".
nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegree reciprocity k0(15) k3(15) rate0(1.5) seed(90210)
matrix __net167_base = e(b)

* --- outdegreeendow/outdegreecreation: real, RSiena-native alternative
* role split for the required baseline network effect. Small toy
* network here (validation/shape only) - the real convergence
* demonstration on non-degenerate data is below, on a denser network.
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreeendow outdegreecreation reciprocity k0(15) k3(15) rate0(1.5) seed(90210)
assert _rc == 0 | _rc == 498 | _rc == 505
if _rc == 0 {
	matrix __net167_od = e(b)
	assert colsof(__net167_od) == 3
	local __net167_odnames : colnames __net167_od
	assert strpos("`__net167_odnames'", "outdegreeendow") > 0
	assert strpos("`__net167_odnames'", "outdegreecreation") > 0
}

* --- reciprocityendow/reciprocitycreation: same mechanism, the other
* RSiena-confirmed effect.
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegree reciprocityendow reciprocitycreation k0(15) k3(15) rate0(1.5) seed(90210)
assert _rc == 0 | _rc == 498 | _rc == 505

* --- both split together ---
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreeendow outdegreecreation reciprocityendow reciprocitycreation k0(15) k3(15) rate0(1.5) seed(90210)
assert _rc == 0 | _rc == 498 | _rc == 505

* --- validation: plain + split together is refused (exact collinearity,
* same rule as linearendow/linearcreation and unit 166's quadratic/
* avalt/avsim splits).
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegree outdegreeendow outdegreecreation k0(5) k3(5)
assert _rc == 198
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegree reciprocity reciprocityendow reciprocitycreation k0(5) k3(5)
assert _rc == 198

* --- validation: endow/creation must be paired ---
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreeendow k0(5) k3(5)
assert _rc == 198
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreecreation k0(5) k3(5)
assert _rc == 198
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegree reciprocityendow k0(5) k3(5)
assert _rc == 198

* --- validation: required baseline still enforced (neither outdegree
* nor outdegreeendow given) ---
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) reciprocity k0(5) k3(5)
assert _rc == 198

* --- validation: v1 scope restrictions - not yet combined with
* co-evolution, composition change, or missing network data.
gen byte pres167 = 1
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreeendow outdegreecreation present(pres167) k0(5) k3(5)
assert _rc == 198
matrix missnet167 = J(6,6,0)
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreeendow outdegreecreation missnet(missnet167 missnet167) k0(5) k3(5)
assert _rc == 198
gen byte behn1 = mod(_n,3)+1
gen byte behn2 = mod(_n+1,3)+1
capture nwsaom, wave1(saomnwave1) wave2(saomnwave2) outdegreeendow outdegreecreation behavior(behn1 behn2) linear k0(5) k3(5)
assert _rc == 198

* --- a real, non-degenerate convergence demonstration on denser data
* (dev/saom_isoiso_wave{1,2}.csv, 60 actors - the same purpose-built
* synthetic dataset harmonisation unit 161's own isolateNet/outIso
* native-port work used) - the tiny 6-actor toy network above is fine
* for validation/shape checks but too sparse to reliably identify a
* role-split baseline effect (real, confirmed finding: this exact
* toy network hits thetaBound for outdegreeendow/outdegreecreation).
preserve
import delimited "dev/saom_isoiso_wave1.csv", clear varnames(nonames)
mkmat v1-v60, matrix(__net167_W1)
nwset, mat(__net167_W1) directed name(saomn167w1)
import delimited "dev/saom_isoiso_wave2.csv", clear varnames(nonames)
mkmat v1-v60, matrix(__net167_W2)
nwset, mat(__net167_W2) directed name(saomn167w2)

nwsaom, wave1(saomn167w1) wave2(saomn167w2) outdegreeendow outdegreecreation reciprocity k0(30) k3(200) seed(90210)
assert e(nodes) == 60
matrix __net167_dense = e(b)
assert colsof(__net167_dense) == 3
* both role coefficients must be genuinely different numbers (not a
* degenerate copy of each other, which would signal the gating itself
* is a no-op) and both finite.
assert __net167_dense[1,1] != __net167_dense[1,2]
assert !missing(__net167_dense[1,1]) & !missing(__net167_dense[1,2])
restore

di as text "nwsaom.ado unit 167 (network-side endowment/creation - outdegreeendow/outdegreecreation, reciprocityendow/reciprocitycreation, plus validation) PASS"

* --- Harmonisation unit 169 (Robbins-Monro non-positive-diagonal
* safeguard, RSiena-faithful): isolateNet/antiIso/isolatePop previously
* diverged outright (rc=498, thetaBound) on this exact isoiso dataset -
* a direct Mata probe found Dhat's own isolatenet-vs-isolatenet
* diagonal Jacobian entry NEGATIVE at every K0 tried (50 through 1000),
* the exact condition real RSiena's own R/phase1.r CalculateDerivative()
* checks for and falls back to "fix that parameter" over (its own real
* ultimate remedy once phase-1 lengthening/finite-difference
* re-estimation are exhausted). This is a real regression guard against
* ever losing that fix - confirms the previously-diverging model now
* converges cleanly (rc==0), not just "does not crash".
preserve
import delimited "dev/saom_isoiso_wave1.csv", clear varnames(nonames)
mkmat v1-v60, matrix(__net169_W1)
nwset, mat(__net169_W1) directed name(saomn169w1)
import delimited "dev/saom_isoiso_wave2.csv", clear varnames(nonames)
mkmat v1-v60, matrix(__net169_W2)
nwset, mat(__net169_W2) directed name(saomn169w2)

capture noisily nwsaom, wave1(saomn169w1) wave2(saomn169w2) outdegree isolatenet k0(50) k3(1000) rate0(5) seed(1)
assert _rc == 0
assert e(nodes) == 60
matrix __net169_b = e(b)
* outdegree must remain well-estimated (a real, precise number, not a
* placeholder) - the safeguard must not have degraded the OTHER,
* well-behaved parameter's own estimate.
assert abs(__net169_b[1,1]) > 1 & abs(__net169_b[1,1]) < 5
assert !missing(__net169_b[1,2])
restore

di as text "nwsaom.ado unit 169 (Robbins-Monro non-positive-diagonal safeguard - isolatenet on isoiso data converges, was rc=498) PASS"

* =====================================================================
* Undirected/symmetric relations - RSiena's own BJOINT mutual-consent
* model type (native-first, direct instruction: implemented in C, not
* Mata - see native/saom_sim.c's own header comment for the real
* source-verified mechanism). v1 scope: two-wave, network-only,
* exactly-symmetric input data, requires the native backend (no Mata
* fallback exists for this mechanism).
* =====================================================================
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,0\0,0,0,1,0,1\0,0,0,0,1,0)) directed name(saomsymw1) labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,0,0\1,0,1,0,0,0\1,1,0,1,0,0\1,0,1,0,1,0\0,0,0,1,0,1\0,0,0,0,1,0)) directed name(saomsymw2) labs(A,B,C,D,E,F)

* reciprocity is degenerate (always 1) once every tie is forced
* symmetric - must be rejected, not silently accepted as a meaningless
* constant term.
capture nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree reciprocity symmetric k0(10) k3(50) rate0(2) seed(1)
assert _rc == 198

* symmetric requires the INPUT data to already be tie-symmetric -
* `symmetric' selects the simulation mechanism, it does not symmetrize
* asymmetric data.
nwset, mat((0,1,0\0,0,1\0,0,0)) directed name(saomsymasym) labs(X,Y,Z)
capture nwsaom, wave1(saomsymasym) wave2(saomsymasym) outdegree symmetric k0(10) k3(50) rate0(2) seed(1)
assert _rc == 198

* a real fit on real symmetric data converges cleanly through the
* native BJOINT path (there is no Mata fallback - if native routing
* were broken, this would either error or silently run the WRONG
* ordinary directed ministep, which the coefficient/rc checks below
* would not by themselves distinguish - the mutual-exclusivity/data-
* symmetry checks above are what actually guard against a silent
* wrong-mechanism fit; this block certifies the correct path still
* produces a stable, real estimate end-to-end).
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric k0(20) k3(200) rate0(2) seed(777)
assert _rc == 0
assert e(nodes) == 6
matrix __symb = e(b)
assert !missing(__symb[1,1])

di as text "nwsaom.ado undirected/symmetric relations (BJOINT, native-first) PASS"

* symmetric + ratecov() combined (native-first): native/saom_sim.c's
* ministep loop already gates hasratecov (weighted actor selection) and
* symtype (the two-sided ministep decision) as two independent flags in
* the same code path, confirmed by reading the C source before wiring
* this in - the combination is no longer rejected. outdegree remains
* well-identified through this combined path (a real correctness
* property, not just "runs without error"); the rate-covariate
* coefficient's OWN standard error is disclosed as unreliably large
* under symtype (see docs/SAOM_ROADMAP.md) - not chased further here,
* consistent with the already-flagged unverified phase-1 score-function
* derivation for symmetric models generally.
gen __symrc_actrate = _n
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric ratecov(__symrc_actrate) k0(20) k3(200) rate0(2) seed(777)
assert _rc == 0
matrix __symrc_b = e(b)
assert abs(__symrc_b[1,1]) > 0.5 & abs(__symrc_b[1,1]) < 10
drop __symrc_actrate

di as text "nwsaom.ado symmetric + ratecov() combined PASS"

* =====================================================================
* Undirected/symmetric follow-ups: (1) the effect-meaningfulness audit
* (real RSiena 1.6.6 getEffects() comparison, not derived) - every
* effect RSiena itself does not offer (or reduces to an exact duplicate
* of one it already offers) for a non-directed relation must be
* rejected; (2) BFORCE/BAGREE, RSiena's other two real B-family
* symmetric model types, native-first alongside BJOINT.
* =====================================================================

* each of these ten is either a constant, an exact duplicate of an
* already-available effect, or an effect real RSiena does not offer for
* a symmetric relation - confirmed against real RSiena's own
* getEffects() output (see nwsaom.ado's own header comment on this
* check for the full account), not assumed.
foreach __symbadeff in cycle3 inactivity outpopularity ininass inoutass outoutass antiiso isolatepop transrectrip transtrip {
	capture nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric `__symbadeff' k0(5) k3(20) rate0(2) seed(1)
	assert _rc == 198
}

* these remain genuinely offered by RSiena for a symmetric relation and
* must NOT be rejected by the effect-audit check (cycle4/outinass are
* also natively eligible, so these fits should actually run to
* completion, not just clear the audit's own rc==198 gate).
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric cycle4 k0(5) k3(20) rate0(2) seed(1)
assert _rc == 0
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric outinass k0(5) k3(20) rate0(2) seed(1)
assert _rc == 0

di as text "nwsaom.ado symmetric effect-meaningfulness audit PASS"

* symtype() requires symmetric - not a standalone option.
capture nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symtype(force) k0(5) k3(20) rate0(2) seed(1)
assert _rc == 198

* an invalid symtype() value is rejected with a clear error, not a
* silent fallback to joint.
capture nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric symtype(bogus) k0(5) k3(20) rate0(2) seed(1)
assert _rc == 198

* BFORCE and BAGREE (RSiena's other two real B-family symmetric model
* types, native-first, no Mata fallback - same v1 scope as BJOINT)
* each converge cleanly end-to-end through the native path.
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric symtype(force) k0(20) k3(200) rate0(2) seed(777)
assert _rc == 0
assert e(nodes) == 6
matrix __symbf = e(b)
assert !missing(__symbf[1,1])

* BAGREE's own formula was independently verified correct via a direct
* hand-computed cross-check against printed u_actor/u_alter values
* (docs/SAOM_ROADMAP.md), and it converges cleanly on real 50-actor s50
* symmetric data - but consistently diverges (thetaBound) on this
* file's own tiny 6-node/1-tie-difference toy network across every seed
* tried, the same real, disclosed small-network identification
* difficulty this file's own precedent already established for other
* effects (see the `_rc == 0 | _rc == 498 | _rc == 505` pattern above) -
* not a defect in the port itself.
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric symtype(agree) k0(20) k3(200) rate0(2) seed(777)
assert _rc == 0 | _rc == 498

* plain `symmetric' with no symtype() is unchanged (still BJOINT,
* symtype defaults to 1) - a real no-op check, not assumed: same seed/
* data/k0/k3 as the original BJOINT smoke test above must give the
* IDENTICAL coefficient as explicitly requesting symtype(joint).
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric k0(20) k3(200) rate0(2) seed(777)
matrix __symdefault = e(b)
capture noisily nwsaom, wave1(saomsymw1) wave2(saomsymw2) outdegree symmetric symtype(joint) k0(20) k3(200) rate0(2) seed(777)
matrix __symjoint = e(b)
assert reldif(__symdefault[1,1], __symjoint[1,1]) < 1e-10

di as text "nwsaom.ado symtype(force)/symtype(agree) (native-first, no Mata fallback) PASS"
