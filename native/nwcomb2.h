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
