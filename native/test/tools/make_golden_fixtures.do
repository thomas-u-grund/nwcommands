* make_golden_fixtures.do -- writes native/test/fixtures/golden.txt: inputs and outputs of the native
* kernels, recorded from the plugin that Stata loads (run it with the plugin you trust, normally the macOS
* build). native/test/test_kernels.c reads the file and must reproduce every number on any platform.
*
* Run from the repository root:
*   adopath ++ <dir with the trusted nwgraph_macos.plugin>
*   global NWGOLD "native/test/fixtures/golden.txt"
*   do native/test/tools/make_golden_fixtures.do
* The random graphs use set seed, so the file is reproducible; the fixture records the numbers, not the seed.
* File format: see native/test/README.txt.

do unw_core.do
capture erase "$NWGOLD"

mata:
mata set matastrict off

real matrix gg_graph(real scalar n, real scalar p, real scalar dir, real scalar wmax, real scalar loops)
{
	real scalar i, j
	real matrix a
	a = J(0, 3, .)
	for (i = 1; i <= n; i++) {
		for (j = (dir ? 1 : i); j <= n; j++) {
			if (i == j & !loops) continue
			if (runiform(1, 1) < p) {
				w = (wmax > 0 ? ceil(runiform(1, 1) * wmax) : 1)
				a = a \ (i, j, w)
				if (!dir & i != j) a = a \ (j, i, w)
			}
		}
	}
	return(sort(a, (1, 2)))
}

// bipartite graph: nodes 1..n1 are mode 1, n1+1..n1+n2 mode 2; ties listed (low, high) once when once==1, else both ways
real matrix gg_bip(real scalar n1, real scalar n2, real scalar p, real scalar wmax, real scalar once)
{
	real scalar i, j
	real matrix a
	a = J(0, 3, .)
	for (i = 1; i <= n1; i++) for (j = 1; j <= n2; j++) {
		if (runiform(1, 1) < p) {
			w = (wmax > 0 ? ceil(runiform(1, 1) * wmax) : 1)
			a = a \ (i, n1 + j, w)
			if (!once) a = a \ (n1 + j, i, w)
		}
	}
	return(sort(a, (1, 2)))
}

string scalar gg_num(real scalar x)
{
	if (x >= .) return(".")
	return(strtrim(strofreal(x, "%24.17g")))
}

void gg_var(real scalar fh, real scalar idx, real colvector x)
{
	real scalar k
	fput(fh, "var " + strofreal(idx) + " " + strofreal(rows(x)))
	for (k = 1; k <= rows(x); k++) fput(fh, gg_num(x[k]))
}

string scalar gg_args(real scalar alg, real scalar n, real scalar nties, real rowvector par)
{
	string scalar s
	real scalar j
	s = strofreal(alg) + " " + strofreal(n) + " " + strofreal(nties)
	for (j = 1; j <= cols(par); j++) s = s + " " + strofreal(par[j], "%21.0g")
	return(s)
}

// kernels of the combinatorial wire protocol (algorithm codes 3..50): record inputs, status, scalars, result matrix
void gg_comb(string scalar path, string scalar name, real scalar alg, real scalar n, real matrix ties,
		real colvector nv, real rowvector par)
{
	real scalar fh, st, j, k, nties, m, c, allint
	string scalar tol, s
	real rowvector aux
	real matrix res
	
	res = nwg_comb(alg, n, ties, nv, par, aux, st)
	nties = rows(ties)
	fh = fopen(path, "a")
	fput(fh, "case " + name)
	fput(fh, "args " + gg_args(alg, n, nties, par))
	if (nties > 0) {
		gg_var(fh, 1, ties[., 1])
		gg_var(fh, 2, ties[., 2])
		gg_var(fh, 3, (cols(ties) >= 3 ? ties[., 3] : J(nties, 1, 1)))
	}
	if (rows(nv) > 0) gg_var(fh, 4, nv)
	fput(fh, "xs __nwg_status " + gg_num(st) + " 0")
	for (j = 1; j <= 4; j++) if (aux[j] < .) fput(fh, "xs __nwg_a" + strofreal(j) + " " + gg_num(aux[j]) + " " + gg_num(1e-9 * (aux[j] != trunc(aux[j]))))
	if (st == 0 & rows(res) > 0 & cols(res) > 0) {
		fput(fh, "xr " + strofreal(rows(res)) + " " + strofreal(cols(res)))
		tol = ""
		for (c = 1; c <= cols(res); c++) {
			allint = (sum(res[., c] :>= .) == 0) & all(res[., c] :== trunc(res[., c]))
			tol = tol + (c > 1 ? " " : "") + (allint ? "0" : "1e-9")
		}
		fput(fh, tol)
		for (k = 1; k <= rows(res); k++) {
			s = ""
			for (c = 1; c <= cols(res); c++) s = s + (c > 1 ? " " : "") + gg_num(res[k, c])
			fput(fh, s)
		}
	}
	fput(fh, "end")
	fclose(fh)
}

// kernels of the older wire protocol (1, 2, 20, 21): inputs in v1.., outputs read from v3..
void gg_legacy(string scalar path, string scalar name, string scalar argstr, real matrix inp, real scalar nout,
		real scalar nrows, real scalar nrowsin)
{
	real scalar fh, nobs, c, k, m
	string scalar of, vl, s
	real matrix out
	real scalar junk
	string rowvector vn

	of = st_framecurrent()
	stata("capture frame drop __gg")
	stata("frame create __gg")
	st_framecurrent("__gg")
	nobs = max((nrows, nrowsin, 3, rows(inp)))
	st_addobs(nobs)
	vn = "v" :+ strofreal(1..(2 + max((nout, 3)) + 1))
	junk = st_addvar("double", vn)
	for (c = 1; c <= cols(inp); c++) if (rows(inp) > 0) st_store((1::rows(inp)), vn[c], inp[., c])
	stata("capture program nwgraph_native, plugin using(" + char(34) + NativeGraphPluginPath() + char(34) + ")")
	vl = invtokens(vn[1..(2 + max((nout, 3)))])
	stata("plugin call nwgraph_native " + vl + ", " + char(34) + argstr + char(34))
	out = st_data((1::nrows), vn[3..(2 + nout)])
	st_framecurrent(of)
	stata("capture frame drop __gg")
	fh = fopen(path, "a")
	fput(fh, "case " + name)
	fput(fh, "args " + argstr)
	for (c = 1; c <= cols(inp); c++) gg_var(fh, c, inp[., c])
	for (c = 1; c <= nout; c++) {
		fput(fh, "xv " + strofreal(2 + c) + " " + strofreal(nrows) + " " + (all(out[., c] :== trunc(out[., c])) ? "0" : "1e-9"))
		for (k = 1; k <= nrows; k++) fput(fh, gg_num(out[k, c]))
	}
	fput(fh, "end")
	fclose(fh)
}
end

global G "$NWGOLD"
set seed 20261026

mata:
G = st_global("G")
// ---- legacy protocol kernels -------------------------------------------------------------------
A = gg_graph(30, 0.12, 0, 0, 0);  gg_legacy(G, "betweenness_undirected_30", "1 30 0 " + strofreal(rows(A)), A[., 1..2], 1, 30, rows(A))
A = gg_graph(25, 0.10, 1, 0, 0);  gg_legacy(G, "betweenness_directed_25", "1 25 1 " + strofreal(rows(A)), A[., 1..2], 1, 25, rows(A))
A = (1,2,1) \ (2,1,1) \ (2,3,1) \ (3,2,1) \ (3,4,1) \ (4,3,1)
gg_legacy(G, "betweenness_path_with_isolates_12", "1 12 0 " + strofreal(rows(A)), A[., 1..2], 1, 12, rows(A))
A = gg_graph(40, 0.07, 1, 0, 0);  gg_legacy(G, "bfs_directed_40_block", "2 40 1 " + strofreal(rows(A)) + " 3 4", A[., 1..2], 4, 40, rows(A))
A = gg_graph(35, 0.06, 0, 0, 0);  gg_legacy(G, "bfs_undirected_35_single", "2 35 0 " + strofreal(rows(A)) + " 1", A[., 1..2], 1, 35, rows(A))
A = gg_graph(14, 0.35, 0, 0, 0);  gg_legacy(G, "kconn_14_target3", "20 14 0 " + strofreal(rows(A)) + " 3", A[., 1..2], 1, 3, rows(A))
A = gg_graph(20, 0.14, 0, 0, 0);  gg_legacy(G, "kconn_20_target2", "20 20 0 " + strofreal(rows(A)) + " 2", A[., 1..2], 1, 3, rows(A))
A = gg_graph(18, 0.30, 0, 0, 0);  gg_legacy(G, "kconn_18_target4", "20 18 0 " + strofreal(rows(A)) + " 4", A[., 1..2], 1, 3, rows(A))
// Kamada-Kawai stress layout: ring of 15 plus chords, start on a circle
A = J(0, 3, .)
for (i = 1; i <= 15; i++) {
	j = mod(i, 15) + 1
	A = A \ (i, j, 1)
	A = A \ (j, i, 1)
}
A = A \ (1, 8, 1) \ (8, 1, 1)
A = A \ (4, 12, 1) \ (12, 4, 1)
A = sort(A, (1, 2))
P = J(15, 2, .)
for (i = 1; i <= 15; i++) P[i, .] = (cos(2 * pi() * i / 15) + 0.01 * i, sin(2 * pi() * i / 15))
inp = J(max((rows(A), 15)), 4, 0)
inp[1::rows(A), 1..2] = A[., 1..2]
inp[1::15, 3..4] = P
gg_legacy(G, "kk_stress_ring15", "21 15 0 " + strofreal(rows(A)) + " 20", inp, 3, 15, rows(inp))

// ---- combinatorial wire protocol ----------------------------------------------------------------
// n, the (sym01) pairs, undirected random graphs
A = gg_graph(14, 0.30, 0, 0, 0);  S = nwg_sym01(A)
gg_comb(G, "cohesion_14", 3, 14, S, J(0, 1, .), (0))
A = gg_graph(26, 0.14, 0, 0, 0);  S = nwg_sym01(A)
gg_comb(G, "cohesion_26", 3, 26, S, J(0, 1, .), (0))
gg_comb(G, "lambda_26", 5, 26, S, J(0, 1, .), J(1, 0, .))
A = gg_graph(16, 0.25, 0, 0, 0);  S = nwg_sym01(A)
gg_comb(G, "lambda_16", 5, 16, S, J(0, 1, .), J(1, 0, .))
gg_comb(G, "motif4_16", 6, 16, S, J(0, 1, .), J(1, 0, .))
A = gg_graph(22, 0.2, 0, 0, 0);  S = nwg_sym01(A)
gg_comb(G, "motif4_22", 6, 22, S, J(0, 1, .), J(1, 0, .))
// factions (weighted symmetric pairs, groups assigned cyclically as nwfactions does)
A = gg_graph(18, 0.25, 0, 5, 0);  SW = nwg_symw(A, 0, 1, 1)
gr = mod((1::18) :- 1, 3) :+ 1
gg_comb(G, "factions_18_k3", 4, 18, SW, gr, (3, 10))
// cluster2: two-mode clustering, five measures
B = gg_bip(8, 9, 0.35, 4, 0)
md = (J(8, 1, 1) \ J(9, 1, 0))
for (mc = 0; mc <= 4; mc++) gg_comb(G, "cluster2_measure" + strofreal(mc), 7, 17, B, md, (mc))
// n-cliques, n-clans, k-plexes
A = gg_graph(20, 0.18, 0, 0, 0)
gg_comb(G, "nclique_20_n2", 8, 20, A, J(0, 1, .), (2, 3, 100000, 0, 0, 60))
gg_comb(G, "nclan_20_n2", 8, 20, A, J(0, 1, .), (2, 3, 100000, 0, 1, 60))
S = nwg_sym01(A)
gg_comb(G, "kplex_20_k2", 9, 20, S, J(0, 1, .), (2, 4, 100000, 0, 60))
// balance (signed), matching, louvain, distance sums
A = gg_graph(16, 0.3, 0, 0, 0);  A[., 3] = 2 * (runiform(rows(A), 1) :> 0.35) :- 1
// make symmetric signs
for (r = 1; r <= rows(A); r++) {
	q = selectindex((A[., 1] :== A[r, 2]) :& (A[., 2] :== A[r, 1]))
	if (rows(q)) A[q, 3] = A[r, 3]
}
gg_comb(G, "balance_16", 22, 16, A, J(0, 1, .), J(1, 0, .))
B = gg_bip(7, 9, 0.3, 0, 0);  md = (J(7, 1, 1) \ J(9, 1, 2))
gg_comb(G, "matching_7_9", 23, 16, B, md, J(1, 0, .))
A = gg_graph(30, 0.12, 0, 3, 0);  P = select(A, A[., 1] :< A[., 2])
gg_comb(G, "louvain_30", 24, 30, P, J(0, 1, .), (1))
gg_comb(G, "louvain_30_res2", 24, 30, P, J(0, 1, .), (2))
A = gg_graph(22, 0.1, 1, 0, 0)
gg_comb(G, "distsum_directed_22", 25, 22, A, J(0, 1, .), (0, 1))
gg_comb(G, "distsum_directed_22_rev_a2", 25, 22, A, J(0, 1, .), (1, 2))
// clustering, triads, eigenvector centrality
A = gg_graph(30, 0.15, 0, 0, 0)
gg_comb(G, "clustering_undirected_30", 26, 30, A, J(0, 1, .), (0))
gg_comb(G, "triads_undirected_30", 27, 30, A, J(0, 1, .), J(1, 0, .))
gg_comb(G, "evcent_undirected_30", 28, 30, A, J(0, 1, .), (0, 0))
A = gg_graph(28, 0.10, 1, 0, 0)
gg_comb(G, "clustering_directed_28", 26, 28, A, J(0, 1, .), (1))
gg_comb(G, "triads_directed_28", 27, 28, A, J(0, 1, .), J(1, 0, .))
gg_comb(G, "evcent_directed_28", 28, 28, A, J(0, 1, .), (0, 0))
A = gg_graph(26, 0.12, 0, 6, 0)
gg_comb(G, "evcent_valued_26", 28, 26, A, J(0, 1, .), (0, 1))
// brokerage: burt, constraint, simmelian; weighted burt
A = gg_graph(24, 0.14, 0, 0, 0)
gg_comb(G, "burt_undirected_24", 29, 24, A, J(0, 1, .), J(1, 0, .))
gg_comb(G, "constraint_undirected_24", 30, 24, A, J(0, 1, .), J(1, 0, .))
A = gg_graph(20, 0.2, 1, 0, 0)
gg_comb(G, "burt_directed_20", 29, 20, A, J(0, 1, .), J(1, 0, .))
gg_comb(G, "constraint_directed_20", 30, 20, A, J(0, 1, .), J(1, 0, .))
A = gg_graph(28, 0.22, 0, 0, 0)
gg_comb(G, "simmelian_28", 31, 28, A[., 1..2], J(0, 1, .), J(1, 0, .))
A = gg_graph(20, 0.2, 0, 6, 0)
gg_comb(G, "burtw_valued_20", 40, 20, A, J(0, 1, .), J(1, 0, .))
// pagerank, cliques
A = gg_graph(32, 0.08, 1, 0, 0)
gg_comb(G, "pagerank_directed_32", 34, 32, A, J(0, 1, .), (0.85, 100, 1e-12))
A = gg_graph(32, 0.08, 1, 5, 0)
gg_comb(G, "pagerankw_directed_32", 44, 32, A, J(0, 1, .), (0.85, 100, 1e-12))
A = gg_graph(24, 0.28, 0, 0, 0)
gg_comb(G, "cliques_24_min1", 35, 24, A, J(0, 1, .), (1))
gg_comb(G, "cliques_24_min3", 35, 24, A, J(0, 1, .), (3))
// two-mode: Barber Louvain, weighted matching, swap, motifs
B = gg_bip(9, 11, 0.3, 3, 0);  P = select(B, B[., 1] :< B[., 2])
P = select(B, B[., 1] :< B[., 2]);  md = (J(9, 1, 1) \ J(11, 1, 2))
gg_comb(G, "louvain_bip_9_11", 43, 20, P, md, (1, 3, 12345))
B = gg_bip(8, 10, 0.35, 7, 0);  md = (J(8, 1, 1) \ J(10, 1, 2))
gg_comb(G, "matchw_8_10", 45, 18, B, md, J(1, 0, .))
B = gg_bip(10, 12, 0.3, 4, 1);  md = (J(10, 1, 1) \ J(12, 1, 2))
gg_comb(G, "swap_10_12", 46, 22, B, J(0, 1, .), (60, 777))
B = gg_bip(7, 8, 0.4, 0, 1);  md = (J(7, 1, 1) \ J(8, 1, 2))
gg_comb(G, "bmotif_7_8", 50, 15, B, md, (0))
B = gg_bip(6, 5, 0.5, 0, 1);  md = (J(6, 1, 1) \ J(5, 1, 2))
gg_comb(G, "bmotif_6_5_six", 50, 11, B, md, (1))
// weighted betweenness, distance sums, distance blocks
A = gg_graph(22, 0.15, 0, 5, 0)
gg_comb(G, "betweenw_undirected_22", 47, 22, A, J(0, 1, .), (1, 0))
A = gg_graph(22, 0.12, 1, 5, 0)
gg_comb(G, "betweenw_directed_22", 47, 22, A, J(0, 1, .), (1, 1))
gg_comb(G, "distsumw_directed_22", 48, 22, A, J(0, 1, .), (1))
gg_comb(G, "distblock_directed_22", 49, 22, A, J(0, 1, .), (1, 3, 5))
end
di as txt "golden fixtures written to $NWGOLD"
