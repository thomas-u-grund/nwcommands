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

* --- validation: quadratic cannot combine with linearendow/linearcreation yet.
capture nwsaom, wave1(saomewave1) wave2(saomewave2) outdegree behavior(behewave1 behewave2) linearendow linearcreation quadratic k0(5) k3(5)
assert _rc == 198

di as text "nwsaom.ado unit 28 (endowment/creation functions, thetaBound-protected per harmonisation unit 29) PASS"

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
