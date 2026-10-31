* nwcommands tutorial 11: brokerage and structural holes
* Requires the core nwcommands.
nwwebuse florentine, nwclear
nwsummarize flomarriage
describe, short
list in 1/4

* 1. Burt's structural holes: constraint
nwburt flomarriage
nwconstraint flomarriage, name(floconstraint)
nwsummarize floconstraint
nwdegree flomarriage, generate(deg)
nwclustering flomarriage, generate(clu) silent
nwbetween flomarriage, generate(btw) silent
sort _nwnode
list _nwnode deg btw clu _effsize _constraint if deg>=3, noobs

* 2. Bridges
nwbridges flomarriage, name(flobridges)
nwsummarize flobridges

* 3. Gould-Fernandez brokerage roles
nwwebuse sampson, nwclear
nwsymmetrize samplike, generate(likes)
encode faction, generate(fnum)
nwbrokerage samplike, group(fnum) generate(brk)
gsort -brk_gatekeeper
list _nwnode faction brk_gatekeeper brk_representative brk_liaison in 1/5, noobs

* 4. Hierarchy and Simmelian ties
nwsimmelian likes, name(strong)
nwsummarize strong
nwsimmelian samplike, name(strongdir)
nwsummarize strongdir
