* fix(), estat simulate and nwsaom simulate (network-only and co-evolution)
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwwebuse glasgow, nwclear

* fix(): the fixed coefficient stays at its starting value, with no standard error
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip theta0(-2 1 0) fix(reciprocity) k3(100) seed(1)
assert e(b)[1,2] == 1
assert e(V)[2,2] == 0
assert e(V)[1,1] > 0 & e(V)[3,3] > 0
* all fixed
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity theta0(-2 1) fix(_all) k3(100) seed(1)
assert e(b)[1,1] == -2 & e(b)[1,2] == 1
* an effect that is not in the model
capture nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity fix(transtrip) k3(50) seed(1)
assert _rc == 198
* fix() with a behavior
nwsaom, wave1(glasgow1) wave2(glasgow2) behavior(smoke1 smoke2) outdegree reciprocity linear quadratic avalt theta0(-2.2 2.4) behtheta0(0 0 0) fix(reciprocity) k3(100) seed(1)
assert reldif(e(b)[1,2], 2.4) < 1e-6
di "PASS fix"

* estat simulate: shape of the result and the effect of theta()
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip k3(100) seed(1)
estat simulate, nsim(15) seed(2) generate(fs)
assert r(nsim) == 15
matrix S = r(sim)
assert rowsof(S) == 15 & colsof(S) == 6
assert S[1,3] > 0
nwtomata fs_3_p1, mat(FS3)
mata: st_numscalar("ok3", rows(FS3) == 50 & sum(FS3) > 50)
assert scalar(ok3) == 1
matrix T = e(b)
matrix T[1,1] = -6
estat simulate, nsim(10) seed(2) theta(T)
matrix S = r(sim)
scalar m = 0
forvalues i = 1/10 {
	scalar m = m + S[`i',3] / 10
}
assert m < 20
di "PASS estat simulate"

* nwsaom simulate: nothing is estimated, the model is the one given
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity theta(-2.3 2) rates(5) nsim(20) seed(3)
matrix S = r(sim)
assert rowsof(S) == 20
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) behavior(smoke1 smoke2) outdegree reciprocity linear quadratic avalt theta(-2.2 2.4) behtheta(-1.7 1.4 0.4) rates(5.5) ratesbeh(2.2) nsim(5) seed(3)
matrix S = r(sim)
assert S[1,6] < .
capture nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity theta(-2.3 2) nsim(5)
assert _rc == 198
di "PASS nwsaom simulate"

* estat score: shape of the result (the comparison with RSiena's score test is in dev/saom_rsiena_score_*)
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip cycle3 theta0(-2.3 2 0 0) fix(transtrip cycle3) k3(300) seed(1)
estat score
assert r(df) == 2 & r(chi2) >= 0 & r(p) >= 0 & r(p) <= 1
matrix S = r(separate)
assert rowsof(S) == 2
estat score, tested(cycle3)
assert r(df) == 1
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k3(100) seed(1)
capture estat score
assert _rc == 198
di "PASS estat score"

* estat timetest: three waves needed
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k3(300) seed(1)
estat timetest
assert r(df) == 3 & r(chi2) >= 0
estat timetest, effects(reciprocity)
assert r(df) == 1
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k3(100) seed(1)
capture estat timetest
assert _rc == 198
di "PASS estat timetest"

* estat importance (the exact comparison with sienaRI is in dev/saom_rsiena_ri_*)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(200) seed(1)
estat importance
matrix RI = r(ri)
assert rowsof(RI) == 3 & colsof(RI) == 2
forvalues pd = 1/2 {
	scalar s = RI[1,`pd'] + RI[2,`pd'] + RI[3,`pd']
	assert abs(s - 1) < 1e-8
}
matrix RH = r(certainty)
assert RH[1,1] > 0 & RH[1,1] < 1
* a co-evolution fit: network and behavior effects (sienaRI gives 0.4330/0.3406/0.2264 and 0.4975/0.1436/0.2922/0.0666 at the estimates of the model below)
qui nwsaom, waves(glasgow1 glasgow2 glasgow3) behavior(smoke1 smoke2 smoke3) outdegree reciprocity transties linear quadratic avalt avsim cores(1) k3(500) seed(1)
estat importance
matrix RIb = r(ri_beh)
assert rowsof(RIb) == 4 & colsof(RIb) == 2
forvalues pd = 1/2 {
	assert abs(RIb[1,`pd'] + RIb[2,`pd'] + RIb[3,`pd'] + RIb[4,`pd'] - 1) < 1e-8
}
* two-mode and non-directed networks (values from sienaRI at the same estimates; data files in dev/)
capture confirm file "dev/saom_twomode_w1.csv"
if _rc == 0 {
	nwclear
	forvalues w = 1/3 {
		qui import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
		mkmat v1-v20, matrix(T`w')
	}
	clear
	forvalues w = 1/3 {
		qui nwset, mat(T`w') bipartite name(tm`w') nooutput
	}
	qui nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity cycle4 unconditional cores(1) seed(1)
	estat importance
	matrix RH = r(certainty)
	assert abs(RH[1,1] - 0.0611) < 0.01
}
capture confirm file "dev/saom_rsiena_symmulti_w1.csv"
if _rc == 0 {
	nwclear
	forvalues w = 1/3 {
		qui import delimited "dev/saom_rsiena_symmulti_w`w'.csv", clear varnames(1) case(preserve)
		mkmat V1-V50, matrix(A`w')
	}
	clear
	forvalues w = 1/3 {
		qui nwset, mat(A`w') undirected name(ma`w') nooutput
	}
	qui nwsaom, waves(ma1 ma2 ma3) outdegree transties cores(1) seed(1)
	estat importance
	matrix RI = r(ri)
	assert abs(RI[1,1] - 0.600) < 0.03
}
di "PASS estat importance"
