* xt_meas_summarize_mixing.do -- extended tests for nwsummarize, nwtabulate, nwmixing and nwassortativity.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: nwsummarize r() on star (undirected, directed), empty, 1 node, valued (edges_sum, negative minimum),
* two-mode (density over the pairs between the modes), detail (centralizations, reciprocity, transitivity;
* D8 checked against R), save() and lists; nwtabulate of one network (number of dyads and values) and by
* attribute (= nwmixing); nwmixing E-I index and table on undirected and directed networks, string
* attributes, one group / all groups different, permutations() and the p-value, the data set is unchanged;
* nwassortativity on star, path, U8 (igraph), a numeric attribute (igraph), K4 (undefined), valued
* (strength vs binary), returned results, error codes.
* U8: graph_from_edgelist(matrix(c(1,2,1,3,2,3,3,4,4,5,5,6,5,7,6,7,7,8),ncol=2,byrow=TRUE), directed=FALSE)
* D8: graph_from_edgelist(matrix(c(1,2,2,1,2,3,3,1,3,4,4,5,5,6,6,4,6,7,7,8,8,7,1,5),ncol=2,byrow=TRUE))
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_summarize_mixing
nwclear

mata: U8 = J(8,8,0)
mata: E = (1,2\1,3\2,3\3,4\4,5\5,6\5,7\6,7\7,8)
mata: for (k = 1; k <= rows(E); k++) U8[E[k,1], E[k,2]] = 1
mata: U8 = U8 + U8'
mata: D8 = J(8,8,0)
mata: E = (1,2\2,1\2,3\3,1\3,4\4,5\5,6\6,4\6,7\7,8\8,7\1,5)
mata: for (k = 1; k <= rows(E); k++) D8[E[k,1], E[k,2]] = 1

* ---------------------------------------------------------------- (1) nwsummarize
nwclear
clear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwsummarize star4
xa r(nodes) == 4 & r(edges) == 3
xa reldif(r(density), .5) < 1e-12
xa reldif(r(meandegree), 1.5) < 1e-12
xa "`r(directed)'" == "false" & "`r(valued)'" == "false" & "`r(mode2)'" == "false"
xa r(maxval) == 1
xa "`r(name)'" == "star4"
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(dstar) directed
nwsummarize dstar
xa r(arcs) == 3
xa reldif(r(density), .25) < 1e-12
xa reldif(r(meandegree), .75) < 1e-12
nwset, mat(J(3,3,0)) name(e3) undirected
nwsummarize e3
xa r(edges) == 0 & r(density) == 0 & r(meandegree) == 0
nwset, mat((0)) name(one) undirected
nwsummarize one
xa r(nodes) == 1
nwsummarize one, detail
* valued: values 2, .5, 3 and a negative -1 in another network
nwset, mat((0,2,.5,3\2,0,0,0\.5,0,0,0\3,0,0,0)) name(vs) undirected
nwsummarize vs
xa "`r(valued)'" == "true"
xa reldif(r(edges_sum), 5.5) < 1e-12
xa r(edges) == 3 & r(maxval) == 3
nwset, mat((0,-1\-1,0)) name(neg) undirected
nwsummarize neg
xa r(minval) == -1 & r(edges) == 1
* detail: star centralization 1, transitivity 0, reciprocity of an undirected network 1
nwsummarize star4, detail
xa reldif(r(dg_central), 1) < 1e-12
xa r(transitivity) == 0
xa r(reciprocity) == 1
* D8, detail: reciprocity .2 (igraph dyad_census), centralizations 4/49 (from igraph::degree in/out)
nwset, mat(D8) name(d8) directed
nwsummarize d8, detail
xa reldif(r(reciprocity), .2) < 1e-12
xa reldif(r(indg_central), 4/49) < 1e-12
xa reldif(r(outdg_central), 4/49) < 1e-12
xa r(arcs) == 12
* r(missing_edges) and r(selfloops) are documented
* the diagonal of a network without self-loops counts as missing (as nwname): 8 cells
xa r(missing_edges) == 8    // fixed: CONFIRMED BUG N1 (documented r() was not set with detail)
xa r(selfloops) == 0
* a list: r() from the last network; save() writes one row per network
tempfile sv
nwsummarize star4 dstar d8, save(`sv')
xa "`r(name)'" == "d8"
preserve
use `sv', clear
xa _N == 3
xa name[1] == "star4" & reldif(density[1], .5) < 1e-6 & edges[1] == 3 & arcs[1] == .
xa arcs[2] == 3 & edges[2] == .
restore
tempfile sv2
nwsummarize star4 d8, save(`sv2') detail
preserve
use `sv2', clear
xa _N == 2
xa reldif(dg_central[1], 1) < 1e-6 & indg_central[1] == .
xa reldif(reciprocity[2], .2) < 1e-6
restore
di "(1) nwsummarize: ok"

* ---------------------------------------------------------------- (2) nwsummarize: two-mode
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
nwsummarize tm
xa "`r(mode2)'" == "true"
xa r(nodes) == 5
xa r(nodes1) + r(nodes2) == 5
xa r(nodes1) * r(nodes2) == 6
* 5 ties over 3 x 2 pairs between the modes
xa reldif(r(density), 5/6) < 1e-12
di "(2) nwsummarize two-mode: ok"

* ---------------------------------------------------------------- (3) nwtabulate
nwclear
clear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwtabulate star4
* undirected: the 6 dyads of the upper triangle, values 0 and 1
xa r(N) == 6 & r(r) == 2
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(dstar) directed
nwtabulate dstar
xa r(N) == 12 & r(r) == 2
nwset, mat((0,2,.5,3\2,0,0,0\.5,0,0,0\3,0,0,0)) name(vs) undirected
nwtabulate vs
xa r(N) == 6 & r(r) == 4
* more than two networks: error 198 ("Maximum two networks allowed")
capture noisily nwtabulate star4 dstar vs
xa _rc == 198
di "(3) nwtabulate: ok"

* ---------------------------------------------------------------- (4) nwmixing and nwtabulate, attribute()
nwclear
clear
* groups (1,1,2,2); edges 1-2, 3-4 (inside), 2-3 (between): undirected table counts each edge twice
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(u4) undirected
set obs 4
gen g = cond(_n <= 2, 1, 2)
gen str1 gs = cond(_n <= 2, "a", "b")
* a first call syncs the data with the network (_nwnode); after that nwmixing must leave the data alone
nwmixing u4, attribute(g) permutations(1)
qui datasignature
local sig0 "`r(datasignature)'"
nwmixing u4, attribute(g) permutations(1)
xa reldif(r(EI_index), -1/3) < 1e-12
matrix T = r(table)
xa T[1,1] == 2 & T[1,2] == 1 & T[2,1] == 1 & T[2,2] == 2
xa "`r(attribute)'" == "g"
* permutations(1): no p-value
mata: st_local("hasp", strofreal(rows(st_numscalar("r(EI_pvalue)")) > 0))
xa `hasp' == 0
* the data set is unchanged
qui datasignature
xa "`r(datasignature)'" == "`sig0'"
* a string attribute gives the same index
nwmixing u4, attribute(gs) permutations(1)
xa reldif(r(EI_index), -1/3) < 1e-12
* nwtabulate, attribute() is the same computation
nwtabulate u4, attribute(g) permutations(1)
xa reldif(r(EI_index), -1/3) < 1e-6
* directed 1->2, 2->3, 3->4, 4->1: two arcs inside, two between: E-I 0
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(d4) directed
nwmixing d4, attribute(g) permutations(1)
xa r(EI_index) == 0
matrix T = r(table)
xa T[1,1] == 1 & T[1,2] == 1 & T[2,1] == 1 & T[2,2] == 1
* one group: -1; every node its own group: +1
gen one = 1
gen own = _n
nwmixing u4, attribute(one) permutations(1)
xa r(EI_index) == -1
nwmixing u4, attribute(own) permutations(1)
xa r(EI_index) == 1
* permutations: a p-value in [0, 1], reproducible with the seed
set seed 11
nwmixing u4, attribute(g) permutations(20)
local p1 = r(EI_pvalue)
xa `p1' >= 0 & `p1' <= 1
set seed 11
nwmixing u4, attribute(g) permutations(20)
xa r(EI_pvalue) == `p1'
* valued ties count as ties
nwset, mat((0,2.5,0,0\2.5,0,.5,0\0,.5,0,3\0,0,3,0)) name(v4) undirected
nwmixing v4, attribute(g) permutations(1)
xa reldif(r(EI_index), -1/3) < 1e-12
* errors
capture nwmixing u4
xa _rc == 198
capture nwmixing nosuchnet, attribute(g)
xa _rc == 482
capture nwmixing u4, attribute(nosuchvar)
xa _rc != 0
di "(4) nwmixing: ok"

* ---------------------------------------------------------------- (5) nwassortativity
nwclear
clear
* igraph::assortativity_degree(make_star(4, mode = "undirected")) = -1
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwassortativity star4
xa reldif(r(assortativity), -1) < 1e-9
xa r(ties) == 3
xa "`r(attribute)'" == "degree" & "`r(weighted)'" == "false" & "`r(name)'" == "star4"
* igraph::assortativity_degree(make_ring(4, circular = FALSE)) = -0.5
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwassortativity p4
xa reldif(r(assortativity), -.5) < 1e-9
* U8: igraph::assortativity_degree(U, directed = FALSE) = -0.551724137931039
nwset, mat(U8) name(u8) undirected
nwassortativity u8
xa reldif(r(assortativity), -0.551724137931039) < 1e-9
* attribute (1,1,2,2) on edges 1-2, 3-4, 2-3: igraph::assortativity(g, values = c(1,1,2,2), directed = FALSE) = 1/3
set obs 8
gen ga = cond(_n <= 2, 1, 2)
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(q4) undirected
nwassortativity q4, attribute(ga)
xa reldif(r(assortativity), 1/3) < 1e-9
xa "`r(attribute)'" == "ga"
* K4: every degree equal, the correlation is undefined (missing), no error
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwassortativity k4
xa r(assortativity) == .
* valued star whose ties all have value 2: strength 6 and 2 vs degree 3 and 1: -1 either way
nwset, mat(2 * (0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(vstar) undirected
nwassortativity vstar
xa "`r(attribute)'" == "strength"
xa reldif(r(assortativity), -1) < 1e-9
nwassortativity vstar, binary
xa "`r(attribute)'" == "degree"
xa reldif(r(assortativity), -1) < 1e-9
* a string attribute is an error (confirm numeric variable)
gen str1 sa = "a"
capture nwassortativity q4, attribute(sa)
xa _rc == 7
capture nwassortativity nosuchnet
xa _rc != 0
di "(5) nwassortativity: ok"

mata: mata drop U8 D8 E k
nwclear
xt_mend
di "ALL PASS"
