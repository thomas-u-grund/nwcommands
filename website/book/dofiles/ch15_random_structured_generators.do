* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 15: Random and structured network generators
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.34.0,
* nwergm 1.12.0, nwsaom 1.9.1, nwrem 1.7.0, nwdynam 1.11.0, nwalaam 1.3.1,
* nwlsm 1.0.5 and nwsbm 1.0.2, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* A random graph as a baseline
* ============================================================
nwwebuse lazega, nwclear
set seed 12345
nwrandom 71, density(.179) name(rand71)
quietly nwsummarize lazega_adv rand71, detail save(cmp)
preserve
use cmp, clear
format reciprocity transitivity indg_central outdg_central %5.3f
list name reciprocity transitivity indg_central outdg_central, noobs ///
    abbreviate(14)
restore
foreach g in lazega_adv rand71 {
    quietly nwgeodesic `g', name(path_`g')
    display "`g': average shortest path " %5.3f r(avgpath)
}

set seed 1
quietly nwrandom 71, density(.179) ntimes(20) name(draw)
set seed 1
quietly nwrandom 16, density(.125) undirected ntimes(20) name(small)
quietly nwsummarize draw_* small_*, detail save(draws)
preserve
use draws, clear
tabstat transitivity, by(nodes) statistics(mean sd min max) format(%5.3f)
count if nodes == 16 & transitivity == 0
restore
nwdrop draw_* small_*

* ============================================================
* What density and size do by themselves
* ============================================================
frame create bydens density reciprocity transitivity
set seed 12345
foreach d in .02 .05 .1 .179 .3 .5 {
    forvalues k = 1/20 {
        quietly nwrandom 71, density(`d') name(tmp)
        quietly nwsummarize tmp, detail
        frame post bydens (`d') (r(reciprocity)) (r(transitivity))
        nwdrop tmp
    }
}
frame bydens: collapse (mean) reciprocity transitivity, by(density)
frame bydens: format reciprocity transitivity %5.3f
frame bydens: list, noobs

frame create bysize nodes density transitivity avgpath
set seed 12345
foreach n in 71 142 284 710 {
    local d = 12.56 / (`n' - 1)
    forvalues k = 1/20 {
        quietly nwrandom `n', density(`d') name(tmp)
        quietly nwsummarize tmp, detail
        local t = r(transitivity)
        quietly nwgeodesic tmp, name(pathnet)
        frame post bysize (`n') (`d') (`t') (r(avgpath))
        nwdrop tmp pathnet
    }
}
frame bysize: collapse (mean) density transitivity avgpath, by(nodes)
frame bysize: format density transitivity avgpath %5.3f
frame bysize: list, noobs

* ============================================================
* One command for every generator: nwgen
* ============================================================
set seed 12345
nwgen g_random = random(71), density(.179)
nwgen g_ring = ring(20), k(4)
nwgen g_lattice = lattice(5 6)
nwgen g_small = small(50), k(4) prob(.1)
nwgen g_pref = pref(100), m(2)

* ============================================================
* Rings and grids
* ============================================================
nwring 40, k(2) undirected
nwplot ring, layout(circle) title("ring lattice") name(ringplot, replace)

nwlattice 4 4, undirected
nwplot lattice, layout(grid)

* ============================================================
* Small-world networks
* ============================================================
set seed 12345
nwsmall 40, k(2) prob(.1) undirected
nwplot small, layout(circle) title("small world, prob(.1)") ///
    name(smallplot, replace)
graph combine ringplot smallplot, cols(2) scheme(s1network) xsize(8) ysize(4)

frame create sw prob clustering avgpath
set seed 12345
foreach p in 0 .001 .003 .01 .03 .1 .3 1 {
    forvalues k = 1/20 {
        quietly nwsmall 500, k(5) prob(`p') undirected name(tmp)
        quietly nwclustering tmp
        local c = r(cluster_global)
        quietly nwgeodesic tmp, name(pathnet)
        frame post sw (`p') (`c') (r(avgpath))
        nwdrop tmp pathnet
    }
}
frame sw: collapse (mean) clustering avgpath, by(prob)
frame sw: format clustering avgpath %6.3f
frame sw: list, noobs
frame sw: generate C = clustering / clustering[1]
frame sw: generate L = avgpath / avgpath[1]
frame sw: twoway (connected C prob, lcolor(black) mcolor(black) ///
    msymbol(O)) (connected L prob, lcolor(gs8) mcolor(gs8) msymbol(D)) if ///
    prob > 0, xscale(log) xlabel(.001 .01 .1 1) ///
    xtitle("rewiring probability") ///
    ytitle("share of the value in the ring") scheme(s1network) ///
    legend(order(1 "clustering" 2 "average path") rows(1))

* ============================================================
* Preferential attachment
* ============================================================
nwclear
set seed 12345
nwpref 71, m0(7) m(6) undirected name(pref71)
quietly nwsummarize pref71, detail
display "ties " r(edges) ", density " %5.3f r(density) ", transitivity " ///
    %5.3f r(transitivity)
quietly nwdegree pref71, generate(_degree)
nwplot pref71, size(_degree) name(prefplot, replace)
histogram _degree, discrete frequency xtitle("degree") scheme(s1network) ///
    name(prefhist, replace)
graph combine prefplot prefhist, cols(2) scheme(s1network) xsize(8) ysize(4)
set seed 12345
nwrandom 71, density(.163) undirected name(rand163)
quietly nwsummarize rand163, detail
display "ties " r(edges) ", density " %5.3f r(density) ", transitivity " ///
    %5.3f r(transitivity)
quietly nwdegree rand163, generate(_degree_rand)
summarize _degree _degree_rand
