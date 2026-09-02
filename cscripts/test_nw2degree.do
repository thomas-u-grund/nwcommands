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

* --- weighted (alpha()) two-mode degree/strength (2026-09-02 addition,
* closing the "Weighted: not used" gap docs/NETWORK_TYPE_MATRIX.md
* self-flagged for this command): Opsahl et al. (2010)'s generalized
* degree k*(s/k)^alpha, same convention nwdegree's own alpha() already
* uses for one-mode degree, applied to each node's two-mode tie set and
* normalized by the OTHER mode's size exactly like the unweighted
* formula above. Hand-computable valued bipartite network: mode-1 A/B,
* mode-2 X/Y/Z (n1=2, n2=3); A-X weight 2, A-Y weight 4, B-Z weight 6.
*   A: k=2, s=6 -> alpha=0: (2*1)/3=.6667 (must match the plain
*      unweighted formula exactly); alpha=1: (2*3)/3=2 (pure strength,
*      normalized); alpha=.5: (2*sqrt(3))/3=1.1547005
*   B: k=1, s=6 -> alpha=0: 1/3=.3333; alpha=1: 6/3=2
*   X: k=1, s=2 -> alpha=0: 1/2=.5;    alpha=1: 2/2=1
*   Y: k=1, s=4 -> alpha=0: 1/2=.5;    alpha=1: 4/2=2
*   Z: k=1, s=6 -> alpha=0: 1/2=.5;    alpha=1: 6/2=3
nwclear
clear
input str10 mode1 str10 mode2 value
"A" "X" 2
"A" "Y" 4
"B" "Z" 6
end
nwset mode1 mode2 value, twomode name(wbip)
nw2degree wbip
assert _rc == 0
sort _nwnode
tempname wlab wval
mata: `wlab' = st_sdata(., "_nwnode")
mata: `wval' = st_data(., "_2degree")
mata: assert(reldif(select(`wval', `wlab':=="A"), 2/3) < 1e-6)
mata: assert(reldif(select(`wval', `wlab':=="B"), 1/3) < 1e-6)
mata: assert(reldif(select(`wval', `wlab':=="X"), .5) < 1e-6)
mata: assert(reldif(select(`wval', `wlab':=="Y"), .5) < 1e-6)
mata: assert(reldif(select(`wval', `wlab':=="Z"), .5) < 1e-6)
mata: mata drop `wlab' `wval'
di "=== alpha(0) reproduces the plain unweighted formula exactly REGRESSION VERIFIED ==="

nw2degree wbip, generate(strength1) alpha(1) replace
assert _rc == 0
sort _nwnode
tempname slab sval
mata: `slab' = st_sdata(., "_nwnode")
mata: `sval' = st_data(., "strength1")
mata: assert(reldif(select(`sval', `slab':=="A"), 2) < 1e-6)
mata: assert(reldif(select(`sval', `slab':=="B"), 2) < 1e-6)
mata: assert(reldif(select(`sval', `slab':=="X"), 1) < 1e-6)
mata: assert(reldif(select(`sval', `slab':=="Y"), 2) < 1e-6)
mata: assert(reldif(select(`sval', `slab':=="Z"), 3) < 1e-6)
mata: mata drop `slab' `sval'
di "=== alpha(1) pure normalized strength REGRESSION VERIFIED ==="

nw2degree wbip, generate(halfalpha) alpha(.5) replace
assert _rc == 0
sort _nwnode
tempname hlab hval
mata: `hlab' = st_sdata(., "_nwnode")
mata: `hval' = st_data(., "halfalpha")
mata: assert(reldif(select(`hval', `hlab':=="A"), (2*sqrt(3))/3) < 1e-6)
mata: mata drop `hlab' `hval'
di "=== alpha(.5) fractional blend REGRESSION VERIFIED ==="

* --- nwdegree's own two-mode redirect forwards alpha() through to
* nw2degree too now (it used to be listed as having "no bipartite
* equivalent" and silently dropped, with a note saying so - that note
* is only correct for a genuinely inapplicable option, and alpha() no
* longer is one).
nwclear
clear
input str10 mode1 str10 mode2 value
"A" "X" 2
"A" "Y" 4
"B" "Z" 6
end
nwset mode1 mode2 value, twomode name(wbip2)
capture noisily nwdegree wbip2, alpha(1) generate(viaredirect)
assert _rc == 0
sort _nwnode
tempname rlab rval
mata: `rlab' = st_sdata(., "_nwnode")
mata: `rval' = st_data(., "viaredirect")
mata: assert(reldif(select(`rval', `rlab':=="A"), 2) < 1e-6)
mata: mata drop `rlab' `rval'
di "=== nwdegree's own two-mode redirect now forwards alpha() REGRESSION VERIFIED ==="
