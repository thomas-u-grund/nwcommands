cscript
nwclear

do unw_core.do

* Fixes of the 10,000-node scaling audit:
*  - clean_matrix_2mode() (nw2fromedge, nw2set) blanks the same-mode cells in place instead of building the
*    n x n string matrix J(n,1,modes) :== J(1,n,modes') (about 10 GB at 15,000 nodes)
*  - nwcomponents / nwcommunity: more than 1,000 components or communities no longer stop at Stata's tabulate limit
*  - nwexpand, network(): the node names of a network above about 900 nodes are not damaged
*  - nwspectral, nwconcor, nwhierarchy: refused above 6,000 nodes unless force is given

set graphics off
set more off

* ---------------------------------------------------------------- two-mode: same matrix as the string definition
forvalues s = 1/30 {
    clear
    nwclear
    set seed `s'
    local n = 6 + floor(runiform()*40)
    local m = 3 + floor(runiform()*20)
    quietly set obs `=`n'*3'
    quietly gen long a = ceil(runiform()*`n')
    quietly gen long b = ceil(runiform()*`m')
    quietly duplicates drop a b, force
    quietly nw2fromedge a b, name(t)
    _nwsyntax t
    mata: p = __nw.nws.pdefs[__nw.nws.get_index_of("t")]
    mata: M = *p->get_matrix()
    // reference: the old definition blanked every cell whose two nodes have the same mode (diagonal included)
    mata: md = vec(p->get_modes()); z = ((J(rows(md), 1, md') :== J(1, rows(md), md)) :== 1)
    mata: st_numscalar("bad", sum((M :== .) :!= z))
    assert scalar(bad) == 0
    nwclear
}
display "=== clean_matrix_2mode: 30 random two-mode networks have missing cells exactly where the modes agree ==="

* ---------------------------------------------------------------- 2,000 + 1,000 node two-mode network: builds, memory small
clear
nwclear
set seed 7
quietly set obs 20000
quietly gen long a = ceil(_n/10)
quietly gen long b = ceil(runiform()*1000)
quietly duplicates drop a b, force
timer clear 1
timer on 1
quietly nw2fromedge a b, name(big)
timer off 1
quietly timer list 1
assert r(t1) < 30
mata: st_numscalar("nn", __nw.nws.pdefs[__nw.nws.get_index_of("big")]->get_nodes())
assert scalar(nn) == 3000
display "=== 3,000-node two-mode network built ==="

* ---------------------------------------------------------------- more than 1,000 components / communities
clear
nwclear
quietly set obs 1201
* 1,200 pairs of nodes (1,200 components) and one extra tie that joins two pairs
quietly gen long from = 2 * _n - 1
quietly gen long to = 2 * _n
quietly replace from = 2 in L
quietly replace to = 3 in L
quietly nwfromedge from to, name(sp) undirected
nwcomponents sp, generate(cc)
local nc = r(components)
assert `nc' > 1000
matrix S = r(comp_sizeid)
assert rowsof(S) == `nc'
local nodes_total = 0
forvalues i = 1/`nc' {
    local nodes_total = `nodes_total' + S[`i', 1]
}
mata: st_numscalar("nn", __nw.nws.pdefs[__nw.nws.get_index_of("sp")]->get_nodes())
assert `nodes_total' == scalar(nn)
assert S[1, 1] >= S[`nc', 1]
local rn : rownames S
assert word("`rn'", `nc') == "comp`nc'"
nwcomponents sp, generate(lg) lgc silent
quietly count if lg == 1
assert r(N) == S[1, 1]
nwcommunity sp, generate(cm)
assert r(communities) > 1000
display "=== `nc' components and `=r(communities)' communities: the commands run to the end ==="

* ---------------------------------------------------------------- nwexpand with a network of 1,500 nodes keeps the node names
clear
nwclear
set seed 11
quietly set obs 12000
quietly gen long from = ceil(_n/8)
quietly gen long to = ceil(runiform()*1500)
quietly drop if from == to
quietly duplicates drop from to, force
quietly nwfromedge from to, name(big)
quietly gen double at = ceil(runiform()*3)
quietly nwexpand at, network(big) name(ex) mode(same)
mata: pe = __nw.nws.pdefs[__nw.nws.get_index_of("ex")]
mata: pb = __nw.nws.pdefs[__nw.nws.get_index_of("big")]
mata: st_numscalar("same", all(vec(pe->get_nodenames()) :== vec(pb->get_nodenames())))
assert scalar(same) == 1
display "=== nwexpand: 1,500 node names intact ==="

* ---------------------------------------------------------------- guards of the cubic commands
clear
nwclear
quietly nwring 6001, k(2) name(r6)
capture nwspectral r6, generate(f) silent
assert _rc == 484
capture nwconcor r6, generate(f) silent
assert _rc == 484
capture nwhierarchy r6
assert _rc == 484
display "=== nwspectral, nwconcor, nwhierarchy refuse 6,001 nodes (r(484)) ==="
