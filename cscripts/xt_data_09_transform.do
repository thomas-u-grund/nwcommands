* xt_data_09_transform.do
* Changing a whole network: nwsym (modes max/min/sum/mean, negative values, generate()/replace, check),
* nwtranspose (twice = identity, generate() over a network that sits before the source in memory, generate()
* = the source), nwpermute (what a relabelling keeps: tie count, value multiset, degree multisets; swap keeps
* every node's degrees), nwduplicate, nwrename, nwname (new...() options, newname() in use).
* Values are derived by hand on 2- to 4-node matrices.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_09_transform
set seed 20261112

* --- A. nwsym modes
nwclear
foreach m in max min sum mean {
	nwset, mat((0,3\1,0)) name(s_`m')
	nwsym s_`m', mode(`m')
	xt_mat s_`m' __xt_M
	mata: st_local("v", strofreal(__xt_M[1,2]) + "," + strofreal(__xt_M[2,1]))
	if "`m'" == "max" local want "3,3"
	if "`m'" == "min" local want "1,1"
	if "`m'" == "sum" local want "4,4"
	if "`m'" == "mean" local want "2,2"
	xt_chk `=("`v'" == "`want'")' "nwsym mode(`m') on (3 one way, 1 the other): `want' (got `v')"
	quietly nwname s_`m'
	xt_chk `=("`r(directed)'" == "false")' "nwsym mode(`m'): the network is undirected afterwards"
}
nwset, mat((0,-1\-2,0)) name(sneg)
nwsym sneg
xt_mat sneg __xt_M
mata: st_local("v", strofreal(__xt_M[1,2]))
xt_chk `=("`v'" == "-1")' "nwsym max of -1 and -2: -1 (got `v')"
* idempotent
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc)
nwsym cyc
xt_mat cyc __xt_A
nwsym cyc
xt_mat cyc __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "nwsym twice = nwsym once"
nwset, mat((0,1\0,0)) name(src)
xt_rmark
nwsym src, check
xt_chk `=("`r(is_symmetric)'" == "false")' "nwsym, check: r(is_symmetric) false"
quietly nwname src
xt_chk `=("`r(directed)'" == "true")' "nwsym, check changes nothing"
nwsym src, generate(srcs)
xt_mat src __xt_A
mata: st_local("ok", strofreal(__xt_A == (0,1\0,0)))
xt_chk `ok' "nwsym generate(): the source is not changed"
xt_mat srcs __xt_B
mata: st_local("ok", strofreal(__xt_B == (0,1\1,0)))
xt_chk `ok' "nwsym generate(): the copy is symmetric"
xt_snap a1
capture noisily nwsym src, generate(srcs)
xt_chk `=(_rc == 483)' "nwsym generate() of an existing network: r(483) (got `=_rc')"
xt_same a1 "nwsym generate() in use"
capture noisily nwsym src, generate(x) replace
xt_chk `=(_rc == 198)' "nwsym generate() with replace: r(198) (got `=_rc')"
xt_same a1 "nwsym generate() with replace"
capture noisily nwsym src, mode(median)
xt_chk `=(_rc == 6555 | _rc == 6556)' "nwsym mode(median) refused (got `=_rc')"
xt_chk `=(_rc == 6556)' "[policy] nwsym mode(median): r(6556) errOptValue of unw_defs (code raises 6555; got `=_rc')"
xt_same a1 "nwsym invalid mode"
di "PASS A nwsym"

* --- B. nwtranspose
nwclear
nwset, mat((0,1,2\0,0,3\0,0,0)) name(t)
nwtranspose t, generate(tt)
xt_mat tt __xt_A
mata: st_local("ok", strofreal(__xt_A == (0,0,0\1,0,0\2,3,0)))
xt_chk `ok' "nwtranspose generate(): the transpose"
nwtranspose t
nwtranspose t
xt_mat t __xt_B
mata: st_local("ok", strofreal(__xt_B == (0,1,2\0,0,3\0,0,0)))
xt_chk `ok' "nwtranspose twice: the original"
* generate() of a network created BEFORE the source, with replace (index of the source shifts)
nwclear
nwset, mat((0,5\0,0)) name(a)
nwset, mat((0,1,0\0,0,1\0,0,0)) name(b)
nwset, mat((0,0,0,7\0,0,0,0\0,0,0,0\0,0,0,0)) name(c)
nwtranspose b, generate(a) replace
xt_mat a __xt_A
mata: st_local("ok", strofreal(__xt_A == (0,0,0\1,0,0\0,1,0)))
xt_chk `ok' "nwtranspose b, generate(a) replace: a is the transpose of b" // was bug S15 (fixed)
xt_mat c __xt_C
mata: st_local("ok", strofreal(__xt_C == (0,0,0,7\0,0,0,0\0,0,0,0\0,0,0,0)))
xt_chk `ok' "[suspected] nwtranspose b, generate(a) replace: c is untouched"
xt_mat b __xt_B
mata: st_local("ok", strofreal(__xt_B == (0,1,0\0,0,1\0,0,0)))
xt_chk `ok' "nwtranspose b, generate(a) replace: b is untouched"
* generate() = the source
nwclear
nwset, mat((0,1\0,0)) name(s)
capture noisily nwtranspose s, generate(s) replace
xt_hasnet s
xt_chk `has' "nwtranspose s, generate(s) replace: s still exists" // was bug S14 (fixed)
if `has' {
	xt_mat s __xt_A
	mata: st_local("ok", strofreal(__xt_A == (0,0\1,0)))
	xt_chk `ok' "nwtranspose s, generate(s) replace: s is transposed"
}
nwclear
nwset, mat((0,1\0,0)) name(s)
nwset, mat((0,1\0,0)) name(s2)
xt_snap b1
capture noisily nwtranspose s, generate(s2)
xt_chk `=(_rc == 483)' "nwtranspose generate() in use: r(483) (got `=_rc')"
xt_same b1 "nwtranspose generate() in use"
capture noisily nwtranspose s, generate(x) name(y)
xt_chk `=(_rc == 198)' "nwtranspose generate() and name(): r(198) (got `=_rc')"
xt_same b1 "nwtranspose generate() and name()"
di "PASS B nwtranspose"

* --- C. nwpermute
nwclear
nwset, mat((0,2,0,0,1\0,0,3,0,0\0,0,0,4,0\5,0,0,0,0\0,0,0,0,0)) name(p)
nwpermute p, generate(pp)
xt_mat p __xt_A
xt_mat pp __xt_B
mata: st_local("ok", strofreal(sort(vec(__xt_A), 1) == sort(vec(__xt_B), 1)))
xt_chk `ok' "nwpermute: same tie values (multiset)"
mata: st_local("ok", strofreal(sort(rowsum(__xt_A :!= 0), 1) == sort(rowsum(__xt_B :!= 0), 1) & sort(colsum(__xt_A :!= 0)', 1) == sort(colsum(__xt_B :!= 0)', 1)))
xt_chk `ok' "nwpermute: same out- and in-degree sequences"
mata: st_local("ok", strofreal(__xt_A == (0,2,0,0,1\0,0,3,0,0\0,0,0,4,0\5,0,0,0,0\0,0,0,0,0)))
xt_chk `ok' "nwpermute generate(): the source is not changed"
quietly nwname pp
xt_chk `=("`r(valued)'" == "true" & "`r(directed)'" == "true")' "nwpermute: flags kept"
nwpermute p, replace
xt_mat p __xt_C
mata: st_local("ok", strofreal(sort(vec(__xt_A), 1) == sort(vec(__xt_C), 1)))
xt_chk `ok' "nwpermute replace: same tie values"
xt_snap c1
capture noisily nwpermute p
xt_chk `=(_rc == 198)' "nwpermute without replace or generate(): r(198) (got `=_rc')"
xt_same c1 "nwpermute without replace/generate"
capture noisily nwpermute p, generate(pp)
xt_chk `=(_rc == 99 | _rc == 483)' "nwpermute generate() in use refused (got `=_rc')"
xt_chk `=(_rc == 483)' "[policy] nwpermute generate() in use: r(483) errNWsExists like the other commands (code raises 99; got `=_rc')"
xt_same c1 "nwpermute generate() in use"
capture noisily nwpermute p, generate(p) nwreplace
xt_hasnet p
xt_chk `has' "[suspected] nwpermute p, generate(p) nwreplace: p still exists" // S14: lost when p is not the first network (repro)
if `has' {
	quietly nwname p
	xt_chk `=(r(nodes) == 5)' "[suspected] nwpermute p, generate(p) nwreplace: p still has 5 nodes (got `r(nodes)')"
}
* the same with p as the second network
nwclear
nwset, mat((0,1\1,0)) name(other)
nwset, mat((0,2,0,0,1\0,0,3,0,0\0,0,0,4,0\5,0,0,0,0\0,0,0,0,0)) name(p)
capture noisily nwpermute p, generate(p) nwreplace
xt_hasnet p
xt_chk `has' "nwpermute p, generate(p) nwreplace, p the second network: p still exists" // was bug S14 (fixed)
* swap keeps every node's degrees (native plugin 3.17.0 or later)
nwclear
nwrandom 12, prob(.3) name(sw)
xt_mat sw __xt_A
capture noisily nwpermute sw, generate(sw2) swap swaps(50)
if _rc == 198 {
	di as txt "  (swap: native plugin missing or too old, skipped)"
}
else {
	xt_mat sw2 __xt_B
	mata: st_local("ok", strofreal(rowsum(__xt_A) == rowsum(__xt_B) & colsum(__xt_A) == colsum(__xt_B) & sum(diagonal(__xt_B)) == 0))
	xt_chk `ok' "nwpermute swap: every node keeps its out- and in-degree, no self-ties"
}
di "PASS C nwpermute"

* --- D. nwduplicate, nwrename
nwclear
nwset, mat((0,1\0,0)) name(d)
nwduplicate d
xt_hasnet d_copy
xt_chk `has' "nwduplicate without name(): d_copy"
nwduplicate d
xt_hasnet d_copy_1
xt_chk `has' "nwduplicate again: d_copy_1"
xt_snap d1
capture noisily nwduplicate d, name(d_copy)
xt_chk `=(_rc == 483)' "nwduplicate name() in use: r(483) (got `=_rc')"
xt_same d1 "nwduplicate name() in use"
capture noisily nwduplicate d, name(d) replace
xt_hasnet d
xt_chk `has' "[suspected] nwduplicate d, name(d) replace: d still exists"
if `has' {
	quietly nwname d
	xt_chk `=(r(nodes) == 2)' "nwduplicate d, name(d) replace: d still has 2 nodes (got `r(nodes)')" // was bug S14 (fixed)
}
nwclear
nwset, mat((0,1\0,0)) name(r1)
nwset, mat((0,1,1\0,0,0\0,0,0)) name(r2)
nwrename r1 r3
xt_hasnet r3
xt_chk `has' "nwrename r1 r3"
quietly nwname r3
xt_chk `=(r(nodes) == 2)' "nwrename: the network keeps its ties and nodes"
xt_snap d2
capture noisily nwrename r3 r2
xt_chk `=(_rc == 110)' "nwrename onto an existing network: r(110) (got `=_rc')"
xt_same d2 "nwrename onto an existing network"
nwrename (r2 r3) (q2 q3)
quietly nwset
xt_chk `=(strtrim("`r(nets)'") == "q3 q2" | strtrim("`r(nets)'") == "q2 q3")' "nwrename (r2 r3) (q2 q3) (got `r(nets)')"
quietly nwname q2
xt_chk `=(r(nodes) == 3)' "nwrename of two: q2 is the former r2"
di "PASS D duplicate/rename"

* --- E. nwname
nwclear
nwset, mat((0,1\0,0)) name(n1)
nwset, mat((0,1\0,0)) name(n2)
nwname n1, newtitle(A title) newcaption(A caption)
quietly nwname n1
xt_chk `=("`r(title)'" == "A title" & "`r(caption)'" == "A caption")' "nwname newtitle()/newcaption()"
nwname n1, newdirected(false)
quietly nwname n1
xt_chk `=("`r(directed)'" == "false")' "nwname newdirected(false)"
xt_snap e1
capture noisily nwname n1, newname(n2)
quietly nwset
xt_chk `=(r(networks) == 2)' "nwname newname() in use: still 2 networks"
xt_hasnet n2
xt_chk `has' "nwname newname() in use: n2 is still there"
xt_hasnet n1
xt_chk `has' "[policy] nwname newname() in use: refused with 483 like nwset (code renames n1 to n2_1)"
nwname n2, newname(m2)
xt_hasnet m2
xt_chk `has' "nwname newname(m2)"
di "PASS E nwname"

capture mata: mata drop __xt_M __xt_A __xt_B __xt_C
xt_end
di "ALL PASS"
