* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 27: A complete network analysis
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.26.0,
* nwergm 1.8.0, nwsaom 1.8.0, nwrem 1.5.0 and nwdynam 1.9.0, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Description
* ============================================================
nwwebuse lazega, nwclear
preserve
quietly nwtoedge lazega_adv, egovars(status) altervars(status)
drop if _ego == _alter
table status_ego status_alter, statistic(mean lazega_adv) nformat(%5.3f)
restore

quietly nwdegree lazega_adv, generate(adv_out adv_in)
tabstat adv_in adv_out seniority, by(status) statistics(mean min max) ///
    format(%5.1f)

* ============================================================
* QAP regression
* ============================================================
generate byte partner_i = partner
generate byte partner_j = partner_i
set seed 12345
nwqap lazega_adv lazega_fr office practice partner_i partner_j, mode(same ///
    same sender receiver) permutations(1000)

* ============================================================
* An ERGM: status net of niches, reciprocity and closure
* ============================================================
nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodeofactor(status) nodeifactor(status) gwesp(.5) edgecov(lazega_fr) ///
    seed(12345)
estimates store firm
quietly estat mcmcdiag
mata: min(st_matrix("r(ess)"))

estat gof, gof(espartners) seed(12345)

* ============================================================
* Whose choices carry the status effect?
* ============================================================
quietly nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodemix(status) gwesp(.5) edgecov(lazega_fr) seed(12345)
estimates store mix
quietly estat mcmcdiag
mata: min(st_matrix("r(ess)"))
estimates table firm mix, b(%7.3f) se(%7.3f) stats(converged) varwidth(22)
lincom nodemix_status_2_2 - nodemix_status_2_1

* ============================================================
* Partnership or seniority?
* ============================================================
quietly nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodeofactor(status) nodeifactor(status) nodeocov(seniority) ///
    nodeicov(seniority) gwesp(.5) edgecov(lazega_fr) seed(12345)
estimates store senior
quietly estat mcmcdiag
mata: min(st_matrix("r(ess)"))
estimates table firm senior, b(%7.3f) se(%7.3f) stats(converged) varwidth(22)

* ============================================================
* Sensitivity: two very active lawyers
* ============================================================
list _nwnode office status seniority adv_out adv_in if adv_out >= 30, clean
nwdrop lazega_fr if adv_out >= 33
nwdrop lazega_adv if adv_out >= 33, clean
quietly nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodemix(status) gwesp(.5) edgecov(lazega_fr) seed(12345)
estimates store mix_d2
quietly nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodeofactor(status) nodeifactor(status) nodeocov(seniority) ///
    nodeicov(seniority) gwesp(.5) edgecov(lazega_fr) seed(12345)
estimates store sen_d2
estimates table mix mix_d2 senior sen_d2, keep(nodemix_status_2_1 ///
    nodemix_status_1_2 nodemix_status_2_2 nodeofactor_status_2 ///
    nodeifactor_status_2 nodeocov_seniority nodeicov_seniority) b(%7.3f) ///
    se(%7.3f) stats(converged) varwidth(22)
