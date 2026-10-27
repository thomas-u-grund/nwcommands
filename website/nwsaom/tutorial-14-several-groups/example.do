* nwsaom tutorial 14: several groups at once (joint estimation with groups())
* Requires the core nwcommands and the package nwsaom, version 1.2 or later.
* The csv files (school1_wave1.csv ... school4_wave2.csv and s50g_actors.csv,
* s50g_wave1.csv ... s50g_wave3.csv) must be in the current folder; they are on
* the website next to this tutorial.

nwclear

* ---- Part 1: four school classes -------------------------------------------
* For each class: read the two adjacency matrices (removing the few self-ties),
* make the two networks of the class (for the separate fits of Part 2) and add
* the matrices to two block-diagonal matrices B1 and B2 (for the joint fit).
mata: B1 = J(0, 0, .); B2 = J(0, 0, .)
local sizes ""
forvalues s = 1/4 {
    forvalues w = 1/2 {
        quietly import delimited using "school`s'_wave`w'.csv", clear
        local n = _N
        quietly mkmat v1-v`n', matrix(X`w')
        matrix X`w' = X`w' - diag(vecdiag(X`w'))
        mata: B`w' = blockdiag(B`w', st_matrix("X`w'"))
    }
    nwset, mat(X1) directed name(school`s'_w1) nooutput
    nwset, mat(X2) directed name(school`s'_w2) nooutput
    local sizes "`sizes' `n'"
}

* The stacked data set: one row per pupil (151), a group variable class,
* and the wave networks w1 and w2 of all classes together (no ties between classes)
clear
mata: st_matrix("G1", B1); st_matrix("G2", B2)
quietly set obs `=rowsof(G1)'
quietly generate byte class = .
local first = 1
local s = 0
foreach n of local sizes {
    local ++s
    quietly replace class = `s' in `first'/`=`first'+`n'-1'
    local first = `first' + `n'
}
nwset, mat(G1) directed name(w1) nooutput
nwset, mat(G2) directed name(w2) nooutput

tabulate class
nwsaom describe, waves(w1 w2)

* ---- Part 2: one joint model for all classes -------------------------------
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(5)
estimates store joint

* what the fit stored about the groups
display "groups: " e(ngroups) "   actors: " e(N)
matrix list e(groupn)
matrix list e(rates_group)
matrix list e(rates_period)

* ---- Part 3: joint model or meta-analysis? ---------------------------------
* the same classes fitted one at a time, then combined
forvalues s = 1/4 {
    quietly nwsaom, wave1(school`s'_w1) wave2(school`s'_w2) outdegree reciprocity transtrip seed(5)
    estimates store school`s'
}
estimates table school1 school2 school3 school4, b(%7.3f) se(%7.3f)
nwsaom meta school1 school2 school3 school4

* the joint estimate next to the average of the classes and the meta-analysis mean
quietly nwsaom meta school1 school2 school3 school4, notable
matrix T = r(theta)
matrix meanT = J(1, 4, 0.25) * T
matrix MM = r(meta)
local c = colnumb(MM, "iwls_mean")
matrix iwls = MM[1..3, `c']'
estimates restore joint
matrix jt = e(b)
matrix cmp = meanT \ iwls \ jt
matrix rownames cmp = avg_classes meta_IWLS joint
matrix colnames cmp = outdegree reciprocity transtrip
matrix list cmp, format(%7.3f)

* a joint model in which reciprocity may differ for class 2
generate byte c2 = (class == 2)
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip egox(c2) interact(egox_c2#reciprocity) seed(5)

* ---- Part 4: a behavior in several groups, and unequal waves ---------------
* 50 pupils (RSiena's s50 data) cut into three groups of 15, 20 and 15; the
* variables are group and alcohol use at three waves (alc1 alc2 alc3)
nwclear
quietly import delimited using "s50g_actors.csv", clear
forvalues w = 1/3 {
    preserve
    quietly import delimited using "s50g_wave`w'.csv", clear varnames(nonames)
    quietly mkmat v*, matrix(W`w')
    restore
    nwset, mat(W`w') directed name(g`w') nooutput
}
tabulate group
summarize alc1 alc2 alc3
nwsaom describe, waves(g1 g2 g3)

* network and behavior together
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip ///
    behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx seed(1)
matrix list e(rates)
matrix list e(rates_beh)

* groups with different waves: group 2 observed at waves 1 and 2, group 3 at waves 2 and 3
nwsaom, waves(g1 g2 g3) groups(group) gwaves(2: 1 2 | 3: 2 3) outdegree reciprocity transtrip seed(1)
matrix list e(groupwaves)
matrix list e(rates_group)
matrix list e(rates_period)

* ---- Part 5: after the fit -------------------------------------------------
* time heterogeneity, per effect, per group and per period
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) unconditional seed(1)
estat timetest, fixrates
matrix list r(group)
matrix list r(period)

* score test: fit the model with the two alcohol effects held fixed at 0, then test them
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) fix(egox(alc) altx(alc)) unconditional seed(1)
estat score
