* Edge cases found before the article (Nov 2026): each assert fails on 3.36.1.
* Run from the repository root (see RELEASING.md C0).
clear all
set more off
set seed 1

* E-I index of nwtabulate: all ties between the two groups gives +1, as in nwmixing; all within gives -1
mata: P = (0,0,1,1 \ 0,0,1,1 \ 1,1,0,0 \ 1,1,0,0)
nwset, mat(P) name(p) undirected
gen g = cond(_n < 3, 1, 2)
nwtabulate p, attribute(g)
assert r(EI_index) == 1
nwclear
mata: W = (0,0,1,0 \ 0,0,0,1 \ 0,0,0,0 \ 0,0,0,0)
nwset, mat(W) name(d) directed
gen g = cond(_n < 3, 1, 2)
nwtabulate d, attribute(g)
assert r(EI_index) == 1

* nwreplace does not allow in
nwclear
mata: M = (0,1,1 \ 1,0,1 \ 1,1,0)
nwset, mat(M) name(a)
capture nwreplace a = 0 in 1/1
assert _rc == 101
nwtomata a, mat(X)
mata: assert(sum(X) == 6)

* nwrandom checks its input
foreach o in "prob(2)" "prob(-1)" "density(1.5)" "prob(.5) density(.5)" "prob(.5) ntimes(0)" {
	capture nwrandom 5, `o'
	assert _rc == 198
}
capture nwrandom 2.5, prob(.5)
assert _rc == 198
nwrandom 5, prob(1) name(full)

* a result named like the input network does not delete it
nwclear
mata: L = (0,1,0 \ 0,0,1 \ 1,0,0)
nwset, mat(L) name(u)
nwset, mat(L) name(keep)
foreach c in "nwcorrelate u, name(u)" "nwgeodesic u, name(u) nwreplace" "nwreach u, name(u) nwreplace" "nwshared u, name(u) replace undirected" {
	capture `c'
	assert _rc == 483
	capture nwname u
	assert _rc == 0
}
capture nwcorrelate u, name(keep)
assert _rc == 483
nwcorrelate u, name(keep) replace
nwcorrelate u
nwcorrelate u

* nwuse keeps a changed data set
tempfile s
nwclear
nwset, mat(L) name(s)
nwsave `s', replace
nwclear
clear
set obs 10
gen precious = _n
capture nwuse `s'
assert _rc == 4
confirm variable precious
nwuse `s', nwclear
nwclear
clear
nwuse `s'
nwuse `s', nwclear

* distances above 1: a valued network; nwreach leaves no placeholder results
nwclear
mata: D = (0,1,0,0 \ 0,0,1,0 \ 0,0,0,1 \ 0,0,0,0)
nwset, mat(D) name(path) directed
nwgeodesic path
nwname _geodesic
assert "`r(valued)'" == "true"
nwreach path
assert r(radius) == . & r(avgpath) == .

* network expressions: minus and not without blanks
nwclear
nwset, mat(M) name(a)
local i 0
foreach x in "1-a" "1 - a" "a-1" "0-a" "(1-a)" "-a" "!a" "a~=0" "1e-1*a" "exp(-1*a)" "exp((-1)*a)" "a*(-1)" "a - -1" {
	local ++i
	nwgen e`i' = `x'
}
nwtomata e1, mat(X)
mata: _diag(X, 0); assert(sum(abs(X)) == 0)
nwtomata e13, mat(X)
mata: _diag(X, 0); assert(sum(X) == 12)

* import: any file name
nwclear
nwset, mat(M) name(e)
local f "`c(tmpdir)'/my-net"
nwexport e, type(gml) fname(`f') replace
nwclear
nwimport `f'.gml, type(gml)
nwname my_net
capture nwname _value
assert _rc != 0

* plot export(file, replace)
nwdegree my_net, generate(deg) plot export("`c(tmpdir)'/edge.png", replace)

* nwdrop of every node is refused and keeps the network
nwclear
nwset, mat(M) name(a)
capture nwdrop a if _n > 0
assert _rc == 198
nwname a
assert r(nodes) == 3

* clear input errors instead of crashes
capture nwrandom -3, prob(.5)
assert _rc == 198
capture nwlattice -1 -1
assert _rc == 198
capture nwlattice 0 3
assert _rc == 198
capture nwpref 10, m0(20) m(2)
assert _rc == 198
nwlattice 3 3
nwpref 10
clear
nwclear
set obs 3
gen str1 s1 = "a"
gen s2 = 1
gen s3 = 0
capture nwset s1 s2 s3, name(q)
assert _rc == 109
clear
gen str1 ego = ""
gen str1 alter = ""
drop if _n > 0
capture nwfromedge ego alter
assert _rc == 2000
set obs 1
replace ego = "a"
replace alter = "b"
gen str1 w = "x"
capture nwfromedge ego alter w
assert _rc == 109

* nwegoplot with more observations than nodes
nwclear
clear
nwrandom 5, prob(1) name(r5) undirected
set obs 12
nwegoplot r5, ego(1)

* nwset, clear with no network loaded
nwclear
clear
set obs 3
gen v1 = 0
gen v2 = 1
gen v3 = 1
nwset v1 v2 v3, clear
nwset, clear
nwset, clear

* reserved words are not network names
nwclear
nwset, mat(M) name(a)
foreach n in _all _n if in byte str5 _nwnode {
	capture nwset, mat(M) name(`n')
	assert _rc != 0
	capture nwrename a `n'
	assert _rc != 0
	capture nwduplicate a, name(`n')
	assert _rc != 0
}
nwds
assert "`r(netlist)'" == "a"
capture nwgen b = 2
assert _rc == 198
nwclear

* undirected table by attribute: the same cells whatever the node order
mata: U = (0,1 \ 1,0)
clear
nwset, mat(U) name(u1) undirected
gen g = cond(_n == 1, 1, 2)
nwtabulate u1, attribute(g) permutations(1)
matrix A = r(table)
local ca = colsof(A)
replace g = cond(_n == 1, 2, 1)
nwtabulate u1, attribute(g) permutations(1)
matrix B = r(table)
assert mreldif(A, B) == 0
matrix C = r(row)
assert C[1,1] == 1

* constraint warns about negative ties
nwclear
clear
mata: N = (0,-1,1 \ -1,0,1 \ 1,1,0)
nwset, mat(N) name(neg) undirected
nwconstraint neg

* plot export(file, replace)
nwclear
clear
nwrandom 5, prob(1) name(r5) undirected
nwplot r5, export("`c(tmpdir)'/edge2.png", replace)
nwplot r5, export(`c(tmpdir)'/edge2.png, replace)

* hierarchy with more observations than nodes: the other rows stay
nwclear
clear
mata: H = J(2,2,0) :+ 0; H = (J(4,4,1), J(4,4,0) \ J(4,4,0), J(4,4,1)) - I(8); H[4,5] = 1; H[5,4] = 1
nwset, mat(H) name(h) undirected
set obs 12
gen row = _n
nwhierarchy h, groups(2) generate(role)
assert _N == 12
confirm variable role
assert missing(role) if row > 8

* an edge list with a single line can be read back
nwclear
clear
mata: M = (0,1,0 \ 1,0,0 \ 0,0,0)
nwset, mat(M) name(one) undirected labs(a,b,c)
nwexport one, type(edgelist) fname("`c(tmpdir)'/edge_one") replace
nwclear
nwimport "`c(tmpdir)'/edge_one.txt", type(edgelist) name(back)
nwsummarize back
assert r(nodes) == 2

di "PASS test_edge_article"
