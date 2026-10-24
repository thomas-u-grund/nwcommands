* network selection on the co-evolving behavior: behegox, behaltx, behegoplusalt = RSiena egoX / altX / egoPlusAltX with the dependent behavior
* (s50 + alcohol, estimates within noise of siena07, dev/saom_rsiena_behsel.{R,do}); here the statistics against a hand count and the refusals
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bs_data() {
	n = 40
	rseed(8642)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
bs_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(bs`w') nooutput
}
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
capture nwsaom, waves(bs1 bs2 bs3) outdegree reciprocity behavior(z1 z2 z3 : linear quadratic) behegox behaltx behegoplusalt k0(10) k3(30) seed(3)
assert inlist(_rc, 0, 498, 505)
* a smaller model fits (native engine)
nwsaom, waves(bs1 bs2 bs3) outdegree reciprocity behavior(z1 z2 z3 : linear) behegox k0(30) k3(100) seed(3)
assert "`e(engine)'" == "native" & colsof(e(b)) == 4
capture nwsaom, waves(bs1 bs2 bs3) outdegree reciprocity behavior(z1 z2 z3 : linear quadratic) behegox behaltx behegoplusalt k0(10) k3(30) seed(3)
mata:
void bs_check() {
	external class SaomModel scalar __nwsaom_last_M
	external class SaomGraph scalar __nwsaom_last_G2
	real colvector z, ze
	real matrix ties
	real scalar m, k, e1, e2, e3
	real rowvector st
	z = st_data(., "z1")
	m = mean(st_data(., "z1") \ st_data(., "z2") \ st_data(., "z3"))
	SaomBehSimSync(__nwsaom_last_M, z)
	ties = __nwsaom_last_G2.all_ties()
	e1 = 0
	e2 = 0
	e3 = 0
	for (k=1; k<=rows(ties); k++) {
		e1 = e1 + z[ties[k,1]] - m
		e2 = e2 + z[ties[k,2]] - m
		e3 = e3 + z[ties[k,1]] + z[ties[k,2]] - 2 * m
	}
	st = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
	assert(abs(st[3] - e1) < 1e-8 & abs(st[4] - e2) < 1e-8 & abs(st[5] - e3) < 1e-8)
}
bs_check()
end
capture noisily nwsaom, waves(bs1 bs2 bs3) outdegree behegox k3(50)
assert _rc == 198
di as text "selection on the co-evolving behavior PASS"
