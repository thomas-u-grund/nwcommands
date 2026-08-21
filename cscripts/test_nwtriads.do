cscript

do unw_core.do

nwclear
nwset, mat((1,1,0\0,0,0\1,4,0)) name(mynet)
nwtriads
assert `r(_030T)' ==  1
assert `r(transitivity)' == 1

nwclear
nwset, mat((0,0,0\0,0,0\1,0,0)) name(mynet)
nwtriads
assert `r(_012)' ==  1
assert `r(transitivity)' == .

nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(mynet)
nwtriads
assert `r(_030C)' ==  1
assert `r(transitivity)' == 0


* --- undirected network: harmonisation-phase regression test. All 12
* asymmetric-dyad-dependent MAN categories (everything except
* _003/_102/_201/_300) must be exactly 0 for undirected data, since an
* undirected network has no asymmetric ties by construction - and the
* command should not silently proceed without saying so. This includes
* _210, which harmonisation unit 32 found was NOT reliably 0 here - not
* because of any actual Mata computation bug (calculate_triadcensus()
* itself was correct the whole time), but because nwtriads.ado's own
* r()-extraction read r(_201) and r(_210) from each other's positions
* in calculate_triadcensus()'s return vector, a simple swapped-index
* bug now fixed (see nwtriads.ado's own inline comment and
* docs/CERTIFICATION.md). This network is a triangle A-B-C with a
* pendant D attached to C: of the 4 possible triads, ABC is a closed
* triangle (3 edges, x_300), ABD has only the A-B edge (1 edge,
* x_102), and ACD/BCD each have 2 edges (A-C+C-D, B-C+C-D
* respectively, x_201) - hand-derived and cross-checked against the
* fixed command's own output below.
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(undirnet) undirected labs(A,B,C,D)
nwtriads undirnet
assert r(_012) == 0
assert r(_021D) == 0
assert r(_021U) == 0
assert r(_021C) == 0
assert r(_030T) == 0
assert r(_030C) == 0
assert r(_111D) == 0
assert r(_111U) == 0
assert r(_120D) == 0
assert r(_120U) == 0
assert r(_120C) == 0
assert r(_210) == 0
assert r(_102) == 1
assert r(_201) == 2
assert r(_300) == 1

* --- second, independent undirected known-answer case (the 5-cycle
* A-B-C-D-E-A has zero triangles by construction - girth 5 - so every
* one of its 10 possible triads has either exactly 1 or exactly 2
* edges, hand-derivable by listing all 10 triples directly): 5 triads
* have 1 edge (x_102), 5 have 2 edges (x_201), none are closed
* (x_300==0) or fully asymmetric-dependent (x_210==0) - this is the
* exact case that most clearly exposed the pre-fix swapped-index bug
* above, since a 5-cycle's x_210/x_201 values are neither both 0 nor
* accidentally equal, unlike some smaller networks.
nwclear
nwset, mat((0,1,0,0,1\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\1,0,0,1,0)) name(cyc5) undirected labs(A,B,C,D,E)
nwtriads cyc5
assert r(_102) == 5
assert r(_201) == 5
assert r(_210) == 0
assert r(_300) == 0







