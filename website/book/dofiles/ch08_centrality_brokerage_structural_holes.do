* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 8: Centrality, brokerage, and structural holes
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.28.0,
* nwergm 1.10.0, nwsaom 1.8.1, nwrem 1.5.1, nwdynam 1.9.1, nwalaam 1.2.0,
* nwlsm 0.6.0 and nwsbm 0.3.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Centrality is several ideas, not one
* ============================================================
nwwebuse florentine, nwclear
quietly nwdegree flomarriage, generate(_degree)
quietly nwcloseness flomarriage, unconnected(16) generate(_closeness ///
    _farness _nearness)
quietly nwbetween flomarriage, generate(_between)
quietly nwburt flomarriage
list _nwnode _degree _closeness _between _effsize _constraint, clean

* ============================================================
* Degree centrality
* ============================================================
nwwebuse lazega, nwclear
tab office partner

nwdegree lazega_adv, generate(adv_out adv_in) silent
summarize adv_out adv_in
gsort -adv_in _nwnode
list _nwnode adv_in adv_out status office yrs_frm in 1/8, clean
tabstat adv_in adv_out, by(partner) statistics(mean sd n)

* ============================================================
* Closeness centrality
* ============================================================
nwcloseness lazega_adv, generate(clo far near)
nwcloseness lazega_adv, generate(clo_d far_d near_d) nosym
correlate clo clo_d adv_in adv_out

* ============================================================
* Betweenness centrality
* ============================================================
nwbetween lazega_adv, generate(bet)
gsort -bet _nwnode
list _nwnode bet adv_in adv_out status office in 1/8, clean
tabstat bet, by(partner) statistics(mean sd n)
regress bet i.partner yrs_frm

* ============================================================
* Eigenvector centrality
* ============================================================
nwevcent lazega_adv, generate(evc)
nwkatz lazega_adv, alpha(.2) generate(katz)

* ============================================================
* No universally best measure
* ============================================================
egen r_in = rank(-adv_in)
egen r_clo = rank(-clo)
egen r_bet = rank(-bet)
egen r_evc = rank(-evc)
spearman adv_in clo bet evc, stats(rho)
gsort r_bet _nwnode
list _nwnode r_in r_clo r_bet r_evc in 1/8, clean

* ============================================================
* Structural holes: Burt's constraint
* ============================================================
nwburt lazega_adv
tabstat _effsize _constraint, by(partner) statistics(mean sd n)
gsort _constraint _nwnode
list _nwnode _effsize _constraint adv_in adv_out status in 1/6, clean
correlate _constraint adv_in adv_out

* ============================================================
* Ties that bridge and ties that are embedded
* ============================================================
nwsym lazega_adv, mode(min) generate(advm)
nwbridges advm, name(advbridges)
nwbridges advm, type(local) name(advlocal)
nwsimmelian advm, name(simm)
nwsummarize simm

* ============================================================
* Gould-Fernandez brokerage roles
* ============================================================
nwbrokerage lazega_adv, generate(brk) group(officenum)
rename (brk_coordinator brk_gatekeeper brk_representative brk_consultant ///
    brk_liaison) (coord gatek repr consult liais)
gsort -liais _nwnode
list _nwnode office coord gatek repr consult liais in 1/6, clean

nwbrokerage lazega_adv, generate(brs) group(partner)
egen brs_total = rowtotal(brs_coordinator brs_gatekeeper ///
    brs_representative brs_consultant)
generate share_gate = brs_gatekeeper / brs_total
generate share_rep = brs_representative / brs_total
tabstat brs_total share_gate share_rep, by(partner) statistics(mean)
