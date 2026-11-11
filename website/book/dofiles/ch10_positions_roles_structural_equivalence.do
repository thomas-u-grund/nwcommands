* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 10: Positions, roles, and structural equivalence
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
* Dissimilarity and similarity of tie profiles
* ============================================================
nwwebuse lazega, nwclear
encode practice, generate(practicen)
generate byte partner = (status == "partner")
nwdissimilar lazega_adv, type(euclidean) name(dis)
preserve
quietly nwtoedge dis
keep if _ego > _alter
summarize dis
restore

* ============================================================
* Comparing similarity measures
* ============================================================
nwsimindex lazega_adv, measure(jaccard) name(simj)
nwsimindex lazega_adv, measure(adamicadar) name(simaa)
preserve
quietly nwtoedge simj, egovars(partner practicen) altervars(partner practicen)
keep if _ego > _alter
generate byte same_status = (partner_ego == partner_alter)
generate byte same_practice = (practicen_ego == practicen_alter)
summarize simj
tabstat simj, by(same_status) statistics(mean sd n)
tabstat simj, by(same_practice) statistics(mean sd n)
gsort -simj _ego _alter
list _ego _alter simj partner_ego partner_alter in 1/5, clean noobs
restore
preserve
quietly nwtoedge simaa
keep if _ego > _alter
gsort -simaa _ego _alter
list _ego _alter simaa in 1/5, clean noobs
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

* ============================================================
* Core-periphery structure
* ============================================================
nwcoreperiphery lazega_adv, generate(core)
tab core status
quietly nwdegree lazega_adv, generate(adv_out adv_in)
tabstat adv_in adv_out seniority yrs_frm, by(core) statistics(mean n)
