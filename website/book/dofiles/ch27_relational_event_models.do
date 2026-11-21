* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 27: Relational event models
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.34.0,
* nwergm 1.12.0, nwsaom 1.9.1, nwrem 1.7.0, nwdynam 1.11.0, nwalaam 1.3.1,
* nwlsm 1.0.5 and nwsbm 1.0.2, the versions the book was printed with.
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
* A real event log: company emails
* ============================================================
nwwebuse manufacturing, nwclear
keep if t < 14
nwset sender receiver, eventtime(t) name(mail)
nwrem mail, nodsnd nidrec

* ============================================================
* Inertia and recency are not the same claim
* ============================================================
nwrem mail, nodsnd nidrec frpsndsnd
nwrem mail, nodsnd nidrec rsndsnd

* ============================================================
* Does working for the same supervisor matter, once inertia is controlled?
* ============================================================
nwload mail, xvars
rename _nwnode label
merge 1:1 label using "$nwwebpath/manufacturing_nodes.dta", keep(master ///
    match) nogen
nwexpand supervisor, name(samesup) network(mail)
nwsummarize samesup

nwrem mail, nodsnd nidrec covevent(samesup)

nwrem mail, nodsnd nidrec frpsndsnd covevent(samesup)
nwrem mail, nodsnd nidrec rsndsnd covevent(samesup)

estat actors, role(sender) title("") scheme(s1network)
