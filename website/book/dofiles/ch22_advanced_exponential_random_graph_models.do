* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 22: Advanced exponential random graph models
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.26.0,
* nwergm 1.7.1, nwsaom 1.7.1, nwrem 1.3.0 and nwdynam 1.5.1, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Simulating networks from an ERGM
* ============================================================
clear
nwclear
set obs 100
generate grp = ceil(_n / 25)
preserve
nwergm simulate 100, edges mutual nodematch(grp) gwesp(.5) directed ///
    theta(-4 1.5 1.2 .6) seed(12345) generate(art)
restore
nwsummarize art, detail

nwergm art, edges mutual nodematch(grp) gwesp(.5) seed(12345)

nwwebuse lazega, nwclear
quietly nwergm lazega_adv, edges mutual nodematch(office practice) ///
    nodeofactor(status) nodeifactor(status) gwesp(.5) seed(12345)
matrix b = e(b)
matlist b', twidth(20)

capture program drop simsummary
program simsummary
    quietly nwsummarize `1'_*, detail save(simstats)
    preserve
    use simstats, clear
    summarize reciprocity density transitivity
    restore
end
nwergm simulate, coef(b) nsim(100) output(network) seed(1)
simsummary sim

matrix b0 = b
matrix b0[1, colnumb(b0, "mutual")] = 0
nwergm simulate, coef(b0) nsim(100) output(network) generate(nomut) seed(1)
simsummary nomut

matrix b0[1, colnumb(b0, "edges")] = -4.45
nwergm simulate, coef(b0) nsim(100) output(network) generate(nomut2) seed(1)
simsummary nomut2

matrix b1 = b
matrix b1[1, colnumb(b1, "gwesp_.5")] = 0
nwergm simulate, coef(b1) nsim(100) output(network) generate(nogw) seed(1)
simsummary nogw
matrix b1[1, colnumb(b1, "edges")] = -3.52
nwergm simulate, coef(b1) nsim(100) output(network) generate(nogw2) seed(1)
simsummary nogw2

* ============================================================
* An undirected case: Faux Mesa High
* ============================================================
nwwebuse mesa, nwclear
nwsummarize mesa

nwergm mesa, edges nodematch(grade race) seed(12345)

nwergm mesa, edges nodematch(grade race) gwesp(.25) seed(12345)
estat mcmcdiag

* ============================================================
* Why gwesp and not triangle
* ============================================================
capture noisily nwergm mesa, edges nodematch(grade race) triangle seed(12345)

* ============================================================
* Missing data
* ============================================================
nwtomata mesa, mat(A)
mata: A[1,2] = A[2,1] = A[1,3] = A[3,1] = A[10,20] = A[20,10] = .
mata: st_matrix("M", A)
nwset, mat(M) undirected name(mesa_na)
nwergm mesa_na, edges nodematch(grade race) seed(12345)
display "informative dyads: " e(N) "   missing dyads: " e(nmissing)
