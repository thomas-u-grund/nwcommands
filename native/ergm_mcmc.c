/*
	ergm_mcmc.c -- native (C) Metropolis-Hastings MCMC kernel for nwergm's
	ERGM sampler (harmonisation unit 83, docs/CERTIFICATION.md).

	WHY THIS EXISTS: docs/ERGM_STATNET_STUDY.md documents (Part I, this
	project's own earlier clean-room architecture study) and a fresh
	verification pass against Statnet's own current C source (August 2026,
	statnet/ergm on GitHub - inst/include/ergm_edgetree.h,
	src/changestats_spcache.c, src/MHproposals.c) both confirm Statnet
	implements its own MCMC proposal/toggle/change-statistic loop in
	compiled C, never crossing into R inside that loop. A direct Mata
	microbenchmark of nwergm's own primitives
	(dev/ergm_benchmark_r_vs_stata/50_microbench_primitives.do) found
	change_gwesp() costing 17-29 microseconds/call versus ~0.3
	microseconds/call for edges/mutual/nodematch - a ~50-100x gap that is
	NOT explained by algorithmic complexity (the shared-partner traversal
	touches only a handful of neighbors at these networks' actual degree)
	but by Mata's own per-call/per-hash-lookup/per-allocation interpreter
	overhead compounding over many small operations. Statnet's own
	shared-partner cache update cost is ALSO O(degree) per toggle (fresh
	verification, above) - the same order as nwergm's own Mata
	implementation - so the gap is specifically compiled-vs-interpreted
	execution of the SAME algorithm, not a smarter algorithm. This is
	exactly the profile where moving to compiled code helps, and the
	explicit trigger for relaxing this project's earlier Mata-first
	default (see docs/ERGM_ROADMAP.md's "Native backend" section for the
	full decision record).

	SCOPE (deliberately narrow - see docs/ERGM_ARCHITECTURE.md): supports
	exactly the four terms already exercised by the R-vs-Stata benchmark
	suite (edges, mutual, nodematch, gwesp), the two existing proposals
	(uniform, TNT), directed and undirected graphs. Any model using a term
	outside this set is NOT eligible for the native backend - the Mata
	implementation (unw_ergm.do) remains the reference/fallback and is
	unchanged; nwergm.ado decides per-model, per-call which backend to use
	and both must be statistically indistinguishable (see
	cscripts/test_nwergm_native.do).

	BOUNDARY: one plugin call per ErgmMCMCSample()/ErgmMCMCSampleDiag()
	invocation - i.e., once per MCMLE iteration, not once per MCMC step
	(explicitly required: crossing the Mata/Stata/native boundary on every
	single proposal, potentially millions of times, would reintroduce the
	same interpreter-crossing overhead this file exists to eliminate). The
	entire burnin+sampling loop (propose, evaluate every term's change
	statistic, accept/reject, toggle, record) runs inside this one call.

	GRAPH REPRESENTATION: a single open-addressing hash table (tombstone
	deletion, periodic compaction) maps a canonical dyad key -> its row
	index in a dynamic "live edge list" array (dyadht_t/edgelist_t below) -
	this single structure gives O(1) average has_edge() AND O(1) average
	removal-by-position (via swap-with-last, exactly mirroring
	ErgmGraph::elist/edgepos in unw_ergm.do), which is what TNT's own
	tie-pick needs. Per-node adjacency arrays (needed only to enumerate
	neighbors for GWESP's shared-partner traversal on undirected graphs)
	are allocated and maintained ONLY when a gwesp term is present in the
	model - directed-only models (edges+mutual+nodematch) never pay for
	them, matching ErgmGraph's own "sp_cache_enabled costs nothing unless
	requested" discipline.

	NO shared-partner CACHE is implemented here, deliberately: unit 82
	found an incremental shared-partner cache to be a NET LOSS below
	roughly degree 30-40 even after accounting for Mata's own interpreter
	overhead (the cache's own maintenance cost is what dominates, not
	lookup cost) - in compiled C the per-operation costs driving that
	finding shrink by roughly the same amount on both sides of the
	tradeoff, so there is no evidence a cache would newly pay off here; the
	on-demand common_neighbors()-style traversal below is a direct,
	correctness-preserving port of unw_ergm.do's own default (cache-
	disabled) code path. A future degree-adaptive cache remains a
	documented open item (docs/ERGM_ROADMAP.md), not implemented here to
	keep this unit's scope controlled per its own governing instructions.

	RNG: a self-contained xorshift128+ generator (Vigna & Blackman 2014
	construction; public-domain algorithm, reimplemented from the published
	recurrence here, no third-party source copied), seeded from a single
	unsigned integer that the Mata caller draws via runiform() immediately
	before the plugin call - so the same Stata `set seed` reproducibly
	drives the same native-backend run (see unw_ergm.do's
	ErgmMCMCSampleNative() wrapper). This is NOT the same RNG stream as
	Mata's own runiform() - native and Mata backends will not produce
	bit-identical sample paths for the same seed, only statistically
	equivalent distributions (matching this unit's own cross-certification
	contract, cscripts/test_nwergm_native.do) - only a run's own
	reproducibility (same seed -> same native result, every time) is
	claimed or required.

	TERM DISPATCH: a fixed small array of (termcode, decay) pairs, parsed
	once at the top of stata_call() from the args string, indexed 0..
	nterms-1 thereafter inside the hot loop via a plain switch() - no
	string parsing, no per-step allocation, inside the loop itself (see
	change_term() below). Adding a fifth native term means adding one
	TERMCODE_* constant, one case in change_term(), and one code in
	nwergm.ado's own native-eligibility check - the loop structure itself
	does not change.
*/

#include "stplugin.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* ===================================================================
   xorshift128+ RNG
   =================================================================== */

typedef struct { unsigned long long s0, s1; } rng_t;

static unsigned long long splitmix64_next(unsigned long long *x) {
	unsigned long long z = (*x += 0x9E3779B97F4A7C15ULL);
	z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
	z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
	return z ^ (z >> 31);
}

static void rng_seed(rng_t *r, unsigned long long seed) {
	unsigned long long sm = seed ? seed : 0xA5A5A5A5A5A5A5A5ULL;
	r->s0 = splitmix64_next(&sm);
	r->s1 = splitmix64_next(&sm);
	if (r->s0 == 0 && r->s1 == 0) r->s0 = 1;
}

static unsigned long long rng_next(rng_t *r) {
	unsigned long long x = r->s0, y = r->s1;
	r->s0 = y;
	x ^= x << 23;
	x ^= x >> 17;
	x ^= y ^ (y >> 26);
	r->s1 = x;
	return x + y;
}

/* uniform double in [0,1), 53 bits of precision */
static double rng_unif(rng_t *r) {
	return (double)(rng_next(r) >> 11) * (1.0 / 9007199254740992.0);
}

/* uniform integer in [0, n-1], n >= 1 */
static long rng_below(rng_t *r, long n) {
	return (long)(rng_unif(r) * (double)n);
}

/* ===================================================================
   Dyad hash table: canonical (i,j) -> row index into the live edge
   list. Open addressing, linear probing, tombstone deletion with
   periodic compaction (rehash keeping only live entries) once
   (live+tombstones) exceeds 60% of capacity - avoids the more
   intricate backward-shift-on-delete algorithm while still bounding
   probe length in the long run of a multi-million-step chain.
   =================================================================== */

typedef struct {
	long *keys;      /* encoded dyad key per slot */
	long *vals;      /* row index into edge list per slot */
	unsigned char *state; /* 0=empty 1=live 2=tomb */
	long cap;
	long nlive;
	long ntomb;
} dyadht_t;

static long ht_next_pow2(long n) {
	long p = 16;
	while (p < n) p <<= 1;
	return p;
}

static void ht_alloc(dyadht_t *h, long cap) {
	h->cap = cap;
	h->keys = (long *)calloc((size_t)cap, sizeof(long));
	h->vals = (long *)calloc((size_t)cap, sizeof(long));
	h->state = (unsigned char *)calloc((size_t)cap, sizeof(unsigned char));
	h->nlive = 0;
	h->ntomb = 0;
}

static void ht_free(dyadht_t *h) {
	free(h->keys); free(h->vals); free(h->state);
	h->keys = NULL; h->vals = NULL; h->state = NULL;
}

static long ht_hash(long key, long cap) {
	unsigned long long k = (unsigned long long)key;
	k ^= k >> 33; k *= 0xff51afd7ed558ccdULL;
	k ^= k >> 33; k *= 0xc4ceb9fe1a85ec53ULL;
	k ^= k >> 33;
	return (long)(k & (unsigned long long)(cap - 1));
}

static void ht_rehash(dyadht_t *h, long newcap) {
	dyadht_t old = *h;
	long i, slot;
	ht_alloc(h, newcap);
	for (i = 0; i < old.cap; i++) {
		if (old.state[i] != 1) continue;
		slot = ht_hash(old.keys[i], h->cap);
		while (h->state[slot] == 1) slot = (slot + 1) & (h->cap - 1);
		h->state[slot] = 1;
		h->keys[slot] = old.keys[i];
		h->vals[slot] = old.vals[i];
		h->nlive++;
	}
	ht_free(&old);
}

static void ht_maybe_grow(dyadht_t *h) {
	if ((h->nlive + h->ntomb) * 10 >= h->cap * 6) {
		long newcap = (h->nlive * 3 >= h->cap) ? h->cap * 2 : h->cap;
		ht_rehash(h, newcap);
	}
}

/* returns 1 if found (val set), 0 otherwise */
static int ht_get(dyadht_t *h, long key, long *val) {
	long slot = ht_hash(key, h->cap);
	long start = slot;
	while (h->state[slot] != 0) {
		if (h->state[slot] == 1 && h->keys[slot] == key) { *val = h->vals[slot]; return 1; }
		slot = (slot + 1) & (h->cap - 1);
		if (slot == start) return 0;
	}
	return 0;
}

static void ht_put(dyadht_t *h, long key, long val) {
	long slot = ht_hash(key, h->cap);
	while (h->state[slot] == 1) {
		if (h->keys[slot] == key) { h->vals[slot] = val; return; }
		slot = (slot + 1) & (h->cap - 1);
	}
	if (h->state[slot] == 2) h->ntomb--;
	h->state[slot] = 1;
	h->keys[slot] = key;
	h->vals[slot] = val;
	h->nlive++;
	ht_maybe_grow(h);
}

/* removes key, returns its old val (row index) via *val; caller must
   have confirmed presence (has_edge) already in every call site below */
static void ht_del(dyadht_t *h, long key, long *val) {
	long slot = ht_hash(key, h->cap);
	while (h->state[slot] != 0) {
		if (h->state[slot] == 1 && h->keys[slot] == key) {
			*val = h->vals[slot];
			h->state[slot] = 2;
			h->nlive--;
			h->ntomb++;
			return;
		}
		slot = (slot + 1) & (h->cap - 1);
	}
	*val = -1; /* should not happen - caller error */
}

static void ht_update_val(dyadht_t *h, long key, long newval) {
	long slot = ht_hash(key, h->cap);
	while (h->state[slot] != 0) {
		if (h->state[slot] == 1 && h->keys[slot] == key) { h->vals[slot] = newval; return; }
		slot = (slot + 1) & (h->cap - 1);
	}
}

/* ===================================================================
   Dynamic per-node adjacency arrays (undirected, GWESP only)
   =================================================================== */

typedef struct {
	long *nb;
	long len;
	long cap;
} adjlist_t;

static void adj_init(adjlist_t *a) { a->nb = NULL; a->len = 0; a->cap = 0; }

static void adj_add(adjlist_t *a, long j) {
	if (a->len >= a->cap) {
		a->cap = a->cap ? a->cap * 2 : 4;
		a->nb = (long *)realloc(a->nb, (size_t)a->cap * sizeof(long));
	}
	a->nb[a->len++] = j;
}

static void adj_remove(adjlist_t *a, long j) {
	long k;
	for (k = 0; k < a->len; k++) {
		if (a->nb[k] == j) {
			a->nb[k] = a->nb[a->len - 1];
			a->len--;
			return;
		}
	}
}

/* ===================================================================
   Graph state
   =================================================================== */

typedef struct {
	long n;
	int directed;
	int need_adj;      /* 1 iff a gwesp term is present (undirected only) */
	dyadht_t ht;
	long *elist_i, *elist_j; /* live edge list, parallel arrays */
	long ecap, nties;
	long *deg;               /* undirected: total degree; directed: out+in not tracked separately here since only needed for common-neighbor smaller-side heuristic on undirected graphs */
	adjlist_t *adj;          /* size n+1, 1-indexed; only if need_adj */
} graph_t;

static long dyadkey(graph_t *g, long i, long j) {
	long a = i, b = j;
	if (!g->directed) { if (a > b) { long t = a; a = b; b = t; } }
	return a * (g->n + 1) + b;
}

static int has_edge(graph_t *g, long i, long j) {
	long val;
	return ht_get(&g->ht, dyadkey(g, i, j), &val);
}

static void elist_ensure(graph_t *g, long need) {
	if (need <= g->ecap) return;
	g->ecap = g->ecap ? g->ecap * 2 : 8;
	if (g->ecap < need) g->ecap = need;
	g->elist_i = (long *)realloc(g->elist_i, (size_t)g->ecap * sizeof(long));
	g->elist_j = (long *)realloc(g->elist_j, (size_t)g->ecap * sizeof(long));
}

/* toggles dyad (i,j); returns 1 if the tie was ADDED, 0 if REMOVED */
static int toggle(graph_t *g, long i, long j) {
	long key = dyadkey(g, i, j);
	long pos;
	int was_edge = ht_get(&g->ht, key, &pos);

	if (was_edge) {
		long lastpos = g->nties - 1;
		if (pos != lastpos) {
			long li = g->elist_i[lastpos], lj = g->elist_j[lastpos];
			g->elist_i[pos] = li; g->elist_j[pos] = lj;
			ht_update_val(&g->ht, dyadkey(g, li, lj), pos);
		}
		{ long dummy; ht_del(&g->ht, key, &dummy); }
		g->nties--;
		g->deg[i]--; g->deg[j]--;
		if (g->need_adj && !g->directed) { adj_remove(&g->adj[i], j); adj_remove(&g->adj[j], i); }
		return 0;
	}
	else {
		elist_ensure(g, g->nties + 1);
		g->elist_i[g->nties] = i;
		g->elist_j[g->nties] = j;
		ht_put(&g->ht, key, g->nties);
		g->nties++;
		g->deg[i]++; g->deg[j]++;
		if (g->need_adj && !g->directed) { adj_add(&g->adj[i], j); adj_add(&g->adj[j], i); }
		return 1;
	}
}

/* number of common neighbors of i and j (undirected sense - the shared-
   partner count GWESP needs), via the smaller-degree side, exactly
   mirroring ErgmGraph::common_neighbors() in unw_ergm.do */
static long common_neighbors(graph_t *g, long i, long j) {
	long a = i, b = j, k, cnt = 0;
	adjlist_t *nb;
	if (g->deg[i] > g->deg[j]) { a = j; b = i; }
	nb = &g->adj[a];
	for (k = 0; k < nb->len; k++) {
		if (nb->nb[k] != b && has_edge(g, b, nb->nb[k])) cnt++;
	}
	return cnt;
}

static double gw_kernel(double d, double decay) {
	return exp(decay) * (1.0 - pow(1.0 - exp(-decay), d));
}

/* GWESP change statistic for toggling (i,j) - direct port of
   change_gwesp() in unw_ergm.do (undirected only) */
static double change_gwesp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors(g, i, j);
	double chg = delta * gw_kernel(pij, decay);
	adjlist_t *nbi = &g->adj[i];
	long m;
	for (m = 0; m < nbi->len; m++) {
		long k = nbi->nb[m];
		double pik, pjk;
		if (k == j) continue;
		if (!has_edge(g, j, k)) continue;
		pik = (double)common_neighbors(g, i, k);
		chg += gw_kernel(pik + delta, decay) - gw_kernel(pik, decay);
		pjk = (double)common_neighbors(g, j, k);
		chg += gw_kernel(pjk + delta, decay) - gw_kernel(pjk, decay);
	}
	return chg;
}

/* ===================================================================
   Term dispatch (fixed small term list, resolved once - see file
   header comment)
   =================================================================== */

#define TERMCODE_EDGES     1
#define TERMCODE_MUTUAL    2
#define TERMCODE_NODEMATCH 3
#define TERMCODE_GWESP     4

static double change_term(graph_t *g, int termcode, double decay, double *attr, long i, long j) {
	switch (termcode) {
		case TERMCODE_EDGES:
			return has_edge(g, i, j) ? -1.0 : 1.0;
		case TERMCODE_MUTUAL:
			if (!has_edge(g, j, i)) return 0.0;
			return has_edge(g, i, j) ? -1.0 : 1.0;
		case TERMCODE_NODEMATCH:
			if (attr[i] != attr[j]) return 0.0;
			return has_edge(g, i, j) ? -1.0 : 1.0;
		case TERMCODE_GWESP:
			return change_gwesp(g, i, j, decay);
	}
	return 0.0;
}

/* ===================================================================
   Proposals (mirrors ergm_propose_uniform()/ergm_propose_tnt() in
   unw_ergm.do exactly, including the TNT Hastings-ratio formulas -
   see that file's own header comments for the derivation and
   docs/ERGM_STATNET_STUDY.md Appendix B section 6 for the fresh
   verification against Statnet's own current MHproposals.c)
   =================================================================== */

static double total_dyads(graph_t *g) {
	double n = (double)g->n;
	return g->directed ? n * (n - 1.0) : n * (n - 1.0) / 2.0;
}

static void propose_uniform(graph_t *g, rng_t *rng, long *pi, long *pj, double *logratio) {
	double Dtot = total_dyads(g);
	long pick = 1 + (long)(rng_unif(rng) * Dtot);
	long i, j, row, col;
	if (g->directed) {
		row = (pick - 1) / (g->n - 1) + 1;
		col = (pick - 1) % (g->n - 1) + 1;
		i = row;
		j = (col < row) ? col : col + 1;
	}
	else {
		i = 1;
		while (pick > g->n - i) { pick -= (g->n - i); i++; }
		j = i + pick;
	}
	*pi = i; *pj = j; *logratio = 0.0;
}

static void propose_tnt(graph_t *g, rng_t *rng, long *pi, long *pj, double *logratio) {
	double Dtot = total_dyads(g);
	double E = (double)g->nties;
	double P = 0.5, Q = 0.5;
	double DP = P * Dtot;
	double DO = DP / Q;
	long i, j;

	if (rng_unif(rng) < P && g->nties > 0) {
		long erow = rng_below(rng, g->nties);
		i = g->elist_i[erow];
		j = g->elist_j[erow];
	}
	else {
		double lr;
		propose_uniform(g, rng, &i, &j, &lr);
	}

	if (has_edge(g, i, j)) {
		*logratio = (E == 1) ? -log(DP + Q) : log(E / (DO + E));
	}
	else {
		*logratio = (E == 0) ? log(DP + Q) : log(1.0 + DO / (E + 1.0));
	}
	*pi = i; *pj = j;
}

/* ===================================================================
   Small string-token reader over the single args string Stata hands
   the plugin in argv[0] (empirically confirmed NOT pre-tokenized by
   Stata - see native/smoke/'s own probe and
   docs/ERGM_ARCHITECTURE.md's native-backend section for this and
   other Stata Plugin Interface contract details confirmed by direct
   trial rather than assumed from general SPI documentation).
   =================================================================== */

/* plain strtok(), not the reentrant _r variant: this plugin never
   tokenizes more than one string at a time (no nesting/concurrency),
   and plain strtok() is available unchanged across the mac/Linux/
   Windows C runtimes this project's own build docs target - avoids
   relying on the POSIX-only strtok_r()/Windows-only strtok_s() split. */
static double next_double(void) {
	char *tok = strtok(NULL, " \t");
	return tok ? atof(tok) : 0.0;
}
static long next_long(void) {
	return (long)next_double();
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long n, directed, nties_in, samplesize, burnin, interval, proposal_code, nterms, i, k;
	unsigned long long rngseed;
	int termcodes[16];
	double decays[16];
	double theta[16];
	double obs[16];
	double *attr = NULL;
	graph_t g;
	rng_t rng;
	double *cur;
	long naccept = 0, ntried = 0;
	long draw, step;
	int need_adj = 0;

	if (argc < 1) { SF_error("ergm_mcmc: missing argument string\n"); return(198); }

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	n             = (long)atof(strtok(argbuf, " \t"));
	directed      = next_long();
	nties_in      = next_long();
	samplesize    = next_long();
	burnin        = next_long();
	interval      = next_long();
	proposal_code = next_long();
	rngseed       = (unsigned long long)next_double();
	nterms        = next_long();
	if (nterms > 16) { SF_error("ergm_mcmc: too many terms\n"); free(argbuf); return(198); }
	for (i = 0; i < nterms; i++) {
		termcodes[i] = (int)next_long();
		decays[i] = next_double();
		if (termcodes[i] == TERMCODE_GWESP) need_adj = 1;
	}
	for (i = 0; i < nterms; i++) theta[i] = next_double();
	for (i = 0; i < nterms; i++) obs[i] = next_double();
	free(argbuf);

	/* --- build graph from dataset columns v1=ego v2=alter (rows
	   1..nties_in), v3=attr (rows 1..n) --- */
	g.n = n;
	g.directed = (int)directed;
	g.need_adj = need_adj;
	ht_alloc(&g.ht, ht_next_pow2(nties_in * 2 + 16));
	g.elist_i = NULL; g.elist_j = NULL; g.ecap = 0; g.nties = 0;
	g.deg = (long *)calloc((size_t)(n + 1), sizeof(long));
	g.adj = NULL;
	if (need_adj) {
		g.adj = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		for (i = 0; i <= n; i++) adj_init(&g.adj[i]);
	}
	attr = (double *)calloc((size_t)(n + 1), sizeof(double));
	for (i = 1; i <= n; i++) {
		ST_double v;
		SF_vdata(3, i, &v);
		attr[i] = SF_is_missing(v) ? 0.0 : v;
	}
	for (i = 1; i <= nties_in; i++) {
		ST_double vi, vj;
		SF_vdata(1, i, &vi);
		SF_vdata(2, i, &vj);
		toggle(&g, (long)vi, (long)vj);
	}

	rng_seed(&rng, rngseed);
	cur = (double *)malloc((size_t)nterms * sizeof(double));
	for (i = 0; i < nterms; i++) cur[i] = obs[i];

	for (step = 0; step < burnin; step++) {
		long pi, pj;
		double logratio, cutoff = 0.0;
		double chg[16];
		if (proposal_code == 2) propose_tnt(&g, &rng, &pi, &pj, &logratio);
		else propose_uniform(&g, &rng, &pi, &pj, &logratio);
		for (k = 0; k < nterms; k++) {
			chg[k] = change_term(&g, termcodes[k], decays[k], attr, pi, pj);
			cutoff += theta[k] * chg[k];
		}
		cutoff += logratio;
		if (cutoff >= 0.0 || log(rng_unif(&rng)) < cutoff) {
			toggle(&g, pi, pj);
			for (k = 0; k < nterms; k++) cur[k] += chg[k];
		}
	}

	for (draw = 0; draw < samplesize; draw++) {
		for (step = 0; step < interval; step++) {
			long pi, pj;
			double logratio, cutoff = 0.0;
			double chg[16];
			if (proposal_code == 2) propose_tnt(&g, &rng, &pi, &pj, &logratio);
			else propose_uniform(&g, &rng, &pi, &pj, &logratio);
			for (k = 0; k < nterms; k++) {
				chg[k] = change_term(&g, termcodes[k], decays[k], attr, pi, pj);
				cutoff += theta[k] * chg[k];
			}
			cutoff += logratio;
			ntried++;
			if (cutoff >= 0.0 || log(rng_unif(&rng)) < cutoff) {
				toggle(&g, pi, pj);
				for (k = 0; k < nterms; k++) cur[k] += chg[k];
				naccept++;
			}
		}
		for (k = 0; k < nterms; k++) SF_vstore((int)(4 + k), draw + 1, cur[k]);
	}

	/* write back final edge list so the Mata caller can rebuild its own
	   ErgmGraph to carry state into the next MCMLE iteration (sequential
	   MCMLE - matches ErgmMCMCSample()'s own in-place-mutation contract) */
	for (i = 0; i < g.nties; i++) {
		SF_vstore(1, i + 1, (ST_double)g.elist_i[i]);
		SF_vstore(2, i + 1, (ST_double)g.elist_j[i]);
	}

	SF_scal_save("__ergm_native_nties_out", (ST_double)g.nties);
	SF_scal_save("__ergm_native_naccept", (ST_double)naccept);
	SF_scal_save("__ergm_native_ntried", (ST_double)ntried);

	free(cur);
	free(attr);
	free(g.deg);
	ht_free(&g.ht);
	free(g.elist_i); free(g.elist_j);
	if (g.adj) {
		for (i = 0; i <= n; i++) free(g.adj[i].nb);
		free(g.adj);
	}

	return(0);
}
