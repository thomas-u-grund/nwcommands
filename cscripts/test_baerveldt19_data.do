cscript

* Example data set baerveldt19 (all 19 Dutch secondary schools of the Dutch Social Behavior study, Baerveldt et al.)
* with baerveldt19_pupils, and nwstack on it. Loaded from the local data folder with nwuse, which is the code path of
* nwwebuse. Run from the repository root.

do unw_core.do

nwuse data/baerveldt19, nwclear
* 57 networks of their own sizes (3 per school)
forvalues k = 1/19 {
    foreach m in w1 w2 ethn {
        nwsummarize school`k'_`m'
        * friendship is directed; the ethnicity matrix is symmetric and is read as undirected
        if "`m'" == "ethn" assert "`r(directed)'" == "false"
        else assert "`r(directed)'" == "true"
        assert "`r(mode2)'" == "false"
        local n_`k'_`m' = r(nodes)
    }
    assert `n_`k'_w1' == `n_`k'_w2'
    assert `n_`k'_w1' == `n_`k'_ethn'
}
* sizes of the Siena files N34_1, N34_3, N34_8, N34_23
assert `n_1_w1' == 45
assert `n_2_w1' == 37
assert `n_6_w1' == 91
assert `n_19_w1' == 73

* nodes are in the order of the pupils' numbers (names p01, p02, ...), not in text order (n1, n10, n11, ...):
* in school 2 (Siena 3), pupil 1 names pupil 12 at wave 1, and pupil 5 names pupil 4;
* in school 1 (Siena 1), pupil 1 names pupil 18 and pupil 3 names pupils 11 and 14
nwtomata school2_w1, mat(M2)
mata: st_numscalar("t112", M2[1, 12]); st_numscalar("t54", M2[5, 4])
assert scalar(t112) == 1 & scalar(t54) == 1
nwtomata school1_w1, mat(M1)
mata: st_numscalar("t118", M1[1, 18]); st_numscalar("t311", M1[3, 11] + M1[3, 14])
assert scalar(t118) == 1 & scalar(t311) == 2

* the 15 classes of data set baerveldt are schools 1-7, 9, 11, 12, 14-18 here, unchanged
* (checked for class 1 = school 2 and class 13 = school 1; Stata matrices survive nwuse, Mata networks do not)
nwtomata school2_w1, mat(N)
mata: _diag(N, 0); st_matrix("N2", N)
nwtomata school1_w2, mat(N)
mata: _diag(N, 0); st_matrix("N1", N)
nwuse data/baerveldt, nwclear
nwtomata class1_w1, mat(O)
mata: _diag(O, 0); st_numscalar("same1", O == st_matrix("N2"))
nwtomata class13_w2, mat(O)
mata: _diag(O, 0); st_numscalar("same13", O == st_matrix("N1"))
assert scalar(same1) == 1 & scalar(same13) == 1
nwuse data/baerveldt19, nwclear

* the ethnicity matrix of Siena school 23 has 72 rows for 73 pupils: the last pupil is padded with zeros
nwtomata school19_ethn, mat(E19)
mata: st_numscalar("lastrow", sum(E19[73, 1..72]))
assert scalar(lastrow) == 0

* stacking with a wildcard keeps the order of the schools
clear
nwstack school*_w1, name(w1) group(school)
assert r(k) == 19
assert r(N) == 990
nwsummarize w1
assert r(arcs) == 1624
nwstack school*_w2, name(w2)
nwsummarize w2
assert r(arcs) == 2168
nwstack school*_ethn, name(ethn)

* the group variable follows the school sizes
assert _N == 990
count if school == 1
assert r(N) == 45
count if school == 6
assert r(N) == 91
tabulate school
assert r(r) == 19

* attributes
bysort school: generate pupil = _n
merge 1:1 school pupil using data/baerveldt19_pupils.dta, assert(match) nogenerate
assert inlist(gender, 1, 2)
assert inrange(delinq1, 0, 4) & inrange(delinq2, 0, 4)
assert nact > 3 & nact < 5
summarize nact if school == 6
assert abs(r(mean) - ln(91)) < 1e-9
summarize siena if school == 19
assert r(mean) == 23
* gender: 2 = boys (share of boys by school .37 to .67, mean .52, Snijders and Baerveldt 2003)
preserve
generate boy = gender == 2
collapse (mean) boy, by(school)
summarize boy
assert abs(r(min) - .370) < .001 & abs(r(max) - .667) < .001
restore

* no tie between pupils of different schools: the ties of the whole network are the sum of the ties of the school blocks
nwtomata w1, mat(Mw)
mata: st_numscalar("inblocks", sum(Mw[1..45, 1..45]) + sum(Mw[46..82, 46..82]) + sum(Mw[83..115, 83..115]))
nwsummarize school1_w1
local a1 = r(arcs)
nwsummarize school2_w1
local a2 = r(arcs)
nwsummarize school3_w1
local a3 = r(arcs)
assert scalar(inblocks) == `a1' + `a2' + `a3'

display "test_baerveldt19_data passed"
