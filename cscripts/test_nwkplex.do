cscript

do unw_core.do

* nwkplex is a new command, implementing maximal k-plex enumeration - a
* "relaxed clique" where every member may miss up to k()-1 ties to the
* other members (k=1 reduces to an ordinary clique, so nwkplex requires
* k>=2 and points to nwclique for that case, which already has a
* cheaper, purpose-built algorithm). Closes the k-plex half of the
* "Cliques/k-plexes (cohesive subgroups beyond k-core)" item in
* docs/CERTIFICATION.md's Pending table (cliques themselves were done
* in harmonisation unit 29, nwclique).
*
* New NWdef::calculate_kplex()/calculate_kplex_filtered() Mata methods
* delegate to a standalone KPlex() function, the same
* Bron-Kerbosch-style R/P/X backtracking nwclique's own BronKerbosch()
* uses, generalized to the k-plex membership rule (a candidate's
* addability now requires checking the whole induced submatrix of the
* candidate set via is_valid_kplex(), not just a simple neighbor-row
* intersection, since a k-plex candidate's validity genuinely depends
* on the exact current membership, not just direct adjacency to it).
* Correctness of reusing the clique algorithm's own R/P/X maximality
* bookkeeping for this more general rule rests on k-plexes being
* downward hereditary (any subset of a valid k-plex is itself a valid
* k-plex under the same k) - proved directly in KPlex()'s own header
* comment in unw_core.do, not just assumed.

* --- two disjoint triangles (A,B,C) and (D,E,F), no ties between them:
* for k=2, each triangle is itself a valid, maximal 2-plex (every
* member already misses 0 ties, well within the k-1=1 budget), and no
* cross-triangle set can be added to or survive as anything larger,
* since any node from one triangle is missing ALL of the other
* triangle's nodes. Hand-derivable, unambiguous: exactly the two
* triangles, size 3 each - a textbook maximal-k-plex example.
* (Without minsize() filtering, every cross-triangle *pair* of nodes -
* 9 of them - is ALSO technically a valid, maximal 2-plex, since any 2
* nodes trivially satisfy "miss at most k-1=1 of the 1 possible tie"
* regardless of whether they're actually tied - confirmed directly
* while building this: an unfiltered calculate_kplex(2) call on this
* network returns 11 rows, not 2. This is exactly why nwkplex's own
* default minsize() is k+1, not a fixed constant like nwclique's own
* minsize(3) - at minsize()<=k, every same-or-smaller-than-k node set
* is automatically, uninformatively "valid".)
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(net1) undirected labs(A,B,C,D,E,F)
nwkplex net1
assert _rc == 0
assert r(kplexes) == 2
sort _nwnode
tempname lab num
mata: `lab' = st_sdata(., "_nwnode")
mata: `num' = st_data(., "_kplexnum")
mata: assert(select(`num', `lab':=="A") == 3)
mata: assert(select(`num', `lab':=="B") == 3)
mata: assert(select(`num', `lab':=="C") == 3)
mata: assert(select(`num', `lab':=="D") == 3)
mata: assert(select(`num', `lab':=="E") == 3)
mata: assert(select(`num', `lab':=="F") == 3)
mata: mata drop `lab' `num'
* the two triangles must appear as exact rows of r(kplex_matrix) (order
* not guaranteed, so check membership rather than position).
mata:
km = st_matrix("r(kplex_matrix)")
target1 = (1,1,1,0,0,0)
target2 = (0,0,0,1,1,1)
found1 = 0
found2 = 0
for (i=1; i<=rows(km); i++) {
	if (km[i,.]==target1) found1=1
	if (km[i,.]==target2) found2=1
}
end
mata: assert(found1 == 1)
mata: assert(found2 == 1)
mata: mata drop km target1 target2 found1 found2 i

* --- 5-node path graph A-B-C-D-E (a simple chain, no other ties): for
* k=2, hand-derived by checking every consecutive triple - {A,B,C}:
* A misses C (1 <= k-1=1, valid), B misses nothing, C misses A -
* valid, and cannot extend to {A,B,C,D} (A would then miss both C and
* D, 2 > 1). By the same logic {B,C,D} and {C,D,E} are each valid,
* maximal 2-plexes too - exactly 3 maximal 2-plexes total, each of
* size 3, overlapping at their shared endpoints (B/C in the first two,
* C/D in the last two).
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(path5) undirected labs(A,B,C,D,E)
nwkplex path5
assert _rc == 0
assert r(kplexes) == 3
mata: kmp = st_matrix("r(kplex_matrix)")
mata:
foundABC = 0
foundBCD = 0
foundCDE = 0
for (i=1; i<=rows(kmp); i++) {
	if (kmp[i,.]==(1,1,1,0,0)) foundABC=1
	if (kmp[i,.]==(0,1,1,1,0)) foundBCD=1
	if (kmp[i,.]==(0,0,1,1,1)) foundCDE=1
}
end
mata: assert(foundABC == 1)
mata: assert(foundBCD == 1)
mata: assert(foundCDE == 1)
mata: mata drop kmp foundABC foundBCD foundCDE i

* --- 4-node "near-complete" graph (all ties present except A-D): for
* k=2, A misses only D (1 <= 1) and D misses only A (1 <= 1); B and C
* miss nothing - so the WHOLE 4-node set already qualifies as one,
* single maximal 2-plex, hand-derivable directly from the missing-tie
* count (a case where the whole network is one large k-plex, unlike
* the two examples above which fragment into several smaller ones).
nwclear
nwset, mat((0,1,1,0\1,0,1,1\1,1,0,1\0,1,1,0)) name(net2) undirected labs(A,B,C,D)
nwkplex net2
assert _rc == 0
assert r(kplexes) == 1
count if _kplexnum == 4
assert r(N) == 4

* --- k=1 is rejected outright (a 1-plex is exactly a clique - use
* nwclique instead, which already implements that case more cheaply).
capture noisily nwkplex net2, k(1)
assert _rc != 0

* --- directed networks are symmetrized automatically (same reasoning
* nwclique/nwcoreperiphery already apply - a k-plex's own definition
* has no directed generalization): A->B,B->A,A->C,B->C,C->B collapses
* to a full undirected triangle; with k=2 and minsize(3), the whole
* triangle is one maximal 2-plex (trivially - every member already
* misses 0 ties).
nwclear
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed labs(A,B,C)
nwkplex dnet
assert _rc == 0
assert r(kplexes) == 1

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1,0\1,0,1,1\1,1,0,1\0,1,1,0)) name(net2) undirected labs(A,B,C,D)
nwkplex net2, generate(customkp)
assert _rc == 0
capture confirm variable customkp, exact
assert _rc == 0
capture noisily nwkplex net2, generate(customkp)
assert _rc != 0
nwkplex net2, generate(customkp) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
nwset, mat((0,1,1,0\1,0,1,1\1,1,0,1\0,1,1,0)) name(neta) undirected labs(A,B,C,D)
nwset, mat((0,1,1,0\1,0,1,1\1,1,0,1\0,1,1,0)) name(netb) undirected labs(A,B,C,D)
nwkplex neta netb
assert _rc == 0
capture confirm variable _kplexnum1, exact
assert _rc == 0
capture confirm variable _kplexnum2, exact
assert _rc == 0

* --- invalid minsize() and k() are rejected explicitly.
nwclear
nwset, mat((0,1,1,0\1,0,1,1\1,1,0,1\0,1,1,0)) name(net2) undirected labs(A,B,C,D)
capture noisily nwkplex net2, minsize(0)
assert _rc != 0
capture noisily nwkplex net2, k(0)
assert _rc != 0

* --- a larger k (k=3) is genuinely less restrictive than k=2 on the
* same network - the path graph's own maximal k-plexes must grow (or
* stay the same size), never shrink, as k increases, a basic
* consistency check on the k parameter's own direction of effect.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(path5) undirected labs(A,B,C,D,E)
nwkplex path5, k(3) minsize(4)
assert _rc == 0
assert r(kplexes) >= 1
mata: assert(max(rowsum(st_matrix("r(kplex_matrix)"))) >= 4)

* missing_test finding, cohesion_subgroups group: silent was never
* exercised.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
nwkplex tri, silent
assert _rc == 0
assert r(kplexes) == 1
di "=== silent REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwkplex nonexistent
assert _rc == 482
