/*
	nwcomb2.h -- exhaustive subgroup searches on bitset adjacency, included by
	nwcomb.h: maximal n-cliques (Bron-Kerbosch with the same pivot rule as the
	Mata BronKerbosch()), n-clans (the maximal n-cliques that also have
	diameter <= n inside the group) and maximal k-plexes (a port of the Mata
	KPlex() with an incremental validity test).

	The search orders are those of the Mata routines, so the maximal sets come
	out in the same order. A cap on the number of sets kept (status 1) protects
	against the exponential output these problems can have.
*/

#include <time.h>

typedef struct {
	long n, W;
	uint64_t *adj;          /* n rows of W words */
	long minsize, maxcnt;
	int countonly, clan, steps;
	const csr_t *sym;       /* undirected simple graph for the n-clan diameter check */
	ilist_t members;        /* flat members of the kept sets (each set ascending) */
	ilist_t sizes;          /* size of each kept set */
	long count, maxsize;
	double work, maxwork;   /* recursive calls made; CPU seconds allowed (0 = no limit) */
	clock_t t0;
	double examined;        /* maximal n-cliques looked at (n-clan search) */
	long *hist;             /* size histogram, n+2 */
	long *R, rlen;
	long *degR;             /* k-plex: members of R adjacent to each node */
	long k;
	uint64_t **Pb, **Xb, **Cb;
	long nbuf;
	char *inset;            /* scratch for the clan check */
	long *dist, *queue;
	int abort;
} bk_t;

static int bk_level(bk_t *b, long d) {
	long i, W = b->W;
	if (d >= b->nbuf) {
		long nn = b->nbuf ? b->nbuf * 2 : 16;
		uint64_t **p;
		while (nn <= d) nn *= 2;
		p = (uint64_t **)realloc(b->Pb, (size_t)nn * sizeof(*p)); if (!p) return 1; b->Pb = p;
		p = (uint64_t **)realloc(b->Xb, (size_t)nn * sizeof(*p)); if (!p) return 1; b->Xb = p;
		p = (uint64_t **)realloc(b->Cb, (size_t)nn * sizeof(*p)); if (!p) return 1; b->Cb = p;
		for (i = b->nbuf; i < nn; i++) { b->Pb[i] = NULL; b->Xb[i] = NULL; b->Cb[i] = NULL; }
		b->nbuf = nn;
	}
	for (i = 0; i <= d; i++) {
		if (!b->Pb[i]) {
			b->Pb[i] = (uint64_t *)malloc((size_t)W * sizeof(uint64_t));
			b->Xb[i] = (uint64_t *)malloc((size_t)W * sizeof(uint64_t));
			b->Cb[i] = (uint64_t *)malloc((size_t)W * sizeof(uint64_t));
			if (!b->Pb[i] || !b->Xb[i] || !b->Cb[i]) return 1;
		}
	}
	return 0;
}

static void bk_free(bk_t *b) {
	long i;
	for (i = 0; i < b->nbuf; i++) { free(b->Pb[i]); free(b->Xb[i]); free(b->Cb[i]); }
	free(b->Pb); free(b->Xb); free(b->Cb);
	free(b->adj); free(b->hist); free(b->R); free(b->degR); free(b->inset); free(b->dist); free(b->queue);
	il_free(&b->members); il_free(&b->sizes);
}

static int cmp_long(const void *a, const void *b) {
	long x = *(const long *)a, y = *(const long *)b;
	return (x > y) - (x < y);
}

/* every pair of the (sorted) members is joined by a path of <= steps inside the set */
static int clan_ok(bk_t *b, const long *mem, long s) {
	long i, qh, qt, u, k, v, reached;
	const csr_t *G = b->sym;
	if (s <= 1) return 1;
	for (i = 0; i < s; i++) b->inset[mem[i]] = 1;
	for (i = 0; i < s; i++) {
		long src = mem[i];
		for (k = 0; k < s; k++) b->dist[mem[k]] = -1;
		b->dist[src] = 0;
		qh = 0; qt = 0;
		b->queue[qt++] = src;
		reached = 1;
		while (qh < qt) {
			u = b->queue[qh++];
			if (b->dist[u] >= b->steps) continue;
			for (k = G->ptr[u]; k < G->ptr[u + 1]; k++) {
				v = G->idx[k];
				if (b->inset[v] && b->dist[v] < 0) {
					b->dist[v] = b->dist[u] + 1;
					b->queue[qt++] = v;
					reached++;
				}
			}
		}
		if (reached < s) {
			for (k = 0; k < s; k++) { b->inset[mem[k]] = 0; b->dist[mem[k]] = -1; }
			return 0;
		}
	}
	for (i = 0; i < s; i++) { b->inset[mem[i]] = 0; b->dist[mem[i]] = -1; }
	return 1;
}

static void bk_report(bk_t *b) {
	long s = b->rlen, i;
	long *tmp;
	if (s < b->minsize) return;
	b->examined += 1;
	if (b->clan && b->examined > (double)b->maxcnt) { b->abort = 1; return; }
	tmp = (long *)malloc((size_t)(s > 0 ? s : 1) * sizeof(long));
	if (!tmp) { b->abort = 2; return; }
	memcpy(tmp, b->R, (size_t)s * sizeof(long));
	qsort(tmp, (size_t)s, sizeof(long), cmp_long);
	if (b->clan && !clan_ok(b, tmp, s)) { free(tmp); return; }
	b->count++;
	if (s > b->maxsize) b->maxsize = s;
	b->hist[s]++;
	if (!b->countonly) {
		if (b->count > b->maxcnt || b->members.len + s > 400000000L) { b->abort = 1; free(tmp); return; }
		for (i = 0; i < s; i++) if (il_push(&b->members, tmp[i])) { b->abort = 2; break; }
		if (il_push(&b->sizes, s)) b->abort = 2;
	}
	free(tmp);
}

static int any_bits(const uint64_t *x, long W) {
	long i;
	for (i = 0; i < W; i++) if (x[i]) return 1;
	return 0;
}

/* true when the branch whose state sits in the level-d buffers cannot produce a reportable set */
static int bk_dead(bk_t *b, long d) {
	long W = b->W, t, pc = 0, i, k, qh, qt, u, w, reached, need;
	uint64_t *P = b->Pb[d];
	const csr_t *G = b->sym;
	long v;
	for (t = 0; t < W; t++) pc += popc64(P[t]);
	if (b->rlen + pc < b->minsize) return 1;
	if (!b->clan || b->rlen < 2) return 0;
	/* inset = R + candidates */
	for (i = 0; i < b->rlen; i++) b->inset[b->R[i]] = 1;
	for (t = 0; t < W; t++) {
		uint64_t bits = P[t];
		while (bits) { b->inset[t * 64 + ctz64(bits)] = 1; bits &= bits - 1; }
	}
	v = b->R[b->rlen - 1];
	qh = 0; qt = 0;
	b->queue[qt++] = v;
	b->dist[v] = 0;
	reached = 0;
	need = b->rlen - 1;
	while (qh < qt) {
		u = b->queue[qh++];
		if (b->dist[u] >= b->steps) continue;
		for (k = G->ptr[u]; k < G->ptr[u + 1]; k++) {
			w = G->idx[k];
			if (b->inset[w] && b->dist[w] < 0) { b->dist[w] = b->dist[u] + 1; b->queue[qt++] = w; }
		}
	}
	for (i = 0; i < b->rlen - 1; i++) if (b->dist[b->R[i]] >= 0) reached++;
	for (i = 0; i < qt; i++) b->dist[b->queue[i]] = -1;
	for (i = 0; i < b->rlen; i++) b->inset[b->R[i]] = 0;
	for (t = 0; t < W; t++) {
		uint64_t bits = P[t];
		while (bits) { b->inset[t * 64 + ctz64(bits)] = 0; bits &= bits - 1; }
	}
	return reached < need;
}

/* Bron-Kerbosch with pivoting, identical choices to BronKerbosch() in unw_core.do */
static void bk_rec(bk_t *b, long d) {
	long W = b->W, w, v, u, best, cnt;
	uint64_t *P = b->Pb[d], *X = b->Xb[d], *B = b->Cb[d];
	uint64_t bits;
	if (b->abort) return;
	b->work += 1;
	if (b->maxwork > 0 && (((long)b->work) & 15) == 0 && (double)(clock() - b->t0) / CLOCKS_PER_SEC > b->maxwork) { b->abort = 3; return; }
	if (!any_bits(P, W) && !any_bits(X, W)) { bk_report(b); return; }
	best = -1; u = -1;
	for (w = 0; w < W; w++) {
		bits = P[w] | X[w];
		while (bits) {
			long t, c2 = 0;
			v = w * 64 + ctz64(bits);
			bits &= bits - 1;
			for (t = 0; t < W; t++) c2 += popc64(P[t] & b->adj[v * W + t]);
			cnt = c2;
			if (cnt > best) { best = cnt; u = v; }
		}
	}
	for (w = 0; w < W; w++) B[w] = P[w] & ~b->adj[u * W + w];
	for (w = 0; w < W; w++) {
		bits = B[w];
		while (bits) {
			long t;
			v = w * 64 + ctz64(bits);
			bits &= bits - 1;
			if (bk_level(b, d + 1)) { b->abort = 2; return; }
			P = b->Pb[d]; X = b->Xb[d];
			for (t = 0; t < W; t++) {
				b->Pb[d + 1][t] = P[t] & b->adj[v * W + t];
				b->Xb[d + 1][t] = X[t] & b->adj[v * W + t];
			}
			b->R[b->rlen++] = v;
			/* a branch whose candidates cannot reach the minimum size would only report sets that are
			   filtered out; for n-clans a branch is dead when some member of R is farther than n steps
			   from the new member inside R + candidates (distances only grow in the subsets a clan
			   below this branch can be). Neither skip changes the sets reported. */
			if (!bk_dead(b, d + 1)) bk_rec(b, d + 1);
			b->rlen--;
			if (b->abort) return;
			P[v >> 6] &= ~(1ULL << (v & 63));
			X[v >> 6] |= (1ULL << (v & 63));
		}
	}
}

/* k-plex search, same visiting order as KPlex() in unw_core.do */
static void kp_rec(bk_t *b, long d, const csr_t *G) {
	long W = b->W, w, v, s1, thr, t, r, nb, k = b->k;
	uint64_t *P = b->Pb[d], *X = b->Xb[d], *C = b->Cb[d];
	uint64_t bits;
	uint64_t *nP, *nX;
	if (b->abort) return;
	b->work += 1;
	if (b->maxwork > 0 && (((long)b->work) & 15) == 0 && (double)(clock() - b->t0) / CLOCKS_PER_SEC > b->maxwork) { b->abort = 3; return; }
	if (!any_bits(P, W) && !any_bits(X, W)) { bk_report(b); return; }
	for (t = 0; t < W; t++) C[t] = P[t];       /* the candidates to branch on: P as it was on entry */
	for (w = 0; w < W; w++) {
		bits = C[w];
		while (bits) {
			long pc = 0;
			v = w * 64 + ctz64(bits);
			bits &= bits - 1;
			if (bk_level(b, d + 1)) { b->abort = 2; return; }
			P = b->Pb[d]; X = b->Xb[d];
			nP = b->Pb[d + 1]; nX = b->Xb[d + 1];
			b->R[b->rlen++] = v;
			for (nb = G->ptr[v]; nb < G->ptr[v + 1]; nb++) b->degR[G->idx[nb]]++;
			s1 = b->rlen;
			thr = s1 + 1 - k;
			for (t = 0; t < W; t++) { nP[t] = P[t]; nX[t] = X[t]; }
			nP[v >> 6] &= ~(1ULL << (v & 63));
			nX[v >> 6] &= ~(1ULL << (v & 63));
			for (r = 0; r < s1; r++) {
				long m = b->R[r];
				if (b->degR[m] < thr) {          /* tight member: every newcomer has to be tied to it */
					for (t = 0; t < W; t++) { nP[t] &= b->adj[m * W + t]; nX[t] &= b->adj[m * W + t]; }
				}
			}
			if (thr > 0) {
				for (t = 0; t < W; t++) {
					uint64_t bb = nP[t];
					while (bb) {
						long u = t * 64 + ctz64(bb);
						bb &= bb - 1;
						if (b->degR[u] < thr) nP[t] &= ~(1ULL << (u & 63));
					}
					bb = nX[t];
					while (bb) {
						long u = t * 64 + ctz64(bb);
						bb &= bb - 1;
						if (b->degR[u] < thr) nX[t] &= ~(1ULL << (u & 63));
					}
				}
			}
			for (t = 0; t < W; t++) pc += popc64(nP[t]);
			/* a branch that cannot reach the minimum size would only report sets that are filtered out */
			if (s1 + pc >= b->minsize)
				kp_rec(b, d + 1, G);
			b->rlen--;
			for (nb = G->ptr[v]; nb < G->ptr[v + 1]; nb++) b->degR[G->idx[nb]]--;
			if (b->abort) return;
			P[v >> 6] &= ~(1ULL << (v & 63));
			X[v >> 6] |= (1ULL << (v & 63));
		}
	}
}

static int bk_setup(bk_t *b, long n) {
	long i;
	memset(b, 0, sizeof(*b));
	b->t0 = clock();
	b->n = n;
	b->W = (n + 63) / 64;
	if (b->W < 1) b->W = 1;
	b->adj = (uint64_t *)calloc((size_t)n * (size_t)b->W + 1, sizeof(uint64_t));
	b->hist = (long *)calloc((size_t)n + 2, sizeof(long));
	b->R = (long *)malloc((size_t)n * sizeof(long) + 8);
	b->degR = (long *)calloc((size_t)n + 1, sizeof(long));
	b->inset = (char *)calloc((size_t)n + 1, 1);
	b->dist = (long *)malloc((size_t)n * sizeof(long) + 8);
	b->queue = (long *)malloc((size_t)n * sizeof(long) + 8);
	if (!b->adj || !b->hist || !b->R || !b->degR || !b->inset || !b->dist || !b->queue) return 1;
	for (i = 0; i < n; i++) b->dist[i] = -1;
	return 0;
}

/* publishes the kept sets */
static int bk_finish(bk_t *b) {
	long i, j, r, pos = 0;
	if (b->abort == 1 || b->abort == 3) {
		pub_a(1, (double)(b->clan ? b->examined : b->count));
		pub_a(3, b->work);
		pub_result(b->abort, 0, 0);          /* 1 = result limit, 3 = work limit */
		return 0;
	}
	if (b->abort) return 2;
	if (b->countonly) {
		long rows = 0;
		for (i = 0; i <= b->n; i++) if (b->hist[i]) rows++;
		if (res_alloc(rows, 2)) return 2;
		r = 0;
		for (i = 0; i <= b->n; i++) if (b->hist[i]) { g_res[r * 2] = (double)i; g_res[r * 2 + 1] = (double)b->hist[i]; r++; }
		pub_result(0, rows, 2);
	}
	else {
		if (res_alloc(b->members.len, 2)) return 2;
		r = 0;
		for (i = 0; i < b->sizes.len; i++) {
			for (j = 0; j < b->sizes.a[i]; j++) {
				g_res[r * 2] = (double)(i + 1);
				g_res[r * 2 + 1] = (double)(b->members.a[pos++] + 1);
				r++;
			}
		}
		pub_result(0, b->members.len, 2);
	}
	pub_a(1, (double)b->count);
	pub_a(2, (double)b->maxsize);
	pub_a(3, b->work);
	return 0;
}

/* p[3] steps, p[4] minsize, p[5] maxcliques, p[6] countonly, p[7] clan, p[8] maxtime (CPU seconds).
   ties: directed out-ties; ew > 0 selects the ones that count (like the native distance kernel) */
static int comb_nclique(long n, long nties, const long *ei, const long *ej, const double *ew, const double *p) {
	csr_t G, S;
	bk_t b;
	long i, k, v, qh, qt, steps = (long)p[3], w;
	long *dist, *queue;
	int rc;
	memset(&S, 0, sizeof(S));
	if (csr_from_edges(&G, n, nties, ei, ej, ew, 1, 1, 0)) return 2;
	if (bk_setup(&b, n)) { bk_free(&b); csr_free(&G); return 2; }
	b.minsize = (long)p[4]; b.maxcnt = (long)p[5]; b.countonly = (int)p[6]; b.clan = (int)p[7]; b.steps = (int)steps; b.maxwork = p[8];
	if (b.clan) {
		/* the undirected simple graph of the same ties */
		long *si = (long *)malloc((size_t)(2 * nties + 1) * sizeof(long));
		long *sj = (long *)malloc((size_t)(2 * nties + 1) * sizeof(long));
		long m2 = 0;
		for (i = 0; i < nties; i++) if (ew[i] > 0 && ei[i] != ej[i]) {
			si[m2] = ei[i]; sj[m2] = ej[i]; m2++;
			si[m2] = ej[i]; sj[m2] = ei[i]; m2++;
		}
		/* sort pairs and drop duplicates through a stable two-pass counting sort (by alter, then by ego) */
		{
			long *cnt = (long *)calloc((size_t)n + 2, sizeof(long));
			long *oi = (long *)malloc((size_t)(m2 + 1) * sizeof(long));
			long *oj = (long *)malloc((size_t)(m2 + 1) * sizeof(long));
			long *ti = (long *)malloc((size_t)(m2 + 1) * sizeof(long));
			long *tj = (long *)malloc((size_t)(m2 + 1) * sizeof(long));
			long j2, last_i = -1, last_j = -1, mm = 0;
			if (!cnt || !oi || !oj || !ti || !tj) { free(cnt); free(oi); free(oj); free(ti); free(tj); free(si); free(sj); bk_free(&b); csr_free(&G); return 2; }
			for (j2 = 0; j2 < m2; j2++) cnt[sj[j2]]++;
			for (j2 = 1; j2 <= n + 1; j2++) cnt[j2] += cnt[j2 - 1];
			for (j2 = m2 - 1; j2 >= 0; j2--) { long pos2 = --cnt[sj[j2]]; ti[pos2] = si[j2]; tj[pos2] = sj[j2]; }
			memset(cnt, 0, (size_t)(n + 2) * sizeof(long));
			for (j2 = 0; j2 < m2; j2++) cnt[ti[j2]]++;
			for (j2 = 1; j2 <= n + 1; j2++) cnt[j2] += cnt[j2 - 1];
			for (j2 = m2 - 1; j2 >= 0; j2--) { long pos2 = --cnt[ti[j2]]; oi[pos2] = ti[j2]; oj[pos2] = tj[j2]; }
			for (j2 = 0; j2 < m2; j2++) {
				if (oi[j2] == last_i && oj[j2] == last_j) continue;
				last_i = oi[j2]; last_j = oj[j2];
				si[mm] = oi[j2]; sj[mm] = oj[j2]; mm++;
			}
			free(cnt); free(oi); free(oj); free(ti); free(tj);
			if (csr_from_edges(&S, n, mm, si, sj, NULL, 0, 1, 0)) { free(si); free(sj); bk_free(&b); csr_free(&G); return 2; }
		}
		free(si); free(sj);
		b.sym = &S;
	}
	/* the graph "distance <= steps" as bitsets (rows are directed) */
	dist = (long *)malloc((size_t)(n > 0 ? n : 1) * sizeof(long));
	queue = (long *)malloc((size_t)(n > 0 ? n : 1) * sizeof(long));
	if (!dist || !queue) { free(dist); free(queue); bk_free(&b); csr_free(&G); csr_free(&S); return 2; }
	for (i = 0; i < n; i++) dist[i] = -1;
	for (i = 0; i < n; i++) {
		qh = 0; qt = 0;
		queue[qt++] = i; dist[i] = 0;
		while (qh < qt) {
			v = queue[qh++];
			if (dist[v] >= steps) continue;
			for (k = G.ptr[v]; k < G.ptr[v + 1]; k++) {
				w = G.idx[k];
				if (dist[w] < 0) { dist[w] = dist[v] + 1; queue[qt++] = w; }
			}
		}
		for (k = 1; k < qt; k++) {
			w = queue[k];
			b.adj[i * b.W + (w >> 6)] |= (1ULL << (w & 63));
		}
		for (k = 0; k < qt; k++) dist[queue[k]] = -1;
	}
	free(dist); free(queue);
	csr_free(&G);
	if (bk_level(&b, 0)) { bk_free(&b); csr_free(&S); return 2; }
	for (i = 0; i < b.W; i++) { b.Pb[0][i] = 0; b.Xb[0][i] = 0; }
	for (i = 0; i < n; i++) b.Pb[0][i >> 6] |= (1ULL << (i & 63));
	bk_rec(&b, 0);
	rc = bk_finish(&b);
	bk_free(&b);
	csr_free(&S);
	return rc;
}

/* p[3] k, p[4] minsize, p[5] maxplexes, p[6] countonly, p[7] maxtime (CPU seconds); ties: symmetric 0/1 simple graph */
static int comb_kplex(long n, long nties, const long *ei, const long *ej, const double *p) {
	csr_t G;
	bk_t b;
	long i, k;
	int rc;
	if (csr_from_edges(&G, n, nties, ei, ej, NULL, 0, 1, 0)) return 2;
	if (bk_setup(&b, n)) { bk_free(&b); csr_free(&G); return 2; }
	b.k = (long)p[3]; b.minsize = (long)p[4]; b.maxcnt = (long)p[5]; b.countonly = (int)p[6]; b.maxwork = p[7];
	for (i = 0; i < n; i++)
		for (k = G.ptr[i]; k < G.ptr[i + 1]; k++)
			b.adj[i * b.W + (G.idx[k] >> 6)] |= (1ULL << (G.idx[k] & 63));
	if (bk_level(&b, 0)) { bk_free(&b); csr_free(&G); return 2; }
	for (i = 0; i < b.W; i++) { b.Pb[0][i] = 0; b.Xb[0][i] = 0; }
	for (i = 0; i < n; i++) b.Pb[0][i >> 6] |= (1ULL << (i & 63));
	kp_rec(&b, 0, &G);
	rc = bk_finish(&b);
	bk_free(&b);
	csr_free(&G);
	return rc;
}

/* ------------------------------------------------------------------ */
/* ALG_BALANCE (22): triad balance of nwbalance                         */
/* ------------------------------------------------------------------ */

/*
	Closed triads and balanced closed triads per node, the port of
	calculate_balance() in unw_core.do.  A triple i<j<k is closed when every pair is tied in
	some direction; its sign product uses, for each pair {a<b}, the weight of the tie a->b when
	it exists and else the weight of b->a.  The product is > 0 (or a weight is missing, which
	Mata's missing > 0 treats as true) for a balanced triad.  Ties: the stored ties (ego, alter,
	weight), 1-based.  Result: n rows x 2 columns (closed, balanced), counts per node.
	Work: O(sum over tied pairs of the smaller neighbour list) instead of O(n^2) pair probes.
*/
typedef struct { long lo, hi; int rev; double w; } bal_pair_t;

static int bal_cmp(const void *a, const void *b) {
	const bal_pair_t *x = (const bal_pair_t *)a, *y = (const bal_pair_t *)b;
	if (x->lo != y->lo) return x->lo < y->lo ? -1 : 1;
	if (x->hi != y->hi) return x->hi < y->hi ? -1 : 1;
	if (x->rev != y->rev) return x->rev < y->rev ? -1 : 1;   /* forward (a<b) tie first */
	return 0;
}

static int comb_balance(long n, long nties, const long *ei, const long *ej, const double *ew) {
	bal_pair_t *pr;
	long np = 0, k, u, q, a;
	long *deg, *ptr, *idx, *cur;
	double *wt;
	int bad = 0;

	pr = (bal_pair_t *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(bal_pair_t));
	if (!pr) return 2;
	for (k = 0; k < nties; k++) {
		long x = ei[k], y = ej[k];
		if (x == y || x < 1 || y < 1 || x > n || y > n) continue;
		pr[np].lo = x < y ? x : y;
		pr[np].hi = x < y ? y : x;
		pr[np].rev = (x > y);
		pr[np].w = ew[k];
		np++;
	}
	qsort(pr, (size_t)np, sizeof(bal_pair_t), bal_cmp);
	/* unique pairs: keep the first (forward preferred) */
	{
		long m = 0;
		for (k = 0; k < np; k++) {
			if (m > 0 && pr[m - 1].lo == pr[k].lo && pr[m - 1].hi == pr[k].hi) continue;
			pr[m++] = pr[k];
		}
		np = m;
	}
	deg = (long *)calloc((size_t)(n + 2), sizeof(long));
	ptr = (long *)calloc((size_t)(n + 2), sizeof(long));
	idx = (long *)malloc((size_t)(2 * np > 0 ? 2 * np : 1) * sizeof(long));
	wt = (double *)malloc((size_t)(2 * np > 0 ? 2 * np : 1) * sizeof(double));
	cur = (long *)calloc((size_t)(n + 2), sizeof(long));
	if (!deg || !ptr || !idx || !wt || !cur) { free(pr); free(deg); free(ptr); free(idx); free(wt); free(cur); return 2; }
	for (k = 0; k < np; k++) { deg[pr[k].lo]++; deg[pr[k].hi]++; }
	ptr[1] = 0;
	for (u = 1; u <= n; u++) ptr[u + 1] = ptr[u] + deg[u];
	for (u = 1; u <= n; u++) cur[u] = ptr[u];
	/* pairs are sorted by (lo, hi): appending in this order keeps every list ascending
	   (neighbours below u arrive from pairs with hi == u in increasing lo, then those above) */
	for (k = 0; k < np; k++) {
		/* entries for 'lo' list: neighbours hi ascending are appended in pair order;
		   entries for 'hi' list: lo values arrive ascending because pairs are sorted by lo first */
		idx[cur[pr[k].lo]] = pr[k].hi; wt[cur[pr[k].lo]++] = pr[k].w;
		idx[cur[pr[k].hi]] = pr[k].lo; wt[cur[pr[k].hi]++] = pr[k].w;
	}
	if (res_alloc(n, 2)) { free(pr); free(deg); free(ptr); free(idx); free(wt); free(cur); return 2; }
	for (k = 0; k < n * 2; k++) g_res[k] = 0;
	/* the lists of a node: lower neighbours (appended while scanning pairs with that hi, in
	   increasing lo) all come before the higher ones only if pairs sorted by lo... guard with a check */
	for (u = 1; u <= n && !bad; u++)
		for (q = ptr[u] + 1; q < ptr[u + 1]; q++)
			if (idx[q] < idx[q - 1]) { bad = 1; break; }
	if (bad) {
		/* insertion sort each list (rare: lists are almost sorted) */
		for (u = 1; u <= n; u++) {
			for (q = ptr[u] + 1; q < ptr[u + 1]; q++) {
				long ti = idx[q]; double tw = wt[q];
				long r = q - 1;
				while (r >= ptr[u] && idx[r] > ti) { idx[r + 1] = idx[r]; wt[r + 1] = wt[r]; r--; }
				idx[r + 1] = ti; wt[r + 1] = tw;
			}
		}
	}
	/* triangles i<j<k: for each tied pair (i,j), common neighbours k > j */
	for (a = 1; a <= n; a++) {
		for (q = ptr[a]; q < ptr[a + 1]; q++) {
			long j = idx[q];
			double vij = wt[q];
			long p1, p2, e1, e2;
			if (j <= a) continue;
			p1 = q + 1;                       /* neighbours of a above j */
			e1 = ptr[a + 1];
			p2 = ptr[j];
			e2 = ptr[j + 1];
			while (p2 < e2 && idx[p2] <= j) p2++;
			while (p1 < e1 && p2 < e2) {
				if (idx[p1] < idx[p2]) p1++;
				else if (idx[p1] > idx[p2]) p2++;
				else {
					long kk = idx[p1];
					double vik = wt[p1], vjk = wt[p2], prod;
					int bl;
					if (SF_is_missing(vij) || SF_is_missing(vjk) || SF_is_missing(vik)) bl = 1;
					else { prod = vij * vjk * vik; bl = (prod > 0); }
					g_res[(a - 1) * 2] += 1;  g_res[(j - 1) * 2] += 1;  g_res[(kk - 1) * 2] += 1;
					g_res[(a - 1) * 2 + 1] += bl;  g_res[(j - 1) * 2 + 1] += bl;  g_res[(kk - 1) * 2 + 1] += bl;
					p1++; p2++;
				}
			}
		}
	}
	free(pr); free(deg); free(ptr); free(idx); free(wt); free(cur);
	pub_result(0, n, 2);
	return 0;
}

/* ------------------------------------------------------------------ */
/* ALG_MATCHING (23): maximum bipartite matching of nwmatching          */
/* ------------------------------------------------------------------ */

/*
	The Edmonds-Karp matching of calculate_bipartite_matching() in unw_core.do on a sparse
	residual graph.  Node ids 1..n, virtual source n+1 and sink n+2; the residual arcs of each
	node are visited in ascending target order and a path is augmented as soon as the sink is
	discovered, exactly as bfs_augment() does on the dense capacity matrix, so the same matching
	comes out.  Ties: mode-1 -> mode-2 ties with a positive weight, sorted by (ego, alter) as
	edgelist() gives them; v4: the mode (1 or 2) of each node.  Result: n x 1, the mode-2 partner
	of each mode-1 node (0 when unmatched).
*/
static int comb_matching(long n, long nties, const long *ei, const long *ej, const double *nv) {
	long *ptr, *idx, *cur, *m1, *m2, *queue, *parent;
	char *vis;
	long k, i, j, u, qh, qt, v, found;
	int rc = 0;

	ptr = (long *)calloc((size_t)(n + 3), sizeof(long));
	idx = (long *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(long));
	cur = (long *)calloc((size_t)(n + 3), sizeof(long));
	m1 = (long *)calloc((size_t)(n + 3), sizeof(long));      /* mode-1 node -> partner (0 none) */
	m2 = (long *)calloc((size_t)(n + 3), sizeof(long));      /* mode-2 node -> partner */
	queue = (long *)malloc((size_t)(n + 3) * sizeof(long));
	parent = (long *)malloc((size_t)(n + 3) * sizeof(long));
	vis = (char *)malloc((size_t)(n + 3));
	if (!ptr || !idx || !cur || !m1 || !m2 || !queue || !parent || !vis) {
		free(ptr); free(idx); free(cur); free(m1); free(m2); free(queue); free(parent); free(vis);
		return 2;
	}
	for (k = 0; k < nties; k++) if (ei[k] >= 1 && ei[k] <= n) ptr[ei[k] + 1]++;
	ptr[1] = 0;
	for (i = 1; i <= n; i++) ptr[i + 1] += ptr[i];
	for (i = 1; i <= n; i++) cur[i] = ptr[i];
	for (k = 0; k < nties; k++) if (ei[k] >= 1 && ei[k] <= n) idx[cur[ei[k]]++] = ej[k];
	{
		long src = n + 1, snk = n + 2;
		for (;;) {
			memset(vis, 0, (size_t)(n + 3));
			qh = 0; qt = 0;
			queue[qt++] = src; vis[src] = 1;
			found = 0;
			while (qh < qt && !found) {
				u = queue[qh++];
				if (u == src) {
					for (i = 1; i <= n; i++)
						if (nv[i - 1] == 1.0 && m1[i] == 0 && !vis[i]) { vis[i] = 1; parent[i] = u; queue[qt++] = i; }
				}
				else if (nv[u - 1] == 1.0) {
					for (k = ptr[u]; k < ptr[u + 1]; k++) {
						j = idx[k];
						if (m1[u] == j) continue;          /* saturated arc */
						if (!vis[j]) { vis[j] = 1; parent[j] = u; queue[qt++] = j; }
					}
					/* the reverse arc to the source leads to a visited node */
				}
				else {
					if (m2[u] != 0) {                      /* reverse arc to the matched partner */
						v = m2[u];
						if (!vis[v]) { vis[v] = 1; parent[v] = u; queue[qt++] = v; }
					}
					else if (!vis[snk]) { vis[snk] = 1; parent[snk] = u; queue[qt++] = snk; found = 1; }
				}
				if (vis[snk]) found = 1;
			}
			if (!found) break;
			/* augment along parent[]: sink <- j <- i <- (j' <- i' ...) <- source */
			{
				long jj = parent[snk];                     /* mode-2 node at the end of the path */
				while (1) {
					long ii = parent[jj];                  /* mode-1 node before it */
					m1[ii] = jj; m2[jj] = ii;
					if (parent[ii] == src) break;
					jj = parent[ii];                       /* ii was entered by the reverse arc of mode-2 node parent[ii] */
				}
			}
		}
	}
	if (res_alloc(n, 1)) rc = 2;
	else for (i = 1; i <= n; i++) g_res[i - 1] = (nv[i - 1] == 1.0) ? (double)m1[i] : 0.0;
	free(ptr); free(idx); free(cur); free(m1); free(m2); free(queue); free(parent); free(vis);
	if (rc == 0) pub_result(0, n, 1);
	return rc;
}

/* ------------------------------------------------------------------ */
/* ALG_LOUVAIN (24): Louvain community detection of nwcommunity        */
/* ------------------------------------------------------------------ */
/*
	Same algorithm and visiting order as the Mata Louvain() in unw_core.do: nodes are visited in the
	order 1..n, a node leaves its community and joins the neighbouring community (candidates in
	ascending community number, the node's own community first as the reference) with the largest
	gain  w(i,C)/m2 - resolution * tot(C) * k(i) / m2^2, a move needs a gain larger than the current
	one by more than 1e-12, sweeps repeat until nothing moves (at most 100), the communities are
	numbered 1..k in ascending order of their old numbers and become the nodes of the next level,
	where the weight inside a community is kept as a loop (twice the sum of its tie values, plus the
	loops of its members).  The weight of a node to its own community leaves out the node's own loop.
	Input: one row (i, j, w) per pair i < j (symmetric simple graph, w != 0).  Output: the community
	(1..k) of every node.
*/
typedef struct { long a, b; double w; } lv_edge_t;

static int lv_cmp(const void *x, const void *y) {
	const lv_edge_t *p = (const lv_edge_t *)x, *q = (const lv_edge_t *)y;
	if (p->a != q->a) return p->a < q->a ? -1 : 1;
	if (p->b != q->b) return p->b < q->b ? -1 : 1;
	return 0;
}

/* sort the directed entries and add up parallel ones; returns the new length */
static long lv_merge(lv_edge_t *E, long m) {
	long k, o = 0;
	qsort(E, (size_t)m, sizeof(lv_edge_t), lv_cmp);
	for (k = 0; k < m; k++) {
		if (o > 0 && E[o - 1].a == E[k].a && E[o - 1].b == E[k].b) E[o - 1].w += E[k].w;
		else E[o++] = E[k];
	}
	return o;
}

static int comb_louvain(long n, long nties, const long *ei, const long *ej, const double *ew, double res) {
	lv_edge_t *E = NULL;
	long m = 0, k, cn = n, u, q, v, i, nc, sweep, ncand, a, c, iter;
	long *map = NULL, *ptr = NULL, *idx = NULL, *comm = NULL, *lab = NULL, *cand = NULL, *seen = NULL;
	double *wt = NULL, *selfw = NULL, *kk = NULL, *Stot = NULL, *acc = NULL, *nself = NULL;
	double m2, kin_old, best_gain, gain, k_i;
	long c_old, best_c, moved, stamp = 0;
	int rc = 0;

	E = (lv_edge_t *)malloc((size_t)(2 * nties + 1) * sizeof(lv_edge_t));
	map = (long *)malloc((size_t)(n + 1) * sizeof(long));
	if (!E || !map) { free(E); free(map); return 2; }
	for (k = 0; k < nties; k++) {
		long x = ei[k], y = ej[k];
		if (x == y || x < 1 || y < 1 || x > n || y > n || ew[k] == 0) continue;
		E[m].a = x; E[m].b = y; E[m].w = ew[k]; m++;
		E[m].a = y; E[m].b = x; E[m].w = ew[k]; m++;
	}
	m = lv_merge(E, m);
	for (i = 1; i <= n; i++) map[i] = i;
	selfw = (double *)calloc((size_t)(n + 2), sizeof(double));
	if (!selfw) { free(E); free(map); return 2; }

	for (iter = 0; iter < 1000; iter++) {
		/* CSR of the current level */
		ptr = (long *)calloc((size_t)(cn + 2), sizeof(long));
		idx = (long *)malloc((size_t)(m + 1) * sizeof(long));
		wt = (double *)malloc((size_t)(m + 1) * sizeof(double));
		kk = (double *)malloc((size_t)(cn + 2) * sizeof(double));
		Stot = (double *)malloc((size_t)(cn + 2) * sizeof(double));
		acc = (double *)calloc((size_t)(cn + 2), sizeof(double));
		comm = (long *)malloc((size_t)(cn + 2) * sizeof(long));
		lab = (long *)calloc((size_t)(cn + 2), sizeof(long));
		cand = (long *)malloc((size_t)(cn + 2) * sizeof(long));
		seen = (long *)calloc((size_t)(cn + 2), sizeof(long));
		if (!ptr || !idx || !wt || !kk || !Stot || !acc || !comm || !lab || !cand || !seen) { rc = 2; goto done; }
		for (k = 0; k < m; k++) ptr[E[k].a + 1]++;
		for (u = 1; u <= cn; u++) ptr[u + 1] += ptr[u];       /* ptr[u]..ptr[u+1]-1 = entries of node u (ptr[1] = 0) */
		for (k = 0; k < m; k++) { idx[k] = E[k].b; wt[k] = E[k].w; }
		m2 = 0;
		for (u = 1; u <= cn; u++) {
			double s = selfw[u];
			for (q = ptr[u]; q < ptr[u + 1]; q++) s += wt[q];
			kk[u] = s;
			m2 += s;
		}
		if (m2 == 0 || cn <= 1) {
			for (u = 1; u <= cn; u++) lab[u] = u;
			nc = cn;
		}
		else {
			for (u = 1; u <= cn; u++) { comm[u] = u; Stot[u] = kk[u]; }
			moved = 1; sweep = 0;
			while (moved && sweep < 100) {
				moved = 0; sweep++;
				for (i = 1; i <= cn; i++) {
					c_old = comm[i]; k_i = kk[i];
					Stot[c_old] -= k_i;
					stamp++; ncand = 0;
					for (q = ptr[i]; q < ptr[i + 1]; q++) {
						c = comm[idx[q]];
						if (seen[c] != stamp) { seen[c] = stamp; acc[c] = 0; cand[ncand++] = c; }
						acc[c] += wt[q];
					}
					if (seen[c_old] != stamp) { seen[c_old] = stamp; acc[c_old] = 0; cand[ncand++] = c_old; }
					if (ncand > 1) qsort(cand, (size_t)ncand, sizeof(long), cmp_long);
					kin_old = acc[c_old];
					best_c = c_old;
					best_gain = kin_old / m2 - res * Stot[c_old] * k_i / (m2 * m2);
					for (a = 0; a < ncand; a++) {
						c = cand[a];
						gain = acc[c] / m2 - res * Stot[c] * k_i / (m2 * m2);
						if (gain > best_gain + 1e-12) { best_gain = gain; best_c = c; }
					}
					comm[i] = best_c;
					Stot[best_c] += k_i;
					if (best_c != c_old) moved = 1;
				}
			}
			/* dense numbering in ascending order of the old community numbers */
			memset(seen, 0, (size_t)(cn + 2) * sizeof(long));
			for (u = 1; u <= cn; u++) seen[comm[u]] = 1;
			nc = 0;
			for (u = 1; u <= cn; u++) if (seen[u]) seen[u] = ++nc;
			for (u = 1; u <= cn; u++) lab[u] = seen[comm[u]];
		}
		for (i = 1; i <= n; i++) map[i] = lab[map[i]];
		if (nc == cn) break;
		/* aggregate */
		nself = (double *)calloc((size_t)(nc + 2), sizeof(double));
		if (!nself) { rc = 2; goto done; }
		{
			long mm = 0;
			lv_edge_t *E2 = (lv_edge_t *)malloc((size_t)(m + 1) * sizeof(lv_edge_t));
			if (!E2) { free(nself); nself = NULL; rc = 2; goto done; }
			for (u = 1; u <= cn; u++) {
				nself[lab[u]] += selfw[u];
				for (q = ptr[u]; q < ptr[u + 1]; q++) {
					a = lab[u]; v = lab[idx[q]];
					if (a == v) nself[a] += wt[q];
					else { E2[mm].a = a; E2[mm].b = v; E2[mm].w = wt[q]; mm++; }
				}
			}
			mm = lv_merge(E2, mm);
			free(E); E = E2; m = mm;
		}
		free(selfw); selfw = nself; nself = NULL;
		cn = nc;
		free(ptr); free(idx); free(wt); free(kk); free(Stot); free(acc); free(comm); free(lab); free(cand); free(seen);
		ptr = NULL; idx = NULL; wt = NULL; kk = NULL; Stot = NULL; acc = NULL; comm = NULL; lab = NULL; cand = NULL; seen = NULL;
	}
	if (res_alloc(n, 1)) rc = 2;
	else for (i = 1; i <= n; i++) g_res[i - 1] = (double)map[i];
done:
	free(E); free(map); free(selfw); free(ptr); free(idx); free(wt); free(kk); free(Stot); free(acc); free(comm); free(lab); free(cand); free(seen);
	if (rc == 0) pub_result(0, n, 1);
	return rc;
}

/* ------------------------------------------------------------------ */
/* ALG_DISTSUM (25): distance sums of every node (nwcloseness, nwkatz) */
/* ------------------------------------------------------------------ */
/*
	One breadth-first search per node over the arcs (i -> j) as given (the caller passes both directions
	of an undirected tie; p[3] = 1 reverses every arc, i.e. searches along the in-ties).  For every
	source s the distances d(s,j) to the nodes j != s that can be reached are summed:
	  column 1  far    = sum of d(s,j)
	  column 2  reach  = number of nodes j != s reached
	  column 3  katz   = sum of alpha^d(s,j)  (alpha = p[4]; the levels are added as count * alpha^d)
	exactly the row sums of the matrices that nwgeodesic builds (unvalued, diagonal and unreachable
	cells missing, i.e. counted as 0), without ever holding an n x n matrix.  Memory is O(n + ties).
*/
static int comb_distsum(long n, long nties, const long *ei, const long *ej, int reverse, double alpha) {
	long *ptr = NULL, *idx = NULL, *cur = NULL, *queue = NULL, *dist = NULL;
	long k, s, h, t, v, w, a, b, cnt;
	double far, kz;
	int rc = 0;

	ptr = (long *)calloc((size_t)(n + 3), sizeof(long));
	idx = (long *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(long));
	cur = (long *)malloc((size_t)(n + 2) * sizeof(long));
	queue = (long *)malloc((size_t)(n + 1) * sizeof(long));
	dist = (long *)malloc((size_t)(n + 1) * sizeof(long));
	if (!ptr || !idx || !cur || !queue || !dist) { free(ptr); free(idx); free(cur); free(queue); free(dist); return 2; }
	for (k = 0; k < nties; k++) {
		a = reverse ? ej[k] : ei[k];
		b = reverse ? ei[k] : ej[k];
		if (a < 1 || b < 1 || a > n || b > n) continue;
		ptr[a + 1]++;
	}
	ptr[1] = 0;
	for (v = 1; v <= n; v++) ptr[v + 1] += ptr[v];
	for (v = 1; v <= n; v++) cur[v] = ptr[v];
	for (k = 0; k < nties; k++) {
		a = reverse ? ej[k] : ei[k];
		b = reverse ? ei[k] : ej[k];
		if (a < 1 || b < 1 || a > n || b > n) continue;
		idx[cur[a]++] = b;
	}
	if (res_alloc(n, 3)) { free(ptr); free(idx); free(cur); free(queue); free(dist); return 2; }
	for (v = 0; v <= n; v++) dist[v] = -1;
	for (s = 1; s <= n; s++) {
		long lv = 1, pos = 1;
		h = 0; t = 0;
		queue[t++] = s;
		dist[s] = 0;
		far = 0; kz = 0; cnt = 0;
		while (h < t) {
			v = queue[h++];
			for (k = ptr[v]; k < ptr[v + 1]; k++) {
				w = idx[k];
				if (dist[w] < 0) {
					dist[w] = dist[v] + 1;
					queue[t++] = w;
				}
			}
		}
		/* the queue lists the nodes in order of distance: add the levels one by one */
		while (pos < t) {
			long c0 = 0;
			while (pos < t && dist[queue[pos]] == lv) { c0++; pos++; }
			far += (double)c0 * (double)lv;
			kz += (double)c0 * pow(alpha, (double)lv);
			cnt += c0;
			lv++;
		}
		g_res[(s - 1) * 3 + 0] = far;
		g_res[(s - 1) * 3 + 1] = (double)cnt;
		g_res[(s - 1) * 3 + 2] = kz;
		for (h = 0; h < t; h++) dist[queue[h]] = -1;
	}
	free(ptr); free(idx); free(cur); free(queue); free(dist);
	pub_result(0, n, 3);
	return rc;
}
