cscript

* Two-mode example data sets: davis (Southern women) and ftdirectors_se
* (Swedish company directors). Loaded from the local data folder with nwuse,
* which is the code path of nwwebuse (nwwebuse only prepends the web path).
* Run from the repository root.

do unw_core.do

* ---------------- davis ----------------
nwuse data/davis, nwclear
nwset
assert `"`r(nets)'"' == " davis"
nwsummarize davis
assert r(nodes) == 32
assert r(edges) == 89
assert "`r(mode2)'" == "true"
count if _nwmode == "1"
assert r(N) == 18
count if _nwmode == "2"
assert r(N) == 14

* attributes
assert surname != "" & title != "" if _nwmode == "1"
assert eventdate != "" if _nwmode == "2"
count if title == "Mrs"
assert r(N) > 0
assert eventdate == "1936-06-27" if _nwnode == "E1"
assert eventdate == "1936-08-03" if _nwnode == "E14"

* degrees as in the published attendance table
* nw2degree gives the degree divided by the size of the other mode
nw2degree davis, generate(dgn)
gen dg = round(dgn * cond(_nwmode == "1", 14, 18))
foreach p in Evelyn Nora Theresa {
	qui sum dg if _nwnode == "`p'"
	assert r(mean) == 8
}
foreach p in Laura Brenda Sylvia {
	qui sum dg if _nwnode == "`p'"
	assert r(mean) == 7
}
qui sum dg if _nwnode == "E8"
assert r(mean) == 14
qui sum dg if _nwnode == "E9"
assert r(mean) == 12
qui sum dg if _nwnode == "E7"
assert r(mean) == 10
foreach e in E5 E6 {
	qui sum dg if _nwnode == "`e'"
	assert r(mean) == 8
}
qui sum dg if _nwmode == "1"
assert r(sum) == 89
qui sum dg if _nwmode == "2"
assert r(sum) == 89
nw2clustering davis, generate(cc)
nw2project davis, project(1) name(women) stat(count)
nwsummarize women
assert r(nodes) == 18
assert r(edges) == 139
nw2project davis, project(2) name(events) stat(count)
nwsummarize events
assert r(nodes) == 14
assert r(edges) == 66
nwcommunity women, generate(com) algorithm(louvain)

* ---------------- ftdirectors_se ----------------
nwuse data/ftdirectors_se, nwclear
nwset
assert `"`r(nets)'"' == " ftdirectors_se"
nwsummarize ftdirectors_se
assert r(nodes) == 5547
assert r(edges) == 5669
assert "`r(mode2)'" == "true"
count if _nwmode == "1"
assert r(N) == 5092
count if _nwmode == "2"
assert r(N) == 455

* attributes
count if gender == "Female" & _nwmode == "1"
assert r(N) == 1025
count if gender == "Male" & _nwmode == "1"
assert r(N) == 3485
count if gender == "" & _nwmode == "1"
assert r(N) == 582
count if !missing(age) & _nwmode == "1"
assert r(N) > 4000
assert missing(gender) | gender == "" if _nwmode == "2"
count if sector != "" & _nwmode == "2"
assert r(N) == 455 - 31
count if industry != "" & _nwmode == "2"
assert r(N) > 350
count if !missing(employees) & _nwmode == "2"
assert r(N) > 300

* degrees
nw2degree ftdirectors_se, generate(dgn)
gen dg = round(dgn * cond(_nwmode == "1", 455, 5092))
qui sum dg if _nwmode == "1"
assert r(sum) == 5669 & r(min) == 1 & r(max) == 7
count if dg > 1 & _nwmode == "1"
assert r(N) == 390
qui sum dg if _nwmode == "2"
assert r(sum) == 5669 & r(min) >= 1
nw2clustering ftdirectors_se, generate(cc)
nw2project ftdirectors_se, project(2) name(firms) stat(binary)
nwsummarize firms
assert r(nodes) == 455
assert r(edges) == 759
nwcommunity firms, generate(comfirm) algorithm(louvain)
nw2project ftdirectors_se, project(1) name(dirs) stat(binary)
nwsummarize dirs
assert r(nodes) == 5092
assert r(edges) == 40284

di "PASS test_twomode_data"
