cscript

do unw_core.do

* nwconcor is a new command (harmonisation unit 21, Part XVII special
* priority: structural equivalence and classical SNA). It implements
* CONCOR (Breiger, Boorman & Arabie 1975) via a new NWdef::calculate_concor()
* Mata method (unw_core.do), delegating to standalone ConcorConverge()/
* ConcorSplitIDs() helpers (the same "instance method delegates to a
* standalone function" pattern already used by calculate_modularity()/
* Louvain()).
*
* While building this: (1) found Mata's own _error(code, message) silently
* hits an undocumented ~100-character cap on its message argument,
* failing with a *different*, unrelated-looking error ("argument out of
* range", r(3300)) rather than anything obviously about message length -
* confirmed by bisection (100 chars: fine; 110: fails). Worked around with
* errprintf()+exit(error()) instead, which has no such limit found.
* (2) Found and fixed a real, independent, pre-existing bug shared by
* nwcomponents.ado and nwcommunity.ado (both copy-paste ancestors of this
* file's own structure): their own already-exists variable check tested
* the *bare* generate() stem, not the actual suffixed name about to be
* created on a given netlist iteration - so on a second-or-later network
* in a netlist call, Stata's own variable-name abbreviation let `confirm
* variable _component' silently match an already-existing `_component1'
* from the first iteration, falsely blocking every subsequent one even
* though its own real target name was still free. Fixed in all three
* files (nwconcor.ado's own version never shipped with the bug) - see
* test_nwcomponents.do/test_nwcommunity.do for their own regression
* tests of the same fix.

* --- two disjoint 3-cliques (A,B,C and D,E,F), zero cross-ties: CONCOR
* cannot avoid separating them (any split that doesn't respect this
* boundary would put two nodes with perfectly correlated tie profiles
* into different blocks and two uncorrelated nodes into the same one,
* the opposite of what the sign-of-correlation split does) - a strong,
* structure-forced regression check, not merely "runs without crashing".
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwconcor net1
assert _rc == 0
assert r(blocks) == 2
assert _concor[1] == _concor[2]
assert _concor[2] == _concor[3]
assert _concor[4] == _concor[5]
assert _concor[5] == _concor[6]
assert _concor[1] != _concor[4]
mat sz = r(block_sizeid)
assert sz[1,1] == 3
assert sz[2,1] == 3
_assert_streq `"`: colfullnames sz'"' `"size blockid share"'

* --- recursive splits(2): 4 disjoint 3-cliques, grouped into two
* "super-blocks" of 2 cliques each via a single distinguishing weak
* cross-tie per super-block (G1-G2 share a weak tie, G3-G4 share a
* different weak tie, no ties at all between the two super-blocks) -
* the strong within-clique ties dominate the second-level split within
* each super-block, while the weak cross-ties are what let the first
* level tell the two super-blocks apart at all (fully symmetric,
* completely disconnected cliques have no signal to prefer any
* particular pairing - confirmed by direct experimentation while
* building this test, not assumed).
nwclear
mata:
M = J(12,12,0)
for (b=0; b<4; b++) {
	for (i=1;i<=3;i++) {
		for (j=1;j<=3;j++) {
			if (i!=j) M[b*3+i,b*3+j]=5
		}
	}
}
M[3,4]=1
M[4,3]=1
M[9,10]=1
M[10,9]=1
st_matrix("M", M)
end
nwset, mat(M) name(net2) undirected labs(A,B,C,D,E,F,G,H,I,J,K,L)
nwconcor net2, splits(2) generate(myblock)
assert _rc == 0
assert r(blocks) == 4
assert myblock[1] == myblock[2] & myblock[2] == myblock[3]
assert myblock[4] == myblock[5] & myblock[5] == myblock[6]
assert myblock[7] == myblock[8] & myblock[8] == myblock[9]
assert myblock[10] == myblock[11] & myblock[11] == myblock[12]
assert myblock[1] != myblock[4]
assert myblock[7] != myblock[10]
assert rowsof(r(block_sizeid)) == 4

* --- isolates are rejected explicitly, not silently mishandled.
nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(neti) undirected labs(A,B,C)
capture noisily nwconcor neti
assert _rc != 0

* --- directed networks work directly, no symmetrize needed (unlike
* nwcommunity) - CONCOR's own profile already keeps out-ties and
* in-ties separate.
nwclear
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\0,0,0,0,0,0\0,0,0,0,1,1\0,0,0,0,0,1\0,0,0,0,0,0)) name(dnet) directed labs(A,B,C,D,E,F)
nwconcor dnet
assert _rc == 0
assert r(blocks) == 2

* --- measure(binary)/measure(valued) must both run cleanly on a
* valued network (default follows the network's own valued-ness).
nwclear
nwset, mat((0,5,3,0,0,0\5,0,4,0,0,0\3,4,0,0,0,0\0,0,0,0,2,7\0,0,0,2,0,6\0,0,0,7,6,0)) name(wnet) undirected labs(A,B,C,D,E,F)
nwconcor wnet, measure(binary)
assert _rc == 0
nwconcor wnet, measure(valued) replace
assert _rc == 0

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwconcor net1, generate(customblock)
assert _rc == 0
capture confirm variable customblock, exact
assert _rc == 0
capture noisily nwconcor net1, generate(customblock)
assert _rc != 0
nwconcor net1, generate(customblock) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable (see this file's own header comment for
* the netlist already-exists-check bug found and fixed while building
* this).
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net3) undirected labs(A,B,C,D,E,F)
nwconcor net1 net3
assert _rc == 0
capture confirm variable _concor1, exact
assert _rc == 0
capture confirm variable _concor2, exact
assert _rc == 0

* --- invalid splits()/maxiter() must error clearly, not silently
* misbehave.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
capture noisily nwconcor net1, splits(0)
assert _rc != 0
capture noisily nwconcor net1, maxiter(0)
assert _rc != 0


* --- alpha-audit regression: a failed call (e.g. an isolate node, which
* CONCOR rejects) used to leave a stale, all-missing output variable
* behind - `gen netgenerate = .' ran BEFORE the call that could fail, so
* a failure's own `exit' left the half-created variable in place. That
* then falsely tripped the "already exists; specify replace" collision
* guard on any retry, masking the real error entirely - exactly what the
* package's own .sthlp worked example hit (its own second example line
* reported the misleading "already exists" error instead of the real
* isolates problem the first line had already failed on). Also
* regression-tests that a fully successful call leaves _rc==0 (a related
* bug introduced and caught during this same fix: capture drop's own
* harmless "variable not found" return code must not leak out as the
* command's final _rc on a successful run - Stata does not reset _rc on
* ordinary successful commands, only on another capture or a real error).
nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(withiso) undirected labs(A,B,C)
capture noisily nwconcor withiso
assert _rc != 0
capture confirm variable _concor, exact
assert _rc != 0
di "=== NO STALE VARIABLE AFTER A FAILED CALL, VERIFIED ==="

nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(clean) undirected labs(A,B,C)
nwconcor clean
assert _rc == 0
di "=== SUCCESSFUL CALL LEAVES _rc==0, VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwconcor nonexistent
assert _rc == 482
