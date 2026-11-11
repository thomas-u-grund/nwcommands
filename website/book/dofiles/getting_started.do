* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Getting started
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
* Installing the software
* ============================================================
* (installation; run once by hand, see Getting started) net install nwcommands, from(https://nwcommands.org/net/) replace
* (installation; run once by hand, see Getting started) nwinstall, everything

* ============================================================
* Reading the examples
* ============================================================
nwwebuse glasgow, nwclear
