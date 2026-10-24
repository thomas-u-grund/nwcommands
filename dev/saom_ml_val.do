* Validation of nwsaom ..., ml against RSiena siena07(maxlike = TRUE) (dev/saom_bayes_ml.R): Glasgow s501-s503. args: model (glas|cov) seed
args model seed opts
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
import delimited "dev/saom_rsiena_coev_netendow_beh.csv", clear varnames(1) case(preserve)
mkmat a1, matrix(AM)
clear
set obs 50
gen double alc = .
mata: st_store(., "alc", st_matrix("AM")[., 1])
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(cx`w') nooutput
}
if "`model'" == "glas" nwsaom, waves(cx1 cx2 cx3) outdegree reciprocity transtrip k3(500) seed(`seed') ml mloptions(seed(`seed') `opts')
else nwsaom, waves(cx1 cx2 cx3) outdegree reciprocity transtrip egox(alc) altx(alc) simx(alc) k3(500) seed(`seed') ml mloptions(seed(`seed') `opts')
di "MLRESULT `model' seed `seed' secs " scalar(__saom_ml_secs)
matrix list e(b)
matrix list e(rates_ml)
matrix V = e(V)
matrix SE = vecdiag(V)
forvalues k = 1/`=colsof(SE)' {
	matrix SE[1,`k'] = sqrt(SE[1,`k'])
}
matrix list SE
