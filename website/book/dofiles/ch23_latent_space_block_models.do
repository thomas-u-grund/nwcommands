* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 23: Latent space and block models
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.34.0,
* nwergm 1.12.0, nwsaom 1.9.1, nwrem 1.7.0, nwdynam 1.11.0, nwalaam 1.3.1,
* nwlsm 1.0.5 and nwsbm 1.0.2, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* A block model
* ============================================================
nwwebuse lazega, nwclear
nwsbm lazega_adv, maxblocks(6) seed(12345) generate(block) replace

nwsbmplot, type(icl) nolegend title("") scheme(s1network)

tabulate block partner
tabulate block office

nwsbmplot, type(matrix) sort shade title("") scheme(s1network)
nwsbmplot, type(membership) colors(gray) title("") scheme(s1network)

* ============================================================
* A latent space model
* ============================================================
nwlsm lazega_adv, dim(2) nsample(2000) burnin(5000) interval(10) chains(2) ///
    seed(12345)
estat mcmcdiag

encode status, generate(rank)
nwlsmplot, color(rank) colors(gray) noarrows edgecolor(gs12%30) ///
    legend(position(6) rows(1) title("") region(lstyle(none))) ///
    scheme(s1network) title("")

estat gof, gof(distance) nsim(100) seed(1)
