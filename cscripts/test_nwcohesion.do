cscript

do unw_core.do

* nwcohesion implements the full, multi-level Moody & White (2003)
* cohesive-blocking hierarchy, built entirely on top of the already-
* certified single-level primitives underlying nwkcomponents (see
* test_nwkcomponents.do): vertex_connectivity()/KComponents(). New Mata
* infrastructure added here: NWdef::extract_subgraph() (a fresh,
* unregistered induced-subgraph copy - hand-verified in isolation via a
* direct probe: original network provably untouched, subgraph's tie
* structure exactly matches the induced subgraph, before ever being
* wired into anything; not actually used by nwcohesion's own recursion,
* since KComponents() already operates directly on 0/1 node-indicator
* vectors over the shared original adjacency matrix - kept as a
* standalone, separately-tested primitive for reuse by other Stage
* 2/Stage 3 work, e.g. ego-network induced-subgraph extraction) and
* CohesionHierarchy()/NWdef::calculate_cohesion_hierarchy() (the actual
* recursive multi-level decomposition: unlike KComponents(), which only
* ever reports node sets meeting one REQUESTED target k, this reports
* EVERY node set visited during the recursion at its own TRUE
* connectivity level, recursing into (level+1)-components found within
* it until no set is large enough to possibly split further).
*
* Also fixed in the same unit: NWdef::keep_nodes()/drop_nodes() never
* called ensure_dense_built() before reading `edge` directly, unlike
* every other dense-touching method in the class - meaning both would
* have silently operated on an empty/stale dense matrix for a genuinely
* sparse-native network (edge_dense_built==False). Found while building
* extract_subgraph() (which calls keep_nodes() internally) - fixed by
* adding the same ensure_dense_built() guard check_symmetry() and others
* already use.

* --- two triangles {A,B,C} and {D,E,F} joined by a single bridge edge
* C-D (identical network to test_nwkcomponents.do's own first case).
* Hand-derivable: whole graph has connectivity 1 (C or D is a genuine
* cut vertex - NOT 0, since the graph IS connected via the bridge; 0
* would mean already-disconnected). Splitting at level 1+1=2 finds
* {A,B,C} and {D,E,F}, each a complete triangle (connectivity 2 = n-1),
* too small (3 nodes < 2+2=4) to split any further. Exactly 3 blocks
* total: the whole graph (level 1) plus the two triangles (level 2
* each) - confirmed by an isolated Mata probe before this test was
* written.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwcohesion net1
assert _rc == 0
assert r(blocks) == 3
sort _nwnode
tempname lab num
mata: `lab' = st_sdata(., "_nwnode")
mata: `num' = st_data(., "_cohesion")
mata: assert(select(`num', `lab':=="A") == 2)
mata: assert(select(`num', `lab':=="B") == 2)
mata: assert(select(`num', `lab':=="C") == 2)
mata: assert(select(`num', `lab':=="D") == 2)
mata: assert(select(`num', `lab':=="E") == 2)
mata: assert(select(`num', `lab':=="F") == 2)
mata: mata drop `lab' `num'
mata:
cm = st_matrix("r(cohesion_matrix)")
cl = st_matrix("r(cohesion_levels)")
targettop = (1,1,1,1,1,1)
target1 = (1,1,1,0,0,0)
target2 = (0,0,0,1,1,1)
foundtop = 0
found1 = 0
found2 = 0
for (i=1; i<=rows(cm); i++) {
	if (cm[i,.]==targettop & cl[i]==1) foundtop=1
	if (cm[i,.]==target1 & cl[i]==2) found1=1
	if (cm[i,.]==target2 & cl[i]==2) found2=1
}
end
mata: assert(foundtop == 1)
mata: assert(found1 == 1)
mata: assert(found2 == 1)
mata: mata drop cm cl targettop target1 target2 foundtop found1 found2 i

* --- single triangle: too small (3 nodes) to ever split past its own
* level (connectivity 2 = n-1); exactly one block, all 3 nodes at
* level 2.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
nwcohesion tri
assert _rc == 0
assert r(blocks) == 1
count if _cohesion == 2
assert r(N) == 3

* --- fully disconnected 4-node graph (no edges at all): connectivity 0
* (already disconnected, by definition), and KComponents at k=1 finds
* no qualifying subset anywhere (no two isolates are even reachable),
* so recursion stops with exactly the one top block.
nwclear
nwset, mat((0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0)) name(iso) undirected
nwcohesion iso
assert _rc == 0
assert r(blocks) == 1
count if _cohesion == 0
assert r(N) == 4

* --- two disjoint triangles, NO bridge at all (genuinely disconnected):
* the whole 6-node graph has connectivity 0 (disconnected), but
* KComponents at k=1 finds each triangle as its own 1-component (the
* ordinary "connected components" case), each then further resolving
* to its own true level-2 connectivity. Every node's OWN highest level
* is 2 (its triangle), not 0 (the whole graph) - confirming
* generate()'s "highest level across all containing blocks" semantics.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net3) undirected
nwcohesion net3
assert _rc == 0
assert r(blocks) == 3
count if _cohesion == 2
assert r(N) == 6

* --- directed networks are symmetrized automatically (matching
* nwkcomponents/nwclique/nwkplex/nwnclique): A->B,B->A,A->C,B->C,C->B
* collapses to a full undirected triangle - one block, level 2.
nwclear
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed
nwcohesion dnet
assert _rc == 0
assert r(blocks) == 1
count if _cohesion == 2
assert r(N) == 3

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwcohesion net1, generate(customcoh)
assert _rc == 0
capture confirm variable customcoh, exact
assert _rc == 0
capture noisily nwcohesion net1, generate(customcoh)
assert _rc != 0
nwcohesion net1, generate(customcoh) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(neta) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(netb) undirected labs(A,B,C,D,E,F)
nwcohesion neta netb
assert _rc == 0
capture confirm variable _cohesion1, exact
assert _rc == 0
capture confirm variable _cohesion2, exact
assert _rc == 0

* --- silent suppresses display but not the underlying computation.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri2) undirected
nwcohesion tri2, silent
assert _rc == 0
assert r(blocks) == 1

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwcohesion nonexistent
assert _rc == 482
