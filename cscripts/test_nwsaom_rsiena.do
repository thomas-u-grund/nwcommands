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
* cond = FALSE is RSiena's UNCONDITIONAL Method of Moments, the estimator
* nwsaom uses: the rates are estimated jointly with the effects. RSiena's
* default for a single network is CONDITIONAL estimation (cond = TRUE),
* whose estimates differ from the unconditional ones by up to 0.3 RSiena
* standard errors on these models (e.g. M2 outdegree -2.686 vs -2.650,
* reciprocity 2.463 vs 2.421; seed-to-seed SD about 0.005), so nwsaom is
* compared with cond = FALSE. Before 2026-10-01 nwsaom held the rate at its
* closed-form starting value during estimation and was 0.3-0.6 SE off.
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
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(12345)
_net_check "rate1 outdegree reciprocity" "5.528 -2.227 2.432" "0.778 0.125 0.240"
di as text "M1 (2 waves) PASS"

* ---------------------------------------------------------------- M2
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip" ///
	"6.485 5.283 -2.650 2.421 0.614" "1.094 0.899 0.119 0.193 0.079"
di as text "M2 (transTrip) PASS"

* ---------------------------------------------------------------- M3
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(12345)
_net_check "rate1 rate2 outdegree reciprocity gwesp_.69" ///
	"6.592 5.269 -2.814 2.525 1.589" "1.114 0.849 0.130 0.189 0.157"
di as text "M3 (gwespFF) PASS"

* ---------------------------------------------------------------- M4
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip nodematch(smoke1) seed(12345)
_net_check "rate1 rate2 outdegree reciprocity transtrip nodematch_smoke1" ///
	"6.540 5.281 -2.727 2.410 0.612 0.128" "1.129 0.828 0.158 0.196 0.083 0.149"
di as text "M4 (sameX) PASS"

* ---------------------------------------------------------------- M5
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity seed(12345)
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
	theta0(`__th') rate0(`=__r0[1,1]' `=__r0[1,2]') seed(54321)
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
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ratecov(__smkc) seed(12345)
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
* forcing, 5 = mutual/agree), unconditional, seeds 1-3 (runs with a
* failed convergence or missing SE dropped): density -1.268 (SE .104),
* -2.541 (.204), -1.083 (.124). The rates are on a different scale (RSiena
* per pair, nwsaom per actor; ratio about 27-29 here) and not compared.
nwtomata glasgow1, mat(__gs1)
nwtomata glasgow2, mat(__gs2)
mata: __gs1 = (__gs1 + __gs1') :> 0
mata: __gs2 = (__gs2 + __gs2') :> 0
nwset, mat(__gs1) directed name(__gsym1)
nwset, mat(__gs2) directed name(__gsym2)
local __rs  "-1.268 -2.541 -1.083"
local __rse "0.104 0.204 0.124"
local __j 0
foreach __t in joint force agree {
	local ++__j
	nwsaom, wave1(__gsym1) wave2(__gsym2) outdegree symmetric symtype(`__t') seed(12345)
	_net_check "outdegree" "`: word `__j' of `__rs''" "`: word `__j' of `__rse''"
	di as text "symmetric symtype(`__t') PASS"
}

di as text "nwsaom network-only vs RSiena: PASS"
