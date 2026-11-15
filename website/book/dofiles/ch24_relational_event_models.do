* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 24: Relational event models
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
nwwebuse manufacturing, nwclear
keep if t < 14
nwset sender receiver, eventtime(t) name(mail)
nwrem mail, nodsnd nidrec
nwrem mail, nodsnd nidrec frpsndsnd
nwrem mail, nodsnd nidrec rsndsnd
nwload mail, xvars
rename _nwnode label
merge 1:1 label using "$nwwebpath/manufacturing_nodes.dta", keep(master match) nogen
nwexpand supervisor, name(samesup)
nwsummarize samesup
nwrem mail, nodsnd nidrec covevent(samesup)
nwrem mail, nodsnd nidrec frpsndsnd covevent(samesup)
nwrem mail, nodsnd nidrec rsndsnd covevent(samesup)
