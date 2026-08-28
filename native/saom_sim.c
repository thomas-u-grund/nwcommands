/*
	saom_sim.c -- native (C) SAOM ministep/interval simulation kernel for
	nwcommands (nwsaom). See docs/SAOM_ROADMAP.md ("Native (C) backend")
	and docs/SAOM_ARCHITECTURE.md for the full design account.

	SCOPE (harmonisation unit 10 - "learn lessons that help for all
	other effects", per explicit user instruction after a real, measured
	speed finding): a direct RSiena benchmark (dev/saom_rsiena_
	crosscheck.R/.do) found the native path already close to real RSiena
	(~4.6x slower, s50 data, outdegree+reciprocity) but the pure-Mata
	fallback catastrophically slow for ANY model using a non-native term
	(>350s and still running for outdegree+transtrip+cycle3 on the same
	50-node data, vs. RSiena's own 0.88s for a comparable fit - a 400x+
	gap, not a small one). Rather than keep adding new effects that each
	individually hit this same wall, this unit extends the ONE native
	kernel to cover EVERY term unw_saom.do currently implements (units
	1-2, 3, 4-5, 9 - 13 terms total), so future effects only need a
	change-statistic formula added here, not a fresh "should this be
	native" decision each time.

	Adjacency/toggle machinery (dyad hash table, live edge list, and -
	new in this unit - per-node degree counters and out-/in-adjacency
	lists for the OTP/OSP shared-partner terms) is a direct structural
	port of native/ergm_mcmc.c's own graph_t/dyadht_t/adjlist_t (read-only
	reference, not included/linked - this file is fully self-contained,
	per the coordination note in docs/SAOM_ROADMAP.md: this initiative
	never edits native/ergm_mcmc.c, which a concurrent session is
	actively working on).

	RNG: same self-contained xorshift128+ construction as
	native/ergm_mcmc.c (Vigna & Blackman 2014, public-domain algorithm,
	reimplemented independently here - not shared code, not copied from
	that file), seeded from a single unsigned integer the Mata caller
	draws via runiform() immediately before the plugin call, matching
	that file's own reproducibility contract: same Stata `set seed` ->
	same native run, every time, but NOT the same sample path as the
	Mata backend (independent RNG streams - see
	docs/SAOM_ARCHITECTURE.md's "Native backend" section, "Certification
	standard").

	WIRE PROTOCOL: one `plugin call` per SIMULATED INTERVAL (never per
	ministep - see docs/SAOM_ARCHITECTURE.md's own "cross the boundary
	once per simulated interval" contract). Args string: "n directed
	nties_in rate rngseed nattr nterms [termcode attridx p1]*nterms
	[theta]*nterms" - extended this unit with a per-term `p1` generic
	scalar (only `simcov` uses it, for the covariate's own range;
	0 and unused for every other term - same "keep the wire format
	uniform, branch only on what a term DOES with the field" convention
	native/ergm_mcmc.c's own header documents for its own mode-dependent
	fields). ALWAYS terminated by two further trailing fields, `condmode
	targetChange` (harmonisation unit 30 - see below), appended AFTER
	the entire behavior-fields block (even on every existing network-
	only/co-evolution call site, which now simply appends " 0 0" -
	same "known-length trailer, not a variable-position insert"
	convention this unit's own header comment on `nbehterms=0` already
	documents). Frame: v1/v2 = starting edge list (rows 1..nties_in) on
	input, FINAL simulated edge list on output (same "caller rebuilds
	its own graph object from the written-back edge list" contract as
	ergm_mcmc.c); v(3..3+nattr-1) = attribute columns (rows 1..n,
	read-only) - one per DISTINCT covariate array the model's own terms
	need (mirroring ergm_mcmc.c's own `native_attrmat` design), NOT one
	per term - two terms on the SAME covariate (e.g. nodeicov(age) and
	nodeocov(age)) share a single column, `attridx` (1-based, 0=none)
	selects which. Scalars saved back: __saom_native_nties_out,
	__saom_native_steps (TOTAL ministep opportunities, including "stay" -
	used for the rate parameter's own score contribution, matching
	SaomSimulateInterval()'s own return value), and
	__saom_native_nchanges (ACCEPTED ministeps only, i.e. actual tie
	toggles - the rate parameter's own moment STATISTIC, compared
	against the observed Hamming distance between waves; harmonisation
	unit 8). Deliberately does NOT also compute/return the final
	network's own statistics in C: the Mata caller rebuilds its ErgmGraph
	from the written-back edge list and calls the EXISTING, already-
	certified M.full_statistic() on it - the same code path the
	pure-Mata backend already uses - rather than duplicating that
	formula a second time in C where it could silently drift out of
	sync. Only the ministep sampler itself (the genuinely hot,
	per-alternative loop) is native; final-statistic computation is
	cheap (called once per simulated interval, not per ministep) and
	stays exactly where every other backend already computes it.

	CERTIFICATION CONTRACT: like ergm_mcmc.c's own MCMC sampler (and
	UNLIKE nwgraph.c's deterministic betweenness kernel), this is a
	STOCHASTIC simulator - certified via statistical equivalence of
	simulated end-of-interval statistic distributions across many runs
	at a fixed theta, against unw_saom.do's own pure-Mata
	SaomSimulateInterval() (the reference/fallback/oracle - unchanged,
	always available), not trajectory-level identity. See
	cscripts/test_nwsaom_native.do.

	CONDITIONAL MODE (harmonisation unit 30 - performance pass, per
	explicit user direction after a real, measured finding: a direct
	RSiena benchmark, dev/saom_rsiena_benchmark.R/.do, found
	SaomEstimateRM()'s own network-only path ~22x slower than real
	RSiena on s50 data, and profiling isolated the ENTIRE cost to
	harmonisation unit 27's own post-phase-3 rate-refinement loop -
	K3=1000 pure-Mata SaomSimulateConditionalTime() replicates, the
	ONE thing in that whole estimator that had never been ported
	native). `condmode=1` switches the SAME ministep sampler above from
	"run until t reaches a fixed interval length" to "run until the
	CURRENT network's signed Hamming distance from its OWN STARTING
	state reaches `targetChange`" - a direct C port of
	SaomSimulateConditionalTime() (unw_saom.do), which that Mata
	function's own header comment derives/verifies against RSiena's
	real C++ source (`EpochSimulation::runEpoch()`'s own
	`simulatedDistance()` stopping check) in full; read that comment
	for the derivation, not repeated here. `horig` below is a snapshot
	of the STARTING dyad membership (built once, right after the
	initial edge list loads, before any ministep mutates `g`) purely so
	each accepted toggle can tell whether it moved a dyad AWAY from or
	BACK TO its own starting value - the same signed-distance
	distinction that Mata function's own header comment documents as a
	real, easy-to-miss subtlety (a naive monotonic accepted-change
	counter is NOT equivalent and was already tried and rejected there).
	Reference rate is always 1 in this mode (the caller MUST pass
	`rate=1`, not a fitted value - see that Mata function's own header
	comment for why exactly 1 is the correct reference rate), and this
	mode is NEVER combined with behavior terms (`nbehterms` must be 0 -
	real RSiena's own conditional-estimation default itself only
	applies to a SINGLE dependent variable, never co-evolution - see
	that Mata function's own header comment's final paragraph) or with
	`want_score` (the refinement loop needs only the elapsed TIME, saved
	back as the new `__saom_native_condtime` scalar, never a Jacobian).
	Every existing field this plugin already parses (nterms, theta,
	want_score, nbehterms, ...) is untouched and still means exactly
	what it always has - `condmode`/`targetChange` are two BRAND NEW
	trailing fields, not a repurposing of anything.
*/

#include "stplugin.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define MAXTERMS 16
#define MAXATTR 8
#define MAXBEHTERMS 8

#define TERMCODE_OUTDEGREE 1
#define TERMCODE_RECIPROCITY 2
#define TERMCODE_NODEMATCH 3
#define TERMCODE_NODECOV 4
#define TERMCODE_NODEICOV 5
#define TERMCODE_NODEOCOV 6
#define TERMCODE_INDEGPOP 7
#define TERMCODE_OUTACTIVITY 8
#define TERMCODE_OUTPOP 9
#define TERMCODE_INACTIVITY 10
#define TERMCODE_TRANSTRIP 11
#define TERMCODE_CYCLE3 12
#define TERMCODE_SIMCOV 13

/* Behavior (co-evolution, harmonisation unit 26) term codes - a
   SEPARATE numbering range (101+, not 14+) so the wire protocol's own
   network-term and behavior-term fields can never be confused with one
   another even if a caller mixes up an argument position; direct C
   ports of unw_saom.do's own stat_saom_linear/quadratic/avalt/avsim -
   change_saom_avalt/change_saom_avsim's own out-neighbor iteration
   reuses this file's own `outadj' (already built for TRANSTRIP/CYCLE3),
   so `need_adj' below is also set whenever AVALT or AVSIM is active. */
#define TERMCODE_BEH_LINEAR 101
#define TERMCODE_BEH_QUADRATIC 102
#define TERMCODE_BEH_AVALT 103
#define TERMCODE_BEH_AVSIM 104

/* ===================================================================
   xorshift128+ RNG - independent reimplementation, same construction
   as native/ergm_mcmc.c's own (see this file's own header comment).
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

static double rng_unif(rng_t *r) {
	return (double)(rng_next(r) >> 11) * (1.0 / 9007199254740992.0);
}

/* ===================================================================
   Dyad hash table - same open-addressing/linear-probing/tombstone
   design as native/ergm_mcmc.c's own dyadht_t (independent
   reimplementation, see this file's own header comment).
   =================================================================== */

typedef struct {
	long *keys;
	long *vals;
	unsigned char *state; /* 0=empty 1=live 2=tomb */
	long cap;
	long nlive;
	long ntomb;
} dyadht_t;

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

static long ht_next_pow2(long n) {
	long p = 16;
	while (p < n) p <<= 1;
	return p;
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

static void ht_update_val(dyadht_t *h, long key, long newval) {
	long slot = ht_hash(key, h->cap);
	while (h->state[slot] != 0) {
		if (h->state[slot] == 1 && h->keys[slot] == key) { h->vals[slot] = newval; return; }
		slot = (slot + 1) & (h->cap - 1);
	}
}

static void ht_del(dyadht_t *h, long key) {
	long slot = ht_hash(key, h->cap);
	while (h->state[slot] != 0) {
		if (h->state[slot] == 1 && h->keys[slot] == key) {
			h->state[slot] = 2;
			h->nlive--;
			h->ntomb++;
			return;
		}
		slot = (slot + 1) & (h->cap - 1);
	}
}

/* ===================================================================
   Dynamic adjacency list - one per node, per direction. Same design as
   native/ergm_mcmc.c's own adjlist_t (independent reimplementation).
   Only allocated when the model actually needs OTP/OSP shared-partner
   computation (transtrip/cycle3) - see graph_t's own need_adj flag.
   =================================================================== */

typedef struct {
	long *nb;
	long len, cap;
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
   Graph state - directed only (SAOM's ministep formulation is
   inherently directed, see docs/SAOM_ROADMAP.md's v1 scope), so unlike
   ergm_mcmc.c's graph_t this never needs an undirected-symmetric
   dyadkey() branch. `dout'/`din' (new this unit) give O(1) degree
   lookups for the popularity/activity terms; `outadj'/`inadj' (new
   this unit, only allocated when need_adj) give the OTP/OSP traversal
   transtrip/cycle3 need.
   =================================================================== */

typedef struct {
	long n;
	int need_adj;
	dyadht_t ht;
	long *elist_i, *elist_j;
	long ecap, nties;
	long *dout, *din;
	adjlist_t *outadj, *inadj;
} graph_t;

static long dyadkey(graph_t *g, long i, long j) {
	return i * (g->n + 1) + j;
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

static void toggle(graph_t *g, long i, long j) {
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
		ht_del(&g->ht, key);
		g->nties--;
		g->dout[i]--; g->din[j]--;
		if (g->need_adj) { adj_remove(&g->outadj[i], j); adj_remove(&g->inadj[j], i); }
	}
	else {
		elist_ensure(g, g->nties + 1);
		g->elist_i[g->nties] = i;
		g->elist_j[g->nties] = j;
		ht_put(&g->ht, key, g->nties);
		g->nties++;
		g->dout[i]++; g->din[j]++;
		if (g->need_adj) { adj_add(&g->outadj[i], j); adj_add(&g->inadj[j], i); }
	}
}

/* ===================================================================
   Batch OTP/OSP precompute (harmonisation unit 13 - performance pass,
   see docs/SAOM_ROADMAP.md's own "Native backend performance" entries
   for units 11/12 and the controlled A/B that motivated this one: the
   per-alternative shared_partners_otp()/osp() calls this unit REPLACES
   each independently re-walked `actor's own neighborhood once PER
   ALTERNATIVE - O(n) alternatives x O(degree) traversal each, per
   ministep. Both `transtrip' and `cycle3' need the SAME actor-local
   neighborhood information for every alternative j in a single
   ministep, so it is computed ONCE per ministep for ALL j simultaneously
   instead: walk `actor's own (out- or in-) neighbors, and for each one,
   walk ITS neighbors, incrementing a per-target counter - a "two-hop
   fan-out" instead of "one target at a time". Cost:
   O(sum over actor's neighbors k of degree(k)), independent of `n' -
   for a sparse network (the typical SAOM/RSiena case) this replaces an
   O(n * degree(actor)) cost with one that does not scale with `n' at
   all, only with LOCAL degree structure. `out[]' is a caller-owned
   scratch array of size >= n+1, indices 1..n, which the caller MUST
   have zeroed before calling (a shared buffer reused across ministeps,
   not zeroed here, to avoid paying for it when a term isn't active).
   =================================================================== */

/* Accumulates OTP(actor,j)+OSP(actor,j) into out[j] for every j - the
   sum `transtrip's own change_saom_transtrip() (unw_saom.do) always
   needs. Direct algebraic reformulation of the old
   shared_partners_otp_plus_osp(actor,j), verified term-by-term against
   it (see this unit's own certification note in
   cscripts/test_nwsaom_native.do): OTP(actor,j) = #{k: actor->k, k->j,
   k!=j} - for each k in outadj[actor], every m in outadj[k] with m!=k
   gets out[m]+=1 (k contributes to OTP(actor,m) exactly when k->m).
   OSP(actor,j) = #{k: actor->k, j->k} - for each k in outadj[actor],
   every m in inadj[k] (m->k) gets out[m]+=1 (k contributes to
   OSP(actor,m) exactly when m->k). */
static void batch_otp_plus_osp(graph_t *g, long actor, double *out) {
	long mo, k, mi, m;
	for (mo = 0; mo < g->outadj[actor].len; mo++) {
		k = g->outadj[actor].nb[mo];
		for (mi = 0; mi < g->outadj[k].len; mi++) {
			m = g->outadj[k].nb[mi];
			if (m != k) out[m] += 1.0;
		}
		for (mi = 0; mi < g->inadj[k].len; mi++) {
			m = g->inadj[k].nb[mi];
			out[m] += 1.0;
		}
	}
}

/* Accumulates OTP(j,actor) into out[j] for every j - what `cycle3's own
   change_saom_cycle3() needs (the OLD code called
   shared_partners_otp(g,j,i) with i=actor, i.e. OTP(j,actor), for each
   alternative j in turn). OTP(j,actor) = #{k: j->k, k->actor, k!=actor}
   - k ranges over inadj[actor] (k->actor; k!=actor is automatic, no
   self-loops), and for each such k, every j in inadj[k] (j->k) gets
   out[j]+=1. */
static void batch_otp_reverse(graph_t *g, long actor, double *out) {
	long mo, k, mi, j;
	for (mo = 0; mo < g->inadj[actor].len; mo++) {
		k = g->inadj[actor].nb[mo];
		for (mi = 0; mi < g->inadj[k].len; mi++) {
			j = g->inadj[k].nb[mi];
			out[j] += 1.0;
		}
	}
}

/* ===================================================================
   Pair-wise OTP/ISP for the AGGREGATE statistic computation
   (harmonisation unit 14 - see saom_stat_term()'s own header comment
   for why this is a SEPARATE thing from batch_otp_plus_osp()/
   batch_otp_reverse() above, which serve the per-ministep CHANGE
   statistic instead). Direct one-pair-at-a-time ports (not batched -
   this runs once per simulated interval, not once per ministep
   alternative, so the batching that mattered for the hot loop is not
   the bottleneck here; a straightforward compiled-C port of the
   existing Mata algorithm's own complexity already delivers the win,
   per this session's own "decide term by term through profiling"
   discipline - unw_ergm.do's own established precedent, see
   shared_partners_otp()'s header comment there). Direct C ports of
   ErgmGraph's own shared_partners_otp()/shared_partners_isp() (Mata,
   unw_ergm.do, read-only reference).
   =================================================================== */

/* OTP(i,j) = #{k: i->k, k->j, k!=j}. */
static long pair_otp(graph_t *g, long i, long j) {
	long cnt = 0, m, k;
	for (m = 0; m < g->outadj[i].len; m++) {
		k = g->outadj[i].nb[m];
		if (k == j) continue;
		if (has_edge(g, k, j)) cnt++;
	}
	return cnt;
}

/* ISP(i,j) = #{k: k->i, k->j} - iterate the SMALLER in-neighbor set of
   i/j, testing membership in the other's via has_edge(), matching
   ErgmGraph::common_neighbors_in()'s own "iterate the smaller side"
   discipline (unw_ergm.do). */
static long pair_isp(graph_t *g, long i, long j) {
	long cnt = 0, m, k, other;
	adjlist_t *small;
	if (g->inadj[i].len <= g->inadj[j].len) { small = &g->inadj[i]; other = j; }
	else { small = &g->inadj[j]; other = i; }
	for (m = 0; m < small->len; m++) {
		k = small->nb[m];
		if (has_edge(g, k, other)) cnt++;
	}
	return cnt;
}

/* ===================================================================
   Aggregate (full-network) statistic per term - harmonisation unit 14
   (performance pass, see docs/SAOM_ROADMAP.md's own "Native backend
   performance" entry). Direct C ports of unw_saom.do's/unw_ergm.do's
   own stat_X() Mata functions (see this codebase's own established
   "certify every port against the ego-level/algebraic original"
   discipline - each case below is annotated with exactly which Mata
   function it ports and the formula match). Computed ONCE per
   simulated interval, on the FINAL graph state, reusing the SAME
   dout/din/outadj/inadj/elist/ht state the ministep loop already
   built - this is what lets stata_call() return the full statistic
   vector directly instead of the Mata caller re-deriving it via a
   second, much slower, pure-interpreted pass
   (M.full_statistic(Gwork)) over a freshly-rebuilt ErgmGraph. TRANSTRIP/
   CYCLE3 (the only cases needing pair_isp()/pair_otp()) are only ever
   dispatched when need_adj is true, matching the existing invariant
   that those termcodes are what SETS need_adj in the first place. */
static double saom_stat_term(graph_t *g, int termcode, double *a, double p1) {
	long i, k;
	double tot = 0.0;
	switch (termcode) {
		case TERMCODE_OUTDEGREE:					// stat_edges(): G.nties
			return (double)g->nties;
		case TERMCODE_RECIPROCITY:					// stat_mutual(): #{ties (i,j), i<j, with reverse (j,i) also present}
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				if (ei < ej && has_edge(g, ej, ei)) tot += 1.0;
			}
			return tot;
		case TERMCODE_NODEMATCH:					// stat_nodematch(): #{ties with attr[ego]==attr[alter]}
			for (k = 0; k < g->nties; k++) {
				if (a[g->elist_i[k]] == a[g->elist_j[k]]) tot += 1.0;
			}
			return tot;
		case TERMCODE_NODECOV:						// stat_nodecov(): sum over ties of attr[ego]+attr[alter]
			for (k = 0; k < g->nties; k++) tot += a[g->elist_i[k]] + a[g->elist_j[k]];
			return tot;
		case TERMCODE_NODEICOV:					// stat_nodeicov(): sum over nodes of attr[node]*indegree(node)
			for (i = 1; i <= g->n; i++) tot += a[i] * (double)g->din[i];
			return tot;
		case TERMCODE_NODEOCOV:					// stat_nodeocov(): sum over nodes of attr[node]*outdegree(node)
			for (i = 1; i <= g->n; i++) tot += a[i] * (double)g->dout[i];
			return tot;
		case TERMCODE_INDEGPOP:					// stat_saom_indegpop(): sum over nodes of indegree(node)^1.5
			for (i = 1; i <= g->n; i++) tot += pow((double)g->din[i], 1.5);
			return tot;
		case TERMCODE_OUTACTIVITY:					// stat_saom_outactivity(): sum over nodes of outdegree(node)^2
			for (i = 1; i <= g->n; i++) tot += (double)g->dout[i] * (double)g->dout[i];
			return tot;
		case TERMCODE_OUTPOP:						// stat_saom_outpop(): sum over nodes of sqrt(outdegree)*indegree
			for (i = 1; i <= g->n; i++) tot += sqrt((double)g->dout[i]) * (double)g->din[i];
			return tot;
		case TERMCODE_INACTIVITY:					// stat_saom_inact(): sum over nodes of outdegree*sqrt(indegree)
			for (i = 1; i <= g->n; i++) tot += (double)g->dout[i] * sqrt((double)g->din[i]);
			return tot;
		case TERMCODE_TRANSTRIP:					// stat_saom_transtrip(): sum over ties (ego,alter) of ISP(ego,alter)
			for (k = 0; k < g->nties; k++) tot += (double)pair_isp(g, g->elist_i[k], g->elist_j[k]);
			return tot;
		case TERMCODE_CYCLE3:						// stat_saom_cycle3(): sum over ties (ego,alter) of OTP(alter,ego)
			for (k = 0; k < g->nties; k++) tot += (double)pair_otp(g, g->elist_j[k], g->elist_i[k]);
			return tot;
		case TERMCODE_SIMCOV:						// stat_saom_simcov(): sum over ties of 1-|attr[ego]-attr[alter]|/decay
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				tot += 1.0 - fabs(a[ei] - a[ej]) / p1;
			}
			return tot;
	}
	return 0.0;
}

/* ===================================================================
   Term dispatch - direct C ports of unw_ergm.do's/unw_saom.do's own
   change_X() Mata functions, each independently re-derived/verified in
   this package's own harmonisation units 1-9 (see unw_saom.do's own
   header comments for the term-by-term derivation/verification
   account - not re-derived here, this is a mechanical port). `a' is
   the resolved attribute array for the terms that need one (NULL
   otherwise); `p1' is the one generic per-term scalar (only `simcov'
   uses it, for the covariate's own range).
   =================================================================== */

/* `ij_exists' (harmonisation unit 11 - performance pass) is has_edge(g,i,j)
   PRECOMPUTED ONCE by the caller before the per-term loop, not
   recomputed by each term that needs it - a direct before/after
   benchmark (docs/SAOM_ROADMAP.md's "Native backend performance" entry)
   motivated this: every one of these 13 terms except reciprocity's own
   OWN reverse-direction check needs exactly this one lookup, so a
   model with several active terms was paying for the identical hash
   lookup once per term instead of once per alternative. `tt_arr'/
   `c3_arr' (harmonisation unit 13) are the batch_otp_plus_osp()/
   batch_otp_reverse() precomputed-for-every-alternative arrays (see
   those functions' own header comments) - only dereferenced for
   TRANSTRIP/CYCLE3, so may be NULL when neither term is active in this
   model. */
static double saom_change_term(graph_t *g, int termcode, double *a, double p1, long i, long j, int ij_exists,
	double *tt_arr, double *c3_arr) {
	switch (termcode) {
		case TERMCODE_OUTDEGREE:
			return ij_exists ? -1.0 : 1.0;
		case TERMCODE_RECIPROCITY:
			if (!has_edge(g, j, i)) return 0.0;
			return ij_exists ? -1.0 : 1.0;
		case TERMCODE_NODEMATCH:
			if (a[i] != a[j]) return 0.0;
			return ij_exists ? -1.0 : 1.0;
		case TERMCODE_NODECOV: {
			double v = a[i] + a[j];
			return ij_exists ? -v : v;
		}
		case TERMCODE_NODEICOV:
			return ij_exists ? -a[j] : a[j];
		case TERMCODE_NODEOCOV:
			return ij_exists ? -a[i] : a[i];
		case TERMCODE_INDEGPOP: {
			double d = (double)g->din[j];
			return ij_exists ? -sqrt(d) : sqrt(d + 1.0);
		}
		case TERMCODE_OUTACTIVITY: {
			double d = (double)g->dout[i];
			return ij_exists ? -(2.0 * d - 1.0) : (2.0 * d + 1.0);
		}
		case TERMCODE_OUTPOP: {
			double d = sqrt((double)g->dout[j]);
			return ij_exists ? -d : d;
		}
		case TERMCODE_INACTIVITY: {
			double d = sqrt((double)g->din[i]);
			return ij_exists ? -d : d;
		}
		case TERMCODE_TRANSTRIP: {
			double d = tt_arr[j];
			return ij_exists ? -d : d;
		}
		case TERMCODE_CYCLE3: {
			double d = c3_arr[j];
			return ij_exists ? -d : d;
		}
		case TERMCODE_SIMCOV: {
			double d = 1.0 - fabs(a[i] - a[j]) / p1;
			return ij_exists ? -d : d;
		}
	}
	return 0.0;
}

/* ===================================================================
   Behavior (co-evolution) term dispatch - direct C ports of
   unw_saom.do's own stat_saom_linear/quadratic/avalt/avsim and
   change_saom_linear/quadratic/avalt/avsim, each independently
   verified against real RSiena source there (see that file's own
   header comments for the term-by-term derivation/verification
   account - not re-derived here, this is a mechanical port). `behval'
   is the current behavior-value array (index 1..n, mutated by the
   ministep loop below exactly like Mata's SaomBehavior.values); `simMean'
   is avsim's own data-derived centering constant (0, harmless, for
   every other term); `range' = behmaxval-behminval.
   =================================================================== */
static double saom_beh_stat_term(graph_t *g, double *behval, int termcode, double range, double simMean) {
	long i, k, od;
	double tot = 0.0, vego, sumabs;
	switch (termcode) {
		case TERMCODE_BEH_LINEAR:					// stat_saom_linear(): sum(values)
			for (i = 1; i <= g->n; i++) tot += behval[i];
			return tot;
		case TERMCODE_BEH_QUADRATIC:					// stat_saom_quadratic(): sum(values^2), RAW/uncentered
			for (i = 1; i <= g->n; i++) tot += behval[i] * behval[i];
			return tot;
		case TERMCODE_BEH_AVALT:					// stat_saom_avalt(): sum_i value_i * avg_{j in N_out(i)}(value_j)
			for (i = 1; i <= g->n; i++) {
				od = g->outadj[i].len;
				if (od == 0) continue;
				double s = 0.0;
				for (k = 0; k < od; k++) s += behval[g->outadj[i].nb[k]];
				tot += behval[i] * (s / (double)od);
			}
			return tot;
		case TERMCODE_BEH_AVSIM:					// stat_saom_avsim(): sum_i [avg_j sim(value_i,value_j) - simMean], 0 for no out-ties
			for (i = 1; i <= g->n; i++) {
				od = g->outadj[i].len;
				if (od == 0) continue;
				vego = behval[i];
				sumabs = 0.0;
				for (k = 0; k < od; k++) sumabs += fabs(behval[g->outadj[i].nb[k]] - vego);
				tot += 1.0 - (sumabs / range) / (double)od - simMean;
			}
			return tot;
	}
	return 0.0;
}

/* `overallMean' (quadratic's own ministep centering) and `range'/
   `simMean' (avsim) are the same model-level constants
   saom_beh_stat_term() above takes - see unw_saom.do's own
   change_saom_quadratic()/change_saom_avsim() for the derivation each
   branch below is a direct, mechanical port of. */
static double saom_beh_change_term(graph_t *g, double *behval, int termcode, double overallMean, double range,
	long i, double diff) {
	long od, k, nhigh, nlow;
	double vego;
	switch (termcode) {
		case TERMCODE_BEH_LINEAR:
			return diff;
		case TERMCODE_BEH_QUADRATIC:
			return (2.0 * (behval[i] - overallMean) + diff) * diff;
		case TERMCODE_BEH_AVALT: {
			od = g->outadj[i].len;
			if (od == 0) return 0.0;
			double s = 0.0;
			for (k = 0; k < od; k++) s += behval[g->outadj[i].nb[k]];
			return diff * (s / (double)od);
		}
		case TERMCODE_BEH_AVSIM: {
			od = g->outadj[i].len;
			if (od == 0 || diff == 0.0) return 0.0;
			vego = behval[i];
			nhigh = 0; nlow = 0;
			for (k = 0; k < od; k++) {
				double vj = behval[g->outadj[i].nb[k]];
				if (vj > vego) nhigh++;
				else if (vj < vego) nlow++;
			}
			if (diff > 0) return (2.0 * (double)nhigh - (double)od) / (range * (double)od);
			return (2.0 * (double)nlow - (double)od) / (range * (double)od);
		}
	}
	return 0.0;
}

/* ===================================================================
   Plugin entry point
   =================================================================== */

static char *tok_saveptr;

static long next_long(void) {
	return (long)atof(strtok(NULL, " \t"));
}
static double next_double(void) {
	return atof(strtok(NULL, " \t"));
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long n, directed, nties_in, nattr, nterms, i, k, want_score;
	double rate;
	unsigned long long rngseed;
	int termcodes[MAXTERMS];
	int attridx[MAXTERMS];
	double p1[MAXTERMS];
	double theta[MAXTERMS];
	double *attrs[MAXATTR];
	graph_t g;
	rng_t rng;
	double t, steps, nchanges;
	int need_adj, need_transtrip, need_cycle3;
	// --- co-evolution (harmonisation unit 26) fields - ALL trailing,
	// after `want_score' - `nbehterms=0' (no further behavior fields at
	// all) is the ENTIRE wire-protocol footprint on every existing
	// network-only caller, which now simply appends " 0" - see
	// SaomSimulateIntervalNative()'s own header comment in unw_saom.do.
	long nbehterms;
	int behtermcodes[MAXBEHTERMS];
	double thetaBeh[MAXBEHTERMS];
	double rateBeh, behminval, behmaxval, behrange, behSimMean, behOverallMean;
	double *behval = NULL;
	double nchangesBeh;
	int need_behadj;
	// --- conditional mode (harmonisation unit 30) - see this file's
	// own header comment's "CONDITIONAL MODE" section for the full
	// account. `horig'/`simDist' only touched when condmode!=0.
	long condmode;
	double targetChange;
	dyadht_t horig;
	long simDist;
	(void)tok_saveptr;

	if (argc < 1) { SF_error("saom_sim: missing argument string\n"); return(198); }

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	n         = (long)atof(strtok(argbuf, " \t"));
	directed  = next_long();
	nties_in  = next_long();
	rate      = next_double();
	rngseed   = (unsigned long long)next_double();
	nattr     = next_long();
	nterms    = next_long();
	if (nterms > MAXTERMS) { SF_error("saom_sim: too many terms\n"); free(argbuf); return(198); }
	if (nattr > MAXATTR) { SF_error("saom_sim: too many attribute arrays\n"); free(argbuf); return(198); }
	need_adj = 0;
	need_transtrip = 0;
	need_cycle3 = 0;
	for (i = 0; i < nterms; i++) {
		termcodes[i] = (int)next_long();
		attridx[i] = (int)next_long();
		p1[i] = next_double();
		if (termcodes[i] == TERMCODE_TRANSTRIP || termcodes[i] == TERMCODE_CYCLE3) need_adj = 1;
		if (termcodes[i] == TERMCODE_TRANSTRIP) need_transtrip = 1;
		if (termcodes[i] == TERMCODE_CYCLE3) need_cycle3 = 1;
	}
	for (i = 0; i < nterms; i++) theta[i] = next_double();
	want_score = next_long();		// harmonisation unit 16 - see saom_stat_term()'s own sibling, the score accumulator in the ministep loop below

	nbehterms = next_long();
	if (nbehterms > MAXBEHTERMS) { SF_error("saom_sim: too many behavior terms\n"); free(argbuf); return(198); }
	need_behadj = 0;
	for (i = 0; i < nbehterms; i++) {
		behtermcodes[i] = (int)next_long();
		if (behtermcodes[i] == TERMCODE_BEH_AVALT || behtermcodes[i] == TERMCODE_BEH_AVSIM) need_behadj = 1;
	}
	for (i = 0; i < nbehterms; i++) thetaBeh[i] = next_double();
	if (nbehterms > 0) {
		rateBeh = next_double();
		behminval = next_double();
		behmaxval = next_double();
		behSimMean = next_double();
		behOverallMean = next_double();
		behrange = behmaxval - behminval;
	}
	else {
		rateBeh = 0.0; behminval = 0.0; behmaxval = 0.0; behrange = 1.0; behSimMean = 0.0; behOverallMean = 0.0;
	}
	condmode = next_long();
	targetChange = next_double();
	free(argbuf);

	if (!directed) { SF_error("saom_sim: directed networks only\n"); return(198); }
	if (need_behadj) need_adj = 1;		// avalt/avsim need outadj exactly like transtrip/cycle3 do

	/* --- build starting graph from dataset columns v1=ego v2=alter
	   (rows 1..nties_in), then nattr attribute columns (rows 1..n) --- */
	g.n = n;
	g.need_adj = need_adj;
	ht_alloc(&g.ht, ht_next_pow2(nties_in * 2 + 16));
	g.elist_i = NULL; g.elist_j = NULL; g.ecap = 0; g.nties = 0;
	g.dout = (long *)calloc((size_t)(n + 1), sizeof(long));
	g.din  = (long *)calloc((size_t)(n + 1), sizeof(long));
	g.outadj = NULL; g.inadj = NULL;
	if (need_adj) {
		g.outadj = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		g.inadj  = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		for (i = 0; i <= n; i++) { adj_init(&g.outadj[i]); adj_init(&g.inadj[i]); }
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

	simDist = 0;
	if (condmode) {
		// snapshot the STARTING dyad membership BEFORE any ministep
		// mutates `g' - see this file's own "CONDITIONAL MODE" header
		// comment for why signed distance-from-start needs this rather
		// than a monotonic accepted-change counter. `dyadkey()' only
		// reads g->n (shared, unaffected by which hashtable it indexes
		// into), so reusing it against `horig' here is safe.
		ht_alloc(&horig, ht_next_pow2(nties_in * 2 + 16));
		for (i = 0; i < g.nties; i++) {
			ht_put(&horig, dyadkey(&g, g.elist_i[i], g.elist_j[i]), 1);
		}
	}

	if (nbehterms > 0) {
		// behavior values live in the column right after the last
		// attribute column (3+nattr) - see SaomSimulateIntervalCoevNative()'s
		// own header comment in unw_saom.do for the variable-list contract.
		behval = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(3 + nattr), i, &v);
			behval[i] = v;
		}
	}

	/* --- simulate one full interval: pooled waiting time
	   Exponential(n*rate) between successive ministeps, acting actor
	   uniform 1..n conditional on an opportunity occurring - see
	   unw_saom.do's own SaomSimulateInterval() header comment for the
	   continuous-time derivation this is a direct port of. --- */
	rng_seed(&rng, rngseed);
	t = 0.0;
	steps = 0.0;
	nchanges = 0.0;
	{
		/* `u'/`ev' allocated ONCE for the whole simulated interval (not
		   per ministep) - reused across every ministep, avoiding
		   malloc/free churn on what is by far the hottest loop in this
		   file. `ev[j]' (harmonisation unit 11 - performance pass, see
		   docs/SAOM_ROADMAP.md's "Native backend performance" entry)
		   caches exp(u[j]-maxu) so it is computed exactly ONCE per
		   alternative per ministep - the original version computed it
		   twice (once building the softmax denominator, again while
		   searching for the sampled alternative), a real, measured cost
		   for exp() being far more expensive than the (typically cheap)
		   change-statistic arithmetic itself. */
		double *u = (double *)malloc((size_t)(n + 1) * sizeof(double));
		double *ev = (double *)malloc((size_t)(n + 1) * sizeof(double));
		/* `tt_arr'/`c3_arr' (harmonisation unit 13 - performance pass, see
		   batch_otp_plus_osp()/batch_otp_reverse()'s own header comments
		   and docs/SAOM_ROADMAP.md's "Native backend performance" entry)
		   hold OTP(actor,j)+OSP(actor,j) / OTP(j,actor) for EVERY
		   alternative j, precomputed ONCE per ministep instead of once
		   per (alternative, term) pair - allocated once for the whole
		   interval like `u'/`ev', only when the model actually uses
		   `transtrip'/`cycle3' (need_transtrip/need_cycle3), matching
		   `outadj'/`inadj's own "only pay for what a model actually uses"
		   convention. */
		double *tt_arr = need_transtrip ? (double *)malloc((size_t)(n + 1) * sizeof(double)) : NULL;
		double *c3_arr = need_cycle3 ? (double *)malloc((size_t)(n + 1) * sizeof(double)) : NULL;
		/* `chgstore'/`score' (harmonisation unit 16 - performance pass,
		   see docs/SAOM_ROADMAP.md's own "Native backend performance"
		   entry): phase 1's own Jacobian estimator (unw_saom.do's
		   SaomSimulateIntervalScored()) needs, for EVERY ministep, the
		   score-function derivative-estimator identity chg(chosen) -
		   E_p[chg] (see that Mata function's own header comment for the
		   derivation) - which needs each alternative's own FULL raw
		   per-term change-statistic value, not just the theta-weighted
		   scalar utility `u[j]' the plain (want_score=0) path already
		   computes. `chgstore[j*nterms+k]' caches term k's own raw value
		   for alternative j (computed once, in the SAME loop that
		   already computes `u[j]' - no second pass over the terms) so
		   the softmax-weighted `ebar'/`chosen_chg' vectors below can be
		   built without recomputing any saom_change_term() call. Only
		   allocated when want_score, matching every other "only pay for
		   what a model/call actually uses" convention in this file. */
		double *chgstore = want_score ? (double *)malloc((size_t)(n + 1) * (size_t)nterms * sizeof(double)) : NULL;
		double *score = want_score ? (double *)calloc((size_t)nterms, sizeof(double)) : NULL;
		double *scoreBeh = (want_score && nbehterms > 0) ? (double *)calloc((size_t)nbehterms, sizeof(double)) : NULL;
		// grand rate = network's own total rate + behavior's own total
		// rate (0 when nbehterms==0, so grandRate==n*rate exactly - the
		// existing network-only draw, unchanged) - direct C port of the
		// multi-variable race SaomSimulateIntervalCoevScored() (unw_saom.do)
		// already implements: ONE pooled exponential waiting time from the
		// GRAND total, which VARIABLE acts chosen proportional to its own
		// share, then an actor uniform within that variable.
		double grandRate = (double)n * rate + (double)n * rateBeh;
		nchangesBeh = 0.0;
		while (condmode ? (simDist < targetChange) : (t < 1.0)) {
			t -= log(rng_unif(&rng)) / grandRate;
			if (condmode || t < 1.0) {
				int actNet = (nbehterms == 0) || (rng_unif(&rng) * grandRate <= (double)n * rate);
				if (actNet) {
					long actor = 1 + (long)(rng_unif(&rng) * (double)n);
					long j, choice;
					double maxu = 0.0, stayterm, denom, draw, cum;

					if (need_transtrip) {
						memset(tt_arr, 0, (size_t)(n + 1) * sizeof(double));
						batch_otp_plus_osp(&g, actor, tt_arr);
					}
					if (need_cycle3) {
						memset(c3_arr, 0, (size_t)(n + 1) * sizeof(double));
						batch_otp_reverse(&g, actor, c3_arr);
					}

					for (j = 1; j <= n; j++) {
						if (j == actor) continue;
						int ij_exists = has_edge(&g, actor, j);
						double uj = 0.0;
						for (k = 0; k < nterms; k++) {
							double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
							double cv = saom_change_term(&g, termcodes[k], a, p1[k], actor, j, ij_exists, tt_arr, c3_arr);
							if (want_score) chgstore[j * nterms + k] = cv;
							uj += theta[k] * cv;
						}
						u[j] = uj;
						if (uj > maxu) maxu = uj;
					}

					stayterm = exp(0.0 - maxu);
					denom = stayterm;
					for (j = 1; j <= n; j++) {
						if (j == actor) continue;
						ev[j] = exp(u[j] - maxu);
						denom += ev[j];
					}

					draw = rng_unif(&rng) * denom;
					cum = stayterm;
					choice = 0;
					if (draw > cum) {
						for (j = 1; j <= n; j++) {
							if (j == actor) continue;
							cum += ev[j];
							choice = j;
							if (draw <= cum) break;
						}
					}
					if (want_score) {
						for (k = 0; k < nterms; k++) {
							double ebar_k = 0.0, chosen_k;
							for (j = 1; j <= n; j++) {
								if (j == actor) continue;
								ebar_k += (ev[j] / denom) * chgstore[j * nterms + k];
							}
							chosen_k = (choice != 0) ? chgstore[choice * nterms + k] : 0.0;
							score[k] += chosen_k - ebar_k;
						}
					}
					if (choice != 0) {
						toggle(&g, actor, choice);
						nchanges += 1.0;
						if (condmode) {
							// signed distance-from-start: DECREASES when this
							// toggle reverts the dyad back to its OWN starting
							// value, INCREASES when it newly differs - see this
							// file's own "CONDITIONAL MODE" header comment.
							long origval;
							int newstate = has_edge(&g, actor, choice);
							int origstate = ht_get(&horig, dyadkey(&g, actor, choice), &origval);
							if (newstate == origstate) simDist -= 1; else simDist += 1;
						}
					}
				}
				else {
					// --- behavior ministep: exactly 3 alternatives
					// (down/stay/up, clamped to [behminval,behmaxval]) -
					// direct C port of SaomBehaviorMinistep()'s own
					// numerically-stable softmax (unw_saom.do), extended
					// with the SAME ebar/chosen_chg score accumulation
					// the network branch above already uses.
					long actor = 1 + (long)(rng_unif(&rng) * (double)n);
					double cur = behval[actor];
					double chgDown[MAXBEHTERMS], chgUp[MAXBEHTERMS];
					double uDown = 0.0, uUp = 0.0, maxu2 = 0.0, denom2, draw2, diff;
					int hasDown = (cur > behminval), hasUp = (cur < behmaxval);

					if (hasDown) {
						uDown = 0.0;
						for (k = 0; k < nbehterms; k++) {
							chgDown[k] = saom_beh_change_term(&g, behval, behtermcodes[k], behOverallMean, behrange, actor, -1.0);
							uDown += thetaBeh[k] * chgDown[k];
						}
						if (uDown > maxu2) maxu2 = uDown;
					}
					if (hasUp) {
						uUp = 0.0;
						for (k = 0; k < nbehterms; k++) {
							chgUp[k] = saom_beh_change_term(&g, behval, behtermcodes[k], behOverallMean, behrange, actor, 1.0);
							uUp += thetaBeh[k] * chgUp[k];
						}
						if (uUp > maxu2) maxu2 = uUp;
					}

					denom2 = exp(0.0 - maxu2);
					if (hasDown) denom2 += exp(uDown - maxu2);
					if (hasUp) denom2 += exp(uUp - maxu2);

					if (want_score) {
						for (k = 0; k < nbehterms; k++) {
							double ebar_k = 0.0;
							if (hasDown) ebar_k += (exp(uDown - maxu2) / denom2) * chgDown[k];
							if (hasUp) ebar_k += (exp(uUp - maxu2) / denom2) * chgUp[k];
							scoreBeh[k] -= ebar_k;		// chosen contribution added below once diff is known
						}
					}

					draw2 = rng_unif(&rng) * denom2;
					diff = 0.0;
					if (hasDown && draw2 <= exp(uDown - maxu2)) {
						diff = -1.0;
						behval[actor] = cur - 1.0;
						if (want_score) for (k = 0; k < nbehterms; k++) scoreBeh[k] += chgDown[k];
					}
					else {
						if (hasDown) draw2 -= exp(uDown - maxu2);
						if (draw2 <= exp(0.0 - maxu2)) {
							diff = 0.0;		// "stay" - chosen change vector is the zero vector, nothing further to add
						}
						else {
							diff = 1.0;
							behval[actor] = cur + 1.0;
							if (want_score) for (k = 0; k < nbehterms; k++) scoreBeh[k] += chgUp[k];
						}
					}
					if (diff != 0.0) nchangesBeh += 1.0;
				}
				steps += 1.0;
			}
		}
		if (want_score) {
			for (k = 0; k < nterms; k++) {
				char scorename[40];
				sprintf(scorename, "__saom_native_score%ld", k + 1);
				SF_scal_save(scorename, score[k]);
			}
			if (nbehterms > 0) {
				for (k = 0; k < nbehterms; k++) {
					char scorename[40];
					sprintf(scorename, "__saom_native_scorebeh%ld", k + 1);
					SF_scal_save(scorename, scoreBeh[k]);
				}
			}
		}
		free(u);
		free(ev);
		free(tt_arr);
		free(c3_arr);
		free(chgstore);
		free(score);
		free(scoreBeh);
	}

	/* --- write back final edge list; the Mata caller still rebuilds its
	   own ErgmGraph from this (test-suite equivalence certification
	   still relies on it, and the Mata fallback path always needs it) -
	   but harmonisation unit 14 (performance pass, see
	   docs/SAOM_ROADMAP.md's own "Native backend performance" entry)
	   ALSO computes and returns the full statistic vector directly here
	   (saom_stat_term(), above), on the SAME graph state, before the
	   adjacency lists TRANSTRIP/CYCLE3 need are freed below - so
	   SaomEstimateRM()'s own native path no longer needs to re-derive it
	   via a second, much slower, pure-interpreted M.full_statistic()
	   pass over a freshly-rebuilt ErgmGraph. --- */
	for (i = 0; i < g.nties; i++) {
		SF_vstore(1, i + 1, (ST_double)g.elist_i[i]);
		SF_vstore(2, i + 1, (ST_double)g.elist_j[i]);
	}
	SF_scal_save("__saom_native_nties_out", (ST_double)g.nties);
	SF_scal_save("__saom_native_steps", (ST_double)steps);
	SF_scal_save("__saom_native_nchanges", (ST_double)nchanges);
	SF_scal_save("__saom_native_condtime", (ST_double)t);		// harmonisation unit 30 - only meaningful when condmode!=0, always saved (uniform wire contract)
	if (condmode) ht_free(&horig);
	for (k = 0; k < nterms; k++) {
		char statname[40];
		double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
		sprintf(statname, "__saom_native_stat%ld", k + 1);
		SF_scal_save(statname, saom_stat_term(&g, termcodes[k], a, p1[k]));
	}

	// --- co-evolution (harmonisation unit 26): write back the final
	// behavior-value column and its own scalars, mirroring the network
	// side's identical contract exactly (final state written back, plus
	// nchanges/per-term statistic computed once on that same final
	// state) - see SaomSimulateIntervalCoevNative()'s own header comment
	// in unw_saom.do for the caller-side read-back.
	if (nbehterms > 0) {
		for (i = 1; i <= n; i++) SF_vstore((int)(3 + nattr), i, (ST_double)behval[i]);
		SF_scal_save("__saom_native_nchangesbeh", (ST_double)nchangesBeh);
		for (k = 0; k < nbehterms; k++) {
			char statname[40];
			sprintf(statname, "__saom_native_statbeh%ld", k + 1);
			SF_scal_save(statname, saom_beh_stat_term(&g, behval, behtermcodes[k], behrange, behSimMean));
		}
	}
	free(behval);

	for (k = 0; k < nattr; k++) free(attrs[k]);
	ht_free(&g.ht);
	free(g.elist_i); free(g.elist_j);
	free(g.dout); free(g.din);
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
