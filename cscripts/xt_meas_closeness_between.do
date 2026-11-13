* xt_meas_closeness_between.do -- extended tests for nwcloseness and nwbetween.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: 1 node, 2 nodes, isolates, K4, star, path, disconnected network, an isolate inside a network,
* directed (sym default vs nosym), valued (cost 1/value, binary, alpha(0), all-ones vs binary), the fast
* kernel against the Mata/nwgeodesic route (nwcloseness with a no-op unconnected() forces the slow route),
* standardize, centralization r(bw_central), node permutation, error codes, networks left behind after
* errors, hard-coded helper network names, and a 2,000-node path (closed-form betweenness and closeness).
* R references: igraph 2.x, the calls are next to the numbers.  U8 below is
*   U <- graph_from_edgelist(matrix(c(1,2,1,3,2,3,3,4,4,5,5,6,5,7,6,7,7,8),ncol=2,byrow=TRUE), directed=FALSE)
* D8 is
*   D <- graph_from_edgelist(matrix(c(1,2,2,1,2,3,3,1,3,4,4,5,5,6,6,4,6,7,7,8,8,7,1,5),ncol=2,byrow=TRUE))
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_closeness_between
nwclear

capture program drop xt_cmp
program xt_cmp
	* variable v (rows 1..n) against a Mata row vector, absolute tolerance
	args v expect tol
	mata: __xte = `expect'
	mata: st_numscalar("__xtd", max(abs(st_data((1, cols(__xte)), "`v'") - __xte')))
	mata: mata drop __xte
	xa scalar(__xtd) < `tol'
	scalar drop __xtd
end

* ---------------------------------------------------------------- (1) closeness: textbook values
nwclear
clear
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwcloseness k4, generate(c f n)
xa reldif(c[1], 1) < 1e-7 & f[1] == 3
xa reldif(n[1], 1/3) < 1e-7
* star: centre farness 3 (closeness 1); leaf farness 1 + 2 + 2 = 5 (closeness 3/5)
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwcloseness star4, generate(cs fs ns)
xa fs[1] == 3 & fs[2] == 5
xa reldif(cs[1], 1) < 1e-7 & reldif(cs[2], .6) < 1e-7
xa reldif(ns[2], .2) < 1e-7
* path 1-2-3-4: farness 6, 4, 4, 6
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(path4) undirected
nwcloseness path4, generate(cp fp np)
xa fp[1] == 6 & fp[2] == 4 & fp[3] == 4 & fp[4] == 6
xa reldif(cp[1], .5) < 1e-7 & reldif(cp[2], .75) < 1e-7
* U8 against igraph::closeness(U, normalized=TRUE)
mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
nwset, mat(U8) name(u8) undirected
nwcloseness u8, generate(cu fu nu)
xt_cmp cu "(0.35,0.35,0.466666666666667,0.538461538461538,0.538461538461538,0.411764705882353,0.4375,0.318181818181818)" 1e-6
di "(1) closeness textbook values: ok"

* ---------------------------------------------------------------- (2) closeness: tiny, disconnected, isolate, directed
nwclear
clear
nwset, mat((0)) name(one) undirected
nwcloseness one, generate(c1 f1 n1)
xa c1[1] == . & n1[1] == .
nwset, mat((0,1\1,0)) name(two) undirected
nwcloseness two, generate(c2 f2 n2)
xa f2[1] == 1 & reldif(c2[1], 1) < 1e-7
* two separate edges 1-2, 3-4: each node reaches one node at distance 1 -> closeness 1/1 (as igraph)
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected
nwcloseness dis, generate(cd fd nd)
xa reldif(cd[1], 1) < 1e-7 & reldif(cd[4], 1) < 1e-7
* legacy: (nodes - 1) / farness = 3
nwcloseness dis, generate(cdl fdl ndl) legacy
xa reldif(cdl[1], 3) < 1e-7
* path 1-2-3 plus an isolate 4: the isolate has no closeness (igraph gives NaN)
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,0\0,0,0,0)) name(piso) undirected
nwcloseness piso, generate(ci fi ni)
xa ci[4] == .
xa reldif(ci[1], 2/3) < 1e-7 & reldif(ci[2], 1) < 1e-7
* directed path 1 -> 2 -> 3: default symmetrizes (= undirected path 3)
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
nwcloseness dp3, generate(cy fy ny)
xa reldif(cy[1], 2/3) < 1e-7 & reldif(cy[2], 1) < 1e-7 & reldif(cy[3], 2/3) < 1e-7
* nosym: out-distances (igraph::closeness(mode = "out", normalized = TRUE)): 2/3, 1, NaN
nwcloseness dp3, generate(cz fz nz) nosym
xa reldif(cz[1], 2/3) < 1e-7 & reldif(cz[2], 1) < 1e-7
xa cz[3] == .
di "(2) closeness edge cases: ok"

* ---------------------------------------------------------------- (3) closeness: valued, and fast route = slow route
nwclear
clear
* path 1-2 (value 2), 2-3 (value 4); cost 1/value: d12 = .5, d23 = .25, d13 = .75
nwset, mat((0,2,0\2,0,4\0,4,0)) name(vp) undirected
nwcloseness vp, generate(cv fv nv)
xa reldif(fv[1], 1.25) < 1e-7 & reldif(fv[2], .75) < 1e-7 & reldif(fv[3], 1) < 1e-7
xa reldif(cv[1], 2/1.25) < 1e-7 & reldif(cv[2], 2/.75) < 1e-7 & reldif(cv[3], 2) < 1e-7
nwcloseness vp, generate(cvb fvb nvb) binary
xa reldif(cvb[1], 2/3) < 1e-7 & reldif(cvb[2], 1) < 1e-7
* alpha(0) on a valued network counts steps, as binary
nwcloseness vp, generate(cva fva nva) alpha(0)
xa reldif(cva[1], cvb[1]) < 1e-7 & reldif(cva[2], cvb[2]) < 1e-7
* all ties 1 with the valued flag = the binary network
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(ones) undirected valued
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(bins) undirected
nwcloseness ones, generate(co fo no)
nwcloseness bins, generate(cb fb nb)
xa reldif(co[1], cb[1]) < 1e-7 & reldif(co[2], cb[2]) < 1e-7
* a no-op unconnected() on a connected network sends nwcloseness through nwgeodesic: same numbers
nwcloseness bins, generate(cs fs ns) unconnected(99)
xa reldif(cs[1], cb[1]) < 1e-7 & reldif(cs[2], cb[2]) < 1e-7 & fs[1] == fb[1]
nwcloseness vp, generate(cvs fvs nvs) unconnected(99)
xa reldif(cvs[1], cv[1]) < 1e-7 & reldif(cvs[2], cv[2]) < 1e-7
di "(3) closeness valued and both routes: ok"

* ---------------------------------------------------------------- (4) closeness: errors, leftovers
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwcloseness p4, generate(w1 w2 w3)
drop w1 w2 w3
gen byte old = 7
capture nwcloseness p4
xa _rc == 198
capture nwcloseness p4, generate(a b)
xa _rc == 198
capture nwcloseness p4, generate(a b c d)
xa _rc == 198
capture nwcloseness p4, generate(old b c)
xa _rc == 99
xa old == 7 in 1/4
capture confirm variable b
xa _rc != 0
* twomode on a one-mode network: r(198), and no helper network is left behind (slow route)
mata: st_local("n0", strofreal(__nw.nws.get_number()))
capture nwcloseness p4, generate(a b c) twomode unconnected(99)
xa _rc == 198
mata: st_local("n1", strofreal(__nw.nws.get_number()))
* SUSPECTED BUG: the twomode/onemode checks run after nwgeodesic created _tempgeodesic
xa `n1' == `n0'    // fixed: CONFIRMED BUG M2a
capture nwname _tempgeodesic
xa _rc != 0    // fixed: CONFIRMED BUG M2a
capture nwdrop _tempgeodesic
capture nwcloseness p4, generate(a b c) twomode onemode
xa _rc == 198
* a user network called _tempgeodesic must neither block nor be replaced (slow route uses that name)
nwset, mat((0,1\1,0)) name(_tempgeodesic) undirected
capture noisily nwcloseness p4, generate(a b c) unconnected(99) replace
xa _rc == 0    // fixed: CONFIRMED BUG M2b (stops silently, no message)
capture noisily nwsummarize _tempgeodesic
xa _rc == 0 & r(nodes) == 2
capture nwdrop _tempgeodesic
di "(4) closeness errors: ok"

* ---------------------------------------------------------------- (5) betweenness: textbook values
nwclear
clear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwbetween star4, generate(bs)
xa bs[1] == 3 & bs[2] == 0
xa reldif(r(bw_central), 1) < 1e-9
nwbetween star4, generate(bss) standardize
xa reldif(bss[1], 1) < 1e-7
* path 1-2-3-4: (0, 2, 2, 0); centralization (2+0+0+2) / ((n-2)(n-1)^2 / 2) = 4/9
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(path4) undirected
nwbetween path4, generate(bp)
xa bp[1] == 0 & bp[2] == 2 & bp[3] == 2 & bp[4] == 0
xa reldif(r(bw_central), 4/9) < 1e-9
nwbetween path4, generate(bps) standardize
xa reldif(bps[2], 2/3) < 1e-7
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwbetween k4, generate(bk)
xa bk == 0 in 1/4
xa r(bw_central) == 0
* U8: igraph::betweenness(U) = 0 0 10 12 12 0 6 0
mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
nwset, mat(U8) name(u8) undirected
nwbetween u8, generate(bu)
xt_cmp bu "(0,0,10,12,12,0,6,0)" 1e-7
* D8: igraph::betweenness(D, directed=TRUE) = 7 1.5 1.5 3 12.5 11.5 6 0 (nosym);
*     igraph::betweenness(as_undirected(D, mode="collapse")) = 3 0 3 5 5 10 6 0 (default, symmetrized)
mata: D8 = J(8,8,0)
mata: E = (1,2\2,1\2,3\3,1\3,4\4,5\5,6\6,4\6,7\7,8\8,7\1,5)
mata: for (k = 1; k <= rows(E); k++) D8[E[k,1], E[k,2]] = 1
nwset, mat(D8) name(d8) directed
nwbetween d8, generate(bdn) nosym
xt_cmp bdn "(7,1.5,1.5,3,12.5,11.5,6,0)" 1e-7
nwbetween d8, generate(bds)
xt_cmp bds "(3,0,3,5,5,10,6,0)" 1e-7
* the symmetrized helper network is gone again
capture nwname d8_symmetrized
xa _rc != 0
mata: mata drop U8 D8 E k
di "(5) betweenness textbook values: ok"

* ---------------------------------------------------------------- (6) betweenness: tiny, disconnected, valued
nwclear
clear
nwset, mat((0)) name(one) undirected
nwbetween one, generate(b1)
xa b1[1] == 0
xa r(bw_central) == .
nwbetween one, generate(b1s) standardize
xa b1s[1] == .
nwset, mat((0,1\1,0)) name(two) undirected
nwbetween two, generate(b2)
xa b2 == 0 in 1/2
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected
nwbetween dis, generate(bdis)
xa bdis == 0 in 1/4
* triangle 1-2 (1), 2-3 (1), 1-3 (.1): cost 1/value makes 1-2-3 (cost 2) shorter than 1-3 (cost 10)
nwset, mat((0,1,.1\1,0,1\.1,1,0)) name(tri) undirected
nwbetween tri, generate(bt)
xa bt[2] == 1 & bt[1] == 0 & bt[3] == 0
nwbetween tri, generate(btb) binary
xa btb == 0 in 1/3
nwbetween tri, generate(btw) weighted
xa btw == bt in 1/3
* all-ones valued = binary
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(ones) undirected valued
nwbetween ones, generate(bo)
xa bo[2] == 2 & bo[1] == 0
di "(6) betweenness edge cases: ok"

* ---------------------------------------------------------------- (7) betweenness: errors, leftovers, names
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwbetween p4, generate(w)
drop w
gen byte old = 7
capture nwbetween p4
xa _rc == 198
capture nwbetween p4, generate(x) binary weighted
xa _rc == 198
capture nwbetween p4, generate(old)
xa _rc == 99
xa old == 7 in 1/4
mata: st_local("n0", strofreal(__nw.nws.get_number()))
capture nwbetween p4, generate(bad) twomode
xa _rc == 198
mata: st_local("n1", strofreal(__nw.nws.get_number()))
* SUSPECTED BUG: the twomode check runs after nwsym created p4_symmetrized and after the variable was filled
xa `n1' == `n0'    // fixed: CONFIRMED BUG M3a
capture confirm variable bad
xa _rc != 0    // fixed: CONFIRMED BUG M3a
capture nwdrop p4_symmetrized
capture drop bad
* a user network called <net>_symmetrized must survive nwbetween <net>
capture nwdrop p4_symmetrized
nwset, mat((0,1\1,0)) name(p4_symmetrized) undirected
capture noisily nwbetween p4, generate(b_ok)
xa _rc == 0    // fixed: CONFIRMED BUG M3b (r(483), network p4_symmetrized already exists)
capture nwname p4_symmetrized
xa _rc == 0
xa r(nodes) == 2
capture nwdrop p4_symmetrized
* a list of networks: suffixed names, r() from the last one
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(s4) undirected
nwbetween p4 s4, generate(bl)
confirm variable bl_p4 bl_s4, exact
xa bl_s4[1] == 3
xa reldif(r(bw_central), 1) < 1e-9
* results are stored as double (betweenness reaches 1e9 at 100,000 nodes; a float keeps 24 bits)
local tb : type bl_s4
xa "`tb'" == "double"    // fixed: CONFIRMED BUG M3c
di "(7) betweenness errors: ok"

* ---------------------------------------------------------------- (8) permutation invariance
nwclear
clear
mata: A = (0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)
mata: p = (4\6\1\3\5\2)
mata: B = A[p, p]
nwset, mat(A) name(a) undirected
nwset, mat(B) name(b) undirected
nwbetween a, generate(ba)
nwbetween b, generate(bb)
nwcloseness a, generate(ca fa na)
nwcloseness b, generate(cb fb nb)
xm assert(max(abs(st_data((1,6), "bb") - (st_data((1,6), "ba"))[p])) < 1e-9)
xm assert(max(abs(st_data((1,6), "cb") - (st_data((1,6), "ca"))[p])) < 1e-6)
mata: mata drop A B p
di "(8) permutation: ok"

* ---------------------------------------------------------------- (9) a 2,000-node path: closed forms
* path 1-2-...-n: betweenness of node i = (i-1)(n-i); farness = (i-1)i/2 + (n-i)(n-i+1)/2;
* closeness = (n-1) / farness
nwclear
clear
mata: P = J(2000, 2000, 0)
mata: for (k = 1; k < 2000; k++) P[k, k+1] = 1
mata: P = P + P'
nwset, mat(P) name(bigpath) undirected
mata: mata drop P k
nwbetween bigpath, generate(bbig)
gen double bexp = (_n - 1) * (2000 - _n) in 1/2000
* stored as float: compare relative to the size of the number
xa reldif(bbig, bexp) < 1e-6 in 1/2000
nwcloseness bigpath, generate(cbig fbig nbig)
gen double fexp = (_n - 1) * _n / 2 + (2000 - _n) * (2000 - _n + 1) / 2 in 1/2000
xa reldif(fbig, fexp) < 1e-6 in 1/2000
xa reldif(cbig[1], 1999 / fexp[1]) < 1e-6
xa reldif(cbig[1000], 1999 / fexp[1000]) < 1e-6
di "(9) 2,000-node path: ok"

nwclear
xt_mend
di "ALL PASS"
