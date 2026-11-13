* xt_meas_geodesic_path_reach.do -- extended tests for nwgeodesic, nwpath and nwreach.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: r() of nwgeodesic on path, star, K4, U8 (igraph), 1 node, a disconnected network (the -1 and
* *_connected results), unconnected(max) and unconnected(#), directed with and without sym, valued
* (cost 1/value, alpha(-1) = values as lengths, binary), generate() eccentricity incl. an abbreviating
* variable name, networks left after an error, nwpath (one path, two tied paths, no path, egoid/alterid,
* directed, valued cost, generate() networks, ego = alter, all error codes), nwreach on directed,
* symmetrized, disconnected and valued networks, name()/nwreplace.
* U8: igraph graph_from_edgelist(matrix(c(1,2,1,3,2,3,3,4,4,5,5,6,5,7,6,7,7,8),ncol=2,byrow=TRUE), directed=FALSE)
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_geodesic_path_reach
nwclear

* ---------------------------------------------------------------- (1) nwgeodesic: r() on textbook networks
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(path4) undirected labs(a,b,c,d)
nwgeodesic path4, generate(ecc)
* distances 1,2,3,1,2,1 over 6 pairs: 10/6
xa r(nodes) == 4
xa r(numpaths) == 6
xa r(unconnected) == 0
xa reldif(r(avgpath), 10/6) < 1e-12
xa r(diameter) == 3
xa r(radius) == 2
xa "`r(netname)'" == "path4"
xa "`r(geodesic)'" == "_geodesic"
xa ecc[1] == 3 & ecc[2] == 2 & ecc[3] == 2 & ecc[4] == 3
nwtomata _geodesic, mat(G)
xm assert(G[1,4] == 3 & G[4,1] == 3 & G[2,4] == 2)
* the source network is not changed
nwtomata path4, mat(P)
xm assert(P[1,3] == 0 & P[1,2] == 1)
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwgeodesic star4, name(gs)
xa reldif(r(avgpath), 1.5) < 1e-12
xa r(diameter) == 2 & r(radius) == 1
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwgeodesic k4, name(gk)
xa r(avgpath) == 1 & r(diameter) == 1 & r(radius) == 1
* U8: mean_distance(U) = 2.42857142857143, diameter(U) = 5, radius(U) = 3, eccentricity(U) = 5 5 4 3 3 4 4 5
mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
nwset, mat(U8) name(u8) undirected
nwgeodesic u8, name(gu) generate(eccu)
xa reldif(r(avgpath), 2.42857142857143) < 1e-9
xa r(diameter) == 5 & r(radius) == 3
xm assert(st_data((1,8), "eccu")' == (5,5,4,3,3,4,4,5))
mata: mata drop U8 E k G P
di "(1) nwgeodesic textbook: ok"

* ---------------------------------------------------------------- (2) nwgeodesic: disconnected, unconnected(), directed, 1 node
nwclear
clear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected
nwgeodesic dis, name(gd)
* 4 unordered pairs are not connected
xa r(unconnected) == 4
xa r(avgpath) == -1 & r(diameter) == -1 & r(radius) == -1
xa reldif(r(connected), 4/12) < 1e-12
xa r(avgpath_connected) == 1
xa r(diameter_connected) == 1
* unconnected(max): the missing distances become max + 1 = 2 -> (2 x 1 + 4 x 2) / 6
nwgeodesic dis, name(gd2) unconnected(max)
xa r(unconnected) == 4
xa reldif(r(avgpath), 10/6) < 1e-12
xa r(diameter) == 2
nwgeodesic dis, name(gd3) unconnected(10)
xa reldif(r(avgpath), 42/6) < 1e-12
* directed path 1 -> 2 -> 3: 3 of the 6 ordered pairs are not connected
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
nwgeodesic dp3, name(gdp)
xa r(numpaths) == 6
xa r(unconnected) == 3
xa reldif(r(avgpath_connected), 4/3) < 1e-12
xa reldif(r(connected), .5) < 1e-12
xa "`r(symmetrized)'" == "false"
nwgeodesic dp3, name(gdps) sym
xa r(unconnected) == 0
xa "`r(symmetrized)'" == "true"
xa r(diameter) == 2
* the temporary symmetrized network is gone
* networks now: dis gd gd2 gd3 dp3 gdp gdps
mata: st_local("nn", strofreal(__nw.nws.get_number()))
xa `nn' == 7
* one node: no pairs; must not error
nwset, mat((0)) name(one) undirected
nwgeodesic one, name(g1)
xa r(nodes) == 1
xa r(numpaths) == 0
di "(2) nwgeodesic edge cases: ok"

* ---------------------------------------------------------------- (3) nwgeodesic: valued
nwclear
clear
* path 1-2 (2), 2-3 (4)
nwset, mat((0,2,0\2,0,4\0,4,0)) name(vp) undirected
nwgeodesic vp, name(gv)
xa r(alpha) == 1
nwtomata gv, mat(V)
xm assert(abs(V[1,3] - .75) < 1e-12 & abs(V[1,2] - .5) < 1e-12)
nwgeodesic vp, name(gvm) alpha(-1)
nwtomata gvm, mat(V)
xm assert(abs(V[1,3] - 6) < 1e-12)
nwgeodesic vp, name(gvb) binary
nwtomata gvb, mat(V)
xm assert(V[1,3] == 2)
* all ties 1 with the valued flag: the same distances as the binary network
nwset, mat((0,1,0\1,0,1\0,1,0)) name(ones) undirected valued
nwgeodesic ones, name(go)
xa r(diameter) == 2
mata: mata drop V
di "(3) nwgeodesic valued: ok"

* ---------------------------------------------------------------- (4) nwgeodesic: errors, leftovers, generate()
nwclear
clear
nwset, mat((0,1,0\1,0,4\0,4,0)) name(v3) undirected
nwgeodesic v3, name(mine)
capture nwgeodesic v3, name(mine)
xa _rc == 483
nwgeodesic v3, name(mine) nwreplace
nwgeodesic v3
capture nwgeodesic v3, noreplace
xa _rc == 483
mata: st_local("n0", strofreal(__nw.nws.get_number()))
capture nwgeodesic v3, name(newone) binary alpha(.5)
xa _rc == 198
mata: st_local("n1", strofreal(__nw.nws.get_number()))
* SUSPECTED BUG: the binary/alpha() check runs after nwduplicate created the result network
xa `n1' == `n0'    // fixed: CONFIRMED BUG M4a
capture nwname newone
xa _rc != 0    // fixed: CONFIRMED BUG M4a
* eccentricity variable exists: r(99) without nwreplace
set obs 3
gen byte ec = 7
capture nwgeodesic v3, name(g2) generate(ec)
xa _rc == 110
xa ec == 7 in 1/3
* SUSPECTED BUG: `confirm variable' and `capture drop' without exact: with an existing variable eclong,
* generate(ecx) is fine, but generate(ecl) is taken as eclong (r(99)) and with nwreplace eclong is dropped
gen eclong = 1
capture noisily nwgeodesic v3, name(g3a) generate(ecl)
xa _rc == 0    // fixed: CONFIRMED BUG M4b
capture drop ecl
nwgeodesic v3, name(g3) generate(ecl) nwreplace
capture confirm variable eclong, exact
xa _rc == 0    // fixed: CONFIRMED BUG M4b
xa eclong == 1 in 1/3    // fixed: CONFIRMED BUG M4b
capture confirm variable ecl, exact
xa _rc == 0
di "(4) nwgeodesic errors: ok"

* ---------------------------------------------------------------- (5) nwpath
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected labs(a,b,c,d)
nwpath p4, ego(a) alter(d)
xa r(paths) == 1
xa r(path_length) == 3 & r(path_shortest) == 3
xa r(ego) == 1 & r(alter) == 4
matrix PM = r(paths_matrix)
xa PM[1,1] == 1 & PM[1,2] == 2 & PM[1,3] == 3 & PM[1,4] == 4
* by id
nwpath p4, egoid(1) alterid(4) nopaths
xa r(path_length) == 3
* a 4-cycle a-b-c-d-a: two shortest paths from a to c
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(c4) undirected labs(a,b,c,d)
nwpath c4, ego(a) alter(c)
xa r(paths) == 2
xa r(path_length) == 2
matrix PM = r(paths_matrix)
xa rowsof(PM) == 2
* no path: 0 paths, length -1, no r(paths_matrix)
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected labs(a,b,c,d)
nwpath dis, ego(a) alter(d)
xa r(paths) == 0
xa r(path_length) == -1
mata: st_local("hasm", strofreal(rows(st_matrix("r(paths_matrix)")) > 0))
xa `hasm' == 0
* directed 1 -> 2 -> 3: no path back; sym finds one of length 2
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed labs(a,b,c)
nwpath dp3, ego(c) alter(a)
xa r(path_length) == -1
nwpath dp3, ego(c) alter(a) sym
xa r(path_length) == 2
* the temporary symmetrized network is removed
mata: st_local("nn", strofreal(__nw.nws.get_number()))
xa `nn' == 4
* valued triangle a-b (1), b-c (1), a-c (.1): weighted path a-b-c, cost 2, 2 steps; binary: a-c, 1 step
nwset, mat((0,1,.1\1,0,1\.1,1,0)) name(tri) undirected labs(a,b,c)
nwpath tri, ego(a) alter(c)
xa r(path_length) == 2
xa reldif(r(path_cost), 2) < 1e-12
nwpath tri, ego(a) alter(c) binary
xa r(path_length) == 1
* alpha(.5): via b costs 2, direct costs .1^-.5 = 3.16
nwpath tri, ego(a) alter(c) alpha(.5)
xa reldif(r(path_cost), 2) < 1e-12
di "(5) nwpath: ok"

* ---------------------------------------------------------------- (6) nwpath: generate(), ego = alter, errors
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected labs(a,b,c,d)
nwpath p4, ego(a) alter(c) generate(sp)
nwsummarize sp_1
xa r(nodes) == 4
nwtomata sp_1, mat(S)
xm assert(S[1,2] == 1 & S[2,3] == 1 & S[3,4] == 0 & S[1,3] == 0)
* undirected: the path network must be symmetric (the dense branch of nw_path_net sets one direction only)
xm assert(S[2,1] == 1 & S[3,2] == 1)    // fixed: CONFIRMED BUG N2
mata: mata drop S
capture nwpath p4, ego(a) alter(c) generate(sp)
xa _rc == 483
nwpath p4, ego(a) alter(c) generate(sp) nwreplace
* ego = alter: the trivial path of length 0 (igraph), also with generate() (a network without ties)
capture noisily nwpath p4, ego(b) alter(b) generate(selfp)
xa _rc == 0
xa r(paths) == 1 & r(path_length) == 0
nwsummarize selfp_1
xa r(nodes) == 4 & r(edges) == 0
* error codes (nwerrorcodes): 485 a node that does not exist or an id out of range, 483 a path network that
* exists, 198 wrong or missing options
capture noisily nwpath p4, alter(c)
xa _rc == 198
capture noisily nwpath p4, ego(a)
xa _rc == 198
capture nwpath p4, egoid(9) alterid(1)
xa _rc == 485
capture nwpath p4, ego(zz) alter(a)
xa _rc == 485
capture nwpath p4, ego(a) alter(c) sym generate(q)
xa _rc == 198
nwset, mat((0,2\2,0)) name(v2) undirected labs(a,b)
capture nwpath v2, ego(a) alter(b) binary alpha(1)
xa _rc == 198
capture nwpath v2, ego(a) alter(b) alpha(x)
xa _rc == 198
di "(6) nwpath generate and errors: ok"

* ---------------------------------------------------------------- (7) nwreach
nwclear
clear
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
nwreach dp3
nwtomata _reach, mat(R)
xm assert(R[1,2] == 1 & R[1,3] == 1 & R[2,3] == 1)
xm assert(R[2,1] == 0 & R[3,1] == 0 & R[3,2] == 0)
capture nwreach dp3
xa _rc == 483
nwreach dp3, nwreplace sym
nwtomata _reach, mat(R)
xm assert(R[3,1] == 1 & R[2,1] == 1)
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected
nwreach dis, name(rdis)
nwtomata rdis, mat(R)
xm assert(R[1,2] == 1 & R[1,3] == 0 & R[4,1] == 0 & R[3,4] == 1)
* valued: the reach network is binary
nwset, mat((0,2.5,0\2.5,0,0\0,0,0)) name(v3) undirected
nwreach v3, name(rv)
nwtomata rv, mat(R)
xm assert(R[1,2] == 1 & R[1,3] == 0)
nwsummarize rv
xa "`r(valued)'" == "false"
mata: mata drop R
di "(7) nwreach: ok"

nwclear
xt_mend
di "ALL PASS"
