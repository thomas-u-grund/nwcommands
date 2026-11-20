* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 24: Influence and contagion
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.28.0,
* nwergm 1.10.0, nwsaom 1.8.1, nwrem 1.5.1, nwdynam 1.9.1, nwalaam 1.2.0,
* nwlsm 0.6.0 and nwsbm 0.3.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Exposure and the chance of adoption
* ============================================================
nwwebuse glasgow, nwclear
generate toa = cond(smoke1 > 1, 1, cond(smoke2 > 1, 2, cond(smoke3 > 1, 3, ///
    .)))
preserve
nwdiffuse long glasgow1, toa(toa) clear
list in 1/6
logit adopt exposure i.period, nolog
restore

* ============================================================
* An outcome that follows the friends: a spatial lag
* ============================================================
nwspmatrix glasgow2, name(W)
spregress alcohol2 smoke2 sport2, ml dvarlag(W) nolog
regress alcohol2 smoke2 sport2

* ============================================================
* An attribute as the outcome: the autologistic actor attribute model
* ============================================================
nwwebuse glasgow, nwclear
generate byte smoker1 = (smoke1 > 1)
tabulate smoker1
nwalaam smoker1 glasgow1, effects(density contagion) mple

nwalaam smoker1 glasgow1, effects(density contagion sender receiver) ///
    seed(12345)
estat mcmcdiag
display exp(_b[contagion])

quietly summarize alcohol1
generate double alc_c = alcohol1 - r(mean)
quietly summarize sport1
generate double sport_c = sport1 - r(mean)
nwalaam smoker1 glasgow1, effects(density contagion sender receiver ///
    ego(alc_c) ego(sport_c)) seed(12345)

estat gof, nsim(1000) seed(7)

nwalaam simulate, nsim(100) generate(sim) seed(2)
nwalaam smoker1 glasgow1, effects(density contagion sender receiver) ///
    method(ee) seed(12345)
