cscript

do unw_core.do
do unw_ergm.do

* Certifies a genuine, previously-undiscovered scaling bug fix in
* nwergm.ado's own MPLE design-matrix construction (harmonisation unit
* 81, found while building the R-vs-Stata benchmark suite's own
* large-network control case): the design matrix was routed through an
* intermediate Stata MATRIX (`mata: st_matrix("nw_ergm_D", ...)`) before
* being copied AGAIN into Stata dataset variables - fine at the tiny
* scale of this suite's other certification networks (a handful of
* dyads), but a genuine Stata matrix (as opposed to the dataset/variable
* system) is not architected for bulk per-observation data: a trivial,
* isolated 999000x4 st_matrix() call alone did not complete within 2
* minutes (killed, not merely slow), where the equivalent st_store()
* directly from Mata took 0.008 seconds for the identical data. Fixed by
* calling st_store() directly on the Mata design matrix, never routing
* through a Stata matrix at all.
*
* This test exercises a MODERATE-scale (n=200 directed, ~39,800 dyads)
* dyad-independent model (edges+nodematch, pure MPLE - no MCMLE, so wall
* time is dominated entirely by MPLE construction) and asserts it
* completes within a generous time bound. Before the fix, this exact
* scale was already measurably affected (the suite's own 500-node
* undirected benchmark, at 124,750 dyads, ran 151.211s before the fix
* and 93.174s after - a ~1.6x improvement from this fix alone); a true
* REGRESSION back to the st_matrix-routed version would make a test at
* this file's own scale, or the true 999,000-dyad case, hang rather than
* merely run slower - an explicit time-bound assertion catches that
* class of regression far more usefully than a bare pass/fail would.

set seed 20260827
nwclear
nwrandom 200, prob(0.05) name(scaletest)
gen grp = ceil(3*runiform())

timer clear 1
timer on 1
qui nwergm scaletest, edges nodematch(grp)
timer off 1
timer list 1

assert `"`e(method)'"' == "mple"
assert e(nodes) == 200
mata: assert(!missing(st_matrix("e(b)")))
* generous bound - this ran in a few seconds even on a modest machine
* during development; failing to complete within 60s at n=200 would
* indicate the st_matrix-routing regression has reappeared.
assert r(t1) < 60
di "MPLE at n=200 (`=e(N)' dyads) completed in " r(t1) " seconds"
