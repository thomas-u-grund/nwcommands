cscript

do unw_core.do

* stack three directed networks of 3, 2 and 4 nodes
nwclear
matrix A = (0,1,0\0,0,1\1,0,0)
matrix B = (0,1\1,0)
matrix C = (0,0,1,0\1,0,0,0\0,1,0,1\0,0,0,0)
nwset, mat(A) directed name(a) nooutput
nwset, mat(B) directed name(b) nooutput
nwset, mat(C) directed name(c) nooutput
clear
nwstack a b c, name(abc) group(g)
assert r(k) == 3
assert r(N) == 9
assert _N == 9
count if g == 1
assert r(N) == 3
count if g == 2
assert r(N) == 2
count if g == 3
assert r(N) == 4
nwsummarize abc
assert r(arcs) == 3 + 2 + 4
assert `"`r(directed)'"' == "true"
assert r(nodes) == 9

* the ties sit in the diagonal blocks and nowhere else
nwtomata abc, mat(M)
mata: st_numscalar("outside", sum(M[1..3, 4..9]) + sum(M[4..5, (1..3, 6..9)]) + sum(M[6..9, 1..5]))
assert scalar(outside) == 0

* an existing name needs replace
capture nwstack a b c, name(abc)
assert _rc == 110
nwstack a b c, name(abc) replace

* a mix of directed and undirected networks is refused
nwset, mat(B) undirected name(u) nooutput
capture nwstack a u, name(au)
assert _rc == 198

* data of the wrong length are refused
clear
set obs 5
capture nwstack a b c, name(x1) group(g)
assert _rc == 198

display "test_nwstack passed"
