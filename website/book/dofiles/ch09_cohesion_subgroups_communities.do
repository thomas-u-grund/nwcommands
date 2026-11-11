* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 9: Cohesion, subgroups, and communities
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
* The reciprocated advice network
* ============================================================
nwwebuse lazega, nwclear
encode office, generate(officen)
encode practice, generate(practicen)
generate byte partner = (status == "partner")
nwsym lazega_adv, mode(min) generate(advm)
nwsummarize advm

* ============================================================
* Components
* ============================================================
nwcomponents advm, generate(comp)
list _nwnode office status if comp > 1, clean noobs
nwbridges advm, name(advbridges)
nwbridges advm, type(local) name(advlocal)

* ============================================================
* Cliques, k-cores, k-components, and k-plexes
* ============================================================
nwclique advm, generate(cl)
nwkcore advm, generate(kc)
tab kc partner

nwkcomponents advm, generate(kcomp2)
nwkcomponents advm, k(3) generate(kcomp3)
nwkcomponents advm, k(4) generate(kcomp4)
nwkcomponents advm, k(5) generate(kcomp5)

nwkplex advm, k(2)
nwnclique advm, n(2) generate(ncl)

* ============================================================
* The full cohesion hierarchy
* ============================================================
nwcohesion advm, generate(coh)
tab coh office

* ============================================================
* Simmelian ties
* ============================================================
nwsimmelian advm, name(simm)
nwsummarize simm

* ============================================================
* Algorithmic community detection
* ============================================================
nwcommunity lazega_adv, algorithm(louvain) seed(12345) symmetrize ///
    generate(adv_com)
tab adv_com office
tab adv_com practice
tab adv_com status

egen op = group(officen practicen)
tab op
nwmodularity lazega_adv, group(officen) symmetrize
nwmodularity lazega_adv, group(practicen) symmetrize
nwmodularity lazega_adv, group(partner) symmetrize
nwmodularity lazega_adv, group(op) symmetrize
nwmodularity lazega_adv, group(adv_com) symmetrize

nwcommunity lazega_fr, algorithm(louvain) seed(12345) symmetrize ///
    generate(fr_com)
tab fr_com office
tab fr_com practice
nwmodularity lazega_fr, group(officen) symmetrize
nwmodularity lazega_fr, group(practicen) symmetrize
nwmodularity lazega_fr, group(partner) symmetrize

nwcommunity advm, algorithm(louvain) generate(mut_com)

nwwebuse gang, nwclear
nwcommunity gang, algorithm(louvain) seed(12345) generate(_community)

nwwebuse macaque, nwclear
nwcommunity macaque, algorithm(louvain) seed(12345) symmetrize ///
    generate(_community)
nwplot macaque, color(_community)
