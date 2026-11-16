* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 9: Cohesion, subgroups, and communities
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.26.0,
* nwergm 1.7.1, nwsaom 1.7.1, nwrem 1.3.0 and nwdynam 1.5.1, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* The reciprocated advice network
* ============================================================
nwwebuse lazega, nwclear
nwsym lazega_adv, mode(min) generate(advm)
nwsummarize advm

nwcomponents advm, generate(comp)
list _nwnode office status if comp > 1, clean noobs

* ============================================================
* Local density: cliques and their relaxations
* ============================================================
nwclique advm, generate(cl)

nwkplex advm, k(2)

nwnclique advm, n(2) generate(ncl)

nwkcore advm, generate(kc)
tab kc partner

* ============================================================
* Robustness: how hard is a group to pull apart?
* ============================================================
nwkcomponents advm, generate(kcomp2)
nwkcomponents advm, k(3) generate(kcomp3)
nwkcomponents advm, k(4) generate(kcomp4)
nwkcomponents advm, k(5) generate(kcomp5)

nwcohesion advm, generate(coh)
tab coh office
count if coh != kc

* ============================================================
* Algorithmic community detection
* ============================================================
nwcommunity lazega_adv, algorithm(louvain) seed(12345) symmetrize ///
    generate(adv_com)
tab adv_com office
tab adv_com practice
tab adv_com status

egen op = group(officenum practicenum)
nwmodularity lazega_adv, group(officenum) symmetrize
nwmodularity lazega_adv, group(practicenum) symmetrize
nwmodularity lazega_adv, group(partner) symmetrize
nwmodularity lazega_adv, group(op) symmetrize
nwmodularity lazega_adv, group(adv_com) symmetrize

nwcommunity lazega_fr, algorithm(louvain) seed(12345) symmetrize ///
    generate(fr_com)
tab fr_com office
tab fr_com practice
nwmodularity lazega_fr, group(officenum) symmetrize
nwmodularity lazega_fr, group(practicenum) symmetrize
nwmodularity lazega_fr, group(partner) symmetrize

nwcommunity advm, algorithm(louvain) generate(mut_com)

nwwebuse gang, nwclear
nwcommunity gang, algorithm(louvain) seed(12345) generate(_community)

nwwebuse macaque, nwclear
nwcommunity macaque, algorithm(louvain) seed(12345) symmetrize ///
    generate(_community)
nwplot macaque, color(_community)
