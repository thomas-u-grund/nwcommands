* nwsaom tutorial 13: combining several groups with a meta-analysis
* Requires the core nwcommands and the package nwsaom.
* The eight csv files (school1_wave1.csv ... school4_wave2.csv) must be in
* the current folder; they are on the website next to this tutorial.

* Four school classes, each observed twice. For each class: read the two
* adjacency matrices, remove the (few) self-ties, describe the class, fit
* the same model, and store the result.
forvalues s = 1/4 {
    forvalues w = 1/2 {
        import delimited using "school`s'_wave`w'.csv", clear
        local n = _N
        mkmat v1-v`n', matrix(X`w')
        matrix X`w' = X`w' - diag(vecdiag(X`w'))
    }
    clear
    nwclear
    nwset, mat(X1) directed name(school`s'_w1)
    nwset, mat(X2) directed name(school`s'_w2)
    nwsaom describe, waves(school`s'_w1 school`s'_w2)
    display as text _newline "School `s'"
    nwsaom, wave1(school`s'_w1) wave2(school`s'_w2) outdegree reciprocity transtrip seed(5)
    estimates store school`s'
}

* Combine: the mean effect, the between-class standard deviation,
* and a test of whether the classes differ
nwsaom meta school1 school2 school3 school4

* The numbers are kept in r()
nwsaom meta school1 school2 school3 school4, notable
matrix list r(theta), format(%7.3f)
matrix list r(se), format(%7.3f)
