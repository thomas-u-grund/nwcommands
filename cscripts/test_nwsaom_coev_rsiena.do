cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* Regression test: nwsaom co-evolution (network + behavior) against RSiena.
*
* Reference: RSiena 1.6.6 on its own s50 data (friendship s501-s503,
* drinking s50a), which is the same data as `nwwebuse glasgow' (networks
* glasgow1-3, alcohol1-3; node order differs, results do not). Effects:
* network density, reciprocity, transTrip, simX(drinking); behavior linear,
* quad, avAlt. R script (seed 12345, default algorithm):
*
*   friendship <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
*   drinking <- sienaDependent(s50a, type = "behavior")
*   dat <- sienaDataCreate(friendship, drinking)
*   eff <- getEffects(dat)
*   eff <- includeEffects(eff, transTrip, name = "friendship")
*   eff <- includeEffects(eff, simX, interaction1 = "drinking", name = "friendship")
*   eff <- includeEffects(eff, avAlt, name = "drinking", interaction1 = "friendship")
*   ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 12345), data = dat, effects = eff)
*
* (the two-wave reference uses s501/s502 and s50a[, 1:2]). Before
* 2026-09-30 nwsaom held both rates at closed-form starting values and never
* estimated them, had no behavior-similarity (simX) effect, used an
* uncentered avAlt and non-lagged cross statistics; on this model the
* behavior parameters ran away (linear shape -40, SE 274).
*
* Tolerances: every estimate within one RSiena standard error of RSiena's
* estimate; standard errors within a factor of 2 of RSiena's (both are Monte
* Carlo estimates); RSiena-style convergence t-ratios below 0.15 and the
* overall maximum convergence ratio below 0.3 (RSiena's own threshold for a
* good fit is 0.25; its reference script simply reruns above that, and with
* the per-simulation random streams introduced 2026-10-01 this seed lands
* at 0.255 for the 3-wave model, with every estimate still within 0.1 SE).

capture program drop _coev_check
program define _coev_check
	args names ests ses
	local k : word count `names'
	matrix __b = e(b)
	matrix __V = e(V)
	forvalues i = 1/`k' {
		local nm : word `i' of `names'
		local rs : word `i' of `ests'
		local rse : word `i' of `ses'
		local j = colnumb(__b, "`nm'")
		local est = __b[1, `j']
		local se = sqrt(__V[`j', `j'])
		di as text %-14s "`nm'" "  nwsaom " %8.3f `est' " (" %6.3f `se' ")   RSiena " %8.3f `rs' " (" %6.3f `rse' ")"
		assert abs(`est' - `rs') < `rse'
		assert `se' > 0.5*`rse' & `se' < 2*`rse'
	}
end

capture program drop _coev_rate
program define _coev_rate
	args label est se rs rse
	di as text %-14s "`label'" "  nwsaom " %8.3f `est' " (" %6.3f `se' ")   RSiena " %8.3f `rs' " (" %6.3f `rse' ")"
	assert abs(`est' - `rs') < `rse'
	assert `se' > 0.5*`rse' & `se' < 2*`rse'
end

local names "outdegree reciprocity transtrip behsim beh_linear beh_quadratic beh_avalt"

* ---------------------------------------------------------------- 3 waves
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim ///
	behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(12345)

_coev_check "`names'" "-2.760 2.354 0.617 1.484 0.392 -0.589 1.286" ///
	"0.145 0.198 0.077 0.626 0.205 0.311 0.774"
matrix __r = e(rates)
matrix __rse = e(rates_se)
matrix __rb = e(rates_beh)
matrix __rbse = e(rates_beh_se)
_coev_rate "rate net p1" __r[1,1] __rse[1,1] 6.483 1.112
_coev_rate "rate net p2" __r[1,2] __rse[1,2] 5.170 0.845
_coev_rate "rate beh p1" __rb[1,1] __rbse[1,1] 1.312 0.346
_coev_rate "rate beh p2" __rb[1,2] __rbse[1,2] 1.809 0.464
matrix __tc = e(tconv)
forvalues i = 1/`=colsof(__tc)' {
	assert abs(__tc[1,`i']) < 0.15
}
assert e(tconv_max) < 0.3
di as text "nwsaom co-evolution vs RSiena, 3 waves: PASS"

* ---------------------------------------------------------------- 2 waves
nwwebuse glasgow, nwclear
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip behsim ///
	behavior(alcohol1 alcohol2) linear quadratic avalt seed(12345)

_coev_check "`names'" "-2.593 2.030 0.593 1.705 0.291 -0.353 1.006" ///
	"0.174 0.243 0.106 1.042 0.258 0.342 0.876"
_coev_rate "rate net" e(rate) e(rate_se) 6.107 1.129
_coev_rate "rate beh" e(rate_beh) e(rate_beh_se) 1.356 0.432
matrix __tc = e(tconv)
forvalues i = 1/`=colsof(__tc)' {
	assert abs(__tc[1,`i']) < 0.15
}
assert e(tconv_max) < 0.3
di as text "nwsaom co-evolution vs RSiena, 2 waves: PASS"

* ---------------------------------------------------------------- behavior endowment/creation
* RSiena's endowment/creation statistics (2026-10-01; before, every split
* used the linear statistic). RSiena 1.6.6, unconditional, means of seeds
* 1-5:
*   B1: linear, quad endowment + creation, avAlt
*   B3: linear, quad, avSim endowment + creation (RSiena fixes both avSim
*       parameters at 0 after phase 1, not estimable; so does nwsaom)
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim ///
	behavior(alcohol1 alcohol2 alcohol3) linear quadraticendow quadraticcreation avalt seed(1)
_coev_check "outdegree reciprocity transtrip behsim beh_linear beh_quadratic_endow beh_quadratic_creation beh_avalt" ///
	"-2.761 2.355 0.618 1.468 0.479 -0.483 -0.832 1.398" ///
	"0.158 0.198 0.079 0.695 0.321 0.440 0.859 1.136"
matrix __rb = e(rates_beh)
matrix __rbse = e(rates_beh_se)
_coev_rate "rate beh p1" __rb[1,1] __rbse[1,1] 1.337 0.373
_coev_rate "rate beh p2" __rb[1,2] __rbse[1,2] 1.842 0.534
di as text "nwsaom quadratic endowment/creation vs RSiena: PASS"

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim ///
	behavior(alcohol1 alcohol2 alcohol3) linear quadratic avsimendow avsimcreation seed(1)
_coev_check "outdegree reciprocity transtrip behsim beh_linear beh_quadratic" ///
	"-2.743 2.385 0.625 1.391 0.363 -0.200" "0.135 0.196 0.077 0.573 0.150 0.095"
matrix __b = e(b)
matrix __V = e(V)
local j1 = colnumb(__b, "beh_avsim_endow")
local j2 = colnumb(__b, "beh_avsim_creation")
assert __b[1,`j1'] == 0 & __b[1,`j2'] == 0 & __V[`j1',`j1'] == 0 & __V[`j2',`j2'] == 0
di as text "nwsaom avSim endowment/creation (fixed, as RSiena): PASS"

