* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 5: Seeing networks
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
* A first picture of the firm
* ============================================================
nwwebuse lazega, nwclear
set seed 42
nwplot lazega_adv, color(office) size(yrs_frm) layout(mds)

* ============================================================
* Worked example: one network, several layouts
* ============================================================
nwwebuse florentine, nwclear
nwplot flomarriage, label(_nwnode) layout(circle) scheme(s1network) ///
    title("circle") labelopt(mlabsize(vsmall) mlabposition(12)) name(g1, ///
    replace)
set seed 42
nwplot flomarriage, label(_nwnode) layout(frucht) scheme(s1network) ///
    title("Fruchterman-Reingold") labelopt(mlabsize(vsmall) ///
    mlabposition(12)) name(g2, replace)
graph combine g1 g2, cols(2) scheme(s1network) xsize(8) ysize(4)

set seed 42
nwplot flomarriage, label(_nwnode) generate(x y) interactive noopen ///
    fname(florentine_explore.html)

* ============================================================
* Matrix plots: an alternative that does not lay out coordinates at all
* ============================================================
nwwebuse lazega, nwclear
nwplotmatrix lazega_adv, group(office) scheme(s1mono)

* ============================================================
* Mapping attributes to visual channels
* ============================================================
nwwebuse glasgow, nwclear
set seed 42
nwplot glasgow1, color(smoke1, colorpalette(gs12 orange cranberry)) ///
    layout(kk, lgc)

* ============================================================
* Highlighting structure within a plot
* ============================================================
nwwebuse florentine, nwclear
nwpath flomarriage, ego(medici) alter(peruzzi) generate(sp)
set seed 42
nwplot flomarriage, label(_nwnode) scheme(s1network) title("full network") ///
    labelopt(mlabsize(vsmall) mlabposition(12)) name(g1, replace)
set seed 42
nwplot flomarriage, label(_nwnode) edgecolor(sp_1, legendoff) ///
    scheme(s1network) title("medici-peruzzi path") ///
    labelopt(mlabsize(vsmall) mlabposition(12)) name(g2, replace)
graph combine g1 g2, cols(2) scheme(s1network) xsize(8) ysize(4)

* ============================================================
* When real coordinates exist
* ============================================================
nwwebuse usair, nwclear
set seed 42
nwplot usair, layout(mds) scheme(s1network) title("mds") name(g1, replace)
nwplot usair, nodexy(Lon Lat) scheme(s1network) ///
    title("geographic (Lon, Lat)") name(g2, replace)
graph combine g1 g2, cols(2) scheme(s1network) xsize(8) ysize(4)

* ============================================================
* Valued ties as edge width
* ============================================================
nwwebuse chesapeake, nwclear
preserve
quietly nwtoedge chesapeake, ego(from) alter(to)
summarize chesapeake if chesapeake > 0
restore
nwgenerate chesapeake_log = ln(chesapeake + 1)
set seed 42
nwplot chesapeake, arcstyle(straight) edgesize(chesapeake, legendoff) ///
    edgefactor(0.5) arrowfactor(0.3) layout(mds) generate(x y) ///
    scheme(s1network) title("raw flux") name(g1, replace)
nwplot chesapeake, arcstyle(straight) edgesize(chesapeake_log, legendoff) ///
    edgefactor(0.5) arrowfactor(0.3) nodexy(x y) scheme(s1network) ///
    title("log of flux plus one") name(g2, replace)
graph combine g1 g2, cols(2) scheme(s1network) xsize(8) ysize(4)

* ============================================================
* Producing a presentable figure
* ============================================================
nwwebuse lazega, nwclear
nwdegree lazega_adv, generate(outdeg indeg) silent
set seed 42
nwplot lazega_adv, color(office, colorpalette(navy dkorange gs12)) ///
    symbol(practice) size(indeg) label(_nwnode) edgefactor(0.4) generate(x ///
    y) interactive noopen fname(lazega_advice_interactive.html)

* needs nwedit_nodes.csv, nwedit_edges.csv: save them from the interactive page, or use the copies posted with the do-files
capture noisily nwplot lazega_adv, nodexy(x y) ///
    importcoords("nwedit_nodes.csv") edgeimport("nwedit_edges.csv") ///
    color(office, colorpalette(navy dkorange gs12)) symbol(practice) ///
    size(indeg) label(_nwnode) scheme(s1mono) nodefactor(0.35) ///
    edgefactor(0.5) labelopt(mlabsize(tiny)) ///
    export("lazega_advice_final.pdf") replace
