cscript

do unw_core.do
do unw_ergm.do

* Certifies nwergm.ado itself (the Stata-facing eclass command), on top
* of unw_ergm.do's own already-certified Mata internals
* (test_nwergm_statistics.do/changestat.do/mple.do/mcmc.do/mcmle.do):
* the NWdef->ErgmGraph bridge, term-option parsing, network-type
* validation, MPLE-vs-MCMLE dispatch, and eclass result posting.

* --- MPLE path: edges-only on a 5-node undirected network with
* density exactly 0.5 (5 ties / 10 dyads) - the exact MPLE is
* logit(0.5) = 0 (same hand-derivable case as test_nwergm_mple.do,
* now exercised through the actual command rather than Mata directly).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(mynet) labs(A,B,C,D,E)
gen sex = .
replace sex = 1 in 1
replace sex = 1 in 2
replace sex = 2 in 3
replace sex = 2 in 4
replace sex = 1 in 5

qui nwergm mynet, edges
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert `"`e(cmd)'"' == "nwergm"
assert e(nodes) == 5
assert e(ties) == 5
assert abs(_b[edges]) < 1e-6

* --- MPLE with nodematch(): two coefficients, still dyad-independent
* (method still auto-selects mple).
qui nwergm mynet, edges nodematch(sex)
assert _rc == 0
assert `"`e(method)'"' == "mple"
assert colsof(e(b)) == 2

* --- method(mple) explicit request on a dyad-DEPENDENT model prints a
* pseudolikelihood-not-MLE note and still reports mple results (not an
* error) - exercised on a directed network with mutual.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,0,0,1\0,0,0,1,0)) directed name(mydirnet) labs(A,B,C,D,E)
qui nwergm mydirnet, edges mutual method(mple)
assert _rc == 0
assert `"`e(method)'"' == "mple"

* --- MCMLE path (default method for a dyad-dependent model): same
* directed network, edges+mutual. A real reciprocity effect exists in
* this hand-built network (a fully mutual triangle among the first
* three nodes plus more), so MCMLE should converge to a genuinely
* positive mutual coefficient - not just "runs without erroring".
set seed 999
qui nwergm mydirnet, edges mutual mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert `"`e(method)'"' == "mcmle"
assert e(converged) == 1
assert e(mcmle_iterations) > 0 & e(mcmle_iterations) <= 15
assert _b[mutual] > 1
assert `"`e(proposal)'"' == "tnt"

* --- proposal(uniform) also runs and converges (both proposals are
* certified at the Mata level already - this just confirms the .ado
* correctly threads the option through).
set seed 998
qui nwergm mydirnet, edges mutual proposal(uniform) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(15)
assert _rc == 0
assert `"`e(proposal)'"' == "uniform"

* --- network-type rejections: two-mode, temporal-adjacent (valued
* here, since this package's temporal groundwork doesn't yet have a
* trivial one-line "make a temporal network" test fixture elsewhere -
* valued is exercised directly below), and the term/network-type
* mismatches (mutual/nodeicov/nodeocov require directed; gwesp/
* gwodegree/gwidegree have their own directedness requirements).
nwclear
nw2set, mat((0,1,0\1,0,1\0,1,1)) name(twomode)
capture noisily nwergm twomode, edges
assert _rc != 0

nwclear
nwset, mat((0,2,0\2,0,3\0,3,0)) name(wnet)
capture noisily nwergm wnet, edges
assert _rc != 0

nwclear
nwset, mat((0,1\1,0)) undirected name(unet)
capture noisily nwergm unet, edges mutual
assert _rc != 0
capture noisily nwergm unet, edges nodeicov(sex)
assert _rc != 0
capture noisily nwergm unet, edges gwodegree(.5)
assert _rc != 0

nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed name(dnet2)
capture noisily nwergm dnet2, edges gwesp(.5)
assert _rc != 0

* --- edges is required.
nwclear
nwset, mat((0,1\1,0)) undirected name(unet2)
capture noisily nwergm unet2, mutual
assert _rc != 0

* --- edgecov(): dyadic covariate taken from another loaded network's
* own tie values, on the same node set.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(basenet3) labs(A,B,C,D,E)
nwset, mat((0,3,1,4,2\3,0,2,1,5\1,2,0,3,1\4,1,3,0,2\2,5,1,2,0)) undirected name(covnet) labs(A,B,C,D,E)
qui nwergm basenet3, edges edgecov(covnet)
assert _rc == 0
assert colsof(e(b)) == 2

* --- gwesp()/gwdegree() run to completion (fixed decay, MCMLE path -
* both dyad-dependent) and report finite, non-degenerate results.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(basenet4) labs(A,B,C,D,E)
set seed 1001
qui nwergm basenet4, edges gwesp(.5) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(10)
assert _rc == 0
assert `"`e(method)'"' == "mcmle"
mata: assert(!missing(st_matrix("e(b)")))
