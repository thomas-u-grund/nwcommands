* nwcommands tutorial 12: cohesion and subgroups
* Requires the core nwcommands.

* 1. Components: who can reach whom?
nwwebuse mesa, nwclear
nwsummarize mesa
nwcomponents mesa, generate(compid) silent
display r(components)
bysort compid: generate csize = _N
tabulate csize
nwcomponents mesa, generate(lgc) lgc silent
tabulate lgc

* 2. A small network with a known group structure: Sampson's monks
nwwebuse sampson, nwclear
list in 1/6
nwsymmetrize samplike, generate(likes)
nwsummarize likes

* 3. Dense cores: k-cores, cliques and k-plexes
nwkcore likes, generate(kcore)
nwclique likes, generate(clique) minsize(4)
nwkplex likes, k(2) generate(plex) minsize(5)

* 4. Communities
nwcommunity likes, generate(comm)
tabulate comm faction
encode faction, generate(fnum)
nwmodularity likes, group(fnum)
nwmodularity likes, group(comm)
nwcommunity likes, generate(comm2) resolution(2)
tabulate comm2 faction

* 5. A fixed number of groups, and core and periphery
nwfactions likes, groups(3) generate(fgroup)
tabulate fgroup faction
nwcoreperiphery likes, generate(cp)
tabulate cp faction

* 6. Plot
nwplot likes, color(faction) label(_nwnode) scheme(s1network) export("plot_sampson_faction.svg") replace
nwplot likes, color(comm) label(_nwnode) scheme(s1network) export("plot_sampson_comm.svg") replace
