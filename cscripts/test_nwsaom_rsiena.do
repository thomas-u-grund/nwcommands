cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* Regression test: nwsaom network-only models against RSiena.
*
* Reference: RSiena 1.6.6 on its own s50 data (friendship s501-s503,
* smoking s50s), the same data as `nwwebuse glasgow' (node order differs,
* results do not). Numbers are means over five seeds (1-5) of
*
*   ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = s, cond = FALSE),
*                  data = dat, effects = eff, batch = TRUE, silent = TRUE)
*
* restarted with prevAns while tconv.max > 0.25 (at most three times).
* Effects: M1 two waves, density + reciprocity; M2-M5 three waves, density
* + reciprocity plus transTrip (M2), gwespFF with parameter 69 instead of
* transTrip (M3), transTrip + sameX(smoke1), smoke1 = s50s[, 1] as coCovar
* (M4), transTrip + inPopSqrt + outAct (M5); then a covariate-dependent
* rate and the three symmetric (pairwise) model types.
*
* cond = FALSE is RSiena's UNCONDITIONAL Method of Moments (nwsaom's
* `unconditional' option); cond = TRUE, RSiena's default for a single
* network, is CONDITIONAL estimation (nwsaom's default). The two differ by
* up to 0.3 RSiena standard errors on these models (e.g. M2 outdegree
* -2.686 vs -2.650; seed-to-seed SD about 0.005), so each nwsaom estimator
* is checked against its RSiena counterpart. Before 2026-10-01 nwsaom held
* the rate at its closed-form starting value during estimation and was
* 0.3-0.6 SE off both.
*
* Tolerances: every estimate, the rates included, within 0.25 RSiena
* standard errors of RSiena's (the five-seed validation found at most
* 0.06); standard errors within a factor of 1.5 of RSiena's; the overall
* maximum convergence ratio below 0.3.

capture program drop _net_check
program define _net_check
	args names ests ses
	local k : word count `names'
	matrix __b = e(b)
	matrix __V = e(V)
	forvalues i = 1/`k' {
		local nm : word `i' of `names'
		local rs : word `i' of `ests'
		local rse : word `i' of `ses'
		if substr("`nm'", 1, 4) == "rate" {
			local p = substr("`nm'", 5, .)
			capture confirm matrix e(rates)
			if _rc {
				local est = e(rate)
				local se = e(rate_se)
			}
			else {
				matrix __r = e(rates)
				matrix __rse = e(rates_se)
				local est = __r[1, `p']
				local se = __rse[1, `p']
			}
		}
		else {
			local j = colnumb(__b, "`nm'")
			local est = __b[1, `j']
			local se = sqrt(__V[`j', `j'])
		}
		di as text %-16s "`nm'" " nwsaom" %8.3f `est' " (" %5.3f `se' ")  RSiena" %8.3f `rs' " (" %5.3f `rse' ")  d/SE" %6.2f (`est' - `rs') / `rse'
		assert abs(`est' - `rs') < 0.25 * `rse'
		assert `se' > `rse' / 1.5 & `se' < 1.5 * `rse'
	}
	di as text "overall maximum convergence ratio " %6.3f e(tconv_max)
	assert e(tconv_max) < 0.3
end

nwwebuse glasgow, nwclear

* ---------------------------------------------------------------- M1
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity unconditional seed(12345)
_net_check "rate1 outdegree reciprocity" "5.528 -2.227 2.432" "0.778 0.125 0.240"
di as text "M1 (2 waves) PASS"

* ---------------------------------------------------------------- M2
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip unconditional seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip" ///
	"6.485 5.283 -2.650 2.421 0.614" "1.094 0.899 0.119 0.193 0.079"
* e(tratio) is on RSiena's scale: the effect columns of e(tconv)
matrix __tr = e(tratio)
matrix __tc = e(tconv)
assert colsof(__tc) == 5
forvalues j = 1/3 {
	assert reldif(__tr[1,`j'], __tc[1,`j']) < 1e-12
}
assert max(abs(__tc[1,1]), abs(__tc[1,2]), abs(__tc[1,3]), abs(__tc[1,4]), abs(__tc[1,5])) < 0.3
di as text "M2 (transTrip) PASS"

* ---------------------------------------------------------------- M3
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(12345)
_net_check "rate1 rate2 outdegree reciprocity gwesp_.69" ///
	"6.592 5.269 -2.814 2.525 1.589" "1.114 0.849 0.130 0.189 0.157"
di as text "M3 (gwespFF) PASS"

* ---------------------------------------------------------------- M4
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip nodematch(smoke1) unconditional seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip nodematch_smoke1" ///
	"6.540 5.281 -2.727 2.410 0.612 0.128" "1.129 0.828 0.158 0.196 0.083 0.149"
di as text "M4 (sameX) PASS"

* ---------------------------------------------------------------- M5
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity unconditional seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip indegpopularity outactivity" ///
	"7.240 5.620 -1.236 2.227 0.779 -0.391 -0.151" "1.308 0.973 0.406 0.200 0.082 0.212 0.046"
di as text "M5 (inPopSqrt, outAct) PASS"

* restarting from the estimates (theta0() and rate0()) stays at the solution
matrix __b0 = e(b)
matrix __r0 = e(rates)
local __th ""
forvalues j = 1/5 {
	local __th "`__th' `=__b0[1,`j']'"
}
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity ///
	theta0(`__th') rate0(`=__r0[1,1]' `=__r0[1,2]') unconditional seed(54321)
_net_check "rate1 rate2 outdegree reciprocity transtrip indegpopularity outactivity" ///
	"7.240 5.620 -1.236 2.227 0.779 -0.391 -0.151" "1.308 0.973 0.406 0.200 0.082 0.212 0.046"
di as text "M5 restarted from its estimates PASS"

* ---------------------------------------------------------------- ratecov()
* two waves, density + reciprocity, rate effect of smoking (RSiena RateX on
* coCovar(s50s[, 1]), which RSiena centers; nwsaom gets the centered
* variable, so both rates refer to an actor of average smoking). RSiena,
* unconditional, five seeds: rate 5.917 (SE .9-1.2), smoking on rate .991
* (.36-.50; one seed 3.6), outdegree -2.221 (.14), reciprocity 2.422
* (.26). The coefficient's SE is noisy in both programs, so only the
* estimates are checked here.
quietly summarize smoke1
generate double __smkc = smoke1 - r(mean)
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ratecov(__smkc) unconditional seed(12345)
matrix __b = e(b)
di as text "rate " %6.3f e(rate) "  ratecoef " %6.3f e(ratecoef) "  outdegree " %6.3f __b[1,1] "  reciprocity " %6.3f __b[1,2]
assert abs(e(rate) - 5.917) < 0.25 * 1.0
assert abs(e(ratecoef) - 0.991) < 0.25 * 0.42
assert abs(__b[1,1] - (-2.221)) < 0.25 * 0.14
assert abs(__b[1,2] - 2.422) < 0.25 * 0.26
assert e(ratecoef_fixed) == 0
assert e(tconv_max) < 0.3
drop __smkc
di as text "ratecov() PASS"

* ---------------------------------------------------------------- symmetric
* glasgow waves 1-2 symmetrized (a tie where either direction exists),
* density only, RSiena's pairwise model types (modelType 6 = joint, 4 =
* forcing, 5 = mutual/agree), unconditional, seeds 1-5 (runs that failed
* or did not converge replaced by the next seed). RSiena's default start
* for these basic rates is on the per-actor scale (5.6 here), from which
* phase 2 diverges ("more than 1000000 steps") or never moves the rate;
* the references use initialValue 0.5 for the rate. The rate is RSiena's
* basic rate parameter lambda (pairs at rate lambda^2), which nwsaom
* reports since 2026-10-01 (e(rate_actor) keeps the per-actor rate):
* joint rate .546 (.051), density -1.271 (.108); force .545 (.047),
* -2.539 (.206); agree .585 (.051), -1.083 (.122).
nwtomata glasgow1, mat(__gs1)
nwtomata glasgow2, mat(__gs2)
mata: __gs1 = (__gs1 + __gs1') :> 0
mata: __gs2 = (__gs2 + __gs2') :> 0
nwset, mat(__gs1) directed name(__gsym1)
nwset, mat(__gs2) directed name(__gsym2)
local __rs  `""0.546 -1.271" "0.545 -2.539" "0.585 -1.083""'
local __rse `""0.051 0.108" "0.047 0.206" "0.051 0.122""'
local __j 0
foreach __t in joint force agree {
	local ++__j
	nwsaom, wave1(__gsym1) wave2(__gsym2) outdegree symmetric symtype(`__t') unconditional seed(12345)
	_net_check "rate1 outdegree" "`: word `__j' of `__rs''" "`: word `__j' of `__rse''"
	assert abs(e(rate) - sqrt(e(rate_actor) / 49)) < 1e-10
	assert "`e(symtype)'" == "`__t'"
	di as text "symmetric symtype(`__t') PASS"
}

di as text "nwsaom unconditional vs RSiena cond = FALSE: PASS"

* ================================================================ conditional
* nwsaom's default against RSiena's default (cond = TRUE), means of five
* seeds. Under conditional estimation RSiena reports as a period's rate the
* mean simulated time to the observed distance and as its standard error
* the standard deviation of that time (ans$rate, ans$vrate); nwsaom does
* the same, so both are compared like the other parameters.
nwwebuse glasgow, nwclear

nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(12345)
assert e(conditional) == 1
assert e(rate_tratio) == .
_net_check "rate1 outdegree reciprocity" "5.474 -2.253 2.478" "0.838 0.128 0.242"
di as text "conditional M1 (2 waves) PASS"

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip" ///
	"6.442 5.211 -2.686 2.463 0.626" "1.089 0.881 0.116 0.202 0.075"
matrix __tc = e(tconv)
assert colsof(__tc) == 3
di as text "conditional M2 (transTrip) PASS"

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(12345)
_net_check "rate1 rate2 outdegree reciprocity gwesp_.69" ///
	"6.554 5.249 -2.850 2.562 1.622" "1.129 0.889 0.131 0.193 0.156"
di as text "conditional M3 (gwespFF) PASS"

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip nodematch(smoke1) seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip nodematch_smoke1" ///
	"6.455 5.238 -2.764 2.447 0.623 0.131" "1.115 0.891 0.159 0.200 0.078 0.151"
di as text "conditional M4 (sameX) PASS"

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip indegpopularity outactivity" ///
	"7.149 5.585 -1.313 2.292 0.791 -0.380 -0.152" "1.291 0.979 0.422 0.212 0.087 0.213 0.048"
di as text "conditional M5 (inPopSqrt, outAct) PASS"

* ratecov(), conditional (RSiena cond = TRUE: the basic rate is conditioned
* on, the covariate-rate coefficient stays a Method-of-Moments parameter):
* rate 5.751 (.939), smoking on rate .902 (.361), outdegree -2.262 (.136),
* reciprocity 2.477 (.258)
quietly summarize smoke1
generate double __smkc2 = smoke1 - r(mean)
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ratecov(__smkc2) seed(12345)
matrix __b = e(b)
di as text "rate " %6.3f e(rate) "  ratecoef " %6.3f e(ratecoef) "  outdegree " %6.3f __b[1,1] "  reciprocity " %6.3f __b[1,2]
assert abs(e(rate) - 5.751) < 0.25 * 0.939
assert abs(e(ratecoef) - 0.902) < 0.25 * 0.361
assert abs(__b[1,1] - (-2.262)) < 0.25 * 0.136
assert abs(__b[1,2] - 2.477) < 0.25 * 0.258
drop __smkc2
di as text "conditional ratecov() PASS"

* missing tie data: 54 and 45 random dyads missing at waves 2 and 3 (the
* matrices below; RSiena got the same networks with those cells NA)
set seed 777
mata: __mn2 = (runiform(50,50) :< 0.02)
mata: _diag(__mn2, 0)
mata: __mn3 = (runiform(50,50) :< 0.02)
mata: _diag(__mn3, 0)
mata: assert(sum(__mn2) == 54 & sum(__mn3) == 45)
mata: st_matrix("__mn2", __mn2)
mata: st_matrix("__mn3", __mn3)
matrix __mn1 = J(50, 50, 0)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip missnet(__mn1 __mn2 __mn3) seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip" ///
	"6.536 5.339 -2.701 2.511 0.623" "1.126 0.953 0.124 0.212 0.081"
di as text "conditional missnet() PASS"

* symmetric (pairwise) model types, conditional (RSiena cond = TRUE,
* seeds 1-5). RSiena reports the mean time to reach the observed distance
* at basic rate 1 (pairs at rate 1), nwsaom's time divided by n - 1:
* joint rate .300 (.043), density -1.275 (.106); force .300 (.044),
* -2.549 (.208); agree .343 (.050), -1.087 (.124).
nwtomata glasgow1, mat(__gs1)
nwtomata glasgow2, mat(__gs2)
mata: __gs1 = (__gs1 + __gs1') :> 0
mata: __gs2 = (__gs2 + __gs2') :> 0
nwset, mat(__gs1) directed name(__gsym1)
nwset, mat(__gs2) directed name(__gsym2)
local __rs  `""0.300 -1.275" "0.300 -2.549" "0.343 -1.087""'
local __rse `""0.043 0.106" "0.044 0.208" "0.050 0.124""'
local __j 0
foreach __t in joint force agree {
	local ++__j
	nwsaom, wave1(__gsym1) wave2(__gsym2) outdegree symmetric symtype(`__t') seed(12345)
	_net_check "rate1 outdegree" "`: word `__j' of `__rs''" "`: word `__j' of `__rse''"
	assert abs(e(rate) - e(rate_actor) / 49) < 1e-10
	di as text "conditional symmetric symtype(`__t') PASS"
}

* pairwise model with a covariate-dependent rate (RateX, joint, cond =
* TRUE, seeds 1-5): rate .289 (.043), density -1.265 (.104), smoke1 on
* rate .311 (.133). RSiena gives actor i the rate lambda * exp(b x_i),
* draws the actor and then the alter by these rates, at total rate
* (sum)^2 - sum of squares; nwsaom does the same since 2026-10-01 (before,
* the alter was drawn uniformly).
qui sum smoke1
generate double __smkc3 = smoke1 - r(mean)
nwsaom, wave1(__gsym1) wave2(__gsym2) outdegree symmetric symtype(joint) ratecov(__smkc3) seed(12345)
_net_check "rate1 outdegree" "0.289 -1.265" "0.043 0.104"
di as text "ratecoef nwsaom" %8.3f e(ratecoef) " (" %5.3f e(ratecoef_se) ")  RSiena   0.311 (0.133)"
assert abs(e(ratecoef) - 0.311) < 0.25 * 0.133
assert e(ratecoef_se) > 0.133 / 1.5 & e(ratecoef_se) < 1.5 * 0.133
drop __smkc3
di as text "conditional symmetric ratecov() PASS"

* non-directed relation, unilateral initiative (RSiena modelType 2 =
* AFORCE, RSiena's default for a symmetric network, and 3 = AAGREE),
* density only, seeds 1-5, waves DECLARED undirected and passed without
* the symmetric option (modeled as non-directed automatically, default
* type forcing). The rate is the per-actor rate, as in RSiena.
* Conditional: forcing rate 1.970 (.289), density -1.354 (.116);
* confirmation 4.113 (.602), -.737 (.082). Unconditional: forcing 1.989
* (.292), -1.353 (.118); confirmation 4.120 (.611), -.736 (.081).
nwset, mat(__gs1) undirected name(__gu1)
nwset, mat(__gs2) undirected name(__gu2)
nwsaom, wave1(__gu1) wave2(__gu2) outdegree seed(12345)
assert "`e(symtype)'" == "forcing" & e(modeltype) == 2
assert e(rate) == e(rate_actor)
_net_check "rate1 outdegree" "1.970 -1.354" "0.289 0.116"
nwsaom, wave1(__gu1) wave2(__gu2) outdegree symtype(confirmation) seed(12345)
assert e(modeltype) == 3
_net_check "rate1 outdegree" "4.113 -0.737" "0.602 0.082"
nwsaom, wave1(__gu1) wave2(__gu2) outdegree symtype(2) unconditional seed(12345)
assert "`e(symtype)'" == "forcing"
_net_check "rate1 outdegree" "1.989 -1.353" "0.292 0.118"
nwsaom, wave1(__gu1) wave2(__gu2) outdegree symtype(confirmation) unconditional seed(12345)
_net_check "rate1 outdegree" "4.120 -0.736" "0.611 0.081"
di as text "non-directed forcing/confirmation PASS"

* covariate effects for several variables at once (2026-10-01; before,
* one variable per effect type). RSiena 1.6.6, seeds 1-5 (default
* algorithm), glasgow waves 1-2 (3 for the co-evolution model);
* covariates centred for egoX/altX/RateX as RSiena centres them; simX is
* centred by its similarity mean in both. Model C3 is the "realistic"
* model with outAct (RSiena's outdegree activity) - with outPopSqrt
* instead RSiena itself does not converge (tconv.max about 3 on every
* seed, even started from nwsaom's estimates), so it cannot serve as a
* reference.
nwwebuse glasgow, nwclear
qui sum smoke1
generate double smkc = smoke1 - r(mean)
qui sum alcohol1
generate double alcc = alcohol1 - r(mean)
local w12 wave1(glasgow1) wave2(glasgow2)

* (a) sameX on two variables, conditional and unconditional
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) seed(12345)
_net_check "rate1 outdegree reciprocity samex_smoke1 samex_sport1" ///
	"5.446 -2.517 2.457 0.345 0.073" "0.826 0.220 0.245 0.190 0.185"
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) unconditional seed(12345)
_net_check "rate1 outdegree reciprocity samex_smoke1 samex_sport1" ///
	"5.507 -2.500 2.429 0.342 0.076" "0.840 0.224 0.246 0.193 0.185"
di as text "(a) samex(smoke1 sport1) PASS"

* (b) egoX, altX, simX on two variables
nwsaom, `w12' outdegree reciprocity egox(alcc smkc) altx(alcc smkc) simx(alcc smkc) seed(12345)
_net_check "rate1 outdegree reciprocity altx_alcc altx_smkc egox_alcc egox_smkc simx_alcc simx_smkc" ///
	"5.367 -2.349 2.402 -0.098 0.104 -0.005 0.348 1.064 0.803" ///
	"0.810 0.143 0.250 0.110 0.177 0.115 0.191 0.442 0.316"
di as text "(b) egox/altx/simx on two variables PASS"

* (c) realistic model: gwespFF, transRecTrip, inPopSqrt, outAct, sameX on
* two variables, egoX/altX/simX(alcohol1)
nwsaom, `w12' outdegree reciprocity gwesp(.69) transrectrip indegpopularity outactivity ///
	samex(smoke1 sport1) egox(alcc) altx(alcc) simx(alcc) seed(12345)
_net_check "rate1 outdegree reciprocity samex_smoke1 samex_sport1 altx_alcc egox_alcc indegpopularity outactivity transrectrip gwesp_.69 simx_alcc" ///
	"6.948 -1.590 2.243 0.268 0.116 -0.067 0.086 -0.364 -0.180 -0.116 2.079 0.869" ///
	"1.248 0.614 0.374 0.245 0.195 0.103 0.117 0.295 0.069 0.258 0.428 0.446"
di as text "(c) realistic model PASS"

* (d) co-evolution, waves 1-3: friendship with sameX(sport1),
* sameX(alcohol1), simX(smoking); smoking linear, quadratic, avAlt
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity samex(sport1 alcohol1) behsim ///
	behavior(smoke1 smoke2 smoke3) linear quadratic avalt seed(12345)
_net_check "rate1 rate2 outdegree reciprocity samex_sport1 samex_alcohol1 behsim beh_linear beh_quadratic beh_avalt" ///
	"5.865 4.624 -2.530 2.743 0.198 0.124 0.612 -1.730 1.831 1.780" ///
	"0.945 0.733 0.154 0.191 0.143 0.142 0.310 0.465 0.475 1.160"
matrix __rb = e(rates_beh)
assert abs(__rb[1,1] - 2.937) < 0.25 * 1.690 & abs(__rb[1,2] - 2.728) < 0.25 * 1.413
di as text "(d) co-evolution with two covariate homophily effects PASS"

* (e) two covariate-dependent rate effects (RateX smoke1, RateX alcohol1)
nwsaom, `w12' outdegree reciprocity ratecov(smkc alcc) seed(12345)
_net_check "rate1 outdegree reciprocity" "5.688 -2.250 2.463" "0.912 0.149 0.269"
matrix __rc = e(ratecoefs)
matrix __rcs = e(ratecoefs_se)
di as text "ratecoef smkc " %8.3f __rc[1,1] " (" %5.3f __rcs[1,1] ")  RSiena 0.811 (0.437)"
di as text "ratecoef alcc " %8.3f __rc[1,2] " (" %5.3f __rcs[1,2] ")  RSiena 0.088 (0.215)"
assert abs(__rc[1,1] - 0.811) < 0.25 * 0.437 & abs(__rc[1,2] - 0.088) < 0.25 * 0.215
assert __rcs[1,1] > 0.437 / 1.5 & __rcs[1,1] < 1.5 * 0.437
assert __rcs[1,2] > 0.215 / 1.5 & __rcs[1,2] < 1.5 * 0.215
di as text "(e) ratecov() on two variables PASS"

* interactions (RSiena includeInteraction(), seeds 1-5, conditional).
* Before 2026-10-01 a two-way interaction's change had the wrong sign on
* tie withdrawals (the product of two signed changes); sameX x recip then
* failed in phase 3 (r(505)), egoX x recip was biased.
nwsaom, `w12' outdegree reciprocity samex(smoke1) interact(samex#reciprocity) seed(12345)
_net_check "rate1 outdegree reciprocity samex_smoke1 interact_nodematch_reciprocity" ///
	"5.451 -2.453 2.417 0.314 0.071" "0.826 0.232 0.450 0.268 0.533"
nwsaom, `w12' outdegree reciprocity egox(alcc) interact(egox#reciprocity) seed(12345)
_net_check "rate1 outdegree reciprocity egox_alcc interact_nodeocov_reciprocity" ///
	"5.155 -2.315 2.552 0.311 -0.879" "0.745 0.160 0.286 0.166 0.360"
di as text "interactions PASS"

di as text "nwsaom network-only vs RSiena: PASS"
