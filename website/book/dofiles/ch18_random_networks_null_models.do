* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 18: Random networks and null models
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
* The conditional uniform graph test
* ============================================================
nwwebuse lazega, nwclear
nwcug lazega_adv, stat(nwclustering ##net##, generate(_clustering) ///
    replace) rname(cluster_global) reps(1000) seed(12345) ///
    condition(density) plot

nwcug lazega_adv, stat(nwdyads ##net##) rname(reciprocity) reps(1000) ///
    seed(12345) condition(density)

* ============================================================
* The conditioning choice is part of the question
* ============================================================
nwcug lazega_adv, stat(nwclustering ##net##, generate(_clustering) ///
    replace) rname(cluster_global) reps(1000) seed(12345) ///
    condition(census)
nwcug lazega_adv, stat(nwdyads ##net##) rname(reciprocity) reps(1000) ///
    seed(12345) condition(census)

nwcug lazega_adv, stat(nwclustering ##net##, generate(_clustering) ///
    replace) rname(cluster_global) reps(1000) seed(12345) ///
    condition(degrees)
nwcug lazega_adv, stat(nwdyads ##net##) rname(reciprocity) reps(1000) ///
    seed(12345) condition(degrees)

nwwebuse glasgow, nwclear
nwcug glasgow1, stat(nwclustering ##net##, generate(_clustering) replace) ///
    rname(cluster_global) reps(500) seed(12345) condition(density)
nwcug glasgow1, stat(nwclustering ##net##, generate(_clustering) replace) ///
    rname(cluster_global) reps(500) seed(12345) condition(census)

* ============================================================
* A result that is not unusual
* ============================================================
set seed 2024
nwrandom 71, density(.179) name(draw)
nwcug draw, stat(nwclustering ##net##, generate(_clustering) replace) ///
    rname(cluster_global) reps(1000) seed(12345) condition(density)
