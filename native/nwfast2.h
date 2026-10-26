/*
	nwfast2.h -- native (C) kernels for nwpagerank (34) and nwclique (35); the second batch of fast kernels.

	#included by nwcomb.h after nwfast.h (one plugin binary); NWCOMB_VERSION 8 announces them (a plugin of
	generation 7 has another set of kernels in codes 29..33).  Wire protocol as in nwcomb.h: ties (ego,
	alter, weight) in variables 1..3, the result stays in static memory (g_res) and is copied out by the
	FETCH call (alg 99).  Status 3 = "this input is not covered, use the Mata code".

	34  pagerank   par: damping maxiter tol.  Result n x 1.  The iteration of calculate_pagerank(), with the
	               same operations in the same order (out-degree = number of stored ties of a node, mass of
	               the dangling nodes shared by all, rnew[j] += d*r[i]/outdeg[i] for i = 1..n in turn), so
	               the scores agree to the last bit except for the order in which the (few) dangling
	               nodes are summed.
	35  cliques    par: minsize.  Result: one row (clique number, node) per member of every maximal clique
	               with at least minsize members, in the order calculate_cliques() finds them
	               (BronKerboschSparse(): same pivot rule, same tie-break, same visiting order).  The
	               ties are the stored ties taken as undirected (a tie in either direction).  A stored
	               self-loop is not covered (status 3): the Mata search is not defined there either.
*/

#define ALG_PAGERANK 34
#define ALG_CLIQUES  35

/* ---------------------------------------------------------------- */
/* 34: pagerank                                                      */
/* ---------------------------------------------------------------- */
static int comb_pagerank(nwint n, nwint nties, const nwint *ei, const nwint *ej, double d, nwint maxiter, double tol) {
	csr_t O;
	double *r = NULL, *rn = NULL, *dmass_dummy = NULL;
	nwint *outd = NULL;
	nwint i, k, iter;
	int rc = 0;

	(void)dmass_dummy;
	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	if (csr_from_edges(&O, n, nties, ei, ej, NULL, 0, 0, 0)) return 2;
	r = (double *)malloc((size_t)n * sizeof(double));
	rn = (double *)malloc((size_t)n * sizeof(double));
	outd = (nwint *)malloc((size_t)n * sizeof(nwint));
	if (!r || !rn || !outd) { rc = 2; goto done; }
	for (i = 0; i < n; i++) { outd[i] = O.ptr[i + 1] - O.ptr[i]; r[i] = 1.0 / (double)n; }
	for (iter = 1; iter <= maxiter; iter++) {
		long double dm = 0.0L;
		double dangling, base, diff = 0;
		for (i = 0; i < n; i++) if (outd[i] == 0) dm += (long double)r[i];
		dangling = (double)dm;
		base = (1.0 - d) / (double)n + d * dangling / (double)n;
		for (i = 0; i < n; i++) rn[i] = base;
		for (i = 0; i < n; i++) {
			double share;
			if (outd[i] == 0) continue;
			share = d * r[i] / (double)outd[i];
			for (k = O.ptr[i]; k < O.ptr[i + 1]; k++) rn[O.idx[k]] = rn[O.idx[k]] + share;
		}
		for (i = 0; i < n; i++) {
			double a = fabs(rn[i] - r[i]);
			if (a > diff) diff = a;
		}
		{ double *sw = r; r = rn; rn = sw; }
		if (diff < tol) break;
	}
	if (res_alloc(n, 1)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) g_res[i] = r[i];
	pub_result(0, n, 1);
done:
	free(r); free(rn); free(outd);
	csr_free(&O);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 35: maximal cliques                                               */
/* ---------------------------------------------------------------- */
typedef struct {
	nwint n;
	const nwint *ptr, *idx;      /* symmetric, sorted, loop-free neighbour lists, 0-based */
	nwint minsize;
	nwint *mk; nwint mkstamp;     /* marker with stamps (no clearing) */
	nwint *xl, *xt;              /* membership of the current X lists: level token, position */
	nwint level;                 /* last level token handed out */
	nwint *R; nwint rlen;         /* the current clique */
	nwint *out; nwint outlen, outcap; nwint ncl;
	nwint *ulog; nwint ulen, ucap; /* undo log of xl/xt writes: (node, old xl, old xt) */
	int oom;
} qbk_t;

static int qbk_isnb(const qbk_t *b, nwint u, nwint w) {
	nwint lo = b->ptr[u], hi = b->ptr[u + 1] - 1;
	while (lo <= hi) {
		nwint mid = (lo + hi) / 2;
		nwint x = b->idx[mid];
		if (x == w) return 1;
		if (x < w) lo = mid + 1; else hi = mid - 1;
	}
	return 0;
}

static int qbk_push_out(qbk_t *b, nwint v) {
	if (b->outlen == b->outcap) {
		nwint nc = b->outcap ? b->outcap * 2 : 1024;
		nwint *p = (nwint *)realloc(b->out, (size_t)nc * sizeof(nwint));
		if (!p) return 1;
		b->out = p; b->outcap = nc;
	}
	b->out[b->outlen++] = v;
	return 0;
}

static int qbk_log(qbk_t *b, nwint w) {
	if (b->ulen + 3 > b->ucap) {
		nwint nc = b->ucap ? b->ucap * 2 : 3072;
		nwint *p = (nwint *)realloc(b->ulog, (size_t)nc * sizeof(nwint));
		if (!p) return 1;
		b->ulog = p; b->ucap = nc;
	}
	b->ulog[b->ulen++] = w; b->ulog[b->ulen++] = b->xl[w]; b->ulog[b->ulen++] = b->xt[w];
	return 0;
}

typedef struct { nwint t, w; } qbk_pair_t;
static int qbk_paircmp(const void *a, const void *b) {
	nwint x = ((const qbk_pair_t *)a)->t, y = ((const qbk_pair_t *)b)->t;
	return (x > y) - (x < y);
}

/* P: ascending node ids, np entries (with "alive" flags); X: list in insertion order, nx entries, room for xcap */
static void qbk_search(qbk_t *b, nwint *P, unsigned char *alive, nwint np, nwint *X, nwint nx, nwint xcap) {
	nwint i, k, v, u, best, cnt, level = 0, ulog0 = 0, nalive, nbranch, *branch = NULL, *bidx = NULL;
	nwint *nP = NULL, *nX = NULL; 
	qbk_pair_t *pairs = NULL;
	nwint stamp;

	if (b->oom) return;
	if (np == 0 && nx == 0) {
		if (b->rlen >= b->minsize) {
			b->ncl++;
			for (i = 0; i < b->rlen; i++)
				if (qbk_push_out(b, b->ncl) || qbk_push_out(b, b->R[i] + 1)) { b->oom = 1; return; }
		}
		return;
	}
	/* pivot: first node of P then X with the most neighbours in P */
	stamp = ++b->mkstamp;
	for (i = 0; i < np; i++) b->mk[P[i]] = stamp;
	best = -1; u = 0;
	for (i = 0; i < np + nx; i++) {
		v = i < np ? P[i] : X[i - np];
		cnt = 0;
		for (k = b->ptr[v]; k < b->ptr[v + 1]; k++) if (b->mk[b->idx[k]] == stamp) cnt++;
		if (cnt > best) { best = cnt; u = v; }
	}
	/* branch: the members of P that are not neighbours of the pivot */
	stamp = ++b->mkstamp;
	for (k = b->ptr[u]; k < b->ptr[u + 1]; k++) b->mk[b->idx[k]] = stamp;
	branch = (nwint *)malloc((size_t)(np > 0 ? np : 1) * sizeof(nwint));
	bidx = (nwint *)malloc((size_t)(np > 0 ? np : 1) * sizeof(nwint));
	if (!branch || !bidx) { b->oom = 1; goto done; }
	nbranch = 0;
	for (i = 0; i < np; i++) if (b->mk[P[i]] != stamp) { branch[nbranch] = P[i]; bidx[nbranch] = i; nbranch++; }
	/* the X membership of this level, for the intersections that walk the neighbours of v */
	level = ++b->level;
	ulog0 = b->ulen;
	for (i = 0; i < nx; i++) {
		if (qbk_log(b, X[i])) { b->oom = 1; goto done; }
		b->xl[X[i]] = level; b->xt[X[i]] = i + 1;
	}
	nalive = np;
	for (i = 0; i < nbranch; i++) {
		nwint dv, m, px;
		v = branch[i];
		dv = b->ptr[v + 1] - b->ptr[v];
		/* newP = P (current) intersect N(v), ascending */
		nP = (nwint *)malloc((size_t)((nalive < dv ? nalive : dv) + 1) * sizeof(nwint));
		/* newX = X intersect N(v), in X order */
		nX = (nwint *)malloc((size_t)((nx < dv ? nx : dv) + 1) * sizeof(nwint));
		if (!nP || !nX) { free(nP); free(nX); nP = nX = NULL; b->oom = 1; goto done; }
		m = 0;
		if (np <= dv * 4) {
			for (k = 0; k < np; k++) if (alive[k] && qbk_isnb(b, v, P[k])) nP[m++] = P[k];
		}
		else {
			for (k = b->ptr[v]; k < b->ptr[v + 1]; k++) {
				nwint w = b->idx[k], lo = 0, hi = np - 1;
				while (lo <= hi) {
					nwint mid = (lo + hi) / 2;
					if (P[mid] == w) { if (alive[mid]) nP[m++] = w; break; }
					if (P[mid] < w) lo = mid + 1; else hi = mid - 1;
				}
			}
		}
		px = m;
		m = 0;
		if (nx <= dv * 4) {
			for (k = 0; k < nx; k++) if (qbk_isnb(b, v, X[k])) nX[m++] = X[k];
		}
		else {
			pairs = (qbk_pair_t *)malloc((size_t)(dv + 1) * sizeof(qbk_pair_t));
			if (!pairs) { free(nP); free(nX); nP = nX = NULL; b->oom = 1; goto done; }
			for (k = b->ptr[v]; k < b->ptr[v + 1]; k++) {
				nwint w = b->idx[k];
				if (b->xl[w] == level) { pairs[m].t = b->xt[w]; pairs[m].w = w; m++; }
			}
			qsort(pairs, (size_t)m, sizeof(qbk_pair_t), qbk_paircmp);
			for (k = 0; k < m; k++) nX[k] = pairs[k].w;
			free(pairs); pairs = NULL;
		}
		/* the child: its P is all alive, its X has room for the nodes it will append */
		{
			nwint cx = m, *nXc;
			unsigned char *ca;
			nwint clen = px;
			nXc = (nwint *)realloc(nX, (size_t)(cx + clen + 1) * sizeof(nwint));
			ca = (unsigned char *)malloc((size_t)(clen > 0 ? clen : 1));
			if (!nXc || !ca) { if (nXc) nX = nXc; free(nP); free(nX); free(ca); nP = nX = NULL; b->oom = 1; goto done; }
			nX = nXc;
			memset(ca, 1, (size_t)(clen > 0 ? clen : 1));
			b->R[b->rlen++] = v;
			qbk_search(b, nP, ca, clen, nX, cx, cx + clen);
			b->rlen--;
			free(ca);
		}
		free(nP); free(nX); nP = nX = NULL;
		if (b->oom) goto done;
		/* P = P \ v ; X = X, v */
		alive[bidx[i]] = 0;
		nalive--;
		if (nx >= xcap) { b->oom = 1; goto done; }
		if (qbk_log(b, v)) { b->oom = 1; goto done; }
		X[nx] = v; nx++;
		b->xl[v] = level; b->xt[v] = nx;
	}
done:
	/* undo the membership writes of this level, newest first */
	while (b->ulen > ulog0 && level) {
		b->ulen -= 3;
		{
			nwint w = b->ulog[b->ulen];
			b->xl[w] = b->ulog[b->ulen + 1];
			b->xt[w] = b->ulog[b->ulen + 2];
		}
	}
	free(branch); free(bidx);
}

static int comb_cliques(nwint n, nwint nties, const nwint *ei, const nwint *ej, nwint minsize) {
	nwint m2 = 2 * nties, k, i, j, w;
	nwint *R = NULL, *C = NULL, *perm = NULL, *ptr = NULL, *idx = NULL;
	nwint *P = NULL;
	unsigned char *alive = NULL;
	qbk_t b;
	int rc = 0;

	memset(&b, 0, sizeof(b));
	for (k = 0; k < nties; k++) if (ei[k] == ej[k]) { pub_result(3, 0, 0); return 0; }
	R = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	C = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	if (!R || !C) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) { R[2 * k] = ei[k]; C[2 * k] = ej[k]; R[2 * k + 1] = ej[k]; C[2 * k + 1] = ei[k]; }
	perm = fast_sort_rc(n, m2, R, C);
	if (m2 > 0 && !perm) { rc = 2; goto done; }
	ptr = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	idx = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	if (!ptr || !idx) { rc = 2; goto done; }
	/* sorted by (row, col); drop duplicates */
	j = 0;
	for (i = 0; i < m2; i++) {
		nwint q = perm[i];
		if (j > 0 && R[q] == R[perm[i - 1]] && C[q] == C[perm[i - 1]]) continue;
		idx[j++] = C[q] - 1;
		ptr[R[q]]++;
	}
	{
		nwint run = 0;
		for (i = 0; i < n; i++) { nwint c = ptr[i + 1]; ptr[i] = run; run += c; }
		ptr[n] = run;
	}
	b.n = n; b.ptr = ptr; b.idx = idx; b.minsize = minsize;
	b.mk = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	b.xl = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	b.xt = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	b.R = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	P = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	alive = (unsigned char *)malloc((size_t)(n > 0 ? n : 1));
	if (!b.mk || !b.xl || !b.xt || !b.R || !P || !alive) { rc = 2; goto done; }
	for (i = 0; i < n; i++) { P[i] = i; alive[i] = 1; }
	{
		nwint *X0 = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
		if (!X0) { rc = 2; goto done; }
		qbk_search(&b, P, alive, n, X0, 0, n);
		free(X0);
	}
	if (b.oom) { rc = 2; goto done; }
	if (res_alloc(b.outlen / 2, 2)) { rc = 2; goto done; }
	for (w = 0; w < b.outlen / 2; w++) { g_res[2 * w] = (double)b.out[2 * w]; g_res[2 * w + 1] = (double)b.out[2 * w + 1]; }
	pub_a(1, (double)b.ncl);
	pub_result(0, b.outlen / 2, 2);
done:
	free(R); free(C); free(perm); free(ptr); free(idx); free(P); free(alive);
	free(b.mk); free(b.xl); free(b.xt); free(b.R); free(b.out); free(b.ulog);
	return rc;
}


/* ---------------------------------------------------------------- */
/* 2-connectivity search of nwkcomponents (k = 2), used by kconn_search() in nwgraph.c (algorithm 20)
   instead of its n flow queries.  The queries of the flow search have a known answer for target 2:
   for a pair s,t that is not adjacent, the number of internally vertex-disjoint paths (capped at 2) is
   0 when t is not in the component of s, 1 when it is but s and t share no biconnected block, and 2
   when they share a block.  The blocks come from one depth-first search (Tarjan, iterative).  The
   queries are then walked in the order of kconn_search() (v0 to every non-neighbour in node order,
   then the non-adjacent pairs of the neighbours of v0 in list order) and the first with a flow below
   2 is reported, so the result (minflow, best_s, best_t) is the same as that of the flow queries.
   Returns 1 when handled (results in *mf, *bs, *bt), 0 when the input is not covered (a self-loop: the
   caller runs the flow search), 2 when out of memory.
   ---------------------------------------------------------------- */
static int kconn2_search(nwint n, const nwint *ei, const nwint *ej, nwint m, nwint delta, nwint v0, nwint *mf, nwint *bs, nwint *bt) {
	nwint e, i, j, k, v, w, nb = 0, top, ntop;
	nwint *ptr = NULL, *adj = NULL, *cur = NULL, *disc = NULL, *low = NULL, *par = NULL, *it = NULL;
	nwint *stk = NULL, *sa = NULL, *sb = NULL, *bhead = NULL, *bnext = NULL, *bid = NULL, *last = NULL, *bmark = NULL;
	nwint nbl = 0, nmem = 0, cnt = 0, minflow = delta, best_s = 0, best_t = 0, firstq_s = 0, firstq_t = 0, counter = 0;
	char *isnb = NULL, *isnb2 = NULL;
	int rc = 1;

	for (e = 0; e < m; e++) if (ei[e] == ej[e]) return 0;
	ptr = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	adj = (nwint *)malloc((size_t)(m > 0 ? m : 1) * sizeof(nwint));
	cur = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	disc = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	low = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	par = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	it = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	stk = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	sa = (nwint *)malloc((size_t)(m + 1) * sizeof(nwint));
	sb = (nwint *)malloc((size_t)(m + 1) * sizeof(nwint));
	bhead = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	bnext = (nwint *)malloc((size_t)(2 * n + 4) * sizeof(nwint));
	bid = (nwint *)malloc((size_t)(2 * n + 4) * sizeof(nwint));
	last = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	bmark = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	isnb = (char *)calloc((size_t)(n + 2), 1);
	isnb2 = (char *)calloc((size_t)(n + 2), 1);
	if (!ptr || !adj || !cur || !disc || !low || !par || !it || !stk || !sa || !sb || !bhead || !bnext || !bid || !last || !bmark || !isnb || !isnb2) { rc = 2; goto out; }
	for (e = 0; e < m; e++) ptr[ei[e] + 1]++;
	for (i = 1; i <= n + 1; i++) ptr[i] += ptr[i - 1];    /* arcs of node v (1-based): ptr[v] .. ptr[v+1]-1 */
	for (i = 1; i <= n; i++) cur[i] = ptr[i];
	for (e = 0; e < m; e++) adj[cur[ei[e]]++] = ej[e];
	for (i = 0; i <= n + 1; i++) { bhead[i] = -1; last[i] = -1; }

	/* depth-first search from v0, biconnected blocks by an edge stack */
	top = 0; ntop = 0;
	stk[top++] = v0; disc[v0] = low[v0] = ++counter; par[v0] = 0; it[v0] = ptr[v0];
	while (top > 0) {
		v = stk[top - 1];
		if (it[v] < ptr[v + 1]) {
			w = adj[it[v]++];
			if (w == par[v]) continue;
			if (!disc[w]) {
				sa[ntop] = v; sb[ntop] = w; ntop++;
				par[w] = v; disc[w] = low[w] = ++counter; it[w] = ptr[w];
				stk[top++] = w;
			}
			else if (disc[w] < disc[v]) {
				sa[ntop] = v; sb[ntop] = w; ntop++;
				if (disc[w] < low[v]) low[v] = disc[w];
			}
		}
		else {
			top--;
			if (top > 0) {
				nwint u = stk[top - 1];
				if (low[v] < low[u]) low[u] = low[v];
				if (low[v] >= disc[u]) {
					/* a block closes at u: pop its edges down to (u, v) */
					nbl++;
					while (ntop > 0) {
						nwint a, b, x2;
						ntop--;
						a = sa[ntop]; b = sb[ntop];
						for (x2 = 0; x2 < 2; x2++) {
							nwint z = x2 ? b : a;
							if (last[z] != nbl) {
								last[z] = nbl;
								bnext[nmem] = bhead[z]; bid[nmem] = nbl; bhead[z] = nmem; nmem++;
							}
						}
						if (a == u && b == v) break;
					}
				}
			}
		}
	}
	/* the queries in the order of the flow search */
	{
		nwint nv0 = ptr[v0 + 1] - ptr[v0];
		const nwint *nbv0 = adj + ptr[v0];
		nwint stampc = 0;
		for (i = 0; i < nv0; i++) isnb[nbv0[i]] = 1;
		/* blocks of v0 */
		for (k = bhead[v0]; k >= 0; k = bnext[k]) bmark[bid[k]] = 1;
		for (i = 1; i <= n; i++) {
			nwint f;
			if (i == v0 || isnb[i]) continue;
			if (!disc[i]) f = 0;
			else {
				f = 1;
				for (k = bhead[i]; k >= 0; k = bnext[k]) if (bmark[bid[k]]) { f = 2; break; }
			}
			cnt++;
			if (cnt == 1) { firstq_s = v0; firstq_t = i; }
			if (f < minflow) { minflow = f; best_s = v0; best_t = i; }
			if (minflow < 2) goto out;
		}
		for (k = bhead[v0]; k >= 0; k = bnext[k]) bmark[bid[k]] = 0;
		/* non-adjacent pairs among the neighbours of v0 */
		for (i = 0; i < nv0 && !(minflow < 2); i++) {
			nwint ni = nbv0[i];
			stampc++;
			for (e = ptr[ni]; e < ptr[ni + 1]; e++) isnb2[adj[e]] = 1;
			for (k = bhead[ni]; k >= 0; k = bnext[k]) bmark[bid[k]] = stampc;
			for (j = i + 1; j < nv0 && !(minflow < 2); j++) {
				nwint nj = nbv0[j], f = 1;
				if (isnb2[nj]) continue;
				for (k = bhead[nj]; k >= 0; k = bnext[k]) if (bmark[bid[k]] == stampc) { f = 2; break; }
				cnt++;
				if (cnt == 1) { firstq_s = ni; firstq_t = nj; }
				if (f < minflow) { minflow = f; best_s = ni; best_t = nj; }
			}
			for (e = ptr[ni]; e < ptr[ni + 1]; e++) isnb2[adj[e]] = 0;
		}
	}
out:
	if (rc == 1) { *mf = minflow; *bs = best_s; *bt = best_t; }
	(void)nb; (void)firstq_s; (void)firstq_t;
	free(ptr); free(adj); free(cur); free(disc); free(low); free(par); free(it); free(stk); free(sa); free(sb);
	free(bhead); free(bnext); free(bid); free(last); free(bmark); free(isnb); free(isnb2);
	return rc;
}

/* called by comb_call() for the codes 34..39 */
static int comb_fast2(nwint alg, nwint n, nwint nties, const nwint *ei, const nwint *ej, const double *ew, const double *nv, const double *p) {
	(void)ew; (void)nv;
	switch (alg) {
		case ALG_PAGERANK: return comb_pagerank(n, nties, ei, ej, p[3], (nwint)p[4], p[5]);
		case ALG_CLIQUES:  return comb_cliques(n, nties, ei, ej, (nwint)p[3]);
		default: SF_error("nwgraph: unknown algorithm code\n"); return 198;
	}
}
