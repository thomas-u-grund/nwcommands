cscript

do unw_core.do

* nwinduced (Everett & Borgatti 2010, "Induced, endogenous and
* exogenous centrality") - a general leave-one-out decomposition
* applicable to any existing centrality measure C: endogenous(v)=C(v);
* induced(v) = sum_i C_G(i) - sum_i C_(G-v)(i); exogenous(v) =
* induced(v) - endogenous(v). v1 scope: undirected networks only,
* measure() one of degree/betweenness/closeness/evcent.
*
* --- PRIMARY correctness check: a universal mathematical identity,
* not a hand-picked toy network. For measure(degree) specifically, with
* the graph invariant taken as total edge count (2x the degree sum for
* an undirected network, since each edge is counted at both endpoints):
* removing node v removes exactly degree(v) edges, each of which
* contributed 2 to the total degree sum - so induced(v) = 2*degree(v)
* EXACTLY, for ANY undirected network, and exogenous(v) =
* induced(v) - degree(v) = degree(v) = endogenous(v) exactly too. This
* holds universally (verified below on 3 structurally different
* networks), not just for one convenient example - a much stronger
* check than a single hand-computed case.

capture program drop _check_degree_identity
program _check_degree_identity
	args netname n
	nwinduced `netname', measure(degree) generate(chk) replace silent
	tempname endog induced exog
	mata: `endog' = st_data((1::`n'), "chk_endog")
	mata: `induced' = st_data((1::`n'), "chk_induced")
	mata: `exog' = st_data((1::`n'), "chk_exog")
	mata: assert(max(abs(`induced' - 2 * `endog')) < 1e-8)
	mata: assert(max(abs(`exog' - `endog')) < 1e-8)
	mata: mata drop `endog' `induced' `exog'
end

nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet4) undirected labs(A,B,C,D)
_check_degree_identity starnet4 4
di "=== degree identity (star) VERIFIED ==="

nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4net) undirected labs(A,B,C,D)
_check_degree_identity k4net 4
di "=== degree identity (complete K4) VERIFIED ==="

nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(path5) undirected labs(A,B,C,D,E)
_check_degree_identity path5 5
di "=== degree identity (path graph) VERIFIED ==="

* --- exact hand-computed values on the star network (A hub, B/C/D
* leaves): endogenous = degree = (3,1,1,1); induced = (6,2,2,2);
* exogenous = (3,1,1,1). Sorted by _nwnode since _nwdatasync's own row
* order is not guaranteed to match input order.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet5) undirected labs(A,B,C,D)
nwinduced starnet5, measure(degree) generate(hand) silent
sort _nwnode
tempname lab endog induced exog
mata: `lab' = st_sdata(., "_nwnode")
mata: `endog' = st_data(., "hand_endog")
mata: `induced' = st_data(., "hand_induced")
mata: `exog' = st_data(., "hand_exog")
mata: assert(select(`endog', `lab':=="A") == 3)
mata: assert(select(`endog', `lab':=="B") == 1)
mata: assert(select(`induced', `lab':=="A") == 6)
mata: assert(select(`induced', `lab':=="B") == 2)
mata: assert(select(`exog', `lab':=="A") == 3)
mata: assert(select(`exog', `lab':=="B") == 1)
mata: mata drop `lab' `endog' `induced' `exog'
di "=== hand-computed star network values VERIFIED ==="

* --- the source network's own state must be completely unaffected by
* the leave-one-out loop (no leftover temporary "__nwind_sub" network,
* node count/edges unchanged, current network still resolves correctly
* afterward) - the real risk in this command's own implementation
* (repeatedly building and dropping temporary subgraph networks) is
* leftover state contaminating the caller, not the arithmetic itself.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(cleanupnet) undirected labs(A,B,C,D)
nwinduced cleanupnet, measure(degree) generate(cleanup) silent
qui nwset
assert `"`r(nets)'"' == `" cleanupnet"'
assert r(networks) == 1
qui nwsummarize cleanupnet
assert r(nodes) == 4
assert r(edges) == 3
di "=== no leftover temporary-network state VERIFIED ==="

* --- betweenness and evcent also run cleanly end to end (not just
* degree) - a 5-node network with genuine variation in all three
* measures.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(path5b) undirected labs(A,B,C,D,E)
nwinduced path5b, measure(betweenness) generate(bcheck) silent
assert _rc == 0
nwinduced path5b, measure(closeness) generate(ccheck) silent
assert _rc == 0
nwinduced path5b, measure(evcent) generate(echeck) silent
assert _rc == 0
di "=== betweenness/closeness/evcent run cleanly REGRESSION VERIFIED ==="

* --- failure paths: an invalid measure() value is rejected; a
* directed network is rejected with the disclosed v1-scope error, not
* silently mishandled; a name that isn't a loaded network is rejected
* via _nwsyntax (482); a target variable already existing without
* replace is rejected.
nwclear
nwset, mat((0,1\1,0)) name(failnet) undirected labs(A,B)
capture noisily nwinduced failnet, measure(bogus)
assert _rc == 6556

nwclear
nwset, mat((0,1\0,0)) name(dirfailnet) directed labs(A,B)
capture noisily nwinduced dirfailnet, measure(degree)
assert _rc == 198

* --- directed networks ARE supported for betweenness/closeness/evcent
* (only measure(degree) is restricted - nwdegree itself is the one
* that splits into separate outdegree/indegree variables when
* directed, none of the other three do).
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirok) directed labs(A,B,C)
capture noisily nwinduced dirok, measure(betweenness) generate(dbcheck) silent
assert _rc == 0
capture noisily nwinduced dirok, measure(closeness) generate(dccheck) silent
assert _rc == 0
capture noisily nwinduced dirok, measure(evcent) generate(decheck) silent
assert _rc == 0
di "=== directed betweenness/closeness/evcent REGRESSION VERIFIED ==="

capture noisily nwinduced nonexistent, measure(degree)
assert _rc == 482

nwclear
nwset, mat((0,1\1,0)) name(replacenet) undirected labs(A,B)
nwinduced replacenet, measure(degree) generate(rep1) silent
capture noisily nwinduced replacenet, measure(degree) generate(rep1) silent
assert _rc == 99
nwinduced replacenet, measure(degree) generate(rep1) replace silent
assert _rc == 0
di "=== failure-path REGRESSION VERIFIED ==="
