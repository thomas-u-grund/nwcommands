* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 21: Exponential random graph models
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.33.0,
* nwergm 1.12.0, nwsaom 1.9.1, nwrem 1.7.0, nwdynam 1.11.0, nwalaam 1.3.1,
* nwlsm 1.0.5 and nwsbm 1.0.2, the versions the book was printed with.
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

* ============================================================
* Step 1: density
* ============================================================
nwergm lazega_adv, edges seed(12345)

* ============================================================
* Step 2: homophily and status
* ============================================================
nwergm lazega_adv, edges nodematch(office practice) nodeofactor(status) ///
    nodeifactor(status) seed(12345)
estimates store covariates

* ============================================================
* Step 3: reciprocity
* ============================================================
nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodeofactor(status) nodeifactor(status) seed(12345)
estimates store reciprocity

* ============================================================
* Checking the MCMC simulation
* ============================================================
estat mcmcdiag

* ============================================================
* Step 4: transitivity
* ============================================================
nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodeofactor(status) nodeifactor(status) gwesp(.5) seed(12345)
estimates store closure

nwcoefplot covariates reciprocity closure, drop(edges) msymbol(O D T) ///
    title("") scheme(s1network)

estat mcmcdiag, plot

* ============================================================
* Reading the final model
* ============================================================
foreach t in mutual nodematch_office nodematch_practice ///
    nodeofactor_status_2 nodeifactor_status_2 {
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

estat gof, gof(espartners) seed(12345) plot panels title("") scheme(s1network)
