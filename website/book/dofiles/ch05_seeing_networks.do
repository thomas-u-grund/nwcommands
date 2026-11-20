* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 5: Seeing networks
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.30.0,
* nwergm 1.11.1, nwsaom 1.9.1, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.0,
* nwlsm 1.0.2 and nwsbm 1.0.1, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* A first picture
* ============================================================
nwwebuse florentine, nwclear
set seed 42
nwplot flomarriage, label(_nwnode)

nwwebuse lazega, nwclear
set seed 42
nwplot lazega_adv, color(office)

nwsubset lazega_adv if office == "Hartford", name(hartford)
set seed 42
nwplot hartford, label(_nwnode)

* ============================================================
* Worked example: one network, several layouts
* ============================================================
nwwebuse florentine, nwclear
nwplot flomarriage, label(_nwnode) layout(circle) scheme(s1network) ///
    title("circle") labelopt(mlabsize(medium) mlabposition(12)) name(g1, ///
    replace)
set seed 42
nwplot flomarriage, label(_nwnode) layout(frucht) scheme(s1network) ///
    title("Fruchterman-Reingold") labelopt(mlabsize(medium) ///
    mlabposition(12)) name(g2, replace)
graph combine g1 g2, cols(2) scheme(s1network) xsize(8) ysize(4)

* ============================================================
* Mapping attributes to visual channels
* ============================================================
set seed 42
nwplot flomarriage, label(_nwnode) size(wealth)

* ============================================================
* Highlighting structure within a plot
* ============================================================
nwpath flomarriage, ego(medici) alter(peruzzi) generate(sp)
set seed 42
nwplot flomarriage, label(_nwnode) edgecolor(sp_1, legendoff) ///
    scheme(s1network) title("path 1") labelopt(mlabsize(medium) ///
    mlabposition(12)) name(g1, replace)
set seed 42
nwplot flomarriage, label(_nwnode) edgecolor(sp_2, legendoff) ///
    scheme(s1network) title("path 2") labelopt(mlabsize(medium) ///
    mlabposition(12)) name(g2, replace)
graph combine g1 g2, cols(2) scheme(s1network) xsize(8) ysize(4)

* ============================================================
* Exploring interactively, then drawing the figure
* ============================================================
set seed 42
nwplot flomarriage, label(_nwnode) generate(x y) interactive noopen ///
    fname(florentine_explore.html)

* needs nwedit_plot.do: save them from the interactive page, or use the copies posted with the do-files
* the posted nwedit_plot.do is the book's (Pucci moved); to redraw your own edits, move the file
* that Save do-file wrote into your Downloads folder into the working directory (pwd)
capture noisily run nwedit_plot.do

* ============================================================
* When real coordinates exist
* ============================================================
nwwebuse usair, nwclear
nwplot usair if Lat < 50 & Lon > -125, nodexy(Lon Lat) basemap(usmap if ///
    !inlist(state, "AK", "HI")) arcstyle(straight) nodefactor(0.3) ///
    edgefactor(0.1) lineopt(lcolor(gs6%15)) arrowfactor(0) xsize(8) ///
    ysize(4.6)

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
nwplot chesapeake, arcstyle(straight) edgesize(chesapeake_log, legendoff) ///
    edgefactor(0.5) arrowfactor(0.3) layout(mds)

* ============================================================
* Matrix plots: an alternative that does not lay out coordinates at all
* ============================================================
nwwebuse lazega, nwclear
nwplotmatrix lazega_adv, group(office) scheme(s1mono)
