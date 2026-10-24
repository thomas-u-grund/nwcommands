* nwsaom ..., ml: (1) the complete-data score of the augmented chain, averaged over the chain, equals the score of the observed-data likelihood
* (Fisher's identity) - checked on a 4-actor model with three waves against exact enumeration (4096 states, matrix power series of the one-ministep
* transition matrix, dev/saom_ml_exact.R); (2) the estimator runs on the Glasgow data and agrees with the method of moments fit and with RSiena's
* maximum likelihood estimates (siena07 maxlike = TRUE, dev/saom_bayes_ml.R: -2.66, 2.22, 0.71; se .14, .18, .08; rates 5.9, 5.0).
cscript
adopath ++ "."
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(G`w')
	nwset, mat(G`w') directed name(gl`w') nooutput
}
* --- Glasgow, three effects
nwsaom, waves(gl1 gl2 gl3) outdegree reciprocity transtrip k3(500) seed(1) ml mloptions(seed(2) n3(300) nstart2(50))
assert e(estimator) == "ml"
assert colsof(e(b)) == 3
matrix R = e(rates_ml)
assert abs(el(e(b),1,1) - (-2.66)) < 0.35
assert abs(el(e(b),1,2) - 2.22) < 0.6
assert abs(el(e(b),1,3) - 0.71) < 0.3
assert R[1,1] > 4 & R[1,1] < 8.5 & R[1,2] > 3.5 & R[1,2] < 7.5
assert sqrt(el(e(V),1,1)) > 0.05 & sqrt(el(e(V),1,1)) < 0.3
assert e(tconv_max_ml) < 1
* --- exact check of the score
mata:
mata set matastrict off
class ErgmGraph scalar tb_graph(real matrix Wm) {
	class ErgmGraph scalar Gt
	real scalar i, j
	Gt = ErgmGraph()
	Gt.init(4, 1)
	for (i=1; i<=4; i++) for (j=1; j<=4; j++) if (Wm[i,j] != 0) Gt.toggle(i, j)
	return(Gt)
}
end
matrix W1 = (0,1,0,0\0,0,1,0\1,0,0,0\0,0,0,0)
matrix W2 = (0,1,0,1\1,0,1,0\1,0,0,0\0,0,1,0)
matrix W3 = (0,0,1,1\1,0,0,0\0,1,0,1\1,0,0,0)
mata:
__nwsaom_last_G1 = tb_graph(st_matrix("W1"))
__nwsaom_last_G2 = tb_graph(st_matrix("W2"))
__nwsaom_last_G3 = tb_graph(st_matrix("W3"))
end
nwsaom_ml, theta0(-1 0.7 0.2) rate0(3 3) nsub(0) n1(5) n3(80000) mult(10) seed(5) notable
matrix SC = e(ml_score)
* exact observed-data score: theta (-1, .7, .2), rates (3, 3): 6.1168, 0.8994, 0.8070, -0.4418, 0.6181
matrix EX = (6.1168, 0.8994, 0.8070, -0.4418, 0.6181)
forvalues k = 1/5 {
	di "score " `k' ": chain " SC[1,`k'] "  exact " EX[1,`k']
	assert abs(SC[1,`k'] - EX[1,`k']) < 0.1
}
di "PASS nwsaom ml: Glasgow estimates and the score of the augmented chain against exact enumeration"
