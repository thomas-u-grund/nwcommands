* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 7: Paths, distance, and reachability
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
* Worked example: a chain of advice
* ============================================================
nwwebuse lazega, nwclear
nwpath lazega_adv, ego(n40) alter(n3)

nwneighbor lazega_adv, ego(n40)

* ============================================================
* Distances across the firm
* ============================================================
nwgeodesic lazega_adv, unconnected(71)

preserve
quietly nwtoedge _geodesic, egovars(status) altervars(status)
drop if _ego == _alter
tabulate status_ego status_alter, summarize(_geodesic) means
tabulate _geodesic if status_ego == "associate" & status_alter == "partner"
list _ego _alter if _geodesic == 4 & status_ego == "associate" & ///
    status_alter == "partner", clean noobs
restore

quietly nwpath lazega_adv, ego(n59) alter(n23)
display "n59 to n23: length " r(path_length) ", shortest paths: " r(paths)
quietly nwpath lazega_adv, ego(n23) alter(n59)
display "n23 to n59: length " r(path_length) ", shortest paths: " r(paths)

* ============================================================
* Short distances and the small-world idea
* ============================================================
set seed 12345
nwrandom 71, prob(.1795) name(rnd)
nwsummarize rnd
nwgeodesic rnd, unconnected(71) name(rnd_geo)
quietly nwtriads rnd
display "random network: transitivity = " %5.3f r(transitivity)

* ============================================================
* Disconnected networks and reachability
* ============================================================
nwwebuse florentine, nwclear
nwgeodesic flomarriage, unconnected(16)

nwwebuse glasgow, nwclear
nwgeodesic glasgow1, unconnected(50)

nwreach glasgow1
nwsummarize _reach
