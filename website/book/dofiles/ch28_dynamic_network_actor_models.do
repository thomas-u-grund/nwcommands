* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 28: The Dynamic Network Actor Model
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.37.1,
* nwergm 1.16.1, nwsaom 1.9.2, nwrem 1.7.2, nwdynam 1.11.1, nwalaam 1.4.0,
* nwlsm 1.0.6 and nwsbm 1.1.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it; lines marked "run" are fits that the text summarizes.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Real data: who writes, and to whom
* ============================================================
nwwebuse manufacturing, nwclear
keep if t < 14
nwset sender receiver, eventtime(t) directed name(mail)
nwdynam mail

estat choiceplot, title("") scheme(s1network)

nwdynam mail, submodel(rate)

estat rateplot, title("") scheme(s1network)

* ============================================================
* Same branch, once more, net of structure
* ============================================================
nwload mail, xvars
rename _nwnode label
merge 1:1 label using "$nwwebpath/manufacturing_nodes.dta", keep(master ///
    match) nogen
rename label _nwnode
encode division, generate(branch)
tabulate branch
nwdynam mail, inertia recip indeg same(branch)

* ============================================================
* When real time, not just order, matters
* ============================================================
nwdynam mail, submodel(rate) intercept indeg outdeg
