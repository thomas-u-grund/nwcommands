* covariate effects for a non-directed (symmetric) relation, constant and changing (tvcov) covariates; native only for the covariate x
* triad / popularity / activity and the threshold / contrast families. siena07 agreement: dev/saom_rsiena_symcov.R, dev/saom_rsiena_symtv.R.
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void sc_data() {
	n = 40
	rseed(55321)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	A = (A + A') :> 0
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.03)
		F = (F + F') :> 0
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
sc_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') undirected name(sc`w') nooutput
}
gen double xa = mod(_n * 7, 4)
gen double tw1 = mod(_n, 4)
gen double tw2 = mod(_n + (_n > 20), 4)
gen double tw3 = mod(_n + (_n > 20) + (_n > 10), 4)
foreach ef in altsqx egosqx egoplusaltsqx altlthresholdx egolthresholdx degabsdiffx diffx absdiffx diffsqx egodiffx althigheregox inpopx inactx unequalx samexinpop diffxinpop samexoutact homxoutact altxoutact samextranstrip diffxtranstrip homxtranstrip egoxaltx {
	capture nwsaom, waves(sc1 sc2 sc3) symmetric outdegree `ef'(xa) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 2
}
foreach ef in egox altx samex simx absdiffx diffx samextranstrip homxoutact {
	capture nwsaom, waves(sc1 sc2 sc3) symmetric outdegree tvcov(tw1 tw2 tw3) `ef'(tw) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 2 & trim("`e(tvcov)'") == "tw"
}
di as text "symmetric covariate effects PASS"
