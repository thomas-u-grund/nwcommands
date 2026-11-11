* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 20: QAP regression
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
* Worked example: predicting advice
* ============================================================
nwwebuse lazega, nwclear
set seed 12345
nwqap lazega_adv lazega_fr office practice status, permutations(500) plot

set seed 12345
nwqap lazega_adv lazega_fr office practice status, permutations(500) qapspp

* ============================================================
* From a nodal attribute to a dyadic predictor
* ============================================================
generate byte partner = (status == "partner")
set seed 12345
nwqap lazega_adv lazega_fr partner seniority, mode(receiver absdist) ///
    permutations(500)

* ============================================================
* Directed dyads and valued outcomes
* ============================================================
nwgen strength = lazega_adv + lazega_cow + lazega_fr
set seed 12345
nwqap strength office practice status, type(regress) permutations(500)

* ============================================================
* Predicted tie probabilities
* ============================================================
set seed 12345
nwqap lazega_adv lazega_fr office practice status, permutations(500) ///
    predict(adv_fitted)
nwtoedge adv_fitted lazega_adv
gsort -adv_fitted _ego _alter
list _ego _alter adv_fitted lazega_adv in 1/5, clean
tabulate lazega_adv if adv_fitted == adv_fitted[1]

* ============================================================
* Change over time: an earlier network as a predictor
* ============================================================
nwwebuse glasgow, nwclear
set seed 12345
nwqap glasgow2 glasgow1 smoke1 sport1, permutations(200)
