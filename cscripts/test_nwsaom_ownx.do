* own-network effects without a covariate (ownx(): jin jout transtrip1 transtrip2 transrectrip2 transtripfe transtripee outpopmore outpopsqrtmore outpopthreshold and the ego
* degree effects), plugin protocol 54; siena07 agreement (s50, symmetric waves for jout): dev/saom_rsiena_dg.{R,do}, dev/saom_rsiena_symdg.R
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void dg_data() {
	n = 40
	rseed(9191)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		st_matrix("__S" + strofreal(w), ((A + A') :> 0))
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
dg_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(dd`w') nooutput
	nwset, mat(__S`w') directed name(ds`w') nooutput
}
foreach ef in jin jout transtrip1 transtrip2 transrectrip2 transtripfr transtripfe transtripee outpopmore:2 outpopsqrtmore:2 outpopthreshold:2 outactego outactmoreego:2 outactsqrtmoreego:2 outmoreego:2 divoutego inactego divinego reciactego {
	capture nwsaom, waves(dd1 dd2 dd3) outdegree reciprocity ownx(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
capture nwsaom, waves(ds1 ds2 ds3) symmetric outdegree ownx(jout) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 505)
capture noisily nwsaom, waves(dd1 dd2 dd3) outdegree ownx(nosuch) k3(30)
assert _rc == 198
di "PASS ownx"
