* xt_data_11_expand_stack_time.do
* nwexpand (modes same/dist/absdist/sender/receiver, string variable, missing values, if and nodes(),
* network() labels), nwcollapse (groups, generate(), the temporary network it makes), nwstack (block diagonal,
* group(), direction and two-mode refused, name in use, undirected and valued inputs), temporal networks
* (nwset ..., time()/interval()/eventtime() and nwattime: which ties are visible at t, r(ties), a variable
* called ties, name in use).
* Values are derived by hand on 3- to 5-node examples.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_11_expand_stack_time

* --- A. nwexpand
nwclear
clear
input x str3 s
1 "a"
2 "b"
2 "b"
5 "c"
end
nwexpand x, mode(same) name(same)
xt_mat same __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,0,0,0\0,0,1,0\0,1,0,0\0,0,0,0)))
xt_chk `ok' "mode(same): only nodes 2 and 3 share x"
quietly nwname same
xt_chk `=("`r(directed)'" == "false")' "mode(same): undirected"
nwexpand x, mode(dist) name(dist)
nwtomata dist, mat(__xt_M)
mata: st_local("ok", strofreal(__xt_M[1,4] == -4 & __xt_M[4,1] == 4 & __xt_M[2,1] == 1))
xt_chk `ok' "mode(dist): cell (i,j) = x_i - x_j"
nwexpand x, mode(absdist) name(absd)
xt_mat absd __xt_M
mata: st_local("ok", strofreal(__xt_M == __xt_M' & __xt_M[1,4] == 4))
xt_chk `ok' "mode(absdist): |x_i - x_j|, symmetric"
nwexpand x, mode(sender) name(snd)
xt_mat snd __xt_M
mata: st_local("ok", strofreal(__xt_M[4,1] == 5 & __xt_M[1,4] == 1))
xt_chk `ok' "mode(sender): cell (i,j) = x_i"
nwexpand s, mode(same) name(sstr)
xt_mat sstr __xt_A
xt_mat same __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "a string variable is encoded: same result as the numeric one"
nwexpand x if x < 5, mode(same) name(sub)
quietly nwname sub
xt_chk `=(r(nodes) == 3)' "if x < 5: 3 nodes (got `r(nodes)')"
nwexpand x, mode(same) nodes(2) name(n2)
quietly nwname n2
xt_chk `=(r(nodes) == 2)' "nodes(2): 2 nodes"
xt_snap a1
capture noisily nwexpand x, mode(same) nodes(9) name(n9)
xt_chk `=(_rc == 2001)' "nodes(9) with 4 observations: r(2001) (got `=_rc')"
xt_same a1 "nodes() larger than the data"
capture noisily nwexpand x, mode(ratio) name(bad)
xt_chk `=(_rc == 6556)' "mode(ratio): r(6556) (got `=_rc')"
xt_same a1 "invalid mode()"
capture noisily nwexpand x, mode(same) name(same)
xt_chk `=(_rc == 483)' "name() in use: r(483) (got `=_rc')"
xt_same a1 "nwexpand name() in use"
capture noisily nwexpand x, mode(same) network(nosuchnet) name(nn)
xt_chk `=(_rc == 482)' "network() unknown: r(482) (got `=_rc')"
xt_same a1 "nwexpand network() unknown"
* missing values: no tie through a missing attribute
nwclear
clear
input x
1
.
1
end
nwexpand x, mode(same) name(miss)
xt_mat miss __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,0,1\0,0,0\1,0,0)))
xt_chk `ok' "mode(same) with a missing value: the missing node has no tie"
* network(): labels of an existing network of another size
nwclear
nwset, mat(J(3,3,0)) name(lab3) labs(p,q,r)
gen x = _n
capture noisily nwexpand x, mode(same) network(lab3) nodes(2) name(nx)
if _rc == 0 {
	quietly nwname nx
	mata: st_local("u", strofreal(xt_nuniq(st_global("r(labs)"))))
	xt_chk `=(r(nodes) == 2 & "`u'" == "2")' "[policy] network() with nodes(2) of a 3-node network: 2 nodes with 2 labels"
}
else {
	xt_hasnet nx
	xt_chk `=(!`has')' "network() with nodes(2) refused: no half-made network nx left"
}
di "PASS A nwexpand"

* --- B. nwcollapse
nwclear
nwset, mat((0,0,1,0\0,0,0,0\0,0,0,0\0,0,0,0)) name(c4)
gen g = cond(_n <= 2, 1, 2)
quietly nwset
local before "`r(nets)'"
nwcollapse c4, by(g) generate(cc)
quietly nwset
local after "`r(nets)'"
xt_chk `=("`after'" == "`before' cc")' "nwcollapse generate(): only cc is added (got `after')" // was bug S18 (fixed)
quietly nwname cc
xt_chk `=(r(nodes) == 2)' "nwcollapse into 2 groups: 2 nodes (got `r(nodes)')"
xt_mat cc __xt_M
mata: st_local("s", strofreal(sum(__xt_M)))
xt_chk `=("`s'" == "1")' "nwcollapse: one tie, group 1 -> group 2 (got `s')"
xt_mat c4 __xt_M
mata: st_local("ok", strofreal(sum(__xt_M) == 1 & rows(__xt_M) == 4))
xt_chk `ok' "nwcollapse generate(): the source is unchanged"
nwset, mat((1,0\0,1)) bipartite name(bp)
xt_snap b1
capture noisily nwcollapse bp, by(g) generate(cb)
xt_chk `=(_rc == 6088)' "nwcollapse of a two-mode network: r(6088) (got `=_rc')"
xt_same b1 "nwcollapse two-mode"
di "PASS B nwcollapse"

* --- C. nwstack
nwclear
nwset, mat((0,1\0,0)) name(s1)
nwset, mat((0,1,0\0,0,1\1,0,0)) name(s2)
clear
nwstack s1 s2, name(st) group(grp)
xt_chk `=(r(k) == 2 & r(N) == 5)' "nwstack: r(k) = 2, r(N) = 5"
xt_mat st __xt_M
mata: st_local("ok", strofreal(__xt_M == blockdiag((0,1\0,0), (0,1,0\0,0,1\1,0,0))))
xt_chk `ok' "nwstack: block-diagonal matrix"
quietly count if grp == 1
local g1 = r(N)
quietly count if grp == 2
xt_chk `=(`g1' == 2 & r(N) == 3)' "nwstack group(): 2 rows of group 1, 3 of group 2"
xt_snap c1
capture noisily nwstack s1 s2, name(st)
xt_chk `=(_rc == 483)' "[policy] nwstack name() in use: r(483) errNWsExists (code raises 110; got `=_rc')"
xt_same c1 "nwstack name() in use"
capture noisily nwstack s1, name(st9)
xt_chk `=(_rc != 0)' "nwstack of one network refused (got `=_rc')"
xt_same c1 "nwstack of one network"
nwset, mat((0,1\1,0)) name(su) undirected
xt_snap c2
capture noisily nwstack s1 su, name(mix)
xt_chk `=(_rc == 198)' "nwstack directed with undirected: r(198) (got `=_rc')"
xt_same c2 "nwstack directed with undirected"
nwset, mat((1,0\0,1)) bipartite name(bp)
xt_snap c3
capture noisily nwstack su bp, name(mix2)
xt_chk `=(_rc == 6088)' "nwstack with a two-mode network: r(6088) (help; got `=_rc')"
xt_same c3 "nwstack with a two-mode network"
nwset, mat((0,1,1\1,0,0\1,0,0)) name(su2) undirected
nwstack su su2, name(stu)
quietly nwname stu
xt_chk `=("`r(directed)'" == "false")' "nwstack of two undirected networks is undirected (got directed `r(directed)')" // was bug S19 (fixed)
nwset, mat((0,1\0,0)) name(sv) valued
nwset, mat((0,1\0,0)) name(sv2) valued
* nwstack runs set obs <nodes>, which cannot shrink the data: with more rows in memory than stacked nodes it
* stops with "observation number out of range" (was bug N11, fixed)
capture noisily nwstack sv sv2, name(stv)
xt_chk `=(_rc == 0)' "nwstack with more data rows than stacked nodes works (got `=_rc')" // was bug N11 (fixed)
if _rc != 0 {
	nwclear
	nwset, mat((0,1\0,0)) name(sv) valued
	nwset, mat((0,1\0,0)) name(sv2) valued
	nwstack sv sv2, name(stv)
}
quietly nwname stv
xt_chk `=("`r(valued)'" == "true")' "[policy] nwstack of valued networks keeps the valued flag (values all 1; got `r(valued)')"
di "PASS C nwstack"

* --- D. temporal networks and nwattime
nwclear
clear
input ego alter wave
1 2 1
2 3 2
1 3 1
end
nwset ego alter, time(wave) name(tn) directed
nwattime tn, at(1) name(v1)
xt_chk `=(r(ties) == 2 & r(at) == 1)' "snapshot at t = 1: 2 ties, r(at) = 1"
xt_mat v1 __xt_M
mata: st_local("s", strofreal(sum(__xt_M)))
xt_chk `=("`s'" == "2")' "snapshot at t = 1: the view has 2 arcs"
nwattime tn, at(2) name(v2)
xt_chk `=(r(ties) == 1)' "snapshot at t = 2: 1 tie"
nwattime tn, at(3) name(v3)
xt_chk `=(r(ties) == 0)' "snapshot at t = 3: no tie"
quietly nwname v3
xt_chk `=(r(nodes) == 3)' "a view keeps all 3 nodes"
capture confirm scalar ties
xt_chk `=(_rc != 0)' "nwattime leaves no Stata scalar called ties" // was bug S20 (policy-level on its own) (fixed)
* a variable called ties must not take the place of the scalar
nwclear
clear
input ego alter wave
1 2 1
2 3 2
1 3 1
end
nwset ego alter, time(wave) name(tn) directed
gen ties = 999
nwattime tn, at(2) name(w2)
xt_chk `=(r(ties) == 1)' "r(ties) with a variable called ties in the data: 1 (got `r(ties)')" // was bug S20 (fixed)
* interval: start <= t < end, missing end = open
nwclear
clear
input ego alter s e
1 2 0 5
2 3 3 .
3 1 6 8
end
nwset ego alter, interval(s e) name(iv) directed
nwattime iv, at(4) name(i4)
xt_chk `=(r(ties) == 2)' "interval at t = 4: [0,5) and [3,.) visible (got `r(ties)')"
nwattime iv, at(5) name(i5)
xt_chk `=(r(ties) == 1)' "interval at t = 5: the end is excluded, the open interval stays (got `r(ties)')"
nwattime iv, at(-1) name(im)
xt_chk `=(r(ties) == 0)' "interval at t = -1: nothing (got `r(ties)')"
* events: ties at exactly t, repeated events counted once
nwclear
clear
input ego alter t
1 2 1
1 2 1
2 1 2
end
nwset ego alter, eventtime(t) name(ev) directed
nwattime ev, at(1) name(e1)
xt_chk `=(r(ties) == 1)' "events at t = 1: two events between 1 and 2 give one tie (got `r(ties)')"
* errors
nwclear
nwset, mat((0,1\0,0)) name(static)
gen keepme = _n
xt_snap d1
capture noisily nwattime static, at(1)
xt_chk `=(_rc == 198)' "nwattime on a network without time: r(198) (got `=_rc')"
xt_same d1 "nwattime on a static network"
clear
input ego alter wave
1 2 1
end
xt_snap d2
capture noisily nwset ego alter, time(wave) eventtime(wave) name(bad)
xt_chk `=(_rc == 198)' "time() with eventtime(): r(198) (got `=_rc')"
xt_same d2 "time() with eventtime()"
nwset ego alter, time(wave) name(tw) directed
nwattime tw, at(1) name(view)
quietly nwset
local before "`r(nets)'"
capture noisily nwattime tw, at(1) name(view)
quietly nwset
xt_chk `=("`r(nets)'" == "`before'")' "[policy] nwattime name() in use: refused with 483 like the other commands (code adds view_1; now `r(nets)')"
di "PASS D temporal"

capture mata: mata drop __xt_M __xt_A __xt_B
xt_end
di "ALL PASS"
