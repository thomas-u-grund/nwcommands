* Missing data in nwergm: missing dyads (NA ties) as in R ergm (excluded from the pseudolikelihood,
* missing-data MCMLE with a constrained second sample), missing covariate values (R refuses them).
* Reference values: R ergm 4.12.0 (dev/ergm_missing/ref_miss.R, ref_miss2.R, mple_dd.R).
cscript

do unw_core.do
do unw_ergm.do
local d "dev/ergm_missing"

* ---- undirected 30 nodes, 3 missing dyads, nodal covariates g (factor) and c
import delimited using "`d'/u_nodes.csv", clear
tempfile nodes
save `nodes'
import delimited using "`d'/u_adj.csv", clear varnames(nonames)
mkmat v*, matrix(A)
nwclear
nwset, mat(A) undirected name(un)
use `nodes', clear

* dyad-independent model: MPLE is the MLE; the missing dyads leave the likelihood (N = 435 - 3)
qui nwergm un, edges nodematch(g) nodecov(c)
assert e(nmissing) == 3
assert e(N) == 432
assert reldif(_b[edges], -1.43765669) < 1e-4
assert reldif(_b[nodematch_g], -0.46711868) < 1e-4
assert reldif(_se[edges], 0.17716308) < 1e-4
assert reldif(_se[nodecov_c], 0.07143919) < 1e-4
assert reldif(e(ll), -188.17797134) < 1e-6
assert reldif(e(bic), 394.56121944) < 1e-6
* missing dyads are not zeros
mata: B = editmissing(st_matrix("A"), 0)
mata: st_matrix("A0", B)
nwclear
nwset, mat(A0) undirected name(u0)
use `nodes', clear
qui nwergm u0, edges nodematch(g) nodecov(c)
assert e(nmissing) == 0
assert e(N) == 435
assert abs(_b[edges] - (-1.43765669)) > 1e-3

* dyad-dependent model (missing-data MCMLE); R over 3 seeds: edges -1.617..-1.626, triangle -0.043..-0.066, logLik -189.70..-189.72
nwclear
nwset, mat(A) undirected name(un)
use `nodes', clear
forvalues sd = 1/3 {
	qui nwergm un, edges triangle seed(`sd')
	assert e(converged) == 1
	assert e(N) == 432
	assert abs(_b[edges] + 1.62) < 0.12
	assert abs(_b[triangle] + 0.05) < 0.15
	assert abs(_se[edges] - 0.23) < 0.05
	assert abs(e(ll) + 189.71) < 0.1
}

* ---- R refuses missing nodal covariates and dyadic covariates with missing values
replace c = . in 4
capture nwergm un, edges nodecov(c)
assert _rc == 416
capture nwergm un, edges nodematch(c)
assert _rc == 416
replace c = 1 in 4
capture nwergm un, edges edgecov(un)
assert _rc == 416

* ---- heavier missingness: 40 nodes, 70 missing dyads (R: MPLE edges -2.7961, nodematch 1.3916, logLik -251.5903, N 710)
import delimited using "`d'/u2_nodes.csv", clear
save `nodes', replace
import delimited using "`d'/u2_adj.csv", clear varnames(nonames)
mkmat v*, matrix(A2)
nwclear
nwset, mat(A2) undirected name(un2)
use `nodes', clear
qui nwergm un2, edges nodematch(g)
assert e(nmissing) == 70
assert e(N) == 710
assert reldif(_b[edges], -2.7961192) < 1e-4
assert reldif(_b[nodematch_g], 1.3916094) < 1e-4
assert reldif(e(ll), -251.5902834) < 1e-6
* R MCMLE over 4 seeds: edges -2.706..-2.728, nodematch 1.463..1.474, triangle -0.200..-0.220, se .25/.28-.32/.24-.30, logLik -251.20..-251.27
foreach sd in 1 2 {
	qui nwergm un2, edges nodematch(g) triangle seed(`sd')
	assert e(converged) == 1
	assert abs(_b[edges] + 2.71) < 0.1
	assert abs(_b[nodematch_g] - 1.46) < 0.1
	assert abs(_b[triangle] + 0.21) < 0.15
	assert abs(_se[edges] - 0.26) < 0.05
	assert abs(_se[triangle] - 0.27) < 0.06
	assert abs(e(ll) + 251.25) < 0.15
}

* ---- directed, 30 nodes, 60 missing dyads (R MCMLE edges+mutual: -3.08, 3.90, se .19/.42, logLik -253.0..-253.2)
import delimited using "`d'/d2_adj.csv", clear varnames(nonames)
mkmat v*, matrix(D2)
nwclear
nwset, mat(D2) directed name(dn2)
forvalues sd = 1/2 {
	qui nwergm dn2, edges mutual seed(`sd')
	assert e(converged) == 1
	assert e(nmissing) == 60
	assert abs(_b[edges] + 3.08) < 0.12
	assert abs(_b[mutual] - 3.90) < 0.3
	assert abs(_se[mutual] - 0.42) < 0.1
	assert abs(e(ll) + 253.15) < 0.5
}
di "PASS test_nwergm_missing"
