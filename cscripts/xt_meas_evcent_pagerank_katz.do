* xt_meas_evcent_pagerank_katz.do -- extended tests for nwevcent, nwpagerank and nwkatz.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: textbook eigenvectors (K4, star, path, 2 nodes, directed cycle), empty and 1-node networks,
* valued networks whose ties all have the same value (= binary), directed mutual = undirected, R references
* (igraph), PageRank sums to 1 and is uniform on an empty network, option range errors, generate() with an
* existing or abbreviating variable name, Katz walk counts solved by hand, the divergence guard, the
* distance-decay form (differences between nodes, so the self term does not matter), and 2,000 nodes.
* nwevcent's vector has length 1 (sum of squares 1): see test_nwevcent.do (K5 gives .447 = 1/sqrt(5)).
* U8 and D8 are the networks of xt_meas_closeness_between.do:
*   U <- graph_from_edgelist(matrix(c(1,2,1,3,2,3,3,4,4,5,5,6,5,7,6,7,7,8),ncol=2,byrow=TRUE), directed=FALSE)
*   D <- graph_from_edgelist(matrix(c(1,2,2,1,2,3,3,1,3,4,4,5,5,6,6,4,6,7,7,8,8,7,1,5),ncol=2,byrow=TRUE))
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_evcent_pagerank_katz
nwclear

capture program drop xt_cmp
program xt_cmp
	args v expect tol
	mata: __xte = `expect'
	mata: st_numscalar("__xtd", max(abs(st_data((1, cols(__xte)), "`v'") - __xte')))
	mata: mata drop __xte
	xa scalar(__xtd) < `tol'
	scalar drop __xtd
end

mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
mata: D8 = J(8,8,0)
mata: E = (1,2\2,1\2,3\3,1\3,4\4,5\5,6\6,4\6,7\7,8\8,7\1,5)
mata: for (k = 1; k <= rows(E); k++) D8[E[k,1], E[k,2]] = 1

* ---------------------------------------------------------------- (1) nwevcent: textbook vectors
nwclear
clear
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwevcent k4, generate(ek)
xa reldif(ek[1], .5) < 1e-6 & reldif(ek[4], .5) < 1e-6
* star, centre + 3 leaves: lambda = sqrt(3); centre 1/sqrt(2), leaves 1/sqrt(6)
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwevcent star4, generate(es)
xa reldif(es[1], 1/sqrt(2)) < 1e-6
xa reldif(es[2], 1/sqrt(6)) < 1e-6
* path 1-2-3 (bipartite: the case plain power iteration oscillates on): (.5, 1/sqrt(2), .5)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
nwevcent p3, generate(ep)
xa reldif(ep[1], .5) < 1e-6 & reldif(ep[2], 1/sqrt(2)) < 1e-6 & reldif(ep[3], .5) < 1e-6
nwset, mat((0,1\1,0)) name(two) undirected
nwevcent two, generate(e2)
xa reldif(e2[1], 1/sqrt(2)) < 1e-6 & reldif(e2[2], 1/sqrt(2)) < 1e-6
* U8: igraph::eigen_centrality(U)$vector scaled to length 1
nwset, mat(U8) name(u8) undirected
nwevcent u8, generate(eu)
xt_cmp eu "(0.254629554045287,0.254629554045287,0.358133274786526,0.352584126799444,0.490356005057229,0.38685228431599,0.440599166137685,0.183088078955842)" 1e-6
di "(1) nwevcent textbook: ok"

* ---------------------------------------------------------------- (2) nwevcent: empty, one node, directed, valued
nwclear
clear
nwset, mat(J(3,3,0)) name(empty3) undirected
nwevcent empty3, generate(e0)
xa e0 == . in 1/3
nwset, mat((0)) name(one) undirected
nwevcent one, generate(e1)
xa e1[1] == .
* directed cycle 1 -> 2 -> 3 -> 1, nosym: every node 1/sqrt(3)
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc) directed
nwevcent cyc, generate(ec) nosym
xa reldif(ec[1], 1/sqrt(3)) < 1e-6 & reldif(ec[3], 1/sqrt(3)) < 1e-6
* directed out-star symmetrized (default) = undirected star
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(dstar) directed
nwevcent dstar, generate(eds)
xa reldif(eds[1], 1/sqrt(2)) < 1e-6 & reldif(eds[2], 1/sqrt(6)) < 1e-6
* a valued star whose ties all have the value 2.5: the same vector as the binary star
nwset, mat((0,2.5,2.5,2.5\2.5,0,0,0\2.5,0,0,0\2.5,0,0,0)) name(vstar) undirected
nwevcent vstar, generate(ev)
xa reldif(ev[1], 1/sqrt(2)) < 1e-6 & reldif(ev[2], 1/sqrt(6)) < 1e-6
nwevcent vstar, generate(evb) binary
xa reldif(evb[1], ev[1]) < 1e-6
* a valued star with one strong tie: the strong leaf is above the others (weighted), equal with binary
nwset, mat((0,1,1,10\1,0,0,0\1,0,0,0\10,0,0,0)) name(wstar) undirected
nwevcent wstar, generate(ew)
xa ew[4] > ew[2]
nwevcent wstar, generate(ewb) binary
xa reldif(ewb[4], ewb[2]) < 1e-6
di "(2) nwevcent edge cases: ok"

* ---------------------------------------------------------------- (3) nwevcent: errors and generate()
nwclear
clear
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwevcent k4, generate(w)
drop w
capture nwevcent k4
xa _rc == 198
capture nwevcent k4, generate(x) binary weighted
xa _rc == 198
gen byte old = 7
capture nwevcent k4, generate(old)
xa _rc == 99
xa old == 7 in 1/4
* SUSPECTED BUG: with replace, `capture generate' fails on the existing byte variable and st_store()
* writes .5 into it (stored as a byte).  Expected: the result is stored with its full value.
nwevcent k4, generate(old) replace
xa reldif(old[1], .5) < 1e-6    // fixed: CONFIRMED BUG M5a
* SUSPECTED BUG: `confirm variable' without `exact': an existing variable evlong makes generate(ev) fail
* with r(99) under the default set varabbrev on.  Expected: ev is a new name and is created.
gen evlong = 1
capture noisily nwevcent k4, generate(ev)
xa _rc == 0    // fixed: CONFIRMED BUG M5b
capture confirm variable ev, exact
xa _rc == 0    // fixed: CONFIRMED BUG M5b
xa evlong == 1 in 1/4
di "(3) nwevcent errors: ok"

* ---------------------------------------------------------------- (4) nwpagerank
nwclear
clear
nwset, mat(U8) name(u8) undirected
nwpagerank u8, generate(pu)
xa "`r(generate)'" == "pu"
* igraph::page_rank(U)$vector
xt_cmp pu "(0.111508265316189,0.111508265316189,0.160119714906384,0.109618092676761,0.16059120042336,0.111932878003992,0.168289545473083,0.0664320378840402)" 1e-6
qui summarize pu in 1/8
xa reldif(r(sum), 1) < 1e-8
nwset, mat(D8) name(d8) directed
nwpagerank d8, generate(pd)
* igraph::page_rank(D)$vector
xt_cmp pd "(0.0512708565657416,0.0405401140404402,0.0359795484671871,0.0817608720781651,0.11003685530688,0.112281327010848,0.296962392719317,0.27116803381142)" 1e-6
* K4: uniform for any damping
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwpagerank k4, generate(pk) damping(.5)
xa reldif(pk[1], .25) < 1e-8 & reldif(pk[4], .25) < 1e-8
* no ties: every node dangles, PageRank is uniform (igraph::page_rank(make_empty_graph(5))$vector = .2)
nwset, mat(J(5,5,0)) name(e5) directed
nwpagerank e5, generate(pe)
xa reldif(pe[1], .2) < 1e-8 & reldif(pe[5], .2) < 1e-8
nwset, mat((0)) name(one) undirected
nwpagerank one, generate(p1)
xa reldif(p1[1], 1) < 1e-8
* valued with all ties the same value = binary
nwset, mat(3 * (J(4,4,1) - I(4))) name(k4v) undirected
nwpagerank k4v, generate(pkv)
xa reldif(pkv[2], .25) < 1e-8
* option checks
capture nwpagerank k4, generate(q) damping(0)
xa _rc == 198
capture nwpagerank k4, generate(q) damping(1)
xa _rc == 198
capture nwpagerank k4, generate(q) maxiter(0)
xa _rc == 198
capture nwpagerank k4
xa _rc == 198
capture nwpagerank k4, generate(pk)
xa _rc == 99
nwpagerank k4, generate(pk) replace
xa reldif(pk[1], .25) < 1e-8
* a 2,000-node network: the scores sum to 1
set seed 99
nwrandom 2000, prob(.003) directed name(big)
nwpagerank big, generate(pbig) silent
qui summarize pbig
xa r(N) == 2000
xa reldif(r(sum), 1) < 1e-6
di "(4) nwpagerank: ok"

* ---------------------------------------------------------------- (5) nwkatz, walks: solved by hand
nwclear
clear
* one edge, alpha .5: x = 1 + .5 x  ->  x = 2
nwset, mat((0,1\1,0)) name(k2) undirected
nwkatz k2, walks alpha(.5) generate(kw)
xa reldif(kw[1], 2) < 1e-9 & reldif(kw[2], 2) < 1e-9
* rho = 1: alpha(1) diverges
capture nwkatz k2, walks alpha(1) generate(kx)
xa _rc == 198
capture confirm variable kx
xa _rc != 0
* star, centre + 3 leaves, alpha .25 (rho = sqrt(3)): c = 1 + .75 l, l = 1 + .25 c -> c = 1.75/.8125
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwkatz star4, walks alpha(.25) generate(kst)
xa reldif(kst[1], 1.75/.8125) < 1e-9
xa reldif(kst[2], 1 + .25 * 1.75/.8125) < 1e-9
* directed path 1 -> 2 -> 3, alpha .5: out (1.75, 1.5, 1), in (1, 1.5, 1.75)
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
nwkatz dp3, walks alpha(.5) generate(kd)
confirm variable kd_out kd_in, exact
xa reldif(kd_out[1], 1.75) < 1e-9 & reldif(kd_out[3], 1) < 1e-9
xa reldif(kd_in[1], 1) < 1e-9 & reldif(kd_in[3], 1.75) < 1e-9
* SUSPECTED BUG: a network with spectral radius 0 (acyclic, or no ties) and no alpha(): the default
* alpha is .9 / rho = missing and the guard stops with r(198).  Every alpha is valid there.
capture noisily nwkatz dp3, walks generate(kdef)
xa _rc == 0    // fixed: CONFIRMED BUG M6b
di "(5) nwkatz walks: ok"

* ---------------------------------------------------------------- (6) nwkatz, distance decay
nwclear
clear
* path 1-2-3, alpha .5: node 2 has (.5 + .5), node 1 has (.5 + .25): difference .25 whatever the self term
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
nwkatz p3, alpha(.5) generate(kp)
xa reldif(kp[2] - kp[1], .25) < 1e-9
xa reldif(kp[1], kp[3]) < 1e-12
* alpha 1 (the default) on a connected network: every node the same
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwkatz p4, generate(k1)
xa reldif(k1[1], k1[2]) < 1e-12 & reldif(k1[1], k1[4]) < 1e-12
* two separate edges: node 1 reaches only node 2; alpha .5 gives the same value for all four
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(dis) undirected
nwkatz dis, alpha(.5) generate(kdis)
xa reldif(kdis[1], kdis[4]) < 1e-12
* directed network, default symmetrized: in = out
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
nwkatz dp3, alpha(.5) generate(kq)
xa reldif(kq_in[1], kq_out[1]) < 1e-12
* nosym: node 1 reaches 2 (d 1) and 3 (d 2); node 3 reaches none: out(1) - out(3) = .5 + .25
nwkatz dp3, alpha(.5) nosym generate(kr)
xa reldif(kr_out[1] - kr_out[3], .75) < 1e-9
xa reldif(kr_in[3] - kr_in[1], .75) < 1e-9
* errors
capture nwkatz p4
xa _rc == 198
capture nwkatz p4, generate(k1)
xa _rc == 99
nwkatz p4, generate(k1) replace
gen zklong = 1
* SUSPECTED BUG (as nwevcent): `confirm variable' without `exact' (zk abbreviates zklong only)
capture noisily nwkatz p4, generate(zk)
xa _rc == 0    // fixed: CONFIRMED BUG M6a
capture confirm variable zk, exact
xa _rc == 0    // fixed: CONFIRMED BUG M6a
xa zklong == 1 in 1/4
di "(6) nwkatz distance decay: ok"

mata: mata drop U8 D8 E k
nwclear
xt_mend
di "ALL PASS"
