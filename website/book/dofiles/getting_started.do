* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Getting started
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.26.0,
* nwergm 1.7.1, nwsaom 1.7.1, nwrem 1.3.0 and nwdynam 1.5.1, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Installing the software
* ============================================================
* (installation; run once by hand, see Getting started) net install nwcommands, from(https://nwcommands.org/net/) replace
* (installation; run once by hand, see Getting started) nwinstall, everything

* ============================================================
* A first network
* ============================================================
nwwebuse florentine, nwclear
nwplot flomarriage

* ============================================================
* Reading the examples
* ============================================================
nwwebuse glasgow, nwclear
