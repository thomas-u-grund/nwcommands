cscript

do unw_core.do

* nwnclique is a new command implementing maximal n-clique enumeration
* (Luce 1950) - a "distance-relaxed clique" where every member need
* only be within geodesic distance n() of every other member, rather
* than directly tied. n=1 is exactly an ordinary clique, so nwnclique
* requires n>=2 and points to nwclique for that case (which already
* implements it more cheaply, working directly on the true adjacency
* matrix rather than a computed distance matrix).
*
* New NWdef::calculate_nclique()/calculate_nclique_filtered() Mata
* methods build the "distance <= n" adjacency matrix (via
* calculate_distances(0, "brute"), the same distance routine
* nwgeodesic itself uses) and hand it straight to the *same*
* BronKerbosch() function nwclique.ado's own calculate_cliques() uses
* unmodified - an n-clique is simply an ordinary clique of the
* "distance <= n" graph, not a different search algorithm. Missing
* distances (the diagonal, and genuinely unreachable pairs) are
* correctly excluded with no special-casing needed, since a Mata
* comparison against a missing value is always false.

* --- 5-node path graph A-B-C-D-E, n=2: hand-derived directly from the
* distance matrix (d(A,B)=1, d(A,C)=2, d(A,D)=3, ...). The "distance
* <= 2" graph has edges A-B,A-C,B-C,B-D,C-D,C-E,D-E - its maximal
* cliques are exactly {A,B,C}, {B,C,D}, {C,D,E} (each hand-checked:
* e.g. {A,B,C} cannot extend to D since d(A,D)=3 > 2).
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(net1) undirected labs(A,B,C,D,E)
nwnclique net1
assert _rc == 0
assert r(ncliques) == 3
sort _nwnode
tempname lab num
mata: `lab' = st_sdata(., "_nwnode")
mata: `num' = st_data(., "_ncliquenum")
mata: assert(select(`num', `lab':=="A") == 3)
mata: assert(select(`num', `lab':=="B") == 3)
mata: assert(select(`num', `lab':=="C") == 3)
mata: assert(select(`num', `lab':=="D") == 3)
mata: assert(select(`num', `lab':=="E") == 3)
mata: mata drop `lab' `num'
mata:
ncm = st_matrix("r(nclique_matrix)")
target1 = (1,1,1,0,0)
target2 = (0,1,1,1,0)
target3 = (0,0,1,1,1)
found1 = 0
found2 = 0
found3 = 0
for (i=1; i<=rows(ncm); i++) {
	if (ncm[i,.]==target1) found1=1
	if (ncm[i,.]==target2) found2=1
	if (ncm[i,.]==target3) found3=1
}
end
mata: assert(found1 == 1)
mata: assert(found2 == 1)
mata: assert(found3 == 1)
mata: mata drop ncm target1 target2 target3 found1 found2 found3 i

* --- n=1 is rejected outright (exactly a clique - use nwclique).
capture noisily nwnclique net1, n(1)
assert _rc != 0

* --- K4 (complete graph on 4 nodes): at any n>=1 the whole graph is
* trivially one maximal n-clique, since all pairwise distances are
* already 1.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
nwnclique k4
assert _rc == 0
assert r(ncliques) == 1
count if _ncliquenum == 4
assert r(N) == 4

* --- directed networks are symmetrized automatically (same reasoning
* nwclique/nwkplex already apply - geodesic distance in an n-clique's
* sense has no directed generalization here): A->B,B->A,A->C,B->C,C->B
* collapses to a full undirected triangle, one maximal n-clique of
* size 3 at n=2.
nwclear
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed labs(A,B,C)
nwnclique dnet
assert _rc == 0
assert r(ncliques) == 1

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(net1) undirected labs(A,B,C,D,E)
nwnclique net1, generate(customnc)
assert _rc == 0
capture confirm variable customnc, exact
assert _rc == 0
capture noisily nwnclique net1, generate(customnc)
assert _rc != 0
nwnclique net1, generate(customnc) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(neta) undirected labs(A,B,C,D,E)
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(netb) undirected labs(A,B,C,D,E)
nwnclique neta netb
assert _rc == 0
capture confirm variable _ncliquenum1, exact
assert _rc == 0
capture confirm variable _ncliquenum2, exact
assert _rc == 0

* --- invalid minsize() and n() are rejected explicitly.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
capture noisily nwnclique k4, minsize(0)
assert _rc != 0
capture noisily nwnclique k4, n(0)
assert _rc != 0

* --- a larger n is genuinely less restrictive than a smaller one on
* the same network - a 6-node path's own maximal n-cliques must grow
* (or stay the same size), never shrink, as n increases. At n=5, the
* whole 6-node path (max possible distance is 5, A to F) qualifies as
* a single n-clique.
nwclear
nwset, mat((0,1,0,0,0,0\1,0,1,0,0,0\0,1,0,1,0,0\0,0,1,0,1,0\0,0,0,1,0,1\0,0,0,0,1,0)) name(path6) undirected labs(A,B,C,D,E,F)
nwnclique path6, n(5) minsize(6)
assert _rc == 0
assert r(ncliques) == 1
count if _ncliquenum == 6
assert r(N) == 6

* missing_test finding, cohesion_subgroups group: silent was never
* exercised.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
nwnclique tri, silent
assert _rc == 0
assert r(ncliques) == 1
di "=== silent REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwnclique nonexistent
assert _rc == 482
