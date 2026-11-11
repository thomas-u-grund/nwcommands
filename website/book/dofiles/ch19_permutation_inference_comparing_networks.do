* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 19: Permutation inference and comparing networks
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
* Node-label permutation
* ============================================================
nwwebuse lazega, nwclear
set seed 12345
nwpermute lazega_fr, generate(fr_perm)
nwsummarize fr_perm, detail
nwcorrelate lazega_adv lazega_fr
nwcorrelate lazega_adv fr_perm

* ============================================================
* Correlating two networks
* ============================================================
set seed 12345
nwcorrelate lazega_adv lazega_fr, permutations(1000)
display "95% of the permuted correlations lie between " %6.3f r(lb) ///
    " and " %6.3f r(ub)

* ============================================================
* Correlating a network with an attribute
* ============================================================
nwmixing lazega_adv, attribute(office) permutations(1000)
nwmixing lazega_adv, attribute(status) permutations(1000)
