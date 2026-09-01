cscript

do unw_core.do

* nw2degree is a new command (harmonisation unit 24, Part XVIII special
* priority: genuine two-mode/bipartite analysis - closing the "Two-mode
* centrality... E" gap in docs/FEATURE_AUDIT.md area N). Implements
* Borgatti & Everett (1997)'s two-mode degree centrality normalization
* via a new NWdef::calculate_2mode_degree() Mata method, using the
* already-existing get_modes() accessor (a string rowvector of "1"/"2"
* per node, already relied on by nw2project.ado for the same purpose) to
* find each mode's members, rather than assuming a fixed node-index
* range for each mode - confirmed empirically while building this that a
* bipartite network's mode-1/mode-2 index ranges are an internal storage
* detail (get_2mode_edge() in nwset.ado places the *columns* of the
* original bipartite input matrix first, then the *rows* - the opposite
* of what a naive rows-then-columns reading of nwset's own bipartite
* input would suggest), not something a caller should hardcode.
*
* Node-value lookups below use _nwnode (the node label) rather than a
* fixed Stata observation number, following the same discipline already
* established for nwdegree's own netlist certification earlier this
* session: nw_datasync's own documented row-ordering does not
* necessarily match raw Mata node index order. Tolerances use 1e-6, not
* a tighter value - the generated variable is an ordinary (float-
* precision) Stata variable, matching the plain "gen x = ." convention
* nwcommunity/nwconcor/nwcoreperiphery's own newly-built commands already
* use in this session (fine for integer-valued outputs there; the first
* fractional-valued one surfaces float rounding at tighter tolerances,
* confirmed directly while building this test).

* --- hand-computable bipartite network: 3 actors (A,B,C), 2 events
* (E1,E2). A ties to both events; B ties only to E1; C ties only to E2.
* Two-mode degree = raw degree / size of the OTHER mode: E1 and E2 each
* tie to 2 of 3 actors -> 2/3; A ties to both of 2 events -> 1; B and C
* each tie to 1 of 2 events -> 0.5.
nwclear
mata: bip = (1,1 \ 1,0 \ 0,1)
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(net1) labs(E1,E2,A,B,C)
nw2degree net1
assert _rc == 0
sort _nwnode
tempname lab val
mata: `lab' = st_sdata(., "_nwnode")
mata: `val' = st_data(., "_2degree")
mata: assert(reldif(select(`val', `lab':=="A"), 1) < 1e-6)
mata: assert(reldif(select(`val', `lab':=="B"), 0.5) < 1e-6)
mata: assert(reldif(select(`val', `lab':=="C"), 0.5) < 1e-6)
mata: assert(reldif(select(`val', `lab':=="E1"), 2/3) < 1e-6)
mata: assert(reldif(select(`val', `lab':=="E2"), 2/3) < 1e-6)
mata: mata drop `lab' `val'

* --- a one-mode network must be rejected explicitly, not silently
* misinterpreted as two-mode.
nwclear
nwset, mat((0,1\1,0)) name(onemode) undirected labs(A,B)
capture noisily nw2degree onemode
assert _rc != 0

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(net1) labs(E1,E2,A,B,C)
nw2degree net1, generate(customdeg)
assert _rc == 0
capture confirm variable customdeg, exact
assert _rc == 0
capture noisily nw2degree net1, generate(customdeg)
assert _rc != 0
nw2degree net1, generate(customdeg) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed output variable.
nwclear
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(net1) labs(E1,E2,A,B,C)
nwset, mat(bip) bipartite name(net2) labs(E1,E2,A,B,C)
nw2degree net1 net2
assert _rc == 0
capture confirm variable _2degree1, exact
assert _rc == 0
capture confirm variable _2degree2, exact
assert _rc == 0

* --- a mode-1-vs-mode-2-imbalanced network (4 actors, 2 events) to
* confirm the normalization uses each node's *own* other-mode size
* correctly, not a single shared denominator - an event tied to all 4
* actors scores exactly 1 (the maximum), while an actor tied to only 1
* of 2 events scores exactly 0.5.
nwclear
mata: bip2 = (1,0 \ 1,1 \ 1,0 \ 1,1)
mata: st_matrix("bip2", bip2)
nwset, mat(bip2) bipartite name(net3) labs(E1,E2,P,Q,R,S)
nw2degree net3
assert _rc == 0
sort _nwnode
tempname lab2 val2
mata: `lab2' = st_sdata(., "_nwnode")
mata: `val2' = st_data(., "_2degree")
mata: assert(reldif(select(`val2', `lab2':=="E1"), 1) < 1e-6)
mata: assert(reldif(select(`val2', `lab2':=="P"), 0.5) < 1e-6)
mata: mata drop `lab2' `val2'

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nw2degree nonexistent
assert _rc == 482
