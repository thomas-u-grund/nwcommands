cscript

do unw_core.do

* nwego is a new command (harmonisation unit 25), implementing ego-network
* size and density via a new NWdef::calculate_egostats() Mata method. This
* was flagged in docs/FEATURE_AUDIT.md area M ("Ego-network size/density...
* all E") as blocked on "no general induced-subgraph-extraction primitive" -
* but a genuine, reusable subgraph-extraction primitive turns out not to be
* needed at all for these two specific scalar summary measures: both are
* computable directly from the existing neighbors()/neighbors_in()/
* has_edge() sparse accessors (the same primitives calculate_components()/
* calculate_kcore()/calculate_brokerage() already use) without ever
* materializing a persistent subgraph network object. The broader
* induced-subgraph *extraction* primitive (for commands that would need an
* actual reusable ego-network object, not just scalar summaries of it)
* remains a real, separate, larger gap - not closed by this unit.

* --- hand-computable network: node A tied to B, C, D; B and C also tied
* to each other (but not D); a disjoint E-F pair elsewhere. A's ego size
* = 3 (B,C,D); among A's alters, only B-C is tied, so density = 1/3. B's
* ego size = 2 (A,C); among B's alters, A-C is tied, so density = 1 (the
* only possible pair is present). Same for C by symmetry. D and E/F each
* have exactly 1 alter - density is undefined (missing), not 0 or 1.
nwclear
mata:
M = J(6,6,0)
M[1,2] = 1; M[2,1] = 1
M[1,3] = 1; M[3,1] = 1
M[1,4] = 1; M[4,1] = 1
M[2,3] = 1; M[3,2] = 1
M[5,6] = 1; M[6,5] = 1
st_matrix("M", M)
end
nwset, mat(M) name(net1) undirected labs(A,B,C,D,E,F)
nwego net1, sizevar(_egosize) densvar(_egodensity)
assert _rc == 0
sort _nwnode
tempname lab sz dens
mata: `lab' = st_sdata(., "_nwnode")
mata: `sz' = st_data(., "_egosize")
mata: `dens' = st_data(., "_egodensity")
mata: assert(select(`sz', `lab':=="A") == 3)
mata: assert(reldif(select(`dens', `lab':=="A"), 1/3) < 1e-6)
mata: assert(select(`sz', `lab':=="B") == 2)
mata: assert(reldif(select(`dens', `lab':=="B"), 1) < 1e-6)
mata: assert(select(`sz', `lab':=="C") == 2)
mata: assert(reldif(select(`dens', `lab':=="C"), 1) < 1e-6)
mata: assert(select(`sz', `lab':=="D") == 1)
mata: assert(missing(select(`dens', `lab':=="D")))
mata: assert(select(`sz', `lab':=="E") == 1)
mata: assert(missing(select(`dens', `lab':=="E")))
mata: mata drop `lab' `sz' `dens'

* --- directed network: A -> B, C -> A, B -> C. A's alters (union of
* in/out) = {B,C}, size 2. Among alters, ordered pairs: B->C exists,
* C->B does not - actual=1, possible=2 (ordered), density=0.5.
nwclear
mata:
D = J(4,4,0)
D[1,2] = 1
D[3,1] = 1
D[2,3] = 1
st_matrix("D", D)
end
nwset, mat(D) name(dnet) directed labs(A,B,C,E)
nwego dnet, sizevar(_egosize) densvar(_egodensity)
assert _rc == 0
sort _nwnode
tempname lab2 sz2 dens2
mata: `lab2' = st_sdata(., "_nwnode")
mata: `sz2' = st_data(., "_egosize")
mata: `dens2' = st_data(., "_egodensity")
mata: assert(select(`sz2', `lab2':=="A") == 2)
mata: assert(reldif(select(`dens2', `lab2':=="A"), 0.5) < 1e-6)
mata: mata drop `lab2' `sz2' `dens2'
* the isolated node E has zero alters - size 0, density missing, not a
* crash.
capture confirm variable _egosize, exact
assert _rc == 0
count if _nwnode == "E" & _egosize == 0
assert r(N) == 1
count if _nwnode == "E" & missing(_egodensity)
assert r(N) == 1

* --- sizevar()/densvar()/replace: custom names honored, and a second
* call without replace is rejected.
nwclear
mata: st_matrix("M", M)
nwset, mat(M) name(net1) undirected labs(A,B,C,D,E,F)
nwego net1, sizevar(mysize) densvar(mydens)
assert _rc == 0
capture confirm variable mysize, exact
assert _rc == 0
capture confirm variable mydens, exact
assert _rc == 0
capture noisily nwego net1, sizevar(mysize) densvar(mydens)
assert _rc != 0
nwego net1, sizevar(mysize) densvar(mydens) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed pair of output variables.
nwclear
mata: st_matrix("M", M)
nwset, mat(M) name(net1) undirected labs(A,B,C,D,E,F)
nwset, mat(M) name(net2) undirected labs(A,B,C,D,E,F)
nwego net1 net2, sizevar(_egosize) densvar(_egodensity)
assert _rc == 0
capture confirm variable _egosize1, exact
assert _rc == 0
capture confirm variable _egosize2, exact
assert _rc == 0
capture confirm variable _egodensity1, exact
assert _rc == 0
capture confirm variable _egodensity2, exact
assert _rc == 0

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwego nonexistent
assert _rc == 482
