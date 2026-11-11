* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 24: Relational event models
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
* Events as a marked point process
* ============================================================
clear
input sender receiver t
1 2 1
1 3 2
2 1 3
1 2 4
3 2 5
2 3 6
1 3 7
3 1 8
2 1 9
1 3 10
end
nwset sender receiver, eventtime(t) name(chat)

nwrem chat, nodsnd nidrec

* ============================================================
* A real event log: dormitory phone calls
* ============================================================
nwwebuse socialevolution, nwclear
nwset sender receiver, eventtime(t) name(calls)
nwrem calls, nodsnd nidrec

* ============================================================
* Inertia and recency are not the same claim
* ============================================================
nwrem calls, nodsnd nidrec frpsndsnd
nwrem calls, nodsnd nidrec rsndsnd

* ============================================================
* Does living on the same floor matter, once inertia is controlled?
* ============================================================
nwload calls, xvars
rename _nwnode label
merge 1:1 label using "$nwwebpath/socialevolution_nodes.dta", keep(master ///
    match) nogen
nwexpand floor, name(samefloor)
nwsummarize samefloor

nwrem calls, nodsnd nidrec covevent(samefloor)

nwrem calls, nodsnd nidrec frpsndsnd covevent(samefloor)
