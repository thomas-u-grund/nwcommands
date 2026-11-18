* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 10: Positions, roles, and structural equivalence
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.27.0,
* nwergm 1.8.0, nwsaom 1.8.0, nwrem 1.5.0, nwdynam 1.9.0 and nwalaam 1.0.0, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* A small example: who could replace whom?
* ============================================================
nwclear
clear
input str8 ego str8 alter
"Anna" "Gwen"
"Sophie" "Gwen"
"Fion" "Leh"
"Magalie" "Leh"
"Gwen" "Antonia"
"Leh" "Antonia"
end
nwset ego alter, edgelist directed name(firm)

nwsimindex firm, measure(jaccard) name(simfirm)
nwsummarize simfirm, matonly

nwregular firm, generate(regular)
list _nwnode regular, noobs sep(0)
matrix list r(image)

* ============================================================
* Similar tie profiles among the lawyers
* ============================================================
nwwebuse lazega, nwclear
nwsimindex lazega_adv, measure(jaccard) name(simj)
preserve
quietly nwtoedge simj, egovars(partner practicenum) altervars(partner ///
    practicenum)
keep if _ego > _alter
generate byte same_status = (partner_ego == partner_alter)
generate byte same_practice = (practicenum_ego == practicenum_alter)
summarize simj
tabstat simj, by(same_status) statistics(mean sd n)
tabstat simj, by(same_practice) statistics(mean sd n)
gsort -simj _ego _alter
list _ego _alter simj partner_ego partner_alter in 1/5, clean noobs
restore

* ============================================================
* Blockmodeling with CONCOR
* ============================================================
nwconcor lazega_adv, splits(2) generate(block)
tab block practice
tab block status

* ============================================================
* From blocks to a blockmodel image
* ============================================================
quietly nwcollapse (mean) lazega_adv, by(block) generate(blockimg)
preserve
quietly nwtoedge lazega_adv, egovars(block) altervars(block)
drop if _ego == _alter
table block_ego block_alter, statistic(mean lazega_adv) nformat(%5.3f)
restore

* ============================================================
* Hierarchical clustering of positions
* ============================================================
nwhierarchy lazega_adv, groups(4) generate(role_single)
tab role_single
nwhierarchy lazega_adv, groups(4) linkage(wardslinkage) generate(role)
tab role status
tab role practice
tab role office

nwwebuse florentine, nwclear
nwhierarchy flomarriage, linkage(wardslinkage)
nwdendrogram _clus_1, lab scheme(s1network)
quietly nwwebuse lazega, nwclear

* ============================================================
* Regular equivalence: the same kind of contacts
* ============================================================
nwregular lazega_adv, generate(regadv)
nwregular lazega_fr, generate(regfr) silent
display r(classes)

* ============================================================
* Core-periphery structure
* ============================================================
nwcoreperiphery lazega_adv, generate(core)
tab core status
quietly nwdegree lazega_adv, generate(adv_out adv_in)
tabstat adv_in adv_out seniority yrs_frm, by(core) statistics(mean n)
