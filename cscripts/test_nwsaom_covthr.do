* covariate threshold / contrast effects (protocol 41, native only): egoplusaltsqx diffsqx egodiffx althigheregox unequalx egolthresholdx egorthresholdx
* altlthresholdx altrthresholdx degabsdiffx degposdiffx degnegdiffx; the observed statistics and the estimates equal siena07 (s50, dev/saom_rsiena_covthr.R)
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void ctr_data() {
	n = 40
	rseed(86420)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
ctr_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(cr`w') nooutput
}
gen double xa = mod(_n * 7, 5)
foreach ef in egoplusaltsqx diffsqx egodiffx althigheregox unequalx egolthresholdx egorthresholdx altlthresholdx altrthresholdx degabsdiffx degposdiffx degnegdiffx {
	capture nwsaom, waves(cr1 cr2 cr3) outdegree reciprocity `ef'(xa) covthreshold(1) k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
replace xa = . in 2
capture nwsaom, waves(cr1 cr2 cr3) outdegree unequalx(xa) k3(30)
assert _rc == 198
di as text "covariate threshold/contrast PASS"
