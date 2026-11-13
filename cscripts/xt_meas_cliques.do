* xt_meas_cliques.do -- extended tests for nwclique, nwnclique, nwnclan and nwkplex.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: maximal cliques of a triangle with a tail, K4, an empty network (minsize 1 and 3), 1 node and
* 2 nodes with and without nomatrix (the 1 x 1 Mata subscript trap of Nov 2026), a directed cycle
* (symmetrized), valued ties, U8 (igraph::max_cliques), nomatrix = matrix route, the user's own scalar
* nw_ncliques / matrix nw_cliquematrix, lists (suffix 1, 2); n-cliques and n-clans of a path, a star and the
* 6-cycle (8 2-cliques but 6 2-clans, hand-counted), countonly / nomatrix / matrix agree; k-plexes of a
* path, a 4-cycle and K4; the default generate() name of nwkplex; every option range error.
* U8: graph_from_edgelist(matrix(c(1,2,1,3,2,3,3,4,4,5,5,6,5,7,6,7,7,8),ncol=2,byrow=TRUE), directed=FALSE)
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_cliques
nwclear

* ---------------------------------------------------------------- (1) nwclique
nwclear
clear
* triangle 1-2-3 with a tail 3-4
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(tt) undirected
nwclique tt, generate(q3)
xa r(cliques) == 1
xa q3[1] == 3 & q3[2] == 3 & q3[3] == 3 & q3[4] == .
matrix CM = r(clique_matrix)
xa rowsof(CM) == 1 & colsof(CM) == 4
xa CM[1,4] == 0 & CM[1,1] == 1
nwclique tt, generate(q2) minsize(2)
xa r(cliques) == 2
xa q2[3] == 3 & q2[4] == 2
* nomatrix: the same variable and count, no matrix
nwclique tt, generate(q2n) minsize(2) nomatrix
xa r(cliques) == 2
xa q2n == q2 in 1/4
mata: st_local("hasm", strofreal(rows(st_matrix("r(clique_matrix)")) > 0))
xa `hasm' == 0
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwclique k4, generate(qk)
xa r(cliques) == 1 & qk == 4 in 1/4
* no ties: minsize(1) gives one clique per node; minsize(3) none (one row of zeros in the matrix)
nwset, mat(J(3,3,0)) name(e3) undirected
nwclique e3, generate(qe1) minsize(1)
xa r(cliques) == 3 & qe1 == 1 in 1/3
nwclique e3, generate(qe3)
xa r(cliques) == 0 & qe3 == . in 1/3
matrix CM = r(clique_matrix)
xa rowsof(CM) == 1
* 1 node and 2 nodes, both routes
nwset, mat((0)) name(one) undirected
nwclique one, generate(q1) minsize(1)
xa r(cliques) == 1 & q1[1] == 1
nwclique one, generate(q1n) minsize(1) nomatrix
xa r(cliques) == 1 & q1n[1] == 1
nwset, mat((0,1\1,0)) name(two) undirected
nwclique two, generate(qt) minsize(2) nomatrix
xa r(cliques) == 1 & qt[1] == 2 & qt[2] == 2
* directed 3-cycle: symmetrized, one clique of 3
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc) directed
nwclique cyc, generate(qc)
xa r(cliques) == 1 & qc == 3 in 1/3
* valued ties are ties
nwset, mat((0,2.5,.1\2.5,0,-1\.1,-1,0)) name(v3) undirected
nwclique v3, generate(qv)
xa r(cliques) == 1
* U8: length(igraph::max_cliques(U, min = 3)) = 2
mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
nwset, mat(U8) name(u8) undirected
nwclique u8, generate(qu)
xa r(cliques) == 2
mata: mata drop U8 E k
* errors
capture nwclique tt, generate(qx) minsize(0)
xa _rc == 198
capture nwclique tt
xa _rc == 198
capture nwclique tt, generate(q3)
xa _rc == 99
* a list: variables ql1, ql2
nwclique tt k4, generate(ql)
confirm variable ql1 ql2, exact
xa ql2 == 4 in 1/4
di "(1) nwclique: ok"

* ---------------------------------------------------------------- (2) nwclique: the user's own scalar and matrix
* SUSPECTED BUG: nwclique.ado writes the Stata scalar nw_ncliques and the matrix nw_cliquematrix under these
* plain names (test_stata_userspace.do does not list them).  Expected: the user's objects are untouched.
nwclear
clear
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
scalar nw_ncliques = -5
matrix nw_cliquematrix = (9, 9)
nwclique k4, generate(qq)
xa r(cliques) == 1
capture confirm scalar nw_ncliques
xa _rc == 0    // fixed: CONFIRMED BUG M8
xa scalar(nw_ncliques) == -5    // fixed: CONFIRMED BUG M8
capture confirm matrix nw_cliquematrix
xa _rc == 0    // fixed: CONFIRMED BUG M8
xa nw_cliquematrix[1,1] == 9 & colsof(nw_cliquematrix) == 2    // fixed: CONFIRMED BUG M8
di "(2) nwclique user objects: ok"

* ---------------------------------------------------------------- (3) nwnclique and nwnclan
nwclear
clear
* path 1-2-3-4, n = 2: {1,2,3} and {2,3,4}, both also 2-clans
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwnclique p4, n(2) generate(np)
xa r(ncliques) == 2
xa np == 3 in 1/4
nwnclan p4, n(2) generate(cp)
xa r(nclans) == 2
* star with 4 leaves, n = 2: all 5 nodes
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(star5) undirected
nwnclique star5, n(2) generate(ns)
xa r(ncliques) == 1 & ns == 5 in 1/5
* the 6-cycle, n = 2: the six consecutive triples and {1,3,5}, {2,4,6} are maximal 2-cliques (8);
* {1,3,5} and {2,4,6} induce no ties (diameter infinite), so there are 6 2-clans
nwset, mat((0,1,0,0,0,1\1,0,1,0,0,0\0,1,0,1,0,0\0,0,1,0,1,0\0,0,0,1,0,1\1,0,0,0,1,0)) name(c6) undirected
nwnclique c6, n(2) generate(nc)
xa r(ncliques) == 8
matrix NM = r(nclique_matrix)
xa rowsof(NM) == 8
nwnclan c6, n(2) generate(cc)
xa r(nclans) == 6
* countonly and nomatrix give the same count
nwnclique c6, n(2) countonly
xa r(ncliques) == 8 & r(maxsize) == 3
matrix ST = r(size_table)
* columns size, count: 8 sets of size 3
mata: ST = st_matrix("ST")
xm assert(sum(ST[., 2] :* (ST[., 1] :== 3)) == 8)
mata: mata drop ST
nwnclique c6, n(2) generate(ncn) nomatrix
xa r(ncliques) == 8
xa ncn == nc in 1/6
nwnclan c6, n(2) countonly
xa r(nclans) == 6
* n = 3 on the 6-cycle: every pair within distance 3 -> one set of 6
nwnclique c6, n(3) generate(nc3)
xa r(ncliques) == 1 & nc3 == 6 in 1/6
* tiny networks through every route (1 x 1 subscripts)
nwset, mat((0)) name(one) undirected
nwnclique one, n(2) minsize(1) generate(n1)
nwnclique one, n(2) minsize(1) generate(n1n) nomatrix
nwnclique one, n(2) minsize(1) countonly
xa r(ncliques) == 1
nwnclan one, n(2) minsize(1) generate(c1n) nomatrix
nwset, mat((0,1\1,0)) name(two) undirected
nwnclique two, n(2) minsize(2) generate(n2n) nomatrix
xa r(ncliques) == 1 & n2n[1] == 2 & n2n[2] == 2
* errors
capture nwnclique p4, n(1) generate(x)
xa _rc == 198
capture nwnclique p4, n(2) minsize(0) generate(x)
xa _rc == 198
capture nwnclique p4, n(2) maxcliques(0) generate(x)
xa _rc == 198
capture nwnclique p4, n(2) maxtime(0) generate(x)
xa _rc == 198
capture nwnclique p4, n(2)
xa _rc == 198
capture nwnclique p4, n(2) generate(np)
xa _rc == 99
capture nwnclan p4, n(1) generate(x)
xa _rc == 198
capture nwnclan p4, n(2)
xa _rc == 198
di "(3) nwnclique and nwnclan: ok"

* ---------------------------------------------------------------- (4) nwkplex
nwclear
clear
* path 1-2-3-4, k = 2 (each member may miss 2 ties incl. itself: needs size - 2 neighbours in the set):
* {1,2,3} and {2,3,4}; the whole path fails (node 1 has 1 neighbour, needs 2)
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwkplex p4, k(2) generate(kp)
xa r(kplexes) == 2
xa kp == 3 in 1/4
* 4-cycle: every node has 2 neighbours in the set of 4 -> one 2-plex of size 4
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(c4) undirected
nwkplex c4, k(2) generate(kc)
xa r(kplexes) == 1 & kc == 4 in 1/4
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwkplex k4, k(2) generate(kk)
xa r(kplexes) == 1 & kk == 4 in 1/4
* countonly / nomatrix agree
nwkplex p4, k(2) countonly
xa r(kplexes) == 2 & r(maxsize) == 3
nwkplex p4, k(2) generate(kpn) nomatrix
xa kpn == kp in 1/4
* without generate(): the documented default name _kplexnum (unlike nwnclique / nwnclan, which require it)
nwkplex c4, k(2)
confirm variable _kplexnum, exact
* errors
capture nwkplex p4, k(1) generate(x)
xa _rc == 198
capture nwkplex p4, k(2) minsize(0) generate(x)
xa _rc == 198
capture nwkplex p4, k(2) maxplexes(0) generate(x)
xa _rc == 198
capture nwkplex p4, k(2) maxtime(0) generate(x)
xa _rc == 198
capture nwkplex p4, k(2) generate(kp)
xa _rc == 99
* tiny
nwset, mat((0)) name(one) undirected
nwkplex one, k(2) minsize(1) generate(k1n) nomatrix
xa k1n[1] == 1
di "(4) nwkplex: ok"

nwclear
xt_mend
di "ALL PASS"
