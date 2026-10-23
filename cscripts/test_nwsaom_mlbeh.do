* Maximum likelihood / Bayes with a co-evolving behavior: the complete-data score of the augmented chain (network and behavior ministeps), averaged over
* the chain, equals the score of the observed-data likelihood (Fisher's identity). Checked on 3 actors, three waves, a behavior with levels 0..2,
* against exact enumeration of the 1728 states (dev/saom_ml_exact_coev.R); then the estimators run on the Glasgow data with the behavior.
cscript
adopath ++ "."
do unw_core.do
do unw_ergm.do
do unw_saom.do

nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behegox behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt k3(100) seed(1)
assert e(has_behavior) == 1
mata:
mata set matastrict off
class ErgmGraph scalar tb_graph(real matrix Wm) {
	class ErgmGraph scalar Gt
	real scalar i, j
	Gt = ErgmGraph()
	Gt.init(3, 1)
	for (i=1; i<=3; i++) for (j=1; j<=3; j++) if (Wm[i,j] != 0) Gt.toggle(i, j)
	return(Gt)
}
end
matrix W1 = (0,1,0\0,0,1\0,0,0)
matrix W2 = (0,1,1\1,0,0\0,0,0)
matrix W3 = (0,0,1\1,0,1\0,1,0)
mata:
__nwsaom_last_G1 = tb_graph(st_matrix("W1"))
__nwsaom_last_G2 = tb_graph(st_matrix("W2"))
__nwsaom_last_G3 = tb_graph(st_matrix("W3"))
__tb_z1 = (0\1\1)
__tb_z2 = (1\1\2)
__tb_z3 = (1\2\2)
__nwsaom_last_Behwaves = (&__tb_z1, &__tb_z2, &__tb_z3)
__nwsaom_beh_minval = 0
__nwsaom_beh_maxval = 2
end
nwsaom_ml, theta0(-0.8 0.5 0.3 0.4 -0.3 0.6) rate0(3 3 2 2) nsub(0) n1(5) n3(60000) mult(10) seed(5) notable
matrix SC = e(ml_score)
* exact observed-data score (R, dev/saom_ml_exact_coev.R): effects (outdegree, reciprocity, behavior egoX, linear, quadratic, avAlt), network rates, behavior rates
* (the egoX term of the behavior keeps the centring constant of the fitted Glasgow data, 3.11333)
matrix EX = (5.208911, 1.873297, -9.746997, 1.46705, -0.7009421, -0.1248466, 0.06943806, -0.04015943, 0.1363325, -0.1154788)
forvalues k = 1/10 {
	di "score " `k' ": chain " SC[1,`k'] "  exact " EX[1,`k']
	assert abs(SC[1,`k'] - EX[1,`k']) < 0.12
}
di "PASS nwsaom ml with a behavior: the score of the augmented chain against exact enumeration"
