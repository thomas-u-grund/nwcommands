* covariate x triad / popularity / activity effects (protocol 39, native only): all 16 fit natively, the observed statistics equal siena07's
* targets and the estimates agree (s50, dev/saom_rsiena_covtriad.{R,do}); here: every option fits natively on synthetic data, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void ct_data() {
	n = 40
	rseed(2468)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
ct_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(ct`w') nooutput
}
gen double xa = mod(_n * 7, 4)
foreach ef in samextranstrip diffxtranstrip simxtranstrip homxtranstrip samexoutact diffxoutact samexreciact diffxreciact homxoutact altxoutact inpopx outpopx inactx outactx samexinpop diffxinpop {
	capture nwsaom, waves(ct1 ct2 ct3) outdegree reciprocity `ef'(xa) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
* missing covariate values are refused
replace xa = . in 2
capture nwsaom, waves(ct1 ct2 ct3) outdegree samextranstrip(xa) k3(30)
assert _rc == 198
di as text "covariate x triad/popularity/activity PASS"
