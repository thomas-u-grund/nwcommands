cscript
nwclear

do unw_core.do

* nwtoedge, nw2toedge, nwexport, nwtabulate, nwrecode, nwdichotomize,
* nwkcomponents, nwplotmatrix, nwplot layout(kk): exact equality with a naive
* reference on small random networks (unsorted labels, isolates, directed and
* undirected, valued), then a size check (5,000 nodes, 10 ties each) that
* finishes in well under a minute.

set graphics off
set more off

* ---------------------------------------------------------------- helpers
capture program drop t_mknet
program t_mknet
    // t_mknet seed dir val : random network "net", labels unsorted as strings ("n10" < "n2")
    args seed dir val
    set seed `seed'
    local n = 4 + floor(runiform()*10)
    local p = 0.15 + runiform()*0.4
    mata: n = `n'; M = J(n, n, 0)
    forvalues i = 1/`n' {
        forvalues j = 1/`n' {
            if `i' != `j' & runiform() < `p' {
                local x = 1
                if `val' == 1 local x = ceil(runiform()*5)
                if `val' == 2 local x = round(rnormal()*3, 0.1)
                if `x' == 0 local x = 1
                if `dir' | `i' < `j' mata: M[`i', `j'] = `x'
                if !`dir' mata: M[`j', `i'] = `x'
            }
        }
    }
    * node 1 is an isolate
    mata: M[1,.] = J(1,n,0); M[.,1] = J(n,1,0)
    mata: st_matrix("__tM", M)
    mata: st_local("labs", invtokens("n" :+ strofreal(jumble(1::`n')'), ","))
    capture nwdrop net
    nwset, mat(__tM) name(net) labs(`labs') `=cond(`dir', "directed", "undirected")'
end

mata:
// every tie (i,j,w) of a matrix as the sorted lines "ego|alter|value" (lower triangle
// including the diagonal if undirected)
string colvector t_ties(real matrix M, string rowvector labs, real scalar undirected)
{
    real scalar i, j
    string colvector out
    out = J(0, 1, "")
    for (j = 1; j <= cols(M); j++) {
        for (i = 1; i <= rows(M); i++) {
            if (i != j & M[i,j] != 0 & M[i,j] < .) {
                if (!undirected | i >= j) out = out \ (labs[i] + "|" + labs[j] + "|" + strofreal(strtoreal(strofreal(M[i,j]))))
            }
        }
    }
    if (rows(out) == 0) return(out)
    return(sort(out, 1))
}

// the matrix rebuilt from the dyad list in memory (_ego, _alter, net) equals MM
real scalar t_sameasmatrix(real matrix MM, string rowvector labs, real scalar undirected)
{
    real colvector V
    string colvector E, A
    real matrix R, MMr
    real scalar k, n, i, j
    n = cols(MM)
    V = st_data(., "net")
    E = st_sdata(., "_ego")
    A = st_sdata(., "_alter")
    R = J(n, n, .)
    for (k = 1; k <= rows(V); k++) {
        i = selectindex(labs :== E[k])
        j = selectindex(labs :== A[k])
        R[i, j] = V[k]
        if (undirected) R[j, i] = V[k]
    }
    // the list holds the values as text with 12 digits (as nwtoedge always did)
    MMr = MM
    for (i = 1; i <= n; i++) {
        for (j = 1; j <= n; j++) {
            if (MMr[i,j] < .) MMr[i,j] = strtoreal(strofreal(MMr[i,j]))
        }
    }
    _diag(MMr, .)
    _diag(R, .)
    return(all((MMr :== R) :| (MMr :>= . :& R :>= .)))
}

// every cell (the lower triangle with the diagonal if undirected), as a column
real colvector t_cells(real matrix M, real scalar undirected)
{
    real scalar n
    real colvector v, ri, ci
    n = cols(M)
    v = vec(M)
    if (undirected) {
        ri = mod((1::n*n) :- 1, n) :+ 1
        ci = floor(((1::n*n) :- 1) :/ n) :+ 1
        v = v[selectindex(ri :>= ci)]
    }
    return(v)
}

// the ties in an exported file, as sorted lines "ego|alter|value"
string colvector t_readexport(string scalar fname, string scalar type, string rowvector labs, real scalar undirected)
{
    real scalar fh, state, k, l, src, tgt
    string scalar line
    string rowvector tk
    string colvector out
    real matrix tab

    out = J(0, 1, "")
    if (type == "edgelist") {
        fh = fopen(fname, "r")
        while ((line = fget(fh)) != J(0, 0, "")) {
            tk = tokens(line, char(9))
            tk = tk[selectindex(tk :!= char(9))]
            out = out \ (tk[1] + "|" + tk[2] + "|" + strofreal(strtoreal(tk[3])))
        }
        fclose(fh)
    }
    else if (type == "pajek" | type == "ucinet") {
        fh = fopen(fname, "r")
        state = 0
        while ((line = fget(fh)) != J(0, 0, "")) {
            if (state == 0) {
                if (substr(line, 1, 5) == "*Arcs" | substr(line, 1, 6) == "*Edges" | line == "data:") state = 1
            }
            else if (strtrim(line) != "") {
                tk = tokens(line)
                out = out \ (labs[strtoreal(tk[1])] + "|" + labs[strtoreal(tk[2])] + "|" + strofreal(strtoreal(tk[3])))
            }
        }
        fclose(fh)
    }
    else if (type == "gml") {
        fh = fopen(fname, "r")
        src = tgt = .
        while ((line = fget(fh)) != J(0, 0, "")) {
            tk = tokens(line)
            if (cols(tk) == 2) {
                if (tk[1] == "source") src = strtoreal(tk[2])
                if (tk[1] == "target") tgt = strtoreal(tk[2])
                if (tk[1] == "value") out = out \ (labs[src] + "|" + labs[tgt] + "|" + strofreal(strtoreal(tk[2])))
            }
        }
        fclose(fh)
    }
    if (rows(out) == 0) return(out)
    return(sort(out, 1))
}

// two-mode style blocks that overlap (so that k-components of different k exist)
real matrix nw_test_blocks()
{
    real scalar b, i, j, a, sz, start, n, ov, p
    real matrix M
    b = 2 + floor(runiform(1,1)*3)
    n = 0
    start = 1
    M = J(18, 18, 0)
    p = 0.7 + runiform(1,1)*0.3
    for (a = 1; a <= b; a++) {
        sz = 4 + floor(runiform(1,1)*3)
        if (start + sz - 1 > 18) sz = 18 - start + 1
        if (sz < 2) break
        for (i = start; i < start + sz; i++) {
            for (j = i + 1; j < start + sz; j++) {
                if (runiform(1,1) < p) {
                    M[i,j] = 1
                    M[j,i] = 1
                }
            }
        }
        n = start + sz - 1
        ov = 1 + floor(runiform(1,1)*3)
        start = max((start + sz - ov, start + 1))
    }
    return(M[1::n, 1::n])
}

real matrix recoderef(real matrix M)
{
    real matrix R
    real scalar i, j
    R = M
    for (i = 1; i <= rows(M); i++) {
        for (j = 1; j <= cols(M); j++) {
            if (M[i,j] >= 1 & M[i,j] <= 2) R[i,j] = 1
            else if (M[i,j] >= 3 & M[i,j] <= 5) R[i,j] = 2
        }
    }
    return(R)
}

// the box corners of the old stack/expand/bysort construction, one cell at a time
real matrix nw_pm_reference(real matrix M, real scalar diff, real rowvector split)
{
    real scalar c, k, n, r, col, nb, j
    real matrix out
    real colvector v
    nb = rows(M) * cols(M)
    n = rows(M)
    v = vec(M)
    out = J(5 * nb, 6, .)
    for (c = 1; c <= nb; c++) {
        r = mod(c - 1, n) + 1
        col = floor((c - 1) / n) + 1
        for (k = 1; k <= 5; k++) {
            out[5*(c-1) + k, 1] = col
            out[5*(c-1) + k, 2] = v[c]
            out[5*(c-1) + k, 3] = r
            if (k == 1 | k == 2) out[5*(c-1) + k, 4] = -1 * (r + diff) + 1
            if (k == 3 | k == 4) out[5*(c-1) + k, 4] = -1 * (r - diff) + 1
            if (k == 1 | k == 4) out[5*(c-1) + k, 5] = col + diff
            if (k == 2 | k == 3) out[5*(c-1) + k, 5] = col - diff
            for (j = 2; j <= cols(split); j++) {
                if (v[c] < split[j] & v[c] >= split[j-1]) out[5*(c-1) + k, 6] = j - 1
            }
        }
    }
    return(out)
}

// the interpreted Kamada-Kawai sweeps (the original kklayout() loop)
real matrix kk_reference(real matrix M, real scalar Iter, real matrix Start)
{
    real matrix D, W, Pos, delta
    real scalar V, i, j, t, wsum, dij
    real rowvector numer
    V = rows(M)
    D = distance(M)
    _diag(D, 0)
    W = J(V, V, 0)
    for (i = 1; i <= V; i++) {
        for (j = 1; j <= V; j++) {
            if (i != j) W[i,j] = 1 / (D[i,j]^2)
        }
    }
    Pos = Start
    for (t = 1; t <= Iter; t++) {
        for (i = 1; i <= V; i++) {
            numer = J(1,2,0)
            wsum = 0
            for (j = 1; j <= V; j++) {
                if (j != i) {
                    delta = Pos[i,.] - Pos[j,.]
                    dij = sqrt(delta*delta')
                    numer = numer :+ W[i,j] :* (Pos[j,.] :+ D[i,j] :* (delta :/ dij))
                    wsum = wsum + W[i,j]
                }
            }
            Pos[i,.] = numer :/ wsum
        }
    }
    return(Pos)
}

real scalar kk_compare(real scalar seed)
{
    real matrix M, S, Pn, Pr, Mr
    real scalar n, i, j
    rseed(seed)
    n = 5 + floor(runiform(1,1) * 25)
    M = J(n, n, 0)
    for (i = 1; i <= n; i++) {
        for (j = i + 1; j <= n; j++) {
            if (runiform(1,1) < 0.12) {
                M[i,j] = 1
                M[j,i] = 1
            }
        }
    }
    M = (M + M') :/ (M + M')
    _diag(M, .)
    S = runiform(n, 2)
    Mr = M
    Pr = kk_reference(Mr, 8, S)
    Pn = S
    if (nw_kk_native(M, Pn, 8) != 0) return(-1)
    return(all(Pn :== Pr))
}
end


* ---------------------------------------------------------------- 1. nwtoedge, 30 networks
forvalues s = 1/30 {
    quietly nwclear
    clear
    t_mknet `s' `=mod(`s',2)' `=mod(`s',3)'
    nwtomata net, mat(MM)
    quietly nwname net
    local isdir "`r(directed)'"
    mata: labs = tokens(subinstr("`r(labs)'", ",", " ", .))
    nwtoedge net
    mata: n = cols(MM)
    mata: st_local("exp", strofreal(("`isdir'" == "true") ? n * n : n * (n + 1) / 2))
    assert _N == `exp'
    * the values: rebuild the matrix from the list
    mata: st_numscalar("same", t_sameasmatrix(MM, labs, "`isdir'" == "false"))
    assert scalar(same) == 1
    * compress: exactly the ties (and the missing diagonal rows)
    nwtoedge net, compress
    quietly count if net != 0 & net < .
    mata: st_local("nt", strofreal(rows(t_ties(MM, labs, "`isdir'" == "false"))))
    di "seed `s': count=" r(N) " nt=`nt' isdir=`isdir'"
    assert r(N) == `nt'
}
di "=== nwtoedge equals the matrix: 30 networks VERIFIED ==="

* ---------------------------------------------------------------- 2. nwexport: the ties in every format
local tmpd `"`c(tmpdir)'"'
forvalues s = 1/30 {
    quietly nwclear
    clear
    t_mknet `s' `=mod(`s',2)' `=mod(`s',3)'
    nwtomata net, mat(MM)
    quietly nwname net
    local isdir "`r(directed)'"
    mata: labs = tokens(subinstr("`r(labs)'", ",", " ", .))
    mata: exp = t_ties(MM, labs, "`isdir'" == "false")
    mata: expall = t_ties(MM, labs, 0)
    foreach ty in pajek ucinet gml edgelist {
        local f `"`tmpd'/slowscale_`ty'"'
        capture erase `"`f'.net"'
        capture erase `"`f'.dl"'
        capture erase `"`f'.gml"'
        capture erase `"`f'.txt"'
        quietly nwexport net, type(`ty') fname(`"`f'"') replace
        local ext = cond("`ty'" == "pajek", "net", cond("`ty'" == "ucinet", "dl", cond("`ty'" == "gml", "gml", "txt")))
        mata: got = t_readexport(st_local("f") + "." + st_local("ext"), "`ty'", labs, "`isdir'" == "false")
        * ucinet lists an undirected tie in both directions
        mata: want = ("`ty'" == "ucinet" ? expall : exp)
        mata: st_numscalar("ok", rows(got) == rows(want) ? (rows(got) == 0 ? 1 : all(got :== want)) : 0)
        assert scalar(ok) == 1
    }
}
di "=== nwexport ties in all four formats equal the matrix: 30 networks VERIFIED ==="
* an existing file without replace is refused
capture nwexport net, type(pajek) fname(`"`tmpd'/slowscale_pajek"')
assert _rc != 0

* ---------------------------------------------------------------- 3. nwtabulate = tab of every dyad
forvalues s = 1/30 {
    quietly nwclear
    clear
    t_mknet `s' `=mod(`s',2)' `=mod(`s',3)'
    nwtomata net, mat(MM)
    quietly nwname net
    local isdir "`r(directed)'"
    quietly nwtabulate net, matcell(T) matrow(R)
    mata: Tn = st_matrix("T"); Rn = st_matrix("R")
    preserve
    clear
    mata: v = t_cells(MM, "`isdir'" == "false")
    mata: st_addobs(rows(v)); junk = st_addvar("double", "x"); st_store(., "x", strtoreal(strofreal(v)))
    quietly tab x, matcell(T0) matrow(R0)
    restore
    mata: st_numscalar("ok", all(st_matrix("T0") :== Tn) & all(st_matrix("R0") :== Rn))
    assert scalar(ok) == 1
}
di "=== nwtabulate equals tab of the dyad list: 30 networks VERIFIED ==="

* ---------------------------------------------------------------- 4. nw2toedge
forvalues s = 1/20 {
    quietly nwclear
    clear
    set seed `s'
    local a = 2 + floor(runiform()*6)
    local b = 2 + floor(runiform()*5)
    mata: st_matrix("__m2", (runiform(`a', `b') :< 0.4) :* ceil(runiform(`a', `b') :* 4))
    quietly nw2set, mat(__m2) name(bn)
    quietly nw2toedge bn, allpairs
    * every dyad between the modes, once
    assert _N == `a' * `b'
    quietly nw2toedge bn, compress
    quietly count if bn != 0 & bn < .
    mata: st_numscalar("nz", sum(st_matrix("__m2") :!= 0))
    assert r(N) == scalar(nz)
}
di "=== nw2toedge lists the dyads between the modes: 20 networks VERIFIED ==="


* a single distinct tie value (matrix of ones) used to fail with a conformability error (r(3200))
foreach v in 1 2.5 {
    quietly nwclear
    clear
    quietly nw2set, mat(J(6, 4, `v')) name(mynet)
    quietly nw2toedge
    assert _N == 24
    quietly nw2toedge, compress
    assert _N == 24
    quietly nw2toedge, full
    assert _N == 48
    quietly nwtoedge mynet
    assert _N == 55
    quietly nwtoedge mynet, compress
    quietly count if mynet == `v'
    assert r(N) == 24
    quietly nwtabulate mynet, matcell(T1)
    quietly nwexport mynet, type(edgelist) fname(`"`tmpd'/slowscale_ones"') replace
    quietly nwrecode mynet (`v'=3), generate(m3)
    nwtomata m3, mat(MR)
    mata: st_numscalar("ok", sum(MR :== 3) == 48)
    assert scalar(ok) == 1
    quietly nwclear
    quietly nwset, mat(J(4, 4, 1)) name(full1) undirected selfloop
    quietly nwrecode full1 (1=2)
    nwtomata full1, mat(MR)
    mata: st_numscalar("ok", all(MR :== 2))
    assert scalar(ok) == 1
    quietly nwdichotomize full1, threshold(2)
    nwtomata full1, mat(MR)
    mata: st_numscalar("ok", all(MR :== 1))
    assert scalar(ok) == 1
}
* nwset with modes and nw2fromedge: same lists as the cross-mode count
quietly nwclear
clear
quietly nwset, mat(J(10, 10, 1)) name(bip) undirected bipartite
quietly nwtoedge bip
quietly nwtoedge bip, compress
quietly nwdrop bip
quietly nwclear
clear
quietly set obs 30
quietly gen long f = ceil(_n/5)
quietly gen long g = mod(_n-1, 5) + 1
quietly nw2fromedge f g, name(two)
quietly nw2toedge two
assert _N == 30
quietly nw2toedge two, compress
assert _N == 30
quietly nwtoedge two
di "=== single-valued and matrix-built two-mode networks VERIFIED ==="

* ---------------------------------------------------------------- 5. nwrecode and nwdichotomize with labels not in alphabetical order
forvalues s = 1/30 {
    quietly nwclear
    clear
    t_mknet `s' `=mod(`s',2)' 1
    nwtomata net, mat(M0)
    quietly nwrecode net (1/2=1)(3/5=2), generate(rc)
    nwtomata rc, mat(M1)
    mata: st_numscalar("ok", all((M1 :== recoderef(M0)) :| (M1 :>= . :& M0 :>= .)))
    assert scalar(ok) == 1
    * the source is untouched
    nwtomata net, mat(M0b)
    mata: st_numscalar("ok", all((M0b :== M0) :| (M0b :>= . :& M0 :>= .)))
    assert scalar(ok) == 1
    quietly nwdichotomize net, threshold(3) generate(dd)
    nwtomata dd, mat(M2)
    mata: st_numscalar("ok", all((M2 :== (M0 :>= 3 :& M0 :< .)) :| (M2 :>= . :& M0 :>= .)))
    assert scalar(ok) == 1
    * in place
    quietly nwrecode net (1/2=1)(3/5=2)
    nwtomata net, mat(M3)
    mata: st_numscalar("ok", all((M3 :== M1) :| (M3 :>= . :& M1 :>= .)))
    assert scalar(ok) == 1
}
di "=== nwrecode / nwdichotomize elementwise, labels not in alphabetical order: 30 networks VERIFIED ==="

* ---------------------------------------------------------------- 6. nwkcomponents against the dense reference
forvalues s = 1/60 {
    quietly nwclear
    clear
    mata: rseed(`s'); AA = nw_test_blocks()
    mata: st_matrix("__tM", AA)
    quietly nwset, mat(__tM) name(net) undirected
    foreach k in 1 2 3 4 {
        quietly nwkcomponents net, k(`k') generate(kc) silent replace
        local ncomp = r(kcomponents)
        mata: nodeset = J(1, rows(AA), 1); KR = KComponents(AA, nodeset, `k')
        mata: st_numscalar("ncref", rows(KR))
        assert `ncomp' == scalar(ncref)
        if `ncomp' > 0 {
            mata: st_numscalar("ok", all(st_matrix("r(kcomp_matrix)") :== KR))
            assert scalar(ok) == 1
        }
    }
}
di "=== nwkcomponents equals the dense reference: 60 networks x 4 values of k VERIFIED ==="

* ---------------------------------------------------------------- 7. nwplotmatrix box data
forvalues s = 1/10 {
    set seed `s'
    local n = 3 + floor(runiform()*6)
    mata: st_matrix("PM", ceil(runiform(`n', `n') :* 3) :* (runiform(`n', `n') :< 0.4))
    preserve
    clear
    quietly set obs `=`n'*`n''
    mata: nw_pm_cells("PM")
    mata: nw_pm_boxes((-0.001, 0, 1.5, 3.001), 0.5)
    mata: REF = nw_pm_reference(st_matrix("PM"), 0.5, (-0.001, 0, 1.5, 3.001))
    mata: GOT = st_data(., ("_stack", "col1", "y", "yy", "xx", "cb"))
    mata: st_numscalar("ok", rows(GOT) == rows(REF) ? all((GOT :== REF) :| (GOT :>= . :& REF :>= .)) : 0)
    assert scalar(ok) == 1
    restore
}
di "=== nwplotmatrix box coordinates and colour levels equal the construction VERIFIED ==="
quietly nwclear
clear
set seed 7
quietly nwrandom 12, prob(.3) name(small)
quietly nwplotmatrix small
quietly nwset, mat(J(2600, 2600, 0)) name(huge) undirected
capture nwplotmatrix huge
assert _rc == 484
quietly nwdrop huge
di "=== nwplotmatrix runs, and refuses 2,600 nodes VERIFIED ==="

* ---------------------------------------------------------------- 8. layout(kk)
mata: st_numscalar("nat", NativeGraphAvailable())
if scalar(nat) == 1 {
    forvalues s = 1/30 {
        mata: st_numscalar("ok", kk_compare(`s'))
        assert scalar(ok) == 1
    }
    di "=== layout(kk) compiled sweeps equal the interpreted reference: 30 networks VERIFIED ==="
}
else {
    di "=== layout(kk): no compiled plugin for this platform, interpreted path only ==="
}
quietly nwclear
clear
set seed 3
quietly nwrandom 30, prob(.1) name(kknet)
quietly nwplot kknet, layout(kk) iterations(5)
di "=== nwplot layout(kk) runs ==="

* ---------------------------------------------------------------- 9. size check, under a minute
timer clear 1
timer on 1
quietly nwclear
clear
set seed 20261025
local N 5000
quietly set obs `=`N'*10'
quietly gen long from = ceil(_n/10)
quietly gen long to = ceil(runiform()*`N')
quietly drop if from == to
quietly duplicates drop from to, force
quietly nwfromedge from to, name(big) undirected
quietly nwtoedge big, compress
assert _N > 40000
foreach ty in edgelist pajek ucinet gml {
    quietly nwexport big, type(`ty') fname(`"`tmpd'/slowscale_big"') replace
}
quietly nwtabulate big, matcell(TB)
mata: st_numscalar("tot", sum(st_matrix("TB")))
assert scalar(tot) == `N' * (`N' + 1) / 2 - `N'
quietly nwrecode big (1=2), generate(big2)
quietly nwdichotomize big, threshold(2) generate(big3)
quietly nwkcomponents big, k(2) generate(bigk) silent
assert r(kcomponents) >= 1
timer off 1
quietly timer list 1
di "size check: " r(t1) " seconds"
assert r(t1) < 60
di "=== size check, 5,000 nodes: under 60 seconds VERIFIED ==="

di "=== test_slowcmds_scale.do passed ==="
