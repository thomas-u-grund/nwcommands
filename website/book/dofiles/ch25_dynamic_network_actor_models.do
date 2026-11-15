* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 25: The Dynamic Network Actor Model
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom; it was checked against nwcommands 3.25.1
* and nwdynam 1.4.0.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

nwwebuse manufacturing, nwclear
keep if t < 14
nwset sender receiver, eventtime(t) directed name(mail)
nwdynam mail
nwdynam mail, submodel(rate)
nwload mail, xvars
rename _nwnode label
merge 1:1 label using "$nwwebpath/manufacturing_nodes.dta", keep(master match) nogen
rename label _nwnode
encode division, generate(branch)
tabulate branch
nwdynam mail, inertia recip indeg same(branch)
nwdynam mail, submodel(rate) intercept indeg
