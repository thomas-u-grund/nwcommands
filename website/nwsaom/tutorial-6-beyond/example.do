* nwsaom tutorial 6: maximum likelihood, Bayesian estimation, two networks
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* Method of moments, for comparison
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1)

* Maximum likelihood
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1) ml

* Bayesian estimation: a short run, after a method-of-moments fit
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1)
nwsaom bayes, nprewarm(20) nwarm(20) nmain(100) nrunmh(5) seed(7)

* Two networks that change together. The Glasgow data have only one network,
* so we SIMULATE a second one ("advice") that overlaps with friendship.
nwtomata glasgow1, mat(F1)
nwtomata glasgow2, mat(F2)
set seed 20261001
mata: A1 = (F1 :* (runiform(50, 50) :< 0.7) + (runiform(50, 50) :< 0.005)) :> 0
mata: _diag(A1, 0)
mata: A2 = (A1 :* (runiform(50, 50) :< 0.8) + F2 :* (1 :- A1) :* (runiform(50, 50) :< 0.4)) :> 0
mata: _diag(A2, 0)
nwset, mat(A1) directed name(advice1)
nwset, mat(A2) directed name(advice2)
nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) seed(1)

* The overall maximum convergence ratio is above 0.25: restart from the estimates
matrix b = e(b)
local th
forvalues j = 1/`=colsof(b)' {
    local th `th' `=b[1,`j']'
}
nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) theta0(`th') seed(2)
