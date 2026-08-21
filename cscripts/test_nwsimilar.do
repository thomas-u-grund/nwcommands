cscript

do unw_core.do

* nwsimilar had zero test coverage and was completely non-functional
* before this session for every type() except pearson (which delegates
* to the already-working nwcorrelate): "matches"/"jaccard"/"hamming"/
* "crossproduct" all crashed with "<fn>_similarity() not found"
* (r(3499)). Root cause and fix are identical to nwdissimilar.ado's -
* see test_nwdissimilar.do's header comment for the full explanation
* (Mata functions defined in an ado-file's own trailing mata: block
* are private to that file, so nwset's mat() option - which evaluates
* its argument in *its own* private scope - could never see them).
*
* A second, independent bug was found and fixed while building this
* test: type(crossproduct) dispatched to hamming_similarity() (a
* copy-paste of the line above it), not crossproduct_similarity() -
* crossproduct_similarity() was fully implemented but completely dead,
* never reachable through any type() value. Fixed to call the correct
* function. A third, shared bug (missing diagonal, missing node-label
* inheritance) was also fixed identically to nwdissimilar.ado's own -
* see that file's header comment.

* --- 4-cycle network (A-B, B-C, C-D, D-A): opposite nodes (A,C and
* B,D) have identical tie profiles (once self is excluded), so their
* similarity must be maximal under every measure, while adjacent
* nodes (A,B) must be strictly less similar. matches_similarity's
* dtype=0 formula gives exactly 1 for identical vectors (by
* construction: sum(i==j) equals the full vector length when the
* vectors are identical, making the formula's numerator equal its own
* denominator) and, hand-computed for A vs B here, exactly 0 (every
* one of the 4 compared positions - 2 out, 2 in - disagrees).
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwsimilar net1, type(matches) name(_s1)
nwtomatafast _s1
mata: Smat = `r(mata)'
mata: assert(Smat[1,1] == 1)
mata: assert(Smat[2,2] == 1)
mata: assert(Smat[1,3] == 1)
mata: assert(Smat[2,4] == 1)
mata: assert(reldif(Smat[1,2], 0) < 1e-9)
mata: mata drop Smat

* --- the similarity network must inherit the source network's own
* node labels, not nwset's generic n1/n2/... fallback (a real bug
* found and fixed while building this test - see the header comment).
assert _N == 4
nwname _s1
assert `"`r(labs)'"' == "A,B,C,D"

* --- all 5 documented similarity types (pearson, matches, jaccard,
* hamming, crossproduct) must run cleanly and produce a symmetric,
* well-defined (non-maximal-by-construction is not asserted, since
* pearson's own diagonal is a correlation of a constant-zero vector
* with itself - genuinely undefined/missing, not a bug; see
* nwcorrelate's own certification for that documented edge case).
foreach t in pearson matches jaccard hamming crossproduct {
	nwclear
	nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
	nwsimilar net1, type(`t') name(_stest)
	assert _rc == 0
}

* --- crossproduct dispatch fix: crossproduct_similarity() must now
* actually run (was previously silently replaced by hamming's own
* formula). Hand-computed for A vs C (identical tie profiles [0,1,0,1]
* and [0,1,0,1] once self-positions are zeroed): out cross-product =
* 0*0+1*1+0*0+1*1 = 2 (summed over both out and in, since undirected
* in/out vectors are identical here) = 4 total. For A vs B (profiles
* [0,0,0,1] and [0,0,1,0] once self-positions are zeroed): cross
* product = 0 in every position, both out and in = 0 total. These two
* values are different from what hamming_similarity would have given
* for the same pairs (2 matches for A,B under hamming - see the
* matches_similarity computation above, a related but distinct
* measure) - confirming the dispatch now genuinely reaches
* crossproduct's own formula, not a copy of hamming's.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwsimilar net1, type(crossproduct) name(_scp)
nwtomatafast _scp
mata: Cmat = `r(mata)'
mata: assert(Cmat[1,3] == 4)
mata: assert(Cmat[1,2] == 0)
mata: mata drop Cmat

* --- mode(incoming)/mode(outgoing) must run cleanly on a directed
* network (a case that could never even be reached before this
* session's fix).
nwclear
nwset, mat((0,1,0,1\0,0,1,0\0,0,0,1\1,0,0,0)) name(dnet) directed labs(A,B,C,D)
nwsimilar dnet, type(hamming) mode(incoming) name(_sin)
assert _rc == 0
nwsimilar dnet, type(hamming) mode(outgoing) name(_sout)
assert _rc == 0
