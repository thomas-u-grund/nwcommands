* nwsaom multinet: fix(), theta0(), estat score and estat timetest after several networks (and a behavior)
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void mn_data() {
	n = 40
	rseed(7771)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	B = (runiform(n, n) :< 0.06)
	B = B - diag(diag(B))
	for (w=1; w<=4; w++) {
		st_matrix("__A" + strofreal(w), A)
		st_matrix("__B" + strofreal(w), B)
		F = (runiform(n, n) :< 0.04)
		A = abs(A - F)
		A = A - diag(diag(A))
		F = (runiform(n, n) :< 0.04)
		B = abs(B - F)
		B = B - diag(diag(B))
	}
}
mn_data()
end
forvalues w = 1/4 {
	nwset, mat(__A`w') directed name(na`w') nooutput
	nwset, mat(__B`w') directed name(nb`w') nooutput
	gen double z`w' = mod(_n * (3 + `w'), 4)
}
* fix the cross effect at 0 and test it
qui nwsaom multinet, net1(na1 na2 na3 na4) net2(nb1 nb2 nb3 nb4) cross1(crprod) theta0(-1 0 0 -1 0) fix(net1_x_crprod) k0(20) k3(100) seed(5)
assert abs(_b[net1_x_crprod]) < 1e-12
assert _se[net1_x_crprod] == 0
estat score
assert r(df) == 1 & r(chi2) < .
estat timetest
assert r(df) < . & r(chi2) < .
* a behavior
qui nwsaom multinet, net1(na1 na2 na3 na4) net2(nb1 nb2 nb3 nb4) behavior(z1 z2 z3 z4) beheff1(linear quadratic avalt) fix(beh_avalt) theta0(-1 0 -1 0 0 0 0) k0(20) k3(100) seed(5)
estat score
assert r(df) == 1
estat timetest, effects(net1_outdegree beh_linear)
capture estat gof
assert _rc == 198
di "PASS mnpost"
