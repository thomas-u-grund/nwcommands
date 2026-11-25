* Commands must not damage what they were not asked to change: other networks, other data, matrices; and a command
* that fails leaves the data as they were.  Plus tie handling: missing ties are no ties; two-mode full edge lists;
* derived networks are not temporal.  Run from the repository root.
clear all
do unw_core.do
set seed 1

* resizing one network leaves the others as they are
foreach how in drop keep mat {
	nwclear
	clear
	mata: U = (0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)
	mata: G = (0,1,1,0\0,0,1,0\0,0,0,1\1,0,0,0)
	nwset, mat(U) name(u) undirected
	nwset, mat(G) name(g) directed
	if "`how'" == "drop" nwdropnodes u, nodes(4)
	if "`how'" == "keep" nwkeepnodes u, nodes(1 2 3)
	if "`how'" == "mat" {
		mata: S = (0,1\1,0)
		nwreplacemat u, newmat(S)
	}
	nwsummarize g
	assert "`r(directed)'" == "true"
	nwtomata g, mat(after)
	mata: assert(editmissing(after, 0) == G)
}

* nwkeep: a condition that no node meets is refused; data and networks stay
nwclear
clear
nwrandom 5, prob(.5) name(u)
nwrandom 4, prob(.5) name(w)
datasignature set, reset
capture noisily nwkeep u if _n > 99
assert _rc == 2000
datasignature confirm
nwsummarize u
assert r(nodes) == 5
qui nwds
assert "`r(netlist)'" == "u w"
nwkeep u if _n <= 3
nwsummarize u
assert r(nodes) == 3

* nwhierarchy: extra observations survive success and failure; the user's matrix mymat stays
nwclear
clear
nwrandom 5, prob(.6) name(u) undirected
clear
set obs 9
gen wage = _n
matrix mymat = (1, 2, 3)
foreach opts in "linkage(bogus)" "badopt" "groups(2)" {
	capture noisily nwhierarchy u, `opts'
	assert _rc != 0
	assert _N == 9 & wage[9] == 9
	capture confirm variable _clus_1_id
	assert _rc != 0
}
nwhierarchy u, linkage(averagelinkage)
qui summarize wage
assert r(N) == 9 & r(sum) == 45
assert colsof(mymat) == 3 & mymat[1,3] == 3

* nwfromedge: no matching rows leaves the data
foreach opt in "" ", noclear" {
	nwclear
	clear
	set obs 5
	gen a = _n
	gen b = _n + 1
	gen wage = _n
	capture noisily nwfromedge a b if wage > 100 `opt'
	assert _rc != 0
	assert _N == 5 & c(k) == 3 & wage[5] == 5
}
nwfromedge a b if wage < 3, noclear name(z)
qui summarize wage
assert r(N) == 5 & r(sum) == 15

* nwdropnodes, attributes(): numeric and string; unrelated observations untouched
foreach gen in "" "generate(newu)" {
	nwclear
	clear
	mata: U = (0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)
	nwset, mat(U) name(u) undirected labs(n1,n2,n3,n4)
	set obs 8
	gen income = _n * 10
	gen str3 town = "t" + string(_n)
	nwdropnodes u, nodes(n1) attributes(income town) `gen'
	foreach i of numlist 2/4 {
		assert income == `i' * 10 & town == "t`i'" if _nwnode == "n`i'"
	}
	assert missing(income) & town == "" in 4
	foreach i of numlist 5/8 {
		assert income[`i'] == `i' * 10
		assert town[`i'] == "t`i'"
	}
}

* nwspmatrix refuses to replace a variable _ID of the user
nwclear
clear
nwrandom 5, prob(.6) name(u) undirected
clear
set obs 5
gen _ID = 5000 + _n
capture noisily nwspmatrix u, name(Wm)
assert _rc == 110
assert _ID[5] == 5005

* nw2set from variables keeps the other variables with the nodes of the second mode (the rows)
nwclear
clear
set obs 6
gen m1 = mod(_n, 2)
gen m2 = mod(_n, 3) == 0
gen id = _n
gen str3 who = "r" + string(_n)
nw2set m1 m2, name(bb)
assert _N == 8
forvalues i = 1/6 {
	assert id == `i' & who == "r`i'" in `=`i' + 2'
}
assert missing(id) in 1/2

* nwutility does not overwrite variables without replace
nwclear
clear
nwrandom 5, prob(.6) name(u) undirected
clear
set obs 5
gen _util = 77
capture noisily nwutility u
assert _rc == 110 & _util[1] == 77
nwutility u, replace
assert _util[1] != 77

* a failed nwcollapse leaves no working network behind
nwclear
clear
nwrandom 6, prob(.6) name(u)
set obs 6
gen grp = mod(_n, 2)
capture noisily nwcollapse u, by(grp) badopt
assert _rc != 0
qui nwds
assert "`r(netlist)'" == "u"

* nwdyadprob: a missing probability is no tie
nwclear
clear
mata: W = J(4, 4, 0)
mata: W[1,2] = .
mata: W[2,1] = .
mata: W[3,4] = 1
nwset, mat(W) name(w) directed
nwdyadprob w, name(r)
nwtomata r, mat(R)
mata: assert(sum(editmissing(R, 0)) == 1 & R[3,4] == 1)

* nwmixing: permutation p-value is the same with missing ties as with zeros
foreach v in 0 . {
	nwclear
	clear
	mata: P = J(6, 6, 0)
	mata: for (i=1; i<=5; i++) P[i,i+1] = P[i+1,i] = 1
	mata: P[1,3] = P[3,1] = 1
	mata: P[1,6] = P[6,1] = P[2,5] = P[5,2] = `v'
	nwset, mat(P) name(p) undirected
	clear
	set obs 6
	gen g = _n <= 3
	set seed 5
	nwmixing p, attribute(g) permutations(2000)
	local p`=cond("`v'" == "0", "zero", "miss")' = r(EI_pvalue)
}
assert `pzero' < . & abs(`pzero' - `pmiss') < 1e-12

* nw2toedge, full lists each tie once in each direction; without full the first mode is the sender
nwclear
clear
mata: T = (1,1,0\0,1,1)
nw2set, mat(T) name(tm)
preserve
nwtoedge tm, full
duplicates report _ego _alter
assert r(unique_value) == r(N)
restore
preserve
nwtoedge tm
assert _nwmode_ego != _nwmode_alter & _nwmode_ego == _nwmode_ego[1] & _nwmode_alter == _nwmode_alter[1]
restore

* a network whose ties are changed is no longer temporal; the source of a derived network stays temporal
foreach cmd in "nwtranspose u" "nwsym u" "nwpermute u, replace" "nwreplace u = u" "nwdichotomize u, threshold(2)" {
	nwclear
	clear
	set obs 3
	gen str1 a = word("a b b", _n)
	gen str1 b = word("b a c", _n)
	gen wave = _n
	nwset a b, time(wave) name(u) directed
	nwduplicate u, name(src)
	`cmd'
	nwsummarize u
	assert "`r(temporal)'" != "true"
	capture noisily nwattime u, at(3) name(u3)
	assert _rc != 0 & _rc != 3200
	nwattime src, at(3) name(s3)
}

* nwsync, and the commands that use it, never drop or overwrite the user's own variables with the node names
nwclear
clear
set obs 3
gen x1 = cond(_n == 2, 1, 0)
gen x2 = cond(_n == 3, 1, 0)
gen x3 = 0
nwset x1 x2 x3, name(own) directed
foreach cmd in "nwsync own" "nwsym own" "nwreplace own = own * 5" {
	`cmd'
	assert x1[2] == 1 & x1[1] == 0 & x1[3] == 0 & x2[3] == 1 & x2[1] == 0 & x3[1] == 0 & x3[2] == 0
}
* copies made by nwload still follow the network
nwclear
clear
mata: P = (0,1,0\1,0,0\0,0,0)
nwset, mat(P) name(p) undirected
nwload p
nwreplace p = p * 5
qui summarize n1
assert r(sum) == 5

* a failed nwwebuse with nwclear keeps data and networks
nwclear
clear
set obs 4
gen wage = _n
nwrandom 4, prob(.5) name(kept)
local __old "$nwwebpath"
nwwebuse set `c(tmpdir)'/nw_no_such_folder
capture nwwebuse nothing, nwclear
assert _rc != 0
global nwwebpath "`__old'"
assert wage[4] == 4
nwname kept

* networks that must stay temporal: undirected ones when created, after dropping nodes, copying, saving and loading
nwclear
clear
set obs 3
gen str1 a = word("a b c", _n)
gen str1 b = word("b c a", _n)
gen wave = _n
nwset a b, time(wave) name(u) undirected
nwsummarize u
assert "`r(temporal)'" == "true"
nwduplicate u, name(copy)
nwsummarize copy
assert "`r(temporal)'" == "true"
nwdropnodes u, nodes(c)
nwsummarize u
assert "`r(temporal)'" == "true"
nwattime u, at(1) name(u1)
nwsummarize u1
assert r(edges) == 1
tempfile tf
nwsave "`tf'", replace
nwclear
nwuse "`tf'", nwclear
nwsummarize copy
assert "`r(temporal)'" == "true"

* commands that leave the ties as they are keep the network temporal
nwclear
clear
set obs 3
gen str1 a = word("a b c", _n)
gen str1 b = word("b c a", _n)
gen wave = _n
nwset a b, time(wave) name(u) undirected
nwtranspose u
nwsym u
nwdichotomize u, threshold(.5)
nwsummarize u
assert "`r(temporal)'" == "true"
clear
set obs 3
gen str1 a = word("a b c", _n)
gen str1 b = word("b c a", _n)
gen wave = _n
nwset a b, time(wave) name(d) directed
nwsym d, generate(ds)
nwsummarize d
assert "`r(temporal)'" == "true"
nwsummarize ds
assert "`r(temporal)'" != "true"

* interactive page: missing values of color() and size() give valid JavaScript
nwclear
clear
nwrandom 4, prob(.6) name(a) undirected
clear
set obs 4
gen col = _n if _n > 1
gen sz = _n if _n < 4
nwplot a, interactive noopen color(col) size(sz)

display "PASS test_edge_state"
