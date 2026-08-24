cscript

do unw_core.do

* nwkcomponents is a new command implementing maximal k-component
* enumeration (Kanevsky 1993) - a subgraph with vertex connectivity of
* at least k(), meaning at least k() nodes must be removed to
* disconnect it. k=1 is exactly an ordinary connected component (see
* nwcomponents, which already implements that case more cheaply via a
* plain reachability search rather than a connectivity computation),
* so nwkcomponents requires k>=1 and points to nwcomponents for k=1.
*
* Built on new standalone Mata infrastructure: bfs_augment() (a single
* Edmonds-Karp BFS augmenting step over an explicit capacity/flow
* matrix), maxflow_vertex_split() (the standard vertex-splitting
* reduction of vertex-connectivity max-flow to ordinary edge-capacity
* max-flow - Even 1979), vertex_connectivity() (Menger's theorem: the
* graph's own overall vertex connectivity is the minimum, over every
* non-adjacent pair, of the minimum vertex set separating them),
* min_vertex_cutset() (extracts an actual minimum cutset, not just its
* size, via a residual-graph BFS after the flow is maximal), and
* KComponents() (the recursive cut-and-recurse decomposition also
* underlying Moody & White's (2003) full cohesive-blocking hierarchy,
* computed here for one target level k rather than the full recursive
* multi-level tree - see nwkcomponents.ado's own "Algorithm" doc
* section for why).
*
* All of this new infrastructure was rigorously hand-verified in
* isolation before ever being wired into calculate_kcomponents() -
* vertex_connectivity()/maxflow_vertex_split() against a 4-node path
* (expect 1), a 4-cycle (expect 2), K4 (expect 3, the "complete graph"
* special case), a disconnected graph (expect 0), K2 (expect 1), and a
* star (expect 1); min_vertex_cutset() against a star (expect just the
* center) and a path (expect one of its two valid middle nodes). Only
* after all of those checks passed was the full recursive
* calculate_kcomponents() itself exercised, below.

* --- two triangles {A,B,C} and {D,E,F} joined by a single bridge edge
* C-D: hand-derivable directly from the recursive algorithm. Overall
* connectivity is 1 (removing C or D disconnects the two triangles),
* so the whole graph doesn't qualify at k=2 - cutting at the bridge
* and recursing into each resulting {component + cutset} piece finds
* {A,B,C} (a complete triangle once C is added back, connectivity 2 -
* qualifies) and {C,D,E,F} (connectivity 1, needs a further cut at D,
* producing a degenerate size-2 {C,D} piece that can never reach
* connectivity 2 and is dropped, and {D,E,F} - another complete
* triangle, connectivity 2, qualifies). Final result: exactly
* {A,B,C} and {D,E,F}, NOT overlapping (C and D each end up in only
* one final qualifying block, not both, since the intermediate {C,D}
* piece that would have connected them didn't itself qualify).
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwkcomponents net1
assert _rc == 0
assert r(kcomponents) == 2
sort _nwnode
tempname lab num
mata: `lab' = st_sdata(., "_nwnode")
mata: `num' = st_data(., "_kcompnum")
mata: assert(select(`num', `lab':=="A") == 3)
mata: assert(select(`num', `lab':=="B") == 3)
mata: assert(select(`num', `lab':=="C") == 3)
mata: assert(select(`num', `lab':=="D") == 3)
mata: assert(select(`num', `lab':=="E") == 3)
mata: assert(select(`num', `lab':=="F") == 3)
mata: mata drop `lab' `num'
mata:
kcm = st_matrix("r(kcomp_matrix)")
target1 = (1,1,1,0,0,0)
target2 = (0,0,0,1,1,1)
found1 = 0
found2 = 0
for (i=1; i<=rows(kcm); i++) {
	if (kcm[i,.]==target1) found1=1
	if (kcm[i,.]==target2) found2=1
}
end
mata: assert(found1 == 1)
mata: assert(found2 == 1)
mata: mata drop kcm target1 target2 found1 found2 i

* --- bowtie: two triangles {A,B,X} and {X,D,E} sharing the single cut
* node X (not a bridge edge this time, a shared cutpoint). Overall
* connectivity is 1 (removing X disconnects {A,B} from {D,E}); cutting
* at X and recursing finds {A,B,X} and {X,D,E}, both complete
* triangles (connectivity 2, qualify) - this time genuinely OVERLAPPING
* at X, unlike the bridge-edge case above, confirming k-components
* correctly keep a cutset shared across every resulting sub-block its
* removal reveals, not assigned to just one side.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,1\0,0,1,0,1\0,0,1,1,0)) name(net2) undirected labs(A,B,X,D,E)
nwkcomponents net2
assert _rc == 0
assert r(kcomponents) == 2
sort _nwnode
mata: lab2 = st_sdata(., "_nwnode")
mata: num2 = st_data(., "_kcompnum")
mata: assert(select(num2, lab2:=="X") == 3)
mata: mata drop lab2 num2
mata:
kcm2 = st_matrix("r(kcomp_matrix)")
target3 = (1,1,1,0,0)
target4 = (0,0,1,1,1)
found3 = 0
found4 = 0
for (i=1; i<=rows(kcm2); i++) {
	if (kcm2[i,.]==target3) found3=1
	if (kcm2[i,.]==target4) found4=1
}
end
mata: assert(found3 == 1)
mata: assert(found4 == 1)
mata: mata drop kcm2 target3 target4 found3 found4 i

* --- k(1) on the same bridge network: the whole 6-node graph already
* has connectivity 1 (it is, after all, connected), so it qualifies
* immediately as a single k-component with no cutting needed at all -
* exactly what nwcomponents would independently report as "one
* component", cross-checked directly against nwcomponents' own count.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwkcomponents net1, k(1)
assert _rc == 0
assert r(kcomponents) == 1
count if _kcompnum == 6
assert r(N) == 6
nwcomponents net1
assert r(components) == 1

* --- k(3) on the same network: nothing reaches connectivity 3
* anywhere (the densest substructures are triangles, connectivity 2) -
* a clean, empty result, not a crash.
nwkcomponents net1, k(3) replace
assert _rc == 0
assert r(kcomponents) == 0

* --- k(0) is rejected outright (exactly a connected component - use
* nwcomponents).
capture noisily nwkcomponents net1, k(0)
assert _rc != 0

* --- a genuinely disconnected network (two triangles with NO
* connection at all, not even a bridge) must split into its two
* components independently at k=1 - matching nwcomponents exactly,
* since neither this file's own recursive cutting logic nor
* nwcomponents' own reachability search should ever merge two
* genuinely unreachable pieces.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net3) undirected labs(A,B,C,D,E,F)
nwkcomponents net3, k(1)
assert _rc == 0
assert r(kcomponents) == 2

* --- K4 (complete graph on 4 nodes): connectivity n-1=3, so it
* qualifies as a single k-component up to k=3 but not k=4.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
nwkcomponents k4, k(3)
assert _rc == 0
assert r(kcomponents) == 1
count if _kcompnum == 4
assert r(N) == 4
nwkcomponents k4, k(4) replace
assert _rc == 0
assert r(kcomponents) == 0

* --- directed networks are symmetrized automatically (same reasoning
* nwclique/nwkplex/nwnclique already apply): A->B,B->A,A->C,B->C,C->B
* collapses to a full undirected triangle, one qualifying 2-component
* of size 3.
nwclear
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed labs(A,B,C)
nwkcomponents dnet, k(2)
assert _rc == 0
assert r(kcomponents) == 1

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwkcomponents net1, generate(customkc)
assert _rc == 0
capture confirm variable customkc, exact
assert _rc == 0
capture noisily nwkcomponents net1, generate(customkc)
assert _rc != 0
nwkcomponents net1, generate(customkc) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(neta) undirected labs(A,B,C,D,E,F)
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(netb) undirected labs(A,B,C,D,E,F)
nwkcomponents neta netb
assert _rc == 0
capture confirm variable _kcompnum1, exact
assert _rc == 0
capture confirm variable _kcompnum2, exact
assert _rc == 0


* --- alpha-audit regression: a single-node network used to crash with
* an uncontrolled Mata conformability error (build_edgelist_csr_dense()'s
* own nzidx-count bug: selectindex() on a genuinely empty match set -
* guaranteed for a 1-node network, no off-diagonal entry can exist -
* returns a 1x0 result, and rows() of that is 1, not 0, wrongly
* dispatching into the mod()/floor() edge-derivation branch with a
* 0-element operand). Fixed to use length() instead, which is robust to
* the row/column shape ambiguity of an empty selectindex() result.
* Reproduces for any k(), including the default k(2) and k(1).
nwclear
nwset, mat((0)) name(single1) undirected labs(A)
nwkcomponents single1
assert _rc == 0
assert r(kcomponents) == 0

nwkcomponents single1, k(1) replace
assert _rc == 0
assert r(kcomponents) == 0
