* Saving long network names, the option directed of edge lists, two-mode UCINET files, nwkeep without a list, commands
* that keep the current network and the user's data, estimation results and networks.  Run from the repository root.
clear all
do unw_core.do
set seed 3

* networks with long names are saved and come back with their ties
foreach nm in friendship_wave1 a23456789012345 a234567890123456 n2345678901234567890123456789012 {
	nwclear
	mata: A = (0,1,0,0\0,0,1,0\0,0,0,1\1,1,0,0)
	nwset, mat(A) name(`nm') directed
	nwset, mat(A') name(second_`=substr("`nm'",1,20)') directed
	clear
	set obs 4
	gen wage = _n * 7
	local f "`c(tmpdir)'/nw_long"
	nwsave "`f'", replace
	assert wage[4] == 28
	nwclear
	nwuse "`f'", nwclear
	nwtomata `nm', mat(B)
	mata: assert(editmissing(B, 0) == A)
	nwtomata second_`=substr("`nm'",1,20)', mat(B)
	mata: assert(editmissing(B, 0) == A')
	assert wage[4] == 28
}
* a short and a long name, two-mode in the same file
nwclear
clear
set obs 3
gen str3 p = word("ann bob bob", _n)
gen str3 e = word("e1 e1 e2", _n)
nwset p e, twomode name(a_two_mode_network_long)
nwsave "`c(tmpdir)'/nw_long2", replace
nwclear
nwuse "`c(tmpdir)'/nw_long2", nwclear
nwsummarize a_two_mode_network_long
assert r(nodes) == 4 & r(edges) == 3

* option directed of an edge list: also a list with every tie reciprocated stays directed
nwclear
clear
set obs 2
gen str1 a = word("a b", _n)
gen str1 b = word("b a", _n)
export delimited using "`c(tmpdir)'/recip.csv", replace
foreach t in "type(edgelist, directed)" "type(edgelist) directed" "type(edgelist, delimiter(,) directed)" {
	nwimport "`c(tmpdir)'/recip.csv", `t' name(r) nwclear clear
	nwsummarize r
	assert "`r(directed)'" == "true"
}
nwimport "`c(tmpdir)'/recip.csv", type(edgelist) name(r) nwclear clear
nwsummarize r
assert "`r(directed)'" == "false"
nwimport "`c(tmpdir)'/recip.csv", type(edgelist, directed) forceundirected name(r) nwclear clear
nwsummarize r
assert "`r(directed)'" == "false"

* two-mode UCINET files: names with blanks, apostrophes and semicolons, an isolate, tie values
foreach valued in 0 1 {
	nwclear
	mata: B = (1,0,0\0,1,0\1,1,0)
	if `valued' mata: B = (5,0,0\0,2.5,0\1,-3,0)
	mata: M = J(6, 6, 0); M[|1,4 \ 3,6|] = B; M[|4,1 \ 6,3|] = B'
	mata: st_matrix("Bm", B)
	clear
	set obs 5
	gen str20 p = word("Ann~Lee Ann~Lee Bob~Jo O'Hara O'Hara", _n)
	gen str20 e = word("Red~Cross Red~Cross Club;A Red~Cross Club;A", _n)
	replace p = subinstr(p, "~", " ", .)
	replace e = subinstr(e, "~", " ", .)
	drop in 2
	gen w = cond(`valued', _n + 1, 1)
	nwset p e w, twomode name(tm)
	clear
	nwtoedge tm
	keep _ego _alter tm
	sort _ego _alter
	tempfile before
	save "`before'"
	nwexport tm, type(ucinet) fname("`c(tmpdir)'/tm") replace
	nwimport "`c(tmpdir)'/tm.dl", type(ucinet) name(back) nwclear clear
	nwsummarize back
	assert r(nodes) == 5 & r(edges) == 4 & "`r(mode2)'" == "true"
	clear
	nwtoedge back
	keep _ego _alter back
	rename back tm
	sort _ego _alter
	cf _all using "`before'"
	nwload back
	confirm variable _nwnode
	qui count if strpos(_nwnode, "z100") == 1
	assert r(N) == 0
}
* a file of another program: blank separated labels, an empty column (an isolate)
tempname fh
file open `fh' using "`c(tmpdir)'/other.dl", write replace
file write `fh' "dl nr=2 nc=3" _n "format = fullmatrix" _n "row labels:" _n "u v" _n "col labels:" _n `""x one" y z"' _n "data:" _n "1 0 0" _n "1 1 0" _n
file close `fh'
nwimport "`c(tmpdir)'/other.dl", type(ucinet) name(o) nwclear clear
nwsummarize o
assert r(nodes) == 5 & r(edges) == 3

* nwkeep without a list is refused
nwclear
nwrandom 4, prob(.5) name(u)
nwrandom 4, prob(.5) name(w)
local empty ""
capture noisily nwkeep `empty'
assert _rc == 198
qui nwds
assert "`r(netlist)'" == "u w"

* a failed command leaves the current network as it was (a command that works makes the analysed network current,
* see test_core_directed)
foreach c in "nwcorrelate u, attribute(nosuch)" "nwhierarchy u, badopt" "nwhierarchy u, linkage(bogus)" {
	nwclear
	clear
	nwrandom 6, prob(.6) name(u) undirected
	nwrandom 6, prob(.6) name(w) undirected
	capture `c'
	local rc = _rc
	assert `rc' != 0
	nwcurrent
	if "`r(current)'" != "w" {
		di as err "current network is `r(current)' after `c' (rc `rc')"
		exit 9
	}
}
* and a successful one still returns its results
nwclear
nwrandom 6, prob(.6) name(u) undirected
nwrandom 6, prob(.6) name(w) undirected
nwcorrelate u w
assert r(corr) < .

* a failed nwcollapse: data, networks and the current network as before
nwclear
clear
nwrandom 6, prob(.6) name(u)
nwrandom 6, prob(.6) name(w)
clear
set obs 6
gen grp = mod(_n, 2)
gen wage = _n
foreach c in "nwcollapse u, by(grp) badopt" "nwcollapse u, by(grp) generate(w)" "nwcollapse u, by(nosuch)" {
	capture noisily `c'
	assert _rc != 0
	assert _N == 6 & wage[6] == 6
	qui nwds
	assert "`r(netlist)'" == "u w"
	nwcurrent
	assert "`r(current)'" == "w"
}
nwcollapse u, by(grp) generate(uc)
nwname uc
assert r(nodes) == 2

* nwdyadprob leaves a network called _tempdyad alone
nwclear
mata: W = J(5, 5, .5); _diag(W, 0)
nwset, mat(W) name(w) directed
nwset, mat(W) name(_tempdyad) directed
nwdyadprob w, density(.5) name(r)
nwname _tempdyad
assert r(nodes) == 5

* nwplot, layout(mds) leaves the estimation results
nwclear
sysuse auto, clear
quietly regress price weight
nwrandom 8, prob(.5) name(g) undirected
nwplot g, layout(mds)
assert "`e(cmd)'" == "regress"
assert e(N) == 74

* Pajek files with blank and comment lines
tempname fh
local p "`c(tmpdir)'/blank.net"
file open `fh' using "`p'", write replace
file write `fh' "% a comment" _n "*Vertices 3" _n `"1 "a""' _n `"2 "b""' _n _n `"3 "c""' _n "   " _n "*Edges" _n "% another" _n "1 2" _n _n "2 3" _n "1 3" _n
file close `fh'
nwimport "`p'", type(pajek) name(pj) nwclear clear
nwsummarize pj
assert r(nodes) == 3 & r(edges) == 3
* the level labels of a two-mode Pajek file still come back
nwclear
clear
set obs 3
gen str3 who = word("x y x", _n)
gen str3 what = word("e e f", _n)
nwset who what, twomode name(tm)
nwname tm
nwexport tm, type(pajek) fname("`c(tmpdir)'/tmp_pj") replace
nwimport "`c(tmpdir)'/tmp_pj.net", type(pajek) name(back) nwclear clear
nwsummarize back
assert r(nodes) == 4 & r(edges) == 3 & "`r(mode2)'" == "true"

* nwmovie: option values, fname() with .html, files of the user
nwclear
clear
mata: A = (0,1,0\0,0,1\0,0,0)
nwset, mat(A) name(w1) directed
mata: A = (0,1,1\0,0,1\0,0,0)
nwset, mat(A) name(w2) directed
foreach o in "duration(0)" "duration(-5)" "speed(0)" "speed(-1)" "window(0)" "window(-2)" "window(abc)" "easing(bogus)" "easing(ease-in-out-bounce)" {
	capture noisily nwmovie w1 w2, noopen fname("`c(tmpdir)'/mv_bad") `o'
	assert _rc == 198
}
capture confirm file "`c(tmpdir)'/mv_bad.html"
assert _rc == 601
local m "`c(tmpdir)'/mv_ok"
capture erase "`m'.html"
nwmovie w1 w2, noopen fname("`m'.html") easing(ease-in-out-sine)
confirm file "`m'.html"
capture confirm file "`m'.html.html"
assert _rc == 601
* its own page is written over
nwmovie w1 w2, noopen fname("`m'") easing(linear)
* any other file only with replace
file open `fh' using "`c(tmpdir)'/mine.html", write replace
file write `fh' "<p>my page</p>" _n
file close `fh'
capture noisily nwmovie w1 w2, noopen fname("`c(tmpdir)'/mine")
assert _rc == 602
mata: assert(cat(st_global("c(tmpdir)") + "/mine.html") == "<p>my page</p>")
nwmovie w1 w2, noopen fname("`c(tmpdir)'/mine") replace

* a failed nwdegree or nwcorrelate leaves no partial result
nwclear
clear
nwrandom 5, prob(.5) name(u) undirected
nwrandom 5, prob(.5) name(g) undirected
clear
set obs 5
gen wage = _n
capture noisily nwdegree u g, generate(zz) badopt
assert _rc == 198
unab vars : _all
assert "`vars'" == "wage"
capture noisily nwcorrelate u, attribute(nosuch)
assert _rc != 0
capture confirm variable _nwinclude, exact
assert _rc == 111
nwdegree u g, generate(zz)
confirm variable zz_u zz_g wage
* also when the caller has preserved the data
capture program drop _nw_outer
program _nw_outer
	preserve
	nwdegree u, generate(inner)
	confirm variable inner
end
_nw_outer
capture confirm variable inner
assert _rc == 111
preserve
nwdegree u, generate(inner2)
confirm variable inner2
restore

* matrix files with empty cells: distances without names, and "empty = no tie" with a node without ties
capture program drop wl
program wl
	args path
	tempname fh
	file open `fh' using "`path'", write replace
	macro shift
	while `"`1'"' != "" {
		file write `fh' `"`1'"' _n
		macro shift
	}
	file close `fh'
end
local d "`c(tmpdir)'"
wl "`d'/dist.csv" ",1,2" "1,,3" "2,3,"
nwimport "`d'/dist.csv", type(matrix) name(m) nwclear clear
nwtomata m, mat(X)
mata: assert(rows(X) == 3 & X[1,2] == 1 & X[1,3] == 2 & X[2,3] == 3)
wl "`d'/iso.csv" ",1," "1,," ",,"
nwimport "`d'/iso.csv", type(matrix) name(m) nwclear clear
nwsummarize m
assert r(nodes) == 3 & r(edges) == 1
wl "`d'/iso1.csv" ",," ",,1" ",1,"
nwimport "`d'/iso1.csv", type(matrix) name(m) nwclear clear
nwtomata m, mat(X)
mata: assert(rows(X) == 3 & editmissing(X, 0) == (0,0,0\0,0,1\0,1,0))
* trailing empty line and column of a spreadsheet are still dropped
wl "`d'/excel.csv" ",a,b," "a,0,1," "b,1,0," ",,,"
nwimport "`d'/excel.csv", type(matrix) name(m) nwclear clear
nwsummarize m
assert r(nodes) == 2 & r(edges) == 1

* commands with option xvars work when the data hold variables of the user with the node names, and keep them
foreach c in "nwgeodesic a, xvars" "nwreach a, xvars" "nwsimilar a, xvars" "nwexpand x1, name(e) xvars" "nwpermute a, replace xvars" "nwdropnodes a, nodes(x2) xvars" "nwreplacemat a, newmat(J(4,4,1)) xvars" "nwlambda a, sym xvars" {
	nwclear
	clear
	set obs 4
	forvalues i = 1/4 {
		gen x`i' = _n == mod(`i', 4) + 1
	}
	gen wage = _n * 10
	nwset x1 x2 x3 x4, name(a)
	* make the variables differ from the ties
	replace x1 = 7 in 1
	capture noisily `c'
	local rc = _rc
	if `rc' != 0 {
		di as err "`c' -> `rc'"
		exit `rc'
	}
	* the values of the user are still there
	qui count if x1 == 7 & wage == 10
	assert r(N) == 1
	qui count if wage == 40
	assert r(N) == 1
}
* a direct nwload still stops
nwclear
clear
set obs 3
gen n1 = 99
mata: M = (0,1,1\1,0,1\1,1,0)
nwset, mat(M) name(u)
capture noisily nwload u
assert _rc == 110 & n1[1] == 99

* import with xvars: the variable _nwinclude is there
wl "`d'/p.net" "*Vertices 3" `"1 "a""' `"2 "b""' `"3 "c""' "*Edges" "1 2" "2 3"
nwimport "`d'/p.net", type(pajek) name(abc) xvars nwclear clear
confirm variable _nwinclude a b c
assert _nwinclude[3] == 1 & b[1] == 1
nwload abc, overwrite
confirm variable _nwinclude

* a matrix imported into an empty data set: its variables follow later changes
wl "`d'/low.csv" ",a,b,c" "a,0,1,0" "b,0,0,1" "c,0,0,0"
nwimport "`d'/low.csv", type(matrix) name(low) nwclear clear
nwsym low
assert a[2] == 1 & b[1] == 1

* UCINET files with tabs
local t = char(9)
wl "`d'/tab.dl" "dl n=3`t'format=edgelist1" "labels:" "a`t'b`t'c" "data:" "1`t'2" "2`t'3"
nwimport "`d'/tab.dl", type(ucinet) name(m) nwclear clear
nwsummarize m
assert r(nodes) == 3 & r(arcs) == 2
wl "`d'/tabf.dl" "dl n=3" "format = fullmatrix" "data:" "0`t'1`t'1" "1`t'0`t'1" "1`t'1`t'0"
nwimport "`d'/tabf.dl", type(ucinet) name(m) nwclear clear
nwsummarize m
assert r(nodes) == 3 & r(edges) == 3

display "PASS test_edge_gaps"
