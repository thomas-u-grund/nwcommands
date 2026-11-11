* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 17: Simulating from network models
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
* Simulating from a fitted model
* ============================================================
nwwebuse lazega, nwclear
foreach v in office practice status {
    encode `v', generate(`v'n)
}
nwergm lazega_adv, edges mutual nodematch(officen practicen) ///
    nodeofactor(statusn) nodeifactor(statusn) gwesp(.5) seed(12345)
matrix b = e(b)

capture program drop simsummary
program simsummary
    args stub nsim
    matrix S = J(`nsim', 3, .)
    matrix colnames S = reciprocity density clustering
    forvalues i = 1/`nsim' {
        quietly nwdyads `stub'_`i'
        matrix S[`i', 1] = r(reciprocity)
        quietly nwsummarize `stub'_`i'
        matrix S[`i', 2] = r(density)
        quietly nwclustering `stub'_`i', generate(_clus) replace
        matrix S[`i', 3] = r(cluster_global)
    }
    preserve
    clear
    quietly svmat S, names(col)
    summarize reciprocity density clustering
    restore
end

nwergm simulate, nsim(100) output(network) seed(1)
simsummary sim 100

nwplot lazega_adv, color(officen) legendopt(off) ///
    title("Observed advice network") name(obs, replace)
nwplot sim_100, color(officen) legendopt(off) ///
    title("One draw from the fitted model") name(draw, replace)

* ============================================================
* Coefficients are not independent dials
* ============================================================
matrix b0 = b
matrix b0[1, colnumb(b0, "mutual")] = 0
nwergm simulate, coef(b0) nsim(100) output(network) generate(nomut) seed(1)
simsummary nomut 100

matrix b0[1, colnumb(b0, "edges")] = -4.45
nwergm simulate, coef(b0) nsim(100) output(network) generate(nomut2) seed(1)
simsummary nomut2 100

matrix b1 = b
matrix b1[1, colnumb(b1, "gwesp_.5")] = 0
nwergm simulate, coef(b1) nsim(100) output(network) generate(nogw) seed(1)
simsummary nogw 100

matrix b1[1, colnumb(b1, "edges")] = -3.52
nwergm simulate, coef(b1) nsim(100) output(network) generate(nogw2) seed(1)
simsummary nogw2 100

nwplot nomut2_100, color(officen) legendopt(off) ///
    title("mutual = 0, edges = -4.45") name(p1, replace)
nwplot nogw2_100, color(officen) legendopt(off) ///
    title("gwesp = 0, edges = -3.52") name(p2, replace)

* ============================================================
* Chosen coefficients, no fitted model
* ============================================================
nwergm simulate 71, edges mutual nodematch(officen) directed theta(-2.4 ///
    1.5 1) seed(12345) generate(scratch)
nwdyads scratch

* ============================================================
* Simulating network change: nwsaom simulate
* ============================================================
nwwebuse glasgow, nwclear
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ///
    transtrip theta(-2.3 2 0.5) rates(5) nsim(100) seed(7) generate(sim)
nwsummarize sim_1_p1
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ///
    transtrip theta(-2.3 0 0.5) rates(5) nsim(100) seed(7)
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ///
    transtrip theta(-2.3 2 0.5) rates(1) nsim(100) seed(7)
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ///
    transtrip theta(-2.3 2 0.5) rates(5) nsim(100) seed(8)
