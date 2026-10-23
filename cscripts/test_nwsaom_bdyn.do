* behavior effects with ANOTHER co-evolving behavior as the covariate (behx(family:beh2), behfrom(beh2), behavxalt(beh2) ...; plugin protocol 53): siena07
* agreement (alcohol effects with smoking as the covariate, s50): dev/saom_rsiena_bdyn.{R,do}; here: every family runs natively, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bd_data() {
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
bd_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(bd`w') nooutput
}
gen double a1 = mod(_n * 7, 5)
gen double a2 = mod(_n * 7 + (_n > 20), 5)
gen double a3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
gen double s1 = mod(_n * 3, 4)
gen double s2 = mod(_n * 3 + (_n > 15), 4)
gen double s3 = mod(_n * 3 + (_n > 15) + (_n > 25), 4)
foreach o in "behavxalt(beh2)" "behtotxalt(beh2)" "behavsamexalt(beh2)" "behfrom(beh2)" "behx(avxinalt:beh2)" "behx(minxalt:beh2)" "behx(avxaltdist2:beh2)" "behx(degabscontrx:beh2)" "behx(avaltsamex:beh2)" {
	capture nwsaom, waves(bd1 bd2 bd3) outdegree reciprocity behavior(a1 a2 a3 : linear avalt | s1 s2 s3 : linear) `o' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native"
}
* beh2 needs a second behavior
capture noisily nwsaom, waves(bd1 bd2 bd3) outdegree behavior(a1 a2 a3 : linear avalt) behfrom(beh2) k3(30)
assert _rc == 198
di "PASS bdyn"
