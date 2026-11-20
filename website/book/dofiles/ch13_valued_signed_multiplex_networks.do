* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 13: Valued, signed, and multiplex networks
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.29.0,
* nwergm 1.11.0, nwsaom 1.9.0, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.0,
* nwlsm 1.0.0 and nwsbm 1.0.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Multiplexity: overlap between relations
* ============================================================
nwwebuse lazega, nwclear
nwsummarize lazega_fr
nwsummarize lazega_cow
nwtabulate lazega_adv lazega_fr

nwgen nrel = lazega_adv + lazega_cow + lazega_fr
nwtabulate nrel
nwcorrelate lazega_adv lazega_fr
nwcorrelate lazega_adv lazega_cow
nwcorrelate lazega_cow lazega_fr

* ============================================================
* Tie strength and the choice to dichotomize
* ============================================================
nwwebuse gang, nwclear
nwsummarize gang_valued
nwtabulate gang_valued

nwrecode gang_valued (1 2 = 1) (3/4 = 2), generate(intensity)
nwsummarize intensity
nwtabulate intensity

nwbetween gang_valued, binary generate(btw_bin)
nwbetween gang_valued, generate(btw_wgt)
correlate btw_bin btw_wgt
gsort -btw_bin
list _nwnode btw_bin btw_wgt in 1/8, clean

nwwebuse chesapeake, nwclear
nwsummarize chesapeake
summarize Biomass
quietly nwdegree chesapeake, binary generate(_outcount _incount)
summarize _outcount _incount

quietly nwdegree chesapeake, generate(_outflow _inflow)
summarize _outflow _inflow
gsort -_outflow
list _nwnode Biomass _outflow _inflow in 1/5, clean

* ============================================================
* Signed ties and structural balance
* ============================================================
nwwebuse gahuku, nwclear
nwsummarize gahuku
nwbalance gahuku

nwrecode gahuku (-1 = 0) (1 = 1), generate(gpos)
nwrecode gahuku (1 = 0) (-1 = 1), generate(gneg)
nwbalance gneg

nwdegree gpos, generate(pos) silent
nwdegree gneg, generate(neg) silent
generate net = pos - neg
gsort -net _nwnode
list _nwnode pos neg net, clean

set seed 42
nwplot gahuku, label(_nwnode) scheme(s1network) edgefactor(1.6) ///
    labelopt(mlabsize(small)) xsize(6) ysize(5)

nwwebuse senate114, nwclear
nwbalance senate114
generate byte republican = (party == "R")
nwrecode senate114 (-1 = 0) (1 = 1), generate(spos)
nwrecode senate114 (1 = 0) (-1 = 1), generate(sneg)
nwtabulate spos, attribute(republican)
nwtabulate sneg, attribute(republican)
nwbalance sneg

nwwebuse senate93, nwclear
nwbalance senate93
generate byte republican = (party == "R")
nwrecode senate93 (-1 = 0) (1 = 1), generate(spos)
nwrecode senate93 (1 = 0) (-1 = 1), generate(sneg)
nwtabulate spos, attribute(republican)
nwtabulate sneg, attribute(republican)
nwbalance sneg

nwwebuse gahuku, nwclear
nwbalance gahuku, reps(500) seed(1)
nwwebuse senate114, nwclear
nwbalance senate114, reps(500) seed(1)
nwwebuse senate93, nwclear
nwbalance senate93, reps(500) seed(1)
