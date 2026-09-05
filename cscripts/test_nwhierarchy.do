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

* --- groups(): the role/position-analysis packaging (harmonisation
* unit 35). On the same 4-cycle A-B-C-D-A used above, structural
* equivalence is hand-derivable directly from each node's own tie
* profile: A ties to {B,D}, C ties to {B,D} - identical, dissimilarity
* 0; B ties to {A,C}, D ties to {A,C} - also identical. So groups(2)
* must split the cycle into exactly {A,C} and {B,D}, its two genuinely
* distinct structural roles - not an arbitrary or order-dependent
* split.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwhierarchy net1, groups(2) generate(_role)
assert _rc == 0
assert r(groups) == 2
assert `"`r(rolevar)'"' == `"_role"'
sort _nwnode
tempname lab role
mata: `lab' = st_sdata(., "_nwnode")
mata: `role' = st_data(., "_role")
mata: assert(select(`role', `lab':=="A") == select(`role', `lab':=="C"))
mata: assert(select(`role', `lab':=="B") == select(`role', `lab':=="D"))
mata: assert(select(`role', `lab':=="A") != select(`role', `lab':=="B"))
mata: mata drop `lab' `role'

* --- replace guard: a second groups() call without replace must be
* rejected; with replace it must succeed.
capture noisily nwhierarchy net1, groups(2) generate(_role)
assert _rc != 0
nwhierarchy net1, groups(2) generate(_role) replace
assert _rc == 0

* --- equivgen() honors a custom variable name.
nwhierarchy net1, groups(2) equivgen(customrole) replace
assert _rc == 0
capture confirm variable customrole, exact
assert _rc == 0

* --- groups(1): the trivial case (everyone in one role) must still
* run cleanly and put every node in the same group.
nwhierarchy net1, groups(1) generate(_role) replace
assert _rc == 0
qui tab _role
assert r(r) == 1

* --- without groups(), behaviour is completely unchanged from before
* this unit: no _role variable is generated, and r(groups)/r(rolevar)
* are not set.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwhierarchy net1
assert _rc == 0
capture confirm variable _role
assert _rc != 0
assert r(groups) == .
assert `"`r(rolevar)'"' == `""'

* moderate-severity pass, community_spectral group: naming consistency -
* the rest of this group (nwcommunity/nwspectral) and the wider package
* convention use generate() for the identical "write a per-node
* partition-id variable" role; nwhierarchy alone used equivgen(). Added
* generate() as a working alias, kept equivgen() for backward
* compatibility.
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net2) undirected labs(A,B,C,D)
nwhierarchy net2, type(hamming) groups(2) generate(myrole)
assert _rc == 0
capture confirm variable myrole
assert _rc == 0
capture noisily nwhierarchy net2, type(hamming) groups(2) generate(a) equivgen(b)
assert _rc == 198
di "=== generate()/equivgen() alias REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwhierarchy nonexistent
assert _rc == 482
