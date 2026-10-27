* checks.do - correctness helpers for the scaling audit (loaded by run_audit.py after the network is built).
* Ground truth comes from the generator's edge list, kept in Mata externals NWA_from/NWA_to/NWA_val
* (nwfromedge replaces the dataset, so the edge list is not in Stata memory any more).
* Failures accumulate in the global NWA_FAIL; run_audit.py prints it as NWAUDIT_CHECK=.
capture program drop nwa_check
capture program drop nwa_netp
capture program drop nwa_net
capture program drop nwa_var
capture program drop nwa_truthinit
mata:
mata set matastrict off
void nwa_truthinit(real scalar undirected)
{
    external real colvector NWA_from, NWA_to, NWA_val, NWA_comp, NWA_rowptr, NWA_col
    external real rowvector NWA_T
    real colvector par, ids, k, u, o
    real scalar n, i, a, b, ncomp, ties
    ties = rows(NWA_from)
    n = max(NWA_from \ NWA_to)
    par = (1::n)
    for (i = 1; i <= ties; i++) {
        a = NWA_from[i]; b = NWA_to[i]
        while (par[a] != a) {
            par[a] = par[par[a]]
            a = par[a]
        }
        while (par[b] != b) {
            par[b] = par[par[b]]
            b = par[b]
        }
        if (a != b) par[a] = b
    }
    NWA_comp = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        a = i
        while (par[a] != a) a = par[a]
        NWA_comp[i] = a
    }
    ncomp = rows(uniqrows(NWA_comp))
    k = sort(rowmin((NWA_from, NWA_to)) :* (n + 1) :+ rowmax((NWA_from, NWA_to)), 1)
    u = uniqrows(k)
    // CSR of the out-neighbours (directed truth), rows = node id
    o = order((NWA_from, NWA_to), (1, 2))
    NWA_col = NWA_to[o]
    NWA_rowptr = J(n + 1, 1, 0)
    for (i = 1; i <= ties; i++) NWA_rowptr[NWA_from[i] + 1] = NWA_rowptr[NWA_from[i] + 1] + 1
    for (i = 1; i <= n; i++) NWA_rowptr[i + 1] = NWA_rowptr[i + 1] + NWA_rowptr[i]
    NWA_T = (ties, rows(u), n, ncomp, sum(NWA_val))
}

// number of distinct nodes mentioned in the edge list for the second column (two-mode)
real scalar nwa_nto()
{
    external real colvector NWA_to
    return(rows(uniqrows(NWA_to)))
}

void nwa_net(pointer(class nw_def scalar) scalar p)
{
    real colvector r, c, w, ok, id
    string colvector lab
    real scalar n, bad
    n = p->get_nodes()
    st_numscalar("nwa_n", n)
    if (p->is_dense_built() & n > 5000) {
        // a result that is dense by nature (all-pairs distances, similarities): building the tie index of its
        // n*n cells would need three more matrices of that size; the recipes of such commands compare sample rows
        // count the ties and add their values row by row (the diagonal is left out)
        pointer(real matrix) scalar PM
        real rowvector rowv
        real scalar ii, narcs, wsm
        PM = p->get_matrix()
        narcs = 0; wsm = 0
        for (ii = 1; ii <= n; ii++) {
            rowv = (*PM)[ii, .]
            rowv[ii] = 0
            narcs = narcs + sum((rowv :!= 0) :& (rowv :!= .))
            wsm = wsm + sum(editmissing(rowv, 0))
        }
        st_numscalar("nwa_arcs", narcs)
        st_numscalar("nwa_wsum", wsm)
    }
    else {
        p->ensure_sparse_built()
        r = p->csr_rows(); c = p->colidx; w = p->cweight
        ok = r :!= c
        st_numscalar("nwa_arcs", sum(ok))
        st_numscalar("nwa_wsum", sum(select(w, ok)))
    }
    lab = p->get_nodenames()
    if (rows(lab) == 1) lab = lab'
    id = strtoreal(substr(lab, 2, .))
    bad = sum(substr(lab, 1, 1) :!= "n") + sum(id :== .) + (rows(uniqrows(lab)) != rows(lab)) + sum(strpos(lab, " ") :> 0)
    st_numscalar("nwa_labbad", bad)
    st_numscalar("nwa_labdens", p->is_dense_built())
}

// mismatches between the network's tie set and the generator's tie set (one-mode).
// mode 0 directed, 1 undirected (both orientations), 2 transposed; keep = node ids that remain (empty = all)
// also sets nwa_wmis: weight mismatches against the generator's tie values (mode 0 and 2)
real scalar nwa_edgecmp(pointer(class nw_def scalar) scalar p, real scalar mode, real colvector keep)
{
    external real colvector NWA_from, NWA_to, NWA_val
    real colvector r, c, w, id, k1, k2, ok, o1, o2, f, t, v, ind
    string colvector lab
    real scalar M
    p->ensure_sparse_built()
    r = p->csr_rows(); c = p->colidx; w = p->cweight
    ok = r :!= c
    r = select(r, ok); c = select(c, ok); w = select(w, ok)
    lab = p->get_nodenames()
    if (rows(lab) == 1) lab = lab'
    id = strtoreal(substr(lab, 2, .))
    if (hasmissing(id)) return(-1)
    M = max(id \ NWA_from \ NWA_to)
    f = NWA_from; t = NWA_to; v = NWA_val
    if (rows(keep) > 0) {
        ind = J(M, 1, 0)
        ind[keep] = J(rows(keep), 1, 1)
        ok = ind[f] :& ind[t]
        f = select(f, ok); t = select(t, ok); v = select(v, ok)
    }
    if (mode == 2) {
        ok = f
        f = t
        t = ok
    }
    k1 = id[r] :* (M + 1) :+ id[c]
    o1 = order(k1, 1)
    st_numscalar("nwa_wmis", 0)
    if (mode == 1) {
        k2 = sort(uniqrows((f :* (M + 1) :+ t) \ (t :* (M + 1) :+ f)), 1)
        k1 = k1[o1]
    }
    else {
        k2 = f :* (M + 1) :+ t
        o2 = order(k2, 1)
        k2 = k2[o2]
        k1 = k1[o1]
        if (rows(k1) == rows(k2)) st_numscalar("nwa_wmis", sum(w[o1] :!= v[o2]))
    }
    if (rows(k1) != rows(k2)) return(abs(rows(k1) - rows(k2)))
    return(sum(k1 :!= k2))
}

// compare an out/in degree variable pair with the generator's degrees (rows = nodes 1..N); w = 1: weighted by tie value
real scalar nwa_degcmp(string scalar vout, string scalar vin, real scalar w)
{
    external real colvector NWA_from, NWA_to, NWA_val
    real colvector d, e, x
    real scalar n, bad, i
    n = max(NWA_from \ NWA_to)
    d = J(n, 1, 0); e = J(n, 1, 0)
    x = (w ? NWA_val : J(rows(NWA_from), 1, 1))
    for (i = 1; i <= rows(x); i++) {
        d[NWA_from[i]] = d[NWA_from[i]] + x[i]
        e[NWA_to[i]] = e[NWA_to[i]] + x[i]
    }
    bad = 0
    if (vout != "") bad = bad + sum(st_data((1, n), vout) :!= d)
    if (vin != "") bad = bad + sum(st_data((1, n), vin) :!= e)
    return(bad)
}
real colvector mm_colsum_n(real colvector x, real scalar n)
{
    real colvector t
    real scalar i
    t = J(n, 1, 0)
    for (i = 1; i <= rows(x); i++) t[x[i]] = t[x[i]] + 1
    return(t)
}

// BFS distances (. = unreachable) from node s on the generator's ties: u = 0 out-ties, 1 undirected, 2 in-ties
real colvector nwa_bfs(real scalar s, real scalar u)
{
    external real colvector NWA_from, NWA_to
    real colvector d, q, rp, cl, ff, tt, oo
    real scalar n, h, t, v, j, w
    n = max(NWA_from \ NWA_to)
    if (u == 1) {
        ff = NWA_from \ NWA_to; tt = NWA_to \ NWA_from
    }
    else if (u == 2) {
        ff = NWA_to; tt = NWA_from
    }
    else {
        ff = NWA_from; tt = NWA_to
    }
    oo = order((ff, tt), (1, 2))
    cl = tt[oo]
    rp = 0 \ runningsum(mm_colsum_n(ff, n))
    d = J(n, 1, .)
    q = J(n, 1, 0)
    d[s] = 0; q[1] = s; h = 1; t = 1
    while (h <= t) {
        v = q[h]
        h++
        for (j = rp[v] + 1; j <= rp[v + 1]; j++) {
            w = cl[j]
            if (d[w] == .) {
                d[w] = d[v] + 1
                t++
                q[t] = w
            }
        }
    }
    return(d)
}

// sample sources (node numbers) used for the distance checks
real colvector nwa_samples()
{
    external real colvector NWA_from, NWA_to
    real scalar n
    n = max(NWA_from \ NWA_to)
    return(uniqrows((1 \ ceil(n/3) \ ceil(n/2) \ ceil(2*n/3) \ n)))
}

// rows of a derived network (geodesic distances: what = 0; reachability 0/1: what = 1) against BFS from the sample sources
real scalar nwa_rowcmp(pointer(class nw_def scalar) scalar p, real scalar what)
{
    real colvector sm, d
    pointer(real matrix) scalar M
    real scalar i, bad
    sm = nwa_samples()
    M = p->get_matrix()
    bad = 0
    for (i = 1; i <= rows(sm); i++) {
        d = nwa_bfs(sm[i], 0)
        d[sm[i]] = .
        if (what == 1) d = (d :!= .) :* 1
        if (what == 1) d[sm[i]] = .
        bad = bad + sum((*M)[sm[i], .]' :!= d)
    }
    return(bad)
}

// closeness: far (sum of distances to reachable nodes) for the sample sources, out or in direction; returns mismatches (out, in)
real rowvector nwa_farcmp(string scalar vfar)
{
    real colvector sm, f, d1, d2, d3
    real scalar i, b1, b2, b3
    sm = nwa_samples()
    f = st_data(., vfar)
    b1 = 0; b2 = 0; b3 = 0
    for (i = 1; i <= rows(sm); i++) {
        d1 = nwa_bfs(sm[i], 0)
        d2 = nwa_bfs(sm[i], 2)
        d3 = nwa_bfs(sm[i], 1)
        b3 = b3 + (sum(editmissing(d3, 0)) != f[sm[i]])
        b1 = b1 + (sum(editmissing(d1, 0)) != f[sm[i]])
        b2 = b2 + (sum(editmissing(d2, 0)) != f[sm[i]])
    }
    return((b1, b2, b3))
}

// (e,a,v) edge-list variables of an nwtoedge result against the generator: key and value mismatches
real scalar nwa_varcmp(string scalar ev, string scalar av, string scalar vv, real scalar valued)
{
    external real colvector NWA_from, NWA_to, NWA_val
    real colvector e, a, v, sel, k1, k2, o1, o2, M
    string colvector se, sa
    real scalar m
    se = st_sdata(., ev); sa = st_sdata(., av)
    v = st_data(., vv)
    sel = selectindex(v :!= . :& v :!= 0)
    se = se[sel]; sa = sa[sel]; v = v[sel]
    e = strtoreal(substr(se, 2, .)); a = strtoreal(substr(sa, 2, .))
    if (hasmissing(e) | hasmissing(a)) return(-1)
    m = max(e \ a \ NWA_from \ NWA_to)
    k1 = e :* (m + 1) :+ a
    k2 = NWA_from :* (m + 1) :+ NWA_to
    if (rows(k1) != rows(k2)) return(abs(rows(k1) - rows(k2)))
    o1 = order(k1, 1); o2 = order(k2, 1)
    return(sum(k1[o1] :!= k2[o2]) + (valued ? sum(v[o1] :!= NWA_val[o2]) : 0))
}

// do two vectors induce the same partition? returns the number of cells (a,b) beyond the partition sizes
real scalar nwa_samepart(real colvector a, real colvector b)
{
    return(rows(uniqrows((a, b))) - max((rows(uniqrows(a)), rows(uniqrows(b)))))
}

// weak components of the generator's ties against a variable
real scalar nwa_compcmp(string scalar v)
{
    external real colvector NWA_comp
    real colvector x
    x = st_data((1, rows(NWA_comp)), v)
    return(nwa_samepart(x, NWA_comp))
}

// coreness of the undirected generator graph by peeling (simple graph: both directions merged)
real colvector nwa_kcore()
{
    external real colvector NWA_from, NWA_to
    real colvector deg, core, alive, stack, kk, ff, tt, rp
    real scalar n, k, v, j, w, left
    n = max(NWA_from \ NWA_to)
    kk = sort(uniqrows((NWA_from :* (n + 1) :+ NWA_to) \ (NWA_to :* (n + 1) :+ NWA_from)), 1)
    ff = floor(kk :/ (n + 1)); tt = kk :- ff :* (n + 1)
    rp = 0 \ runningsum(mm_colsum_n(ff, n))
    deg = rp[2::(n + 1)] - rp[1::n]
    core = J(n, 1, 0); alive = J(n, 1, 1); left = n
    k = 0
    while (left > 0) {
        stack = select((1::n), alive :& deg :<= k)
        while (rows(stack) > 0) {
            v = stack[rows(stack)]
            stack = (rows(stack) > 1 ? stack[1::(rows(stack) - 1)] : J(0, 1, 0))
            if (!alive[v]) continue
            alive[v] = 0; core[v] = k; left--
            for (j = rp[v] + 1; j <= rp[v + 1]; j++) {
                w = tt[j]
                if (alive[w]) {
                    deg[w] = deg[w] - 1
                    if (deg[w] <= k) stack = stack \ w
                }
            }
        }
        k++
    }
    return(core)
}
// simple undirected graph of the generator as a sorted key vector (lo*(n+1)+hi both orientations), and CSR
void nwa_ugraph()
{
    external real colvector NWA_from, NWA_to, NWA_ukey, NWA_urp, NWA_ucl
    real colvector kk, ff
    real scalar n
    n = max(NWA_from \ NWA_to)
    kk = sort(uniqrows((NWA_from :* (n + 1) :+ NWA_to) \ (NWA_to :* (n + 1) :+ NWA_from)), 1)
    ff = floor(kk :/ (n + 1))
    NWA_ukey = kk
    NWA_ucl = kk :- ff :* (n + 1)
    NWA_urp = 0 \ runningsum(mm_colsum_n(ff, n))
}

real scalar nwa_has(real colvector K, real scalar key)
{
    real scalar lo, hi, mid
    lo = 1; hi = rows(K)
    while (lo <= hi) {
        mid = floor((lo + hi) / 2)
        if (K[mid] == key) return(1)
        if (K[mid] < key) lo = mid + 1
        else hi = mid - 1
    }
    return(0)
}

// local clustering coefficient (undirected simple graph) of ns sample nodes against variable v: mismatches above tol
real scalar nwa_clustcmp(string scalar v, real scalar ns)
{
    external real colvector NWA_from, NWA_to, NWA_ukey, NWA_urp, NWA_ucl
    real colvector x, nb, idx
    real scalar n, i, j, k, a, b, d, tri, c, bad, key
    nwa_ugraph()
    n = rows(NWA_urp) - 1
    x = st_data((1, n), v)
    bad = 0
    idx = uniqrows(ceil((1::ns) :* (n / ns)))
    for (i = 1; i <= rows(idx); i++) {
        a = idx[i]
        nb = NWA_ucl[(NWA_urp[a] + 1)::NWA_urp[a + 1]]
        d = rows(nb)
        tri = 0
        for (j = 1; j <= d; j++) {
            for (k = j + 1; k <= d; k++) {
                key = nb[j] * (n + 1) + nb[k]
                tri = tri + nwa_has(NWA_ukey, key)
            }
        }
        c = (d > 1 ? tri / (d * (d - 1) / 2) : 0)
        if (abs(x[a] - c) > 1e-5 & !(x[a] == . & d < 2)) bad++
    }
    return(bad)
}

// Newman modularity of the partition in variable v (rows = nodes 1..n) on the simple undirected generator graph
real scalar nwa_modq(string scalar v)
{
    external real colvector NWA_ukey, NWA_urp, NWA_ucl
    real colvector g, deg, ff, uq, ein, dtot
    real scalar n, m2, q, i
    nwa_ugraph()
    n = rows(NWA_urp) - 1
    g = st_data((1, n), v)
    deg = NWA_urp[2::(n + 1)] - NWA_urp[1::n]
    ff = floor(NWA_ukey :/ (n + 1))
    m2 = rows(NWA_ukey)
    uq = uniqrows(g)
    q = 0
    for (i = 1; i <= rows(uq); i++) {
        ein = sum(g[ff] :== uq[i] :& g[NWA_ucl] :== uq[i])
        dtot = sum(select(deg, g :== uq[i]))
        q = q + ein / m2 - (dtot / m2)^2
    }
    return(q)
}

// hitting-time identity h(i) = 1 + mean of h over the neighbours of i (undirected simple graph), h(target) = 0, on the sample nodes
real scalar nwa_hitcheck(string scalar v, real scalar target)
{
    external real colvector NWA_ukey, NWA_urp, NWA_ucl
    real colvector h, sm, nb
    real scalar n, i, a, bad
    nwa_ugraph()
    n = rows(NWA_urp) - 1
    h = st_data((1, n), v)
    bad = (abs(h[target]) > 1e-9)
    sm = nwa_samples()
    for (i = 1; i <= rows(sm); i++) {
        a = sm[i]
        if (a == target) continue
        nb = NWA_ucl[(NWA_urp[a] + 1)::NWA_urp[a + 1]]
        if (abs(h[a] - (1 + mean(h[nb]))) > 1e-6 * max((1, abs(h[a])))) bad++
    }
    return(bad)
}

end

program nwa_truthinit
    mata: NWA_urowptr = J(0, 1, 0); NWA_ucol = J(0, 1, 0)
    mata: nwa_truthinit(0)
    mata: st_numscalar("nwa_t_ties", NWA_T[1]); st_numscalar("nwa_t_upairs", NWA_T[2])
    mata: st_numscalar("nwa_t_nodes", NWA_T[3]); st_numscalar("nwa_t_ncomp", NWA_T[4])
    mata: st_numscalar("nwa_t_valsum", NWA_T[5])
end

// nwa_check "what" , c(expression): a failed or erroring condition adds to NWA_FAIL
program nwa_check
    syntax anything(name=desc), c(string asis)
    local ok = 0
    capture local ok = (`c')
    if _rc | `ok' != 1 {
        global NWA_FAIL `"${NWA_FAIL}; `desc' [`c']"'
    }
end

// nwa_netp name: loads nwa_* scalars of the named network
program nwa_netp
    args name
    mata: nwa_p = __nw.nws.pdefs[__nw.nws.get_index_of("`name'")]
    mata: nwa_net(nwa_p)
end

// nwa_var v, n(#) [sum(#) min(#) max(#) tol(#)]: v has n non-missing values, optional sum/min/max
program nwa_var
    syntax varname, n(real) [sum(string) min(string) max(string) tol(real 1e-6)]
    quietly count if !missing(`varlist')
    if r(N) != `n' global NWA_FAIL `"${NWA_FAIL}; `varlist' has `r(N)' non-missing, expected `n'"'
    quietly summarize `varlist'
    if "`sum'" != "" {
        if abs(r(sum) - `sum') > `tol' * max(1, abs(`sum')) global NWA_FAIL `"${NWA_FAIL}; sum(`varlist')=`=r(sum)' expected `sum'"'
    }
    if "`min'" != "" {
        if r(min) < `min' global NWA_FAIL `"${NWA_FAIL}; min(`varlist')=`=r(min)' < `min'"'
    }
    if "`max'" != "" {
        if r(max) > `max' global NWA_FAIL `"${NWA_FAIL}; max(`varlist')=`=r(max)' > `max'"'
    }
end

capture program drop nwa_std
capture program drop nwa_edges
// nwa_edges name, mode(0|1|2) [keep(mata expr) nodes(#) noweights]
program nwa_edges
    syntax anything(name=name), mode(integer) [keep(string asis) nodes(string) NOWeights]
    nwa_netp `name'
    if "`keep'" == "" local keep "J(0,1,0)"
    mata: nwa_keep = `keep'
    mata: st_numscalar("nwa_ecmp", nwa_edgecmp(nwa_p, `mode', nwa_keep))
    mata: st_numscalar("nwa_nkeep", rows(nwa_keep))
    if "`nodes'" == "" {
        local nodes = scalar(nwa_t_nodes)
        if scalar(nwa_nkeep) > 0 local nodes = scalar(nwa_nkeep)
    }
    nwa_check "nodes" , c(scalar(nwa_n) == `nodes')
    nwa_check "labels n<number>, unique, no blank" , c(scalar(nwa_labbad) == 0)
    nwa_check "tie set equals the generator's" , c(scalar(nwa_ecmp) == 0)
    if "`noweights'" == "" & `mode' != 1 & ("$NWA_KIND" == "valued" | "$NWA_KIND" == "edges") {
        nwa_check "tie values equal the generator's" , c(scalar(nwa_wmis) == 0)
    }
end

program nwa_std
    syntax anything(name=name) [, kind(string) nodes(string) noedges VALued]
    if "`kind'" == "" local kind "$NWA_KIND"
    if "`kind'" == "valued" local kind "dir"
    if "`kind'" == "valuedu" local kind "undir"
    if "`kind'" == "two" {
        nwa_netp `name'
        mata: st_numscalar("nwa_ton", nwa_nto())
        nwa_check "nodes (two-mode)" , c(scalar(nwa_n) == $NWA_N + scalar(nwa_ton))
        nwa_check "arcs (two-mode)" , c(scalar(nwa_arcs) == 2*scalar(nwa_t_ties))
        exit
    }
    local nopt ""
    if "`nodes'" != "" local nopt "nodes(`nodes')"
    if "`kind'" == "undir" {
        nwa_edges `name', mode(1) `nopt' noweights
        nwa_check "arcs (undirected)" , c(scalar(nwa_arcs) == 2*scalar(nwa_t_upairs))
    }
    else {
        if "`valued'" != "" | "$NWA_KIND" == "valued" nwa_edges `name', mode(0) `nopt'
        else nwa_edges `name', mode(0) `nopt' noweights
        nwa_check "arcs" , c(scalar(nwa_arcs) == scalar(nwa_t_ties))
    }
end

// all networks gone (after nwdrop / nwclear): nwcurrent fails
capture program drop nwa_gone
program nwa_gone
    capture nwcurrent
    local rc = _rc
    nwa_check "no network left" , c(`rc' != 0)
end

// nwa_cnt "what", if(condition) eq(expression): the number of observations satisfying the condition equals the expression
capture program drop nwa_cnt
program nwa_cnt
    syntax anything(name=desc), if(string asis) eq(string asis)
    quietly count if `if'
    local got = r(N)
    nwa_check `desc' , c(`got' == `eq')
end
