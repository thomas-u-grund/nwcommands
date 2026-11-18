* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 14: Networks over time
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.27.0,
* nwergm 1.8.0, nwsaom 1.8.0, nwrem 1.5.0, nwdynam 1.9.0 and nwalaam 1.0.0, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Measuring turnover between waves
* ============================================================
nwwebuse glasgow, nwclear
nwturnover glasgow1 glasgow2, generate(_turnover)

nwturnover glasgow2 glasgow3, generate(_turnover) replace

* ============================================================
* Animating change
* ============================================================
nwgen glasgowall = (glasgow1 + glasgow2 + glasgow3) > 0
nwplot glasgowall, generate(x y)
nwplot glasgow1, nodexy(x y) title("wave 1") name(g1, replace)
nwplot glasgow2, nodexy(x y) title("wave 2") name(g2, replace)
nwplot glasgow3, nodexy(x y) title("wave 3") name(g3, replace)
graph combine g1 g2 g3, rows(1) xsize(9) ysize(3.3)

nwmovie glasgow1 glasgow2 glasgow3, fname(glasgow_movie) noopen

nwmovie glasgow1 glasgow2 glasgow3, duration(2000) fixedlayout ///
    export(glasgow.mp4) replace

* ============================================================
* What a model of change has to explain
* ============================================================
nwturnover glasgow1 glasgow2, generate(_turnover) replace formation
nwturnover glasgow2 glasgow3, generate(_turnover) replace formation

* ============================================================
* Slicing a genuinely timestamped network
* ============================================================
nwclear
clear
input str8 ego str8 alter wave
"Anna" "Sophie" 1
"Sophie" "Gwen" 1
"Gwen" "Anna" 1
"Gwen" "Leh" 2
"Anna" "Leh" 2
"Leh" "Sophie" 3
end
nwset ego alter, edgelist undirected time(wave) name(evolving)
nwsummarize evolving
nwattime evolving, at(1) name(snap1)
nwattime evolving, at(2) name(snap2)
