* Tutorial 9: Two-mode networks
* The two data sets are loaded from the data folder of the repository here;
* once the release is installed, nwwebuse davis and nwwebuse ftdirectors_se do the same.

* Southern women: 18 women, 14 social events
nwuse ../../../data/davis, nwclear
nwsummarize davis

* Degree in a two-mode network: the number of ties divided by the size of the other mode
nw2degree davis, generate(att)
generate attended = round(att * 14) if _nwmode == "1"
generate guests = round(att * 18) if _nwmode == "2"
list _nwnode surname title attended if _nwmode == "1", noobs
gsort -guests
list _nwnode eventdate guests in 1/3, noobs
sort _nwmode _nwnode

* Project onto the women: the tie value is the number of events two women attended together
nw2project davis, project(1) name(women)
nwsummarize women
nwcommunity women, generate(group)

* Plot the two modes in two columns
nwplot davis, layout(bipartite, vertical) color(_nwmode) label(_nwnode) scheme(s1network) export("plot_davis.svg") replace

* Part of the network: the flag, the two modes and the level labels are kept
nwkeepnodes davis, nodes(Brenda Charlotte Dorothy Eleanor E1 E2 E3 E4 E5) generate(small)
nwsummarize small
nw2degree small, generate(attsmall)

* Communities of the two-mode network itself: the bipartite modularity of Barber (the default) and Newman's modularity
nwcommunity davis, generate(comm_bip) seed(1)
nwcommunity davis, generate(comm_one) onemode seed(1)
nwmodularity davis, group(comm_bip)
nwmodularity davis, group(comm_bip) onemode

* How nested is the network? NODF and the C-score
nw2nested davis

* Clustering: Opsahl (default) and Robins-Alexander
nw2clustering davis, generate(clo)
display r(C_global)
nw2clustering davis, ra

* A null model that keeps both degree sequences
set seed 1
nwpermute davis, generate(davis_swap) swap
nw2degree davis_swap, generate(att_swap) raw silent
nw2degree davis, generate(att_raw) raw silent
assert att_swap == att_raw

* Export and import keep the two modes
nwexport davis, type(pajek) fname(davis_pajek) replace
nwimport davis_pajek.net, type(pajek) name(davis_back) nwappend
nwsummarize davis_back
erase davis_pajek.net

* Commands that cannot say anything about a two-mode network stop
capture noisily nwspectral davis, generate(sp)
display _rc

* Company directors in Sweden: 5,092 directors, 455 companies
nwuse ../../../data/ftdirectors_se, nwclear
nwsummarize ftdirectors_se
nw2degree ftdirectors_se, generate(deg)
generate boards = round(deg * 455) if _nwmode == "1"
tabulate boards
tabulate gender if _nwmode == "1", missing
tabstat boards if _nwmode == "1", by(gender) statistics(mean count)
nw2project ftdirectors_se, project(2) name(companies)
nwsummarize companies
* Components of the projection: how many groups of interlocked companies?
quietly nwcomponents companies, generate(comp)
display r(components)
egen size = count(comp), by(comp)
summarize size, meanonly
display r(max)
