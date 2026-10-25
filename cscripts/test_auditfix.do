cscript

* Regression tests for the fixes that followed the Appendix D audit of release 3.5.0:
* nwdegree standardize, nwbetween centralisation, nwkatz with more observations than nodes, nwcloseness on unconnected
* networks, nwsimilar/nwdissimilar jaccard (and all other types and contexts against a brute-force definition),
* nwutility with intrvalue()/intrcost(), nwmixing stray output, nwcorrelate double storage, nwreach help.
* Run from the repository root.

do unw_core.do

mata:
// all-pairs shortest path lengths (unit steps, ties > 0) by Floyd-Warshall; unreachable = .
real matrix t_dist(real matrix A, real scalar sym)
{
	real matrix D, B
	real scalar n, i, j, k
	n = rows(A)
	B = (A :!= 0) :& (A :< .)
	_diag(B, 0)
	if (sym) B = B :| B'
	D = J(n, n, .)
	for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) if (B[i, j]) D[i, j] = 1
	_diag(D, 0)
	for (k = 1; k <= n; k++) for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) {
		if (D[i, k] < . & D[k, j] < .) if (D[i, j] >= . | D[i, k] + D[k, j] < D[i, j]) D[i, j] = D[i, k] + D[k, j]
	}
	return(D)
}

// betweenness of an undirected network by counting shortest paths (unordered pairs)
real colvector t_betw(real matrix A)
{
	real matrix D, sig
	real colvector b
	real scalar n, i, j, k, d, s, t, v
	n = rows(A)
	D = t_dist(A, 0)
	sig = J(n, n, 0)
	for (i = 1; i <= n; i++) {
		sig[i, i] = 1
		for (d = 1; d <= n; d++) {
			for (j = 1; j <= n; j++) {
				if (D[i, j] == d) {
					for (k = 1; k <= n; k++) {
						if (A[k, j] == 1 & D[i, k] == d - 1) sig[i, j] = sig[i, j] + sig[i, k]
					}
				}
			}
		}
	}
	b = J(n, 1, 0)
	for (s = 1; s <= n; s++) for (t = s + 1; t <= n; t++) for (v = 1; v <= n; v++) {
		if (v != s & v != t & D[s, v] < . & D[v, t] < . & D[s, t] < .) {
			if (D[s, v] + D[v, t] == D[s, t]) b[v] = b[v] + sig[s, v] * sig[v, t] / sig[s, t]
		}
	}
	return(b)
}

// igraph closeness: reachable nodes / sum of distances to them
real colvector t_clo(real matrix D)
{
	real colvector far, r
	real matrix F
	F = D
	_diag(F, .)
	r = rowsum(F :< .)
	far = rowsum(editmissing(F, 0))
	return(r :/ far)
}

// brute-force similarities of nodes i,j from binary tie vectors; positions i and j are masked to 0
// type: 1 matches (share of the n-2 other positions that agree), 2 jaccard, 3 hamming (agreements, masked
// positions counted as agreements), 4 crossproduct, 5 hamming dissimilarity (disagreements); dtype 0 both, 1 incoming, 2 outgoing
real matrix t_sim(real matrix A, real scalar ty, real scalar dtype)
{
	real matrix B, S
	real colvector a, b, c, d, keep
	real colvector u, v
	real scalar n, i, j, num, den, agr, tot
	n = rows(A)
	B = (A :!= 0) :& (A :< .)
	_diag(B, 0)
	S = J(n, n, .)
	for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) {
		if (i == j) continue
		keep = J(n, 1, 1); keep[i] = 0; keep[j] = 0
		a = B[i, .]' :* keep; b = B[j, .]' :* keep       // out vectors
		c = B[., i] :* keep; d = B[., j] :* keep         // in vectors
		if (dtype == 1) {
			a = J(0, 1, .)
			b = J(0, 1, .)
		}
		if (dtype == 2) {
			c = J(0, 1, .)
			d = J(0, 1, .)
		}
		u = a \ c; v = b \ d
		num = sum(u :* v)
		den = sum((u :+ v) :> 0)
		agr = sum(u :== v)
		tot = rows(u)
		if (ty == 1) S[i, j] = (agr - (dtype == 0 ? 4 : 2)) / (dtype == 0 ? 2 * (n - 2) : (n - 2))
		if (ty == 2) S[i, j] = num / den
		if (ty == 3) S[i, j] = agr
		if (ty == 4) S[i, j] = num
		if (ty == 5) S[i, j] = tot - agr
	}
	return(S)
}
end


capture program drop t_close
program t_close
	args a b tol
	mata: st_local("ok", strofreal(all((abs(`a' :- `b') :< `tol') :| (missing(`a') :& missing(`b')))))
	assert `ok' == 1
end

* ------------------------------------------------------------------------------------------------
* 1. nwdegree, standardize: degree / (n-1), once
* ------------------------------------------------------------------------------------------------
nwclear
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(S5) undirected
nwdegree S5, generate(deg) standardize silent
assert deg[1] == 1 & deg[2] == .25 & deg[5] == .25
assert r(dg_central) == 1
nwdegree S5, generate(rawdeg) silent
assert rawdeg[1] == 4 & rawdeg[2] == 1
nwdegree S5, generate(deg2) standardize isolates silent
assert deg2[1] == 1 & deg2[2] == .25
* directed: outdegree and indegree
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\0,0,0,1,0,0\0,0,0,0,1,0\0,0,0,0,0,1\1,0,0,0,0,0)) name(D6)
nwdegree D6, generate(o i) standardize silent
nwdegree D6, generate(ro ri) silent
forvalues r = 1/6 {
	assert abs(o[`r'] - ro[`r'] / 5) < 1e-6
	assert abs(i[`r'] - ri[`r'] / 5) < 1e-6
}
assert abs(o[1] - .4) < 1e-6 & abs(i[3] - .4) < 1e-6
* centralisation is from the raw scores and unchanged by standardize: path of 5 = 1/6 (Freeman)
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(P5) undirected
nwdegree P5, generate(pd) silent
assert abs(r(dg_central) - 1/6) < 1e-12
nwdegree P5, generate(pd2) standardize silent
assert abs(r(dg_central) - 1/6) < 1e-12
di "nwdegree standardize: ok"

* ------------------------------------------------------------------------------------------------
* 2. nwbetween: r(bw_central) is Freeman's centralisation
* ------------------------------------------------------------------------------------------------
nwbetween S5, generate(b) silent
assert abs(r(bw_central) - 1) < 1e-12
nwbetween S5, generate(bs) standardize silent
assert abs(r(bw_central) - 1) < 1e-12
nwbetween P5, generate(b) replace silent
* raw 0 3 4 3 0: sum(4 - b) = 10 over (n-1)^2 (n-2) / 2 = 24
assert abs(r(bw_central) - 10/24) < 1e-12
* directed path 1->2->3 with nosym: node 2 has raw 1, sum(max - b) = 2, denominator (n-1)^2 (n-2) = 4
nwset, mat((0,1,0\0,0,1\0,0,0)) name(DP3)
nwbetween DP3, generate(bd) nosym silent
assert abs(r(bw_central) - .5) < 1e-12
* undirected 6-node network against a brute-force betweenness (Freeman: sum(max - b) / ((n-1)^2 (n-2) / 2))
nwset, mat((0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,0\0,0,0,1,0,0)) name(U6) undirected
nwbetween U6, generate(bu) silent
local c = r(bw_central)
mata: A = (0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,0\0,0,0,1,0,0)
mata: D = t_dist(A, 0); n = 6
mata: b = t_betw(A)
mata: st_numscalar("brute", sum(max(b) :- b) / ((n - 1)^2 * (n - 2) / 2))
mata: st_local("diff", strofreal(max(abs(b :- st_data(1::6, "bu")))))
assert `diff' < 1e-9
assert abs(`c' - scalar(brute)) < 1e-9
di "nwbetween centralisation: ok"

* ------------------------------------------------------------------------------------------------
* 3. nwkatz with more observations than nodes
* ------------------------------------------------------------------------------------------------
nwclear
clear
set obs 12
nwset, mat((0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,0,1,0\0,1,0,0,1,1\0,0,1,1,0,0\0,0,0,1,0,0)) name(U6)
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(P5) undirected
if _N < 12 set obs 12
nwkatz P5, generate(k5) alpha(.5)
nwkatz P5, generate(k5w) alpha(.1) walks
nwkatz U6, generate(k6) alpha(.5)
count if !missing(k5)
assert r(N) == 5
count if !missing(k6_out)
assert r(N) == 6
assert _N >= 12
* the same values as with exactly n observations
preserve
nwclear
clear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(P5) undirected
nwkatz P5, generate(k5) alpha(.5)
nwkatz P5, generate(k5w) alpha(.1) walks
mata: ref1 = st_data(1::5, "k5"); ref2 = st_data(1::5, "k5w")
restore
mata: st_local("d1", strofreal(max(abs(st_data(1::5, "k5") :- ref1))))
mata: st_local("d2", strofreal(max(abs(st_data(1::5, "k5w") :- ref2))))
assert `d1' < 1e-12 & `d2' < 1e-12
* directed network, more observations than nodes
nwclear
clear
set obs 9
nwset, mat((0,1,1,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(D4)
nwkatz D4, generate(kd) alpha(.3) walks
count if !missing(kd_out)
assert r(N) == 4
di "nwkatz _N > nodes: ok"

* ------------------------------------------------------------------------------------------------
* 4. nwcloseness on an unconnected network
* ------------------------------------------------------------------------------------------------
nwclear
clear
* a-b, c-d-e path (unconnected)
nwset, mat((0,1,0,0,0\1,0,0,0,0\0,0,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(UC) undirected
log using "`c(tmpdir)'/auditfix_clo.log", text replace
nwcloseness UC, generate(c f n) silent
log close
mata: st_local("warned", strofreal(any(regexm(cat("`c(tmpdir)'/auditfix_clo.log"), "not connected"))))
assert `warned' == 1
* a: reaches 1 node at distance 1 -> 1; c: farness 3, reaches 2 -> 2/3; d: 2/2 = 1
assert c[1] == 1 & c[2] == 1
assert abs(c[3] - 2/3) < 1e-6 & c[4] == 1 & abs(c[5] - 2/3) < 1e-6
assert f[1] == 1 & f[3] == 3 & f[4] == 2
nwcloseness UC, generate(c2 f2 n2) legacy silent
assert c2[1] == 4 & abs(c2[4] - 2) < 1e-6
* unconnected(): old documented behaviour, (n-1)/farness with the missing paths given a length
nwcloseness UC, generate(c3 f3 n3) unconnected(5) silent
assert f3[1] == 1 + 5 * 3 & abs(c3[1] - 4 / 16) < 1e-6
* connected network: no warning, (n-1)/farness
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(P5) undirected
log using "`c(tmpdir)'/auditfix_clo2.log", text replace
nwcloseness P5, generate(cp fp np) silent
log close
mata: st_local("warned", strofreal(any(regexm(cat("`c(tmpdir)'/auditfix_clo2.log"), "not connected"))))
assert `warned' == 0
assert abs(cp[1] - 4/10) < 1e-6 & fp[1] == 10 & abs(cp[3] - 4/6) < 1e-6
* random unconnected networks against an independent igraph-style computation
forvalues rep = 1/5 {
	nwclear
	clear
	set seed `rep'
	nwrandom 14, prob(.08) name(RU) undirected
	nwcloseness RU, generate(c f n) silent
	nwtomata RU, mat(A)
	mata: A = editmissing(A, 0)
	mata: Dm = t_dist(A, 0); cl = t_clo(Dm)
	mata: st_local("dd", strofreal(max(abs(editmissing(st_data(1::14, "c"), 99) :- editmissing(cl, 99)))))
	assert `dd' < 1e-6
	nwcloseness RU, generate(c2 f2 n2) legacy silent
	mata: st_local("dd", strofreal(max(abs(editmissing(st_data(1::14, "c2"), 99) :- editmissing(rowsum(editmissing(Dm,0)):^-1 :* 13, 99)))))
	assert `dd' < 1e-6
}
* directed, nosym: out-distances
nwclear
clear
set seed 7
nwrandom 12, prob(.12) name(RD)
nwcloseness RD, generate(c f n) nosym silent
nwtomata RD, mat(A)
mata: Dm = t_dist(editmissing(A, 0), 0); cl = t_clo(Dm)
mata: st_local("dd", strofreal(max(abs(editmissing(st_data(1::12, "c"), 99) :- editmissing(cl, 99)))))
assert `dd' < 1e-6
di "nwcloseness unconnected: ok"

* ------------------------------------------------------------------------------------------------
* 5. nwsimilar / nwdissimilar: every type and context against brute force
* ------------------------------------------------------------------------------------------------
nwclear
clear
mata: A = (0,1,1,0,0,1\0,0,1,0,1,0\1,0,0,1,0,0\0,1,0,0,1,1\1,0,0,1,0,0\0,0,1,0,0,0)
mata: st_matrix("Am", A)
nwset, mat(Am) name(DN)
foreach ctx in both incoming outgoing {
	local dt = cond("`ctx'" == "both", 0, cond("`ctx'" == "incoming", 1, 2))
	local ti = 0
	foreach ty in matches jaccard hamming crossproduct {
		local ++ti
		nwsimilar DN, type(`ty') context(`ctx') name(S_`ty'_`ctx')
		nwtomata S_`ty'_`ctx', mat(S)
		mata: B = t_sim(A, `ti', `dt'); S = editmissing(S, 99)
		mata: _diag(S, 99); B = editmissing(B, 99)
		mata: st_local("dd", strofreal(max(abs(S :- B))))
		assert `dd' < 1e-12
		* symmetric
		mata: S = S; st_local("asym", strofreal(max(abs(S :- S'))))
		assert `asym' < 1e-12
	}
	* dissimilar jaccard = 1 - jaccard
	nwdissimilar DN, type(jaccard) context(`ctx') name(DJ_`ctx')
	nwtomata DJ_`ctx', mat(S)
	mata: B = t_sim(A, 2, `dt'); S = editmissing(S, 99); _diag(S, 99); B = editmissing(1 :- B, 99)
	mata: st_local("dd", strofreal(max(abs(S :- B))))
	assert `dd' < 1e-12
	* hamming dissimilarity: number of disagreements of the masked vectors
	nwdissimilar DN, type(hamming) context(`ctx') name(DH_`ctx')
	nwtomata DH_`ctx', mat(S)
	mata: B = t_sim(A, 5, `dt'); S = editmissing(S, 99); _diag(S, 99); B = editmissing(B, 99)
	mata: st_local("dd", strofreal(max(abs(S :- B))))
	assert `dd' < 1e-12
}
* the reproduction of the audit: s[1,4] = s[4,1]
nwsimilar DN, type(jaccard) context(both) name(JB)
nwtomata JB, mat(S)
mata: st_local("a14", strofreal(S[1,4])); st_local("a41", strofreal(S[4,1]))
assert abs(`a14' - `a41') < 1e-12
di "nwsimilar/nwdissimilar: ok"

* ------------------------------------------------------------------------------------------------
* 6. nwutility: intrvalue()/intrcost() honour benefit() and cost()
* ------------------------------------------------------------------------------------------------
nwclear
clear
mata: A = (0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)
mata: st_matrix("Am", A)
nwset, mat(Am) name(Q) undirected
* intrinsic values 1 off the diagonal, 0 on it (a self-loop network keeps the diagonal)
mata: st_matrix("Wm", J(4, 4, 1) - I(4))
nwset, mat(Wm) name(W) selfloop
nwutility Q, benefit(.5) cost(.2)
mata: ub = st_data(1::4, "_benefit"); uc = st_data(1::4, "_cost"); uu = st_data(1::4, "_util")
nwutility Q, benefit(.5) cost(.2) intrvalue(W)
mata: st_local("d1", strofreal(max(abs(st_data(1::4, "_benefit") :- ub))))
mata: st_local("d2", strofreal(max(abs(st_data(1::4, "_cost") :- uc))))
mata: st_local("d3", strofreal(max(abs(st_data(1::4, "_util") :- uu))))
assert `d1' < 1e-6 & `d2' < 1e-6 & `d3' < 1e-6
* independent: U(i) = sum_j b^d_ij w_ij - sum_{j tied} cost
mata: D = t_dist(A, 0); Bx = .5 :^ D; _diag(Bx, 0); st_local("d4", strofreal(max(abs(rowsum(Bx) :- ub))))
assert `d4' < 1e-6
mata: st_local("d5", strofreal(max(abs(rowsum(A) :* .2 :- uc))))
assert `d5' < 1e-6
* intrcost() with a per-dyad cost
mata: C = A :* (1, 2, 3, 4)'
mata: st_matrix("Cm", C)
nwset, mat(Cm) name(C)
nwutility Q, benefit(.5) intrcost(C)
mata: st_local("d6", strofreal(max(abs(st_data(1::4, "_cost") :- rowsum(C)))))
assert `d6' < 1e-6
mata: st_local("d7", strofreal(max(abs(st_data(1::4, "_benefit") :- ub))))
assert `d7' < 1e-6
* only intrvalue() with weights: benefit applies
mata: Wv = (J(4, 4, 2) :- 2 * I(4)); Wv = Wv + I(4) * 3
mata: st_matrix("Wvm", Wv)
nwset, mat(Wvm) name(WV) selfloop
nwutility Q, benefit(.5) cost(.2) intrvalue(WV)
mata: Bw = (.5 :^ D) :* Wv; _diag(Bw, 0); Bw = rowsum(Bw) :+ diagonal(Wv)
mata: st_local("d8", strofreal(max(abs(st_data(1::4, "_benefit") :- Bw))))
assert `d8' < 1e-6
di "nwutility: ok"

* ------------------------------------------------------------------------------------------------
* 7. nwmixing prints no stray 'invalid name' lines
* ------------------------------------------------------------------------------------------------
nwclear
clear
set seed 1
nwrandom 8, prob(.3) undirected name(g)
gen grp = mod(_n, 2)
log using "`c(tmpdir)'/auditfix_mix.log", text replace
nwmixing g, attribute(grp) permutations(20)
log close
mata: st_local("bad", strofreal(any(regexm(cat("`c(tmpdir)'/auditfix_mix.log"), "invalid name"))))
assert `bad' == 0
* and with a value label
label define gl 0 "zero" 1 "one"
label values grp gl
log using "`c(tmpdir)'/auditfix_mix2.log", text replace
nwmixing g, attribute(grp) permutations(20)
log close
mata: st_local("bad", strofreal(any(regexm(cat("`c(tmpdir)'/auditfix_mix2.log"), "invalid name"))))
assert `bad' == 0
mata: st_local("lab", strofreal(any(regexm(cat("`c(tmpdir)'/auditfix_mix2.log"), "zero"))))
assert `lab' == 1
di "nwmixing: ok"

* ------------------------------------------------------------------------------------------------
* 8. nwcorrelate stores the permuted correlations as double
* ------------------------------------------------------------------------------------------------
nwclear
clear
set seed 3
nwrandom 10, prob(.3) name(c1)
nwrandom 10, prob(.3) name(c2)
tempfile perm
nwcorrelate c1 c2, permutations(50) save("`perm'")
preserve
use "`perm'.dta", clear
describe correlation
assert "`: type correlation'" == "double"
restore
di "nwcorrelate: ok"

di "test_auditfix: all passed"
