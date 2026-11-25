* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Appendix: Performance and network size
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
* A worked example at a larger, real scale
* ============================================================
* setup (not printed in the book):
nwwebuse usair_full, nwclear
quietly nwdegree usair_full, generate(_od _id)
quietly nwevcent usair_full, generate(_evcent) sym
quietly nwbetween usair_full, generate(_between) sym
quietly nwcloseness usair_full, generate(_close _far _near) sym
gsort -_degree _nwnode
list _nwnode name _degree in 1/5, clean noobs abbreviate(5)
gsort -_between _nwnode
list _nwnode name _between in 1/5, clean

* ============================================================
* When closeness meets a disconnected network
* ============================================================
gsort -_close _nwnode
list _nwnode name _close in 1/5, clean

nwcloseness usair_full, generate(_close2 _far2 _near2) unconnected(max) sym
gsort -_close2 _nwnode
format _close2 %6.4f
list _nwnode name _close2 in 1/5, clean noobs abbreviate(5)
