cscript
nwclear

do unw_core.do

* Fixes of the 20,000-node scaling audit:
*  - nwtranspose, nwpermute, nwaddnodes, nwturnover, nwshared, nwsimmelian, nwbridges, nwdyads, nwsummarize, nwpath(generate),
*    nwdropnodes, nwreach, nwvalue work on the stored ties of a large network instead of an n x n matrix
*  - nwcloseness and nwkatz: breadth-first search from every node in the plugin (kernel 25), no distance matrix
*  - nwcommunity (labelprop), nwcoreperiphery, nwclique, nwmixing / nwtabulate permutations, nwattime without n x n work
*  - nwring, nwrandom (prob, density), nwsmall, nwpref draw the ties as a list above 2,000 nodes
*  - dense-by-nature commands stop at once with r(484) when their matrices do not fit (_nwdenseguard)
*  - bugs found on the way: nwmixing overwrote a valued network with its 0/1 pattern, nwtabulate attribute() permutations
*    counted the missing diagonal as ties, nwpref stopped above 10,000 nodes (rdiscrete limit), nwaddnodes left a 0 on the
*    diagonal of the new node, edge_weight() failed for a pair without a tie

set graphics off
set more off

mata:
// the n x n matrix of a list of ties (ego, alter, value)
real matrix t2m(real matrix T, real scalar n)
{
    real matrix M
    real scalar i

    M = J(n, n, 0)
    for (i = 1; i <= rows(T); i++) M[T[i, 1], T[i, 2]] = T[i, 3]
    _diag(M, 0)
    return(M)
}
end

capture program drop nwt20_matrix
program nwt20_matrix
    args net mname
    quietly nwtomata `net', mat(`mname')
    mata: _diag(`mname', .)
end

* a random small network, built twice: from the edge list (sparse, name sp) and from its matrix (dense, name de)
capture program drop nwt20_pair
program nwt20_pair
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
    quietly nwtomata sp, mat(__M)
    mata: _diag(__M, 0)
    if "`directed'" == "1" quietly nwset, mat(__M) name(de)
    else quietly nwset, mat(__M) name(de) undirected
    mata: mata drop __M
end

* ---------------------------------------------------------------- sparse = dense for the network manipulations
forvalues s = 1/20 {
    local dir = mod(`s', 2)
    nwt20_pair `s' `=12 + `s'' `dir'

    quietly nwtranspose sp, generate(sp_t)
    quietly nwtranspose de, generate(de_t)
    nwt20_matrix sp_t A
    nwt20_matrix de_t B
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0

    set seed 99
    quietly nwpermute sp, generate(sp_p)
    set seed 99
    quietly nwpermute de, generate(de_p)
    nwt20_matrix sp_p A
    nwt20_matrix de_p B
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0

    quietly nwaddnodes sp, nodenames(zz1, zz2) generate(sp_a)
    quietly nwaddnodes de, nodenames(zz1, zz2) generate(de_a)
    nwt20_matrix sp_a A
    nwt20_matrix de_a B
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0

    quietly nwturnover sp sp_p, generate(t1) silent
    local st1 = r(stable)
    local fo1 = r(formed)
    local di1 = r(dissolved)
    quietly nwturnover de de_p, generate(t2) silent
    assert `st1' == r(stable) & `fo1' == r(formed) & `di1' == r(dissolved)

    * 3.7.0: nwshared on a directed network needs the option undirected
    local shopt ""
    if `dir' == 1 local shopt "undirected"
    quietly nwshared sp, name(sp_s) `shopt'
    quietly nwshared de, name(de_s) `shopt'
    nwt20_matrix sp_s A
    nwt20_matrix de_s B
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0

    quietly nwsimmelian sp, name(sp_m)
    quietly nwsimmelian de, name(de_m)
    nwt20_matrix sp_m A
    nwt20_matrix de_m B
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0

    quietly nwdropnodes sp, nodes(1 3) generate(sp_d)
    quietly nwdropnodes de, nodes(1 3) generate(de_d)
    nwt20_matrix sp_d A
    nwt20_matrix de_d B
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0

    quietly nwdyads sp
    local m1 = r(_100)
    local a1 = r(_010)
    local n1 = r(_001)
    quietly nwdyads de
    assert `m1' == r(_100) & `a1' == r(_010) & `n1' == r(_001)

    quietly nwsummarize sp
    local dens1 = r(density)
    local mn1 = r(minval)
    local mx1 = r(maxval)
    quietly nwsummarize de
    assert reldif(`dens1', r(density)) < 1e-14 & `mn1' == r(minval) & `mx1' == r(maxval)

    quietly nwpath sp, egoid(1) alterid(5) generate(pa)
    local np_sp = r(paths)
    quietly nwpath de, egoid(1) alterid(5) generate(pb)
    assert `np_sp' == r(paths)
    forvalues k = 1/`=min(max(`np_sp', 0), 3)' {
        nwt20_matrix pa_`k' A
        nwt20_matrix pb_`k' B
        mata: st_numscalar("bad", sum(A :!= B))
        assert scalar(bad) == 0
    }
}
display "=== 20 random networks: transpose, permute, addnodes, turnover, shared, simmelian, dropnodes, dyads, summarize, path agree with the dense versions ==="

* ---------------------------------------------------------------- bridges of a sparse network (many bridges: a tree-like network)
forvalues s = 1/10 {
    clear
    nwclear
    set seed `s'
    quietly set obs 25
    quietly gen long from = ceil(runiform()*20)
    quietly gen long to = ceil(runiform()*20)
    quietly drop if from == to
    quietly duplicates drop from to, force
    quietly nwfromedge from to, name(sp) undirected
    quietly nwbridges sp, name(brs)
    local b1 "`r(bridges)'"
    nwt20_matrix brs A
    mata: _editmissing(A, 0)
    * the same count and ties from the dense route (the network rebuilt from its matrix)
    quietly nwtomata sp, mat(__M)
    mata: _diag(__M, 0)
    quietly nwset, mat(__M) name(de) undirected
    mata: mata drop __M
    quietly nwbridges de, name(brd)
    assert "`b1'" == "`r(bridges)'"
    nwt20_matrix brd B
    mata: _editmissing(B, 0)
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0
}
display "=== nwbridges: the same bridges from the sparse and the dense route ==="

* ---------------------------------------------------------------- the added node has a missing diagonal like all others
nwt20_pair 3 12 1
quietly nwaddnodes sp, nodenames(zz1) generate(sp_a)
quietly nwaddnodes de, nodenames(zz1) generate(de_a)
quietly nwtomata sp_a, mat(A)
quietly nwtomata de_a, mat(B)
mata: st_numscalar("bad", (A[rows(A), rows(A)] != .) + (B[rows(B), rows(B)] != .))
assert scalar(bad) == 0
display "=== nwaddnodes: the diagonal of the new node is missing ==="

* ---------------------------------------------------------------- one cell of a network without a tie is 0, not an error
nwt20_pair 4 14 1
quietly nwvalue sp, egoid(1) alterid(2)
local v12 = r(value)
quietly nwtomata sp, mat(A)
mata: st_numscalar("v", A[1, 2])
assert scalar(v) == `v12'
quietly nwvalue sp, egoid(3) alterid(3)
assert r(value) == .
display "=== nwvalue on a network held as stored ties ==="

* ---------------------------------------------------------------- nwmixing does not overwrite the network
clear
nwclear
set seed 5
quietly set obs 80
quietly gen long from = ceil(runiform()*20)
quietly gen long to = ceil(runiform()*20)
quietly drop if from == to
quietly duplicates drop from to, force
quietly gen byte val = ceil(runiform()*5)
quietly nwfromedge from to val, name(g)
quietly gen byte grp = ceil(runiform()*3)
quietly nwtomata g, mat(B0)
quietly nwmixing g, attribute(grp) permutations(10)
quietly nwtomata g, mat(B1)
mata: st_numscalar("bad", sum(B0 :!= B1))
assert scalar(bad) == 0
display "=== nwmixing with permutations() leaves the values of a valued network alone ==="

* ---------------------------------------------------------------- permutation p-values: sparse = dense (same seed)
forvalues s = 1/6 {
    nwt20_pair `s' 25 1
    quietly gen byte grp = ceil(runiform()*3)
    set seed 17
    quietly nwmixing sp, attribute(grp) permutations(30)
    local p1 = r(EI_pvalue)
    set seed 17
    quietly nwmixing de, attribute(grp) permutations(30)
    assert reldif(`p1', r(EI_pvalue)) < 1e-12
    set seed 18
    quietly nwtabulate sp, attribute(grp) permutations(30)
    local p2 = r(EI_pvalue)
    set seed 18
    quietly nwtabulate de, attribute(grp) permutations(30)
    assert reldif(`p2', r(EI_pvalue)) < 1e-12
}
display "=== nwmixing / nwtabulate permutation tests: sparse and dense give the same p-values ==="

* ---------------------------------------------------------------- closeness and Katz: plugin = matrix of distances
forvalues s = 1/10 {
    local dir = mod(`s', 2)
    nwt20_pair `s' 40 `dir'
    quietly nwcloseness sp, generate(c1 f1 n1)
    quietly nwkatz sp, generate(k1) alpha(.6)
    mata: nwg_comb_state = 0
    quietly nwcloseness sp, generate(c2 f2 n2)
    quietly nwkatz sp, generate(k2) alpha(.6)
    mata: nwg_comb_state = .
    foreach v in c f n {
        quietly count if abs(`v'1 - `v'2) > 1e-12 & `v'1 < . & `v'2 < .
        assert r(N) == 0
        quietly count if missing(`v'1) != missing(`v'2)
        assert r(N) == 0
    }
    capture confirm variable k1_in
    if _rc == 0 {
        quietly count if abs(k1_in - k2_in) > 1e-12
        assert r(N) == 0
        quietly count if abs(k1_out - k2_out) > 1e-12
        assert r(N) == 0
    }
    else {
        quietly count if abs(k1 - k2) > 1e-12
        assert r(N) == 0
    }
}
display "=== nwcloseness / nwkatz: breadth-first sums in the plugin equal the distance-matrix route ==="

* ---------------------------------------------------------------- label propagation, core-periphery on pairs = on the matrix
forvalues s = 1/10 {
    nwt20_pair `s' 40 0
    _nwsyntax sp
    mata: w = *`netobj'->get_matrix_mod(1, 0)
    mata: _diag(w, 0)
    mata: pr = nwg_symweights(`nodes', `netobj'->edgelist(), 1)
    mata: rseed(7)
    mata: l1 = LabelPropagation(w)
    mata: rseed(7)
    mata: l2 = LabelPropagationPairs(`nodes', pr)
    mata: st_numscalar("bad", sum(l1 :!= l2))
    assert scalar(bad) == 0
    mata: c1 = CorePeriphery(w, 100)
    mata: c2 = CorePeripheryPairs(`nodes', pr, 100)
    mata: st_numscalar("bad", sum(c1[1::rows(c1)-1] :!= c2[1::rows(c2)-1]) + (abs(c1[rows(c1)] - c2[rows(c2)]) > 1e-12))
    assert scalar(bad) == 0
    mata: mata drop w pr l1 l2 c1 c2
}
display "=== label propagation and core-periphery on the pairs equal the matrix versions ==="

* ---------------------------------------------------------------- nwclique keeps only the cliques asked for
forvalues s = 1/10 {
    nwt20_pair `s' 30 0
    _nwsyntax sp
    mata: c0 = `netobj'->calculate_cliques()
    mata: c3 = `netobj'->calculate_cliques(3)
    mata: st_numscalar("bad", (rows(select(c0, rowsum(c0) :>= 3)) != rows(c3)) + sum(select(c0, rowsum(c0) :>= 3) :!= c3))
    assert scalar(bad) == 0
    mata: mata drop c0 c3
}
display "=== calculate_cliques(minsize) equals the filtered full list ==="

* ---------------------------------------------------------------- generators: the list of ties equals the matrix of the earlier code
* the matrix versions are Mata functions in the ado files: run the files so that they are defined
foreach c in nwring nwsmall nwpref nwrandom {
    quietly findfile `c'.ado
    quietly run "`r(fn)'"
}
mata: A = ringlattice(300, 3)
mata: T = nw_ring_triplets(300, 3)
mata: B = t2m(T, 300)
mata: _diag(A, 0)
mata: st_numscalar("bad", sum(A :!= B))
assert scalar(bad) == 0
foreach d in 0 1 {
    foreach k in 2 4 {
        mata: rseed(5)
        mata: A = smallworldprob(400, `k', .15, `d')
        mata: rseed(5)
        mata: T = nw_small_prob_triplets(400, `k', .15, `d')
        mata: B = t2m(T, 400)
        mata: _diag(A, 0)
        mata: st_numscalar("bad", sum(A :!= B))
        assert scalar(bad) == 0
        mata: rseed(6)
        mata: A = smallworldsk(400, `k', 50, `d')
        mata: rseed(6)
        mata: T = nw_small_sk_triplets(400, `k', 50, `d')
        mata: B = t2m(T, 400)
        mata: _diag(A, 0)
        mata: st_numscalar("bad", sum(A :!= B))
        assert scalar(bad) == 0
    }
    mata: rseed(7)
    mata: A = prefattach(500, 2, 2, .1, `d')
    mata: rseed(7)
    mata: T = nw_pref_triplets(500, 2, 2, .1, `d')
    mata: B = t2m(T, 500)
    mata: _diag(A, 0)
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0
    mata: rseed(8)
    mata: A = get_random_prob(400, .02, `d', 0)
    mata: rseed(8)
    mata: T = nw_random_prob_triplets(400, .02, `d', 0)
    mata: B = t2m(T, 400)
    mata: _diag(A, 0)
    mata: st_numscalar("bad", sum(A :!= B))
    assert scalar(bad) == 0
}
display "=== ring, small-world, preferential attachment, random(prob): the same networks for the same seed ==="

* ---------------------------------------------------------------- random density: right number of ties, no loops, symmetric if undirected
mata: rseed(9)
mata: T = nw_random_density_triplets(300, .01, 0, 0)
mata: st_numscalar("bad", (rows(T) != floor(300 * 299 * .01)) + sum(T[., 1] :== T[., 2]) + (rows(uniqrows(T[., 1] :* 301 :+ T[., 2])) != rows(T)))
assert scalar(bad) == 0
mata: T = nw_random_density_triplets(300, .01, 1, 0)
mata: st_numscalar("bad", (rows(T) != 2 * floor(floor(300 * 299 * .01) / 2)) + sum(T[., 1] :== T[., 2]) + (rows(uniqrows(T[., 1] :* 301 :+ T[., 2])) != rows(T)))
assert scalar(bad) == 0
mata: M = t2m(T, 300)
mata: st_numscalar("bad", sum(M :!= M'))
assert scalar(bad) == 0
mata: T = nw_random_density_triplets(300, .01, 1, 1)
mata: st_numscalar("bad", (rows(uniqrows(T[., 1] :* 301 :+ T[., 2])) != rows(T)))
assert scalar(bad) == 0
display "=== nw_random_density_triplets: tie counts, no duplicates, symmetric ==="

* ---------------------------------------------------------------- nwpref above 10,000 nodes (rdiscrete stops there)
clear
nwclear
set seed 3
quietly nwpref 12000, name(big) undirected
_nwsyntax big
assert `nodes' == 12000
mata: st_numscalar("m", rows(__nw.nws.pdefs[__nw.nws.get_index_of("big")]->edgelist()))
* the seed block of 2 nodes holds one tie, every later node adds 2 ties (each in both directions)
assert scalar(m) == 2 * (1 + 2 * (12000 - 2))
display "=== nwpref with 12,000 nodes ==="

* ---------------------------------------------------------------- guards: immediate, with the alternative
capture _nwdenseguard, command(nwx) nodes(20000) copies(9) alternative(Use a part of it.)
assert _rc == 484
capture _nwdenseguard, command(nwx) nodes(20000) copies(9) force
assert _rc == 0
capture _nwdenseguard, command(nwx) nodes(5000) copies(9)
assert _rc == 0
clear
nwclear
set seed 1
quietly set obs 20000
quietly gen long from = ceil(_n / 2)
quietly gen long to = mod(_n * 7, 20000) + 1
quietly drop if from == to
quietly nwfromedge from to, name(g20)
timer clear 9
timer on 9
capture nwsimilar g20, type(matches) name(zz)
local rc1 = _rc
capture nwqap g20 g20, permutations(5) type(regress)
local rc2 = _rc
capture nwplot g20, layout(circle)
local rc3 = _rc
timer off 9
quietly timer list 9
assert `rc1' == 484 & `rc2' == 484 & `rc3' == 484
assert r(t9) < 10
display "=== nwsimilar, nwqap, nwplot stop at once above the memory limit ==="

* ---------------------------------------------------------------- 20,000 nodes: the sparse generators and sums finish in seconds
clear
nwclear
timer clear 1
timer on 1
set seed 1
quietly nwring 20000, k(5) name(r20)
quietly nwrandom 20000, prob(.0002) name(p20)
quietly nwrandom 20000, density(.0002) name(d20)
quietly nwsmall 20000, k(5) prob(.1) name(s20)
quietly nwpref 20000, name(f20) undirected
timer off 1
quietly timer list 1
assert r(t1) < 60
mata: st_numscalar("m", rows(__nw.nws.pdefs[__nw.nws.get_index_of("r20")]->edgelist()))
assert scalar(m) == 20000 * 10
mata: st_numscalar("m", rows(__nw.nws.pdefs[__nw.nws.get_index_of("d20")]->edgelist()))
assert scalar(m) == floor(20000 * 19999 * .0002)
nwdrop _all
quietly nwring 20000, k(5) name(r20)
timer clear 2
timer on 2
quietly nwcloseness r20, generate(clo far near)
timer off 2
quietly timer list 2
assert r(t2) < 120
quietly count if clo < .
assert r(N) == 20000
display "=== 20,000 nodes: generators and closeness ==="

display "test_scale20k: all passed"
