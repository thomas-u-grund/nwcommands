* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 7: Paths, distance, and reachability
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.31.0,
* nwergm 1.11.1, nwsaom 1.9.1, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.0,
* nwlsm 1.0.2 and nwsbm 1.0.1, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Worked example: a chain of advice
* ============================================================
nwwebuse lazega, nwclear
nwpath lazega_adv, ego(n40) alter(n3)

nwneighbor lazega_adv, ego(n40)

* ============================================================
* Who can reach whom
* ============================================================
nwreach lazega_adv
nwsummarize _reach

* ============================================================
* Distances across the firm
* ============================================================
nwgeodesic lazega_adv

preserve
quietly nwtoedge _geodesic, egovars(status) altervars(status)
drop if _ego == _alter
tabulate status_ego status_alter, summarize(_geodesic) means
tabulate _geodesic if status_ego == "associate" & status_alter == "partner"

list _ego _alter _geodesic if inlist(_ego, "n59", "n23") & inlist(_alter, ///
    "n59", "n23"), clean noobs abbreviate(9)
restore

* ============================================================
* Short distances and the small-world idea
* ============================================================
set seed 12345
nwrandom 71, prob(.1795)
nwsummarize random
nwgeodesic random
quietly nwtriads random
display "random network: transitivity = " %5.3f r(transitivity)

* ============================================================
* Disconnected networks
* ============================================================
nwwebuse florentine, nwclear
nwgeodesic flomarriage

nwgeodesic flomarriage, unconnected(16)

nwwebuse glasgow, nwclear
nwreach glasgow1
nwsummarize _reach
