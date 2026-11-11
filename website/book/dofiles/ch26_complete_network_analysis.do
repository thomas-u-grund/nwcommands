* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 26: A complete network analysis
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
* Description
* ============================================================
nwwebuse lazega, nwclear
foreach v in office practice status {
    encode `v', generate(`v'n)
}
preserve
quietly nwtoedge lazega_adv, egovars(status) altervars(status)
drop if _ego == _alter
table status_ego status_alter, statistic(mean lazega_adv) nformat(%5.3f)
restore

quietly nwdegree lazega_adv, generate(adv_out adv_in)
quietly nwbetween lazega_adv, generate(bet)
quietly nwsym lazega_adv, mode(min) generate(advm)
quietly nwkcore advm, generate(kc)
tabstat adv_in adv_out bet kc, by(status) statistics(mean) format(%6.1f)
tab kc status if kc == 5

* ============================================================
* A baseline: could the core be chance?
* ============================================================
display comb(36,11)/comb(71,11)

preserve
quietly nwergm simulate 71, edges theta(0) basis(lazega_adv) ///
    constraints(degrees) directed nsim(500) generate(deg) seed(12345)
restore
frame create sims kmax size partners
forvalues s = 1/500 {
    quietly nwsym deg_`s', mode(min) generate(dm)
    quietly nwkcore dm, generate(kcs)
    quietly summarize kcs
    local k = r(max)
    quietly count if kcs == `k'
    local n = r(N)
    quietly count if kcs == `k' & status == "partner"
    frame post sims (`k') (`n') (r(N))
    nwdrop deg_`s' dm
    drop kcs
}
frame sims: generate allp = partners == size
frame sims: tab kmax allp
frame sims: summarize size if allp

* ============================================================
* QAP regression
* ============================================================
generate byte partner_i = (status == "partner")
generate byte partner_j = partner_i
set seed 12345
nwqap lazega_adv lazega_fr officen practicen partner_i partner_j, ///
    mode(same same sender receiver) permutations(1000)

* ============================================================
* An ERGM: status and niches net of reciprocity and closure
* ============================================================
nwergm lazega_adv, edges mutual nodematch(officen practicen) ///
    nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) edgecov(lazega_fr) ///
    seed(12345)
estimates store firm
quietly estat mcmcdiag
mata: min(st_matrix("r(ess)"))

* ============================================================
* Sensitivity: tie rule and two very active lawyers
* ============================================================
nwsym lazega_fr, mode(min) generate(fr_and)
quietly nwergm lazega_adv, edges mutual nodematch(officen practicen) ///
    nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) edgecov(fr_and) ///
    seed(12345)
estimates store and_fr
display "converged: " e(converged)
list _nwnode office status adv_out adv_in if adv_out >= 30, clean
nwdrop lazega_fr if adv_out >= 33
nwdrop lazega_adv if adv_out >= 33, clean
quietly nwergm lazega_adv, edges mutual nodematch(officen practicen) ///
    nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) edgecov(lazega_fr) ///
    seed(12345)
estimates store drop2
display "converged: " e(converged)
estimates table firm and_fr drop2, b(%7.3f) se(%7.3f) varwidth(22)
