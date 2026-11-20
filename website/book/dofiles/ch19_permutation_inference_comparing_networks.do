* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 19: Permutation inference and comparing networks
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.29.0,
* nwergm 1.11.0, nwsaom 1.9.0, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.0,
* nwlsm 1.0.0 and nwsbm 1.0.0, the versions the book was printed with.
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

* ============================================================
* Correlating a network with an attribute
* ============================================================
nwmixing lazega_adv, attribute(office) permutations(1000)
nwmixing lazega_adv, attribute(status) permutations(1000)
