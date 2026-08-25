cscript

do unw_ergm.do

* Certifies ErgmMCMLE() (Part XIII of the governing nwergm task) against
* a REAL Statnet `ergm()` MCMLE fit, independently generated via
* dev/ergm_reference/ref_mcmle.R (R 4.6.0, ergm 4.12.0):
*
*   ergm(nwD ~ edges + mutual)  on the same directed canonical network
*   test_nwergm_statistics.do/test_nwergm_mple.do use.
*
* Real Statnet reference (converged after 1 MCMLE iteration - this
* particular network is close enough to dyad-independent that MCMLE
* barely moves from MPLE): coef edges=-0.91768257972483,
* mutual=0.22086332077996; vcov diag edges=0.44468325270188,
* mutual=2.17161915170670.
*
* This is a genuinely dyad-DEPENDENT model (mutual violates dyad
* independence), so unlike test_nwergm_mple.do this is a real test of
* the MCMLE Newton-step/step-length/convergence machinery, not just the
* design-matrix builder - certifying that this package's own
* deliberately-simplified step-length (a Mahalanobis trust-region cap,
* not Statnet's own convex-hull linear program - see unw_ergm.do's own
* header comment on ErgmMCMLE for the full disclosure) and convergence
* test still land in the right place. A generous tolerance is used
* throughout (both this run's own MCMC and Statnet's own MCMC are
* independent stochastic processes - exact agreement is neither
* expected nor the right thing to assert; investigate only a MATERIAL,
* systematic disagreement, per Part XXVII's own explicit guidance).

mata:
mata set matastrict off

gD = ErgmGraph()
gD.init(5, 1)
gD.toggle(1,2)
gD.toggle(2,1)
gD.toggle(1,3)
gD.toggle(3,4)
gD.toggle(4,5)
gD.toggle(5,1)

M = ErgmModel()
M.init()
td1 = ErgmTermData()
M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
td2 = ErgmTermData()
M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))

rseed(777)
theta0 = (-0.91629073186161214, 0.22314355130166649)
fit = ErgmMCMLE(M, gD, theta0, 20, 3000, 50, 3000, &ergm_propose_tnt(), 0)

st_numscalar("converged", fit.converged)
st_numscalar("niter", fit.niter)
st_numscalar("edges_coef", fit.coef[1])
st_numscalar("mutual_coef", fit.coef[2])
st_numscalar("edges_var", fit.vcov[1,1])
st_numscalar("mutual_var", fit.vcov[2,2])
end

assert converged == 1
assert niter <= 20
assert reldif(edges_coef, -0.91768257972483) < 0.2
assert reldif(mutual_coef, 0.22086332077996) < 0.6
assert reldif(edges_var, 0.44468325270188) < 0.6
assert reldif(mutual_var, 2.17161915170670) < 0.6
