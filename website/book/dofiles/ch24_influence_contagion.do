* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 24: Influence and contagion
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.32.1,
* nwergm 1.11.1, nwsaom 1.9.1, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.1,
* nwlsm 1.0.3 and nwsbm 1.0.2, the versions the book was printed with.
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

estat gof, nsim(1000) seed(7) plot title("") scheme(s1network)

nwalaam simulate, nsim(100) generate(sim) seed(2)
nwalaam smoker1 glasgow1, effects(density contagion sender receiver) ///
    method(ee) seed(12345)
