cscript

do unw_core.do

* nwspectral is a new command implementing graph Laplacian spectral
* analysis (Stage 6's "spectral analysis" roadmap item), built on a new
* NWdef::calculate_laplacian() Mata method (L = D - W, always
* symmetrized) and Mata's own built-in symeigensystem() (already proven
* elsewhere in this package by nwevcent.ado).

* --- path graph 1-2-3-4 (undirected, unweighted): the Laplacian
* spectrum of a path graph P_n is known in closed form,
* 2-2*cos(k*pi/n) for k=0..n-1 - for n=4: 0, 2-sqrt(2), 2, 2+sqrt(2).
* Hand-computed and verified directly against a Mata probe before
* writing this test. Algebraic connectivity (2nd-smallest) = 2-sqrt(2).
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) undirected labs(A,B,C,D) name(path4)
nwspectral path4, bipartition
assert _rc == 0
assert r(components) == 1
assert reldif(r(algebraic_connectivity), 2 - sqrt(2)) < 1E-6
mata: ev = st_matrix("r(eigenvalues)")
mata: assert(abs(ev[1,1]) < 1E-6)
mata: assert(reldif(ev[1,2], 2 - sqrt(2)) < 1E-6)
mata: assert(reldif(ev[1,3], 2) < 1E-6)
mata: assert(reldif(ev[1,4], 2 + sqrt(2)) < 1E-6)
mata: mata drop ev

* the Fiedler vector's sign gives the classical, intuitively correct
* spectral bisection of a path: split it in the middle, {A,B} vs {C,D}.
assert _fiedlersign[1] == _fiedlersign[2]
assert _fiedlersign[3] == _fiedlersign[4]
assert _fiedlersign[1] != _fiedlersign[3]

* --- two disjoint triangles: the MULTIPLICITY of Laplacian eigenvalue
* 0 exactly equals the number of connected components (a classical,
* exact spectral-graph-theory identity, not an approximation) -
* cross-checked directly against nwcomponents' own independent
* reachability-based count. Algebraic connectivity is exactly 0 for
* any disconnected network.
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected labs(A,B,C,D,E,F) name(disc)
nwspectral disc, silent
assert _rc == 0
assert r(components) == 2
assert abs(r(algebraic_connectivity)) < 1E-8
qui nwcomponents disc
assert r(components) == 2

* --- K3 (complete graph on 3 nodes): known closed-form Laplacian
* spectrum for K_n is {0, n, n, ..., n} (0 once, n with multiplicity
* n-1) - algebraic connectivity is exactly n = 3.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) undirected name(k3)
nwspectral k3, silent
assert _rc == 0
assert reldif(r(algebraic_connectivity), 3) < 1E-6

* --- directed networks are symmetrized automatically (matching
* nwcommunity/nwkcomponents): a directed 3-cycle A->B->C->A
* symmetrizes to the same K3 above, giving the identical spectrum.
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed name(dnet)
nwspectral dnet, silent
assert _rc == 0
assert reldif(r(algebraic_connectivity), 3) < 1E-6

* --- generate()/replace: a custom name must be honored (both the
* Fiedler-vector variable and its bipartition-sign companion, which is
* named by appending "sign" to whatever generate() name was given -
* not always "_fiedlersign"), and a second call without replace must
* be rejected.
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) undirected name(path4b)
nwspectral path4b, generate(myfiedler) bipartition
assert _rc == 0
capture confirm variable myfiedler, exact
assert _rc == 0
capture confirm variable myfiedlersign, exact
assert _rc == 0
capture noisily nwspectral path4b, generate(myfiedler)
assert _rc != 0
nwspectral path4b, generate(myfiedler) replace
assert _rc == 0
capture noisily nwspectral path4b, generate(myfiedler) bipartition
assert _rc != 0
nwspectral path4b, generate(myfiedler) bipartition replace
assert _rc == 0

* --- measure(binary|valued): a weighted network's own valued Laplacian
* differs from its binary (dichotomized) one - checked by comparing
* algebraic connectivity across both on the same weighted network,
* which must NOT coincide in general (confirmed here on a concrete
* unequal-weight example, not assumed). measure(binary) on this network
* dichotomizes to the identical structure as the plain unweighted path4
* above, so its own algebraic connectivity must exactly match that
* already-hand-verified value (2-sqrt(2)).
nwclear
nwset, mat((0,5,0,0\5,0,1,0\0,1,0,1\0,0,1,0)) undirected name(wpath)
nwspectral wpath, measure(valued) generate(fvalued) silent
local algconn_valued = r(algebraic_connectivity)
nwspectral wpath, measure(binary) generate(fbinary) silent
local algconn_binary = r(algebraic_connectivity)
assert reldif(`algconn_binary', 2 - sqrt(2)) < 1E-6
assert reldif(`algconn_valued', `algconn_binary') > 1E-6
