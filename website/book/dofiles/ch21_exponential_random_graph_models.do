* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 21: Exponential random graph models
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom; it was checked against nwcommands 3.18.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* The advice network as an outcome
* ============================================================
nwwebuse lazega, nwclear
foreach v in office practice status {
    encode `v', generate(`v'n)
}

* ============================================================
* Step 1: density
* ============================================================
nwergm lazega_adv, edges seed(12345)

* ============================================================
* Step 2: homophily and status
* ============================================================
nwergm lazega_adv, edges nodematch(officen practicen) nodeofactor(statusn) ///
    nodeifactor(statusn) seed(12345)
estimates store covariates

* ============================================================
* Step 3: reciprocity
* ============================================================
nwergm lazega_adv, edges mutual nodematch(officen practicen) ///
    nodeofactor(statusn) nodeifactor(statusn) seed(12345)
estimates store reciprocity

* ============================================================
* Checking the MCMC simulation
* ============================================================
estat mcmcdiag

* ============================================================
* Step 4: transitivity
* ============================================================
nwergm lazega_adv, edges mutual nodematch(officen practicen) ///
    nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) seed(12345)
estimates store closure

estat mcmcdiag, plot

* ============================================================
* Reading the final model
* ============================================================
foreach t in mutual nodematch_officen nodematch_practicen ///
    nodeofactor_statusn_2 nodeifactor_statusn_2 {
    display %-24s "`t'" %8.2f exp(_b[`t'])
}

* ============================================================
* Comparing models: likelihood, AIC, and BIC
* ============================================================
estimates stats covariates reciprocity closure
lrtest reciprocity closure

predict, frame(pr) pr
frame pr: summarize p

* ============================================================
* Goodness of fit
* ============================================================
estat gof, gof(model distance odegree idegree espartners) seed(12345) plot

* ============================================================
* An undirected case: Faux Mesa High
* ============================================================
nwwebuse mesa, nwclear
nwsummarize mesa
encode race, generate(racen)

nwergm mesa, edges nodematch(grade racen) seed(12345)

nwergm mesa, edges nodematch(grade racen) gwesp(.25) seed(12345)
estat mcmcdiag

* ============================================================
* Why gwesp and not triangle
* ============================================================
capture noisily nwergm mesa, edges nodematch(grade racen) triangle seed(12345)

* ============================================================
* Missing data
* ============================================================
nwtomata mesa, mat(A)
mata: A[1,2] = A[2,1] = A[1,3] = A[3,1] = A[10,20] = A[20,10] = .
mata: st_matrix("M", A)
nwset, mat(M) undirected name(mesa_na)
nwergm mesa_na, edges nodematch(grade racen) seed(12345)
display "informative dyads: " e(N) "   missing dyads: " e(nmissing)
