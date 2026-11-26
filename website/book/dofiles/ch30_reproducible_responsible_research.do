* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 30: Reproducible and responsible network research
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.39.0,
* nwergm 1.16.1, nwsaom 1.9.2, nwrem 1.7.2, nwdynam 1.11.2, nwalaam 1.4.0,
* nwlsm 1.0.6 and nwsbm 1.1.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it; lines marked "run" are fits that the text summarizes.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Stored results: chaining commands together
* ============================================================
nwwebuse lazega, nwclear
quietly nwcug lazega_adv, stat(nwdyads) rname(reciprocity) reps(1000) ///
    seed(12345)
return list

set seed 12345
quietly nwqap lazega_adv lazega_fr office practice status, permutations(500)
ereturn list
test same_practice same_status
