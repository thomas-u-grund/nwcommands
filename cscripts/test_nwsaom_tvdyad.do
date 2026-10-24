* changing dyadic covariates (tvdyadcov(), tvdyadcovrecip(), tvdyadx()): the matrices stem1 .. stem`P' travel as time-varying attribute columns. siena07 agreement
* (statistics and estimates, directed s50 and symmetric s50 waves): dev/saom_rsiena_tvdyad.{R,do}, dev/saom_rsiena_symdyad.{R,do}; here: every effect fits natively
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void td_data() {
	n = 40
	rseed(31337)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		st_matrix("__S" + strofreal(w), ((A + A') :> 0))
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
	for (p=1; p<=2; p++) {
		D = floor(runiform(n, n) :* 3)
		D = D - diag(diag(D))
		st_matrix("TW" + strofreal(p), D)
	}
}
td_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(tw`w') nooutput
	nwset, mat(__S`w') directed name(ts`w') nooutput
}
foreach ef in dyadcov dyadcovrecip {
	capture nwsaom, waves(tw1 tw2 tw3) outdegree reciprocity tv`ef'(TW) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
foreach ef in wwx cywwx inwwx outwwx wxx xwx xwx1 xwx2 xxw {
	capture nwsaom, waves(tw1 tw2 tw3) outdegree reciprocity tvdyadx(`ef':TW) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
	capture nwsaom, waves(ts1 ts2 ts3) symmetric outdegree tvdyadx(`ef':TW) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 2
	capture nwsaom, waves(ts1 ts2 ts3) symmetric outdegree dyadx(`ef':TW1) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
}
capture nwsaom, waves(ts1 ts2 ts3) symmetric outdegree tvdyadcov(TW) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 505)
capture noisily nwsaom, waves(tw1 tw2 tw3) outdegree tvdyadcov(NOPE) k3(30)
assert _rc == 111
capture noisily nwsaom, waves(tw1 tw2 tw3) outdegree tvdyadx(nosuch:TW) k3(30)
assert _rc == 198
di "PASS tvdyad"
