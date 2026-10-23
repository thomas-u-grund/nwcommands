* homXTransRecTrip sameXTransRecTrip diffXTransRecTrip egoXaltXRecip sameXCycle4 sameInXCycle4 avGroupEgoX totGroupEgoX (netx(), netbeh(), tvcov()), plugin protocol 50.
* siena07 agreement (observed statistics and estimates): dev/saom_rsiena_nx2.{R,do} equivalents (s50 age, _tv, alcohol, symmetric waves)
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void cz_data() {
	n = 40
	rseed(777)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		B = ((A + A') :> 0)
		st_matrix("__S" + strofreal(w), B)
		F = (runiform(n, n) :< 0.04)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
cz_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(cd`w') nooutput
	nwset, mat(__S`w') directed name(cs`w') nooutput
}
gen double xa = mod(_n * 7, 4)
gen double tw1 = mod(_n, 4)
gen double tw2 = mod(_n + (_n > 20), 4) + 1
gen double tw3 = mod(_n + (_n > 20) + (_n > 10), 4)
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
* constant covariate, directed
foreach ef in homxtransrectrip samextransrectrip diffxtransrectrip egoxaltxrecip samexcycle4 sameinxcycle4 {
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity netx(`ef':xa) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
* RSiena parameter 2 (sqrt) of the 4-cycle effects
capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity netx(samexcycle4:xa) xparam(2) k0(10) k3(30) seed(3)
assert inlist(_rc, 0, 498, 505)
* changing covariate (group mean needs a covariate whose mean changes between the periods)
foreach ef in homxtransrectrip samexcycle4 sameinxcycle4 avgroupegox totgroupegox {
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity tvcov(tw1 tw2 tw3) netx(`ef':tw) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
* the group-mean effects are not defined for a constant covariate
capture noisily nwsaom, waves(cd1 cd2 cd3) outdegree netx(avgroupegox:xa) k3(30)
assert _rc == 198
* the dependent behavior as the covariate, directed and symmetric
foreach ef in homxtransrectrip egoxaltxrecip samexcycle4 sameinxcycle4 avgroupegox totgroupegox {
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity behavior(z1 z2 z3 : linear) netbeh(`ef') k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 4
}
foreach ef in samexcycle4 sameinxcycle4 avgroupegox {
	capture nwsaom, waves(cs1 cs2 cs3) symmetric outdegree behavior(z1 z2 z3 : linear) netbeh(`ef') k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	capture nwsaom, waves(cs1 cs2 cs3) symmetric outdegree netx(`ef':xa) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 198, 498, 505)
}
* similarity effects with the dependent behavior as the covariate (protocol 58; siena07: dev/saom_rsiena_nx2.do modes C and F)
foreach ef in simdist2 simegodist2 simegoindist2 simrecipx simxtranstrip {
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity behavior(z1 z2 z3 : linear) netbeh(`ef') k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 4
	capture nwsaom, waves(cs1 cs2 cs3) symmetric outdegree behavior(z1 z2 z3 : linear) netbeh(`ef') k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
}
* two category covariates (protocol 59): netx(samexv:v1:v2) netx(samexvinpop:v1:v2[:#]); siena07: dev/saom_rsiena_dbl.R/.do
gen double ca1 = 1 + mod(_n, 3)
gen double ca2 = 1 + mod(_n * 5, 4)
foreach sp in samexv:ca1:ca2 samexvinpop:ca1:ca2 samexvinpop:ca1:ca2:1 samexvinpop:ca1:ca2:2 samexvinpop2:ca1:ca2 {
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity netx(`sp') k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
capture nwsaom, waves(cd1 cd2 cd3) outdegree netx(samexv:ca1) k3(30)
assert _rc != 0
* simRecipX / simXTransTrip as netx effects of a changing covariate (protocol 61: codes 53 / 167)
foreach ef in simrecipx simxtranstrip {
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity tvcov(tw1 tw2 tw3) netx(`ef':tw) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	capture nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity netx(`ef':xa) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
}
di "PASS cz2"
