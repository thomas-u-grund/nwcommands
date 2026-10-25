cscript

* Signed example data sets: senate93, senate114 (Neal 2020, US Senate signed
* co-sponsorship networks) and gahuku (Read 1954, Gahuku-Gama tribes).
* Loaded from the local data folder with nwuse, which is the code path of
* nwwebuse (nwwebuse only prepends the web path). Run from the repository root.

do unw_core.do

* ---------------- senate114 ----------------
nwuse data/senate114, nwclear
nwset
assert `"`r(nets)'"' == " senate114"
nwsummarize senate114
assert r(nodes) == 100
assert r(edges) == 3696
assert r(edges_sum) == 1435 - 2261
assert "`r(directed)'" == "false"
assert r(minval) == -1 & r(maxval) == 1
count if party == "D"
assert r(N) == 44
count if party == "I"
assert r(N) == 2
count if party == "R"
assert r(N) == 54
assert state != "" & _nwnode != ""

* positive and negative parts
nwrecode senate114 (-1 = 0), generate(s114pos)
nwrecode senate114 (1 = 0) (-1 = 1), generate(s114neg)
nwsummarize s114pos
assert r(edges) == 1435
nwsummarize s114neg
assert r(edges) == 2261

* balance
nwbalance senate114
assert r(closed_triad) == 74140
assert r(balanced_triad) == 72139
assert r(unbalanced_triad) == 2001
assert abs(r(balance) - 0.9730) < 0.0005

* signed degree
nwdegree s114pos, generate(npos) silent
nwdegree s114neg, generate(nneg) silent
gen signeddeg = npos - nneg
qui sum npos
assert r(sum) == 2 * 1435
qui sum nneg
assert r(sum) == 2 * 2261
qui sum signeddeg if party == "D"
assert abs(r(mean) - (-21.6)) < 0.05
qui sum signeddeg if party == "R"
assert abs(r(mean) - (-12.0)) < 0.05
qui sum npos if party == "D"
assert abs(r(mean) - 27.2) < 0.05
qui sum nneg if party == "R"
assert abs(r(mean) - 42.1) < 0.05

* smoke test of the plot
nwplot senate114, color(party)

* ---------------- senate93 ----------------
nwuse data/senate93, nwclear
nwset
assert `"`r(nets)'"' == " senate93"
nwsummarize senate93
assert r(nodes) == 101
assert r(edges) == 2439
count if party == "D"
assert r(N) == 57
count if party == "R"
assert r(N) == 42
count if party == "C" | party == "I"
assert r(N) == 2
nwrecode senate93 (-1 = 0), generate(s93pos)
nwsummarize s93pos
assert r(edges) == 581
nwrecode senate93 (1 = 0) (-1 = 1), generate(s93neg)
nwsummarize s93neg
assert r(edges) == 1858
nwbalance senate93
assert r(closed_triad) == 25355
assert r(balanced_triad) == 13947
assert r(unbalanced_triad) == 11408
assert abs(r(balance) - 0.5501) < 0.0005

* ---------------- gahuku ----------------
nwuse data/gahuku, nwclear
nwset
assert `"`r(nets)'"' == " gahuku"
nwsummarize gahuku
assert r(nodes) == 16
assert r(edges) == 58
assert r(minval) == -1 & r(maxval) == 1
nwrecode gahuku (-1 = 0), generate(gpos)
nwrecode gahuku (1 = 0) (-1 = 1), generate(gneg)
nwsummarize gpos
assert r(edges) == 29
nwsummarize gneg
assert r(edges) == 29
nwbalance gahuku
assert r(closed_triad) == 68
assert r(balanced_triad) == 59
assert r(unbalanced_triad) == 9
nwdegree gpos, generate(gp) silent
nwdegree gneg, generate(gn) silent
gen gs = gp - gn
qui sum gs
assert r(min) == -3 & r(max) == 7
* weakly balanced triads: all except the 2 with exactly one negative tie
* (7 of the 9 strongly unbalanced triads are all negative)
nwplot gahuku

di "PASS test_signed_data"
