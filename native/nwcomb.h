/*
	nwcomb.h -- native (C) kernels for the combinatorial commands of the
	core package: cohesive blocking (nwcohesion), factions (nwfactions),
	line connectivity (nwlambda), the 4-node motif census (nwmotifs),
	two-mode clustering (nw2clustering) and the exhaustive subgroup
	searches (nwnclique, nwnclan, nwkplex).

	This file is #included by nwgraph.c (one plugin binary, so no change to
	the build commands); it is not a separate translation unit.

	Codes 22 (triad balance of nwbalance) and 23 (bipartite matching of nwmatching) were added with
	NWCOMB_VERSION 3 (see comb_balance(), comb_matching() in nwcomb2.h), code 24 (Louvain communities of
	nwcommunity) with NWCOMB_VERSION 4 (comb_louvain()), code 25 (distance sums of
	nwcloseness and nwkatz) with NWCOMB_VERSION 5 (comb_distsum()), codes 26 (clustering of nwclustering), 27
	(triad census of nwtriads) and 28 (eigenvector centrality of nwevcent) with NWCOMB_VERSION 6 (nwfast.h), 29 (nwburt), 30 (nwconstraint) and
	31 (nwsimmelian) with NWCOMB_VERSION 7 (nwbrokerage.h).
	Codes 34..39 (nwfast2.h, NWCOMB_VERSION 8): 34 pagerank of nwpagerank, 35 maximal cliques of nwclique.
	Code 40 (nwburtw.h, NWCOMB_VERSION 9): weighted Burt measures of nwburt for valued networks (41, 42 reserved).
	Code 50 (nwnative380.h, NWCOMB_VERSION 11): node position counts of the bipartite motifs of nw2motifs.
	Codes 51..60 (nwnative390.h, NWCOMB_VERSION 12): node-by-node similarities, DIRT_LPA+ communities, two-mode null-model draws.
	Codes 43..49 (nwnative370.h, NWCOMB_VERSION 10): bipartite Louvain (Barber) of nwcommunity, weighted pagerank of nwpagerank,
	maximum-weight matching of nwmatching, tie swapping of nwpermute, weighted betweenness of nwbetween, weighted distances of nwcloseness and nwgeodesic.

	WIRE PROTOCOL (algorithm codes 3..99, see comb_call() at the end):
	  plugin call nwgraph_native v1 v2 v3 v4 [v5 ...], "alg n nties p1 p2 ..."
	  v1, v2   ego, alter (1-based node ids), one row per tie
	  v3       tie weight (algorithms that need it)
	  v4       one value per node, rows 1..n (algorithms that need it)
	  v5...    output columns, written only by the FETCH call (alg 99)
	A compute call keeps its result in static memory and publishes its size
	and a few numbers as scalars __nwg_status, __nwg_rows, __nwg_cols,
	__nwg_a1 ...; the Mata caller then sizes the frame and calls FETCH
	(alg 99) to copy the result matrix into the output columns and free it.
	status: 0 ok, 1 result limit exceeded (maxcliques), 2 out of memory.
	Algorithm 100 only publishes __nwg_ver (so Mata can tell a plugin that
	has these kernels from an older one).

	All kernels are exact ports (same visiting order, same tie-breaks) of the
	Mata routines they replace in unw_core.do, except where the header of the
	individual kernel says otherwise; cscripts/test_*_scale.do proves the
	equality against a naive reference.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <time.h>
#if defined(_MSC_VER)
#include <intrin.h>
#endif
#include "nwtypes.h"

#define NWCOMB_VERSION 12

#define ALG_COHESION   3
#define ALG_FACTIONS   4
#define ALG_LAMBDATREE 5
#define ALG_MOTIF4     6
#define ALG_CLUSTER2   7
#define ALG_NCLIQUE    8
#define ALG_KPLEX      9
#define ALG_BALANCE    22
#define ALG_MATCHING   23
#define ALG_LOUVAIN    24
#define ALG_DISTSUM    25
#define ALG_FETCH      99
#define ALG_VERSION    100

/* ------------------------------------------------------------------ */
/* small utilities                                                     */
/* ------------------------------------------------------------------ */

/* work counters (published for diagnostics) */
static nwint g_nsearch = 0, g_nquery = 0, g_nbfs = 0;
static int g_oom = 0;

static double *g_res = NULL;
static nwint g_res_rows = 0, g_res_cols = 0;

static void res_clear(void) {
	free(g_res);
	g_res = NULL;
	g_res_rows = g_res_cols = 0;
}

static int res_alloc(nwint rows, nwint cols) {
	res_clear();
	g_res = (double *)malloc((size_t)((rows * cols) > 0 ? rows * cols : 1) * sizeof(double));
	if (!g_res) return 1;
	g_res_rows = rows;
	g_res_cols = cols;
	return 0;
}

static void pub(const char *name, double v) {
	char buf[40];
	strncpy(buf, name, 39);
	buf[39] = 0;
	SF_scal_save(buf, v);
}

static void pub_a(int i, double v) {
	char buf[40];
	sprintf(buf, "__nwg_a%d", i);
	SF_scal_save(buf, v);
}

static void pub_result(nwint status, nwint rows, nwint cols) {
	pub("__nwg_status", (double)status);
	pub("__nwg_rows", (double)rows);
	pub("__nwg_cols", (double)cols);
}

typedef struct {
	nwint *a;
	nwint len, cap;
} ilist_t;

static int il_push(ilist_t *l, nwint v) {
	if (l->len == l->cap) {
		nwint nc = l->cap ? l->cap * 2 : 64;
		nwint *p = (nwint *)realloc(l->a, (size_t)nc * sizeof(nwint));
		if (!p) return 1;
		l->a = p;
		l->cap = nc;
	}
	l->a[l->len++] = v;
	return 0;
}

static void il_free(ilist_t *l) {
	free(l->a);
	l->a = NULL;
	l->len = l->cap = 0;
}

static int popc64(uint64_t x) {
#if defined(__GNUC__) || defined(__clang__)
	return __builtin_popcountll(x);
#else
	x = x - ((x >> 1) & 0x5555555555555555ULL);
	x = (x & 0x3333333333333333ULL) + ((x >> 2) & 0x3333333333333333ULL);
	x = (x + (x >> 4)) & 0x0f0f0f0f0f0f0f0fULL;
	return (int)((x * 0x0101010101010101ULL) >> 56);
#endif
}

static int ctz64(uint64_t x) {
#if defined(__GNUC__) || defined(__clang__)
	return __builtin_ctzll(x);
#elif defined(_MSC_VER) && (defined(_M_X64) || defined(_M_ARM64))
	unsigned long idx;   /* the type _BitScanForward64 wants: a 32-bit unsigned long under MSVC, on purpose */
	_BitScanForward64(&idx, x);
	return (int)idx;
#else
	int c = 0;
	while (!(x & 1ULL)) { x >>= 1; c++; }
	return c;
#endif
}

/* ------------------------------------------------------------------ */
/* CSR graph, 0-based nodes                                            */
/* ------------------------------------------------------------------ */

typedef struct {
	nwint n;
	nwint *ptr;      /* n+1 */
	nwint *idx;      /* ptr[n] */
	double *w;      /* ptr[n] or NULL */
} csr_t;

static void csr_free(csr_t *g) {
	free(g->ptr); free(g->idx); free(g->w);
	g->ptr = NULL; g->idx = NULL; g->w = NULL; g->n = 0;
}

/* ei/ej are 1-based ids; the order of the input inside a row is kept.
   only_pos: drop ties whose weight is not > 0 (ew must then be given);
   noloop: drop self ties. */
static int csr_from_edges(csr_t *g, nwint n, nwint m, const nwint *ei, const nwint *ej,
		const double *ew, int only_pos, int noloop, int keep_w) {
	nwint i, k, tot = 0;
	nwint *cur;
	g->n = n; g->ptr = NULL; g->idx = NULL; g->w = NULL;
	g->ptr = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	if (!g->ptr) return 1;
	for (k = 0; k < m; k++) {
		if (only_pos && !(ew[k] > 0)) continue;
		if (noloop && ei[k] == ej[k]) continue;
		g->ptr[ei[k]]++;           /* count in slot (id) = row id-1 shifted by one */
		tot++;
	}
	/* ptr currently holds counts at index id (1-based); prefix-sum into 0-based starts */
	{
		nwint run = 0;
		for (i = 0; i < n; i++) {
			nwint c = g->ptr[i + 1];
			g->ptr[i] = run;
			run += c;
		}
		g->ptr[n] = run;
	}
	g->idx = (nwint *)malloc((size_t)(tot > 0 ? tot : 1) * sizeof(nwint));
	if (keep_w) g->w = (double *)malloc((size_t)(tot > 0 ? tot : 1) * sizeof(double));
	cur = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	if (!g->idx || (keep_w && !g->w) || !cur) { free(cur); return 1; }
	for (i = 0; i < n; i++) cur[i] = g->ptr[i];
	for (k = 0; k < m; k++) {
		nwint r;
		if (only_pos && !(ew[k] > 0)) continue;
		if (noloop && ei[k] == ej[k]) continue;
		r = ei[k] - 1;
		g->idx[cur[r]] = ej[k] - 1;
		if (keep_w) g->w[cur[r]] = ew ? ew[k] : 1.0;
		cur[r]++;
	}
	free(cur);
	return 0;
}

static int has_nbr(const csr_t *g, nwint u, nwint v) {
	/* neighbour lists are sorted ascending (the Mata side guarantees it) */
	nwint lo = g->ptr[u], hi = g->ptr[u + 1] - 1;
	while (lo <= hi) {
		nwint mid = (lo + hi) / 2;
		if (g->idx[mid] == v) return 1;
		if (g->idx[mid] < v) lo = mid + 1; else hi = mid - 1;
	}
	return 0;
}

/* index into idx/w of the entry (u -> v), or -1 */
static nwint find_nbr(const csr_t *g, nwint u, nwint v) {
	nwint lo = g->ptr[u], hi = g->ptr[u + 1] - 1;
	while (lo <= hi) {
		nwint mid = (lo + hi) / 2;
		if (g->idx[mid] == v) return mid;
		if (g->idx[mid] < v) lo = mid + 1; else hi = mid - 1;
	}
	return -1;
}

/* ------------------------------------------------------------------ */
/* induced local graph on a sorted node list                            */
/* ------------------------------------------------------------------ */

typedef struct {
	nwint n;
	nwint *ptr, *idx;
} lg_t;

static nwint *g_loc = NULL;      /* orig node -> local index, -1 outside; size n of the full graph */

static void lg_free(lg_t *g) {
	free(g->ptr); free(g->idx);
	g->ptr = NULL; g->idx = NULL; g->n = 0;
}

static int lg_build(const csr_t *G, const nwint *nodes, nwint len, lg_t *g) {
	nwint i, k, tot = 0, p;
	g->n = len; g->ptr = NULL; g->idx = NULL;
	for (i = 0; i < len; i++) g_loc[nodes[i]] = i;
	g->ptr = (nwint *)malloc((size_t)(len + 1) * sizeof(nwint));
	if (!g->ptr) return 1;
	for (i = 0; i < len; i++) {
		nwint c = 0, u = nodes[i];
		for (k = G->ptr[u]; k < G->ptr[u + 1]; k++) if (g_loc[G->idx[k]] >= 0) c++;
		g->ptr[i] = tot;
		tot += c;
	}
	g->ptr[len] = tot;
	g->idx = (nwint *)malloc((size_t)(tot > 0 ? tot : 1) * sizeof(nwint));
	if (!g->idx) { for (i = 0; i < len; i++) g_loc[nodes[i]] = -1; return 1; }
	for (i = 0; i < len; i++) {
		nwint u = nodes[i];
		p = g->ptr[i];
		for (k = G->ptr[u]; k < G->ptr[u + 1]; k++) {
			nwint l = g_loc[G->idx[k]];
			if (l >= 0) g->idx[p++] = l;      /* monotone map keeps the ascending order */
		}
	}
	for (i = 0; i < len; i++) g_loc[nodes[i]] = -1;
	return 0;
}

/* ------------------------------------------------------------------ */
/* Vertex-split flow network of an undirected simple graph and the local
   vertex connectivity (number of internally vertex-disjoint s-t paths).

   Node x of the graph becomes x_in = x and x_out = n+x joined by an arc of capacity 1;
   a tie {u,v} becomes u_out -> v_in and v_out -> u_in with capacity n+10. The
   Mata original (build_vertexsplit_sparse_edges / maxflow_sparse_query_buffered)
   used a linked list of arcs; here the arcs of a node are contiguous (CSR), the
   reverse arc is stored explicitly, and the residual capacity is kept directly.
   The value of a maximum flow and the set of nodes reachable from the source in
   its residual graph do not depend on the order of the augmenting paths, so the
   searches below return the same minima, witness pairs and cutsets as the Mata
   routines they replace.                                                   */
/* ------------------------------------------------------------------ */

typedef struct {
	nwint n, E;
	int bignum;
	int *to, *rev, *cap0, *res;
	nwint *ptr;              /* 2n+1 */
	nwint *split_in;         /* arc index of x_in -> x_out */
	int *vis, *queue, *pe, *queue2, *visF, *visB, *peF, *peB;
	int stamp;
	nwint *touched; nwint ntouched, captouched;
} vs_t;

static void vs_free(vs_t *vs) {
	free(vs->to); free(vs->rev); free(vs->cap0); free(vs->res); free(vs->ptr); free(vs->split_in);
	free(vs->vis); free(vs->queue); free(vs->pe); free(vs->touched);
	free(vs->queue2); free(vs->visF); free(vs->visB); free(vs->peF); free(vs->peB);
	memset(vs, 0, sizeof(*vs));
}

static int vs_init(vs_t *vs, const lg_t *g) {
	nwint n = g->n, N = 2 * n, E = 2 * (n + g->ptr[n]), u, k, v, a, b;
	nwint *pos;
	memset(vs, 0, sizeof(*vs));
	vs->n = n; vs->E = E; vs->bignum = (int)(n + 10);
	vs->to = (int *)malloc((size_t)E * sizeof(int));
	vs->rev = (int *)malloc((size_t)E * sizeof(int));
	vs->cap0 = (int *)malloc((size_t)E * sizeof(int));
	vs->res = (int *)malloc((size_t)E * sizeof(int));
	vs->ptr = (nwint *)malloc((size_t)(N + 1) * sizeof(nwint));
	vs->split_in = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	vs->vis = (int *)calloc((size_t)N, sizeof(int));
	vs->queue = (int *)malloc((size_t)N * sizeof(int));
	vs->pe = (int *)malloc((size_t)N * sizeof(int));
	vs->queue2 = (int *)malloc((size_t)N * sizeof(int));
	vs->visF = (int *)calloc((size_t)N, sizeof(int));
	vs->visB = (int *)calloc((size_t)N, sizeof(int));
	vs->peF = (int *)malloc((size_t)N * sizeof(int));
	vs->peB = (int *)malloc((size_t)N * sizeof(int));
	pos = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	if (!vs->to || !vs->rev || !vs->cap0 || !vs->res || !vs->ptr || !vs->split_in || !vs->vis || !vs->queue || !vs->pe || !vs->queue2 || !vs->visF || !vs->visB || !vs->peF || !vs->peB || !pos) {
		free(pos); vs_free(vs); return 1;
	}
	/* in-node u: split arc + one reverse arc per tie; out-node u: reverse split arc + one forward arc per tie */
	a = 0;
	for (u = 0; u < n; u++) { vs->ptr[u] = a; a += 1 + (g->ptr[u + 1] - g->ptr[u]); }
	for (u = 0; u < n; u++) { vs->ptr[n + u] = a; a += 1 + (g->ptr[u + 1] - g->ptr[u]); }
	vs->ptr[N] = a;
	for (u = 0; u < n; u++) {
		a = vs->ptr[u];
		b = vs->ptr[n + u];
		vs->split_in[u] = a;
		vs->to[a] = (int)(n + u); vs->cap0[a] = 1; vs->rev[a] = (int)b;
		vs->to[b] = (int)u; vs->cap0[b] = 0; vs->rev[b] = (int)a;
	}
	/* tie arcs: out_u -> in_v sits at ptr[n+u]+1+j (j = index of v in u's list); its reverse in_v -> out_u at ptr[v]+1+i
	   (i = index of u in v's list). Lists are sorted and symmetric. */
	for (u = 0; u < n; u++) pos[u] = 0;
	for (u = 0; u < n; u++) {
		for (k = g->ptr[u]; k < g->ptr[u + 1]; k++) {
			v = g->idx[k];
			if (v > u) {
				nwint j = k - g->ptr[u];
				nwint i;
				for (i = pos[v]; g->idx[g->ptr[v] + i] != u; i++) ;
				pos[v] = i + 1;
				a = vs->ptr[n + u] + 1 + j;           /* out_u -> in_v */
				b = vs->ptr[v] + 1 + i;               /* in_v -> out_u */
				vs->to[a] = (int)v; vs->cap0[a] = vs->bignum; vs->rev[a] = (int)b;
				vs->to[b] = (int)(n + u); vs->cap0[b] = 0; vs->rev[b] = (int)a;
				/* and the other direction of the tie: out_v -> in_u at ptr[n+v]+1+i, reverse in_u -> out_v at ptr[u]+1+j */
				a = vs->ptr[n + v] + 1 + i;
				b = vs->ptr[u] + 1 + j;
				vs->to[a] = (int)u; vs->cap0[a] = vs->bignum; vs->rev[a] = (int)b;
				vs->to[b] = (int)(n + v); vs->cap0[b] = 0; vs->rev[b] = (int)a;
			}
		}
	}
	free(pos);
	memcpy(vs->res, vs->cap0, (size_t)E * sizeof(int));
	vs->stamp = 0;
	vs->touched = NULL; vs->ntouched = 0; vs->captouched = 0;
	return 0;
}

static int vs_touch(vs_t *vs, nwint a) {
	if (vs->ntouched == vs->captouched) {
		nwint nc = vs->captouched ? vs->captouched * 2 : 256;
		nwint *p = (nwint *)realloc(vs->touched, (size_t)nc * sizeof(nwint));
		if (!p) return 1;
		vs->touched = p;
		vs->captouched = nc;
	}
	vs->touched[vs->ntouched++] = a;
	return 0;
}

/* Bidirectional search for an augmenting path: grows the smaller frontier one level at a time,
   forward from s over residual arcs and backward from t over the reverse arcs. On success the
   path is s ..(peF).. m ..(peB).. t and the meeting node m is returned in *meet. */
static int vs_bibfs(vs_t *vs, int s, int t, int *meet) {
	nwint fh = 0, ft = 0, bh = 0, bt = 0, a, e1, lvl;
	int u, v;
	int *qf = vs->queue, *qb = vs->queue2;
	vs->visF[s] = vs->stamp;
	vs->visB[t] = vs->stamp;
	qf[ft++] = s;
	qb[bt++] = t;
	while (fh < ft && bh < bt) {
		if (ft - fh <= bt - bh) {
			lvl = ft;
			while (fh < lvl) {
				u = qf[fh++];
				e1 = vs->ptr[u + 1];
				for (a = vs->ptr[u]; a < e1; a++) {
					if (vs->res[a] > 0) {
						v = vs->to[a];
						if (vs->visF[v] != vs->stamp) {
							vs->visF[v] = vs->stamp;
							vs->peF[v] = (int)a;
							if (vs->visB[v] == vs->stamp) { *meet = v; return 1; }
							qf[ft++] = v;
						}
					}
				}
			}
		}
		else {
			lvl = bt;
			while (bh < lvl) {
				v = qb[bh++];
				e1 = vs->ptr[v + 1];
				for (a = vs->ptr[v]; a < e1; a++) {
					u = vs->to[a];
					if (vs->res[vs->rev[a]] > 0 && vs->visB[u] != vs->stamp) {
						vs->visB[u] = vs->stamp;
						vs->peB[u] = vs->rev[a];          /* the arc u -> v */
						if (vs->visF[u] == vs->stamp) { *meet = u; return 1; }
						qb[bt++] = u;
					}
				}
			}
		}
	}
	return 0;
}

/* Augments from the out-node of s to the in-node of t until no path is left or the flow reaches `limit`.
   The split arcs of s and t must already have been raised. Leaves the residual capacities changed
   (vs_reset undoes them). s and t must not be adjacent, so every path has unit bottleneck. */
static nwint vs_augment(vs_t *vs, nwint s, nwint t, nwint limit) {
	nwint n = vs->n, flow = 0;
	int v, m;
	vs->stamp++;
	g_nquery++;
	while (flow < limit && (g_nbfs++, vs_bibfs(vs, (int)(n + s), (int)t, &m))) {
		v = m;
		while (v != (int)(n + s)) {                 /* source side of the path */
			nwint a = vs->peF[v];
			nwint r = vs->rev[a];
			vs->res[a] -= 1;
			vs->res[r] += 1;
			if (vs_touch(vs, a) || vs_touch(vs, r)) { g_oom = 1; return flow; }
			v = vs->to[r];
		}
		v = m;
		while (v != (int)t) {                        /* sink side of the path */
			nwint a = vs->peB[v];
			nwint r = vs->rev[a];
			vs->res[a] -= 1;
			vs->res[r] += 1;
			if (vs_touch(vs, a) || vs_touch(vs, r)) { g_oom = 1; return flow; }
			v = vs->to[a];
		}
		flow++;
		vs->stamp++;
	}
	return flow;
}

static void vs_reset(vs_t *vs) {
	nwint i;
	for (i = 0; i < vs->ntouched; i++) vs->res[vs->touched[i]] = vs->cap0[vs->touched[i]];
	vs->ntouched = 0;
}

/* local vertex connectivity of the nonadjacent pair (s,t), but not more than limit */
static nwint vs_query(vs_t *vs, nwint s, nwint t, nwint limit) {
	nwint f;
	vs->res[vs->split_in[s]] = vs->bignum;
	vs->res[vs->split_in[t]] = vs->bignum;
	f = vs_augment(vs, s, t, limit);
	vs_reset(vs);
	vs->res[vs->split_in[s]] = vs->cap0[vs->split_in[s]];
	vs->res[vs->split_in[t]] = vs->cap0[vs->split_in[t]];
	return f;
}

/* ------------------------------------------------------------------ */
/* Esfahanian-Hakimi search (port of fast_min_cut_search_edges)         */
/* returns the minimum, sets *bs,*bt (-1,-1 if the degree bound won)     */
/* A query is stopped as soon as its flow reaches the best value found so far:
   the exact flow of such a pair cannot lower the minimum, and the Mata search
   only records a pair when its flow is strictly smaller.                   */
/* ------------------------------------------------------------------ */

static nwint fmc_search(const lg_t *g, int has_target, nwint target, nwint *bs, nwint *bt) {
	nwint n = g->n, i, v0, delta, minflow, f, a, b;
	nwint *mark = NULL;
	vs_t vs;
	nwint stamp = 0;
	g_nsearch++;
	*bs = -1; *bt = -1;
	delta = -1; v0 = 0;
	for (i = 0; i < n; i++) {
		nwint d = g->ptr[i + 1] - g->ptr[i];
		if (delta < 0 || d < delta) { delta = d; v0 = i; }
	}
	minflow = delta;
	if (n <= 1) return minflow;
	/* the degree bound is already below the target: the Mata search runs no query either */
	if (has_target && minflow < target) return minflow;
	mark = (nwint *)calloc((size_t)n, sizeof(nwint));
	if (!mark) { g_oom = 1; return minflow; }
	if (vs_init(&vs, g)) { g_oom = 1; free(mark); return minflow; }

	stamp = 1;
	for (i = g->ptr[v0]; i < g->ptr[v0 + 1]; i++) mark[g->idx[i]] = stamp;
	for (i = 0; i < n && !(has_target && minflow < target); i++) {
		if (i != v0 && mark[i] != stamp) {
			f = vs_query(&vs, v0, i, minflow);
			if (g_oom) break;
			if (f < minflow) { minflow = f; *bs = v0; *bt = i; }
		}
	}
	{
		nwint nv = g->ptr[v0 + 1] - g->ptr[v0];
		const nwint *nb = g->idx + g->ptr[v0];
		for (a = 0; a < nv && !g_oom && !(has_target && minflow < target); a++) {
			stamp++;
			for (i = g->ptr[nb[a]]; i < g->ptr[nb[a] + 1]; i++) mark[g->idx[i]] = stamp;
			for (b = a + 1; b < nv && !(has_target && minflow < target); b++) {
				if (mark[nb[b]] != stamp) {
					f = vs_query(&vs, nb[a], nb[b], minflow);
					if (g_oom) break;
					if (f < minflow) { minflow = f; *bs = nb[a]; *bt = nb[b]; }
				}
			}
		}
	}
	vs_free(&vs);
	free(mark);
	return minflow;
}

/* port of min_vertex_cutset_edges_given; cut must hold n entries; returns its size */
static nwint cutset_given(const lg_t *g, nwint minflow, nwint bs, nwint bt, nwint *cut) {
	nwint n = g->n, i, j, v, a, nc = 0, delta, v0, qh, qt, e1;
	vs_t vs;
	if (bs < 0) {
		if (minflow == 0) return 0;
		delta = -1; v0 = 0;
		for (i = 0; i < n; i++) {
			nwint d = g->ptr[i + 1] - g->ptr[i];
			if (delta < 0 || d < delta) { delta = d; v0 = i; }
		}
		for (j = g->ptr[v0]; j < g->ptr[v0 + 1]; j++) cut[nc++] = g->idx[j];
		return nc;
	}
	if (vs_init(&vs, g)) { g_oom = 1; return 0; }
	vs.res[vs.split_in[bs]] = vs.bignum;
	vs.res[vs.split_in[bt]] = vs.bignum;
	(void)vs_augment(&vs, bs, bt, (nwint)vs.bignum * 4);
	if (g_oom) { vs_free(&vs); return 0; }
	/* nodes reachable from the out-node of bs in the residual graph of the maximum flow */
	vs.stamp++;
	qh = 0; qt = 0;
	vs.queue[qt++] = (int)(n + bs);
	vs.vis[n + bs] = vs.stamp;
	while (qh < qt) {
		v = vs.queue[qh++];
		e1 = vs.ptr[v + 1];
		for (a = vs.ptr[v]; a < e1; a++) {
			if (vs.res[a] > 0 && vs.vis[vs.to[a]] != vs.stamp) {
				vs.vis[vs.to[a]] = vs.stamp;
				vs.queue[qt++] = vs.to[a];
			}
		}
	}
	for (i = 0; i < n; i++) {
		if (i == bs || i == bt) continue;
		if (vs.vis[i] == vs.stamp && vs.vis[n + i] != vs.stamp) cut[nc++] = i;
	}
	vs_free(&vs);
	return nc;
}

/* ------------------------------------------------------------------ */
/* k-components and the cohesion hierarchy                              */
/* ------------------------------------------------------------------ */

typedef struct {
	ilist_t nodes;      /* all members, block after block */
	ilist_t start;      /* start offsets, one per block, plus a final sentinel kept in len */
	ilist_t kappa;
	ilist_t bs, bt;     /* witness pair of the connectivity search that certified the block (local indices) */
} blocks_t;

static int blocks_add(blocks_t *b, const nwint *nodes, nwint len, nwint kappa, nwint bs, nwint bt) {
	nwint i;
	if (il_push(&b->start, b->nodes.len)) return 1;
	if (il_push(&b->kappa, kappa)) return 1;
	if (il_push(&b->bs, bs) || il_push(&b->bt, bt)) return 1;
	for (i = 0; i < len; i++) if (il_push(&b->nodes, nodes[i])) return 1;
	return 0;
}

static void blocks_free(blocks_t *b) {
	il_free(&b->nodes); il_free(&b->start); il_free(&b->kappa); il_free(&b->bs); il_free(&b->bt);
}

static nwint blocks_count(const blocks_t *b) { return b->start.len; }
static nwint blocks_lo(const blocks_t *b, nwint i) { return b->start.a[i]; }
static nwint blocks_hi(const blocks_t *b, nwint i) { return i + 1 < b->start.len ? b->start.a[i + 1] : b->nodes.len; }

/* port of KComponentsEdges: appends every maximal set with connectivity >= k found inside nodes */
static int kcomp_rec(const csr_t *G, const nwint *nodes, nwint len, nwint k, const nwint *pre, blocks_t *out) {
	lg_t lg;
	nwint bs, bt, conn, nc, i, c, ncomp, qh, qt, u, l;
	nwint *cut = NULL, *queue = NULL;
	int *comp = NULL;
	char *incut = NULL;
	int rc = 0;

	if (len < k + 1) return 0;
	if (lg_build(G, nodes, len, &lg)) return 1;
	if (pre) { conn = pre[0]; bs = pre[1]; bt = pre[2]; }
	else conn = fmc_search(&lg, 1, k, &bs, &bt);
	if (g_oom) { lg_free(&lg); return 1; }
	if (conn >= k) {
		lg_free(&lg);
		/* a search that ran to the end returns the exact connectivity of the block: keep it for the hierarchy */
		return blocks_add(out, nodes, len, conn, bs, bt);
	}
	cut = (nwint *)malloc((size_t)(len + 1) * sizeof(nwint));
	incut = (char *)calloc((size_t)len, 1);
	comp = (int *)malloc((size_t)len * sizeof(int));
	queue = (nwint *)malloc((size_t)len * sizeof(nwint));
	if (!cut || !incut || !comp || !queue) { rc = 1; goto done; }
	nc = cutset_given(&lg, conn, bs, bt, cut);
	if (g_oom) { rc = 1; goto done; }
	for (i = 0; i < nc; i++) incut[cut[i]] = 1;
	for (i = 0; i < len; i++) comp[i] = 0;
	ncomp = 0;
	for (i = 0; i < len; i++) {
		if (incut[i] || comp[i]) continue;
		ncomp++;
		qh = 0; qt = 0;
		queue[qt++] = i;
		comp[i] = (int)ncomp;
		while (qh < qt) {
			u = queue[qh++];
			for (l = lg.ptr[u]; l < lg.ptr[u + 1]; l++) {
				nwint w = lg.idx[l];
				if (!incut[w] && !comp[w]) { comp[w] = (int)ncomp; queue[qt++] = w; }
			}
		}
	}
	lg_free(&lg);
	free(cut); cut = NULL; free(queue); queue = NULL;
	for (c = 1; c <= ncomp && !rc; c++) {
		nwint cnt = 0, p = 0;
		nwint *child;
		for (i = 0; i < len; i++) if (comp[i] == c || incut[i]) cnt++;
		child = (nwint *)malloc((size_t)(cnt > 0 ? cnt : 1) * sizeof(nwint));
		if (!child) { rc = 1; break; }
		for (i = 0; i < len; i++) if (comp[i] == c || incut[i]) child[p++] = nodes[i];
		rc = kcomp_rec(G, child, cnt, k, NULL, out);
		free(child);
	}
done:
	lg_free(&lg);
	free(cut); free(incut); free(comp); free(queue);
	return rc;
}

/* kappa < 0: not known yet. Otherwise kappa is the exact connectivity of the node set, found by a search that
   ended with the witness pair (bs,bt); the Mata hierarchy recomputes both, and the search that certifies a
   block of the parent's k-component step is the same sequence of queries as the one that measures it, so the
   values are identical. */
static int cohesion_rec(const csr_t *G, const nwint *nodes, nwint len, nwint kappa, nwint bs, nwint bt, blocks_t *out) {
	nwint i, nb;
	blocks_t kc;
	nwint pre[3];
	int rc = 0;
	memset(&kc, 0, sizeof(kc));
	if (kappa < 0) {
		kappa = 0; bs = -1; bt = -1;
		if (len > 1) {
			lg_t lg;
			if (lg_build(G, nodes, len, &lg)) return 1;
			kappa = fmc_search(&lg, 0, 0, &bs, &bt);
			lg_free(&lg);
			if (g_oom) return 1;
		}
	}
	if (blocks_add(out, nodes, len, kappa, bs, bt)) return 1;
	if (len < kappa + 2) return 0;
	pre[0] = kappa; pre[1] = bs; pre[2] = bt;
	if (kcomp_rec(G, nodes, len, kappa + 1, pre, &kc)) { blocks_free(&kc); return 1; }
	nb = blocks_count(&kc);
	for (i = 0; i < nb && !rc; i++) {
		nwint lo = blocks_lo(&kc, i), hi = blocks_hi(&kc, i);
		nwint *child = (nwint *)malloc((size_t)(hi - lo > 0 ? hi - lo : 1) * sizeof(nwint));
		if (!child) { rc = 1; break; }
		memcpy(child, kc.nodes.a + lo, (size_t)(hi - lo) * sizeof(nwint));
		rc = cohesion_rec(G, child, hi - lo, kc.kappa.a[i], kc.bs.a[i], kc.bt.a[i], out);
		free(child);
	}
	blocks_free(&kc);
	return rc;
}

/* args: n ; ties: symmetric 0/1 sorted list (both directions).  extra p1 = k (0 = hierarchy) */
static int comb_cohesion(nwint n, nwint nties, const nwint *ei, const nwint *ej, nwint kk) {
	csr_t G;
	blocks_t B;
	nwint *all, i, b, nb, tot, r;
	int rc = 0;
	memset(&B, 0, sizeof(B));
	g_oom = 0;
	if (csr_from_edges(&G, n, nties, ei, ej, NULL, 0, 1, 0)) return 2;
	g_loc = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	all = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	if (!g_loc || !all) { csr_free(&G); free(g_loc); free(all); g_loc = NULL; return 2; }
	for (i = 0; i < n; i++) { g_loc[i] = -1; all[i] = i; }
	if (kk <= 0) rc = cohesion_rec(&G, all, n, -1, -1, -1, &B);
	else rc = kcomp_rec(&G, all, n, kk, NULL, &B);
	free(g_loc); g_loc = NULL; free(all);
	csr_free(&G);
	if (rc) { blocks_free(&B); return 2; }
	nb = blocks_count(&B);
	tot = B.nodes.len;
	if (res_alloc(tot, 3)) { blocks_free(&B); return 2; }
	r = 0;
	for (b = 0; b < nb; b++) {
		nwint lo = blocks_lo(&B, b), hi = blocks_hi(&B, b), j;
		for (j = lo; j < hi; j++) {
			g_res[r * 3 + 0] = (double)(b + 1);
			g_res[r * 3 + 1] = (double)(B.nodes.a[j] + 1);
			g_res[r * 3 + 2] = (double)B.kappa.a[b];
			r++;
		}
	}
	blocks_free(&B);
	pub_result(0, tot, 3);
	pub_a(1, (double)nb);
	pub_a(2, (double)g_nsearch);
	pub_a(3, (double)g_nquery);
	pub_a(4, (double)g_nbfs);
	return 0;
}

/* ------------------------------------------------------------------ */
/* line connectivity: Gusfield equivalent-flow tree with Dinic          */
/* ------------------------------------------------------------------ */

typedef struct {
	nwint n, m2;             /* nodes, arcs */
	nwint *ptr, *to;         /* CSR of arcs, arc a pairs with rev[a] */
	nwint *rev;
	signed char *cap, *cap0;
	nwint *level, *it, *queue;
	nwint *stk;
} din_t;

static void din_free(din_t *d) {
	free(d->ptr); free(d->to); free(d->rev); free(d->cap); free(d->cap0);
	free(d->level); free(d->it); free(d->queue); free(d->stk);
	memset(d, 0, sizeof(*d));
}

/* G: symmetric simple graph (each undirected tie in both directions). */
static int din_init(din_t *d, const csr_t *G) {
	nwint n = G->n, m2 = G->ptr[n], u, k, v, p;
	nwint *pos;
	memset(d, 0, sizeof(*d));
	d->n = n; d->m2 = m2;
	d->ptr = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	d->to = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	d->rev = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	d->cap = (signed char *)malloc((size_t)(m2 > 0 ? m2 : 1));
	d->cap0 = (signed char *)malloc((size_t)(m2 > 0 ? m2 : 1));
	d->level = (nwint *)malloc((size_t)n * sizeof(nwint));
	d->it = (nwint *)malloc((size_t)n * sizeof(nwint));
	d->queue = (nwint *)malloc((size_t)n * sizeof(nwint));
	d->stk = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	pos = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	if (!d->ptr || !d->to || !d->rev || !d->cap || !d->cap0 || !d->level || !d->it || !d->queue || !d->stk || !pos) {
		free(pos); din_free(d); return 1;
	}
	memcpy(d->ptr, G->ptr, (size_t)(n + 1) * sizeof(nwint));
	memcpy(d->to, G->idx, (size_t)m2 * sizeof(nwint));
	for (u = 0; u < n; u++) pos[u] = d->ptr[u];
	/* the reverse of arc (u -> v) is the arc (v -> u): found by the position of u in v's list;
	   because lists are sorted and symmetric, walk u ascending and v's cursor advances in step. */
	for (u = 0; u < n; u++) {
		for (k = d->ptr[u]; k < d->ptr[u + 1]; k++) {
			v = d->to[k];
			if (v > u) {
				p = pos[v];
				while (d->to[p] != u) p++;
				pos[v] = p + 1;
				d->rev[k] = p;
				d->rev[p] = k;
			}
		}
	}
	free(pos);
	for (k = 0; k < m2; k++) d->cap0[k] = 1;
	return 0;
}

static int din_bfs(din_t *d, nwint s, nwint t) {
	nwint qh = 0, qt = 0, u, k, v;
	nwint i;
	for (i = 0; i < d->n; i++) d->level[i] = -1;
	d->level[s] = 0;
	d->queue[qt++] = s;
	while (qh < qt) {
		u = d->queue[qh++];
		for (k = d->ptr[u]; k < d->ptr[u + 1]; k++) {
			v = d->to[k];
			if (d->cap[k] > 0 && d->level[v] < 0) {
				d->level[v] = d->level[u] + 1;
				if (v == t) return 1;
				d->queue[qt++] = v;
			}
		}
	}
	return 0;
}

/* maximum flow s -> t, at most ub; leaves cap[] residual. returns the flow */
static nwint din_flow(din_t *d, nwint s, nwint t, nwint ub) {
	nwint flow = 0, top, u, k, v;
	nwint n = d->n;
	memcpy(d->cap, d->cap0, (size_t)(d->m2 > 0 ? d->m2 : 1));
	while (flow < ub && din_bfs(d, s, t)) {
		nwint i;
		for (i = 0; i < n; i++) d->it[i] = d->ptr[i];
		while (flow < ub) {
			/* iterative DFS for one augmenting path in the level graph; stk holds arcs */
			top = 0;
			u = s;
			while (u != t) {
				int adv = 0;
				for (; d->it[u] < d->ptr[u + 1]; d->it[u]++) {
					k = d->it[u];
					v = d->to[k];
					if (d->cap[k] > 0 && d->level[v] == d->level[u] + 1) {
						d->stk[top++] = k;
						u = v;
						adv = 1;
						break;
					}
				}
				if (!adv) {
					if (top == 0) break;
					/* retreat: mark u dead and step back along the arc we came by */
					d->level[u] = -2;
					k = d->stk[--top];
					u = d->to[d->rev[k]];
					d->it[u]++;
				}
			}
			if (u != t) break;
			for (i = 0; i < top; i++) {
				k = d->stk[i];
				d->cap[k]--;
				d->cap[d->rev[k]]++;
			}
			flow++;
		}
	}
	return flow;
}

/* residual reachability from s (after din_flow has stopped because no path remains) */
static void din_reach(din_t *d, nwint s, char *inX) {
	nwint qh = 0, qt = 0, u, k, v, i;
	for (i = 0; i < d->n; i++) inX[i] = 0;
	inX[s] = 1;
	d->queue[qt++] = s;
	while (qh < qt) {
		u = d->queue[qh++];
		for (k = d->ptr[u]; k < d->ptr[u + 1]; k++) {
			v = d->to[k];
			if (d->cap[k] > 0 && !inX[v]) { inX[v] = 1; d->queue[qt++] = v; }
		}
	}
}

static int comb_lambda(nwint n, nwint nties, const nwint *ei, const nwint *ej) {
	csr_t G;
	din_t d;
	nwint s, t, i, f, ub, ds, dt;
	nwint *par, *fl;
	char *inX;
	if (csr_from_edges(&G, n, nties, ei, ej, NULL, 0, 1, 0)) return 2;
	if (din_init(&d, &G)) { csr_free(&G); return 2; }
	par = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	fl = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	inX = (char *)malloc((size_t)(n > 0 ? n : 1));
	if (!par || !fl || !inX) { free(par); free(fl); free(inX); din_free(&d); csr_free(&G); return 2; }
	for (s = 1; s < n; s++) {
		t = par[s];
		ds = G.ptr[s + 1] - G.ptr[s];
		dt = G.ptr[t + 1] - G.ptr[t];
		ub = ds < dt ? ds : dt;
		f = din_flow(&d, s, t, ub);
		fl[s] = f;
		if (f == ub) {
			/* the degree bound is attained: the trivial cut around the smaller-degree end is a minimum cut */
			if (ds <= dt) {
				for (i = 0; i < n; i++) inX[i] = 0;
				inX[s] = 1;
			}
			else {
				for (i = 0; i < n; i++) inX[i] = 1;
				inX[t] = 0;
			}
		}
		else din_reach(&d, s, inX);
		for (i = s + 1; i < n; i++) if (inX[i] && par[i] == t) par[i] = s;
	}
	if (res_alloc(n, 2)) { free(par); free(fl); free(inX); din_free(&d); csr_free(&G); return 2; }
	for (i = 0; i < n; i++) {
		g_res[i * 2 + 0] = (double)(par[i] + 1);
		g_res[i * 2 + 1] = (double)fl[i];
	}
	free(par); free(fl); free(inX); din_free(&d); csr_free(&G);
	pub_result(0, n, 2);
	return 0;
}

/* ------------------------------------------------------------------ */
/* factions: greedy relocation with incremental fitness                  */
/* ------------------------------------------------------------------ */

typedef struct {
	double SA, SA2, M;
	int aconst;
} fac_stat_t;

static double fac_fit(const fac_stat_t *st, double W, double P) {
	double M = st->M, va, vp, num;
	if (st->aconst || P <= 0 || P >= M) return NAN;
	num = W - st->SA * P / M;
	va = st->SA2 - st->SA * st->SA / M;
	vp = P - P * P / M;
	if (!(va > 0) || !(vp > 0)) return NAN;
	return num / sqrt(va * vp);
}

/* a missing correlation compares larger than every real number (Mata semantics of . > x) */
static double fac_cmp(double x) { return isnan(x) ? INFINITY : x; }

/* ties: symmetric weighted list (both directions); v4 holds the starting groups (1..K) */
static int comb_factions(nwint n, nwint nties, const nwint *ei, const nwint *ej, const double *ew,
		double *grp0, nwint K, nwint maxiter) {
	csr_t G;
	fac_stat_t st;
	nwint i, k, g, sweep, moved, orig, bestg;
	nwint *grp, *size;
	double *S, W, P, bestfit, fit1, nnz = 0, w0 = 0;
	int allsame = 1;
	if (csr_from_edges(&G, n, nties, ei, ej, ew, 0, 1, 1)) return 2;
	grp = (nwint *)malloc((size_t)n * sizeof(nwint));
	size = (nwint *)calloc((size_t)(K + 2), sizeof(nwint));
	S = (double *)malloc((size_t)(K + 2) * sizeof(double));
	if (!grp || !size || !S) { free(grp); free(size); free(S); csr_free(&G); return 2; }
	for (i = 0; i < n; i++) { grp[i] = (nwint)grp0[i]; size[grp[i]]++; }
	st.SA = 0; st.SA2 = 0; st.M = (double)n * (double)(n - 1);
	for (k = 0; k < G.ptr[n]; k++) {
		double w = G.w[k];
		st.SA += w; st.SA2 += w * w; nnz += 1;
		if (nnz == 1) w0 = w; else if (w != w0) allsame = 0;
	}
	st.aconst = (nnz == 0) || (nnz == st.M && allsame);
	W = 0;
	for (i = 0; i < n; i++)
		for (k = G.ptr[i]; k < G.ptr[i + 1]; k++)
			if (grp[G.idx[k]] == grp[i]) W += G.w[k];
	P = 0;
	for (g = 1; g <= K; g++) P += (double)size[g] * (double)(size[g] - 1);
	sweep = 0; moved = 1;
	while (moved && sweep < maxiter) {
		moved = 0; sweep++;
		for (i = 0; i < n; i++) {
			orig = grp[i];
			bestg = orig;
			bestfit = fac_fit(&st, W, P);
			for (g = 0; g <= K; g++) S[g] = 0;
			for (k = G.ptr[i]; k < G.ptr[i + 1]; k++) S[grp[G.idx[k]]] += 2.0 * G.w[k];
			for (g = 1; g <= K; g++) {
				if (g == orig) continue;
				fit1 = fac_fit(&st, W - S[orig] + S[g],
					P - 2.0 * (double)(size[orig] - 1) + 2.0 * (double)size[g]);
				if (fac_cmp(fit1) > fac_cmp(bestfit) + 1e-12) { bestfit = fit1; bestg = g; }
			}
			if (bestg != orig) {
				W = W - S[orig] + S[bestg];
				P = P - 2.0 * (double)(size[orig] - 1) + 2.0 * (double)size[bestg];
				size[orig]--; size[bestg]++;
				grp[i] = bestg;
				moved = 1;
			}
		}
	}
	if (res_alloc(n, 1)) { free(grp); free(size); free(S); csr_free(&G); return 2; }
	for (i = 0; i < n; i++) g_res[i] = (double)grp[i];
	{
		double f = fac_fit(&st, W, P);
		pub_a(1, isnan(f) ? SV_missval : f);
		pub_a(2, (double)sweep);
	}
	free(grp); free(size); free(S); csr_free(&G);
	pub_result(0, n, 1);
	return 0;
}

/* ------------------------------------------------------------------ */
/* 4-node motif census (induced), exact integer arithmetic               */
/* ------------------------------------------------------------------ */

static int comb_motif4(nwint n, nwint nties, const nwint *ei, const nwint *ej) {
	csr_t G;
	nwint u, v, k, l, w;
	nwint *mark, *tv;
	int64_t star = 0, pathsub = 0, cyc2 = 0, paw = 0, dia = 0, k4 = 0, tri3 = 0, sumpath = 0;
	int64_t ind[6];
	double total;
	nwint *cnt;
	if (csr_from_edges(&G, n, nties, ei, ej, NULL, 0, 1, 0)) return 2;
	mark = (nwint *)malloc((size_t)n * sizeof(nwint));
	tv = (nwint *)calloc((size_t)n, sizeof(nwint));
	cnt = (nwint *)calloc((size_t)n, sizeof(nwint));
	if (!mark || !tv || !cnt) { free(mark); free(tv); free(cnt); csr_free(&G); return 2; }
	for (u = 0; u < n; u++) mark[u] = -1;

	/* stars, and the sum over ties of (d_u-1)(d_v-1) */
	for (u = 0; u < n; u++) {
		int64_t d = G.ptr[u + 1] - G.ptr[u];
		if (d >= 3) star += d * (d - 1) * (d - 2) / 6;
	}
	for (u = 0; u < n; u++) {
		int64_t du = G.ptr[u + 1] - G.ptr[u];
		for (k = G.ptr[u]; k < G.ptr[u + 1]; k++) {
			v = G.idx[k];
			if (v > u) {
				int64_t dv = G.ptr[v + 1] - G.ptr[v];
				sumpath += (du - 1) * (dv - 1);
			}
		}
	}

	/* triangles per tie and per node, diamonds (pairs of triangles on a tie), K4 */
	for (u = 0; u < n; u++) {
		for (k = G.ptr[u]; k < G.ptr[u + 1]; k++) mark[G.idx[k]] = u;
		for (k = G.ptr[u]; k < G.ptr[u + 1]; k++) {
			v = G.idx[k];
			if (v <= u) continue;
			{
				int64_t te = 0;
				nwint nw = 0;
				nwint wbuf_n = 0;
				(void)nw; (void)wbuf_n;
				for (l = G.ptr[v]; l < G.ptr[v + 1]; l++) {
					w = G.idx[l];
					if (mark[w] == u) te++;
				}
				tri3 += te;
				dia += te * (te - 1) / 2;
				tv[u] += te; tv[v] += te;
				/* triangles at the third node get counted when the other two ties are visited */
			}
		}
	}
	/* tv[x] now counts, for each triangle at x, the tie opposite... fix: each triangle {a,b,c}
	   was counted once per tie, adding te to the two endpoints of that tie; so tv[x] = 2 * (#triangles at x) */
	for (u = 0; u < n; u++) tv[u] = tv[u] / 2;
	/* tri3 = 3 * triangles (each triangle seen at each of its 3 ties u<v) */
	pathsub = sumpath - tri3;     /* sum (du-1)(dv-1) minus 3T */
	for (u = 0; u < n; u++) {
		int64_t d = G.ptr[u + 1] - G.ptr[u];
		if (d >= 2) paw += (int64_t)tv[u] * (d - 2);
	}
	/* 4-cycles: for every u, count paths u - x - w with w > u and accumulate codegrees */
	for (u = 0; u < n; u++) {
		ilist_t touched = {0, 0, 0};
		for (k = G.ptr[u]; k < G.ptr[u + 1]; k++) {
			nwint x = G.idx[k];
			for (l = G.ptr[x]; l < G.ptr[x + 1]; l++) {
				w = G.idx[l];
				if (w > u) {
					if (cnt[w] == 0) { if (il_push(&touched, w)) { il_free(&touched); free(mark); free(tv); free(cnt); csr_free(&G); return 2; } }
					cnt[w]++;
				}
			}
		}
		for (k = 0; k < touched.len; k++) {
			int64_t c = cnt[touched.a[k]];
			cyc2 += c * (c - 1) / 2;
			cnt[touched.a[k]] = 0;
		}
		il_free(&touched);
	}
	/* K4: tie (a,b), a<b, common neighbours c,d > b with c-d tied */
	{
		nwint *wl = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
		if (!wl) { free(mark); free(tv); free(cnt); csr_free(&G); return 2; }
		for (u = 0; u < n; u++) mark[u] = -1;
		for (u = 0; u < n; u++) {
			for (k = G.ptr[u]; k < G.ptr[u + 1]; k++) mark[G.idx[k]] = u;
			for (k = G.ptr[u]; k < G.ptr[u + 1]; k++) {
				nwint nwl = 0, a, b;
				v = G.idx[k];
				if (v <= u) continue;
				for (l = G.ptr[v]; l < G.ptr[v + 1]; l++) {
					w = G.idx[l];
					if (w > v && mark[w] == u) wl[nwl++] = w;
				}
				for (a = 0; a < nwl; a++)
					for (b = a + 1; b < nwl; b++)
						if (has_nbr(&G, wl[a], wl[b])) k4++;
			}
		}
		free(wl);
	}
	/* subgraph counts -> induced counts, order: path, star, cycle, paw, diamond, k4 */
	{
		int64_t sub_path = pathsub, sub_star = star, sub_cycle = cyc2 / 2, sub_paw = paw, sub_dia = dia, sub_k4 = k4;
		int64_t i_k4 = sub_k4;
		int64_t i_dia = sub_dia - 6 * i_k4;
		int64_t i_paw = sub_paw - 4 * i_dia - 12 * i_k4;
		int64_t i_cyc = sub_cycle - i_dia - 3 * i_k4;
		int64_t i_star = sub_star - i_paw - 2 * i_dia - 4 * i_k4;
		int64_t i_path = sub_path - 4 * i_cyc - 2 * i_paw - 6 * i_dia - 12 * i_k4;
		ind[0] = i_path; ind[1] = i_star; ind[2] = i_cyc; ind[3] = i_paw; ind[4] = i_dia; ind[5] = i_k4;
	}
	if (res_alloc(1, 7)) { free(mark); free(tv); free(cnt); csr_free(&G); return 2; }
	{
		int i;
		int64_t conn = 0;
		for (i = 0; i < 6; i++) { g_res[i] = (double)ind[i]; conn += ind[i]; }
		if (n <= 60000) {
			/* exact in 64 bits up to 60,000 nodes: C(n,4) = n(n-1)/2 * (n-2)/3 * (n-3)/4, each step an integer */
			int64_t t = (int64_t)n * (n - 1) / 2;
			t = t * (n - 2) / 3;
			t = t * (n - 3) / 4;
			g_res[6] = (double)(t - conn);
		}
		else {
			total = (double)n * (double)(n - 1) / 2.0 * (double)(n - 2) / 3.0 * (double)(n - 3) / 4.0;
			g_res[6] = total - (double)conn;
		}
	}
	free(mark); free(tv); free(cnt); csr_free(&G);
	pub_result(0, 1, 7);
	return 0;
}

/* ------------------------------------------------------------------ */
/* two-mode clustering (4-paths and 6-cycles), port of _nw2c_run         */
/* ------------------------------------------------------------------ */

/* measure: 0 binary, 1 arithmetic, 2 geometric, 3 maximum, 4 minimum.
   ties: raw out-neighbour lists with weights (as stored); v4 = 1 for the nodes of the requested level */
static int comb_cluster2(nwint n, nwint nties, const nwint *ei, const nwint *ej, const double *ew,
		const double *lvl, int measure) {
	csr_t G;
	nwint ci, c, ia0, ia1, ie0, ie2, a0, a1, e0, e2, k;
	nwint *mark;
	nwint stamp = 0;
	double total_pot = 0, total_clo = 0;
	if (csr_from_edges(&G, n, nties, ei, ej, ew, 0, 0, 1)) return 2;
	mark = (nwint *)calloc((size_t)n, sizeof(nwint));
	if (!mark || res_alloc(n, 2)) { free(mark); csr_free(&G); return 2; }
	for (ci = 0; ci < n; ci++) { g_res[ci * 2] = 0; g_res[ci * 2 + 1] = 0; }
	for (c = 0; c < n; c++) {
		nwint pc0 = G.ptr[c], pc1 = G.ptr[c + 1];
		double pot = 0, clo = 0;
		if (!(lvl[c] > 0.5)) continue;
		for (ia0 = pc0; ia0 < pc1; ia0++) {
			double w2 = 0;
			a0 = G.idx[ia0];
			if (measure) { nwint q = find_nbr(&G, a0, c); w2 = q >= 0 ? G.w[q] : 0; }
			for (ia1 = pc0; ia1 < pc1; ia1++) {
				double w3 = 0;
				if (ia1 == ia0) continue;
				a1 = G.idx[ia1];
				w3 = measure ? G.w[ia1] : 0;
				for (ie0 = G.ptr[a0]; ie0 < G.ptr[a0 + 1]; ie0++) {
					double w1 = 0;
					e0 = G.idx[ie0];
					if (e0 == c) continue;
					if (measure) { nwint q = find_nbr(&G, e0, a0); w1 = q >= 0 ? G.w[q] : 0; }
					stamp++;
					for (k = G.ptr[e0]; k < G.ptr[e0 + 1]; k++) mark[G.idx[k]] = stamp;
					for (ie2 = G.ptr[a1]; ie2 < G.ptr[a1 + 1]; ie2++) {
						double m = 1, w4;
						int closed = 0;
						e2 = G.idx[ie2];
						if (e2 == c || e2 == e0) continue;
						if (measure) {
							w4 = G.w[ie2];
							if (measure == 1) m = (w1 + w2 + w3 + w4) / 4;
							else if (measure == 2) m = pow(w1 * w2 * w3 * w4, 1.0 / 4);
							else if (measure == 3) {
								m = w1; if (w2 > m) m = w2; if (w3 > m) m = w3; if (w4 > m) m = w4;
							}
							else {
								m = w1; if (w2 < m) m = w2; if (w3 < m) m = w3; if (w4 < m) m = w4;
							}
						}
						for (k = G.ptr[e2]; k < G.ptr[e2 + 1]; k++) {
							nwint a2 = G.idx[k];
							if (mark[a2] == stamp && a2 != a0 && a2 != a1) { closed = 1; break; }
						}
						pot += m;
						total_pot += m;
						if (closed) { clo += m; total_clo += m; }
					}
				}
			}
		}
		g_res[c * 2] = pot;
		g_res[c * 2 + 1] = clo;
	}
	free(mark);
	csr_free(&G);
	pub_a(1, total_pot);
	pub_a(2, total_clo);
	pub_result(0, n, 2);
	return 0;
}

#include "nwcomb2.h"
#include "nwfast.h"
#include "nwbrokerage.h"
#include "nwfast2.h"
#include "nwburtw.h"
#include "nwnative370.h"
#include "nwnative380.h"
#include "nwnative390.h"

/* ------------------------------------------------------------------ */
/* dispatcher                                                           */
/* ------------------------------------------------------------------ */

static int comb_handles(const char *s) {
	nwint a = (nwint)atof(s);
	/* codes 20 and 21 belong to the k-connectivity search and the Kamada-Kawai kernel in nwgraph.c */
	return ((a >= 3 && a <= 9) || a == 22 || a == 23 || a == 24 || a == 25 || a == 26 || a == 27 || a == 28 || (a >= 29 && a <= 31) || (a >= 34 && a <= 39) || (a >= 40 && a <= 42) || (a >= 43 && a <= 49) || a == 50 || (a >= 51 && a <= 60) || a == 99 || a == 100);
}

static int comb_call(int argc, char *argv[]) {
	char *buf;
	double p[16];
	int np = 0, i;
	nwint alg, n, nties, k;
	nwint *ei = NULL, *ej = NULL;
	double *ew = NULL, *nv = NULL;
	int rc = 0;
	char *tok;

	if (argc < 1) return 198;
	buf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(buf, argv[0]);
	for (i = 0; i < 16; i++) p[i] = 0;
	tok = strtok(buf, " \t");
	while (tok && np < 16) { p[np++] = atof(tok); tok = strtok(NULL, " \t"); }
	free(buf);
	alg = (nwint)p[0];
	n = (nwint)p[1];
	nties = (nwint)p[2];

	if (alg == ALG_VERSION) {
		pub("__nwg_ver", (double)NWCOMB_VERSION);
		return 0;
	}
	if (alg == ALG_FETCH) {
		/* p[3] = number of output columns, written to variables 5.. */
		nwint r, c, cols = (nwint)p[3];
		for (c = 0; c < cols && c < g_res_cols; c++)
			for (r = 0; r < g_res_rows; r++)
				NW_VSTORE(5 + c, r + 1, g_res[r * g_res_cols + c]);
		res_clear();
		return 0;
	}

	if (nties > 0) {
		ei = (nwint *)malloc((size_t)nties * sizeof(nwint));
		ej = (nwint *)malloc((size_t)nties * sizeof(nwint));
		ew = (double *)malloc((size_t)nties * sizeof(double));
		if (!ei || !ej || !ew) { free(ei); free(ej); free(ew); pub_result(2, 0, 0); return 0; }
		for (k = 0; k < nties; k++) {
			ST_double v;
			NW_VDATA(1, k + 1, &v); ei[k] = (nwint)v;
			NW_VDATA(2, k + 1, &v); ej[k] = (nwint)v;
			NW_VDATA(3, k + 1, &v); ew[k] = v;
		}
	}
	if (alg == ALG_FACTIONS || alg == ALG_CLUSTER2 || alg == ALG_MATCHING || alg == ALG_LOUVBIP || alg == ALG_MATCHW || alg == ALG_BMOTIF || (alg >= 52 && alg <= 60)) {
		{ nwint nvn = (alg == 54) ? 2 * n : n;   /* kernel 54 takes two values per node */
		nv = (double *)malloc((size_t)(nvn > 0 ? nvn : 1) * sizeof(double));
		if (!nv) { free(ei); free(ej); free(ew); pub_result(2, 0, 0); return 0; }
		for (k = 0; k < nvn; k++) { ST_double v; NW_VDATA(4, k + 1, &v); nv[k] = v; } }
	}
	res_clear();
	if (alg >= 34 && alg <= 39) {
		rc = comb_fast2(alg, n, nties, ei, ej, ew, nv, p);
		free(ei); free(ej); free(ew); free(nv);
		if (rc == 2) { res_clear(); pub_result(2, 0, 0); }
		return rc == 198 ? 198 : 0;
	}
	if (alg >= 43 && alg <= 49) {
		rc = comb_n370(alg, n, nties, ei, ej, ew, nv, p);
		free(ei); free(ej); free(ew); free(nv);
		if (rc == 2) { res_clear(); pub_result(2, 0, 0); }
		return rc == 198 ? 198 : 0;
	}
	if (alg >= 51 && alg <= 60) {
		rc = comb_n390(alg, n, nties, ei, ej, ew, nv, p);
		free(ei); free(ej); free(ew); free(nv);
		if (rc == 2) { res_clear(); pub_result(2, 0, 0); }
		return rc == 198 ? 198 : 0;
	}
	if (alg == ALG_BMOTIF) {
		rc = comb_bmotif(n, nties, ei, ej, ew, nv, (int)p[3]);
		free(ei); free(ej); free(ew); free(nv);
		if (rc == 2) { res_clear(); pub_result(2, 0, 0); }
		return 0;
	}
	switch (alg) {
		case ALG_COHESION:
			rc = comb_cohesion(n, nties, ei, ej, (nwint)p[3]);
			break;
		case ALG_FACTIONS:
			rc = comb_factions(n, nties, ei, ej, ew, nv, (nwint)p[3], (nwint)p[4]);
			break;
		case ALG_LAMBDATREE:
			rc = comb_lambda(n, nties, ei, ej);
			break;
		case ALG_MOTIF4:
			rc = comb_motif4(n, nties, ei, ej);
			break;
		case ALG_CLUSTER2:
			rc = comb_cluster2(n, nties, ei, ej, ew, nv, (int)p[3]);
			break;
		case ALG_NCLIQUE:
			rc = comb_nclique(n, nties, ei, ej, ew, p);
			break;
		case ALG_KPLEX:
			rc = comb_kplex(n, nties, ei, ej, p);
			break;
		case ALG_BALANCE:
			rc = comb_balance(n, nties, ei, ej, ew);
			break;
		case ALG_MATCHING:
			rc = comb_matching(n, nties, ei, ej, nv);
			break;
		case ALG_LOUVAIN:
			rc = comb_louvain(n, nties, ei, ej, ew, p[3]);
			break;
		case ALG_DISTSUM:
			rc = comb_distsum(n, nties, ei, ej, (int)p[3], p[4]);
			break;
		case ALG_CLUSTERING:
			rc = comb_clustering(n, nties, ei, ej, (int)p[3]);
			break;
		case ALG_TRIADS:
			rc = comb_triads(n, nties, ei, ej);
			break;
		case ALG_EVCENT:
			rc = comb_evcent(n, nties, ei, ej, ew, (int)p[3], (int)p[4]);
			break;
		case ALG_BURT:
			rc = comb_burt(n, nties, ei, ej, ew);
			break;
		case ALG_CONSTRAINT:
			rc = comb_constraint(n, nties, ei, ej, ew);
			break;
		case ALG_BURTW:
			rc = comb_burtw(n, nties, ei, ej, ew);
			break;
		case ALG_SIMMELIAN:
			rc = comb_simmelian(n, nties, ei, ej);
			break;
		default:
			SF_error("nwgraph: unknown algorithm code\n");
			free(ei); free(ej); free(ew); free(nv);
			return 198;
	}
	free(ei); free(ej); free(ew); free(nv);
	if (rc == 2) { res_clear(); pub_result(2, 0, 0); }
	else if (rc == 1) { res_clear(); pub_result(1, 0, 0); }
	return 0;
}
