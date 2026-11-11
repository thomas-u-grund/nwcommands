* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Appendix: Performance and network size
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
* A worked example at a larger, real scale
* ============================================================
* setup (not printed in the book):
nwwebuse usair_full, nwclear
quietly nwdegree usair_full, generate(_od _id)
quietly nwevcent usair_full, generate(_evcent)
quietly nwbetween usair_full, generate(_between)
quietly nwcloseness usair_full, generate(_close _far _near)
gsort -_degree _nwnode
list _nwnode name _degree in 1/5, clean noobs abbreviate(5)
gsort -_evcent _nwnode
list _nwnode name _evcent in 1/5, clean
gsort -_between _nwnode
list _nwnode name _between in 1/5, clean

* ============================================================
* When closeness meets a disconnected network
* ============================================================
gsort -_close _nwnode
list _nwnode name _close in 1/5, clean

nwcomponents usair_full, generate(_comp)

nwcloseness usair_full, generate(_close2 _far2 _near2) unconnected(max)
gsort -_close2 _nwnode
format _close2 %6.4f
list _nwnode name _close2 in 1/5, clean noobs abbreviate(5)
