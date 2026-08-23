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

	SCOPE: originally exactly the four terms exercised by the R-vs-Stata
	benchmark suite (edges, mutual, nodematch, gwesp). Relaxed
	(harmonisation unit 91 follow-on, per explicit user instruction to
	"move all effects to C" rather than have any term outside a narrow
	set force the WHOLE model back onto the Mata sampler) to also cover
	the full dyad-independent attribute/factor family - nodecov/
	nodeicov/nodeocov/absdist/nodematch_diff/nodefactor/nodeofactor/
	nodeifactor/sender/receiver/nodemix - and the GW-degree family -
	gwdegree/gwodegree/gwidegree. See TERMCODE_* below for the complete
	current list and unw_ergm.do's own ErgmNativeSetup() header comment
	for exactly what is still NOT covered (edgecov/hamming - need an
	n x n matrix marshalled across the boundary; the degree-COUNT family
	degree/odegree/idegree/concurrent/degrange/kstar - needs threshold-
	crossing logic not yet ported; the shared-partner family beyond
	gwesp itself - gwdsp/gwnsp/esp/dsp/triangle/ctriple/transitiveties/
	cyclicalties; and directed/OTP gwesp specifically) and why - each a
	well-scoped, documented follow-on, not attempted here to keep this
	wave's own scope controlled. The two existing proposals (uniform,
	TNT), directed and undirected graphs, are unchanged. Any model using
	a term outside the current native set is NOT eligible for the native
	backend - the Mata implementation (unw_ergm.do) remains the
	reference/fallback and is unchanged; nwergm.ado decides per-model,
	per-call which backend to use and both must be statistically
	indistinguishable (see cscripts/test_nwergm_native.do).

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

	TERM DISPATCH: a fixed small array of per-OUTPUT-COLUMN slots
	(termcode, attridx, p1, p2), parsed once at the top of stata_call()
	from the args string, indexed 0..nterms-1 thereafter inside the hot
	loop via a plain switch() - no string parsing, no per-step
	allocation, inside the loop itself (see change_term() below). A
	multi-column Mata term (e.g. nodefactor with 3 levels) occupies 3
	CONSECUTIVE slots here, one per level, each carrying its own target
	level value in `p1` - this is Mata-side ErgmNativeSetup()'s own
	job to expand, not something this file needs to know about term
	"instances" versus term "columns" at all. `attridx` (0 = none, else
	1-based) selects which of the model's own distinct attribute arrays
	(read once at the top of stata_call() into `attrs[]`, one frame
	variable per array) a given slot needs - this is what lets several
	DIFFERENT covariates (e.g. nodecov(age) and nodematch(sex) in the
	same model) coexist without treating "the model's attribute array"
	as a single global the way the original 4-term version of this file
	did (nodematch was the only attribute consumer then, so one shared
	array sufficed). `p1`/`p2` are two generic per-slot scalar
	parameters - decay for the geometrically-weighted terms, a target
	attribute level for the factor/match family, a level-PAIR (p1=lo,
	p2=hi) for nodemix. Adding a new native term means adding one
	TERMCODE_* constant, one case in change_term() (and possibly one
	array in graph_t/toggle() if it needs new per-node bookkeeping, the
	way `outdeg`/`indeg` were added for the GW-degree family below), and
	one branch in unw_ergm.do's own ErgmNativeSetup() - the loop
	structure itself does not change.
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
	int need_outin;    /* 1 iff outdeg/indeg were actually allocated (a gwodegree/gwidegree term is present) - toggle() must check THIS, not just `directed`, or it dereferences NULL on any other directed model */
	dyadht_t ht;
	long *elist_i, *elist_j; /* live edge list, parallel arrays */
	long ecap, nties;
	long *deg;               /* TOTAL degree (out+in for directed, plain degree for undirected) - already correct as-is: adding arc i->j increments deg[i] AND deg[j] by 1 each, which is exactly "i gained an out-arc" + "j gained an in-arc", i.e. total degree for both, directed or not. Used by common_neighbors()' smaller-side heuristic and GWDEGREE. */
	long *outdeg, *indeg;    /* directed-only degree (harmonisation unit 91 follow-on, GWODEGREE/GWIDEGREE): meaningless/unused for undirected graphs, where degree_out_of()/degree_in_of() below both read `deg` instead */
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
		if (g->need_outin) { g->outdeg[i]--; g->indeg[j]--; }
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
		if (g->need_outin) { g->outdeg[i]++; g->indeg[j]++; }
		if (g->need_adj && !g->directed) { adj_add(&g->adj[i], j); adj_add(&g->adj[j], i); }
		return 1;
	}
}

static long degree_out_of(graph_t *g, long i) { return g->directed ? g->outdeg[i] : g->deg[i]; }
static long degree_in_of(graph_t *g, long i)  { return g->directed ? g->indeg[i]  : g->deg[i]; }

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

#define TERMCODE_EDGES          1
#define TERMCODE_MUTUAL         2
#define TERMCODE_NODEMATCH      3
#define TERMCODE_GWESP          4
#define TERMCODE_NODECOV        5
#define TERMCODE_NODEICOV       6
#define TERMCODE_NODEOCOV       7
#define TERMCODE_ABSDIST        8
#define TERMCODE_NODEMATCH_DIFF 9
#define TERMCODE_NODEFACTOR     10
#define TERMCODE_NODEOFACTOR    11  /* also used for sender (attr = node id) */
#define TERMCODE_NODEIFACTOR    12  /* also used for receiver (attr = node id) */
#define TERMCODE_NODEMIX        13
#define TERMCODE_GWDEGREE       14
#define TERMCODE_GWODEGREE      15
#define TERMCODE_GWIDEGREE      16
#define TERMCODE_DEGREE         17
#define TERMCODE_ODEGREE        18
#define TERMCODE_IDEGREE        19
#define TERMCODE_CONCURRENT     20
#define TERMCODE_KSTAR          21
#define TERMCODE_OSTAR          22
#define TERMCODE_ISTAR          23
#define TERMCODE_DEGRANGE       24
#define TERMCODE_ODEGRANGE      25
#define TERMCODE_IDEGRANGE      26
#define TERMCODE_GWDSP          27
#define TERMCODE_GWNSP          28
#define TERMCODE_ESP            29
#define TERMCODE_DSP            30
#define TERMCODE_TRIANGLE       31

/* exact-match indicator kernel, direct port of the `(x :== td.levels')`
   rowvector construction esp()/dsp() use in unw_ergm.do - here evaluated
   for a single target d (one native "slot" per requested d, exactly
   like TERMCODE_NODEFACTOR/TERMCODE_DEGREE above) */
static double ind_kernel(double x, double d) {
	return (x == d) ? 1.0 : 0.0;
}

/* GWDSP change statistic - direct port of change_gwdsp() in
   unw_ergm.do: the SAME two-neighbor-loop shape change_gwesp() above
   uses, but WITHOUT its "must also be a tie" restriction and WITHOUT
   its own-dyad term (shared_partners(i,j) itself does not depend on
   whether i-j is tied, so toggling it contributes nothing via the
   {i,j} dyad's own term - only via every OTHER dyad that gains/loses
   i or j as a shared partner). */
static double change_gwdsp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *nbi = &g->adj[i];
	adjlist_t *nbj = &g->adj[j];
	long m;
	for (m = 0; m < nbi->len; m++) {
		long k = nbi->nb[m];
		double pk;
		if (k == j) continue;
		pk = (double)common_neighbors(g, j, k);
		chg += gw_kernel(pk + delta, decay) - gw_kernel(pk, decay);
	}
	for (m = 0; m < nbj->len; m++) {
		long k = nbj->nb[m];
		double pk;
		if (k == i) continue;
		pk = (double)common_neighbors(g, i, k);
		chg += gw_kernel(pk + delta, decay) - gw_kernel(pk, decay);
	}
	return chg;
}

/* esp(d) change statistic (one native slot per requested d, `p1'=d) -
   same shape as change_gwesp() with `gw_kernel' replaced by
   `ind_kernel', direct port of change_esp() in unw_ergm.do */
static double change_esp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors(g, i, j);
	double chg = delta * ind_kernel(pij, d);
	adjlist_t *nbi = &g->adj[i];
	long m;
	for (m = 0; m < nbi->len; m++) {
		long k = nbi->nb[m];
		double pik, pjk;
		if (k == j) continue;
		if (!has_edge(g, j, k)) continue;
		pik = (double)common_neighbors(g, i, k);
		chg += ind_kernel(pik + delta, d) - ind_kernel(pik, d);
		pjk = (double)common_neighbors(g, j, k);
		chg += ind_kernel(pjk + delta, d) - ind_kernel(pjk, d);
	}
	return chg;
}

/* dsp(d) change statistic (one native slot per requested d) - same
   shape as change_gwdsp() with `gw_kernel' replaced by `ind_kernel',
   direct port of change_dsp() in unw_ergm.do */
static double change_dsp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *nbi = &g->adj[i];
	adjlist_t *nbj = &g->adj[j];
	long m;
	for (m = 0; m < nbi->len; m++) {
		long k = nbi->nb[m];
		double pk;
		if (k == j) continue;
		pk = (double)common_neighbors(g, j, k);
		chg += ind_kernel(pk + delta, d) - ind_kernel(pk, d);
	}
	for (m = 0; m < nbj->len; m++) {
		long k = nbj->nb[m];
		double pk;
		if (k == i) continue;
		pk = (double)common_neighbors(g, i, k);
		chg += ind_kernel(pk + delta, d) - ind_kernel(pk, d);
	}
	return chg;
}

/* d choose k, direct port of _ergm_choose() in unw_ergm.do */
static double ergm_choose(double d, double k) {
	double out;
	long kk = (long)k, m;
	if (d < k) return 0.0;
	if (kk == 0) return 1.0;
	out = 1.0;
	for (m = 0; m < kk; m++) out *= (d - (double)m);
	for (m = 1; m <= kk; m++) out /= (double)m;
	return out;
}

/* [from,to) range membership, direct port of _ergm_inrange() in
   unw_ergm.do - `to >= 1e8' is the "no upper bound" sentinel
   unw_ergm.do's own ErgmNativeSetup() substitutes for Mata's `.'
   (missing) before marshalling, since `.' itself cannot survive a
   plain strtok()/atof() round-trip through the args string. */
static int in_range(double d, double from, double to) {
	if (d < from) return 0;
	if (to >= 1e8) return 1;
	return d < to;
}

/* exact-degree-value threshold-crossing delta, direct port of
   _ergm_degree_change() in unw_ergm.do */
static double degree_change_at(double olddeg, double delta, double target) {
	double c = 0.0;
	if (olddeg == target) c -= 1.0;
	if (olddeg + delta == target) c += 1.0;
	return c;
}

/*
	`delta' (+1 if the toggle ADDS the dyad, -1 if it REMOVES it) is
	computed ONCE per toggle by the caller (harmonisation unit 91
	follow-on) and passed in here, rather than each applicable term
	recomputing `has_edge(g,i,j)' independently the way the original
	4-term version of this function did - a genuine, free redundant-
	hash-lookup elimination once `nterms' can exceed a handful (as it
	now can, with multi-column attribute/factor terms), not just a
	refactor. `attr' is already resolved to the correct one of the
	model's own (possibly several) distinct attribute arrays by the
	caller (0 if this slot's own `attridx' was 0, i.e. no attribute
	needed) - see this file's own header comment for why several
	distinct arrays, not one shared one, are now needed. Every formula
	below is a direct, term-by-term port of the corresponding
	change_*() function in unw_ergm.do - see ErgmNativeSetup()'s own
	header comment there for the exact Mata source each was checked
	against before porting.
*/
static double change_term(graph_t *g, int termcode, double p1, double p2, double *attr, double delta, long i, long j) {
	switch (termcode) {
		case TERMCODE_EDGES:
			return delta;
		case TERMCODE_MUTUAL:
			if (!has_edge(g, j, i)) return 0.0;
			return delta;
		case TERMCODE_NODEMATCH:
			return (attr[i] == attr[j]) ? delta : 0.0;
		case TERMCODE_GWESP:
			return change_gwesp(g, i, j, p1);
		case TERMCODE_NODECOV:
			return delta * (attr[i] + attr[j]);
		case TERMCODE_NODEICOV:
			return delta * attr[j];
		case TERMCODE_NODEOCOV:
			return delta * attr[i];
		case TERMCODE_ABSDIST:
			return delta * fabs(attr[i] - attr[j]);
		case TERMCODE_NODEMATCH_DIFF:
			return (attr[i] == attr[j] && attr[i] == p1) ? delta : 0.0;
		case TERMCODE_NODEFACTOR: {
			double c = 0.0;
			if (attr[i] == p1) c += delta;
			if (attr[j] == p1) c += delta;
			return c;
		}
		case TERMCODE_NODEOFACTOR:
			return (attr[i] == p1) ? delta : 0.0;
		case TERMCODE_NODEIFACTOR:
			return (attr[j] == p1) ? delta : 0.0;
		case TERMCODE_NODEMIX: {
			double lo = (attr[i] < attr[j]) ? attr[i] : attr[j];
			double hi = (attr[i] < attr[j]) ? attr[j] : attr[i];
			return (lo == p1 && hi == p2) ? delta : 0.0;
		}
		case TERMCODE_GWDEGREE: {
			double di = (double)g->deg[i], dj = (double)g->deg[j];
			double chg = gw_kernel(di + delta, p1) - gw_kernel(di, p1);
			chg += gw_kernel(dj + delta, p1) - gw_kernel(dj, p1);
			return chg;
		}
		case TERMCODE_GWODEGREE: {
			double di = (double)degree_out_of(g, i);
			return gw_kernel(di + delta, p1) - gw_kernel(di, p1);
		}
		case TERMCODE_GWIDEGREE: {
			double dj = (double)degree_in_of(g, j);
			return gw_kernel(dj + delta, p1) - gw_kernel(dj, p1);
		}
		case TERMCODE_DEGREE: {
			double di = (double)g->deg[i], dj = (double)g->deg[j];
			return degree_change_at(di, delta, p1) + degree_change_at(dj, delta, p1);
		}
		case TERMCODE_ODEGREE: {
			double di = (double)degree_out_of(g, i);
			return degree_change_at(di, delta, p1);
		}
		case TERMCODE_IDEGREE: {
			double dj = (double)degree_in_of(g, j);
			return degree_change_at(dj, delta, p1);
		}
		case TERMCODE_CONCURRENT: {
			double di = (double)g->deg[i], dj = (double)g->deg[j];
			double c = (((di + delta) >= 2.0) - (di >= 2.0));
			c += (((dj + delta) >= 2.0) - (dj >= 2.0));
			return c;
		}
		case TERMCODE_KSTAR: {
			double di = (double)g->deg[i], dj = (double)g->deg[j];
			double c = (ergm_choose(di + delta, p1) - ergm_choose(di, p1));
			c += (ergm_choose(dj + delta, p1) - ergm_choose(dj, p1));
			return c;
		}
		case TERMCODE_OSTAR: {
			double di = (double)degree_out_of(g, i);
			return ergm_choose(di + delta, p1) - ergm_choose(di, p1);
		}
		case TERMCODE_ISTAR: {
			double dj = (double)degree_in_of(g, j);
			return ergm_choose(dj + delta, p1) - ergm_choose(dj, p1);
		}
		case TERMCODE_DEGRANGE: {
			double di = (double)g->deg[i], dj = (double)g->deg[j];
			double c = (double)(in_range(di + delta, p1, p2) - in_range(di, p1, p2));
			c += (double)(in_range(dj + delta, p1, p2) - in_range(dj, p1, p2));
			return c;
		}
		case TERMCODE_ODEGRANGE: {
			double di = (double)degree_out_of(g, i);
			return (double)(in_range(di + delta, p1, p2) - in_range(di, p1, p2));
		}
		case TERMCODE_IDEGRANGE: {
			double dj = (double)degree_in_of(g, j);
			return (double)(in_range(dj + delta, p1, p2) - in_range(dj, p1, p2));
		}
		case TERMCODE_GWDSP:
			return change_gwdsp(g, i, j, p1);
		case TERMCODE_GWNSP:
			/* thin composition, matching stat_gwnsp()/change_gwnsp() in
			   unw_ergm.do exactly: gwnsp = gwdsp - gwesp */
			return change_gwdsp(g, i, j, p1) - change_gwesp(g, i, j, p1);
		case TERMCODE_ESP:
			return change_esp(g, i, j, p1);
		case TERMCODE_DSP:
			return change_dsp(g, i, j, p1);
		case TERMCODE_TRIANGLE:
			return delta * (double)common_neighbors(g, i, j);
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

#define MAXTERMS 64  /* must match unw_ergm.do's own ErgmNativeSetup() maxcols */
#define MAXATTR  32  /* must match unw_ergm.do's own ErgmNativeSetup() maxattr */

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long n, directed, nties_in, samplesize, burnin, interval, proposal_code, nattr, nterms, i, k;
	unsigned long long rngseed;
	int termcodes[MAXTERMS];
	int attridx[MAXTERMS];
	double p1[MAXTERMS], p2[MAXTERMS];
	double theta[MAXTERMS];
	double obs[MAXTERMS];
	double *attrs[MAXATTR];
	graph_t g;
	rng_t rng;
	double *cur;
	long naccept = 0, ntried = 0;
	long draw, step;
	int need_adj = 0;
	int need_outin = 0;

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
	nattr         = next_long();
	nterms        = next_long();
	if (nterms > MAXTERMS) { SF_error("ergm_mcmc: too many terms\n"); free(argbuf); return(198); }
	if (nattr > MAXATTR) { SF_error("ergm_mcmc: too many attribute arrays\n"); free(argbuf); return(198); }
	for (i = 0; i < nterms; i++) {
		termcodes[i] = (int)next_long();
		attridx[i] = (int)next_long();
		p1[i] = next_double();
		p2[i] = next_double();
		switch (termcodes[i]) {
			case TERMCODE_GWESP: case TERMCODE_GWDSP: case TERMCODE_GWNSP:
			case TERMCODE_ESP: case TERMCODE_DSP: case TERMCODE_TRIANGLE:
				need_adj = 1;
		}
		switch (termcodes[i]) {
			case TERMCODE_GWODEGREE: case TERMCODE_GWIDEGREE:
			case TERMCODE_ODEGREE: case TERMCODE_IDEGREE:
			case TERMCODE_OSTAR: case TERMCODE_ISTAR:
			case TERMCODE_ODEGRANGE: case TERMCODE_IDEGRANGE:
				need_outin = 1;
		}
	}
	for (i = 0; i < nterms; i++) theta[i] = next_double();
	for (i = 0; i < nterms; i++) obs[i] = next_double();
	free(argbuf);

	/* --- build graph from dataset columns v1=ego v2=alter (rows
	   1..nties_in), then nattr attribute columns (rows 1..n, one per
	   distinct attribute array the model's own terms need - see this
	   file's own header comment) --- */
	g.n = n;
	g.directed = (int)directed;
	g.need_adj = need_adj;
	g.need_outin = need_outin && directed;
	ht_alloc(&g.ht, ht_next_pow2(nties_in * 2 + 16));
	g.elist_i = NULL; g.elist_j = NULL; g.ecap = 0; g.nties = 0;
	g.deg = (long *)calloc((size_t)(n + 1), sizeof(long));
	g.outdeg = NULL; g.indeg = NULL;
	if (need_outin && directed) {
		g.outdeg = (long *)calloc((size_t)(n + 1), sizeof(long));
		g.indeg  = (long *)calloc((size_t)(n + 1), sizeof(long));
	}
	g.adj = NULL;
	if (need_adj) {
		g.adj = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		for (i = 0; i <= n; i++) adj_init(&g.adj[i]);
	}
	for (k = 0; k < nattr; k++) {
		attrs[k] = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(3 + k), i, &v);
			attrs[k][i] = SF_is_missing(v) ? 0.0 : v;
		}
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
		double logratio, cutoff = 0.0, delta;
		double chg[MAXTERMS];
		if (proposal_code == 2) propose_tnt(&g, &rng, &pi, &pj, &logratio);
		else propose_uniform(&g, &rng, &pi, &pj, &logratio);
		delta = has_edge(&g, pi, pj) ? -1.0 : 1.0;
		for (k = 0; k < nterms; k++) {
			double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
			chg[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, delta, pi, pj);
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
			double logratio, cutoff = 0.0, delta;
			double chg[MAXTERMS];
			if (proposal_code == 2) propose_tnt(&g, &rng, &pi, &pj, &logratio);
			else propose_uniform(&g, &rng, &pi, &pj, &logratio);
			delta = has_edge(&g, pi, pj) ? -1.0 : 1.0;
			for (k = 0; k < nterms; k++) {
				double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
				chg[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, delta, pi, pj);
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
		for (k = 0; k < nterms; k++) SF_vstore((int)(3 + nattr + k), draw + 1, cur[k]);
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
	for (k = 0; k < nattr; k++) free(attrs[k]);
	free(g.deg);
	free(g.outdeg); free(g.indeg);
	ht_free(&g.ht);
	free(g.elist_i); free(g.elist_j);
	if (g.adj) {
		for (i = 0; i <= n; i++) free(g.adj[i].nb);
		free(g.adj);
	}

	return(0);
}
