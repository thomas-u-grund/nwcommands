cscript

do unw_core.do

* nwdyads had a SMCL doc header but literally no cscripts/test_*.do file
* at all (found while scoping harmonisation unit 16, not itself fixed by
* it - see docs/CERTIFICATION.md's own Pending-table history). Writing
* real hand-computable known-answer tests (per the certification
* standard's own "Functional" requirement) surfaced a genuine,
* previously-undiscovered bug in unw_core.do's own
* NWdef::calculate_dyadcensus(): the one-mode null-dyad count used
* `n*(n-1) - asym - mutual`, but n*(n-1) is the count of ORDERED pairs
* (i,j) and (j,i) counted separately) - a dyad is an UNORDERED pair, so
* the correct total is n*(n-1)/2, not n*(n-1). The missing /2 silently
* doubled every reported null-dyad count, landing entirely in r(_001)/
* the displayed "Null" column, since mutual and asym are each computed
* independently via their own already-correctly-halved formulas.
* r(reciprocity) (mutual/(mutual+asym)) does not depend on null at all,
* so this bug was completely invisible in that stored result - only the
* null count itself was wrong, for every single network, every time.
* Confirmed via 3 hand-computable one-mode cases below (before the fix:
* a fully-connected undirected triangle reported null=3 instead of the
* correct 0; a 3-node mixed directed network reported null=4 instead of
* 1; an empty 3-node network reported null=6 instead of 3 - in every
* case exactly double). Fixed in unw_core.do by dividing by 2. The
* two-mode branch (`get_nodes_mode1() * get_nodes_mode2()`, no /2
* needed since mode1-mode2 pairs are cross-set, not same-set unordered
* pairs) was already correct and is unaffected by this fix - confirmed
* directly via its own hand-computable case below. This touches
* unw_core.do (shared Mata core) - rebuilt lib/lnwcommands.mlib via
* lib/build.do and re-verified in production mode. Only caller of
* calculate_dyadcensus() in the whole package is nwdyads.ado itself
* (confirmed via direct grep), so this fix's blast radius is narrow
* despite touching the shared core.

* --- fully-connected undirected triangle: all 3 possible dyads are
* mutual, none null.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected labs(A,B,C)
nwdyads tri
assert _rc == 0
assert r(_100) == 3
assert r(_010) == 0
assert r(_001) == 0
assert r(reciprocity) == 1

* --- 3-node directed network with one of each dyad type: A->B only
* (asym), B<->C (mutual), A/C unconnected (null).
nwclear
nwset, mat((0,1,0\0,0,1\0,1,0)) name(mix) directed labs(A,B,C)
nwdyads mix
assert _rc == 0
assert r(_100) == 1
assert r(_010) == 1
assert r(_001) == 1
assert r(reciprocity) == .5

* --- empty 3-node undirected network: all 3 possible dyads are null.
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(empt) undirected labs(A,B,C)
nwdyads empt
assert _rc == 0
assert r(_100) == 0
assert r(_010) == 0
assert r(_001) == 3

* --- two-mode network (regression guard: this branch was already
* correct, must remain so): 3 actors (A,B,C), 2 events (E1,E2). A ties
* to both events, B only to E1, C only to E2 - 4 of the 6 possible
* actor-event pairs are connected, 2 are not; two-mode ties have no
* directed/asymmetric concept, so asym is always 0.
nwclear
mata: bip = (1,1 \ 1,0 \ 0,1)
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(net1) labs(E1,E2,A,B,C)
nwdyads net1
assert _rc == 0
assert r(_100) == 4
assert r(_010) == 0
assert r(_001) == 2

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwdyads nonexistent
assert _rc == 482
