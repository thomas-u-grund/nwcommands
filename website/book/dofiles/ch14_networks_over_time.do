* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 14: Networks over time
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
nwtomata glasgow1, mat(A1)
nwtomata glasgow2, mat(A2)
nwtomata glasgow3, mat(A3)
mata:
A1 = editmissing(A1, 0); A2 = editmissing(A2, 0); A3 = editmissing(A3, 0)
off = J(rows(A1), rows(A1), 1) - I(rows(A1))
ab1 = off :* (A1 :== 0); f1 = ab1 :* A2
ab2 = off :* (A2 :== 0); f2 = ab2 :* A3
r1 = A1'; c1 = (A1 * A1) :> 0; r2 = A2'; c2 = (A2 * A2) :> 0
P = (sum(f1), sum(f1:*r1)/sum(f1), sum(f1:*c1)/sum(f1))
P = P \ (sum(ab1), sum(ab1:*r1)/sum(ab1), sum(ab1:*c1)/sum(ab1))
P = P \ (sum(f2), sum(f2:*r2)/sum(f2), sum(f2:*c2)/sum(f2))
P = P \ (sum(ab2), sum(ab2:*r2)/sum(ab2), sum(ab2:*c2)/sum(ab2))
st_matrix("P", P)
end
matrix rownames P = "formed 1-2" "absent 1" "formed 2-3" "absent 2"
matrix colnames P = pairs recip two-path
matlist P, format(%9.3f) names(all)

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
