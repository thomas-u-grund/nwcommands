cscript
nwclear
do unw_core.do

* nwcommunity (Louvain): native kernel (code 24) against the Mata routine, and the second and later levels merge.
set graphics off
set more off

mata: st_numscalar("ver", nwg_comb_version())
local native = (scalar(ver) >= 4)
if !`native' di "note: the plugin of this platform has no Louvain kernel (code 24) yet; native-versus-Mata comparison skipped"

mata:
void t_louvain_native(real scalar on)
{
    external real scalar nwg_comb_state
    nwg_comb_state = (on ? . : 0)
}
end

local ncmp 0
forvalues s = 1/40 {
    clear
    nwclear
    set seed `s'
    local n = 10 + floor(runiform()*120)
    quietly set obs `=`n'*4'
    quietly gen long from = ceil(runiform()*`n')
    quietly gen long to = ceil(runiform()*`n')
    quietly drop if from == to
    quietly duplicates drop from to, force
    quietly gen double val = ceil(runiform()*5)
    local kind = mod(`s', 4)
    if `kind' == 0 quietly nwfromedge from to, name(g) undirected
    if `kind' == 1 quietly nwfromedge from to val, name(g) undirected
    if `kind' == 2 quietly nwfromedge from to, name(g)
    if `kind' == 3 quietly nwfromedge from to val, name(g)
    local meas = cond(inlist(`kind', 1, 3), "valued", "binary")
    local sy = cond(`kind' >= 2, "symmetrize", "")
    local res = 1 + (mod(`s', 3) == 0) * .5
    mata: t_louvain_native(0)
    quietly nwcommunity g, generate(c_mata) measure(`meas') resolution(`res') `sy' silent
    local q1 = r(modularity)
    local k1 = r(communities)
    if `native' {
        mata: t_louvain_native(1)
        quietly nwcommunity g, generate(c_nat) measure(`meas') resolution(`res') `sy' silent
        assert c_mata == c_nat
        assert abs(r(modularity) - `q1') < 1e-12
        assert r(communities) == `k1'
        local ++ncmp
    }
    * Louvain must find structure: modularity above the singleton partition's (negative) value
    assert `q1' > 0
    mata: t_louvain_native(1)
    nwclear
}
di "=== nwcommunity: `ncmp' random networks (binary/valued, directed/undirected, resolution 1 and 1.5), native equals Mata ==="

* a planted partition of 6 groups of 40 nodes is recovered, which needs the aggregation levels
clear
nwclear
set seed 5
set obs 240
gen long id = _n
gen byte grp = ceil(id/40)
tempfile nodes
save `nodes'
clear
set obs 40000
gen long from = ceil(runiform()*240)
gen long to = ceil(runiform()*240)
quietly drop if from == to
gen byte gf = ceil(from/40)
gen byte gt = ceil(to/40)
quietly keep if (gf == gt & runiform() < .9) | (gf != gt & runiform() < .02)
quietly duplicates drop from to, force
quietly nwfromedge from to, name(p) undirected
quietly nwcommunity p, generate(cm) silent
display "planted partition: " r(communities) " communities, Q = " r(modularity)
assert r(modularity) > .5
assert r(communities) <= 8

* the modularity of the nwmodularity command: sparse sum equals the dense one
mata: st_numscalar("dummy", 1)
quietly nwmodularity p, group(cm) silent
local qd = r(modularity)
mata: st_numscalar("nn", nw.nws.pdefs[nw.nws.get_index_of("p")]->get_nodes())
mata: pp = nw.nws.pdefs[nw.nws.get_index_of("p")]
mata: st_numscalar("qs", nw_modularity_pairs(240, nwg_symweights(240, pp->edgelist(), 1), st_data((1,240), "cm"), 1))
assert abs(scalar(qs) - `qd') < 1e-10
display "=== sparse modularity equals the dense one ==="
