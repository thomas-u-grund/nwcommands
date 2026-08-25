cscript

do unw_core.do

* nwdissimilar had zero test coverage and was completely non-functional
* before this session: every call crashed with "euclidean_dissimilarity()
* not found" (r(3499)), even after two earlier, separate bug fixes
* (nwtomatafast's dead pre-2016 nw_mata<id> reference, and matastrict
* compile errors in the (dis)similarity Mata functions themselves) had
* already been made and certified. Root-caused with a minimal two-ado-
* file repro: Mata functions defined in an ado-file's own trailing
* mata: block are PRIVATE to that ado-file - visible only to mata code
* running from *within that same file* - not to a *different* ado-
* file's own mata: blocks, even when that second file is invoked
* synchronously from the first (confirmed directly: an identical
* function, called from its own defining ado-file, works; called from
* a second ado-file given only the unevaluated expression text, fails
* "not found"). nwdissimilar used to pass an unevaluated function-call
* expression straight through to nwset's mat() option, which evaluates
* its argument inside *nwset.ado's own* private mata scope - so it
* could never see nwdissimilar.ado's private functions, regardless of
* adopath/timing (an inconclusive investigation into this exact
* symptom was logged, without the root cause, earlier this session).
* Interactive mata *workspace variables*, unlike function definitions,
* are NOT ado-file-private - fixed by evaluating the dissimilarity
* function inside nwdissimilar.ado itself (where it IS visible) into
* such a variable, then passing that already-computed matrix's name to
* nwset instead of an unevaluated function call.
*
* A second, related bug was found and fixed while building this test:
* the resulting dissimilarity network's diagonal came back missing
* (nwset's default when selfloop is not given), even though a node's
* dissimilarity from itself is a genuine, well-defined value (0) that
* the dissimilarity functions themselves already compute correctly -
* fixed by passing selfloop to nwset. A third bug: the dissimilarity
* network never inherited the source network's own node labels (nwset
* defaulted to generic n1/n2/... instead) - harmless standalone, but
* broke nwhierarchy's default path, which relies on nwdissimilar's
* output sharing node identity with the original network (see
* test_nwhierarchy.do). Fixed by deriving labs() from the source
* network by default when the caller doesn't specify one.

* --- 4-cycle network (A-B, B-C, C-D, D-A): opposite nodes (A,C and
* B,D) are structurally equivalent (identical tie profiles once self
* is excluded), so their dissimilarity must be exactly 0 under every
* measure, while adjacent nodes (A,B) must be strictly positive.
* Hand-computed euclidean distance for A vs B (context both): A's
* ties (excluding A,B themselves) = [_,_,0,1] (to C,D), B's ties
* (excluding A,B) = [_,_,1,0] - both out and in vectors are identical
* here (undirected), so D_AB = sqrt((0-1)^2+(1-0)^2 + same again)
* = sqrt(1+1+1+1) = 2.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwdissimilar net1, type(euclidean)
nwtomatafast _dissimilar
mata: Dmat = `r(mata)'
mata: assert(Dmat[1,1] == 0)
mata: assert(Dmat[2,2] == 0)
mata: assert(Dmat[1,2] == 2)
mata: assert(Dmat[1,3] == 0)
mata: assert(Dmat[2,4] == 0)
mata: mata drop Dmat

* --- the dissimilarity network must inherit the source network's own
* node labels (not nwset's generic n1/n2/... fallback), and must not
* alter the currently loaded dataset's node count (a real bug found
* and fixed while building this test - see the header comment above).
assert _N == 4
nwname _dissimilar
assert `"`r(labs)'"' == "A,B,C,D"

* --- all 5 documented dissimilarity types must run cleanly and
* produce a symmetric, zero-diagonal result (structural properties
* that must hold regardless of the specific formula).
foreach t in euclidean manhatten nonmatches jaccard hamming {
	nwclear
	nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
	nwdissimilar net1, type(`t')
	nwtomatafast _dissimilar
	mata: Dm = `r(mata)'
	mata: assert(Dm[1,1] == 0)
	mata: assert(reldif(Dm[1,2], Dm[2,1]) < 1e-9 | (Dm[1,2]==0 & Dm[2,1]==0))
	mata: mata drop Dm
}

* --- context(incoming)/context(outgoing) must run cleanly on a
* directed network (a case that could never even be reached before
* this session's fix).
nwclear
nwset, mat((0,1,0,1\0,0,1,0\0,0,0,1\1,0,0,0)) name(dnet) directed labs(A,B,C,D)
nwdissimilar dnet, type(hamming) context(incoming) name(_din)
assert _rc == 0
nwdissimilar dnet, type(hamming) context(outgoing) name(_dout)
assert _rc == 0

* --- name()/xvars: a custom name must be honored, and (default, no
* xvars) the final nwload must be suppressed (none of the new
* dissimilarity network's own per-node variables appear - it inherits
* net1's own A/B/C/D node labels as its default Stata variable names,
* same convention nwset() itself uses when no vars() is given - the
* current dataset's own keepme is untouched).
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
gen keepme = 1
nwdissimilar net1, type(euclidean) name(_customdis)
assert _N == 4
capture confirm variable keepme
assert _rc == 0
capture confirm variable A
assert _rc != 0

* xvars additionally invokes nwload, generating the new network's own
* Stata variables (A.._D, inherited from net1's own node labels)
* alongside keepme.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
gen keepme = 1
nwdissimilar net1, type(euclidean) name(_customdis) xvars
assert _N == 4
capture confirm variable keepme
assert _rc == 0
capture confirm variable A
assert _rc == 0
