* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 15: Random and structured network generators
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.28.0,
* nwergm 1.10.0, nwsaom 1.8.1, nwrem 1.5.1, nwdynam 1.9.1, nwalaam 1.2.0,
* nwlsm 1.0.0 and nwsbm 1.0.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* What density does by itself
* ============================================================
matrix R = J(6, 5, .)
local i = 0
foreach d in .02 .05 .1 .179 .3 .5 {
    local ++i
    set seed 12345
    quietly nwrandom 71, density(`d') name(r)
    quietly nwsummarize r, detail
    matrix R[`i', 1] = (`d', r(reciprocity), r(transitivity))
    quietly nwgeodesic r, name(geo_r)
    local path = cond(r(avgpath) < 0, ., r(avgpath))
    matrix R[`i', 4] = (1 - r(unconnected) / r(numpaths), `path')
    nwdrop r geo_r
}
matrix colnames R = density reciprocity transitivity reachable avgpath
matlist R, format(%12.3f) names(columns)

matrix S = J(4, 3, .)
local i = 0
foreach n in 71 142 284 710 {
    local ++i
    set seed 12345
    local d = 12.56 / (`n' - 1)
    quietly nwrandom `n', density(`d') name(r)
    quietly nwsummarize r, detail
    matrix S[`i', 1] = (`d', r(transitivity))
    quietly nwgeodesic r, name(geo_r)
    matrix S[`i', 3] = r(avgpath)
    nwdrop r geo_r
}
matrix rownames S = 71 142 284 710
matrix colnames S = density transitivity avgpath
matlist S, format(%12.3f) rowtitle(nodes)

* ============================================================
* Random graphs
* ============================================================
nwwebuse lazega, nwclear
nwsummarize lazega_adv, detail
nwgeodesic lazega_adv, name(geo_adv)

set seed 12345
nwrandom 71, density(.179) name(rand71)
nwsummarize rand71, detail
nwgeodesic rand71, name(geo_rand)

set seed 1
quietly nwrandom 71, density(.179) ntimes(5) name(draw)
set seed 1
quietly nwrandom 16, density(.125) undirected ntimes(10) name(small)
quietly nwsummarize draw_* small_*, detail save(draws)
preserve
use draws, clear
format transitivity %5.3f
list name transitivity, noobs sep(5) abbreviate(12)
restore

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

preserve
matrix W = J(14, 3, 0)
local i = 0
set seed 12345
foreach p in 0 .0001 .0002 .0005 .001 .002 .005 .01 .02 .05 .1 .2 .5 1 {
    local ++i
    matrix W[`i', 1] = `p'
    forvalues r = 1/20 {
        quietly nwsmall 500, k(5) prob(`p') undirected name(sw)
        quietly nwclustering sw
        matrix W[`i', 2] = W[`i', 2] + r(cluster_global) / 20
        quietly nwgeodesic sw, name(geo_sw)
        matrix W[`i', 3] = W[`i', 3] + r(avgpath) / 20
        nwdrop sw geo_sw
    }
}
matrix colnames W = prob clustering avgpath
matlist W, format(%12.4f) names(columns)
clear
quietly svmat W, names(col)
generate C = clustering / clustering[1]
generate L = avgpath / avgpath[1]
twoway (connected C prob, lcolor(black) mcolor(black) msymbol(O)) ///
    (connected L prob, lcolor(gs8) mcolor(gs8) msymbol(D)) if prob > 0, ///
    xscale(log) xlabel(.0001 .001 .01 .1 1) xtitle("rewiring probability") ///
    ytitle("share of the value in the ring") scheme(s1network) ///
    legend(order(1 "clustering" 2 "average path") rows(1))
restore

* ============================================================
* Preferential attachment
* ============================================================
quietly nwdegree lazega_adv, generate(_outdeg _indeg)
summarize _outdeg _indeg
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
