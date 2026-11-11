* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 23: Advanced stochastic actor-oriented models
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
* Is the specified process adequate?
* ============================================================
nwwebuse glasgow, nwclear
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
    transtrip seed(12345)
quietly nwsaom refit, seed(12346)
matrix b = e(b)
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
    transtrip indegpopularity outactivity cycle3 theta0(`=b[1,1]' ///
    `=b[1,2]' 0 0 `=b[1,3]' 0) fix(indegpopularity outactivity cycle3) ///
    seed(1)
display "Overall maximum t-ratio of the restricted fit: " %5.3f e(tconv_max)
estat score

quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
    transtrip seed(12345)
quietly nwsaom refit, seed(12346)
estat timetest, fixrates

estat importance

* ============================================================
* What does the fitted model imply?
* ============================================================
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip ///
    seed(4)
estat simulate, nsim(100) seed(5)

capture program drop mutualties
program mutualties, rclass
    args netname
    nwtomata `netname', mat(MM)
    mata: st_numscalar("__mut", sum(MM :* MM') / 2)
    return scalar stat = scalar(__mut)
end
estat mems, effect(reciprocity) macro(mutualties) nsim(100) seed(1)

* ============================================================
* Which estimator?
* ============================================================
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ///
    ml seed(12345) mloptions(n3(3000))

quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
    transtrip seed(12345)
quietly nwsaom refit, seed(12346)
nwsaom bayes, nmain(250) seed(1)

frame nwsaom_bayes_draws: summarize b1 b2 b3

* ============================================================
* Pool the groups or not?
* ============================================================
nwwebuse baerveldt19, nwclear
clear
nwstack school*_w1, name(w1) group(school)
nwstack school*_w2, name(w2)
nwstack school*_ethn, name(ethn)
bysort school: generate pupil = _n
merge 1:1 school pupil using "$nwwebpath/baerveldt19_pupils.dta", nogenerate
nwtomata ethn, mat(E)
mata: st_matrix("Eth", E)
tabulate school
nwsaom describe, waves(w1 w2)

quietly nwsaom, waves(w1 w2) groups(school) outdegree reciprocity ///
    transtrip seed(1)
nwsaom refit, seed(2)
estimates store joint
matrix C = J(19, 3, .)
local fits ""
forvalues s = 1/19 {
    quietly nwsaom, waves(school`s'_w1 school`s'_w2) outdegree reciprocity ///
        transtrip seed(1)
    quietly nwsaom refit, seed(2)
    estimates store school`s'
    matrix b = e(b)
    matrix C[`s', 1] = b[1, 1], b[1, 2], b[1, 3]
    local fits `fits' school`s'
}
matrix colnames C = outdegree reciprocity transtrip
matrix list C, format(%7.3f)

nwsaom meta `fits'
quietly nwsaom meta `fits', notable
matrix MM = r(meta)
matrix SEm = MM[1..3, colnumb(MM, "iwls_se")]'
quietly estimates restore joint
matrix V = e(V)
matrix SEj = (sqrt(V[1,1]), sqrt(V[2,2]), sqrt(V[3,3]))
matrix cmp = (SEj', SEm')'
matrix rownames cmp = joint meta
matrix colnames cmp = outdegree reciprocity transtrip
matrix list cmp, format(%7.3f)

quietly nwsaom, waves(w1 w2) groups(school) behavior(delinq1 delinq2) ///
    outdegree reciprocity gwesp(.69) outactivity inpop inact reciact ///
    interact(reciprocity#gwesp) egox(gender nact) uncentered(nact) ///
    netbeh(egoxaltx) behegox behaltx dyadcov(Eth) linear quadratic ///
    beheff(totalt outdeg) behfrom(gender) seed(1235)
nwsaom refit, k3(3000)
