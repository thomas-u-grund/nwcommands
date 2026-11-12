* xt_data_10_replace_generate.do
* nwreplace (whole network, one cell, flags afterwards, r()), nwreplacemat (newmat of the same and of another
* size, triplets(), Stata matrices, invalid shapes; data and networks unchanged on error), nwgenerate
* (copy, arithmetic, transpose(), sym(), if, replace that refers to itself, name in use, network names that
* contain "if").
* Values are derived by hand on 2- to 4-node matrices.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_10_replace_generate

* --- A. nwreplace
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(u) undirected
nwreplace u = u * 2
xt_chk `=(r(valued) == 1 & r(symmetric) == 1)' "nwreplace returns r(valued) = 1 and r(symmetric) = 1"
xt_mat u __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,2,0\2,0,2\0,2,0)))
xt_chk `ok' "nwreplace u = u * 2: every tie value 2"
quietly nwname u
xt_chk `=("`r(valued)'" == "true")' "nwreplace: values 2 make the network valued"
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(u) undirected
nwreplace u[1,3] = 5
xt_mat u __xt_M
mata: st_local("sym", strofreal(__xt_M == __xt_M'))
quietly nwname u
xt_chk `=("`sym'" == "1" | "`r(directed)'" == "true")' "nwreplace of one cell of an undirected network: either the mirror cell is set too or the network becomes directed (symmetric `sym', directed `r(directed)')" // was bug S16 (fixed)
nwclear
nwset, mat((0,1\1,0)) name(z)
nwreplace z = 0
xt_mat z __xt_M
mata: st_local("s", strofreal(sum(abs(__xt_M))))
xt_chk `=("`s'" == "0")' "nwreplace z = 0: no ties"
nwset, mat((0,1,1\0,0,1\1,0,0)) name(three)
xt_snap a1
capture noisily nwreplace z = three
xt_chk `=(_rc != 0)' "nwreplace with a network of another size fails (got `=_rc')"
xt_same a1 "nwreplace with a network of another size" nosig
capture noisily nwreplace nosuchnet = 1
xt_chk `=(_rc == 482)' "nwreplace of an unknown network: r(482) (got `=_rc')"
xt_same a1 "nwreplace of an unknown network" nosig
di "PASS A nwreplace"

* --- B. nwreplacemat
nwclear
nwset, mat((0,1,0\0,0,1\0,0,0)) name(r) labs(a,b,c)
nwset, mat((0,1\0,0)) name(other)
gen keepme = _n
mata: __xt_N = (0,1,1\1,0,1\1,1,0)
nwreplacemat r, newmat(__xt_N)
xt_mat r __xt_M
mata: st_local("ok", strofreal(__xt_M == __xt_N))
xt_chk `ok' "nwreplacemat same size: the new matrix"
quietly nwname r
xt_chk `=("`r(labs)'" == "a,b,c")' "nwreplacemat same size: labels kept"
xt_chk `=("`r(directed)'" == "false")' "nwreplacemat with a symmetric matrix: undirected (code: issymmetric)"
matrix XTN = (0,2,0\0,0,0\0,0,0)
nwreplacemat r, newmat(XTN)
xt_mat r __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,2,0\0,0,0\0,0,0)))
xt_chk `ok' "nwreplacemat takes a Stata matrix"
quietly nwname r
xt_chk `=("`r(valued)'" == "true" & "`r(directed)'" == "true")' "nwreplacemat: value 2 valued, asymmetric directed"
matrix drop XTN
xt_snap b1
mata: __xt_R = J(2, 3, 0)
capture noisily nwreplacemat r, newmat(__xt_R)
xt_chk `=(_rc == 6082)' "nwreplacemat with a 2 x 3 matrix: r(6082) (got `=_rc')"
xt_same b1 "nwreplacemat with a non-square matrix"
mata: __xt_T = (1, 2, 1)
capture noisily nwreplacemat r, triplets(__xt_T)
xt_chk `=(_rc == 198)' "nwreplacemat triplets() without labsmata(): r(198) (got `=_rc')"
xt_same b1 "nwreplacemat triplets() without labsmata()"
capture noisily nwreplacemat r
xt_chk `=(_rc == 198)' "nwreplacemat without newmat() or triplets(): r(198) (got `=_rc')"
xt_same b1 "nwreplacemat without a matrix"
* another size: other networks and their order untouched
mata: __xt_N4 = J(4, 4, 1)
nwreplacemat r, newmat(__xt_N4)
quietly nwname r
xt_chk `=(r(nodes) == 4)' "nwreplacemat with a 4 x 4 matrix: 4 nodes"
xt_hasnet other
xt_chk `has' "nwreplacemat with another size: the other network is still there"
quietly nwset
xt_chk `=("`r(nets)'" == "r other")' "[policy] nwreplacemat with another size keeps the order of the networks (got `r(nets)')"
xt_mat other __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,1\0,0)))
xt_chk `ok' "nwreplacemat with another size: the other network unchanged"
di "PASS B nwreplacemat"

* --- C. nwgenerate
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(x)
nwgen y = x
xt_mat y __xt_A
xt_mat x __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "nwgen y = x: a copy"
nwgen y2 = x + x
xt_mat y2 __xt_A
mata: st_local("ok", strofreal(__xt_A == 2 :* __xt_B))
xt_chk `ok' "nwgen y2 = x + x: values 2"
quietly nwname y2
xt_chk `=("`r(valued)'" == "true")' "nwgen y2 = x + x: valued"
nwgen y3 = x * 0.5
xt_mat y3 __xt_A
mata: st_local("ok", strofreal(__xt_A == .5 :* __xt_B))
xt_chk `ok' "nwgen y3 = x * 0.5: values .5"
nwgen yt = transpose(x)
xt_mat yt __xt_A
mata: st_local("ok", strofreal(__xt_A == __xt_B'))
xt_chk `ok' "nwgen yt = transpose(x)"
nwgen ys = sym(x)
xt_mat ys __xt_A
mata: st_local("ok", strofreal(__xt_A == __xt_A' & sum(__xt_A) == 6))
xt_chk `ok' "nwgen ys = sym(x): symmetric, 6 cells"
gen keepme = _n
xt_snap c1
capture noisily nwgen y = x
xt_chk `=(_rc == 483)' "nwgen of an existing name without replace: r(483) (got `=_rc')"
xt_same c1 "nwgen name in use"
capture noisily nwgen x = nosuchnet + 1, replace
xt_hasnet x
xt_chk `has' "nwgen x = <invalid>, replace: x must survive the failed expression (got `=_rc')" // was bug S14 (fixed)
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(x)
capture noisily nwgen x = x * 2, replace
xt_hasnet x
xt_chk `has' "nwgen x = x * 2, replace: x still exists" // was bug S14 (fixed)
if `has' {
	xt_mat x __xt_A
	mata: st_local("ok", strofreal(__xt_A == 2 :* (0,1,0\0,0,1\1,0,0)))
	xt_chk `ok' "nwgen x = x * 2, replace: values doubled"
}
* a network whose name contains "if"
nwclear
nwset, mat((0,1\0,0)) name(diff)
capture noisily nwgen y = diff
xt_chk `=(_rc == 0)' "nwgen y = diff (a name containing if) works (got `=_rc')" // was bug S17 (fixed)
if _rc == 0 {
	xt_mat y __xt_A
	mata: st_local("ok", strofreal(__xt_A == (0,1\0,0)))
	xt_chk `ok' "nwgen y = diff: a copy of diff"
}
* if: keep only some nodes
nwclear
nwset, mat(J(4,4,1)) name(w)
gen g = _n <= 2
nwgen w2 = w if g == 1
quietly nwname w2
xt_chk `=(r(nodes) == 2)' "nwgen w2 = w if g == 1: 2 nodes (got `r(nodes)')"
quietly nwname w
xt_chk `=(r(nodes) == 4)' "nwgen ... if: the source keeps 4 nodes"
di "PASS C nwgenerate"

capture mata: mata drop __xt_M __xt_A __xt_B __xt_N __xt_N4 __xt_R __xt_T
xt_end
di "ALL PASS"
