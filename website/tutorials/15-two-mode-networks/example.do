* Tutorial 9: Two-mode networks
* The two data sets are loaded from the data folder of the repository here;
* once the release is installed, nwwebuse davis and nwwebuse ftdirectors_se do the same.

* Southern women: 18 women, 14 social events
nwuse ../../../data/davis, nwclear
nwsummarize davis

* Degree in a two-mode network: nwdegree recognises the network and divides the number of ties by the size of the other mode
nwdegree davis, generate(att)
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
nwdegree small, generate(attsmall)

* Communities of the two-mode network itself: the bipartite modularity of Barber (the default) and Newman's modularity
nwcommunity davis, generate(comm_bip) seed(1)
nwcommunity davis, generate(comm_one) onemode seed(1)
nwmodularity davis, group(comm_bip)
nwmodularity davis, group(comm_bip) onemode

* How nested is the network? NODF and the C-score
nw2nested davis

* Clustering: nwclustering recognises the network too; Opsahl (default) and Robins-Alexander
nwclustering davis, generate(clo)
display r(C_global)
nwclustering davis, ra

* Motifs: the bipartite motifs of Simmons et al. and the positions of the nodes in them
nwmotifs davis, generate(np)
list _nwnode np1 np2 np3 np4 np5 np6 in 1/3, noobs

* Closeness and betweenness are normalised for the two modes (Borgatti and Everett); onemode gives the numbers of the bipartite graph read as a one-mode graph
nwcloseness davis, generate(cl_ cf_ cn_) silent
nwcloseness davis, generate(clo1 cfo1 cno1) onemode silent
summarize cl_ clo1
nwbetween davis, generate(bw) silent
nwbetween davis, generate(bw1) onemode silent
summarize bw bw1

* A null model that keeps both degree sequences
set seed 1
nwpermute davis, generate(davis_swap) swap
nwdegree davis_swap, generate(att_swap) raw silent
nwdegree davis, generate(att_raw) raw silent
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
nwdegree ftdirectors_se, generate(deg)
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
