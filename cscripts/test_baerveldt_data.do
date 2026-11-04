cscript

* Example data set baerveldt (15 Dutch school classes, Baerveldt et al.) with baerveldt_pupils, and nwstack on it.
* Loaded from the local data folder with nwuse, which is the code path of nwwebuse. Run from the repository root.

do unw_core.do

nwuse data/baerveldt, nwclear
* 45 networks of their own sizes (3 per class)
local nclass = 0
forvalues k = 1/15 {
    foreach m in w1 w2 ethn {
        nwsummarize class`k'_`m'
        * friendship is directed; the ethnicity matrix is symmetric and is read as undirected
        if "`m'" == "ethn" assert "`r(directed)'" == "false"
        else assert "`r(directed)'" == "true"
        assert "`r(mode2)'" == "false"
        local n_`k'_`m' = r(nodes)
    }
    assert `n_`k'_w1' == `n_`k'_w2'
    assert `n_`k'_w1' == `n_`k'_ethn'
}
assert `n_1_w1' == 37
assert `n_5_w1' == 91
assert `n_2_w1' == 33

* nodes are in the order of the pupils' numbers (names p01, p02, ...), not in text order (n1, n10, n11, ...):
* pupil 1 of class 1 names pupil 12 as a friend at wave 1, and pupil 5 names pupil 4
nwtomata class1_w1, mat(M1)
mata: st_numscalar("t112", M1[1, 12]); st_numscalar("t54", M1[5, 4])
assert scalar(t112) == 1 & scalar(t54) == 1

local w1 ""
local w2 ""
local et ""
local total = 0
forvalues k = 1/15 {
    local w1 `w1' class`k'_w1
    local w2 `w2' class`k'_w2
    local et `et' class`k'_ethn
    local total = `total' + `n_`k'_w1'
}
assert `total' == 810

* tie counts per wave
clear
nwstack `w1', name(w1) group(class)
assert r(k) == 15
assert r(N) == 810
nwsummarize w1
assert r(arcs) == 1360
nwstack `w2', name(w2)
nwsummarize w2
assert r(arcs) == 1816
nwstack `et', name(ethn)

* the group variable follows the class sizes
assert _N == 810
count if class == 1
assert r(N) == 37
count if class == 5
assert r(N) == 91
tabulate class
assert r(r) == 15

* attributes
bysort class: generate pupil = _n
merge 1:1 class pupil using data/baerveldt_pupils.dta, assert(match) nogenerate
assert gender < .
assert delinq1 < . & delinq2 < .
assert nact > 3 & nact < 5
sum nact if class == 5
assert abs(r(mean) - ln(91)) < 1e-9

* no tie between pupils of different classes: the ties of the whole network are the sum of the ties of the class blocks
nwtomata w1, mat(Mw)
mata: st_numscalar("inblocks", sum(Mw[1..37, 1..37]) + sum(Mw[38..70, 38..70]) + sum(Mw[71..106, 71..106]))
nwsummarize class1_w1
local a1 = r(arcs)
nwsummarize class2_w1
local a2 = r(arcs)
nwsummarize class3_w1
local a3 = r(arcs)
assert scalar(inblocks) == `a1' + `a2' + `a3'

display "test_baerveldt_data passed"
