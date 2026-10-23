* Fit statistics of nwergm: log-likelihood (exact / pseudolikelihood / bridge sampling), deviance, AIC, BIC,
* estat ic, lrtest, predict. Reference: R ergm 4.12.0 (R scripts in dev/ergm_missing).
cscript

do unw_core.do
do unw_ergm.do
local d "dev/ergm_missing"
import delimited using "`d'/u_nodes.csv", clear
tempfile nodes
save `nodes'
import delimited using "`d'/u_adj.csv", clear varnames(nonames)
mkmat v*, matrix(A)
mata: st_matrix("A0", editmissing(st_matrix("A"), 0))
nwclear
nwset, mat(A) undirected name(un)
nwset, mat(A0) undirected name(u0)
use `nodes', clear

* dyad-independent: exact (R: ll -188.17797, AIC 382.35594, BIC 394.56122, null -299.43958, nobs 432)
qui nwergm un, edges nodematch(g) nodecov(c)
assert reldif(e(ll), -188.17797134) < 1e-7
assert reldif(e(aic), 382.35594267) < 1e-7
assert reldif(e(bic), 394.56121944) < 1e-7
assert reldif(e(ll_0), -299.43958200) < 1e-7
assert e(df_m) == 3 & e(N) == 432
assert reldif(e(deviance), 376.3559427) < 1e-7
assert reldif(e(deviance_0), 598.8791640) < 1e-7
assert e(ll_se) == 0
estimates store m1
qui nwergm un, edges
estimates store m0
* R anova: Deviance 3.12 on 2 df, p = 0.2101
lrtest m0 m1
assert abs(r(chi2) - 3.12) < 0.005
assert abs(r(p) - 0.2101) < 0.0005
estat ic
matrix S = r(S)
assert reldif(S[1,6], 381.5) < 1e-3 | abs(S[1,5] - 381.5) < 0.1

* predict (R predict.ergm): conditional tie probabilities
qui nwergm un, edges nodematch(g) nodecov(c)
predict, frame(pf) pr
frame pf: assert _N == 432
frame pf: assert abs(p[1] - 0.1897684) < 1e-6 & abs(p[100] - 0.1273231) < 1e-6
predict, frame(pf2) xb
frame pf2: assert abs(p[1] - (-1.4515156)) < 1e-6
predict, matrix(PM) pr
assert abs(PM[1,3] - 0.1897684) < 1e-6 & PM[1,3] == PM[3,1] & PM[2,1] == .

* dyad-dependent MPLE: pseudolikelihood (R: edges -1.646353, triangle -0.033559, ll -190.24163)
qui nwergm u0, edges triangle method(mple)
assert abs(_b[edges] + 1.646353) < 1e-4 & abs(_b[triangle] + 0.033559) < 1e-4
assert abs(e(ll) + 190.241630) < 1e-4
assert abs(e(aic) - 384.4833) < 1e-3

* bridge sampling for a dyad-dependent MCMLE fit (R: -190.21 +- .01, edges -1.61..-1.63, triangle -0.06..-0.08)
forvalues sd = 1/2 {
	qui nwergm u0, edges triangle seed(`sd')
	assert abs(e(ll) + 190.21) < 0.06
	assert e(ll_se) > 0 & e(ll_se) < 0.05
	assert abs(e(aic) - (-2*e(ll) + 4)) < 1e-9
}
qui nwergm u0, edges triangle seed(1) nologlik
assert missing(e(ll))
capture estat ic
assert _rc == 498
di "PASS test_nwergm_ll"
