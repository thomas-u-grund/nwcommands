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
