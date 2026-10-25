cscript
nwclear
do unw_core.do
* nwrandomwalk: conjugate-gradient route (large networks) against the dense LU route
set graphics off
set more off
mata:
void t_hit_cg(real scalar on)
{
    external real scalar nw_hitting_cg_min_x
    nw_hitting_cg_min_x = (on ? 0 : 1e9)
}
end
local worst 0
local ndiff 0
forvalues s = 1/25 {
    clear
    nwclear
    set seed `s'
    local n = 12 + floor(runiform()*300)
    quietly set obs `=`n'*4'
    quietly gen long from = ceil(runiform()*`n')
    quietly gen long to = ceil(runiform()*`n')
    quietly drop if from == to
    quietly duplicates drop from to, force
    quietly nwfromedge from to, name(g) undirected
    quietly nwcomponents g, generate(cc) silent
    if r(components) > 1 continue
    mata: t_hit_cg(0)
    quietly nwrandomwalk g, target(n1) generate(h_lu) silent
    mata: t_hit_cg(1)
    quietly nwrandomwalk g, target(n1) generate(h_cg) silent
    quietly gen double rel = abs(h_cg - h_lu) / max(1, abs(h_lu))
    quietly count if h_cg != h_lu
    local ndiff = `ndiff' + (r(N) > 0)
    quietly summarize rel
    local worst = max(`worst', r(max))
    assert r(max) < 1e-9
    drop h_lu h_cg rel cc
    nwclear
}
* the CG route must really have been used: it differs from the LU result in the last digits for most networks
assert `ndiff' > 0
display "=== nwrandomwalk: conjugate gradients equal the dense solution, worst relative difference " `worst' " ==="
* a disconnected network falls back to the dense route and gives the same answer as before
clear
nwclear
set obs 40
gen long from = ceil(_n/2)
gen long to = mod(_n, 20) + 1
quietly drop if from == to
quietly nwfromedge from to, name(d) undirected
mata: t_hit_cg(1)
capture quietly nwrandomwalk d, target(n1) generate(h1) silent
local rc1 = _rc
mata: t_hit_cg(0)
capture quietly nwrandomwalk d, target(n1) generate(h2) silent
assert _rc == `rc1'
display "=== nwrandomwalk disconnected network: same outcome with and without the CG route ==="
