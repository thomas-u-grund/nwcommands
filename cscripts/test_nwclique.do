cscript

do unw_core.do

* nwclique is a new command (harmonisation unit 29), implementing maximal
* clique enumeration via the classical Bron-Kerbosch (1973) algorithm, a
* new NWdef::calculate_cliques() Mata method delegating to a standalone
* BronKerbosch() function (the same "instance method delegates to a
* standalone function" pattern already used throughout this session's
* other new algorithms). Closes the "Cliques/k-plexes (cohesive
* subgroups beyond k-core)" item flagged in docs/CERTIFICATION.md's
* Pending table (k-plexes themselves remain open - only exact cliques
* are implemented here).
*
* While building this, found that a bare mata:/end multi-line block does
* NOT nest correctly inside a running .ado program's own execution flow
* the way it does at file level after a program's own "end" - it
* silently truncates the *program's* own boundary detection instead of
* behaving as a scoped Mata call, confirmed directly (a first attempt
* crashed with a confusing "too few variables specified... while loading
* nwclique.ado", not an error pointing at the actual mismatched-nesting
* cause). Fixed by moving the multi-statement Mata logic into a small
* unw_core.do wrapper method (calculate_cliques_filtered()) instead, so
* nwclique.ado itself only ever needs single-line mata: calls, matching
* every other command in this package.

* --- two triangles sharing an edge (A-B-C and B-C-D), plus an isolated
* node E: has exactly two maximal cliques of size 3 - {A,B,C} and
* {B,C,D} - and one of size 1 ({E}), a textbook example whose clique
* structure is unambiguous and hand-derivable, not merely plausible.
* Default minsize(3) excludes the trivial isolate.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,1,0\1,1,0,1,0\0,1,1,0,0\0,0,0,0,0)) name(net1) undirected labs(A,B,C,D,E)
nwclique net1
assert _rc == 0
assert r(cliques) == 2
sort _nwnode
tempname lab num
mata: `lab' = st_sdata(., "_nwnode")
mata: `num' = st_data(., "_cliquenum")
mata: assert(select(`num', `lab':=="A") == 3)
mata: assert(select(`num', `lab':=="B") == 3)
mata: assert(select(`num', `lab':=="C") == 3)
mata: assert(select(`num', `lab':=="D") == 3)
mata: assert(missing(select(`num', `lab':=="E")))
mata: mata drop `lab' `num'
* both expected size-3 cliques appear as exact rows of r(clique_matrix)
* (order is not guaranteed, so check membership rather than position).
mata:
cm = st_matrix("r(clique_matrix)")
target1 = (1,1,1,0,0)
target2 = (0,1,1,1,0)
found1 = 0
found2 = 0
for (i=1; i<=rows(cm); i++) {
	if (cm[i,.]==target1) found1=1
	if (cm[i,.]==target2) found2=1
}
end
mata: assert(found1 == 1)
mata: assert(found2 == 1)
mata: mata drop cm target1 target2 found1 found2 i

* --- minsize(1) additionally includes the isolated node's own trivial
* singleton clique.
nwclique net1, minsize(1) generate(cliq2) replace
assert _rc == 0
assert r(cliques) == 3

* --- K4 (complete graph on 4 nodes): exactly one maximal clique,
* containing all 4 nodes - the unambiguous, maximally-connected case.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
nwclique k4
assert _rc == 0
assert r(cliques) == 1
count if _cliquenum == 4
assert r(N) == 4

* --- directed networks are symmetrized automatically (a clique's own
* definition - every pair mutually tied - has no directed
* generalization, the same reasoning nwcoreperiphery already applies):
* A->B, B->A, A->C, B->C, C->B collapses to a full undirected triangle,
* giving exactly one maximal clique of size 3.
nwclear
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed labs(A,B,C)
nwclique dnet
assert _rc == 0
assert r(cliques) == 1

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
nwclique k4, generate(customclq)
assert _rc == 0
capture confirm variable customclq, exact
assert _rc == 0
capture noisily nwclique k4, generate(customclq)
assert _rc != 0
nwclique k4, generate(customclq) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4a) undirected labs(A,B,C,D)
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4b) undirected labs(A,B,C,D)
nwclique k4a k4b
assert _rc == 0
capture confirm variable _cliquenum1, exact
assert _rc == 0
capture confirm variable _cliquenum2, exact
assert _rc == 0

* --- invalid minsize() is rejected explicitly.
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4) undirected labs(A,B,C,D)
capture noisily nwclique k4, minsize(0)
assert _rc != 0

* missing_test finding, cohesion_subgroups group: silent (suppresses
* display but not the underlying computation) was never exercised.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
nwclique tri, silent
assert _rc == 0
assert r(cliques) == 1
di "=== silent REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwclique nonexistent
assert _rc == 482
