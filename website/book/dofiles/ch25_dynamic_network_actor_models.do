* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 25: The Dynamic Network Actor Model
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
* Real data: who calls, and whom they call
* ============================================================
nwwebuse socialevolution, nwclear
nwset sender receiver, eventtime(t) directed name(calls)
nwdynam calls

nwdynam calls, submodel(rate)

* ============================================================
* Same floor, once more, net of structure
* ============================================================
nwload calls, xvars
rename _nwnode label
merge 1:1 label using "$nwwebpath/socialevolution_nodes.dta", keep(master ///
    match) nogen
rename label _nwnode
tabulate floor
nwdynam calls, inertia recip indeg same(floor)

* ============================================================
* When real time, not just order, matters
* ============================================================
nwdynam calls, submodel(rate) intercept indeg
