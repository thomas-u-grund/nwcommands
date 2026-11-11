* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 8: Centrality, brokerage, and structural holes
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
encode office, generate(officen)
encode practice, generate(practicen)
generate byte partner = (status == "partner")
label define partlab 0 "associate" 1 "partner"
label values partner partlab
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
* Gould-Fernandez brokerage roles
* ============================================================
nwbrokerage lazega_adv, generate(brk) group(officen)
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

* ============================================================
* A different question: position as strategic value
* ============================================================
nwutility lazega_adv, benefit(.5) cost(.1)
summarize _benefit _cost _util
gsort -_util _nwnode
list _nwnode _benefit _cost _util adv_in adv_out in 1/6, clean
nwutility lazega_adv, benefit(.5) cost(.6) replace
gsort -_util _nwnode
list _nwnode _benefit _cost _util adv_in adv_out in 1/6, clean
