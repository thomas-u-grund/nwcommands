* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 2: What is a network?
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
* Worked example: a four-person network
* ============================================================
nwclear
clear
input str8 ego str8 alter
"Anna" "Sophie"
"Sophie" "Gwen"
"Gwen" "Anna"
"Gwen" "Leh"
end
nwset ego alter, edgelist directed name(mini)
nwsummarize mini
nwdegree mini, generate(_outdegree _indegree)

nwplot mini, label(_nwnode)

* ============================================================
* Worked example: eight lawyers
* ============================================================
nwwebuse lazega, nwclear
nwset
list _nwnode seniority status office practice if mod(seniority, 9) == 1, ///
    clean noobs
nwsubset lazega_adv if mod(seniority, 9) == 1, name(adv8)

nwsummarize adv8
set seed 42
nwplot adv8, label(_nwnode)

quietly nwtoedge adv8, ego(sender) alter(receiver)
list sender receiver if adv8 == 1, clean noobs

nwsummarize adv8, matonly

* ============================================================
* All 71 lawyers
* ============================================================
nwwebuse lazega, nwclear
nwsummarize lazega_adv
display 892 / (71 * 70)
quietly nwdegree lazega_adv, generate(adv_out adv_in)
summarize adv_out adv_in
nwsym lazega_adv, generate(adv_und)
nwsummarize adv_und
