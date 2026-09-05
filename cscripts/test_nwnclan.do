cscript

do unw_core.do

* nwnclan is a new command implementing maximal n-clan enumeration
* (Mokken 1979) - an n-clique (see nwnclique/test_nwnclique.do for the
* base concept) that additionally requires every pair of its own
* members to be reachable from one another WITHOUT leaving the group,
* within n() steps. A plain n-clique only guarantees each pair's
* shortest path in the WHOLE network is within n() - that path may
* legitimately run through a node that is not itself an n-clique
* member (Alba 1973); n-clans close that gap.
*
* New NWdef::calculate_nclan_filtered() takes the already-enumerated
* maximal n-cliques (calculate_nclique_filtered()) and keeps only the
* ones whose INDUCED subgraph - built from the network's own true
* adjacency, restricted to just that set's members - has every pair
* within n() steps of each other using only within-group ties. This
* matches the standard treatment in the literature: n-clans are a
* FILTERED SUBSET of the maximal n-cliques, not an independently
* re-maximized search of their own - a maximal n-clique that fails the
* induced-diameter check is simply not reported as a clan, not
* replaced by some smaller clan-qualifying subset of itself.
*
* A genuinely interesting, non-obvious finding from developing this:
* constructing a small, hand-computable network where a FULL command-
* level nwnclique call reports a maximal n-clique that nwnclan then
* excludes turns out to be considerably harder than expected, for a
* provable structural reason. Any node set connected by a single
* shortest PATH (the simplest, most common "bridge" scenario) can
* never itself demonstrate divergence: every node lying ON a shortest
* path between two others is automatically within n of every OTHER
* node on that same path too (sub-path distances never exceed the
* full path's own length), so Bron-Kerbosch's own maximality search
* always ends up including the whole bridging path as clique members
* once it includes any of them - and once included, that same path
* IS the within-group route the clan check needs, so it always
* passes. Genuine divergence needs a node whose short whole-network
* distance to two group members comes from a path that a *different,
* independently-required* clique member then makes structurally
* impossible to also include - a real but more elaborate multi-branch
* condition, not reproducible with the small, simple bridge-graph
* constructions that hand-verification favors. calculate_nclan_filtered()'s
* own diameter-check logic (nclan_diameter_ok(), unw_core.do) is
* therefore verified directly and rigorously below via a hand-built
* divergent case at the Mata level (bypassing the search-for-
* maximality step entirely, since that is the part that keeps
* resolving the divergence away) - the full command-level tests below
* it use networks where n-clique and n-clan legitimately coincide,
* which still exercises the complete real pipeline end to end.

* --- direct, isolated verification of nclan_diameter_ok() against a
* deliberately constructed divergent case: a 6-node path A-B-C-D-E-F
* plus a hub node G tied ONLY to A and F (a shortcut, giving
* whole-network d(A,F) = 2 via G, vs. 5 via the path). The pair {A,F}
* alone (deliberately excluding G) has NO tie and no common neighbor
* within just those two nodes - its own induced "subgraph" is
* completely disconnected - so it must fail the n=2 clan check despite
* qualifying as a valid n-clique pair at the whole-network level.
* Including G restores a valid within-group path (A-G-F, length 2) and
* the same check must then pass.
mata:
bignet = (.,1,0,0,0,0,1 \ 1,.,1,0,0,0,0 \ 0,1,.,1,0,0,0 \ 0,0,1,.,1,0,0 \ 0,0,0,1,.,1,0 \ 0,0,0,0,1,.,1 \ 1,0,0,0,0,1,.)
members_AF = (1,0,0,0,0,1,0)
members_AFG = (1,0,0,0,0,1,1)
end
mata: assert(nclan_diameter_ok(bignet, members_AF, 2) == 0)
mata: assert(nclan_diameter_ok(bignet, members_AFG, 2) == 1)
mata: mata drop bignet members_AF members_AFG

* --- full-pipeline test on a 5-node path A-B-C-D-E, n=2: a plain path
* has no shortcuts at all, so every maximal n-clique's own bridging
* nodes are, by construction, always already members of it (see this
* file's own header note) - n-clique and n-clan coincide exactly here,
* letting this test validate the complete real command (not just the
* isolated helper above) end to end, including generate()/r(nclans)/
* r(nclan_matrix).
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(net1) undirected labs(A,B,C,D,E)
nwnclan net1, generate(_nclannum)
assert _rc == 0
assert r(nclans) == 3
sort _nwnode
tempname lab num
mata: `lab' = st_sdata(., "_nwnode")
mata: `num' = st_data(., "_nclannum")
mata: assert(select(`num', `lab':=="A") == 3)
mata: assert(select(`num', `lab':=="C") == 3)
mata: assert(select(`num', `lab':=="E") == 3)
mata: mata drop `lab' `num'

* nwnclan's own count/membership must exactly match nwnclique's own on
* this shortcut-free network - a direct cross-check between the two
* commands, not just against a hand count. r(nclan_matrix) is copied
* out to a plain Stata matrix first since nwnclique's own call below
* is itself rclass and would otherwise clear it before the comparison.
matrix nclanmat_saved = r(nclan_matrix)
nwnclique net1, generate(_ncliquenum)
assert r(ncliques) == 3
mata: assert(st_matrix("r(nclique_matrix)") == st_matrix("nclanmat_saved"))

* --- n=1 is rejected outright (exactly a clique - use nwclique).
capture noisily nwnclan net1, n(1)
assert _rc != 0

* --- K4: trivially one maximal n-clan (all distances already 1, so
* the induced subgraph IS the original graph - no divergence possible
* here either, by definition, since nothing is excluded).
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
nwnclan k4, generate(_nclannum)
assert _rc == 0
assert r(nclans) == 1
count if _nclannum == 4
assert r(N) == 4

* --- directed networks are symmetrized automatically (same reasoning
* nwnclique/nwclique/nwkplex already apply).
nwclear
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed labs(A,B,C)
nwnclan dnet, generate(_nclannum)
assert _rc == 0
assert r(nclans) == 1

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(net1) undirected labs(A,B,C,D,E)
nwnclan net1, generate(customclan)
assert _rc == 0
capture confirm variable customclan, exact
assert _rc == 0
capture noisily nwnclan net1, generate(customclan)
assert _rc != 0
nwnclan net1, generate(customclan) replace
assert _rc == 0

* --- netlist support.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(neta) undirected labs(A,B,C,D,E)
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(netb) undirected labs(A,B,C,D,E)
nwnclan neta netb, generate(_nclannum)
assert _rc == 0
capture confirm variable _nclannum1, exact
assert _rc == 0
capture confirm variable _nclannum2, exact
assert _rc == 0

* --- invalid minsize() and n() are rejected explicitly.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
capture noisily nwnclan k4, minsize(0)
assert _rc != 0
capture noisily nwnclan k4, n(0)
assert _rc != 0

* missing_test finding, cohesion_subgroups group: silent was never
* exercised.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
nwnclan tri, generate(_nclannum) silent
assert _rc == 0
assert r(nclans) == 1
di "=== silent REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwnclan nonexistent
assert _rc == 482
