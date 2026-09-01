cscript

do unw_core.do

* nwcoreperiphery is a new command (harmonisation unit 22, Part XVII special
* priority: structural equivalence and classical SNA), implementing discrete
* core-periphery detection (Borgatti & Everett 1999) via a new
* NWdef::calculate_coreperiphery() Mata method (unw_core.do), delegating to
* standalone CorePeriphery()/nw_cp_fitness() helpers - the same "instance
* method delegates to a standalone function" pattern already used by
* calculate_modularity()/Louvain() and calculate_concor()/ConcorSplitIDs().
* Closes another piece of docs/FEATURE_AUDIT.md area F's "confirmed E
* across the entire area" gap (no core-periphery functionality existed
* anywhere), alongside nwconcor (harmonisation unit 21).

* --- a network built to have an EXACT discrete core-periphery structure
* by construction (3 fully-interconnected core nodes A,B,C, each also
* tied to every periphery node; 3 periphery nodes D,E,F with no ties
* among themselves) must be recovered exactly, with fitness exactly 1
* (a perfect correlation between observed and ideal pattern) - a
* structure-forced check, not merely "runs without crashing".
nwclear
nwset, mat((0,1,1,1,1,1\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,0,0\1,1,1,0,0,0\1,1,1,0,0,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwcoreperiphery net1
assert _rc == 0
assert reldif(r(fitness), 1) < 1e-6
assert r(core) == 3
assert _core[1] == 1 & _core[2] == 1 & _core[3] == 1
assert _core[4] == 0 & _core[5] == 0 & _core[6] == 0

* --- determinism: the algorithm is a fixed-order (1..n) greedy local
* search with no randomness, so repeated calls on the same network must
* give bit-identical results.
nwclear
nwset, mat((0,1,1,1,1,0\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,1,0\1,1,1,1,0,0\0,1,1,0,0,0)) name(net2) undirected labs(A,B,C,D,E,F)
nwcoreperiphery net2, generate(run1)
local fit1 = r(fitness)
nwcoreperiphery net2, generate(run2)
local fit2 = r(fitness)
assert reldif(`fit1', `fit2') < 1e-9
forvalues i = 1/6 {
	assert run1[`i'] == run2[`i']
}

* --- an isolate node (no ties at all) must not crash - unlike nwconcor,
* core-periphery fitness is a whole-matrix correlation, not a per-node
* profile comparison, so a degree-0 node causes no division-by-zero; it
* should simply be assigned to the periphery (it cannot contribute to
* any core-implied tie).
nwclear
nwset, mat((0,1,1,1,1,1,0\1,0,1,1,1,1,0\1,1,0,1,1,1,0\1,1,1,0,0,0,0\1,1,1,0,0,0,0\1,1,1,0,0,0,0\0,0,0,0,0,0,0)) name(net3) undirected labs(A,B,C,D,E,F,G)
nwcoreperiphery net3
assert _rc == 0
assert _core[7] == 0

* --- a network with no ties at all must be rejected explicitly (no
* structure to fit a core-periphery pattern to), not silently
* mishandled.
nwclear
nwset, mat((0,0\0,0)) name(empty1) undirected labs(A,B)
capture noisily nwcoreperiphery empty1
assert _rc != 0

* --- directed networks are symmetrized automatically (no explicit
* symmetrize option, unlike nwcommunity - the classical model itself
* does not distinguish direction) - must run cleanly, not error asking
* for a symmetrize option the way nwcommunity does.
nwclear
nwset, mat((0,1,1,0,0,0\0,0,1,1,0,0\0,0,0,0,1,0\0,0,0,0,0,0\0,0,0,0,0,1\0,0,0,0,0,0)) name(dnet) directed labs(A,B,C,D,E,F)
nwcoreperiphery dnet
assert _rc == 0
assert r(fitness) >= -1 & r(fitness) <= 1

* --- measure(binary)/measure(valued) must both run cleanly on a valued
* network (default follows the network's own valued-ness).
nwclear
nwset, mat((0,5,3,4,2,1\5,0,4,3,2,1\3,4,0,2,1,1\4,3,2,0,0,0\2,2,1,0,0,0\1,1,1,0,0,0)) name(wnet) undirected labs(A,B,C,D,E,F)
nwcoreperiphery wnet, measure(binary)
assert _rc == 0
nwcoreperiphery wnet, measure(valued) replace
assert _rc == 0
assert r(fitness) >= -1 & r(fitness) <= 1

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1,1,1,1\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,0,0\1,1,1,0,0,0\1,1,1,0,0,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwcoreperiphery net1, generate(customcore)
assert _rc == 0
capture confirm variable customcore, exact
assert _rc == 0
capture noisily nwcoreperiphery net1, generate(customcore)
assert _rc != 0
nwcoreperiphery net1, generate(customcore) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
nwset, mat((0,1,1,1,1,1\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,0,0\1,1,1,0,0,0\1,1,1,0,0,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,1,1,1\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,0,0\1,1,1,0,0,0\1,1,1,0,0,0)) name(net4) undirected labs(A,B,C,D,E,F)
nwcoreperiphery net1 net4
assert _rc == 0
capture confirm variable _core1, exact
assert _rc == 0
capture confirm variable _core2, exact
assert _rc == 0

* --- invalid maxiter() must error clearly.
nwclear
nwset, mat((0,1,1,1,1,1\1,0,1,1,1,1\1,1,0,1,1,1\1,1,1,0,0,0\1,1,1,0,0,0\1,1,1,0,0,0)) name(net1) undirected labs(A,B,C,D,E,F)
capture noisily nwcoreperiphery net1, maxiter(0)
assert _rc != 0

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwcoreperiphery nonexistent
assert _rc == 482
