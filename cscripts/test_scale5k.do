cscript
nwclear

do unw_core.do

* Fixes of the 5,000-node scaling audit:
*  - nwbalance, nwmatching: native kernels (algorithm codes 22 and 23), equal to the Mata code
*  - nwmixing: lists only the ties (not all N x N dyads), same table
*  - nwevcent: neighbour list built once, same centrality
*  - node names of derived networks no longer pass through a Stata option string (Stata inserts a blank
*    every 5,292 characters), which corrupted names above about 900 nodes and added rows to the data
*    (nwdissimilar, nwsimilar, nwsimindex, nwlambda, nwdropnodes, nwkeepnodes, nwcug)
*  - nwtostata: clear message when the flavour cannot hold the variables

set graphics off
set more off

* ---------------------------------------------------------------- random small networks
capture program drop t_mk
program t_mk
    // t_mk seed kind : kind 1 directed valued +-, 2 undirected, 3 two-mode
    args seed kind
    set seed `seed'
    clear
    nwclear
    local n = 8 + floor(runiform()*30)
    quietly set obs `=`n'*4'
    quietly gen long from = ceil(runiform()*`n')
    if `kind' == 3 {
        local m = max(2, floor(`n'/2))
        quietly gen long to = ceil(runiform()*`m')
        quietly duplicates drop from to, force
        quietly nw2fromedge from to, name(net)
    }
    else {
        quietly gen long to = ceil(runiform()*`n')
        quietly drop if from == to
        quietly duplicates drop from to, force
        quietly gen double val = ceil(runiform()*5) - 2
        quietly replace val = 1 if val == 0
        if `kind' == 1 quietly nwfromedge from to val, name(net)
        if `kind' == 2 quietly nwfromedge from to, undirected name(net)
    }
end

mata:
// dominant eigenvector of the symmetrised 0/1 adjacency matrix against the stored variable ev
void t_evref(real matrix A)
{
    real matrix X
    real rowvector L
    real colvector x, y, srt
    real scalar k, i

    A = ((A :+ A') :> 0) :* 1
    _diag(A, 0)
    symeigensystem(A, X = ., L = .)
    k = 1
    for (i = 2; i <= cols(L); i++) if (L[i] > L[k]) k = i
    x = X[., k]
    if (x[1] < 0) x = -x
    y = st_data(., "ev")
    y = y[1::rows(x)]
    srt = sort(L', 1)
    st_numscalar("dev", max(abs(y - x)))
    st_numscalar("gap", L[k] - (rows(srt) > 1 ? srt[rows(srt) - 1] : -1000))
}

void t_setnative(real scalar on)
{
    external real scalar nwg_comb_state
    nwg_comb_state = (on ? . : 0)
}
end
capture program drop t_native
program t_native
    // t_native 1 -> native kernels allowed (default), t_native 0 -> force the Mata code
    args on
    mata: t_setnative(`on')
end

mata: st_numscalar("ver", nwg_comb_version())
local native = (scalar(ver) >= 3)
if !`native' di "note: the plugin of this platform has no kernels 22/23 yet; native-versus-Mata comparisons skipped"

* ---------------------------------------------------------------- nwbalance / nwmatching: native = Mata
local ncmp 0
forvalues s = 1/40 {
    local kind = 1 + mod(`s', 3)
    t_mk `s' `kind'
    if `kind' == 3 {
        capture quietly nwmatching net, generate(m1) silent
        assert _rc == 0
        local matched1 = r(matched)
    }
    else {
        quietly nwbalance net, generate(b1 bb1 bc1)
        local clo1 = r(closed_triad)
        local bal1 = r(balanced_triad)
    }
    if `native' {
        t_native 0
        if `kind' == 3 {
            quietly nwmatching net, generate(m2) silent
            assert r(matched) == `matched1'
            assert m1 == m2
        }
        else {
            quietly nwbalance net, generate(b2 bb2 bc2)
            assert r(closed_triad) == `clo1' & r(balanced_triad) == `bal1'
            assert bb1 == bb2 & bc1 == bc2
            capture assert (b1 == b2) | (missing(b1) & missing(b2))
            assert _rc == 0
        }
        t_native 1
        local ++ncmp
    }
}
di "=== nwbalance / nwmatching: `ncmp' random networks, native equals Mata ==="

* a perfect matching on a known graph: 3 + 3 nodes, ties 1-1, 1-2, 2-1, 3-2, 3-3
clear
nwclear
quietly input long from long to
1 1
1 2
2 1
3 2
3 3
end
quietly nw2fromedge from to, name(known)
quietly nwmatching known, generate(mk) silent
assert r(matched) == 3

* ---------------------------------------------------------------- nwevcent against the dense eigenvector
forvalues s = 1/15 {
    t_mk `s' 2
    quietly nwevcent net, generate(ev)
    quietly nwtomatafast net
    mata: t_evref(`r(mata)')
    if scalar(gap) > 0.05 {
        assert scalar(dev) < 1e-5
    }
}
di "=== nwevcent equals the dense dominant eigenvector ==="

* ---------------------------------------------------------------- nwmixing: tie table from the matrix
forvalues s = 1/12 {
    local kind = 1 + mod(`s', 2)
    t_mk `s' `kind'
    quietly gen byte grp = 1 + mod(_n, 3)
    quietly nwmixing net, attribute(grp) permutations(0)
    local ei = r(EI_index)
    quietly nwtomatafast net
    mata: A = `r(mata)'
    mata: g = st_data((1, rows(A)), "grp")
    mata: S = (A :!= 0) :& (A :!= .)
    mata: _diag(S, 0)
    mata: same = (g * J(1, rows(A), 1)) :== (J(rows(A), 1, 1) * g')
    mata: nin = sum(S :* same)
    mata: nex = sum(S) - nin
    mata: st_numscalar("ei_ref", (nex - nin) / (nex + nin))
    assert reldif(`ei', scalar(ei_ref)) < 1e-12
}
di "=== nwmixing equals the index computed from the matrix ==="

* ---------------------------------------------------------------- names above 900 nodes
local N 1200
clear
nwclear
set seed 17
quietly set obs `=`N'*6'
quietly gen long from = ceil(_n/6)
quietly gen long to = ceil(runiform()*`N')
quietly drop if from == to
quietly duplicates drop from to, force
quietly nwfromedge from to, undirected name(big)
quietly gen double attr = rnormal()
assert _N == `N'

foreach c in "nwdissimilar big, name(d1)" "nwsimilar big, type(matches) name(d2)" ///
        "nwsimindex big, measure(jaccard) name(d3)" "nwlambda big, name(d4)" {
    quietly `c'
    assert _N == `N'
}
foreach net in d1 d2 d3 d4 {
    capture quietly nwname `net'
    if _rc continue
    mata: nn = tokens(st_global("r(labs)"), ",")
    mata: nn = select(nn, nn :!= ",")
    mata: st_numscalar("nbad", sum(strpos(nn, " ") :> 0) + (cols(nn) != `N'))
    assert scalar(nbad) == 0
}

quietly nwdropnodes big, nodes(1 2 3) generate(dn)
assert _N == `N'
quietly nwname dn
assert r(nodes) == `N' - 3
mata: nn = tokens(st_global("r(labs)"), ",")
mata: nn = select(nn, nn :!= ",")
mata: st_numscalar("nbad", sum(strpos(nn, " ") :> 0))
assert scalar(nbad) == 0
quietly nwkeepnodes big, nodes(5 6 7 8 9 10) generate(kn)
assert _N == `N'
di "=== node names intact above 900 nodes, no rows added ==="

* ---------------------------------------------------------------- nwtostata in a flavour with fewer variables
if c(max_k_theory) < 3000 {
    clear
    nwclear
    quietly nwring 2100, k(1) name(wide)
    quietly nwtomata wide, mat(WM)
    capture nwtostata, mat(WM) stub(w_)
    assert _rc == 900
    capture confirm variable w_1
    assert _rc != 0
    di "=== nwtostata: clear refusal above the variable limit ==="
}

* ---------------------------------------------------------------- size check, 5,000 nodes
local N 5000
clear
nwclear
set seed 5
timer clear 1
timer on 1
quietly set obs `=`N'*10'
quietly gen long from = ceil(_n/10)
quietly gen long to = ceil(runiform()*`N')
quietly drop if from == to
quietly duplicates drop from to, force
quietly gen byte val = ceil(runiform()*5)
quietly nwfromedge from to val, name(big)
quietly gen byte grp = ceil(runiform()*5)
quietly nwbalance big, generate(bb bbal bclo)
quietly nwmixing big, attribute(grp) permutations(0)
quietly nwevcent big, generate(evc)
quietly nwdissimilar big, name(dis)
assert _N == `N'
quietly nwdropnodes big, nodes(1 2 3) generate(dn5)
assert _N == `N'
clear
nwclear
quietly set obs `=`N'*10'
quietly gen long from = ceil(_n/10)
quietly gen long to = ceil(runiform()*`=`N'/2')
quietly duplicates drop from to, force
quietly nw2fromedge from to, name(two)
quietly nwmatching two, generate(mt) silent
assert r(matched) > 0
timer off 1
quietly timer list 1
di "size check: " r(t1) " seconds"
if `native' assert r(t1) < 60
di "=== size check, 5,000 nodes VERIFIED ==="

di "=== test_scale5k.do passed ==="
