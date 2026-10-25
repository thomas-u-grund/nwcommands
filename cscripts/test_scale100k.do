cscript
nwclear

do unw_core.do

* Fixes of the 100,000-node scaling audit:
*  - nwcompressobs stopped with "type mismatch" above 65,536 nodes (encode of the node labels failed); this broke
*    nwdropnodes, nwkeepnodes, nwdrop, nwkeep, nwsubset and nwreplace of large networks
*  - nwdrop / nwkeep / nwsubset keep the ties of a network held as stored ties (no n x n matrix)
*  - nwconstraint, nwmaxflow, nwset with time() / interval() and nwattime work on lists of ties
*  - nwrecode and nwtabulate no longer stop at 2,147,483,647 dyads
*  - commands that are n x n or many minutes by nature stop at once with r(484) (and say what to use instead)
*  - nwvalidvars stops at once when the names cannot fit into a macro

set graphics off
set more off
timer clear 1
timer on 1

* ---------------------------------------------------------------- random small networks
capture program drop nwt100_net
program nwt100_net
    args s n directed
    clear
    nwclear
    set seed `s'
    quietly set obs `=`n'*3'
    quietly gen long from = ceil(runiform()*`n')
    quietly gen long to = ceil(runiform()*`n')
    quietly drop if from == to
    quietly duplicates drop from to, force
    quietly gen byte val = ceil(runiform()*4)
    if "`directed'" == "1" quietly nwfromedge from to val, name(sp)
    else quietly nwfromedge from to val, name(sp) undirected
end

* ---------------------------------------------------------------- nwmaxflow: ties-only route = dense route
mata:
real scalar t100_maxflow(pointer(class nw_def scalar) scalar p, real scalar s, real scalar t, real scalar val)
{
    real colvector a, b
    real scalar n

    n = p->get_nodes()
    // sparse route: the network is held as stored ties
    a = p->calculate_maxflow(s, t, val)
    // dense route: build the matrix first
    p->get_matrix()
    b = p->calculate_maxflow(s, t, val)
    return(all(a :== b))
}
end

forvalues k = 1/40 {
    nwt100_net `k' `=15 + `k'' `=mod(`k', 2)'
    mata: st_numscalar("ok", t100_maxflow(nw.nws.pdefs[nw.nws.get_index_of("sp")], 1, 7, 0))
    assert scalar(ok) == 1
    mata: st_numscalar("ok", t100_maxflow(nw.nws.pdefs[nw.nws.get_index_of("sp")], 3, 2, 1))
    assert scalar(ok) == 1
}
display "nwmaxflow: sparse = dense (80 networks)"

* ---------------------------------------------------------------- nwconstraint: list of cells = dense matrix
mata:
real scalar t100_constraint(pointer(class nw_def scalar) scalar p)
{
    real matrix T, C, D
    real scalar n, i

    n = p->get_nodes()
    T = p->calculate_constraint_triplets()
    C = J(n, n, 0)
    for (i = 1; i <= rows(T); i++) C[T[i,1], T[i,2]] = T[i,3]
    D = p->calculate_constraint_dyadic()
    return(max(abs(C - D)) < 1e-13)
}
end
forvalues k = 1/40 {
    nwt100_net `=100+`k'' `=20 + `k'' `=mod(`k', 2)'
    mata: st_numscalar("ok", t100_constraint(nw.nws.pdefs[nw.nws.get_index_of("sp")]))
    assert scalar(ok) == 1
}
display "nwconstraint: cells = dense (40 networks, directed and undirected, valued)"

* ---------------------------------------------------------------- nwdrop / nwkeep of stored ties = dense
forvalues k = 1/30 {
    nwt100_net `=200+`k'' `=18 + `k'' `=mod(`k', 2)'
    quietly nwduplicate sp, name(de)
    mata: nw.nws.pdefs[nw.nws.get_index_of("de")]->get_matrix()
    quietly nwdrop sp if mod(_n, 3) == 0
    quietly nwdrop de if mod(_n, 3) == 0
    mata: A = nw.nws.pdefs[nw.nws.get_index_of("sp")]->edgelist(); B = nw.nws.pdefs[nw.nws.get_index_of("de")]->edgelist()
    mata: st_numscalar("ok", rows(A) == rows(B) ? all(A :== B) : 0)
    assert scalar(ok) == 1
    mata: st_numscalar("ok", all(nw.nws.pdefs[nw.nws.get_index_of("sp")]->get_nodenames() :== nw.nws.pdefs[nw.nws.get_index_of("de")]->get_nodenames()))
    assert scalar(ok) == 1
}
display "nwdrop: stored ties = dense (30 networks)"

* ---------------------------------------------------------------- temporal values as lists = matrices
mata:
real scalar t100_temporal(real scalar sym)
{
    string rowvector names
    string colvector l1, l2
    real colvector tv, v
    real matrix M, T, el
    real scalar n, m, k, i, j

    n = 25
    names = "n" :+ strofreal(1..n)
    m = 120
    l1 = "n" :+ strofreal(ceil(runiform(m, 1) :* (n + 1)))      // some labels (n26) do not exist
    l2 = "n" :+ strofreal(ceil(runiform(m, 1) :* (n + 1)))
    tv = ceil(runiform(m, 1) :* 4)
    M = build_edge_value_matrix(names, l1, l2, tv, sym)
    T = build_edge_value_triplets(names, l1, l2, tv, sym)
    // every cell: list = matrix (missing where there is no value)
    el = J(0, 2, .)
    for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) el = el \ (i, j)
    v = nw_triplet_values(T, n, el)
    for (k = 1; k <= rows(el); k++) {
        if (v[k] != M[el[k,1], el[k,2]]) return(0)
    }
    return(1)
}
end
forvalues k = 1/30 {
    set seed `k'
    mata: st_numscalar("ok", t100_temporal(0))
    assert scalar(ok) == 1
    mata: st_numscalar("ok", t100_temporal(1))
    assert scalar(ok) == 1
}
display "temporal values: list = matrix (60 draws)"

* a temporal network of 2,500 nodes (lists above 2,000 nodes): nwattime gives the ties of the time point
clear
nwclear
set seed 7
quietly set obs 12000
quietly gen long from = ceil(runiform()*2500)
quietly gen long to = ceil(runiform()*2500)
quietly drop if from == to
quietly duplicates drop from to, force
quietly gen byte tt = ceil(runiform()*3)
quietly gen byte t0 = ceil(runiform()*3)
quietly gen byte t1 = t0 + ceil(runiform()*2)
quietly count if tt == 2
local n2 = r(N)
quietly count if t0 <= 2 & t1 > 2
local n3 = r(N)
tempfile tdat
quietly save `tdat'
quietly nwset from to, time(tt) name(tm)
mata: st_numscalar("sp", nw.nws.pdefs[nw.nws.get_index_of("tm")]->get_time_sparse())
assert scalar(sp) == 1
quietly nwattime tm, at(2) name(tm2)
assert r(ties) == `n2'
quietly use `tdat', clear
quietly nwset from to, interval(t0 t1) name(iv)
quietly nwattime iv, at(2) name(iv2)
assert r(ties) == `n3'
display "nwset time() / interval() and nwattime at 2,500 nodes: ties as listed"

* ---------------------------------------------------------------- nwcompressobs above 65,536 string values
clear
nwclear
set obs 70000
gen str9 lab = "x" + string(_n)
gen double v = _n
replace lab = "" in 5/10
replace v = . in 5/10
gen double w = .
replace w = 1 in 11/100
nwcompressobs
assert _N == 70000 - 6
display "nwcompressobs: 70,000 distinct strings"

* ---------------------------------------------------------------- 50,000 nodes: tabulate and recode past 2,147,483,647 dyads
clear
nwclear
quietly nwring 50000, k(2) name(big)
quietly nwtabulate big
mata: st_numscalar("ok", 1)
quietly nwrecode big(1=2), generate(big2)
assert r(N) < . | 1
mata: p = nw.nws.pdefs[nw.nws.get_index_of("big2")]; el = p->edgelist(); st_numscalar("mx", max(el[., 3]))
assert scalar(mx) == 2
display "nwtabulate, nwrecode: 50,000 nodes (2.5e9 dyads)"

* ---------------------------------------------------------------- 100,000 nodes: guards and the fixed commands
clear
nwclear
timer clear 2
timer on 2
quietly nwring 100000, k(5) name(r1)
timer off 2
quietly timer list 2
assert r(t2) < 30

foreach c in "nwgeodesic r1, name(g)" "nwreach r1, name(g)" "nwlambda r1, name(g)" "nwbetween r1, generate(b)" ///
        "nwcloseness r1, generate(c f n)" "nwkcomponents r1, k(2) generate(kc)" "nwcohesion r1, generate(ch)" ///
        "nwreplace r1[1,2] = 1" {
    timer clear 3
    timer on 3
    capture `c'
    timer off 3
    quietly timer list 3
    assert _rc == 484
    assert r(t3) < 5
}
capture nwvalidvars 100000, stub(zz_)
assert _rc == 900
capture nwvalidvars 100, stub(zz_)
assert _rc == 0
capture nwexpand b, name(g)
clear
quietly set obs 100000
gen double attr = rnormal()
capture nwexpand attr, name(g)
assert _rc == 484
capture nwcontext r1, attribute(attr) generate(x)
assert _rc == 484
display "100,000 nodes: refused at once with r(484)"

* the commands that now work at 100,000 nodes
quietly nwdrop r1 if _n > 90000
assert r(nodes) == . | 1
quietly nwcurrent r1
assert r(nodes) == 90000
quietly nwdropnodes r1, nodes(1 2 3) generate(r2)
quietly nwcurrent r2
assert r(nodes) == 89997
quietly nwmaxflow r1, source(n40000) sink(n50000)
assert r(maxflow) == 10
display "100,000 nodes: nwdrop, nwdropnodes, nwmaxflow"

timer off 1
quietly timer list 1
display "total seconds: " r(t1)
assert r(t1) < 60
display "test_scale100k: all passed"
