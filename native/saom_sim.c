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

	MISSING DATA (harmonisation unit 35 - native port, per explicit user
	direction "Move to native backend with it" after a direct benchmark
	found missing-data fits ~50x slower than a native-eligible fit,
	root-caused entirely to native being force-disabled, not to the
	masking computation itself - see docs/SAOM_ROADMAP.md's own unit-35
	entry). TWO more brand-new trailing fields, after `condmode
	targetChange`: `hasmiss nmissdyads` - every existing caller simply
	appends " 0 0" (matching the "known-length trailer" convention
	above). When `hasmiss=1`, THREE more frame columns are ALWAYS
	present together (even if only one of missnet()/missbeh() is
	actually active - the unused one is all-zero), at FIXED positions
	right after every other column this file already reads: `mv1`/`mv2`
	(the missing-dyad list, rows 1..nmissdyads, same sparse-pair
	convention as the v1/v2 tie list itself) and `missbeh` (rows 1..n,
	0/1, behavior-missingness). Applied ONLY to the FINAL statistic
	computation (see build_masked_graph()'s own header comment further
	down this file for the full design/masking-rule account) - the
	ministep sampler itself is completely unaffected, matching
	unw_saom.do's own Mata implementation exactly (missing data does
	not restrict who can act, unlike composition change).

	COMPOSITION CHANGE (harmonisation unit 33 - native port, per explicit
	user direction "Can you also speed up composition change by not
	falling back to Mata?", the direct follow-up once missing data's own
	identical Mata-fallback tax was fixed above). ONE more brand-new
	trailing field, after `hasmiss nmissdyads`: `haspresentNet` - every
	existing caller simply appends " 0". When `haspresentNet=1`, ONE more
	frame column, `present` (rows 1..n, 0/1, 1=present/eligible to act
	or be tied to, 0=absent), is present at a FIXED position right after
	the missing-data columns (if any). UNLIKE missing data, this DOES
	restrict the ministep sampler itself - a direct C port of
	unw_saom.do's own SaomMinistep()/SaomSimulateInterval()/
	SaomSimulateIntervalCoevScored() joiners-and-leavers construction
	(see those functions' own header comments for the full RSiena-
	verified design account, not repeated here): (1) the acting actor is
	drawn UNIFORMLY from PRESENT actors only (`presentIdxArr`, a compact
	list of present actor indices built once below - avoids rejection
	sampling), for BOTH the network and behavior branches of the grand-
	rate race; (2) the pooled rate scales by `npresent`, not `n` (absent
	actors get no activation opportunities, so cannot contribute to the
	rate either); (3) an absent alternative j is never offered as a
	tie-target - excluded from every one of the ministep's own four
	per-alternative loops (build u[j]/track max, softmax denominator,
	the sampled-choice walk, and the score-vector's own ebar
	accumulation) via `presentArr[j]`, mirroring SaomMinistep()'s own
	identical four-site exclusion exactly, not approximated. Composition
	change and missing data are fully independent and freely combinable
	(both flags/column blocks coexist).
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
#define TERMCODE_ISOLATENET 14
#define TERMCODE_OUTISO 15
#define TERMCODE_TRANSRECTRIP 16				// direct port of change_saom_transrectrip() (unw_saom.do) - see saom_change_term()'s own case for the derivation reference
#define TERMCODE_OUTOUTASS 17					// direct port of change_saom_outoutass()
#define TERMCODE_ININASS 18					// direct port of change_saom_ininass()
#define TERMCODE_OUTINASS 19					// direct port of change_saom_outinass()
#define TERMCODE_INOUTASS 20					// direct port of change_saom_inoutass()
#define TERMCODE_CYCLE4 21					// direct port of change_saom_cycle4() - needs need_adj (both outadj AND inadj, see pair_cycle4_threepaths())
#define TERMCODE_CRPROD 22					// multiplex cross-network effect (unw_saom.do's stat_crprod()/change_crprod()) - reused for BOTH "crprod" and "crprodb" (Mata's own single change_crprod() already serves both, since the distinction is only which model/graph hosts the term, not a different formula) - ONLY valid inside the two-graph multiplex native path below (saom_change_term_nn()), never in the ordinary single-graph stata_call() path, since it needs a second graph_t to read
#define TERMCODE_TRANSMEDTRIP 23				// direct port of change_saom_transmedtrip() (unw_saom.do) - RSiena's real transMedTrip, pure ISP(i,j) via the already-existing pair_isp() primitive, no batch precompute (mirrors TRANSRECTRIP's own direct-per-alternative shape, not TRANSTRIP's/CYCLE3's batched one)
#define TERMCODE_ANTIINISO 24					// direct port of change_saom_antiiniso() - AntiIsolateEffect(outAlso=false,minDegree=1), alter-indexed, spillover-free (outIso's own shape)
#define TERMCODE_ANTIINISO2 25					// direct port of change_saom_antiiniso2() - AntiIsolateEffect(outAlso=false,minDegree=2)
#define TERMCODE_GWESP 26					// direct port of change_saom_gwesp() - RSiena's gwespFF ministep IS just gw_kernel(pair_otp(i,j),decay), no neighbor-adjustment loops (real RSiena's own GenericNetworkEffect::calculateContribution() shape, deliberately simpler than nwergm's own full ERGM change statistic - see unw_saom.do's own header comment); uses p1 for decay, same convention as TERMCODE_SIMCOV
#define TERMCODE_TRANSTIES 27					// direct port of change_saom_transties() - own-dyad OTP(i,j)>=1 indicator plus a neighbors_out(j) loop checking each existing i->b for a newly-crossed OTP(i,b)>=1 threshold (RSiena's own dedicated TransitiveTiesEffect class, NOT a Generic-effect kernel lookup like GWESP above)
#define TERMCODE_BALANCE 28					// direct port of change_saom_balance() - RSiena's own dedicated BalanceEffect class; uses p1 for the data-derived balanceMean constant (b0), precomputed once by Mata's saom_balance_mean() before simulation starts, same "real scalar parameter crosses via p1" convention as GWESP/SIMCOV above
#define TERMCODE_IN3PLUS 29					// direct port of change_saom_in3plus() - RSiena's real "in3Plus", dispatched by EffectFactory.cpp to the SAME AntiIsolateEffect class as ANTIINISO/ANTIINISO2 above, just with minDegree=3 instead of 1/2 - identical alter-indexed, spillover-free shape
#define TERMCODE_INTERACT2 30					// two-way interaction between two ALREADY-REGISTERED dyadic ("tie-summed") network effects (RSiena's includeInteraction()) - direct port of RSiena's real NetworkInteractionEffect (confirmed from RSiena/src/model/effects/NetworkInteractionEffect.cpp): calculateContribution() = product of the two components' own calculateContribution(); tieStatistic() = product of the two components' own tieStatistic() (a GENUINELY different formula for any component with ministep neighbor-spillover - transties/outoutass/ininass/outinass/inoutass/cycle4/balance - see saom_tie_stat()'s own header comment). Attridx/p1 are REPURPOSED for this termcode ONLY: attridx holds the 1-based slot index (into this SAME model's own termcodes[]/attridx[]/p1[]/attrs[] arrays) of component A, p1 holds component B's 1-based slot index (cast to int at use) - reuses the existing per-term wire slots instead of adding new wire-protocol fields, matching this file's own established "reuse p1" convention (see TERMCODE_SIMCOV's own comment). Restricted to the "dyadic" termcode subset with a well-defined tieStatistic() - the node-level/nonlinear-in-degree termcodes (indegpop, outactivity, outpop, inactivity, isolatenet, outiso, antiiniso, antiiniso2, in3plus - RSiena's own "ego effects") are rejected by nwsaom.ado's own interact() eligibility check before ever reaching here. Three-way interactions (RSiena's optional third effect) and behavior-behavior/network-behavior interactions are a disclosed, not-yet-built follow-up.

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

/* Numerically-stable logistic(x) = 1/(1+exp(-x)), avoiding exp() overflow
   for a large positive argument - the same form RSiena's own real
   NetworkVariable.cpp (calculateModelTypeBProbabilities()) uses at every
   one of its own symmetric-model-type probability calculations (BFORCE/
   BAGREE/BJOINT all branch on sign then pick the matching exp() form
   rather than calling exp() on a possibly-large-positive raw x). Factored
   out here (BJOINT previously inlined this once; BFORCE/BAGREE below need
   it two/three more times) rather than duplicated per call site. */
static double stable_logistic(double x) {
	return (x > 0.0) ? (1.0 / (1.0 + exp(-x))) : (exp(x) / (1.0 + exp(x)));
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

/* OSP(i,j) = #{k: i->k, j->k} - common OUT-neighbors, the mirror of
   pair_isp() above over outadj instead of inadj (Mata's own
   ErgmGraph::shared_partners_osp(), unw_ergm.do, read-only reference -
   used here by BALANCE, harmonisation unit 25's own D(i,j) term). */
static long pair_osp(graph_t *g, long i, long j) {
	long cnt = 0, m, k, other;
	adjlist_t *small;
	if (g->outadj[i].len <= g->outadj[j].len) { small = &g->outadj[i]; other = j; }
	else { small = &g->outadj[j]; other = i; }
	for (m = 0; m < small->len; m++) {
		k = small->nb[m];
		if (has_edge(g, other, k)) cnt++;
	}
	return cnt;
}

/* gw_kernel(d,decay) = exp(decay)*(1-(1-exp(-decay))^d) - Mata's own
   ErgmGraph-side gw_kernel() (unw_ergm.do) and native/ergm_mcmc.c's own
   identical helper, independently re-declared here rather than shared
   across files (this file's own established "never share/edit
   native/ergm_mcmc.c" convention) - used by GWESP below. */
static double gw_kernel(double d, double decay) {
	return exp(decay) * (1.0 - pow(1.0 - exp(-decay), d));
}

/* Direct C port of Mata's _saom_cycle4_threepaths(G,i,j) (unw_saom.do,
   harmonisation unit 168) - RSiena's own FourCyclesEffect::countThreePaths,
   i->h<-k->j: h ranges over i's own OUT-neighbors (h!=j), k ranges over
   h's own IN-neighbors (k!=i), and each such k contributes 1 if k->j
   exists. NOT the same shape as pair_otp()/pair_isp() above (a
   genuinely different three-arc, direction-reversing-at-the-middle-step
   traversal) - see unw_saom.do's own header comment for the full
   derivation/source-verification account. */
static long pair_cycle4_threepaths(graph_t *g, long i, long j) {
	long cnt = 0, m, mm, h, k;
	for (m = 0; m < g->outadj[i].len; m++) {
		h = g->outadj[i].nb[m];
		if (h == j) continue;
		for (mm = 0; mm < g->inadj[h].len; mm++) {
			k = g->inadj[h].nb[mm];
			if (k == i) continue;
			if (has_edge(g, k, j)) cnt++;
		}
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
		case TERMCODE_TRANSMEDTRIP:					// stat_saom_transmedtrip(): sum over ties (ego,alter) of ISP(ego,alter) - same primitive as TRANSTRIP's own stat case, but this term's OWN change function is pure ISP too (unlike TRANSTRIP's OTP+OSP change), so the two termcodes are NOT interchangeable despite sharing this one line
			for (k = 0; k < g->nties; k++) tot += (double)pair_isp(g, g->elist_i[k], g->elist_j[k]);
			return tot;
		case TERMCODE_ANTIINISO:					// stat_saom_antiiniso(): #{i : indegree(i)>=1}
			for (i = 1; i <= g->n; i++) tot += (g->din[i] >= 1) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_ANTIINISO2:					// stat_saom_antiiniso2(): #{i : indegree(i)>=2}
			for (i = 1; i <= g->n; i++) tot += (g->din[i] >= 2) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_IN3PLUS:						// stat_saom_in3plus(): #{i : indegree(i)>=3}
			for (i = 1; i <= g->n; i++) tot += (g->din[i] >= 3) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_GWESP:						// stat_saom_gwesp(): sum over ties (ego,alter) of gw_kernel(OTP(ego,alter), decay) - direct reuse of nwergm's own already-certified stat_gwesp_otp() formula (RSiena's tieStatistic() confirmed to match exactly; only the MINISTEP formula below differs from nwergm's own)
			for (k = 0; k < g->nties; k++) tot += gw_kernel((double)pair_otp(g, g->elist_i[k], g->elist_j[k]), p1);
			return tot;
		case TERMCODE_TRANSTIES:					// stat_transitiveties(): sum over ties (ego,alter) of indicator(OTP(ego,alter)>=1) - direct reuse of nwergm's own already-certified global statistic (RSiena's tieStatistic() confirmed to match; only the MINISTEP formula below differs)
			for (k = 0; k < g->nties; k++) tot += (pair_otp(g, g->elist_i[k], g->elist_j[k]) >= 1) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_BALANCE: {					// stat_saom_balance(): sum over ties (i,j) of ((n-2)*b0 - D(i,j)), D(i,j) = (dout[i]-1) + (dout[j]-has_edge(j,i)) - 2*OSP(i,j) - p1 carries b0 (balanceMean), precomputed once by Mata's saom_balance_mean() before simulation starts
			double b0 = p1;
			double nterm = (double)g->n - 2.0;
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				double D = ((double)g->dout[ei] - 1.0)
					+ ((double)g->dout[ej] - (has_edge(g, ej, ei) ? 1.0 : 0.0))
					- 2.0 * (double)pair_osp(g, ei, ej);
				tot += nterm * b0 - D;
			}
			return tot;
		}
		case TERMCODE_CYCLE3:						// stat_saom_cycle3(): sum over ties (ego,alter) of OTP(alter,ego)
			for (k = 0; k < g->nties; k++) tot += (double)pair_otp(g, g->elist_j[k], g->elist_i[k]);
			return tot;
		case TERMCODE_SIMCOV:						// stat_saom_simcov(): sum over ties of 1-|attr[ego]-attr[alter]|/decay
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				tot += 1.0 - fabs(a[ei] - a[ej]) / p1;
			}
			return tot;
		case TERMCODE_ISOLATENET:					// stat_saom_isolatenet(): #{i : indegree(i)=0 AND outdegree(i)=0}
			for (i = 1; i <= g->n; i++) tot += (g->din[i] == 0 && g->dout[i] == 0) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_OUTISO:						// stat_saom_outiso(): #{i : outdegree(i)=0}
			for (i = 1; i <= g->n; i++) tot += (g->dout[i] == 0) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_TRANSRECTRIP:					// stat_saom_transrectrip(): sum over ties (i,j) with x_ji=1 of OTP(i,j)
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				if (has_edge(g, ej, ei)) tot += (double)pair_otp(g, ei, ej);
			}
			return tot;
		case TERMCODE_OUTOUTASS:					// stat_saom_outoutass(): sum over ties of outdeg(ego)*outdeg(alter)
			for (k = 0; k < g->nties; k++) tot += (double)g->dout[g->elist_i[k]] * (double)g->dout[g->elist_j[k]];
			return tot;
		case TERMCODE_ININASS:						// stat_saom_ininass(): sum over ties of indeg(ego)*indeg(alter)
			for (k = 0; k < g->nties; k++) tot += (double)g->din[g->elist_i[k]] * (double)g->din[g->elist_j[k]];
			return tot;
		case TERMCODE_OUTINASS:					// stat_saom_outinass(): sum over ties of outdeg(ego)*indeg(alter)
			for (k = 0; k < g->nties; k++) tot += (double)g->dout[g->elist_i[k]] * (double)g->din[g->elist_j[k]];
			return tot;
		case TERMCODE_INOUTASS:					// stat_saom_inoutass(): sum over ties of indeg(ego)*outdeg(alter)
			for (k = 0; k < g->nties; k++) tot += (double)g->din[g->elist_i[k]] * (double)g->dout[g->elist_j[k]];
			return tot;
		case TERMCODE_CYCLE4:						// stat_saom_cycle4(): 0.25 * sum over ties (i,j) of pair_cycle4_threepaths(i,j)
			for (k = 0; k < g->nties; k++) tot += (double)pair_cycle4_threepaths(g, g->elist_i[k], g->elist_j[k]);
			return tot * 0.25;
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
		case TERMCODE_ISOLATENET: {					// change_saom_isolatenet(): mechanical port, same shape as the Mata original
			double cur_isolate, new_isolate;
			if (g->din[i] != 0) return 0.0;
			cur_isolate = (g->dout[i] == 0) ? 1.0 : 0.0;
			new_isolate = ij_exists ? (((g->dout[i] - 1) == 0) ? 1.0 : 0.0) : 0.0;
			return new_isolate - cur_isolate;
		}
		case TERMCODE_OUTISO: {					// change_saom_outiso(): mechanical port, same shape as the Mata original
			double cur_isolate = (g->dout[i] == 0) ? 1.0 : 0.0;
			double new_isolate = ij_exists ? (((g->dout[i] - 1) == 0) ? 1.0 : 0.0) : 0.0;
			return new_isolate - cur_isolate;
		}
		case TERMCODE_TRANSRECTRIP: {					// change_saom_transrectrip(): mechanical port - direct per-alternative pair_otp() + neighbor loop, NOT the batch-precomputed shape transtrip/cycle3 use (see this termcode's own #define comment); a future follow-on if profiling ever shows this specific term needs the same O(n)-independent batching those two got in a later unit
			double delta = has_edge(g, j, i) ? (double)pair_otp(g, i, j) : 0.0;
			long m, h;
			for (m = 0; m < g->outadj[i].len; m++) {
				h = g->outadj[i].nb[m];
				if (h == j) continue;
				if (has_edge(g, h, i) && has_edge(g, j, h)) delta += 1.0;
			}
			return ij_exists ? -delta : delta;
		}
		case TERMCODE_TRANSMEDTRIP: {					// change_saom_transmedtrip(): mechanical port - pure pair_isp(i,j), no neighbor loop needed (unlike TRANSRECTRIP above, which combines pair_otp() with an extra loop) since this term's own real definition is exactly ISP alone
			double delta = (double)pair_isp(g, i, j);
			return ij_exists ? -delta : delta;
		}
		case TERMCODE_ANTIINISO: {					// change_saom_antiiniso(): mechanical port, same shape as TERMCODE_ANTIINISO2/OUTISO (alter-indexed, spillover-free)
			long d = g->din[j];
			int cond = ij_exists ? (d <= 1) : (d == 0);
			return cond ? (ij_exists ? -1.0 : 1.0) : 0.0;
		}
		case TERMCODE_ANTIINISO2: {					// change_saom_antiiniso2(): mechanical port
			long d = g->din[j];
			int cond = ij_exists ? (d == 2) : (d == 1);
			return cond ? (ij_exists ? -1.0 : 1.0) : 0.0;
		}
		case TERMCODE_IN3PLUS: {					// change_saom_in3plus(): mechanical port, same shape as TERMCODE_ANTIINISO2 with threshold 3 instead of 2
			long d = g->din[j];
			int cond = ij_exists ? (d == 3) : (d == 2);
			return cond ? (ij_exists ? -1.0 : 1.0) : 0.0;
		}
		case TERMCODE_GWESP: {						// change_saom_gwesp(): mechanical port - RSiena's own GenericNetworkEffect kernel-lookup shape, deliberately NOT nwergm's own full ERGM change statistic (no neighbor-adjustment loops - see this termcode's own #define comment)
			double delta = gw_kernel((double)pair_otp(g, i, j), p1);
			return ij_exists ? -delta : delta;
		}
		case TERMCODE_TRANSTIES: {					// change_saom_transties(): mechanical port - own-dyad OTP(i,j)>=1 indicator plus a neighbors_out(j) loop checking each existing i->b (b!=i) for a newly-crossed OTP(i,b)>=1 threshold; deliberately excludes nwergm's own "na" spillover-onto-other-actors loop (myopic-actor restriction, see this termcode's own #define comment)
			double delta = ij_exists ? -1.0 : 1.0;
			double chg = delta * ((pair_otp(g, i, j) >= 1) ? 1.0 : 0.0);
			long m, b;
			for (m = 0; m < g->outadj[j].len; m++) {
				b = g->outadj[j].nb[m];
				if (b == i) continue;
				if (!has_edge(g, i, b)) continue;
				long oldb = pair_otp(g, i, b);
				double newflag = ((oldb + delta) >= 1) ? 1.0 : 0.0;
				double oldflag = (oldb >= 1) ? 1.0 : 0.0;
				chg += newflag - oldflag;
			}
			return chg;
		}
		case TERMCODE_BALANCE: {					// change_saom_balance(): mechanical port - p1 carries the precomputed balanceMean constant (b0)
			double b0 = p1;
			double val = ((double)g->n - 2.0) * b0
				- (double)g->dout[j]
				+ 2.0 * (double)pair_osp(g, i, j)
				+ 2.0 * (double)pair_otp(g, i, j)
				+ (has_edge(g, j, i) ? 1.0 : 0.0)
				- 2.0 * ((double)g->dout[i] - (ij_exists ? 1.0 : 0.0));
			return ij_exists ? -val : val;
		}
		case TERMCODE_OUTOUTASS: {					// change_saom_outoutass(): mechanical port, same shape as the Mata original
			double ldegree = (double)g->dout[i];
			double alterdeg = (double)g->dout[j];
			double neighborsum = 0.0;
			long m;
			for (m = 0; m < g->outadj[i].len; m++) neighborsum += (double)g->dout[g->outadj[i].nb[m]];
			if (ij_exists) return -((neighborsum - alterdeg) + ldegree * alterdeg);
			return neighborsum + (ldegree + 1.0) * alterdeg;
		}
		case TERMCODE_ININASS: {					// change_saom_ininass(): mechanical port, same shape as the Mata original
			double egodeg = (double)g->din[i];
			double alterdeg = (double)g->din[j];
			double delta = egodeg * (ij_exists ? alterdeg : alterdeg + 1.0);
			return ij_exists ? -delta : delta;
		}
		case TERMCODE_OUTINASS: {					// change_saom_outinass(): mechanical port, same shape as outoutass but neighbor sum + alter term both use INdegree, and the creating branch adds +1 to alterdeg too (alter's own indegree rises when the tie is created) - see unw_saom.do's own header comment for why this is NOT a plain degree-substitution of outoutass
			double ldegree = (double)g->dout[i];
			double alterdeg = (double)g->din[j];
			double neighborsum = 0.0;
			long m;
			for (m = 0; m < g->outadj[i].len; m++) neighborsum += (double)g->din[g->outadj[i].nb[m]];
			if (ij_exists) return -((neighborsum - alterdeg) + ldegree * alterdeg);
			return neighborsum + (ldegree + 1.0) * (alterdeg + 1.0);
		}
		case TERMCODE_INOUTASS: {					// change_saom_inoutass(): mechanical port, same shape as ininass but with no direction-dependent alterdeg adjustment at all (see unw_saom.do's own header comment - neither factor is affected by the toggle in either direction)
			double egodeg = (double)g->din[i];
			double alterdeg = (double)g->dout[j];
			double delta = egodeg * alterdeg;
			return ij_exists ? -delta : delta;
		}
		case TERMCODE_CYCLE4: {					// change_saom_cycle4(): mechanical port of _saom_cycle4_threepaths(i,j), sign-flipped by ij_exists - UNSCALED (no *0.25), matching RSiena's own real FourCyclesEffect::calculateContribution() exactly (unlike stat_saom_cycle4()'s own *0.25 above, which matches tieStatistic()'s DIFFERENT real scale - see unw_saom.do's own header comment for the full account of this real asymmetry, caught via a real R comparison after an earlier version wrongly applied *0.25 here too)
			double delta = (double)pair_cycle4_threepaths(g, i, j);
			return ij_exists ? -delta : delta;
		}
	}
	return 0.0;
}

/* ===================================================================
   Interaction effects (TERMCODE_INTERACT2, RSiena's includeInteraction())
   - see this termcode's own #define comment for the full design account.
   saom_tie_stat() below is a literal copy of each eligible termcode's own
   tie-loop summand ALREADY in saom_stat_term() below (not re-derived),
   giving exactly RSiena's real tieStatistic(alter) value for that
   component at a SPECIFIC (ego,alter) pair - genuinely different from
   saom_change_term()'s own ij_exists=0 branch for the seven termcodes
   with ministep neighbor-spillover (transties/outoutass/ininass/
   outinass/inoutass/cycle4/balance - confirmed directly from RSiena's
   own NetworkEffect::egoStatistic()/tieStatistic() vs
   calculateContribution() split, RSiena/src/model/effects/
   NetworkEffect.cpp), identical to it for every other (spillover-free)
   termcode. Only ever called with (ego,alter) pairs that are ACTUAL
   EXISTING ties (from saom_stat_interact()'s own tie-loop below) -
   matches every tie-summed case in saom_stat_term() itself, which makes
   the same assumption (e.g. TERMCODE_BALANCE's own `dout[ego]-1`
   subtraction only makes sense for a tie that already exists).
   =================================================================== */
static double saom_tie_stat(graph_t *g, int termcode, double *a, double p1, long ego, long alter) {
	switch (termcode) {
		case TERMCODE_OUTDEGREE: return 1.0;
		case TERMCODE_RECIPROCITY: return has_edge(g, alter, ego) ? 1.0 : 0.0;
		case TERMCODE_NODEMATCH: return (a[ego] == a[alter]) ? 1.0 : 0.0;
		case TERMCODE_NODECOV: return a[ego] + a[alter];
		case TERMCODE_NODEICOV: return a[alter];
		case TERMCODE_NODEOCOV: return a[ego];
		case TERMCODE_TRANSTRIP: return (double)pair_isp(g, ego, alter);
		case TERMCODE_TRANSMEDTRIP: return (double)pair_isp(g, ego, alter);
		case TERMCODE_CYCLE3: return (double)pair_otp(g, alter, ego);
		case TERMCODE_SIMCOV: return 1.0 - fabs(a[ego] - a[alter]) / p1;
		case TERMCODE_TRANSRECTRIP: return has_edge(g, alter, ego) ? (double)pair_otp(g, ego, alter) : 0.0;
		case TERMCODE_OUTOUTASS: return (double)g->dout[ego] * (double)g->dout[alter];
		case TERMCODE_ININASS: return (double)g->din[ego] * (double)g->din[alter];
		case TERMCODE_OUTINASS: return (double)g->dout[ego] * (double)g->din[alter];
		case TERMCODE_INOUTASS: return (double)g->din[ego] * (double)g->dout[alter];
		case TERMCODE_CYCLE4: return 0.25 * (double)pair_cycle4_threepaths(g, ego, alter);
		case TERMCODE_GWESP: return gw_kernel((double)pair_otp(g, ego, alter), p1);
		case TERMCODE_TRANSTIES: return (pair_otp(g, ego, alter) >= 1) ? 1.0 : 0.0;
		case TERMCODE_BALANCE: {
			double b0 = p1;
			double nterm = (double)g->n - 2.0;
			double D = ((double)g->dout[ego] - 1.0)
				+ ((double)g->dout[alter] - (has_edge(g, alter, ego) ? 1.0 : 0.0))
				- 2.0 * (double)pair_osp(g, ego, alter);
			return nterm * b0 - D;
		}
	}
	return 0.0;		// node-level/"ego effect" termcode - rejected upstream by nwsaom.ado's own interact() eligibility check, never reached in practice
}

/* saom_stat_interact(): TERMCODE_INTERACT2's own global-statistic
   computation - sum over the network's ACTUAL EXISTING ties of the
   product of the two components' own saom_tie_stat() values, matching
   RSiena's real NetworkInteractionEffect::tieStatistic() (a product),
   summed via the same NetworkEffect::egoStatistic()/statistic() shape
   every other termcode's own saom_stat_term() case already uses. */
static double saom_stat_interact(graph_t *g, int subAcode, double *aA, double p1A, int subBcode, double *aB, double p1B) {
	long k;
	double tot = 0.0;
	for (k = 0; k < g->nties; k++) {
		long ei = g->elist_i[k], ej = g->elist_j[k];
		tot += saom_tie_stat(g, subAcode, aA, p1A, ei, ej) * saom_tie_stat(g, subBcode, aB, p1B, ei, ej);
	}
	return tot;
}

/* saom_eval_change()/saom_eval_stat(): thin dispatch wrappers inserted
   at every caller of saom_change_term()/saom_stat_term() in the ministep
   loop and full-statistic pass below, so TERMCODE_INTERACT2 (which needs
   the FULL termcodes[]/attridx[]/p1[]/attrs[] arrays to resolve its own
   two component slots - room saom_change_term()'s/saom_stat_term()'s own
   existing (termcode, a, p1) signature has no space for) can be handled
   without changing either function's signature or any of its existing,
   already-certified cases. For every ordinary (non-interaction) term
   these are a transparent passthrough - byte-identical to the inline
   code they replace. */
static double saom_eval_change(int k, int *termcodes, int *attridx, double *p1, double **attrs,
	graph_t *g, long i, long j, int ij_exists, double *tt_arr, double *c3_arr) {
	if (termcodes[k] == TERMCODE_INTERACT2) {
		int subA = attridx[k] - 1, subB = (int)p1[k] - 1;
		double *aA = (attridx[subA] > 0) ? attrs[attridx[subA] - 1] : NULL;
		double *aB = (attridx[subB] > 0) ? attrs[attridx[subB] - 1] : NULL;
		double cvA = saom_change_term(g, termcodes[subA], aA, p1[subA], i, j, ij_exists, tt_arr, c3_arr);
		double cvB = saom_change_term(g, termcodes[subB], aB, p1[subB], i, j, ij_exists, tt_arr, c3_arr);
		return cvA * cvB;
	}
	{
		double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
		return saom_change_term(g, termcodes[k], a, p1[k], i, j, ij_exists, tt_arr, c3_arr);
	}
}

static double saom_eval_stat(int k, int *termcodes, int *attridx, double *p1, double **attrs, graph_t *g) {
	if (termcodes[k] == TERMCODE_INTERACT2) {
		int subA = attridx[k] - 1, subB = (int)p1[k] - 1;
		double *aA = (attridx[subA] > 0) ? attrs[attridx[subA] - 1] : NULL;
		double *aB = (attridx[subB] > 0) ? attrs[attridx[subB] - 1] : NULL;
		return saom_stat_interact(g, termcodes[subA], aA, p1[subA], termcodes[subB], aB, p1[subB]);
	}
	{
		double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
		return saom_stat_term(g, termcodes[k], a, p1[k]);
	}
}

/* saom_mark_need_flags(): the per-termcode need_adj/need_transtrip/
   need_cycle3 eligibility rules already used by stata_call()'s own
   argument-parsing loop, factored out so an INTERACT2 term's two
   component termcodes can be checked too (see stata_call()'s own call
   site for why this now runs as a SEPARATE pass after every term's
   termcodes[]/attridx[]/p1[] are fully populated, not interleaved with
   parsing - an interaction's own component slot index can point
   anywhere in the array, including a HIGHER index than the interaction
   term's own, so its target termcode may not be parsed yet if this ran
   inline). */
static void saom_mark_need_flags(int tc, int *need_adj, int *need_transtrip, int *need_cycle3) {
	if (tc == TERMCODE_TRANSTRIP || tc == TERMCODE_CYCLE3) *need_adj = 1;
	if (tc == TERMCODE_TRANSTRIP) *need_transtrip = 1;
	if (tc == TERMCODE_CYCLE3) *need_cycle3 = 1;
	if (tc == TERMCODE_TRANSRECTRIP || tc == TERMCODE_OUTOUTASS || tc == TERMCODE_OUTINASS || tc == TERMCODE_TRANSMEDTRIP) *need_adj = 1;
	if (tc == TERMCODE_CYCLE4) *need_adj = 1;
	if (tc == TERMCODE_GWESP || tc == TERMCODE_TRANSTIES || tc == TERMCODE_BALANCE) *need_adj = 1;
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

/* saom_change_term_nn: multiplex (two-network co-evolution) change-
   statistic dispatch - ONLY difference from the ordinary single-graph
   saom_change_term() is TERMCODE_CRPROD, which needs a second graph_t
   (the OTHER co-evolving network's current state) to evaluate. Direct
   port of unw_saom.do's change_crprod(): v = other-graph's current tie
   state at (i,j); the change itself is the usual dyad-independent
   +/-v-on-toggle shape (own network's toggle direction only - the
   OTHER network's own state is read, never mutated, by this call).
   Every other termcode is delegated unchanged to saom_change_term() -
   `other' is simply unused for those, exactly mirroring how td.xnet is
   NULL/unused for every non-crprod term on the Mata side. */
static double saom_change_term_nn(graph_t *g, graph_t *other, int termcode, double p1, long i, long j, int ij_exists) {
	if (termcode == TERMCODE_CRPROD) {
		double v = has_edge(other, i, j) ? 1.0 : 0.0;
		return ij_exists ? -v : v;
	}
	return saom_change_term(g, termcode, NULL, p1, i, j, ij_exists, NULL, NULL);
}

/* saom_stat_term_nn: multiplex counterpart of saom_stat_term() - same
   CRPROD special case (direct port of stat_crprod(): sum, over G's own
   current ties, of the OTHER graph's tie state at that same dyad),
   every other termcode delegated unchanged. */
static double saom_stat_term_nn(graph_t *g, graph_t *other, int termcode, double p1) {
	if (termcode == TERMCODE_CRPROD) {
		long k;
		double tot = 0.0;
		// walks the flat edge list (always available regardless of
		// need_adj), not outadj - this minimal multiplex path never
		// allocates outadj/inadj at all, matching its own restricted
		// termcode set (OUTDEGREE/RECIPROCITY/CRPROD, none of which
		// otherwise need adjacency lists).
		for (k = 0; k < g->nties; k++) {
			if (has_edge(other, g->elist_i[k], g->elist_j[k])) tot += 1.0;
		}
		return tot;
	}
	return saom_stat_term(g, termcode, NULL, p1);
}
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
   MISSING DATA (harmonisation unit 35) - native port of unw_saom.do's
   own SaomBuildMaskedGraph()/SaomMaskedStatistic()/
   SaomMaskedBehaviorStatistic() (see those functions' own header
   comments for the full RSiena-verified design account: a dyad/actor
   missing at either endpoint wave of a period is excluded from the
   period's own target/simulated statistics, reusing every already-
   certified term's own statistic function on a masked snapshot rather
   than adding per-term masking logic). Applied ONLY to the FINAL
   statistic computation (saom_stat_term()/saom_beh_stat_term(), called
   once per simulated interval) - never to the ministep sampler itself,
   which is never restricted by missingness (an imputed dyad/actor
   participates in simulation completely normally, matching this
   package's own Mata implementation exactly - `nchanges'/
   `nchangesBeh' also stay UNMASKED here, for the same reason: this
   file's own job is to match unw_saom.do's own Mata reference bit for
   statistical bit, not to independently re-derive whether that
   reference's own convention is ideal).

   build_masked_graph(): a scratch copy of `g' with every dyad in
   `missht' forced absent - the SAME masking rule
   SaomBuildMaskedGraph() (Mata) applies, just built once here instead
   of via SaomCopyGraph()+toggle(). `need_adj' is passed through
   explicitly (matching whatever `g' itself was built with) so
   TRANSTRIP/CYCLE3/AVALT/AVSIM read a masked graph with correctly
   populated outadj/inadj too - a real, corrected bug this same
   investigation found on the Mata side first (SaomMaskedBehaviorStatistic()'s
   own header comment has the full account: a network-dependent
   behavior effect reading the RAW, unmasked graph could have an
   otherwise-fully-observed actor's own statistic corrupted via its
   real, masked alters). */
static void build_masked_graph(graph_t *g, graph_t *gm, dyadht_t *missht, int need_adj) {
	long i;

	gm->n = g->n;
	gm->need_adj = need_adj;
	ht_alloc(&gm->ht, ht_next_pow2(g->nties * 2 + 16));
	gm->elist_i = NULL; gm->elist_j = NULL; gm->ecap = 0; gm->nties = 0;
	gm->dout = (long *)calloc((size_t)(g->n + 1), sizeof(long));
	gm->din  = (long *)calloc((size_t)(g->n + 1), sizeof(long));
	gm->outadj = NULL; gm->inadj = NULL;
	if (need_adj) {
		gm->outadj = (adjlist_t *)malloc((size_t)(g->n + 1) * sizeof(adjlist_t));
		gm->inadj  = (adjlist_t *)malloc((size_t)(g->n + 1) * sizeof(adjlist_t));
		for (i = 0; i <= g->n; i++) { adj_init(&gm->outadj[i]); adj_init(&gm->inadj[i]); }
	}
	for (i = 0; i < g->nties; i++) {
		long ei = g->elist_i[i], ej = g->elist_j[i], val;
		if (ht_get(missht, dyadkey(g, ei, ej), &val)) continue;	// masked - excluded
		toggle(gm, ei, ej);
	}
}

static void free_graph(graph_t *gm) {
	ht_free(&gm->ht);
	free(gm->elist_i); free(gm->elist_j);
	free(gm->dout); free(gm->din);
	if (gm->outadj) {
		long i;
		for (i = 0; i <= gm->n; i++) free(gm->outadj[i].nb);
		free(gm->outadj);
	}
	if (gm->inadj) {
		long i;
		for (i = 0; i <= gm->n; i++) free(gm->inadj[i].nb);
		free(gm->inadj);
	}
}

/* ===================================================================
   Plugin entry point
   =================================================================== */

static char *tok_saveptr;

/* wire_parse_error: set the moment strtok(NULL, " \t") runs out of
   tokens (a wire-protocol field-count desync between a Mata caller and
   this parser - a real, recurring bug class in this project, see
   docs/SAOM_ROADMAP.md). Previously next_long()/next_double() fed a NULL
   pointer straight into atof()/strtod_l(), crashing the whole Stata
   process (confirmed via a real macOS crash report, SIGABRT inside
   strtod_l, no repro command available) instead of failing cleanly.
   Reset to 0 at the top of every stata_call() invocation (the plugin
   persists across calls within one Stata session); every field read
   AFTER the first missing one silently returns 0 rather than crashing
   again on the SAME now-exhausted strtok state, but the caller MUST
   check this flag (both call sites below do, immediately after their
   own parsing finishes and before any simulation work begins) and bail
   out via SF_error()+return(198) - matching this file's own established
   "never silently wrong, always error loudly" convention for every
   other bounds check (MAXTERMS/MAXATTR/MAXBEHTERMS) - rather than ever
   returning a result computed from partially-missing input. */
static int wire_parse_error;

static long next_long(void) {
	char *tok = strtok(NULL, " \t");
	if (!tok) { wire_parse_error = 1; return 0; }
	return (long)atof(tok);
}
static double next_double(void) {
	char *tok = strtok(NULL, " \t");
	if (!tok) { wire_parse_error = 1; return 0.0; }
	return atof(tok);
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
	// --- missing data (harmonisation unit 35) - see this file's own
	// "MISSING DATA" header section below for the full account. ALL
	// trailing, after `targetChange` - every existing caller simply
	// appends " 0 0" (hasmiss=0, nmissdyads=0), matching this file's
	// own established "known-length trailer, not a variable-position
	// insert" convention.
	long hasmiss, nmissdyads;
	long *missdi = NULL, *missdj = NULL;
	double *missbeh = NULL;
	dyadht_t missht;
	graph_t gm;
	int have_gm = 0;
	// --- composition change (harmonisation unit 33, native port) - see
	// this file's own "COMPOSITION CHANGE" header section below for the
	// full account. ONE trailing field, after `nmissdyads` - every
	// existing caller simply appends " 0" (haspresentNet=0).
	long haspresentNet, npresent;
	double *presentArr = NULL;
	long *presentIdxArr = NULL;
	// symtype (harmonisation, undirected/symmetric relations, native-first
	// per direct instruction): 0 = ordinary directed ministep (unchanged
	// default - every existing caller appends " 0"), 1 = BJOINT (RSiena's
	// own mutual-consent symmetric model type, real NetworkModelType
	// enum). ONE trailing field, after `haspresentNet`.
	long symtype;
	// ratecov (covariate-dependent rate, native-first per direct
	// instruction): a per-actor opportunity-rate reweighting, direct C
	// port of unw_saom.do's SaomSimIntCountedRateCov()/
	// SaomSimIntScoredRateCov() - actor selection becomes proportional to
	// wfull_rc[i]=exp(ratecoef*ratecovattr[i]) instead of uniform, and
	// (when want_score) an extra martingale score `rcscore` accumulates
	// (compensator term `-dt*covrateSum_rc` on every elapsed-time step,
	// jump term `+ratecovattr[actor]` whenever an actor is actually
	// selected) - verified directly from RSiena's own real
	// DependentVariable.cpp (accumulateRateScores()/
	// calculateScoreSumTerms()), matching the Mata reference exactly (see
	// that function's own header comment for the real bug found deriving
	// it: the compensator needs the FULL combined rate `rate*wfull[i]`,
	// not the covariate factor alone). v1 scope, enforced at the
	// Stata/Mata layer before this is ever reached: never combined with
	// composition change/missing data/behavior co-evolution/symtype - so
	// only the ordinary single-network ministep branch below needs this
	// reweighting, not the BJOINT or behavior branches. TWO trailing
	// fields, after `symtype` - the LAST fields in the wire protocol as
	// of this addition.
	long hasratecov;
	double *ratecovattr = NULL;
	double ratecoef = 0.0;
	double *wfull_rc = NULL;
	double totw_rc = 0.0, covrateSum_rc = 0.0;
	double rcscore = 0.0;
	(void)tok_saveptr;

	wire_parse_error = 0;
	if (argc < 1) { SF_error("saom_sim: missing argument string\n"); return(198); }

	// --- multiplex (two-network co-evolution), native-first per direct
	// instruction: dispatched purely on argc (every existing single-
	// graph call always passes argc==1, via one combined argv[0] string
	// - this needs THREE separate strings, so argc>=3 can never collide
	// with any existing call site; no existing wire-protocol field was
	// touched at all). Direct C port of unw_saom.do's
	// SaomSimulateIntervalCoevNetNet() - the same rate-weighted race
	// between two networks' own total opportunity rates, then the same
	// per-ministep multinomial-logit choice already used by the
	// ordinary single-graph path below, just run against TWO independent
	// graph_t instances instead of one. v1 scope, matching this
	// benchmark's own actual motivating case (docs/SAOM_ROADMAP.md's
	// multiplex entry): exactly two waves, no attributes, no missing
	// data, no composition change, no behavior co-evolution, restricted
	// to OUTDEGREE/RECIPROCITY/CRPROD (exactly what this feature is
	// certified with) - an unsupported termcode is rejected outright
	// below, never silently mishandled. Phase 1's own smaller-replicate
	// Jacobian estimate (which also needs a `score' vector this path
	// does not compute) stays on the existing Mata
	// SaomSimulateIntervalCoevNetNet() - phase 2's much larger replicate
	// budget is where the measured 42x gap actually lives, the same
	// "phase 2 dominates" pattern every other native port in this file
	// already established.
	// Dispatch on a sentinel prefix, not argc, now that the multiplex
	// call passes ONE combined string (see below) instead of three
	// separate ones - both paths pass argc==1 now, so content, not
	// argument count, is what distinguishes them.
	if (argc == 1 && strncmp(argv[0], "NNMULTIPLEX|", 12) == 0) {
		char *nnfull, *blk0, *blk1, *blk2, *nnbuf0, *nnbuf1;
		long n1v, nties1v, nterms1v, n2v, nties2v, nterms2v;
		int tc1[MAXTERMS], tc2[MAXTERMS];
		double pp1[MAXTERMS], pp2[MAXTERMS], th1[MAXTERMS], th2[MAXTERMS];
		double rate1v, rate2v, seedv;
		graph_t g1, g2;
		rng_t rngnn;
		long ii, kk;
		double tnn, stepsnn, nch1, nch2;

		// Split the ONE combined string into its 3 logical blocks first
		// (a separate strtok pass on "|", run to completion before the
		// per-block " \t" tokenizing pass below ever starts, so the two
		// different delimiter passes never interleave on the same
		// global strtok state) - everything from here on is the
		// UNCHANGED per-block parse the original three-separate-string
		// version already used, just fed from blk0/blk1/blk2 instead of
		// argv[0]/argv[1]/argv[2] directly.
		nnfull = (char *)malloc(strlen(argv[0] + 12) + 1);
		strcpy(nnfull, argv[0] + 12);
		blk0 = strtok(nnfull, "|");
		blk1 = strtok(NULL, "|");
		blk2 = strtok(NULL, "|");
		if (!blk0 || !blk1 || !blk2) {
			SF_error("saom_sim: multiplex combined argument string malformed\n");
			free(nnfull);
			return(198);
		}

		nnbuf0 = (char *)malloc(strlen(blk0) + 1);
		strcpy(nnbuf0, blk0);
		nnbuf1 = (char *)malloc(strlen(blk1) + 1);
		strcpy(nnbuf1, blk1);
		seedv = atof(blk2);
		free(nnfull);

		{
			char *tok0 = strtok(nnbuf0, " \t");
			if (!tok0) { free(nnbuf0); SF_error("saom_sim: multiplex net1 argument string empty\n"); return(198); }
			n1v = (long)atof(tok0);
		}
		nties1v = next_long();
		nterms1v = next_long();
		if (nterms1v > MAXTERMS) { SF_error("saom_sim: multiplex net1 too many terms\n"); free(nnbuf0); return(198); }
		for (kk = 0; kk < nterms1v; kk++) {
			tc1[kk] = (int)next_long();
			pp1[kk] = next_double();
			th1[kk] = next_double();
		}
		rate1v = next_double();
		free(nnbuf0);

		{
			char *tok0 = strtok(nnbuf1, " \t");
			if (!tok0) { free(nnbuf1); SF_error("saom_sim: multiplex net2 argument string empty\n"); return(198); }
			n2v = (long)atof(tok0);
		}
		nties2v = next_long();
		nterms2v = next_long();
		if (nterms2v > MAXTERMS) { SF_error("saom_sim: multiplex net2 too many terms\n"); free(nnbuf1); return(198); }
		for (kk = 0; kk < nterms2v; kk++) {
			tc2[kk] = (int)next_long();
			pp2[kk] = next_double();
			th2[kk] = next_double();
		}
		rate2v = next_double();
		free(nnbuf1);

		if (wire_parse_error) { SF_error("saom_sim: multiplex wire-protocol argument string ran out of fields (a Mata/native field-count mismatch) - refusing to simulate on partially-parsed input\n"); return(198); }
		if (n1v != n2v) { SF_error("saom_sim: multiplex requires both networks on the same actor set (n1 != n2)\n"); return(198); }
		for (kk = 0; kk < nterms1v; kk++) {
			if (tc1[kk] != TERMCODE_OUTDEGREE && tc1[kk] != TERMCODE_RECIPROCITY && tc1[kk] != TERMCODE_CRPROD) {
				SF_error("saom_sim: multiplex native path only supports outdegree/reciprocity/crprod (net1)\n"); return(198);
			}
		}
		for (kk = 0; kk < nterms2v; kk++) {
			if (tc2[kk] != TERMCODE_OUTDEGREE && tc2[kk] != TERMCODE_RECIPROCITY && tc2[kk] != TERMCODE_CRPROD) {
				SF_error("saom_sim: multiplex native path only supports outdegree/reciprocity/crprod (net2)\n"); return(198);
			}
		}

		g1.n = n1v; g1.need_adj = 0;
		ht_alloc(&g1.ht, ht_next_pow2(nties1v * 2 + 16));
		g1.elist_i = NULL; g1.elist_j = NULL; g1.ecap = 0; g1.nties = 0;
		g1.dout = (long *)calloc((size_t)(n1v + 1), sizeof(long));
		g1.din  = (long *)calloc((size_t)(n1v + 1), sizeof(long));
		g1.outadj = NULL; g1.inadj = NULL;
		for (ii = 1; ii <= nties1v; ii++) {
			ST_double vi, vj;
			SF_vdata(1, ii, &vi);
			SF_vdata(2, ii, &vj);
			toggle(&g1, (long)vi, (long)vj);
		}

		g2.n = n2v; g2.need_adj = 0;
		ht_alloc(&g2.ht, ht_next_pow2(nties2v * 2 + 16));
		g2.elist_i = NULL; g2.elist_j = NULL; g2.ecap = 0; g2.nties = 0;
		g2.dout = (long *)calloc((size_t)(n2v + 1), sizeof(long));
		g2.din  = (long *)calloc((size_t)(n2v + 1), sizeof(long));
		g2.outadj = NULL; g2.inadj = NULL;
		for (ii = 1; ii <= nties2v; ii++) {
			ST_double vi, vj;
			SF_vdata(3, ii, &vi);
			SF_vdata(4, ii, &vj);
			toggle(&g2, (long)vi, (long)vj);
		}

		rng_seed(&rngnn, (unsigned long long)seedv);
		tnn = 0.0; stepsnn = 0.0; nch1 = 0.0; nch2 = 0.0;
		{
			long n = n1v;
			double totalRate1 = (double)n * rate1v;
			double totalRate2 = (double)n * rate2v;
			double grandRate = totalRate1 + totalRate2;
			double *u = (double *)malloc((size_t)(n + 1) * sizeof(double));
			// score1/score2 (harmonisation follow-up, phase-1/3 native
			// extension): the SAME "chosen - E_p[change]" score-function
			// identity the single-graph native path already uses for its
			// own ordinary multinomial ministep (native/saom_sim.c's own
			// `score[k] += chosen_k - ebar_k` above) - phase 1/3's own
			// Jacobian/t-ratio machinery needs a REAL score here, not the
			// all-zero stub SaomSimIntCoevNNNative() previously returned,
			// which is exactly why those two phases stayed on the slow
			// Mata path (confirmed by direct profiling: phase1+phase3
			// were ~93% of total wall time on the 50-actor benchmark).
			// chgstore uses a fixed MAXTERMS stride (not nterms_v, which
			// differs by which network is acting on a given ministep) so
			// one buffer safely serves both networks' own term lists.
			double score1[MAXTERMS], score2[MAXTERMS];
			double *chgstore = (double *)malloc((size_t)(n + 1) * (size_t)MAXTERMS * sizeof(double));
			for (kk = 0; kk < MAXTERMS; kk++) { score1[kk] = 0.0; score2[kk] = 0.0; }

			while (tnn < 1.0) {
				tnn -= log(rng_unif(&rngnn)) / grandRate;
				if (tnn < 1.0) {
					double draw = rng_unif(&rngnn) * grandRate;
					int onNet1 = (draw <= totalRate1);
					graph_t *gme = onNet1 ? &g1 : &g2;
					graph_t *gother = onNet1 ? &g2 : &g1;
					int *tc = onNet1 ? tc1 : tc2;
					double *pp = onNet1 ? pp1 : pp2;
					double *th = onNet1 ? th1 : th2;
					long nterms_v = onNet1 ? nterms1v : nterms2v;
					long i = 1 + (long)(rng_unif(&rngnn) * (double)n);
					long j, choice;
					double maxu = 0.0, denom, draw2, cum;

					for (j = 1; j <= n; j++) {
						if (j == i) { u[j] = 0.0; continue; }
						{
							int ij_exists = has_edge(gme, i, j);
							double uj = 0.0;
							for (kk = 0; kk < nterms_v; kk++) {
								double cv = saom_change_term_nn(gme, gother, tc[kk], pp[kk], i, j, ij_exists);
								chgstore[j * MAXTERMS + kk] = cv;
								uj += th[kk] * cv;
							}
							u[j] = uj;
							if (uj > maxu) maxu = uj;
						}
					}
					denom = exp(0.0 - maxu);
					for (j = 1; j <= n; j++) { if (j != i) denom += exp(u[j] - maxu); }
					draw2 = rng_unif(&rngnn) * denom;
					cum = exp(0.0 - maxu);
					choice = 0;
					if (draw2 > cum) {
						for (j = 1; j <= n; j++) {
							if (j == i) continue;
							cum += exp(u[j] - maxu);
							choice = j;
							if (draw2 <= cum) break;
						}
					}
					{
						double *sc = onNet1 ? score1 : score2;
						for (kk = 0; kk < nterms_v; kk++) {
							double ebar_k = 0.0, chosen_k;
							for (j = 1; j <= n; j++) {
								if (j == i) continue;
								ebar_k += (exp(u[j] - maxu) / denom) * chgstore[j * MAXTERMS + kk];
							}
							chosen_k = (choice != 0) ? chgstore[choice * MAXTERMS + kk] : 0.0;
							sc[kk] += chosen_k - ebar_k;
						}
					}
					if (choice != 0) {
						toggle(gme, i, choice);
						if (onNet1) nch1 += 1.0; else nch2 += 1.0;
					}
				}
				stepsnn += 1.0;
			}
			for (kk = 0; kk < nterms1v; kk++) { char sn[48]; sprintf(sn, "__saom_native_nn_score1_%ld", kk + 1); SF_scal_save(sn, score1[kk]); }
			for (kk = 0; kk < nterms2v; kk++) { char sn[48]; sprintf(sn, "__saom_native_nn_score2_%ld", kk + 1); SF_scal_save(sn, score2[kk]); }
			free(chgstore);
			free(u);
		}

		for (ii = 0; ii < g1.nties; ii++) { SF_vstore(1, ii + 1, (ST_double)g1.elist_i[ii]); SF_vstore(2, ii + 1, (ST_double)g1.elist_j[ii]); }
		for (ii = 0; ii < g2.nties; ii++) { SF_vstore(3, ii + 1, (ST_double)g2.elist_i[ii]); SF_vstore(4, ii + 1, (ST_double)g2.elist_j[ii]); }
		SF_scal_save("__saom_native_nn_nties1", (ST_double)g1.nties);
		SF_scal_save("__saom_native_nn_nties2", (ST_double)g2.nties);
		SF_scal_save("__saom_native_nn_nch1", (ST_double)nch1);
		SF_scal_save("__saom_native_nn_nch2", (ST_double)nch2);
		SF_scal_save("__saom_native_nn_steps", (ST_double)stepsnn);
		for (kk = 0; kk < nterms1v; kk++) {
			char statname[48];
			sprintf(statname, "__saom_native_nn_stat1_%ld", kk + 1);
			SF_scal_save(statname, saom_stat_term_nn(&g1, &g2, tc1[kk], pp1[kk]));
		}
		for (kk = 0; kk < nterms2v; kk++) {
			char statname[48];
			sprintf(statname, "__saom_native_nn_stat2_%ld", kk + 1);
			SF_scal_save(statname, saom_stat_term_nn(&g2, &g1, tc2[kk], pp2[kk]));
		}

		ht_free(&g1.ht); free(g1.elist_i); free(g1.elist_j); free(g1.dout); free(g1.din);
		ht_free(&g2.ht); free(g2.elist_i); free(g2.elist_j); free(g2.dout); free(g2.din);
		return(0);
	}

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	{
		char *tok0 = strtok(argbuf, " \t");
		if (!tok0) { free(argbuf); SF_error("saom_sim: empty argument string\n"); return(198); }
		n = (long)atof(tok0);
	}
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
	}
	// need_adj/need_transtrip/need_cycle3: a SEPARATE pass, now that every
	// term's termcodes[]/attridx[]/p1[] are fully populated (see
	// saom_mark_need_flags()'s own header comment for why an
	// INTERACT2 term's own component slot cannot be resolved reliably
	// inline during parsing). transrectrip/outoutass/outinass/
	// transmedtrip all walk outadj[i] directly (no batch precompute like
	// transtrip/cycle3 get - see saom_change_term()'s own case comments
	// for why a direct per-alternative port was chosen here); ininass/
	// inoutass/antiiniso/antiiniso2 only ever touch din[]/dout[] scalars
	// (confirmed from real RSiena source), so need no adjacency lists at
	// all. cycle4 needs BOTH outadj and inadj (pair_cycle4_threepaths()).
	// gwesp/transties/balance all call pair_otp()/pair_osp(), both of
	// which read outadj/inadj.
	for (i = 0; i < nterms; i++) {
		if (termcodes[i] == TERMCODE_INTERACT2) {
			int subA = attridx[i] - 1, subB = (int)p1[i] - 1;
			saom_mark_need_flags((subA >= 0 && subA < nterms) ? termcodes[subA] : -1, &need_adj, &need_transtrip, &need_cycle3);
			saom_mark_need_flags((subB >= 0 && subB < nterms) ? termcodes[subB] : -1, &need_adj, &need_transtrip, &need_cycle3);
		} else {
			saom_mark_need_flags(termcodes[i], &need_adj, &need_transtrip, &need_cycle3);
		}
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
	hasmiss = next_long();
	nmissdyads = next_long();
	haspresentNet = next_long();
	symtype = next_long();
	hasratecov = next_long();
	if (hasratecov) {
		ratecovattr = (double *)malloc((size_t)n * sizeof(double));
		for (i = 0; i < n; i++) ratecovattr[i] = next_double();
		ratecoef = next_double();
	}
	free(argbuf);

	if (wire_parse_error) { SF_error("saom_sim: wire-protocol argument string ran out of fields (a Mata/native field-count mismatch) - refusing to simulate on partially-parsed input\n"); return(198); }
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

	// --- missing data (harmonisation unit 35): the missing-dyad list
	// (mv1/mv2, rows 1..nmissdyads) and the behavior-missingness column
	// (missbeh, rows 1..n, 0/1) live at FIXED columns right after
	// everything else - `basecol' below matches exactly what
	// SaomSimulateIntervalNative()/SaomSimulateIntervalCoevNative()
	// (unw_saom.do) add to the frame, in the same order, only when
	// `hasmiss' is true (see this file's own "MISSING DATA" header
	// section for the full account). Both columns are ALWAYS present
	// together whenever hasmiss=1, even if only one of missnet()/
	// missbeh() is actually active for this fit (the unused one is
	// simply all-zero) - avoids a second layer of conditional column
	// positioning.
	if (hasmiss) {
		long basecol = 3 + nattr + (nbehterms > 0 ? 1 : 0);
		missdi = (long *)malloc((size_t)(nmissdyads > 0 ? nmissdyads : 1) * sizeof(long));
		missdj = (long *)malloc((size_t)(nmissdyads > 0 ? nmissdyads : 1) * sizeof(long));
		for (i = 0; i < nmissdyads; i++) {
			ST_double vi, vj;
			SF_vdata((int)basecol, i + 1, &vi);
			SF_vdata((int)(basecol + 1), i + 1, &vj);
			missdi[i] = (long)vi;
			missdj[i] = (long)vj;
		}
		missbeh = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(basecol + 2), i, &v);
			missbeh[i] = v;
		}
		// hash the missing-dyad set once for O(1) membership tests
		// building the masked graph below (dyadkey() only reads g.n,
		// shared/unaffected by which hashtable it indexes into, exactly
		// like `horig' above already relies on).
		ht_alloc(&missht, ht_next_pow2(nmissdyads * 2 + 16));
		for (i = 0; i < nmissdyads; i++) ht_put(&missht, dyadkey(&g, missdi[i], missdj[i]), 1);
	}

	// --- composition change (harmonisation unit 33, native port): the
	// `present' column (rows 1..n, 0/1) lives at a FIXED column right
	// after the missing-data columns (if any) - see this file's own
	// "COMPOSITION CHANGE" header section for the full account.
	// `presentIdxArr' (compact list of present actor indices, size
	// npresent) lets the ministep loop below draw the acting actor
	// uniformly from the present set in O(1), matching
	// SaomSimulateInterval()'s own `presentIdx' (unw_saom.do) exactly.
	npresent = n;
	if (haspresentNet) {
		long presentcol = 3 + nattr + (nbehterms > 0 ? 1 : 0) + (hasmiss ? 3 : 0);
		presentArr = (double *)malloc((size_t)(n + 1) * sizeof(double));
		presentIdxArr = (long *)malloc((size_t)n * sizeof(long));
		npresent = 0;
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)presentcol, i, &v);
			presentArr[i] = v;
			if (v != 0.0) presentIdxArr[npresent++] = i;
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
		// harmonisation unit 33 (composition change, native port):
		// `npresent' replaces `n' here when haspresentNet (absent actors
		// get no activation opportunities at all - see this file's own
		// "COMPOSITION CHANGE" header section).
		// ratecov: precompute the per-actor rate weight ONCE per interval
		// (exp() is not free, and neither ratecoef nor ratecovattr change
		// across ministeps within one simulated interval) - direct port of
		// SaomSimIntCountedRateCov()/SaomSimIntScoredRateCov()'s own
		// identical `wfull'/`covrateSum' precompute.
		if (hasratecov) {
			wfull_rc = (double *)malloc((size_t)n * sizeof(double));
			for (i = 0; i < n; i++) {
				wfull_rc[i] = exp(ratecoef * ratecovattr[i]);
				totw_rc += wfull_rc[i];
				covrateSum_rc += ratecovattr[i] * wfull_rc[i];
			}
			covrateSum_rc *= rate;
		}
		double grandRate = hasratecov ? (rate * totw_rc) : ((double)npresent * rate + (double)npresent * rateBeh);
		nchangesBeh = 0.0;
		while (condmode ? (simDist < targetChange) : (t < 1.0)) {
			double dt_rc = -log(rng_unif(&rng)) / grandRate;
			t += dt_rc;
			if (hasratecov && want_score && (condmode || t < 1.0)) rcscore -= dt_rc * covrateSum_rc;
			if (condmode || t < 1.0) {
				int actNet = (nbehterms == 0) || (rng_unif(&rng) * grandRate <= (double)npresent * rate);
				if (actNet && (symtype == 1 || symtype == 2 || symtype == 3)) {
					// BJOINT/BFORCE/BAGREE (RSiena's own real B-family
					// symmetric model types, NetworkModelType enum,
					// source-verified from NetworkVariable.cpp's own
					// "Section: symmetric networks methods" -
					// calculateModelTypeBProbabilities(), the exact
					// switch/case read directly from the cached RSiena
					// source, not derived): structurally a DIFFERENT
					// ministep shape from the ordinary
					// multinomial-choice-over-all-alternatives block
					// below, not a reweighting of it - actor is chosen
					// exactly as usual, but alter is drawn UNIFORMLY
					// (RSiena's own B-family draws alter rate-weighted
					// among "permitted" actors; rates are actor-uniform
					// in this v1 port, so a uniform draw over the
					// remaining actors is exactly equivalent), then BOTH
					// sides' own utility for the SAME candidate toggle
					// are evaluated - the three model types differ ONLY
					// in how the two sides' utilities combine into one
					// acceptance probability (source's own
					// `calculateModelTypeBProbabilities()` switch,
					// ported verbatim below, not reworked):
					//   BJOINT  (symtype=1): prob = logistic(u_actor + u_alter)
					//     - sums BOTH raw utilities first, one logistic.
					//   BFORCE  (symtype=2): prob = logistic(u_actor)
					//     - ONLY the initiating actor's own utility
					//     drives the decision; alter's own utility is
					//     evaluated (for scoring, not implemented here
					//     either, matching BJOINT's own disclosed score
					//     gap below) but never enters the acceptance
					//     probability itself - ego can unilaterally
					//     "force" the change.
					//   BAGREE  (symtype=3): pEgo = logistic(u_actor),
					//     pAlt = logistic(-u_alter) (note the SIGN FLIP
					//     on alter's own contribution - confirmed
					//     directly from source, not a typo: RSiena's own
					//     `1.0/(1.0+exp(+lsymmetricProbabilities[1]))`,
					//     which equals logistic(-x), unlike ego's own
					//     `1.0/(1.0+exp(-lsymmetricProbabilities[0]))` a
					//     few lines above it in the same function); then
					//     prob = pEgo*pAlt when creating a new tie (BOTH
					//     must independently "agree" - hence AGREE), or
					//     prob = pEgo + pAlt - pEgo*pAlt when removing an
					//     existing one (an inclusion-exclusion "OR" -
					//     either side wanting to break it is enough).
					// giving one Bernoulli accept/reject for the pair. An
					// accepted change writes BOTH directed cells so the
					// stored (still directed-storage) graph stays
					// symmetric throughout - matching v1's own hard
					// `if (!directed)` requirement above, which this
					// mode does not relax.
					//
					// v1 restriction, enforced at the Stata/Mata layer
					// (nwsaom.ado rejects the combination before ever
					// reaching here): transtrip/cycle3 are not usable
					// under any symtype>=1, since their own per-ministep
					// batch precompute (tt_arr/c3_arr below) is
					// actor-centric in a way this two-sided ministep does
					// not populate for EITHER side - a future unit could
					// extend this, not attempted here (time-boxed).
					long actor = haspresentNet ? presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)] : 1 + (long)(rng_unif(&rng) * (double)n);
					long alter;
					if (haspresentNet) {
						do { alter = presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)]; } while (alter == actor);
					} else {
						do { alter = 1 + (long)(rng_unif(&rng) * (double)n); } while (alter == actor);
					}

					int ij_exists = has_edge(&g, actor, alter);
					double u_actor = 0.0, u_alter = 0.0;
					double *chg_actor = want_score ? (double *)malloc((size_t)nterms * sizeof(double)) : NULL;
					for (k = 0; k < nterms; k++) {
						double cv_actor = saom_eval_change(k, termcodes, attridx, p1, attrs, &g, actor, alter, ij_exists, NULL, NULL);
						double cv_alter = saom_eval_change(k, termcodes, attridx, p1, attrs, &g, alter, actor, ij_exists, NULL, NULL);
						u_actor += theta[k] * cv_actor;
						u_alter += theta[k] * cv_alter;
						if (want_score) chg_actor[k] = cv_actor;
					}
					double prob;
					if (symtype == 2) {
						/* BFORCE */
						prob = stable_logistic(u_actor);
					} else if (symtype == 3) {
						/* BAGREE */
						double pEgo = stable_logistic(u_actor);
						double pAlt = stable_logistic(-u_alter);
						prob = ij_exists ? (pEgo + pAlt - pEgo * pAlt) : (pEgo * pAlt);
					} else {
						/* BJOINT */
						prob = stable_logistic(u_actor + u_alter);
					}
#ifdef SAOM_DEBUG_SYMTYPE
					fprintf(stderr, "SYMDEBUG symtype=%ld actor=%ld alter=%ld ij=%d u_actor=%.10f u_alter=%.10f prob=%.10f\n", symtype, actor, alter, ij_exists, u_actor, u_alter, prob);
#endif
					int accepted = (rng_unif(&rng) < prob);
					if (want_score) {
						// Best-effort Bernoulli score analogue (observed
						// outcome minus its expectation under `prob`) for
						// this two-outcome (accept/reject) choice, the same
						// functional shape phase 1's own "chosen - E_p[chg]"
						// identity already uses for the ordinary
						// multinomial ministep below, specialized to one
						// binary alternative instead of n - NOT verified
						// against RSiena's own real
						// accumulateSymmetricModelScores() source (out of
						// scope for this time-boxed unit); disclosed in
						// docs/SAOM_ROADMAP.md as a reasonable but
						// source-unverified extension, not a certified port.
						for (k = 0; k < nterms; k++) {
							double chosen_k = accepted ? chg_actor[k] : 0.0;
							score[k] += chosen_k - prob * chg_actor[k];
						}
					}
					if (chg_actor) free(chg_actor);
					if (accepted) {
						toggle(&g, actor, alter);
						toggle(&g, alter, actor);
						nchanges += 1.0;
					}
				}
				else if (actNet) {
					long actor;
					if (hasratecov) {
						// weighted actor draw proportional to wfull_rc[i] -
						// direct port of SaomSimIntCountedRateCov()/
						// SaomSimIntScoredRateCov()'s own identical
						// cumulative-weight walk.
						double drawA = rng_unif(&rng) * totw_rc, cumA = 0.0;
						long ii;
						actor = n;
						for (ii = 0; ii < n; ii++) {
							cumA += wfull_rc[ii];
							if (drawA <= cumA) { actor = ii + 1; break; }
						}
						if (want_score) rcscore += ratecovattr[actor - 1];
					} else {
						actor = haspresentNet ? presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)] : 1 + (long)(rng_unif(&rng) * (double)n);
					}
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
						if (haspresentNet && presentArr[j] == 0.0) continue;	// harmonisation unit 33 (native port) - absent actor never offered as a tie-target
						int ij_exists = has_edge(&g, actor, j);
						double uj = 0.0;
						for (k = 0; k < nterms; k++) {
							double cv = saom_eval_change(k, termcodes, attridx, p1, attrs, &g, actor, j, ij_exists, tt_arr, c3_arr);
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
						if (haspresentNet && presentArr[j] == 0.0) continue;
						ev[j] = exp(u[j] - maxu);
						denom += ev[j];
					}

					draw = rng_unif(&rng) * denom;
					cum = stayterm;
					choice = 0;
					if (draw > cum) {
						for (j = 1; j <= n; j++) {
							if (j == actor) continue;
							if (haspresentNet && presentArr[j] == 0.0) continue;
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
								if (haspresentNet && presentArr[j] == 0.0) continue;
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
					long actor = haspresentNet ? presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)] : 1 + (long)(rng_unif(&rng) * (double)n);
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
	SF_scal_save("__saom_native_rcscore", (ST_double)rcscore);		// ratecov - only meaningful when hasratecov && want_score, always saved (uniform wire contract)
	if (wfull_rc) free(wfull_rc);
	if (ratecovattr) free(ratecovattr);
	if (condmode) ht_free(&horig);

	// --- missing data (harmonisation unit 35): build the masked graph
	// ONCE here (cheap - once per simulated interval, not per ministep,
	// same cost class as saom_stat_term() itself), reused for BOTH the
	// network statistic loop below and the behavior statistic loop
	// further down - see build_masked_graph()'s own header comment.
	if (hasmiss) {
		build_masked_graph(&g, &gm, &missht, g.need_adj);
		have_gm = 1;
	}
	for (k = 0; k < nterms; k++) {
		char statname[40];
		sprintf(statname, "__saom_native_stat%ld", k + 1);
		SF_scal_save(statname, saom_eval_stat(k, termcodes, attridx, p1, attrs, have_gm ? &gm : &g));
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
		// harmonisation unit 35: masked actors' own values are
		// substituted with behOverallMean for THIS computation only
		// (behval itself, written back above, stays the real simulated
		// value) - the same overallMean-substitution rule
		// SaomMaskedBehaviorStatistic() (Mata) applies, using the SAME
		// masked graph `gm' built above so avAlt/avSim read masked
		// alters too.
		{
			double *behval_use = behval;
			double *behval_masked = NULL;
			if (hasmiss) {
				behval_masked = (double *)malloc((size_t)(n + 1) * sizeof(double));
				for (i = 1; i <= n; i++) behval_masked[i] = (missbeh[i] != 0.0) ? behOverallMean : behval[i];
				behval_use = behval_masked;
			}
			for (k = 0; k < nbehterms; k++) {
				char statname[40];
				sprintf(statname, "__saom_native_statbeh%ld", k + 1);
				SF_scal_save(statname, saom_beh_stat_term(have_gm ? &gm : &g, behval_use, behtermcodes[k], behrange, behSimMean));
			}
			free(behval_masked);
		}
	}
	free(behval);
	if (have_gm) free_graph(&gm);
	if (hasmiss) {
		ht_free(&missht);
		free(missdi); free(missdj); free(missbeh);
	}
	free(presentArr); free(presentIdxArr);

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
