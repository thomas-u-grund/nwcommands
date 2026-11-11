* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 22: Stochastic actor-oriented models
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
* The objective function and the choice probability
* ============================================================
nwwebuse glasgow, nwclear
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(1)

* ============================================================
* Looking at the data first
* ============================================================
nwsaom describe, waves(glasgow1 glasgow2 glasgow3) behavior(alcohol1 ///
    alcohol2 alcohol3)

* ============================================================
* Building up a real model on Glasgow
* ============================================================
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip ///
    nodematch(smoke1) seed(12345)

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ///
    nodematch(smoke1) seed(12345)

* ============================================================
* Does the model fit? Goodness of fit
* ============================================================
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ///
    seed(12345)

nwsaom refit, seed(12346)
estat gof, nsim(100) seed(1)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree seed(12345)

estat gof, nsim(100) seed(1)

* ============================================================
* Selection or influence? Letting behavior evolve too
* ============================================================
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ///
    behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt ///
    seed(12345)
