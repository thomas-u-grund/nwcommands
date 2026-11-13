* xt_meas_degree.do -- extended edge-case tests for nwdegree (and the two-mode form, nw2degree).
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: 1 node, 2 nodes, all isolates, K4, star, path, directed out-star, directed mutual star vs
* undirected star (cross-route), valued (non-integer, negative, all-ones vs binary), alpha(), ties(),
* isolates, standardize, two-mode default / raw / onemode, list of networks, node permutation, generate()
* with existing names (with and without replace), error codes from nwdegree.ado, a 2,000-node network.
* Every expected number is hand-derived (Freeman centralization: sum(max - d) / ((n-1)(n-2)) undirected,
* / (n-1)^2 directed, as coded in nwdegree.ado) or noted as from R.
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_degree
nwclear

* ---------------------------------------------------------------- helpers
* ordered values of variable v in rows 1..n against a Mata row vector (sorted comparison)
capture program drop xt_sorted
program xt_sorted
	args v n expect
	mata: st_numscalar("__xtd", max(abs(sort(st_data((1, `n'), "`v'"), 1) - sort(`expect'', 1))))
	xa scalar(__xtd) < 1e-6
	scalar drop __xtd
end

* ---------------------------------------------------------------- (1) one node, two nodes
nwclear
clear
nwset, mat((0)) name(one) undirected
nwdegree one, generate(d1)
xa d1[1] == 0
* centralization divides by (n-2)(n-1) = 0: undefined, must be missing and must not error
xa r(dg_central) == .
nwdegree one, generate(d1s) standardize
* standardize divides by n-1 = 0
xa d1s[1] == .
nwdegree one, generate(d1i) isolates
confirm variable _isolates
xa _isolates[1] == 1
drop _isolates

nwset, mat((0,1\1,0)) name(two) undirected
nwdegree two, generate(d2)
xa d2[1] == 1 & d2[2] == 1
xa r(dg_central) == .
nwdegree two, generate(d2s) standardize
xa d2s[1] == 1 & d2s[2] == 1

* a directed 1-node network: (n-1)^2 = 0 in both centralizations
nwset, mat((0)) name(oned) directed
nwdegree oned, generate(o1 i1)
xa o1[1] == 0 & i1[1] == 0
xa r(indg_central) == . & r(outdg_central) == .
* a directed 2-node network 1 -> 2: out (1,0), in (0,1), both centralizations (1-0)/1 = 1
nwset, mat((0,1\0,0)) name(twod) directed
nwdegree twod, generate(o2 i2)
xa o2[1] == 1 & o2[2] == 0 & i2[1] == 0 & i2[2] == 1
xa reldif(r(outdg_central), 1) < 1e-12
xa reldif(r(indg_central), 1) < 1e-12
di "(1) one and two nodes: ok"

* ---------------------------------------------------------------- (2) isolates, complete, star, path
nwclear
clear
nwset, mat(J(4,4,0)) name(iso4) undirected
nwdegree iso4, generate(di) isolates
xa di == 0 in 1/4
xa _isolates == 1 in 1/4
drop _isolates
nwdegree iso4, generate(di2) replace
* all degrees 0: max - d = 0 everywhere
xa r(dg_central) == 0

nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwdegree k4, generate(dk)
xa dk == 3 in 1/4
xa r(dg_central) == 0
nwdegree k4, generate(dks) standardize
xa dks == 1 in 1/4

* star: node 1 is the centre of 4 leaves; centralization (4 x 3) / (3 x 4) = 1
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(star5) undirected
nwdegree star5, generate(ds)
xa ds[1] == 4
xa ds == 1 in 2/5
xa reldif(r(dg_central), 1) < 1e-12
nwdegree star5, generate(dss) standardize
xa dss[1] == 1
xa reldif(dss[2], 0.25) < 1e-7

* path 1-2-3-4: (1,2,2,1); centralization (1+0+0+1) / (2 x 3) = 1/3
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(path4) undirected
nwdegree path4, generate(dp)
xa dp[1] == 1 & dp[2] == 2 & dp[3] == 2 & dp[4] == 1
xa reldif(r(dg_central), 1/3) < 1e-12
xa r(alpha) == 0
di "(2) isolates, K4, star, path: ok"

* ---------------------------------------------------------------- (3) directed: out-star, mutual star = undirected star
nwclear
clear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(dstar) directed
nwdegree dstar, generate(od id)
xa od[1] == 3 & id[1] == 0
xa od == 0 in 2/4
xa id == 1 in 2/4
* out: (3+3+3) / 9 = 1; in: max 1, (1+0+0+0) / 9
xa reldif(r(outdg_central), 1) < 1e-12
xa reldif(r(indg_central), 1/9) < 1e-12
* isolates on a directed network: no node is isolated
nwdegree dstar, generate(od2 id2 isox) isolates
xa isox == 0 in 1/4

* the same ties, all reciprocated, declared directed: out = in = degree of the undirected star
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(dmut) directed
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(umut) undirected
nwdegree dmut, generate(mo mi)
nwdegree umut, generate(mu)
xa mo == mu in 1/4
xa mi == mu in 1/4
di "(3) directed: ok"

* ---------------------------------------------------------------- (4) valued: strength, binary, alpha(), ties(), all-ones
nwclear
clear
* star, centre 1, values 2, 0.5, 3 (non-integer)
nwset, mat((0,2,.5,3\2,0,0,0\.5,0,0,0\3,0,0,0)) name(vs) undirected
nwdegree vs, generate(sv)
xa reldif(sv[1], 5.5) < 1e-12
xa reldif(sv[2], 2) < 1e-12 & reldif(sv[3], .5) < 1e-12 & reldif(sv[4], 3) < 1e-12
xa r(alpha) == 1
* mean strength (5.5 + 2 + .5 + 3) / 4, mean number of ties (3 + 1 + 1 + 1) / 4
xa reldif(r(mean_strength), 2.75) < 1e-12
xa reldif(r(mean_ties), 1.5) < 1e-12
local tsv : type sv
xa "`tsv'" == "double"
nwdegree vs, generate(sb) binary
xa sb[1] == 3 & sb[2] == 1
xa r(alpha) == 0
nwdegree vs, generate(sa0) alpha(0)
xa sa0 == sb in 1/4
* alpha(.5): k (s/k)^alpha, documented formula
nwdegree vs, generate(sa5) alpha(.5)
xa reldif(sa5[1], 3 * sqrt(5.5/3)) < 1e-12
xa reldif(sa5[3], sqrt(.5)) < 1e-12
* ties(): strength and count side by side
nwdegree vs, generate(st) ties(tc)
xa st == sv in 1/4
xa tc == sb in 1/4
* the same ties with value 1, valued flag on, against the binary network: same numbers
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(ones) undirected valued
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(bins) undirected
nwdegree ones, generate(d_ones)
nwdegree bins, generate(d_bins)
xa d_ones == d_bins in 1/4
* a negative tie value is a tie: strength sums the values, the count counts it, the node is no isolate
nwset, mat((0,2,-1,.5,0\2,0,0,0,0\-1,0,0,0,0\.5,0,0,0,0\0,0,0,0,0)) name(neg) undirected
nwdegree neg, generate(sn iso_n) ties(cn) isolates
xa reldif(sn[1], 1.5) < 1e-12
xa reldif(sn[3], -1) < 1e-12
xa cn[1] == 3 & cn[3] == 1
xa iso_n[3] == 0
xa iso_n[5] == 1
* isolates on a valued network without ties(): the isolate test must use the count, not the strength
* (node 3 has strength -1, node 5 strength 0; only node 5 is isolated)
nwdegree neg, generate(sn2 iso_n2) isolates
xa iso_n2[3] == 0 & iso_n2[5] == 1
di "(4) valued: ok"

* ---------------------------------------------------------------- (5) generate() with existing names; errors
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(ds4) directed
* one successful call first: it syncs the data with the network (_nwnode, 4 rows)
nwdegree p4, generate(warm)
drop warm
gen byte taken = 7
qui datasignature
local sig0 "`r(datasignature)'"
* generate() required
capture nwdegree p4
xa _rc == 198
* existing variable without replace: r(99), the variable is untouched
capture nwdegree p4, generate(taken)
xa _rc == 110
xa taken == 7 in 1/4
qui datasignature
xa "`r(datasignature)'" == "`sig0'"
* directed network, one name only
capture nwdegree ds4, generate(onlyone)
xa _rc == 198
capture confirm variable onlyone
xa _rc != 0
* ties() with the wrong number of names
capture nwdegree p4, generate(q1) ties(a b)
xa _rc == 198
capture nwdegree ds4, generate(q1 q2) ties(a)
xa _rc == 198
* alpha() not a number; binary with alpha() other than 0
capture nwdegree p4, generate(q1) alpha(abc)
xa _rc == 198
capture nwdegree p4, generate(q1) binary alpha(1)
xa _rc == 198
* binary with alpha(0) is allowed (same thing)
nwdegree p4, generate(q0) binary alpha(0)
xa q0[2] == 2
* raw is two-mode only and cannot be combined with onemode
capture nwdegree p4, generate(q1) raw onemode
xa _rc == 198
* replace: the old byte variable is dropped and recreated with the degree
nwdegree p4, generate(taken) replace
xa taken[1] == 1 & taken[2] == 2
* network that does not exist
capture nwdegree nosuchnet, generate(q9)
xa _rc != 0
capture confirm variable q9
xa _rc != 0
* if/in are not part of nwdegree's syntax: a clean error, no variable
capture nwdegree p4 in 1/2, generate(q8)
xa _rc != 0
capture confirm variable q8
xa _rc != 0
di "(5) errors: ok"

* ---------------------------------------------------------------- (6) SUSPECTED BUG: second generate() name on an undirected network
* nwdegree.ado takes word 2 of generate() as `_indegree' also for an undirected network and, in the existence
* loop, checks it and (with replace) DROPS it, although no indegree variable is ever created for an
* undirected network.  Expected: a variable that the command does not produce is left alone.
nwclear
clear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
set obs 3
gen keepme = 5
nwdegree p3, generate(dd keepme) replace
capture confirm variable keepme, exact
xa _rc == 0    // fixed: CONFIRMED BUG M1
xa keepme == 5 in 1/3    // fixed: CONFIRMED BUG M1
* CONFIRMED BUG N4: after the exact existence check, `capture drop <name>' (nwdegree.ado:361, nwcloseness.ado:212)
* runs without exact; with varabbrev on, generate(d) drops the user's variable dlong
clear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3b) undirected
nwdegree p3b, generate(warm)
drop warm
gen dlong = 5
nwdegree p3b, generate(d)
capture confirm variable dlong, exact
xa _rc == 0    // fixed: CONFIRMED BUG N4
di "(6) second generate() name on an undirected network: ok"

* ---------------------------------------------------------------- (7) list of networks, permutation, relabelling
nwclear
clear
nwset, mat(J(4,4,1) - I(4)) name(ka) undirected
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(pa) undirected
nwdegree ka pa, generate(dg)
confirm variable dg_ka dg_pa, exact
xa dg_ka == 3 in 1/4
xa dg_pa[2] == 2 & dg_pa[4] == 1
* r() is from the last network of the list (path: 1/3)
xa reldif(r(dg_central), 1/3) < 1e-12

* permuting the node order permutes the degrees
mata: A = (0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)
mata: p = (3\5\1\4\2)
mata: B = A[p, p]
nwset, mat(A) name(orig) undirected
nwset, mat(B) name(perm) undirected
nwdegree orig, generate(dorig)
nwdegree perm, generate(dperm)
xm assert(st_data((1,5), "dperm") == (st_data((1,5), "dorig"))[p])
* relabelling only (same matrix, other node names) does not change the values.  The data rows are keyed by node
* name (_nwnode), so the rows of relab are e..a and not the rows of orig: compare with A's row sums.
nwset, mat(A) name(relab) undirected labs(e,d,c,b,a)
nwdegree relab, generate(drelab)
xm assert(st_data((1,5), "drelab") == rowsum(A))
mata: mata drop A B p
di "(7) lists, permutation, relabelling: ok"

* ---------------------------------------------------------------- (8) two-mode
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
* raw degrees: Thomas 1, Peter 2, Tim 2, Oxford 3, LiU 2; default divides by the size of the other mode
* (persons by 2 organisations, organisations by 3 persons): .5, 1, 1, 1, 2/3.  Node order is not asserted.
nwdegree tm, generate(t2)
xt_sorted t2 5 "(.5, 1, 1, 1, 2/3)"
nwdegree tm, generate(t2r) raw
xt_sorted t2r 5 "(1, 2, 2, 3, 2)"
* nw2degree is an alias of the two-mode form
nw2degree tm, generate(t2b)
xa t2b == t2 in 1/5
* onemode: the bipartite graph read as a one-mode graph, degree = number of ties
nwdegree tm, generate(t1m) onemode
xt_sorted t1m 5 "(1, 2, 2, 3, 2)"
* options without a two-mode form are ignored with a note, not an error
nwdegree tm, generate(t2c) isolates standardize
xa t2c == t2 in 1/5
* existing variable without replace
capture nwdegree tm, generate(t2)
xa _rc == 110
di "(8) two-mode: ok"

* ---------------------------------------------------------------- (9) 2,000 nodes: sum of degrees = 2 x edges
nwclear
clear
set seed 4711
nwrandom 2000, prob(.002) undirected name(big)
nwsummarize big
local e = r(edges)
nwdegree big, generate(dbig) silent
qui summarize dbig
xa r(N) == 2000
xa r(sum) == 2 * `e'
nwrandom 2000, prob(.002) directed name(bigd)
nwsummarize bigd
local a = r(arcs)
nwdegree bigd, generate(obig ibig) silent
qui summarize obig
xa r(sum) == `a'
qui summarize ibig
xa r(sum) == `a'
di "(9) 2,000 nodes: ok"

nwclear
xt_mend
di "ALL PASS"
