* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 12: Two-mode networks
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
* First example: the Southern women
* ============================================================
nwwebuse davis, nwclear
nwsummarize davis
list _nwnode surname title if _nwmode == "1", noobs
list _nwnode eventdate if inlist(_nwnode, "E1", "E8", "E14"), noobs

preserve
nw2toedge davis, compress
generate woman = cond(_nwmode_ego == "1", _ego, _alter)
generate event = cond(_nwmode_ego == "1", _alter, _ego)
generate e = real(substr(event, 2, .))
bysort woman (e): generate str40 events = string(e)
by woman: replace events = events[_n-1] + " " + string(e) if _n > 1
by woman: keep if _n == _N
generate n = wordcount(events)
list woman n events, noobs
restore

* ============================================================
* Seeing both modes at once
* ============================================================
set seed 42
nwplot davis, color(_nwmode, legendoff) symbol(_nwmode, legendoff) ///
    label(_nwnode) layout(bipartite, vertical) scheme(s1network) ///
    labelopt(mlabsize(vsmall) mlabposition(3)) xsize(5) ysize(6)

* ============================================================
* Two-mode degree and clustering
* ============================================================
nwdegree davis, generate(dg)
generate k = round(dg * cond(_nwmode == "1", 14, 18))
preserve
keep if _nwmode == "1"
gsort -k _nwnode
list _nwnode k dg, noobs
restore
preserve
keep if _nwmode == "2"
gsort -k _nwnode
list _nwnode k dg eventdate, noobs
restore

nwclustering davis, generate(cc_w) level(1)
nwclustering davis, generate(cc_e) level(2)
summarize cc_w cc_e

* ============================================================
* Projection
* ============================================================
nw2project davis, project(1) name(women) stat(count)
nwsummarize women
nw2project davis, project(2) name(events) stat(count)
nwsummarize events

nw2project davis, project(1) name(wbin) stat(binary)
nw2project davis, project(1) name(wjac) stat(jaccard)
preserve
quietly nwtoedge women wbin wjac, compress
drop if missing(women)
gsort -women -wjac _ego _alter
list _ego _alter women wbin wjac in 1/6, noobs
tabulate women
restore

* ============================================================
* Communities and the two projections
* ============================================================
nwcommunity women, generate(com_w)
nwcommunity events, generate(com_e)

generate byte in1 = (com_w == 1)
generate byte in2 = (com_w == 2)
nwaltergen from1 = sum(alter.in1), net(davis)
nwaltergen from2 = sum(alter.in2), net(davis)
preserve
keep if _nwmode == "2"
generate e = real(substr(_nwnode, 2, .))
sort e
list _nwnode com_e from1 from2, noobs sep(5)
restore

nwcommunity davis, seed(12345) generate(cb)
nwcommunity davis, onemode generate(cn)

* ============================================================
* Second example: boards of directors in Sweden
* ============================================================
nwwebuse ftdirectors_se, nwclear
nwsummarize ftdirectors_se

nwdegree ftdirectors_se, generate(dgn)
generate k = round(dgn * cond(_nwmode == "1", 455, 5092))
tabulate k if _nwmode == "1"
tabstat k, by(_nwmode) statistics(n mean sd min p50 max)

* ============================================================
* Projecting the boards
* ============================================================
nw2project ftdirectors_se, project(2) name(firms) stat(count)
preserve
quietly nwtoedge firms, compress
drop if missing(firms)
tabulate firms
restore
nw2project ftdirectors_se, project(1) name(dirs) stat(binary)

preserve
keep if _nwmode == "2"
generate pairs = k * (k - 1) / 2
quietly summarize pairs
display "pairs summed over boards: " r(sum) ", largest board: " r(max)
restore

* ============================================================
* What the two-mode data say directly
* ============================================================
generate byte multi = (k > 1) if _nwmode == "1"
tabulate gender multi if _nwmode == "1" & gender != "", row nofreq
