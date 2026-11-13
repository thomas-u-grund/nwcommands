* xt_meas_clustering_triads_dyads.do -- extended tests for nwclustering, nwtriads and nwdyads.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: local / global / average clustering of a triangle, star, triangle with a tail, K4, U8 (igraph),
* empty and 1-node networks; directed mutual = undirected; valued networks whose ties all have one value
* give the binary numbers for every measure(); option and error codes (6556, 198, 99); a helper network
* left behind after an error; the user's own scalar clust_global; two-mode clustering with ra (hand-counted
* C4 and L3); every one of the 16 triad types on its own 3-node network (igraph / sna names checked in R);
* the census of D8 (igraph::triad_census); census sums to C(n,3) at 2,000 nodes; the native census against
* the Mata census (global NW_NOFASTKERNELS); the dyad census and reciprocity, lists of networks.
* U8: graph_from_edgelist(matrix(c(1,2,1,3,2,3,3,4,4,5,5,6,5,7,6,7,7,8),ncol=2,byrow=TRUE), directed=FALSE)
* D8: graph_from_edgelist(matrix(c(1,2,2,1,2,3,3,1,3,4,4,5,5,6,6,4,6,7,7,8,8,7,1,5),ncol=2,byrow=TRUE))
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_clustering_triads_dyads
nwclear

mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
mata: D8 = J(8,8,0)
mata: E = (1,2\2,1\2,3\3,1\3,4\4,5\5,6\6,4\6,7\7,8\8,7\1,5)
mata: for (k = 1; k <= rows(E); k++) D8[E[k,1], E[k,2]] = 1

* ---------------------------------------------------------------- (1) nwclustering: textbook values
nwclear
clear
nwset, mat(J(3,3,1) - I(3)) name(tri) undirected
nwclustering tri, generate(ct)
xa ct == 1 in 1/3
xa r(cluster_global) == 1 & r(cluster_avg) == 1
xa "`r(measure)'" == "binary"
* star: the centre 0, the leaves (one neighbour) missing
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwclustering star4, generate(cs)
xa cs[1] == 0
xa cs == . in 2/4
xa r(cluster_global) == 0
* triangle 1-2-3 with a tail 3-4: local (1, 1, 1/3, .); global 3/5; average 7/9
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(tt) undirected
nwclustering tt, generate(ctt)
xa ctt[1] == 1 & ctt[2] == 1 & reldif(ctt[3], 1/3) < 1e-7 & ctt[4] == .
xa reldif(r(cluster_global), 3/5) < 1e-12
xa reldif(r(cluster_avg), 7/9) < 1e-7
* U8: igraph::transitivity(U, "global") = 0.461538461538462 (= 6/13);
*     transitivity(U, "local") = 1 1 1/3 0 1/3 1 1/3 NaN; average over the defined values 4/7 (igraph localaverage 0.5714286)
nwset, mat(U8) name(u8) undirected
nwclustering u8, generate(cu)
xa reldif(r(cluster_global), 6/13) < 1e-12
xa reldif(r(cluster_avg), 4/7) < 1e-7
xa cu[4] == 0 & cu[8] == . & reldif(cu[5], 1/3) < 1e-7
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwclustering k4, generate(ck)
xa ck == 1 in 1/4
* no ties: every local value missing, the global value undefined
nwset, mat(J(3,3,0)) name(e3) undirected
nwclustering e3, generate(ce)
xa ce == . in 1/3
xa r(cluster_global) == .
nwset, mat((0)) name(one) undirected
nwclustering one, generate(c1)
xa c1[1] == .
di "(1) nwclustering textbook: ok"

* ---------------------------------------------------------------- (2) nwclustering: cross-routes
nwclear
clear
* the triangle with a tail declared directed with every tie reciprocated = undirected
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(ttd) directed
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(ttu) undirected
nwclustering ttd, generate(cd)
local gd = r(cluster_global)
nwclustering ttu, generate(cu)
xa reldif(r(cluster_global), `gd') < 1e-12
xa reldif(cd[3], cu[3]) < 1e-7 & cd[1] == cu[1]
* all ties 2: every weighted measure equals the binary one
nwset, mat(2 * (J(4,4,0) + (0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0))) name(ttv) undirected
nwclustering ttv, generate(cv)
xa "`r(measure)'" == "arithmetic"
xa reldif(r(cluster_global), 3/5) < 1e-9
foreach m in binary arithmetic geometric maximum minimum {
	nwclustering ttv, generate(cv_`m') measure(`m')
	xa reldif(r(cluster_global), 3/5) < 1e-9
	xa reldif(cv_`m'[3], 1/3) < 1e-7
}
* permuting the nodes permutes the local values
mata: A = (0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)
mata: p = (4\2\3\1)
mata: B = A[p, p]
nwset, mat(B) name(ttp) undirected
nwclustering ttp, generate(cp)
* node 3 of ttp is node 3 of tt (1/3), node 4 of ttp is node 1 of tt (1), node 1 of ttp is node 4 (missing)
xa reldif(cp[3], 1/3) < 1e-7 & cp[4] == 1 & cp[1] == .
mata: mata drop A B p
di "(2) nwclustering cross-routes: ok"

* ---------------------------------------------------------------- (3) nwclustering: errors, leftovers, user objects
nwclear
clear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(d3) directed
nwset, mat((0,2,1\2,0,3\1,3,0)) name(v3) undirected
nwset, mat((0,2,1\0,0,3\0,0,0)) name(dv3) directed
nwclustering v3, generate(w)
drop w
capture nwclustering v3
xa _rc == 198
capture nwclustering v3, generate(q) measure(foo)
xa _rc == 6556
capture nwclustering dv3, generate(q) measure(arithmetic)
xa _rc == 198
capture nwclustering v3, generate(q) ra
xa _rc == 198
capture nwclustering v3, generate(q) level(2)
xa _rc == 198
gen byte old = 7
capture nwclustering v3, generate(old)
xa _rc == 110
xa old == 7 in 1/3
* symmetrize without generate(): r(198) and no symmetrized helper network left
mata: st_local("n0", strofreal(__nw.nws.get_number()))
capture nwclustering d3, symmetrize
xa _rc == 198
mata: st_local("n1", strofreal(__nw.nws.get_number()))
* SUSPECTED BUG: generate() is checked after nwsym created the helper network
xa `n1' == `n0'    // fixed: CONFIRMED BUG M7b
* the leftover helper (a tempname) then blocks the next symmetrize call with r(483)
capture noisily nwclustering d3, symmetrize generate(cs)
xa _rc == 0    // fixed: CONFIRMED BUG M7b
if _rc {
	qui nwset
	foreach nn in `r(nets)' {
		if substr("`nn'", 1, 2) == "__" nwdrop `nn'
	}
	capture drop cs
	nwclustering d3, symmetrize generate(cs)
}
xa "`r(symmetrized)'" == "true"
* SUSPECTED BUG: nwclustering writes and drops a Stata scalar called clust_global
scalar clust_global = 42
nwclustering v3, generate(cg)
capture confirm scalar clust_global
xa _rc == 0    // fixed: CONFIRMED BUG M7a
xa scalar(clust_global) == 42    // fixed: CONFIRMED BUG M7a
di "(3) nwclustering errors: ok"

* ---------------------------------------------------------------- (4) nwclustering: two-mode, Robins-Alexander
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
end
nwset person org, twomode name(tm)
clear
* one 4-cycle (Peter-Oxford-Tim-LiU); 3-paths: sum over ties of (deg(u)-1)(deg(v)-1) = 0+2+2+1+1 = 6
nwclustering tm, ra
xa r(C4) == 1
xa r(L3) == 6
xa reldif(r(ra), 4/6) < 1e-9
nwclustering tm, generate(c2)
xa r(C_global) >= 0 & r(C_global) <= 1
capture nwclustering tm, generate(c2b) level(3)
xa _rc == 198
* two-mode measure() is checked as well
capture nwclustering tm, generate(c2c) measure(foo)
xa _rc == 6556
di "(4) nwclustering two-mode: ok"

* ---------------------------------------------------------------- (5) nwtriads: each type on its own
capture program drop xt_onetriad
program xt_onetriad
	args m want
	nwclear
	nwset, mat(`m') name(t3) directed
	nwtriads t3
	foreach c in 003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300 {
		local e = ("`c'" == "`want'")
		if r(_`c') != `e' {
			di as error "triad `want': r(_`c') = `=r(_`c')', expected `e'"
			exit 9
		}
	}
end
* 3-node networks; names as igraph::triad_census and sna::triad.census report them
xt_onetriad "(0,0,0\0,0,0\0,0,0)" 003
xt_onetriad "(0,1,0\0,0,0\0,0,0)" 012
xt_onetriad "(0,1,0\1,0,0\0,0,0)" 102
xt_onetriad "(0,1,1\0,0,0\0,0,0)" 021D
xt_onetriad "(0,1,0\0,0,0\0,1,0)" 021U
xt_onetriad "(0,1,0\0,0,1\0,0,0)" 021C
* 1<->2, 3->2: 111D;  1<->2, 2->3: 111U  (R: triad_census(make_empty_graph(3) + edges(...)))
xt_onetriad "(0,1,0\1,0,0\0,1,0)" 111D
xt_onetriad "(0,1,0\1,0,1\0,0,0)" 111U
xt_onetriad "(0,1,1\0,0,1\0,0,0)" 030T
xt_onetriad "(0,1,0\0,0,1\1,0,0)" 030C
xt_onetriad "(0,1,0\1,0,1\0,1,0)" 201
* 2->1, 2->3, 1<->3: 120D;  1->2, 3->2, 1<->3: 120U;  1->2, 2->3, 1<->3: 120C
xt_onetriad "(0,0,1\1,0,1\1,0,0)" 120D
xt_onetriad "(0,1,1\0,0,0\1,1,0)" 120U
xt_onetriad "(0,1,1\0,0,1\1,0,0)" 120C
* 1<->2, 2<->3, 1->3: 210
xt_onetriad "(0,1,1\1,0,1\0,1,0)" 210
xt_onetriad "(0,1,1\1,0,1\1,1,0)" 300
di "(5) nwtriads single types: ok"

* ---------------------------------------------------------------- (6) nwtriads: D8, undirected, small, large, both routes
nwclear
clear
nwset, mat(D8) name(d8) directed
nwtriads d8
* igraph::triad_census(D) = 11 23 9 2 2 5 1 1 0 1 0 0 0 1 0 0
xa r(_003) == 11 & r(_012) == 23 & r(_102) == 9 & r(_021D) == 2 & r(_021U) == 2 & r(_021C) == 5
xa r(_111D) == 1 & r(_111U) == 1 & r(_030T) == 0 & r(_030C) == 1 & r(_201) == 0
xa r(_120D) == 0 & r(_120U) == 0 & r(_120C) == 1 & r(_210) == 0 & r(_300) == 0
xa "`r(name)'" == "d8" & "`r(netname)'" == "d8"
* the Mata route gives the same census
global NW_NOFASTKERNELS 1
nwtriads d8
global NW_NOFASTKERNELS
xa r(_003) == 11 & r(_012) == 23 & r(_021C) == 5 & r(_120C) == 1 & r(_210) == 0 & r(_201) == 0
* undirected: star4 = three 2-edge triads and one empty triad; U8 transitivity = 6/13
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwtriads star4
xa r(_201) == 3 & r(_003) == 1 & r(_300) == 0
nwset, mat(U8) name(u8) undirected
nwtriads u8
xa r(_300) == 2
xa reldif(r(transitivity), 6/13) < 1e-12
* fewer than 3 nodes: no triads, no error
nwset, mat((0,1\1,0)) name(two) undirected
nwtriads two
xa r(_003) == 0 & r(_102) == 0 & r(_300) == 0
* the census adds up to C(n,3) at 2,000 nodes
set seed 7
nwrandom 2000, prob(.003) directed name(big)
nwtriads big
local tot = 0
foreach c in 003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300 {
	local tot = `tot' + r(_`c')
}
xa `tot' == 2000 * 1999 * 1998 / 6
* native against Mata on a 40-node random network
nwrandom 40, prob(.15) directed name(mid)
nwtriads mid
foreach c in 003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300 {
	local nat_`c' = r(_`c')
}
global NW_NOFASTKERNELS 1
nwtriads mid
global NW_NOFASTKERNELS
foreach c in 003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300 {
	xa r(_`c') == `nat_`c''
}
di "(6) nwtriads census: ok"

* ---------------------------------------------------------------- (7) nwdyads
nwclear
clear
nwset, mat(D8) name(d8) directed
nwdyads d8
* igraph::dyad_census(D): mut 2, asym 8, null 18
xa r(_100) == 2 & r(_010) == 8 & r(_001) == 18
xa reldif(r(reciprocity), .2) < 1e-12
xa "`r(name)'" == "d8"
nwset, mat(J(3,3,1) - I(3)) name(k3) undirected
nwdyads k3
xa r(_100) == 3 & r(_001) == 0
xa r(reciprocity) == 1
nwset, mat(J(3,3,0)) name(e3) directed
nwdyads e3
xa r(_001) == 3
xa r(reciprocity) == .
* a list: r() from the last network
nwdyads d8 k3
xa r(_100) == 3 & "`r(name)'" == "k3"
* valued directed with a non-integer value: the census counts ties
nwset, mat((0,.5,0\2,0,0\0,3,0)) name(v3) directed
nwdyads v3
xa r(_100) == 1 & r(_010) == 1 & r(_001) == 1
di "(7) nwdyads: ok"

mata: mata drop U8 D8 E k
nwclear
xt_mend
di "ALL PASS"
