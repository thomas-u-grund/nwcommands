* xt_data_08_nodes.do
* Removing and adding nodes: nwdropnodes, nwkeepnodes, nwsubset, nwdrop/nwkeep with if, nwaddnodes,
* nwnoderename. Labels with blanks (looked up by label), unknown labels, ids out of range, dropping every node,
* generate() together with an invalid request, the flags (directed, valued, two-mode) after dropping, compound
* if conditions, a 2,000-node network with labels longer than 200,000 characters in total, the data rows, and
* every error leaving data and networks unchanged.
* Expected results are derived by hand on networks of 3 to 6 nodes.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_08_nodes

* --- A. nwdropnodes by label when labels have blanks
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(sp) labs(Anna Maria,Bob,Carl)
nwdropnodes sp, nodes(Bob)
quietly nwname sp
xt_chk `=("`r(labs)'" == "Anna Maria,Carl")' "dropping Bob from (Anna Maria, Bob, Carl) leaves Anna Maria,Carl (got `r(labs)')" // was bug S10 (fixed)
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(sp) labs(Anna Maria,Bob,Carl)
capture noisily nwkeepnodes sp, nodes(Carl)
xt_chk `=(_rc == 0)' "keeping Carl of (Anna Maria, Bob, Carl) works (got `=_rc')" // was bug S10 (fixed)
quietly nwname sp
xt_chk `=("`r(labs)'" == "Carl")' "keeping Carl of (Anna Maria, Bob, Carl) leaves Carl (got `r(labs)')" // was bug S10 (fixed)
di "PASS A labels with blanks"

* --- B. what is dropped, ties among the rest, flags
nwclear
nwset, mat((0,2,0,0,1\2,0,3,0,0\0,3,0,-1,0\0,0,-1,0,0\1,0,0,0,0)) name(v5) undirected labs(a,b,c,d,e)
nwdropnodes v5, nodes(2 4)
quietly nwname v5
xt_chk `=("`r(labs)'" == "a,c,e" & "`r(directed)'" == "false" & "`r(valued)'" == "true")' "dropping b and d: a,c,e, undirected, valued (got `r(labs)', `r(directed)', `r(valued)')"
xt_mat v5 __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,0,1\0,0,0\1,0,0)))
xt_chk `ok' "dropping b and d: only the tie a-e (value 1) is left"
nwclear
nwset, mat((0,2,0,0,1\2,0,3,0,0\0,3,0,-1,0\0,0,-1,0,0\1,0,0,0,0)) name(v5) undirected labs(a,b,c,d,e)
nwduplicate v5, name(k5)
nwdropnodes v5, nodes(b d)
nwkeepnodes k5, nodes(1 3 5)
xt_mat v5 __xt_A
xt_mat k5 __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "dropnodes(b d) by label == keepnodes(1 3 5) by id"
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri)
nwdropnodes tri, nodes(1) generate(tri2)
quietly nwname tri
xt_chk `=(r(nodes) == 3)' "generate(): the source keeps 3 nodes"
quietly nwname tri2
xt_chk `=(r(nodes) == 2)' "generate(): the copy has 2 nodes"
di "PASS B dropping"

* --- C. errors leave everything unchanged, including generate()
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) labs(x,y,z)
gen keepme = _n
xt_snap c1
mata: __xt_K = J(2, 1, 1)
capture noisily nwdropnodes tri, keepmat(__xt_K)
xt_chk `=(_rc == 503)' "keepmat() of the wrong size: r(503) (got `=_rc')"
xt_same c1 "keepmat() of the wrong size"
capture noisily nwdropnodes tri, keepmat(__xt_K) generate(tri2)
xt_chk `=(_rc == 503)' "keepmat() of the wrong size with generate(): r(503) (got `=_rc')"
xt_same c1 "keepmat() of the wrong size with generate(): no copy left behind" // was bug S12 (fixed)
xt_hasnet tri2
if `has' nwdrop tri2
xt_snap c1
capture noisily nwdropnodes tri, nodes(1 2 3)
xt_chk `=(_rc == 198)' "dropping every node: r(198) (got `=_rc')"
xt_same c1 "dropping every node"
capture noisily nwdropnodes tri, nodes(x y z) generate(tri3)
xt_chk `=(_rc == 198)' "dropping every node with generate(): r(198) (got `=_rc')"
xt_same c1 "dropping every node with generate(): no copy left behind" // was bug S12 (fixed)
xt_hasnet tri3
if `has' nwdrop tri3
xt_snap c1
capture noisily nwdropnodes tri, nodes(nosuchnode)
xt_chk `=(_rc == 485)' "unknown label: r(485) (got `=_rc')"
xt_same c1 "unknown label"
capture noisily nwdropnodes tri, nodes(0)
xt_chk `=(_rc == 485)' "[policy] node id 0: r(485) errNodeNotFound (got `=_rc')"
xt_same c1 "node id 0"
capture noisily nwdropnodes tri, nodes(9)
xt_chk `=(_rc == 485)' "[policy] node id 9 of 3: r(485) errNodeNotFound, not silently ignored (got `=_rc')"
xt_same c1 "node id 9" // was bug N10: nwdropnodes (here a no-op) turns the declared-directed symmetric tri undirected (fixed)
xt_snap c1
capture noisily nwkeepnodes tri
xt_chk `=(_rc == 198)' "nwkeepnodes without nodes() or keepmat(): r(198) (got `=_rc')"
xt_same c1 "nwkeepnodes without a list"
capture noisily nwdropnodes nosuchnet, nodes(1)
xt_chk `=(_rc == 482)' "unknown network: r(482) (got `=_rc')"
xt_same c1 "unknown network"
di "PASS C errors"

* --- D. two-mode: modes and flags kept
nwclear
nwset, mat((1,0,1\0,1,1)) bipartite name(bp)
nwdropnodes bp, nodes(2)
quietly nwname bp
xt_chk `=("`r(mode2)'" == "true" & r(nodes1) == 2 & r(nodes2) == 2)' "two-mode: drop one mode-1 node, 2 + 2 nodes left (got `r(nodes1)' + `r(nodes2)')"
di "PASS D two-mode"

* --- E. nwsubset: if conditions, name in use
nwclear
nwset, mat(J(4,4,1)) name(sq) undirected
gen a = inlist(_n, 1, 2)
gen b = inlist(_n, 1, 3) * 2
nwsubset sq if a == 1 & b == 2, name(sub1)
quietly nwname sub1
xt_chk `=(r(nodes) == 1)' "nwsubset if a == 1 & b == 2 keeps node 1 only (got `r(nodes)' nodes)" // was bug S13 (fixed)
nwsubset sq if a == 1 | b == 2, name(sub2)
quietly nwname sub2
xt_chk `=(r(nodes) == 3)' "nwsubset if a == 1 | b == 2 keeps nodes 1, 2, 3 (got `r(nodes)')" // was bug S13 (fixed)
xt_snap e1
capture noisily nwsubset sq if a == 9, name(none)
xt_chk `=(_rc == 198)' "[suspected] nwsubset selecting no node: r(198) (got `=_rc')"
* the 0-node case is refused (S13 second part: not a bug); the rows are re-sorted into the node order of sq,
* which is the documented data sync, so only the networks are compared
quietly nwset
xt_chk `=("`r(nets)'" == "${XT_e1_nets}")' "nwsubset selecting no node: no network added (now: `r(nets)')"
xt_hasnet none
if `has' nwdrop none
xt_snap e2
capture noisily nwsubset sq if a == 1, name(sub1)
xt_chk `=(_rc == 483)' "nwsubset name() in use: r(483) (got `=_rc')"
xt_same e2 "nwsubset name() in use"
capture noisily nwsubset sq if a == 1, name(sq) replace
xt_hasnet sq
xt_chk `has' "nwsubset sq ..., name(sq) replace: sq still exists (replace drops the source first)" // was bug S14 (fixed)
di "PASS E nwsubset"

* --- F. nwdrop / nwkeep with if
nwclear
nwset, mat(J(5,5,1)) name(f5) labs(a,b,c,d,e)
gen x = _n
nwdrop f5 if x <= 2
quietly nwname f5
xt_chk `=(r(nodes) == 3 & "`r(labs)'" == "c,d,e")' "nwdrop if x <= 2: c,d,e left (got `r(labs)')"
nwclear
nwset, mat(J(5,5,1)) name(f5) labs(a,b,c,d,e)
gen x = _n
nwkeep f5 if x <= 2
quietly nwname f5
xt_chk `=(r(nodes) == 2 & "`r(labs)'" == "a,b")' "nwkeep if x <= 2: a,b left (got `r(labs)')"
nwclear
nwset, mat(J(3,3,1)) name(g3)
nwset, mat(J(2,2,1)) name(h2)
gen x = _n
nwkeep g3 if x > 9
xt_hasnet g3
xt_chk `=(!`has')' "nwkeep with an if that selects no node drops the network (code)"
xt_hasnet h2
xt_chk `has' "nwkeep ... if: the other network is untouched"
nwclear
nwset, mat(J(3,3,1)) name(g3)
gen x = _n
capture noisily nwdrop g3 if x > 0
xt_hasnet g3
if `has' {
	quietly nwname g3
	xt_chk `=(r(nodes) == 0)' "[policy] nwdrop if <all nodes>: the network has 0 nodes (nwkeep would drop it)"
}
nwclear
nwset, mat(J(3,3,1)) name(g3)
nwset, mat(J(3,3,1)) name(g4)
xt_snap f1
capture noisily nwdrop g3 nosuchnet
xt_chk `=(_rc == 482)' "nwdrop of a list with an unknown network: r(482) (got `=_rc')"
xt_same f1 "nwdrop with an unknown network: nothing dropped"
nwkeep g4
quietly nwset
xt_chk `=(strtrim("`r(nets)'") == "g4")' "nwkeep g4: only g4 left"
di "PASS F nwdrop/nwkeep"

* --- G. nwaddnodes
nwclear
nwset, mat((0,1\1,0)) name(ad) labs(a,b)
nwaddnodes ad, nodenames(Thomas Grund, Zoë)
quietly nwname ad
xt_chk `=("`r(labs)'" == "a,b,Thomas Grund,Zoë" & r(nodes) == 4)' "nwaddnodes: names with a blank and a non-ASCII letter (got `r(labs)')"
xt_mat ad __xt_M
mata: st_local("ok", strofreal(__xt_M == (0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)))
xt_chk `ok' "nwaddnodes: the new nodes are isolates, old ties kept"
xt_snap g1
capture noisily nwaddnodes ad, nodenames(a)
if _rc == 0 {
	quietly nwname ad
	mata: st_local("u", strofreal(xt_nuniq(st_global("r(labs)")) == cols(xt_toks(st_global("r(labs)")))))
	xt_chk `=("`u'" == "1")' "[policy] nwaddnodes of an existing label: refused (481) or labels stay unique (got `r(labs)')"
}
else {
	xt_chk `=(_rc == 481)' "[policy] nwaddnodes of an existing label: r(481) errNodeDupName (got `=_rc')"
	xt_same g1 "nwaddnodes of an existing label"
}
nwclear
nwset, mat((0,1\1,0)) name(ad) labs(a,b)
xt_snap g2
capture noisily nwaddnodes ad, nodenames(c) mode(1)
xt_chk `=(_rc == 198)' "nwaddnodes mode() on a one-mode network: r(198) (got `=_rc')"
xt_same g2 "nwaddnodes mode() on one-mode"
nwaddnodes ad, nodenames(c) generate(ad2)
quietly nwname ad
xt_chk `=(r(nodes) == 2)' "nwaddnodes generate(): the source keeps 2 nodes"
quietly nwname ad2
xt_chk `=(r(nodes) == 3)' "nwaddnodes generate(): the copy has 3 nodes"
di "PASS G nwaddnodes"

* --- H. nwnoderename
nwclear
nwset, mat((0,1,0\0,0,1\0,0,0)) name(nr) labs(a,b,c)
gen double w = 10 * _n
nwnoderename nr, old(b) new(bee)
quietly nwname nr
xt_chk `=("`r(labs)'" == "a,bee,c")' "nwnoderename b -> bee (got `r(labs)')"
xt_chk `=(_N == 3)' "nwnoderename: _N stays 3 (got `=_N')" // was bug S21 (the old label stays as an extra row) (fixed)
quietly count if _nwnode == "bee" & w == 20
xt_chk `=(r(N) == 1)' "nwnoderename: the attribute moves with the node"
xt_snap h1
capture noisily nwnoderename nr, old(zzz) new(y)
xt_chk `=(_rc == 198)' "unknown old name: r(198) (got `=_rc')"
xt_same h1 "unknown old name"
capture noisily nwnoderename nr, old(a) new(c)
xt_chk `=(_rc == 198)' "new name already a node: r(198) (help; got `=_rc')"
xt_same h1 "new name already a node"
nwclear
nwset, mat((0,1\1,0)) name(nv) labs(age,b)
gen age = 30 + _n
nwnoderename nv, old(age) new(years)
capture confirm variable age
xt_chk `=(_rc == 0)' "renaming node age does not rename the user's variable age" // was bug S21 (fixed)
di "PASS H nwnoderename"

* --- I. 2,000 nodes, labels longer than 200,000 characters in total: drop by label
nwclear
mata: __xt_bl = "node_" :+ strofreal(1..2000) :+ "_" :+ invtokens(J(1, 100, "x"), "")
mata: __xt_big = ((J(1999, 1, 0), I(1999)) \ J(1, 2000, 0))
nwset, mat(__xt_big) name(big) nodenames(__xt_bl)
mata: st_local("lab7", __xt_bl[7])
capture noisily nwdropnodes big, nodes(`lab7')
xt_chk `=(_rc == 0)' "dropping a node by label in a network whose labels exceed 200,000 characters (got `=_rc')" // was bug S11 (fixed)
quietly nwname big
local n1 = r(nodes)
xt_chk `=(`n1' == 1999)' "2,000 nodes minus one: 1,999 (got `n1')" // was bug S11 (fixed)
nwdropnodes big, nodes(1/10)
quietly nwname big
xt_chk `=(r(nodes) == `n1' - 10)' "dropping ids 1/10: 10 fewer nodes (got `r(nodes)')"
xt_mat big __xt_M
mata: st_local("s", strofreal(sum(__xt_M)))
di as txt "  (ties left in the path: `s')"
mata: mata drop __xt_bl __xt_big
di "PASS I big"

capture mata: mata drop __xt_M __xt_A __xt_B __xt_K
xt_end
di "ALL PASS"
