* network effects with the dependent behavior as the covariate in a NON-DIRECTED network (netbeh(), behegox/behaltx/behegoplusalt) and samex: estimates equal
* siena07 (symmetric s50 waves + alcohol, dev/saom_rsiena_symnetbeh.R/.do); here: every effect fits natively
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void sn_data() {
	n = 40
	rseed(4242)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	A = ((A + A') :> 0)
	for (w=1; w<=3; w++) {
		st_matrix("__S" + strofreal(w), A)
		F = (runiform(n, n) :< 0.04)
		F = ((F + F') :> 0)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
sn_data()
end
forvalues w = 1/3 {
	nwset, mat(__S`w') directed name(sn`w') nooutput
}
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
foreach ef in samex altsqx outxmore diffsqx outpopx samexinpop crossxoutact transtripx indties totdist2 {
	capture nwsaom, waves(sn1 sn2 sn3) symmetric outdegree behavior(z1 z2 z3 : linear) netbeh(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 3
	}
}
foreach ef in behegox behaltx behegoplusalt {
	capture nwsaom, waves(sn1 sn2 sn3) symmetric outdegree behavior(z1 z2 z3 : linear) `ef' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 3
	}
}
* behavior effects of a non-directed network x a covariate (avXAlt totXAlt avSameXAlt totSameXAlt), siena07: dev/_sb.R
gen double cvx = mod(_n * 3, 5)
foreach ef in behavxalt behtotxalt behavsamexalt behtotsamexalt {
	capture nwsaom, waves(sn1 sn2 sn3) symmetric outdegree behavior(z1 z2 z3 : linear) `ef'(cvx) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native"
}
di "PASS symnb"
