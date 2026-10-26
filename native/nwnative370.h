/*
	nwnative370.h -- native (C) kernels for the two-mode and valued gaps closed in core 3.7.0.

	#included by nwcomb.h after nwburtw.h (one plugin binary); NWCOMB_VERSION 10 announces them.  Wire
	protocol as in nwcomb.h: ties (ego, alter, weight) in variables 1..3, one value per node in variable 4
	(algorithms that need it), the result stays in static memory (g_res) and is copied out by the FETCH
	call (alg 99).  Status 2 = out of memory or input too large (the caller then keeps the Mata code).

	43  louvain_bip  par: resolution nstart seed.  Barber's (2007) bipartite modularity search of
	                 nw_louvain_bip() in unw_core.do.  Ties = the symmetric pairs (i, j, w), i < j, of
	                 nwg_symweights(); variable 4 = the mode (1 or 2) of every node.  The first search (nodes
	                 visited in their order, neighbours in ascending order) is the Mata search; the nstart
	                 further searches visit the nodes in a random order drawn from the generator seeded with
	                 `seed' (the Mata caller draws the seed from uniform(), so set seed controls it): the
	                 same partition for the same seed on every platform, Q never below the Mata search
	                 from the first order.  Result n x 1 (community 1..k, as nw_community_denserelabel()).
	                 Published: a1 = Barber's Q of the result.
	44  pagerankw    par: damping maxiter tol.  Weighted PageRank of calculate_pagerank(, weighted = 1)
	                 (igraph::page_rank with weights): the surfer follows a tie with probability w / out-
	                 strength, ties with a value of zero or less (or missing) are not followed, nodes
	                 without such a tie are dangling.  Ties = edgelist().  Result n x 1.
	45  matchw        par: none.  Maximum-total-weight bipartite matching of calculate_matching_maxweight()
	                 (Hungarian method, shortest augmenting paths with potentials).  Ties = edgelist(),
	                 variable 4 = the mode of every node.  Up to 1,500 nodes in the larger mode the method runs on
	                 the same padded square matrix and in the same order as the Mata routine (so even a tie
	                 between optimal matchings is resolved the same way); above that on the rectangle
	                 (smaller mode as rows), where an optimal matching of the same total weight is found.
	                 Result n x 1: the mode-2 partner of a mode-1 node (0 = none), 0 for mode-2 nodes.
	46  swap          par: nswaps seed.  Tie-swap null model of permute_swap() (Maslov-Sneppen).  Ties = the
	                 cross-mode ties (mode 1, mode 2, value) once each.  Result m x 3 = the ties after
	                 nswaps attempts; a1 = number of swaps that took place.  The random choices come from the
	                 generator seeded with `seed'.
	47  betweenw     par: alpha directed.  Weighted betweenness of calculate_betweenness_weighted(): Brandes' (2001)
	                 algorithm with Dijkstra's search (binary heap), the cost of a tie of value w > 0 is w^(-alpha),
	                 lengths are compared with the relative tolerance 1e-10 as in the Mata routine, shortest-path
	                 counts are accumulated in the order in which the nodes are settled (equal distances are
	                 settled in node order, as the linear scan of the Mata routine does).  Ties = edgelist().
	                 directed = 0 halves the sums.  Result n x 1.
	48  distsumw     par: alpha.  Weighted distance sums for nwcloseness on valued networks: Dijkstra from every node,
	                 cost of a tie of value w > 0 is w^(-alpha), self-loops and ties of value zero or less are
	                 left out.  Ties = edgelist().  Result n x 2 = (sum of the distances to the other nodes that can be
	                 reached, number of those nodes).  No n x n matrix.
	49  distblock    par: alpha start count.  The distances of nwgeodesic on a valued network: Dijkstra from the nodes
	                 start..start+count-1 (1-based).  Result n x count: column c = distances from node start+c to every
	                 node (missing = unreachable, 0 for the node itself).
*/

#define ALG_LOUVBIP  43
#define ALG_PAGERANKW 44
#define ALG_MATCHW   45
#define ALG_SWAP     46
#define ALG_BETWEENW 47
#define ALG_DISTSUMW 48
#define ALG_DISTBLOCK 49

/* ---------------------------------------------------------------- */
/* generator: xorshift64* seeded by SplitMix64                       */
/* ---------------------------------------------------------------- */
typedef struct { uint64_t s; } n370_rng_t;

static void n370_seed(n370_rng_t *r, double seed) {
	uint64_t z = (uint64_t)(seed < 0 ? -seed : seed) + 0x9E3779B97F4A7C15ULL;
	z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
	z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
	z = z ^ (z >> 31);
	r->s = z ? z : 0x2545F4914F6CDD1DULL;
}

static uint64_t n370_next(n370_rng_t *r) {
	uint64_t x = r->s;
	x ^= x >> 12; x ^= x << 25; x ^= x >> 27;
	r->s = x;
	return x * 0x2545F4914F6CDD1DULL;
}

/* uniform integer in 0..k-1 (k < 2^32), unbiased by rejection */
static long n370_below(n370_rng_t *r, long k) {
	uint64_t lim = (UINT64_MAX / (uint64_t)k) * (uint64_t)k, x;
	do { x = n370_next(r); } while (x >= lim);
	return (long)(x % (uint64_t)k);
}

/* ---------------------------------------------------------------- */
/* 43: Louvain search for Barber's bipartite modularity              */
/* ---------------------------------------------------------------- */
typedef struct { long node, nbr, idx; double w; } lb_adj_t;
typedef struct { double key; long idx; double w; } lb_agg_t;

static int lb_adjcmp(const void *x, const void *y) {
	const lb_adj_t *a = (const lb_adj_t *)x, *b = (const lb_adj_t *)y;
	if (a->node != b->node) return a->node < b->node ? -1 : 1;
	if (a->nbr != b->nbr) return a->nbr < b->nbr ? -1 : 1;
	return (a->idx > b->idx) - (a->idx < b->idx);
}

static int lb_aggcmp(const void *x, const void *y) {
	const lb_agg_t *a = (const lb_agg_t *)x, *b = (const lb_agg_t *)y;
	if (a->key != b->key) return a->key < b->key ? -1 : 1;
	return (a->idx > b->idx) - (a->idx < b->idx);
}

/* v[0..n-1] holds values 0..maxv; replaced by their rank among the distinct values (0-based); returns the number of distinct values or -1 */
static long lb_denserank(long *v, long n, long maxv) {
	long *rk = (long *)calloc((size_t)(maxv + 2), sizeof(long));
	long i, c = 0;
	if (!rk) return -1;
	for (i = 0; i < n; i++) rk[v[i]] = 1;
	for (i = 0; i <= maxv; i++) { if (rk[i]) { rk[i] = c; c++; } }
	for (i = 0; i < n; i++) v[i] = rk[v[i]];
	free(rk);
	return c;
}

/* Barber's Q of a membership (1-based labels) on the pairs; md[i] = 1 or 2 (0-based node ids in ps/pd) */
static double lb_modularity(long n, long np, const long *ps, const long *pd, const double *pw, const int *md, const long *mem, double res) {
	double m = 0, sinw = 0, sk = 0;
	double *K1 = NULL, *K2 = NULL, *inw = NULL;
	long ncomm = 0, r, i, j, c;
	for (i = 0; i < n; i++) if (mem[i] > ncomm) ncomm = mem[i];
	if (ncomm < 1) return 0;
	for (r = 0; r < np; r++) if (md[ps[r]] != md[pd[r]] && pw[r] == pw[r] && pw[r] != 0) m += pw[r];
	if (m == 0) return 0;
	K1 = (double *)calloc((size_t)ncomm + 1, sizeof(double));
	K2 = (double *)calloc((size_t)ncomm + 1, sizeof(double));
	inw = (double *)calloc((size_t)ncomm + 1, sizeof(double));
	if (!K1 || !K2 || !inw) { free(K1); free(K2); free(inw); return 0.0 / 0.0; }
	for (r = 0; r < np; r++) {
		double w = pw[r];
		if (md[ps[r]] == md[pd[r]] || !(w == w) || w == 0) continue;
		i = ps[r]; j = pd[r];
		if (md[i] != 1) { i = pd[r]; j = ps[r]; }
		if (mem[i] >= 1) K1[mem[i]] += w;
		if (mem[j] >= 1) K2[mem[j]] += w;
		if (mem[i] == mem[j] && mem[i] >= 1) inw[mem[i]] += w;
	}
	for (c = 1; c <= ncomm; c++) { sinw += inw[c]; sk += K1[c] * K2[c]; }
	free(K1); free(K2); free(inw);
	return (sinw - res * sk / m) / m;
}

/* one search of nw_louvain_bip1(); pairs ps/pd/pw already restricted to cross-mode ties of value > 0; out = labels 1..k, or NULL on failure */
static int lb_search(long n, long np, const long *ps0, const long *pd0, const double *pw0, const int *md, double res,
		int rnd, n370_rng_t *rng, const long *init, long *out) {
	long *src = NULL, *dst = NULL, *final = NULL, *comm = NULL, *ptr = NULL, *nbr = NULL, *touched = NULL, *ord = NULL, *csrc = NULL, *cdst = NULL;
	double *wt = NULL, *a = NULL, *b = NULL, *Ac = NULL, *Bc = NULL, *kin = NULL, *wgt = NULL, *A2 = NULL, *B2 = NULL, *tmpd = NULL;
	lb_adj_t *adj = NULL;
	lb_agg_t *agg = NULL;
	long L = np, N = n, lvl = 0, i, q, r, K, rc = 0, ii, nt, t, c, ci, best, sweep, na;
	double m = 0, g, bestg;
	int moved, anymove, hasinit = (init != NULL);

	src = (long *)malloc((size_t)(np + 1) * sizeof(long));
	dst = (long *)malloc((size_t)(np + 1) * sizeof(long));
	wt = (double *)malloc((size_t)(np + 1) * sizeof(double));
	a = (double *)calloc((size_t)n + 1, sizeof(double));
	b = (double *)calloc((size_t)n + 1, sizeof(double));
	final = (long *)malloc((size_t)(n + 1) * sizeof(long));
	if (!src || !dst || !wt || !a || !b || !final) { rc = 2; goto done; }
	for (r = 0; r < np; r++) {
		src[r] = ps0[r]; dst[r] = pd0[r]; wt[r] = pw0[r];
		m += pw0[r];
		if (md[ps0[r]] == 1) a[ps0[r]] += pw0[r]; else b[ps0[r]] += pw0[r];
		if (md[pd0[r]] == 1) a[pd0[r]] += pw0[r]; else b[pd0[r]] += pw0[r];
	}
	for (i = 0; i < n; i++) final[i] = i;
	while (1) {
		na = 2 * L;
		free(adj); free(ptr); free(nbr); free(wgt); free(comm); free(Ac); free(Bc); free(kin); free(touched); free(ord);
		adj = (lb_adj_t *)malloc((size_t)(na + 1) * sizeof(lb_adj_t));
		ptr = (long *)calloc((size_t)N + 2, sizeof(long));
		nbr = (long *)malloc((size_t)(na + 1) * sizeof(long));
		wgt = (double *)malloc((size_t)(na + 1) * sizeof(double));
		comm = (long *)malloc((size_t)(N + 1) * sizeof(long));
		Ac = (double *)calloc((size_t)N + 1, sizeof(double));
		Bc = (double *)calloc((size_t)N + 1, sizeof(double));
		kin = (double *)calloc((size_t)N + 1, sizeof(double));
		touched = (long *)malloc((size_t)(N + 1) * sizeof(long));
		ord = (long *)malloc((size_t)(N + 1) * sizeof(long));
		if (!adj || !ptr || !nbr || !wgt || !comm || !Ac || !Bc || !kin || !touched || !ord) { rc = 2; goto done; }
		for (r = 0; r < L; r++) {
			adj[r].node = src[r]; adj[r].nbr = dst[r]; adj[r].idx = r; adj[r].w = wt[r];
			adj[L + r].node = dst[r]; adj[L + r].nbr = src[r]; adj[L + r].idx = L + r; adj[L + r].w = wt[r];
		}
		if (na > 1) qsort(adj, (size_t)na, sizeof(lb_adj_t), lb_adjcmp);
		for (q = 0; q < na; q++) { nbr[q] = adj[q].nbr; wgt[q] = adj[q].w; ptr[adj[q].node + 1]++; }
		for (i = 0; i < N; i++) ptr[i + 1] += ptr[i];
		for (i = 0; i < N; i++) { comm[i] = i; Ac[i] = a[i]; Bc[i] = b[i]; }
		if (lvl == 0 && hasinit) {
			for (i = 0; i < N; i++) { comm[i] = init[i] - 1; Ac[i] = 0; Bc[i] = 0; }
			for (i = 0; i < N; i++) { Ac[comm[i]] += a[i]; Bc[comm[i]] += b[i]; }
		}
		moved = 0; anymove = 1; sweep = 0;
		while (anymove && sweep < 100) {
			anymove = 0; sweep++;
			for (i = 0; i < N; i++) ord[i] = i;
			if (rnd) for (i = N - 1; i > 0; i--) { long j = n370_below(rng, i + 1), tmp = ord[i]; ord[i] = ord[j]; ord[j] = tmp; }
			for (ii = 0; ii < N; ii++) {
				i = ord[ii];
				ci = comm[i];
				Ac[ci] -= a[i]; Bc[ci] -= b[i];
				nt = 0;
				for (q = ptr[i]; q < ptr[i + 1]; q++) {
					c = comm[nbr[q]];
					if (kin[c] == 0) { touched[nt++] = c; }
					kin[c] += wgt[q];
				}
				best = ci;
				bestg = kin[ci] / m - res * (a[i] * Bc[ci] + b[i] * Ac[ci]) / (m * m);
				for (t = 0; t < nt; t++) {
					c = touched[t];
					g = kin[c] / m - res * (a[i] * Bc[c] + b[i] * Ac[c]) / (m * m);
					if (g > bestg + 1e-12) { bestg = g; best = c; }
				}
				for (t = 0; t < nt; t++) kin[touched[t]] = 0;
				comm[i] = best;
				Ac[best] += a[i]; Bc[best] += b[i];
				if (best != ci) { anymove = 1; moved = 1; }
			}
		}
		if (!moved && !(lvl == 0 && hasinit)) break;
		K = lb_denserank(comm, N, N);
		if (K < 0) { rc = 2; goto done; }
		lvl++;
		for (i = 0; i < n; i++) final[i] = comm[final[i]];
		/* next level graph */
		csrc = (long *)malloc((size_t)(L + 1) * sizeof(long));
		cdst = (long *)malloc((size_t)(L + 1) * sizeof(long));
		agg = (lb_agg_t *)malloc((size_t)(L + 1) * sizeof(lb_agg_t));
		A2 = (double *)calloc((size_t)K + 1, sizeof(double));
		B2 = (double *)calloc((size_t)K + 1, sizeof(double));
		if (!csrc || !cdst || !agg || !A2 || !B2) { rc = 2; goto done; }
		{
			long keep = 0, u = 0;
			for (r = 0; r < L; r++) {
				long cs = comm[src[r]], cd = comm[dst[r]], lo, hi;
				if (cs == cd) continue;
				lo = cs < cd ? cs : cd; hi = cs < cd ? cd : cs;
				agg[keep].key = (double)lo * (double)(K + 1) + (double)hi; agg[keep].idx = keep; agg[keep].w = wt[r];
				keep++;
			}
			if (keep == 0) break;
			for (i = 0; i < N; i++) { A2[comm[i]] += a[i]; B2[comm[i]] += b[i]; }
			if (keep > 1) qsort(agg, (size_t)keep, sizeof(lb_agg_t), lb_aggcmp);
			for (r = 0; r < keep; r++) {
				if (u > 0 && agg[r].key == agg[u - 1].key) { agg[u - 1].w += agg[r].w; }
				else { agg[u] = agg[r]; u++; }
			}
			for (r = 0; r < u; r++) {
				long lo = (long)floor(agg[r].key / (double)(K + 1));
				csrc[r] = lo; cdst[r] = (long)(agg[r].key - (double)lo * (double)(K + 1));
			}
			free(src); free(dst); free(wt); free(a); free(b);
			src = csrc; dst = cdst; csrc = cdst = NULL;
			wt = (double *)malloc((size_t)(u + 1) * sizeof(double));
			if (!wt) { rc = 2; goto done; }
			for (r = 0; r < u; r++) wt[r] = agg[r].w;
			a = A2; b = B2; A2 = B2 = NULL;
			L = u; N = K;
		}
		free(agg); agg = NULL;
	}
	for (i = 0; i < n; i++) out[i] = final[i];
	/* final labels: dense rank, 0-based -> 1-based */
	{
		long kk = lb_denserank(out, n, n);
		if (kk < 0) { rc = 2; goto done; }
		for (i = 0; i < n; i++) out[i] += 1;
	}
done:
	free(src); free(dst); free(wt); free(a); free(b); free(final);
	free(adj); free(ptr); free(nbr); free(wgt); free(comm); free(Ac); free(Bc); free(kin); free(touched); free(ord);
	free(csrc); free(cdst); free(agg); free(A2); free(B2); free(tmpd);
	return rc;
}

static int comb_louvbip(long n, long nties, const long *ei, const long *ej, const double *ew, const double *nv, double res, long nstart, double seed) {
	long *ps = NULL, *pd = NULL, *best = NULL, *cur = NULL, *nxt = NULL, *init1 = NULL;
	double *pw = NULL;
	int *md = NULL;
	long np = 0, k, r, it, i;
	double bq, cq, nq;
	n370_rng_t rng;
	int rc = 0;

	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	n370_seed(&rng, seed);
	md = (int *)malloc((size_t)n * sizeof(int));
	ps = (long *)malloc((size_t)(nties + 1) * sizeof(long));
	pd = (long *)malloc((size_t)(nties + 1) * sizeof(long));
	pw = (double *)malloc((size_t)(nties + 1) * sizeof(double));
	best = (long *)malloc((size_t)n * sizeof(long));
	cur = (long *)malloc((size_t)n * sizeof(long));
	nxt = (long *)malloc((size_t)n * sizeof(long));
	if (!md || !ps || !pd || !pw || !best || !cur || !nxt) { rc = 2; goto done; }
	for (i = 0; i < n; i++) md[i] = (nv[i] == 1) ? 1 : 2;
	/* the ties that count in the search: cross-mode, value above zero */
	for (k = 0; k < nties; k++) {
		long x = ei[k] - 1, y = ej[k] - 1;
		if (x < 0 || y < 0 || x >= n || y >= n) continue;
		if (md[x] == md[y] || !(ew[k] > 0)) continue;
		ps[np] = x; pd[np] = y; pw[np] = ew[k]; np++;
	}
	if (np == 0 || n <= 1) {
		for (i = 0; i < n; i++) best[i] = i + 1;
	}
	else {
		if ((rc = lb_search(n, np, ps, pd, pw, md, res, 0, &rng, NULL, best))) goto done;
		bq = lb_modularity(n, np, ps, pd, pw, md, best, res);
		for (r = 1; r <= nstart; r++) {
			if (r == 1) memcpy(cur, best, (size_t)n * sizeof(long));
			else if ((rc = lb_search(n, np, ps, pd, pw, md, res, 1, &rng, NULL, cur))) goto done;
			cq = lb_modularity(n, np, ps, pd, pw, md, cur, res);
			for (it = 1; it <= 20; it++) {
				if ((rc = lb_search(n, np, ps, pd, pw, md, res, 1, &rng, cur, nxt))) goto done;
				nq = lb_modularity(n, np, ps, pd, pw, md, nxt, res);
				if (nq > cq + 1e-12) { cq = nq; memcpy(cur, nxt, (size_t)n * sizeof(long)); }
				else break;
			}
			if (cq > bq + 1e-12) { bq = cq; memcpy(best, cur, (size_t)n * sizeof(long)); }
		}
	}
	if (res_alloc(n, 1)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) g_res[i] = (double)best[i];
	pub_a(1, np > 0 ? lb_modularity(n, np, ps, pd, pw, md, best, res) : 0.0);
	pub_result(0, n, 1);
done:
	(void)init1;
	free(md); free(ps); free(pd); free(pw); free(best); free(cur); free(nxt);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 44: weighted PageRank                                             */
/* ---------------------------------------------------------------- */
static int comb_pagerankw(long n, long nties, const long *ei, const long *ej, const double *ew, double d, long maxiter, double tol) {
	long *ptr = NULL, *idx = NULL;
	double *w = NULL, *str = NULL, *r = NULL, *rn = NULL, *tmp = NULL;
	long i, k, iter, tot = 0;
	int rc = 0;

	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	ptr = (long *)calloc((size_t)n + 2, sizeof(long));
	str = (double *)calloc((size_t)n + 1, sizeof(double));
	r = (double *)malloc((size_t)n * sizeof(double));
	rn = (double *)malloc((size_t)n * sizeof(double));
	tmp = (double *)malloc((size_t)n * sizeof(double));
	idx = (long *)malloc((size_t)(nties + 1) * sizeof(long));
	w = (double *)malloc((size_t)(nties + 1) * sizeof(double));
	if (!ptr || !str || !r || !rn || !tmp || !idx || !w) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) {
		if (ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n || !(ew[k] > 0)) continue;
		ptr[ei[k]]++; tot++;
	}
	{ long run = 0; for (i = 0; i < n; i++) { long c = ptr[i + 1]; ptr[i] = run; run += c; } ptr[n] = run; }
	{
		long *cur = (long *)malloc((size_t)n * sizeof(long));
		if (!cur) { rc = 2; goto done; }
		for (i = 0; i < n; i++) cur[i] = ptr[i];
		for (k = 0; k < nties; k++) {
			long s;
			if (ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n || !(ew[k] > 0)) continue;
			s = ei[k] - 1;
			idx[cur[s]] = ej[k] - 1; w[cur[s]] = ew[k]; cur[s]++;
			str[s] += ew[k];
		}
		free(cur);
	}
	(void)tot;
	for (i = 0; i < n; i++) r[i] = 1.0 / (double)n;
	for (iter = 1; iter <= maxiter; iter++) {
		long double dm = 0.0L;
		double dangling, base, diff = 0;
		for (i = 0; i < n; i++) if (str[i] == 0) dm += (long double)r[i];
		dangling = (double)dm;
		base = (1.0 - d) / (double)n + d * dangling / (double)n;
		for (i = 0; i < n; i++) tmp[i] = 0;
		for (i = 0; i < n; i++) {
			if (str[i] == 0) continue;
			for (k = ptr[i]; k < ptr[i + 1]; k++) tmp[idx[k]] += (w[k] / str[i]) * r[i];
		}
		for (i = 0; i < n; i++) {
			double a;
			rn[i] = base + d * tmp[i];
			a = fabs(rn[i] - r[i]);
			if (a > diff) diff = a;
		}
		{ double *sw = r; r = rn; rn = sw; }
		if (diff < tol) break;
	}
	if (res_alloc(n, 1)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) g_res[i] = r[i];
	pub_result(0, n, 1);
done:
	free(ptr); free(idx); free(w); free(str); free(r); free(rn); free(tmp);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 45: maximum-weight bipartite matching (Hungarian method)          */
/* ---------------------------------------------------------------- */
/* cost = -W for an nr x nc matrix (nr <= nc), row-major in Wm; rowof[j] (1-based columns) = assigned row (1-based) or 0 */
static int hung_run(long nr, long nc, const double *Wm, long *rowof) {
	double *u = NULL, *v = NULL, *minv = NULL;
	long *p = NULL, *way = NULL;
	unsigned char *used = NULL;
	long i, j, j0, j1, i0;
	double delta, cur;
	int rc = 0;

	u = (double *)calloc((size_t)nr + 2, sizeof(double));
	v = (double *)calloc((size_t)nc + 2, sizeof(double));
	minv = (double *)malloc((size_t)(nc + 2) * sizeof(double));
	p = (long *)calloc((size_t)nc + 2, sizeof(long));
	way = (long *)calloc((size_t)nc + 2, sizeof(long));
	used = (unsigned char *)malloc((size_t)nc + 2);
	if (!u || !v || !minv || !p || !way || !used) { rc = 2; goto done; }
	for (i = 1; i <= nr; i++) {
		p[0] = i;
		j0 = 0;
		for (j = 0; j <= nc; j++) { minv[j] = 1e300; used[j] = 0; }
		do {
			used[j0] = 1;
			i0 = p[j0];
			delta = 1e300;
			j1 = 0;
			for (j = 1; j <= nc; j++) {
				if (!used[j]) {
					cur = -Wm[(i0 - 1) * nc + (j - 1)] - u[i0] - v[j];
					if (cur < minv[j]) { minv[j] = cur; way[j] = j0; }
					if (minv[j] < delta) { delta = minv[j]; j1 = j; }
				}
			}
			for (j = 0; j <= nc; j++) {
				if (used[j]) { u[p[j]] += delta; v[j] -= delta; }
				else minv[j] -= delta;
			}
			j0 = j1;
		} while (p[j0] != 0);
		do {
			j1 = way[j0];
			p[j0] = p[j1];
			j0 = j1;
		} while (j0 != 0);
	}
	for (j = 1; j <= nc; j++) rowof[j] = p[j];
done:
	free(u); free(v); free(minv); free(p); free(way); free(used);
	return rc;
}

static int comb_matchw(long n, long nties, const long *ei, const long *ej, const double *ew, const double *nv) {
	long *pos = NULL, *idx1 = NULL, *idx2 = NULL, *rowof = NULL;
	double *Wm = NULL;
	long n1 = 0, n2 = 0, N, i, j, k, nr, nc;
	int rc = 0, transposed = 0;

	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	pos = (long *)calloc((size_t)n + 1, sizeof(long));
	idx1 = (long *)malloc((size_t)n * sizeof(long));
	idx2 = (long *)malloc((size_t)n * sizeof(long));
	if (!pos || !idx1 || !idx2) { rc = 2; goto done; }
	for (i = 0; i < n; i++) {
		if (nv[i] == 1) { idx1[n1] = i + 1; pos[i] = ++n1; }
		else if (nv[i] == 2) { idx2[n2] = i + 1; pos[i] = ++n2; }
	}
	if (res_alloc(n, 1)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) g_res[i] = 0;
	if (n1 == 0 || n2 == 0) { pub_result(0, n, 1); goto done; }
	N = n1 > n2 ? n1 : n2;
	if (N <= 1500) { nr = N; nc = N; }
	else if (n1 <= n2) { nr = n1; nc = n2; }
	else { nr = n2; nc = n1; transposed = 1; }
	if ((double)nr * (double)nc > 4e8) { rc = 2; goto done; }
	Wm = (double *)calloc((size_t)(nr * nc) + 1, sizeof(double));
	rowof = (long *)calloc((size_t)nc + 2, sizeof(long));
	if (!Wm || !rowof) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) {
		long x = ei[k], y = ej[k];
		if (x < 1 || y < 1 || x > n || y > n || x == y) continue;
		if (!(ew[k] > 0) || nv[x - 1] != 1 || nv[y - 1] != 2) continue;
		if (transposed) Wm[(pos[y - 1] - 1) * nc + (pos[x - 1] - 1)] = ew[k];
		else Wm[(pos[x - 1] - 1) * nc + (pos[y - 1] - 1)] = ew[k];
	}
	if ((rc = hung_run(nr, nc, Wm, rowof))) goto done;
	for (j = 1; j <= nc; j++) {
		i = rowof[j];
		if (i < 1) continue;
		if (!transposed) {
			if (i <= n1 && j <= n2 && Wm[(i - 1) * nc + (j - 1)] > 0) g_res[idx1[i - 1] - 1] = (double)idx2[j - 1];
		}
		else {
			/* rows = mode 2, columns = mode 1 */
			if (i <= n2 && j <= n1 && Wm[(i - 1) * nc + (j - 1)] > 0) g_res[idx1[j - 1] - 1] = (double)idx2[i - 1];
		}
	}
	pub_result(0, n, 1);
done:
	free(pos); free(idx1); free(idx2); free(Wm); free(rowof);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 46: tie swapping (Maslov-Sneppen)                                 */
/* ---------------------------------------------------------------- */
typedef struct { int64_t *key; long cap, used; } sw_hash_t;

static uint64_t sw_h(int64_t k) {
	uint64_t x = (uint64_t)k;
	x ^= x >> 33; x *= 0xff51afd7ed558ccdULL; x ^= x >> 33; x *= 0xc4ceb9fe1a85ec53ULL; x ^= x >> 33;
	return x;
}

#define SW_EMPTY (-1)
#define SW_TOMB  (-2)

static int sw_has(const sw_hash_t *h, int64_t k) {
	uint64_t i = sw_h(k) & (uint64_t)(h->cap - 1);
	while (h->key[i] != SW_EMPTY) {
		if (h->key[i] == k) return 1;
		i = (i + 1) & (uint64_t)(h->cap - 1);
	}
	return 0;
}

static void sw_add(sw_hash_t *h, int64_t k) {
	uint64_t i = sw_h(k) & (uint64_t)(h->cap - 1);
	while (h->key[i] >= 0) i = (i + 1) & (uint64_t)(h->cap - 1);
	if (h->key[i] == SW_EMPTY) h->used++;
	h->key[i] = k;
}

static void sw_del(sw_hash_t *h, int64_t k) {
	uint64_t i = sw_h(k) & (uint64_t)(h->cap - 1);
	while (h->key[i] != SW_EMPTY) {
		if (h->key[i] == k) { h->key[i] = SW_TOMB; return; }
		i = (i + 1) & (uint64_t)(h->cap - 1);
	}
}

static void sw_rebuild(sw_hash_t *h, const double *T, long m, long n) {
	long r;
	for (r = 0; r < h->cap; r++) h->key[r] = SW_EMPTY;
	h->used = 0;
	for (r = 0; r < m; r++) sw_add(h, (int64_t)T[3 * r] * (int64_t)(n + 1) + (int64_t)T[3 * r + 1]);
}

static int comb_swap(long n, long nties, const long *ei, const long *ej, const double *ew, long nswap, double seed) {
	double *T = NULL;
	sw_hash_t h;
	n370_rng_t rng;
	long m = nties, t, r1, r2, swaps = 0, k;
	int rc = 0;

	h.key = NULL;
	if (res_alloc(m, 3)) return 2;
	if (m < 2) {
		for (k = 0; k < m; k++) { g_res[3 * k] = (double)ei[k]; g_res[3 * k + 1] = (double)ej[k]; g_res[3 * k + 2] = ew[k]; }
		pub_a(1, 0); pub_result(0, m, 3);
		return 0;
	}
	n370_seed(&rng, seed);
	T = g_res;
	for (k = 0; k < m; k++) { T[3 * k] = (double)ei[k]; T[3 * k + 1] = (double)ej[k]; T[3 * k + 2] = ew[k]; }
	h.cap = 16;
	while (h.cap < 4 * m) h.cap *= 2;
	h.key = (int64_t *)malloc((size_t)h.cap * sizeof(int64_t));
	if (!h.key) { rc = 2; goto done; }
	sw_rebuild(&h, T, m, n);
	for (t = 1; t <= nswap; t++) {
		long a, b, c, d;
		double w1, w2;
		r1 = n370_below(&rng, m);
		r2 = n370_below(&rng, m);
		if (r1 == r2) continue;
		a = (long)T[3 * r1]; b = (long)T[3 * r1 + 1]; w1 = T[3 * r1 + 2];
		c = (long)T[3 * r2]; d = (long)T[3 * r2 + 1]; w2 = T[3 * r2 + 2];
		if (a == c || b == d) continue;
		if (sw_has(&h, (int64_t)a * (n + 1) + d)) continue;
		if (sw_has(&h, (int64_t)c * (n + 1) + b)) continue;
		sw_del(&h, (int64_t)a * (n + 1) + b);
		sw_del(&h, (int64_t)c * (n + 1) + d);
		sw_add(&h, (int64_t)a * (n + 1) + d);
		sw_add(&h, (int64_t)c * (n + 1) + b);
		T[3 * r1] = (double)a; T[3 * r1 + 1] = (double)d; T[3 * r1 + 2] = w1;
		T[3 * r2] = (double)c; T[3 * r2 + 1] = (double)b; T[3 * r2 + 2] = w2;
		swaps++;
		if (h.used > (h.cap * 3) / 4) sw_rebuild(&h, T, m, n);
	}
	pub_a(1, (double)swaps);
	pub_result(0, m, 3);
done:
	free(h.key);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 47: weighted betweenness (Brandes with Dijkstra)                  */
/* ---------------------------------------------------------------- */
typedef struct { double d; long v; } bw_hn_t;

static int bw_less(const bw_hn_t *a, const bw_hn_t *b) {
	return a->d < b->d || (a->d == b->d && a->v < b->v);
}

static void bw_push(bw_hn_t *h, long *hn, double d, long v) {
	long i = (*hn)++;
	h[i].d = d; h[i].v = v;
	while (i > 0) {
		long p = (i - 1) / 2;
		if (bw_less(&h[i], &h[p])) { bw_hn_t t = h[i]; h[i] = h[p]; h[p] = t; i = p; }
		else break;
	}
}

static bw_hn_t bw_pop(bw_hn_t *h, long *hn) {
	bw_hn_t top = h[0];
	long i = 0, n = --(*hn);
	h[0] = h[n];
	for (;;) {
		long l = 2 * i + 1, r = l + 1, m = i;
		if (l < n && bw_less(&h[l], &h[m])) m = l;
		if (r < n && bw_less(&h[r], &h[m])) m = r;
		if (m == i) break;
		{ bw_hn_t t = h[i]; h[i] = h[m]; h[m] = t; i = m; }
	}
	return top;
}

static int comb_betweenw(long n, long nties, const long *ei, const long *ej, const double *ew, double alpha, int directed) {
	long *optr = NULL, *oidx = NULL, *iptr = NULL, *pred = NULL, *npred = NULL, *order = NULL, *cur = NULL;
	double *ocost = NULL, *D = NULL, *S = NULL, *Dd = NULL, *Cb = NULL;
	unsigned char *settled = NULL;
	bw_hn_t *heap = NULL;
	long i, k, s, m = 0, nord, hn;
	int rc = 0;

	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	optr = (long *)calloc((size_t)n + 2, sizeof(long));
	iptr = (long *)calloc((size_t)n + 2, sizeof(long));
	if (!optr || !iptr) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) {
		if (ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n || ei[k] == ej[k] || !(ew[k] > 0)) continue;
		optr[ei[k]]++; iptr[ej[k]]++; m++;
	}
	{
		long ro = 0, ri = 0;
		for (i = 0; i < n; i++) {
			long co = optr[i + 1], ci = iptr[i + 1];
			optr[i] = ro; ro += co; iptr[i] = ri; ri += ci;
		}
		optr[n] = ro; iptr[n] = ri;
	}
	oidx = (long *)malloc((size_t)(m + 1) * sizeof(long));
	ocost = (double *)malloc((size_t)(m + 1) * sizeof(double));
	pred = (long *)malloc((size_t)(m + 1) * sizeof(long));
	cur = (long *)malloc((size_t)n * sizeof(long));
	npred = (long *)malloc((size_t)n * sizeof(long));
	order = (long *)malloc((size_t)n * sizeof(long));
	D = (double *)malloc((size_t)n * sizeof(double));
	S = (double *)malloc((size_t)n * sizeof(double));
	Dd = (double *)malloc((size_t)n * sizeof(double));
	Cb = (double *)calloc((size_t)n, sizeof(double));
	settled = (unsigned char *)malloc((size_t)n);
	heap = (bw_hn_t *)malloc((size_t)(m + 2) * sizeof(bw_hn_t));
	if (!oidx || !ocost || !pred || !cur || !npred || !order || !D || !S || !Dd || !Cb || !settled || !heap) { rc = 2; goto done; }
	for (i = 0; i < n; i++) cur[i] = optr[i];
	for (k = 0; k < nties; k++) {
		if (ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n || ei[k] == ej[k] || !(ew[k] > 0)) continue;
		oidx[cur[ei[k] - 1]] = ej[k] - 1;
		ocost[cur[ei[k] - 1]] = pow(ew[k], -alpha);
		cur[ei[k] - 1]++;
	}
	for (s = 0; s < n; s++) {
		for (i = 0; i < n; i++) { D[i] = -1; S[i] = 0; Dd[i] = 0; npred[i] = 0; settled[i] = 0; }
		D[s] = 0; S[s] = 1;
		nord = 0; hn = 0;
		bw_push(heap, &hn, 0.0, s);
		while (hn > 0) {
			bw_hn_t t = bw_pop(heap, &hn);
			long u = t.v;
			if (settled[u]) continue;
			settled[u] = 1;
			order[nord++] = u;
			for (k = optr[u]; k < optr[u + 1]; k++) {
				long w = oidx[k];
				double newd;
				if (settled[w]) continue;
				newd = D[u] + ocost[k];
				if (D[w] < 0 || D[w] - newd > 1e-10 * newd) {
					D[w] = newd; S[w] = 0; npred[w] = 0;
					bw_push(heap, &hn, newd, w);
				}
				if (fabs(D[w] - newd) <= 1e-10 * newd) {
					S[w] += S[u];
					pred[iptr[w] + npred[w]] = u; npred[w]++;
				}
			}
		}
		for (k = nord - 1; k >= 0; k--) {
			long w = order[k], j;
			for (j = 0; j < npred[w]; j++) {
				long v = pred[iptr[w] + j];
				Dd[v] += (S[v] / S[w]) * (1 + Dd[w]);
			}
			if (w != s) Cb[w] += Dd[w];
		}
	}
	if (res_alloc(n, 1)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) g_res[i] = directed ? Cb[i] : Cb[i] / 2;
	pub_result(0, n, 1);
done:
	free(optr); free(oidx); free(ocost); free(iptr); free(pred); free(cur); free(npred); free(order);
	free(D); free(S); free(Dd); free(Cb); free(settled); free(heap);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 48, 49: weighted distances (Dijkstra)                             */
/* ---------------------------------------------------------------- */
typedef struct { long *ptr, *idx; double *cost; long n; } dj_t;

static void dj_free(dj_t *g) { free(g->ptr); free(g->idx); free(g->cost); g->ptr = NULL; g->idx = NULL; g->cost = NULL; }

static int dj_build(dj_t *g, long n, long nties, const long *ei, const long *ej, const double *ew, double alpha) {
	long k, i, *cur;
	g->n = n; g->idx = NULL; g->cost = NULL;
	g->ptr = (long *)calloc((size_t)n + 2, sizeof(long));
	if (!g->ptr) return 2;
	for (k = 0; k < nties; k++) {
		if (ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n || ei[k] == ej[k] || !(ew[k] > 0)) continue;
		g->ptr[ei[k]]++;
	}
	{ long run = 0; for (i = 0; i < n; i++) { long c = g->ptr[i + 1]; g->ptr[i] = run; run += c; } g->ptr[n] = run; }
	g->idx = (long *)malloc((size_t)(g->ptr[n] + 1) * sizeof(long));
	g->cost = (double *)malloc((size_t)(g->ptr[n] + 1) * sizeof(double));
	cur = (long *)malloc((size_t)n * sizeof(long));
	if (!g->idx || !g->cost || !cur) { free(cur); dj_free(g); return 2; }
	for (i = 0; i < n; i++) cur[i] = g->ptr[i];
	for (k = 0; k < nties; k++) {
		if (ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n || ei[k] == ej[k] || !(ew[k] > 0)) continue;
		g->idx[cur[ei[k] - 1]] = ej[k] - 1;
		g->cost[cur[ei[k] - 1]] = pow(ew[k], -alpha);
		cur[ei[k] - 1]++;
	}
	free(cur);
	return 0;
}

/* D[0..n-1] = distance from s (-1 = unreachable); heap has room for ptr[n]+2 entries; settled is scratch */
static void dj_run(const dj_t *g, long s, double *D, bw_hn_t *heap, unsigned char *settled) {
	long i, k, hn = 0, n = g->n;
	for (i = 0; i < n; i++) { D[i] = -1; settled[i] = 0; }
	D[s] = 0;
	bw_push(heap, &hn, 0.0, s);
	while (hn > 0) {
		bw_hn_t t = bw_pop(heap, &hn);
		long u = t.v;
		if (settled[u]) continue;
		settled[u] = 1;
		for (k = g->ptr[u]; k < g->ptr[u + 1]; k++) {
			long w = g->idx[k];
			double nd = D[u] + g->cost[k];
			if (settled[w]) continue;
			if (D[w] < 0 || nd < D[w]) { D[w] = nd; bw_push(heap, &hn, nd, w); }
		}
	}
}

static int comb_distw(long n, long nties, const long *ei, const long *ej, const double *ew, double alpha, long start, long count, int block) {
	dj_t g;
	double *D = NULL;
	unsigned char *settled = NULL;
	bw_hn_t *heap = NULL;
	long s, i;
	int rc = 0;

	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	if (dj_build(&g, n, nties, ei, ej, ew, alpha)) return 2;
	D = (double *)malloc((size_t)n * sizeof(double));
	settled = (unsigned char *)malloc((size_t)n);
	heap = (bw_hn_t *)malloc((size_t)(g.ptr[n] + 2) * sizeof(bw_hn_t));
	if (!D || !settled || !heap) { rc = 2; goto done; }
	if (block) {
		if (start < 1 || count < 1 || start + count - 1 > n) { rc = 2; goto done; }
		if (res_alloc(n, count)) { rc = 2; goto done; }
		for (s = 0; s < count; s++) {
			dj_run(&g, start - 1 + s, D, heap, settled);
			for (i = 0; i < n; i++) g_res[i * count + s] = D[i] < 0 ? SV_missval : D[i];
		}
		pub_result(0, n, count);
	}
	else {
		if (res_alloc(n, 2)) { rc = 2; goto done; }
		for (s = 0; s < n; s++) {
			double sum = 0; long cnt = 0;
			dj_run(&g, s, D, heap, settled);
			for (i = 0; i < n; i++) if (i != s && D[i] >= 0) { sum += D[i]; cnt++; }
			g_res[2 * s] = sum; g_res[2 * s + 1] = (double)cnt;
		}
		pub_result(0, n, 2);
	}
done:
	free(D); free(settled); free(heap); dj_free(&g);
	return rc;
}

/* called by comb_call() for the codes 43..49 */
static int comb_n370(long alg, long n, long nties, const long *ei, const long *ej, const double *ew, const double *nv, const double *p) {
	switch (alg) {
		case ALG_LOUVBIP:   return comb_louvbip(n, nties, ei, ej, ew, nv, p[3], (long)p[4], p[5]);
		case ALG_PAGERANKW: return comb_pagerankw(n, nties, ei, ej, ew, p[3], (long)p[4], p[5]);
		case ALG_MATCHW:    return comb_matchw(n, nties, ei, ej, ew, nv);
		case ALG_SWAP:      return comb_swap(n, nties, ei, ej, ew, (long)p[3], p[4]);
		case ALG_BETWEENW:  return comb_betweenw(n, nties, ei, ej, ew, p[3], (int)p[4]);
		case ALG_DISTSUMW:  return comb_distw(n, nties, ei, ej, ew, p[3], 0, 0, 0);
		case ALG_DISTBLOCK: return comb_distw(n, nties, ei, ej, ew, p[3], (long)p[4], (long)p[5], 1);
		default: SF_error("nwgraph: unknown algorithm code\n"); return 198;
	}
}
