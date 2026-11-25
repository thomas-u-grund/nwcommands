* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 12: Two-mode networks
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.37.1,
* nwergm 1.16.1, nwsaom 1.9.2, nwrem 1.7.2, nwdynam 1.11.1, nwalaam 1.4.0,
* nwlsm 1.0.6 and nwsbm 1.1.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it; lines marked "run" are fits that the text summarizes.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* The Southern women
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
generate byte lpos = cond(_nwmode == "1", 9, 3)
set seed 42
nwplot davis, color(_nwmode, legendoff) symbol(_nwmode, legendoff) ///
    label(_nwnode) layout(bipartite, vertical) scheme(s1network) ///
    labelopt(mlabsize(small) mlabvposition(lpos)) xsize(5) ysize(6)

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

local grays white gs14 gs14 gs10 gs7 gs4 gs2 black black black
set seed 1
nwplot women, lab layout(kk) edgesize(women, legendoff) edgefactor(0.6) ///
    edgecolor(women, legendoff edgecolorpalette(`grays')) ///
    labelopt(mlabsize(medsmall)) scheme(s1network) xsize(5) ysize(5)
set seed 42
nwplot events, lab edgesize(events, legendoff) edgefactor(0.6) ///
    edgecolor(events, legendoff edgecolorpalette(`grays')) ///
    scatteropt(msymbol(D) mfcolor(blue) mlcolor(blue)) ///
    labelopt(mlabsize(medsmall)) scheme(s1network) xsize(5) ysize(5)

nw2project davis, project(1) name(wbin) stat(binary)
nw2project davis, project(1) name(wjac) stat(jaccard)
preserve
quietly nwtoedge women wbin wjac, compress
drop if missing(women)
gsort -women -wjac _ego _alter
list _ego _alter women wbin wjac in 1/6, noobs
tabulate women
restore

nwcommunity women, generate(com_w)
nwcommunity events, generate(com_e)
list _nwnode com_e if !missing(com_e), noobs
