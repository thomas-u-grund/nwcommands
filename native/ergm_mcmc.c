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
	set force the WHOLE model back onto the Mata sampler) across four
	subsequent waves (unit 92) to cover: the full dyad-independent
	attribute/factor family - nodecov/nodeicov/nodeocov/absdist/
	nodematch_diff/nodefactor/nodeofactor/nodeifactor/sender/receiver/
	nodemix - and the GW-degree family - gwdegree/gwodegree/gwidegree
	(wave 1); the full degree-COUNT family - degree/odegree/idegree/
	concurrent/kstar/ostar/istar/degrange/odegrange/idegrange (wave 2);
	the undirected shared-partner family beyond gwesp itself - gwdsp/
	gwnsp/esp/dsp/triangle (wave 3); the full DIRECTED shared-partner
	family under R ergm's OTP default - gwesp/gwdsp/gwnsp/esp/dsp plus
	ctriple/transitiveties/cyclicalties (wave 4), backed by a new pair of
	directed adjacency arrays (`outadj'/`inadj') and a
	`common_neighbors_otp()' primitive alongside the undirected
	`adj'/`common_neighbors()' wave 3 already built; and (wave 5, this
	update) the remaining four directed shared-partner definitions -
	ITP/OSP/ISP/RTP - for gwesp/gwdsp/gwnsp/esp/dsp, direct ports of
	their already-certified Mata counterparts in unw_ergm.do, reusing
	wave 4's own `outadj'/`inadj' arrays (no new graph-level state
	needed - RTP's reciprocated-tie check is just `has_edge()' in both
	directions on the same two arrays); and (harmonisation unit 159)
	BIPARTITE (two-mode) support - a real graph struct extension, not
	just eight more termcodes: `bipartite'/`mode'/`n1'/`n2'/
	`mode1nodes'/`mode2nodes' fields added to graph_t, `total_dyads()'/
	`propose_uniform()' each gained a bipartite branch (direct C ports
	of `ergm_total_dyads()'/`ergm_propose_uniform()''s own bipartite
	branches in unw_ergm.do, unit 155 - `propose_tnt()' needed NO change
	at all, since it already delegates to both), and mode=1's own MPLE
	dyad-enumeration loop gained a bipartite branch (mirrors
	`ErgmModel::build_mple_data()''s own). Bipartite models were
	Mata-only through unit 157 (this file had no bipartite dyad-space
	awareness at all - routing one to native would have silently
	sampled the FULL one-mode dyad space); measured directly (not
	assumed) at ~38.9x slower than R before this unit, ~1.9x after -
	dev/ergm_benchmark_bipartite/, docs/CERTIFICATION.md unit 159. The
	eight new termcodes (60-67, TERMCODE_B1COV..TERMCODE_B2STAR) are
	direct ports of unw_ergm.do's own bipartite change_*() functions
	(units 156/157) - see change_term()'s own comment on these for why
	each checks `g->mode[i]' explicitly rather than assuming the
	mode-1 endpoint arrives in position `i'. The per-node MODE array
	crosses the Mata/native boundary as its own dedicated dataset
	column (immediately after v1/v2, before the attribute columns) -
	see stata_call()'s own header comment on `attrcol_base'. See
	TERMCODE_* below for the
	complete current list and unw_ergm.do's own ErgmNativeSetup() header
	comment for exactly what is still NOT covered (edgecov/hamming - need
	an n x n matrix marshalled across the boundary, a genuinely different
	wire-protocol shape from everything else here) and why - the one
	remaining well-scoped, documented follow-on (docs/ERGM_ROADMAP.md's
	own "Native backend" section), not attempted here to keep this wave's
	own scope controlled. The two existing proposals (uniform,
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
#include <stdio.h>

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
	int need_dirsp;    /* 1 iff outadj/inadj were actually allocated (harmonisation unit 92 wave 4: a directed OTP shared-partner term - gwesp/gwdsp/gwnsp/esp/dsp with sptype "OTP" - or ctriple/transitiveties/cyclicalties is present); toggle() must check THIS, not `directed`, same reasoning as need_outin above */
	int bipartite;     /* harmonisation unit 159: 1 iff this is a bipartite (two-mode) graph - a direct C port of ErgmGraph's own `bipartite` field in unw_ergm.do */
	long *mode;              /* size n+1, 1-indexed; mode[i] is 1 or 2 - only meaningful when bipartite. NOT freed/reallocated by toggle() - set once at graph-build time, like `deg` is sized once, never per-node-added-later (this plugin never adds nodes after construction). */
	long n1, n2;             /* count of mode-1 / mode-2 nodes - only meaningful when bipartite */
	long *mode1nodes, *mode2nodes; /* size n1 / n2, 1-indexed node ids with that mode, built once from `mode[]` - direct C port of ErgmGraph's own mode1nodes/mode2nodes colvectors */
	dyadht_t ht;
	long *elist_i, *elist_j; /* live edge list, parallel arrays */
	long ecap, nties;
	long *deg;               /* TOTAL degree (out+in for directed, plain degree for undirected) - already correct as-is: adding arc i->j increments deg[i] AND deg[j] by 1 each, which is exactly "i gained an out-arc" + "j gained an in-arc", i.e. total degree for both, directed or not. Used by common_neighbors()' smaller-side heuristic and GWDEGREE. */
	long *outdeg, *indeg;    /* directed-only degree (harmonisation unit 91 follow-on, GWODEGREE/GWIDEGREE): meaningless/unused for undirected graphs, where degree_out_of()/degree_in_of() below both read `deg` instead */
	adjlist_t *adj;          /* size n+1, 1-indexed; only if need_adj */
	adjlist_t *outadj, *inadj; /* size n+1, 1-indexed; only if need_dirsp - directed out-/in-neighbor lists (SP_OTP(a,b) != SP_OTP(b,a) in general, so unlike gwesp's undirected `adj[]` a single symmetric array cannot serve both directions - see common_neighbors_otp() below) */
	/* harmonisation unit 168 (freedyads() masked TNT native port): a
	   direct C port of ErgmGraph's own has_dyadmask/freedyadmat/
	   freeelist/freeedgepos/nfreedyads/nfreeties (unw_ergm.do). `mask`
	   is dyadkey()-indexed (size (n+1)*(n+1), same key space as `ht`),
	   not the raw column-major layout the wire sends it in - built once
	   at graph-construction time from the raw parsed block, then never
	   touched again, so every later mask_free() lookup is a single
	   array read. `free_pos` is the free-tie analogue of `ht`'s own
	   position-lookup role for `elist_i`/`elist_j`: since a dyad's mask
	   status never changes mid-run (only its tie state does), a plain
	   dyadkey()-indexed array (not a second hashtable) is a correct and
	   much simpler O(1) position lookup, at the same O(n^2) memory cost
	   `mask` itself already pays - no new asymptotic cost class. */
	int has_mask;
	int *mask;               /* size (n+1)*(n+1), dyadkey()-indexed, 1 iff that dyad is free to vary */
	long *free_pos;          /* size (n+1)*(n+1), dyadkey()-indexed; position in free_elist_i/j (0-based), or -1 if not a current free tie */
	long *free_elist_i, *free_elist_j; /* live list of CURRENTLY TIED free dyads only - the elist_i/elist_j analogue restricted to the free subspace */
	long free_ecap, n_free_ties;
	double n_free_dyads;     /* total free-dyad count over the canonical dyad space - computed once at graph-build time, mirrors ergm_propose_tnt_masked()'s own G.nfreedyads */
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

/* harmonisation unit 168: g->mask is only ever allocated when
   g->has_mask - callers must check has_mask first (mirrored by every
   call site below, same discipline need_adj/need_outin/need_dirsp
   already use for their own optional arrays). */
static int mask_free(graph_t *g, long i, long j) {
	return g->mask[dyadkey(g, i, j)] != 0;
}

static void elist_ensure(graph_t *g, long need) {
	if (need <= g->ecap) return;
	g->ecap = g->ecap ? g->ecap * 2 : 8;
	if (g->ecap < need) g->ecap = need;
	g->elist_i = (long *)realloc(g->elist_i, (size_t)g->ecap * sizeof(long));
	g->elist_j = (long *)realloc(g->elist_j, (size_t)g->ecap * sizeof(long));
}

static void free_elist_ensure(graph_t *g, long need) {
	if (need <= g->free_ecap) return;
	g->free_ecap = g->free_ecap ? g->free_ecap * 2 : 8;
	if (g->free_ecap < need) g->free_ecap = need;
	g->free_elist_i = (long *)realloc(g->free_elist_i, (size_t)g->free_ecap * sizeof(long));
	g->free_elist_j = (long *)realloc(g->free_elist_j, (size_t)g->free_ecap * sizeof(long));
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
		if (g->need_dirsp) { adj_remove(&g->outadj[i], j); adj_remove(&g->inadj[j], i); }
		if (g->has_mask && mask_free(g, i, j)) {
			long fpos = g->free_pos[key];
			long lastpos = g->n_free_ties - 1;
			if (fpos != lastpos) {
				long li = g->free_elist_i[lastpos], lj = g->free_elist_j[lastpos];
				g->free_elist_i[fpos] = li; g->free_elist_j[fpos] = lj;
				g->free_pos[dyadkey(g, li, lj)] = fpos;
			}
			g->free_pos[key] = -1;
			g->n_free_ties--;
		}
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
		if (g->need_dirsp) { adj_add(&g->outadj[i], j); adj_add(&g->inadj[j], i); }
		if (g->has_mask && mask_free(g, i, j)) {
			free_elist_ensure(g, g->n_free_ties + 1);
			g->free_elist_i[g->n_free_ties] = i;
			g->free_elist_j[g->n_free_ties] = j;
			g->free_pos[key] = g->n_free_ties;
			g->n_free_ties++;
		}
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

/* ===================================================================
   Curved-MPLE fit, entirely native (harmonisation unit 146,
   docs/CERTIFICATION.md). Direct C ports of unw_ergm.do's own
   ergm_log1mexp()/ergm_gwdecay_map()/ergm_gwdecay_gradient() - see
   those functions' own header comments in unw_ergm.do for the full
   derivation/R-cross-certification account; this is a line-for-line
   transcription, not a re-derivation, to minimize the chance of a
   silent divergence between the Mata reference (still the certification
   oracle, unchanged) and this native path.
   =================================================================== */
static double ergm_log1mexp_c(double a) {
	if (a <= 0.0) return NAN;
	if (a <= log(2.0)) return log(-expm1(-a));
	return log1p(-exp(-a));
}

/* eta = theta_w * exp(alpha + log1mexp(-a*k)), a = log1mexp(alpha),
   k = 1..ncurved - see ergm_gwdecay_map()'s own header comment in
   unw_ergm.do for why this two-step structure (not a single
   log1mexp(alpha*k) call) is required. */
static void gwdecay_map(double theta_w, double alpha, long ncurved, double *eta_out) {
	double a = ergm_log1mexp_c(alpha);
	long k;
	for (k = 1; k <= ncurved; k++) {
		eta_out[k-1] = theta_w * exp(alpha + ergm_log1mexp_c(-a * (double)k));
	}
}

/* d(eta_k)/d(theta_w) into dw_out, d(eta_k)/d(alpha) into dalpha_out -
   see ergm_gwdecay_gradient()'s own header comment in unw_ergm.do. */
static void gwdecay_gradient(double theta_w, double alpha, long ncurved, double *dw_out, double *dalpha_out) {
	double a = ergm_log1mexp_c(alpha);
	long k;
	for (k = 1; k <= ncurved; k++) {
		double w = exp(alpha + ergm_log1mexp_c(-a * (double)k));
		dw_out[k-1] = w;
		dalpha_out[k-1] = theta_w * (w - (double)k * exp(a * ((double)k - 1.0)));
	}
}

/* Symmetric generalized inverse of A (p x p, row-major, overwritten
   with the result) via Gauss-Jordan elimination with partial pivoting
   - p is always small here (ntheta: a handful of ordinary terms plus
   2 for the curved block), so this plain, textbook approach (no need
   for a general-purpose BLAS/LAPACK dependency this project has never
   otherwise needed) is both sufficient and easy to certify directly
   against Mata's own invsym().

   BUGFIX (harmonisation unit 146, found benchmarking the real ecoli2
   network): the first cut of this function (and a solve_linear()
   sibling used for the per-iteration Newton delta) hard-failed on a
   singular pivot, unlike Mata's invsym() - which NEVER fails, instead
   giving a linearly-dependent direction a zero row/column in the
   result (a genuine generalized inverse). The curved gwesp decay->0
   boundary genuinely drives the Fisher information singular (not a
   numerical-precision artifact - R's own independent BFGS lands at
   the same boundary on real data, per ErgmCurvedMPLEFit()'s own
   header comment in unw_ergm.do), so on ecoli2 this was hit almost
   immediately and silently fell the whole fit back to Mata every
   time - completely defeating this unit's own optimization, though
   never producing a wrong answer (the graceful native-then-Mata-
   fallback design meant correctness was never at risk, only speed).
   invsym()'s exact contract is reproduced here (zero the pivot's row
   AND column post-hoc, so no partial-elimination leakage into other
   rows survives) and is now used for BOTH the per-iteration delta and
   the final covariance, matching ErgmCurvedMPLEFit()'s own identical
   use of invsym() for both. Always returns 0 (kept as an int return
   for minimal caller disruption; no caller needs to branch on it any
   more). */
static int invert_matrix(double *A, long p) {
	double *aug = (double *)malloc((size_t)(p*2*p) * sizeof(double));
	int *is_singular = (int *)calloc((size_t)p, sizeof(int));
	long i, j, k, piv;
	double scale = 0.0;
	for (i = 0; i < p; i++) {
		for (j = 0; j < p; j++) aug[i*(2*p)+j] = A[i*p+j];
		for (j = 0; j < p; j++) aug[i*(2*p)+p+j] = (i == j) ? 1.0 : 0.0;
		if (fabs(A[i*p+i]) > scale) scale = fabs(A[i*p+i]);
	}
	if (scale <= 0.0) scale = 1.0;
	{
		double tol = scale * 1e-10;
		for (k = 0; k < p; k++) {
			double maxval = fabs(aug[k*(2*p)+k]);
			piv = k;
			for (i = k+1; i < p; i++) {
				if (fabs(aug[i*(2*p)+k]) > maxval) { maxval = fabs(aug[i*(2*p)+k]); piv = i; }
			}
			if (maxval < tol) {
				is_singular[k] = 1;
				for (j = 0; j < 2*p; j++) aug[k*(2*p)+j] = 0.0;
				continue;
			}
			if (piv != k) {
				for (j = 0; j < 2*p; j++) { double t = aug[k*(2*p)+j]; aug[k*(2*p)+j] = aug[piv*(2*p)+j]; aug[piv*(2*p)+j] = t; }
			}
			{
				double d = aug[k*(2*p)+k];
				for (j = 0; j < 2*p; j++) aug[k*(2*p)+j] /= d;
			}
			for (i = 0; i < p; i++) {
				if (i == k) continue;
				double f = aug[i*(2*p)+k];
				if (f == 0.0) continue;
				for (j = 0; j < 2*p; j++) aug[i*(2*p)+j] -= f * aug[k*(2*p)+j];
			}
		}
	}
	for (i = 0; i < p; i++)
		for (j = 0; j < p; j++) A[i*p+j] = aug[i*(2*p)+p+j];
	for (k = 0; k < p; k++) {
		if (is_singular[k]) {
			for (j = 0; j < p; j++) { A[k*p+j] = 0.0; A[j*p+k] = 0.0; }
		}
	}
	free(aug);
	free(is_singular);
	return 0;
}

/* SP_OTP(i,j) = #{k : i->k and k->j} - the directed "outgoing two-path"
   shared-partner count (harmonisation unit 92 wave 4), a direct port of
   ErgmGraph::shared_partners_otp() in unw_ergm.do. NOT symmetric in
   (i,j) in general, unlike common_neighbors() above, so it walks only
   i's own out-neighbors (via `outadj`, not the smaller-of-two-sides
   heuristic common_neighbors() uses - there is no symmetric "smaller
   side" here since the two arguments play genuinely different roles). */
static long common_neighbors_otp(graph_t *g, long i, long j) {
	adjlist_t *nb = &g->outadj[i];
	long k, m, cnt = 0;
	for (m = 0; m < nb->len; m++) {
		k = nb->nb[m];
		if (k == j) continue;
		if (has_edge(g, k, j)) cnt++;
	}
	return cnt;
}

/*
	SP_ITP(i,j)/SP_OSP(i,j)/SP_ISP(i,j)/SP_RTP(i,j) - the four remaining
	directed shared-partner definitions R ergm's own `type=' argument
	offers, ported here (native-backend expansion, following the OTP-only
	wave above) directly from the already-certified
	shared_partners_itp()/_osp()/_isp()/_rtp() in unw_ergm.do - which see
	for the derivation and the literal `statnet/ergm' C source cross-
	check each was verified against. ITP(i,j) := OTP(j,i) (one-line
	reuse). OSP(i,j) := #{k: i->k, j->k} and ISP(i,j) := #{k: k->i, k->j}
	are both SYMMETRIC in (i,j), unlike OTP/ITP - each gets a
	`common_neighbors()'-shaped traversal (smaller-side-first, via
	`outadj'/`inadj' respectively instead of the undirected `adj[]', and
	using each side's own `adjlist_t.len' directly rather than a separate
	outdeg/indeg array that may not be allocated for these termcodes).
	RTP(i,j) := #{k: i<->k, k<->j} (k!=j), a<->b meaning BOTH has_edge(a,b)
	and has_edge(b,a) - also symmetric, but walked unconditionally via
	`outadj[i]' with no side-selection (mirroring
	ErgmGraph::shared_partners_rtp()'s own unconditional traversal
	exactly, for parity with the already-certified Mata reference rather
	than a speculative optimization).
*/
static long common_neighbors_itp(graph_t *g, long i, long j) {
	return common_neighbors_otp(g, j, i);
}
static long common_neighbors_osp(graph_t *g, long i, long j) {
	long a = i, b = j, m, k, cnt = 0;
	adjlist_t *nb;
	if (g->outadj[i].len > g->outadj[j].len) { a = j; b = i; }
	nb = &g->outadj[a];
	for (m = 0; m < nb->len; m++) {
		k = nb->nb[m];
		if (k != b && has_edge(g, b, k)) cnt++;
	}
	return cnt;
}
static long common_neighbors_isp(graph_t *g, long i, long j) {
	long a = i, b = j, m, k, cnt = 0;
	adjlist_t *nb;
	if (g->inadj[i].len > g->inadj[j].len) { a = j; b = i; }
	nb = &g->inadj[a];
	for (m = 0; m < nb->len; m++) {
		k = nb->nb[m];
		if (k != b && has_edge(g, k, b)) cnt++;
	}
	return cnt;
}
static long common_neighbors_rtp(graph_t *g, long i, long j) {
	adjlist_t *nb = &g->outadj[i];
	long k, m, cnt = 0;
	for (m = 0; m < nb->len; m++) {
		k = nb->nb[m];
		if (k == j) continue;
		if (!has_edge(g, k, i)) continue;		/* require i<->k */
		if (has_edge(g, k, j) && has_edge(g, j, k)) cnt++;	/* require k<->j */
	}
	return cnt;
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

/*
	Directed OTP variants of the shared-partner family (harmonisation
	unit 92 wave 4) - direct ports of change_gwesp_otp()/
	change_gwdsp_otp()/change_esp_otp()/change_dsp_otp() in unw_ergm.do,
	which see for the derivation of why toggling arc i->j affects
	SP_OTP(a,j) for every IN-neighbor a of i and SP_OTP(i,b) for every
	OUT-neighbor b of j (two structurally different adjustment loops,
	unlike the undirected functions' single symmetric loop, since
	SP_OTP is not symmetric).
*/
static double change_gwesp_otp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_otp(g, i, j);
	double chg = delta * gw_kernel(pij, decay);
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long a = na->nb[m];
		double paj;
		if (a == j) continue;
		if (!has_edge(g, a, j)) continue;
		paj = (double)common_neighbors_otp(g, a, j);
		chg += gw_kernel(paj + delta, decay) - gw_kernel(paj, decay);
	}
	for (m = 0; m < nb->len; m++) {
		long b = nb->nb[m];
		double pib;
		if (b == i) continue;
		if (!has_edge(g, i, b)) continue;
		pib = (double)common_neighbors_otp(g, i, b);
		chg += gw_kernel(pib + delta, decay) - gw_kernel(pib, decay);
	}
	return chg;
}

/* GWDSP's own OTP mode - same two adjustment loops as
   change_gwesp_otp() above, but (matching change_gwdsp()'s own
   relationship to change_gwesp()) without the tie-check on the
   adjusted dyad and without the own-dyad `pij` term. */
static double change_gwdsp_otp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long a = na->nb[m];
		double paj;
		if (a == j) continue;
		paj = (double)common_neighbors_otp(g, a, j);
		chg += gw_kernel(paj + delta, decay) - gw_kernel(paj, decay);
	}
	for (m = 0; m < nb->len; m++) {
		long b = nb->nb[m];
		double pib;
		if (b == i) continue;
		pib = (double)common_neighbors_otp(g, i, b);
		chg += gw_kernel(pib + delta, decay) - gw_kernel(pib, decay);
	}
	return chg;
}

/* esp(d)'s own OTP mode - change_gwesp_otp()'s shape with `gw_kernel`
   replaced by `ind_kernel` (defined below, forward-declared here since
   the OTP family is ported ahead of the TERMCODE_* block that
   introduces ind_kernel() for the undirected esp()/dsp() terms). */
static double ind_kernel(double x, double d);
static double change_esp_otp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_otp(g, i, j);
	double chg = delta * ind_kernel(pij, d);
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long a = na->nb[m];
		double paj;
		if (a == j) continue;
		if (!has_edge(g, a, j)) continue;
		paj = (double)common_neighbors_otp(g, a, j);
		chg += ind_kernel(paj + delta, d) - ind_kernel(paj, d);
	}
	for (m = 0; m < nb->len; m++) {
		long b = nb->nb[m];
		double pib;
		if (b == i) continue;
		if (!has_edge(g, i, b)) continue;
		pib = (double)common_neighbors_otp(g, i, b);
		chg += ind_kernel(pib + delta, d) - ind_kernel(pib, d);
	}
	return chg;
}

/* dsp(d)'s own OTP mode - change_gwdsp_otp()'s shape with `gw_kernel`
   replaced by `ind_kernel`. */
static double change_dsp_otp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long a = na->nb[m];
		double paj;
		if (a == j) continue;
		paj = (double)common_neighbors_otp(g, a, j);
		chg += ind_kernel(paj + delta, d) - ind_kernel(paj, d);
	}
	for (m = 0; m < nb->len; m++) {
		long b = nb->nb[m];
		double pib;
		if (b == i) continue;
		pib = (double)common_neighbors_otp(g, i, b);
		chg += ind_kernel(pib + delta, d) - ind_kernel(pib, d);
	}
	return chg;
}

/*
	ITP variants of GWESP/GWDSP/esp(d)/dsp(d) - direct ports of
	change_gwesp_itp()/change_gwdsp_itp()/change_esp_itp()/
	change_dsp_itp() in unw_ergm.do: ITP(i,j) = OTP(j,i), so these are
	the OTP loops above with every dyad mirrored - `na'/`nb' swap roles
	(inadj[i] paired with has_edge(j,k), outadj[j] paired with
	has_edge(k,i), rather than OTP's has_edge(a,j)/has_edge(i,b)).
*/
static double change_gwesp_itp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_itp(g, i, j);
	double chg = delta * gw_kernel(pij, decay);
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long k = na->nb[m];
		double pjk;
		if (k == j) continue;
		if (!has_edge(g, j, k)) continue;
		pjk = (double)common_neighbors_itp(g, j, k);
		chg += gw_kernel(pjk + delta, decay) - gw_kernel(pjk, decay);
	}
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pki;
		if (k == i) continue;
		if (!has_edge(g, k, i)) continue;
		pki = (double)common_neighbors_itp(g, k, i);
		chg += gw_kernel(pki + delta, decay) - gw_kernel(pki, decay);
	}
	return chg;
}
static double change_gwdsp_itp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long k = na->nb[m];
		double pjk;
		if (k == j) continue;
		pjk = (double)common_neighbors_itp(g, j, k);
		chg += gw_kernel(pjk + delta, decay) - gw_kernel(pjk, decay);
	}
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pki;
		if (k == i) continue;
		pki = (double)common_neighbors_itp(g, k, i);
		chg += gw_kernel(pki + delta, decay) - gw_kernel(pki, decay);
	}
	return chg;
}
static double change_esp_itp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_itp(g, i, j);
	double chg = delta * ind_kernel(pij, d);
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long k = na->nb[m];
		double pjk;
		if (k == j) continue;
		if (!has_edge(g, j, k)) continue;
		pjk = (double)common_neighbors_itp(g, j, k);
		chg += ind_kernel(pjk + delta, d) - ind_kernel(pjk, d);
	}
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pki;
		if (k == i) continue;
		if (!has_edge(g, k, i)) continue;
		pki = (double)common_neighbors_itp(g, k, i);
		chg += ind_kernel(pki + delta, d) - ind_kernel(pki, d);
	}
	return chg;
}
static double change_dsp_itp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long k = na->nb[m];
		double pjk;
		if (k == j) continue;
		pjk = (double)common_neighbors_itp(g, j, k);
		chg += ind_kernel(pjk + delta, d) - ind_kernel(pjk, d);
	}
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pki;
		if (k == i) continue;
		pki = (double)common_neighbors_itp(g, k, i);
		chg += ind_kernel(pki + delta, d) - ind_kernel(pki, d);
	}
	return chg;
}

/*
	OSP variants - direct ports of change_gwesp_osp()/change_gwdsp_osp()/
	change_esp_osp()/change_dsp_osp() in unw_ergm.do: OSP is SYMMETRIC in
	(i,j), so toggling arc i->j affects exactly ONE family of other
	dyads (q in inadj[j], i.e. q->j), not OTP/ITP's two - esp/gwesp check
	has_edge() in BOTH directions per affected node (OSP(i,q)==OSP(q,i)
	could be attributed to either arc independently); dsp/gwdsp instead
	double the single pass's own contribution (every unordered pair
	visited once here represents both ordered instances dsp's own sum
	counts).
*/
static double change_gwesp_osp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_osp(g, i, j);
	double chg = delta * gw_kernel(pij, decay);
	adjlist_t *nb = &g->inadj[j];
	long m;
	for (m = 0; m < nb->len; m++) {
		long q = nb->nb[m];
		double pq;
		if (q == i) continue;
		pq = (double)common_neighbors_osp(g, i, q);
		if (has_edge(g, i, q)) chg += gw_kernel(pq + delta, decay) - gw_kernel(pq, decay);
		if (has_edge(g, q, i)) chg += gw_kernel(pq + delta, decay) - gw_kernel(pq, decay);
	}
	return chg;
}
static double change_gwdsp_osp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *nb = &g->inadj[j];
	long m;
	for (m = 0; m < nb->len; m++) {
		long q = nb->nb[m];
		double pq;
		if (q == i) continue;
		pq = (double)common_neighbors_osp(g, i, q);
		chg += 2.0 * (gw_kernel(pq + delta, decay) - gw_kernel(pq, decay));
	}
	return chg;
}
static double change_esp_osp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_osp(g, i, j);
	double chg = delta * ind_kernel(pij, d);
	adjlist_t *nb = &g->inadj[j];
	long m;
	for (m = 0; m < nb->len; m++) {
		long q = nb->nb[m];
		double pq;
		if (q == i) continue;
		pq = (double)common_neighbors_osp(g, i, q);
		if (has_edge(g, i, q)) chg += ind_kernel(pq + delta, d) - ind_kernel(pq, d);
		if (has_edge(g, q, i)) chg += ind_kernel(pq + delta, d) - ind_kernel(pq, d);
	}
	return chg;
}
static double change_dsp_osp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *nb = &g->inadj[j];
	long m;
	for (m = 0; m < nb->len; m++) {
		long q = nb->nb[m];
		double pq;
		if (q == i) continue;
		pq = (double)common_neighbors_osp(g, i, q);
		chg += 2.0 * (ind_kernel(pq + delta, d) - ind_kernel(pq, d));
	}
	return chg;
}

/*
	ISP variants - direct ports of change_gwesp_isp()/change_gwdsp_isp()/
	change_esp_isp()/change_dsp_isp() in unw_ergm.do: the mirror image of
	the OSP family above (outadj[i] in place of inadj[j], has_edge(p,j)/
	has_edge(j,p) in place of has_edge(i,q)/has_edge(q,i)).
*/
static double change_gwesp_isp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_isp(g, i, j);
	double chg = delta * gw_kernel(pij, decay);
	adjlist_t *na = &g->outadj[i];
	long m;
	for (m = 0; m < na->len; m++) {
		long p = na->nb[m];
		double pp;
		if (p == j) continue;
		pp = (double)common_neighbors_isp(g, p, j);
		if (has_edge(g, p, j)) chg += gw_kernel(pp + delta, decay) - gw_kernel(pp, decay);
		if (has_edge(g, j, p)) chg += gw_kernel(pp + delta, decay) - gw_kernel(pp, decay);
	}
	return chg;
}
static double change_gwdsp_isp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *na = &g->outadj[i];
	long m;
	for (m = 0; m < na->len; m++) {
		long p = na->nb[m];
		double pp;
		if (p == j) continue;
		pp = (double)common_neighbors_isp(g, p, j);
		chg += 2.0 * (gw_kernel(pp + delta, decay) - gw_kernel(pp, decay));
	}
	return chg;
}
static double change_esp_isp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_isp(g, i, j);
	double chg = delta * ind_kernel(pij, d);
	adjlist_t *na = &g->outadj[i];
	long m;
	for (m = 0; m < na->len; m++) {
		long p = na->nb[m];
		double pp;
		if (p == j) continue;
		pp = (double)common_neighbors_isp(g, p, j);
		if (has_edge(g, p, j)) chg += ind_kernel(pp + delta, d) - ind_kernel(pp, d);
		if (has_edge(g, j, p)) chg += ind_kernel(pp + delta, d) - ind_kernel(pp, d);
	}
	return chg;
}
static double change_dsp_isp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *na = &g->outadj[i];
	long m;
	for (m = 0; m < na->len; m++) {
		long p = na->nb[m];
		double pp;
		if (p == j) continue;
		pp = (double)common_neighbors_isp(g, p, j);
		chg += 2.0 * (ind_kernel(pp + delta, d) - ind_kernel(pp, d));
	}
	return chg;
}

/*
	RTP variants - direct ports of change_gwesp_rtp()/change_gwdsp_rtp()/
	change_esp_rtp()/change_dsp_rtp() in unw_ergm.do, which see for the
	full derivation (fresh-checked against the real `statnet/ergm' C
	source's own `espRTP_change'/`dspRTP_change' `htedge' gate): toggling
	arc i->j can only change ANOTHER dyad's RTP value when the REVERSE
	arc j->i already exists (`has_edge(g,j,i)' below - mirroring
	change_mutual()'s own identical gate). When it does, TWO distinct
	families of dyads are affected - every node mutually tied to j
	affects dyads with i, and every node mutually tied to i affects
	dyads with j - each walked here as `outadj[x]' filtered by
	`has_edge(k,x)' (a mutual tie), the inline equivalent of
	ErgmGraph::mutual_neighbors() in unw_ergm.do.
*/
static double change_gwesp_rtp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_rtp(g, i, j);
	double chg = delta * gw_kernel(pij, decay);
	adjlist_t *nb;
	long m;
	if (!has_edge(g, j, i)) return chg;
	nb = &g->outadj[j];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == i) continue;
		if (!has_edge(g, k, j)) continue;
		pk = (double)common_neighbors_rtp(g, k, i);
		if (has_edge(g, k, i)) chg += gw_kernel(pk + delta, decay) - gw_kernel(pk, decay);
		if (has_edge(g, i, k)) chg += gw_kernel(pk + delta, decay) - gw_kernel(pk, decay);
	}
	nb = &g->outadj[i];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == j) continue;
		if (!has_edge(g, k, i)) continue;
		pk = (double)common_neighbors_rtp(g, k, j);
		if (has_edge(g, k, j)) chg += gw_kernel(pk + delta, decay) - gw_kernel(pk, decay);
		if (has_edge(g, j, k)) chg += gw_kernel(pk + delta, decay) - gw_kernel(pk, decay);
	}
	return chg;
}
static double change_gwdsp_rtp(graph_t *g, long i, long j, double decay) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *nb;
	long m;
	if (!has_edge(g, j, i)) return chg;
	nb = &g->outadj[j];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == i) continue;
		if (!has_edge(g, k, j)) continue;
		pk = (double)common_neighbors_rtp(g, k, i);
		chg += 2.0 * (gw_kernel(pk + delta, decay) - gw_kernel(pk, decay));
	}
	nb = &g->outadj[i];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == j) continue;
		if (!has_edge(g, k, i)) continue;
		pk = (double)common_neighbors_rtp(g, k, j);
		chg += 2.0 * (gw_kernel(pk + delta, decay) - gw_kernel(pk, decay));
	}
	return chg;
}
static double change_esp_rtp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_rtp(g, i, j);
	double chg = delta * ind_kernel(pij, d);
	adjlist_t *nb;
	long m;
	if (!has_edge(g, j, i)) return chg;
	nb = &g->outadj[j];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == i) continue;
		if (!has_edge(g, k, j)) continue;
		pk = (double)common_neighbors_rtp(g, k, i);
		if (has_edge(g, k, i)) chg += ind_kernel(pk + delta, d) - ind_kernel(pk, d);
		if (has_edge(g, i, k)) chg += ind_kernel(pk + delta, d) - ind_kernel(pk, d);
	}
	nb = &g->outadj[i];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == j) continue;
		if (!has_edge(g, k, i)) continue;
		pk = (double)common_neighbors_rtp(g, k, j);
		if (has_edge(g, k, j)) chg += ind_kernel(pk + delta, d) - ind_kernel(pk, d);
		if (has_edge(g, j, k)) chg += ind_kernel(pk + delta, d) - ind_kernel(pk, d);
	}
	return chg;
}
static double change_dsp_rtp(graph_t *g, long i, long j, double d) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double chg = 0.0;
	adjlist_t *nb;
	long m;
	if (!has_edge(g, j, i)) return chg;
	nb = &g->outadj[j];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == i) continue;
		if (!has_edge(g, k, j)) continue;
		pk = (double)common_neighbors_rtp(g, k, i);
		chg += 2.0 * (ind_kernel(pk + delta, d) - ind_kernel(pk, d));
	}
	nb = &g->outadj[i];
	for (m = 0; m < nb->len; m++) {
		long k = nb->nb[m];
		double pk;
		if (k == j) continue;
		if (!has_edge(g, k, i)) continue;
		pk = (double)common_neighbors_rtp(g, k, j);
		chg += 2.0 * (ind_kernel(pk + delta, d) - ind_kernel(pk, d));
	}
	return chg;
}

/*
	transitiveties/cyclicalties (harmonisation unit 92 wave 4, directed
	only) - direct ports of change_transitiveties()/change_cyclicalties()
	in unw_ergm.do. Same two-adjustment-loop shape as the OTP family
	above, but each affected SP_OTP count only contributes through a
	0/1 THRESHOLD CROSSING (>=1), and (see unw_ergm.do's own header
	comment for the full derivation) the two terms read the threshold
	off DIFFERENT arcs: transitiveties uses has_edge(a,j)/has_edge(i,b)
	(the same existence checks change_gwesp_otp() uses), cyclicalties
	uses the REVERSED has_edge(j,a)/has_edge(b,i).
*/
static double change_transitiveties(graph_t *g, long i, long j) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pij = (double)common_neighbors_otp(g, i, j);
	double chg = delta * (pij >= 1.0 ? 1.0 : 0.0);
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long a = na->nb[m];
		double olda;
		if (a == j) continue;
		if (!has_edge(g, a, j)) continue;
		olda = (double)common_neighbors_otp(g, a, j);
		chg += ((olda + delta >= 1.0) ? 1.0 : 0.0) - ((olda >= 1.0) ? 1.0 : 0.0);
	}
	for (m = 0; m < nb->len; m++) {
		long b = nb->nb[m];
		double oldb;
		if (b == i) continue;
		if (!has_edge(g, i, b)) continue;
		oldb = (double)common_neighbors_otp(g, i, b);
		chg += ((oldb + delta >= 1.0) ? 1.0 : 0.0) - ((oldb >= 1.0) ? 1.0 : 0.0);
	}
	return chg;
}
static double change_cyclicalties(graph_t *g, long i, long j) {
	double delta = has_edge(g, i, j) ? -1.0 : 1.0;
	double pji = (double)common_neighbors_otp(g, j, i);
	double chg = delta * (pji >= 1.0 ? 1.0 : 0.0);
	adjlist_t *na = &g->inadj[i];
	adjlist_t *nb = &g->outadj[j];
	long m;
	for (m = 0; m < na->len; m++) {
		long a = na->nb[m];
		double olda;
		if (a == j) continue;
		if (!has_edge(g, j, a)) continue;
		olda = (double)common_neighbors_otp(g, a, j);
		chg += ((olda + delta >= 1.0) ? 1.0 : 0.0) - ((olda >= 1.0) ? 1.0 : 0.0);
	}
	for (m = 0; m < nb->len; m++) {
		long b = nb->nb[m];
		double oldb;
		if (b == i) continue;
		if (!has_edge(g, b, i)) continue;
		oldb = (double)common_neighbors_otp(g, i, b);
		chg += ((oldb + delta >= 1.0) ? 1.0 : 0.0) - ((oldb >= 1.0) ? 1.0 : 0.0);
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
#define TERMCODE_GWESP_OTP      32  /* directed OTP mode of gwesp - harmonisation unit 92 wave 4 */
#define TERMCODE_GWDSP_OTP      33
#define TERMCODE_GWNSP_OTP      34  /* composition, no dedicated change_*() function - see change_term() */
#define TERMCODE_ESP_OTP        35
#define TERMCODE_DSP_OTP        36
#define TERMCODE_CTRIPLE        37  /* composition of common_neighbors_otp(), no dedicated change_*() function */
#define TERMCODE_TRANSITIVETIES 38
#define TERMCODE_CYCLICALTIES   39
#define TERMCODE_GWESP_ITP      40  /* ITP/OSP/ISP/RTP native expansion, following the OTP-only wave above */
#define TERMCODE_GWDSP_ITP      41
#define TERMCODE_GWNSP_ITP      42  /* composition, no dedicated change_*() function - see change_term() */
#define TERMCODE_ESP_ITP        43
#define TERMCODE_DSP_ITP        44
#define TERMCODE_GWESP_OSP      45
#define TERMCODE_GWDSP_OSP      46
#define TERMCODE_GWNSP_OSP      47
#define TERMCODE_ESP_OSP        48
#define TERMCODE_DSP_OSP        49
#define TERMCODE_GWESP_ISP      50
#define TERMCODE_GWDSP_ISP      51
#define TERMCODE_GWNSP_ISP      52
#define TERMCODE_ESP_ISP        53
#define TERMCODE_DSP_ISP        54
#define TERMCODE_GWESP_RTP      55
#define TERMCODE_GWDSP_RTP      56
#define TERMCODE_GWNSP_RTP      57
#define TERMCODE_ESP_RTP        58
#define TERMCODE_DSP_RTP        59
/* harmonisation unit 159: bipartite (two-mode) terms - direct ports of
   stat_b1cov()/change_b1cov()/etc. in unw_ergm.do (units 156/157). Only
   ever registered on a graph with `bipartite`=1 - unw_ergm.do's own
   ErgmNativeSetup() never emits these codes for a one-mode model, since
   the b1cov()/b1factor()/b1degree()/b1star() Stata options themselves
   are rejected outright on a one-mode network before ErgmNativeSetup()
   ever runs (nwergm.ado's own network-type validation). */
#define TERMCODE_B1COV          60
#define TERMCODE_B2COV          61
#define TERMCODE_B1FACTOR       62
#define TERMCODE_B2FACTOR       63
#define TERMCODE_B1DEGREE       64
#define TERMCODE_B2DEGREE       65
#define TERMCODE_B1STAR         66
#define TERMCODE_B2STAR         67

/* harmonisation unit 160: edgecov/hamming - direct ports of
   change_edgecov()/change_hamming() in unw_ergm.do, the last remaining
   gap in the native migration. Both need a dense n x n dyadic covariate
   matrix, a genuinely different shape from every attribute array above
   (one value per DYAD, not per node) - see stata_call()'s own header
   comment on the `covmat'/`covidx' wire fields for how this crosses the
   Mata/native boundary. */
#define TERMCODE_EDGECOV        68
#define TERMCODE_HAMMING        69

/* nsp(d): raw (unweighted) non-edgewise-shared-partners per-level count -
   direct port of stat_nsp()/change_nsp() in unw_ergm.do, which is itself
   a thin composition (dsp(d) - esp(d), a definitional tautology - see
   that function's own header comment) - the raw counterpart gwnspfree()
   needs the same way gwespfree()/gwdegreefree()/etc. reuse the plain
   esp/degree/etc. termcodes above (this is the one raw multi-level term
   that had no native slot of its own before - gwnsp itself already did,
   TERMCODE_GWNSP/_OTP/etc. above, being a thin GW-weighted composition
   of the SAME two functions). Six variants for the same reason ESP/DSP
   have six each - td.sptype's OTP/ITP/OSP/ISP/RTP dispatch, inherited
   "for free" by composition per stat_nsp()'s own header comment. */
#define TERMCODE_NSP             70
#define TERMCODE_NSP_OTP         71
#define TERMCODE_NSP_ITP         72
#define TERMCODE_NSP_OSP         73
#define TERMCODE_NSP_ISP         74
#define TERMCODE_NSP_RTP         75

/* bipartite (two-mode) Stage 4 terms - direct ports of
   change_b1nodematch()/change_b2nodematch()/change_bgwdegree1()/
   change_bgwdegree2() in unw_ergm.do (harmonisation unit 162). Only ever
   registered on a bipartite graph, same guarantee TERMCODE_B1COV etc.
   above already rely on. */
#define TERMCODE_B1NODEMATCH     76
#define TERMCODE_B2NODEMATCH     77
#define TERMCODE_BGWDEGREE1      78
#define TERMCODE_BGWDEGREE2      79

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

/* b1nodematch()/b2nodematch() shared helper - direct port of
   _ergm_bnodematch_partner_count() in unw_ergm.do: among node2's own
   CURRENT neighbors (excluding node1 itself), how many share node1's own
   `attr' value. Walks g->adj[node2] (bipartite graphs are always
   undirected - see g->bipartite's own header comment - so the plain
   undirected adjacency list is exactly node2's neighbor set), gated by
   need_adj the same way ESP/DSP/NSP already are.
   No explicit missing-value guard (unlike Mata's own `a1 >= .' check) -
   every attribute array crossing the wire already has SF_is_missing()
   converted to a plain 0.0 upstream (this function's own caller reads
   `attr' straight from that same shared array, same as NODEMATCH/
   NODEFACTOR/B1FACTOR/B2FACTOR above), so adding a special case here
   alone would make this term behave differently from every sibling
   attribute-based term instead of consistently with them. */
static double bnodematch_partner_count(graph_t *g, long node1, long node2, double *attr) {
	double a1 = attr[node1];
	adjlist_t *nb = &g->adj[node2];
	long m, cnt = 0;
	for (m = 0; m < nb->len; m++) {
		if (nb->nb[m] == node1) continue;
		if (attr[nb->nb[m]] == a1) cnt++;
	}
	return (double)cnt;
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
static double change_term(graph_t *g, int termcode, double p1, double p2, double *attr, double *cm, long n, double delta, long i, long j) {
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
		case TERMCODE_GWESP_OTP:
			return change_gwesp_otp(g, i, j, p1);
		case TERMCODE_GWDSP_OTP:
			return change_gwdsp_otp(g, i, j, p1);
		case TERMCODE_GWNSP_OTP:
			/* thin composition, matching stat_gwnsp()/change_gwnsp()'s
			   own OTP dispatch in unw_ergm.do exactly (gwnsp = gwdsp -
			   gwesp under either shared-partner definition) */
			return change_gwdsp_otp(g, i, j, p1) - change_gwesp_otp(g, i, j, p1);
		case TERMCODE_ESP_OTP:
			return change_esp_otp(g, i, j, p1);
		case TERMCODE_DSP_OTP:
			return change_dsp_otp(g, i, j, p1);
		case TERMCODE_CTRIPLE:
			/* change_ctriple() in unw_ergm.do is
			   `delta * _ergm_cyclic_partners(i,j)`, and
			   _ergm_cyclic_partners(i,j) == shared_partners_otp(j,i)
			   exactly (both count k with j->k and k->i) - no dedicated
			   function needed, just the arguments swapped. */
			return delta * (double)common_neighbors_otp(g, j, i);
		case TERMCODE_TRANSITIVETIES:
			return change_transitiveties(g, i, j);
		case TERMCODE_CYCLICALTIES:
			return change_cyclicalties(g, i, j);
		case TERMCODE_GWESP_ITP:
			return change_gwesp_itp(g, i, j, p1);
		case TERMCODE_GWDSP_ITP:
			return change_gwdsp_itp(g, i, j, p1);
		case TERMCODE_GWNSP_ITP:
			return change_gwdsp_itp(g, i, j, p1) - change_gwesp_itp(g, i, j, p1);
		case TERMCODE_ESP_ITP:
			return change_esp_itp(g, i, j, p1);
		case TERMCODE_DSP_ITP:
			return change_dsp_itp(g, i, j, p1);
		case TERMCODE_GWESP_OSP:
			return change_gwesp_osp(g, i, j, p1);
		case TERMCODE_GWDSP_OSP:
			return change_gwdsp_osp(g, i, j, p1);
		case TERMCODE_GWNSP_OSP:
			return change_gwdsp_osp(g, i, j, p1) - change_gwesp_osp(g, i, j, p1);
		case TERMCODE_ESP_OSP:
			return change_esp_osp(g, i, j, p1);
		case TERMCODE_DSP_OSP:
			return change_dsp_osp(g, i, j, p1);
		case TERMCODE_GWESP_ISP:
			return change_gwesp_isp(g, i, j, p1);
		case TERMCODE_GWDSP_ISP:
			return change_gwdsp_isp(g, i, j, p1);
		case TERMCODE_GWNSP_ISP:
			return change_gwdsp_isp(g, i, j, p1) - change_gwesp_isp(g, i, j, p1);
		case TERMCODE_ESP_ISP:
			return change_esp_isp(g, i, j, p1);
		case TERMCODE_DSP_ISP:
			return change_dsp_isp(g, i, j, p1);
		case TERMCODE_GWESP_RTP:
			return change_gwesp_rtp(g, i, j, p1);
		case TERMCODE_GWDSP_RTP:
			return change_gwdsp_rtp(g, i, j, p1);
		case TERMCODE_GWNSP_RTP:
			return change_gwdsp_rtp(g, i, j, p1) - change_gwesp_rtp(g, i, j, p1);
		case TERMCODE_ESP_RTP:
			return change_esp_rtp(g, i, j, p1);
		case TERMCODE_DSP_RTP:
			return change_dsp_rtp(g, i, j, p1);
		/* harmonisation unit 159: bipartite terms - direct ports of
		   change_b1cov()/change_b2cov()/change_b1factor()/
		   change_b2factor()/change_b1degree()/change_b2degree()/
		   change_b1star()/change_b2star() in unw_ergm.do. Every
		   bipartite dyad (i,j) reaching this function has EXACTLY one
		   mode-1 and one mode-2 endpoint (the graph's own bipartite
		   dyad-space guarantee, enforced by propose_uniform()/
		   propose_tnt() below and by mode=1's own dyad-enumeration
		   loop in stata_call()) - but `i' is NOT guaranteed to be the
		   mode-1 one (the live edge list canonicalizes by raw numeric
		   node index, not by mode - the identical pitfall unw_ergm.do's
		   own "bipartite Stage 2 terms" header comment documents), so
		   every case below checks `g->mode[i]' explicitly rather than
		   assuming positional order. */
		case TERMCODE_B1COV:
			return delta * ((g->mode[i] == 1) ? attr[i] : attr[j]);
		case TERMCODE_B2COV:
			return delta * ((g->mode[i] == 2) ? attr[i] : attr[j]);
		case TERMCODE_B1FACTOR:
			return ((g->mode[i] == 1 ? attr[i] : attr[j]) == p1) ? delta : 0.0;
		case TERMCODE_B2FACTOR:
			return ((g->mode[i] == 2 ? attr[i] : attr[j]) == p1) ? delta : 0.0;
		case TERMCODE_B1DEGREE: {
			long node1 = (g->mode[i] == 1) ? i : j;
			double d1 = (double)g->deg[node1];
			return degree_change_at(d1, delta, p1);
		}
		case TERMCODE_B2DEGREE: {
			long node2 = (g->mode[i] == 2) ? i : j;
			double d2 = (double)g->deg[node2];
			return degree_change_at(d2, delta, p1);
		}
		case TERMCODE_B1STAR: {
			long node1 = (g->mode[i] == 1) ? i : j;
			double d1 = (double)g->deg[node1];
			return ergm_choose(d1 + delta, p1) - ergm_choose(d1, p1);
		}
		case TERMCODE_B2STAR: {
			long node2 = (g->mode[i] == 2) ? i : j;
			double d2 = (double)g->deg[node2];
			return ergm_choose(d2 + delta, p1) - ergm_choose(d2, p1);
		}
		/* harmonisation unit 160: direct ports of change_edgecov()/
		   change_hamming() in unw_ergm.do. `cm' is the flattened n x n
		   dyadic covariate matrix this term instance was registered
		   with (stata_call()'s own covmats[covidx[k]-1], column-major:
		   cm[(col-1)*n+(row-1)] == Mata's edgecovmat[row,col]), so
		   cm[(j-1)*n+(i-1)] is exactly edgecovmat[i,j]. change_edgecov
		   is genuinely delta-scaled (delta already encodes the toggle
		   direction, has_edge?-1:+1, matching Mata's own
		   `has_edge(i,j) ? -v : v'); change_hamming is NOT a delta
		   scaling of anything (a mismatch-agreement flip, +1/-1
		   depending on whether the CURRENT tie state already agrees
		   with the reference, matching Mata's own
		   `has_edge(i,j)==edgecovmat[i,j] ? 1 : -1' exactly) - ported
		   as its own direct boolean comparison rather than forced into
		   the delta-scaling shape every other case here uses. */
		case TERMCODE_EDGECOV:
			return delta * cm[(j-1)*n + (i-1)];
		case TERMCODE_HAMMING: {
			double ref = cm[(j-1)*n + (i-1)];
			double tied = has_edge(g, i, j) ? 1.0 : 0.0;
			return (tied == ref) ? 1.0 : -1.0;
		}
		/* nsp(d) = dsp(d) - esp(d), same thin composition as
		   TERMCODE_GWNSP(_OTP/_ITP/_OSP/_ISP/_RTP) above, one level down
		   (raw per-level dsp/esp instead of GW-weighted) - direct port of
		   change_nsp() in unw_ergm.do. */
		case TERMCODE_NSP:
			return change_dsp(g, i, j, p1) - change_esp(g, i, j, p1);
		case TERMCODE_NSP_OTP:
			return change_dsp_otp(g, i, j, p1) - change_esp_otp(g, i, j, p1);
		case TERMCODE_NSP_ITP:
			return change_dsp_itp(g, i, j, p1) - change_esp_itp(g, i, j, p1);
		case TERMCODE_NSP_OSP:
			return change_dsp_osp(g, i, j, p1) - change_esp_osp(g, i, j, p1);
		case TERMCODE_NSP_ISP:
			return change_dsp_isp(g, i, j, p1) - change_esp_isp(g, i, j, p1);
		case TERMCODE_NSP_RTP:
			return change_dsp_rtp(g, i, j, p1) - change_esp_rtp(g, i, j, p1);
		/* bipartite Stage 4 - direct ports of change_b1nodematch()/
		   change_b2nodematch()/change_bgwdegree1()/change_bgwdegree2() in
		   unw_ergm.do. `delta' is already the caller's own has_edge?-1:+1
		   signed toggle direction (see this function's own header
		   comment) - both b1nodematch/b2nodematch's own Mata source and
		   bgwdegree1/bgwdegree2's own already reuse exactly that same
		   quantity rather than recomputing has_edge() a second time, so
		   these cases do too. */
		case TERMCODE_B1NODEMATCH: {
			long node1 = (g->mode[i] == 1) ? i : j;
			long node2 = (g->mode[i] == 1) ? j : i;
			return delta * bnodematch_partner_count(g, node1, node2, attr);
		}
		case TERMCODE_B2NODEMATCH: {
			long node2 = (g->mode[i] == 2) ? i : j;
			long node1 = (g->mode[i] == 2) ? j : i;
			return delta * bnodematch_partner_count(g, node2, node1, attr);
		}
		case TERMCODE_BGWDEGREE1: {
			long node1 = (g->mode[i] == 1) ? i : j;
			double d1 = (double)g->deg[node1];
			return gw_kernel(d1 + delta, p1) - gw_kernel(d1, p1);
		}
		case TERMCODE_BGWDEGREE2: {
			long node2 = (g->mode[i] == 2) ? i : j;
			double d2 = (double)g->deg[node2];
			return gw_kernel(d2 + delta, p1) - gw_kernel(d2, p1);
		}
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
	if (g->bipartite) return (double)g->n1 * (double)g->n2;
	return g->directed ? n * (n - 1.0) : n * (n - 1.0) / 2.0;
}

static void propose_uniform(graph_t *g, rng_t *rng, long *pi, long *pj, double *logratio) {
	double Dtot = total_dyads(g);
	long pick = 1 + (long)(rng_unif(rng) * Dtot);
	long i, j, row, col;
	if (g->bipartite) {
		/* linear index -> (i,j) over the rectangular mode1 x mode2
		   cross-mode dyad space - direct C port of
		   ergm_propose_uniform()'s own bipartite branch in
		   unw_ergm.do. */
		row = (pick - 1) / g->n2 + 1;
		col = (pick - 1) % g->n2 + 1;
		i = g->mode1nodes[row];
		j = g->mode2nodes[col];
	}
	else if (g->directed) {
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

/* Fixed-density (R ergm's own `constraints=~edges', nwergm's
   `fixdensity' option) compound proposal - direct port of
   ergm_propose_swap() in unw_ergm.do: pick a uniformly random CURRENT
   tie to remove (t1,h1), then a uniformly random dyad via
   propose_uniform()'s own rejection loop until it lands on a current
   non-tie to add (t2,h2). No Hastings-ratio correction (mirrors the
   Mata original exactly - ErgmMCMCSampleSwap()'s own `cutoff = theta *
   chgtot'' has no logratio term added, unlike propose_tnt() above), so
   this function reports none (unlike propose_uniform()/propose_tnt(),
   it has no `logratio' output parameter at all - its caller in
   stata_call() below never needs one, always using this proposal ALONE,
   never mixed with a masked/TNT branch, since fixdensity is mutually
   exclusive with freedyads()/blockdiag() by nwergm.ado's own
   validation). Returns nonzero if no valid swap exists (an edgeless or
   complete network - cannot happen for a real fixed-density fit
   starting from an observed network with at least one tie and one
   non-tie, guarded explicitly the same way ergm_propose_swap()'s own
   Mata header comment describes, and the same way
   propose_uniform_masked()'s own exhausted-retry-cap guard above
   reports failure to its caller rather than looping forever). */
static int propose_swap(graph_t *g, rng_t *rng, long *t1, long *h1, long *t2, long *h2) {
	long erow, i, j;
	double lr;
	if (g->nties == 0 || (double)g->nties == total_dyads(g)) return 1;
	erow = rng_below(rng, g->nties);
	*t1 = g->elist_i[erow];
	*h1 = g->elist_j[erow];
	do {
		propose_uniform(g, rng, &i, &j, &lr);
	} while (has_edge(g, i, j));
	*t2 = i;
	*h2 = j;
	return 0;
}

/* Masked proposals (harmonisation unit 168, freedyads() native port) -
   direct C ports of ergm_propose_uniform_masked()/ergm_propose_tnt_masked()
   in unw_ergm.do; see that file's own header comments for the derivation
   (every population count TNT's Hastings-ratio math depends on restricted
   to the free-dyad subspace; the log-ratio FORMULAS themselves are
   byte-for-byte identical to the unmasked versions above). Return 0 on
   success, nonzero if propose_uniform_masked's own rejection loop could
   not find a free dyad after MASK_MAX_TRIES draws (mirrors Mata's own
   "the mask may be far too sparse" backstop - not the expected path on
   any reasonably-specified mask; on this exhaust-the-retry-cap failure
   the caller reports a fatal error and returns immediately without
   unwinding every graph allocation first, the same trade-off this file's
   own pre-graph-construction fatal-argument-error paths already make). */
#define MASK_MAX_TRIES 1000000

static int propose_uniform_masked(graph_t *g, rng_t *rng, long *pi, long *pj, double *logratio) {
	long tries;
	for (tries = 0; tries < MASK_MAX_TRIES; tries++) {
		long i, j;
		propose_uniform(g, rng, &i, &j, logratio);
		if (mask_free(g, i, j)) { *pi = i; *pj = j; return 0; }
	}
	return 1;
}

static int propose_tnt_masked(graph_t *g, rng_t *rng, long *pi, long *pj, double *logratio) {
	double Dtot = g->n_free_dyads;
	double E = (double)g->n_free_ties;
	double P = 0.5, Q = 0.5;
	double DP = P * Dtot;
	double DO = DP / Q;
	long i, j;

	if (rng_unif(rng) < P && g->n_free_ties > 0) {
		long erow = rng_below(rng, g->n_free_ties);
		i = g->free_elist_i[erow];
		j = g->free_elist_j[erow];
	}
	else {
		double lr;
		if (propose_uniform_masked(g, rng, &i, &j, &lr)) return 1;
	}

	if (has_edge(g, i, j)) {
		*logratio = (E == 1) ? -log(DP + Q) : log(E / (DO + E));
	}
	else {
		*logratio = (E == 0) ? log(DP + Q) : log(1.0 + DO / (E + 1.0));
	}
	*pi = i; *pj = j;
	return 0;
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
#define MAXCOVMAT 8  /* must match unw_ergm.do's own ErgmNativeSetup() maxcovmat (harmonisation unit 160) - distinct dense n x n edgecov()/hamming() matrices are far heavier per slot (n^2 doubles, not n) than an attribute array, so this cap is deliberately much smaller than MAXATTR */

/* eta = theta_to_eta(theta): the first (nterms-ncurved) eta slots equal
   the corresponding theta values one-for-one (an ordinary term IS its
   own eta - ErgmModel::theta_to_eta()'s own "else" branch in
   unw_ergm.do); the final `ncurved' slots are gwdecay_map()'s own
   output from theta's own final 2 values (weight, decay) - the
   registered-last invariant this whole native extension leans on (see
   this file's own header comment above the mode-field parsing). */
static void theta_to_eta_c(const double *theta, long ntheta, long nterms, long ncurved, double *eta_out) {
	long nord = nterms - ncurved;
	long i;
	for (i = 0; i < nord; i++) eta_out[i] = theta[i];
	if (ncurved > 0) gwdecay_map(theta[ntheta-2], theta[ntheta-1], ncurved, eta_out + nord);
}

/* Log-pseudolikelihood at a given theta - sum over dyads of
   y*log(p)+(1-y)*log(1-p), p=invlogit(X*eta') - direct port of
   ergm_curved_loglik() in unw_ergm.do, used by the backtracking line
   search below exactly as it is there. */
static double curved_loglik_c(const double *X, const double *y, long ndyads, long nterms,
		long ntheta, long ncurved, const double *theta) {
	double eta[MAXTERMS];
	double ll = 0.0;
	long i, k;
	theta_to_eta_c(theta, ntheta, nterms, ncurved, eta);
	for (i = 0; i < ndyads; i++) {
		double xb = 0.0, p;
		const double *xi = X + (size_t)i * (size_t)nterms;
		for (k = 0; k < nterms; k++) xb += xi[k] * eta[k];
		p = 1.0 / (1.0 + exp(-xb));
		if (p < 1e-300) p = 1e-300;
		if (p > 1.0 - 1e-300) p = 1.0 - 1e-300;
		ll += y[i] * log(p) + (1.0 - y[i]) * log(1.0 - p);
	}
	return ll;
}

/* Direct C port of ErgmCurvedMPLEFit() in unw_ergm.do - damped
   Newton-Raphson on the pseudolikelihood in theta-space, chain-ruled
   through theta_to_eta_c()'s own Jacobian, with the identical
   backtracking line search (halve the step up to 30 times, both to
   keep the decay parameter positive AND to not decrease the log-
   pseudolikelihood) and graceful boundary-stop (clamp decay to 1e-6
   and report converged=1 rather than propagate a degenerate estimate)
   the Mata reference already has certified, real-network evidence for
   (docs/CERTIFICATION.md units 136-141) - see that function's own
   header comment for the full account of why each piece is there.
   `maxit'/`tol' match the ONLY values nwergm.ado's own call site ever
   actually passes (100, 1e-10) - hardcoded here rather than threaded
   through the wire protocol as two more fields, since no caller has
   ever varied them. Returns 0 on success (theta_out/V_out populated),
   -1 if the final information matrix is singular (V_out left
   undefined in that case - a real but exceedingly unlikely failure
   mode on a well-posed problem that already survived 100 Newton
   iterations without it). */
static int curved_mple_fit_c(const double *X, const double *y, long ndyads, long nterms,
		long ncurved, double curved_decay_start,
		double *theta_out, double *V_out, long *converged_out) {
	long ntheta = (nterms - ncurved) + 2;
	long decay_pos = ntheta - 1;
	long maxit = 100;
	double tol = 1e-10;
	double theta[MAXTERMS], theta_try[MAXTERMS];
	double eta[MAXTERMS];
	double g_eta[MAXTERMS], g_theta[MAXTERMS];
	double delta[MAXTERMS];
	double *I_eta, *I_theta, *Jac;
	double ll0, ll1;
	long iter, i, j, k, halvings, found, converged;
	double step, maxabs;

	for (i = 0; i < ntheta - 2; i++) theta[i] = 0.0;
	theta[ntheta-2] = 0.0;
	theta[ntheta-1] = curved_decay_start;

	I_eta = (double *)malloc((size_t)nterms * (size_t)nterms * sizeof(double));
	I_theta = (double *)malloc((size_t)ntheta * (size_t)ntheta * sizeof(double));
	Jac = (double *)malloc((size_t)nterms * (size_t)ntheta * sizeof(double));

	ll0 = curved_loglik_c(X, y, ndyads, nterms, ntheta, ncurved, theta);
	converged = 0;

	for (iter = 1; iter <= maxit; iter++) {
		double dw[MAXTERMS], dalpha[MAXTERMS];
		long nord = nterms - ncurved;

		theta_to_eta_c(theta, ntheta, nterms, ncurved, eta);

		/* Jacobian: nterms x ntheta, row-major. Ordinary block =
		   identity (d eta_i/d theta_i = 1); curved block = gwdecay_
		   gradient()'s own 2 x ncurved output, transposed. */
		for (i = 0; i < nterms * ntheta; i++) Jac[i] = 0.0;
		for (i = 0; i < nord; i++) Jac[i*ntheta + i] = 1.0;
		if (ncurved > 0) {
			gwdecay_gradient(theta[ntheta-2], theta[ntheta-1], ncurved, dw, dalpha);
			for (k = 0; k < ncurved; k++) {
				Jac[(nord+k)*ntheta + (ntheta-2)] = dw[k];
				Jac[(nord+k)*ntheta + (ntheta-1)] = dalpha[k];
			}
		}

		for (i = 0; i < nterms; i++) g_eta[i] = 0.0;
		for (i = 0; i < nterms * nterms; i++) I_eta[i] = 0.0;
		for (i = 0; i < ndyads; i++) {
			const double *xi = X + (size_t)i * (size_t)nterms;
			double xb = 0.0, p, w;
			for (k = 0; k < nterms; k++) xb += xi[k] * eta[k];
			p = 1.0 / (1.0 + exp(-xb));
			w = p * (1.0 - p);
			for (k = 0; k < nterms; k++) g_eta[k] += xi[k] * (y[i] - p);
			for (j = 0; j < nterms; j++) {
				double wxj = w * xi[j];
				if (wxj == 0.0) continue;
				for (k = j; k < nterms; k++) I_eta[j*nterms+k] += wxj * xi[k];
			}
		}
		/* I_eta is symmetric - only the upper triangle was accumulated
		   above (halves the inner work); mirror it before use. */
		for (j = 0; j < nterms; j++)
			for (k = j+1; k < nterms; k++)
				I_eta[k*nterms+j] = I_eta[j*nterms+k];

		/* g_theta = g_eta * Jac  [1 x ntheta] */
		for (k = 0; k < ntheta; k++) {
			g_theta[k] = 0.0;
			for (i = 0; i < nterms; i++) g_theta[k] += g_eta[i] * Jac[i*ntheta+k];
		}
		/* I_theta = Jac' * I_eta * Jac  [ntheta x ntheta] - via the
		   nterms x ntheta intermediate M = I_eta * Jac, then
		   Jac' * M, avoiding ever materializing a second nterms x
		   nterms temporary. */
		{
			double *M = (double *)malloc((size_t)nterms * (size_t)ntheta * sizeof(double));
			for (i = 0; i < nterms; i++) {
				for (k = 0; k < ntheta; k++) {
					double s = 0.0;
					for (j = 0; j < nterms; j++) s += I_eta[i*nterms+j] * Jac[j*ntheta+k];
					M[i*ntheta+k] = s;
				}
			}
			for (i = 0; i < ntheta; i++) {
				for (k = 0; k < ntheta; k++) {
					double s = 0.0;
					for (j = 0; j < nterms; j++) s += Jac[j*ntheta+i] * M[j*ntheta+k];
					I_theta[i*ntheta+k] = s;
				}
			}
			free(M);
		}

		/* delta = invsym(I_theta) * g_theta' - a generalized-inverse
		   solve, not solve_linear()'s old hard-failing Gauss-Jordan
		   solve, exactly matching ErgmCurvedMPLEFit()'s own
		   invsym()-based delta in unw_ergm.do (see invert_matrix()'s
		   own header comment for why this is required, not optional,
		   on the curved gwesp decay->0 boundary). */
		invert_matrix(I_theta, ntheta);
		for (i = 0; i < ntheta; i++) {
			double s = 0.0;
			for (j = 0; j < ntheta; j++) s += I_theta[i*ntheta+j] * g_theta[j];
			delta[i] = s;
		}

		step = 1.0;
		found = 0;
		for (halvings = 1; halvings <= 30; halvings++) {
			for (i = 0; i < ntheta; i++) theta_try[i] = theta[i] + step * delta[i];
			if (theta_try[decay_pos] > 1e-6) {
				ll1 = curved_loglik_c(X, y, ndyads, nterms, ntheta, ncurved, theta_try);
				if (ll1 >= ll0) { found = 1; break; }
			}
			step = step / 2.0;
		}
		if (!found) {
			theta[decay_pos] = 1e-6;
			converged = 1;
			break;
		}
		for (i = 0; i < ntheta; i++) theta[i] = theta_try[i];
		ll0 = ll1;
		maxabs = 0.0;
		for (i = 0; i < ntheta; i++) {
			double d = fabs(step * delta[i]);
			if (d > maxabs) maxabs = d;
		}
		if (maxabs < tol) { converged = 1; break; }
	}

	/* Final Fisher information at the converged (or last-tried) theta -
	   recomputed fresh, not reused from the last iteration's own
	   pre-update value, matching ErgmCurvedMPLEFit()'s own identical
	   convention in unw_ergm.do. */
	{
		long nord = nterms - ncurved;
		double dw[MAXTERMS], dalpha[MAXTERMS];
		theta_to_eta_c(theta, ntheta, nterms, ncurved, eta);
		for (i = 0; i < nterms * ntheta; i++) Jac[i] = 0.0;
		for (i = 0; i < nord; i++) Jac[i*ntheta + i] = 1.0;
		if (ncurved > 0) {
			gwdecay_gradient(theta[ntheta-2], theta[ntheta-1], ncurved, dw, dalpha);
			for (k = 0; k < ncurved; k++) {
				Jac[(nord+k)*ntheta + (ntheta-2)] = dw[k];
				Jac[(nord+k)*ntheta + (ntheta-1)] = dalpha[k];
			}
		}
		for (i = 0; i < nterms * nterms; i++) I_eta[i] = 0.0;
		for (i = 0; i < ndyads; i++) {
			const double *xi = X + (size_t)i * (size_t)nterms;
			double xb = 0.0, p, w;
			for (k = 0; k < nterms; k++) xb += xi[k] * eta[k];
			p = 1.0 / (1.0 + exp(-xb));
			w = p * (1.0 - p);
			for (j = 0; j < nterms; j++) {
				double wxj = w * xi[j];
				if (wxj == 0.0) continue;
				for (k = j; k < nterms; k++) I_eta[j*nterms+k] += wxj * xi[k];
			}
		}
		for (j = 0; j < nterms; j++)
			for (k = j+1; k < nterms; k++)
				I_eta[k*nterms+j] = I_eta[j*nterms+k];
		{
			double *M = (double *)malloc((size_t)nterms * (size_t)ntheta * sizeof(double));
			for (i = 0; i < nterms; i++) {
				for (k = 0; k < ntheta; k++) {
					double s = 0.0;
					for (j = 0; j < nterms; j++) s += I_eta[i*nterms+j] * Jac[j*ntheta+k];
					M[i*ntheta+k] = s;
				}
			}
			for (i = 0; i < ntheta; i++) {
				for (k = 0; k < ntheta; k++) {
					double s = 0.0;
					for (j = 0; j < nterms; j++) s += Jac[j*ntheta+i] * M[j*ntheta+k];
					I_theta[i*ntheta+k] = s;
				}
			}
			free(M);
		}
	}

	for (i = 0; i < ntheta; i++) theta_out[i] = theta[i];
	invert_matrix(I_theta, ntheta);
	for (i = 0; i < ntheta * ntheta; i++) V_out[i] = I_theta[i];
	*converged_out = converged;

	free(I_eta); free(I_theta); free(Jac);
	return 0;
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long mode, n, directed, bipartite, nties_in, samplesize, burnin, interval, proposal_code, nattr, ncovmat, hasmask, fixed_density, nterms, i, k;
	long attrcol_base, covmatcol_base, maskcol_base, outcol_base;
	long ncurved;
	double curved_decay_start;
	unsigned long long rngseed;
	int termcodes[MAXTERMS];
	int attridx[MAXTERMS];
	int covidx[MAXTERMS];
	double p1[MAXTERMS], p2[MAXTERMS];
	double theta[MAXTERMS];
	double obs[MAXTERMS];
	double *attrs[MAXATTR];
	double *covmats[MAXCOVMAT];
	graph_t g;
	rng_t rng;
	double *cur;
	long naccept = 0, ntried = 0;
	long draw, step;
	int need_adj = 0;
	int need_outin = 0;
	int need_dirsp = 0;

	if (argc < 1) { SF_error("ergm_mcmc: missing argument string\n"); return(198); }

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	/* mode: 0 = run the MCMC burnin+sampling loop (original, unchanged
	   behavior below); 1 = build the MPLE design matrix instead - one
	   pass over every dyad, writing each slot's own change_toward_one()
	   value plus the observed tie indicator, no MCMC at all (harmonisation
	   unit 145, docs/CERTIFICATION.md - the same "build_mple_data()" role
	   ErgmModel::build_mple_data() plays in unw_ergm.do, natively). Every
	   OTHER field below is parsed identically in both modes (the parser
	   itself never branches on mode) so the two modes cannot silently
	   drift apart in how they read the wire - mode 1 simply does not use
	   samplesize/burnin/interval/proposal_code/rngseed/theta/obs, which
	   the Mata-side caller still sends as harmless placeholder zeros
	   rather than requiring a second, divergent argstr format. */
	mode          = (long)atof(strtok(argbuf, " \t"));
	n             = next_long();
	directed      = next_long();
	bipartite     = next_long();
	nties_in      = next_long();
	samplesize    = next_long();
	burnin        = next_long();
	interval      = next_long();
	proposal_code = next_long();
	rngseed       = (unsigned long long)next_double();
	nattr         = next_long();
	ncovmat       = next_long();
	/* hasmask (harmonisation unit 168): inserted right after ncovmat, in
	   ALL THREE Mata-side wire-format callers - unw_ergm.do's own
	   ErgmNativeSampleCore() is the only one that ever sends 1;
	   ErgmNativeBuildMPLEData()/ErgmNativeCurvedMPLEFit() always send a
	   literal 0 at this exact position, keeping this shared header's
	   own field count aligned across every mode, the same discipline
	   `ncovmat' itself required when IT was added (unit 160). */
	hasmask       = next_long();
	/* fixed_density (R ergm's own `constraints=~edges', nwergm's
	   `fixdensity' option): inserted right after hasmask, the SAME
	   "all three callers, in lockstep" discipline every earlier field
	   addition here required - ErgmNativeSampleCore() is the only
	   caller that ever sends a genuine model's own M.fixed_density value
	   (0 or 1); ErgmNativeBuildMPLEData()/ErgmNativeCurvedMPLEFit()
	   always send a literal 0 (a fixed-density model is MCMLE-only -
	   nwergm.ado itself requires method(mcmle) for fixdensity - so
	   neither MPLE mode ever legitimately runs on one; kept only for
	   the shared header's own field-count alignment). When 1, the
	   burnin/sampling loops below dispatch to propose_swap()'s own
	   compound tie/non-tie move instead of the ordinary single-dyad
	   uniform/TNT/masked proposal - direct port of
	   ErgmMCMCSampleSwap()/ErgmMCMCSampleDiagSwap() in unw_ergm.do. */
	fixed_density = next_long();
	nterms        = next_long();
	if (nterms > MAXTERMS) { SF_error("ergm_mcmc: too many terms\n"); free(argbuf); return(198); }
	if (nattr > MAXATTR) { SF_error("ergm_mcmc: too many attribute arrays\n"); free(argbuf); return(198); }
	if (ncovmat > MAXCOVMAT) { SF_error("ergm_mcmc: too many dyadic covariate matrices\n"); free(argbuf); return(198); }
	for (i = 0; i < nterms; i++) {
		termcodes[i] = (int)next_long();
		attridx[i] = (int)next_long();
		p1[i] = next_double();
		p2[i] = next_double();
		covidx[i] = (int)next_long();
		switch (termcodes[i]) {
			case TERMCODE_GWESP: case TERMCODE_GWDSP: case TERMCODE_GWNSP:
			case TERMCODE_ESP: case TERMCODE_DSP: case TERMCODE_TRIANGLE:
			case TERMCODE_NSP: case TERMCODE_B1NODEMATCH: case TERMCODE_B2NODEMATCH:
				need_adj = 1;
		}
		switch (termcodes[i]) {
			case TERMCODE_GWODEGREE: case TERMCODE_GWIDEGREE:
			case TERMCODE_ODEGREE: case TERMCODE_IDEGREE:
			case TERMCODE_OSTAR: case TERMCODE_ISTAR:
			case TERMCODE_ODEGRANGE: case TERMCODE_IDEGRANGE:
				need_outin = 1;
		}
		switch (termcodes[i]) {
			case TERMCODE_GWESP_OTP: case TERMCODE_GWDSP_OTP:
			case TERMCODE_GWNSP_OTP: case TERMCODE_ESP_OTP:
			case TERMCODE_DSP_OTP: case TERMCODE_CTRIPLE:
			case TERMCODE_TRANSITIVETIES: case TERMCODE_CYCLICALTIES:
			case TERMCODE_GWESP_ITP: case TERMCODE_GWDSP_ITP:
			case TERMCODE_GWNSP_ITP: case TERMCODE_ESP_ITP:
			case TERMCODE_DSP_ITP:
			case TERMCODE_GWESP_OSP: case TERMCODE_GWDSP_OSP:
			case TERMCODE_GWNSP_OSP: case TERMCODE_ESP_OSP:
			case TERMCODE_DSP_OSP:
			case TERMCODE_GWESP_ISP: case TERMCODE_GWDSP_ISP:
			case TERMCODE_GWNSP_ISP: case TERMCODE_ESP_ISP:
			case TERMCODE_DSP_ISP:
			case TERMCODE_GWESP_RTP: case TERMCODE_GWDSP_RTP:
			case TERMCODE_GWNSP_RTP: case TERMCODE_ESP_RTP:
			case TERMCODE_DSP_RTP:
			case TERMCODE_NSP_OTP: case TERMCODE_NSP_ITP:
			case TERMCODE_NSP_OSP: case TERMCODE_NSP_ISP:
			case TERMCODE_NSP_RTP:
				need_dirsp = 1;
		}
	}
	for (i = 0; i < nterms; i++) theta[i] = next_double();
	for (i = 0; i < nterms; i++) obs[i] = next_double();
	/* mode=2 only (harmonisation unit 146): how many of the LAST
	   `nterms' eta-space slots belong to the curved term's own per-
	   count block, and that block's own starting decay value - always
	   parsed, unused placeholders (0, 0) on every other mode, matching
	   this file's own established "keep the wire format uniform, branch
	   only on what a mode DOES with the fields, not on how many fields
	   it reads" convention already used for mode=1's own unused theta/
	   obs. Registering the curved term LAST (nwergm.ado's own, already-
	   documented invariant - "its own 2 theta columns are always the
	   final 2") is what makes a single trailing count sufficient: slots
	   0..(nterms-ncurved-1) are ordinary (theta IS eta, one column
	   each), the final `ncurved' slots are the curved block (mapped via
	   ergm_gwdecay_map()/_gradient() below, 2 theta values - weight,
	   decay - for the whole block). */
	ncurved = (long)next_double();
	curved_decay_start = next_double();
	free(argbuf);

	/* --- build graph from dataset columns v1=ego v2=alter (rows
	   1..nties_in), then [m, if bipartite] (rows 1..n, harmonisation
	   unit 159), then nattr attribute columns (rows 1..n, one per
	   distinct attribute array the model's own terms need - see this
	   file's own header comment) --- */
	g.n = n;
	g.directed = (int)directed;
	g.bipartite = (int)bipartite;
	g.mode = NULL; g.mode1nodes = NULL; g.mode2nodes = NULL; g.n1 = 0; g.n2 = 0;
	/* attribute columns start right after v1/v2 (column 3), shifted one
	   further (column 4) when a mode column is present - every other
	   attrs[]-column reference in this file already goes through this
	   variable rather than a hardcoded `3', so this is the only place
	   the shift needs to be applied. */
	attrcol_base = bipartite ? 4 : 3;
	if (bipartite) {
		g.mode = (long *)calloc((size_t)(n + 1), sizeof(long));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata(3, i, &v);
			g.mode[i] = (long)v;
			if (g.mode[i] == 1) g.n1++; else g.n2++;
		}
		g.mode1nodes = (long *)malloc((size_t)(g.n1 + 1) * sizeof(long));
		g.mode2nodes = (long *)malloc((size_t)(g.n2 + 1) * sizeof(long));
		{
			long a = 0, b = 0;
			for (i = 1; i <= n; i++) {
				if (g.mode[i] == 1) g.mode1nodes[++a] = i;
				else g.mode2nodes[++b] = i;
			}
		}
	}
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
	g.need_dirsp = need_dirsp;
	g.outadj = NULL; g.inadj = NULL;
	if (need_dirsp) {
		g.outadj = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		g.inadj  = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		for (i = 0; i <= n; i++) { adj_init(&g.outadj[i]); adj_init(&g.inadj[i]); }
	}
	for (k = 0; k < nattr; k++) {
		attrs[k] = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(attrcol_base + k), i, &v);
			attrs[k][i] = SF_is_missing(v) ? 0.0 : v;
		}
	}
	/* harmonisation unit 160: each distinct dense n x n dyadic covariate
	   matrix (edgecov()/hamming()) crosses the wire as its own BLOCK of n
	   dataset columns immediately after the nattr attribute columns (see
	   unw_ergm.do's own ErgmNativeSampleCore()/etc. header comment on the
	   covmat mechanism) - column (covmatcol_base + k*n + c) holds the
	   k-th matrix's own column c (Stata row r == that matrix's row r), so
	   flattening column-major (covmats[k][(c-1)*n+(r-1)]) reproduces
	   Mata's edgecovmat[r,c] exactly, read back the same way in
	   change_term()'s own TERMCODE_EDGECOV/TERMCODE_HAMMING cases. This
	   inserts covmatcol_base..covmatcol_base+ncovmat*n-1 BEFORE every
	   existing output-column reference in this function - `outcol_base'
	   (not the old hardcoded `attrcol_base+nattr' expression) is used at
	   every one of those sites below so none of them silently shift. */
	covmatcol_base = attrcol_base + nattr;
	maskcol_base = covmatcol_base + ncovmat * n;
	outcol_base = maskcol_base + (hasmask ? n : 0);
	for (k = 0; k < ncovmat; k++) {
		long c, r;
		covmats[k] = (double *)calloc((size_t)n * (size_t)n, sizeof(double));
		for (c = 1; c <= n; c++) {
			for (r = 1; r <= n; r++) {
				ST_double v;
				SF_vdata((int)(covmatcol_base + k*n + c - 1), r, &v);
				covmats[k][(c-1)*n + (r-1)] = SF_is_missing(v) ? 0.0 : v;
			}
		}
	}
	/* harmonisation unit 168 (freedyads() masked TNT native port): the
	   dyad-eligibility mask block (present only when hasmask), one
	   column per dataset column, same column-major layout as a covmat
	   block above - built into g.mask/g.free_pos (both dyadkey()-indexed,
	   NOT this raw column-major layout - see graph_t's own field comment)
	   and g.n_free_dyads BEFORE the initial observed-edge toggle() loop
	   just below, since toggle() itself reads g.has_mask/g.mask/
	   g.free_pos unconditionally once has_mask is set. g.n_free_dyads is
	   computed here via the SAME canonical dyad-space walk
	   ErgmModel::build_mple_data()'s own free-dyad preallocation counters
	   use in unw_ergm.do (i<j for undirected, i!=j for directed, mode1 x
	   mode2 for bipartite) - a direct, independent count over the raw
	   mask data, not inferred from anything else. */
	g.has_mask = (int)hasmask;
	g.mask = NULL; g.free_pos = NULL;
	g.free_elist_i = NULL; g.free_elist_j = NULL; g.free_ecap = 0; g.n_free_ties = 0;
	g.n_free_dyads = 0.0;
	if (hasmask) {
		long dsize = (n + 1) * (n + 1);
		double *maskraw = (double *)calloc((size_t)n * (size_t)n, sizeof(double));
		long ii, jj;
		for (jj = 1; jj <= n; jj++) {
			for (ii = 1; ii <= n; ii++) {
				ST_double v;
				SF_vdata((int)(maskcol_base + jj - 1), ii, &v);
				maskraw[(jj-1)*n + (ii-1)] = SF_is_missing(v) ? 0.0 : v;
			}
		}
		g.mask = (int *)calloc((size_t)dsize, sizeof(int));
		g.free_pos = (long *)malloc((size_t)dsize * sizeof(long));
		for (i = 0; i < dsize; i++) g.free_pos[i] = -1;
		if (g.bipartite) {
			for (ii = 1; ii <= g.n1; ii++) {
				for (jj = 1; jj <= g.n2; jj++) {
					long i2 = g.mode1nodes[ii], j2 = g.mode2nodes[jj];
					if (maskraw[(j2-1)*n + (i2-1)] != 0.0) {
						g.mask[dyadkey(&g, i2, j2)] = 1;
						g.n_free_dyads += 1.0;
					}
				}
			}
		}
		else {
			for (ii = 1; ii <= n; ii++) {
				long jstart = directed ? 1 : ii + 1;
				for (jj = jstart; jj <= n; jj++) {
					if (jj == ii) continue;
					if (maskraw[(jj-1)*n + (ii-1)] != 0.0) {
						g.mask[dyadkey(&g, ii, jj)] = 1;
						g.n_free_dyads += 1.0;
					}
				}
			}
		}
		free(maskraw);
	}
	for (i = 1; i <= nties_in; i++) {
		ST_double vi, vj;
		SF_vdata(1, i, &vi);
		SF_vdata(2, i, &vj);
		toggle(&g, (long)vi, (long)vj);
	}

	if (mode == 1) {
		/* Build the MPLE design matrix: one pass over every dyad (same
		   ordering ErgmModel::build_mple_data() uses in unw_ergm.do -
		   i=1..n, j=1..n, skip i==j, skip j<i for undirected; for a
		   bipartite graph (harmonisation unit 159), i ranges over
		   mode1nodes and j over mode2nodes instead, the SAME restricted
		   dyad-space loop ErgmModel::build_mple_data()'s own bipartite
		   branch uses in unw_ergm.do - not that row order matters for
		   fitting a logit design, but matching it keeps a direct
		   row-by-row Mata-vs-native comparison possible during
		   certification), writing each slot's own change_toward_one()
		   value (the change statistic as if setting Y_ij=1, regardless
		   of the dyad's own current state - the exact mirror-negation
		   ErgmModel::change_toward_one() applies in Mata) plus the
		   observed tie indicator as the response column, laid out
		   immediately after the nterms change-statistic columns (at
		   frame column outcol_base+nterms, i.e. attrcol_base+nattr+
		   ncovmat*n+nterms once unit 160's own covmat column block is
		   accounted for - one more variable
		   than the MCMC mode's own `plugin call' passes, see
		   unw_ergm.do's ErgmNativeBuildMPLEData()). No MCMC, no RNG, no
		   theta/obs use at all - burnin/interval/samplesize/
		   proposal_code/rngseed are simply unused placeholders on this
		   path. */
		long pos = 1;
		long respcol = outcol_base + nterms;
		long ii, jj;
		for (ii = 1; ii <= (g.bipartite ? g.n1 : n); ii++) {
			long jend = g.bipartite ? g.n2 : n;
			for (jj = 1; jj <= jend; jj++) {
				double delta, tied;
				long i2 = g.bipartite ? g.mode1nodes[ii] : ii;
				long j2 = g.bipartite ? g.mode2nodes[jj] : jj;
				if (!g.bipartite) {
					if (i2 == j2) continue;
					if (!directed && j2 < i2) continue;
				}
				tied = has_edge(&g, i2, j2) ? 1.0 : 0.0;
				delta = tied ? -1.0 : 1.0;
				for (k = 0; k < nterms; k++) {
					double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
					double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
					double chg = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, delta, i2, j2);
					double chg_toward_one = tied ? -chg : chg;
					SF_vstore((int)(outcol_base + k), pos, chg_toward_one);
				}
				SF_vstore((int)respcol, pos, tied);
				pos++;
			}
		}
		SF_scal_save("__ergm_native_ndyads_out", (ST_double)(pos - 1));

		for (k = 0; k < nattr; k++) free(attrs[k]);
		for (k = 0; k < ncovmat; k++) free(covmats[k]);
		free(g.mode); free(g.mode1nodes); free(g.mode2nodes);
		free(g.deg);
		free(g.outdeg); free(g.indeg);
		ht_free(&g.ht);
		free(g.elist_i); free(g.elist_j);
	free(g.mask); free(g.free_pos); free(g.free_elist_i); free(g.free_elist_j);
		if (g.adj) {
			for (i = 0; i <= n; i++) free(g.adj[i].nb);
			free(g.adj);
		}
		if (g.outadj) {
			for (i = 0; i <= n; i++) free(g.outadj[i].nb);
			free(g.outadj);
		}
		if (g.inadj) {
			for (i = 0; i <= n; i++) free(g.inadj[i].nb);
			free(g.inadj);
		}
		return(0);
	}

	if (mode == 2) {
		/* Curved MPLE, entirely native (harmonisation unit 146): build
		   the SAME design matrix mode=1 builds (identical per-dyad
		   loop, identical column values), but keep it in memory as a
		   plain C array instead of writing it to the frame, then run
		   curved_mple_fit_c() (this file's own direct port of
		   ErgmCurvedMPLEFit()) on it directly - crossing the Mata/
		   native boundary exactly once for the WHOLE curved fit, per
		   this file's own governing "never once per proposal, never
		   once per iteration" boundary-crossing discipline (this
		   file's own header comment). Small, model-scale results
		   (theta, the covariance matrix, a converged flag) cross back
		   via SF_scal_save() - the dyad-scale design matrix itself
		   never needs to leave this call at all. */
		long ndyads = directed ? n * (n - 1) : n * (n - 1) / 2;
		long ntheta = (nterms - ncurved) + 2;
		double *X, *Y;
		double theta_out[MAXTERMS], V_out[MAXTERMS*MAXTERMS];
		long converged_out = 0;
		long pos = 0;
		int fit_rc;

		X = (double *)malloc((size_t)ndyads * (size_t)nterms * sizeof(double));
		Y = (double *)malloc((size_t)ndyads * sizeof(double));
		for (i = 1; i <= n; i++) {
			long j;
			for (j = 1; j <= n; j++) {
				double delta, tied;
				double *xrow;
				if (i == j) continue;
				if (!directed && j < i) continue;
				tied = has_edge(&g, i, j) ? 1.0 : 0.0;
				delta = tied ? -1.0 : 1.0;
				xrow = X + (size_t)pos * (size_t)nterms;
				for (k = 0; k < nterms; k++) {
					double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
					double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
					double chg = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, delta, i, j);
					xrow[k] = tied ? -chg : chg;
				}
				Y[pos] = tied;
				pos++;
			}
		}

		fit_rc = curved_mple_fit_c(X, Y, ndyads, nterms, ncurved, curved_decay_start,
			theta_out, V_out, &converged_out);
		free(X); free(Y);

		if (fit_rc == 0) {
			char name[64];
			for (i = 0; i < ntheta; i++) {
				snprintf(name, sizeof(name), "__ergm_native_curved_theta%ld", i + 1);
				SF_scal_save(name, (ST_double)theta_out[i]);
			}
			for (i = 0; i < ntheta * ntheta; i++) {
				snprintf(name, sizeof(name), "__ergm_native_curved_V%ld", i + 1);
				SF_scal_save(name, (ST_double)V_out[i]);
			}
			SF_scal_save("__ergm_native_curved_ntheta_out", (ST_double)ntheta);
			SF_scal_save("__ergm_native_curved_converged", (ST_double)converged_out);
			SF_scal_save("__ergm_native_curved_rc", (ST_double)0);
		}
		else {
			SF_scal_save("__ergm_native_curved_rc", (ST_double)fit_rc);
		}

		for (k = 0; k < nattr; k++) free(attrs[k]);
		for (k = 0; k < ncovmat; k++) free(covmats[k]);
		free(g.mode); free(g.mode1nodes); free(g.mode2nodes);
		free(g.deg);
		free(g.outdeg); free(g.indeg);
		ht_free(&g.ht);
		free(g.elist_i); free(g.elist_j);
	free(g.mask); free(g.free_pos); free(g.free_elist_i); free(g.free_elist_j);
		if (g.adj) {
			for (i = 0; i <= n; i++) free(g.adj[i].nb);
			free(g.adj);
		}
		if (g.outadj) {
			for (i = 0; i <= n; i++) free(g.outadj[i].nb);
			free(g.outadj);
		}
		if (g.inadj) {
			for (i = 0; i <= n; i++) free(g.inadj[i].nb);
			free(g.inadj);
		}
		return(0);
	}

	rng_seed(&rng, rngseed);
	cur = (double *)malloc((size_t)nterms * sizeof(double));
	for (i = 0; i < nterms; i++) cur[i] = obs[i];

	if (fixed_density && (g.nties == 0 || (double)g.nties == total_dyads(&g))) {
		SF_error("ergm_mcmc: fixdensity: network has no ties, or is complete - no valid tie/non-tie swap exists.\n");
		free(cur);
		return(198);
	}

	for (step = 0; step < burnin; step++) {
		long pi, pj;
		double logratio, cutoff = 0.0, delta;
		double chg[MAXTERMS];
		int propfail = 0;
		if (fixed_density) {
			long t1, h1, t2, h2;
			double chg1[MAXTERMS], chg2[MAXTERMS];
			propose_swap(&g, &rng, &t1, &h1, &t2, &h2);
			for (k = 0; k < nterms; k++) {
				double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
				double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
				chg1[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, -1.0, t1, h1);
			}
			toggle(&g, t1, h1);
			for (k = 0; k < nterms; k++) {
				double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
				double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
				chg2[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, 1.0, t2, h2);
				cutoff += theta[k] * (chg1[k] + chg2[k]);
			}
			if (cutoff >= 0.0 || log(rng_unif(&rng)) < cutoff) {
				toggle(&g, t2, h2);
				for (k = 0; k < nterms; k++) cur[k] += chg1[k] + chg2[k];
			}
			else {
				toggle(&g, t1, h1);
			}
			continue;
		}
		if (g.has_mask) {
			if (proposal_code == 2) propfail = propose_tnt_masked(&g, &rng, &pi, &pj, &logratio);
			else propfail = propose_uniform_masked(&g, &rng, &pi, &pj, &logratio);
			if (propfail) { SF_error("ergm_mcmc: freedyads() mask has no free dyad to propose after 1,000,000 draws\n"); return(198); }
		}
		else if (proposal_code == 2) propose_tnt(&g, &rng, &pi, &pj, &logratio);
		else propose_uniform(&g, &rng, &pi, &pj, &logratio);
		delta = has_edge(&g, pi, pj) ? -1.0 : 1.0;
		for (k = 0; k < nterms; k++) {
			double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
			double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
			chg[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, delta, pi, pj);
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
			int propfail = 0;
			if (fixed_density) {
				long t1, h1, t2, h2;
				double chg1[MAXTERMS], chg2[MAXTERMS];
				propose_swap(&g, &rng, &t1, &h1, &t2, &h2);
				for (k = 0; k < nterms; k++) {
					double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
					double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
					chg1[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, -1.0, t1, h1);
				}
				toggle(&g, t1, h1);
				for (k = 0; k < nterms; k++) {
					double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
					double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
					chg2[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, 1.0, t2, h2);
					cutoff += theta[k] * (chg1[k] + chg2[k]);
				}
				ntried++;
				if (cutoff >= 0.0 || log(rng_unif(&rng)) < cutoff) {
					toggle(&g, t2, h2);
					for (k = 0; k < nterms; k++) cur[k] += chg1[k] + chg2[k];
					naccept++;
				}
				else {
					toggle(&g, t1, h1);
				}
				continue;
			}
			if (g.has_mask) {
				if (proposal_code == 2) propfail = propose_tnt_masked(&g, &rng, &pi, &pj, &logratio);
				else propfail = propose_uniform_masked(&g, &rng, &pi, &pj, &logratio);
				if (propfail) { SF_error("ergm_mcmc: freedyads() mask has no free dyad to propose after 1,000,000 draws\n"); return(198); }
			}
			else if (proposal_code == 2) propose_tnt(&g, &rng, &pi, &pj, &logratio);
			else propose_uniform(&g, &rng, &pi, &pj, &logratio);
			delta = has_edge(&g, pi, pj) ? -1.0 : 1.0;
			for (k = 0; k < nterms; k++) {
				double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
				double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
				chg[k] = change_term(&g, termcodes[k], p1[k], p2[k], a, cmk, n, delta, pi, pj);
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
		for (k = 0; k < nterms; k++) SF_vstore((int)(outcol_base + k), draw + 1, cur[k]);
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
	for (k = 0; k < ncovmat; k++) free(covmats[k]);
	free(g.mode); free(g.mode1nodes); free(g.mode2nodes);
	free(g.deg);
	free(g.outdeg); free(g.indeg);
	ht_free(&g.ht);
	free(g.elist_i); free(g.elist_j);
	free(g.mask); free(g.free_pos); free(g.free_elist_i); free(g.free_elist_j);
	if (g.adj) {
		for (i = 0; i <= n; i++) free(g.adj[i].nb);
		free(g.adj);
	}
	if (g.outadj) {
		for (i = 0; i <= n; i++) free(g.outadj[i].nb);
		free(g.outadj);
	}
	if (g.inadj) {
		for (i = 0; i <= n; i++) free(g.inadj[i].nb);
		free(g.inadj);
	}

	return(0);
}
