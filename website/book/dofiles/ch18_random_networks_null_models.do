* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 18: Random networks and null models
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.26.0,
* nwergm 1.7.1, nwsaom 1.7.1, nwrem 1.3.0 and nwdynam 1.5.1, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* The conditional uniform graph test
* ============================================================
nwwebuse lazega, nwclear
nwcug lazega_adv, stat(nwclustering) rname(cluster_global) reps(1000) ///
    seed(12345) condition(density) plot

nwcug lazega_adv, stat(nwdyads) rname(reciprocity) reps(1000) seed(12345) ///
    condition(density)

* ============================================================
* The conditioning choice is part of the question
* ============================================================
nwcug lazega_adv, stat(nwclustering) rname(cluster_global) reps(1000) ///
    seed(12345) condition(census)
nwcug lazega_adv, stat(nwdyads) rname(reciprocity) reps(1000) seed(12345) ///
    condition(census)

nwcug lazega_adv, stat(nwclustering) rname(cluster_global) reps(1000) ///
    seed(12345) condition(degrees)
nwcug lazega_adv, stat(nwdyads) rname(reciprocity) reps(1000) seed(12345) ///
    condition(degrees)

* ============================================================
* A result that is not unusual
* ============================================================
set seed 2024
nwrandom 71, density(.179) name(draw)
nwcug draw, stat(nwclustering) rname(cluster_global) reps(1000) ///
    seed(12345) condition(density)
