* xt_data_01_nwset.do
* Extended tests of nwset, mat(): sizes 0/1/2, a 2,000-node network with long labels, labels (spaces,
* non-ASCII, long, duplicates, too few), valued/unvalued/directed/undirected flags and their combinations,
* tie values (negative, non-integer, zero, missing), name() in use with and without replace, error paths that
* must leave data and networks unchanged, many networks in memory, the data rows under new networks.
* All expected numbers are derived by hand on tiny matrices; no number comes from a run.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_01_nwset
set seed 20261112

* --- A. one node, two nodes, zero nodes
nwclear
nwset, mat(0) name(one)
quietly nwname one
xt_chk `=(r(nodes) == 1)' "1 node: r(nodes) == 1"
nwtomata one, mat(__xt_M)
mata: st_local("dim", strofreal(rows(__xt_M)) + "x" + strofreal(cols(__xt_M)))
xt_chk `=("`dim'" == "1x1")' "1 node: nwtomata gives a 1x1 matrix (got `dim')"
quietly nwsummarize one
xt_chk `=(r(nodes) == 1)' "1 node: nwsummarize r(nodes) == 1"

nwset, mat(1) selfloop name(oneloop)
quietly nwname oneloop
xt_chk `=("`r(selfloop)'" == "true")' "1 node with selfloop: r(selfloop) == true"
nwtomata oneloop, mat(__xt_M)
mata: st_local("v", strofreal(__xt_M[1, 1]))
xt_chk `=("`v'" == "1")' "1 node with selfloop: the self-tie is kept (got `v')"

nwset, mat((0,1\0,0)) name(two)
quietly nwname two
xt_chk `=(r(nodes) == 2 & "`r(directed)'" == "true")' "2 nodes, one arc: directed"
xt_mat two __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,1\0,0)))
xt_chk `ok' "2 nodes: matrix (0,1 \ 0,0) kept"

nwset, mat((0,1\1,0)) name(twou) undirected
quietly nwname twou
xt_chk `=("`r(directed)'" == "false")' "2 nodes, undirected option: r(directed) == false"

xt_snap s0
capture noisily nwset, mat(J(0,0,.)) name(zero)
xt_chk `=(_rc == 198)' "0 x 0 matrix refused with r(198) (got `=_rc')"
xt_same s0 "0 x 0 matrix"
di "PASS A sizes"

* --- B. errors after name() with replace must not cost the existing network
capture program drop xt_01_reset
program xt_01_reset
	nwclear
	nwset, mat((0,1,0\1,0,1\0,1,0)) name(keepme) undirected
	nwset, mat((0,1\0,0)) name(other)
	xt_snap s1
end
xt_01_reset
capture noisily nwset, mat(J(2,3,0)) name(keepme) replace
xt_chk `=(_rc == 198)' "non-square mat() refused with r(198) (got `=_rc')"
xt_same s1 "non-square mat() with replace: keepme must survive" // was bug S1 (fixed)
xt_01_reset
capture noisily nwset, mat(J(3,3,0)) name(keepme) labs(a,b,a) replace
xt_chk `=(_rc == 198)' "duplicate labels refused with r(198) (got `=_rc')"
xt_same s1 "duplicate labels with replace: keepme must survive" // was bug S1 (fixed)
xt_01_reset
capture noisily nwset, mat(J(3,3,0)) name(keepme)
xt_chk `=(_rc == 483)' "name() in use without replace: r(483) (got `=_rc')"
xt_same s1 "name() in use without replace"
capture noisily nwset, mat(J(3,3,0)) name(newnet) vars(a b)
xt_chk `=(_rc == 6070)' "vars() with the wrong number of names: r(6070) (got `=_rc')"
xt_same s1 "vars() of the wrong length: no half-made network left" // was bug S2 (fixed)
xt_01_reset
mata: __xt_nn = ("a", "b")
capture noisily nwset, mat(J(3,3,0)) name(newnet2) nodenames(__xt_nn)
if _rc != 0 {
	xt_same s1 "nodenames() of the wrong length refused: nothing changed"
}
else {
	quietly nwname newnet2
	mata: st_local("u", strofreal(xt_nuniq(st_global("r(labs)"))))
	xt_chk `=(r(nodes) == 3 & "`u'" == "3")' "nodenames() of the wrong length: 3 nodes with 3 distinct labels" // was bug S2 (fixed)
	nwdrop newnet2
}
* replace that works: the new matrix, same name, other network untouched
nwset, mat(J(4,4,1)) name(keepme) replace
quietly nwname keepme
xt_chk `=(r(nodes) == 4)' "replace: keepme now has 4 nodes"
xt_hasnet other
xt_chk `has' "replace: the other network is still there"
di "PASS B replace and errors"

* --- C. default name in use gets a new name (documented), explicit name does not
nwclear
nwset, mat(J(2,2,0))
nwset, mat(J(2,2,0))
xt_hasnet network
xt_chk `has' "default name: network"
xt_hasnet network_1
xt_chk `has' "default name in use: the second one is network_1"
di "PASS C default names"

* --- D. labels
nwclear
local long = "abcdefghij" * 8
nwset, mat(J(3,3,0)) labs(Anna Maria,Zoë,`long') name(lab)
quietly nwname lab
xt_chk `=(`"`r(labs)'"' == `"Anna Maria,Zoë,`long'"')' "labels with a space, a non-ASCII letter and 80 characters kept"
* fewer labels than nodes: the padded default names must not collide with a given label (owner's decision on
* S4: only unused default names; node 2 gets n4, the next unused name above the number of nodes)
capture noisily nwset, mat(J(3,3,0)) labs(n2) name(pad)
xt_chk `=(_rc == 0)' "labs(n2) for 3 nodes: accepted (got `=_rc')"
if _rc == 0 {
	quietly nwname pad
	xt_chk `=("`r(labs)'" == "n2,n4,n3")' "labs(n2) for 3 nodes: n2,n4,n3 (got `r(labs)')"
}
* a real duplicate in labs() is still refused
capture noisily nwset, mat(J(3,3,0)) labs(a,b,a) name(pad2)
xt_chk `=(_rc == 198)' "labs(a,b,a): repeated label refused with 198 (got `=_rc')"
* more labels than nodes: extra ignored
nwset, mat(J(2,2,0)) labs(p,q,r) name(extra)
quietly nwname extra
xt_chk `=("`r(labs)'" == "p,q")' "more labels than nodes: the extra labels are ignored"
* labsfromvar() with a numeric variable
nwclear
set obs 3
gen id = 10 * _n
nwset, mat(J(3,3,0)) labsfromvar(id) name(lv)
quietly nwname lv
xt_chk `=("`r(labs)'" == "10,20,30")' "labsfromvar(): labels from the variable (got `r(labs)')" // was bug N1 (fixed)
capture confirm numeric variable id
xt_chk `=(_rc == 0)' "labsfromvar() must not turn the user's numeric variable into a string" // was bug S3 (fixed)
di "PASS D labels"

* --- E. flags: valued, directed, and option pairs that contradict each other
nwclear
nwset, mat((0,2\1,0)) name(v2)
quietly nwname v2
xt_chk `=("`r(valued)'" == "true")' "a value 2 makes the network valued"
nwset, mat((0,1\1,0)) name(b2)
quietly nwname b2
xt_chk `=("`r(valued)'" == "false")' "0/1 values: binary"
nwset, mat((0,1\1,0)) name(b2v) valued
quietly nwname b2v
xt_chk `=("`r(valued)'" == "true")' "option valued on 0/1 values: valued"
nwset, mat((0,2\3,0)) name(v2u) unvalued
quietly nwname v2u
xt_chk `=("`r(valued)'" == "false")' "option unvalued: binary flag"
xt_mat v2u __xt_M
mata: st_local("s", strofreal(sum(__xt_M)))
xt_chk `=("`s'" == "5")' "option unvalued keeps the stored values (sum 5, got `s')"
nwset, mat((0,1\0,0)) name(dflt)
quietly nwname dflt
xt_chk `=("`r(directed)'" == "true")' "asymmetric matrix: directed"
xt_snap s2
capture noisily nwset, mat((0,1\0,0)) name(both) directed undirected
xt_chk `=(_rc == 198)' "[policy] directed and undirected together refused with 198 (got `=_rc')"
if _rc == 0 nwdrop both
capture noisily nwset, mat((0,1\0,0)) name(both2) valued unvalued
xt_chk `=(_rc == 198)' "[policy] valued and unvalued together refused with 198 (got `=_rc')"
if _rc == 0 nwdrop both2
xt_same s2 "contradicting option pairs"
di "PASS E flags"

* --- F. tie values: negative, non-integer, missing; undirected on an asymmetric matrix
nwclear
nwset, mat((0,-1.5,.\.25,0,0\0,0,0)) name(vals)
nwtomata vals, mat(__xt_V)
mata: st_local("ok", strofreal(__xt_V[1,2] == -1.5 & __xt_V[2,1] == .25))
xt_chk `ok' "negative and non-integer values kept exactly"
mata: st_local("ok", strofreal(__xt_V[1,3] >= .))
xt_chk `ok' "a missing cell stays missing"
quietly nwname vals
xt_chk `=("`r(valued)'" == "true")' "negative values: valued"
nwset, mat((0,1,0\0,0,0\0,0,0)) name(usym) undirected
xt_mat usym __xt_U
mata: st_local("ok", strofreal(__xt_U == __xt_U' & sum(__xt_U) == 2))
xt_chk `ok' "undirected on an asymmetric matrix: symmetric, one edge (2 cells)"
matrix XTA = (0,1\1,0)
nwset, mat(XTA) name(fromstata)
quietly nwname fromstata
xt_chk `=(r(nodes) == 2)' "mat() takes a Stata matrix"
matrix drop XTA
di "PASS F values"

* --- G. the data rows under new networks
nwclear
set obs 3
gen x = _n * 10
nwset, mat(J(3,3,0)) name(al3)
xt_chk `=(_N == 3)' "3-node network over 3 rows: _N stays 3"
xt_chk `=(x[1] == 10 & x[2] == 20 & x[3] == 30)' "3-node network: attribute rows not moved"
nwset, mat(J(5,5,0)) name(al5)
xt_chk `=(_N == 5)' "5-node network over 3 rows: _N becomes 5 (got `=_N')"
quietly summarize x
xt_chk `=(r(N) == 3 & r(sum) == 60)' "5-node network: the 3 attribute values are all still there"
di "PASS G data rows"

* --- H. many networks; nwset listing; clear option with mat()
nwclear
forvalues i = 1/60 {
	quietly nwset, mat(J(3,3,0)) name(m`i')
}
quietly nwset
xt_chk `=(r(networks) == 60)' "60 networks in memory"
local w : word 60 of `r(nets)'
xt_chk `=("`w'" == "m60")' "r(nets) lists them in creation order"
nwdrop m7 m9
quietly nwset
xt_chk `=(r(networks) == 58)' "nwdrop of two of 60"
xt_hasnet m8
xt_chk `has' "m8 still there"
nwset, mat(J(2,2,0)) name(alone) clear
quietly nwset
xt_chk `=(strtrim("`r(nets)'") == "alone")' "clear together with mat(): only the new network is left"
nwdrop _all
quietly nwset
xt_chk `=(r(networks) == 0)' "nwdrop _all"
di "PASS H many networks"

* --- I. 2,000 nodes with 110-character labels (label string longer than 200,000 characters)
nwclear
mata: __xt_big = ((J(1999, 1, 0), I(1999)) \ J(1, 2000, 0))
mata: __xt_big[2000, 1] = 1
mata: __xt_bl = "node_" :+ strofreal(1..2000) :+ "_" :+ invtokens(J(1, 100, "x"), "")
nwset, mat(__xt_big) name(big) nodenames(__xt_bl)
quietly nwname big
xt_chk `=(r(nodes) == 2000)' "2,000 nodes"
xt_chk `=("`r(labs)'" == "")' "label string above 200,000 characters: r(labs) is empty (nw_labs_string)"
xt_mat big __xt_M
mata: st_local("s", strofreal(sum(__xt_M)))
xt_chk `=("`s'" == "2000")' "2,000-node cycle: 2,000 arcs (got `s')"
xt_chk `=(_N == 2000)' "2,000-node network: _N == 2000 (got `=_N')"
mata: mata drop __xt_big __xt_bl
di "PASS I big"

capture mata: mata drop __xt_M __xt_V __xt_U __xt_nn
xt_end
di "ALL PASS"
