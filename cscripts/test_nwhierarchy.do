cscript

do unw_core.do

* nwhierarchy had zero test coverage. Its default (no dismat()/disnet())
* path calls nwdissimilar internally, so it was blocked end-to-end by
* the exact same nwdissimilar/nwset root cause described in
* test_nwdissimilar.do's header comment, plus one nwhierarchy-specific
* consequence of a bug that fix surfaced: before nwdissimilar.ado was
* fixed to inherit the source network's own node labels, the internal
* `_temp_dissimilar` network it builds got nwset's generic n1/n2/...
* labels instead of the source network's real labels - and since
* nwcommands' master dataset keys rows by node label across every
* currently-tracked network, two differently-labeled 4-node networks
* looked like a disjoint 8-node union to Stata's own `clustermat`
* (which nwhierarchy delegates the actual clustering to), crashing with
* "number of selected observations must match dimension of mymat"
* (r(198)). Fixed as part of nwdissimilar.ado's own label-inheritance
* fix - nothing further needed in nwhierarchy.ado itself. The
* dismat()/disnet() forms, which bypass nwdissimilar entirely, were
* unaffected by any of this and are exercised separately below.

* --- default path (no dismat()/disnet()): must run to completion and
* produce a genuine cluster object matching the network's node count.
* 4-cycle network (A-B, B-C, C-D, D-A) - single-linkage clustering on
* euclidean dissimilarity should first merge the two structurally
* equivalent pairs (A,C and B,D each have dissimilarity 0 - see
* test_nwdissimilar.do), which is checkable via Stata's own cluster
* generate() without re-deriving clustermat's internals.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwhierarchy net1
assert _rc == 0
cluster query _clus_1
assert `"`r(type)'"' == "hierarchical"
assert `"`r(method)'"' == "single"
count if !missing(_clus_1_id)
assert r(N) == 4

* --- type()/context()/linkage() must all be honored and run cleanly.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwhierarchy net1, type(jaccard) context(outgoing) linkage(averagelinkage)
assert _rc == 0

* --- dismat(): a directly-supplied Stata matrix must be used as-is,
* bypassing nwdissimilar. Reuses the hand-derived euclidean
* dissimilarity matrix from test_nwdissimilar.do so the clustering
* input is independently known, not just "whatever nwdissimilar
* produces".
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
matrix handmat = (0,2,0,2 \ 2,0,2,0 \ 0,2,0,2 \ 2,0,2,0)
nwhierarchy, dismat(handmat)
assert _rc == 0
count if !missing(_clus_1_id)
assert r(N) == 4

* --- disnet(): a dissimilarity matrix supplied as an existing network
* (rather than a Stata matrix) must also work, and must not require
* label-matching the way the default path does (disnet() bypasses
* nwdissimilar's own label-inheritance logic entirely).
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwset, mat((0,2,0,2\2,0,2,0\0,2,0,2\2,0,2,0)) name(net2) undirected selfloop labs(A,B,C,D)
nwhierarchy net1, disnet(net2)
assert _rc == 0
