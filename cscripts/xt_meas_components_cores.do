* xt_meas_components_cores.do -- extended tests for nwcomponents, nwkcore and nwkcomponents.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: 1 node, 2 nodes, all isolates, two separate edges, an isolate inside a network, weak components
* of a directed network, lgc (also with two largest components of equal size), valued networks (values
* ignored, a negative value is a tie), r(components) / r(comp_sizeid), lists of networks (suffix k = 1, 2),
* coreness of K4, star, path, U8 (igraph::coreness) and K4 + pendant, r(maxcore) / r(core_sizeid),
* k-components of a bow-tie, a path (none), K4 with k = 3, nomatrix, tiny networks, error codes, and a
* 2,000-node random network (sizes add up to the number of nodes, permutation invariance).
* Component ids are not asserted; the partition is.
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_components_cores
nwclear

* ---------------------------------------------------------------- (1) nwcomponents: small cases
nwclear
clear
nwset, mat((0)) name(one) undirected
nwcomponents one, generate(c1)
xa r(components) == 1
xa c1[1] < .
nwset, mat((0,1\1,0)) name(two) undirected
nwcomponents two, generate(c2)
xa r(components) == 1
xa c2[1] == c2[2]
nwset, mat(J(4,4,0)) name(iso4) undirected
nwcomponents iso4, generate(ci)
xa r(components) == 4
xm assert(rows(uniqrows(st_data((1,4), "ci"))) == 4)
* two separate edges
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected
nwcomponents dis, generate(cd)
xa r(components) == 2
xa cd[1] == cd[2] & cd[3] == cd[4] & cd[1] != cd[3]
matrix S = r(comp_sizeid)
xa rowsof(S) == 2 & colsof(S) == 3
xa S[1,1] == 2 & S[2,1] == 2
xa reldif(S[1,3], .5) < 1e-12
* path 1-2-3 plus an isolate; lgc marks the path
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,0\0,0,0,0)) name(piso) undirected
nwcomponents piso, generate(cp)
xa r(components) == 2
matrix S = r(comp_sizeid)
* sorted by size: the path (3 nodes) first
xa S[1,1] == 3 & S[2,1] == 1
xa reldif(S[1,3], .75) < 1e-12
nwcomponents piso, generate(lg) lgc
xa lg[1] == 1 & lg[2] == 1 & lg[3] == 1 & lg[4] == 0
* two largest components of the same size: exactly one of them is marked, as a whole
nwcomponents dis, generate(lgd) lgc
qui count if lgd == 1 in 1/4
xa r(N) == 2
xa lgd[1] == lgd[2] & lgd[3] == lgd[4]
di "(1) nwcomponents small cases: ok"

* ---------------------------------------------------------------- (2) nwcomponents: directed, valued, lists
nwclear
clear
* 1 -> 2 <- 3: one weak component (help: the direction is ignored)
nwset, mat((0,1,0\0,0,0\0,1,0)) name(dw) directed
nwcomponents dw, generate(cw)
xa r(components) == 1
* valued with a negative and a non-integer value: the same partition as the binary network
nwset, mat((0,-2,0,0\-2,0,0,0\0,0,0,.3\0,0,.3,0)) name(vd) undirected
nwcomponents vd, generate(cv)
xa r(components) == 2
xa cv[1] == cv[2] & cv[3] == cv[4] & cv[1] != cv[3]
* a list of two networks: variables cl1 and cl2, r() from the last network
nwset, mat((0,1,0\1,0,0\0,0,0)) name(a3) undirected
nwset, mat(J(3,3,1) - I(3)) name(b3) undirected
nwcomponents a3 b3, generate(cl)
confirm variable cl1 cl2, exact
xa r(components) == 1
xa cl1[1] == cl1[2] & cl1[1] != cl1[3]
* errors
capture nwcomponents a3
xa _rc == 198
gen byte old = 7
capture nwcomponents a3, generate(old)
xa _rc == 110
xa old == 7 in 1/3
nwcomponents a3, generate(old) replace
xa old[1] == old[2]
di "(2) nwcomponents directed, valued, lists: ok"

* ---------------------------------------------------------------- (3) nwcomponents: 2,000 nodes
nwclear
clear
set seed 2026
nwrandom 2000, prob(.0008) undirected name(big)
nwcomponents big, generate(cb) silent
local ncomp = r(components)
matrix S = r(comp_sizeid)
xa rowsof(S) == `ncomp'
xm assert(sum((st_matrix("S"))[., 1]) == 2000)
xm assert(abs(sum((st_matrix("S"))[., 3]) - 1) < 1e-9)
xm assert(rows(uniqrows(st_data((1,2000), "cb"))) == `ncomp')
* the same network with the nodes in another order has the same number of components
nwtomata big, mat(B)
mata: p = jumble((1::2000))
mata: B2 = B[p, p]
nwset, mat(B2) name(bigp) undirected
nwcomponents bigp, generate(cb2) silent
xa r(components) == `ncomp'
mata: mata drop B B2 p
di "(3) nwcomponents 2,000 nodes: ok"

* ---------------------------------------------------------------- (4) nwkcore
nwclear
clear
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwkcore k4, generate(ck)
xa ck == 3 in 1/4
xa r(maxcore) == 3
matrix S = r(core_sizeid)
xa rowsof(S) == 1 & S[1,1] == 4 & S[1,2] == 3
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwkcore star4, generate(cs)
xa cs == 1 in 1/4
nwset, mat(J(3,3,0)) name(iso3) undirected
nwkcore iso3, generate(c0)
xa c0 == 0 in 1/3
xa r(maxcore) == 0
* K4 plus a pendant node 5 attached to node 1
nwset, mat((0,1,1,1,1\1,0,1,1,0\1,1,0,1,0\1,1,1,0,0\1,0,0,0,0)) name(k4p) undirected
nwkcore k4p, generate(cp)
xa cp[1] == 3 & cp[4] == 3 & cp[5] == 1
matrix S = r(core_sizeid)
xa rowsof(S) == 2
xa S[1,1] == 4 & S[1,2] == 3 & S[2,1] == 1
* U8: igraph::coreness(U) = 2 2 2 2 2 2 2 1
mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
nwset, mat(U8) name(u8) undirected
nwkcore u8, generate(cu)
xm assert(st_data((1,8), "cu")' == (2,2,2,2,2,2,2,1))
mata: mata drop U8 E k
nwset, mat((0)) name(one) undirected
nwkcore one, generate(c1)
xa c1[1] == 0
* valued: values ignored
nwset, mat(2.5 * (J(4,4,1) - I(4))) name(k4v) undirected
nwkcore k4v, generate(ckv)
xa ckv == 3 in 1/4
capture nwkcore k4
xa _rc == 198
capture nwkcore k4, generate(ck)
xa _rc == 110
di "(4) nwkcore: ok"

* ---------------------------------------------------------------- (5) nwkcomponents
nwclear
clear
* bow-tie: triangles 1-2-3 and 3-4-5 share node 3: two 2-components of size 3
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,1\0,0,1,0,1\0,0,1,1,0)) name(bow) undirected
nwkcomponents bow, k(2) generate(kb)
xa r(kcomponents) == 2
xa kb == 3 in 1/5
matrix KM = r(kcomp_matrix)
xa rowsof(KM) == 2 & colsof(KM) == 5
* node 3 is in both
xa KM[1,3] == 1 & KM[2,3] == 1
* a path has no 2-component (help: a k-component has at least k + 1 nodes and connectivity k): missing for every node, r(kcomp_matrix) one row of zeros
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwkcomponents p4, k(2) generate(kp)
xa r(kcomponents) == 0
xa kp == . in 1/4
matrix KM = r(kcomp_matrix)
xa rowsof(KM) == 1
* K4: one 3-component of size 4
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwkcomponents k4, k(3) generate(kk)
xa r(kcomponents) == 1
xa kk == 4 in 1/4
* nomatrix: no r(kcomp_matrix), the same variable
nwkcomponents bow, k(2) generate(kb2) nomatrix
xa r(kcomponents) == 2
mata: st_local("hasm", strofreal(rows(st_matrix("r(kcomp_matrix)")) > 0))
xa `hasm' == 0
xa kb2 == kb in 1/5
* tiny networks (1 x 1 subscripts): no error
nwset, mat((0)) name(one) undirected
nwkcomponents one, k(2) generate(k1)
xa r(kcomponents) == 0
nwkcomponents one, k(2) generate(k1n) nomatrix
nwset, mat((0,1\1,0)) name(two) undirected
nwkcomponents two, k(2) generate(k2)
xa r(kcomponents) == 0
* errors
capture nwkcomponents bow, k(0) generate(kx)
xa _rc == 198
capture nwkcomponents bow, k(2)
xa _rc == 198
capture nwkcomponents bow, k(2) generate(kb)
xa _rc == 110
di "(5) nwkcomponents: ok"

nwclear
xt_mend
di "ALL PASS"
