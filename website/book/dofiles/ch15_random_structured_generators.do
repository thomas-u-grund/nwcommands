* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 15: Random and structured network generators
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
* What density does by itself
* ============================================================
display "density  arcs  reciprocity  transitivity  reachable  average path"
foreach d in .02 .05 .1 .179 .3 .5 {
    set seed 12345
    quietly nwrandom 71, density(`d') name(r)
    quietly nwsummarize r, detail
    local arcs = r(arcs)
    local rec = r(reciprocity)
    local tra = r(transitivity)
    quietly nwgeodesic r, name(geo_r)
    local reach = 1 - r(unconnected) / r(numpaths)
    local path = cond(r(avgpath) < 0, ., r(avgpath))
    display %7.3f `d' %6.0f `arcs' %13.2f `rec' %14.2f `tra' %11.2f ///
        `reach' %14.2f `path'
    nwdrop r geo_r
}

display "nodes  density  transitivity  average path"
foreach n in 71 142 284 710 {
    set seed 12345
    local d = 12.56 / (`n' - 1)
    quietly nwrandom `n', density(`d') name(r)
    quietly nwsummarize r, detail
    local tra = r(transitivity)
    quietly nwgeodesic r, name(geo_r)
    display %5.0f `n' %9.3f `d' %14.3f `tra' %14.2f r(avgpath)
    nwdrop r geo_r
}

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
nwplot rand71

forvalues s = 1/5 {
    set seed `s'
    quietly nwrandom 71, density(.179) name(draw`s')
    quietly nwclustering draw`s', generate(_cl`s')
    display "seed `s':  clustering = " %5.3f r(cluster_global)
}
forvalues s = 1/10 {
    set seed `s'
    quietly nwrandom 16, density(.125) undirected name(small`s')
    quietly nwclustering small`s', generate(_cs`s')
    display "seed " %2.0f `s' ", 16 nodes:  clustering = " %5.3f ///
        r(cluster_global)
}

* ============================================================
* Rings and grids
* ============================================================
nwring 40, k(2) undirected
nwclustering ring, generate(_clus)
nwgeodesic ring, name(geo_ring)
nwplot ring, layout(circle) title("ring lattice") name(ringplot, replace)

nwlattice 4 4, undirected
nwplot lattice, layout(grid)

* ============================================================
* Small-world networks
* ============================================================
set seed 12345
nwsmall 40, k(2) prob(.1) undirected
nwclustering small, generate(_clus) replace
nwgeodesic small, name(geo_small)
nwplot small, layout(circle) title("small world, prob(.1)") ///
    name(smallplot, replace)
graph combine ringplot smallplot, cols(2) scheme(s1network) xsize(8) ysize(4)

foreach p in 0 .01 .05 .1 .2 .5 1 {
    set seed 12345
    quietly nwsmall 40, k(2) prob(`p') undirected name(sw)
    quietly nwclustering sw, generate(_clus) replace
    local c = r(cluster_global)
    quietly nwgeodesic sw, name(geo_sw)
    display "prob(" %4.2f `p' ")  clustering = " %5.3f `c' ///
        "  average path = " %5.2f r(avgpath)
    nwdrop sw geo_sw
}

* ============================================================
* Preferential attachment
* ============================================================
quietly nwdegree lazega_adv, generate(_outdeg _indeg)
summarize _outdeg _indeg
set seed 12345
nwpref 71, m0(7) m(6) undirected name(pref71)
nwsummarize pref71, detail
quietly nwdegree pref71, generate(_degree)
summarize _degree, detail
nwplot pref71, size(_degree)
