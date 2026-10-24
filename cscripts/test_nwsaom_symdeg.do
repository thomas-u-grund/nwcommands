* non-directed (symmetric) degree-function effects, centred / combined degree effects and transTriads (protocols 40),
* validated against siena07 (targets and estimates, dev/saom_rsiena_symm.R, dev/saom_rsiena_degfam.R); here: they fit natively + refusals
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void sd_data() {
	n = 40
	rseed(97531)
	A = (runiform(n, n) :< 0.08)
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
sd_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') undirected name(sd`w') nooutput
}
foreach spec in "outmore(2)" "outtrunc(3)" "outthreshold(3)" "outinv(2)" "outsqinv(2)" "nbrdist2" "dblnbrdist2" "between" "inpop" "outactsqrt" "inpopc" "outactc" "degplus" "degplusc" "avdeg(2)" "transtriads" {
	capture nwsaom, waves(sd1 sd2 sd3) symmetric outdegree `spec' k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 2
}
* directed relation: the centred variants fit, degplus and transtriads are refused
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(sdd`w') nooutput
}
foreach spec in "outpopc" "inactc" "inpopc" "outactc" "avdeg(2)" {
	capture nwsaom, waves(sdd1 sdd2 sdd3) outdegree reciprocity `spec' k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
capture nwsaom, waves(sdd1 sdd2 sdd3) outdegree reciprocity degplus k3(30)
assert _rc == 198
capture nwsaom, waves(sdd1 sdd2 sdd3) outdegree reciprocity transtriads k3(30)
assert _rc == 198
capture nwsaom, waves(sd1 sd2 sd3) symmetric outdegree outpopc k3(30)
assert _rc == 198
di as text "symmetric degree effects PASS"
