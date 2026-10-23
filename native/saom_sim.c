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

#define MAXTERMS 256
#define MAXATTR 1024		/* one dyadic covariate takes n attribute columns (protocol 15) */
#define MAXRC 16		/* ratecov() covariates */
#define MAXBEHTERMS 64
#define MAXBEH 8			/* protocol 19: co-evolving behavior variables */

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
/* TERMCODE_BEHSIM (2026-09-30): network-side similarity on the CO-EVOLVING
   behavior (RSiena's simX with the dependent behavior as interaction1,
   unw_saom.do's change_saom_behsim()). Change contribution for i->j:
   1 - |z_i - z_j|/behrange - p1, where p1 carries the similarity mean and
   z is the CURRENT simulated behavior. stata_call() points the term's
   attribute slot at `behval' during simulation and at the period's
   STARTING behavior for the final statistic (RSiena's lagged
   cross-statistic). Only valid when nbehterms > 0. */
#define TERMCODE_BEHSIM 31
#define TERMCODE_ANTIISO 32					// protocol 9: direct port of change_saom_antiiso() (#{i : indegree>=1, outdegree 0}, alter-indexed)
#define TERMCODE_ISOLATEPOP 33
#define TERMCODE_INTERACT3 34					// protocol 11: three-way interaction, components attridx (A) and p1 = B + 1000*C (1-based slots); change = product of the three signed changes (a withdrawal: (-)(-)(-) = minus the product of the creation contributions, RSiena's sign)					// protocol 9: direct port of change_saom_isolatepop() (#{i : indegree==1, outdegree 0}, alter-indexed)
/* protocol 13: covariate effects with MISSING covariate values (RSiena: ministep uses the
   imputed value, the statistic skips ties whose relevant actor is missing - see unw_saom.do,
   stat_saom_*_m). 35..39 = masked nodematch / nodecov / nodeicov / nodeocov / simcov. The
   change statistic is the unmasked term's (same attribute column, same p1); the 0/1 missing
   mask (1 = missing) is the NEXT attribute slot, used only by saom_eval_stat(). */
#define TERMCODE_NODEMATCH_M 35
#define TERMCODE_NODECOV_M 36
#define TERMCODE_NODEICOV_M 37
#define TERMCODE_NODEOCOV_M 38
#define TERMCODE_SIMCOV_M 39
/* protocol 15: dyadic covariates (RSiena X / XRecip). The n x n matrix of centred values (missing dyads and
   the diagonal = 0) arrives as n consecutive attribute columns, column i = row i of the matrix, so
   value(i,j) = attrs[attridx - 1 + (i - 1)][j]. X: ministep contribution = value(i,j); XRecip: value(i,j) only if
   the reverse tie j -> i exists; the statistic is the sum over the existing ties (of the same quantity). */
/* protocol 16: RSiena absDiffX = |x_j - x_i| and egoXaltX = x_i * x_j (centred covariate values; variables without
   missing values only - RSiena skips pairs with a missing value in the statistic) */
#define TERMCODE_ABSDIFFX 42
#define TERMCODE_EGOXALTX 43
/* protocol 23: RSiena diffX, higher, egoSqX, altSqX, sameXRecip, simRecipX (centred covariate values; recip: times x_ji) */
#define TERMCODE_DIFFX 48
#define TERMCODE_HIGHER 49
#define TERMCODE_EGOSQX 50
#define TERMCODE_ALTSQX 51
#define TERMCODE_SAMEXRECIP 52
#define TERMCODE_SIMRECIPX 53
#define TERMCODE_INPOP 44			/* protocol 22: RSiena inPop: sum_j indeg_j^2 */
#define TERMCODE_OUTPOPL 45			/* outPop: sum_j outdeg_j * indeg_j */
#define TERMCODE_INACTL 46			/* inAct: sum_i outdeg_i * indeg_i (actor form: indeg of ego) */
#define TERMCODE_OUTACTSQRT 47		/* outActSqrt: sum_i outdeg_i^1.5 */
#define TERMCODE_OUTTRUNC 54		/* protocol 30: RSiena's functions of the outdegree with parameter c */
#define TERMCODE_OUTMORE 55
#define TERMCODE_OUTTHRESHOLD 56
#define TERMCODE_OUTINV 57
#define TERMCODE_OUTSQINV 58
#define TERMCODE_RECIPOP 59			/* protocol 31: RSiena's reciprocated-degree effects, statistic and contribution copied separately */
#define TERMCODE_RECIPOPSQRT 60
#define TERMCODE_RECIACT 61
#define TERMCODE_RECIACTSQRT 62
#define TERMCODE_GWDSPFF 63			/* protocol 32: gwdspFF, gwdspFB (decay in p1), betweenness */
#define TERMCODE_GWDSPFB 64
#define TERMCODE_BETWEEN 65
#define TERMCODE_GWESPFB 66			/* protocol 33: gwespFB/BF/BB/RR (decay in p1), nbrDist2, nbrDist2twice */
#define TERMCODE_GWESPBF 67
#define TERMCODE_GWESPBB 68
#define TERMCODE_GWESPRR 69
#define TERMCODE_NBRDIST2 70
#define TERMCODE_NBRDIST2TWICE 71
#define TERMCODE_BEHEGOX 73			/* protocol 34: egoX / altX / egoPlusAltX of the dependent behavior (p1 = its overall mean; the term reads the live behavior slot attrs[nattr]) */
#define TERMCODE_BEHALTX 74
#define TERMCODE_BEHEGOPLUSALT 75
#define SAOM_DYNTC(tc) ((tc) == TERMCODE_BEHSIM || ((tc) >= TERMCODE_BEHEGOX && (tc) <= TERMCODE_BEHEGOPLUSALT))
#define TERMCODE_CYCLE4SQRT 72			/* cycle4 / sharedPop with RSiena parameter 2 */
#define TERMCODE_DYADCOV 40
#define TERMCODE_DYADCOVRECIP 41
static int saom_masked_base(int tc) {
	if (tc == 142 || tc == 143 || (tc >= 148 && tc <= 153)) return tc - 100;		/* protocol 24: masked absdiffx, egoxaltx, diffx ... simrecipx */
	switch (tc) {
		case TERMCODE_NODEMATCH_M: return TERMCODE_NODEMATCH;
		case TERMCODE_NODECOV_M: return TERMCODE_NODECOV;
		case TERMCODE_NODEICOV_M: return TERMCODE_NODEICOV;
		case TERMCODE_NODEOCOV_M: return TERMCODE_NODEOCOV;
		case TERMCODE_SIMCOV_M: return TERMCODE_SIMCOV;
		default: return 0;
	}
}

/* Plugin protocol version, saved as __saom_native_version on every call.
   2 = adds TERMCODE_BEHSIM, centered avAlt, and the per-variable ministep
   counts (__saom_native_stepsnet/stepsbeh) and end-vs-start network
   distance (__saom_native_netdist) that unconditional co-evolution
   estimation needs. The Mata side refuses the native co-evolution path for
   a plugin reporting < 2 (stale binary) and falls back to Mata. */
static double saom_degfun(int termcode, double d, double c) {
	switch (termcode) {
		case TERMCODE_OUTTRUNC: return d < c ? d : c;
		case TERMCODE_OUTMORE: return d > c ? d - c : 0.0;
		case TERMCODE_OUTTHRESHOLD: return d > c ? 1.0 : 0.0;
		case TERMCODE_OUTINV: return 1.0 / (d + c);
		default: return 1.0 / ((d + c) * (d + c + 1.0));
	}
}

#define SAOM_NATIVE_VERSION 70		// 70 = structural rate effects (outRate, outRateInv, outRateLog) in non-directed (pairwise) and two-mode networks; 66 = CONTRIBB: the change contributions of a behavior term for the -1/+1 options of every actor (estat importance with a behavior; the network contributions read the start behavior); 65 (dist-2 W average/similarity effects with the behavior: constant covariate mean, similarity scale) = cross-network terms with the dependent behavior as covariate (codes 4000+: 3000+ code + 1000); 64 = a co-evolving behavior in several networks (MNRUN with behavior terms of BATCHSETUP slot 0, behavior terms >= 10000 driven by the second network); 63 = CONTRIBK: the change contributions of every ego/alternative for one network term (estat importance); 3 = __saom_native_statbehlag%d; 4 = BATCHSETUP/BATCHRUN/BATCHCLEAN (threaded batch simulation), NCORES; 5 = netdist for network-only models too, multiplex per-network steps/distances; 6 = conditional mode with missing dyads/symmetric networks, BATCHRUN condmode 2; 7 = pairwise (symmetric) models with ratecov(): alter drawn by the covariate, RSiena total rate; 8 = symtype 4/5, unilateral-initiative non-directed model types (RSiena AFORCE/AAGREE); 9 = several ratecov() covariates, MAXTERMS 32, MAXATTR 24; 10 = two-way interaction sign on withdrawals (RSiena); 11 = endowment/creation (network and behavior), structural(), three-way interactions, batch for ratecov()/non-directed models, MAXTERMS 256/MAXATTR 128/MAXBEHTERMS 64; 12 = RSiena behavior endowment/creation statistics, interactions of more effects (RSiena tie statistics); 26 = an inactive (absent) actor stays among the alters of an active ego, as RSiena (composition change); 27 = composition change at fractional times in the batch path (join/leave events per period); 28 = pairwise (symmetric) models draw the alter among the active actors only (RSiena: alters in proportion to their rates), events recompute the pairwise rate terms; 29 = creation statistic of the ego-activity degree effects on the start-network degrees (RSiena); 30 = outTrunc, outMore, outThreshold, outInv, outSqInv (term codes 54-58, parameter c); 31 = reciPop, reciPopSqrt, reciAct, reciAct(2) (59-62); 32 = gwdspFF, gwdspFB, betweenness (63-65); 33 = gwespFB/BF/BB/RR, nbrDist2, nbrDist2twice (66-71); 34 = egoX/altX/egoPlusAltX of the dependent behavior (73-75); 35 = behavior effects indeg, outdeg, recipDeg, isolate, outIsolate, totAlt, avAltPop, totAltPop, maxAlt, minAlt, avRecAlt, totRecAlt and the similarity family (105-124); 36 = effFrom: covariate main effects on the behavior (term codes 125-132, centred covariates in the BATCHSETUP trailer); 37 = avXAlt, avSameXAlt, totXAlt, totSameXAlt (term codes 133-164) on the behavior-covariate store; 38 = changing (per-period) covariates for the behavior covariate effects; 39 = covariate x triad/popularity/activity effects (term codes 165-180); 40 = centred and combined degree effects, avDeg, transTriads (term codes 181-188); 41 = covariate threshold and contrast effects (term codes 189-200); 42 = structural rate effects (outRate, inRate, recipRate, Inv, Log versions) as dynamic rate covariates; 43 = behavior effects of the network x a covariate (term codes 300+: avXInAlt ... degNegContrX); 44 = behavior effects avInSim ... totInAlt (term codes 820+); 45 = network terms with the dependent behavior as the covariate (term code + 1000); 46 = NETSTAT: the observed statistic of one network term computed by the plugin; 47 = BEHSTAT: the observed statistic of one behavior term computed by the plugin; 48 = behavior effects with a dyadic covariate (term codes 840+: avAltW ... totSimW); 49 = network effects of a dyadic covariate WWX ... XXW (term codes 250-258); 62 = non-directed (forcing) members in several co-evolving networks; 61 = primary-setting effects primary primCompress nonPCompress primDegAct* (codes 296-304, the period's start network); 60 = behavior effects varAlt avSimVarAlt behDenseTriads simDenseTriads (bu 14-17, the behavior variance in the trailer); 59 = sameXV/sameXVInPop (codes 293, 294); 58 = similarity effects with the dependent behavior as covariate (scale 1/range); 57 = changing dyadic covariates of the behavior effects (tvbehw); 56 = cross-network effects with a constant covariate (codes 3100+), covariate effects in two-mode networks; 55 = behavior effects indegAvGroup indegTotGroup avAlt_cc totAlt_cc avInAltDist2_nc ... totGwdspFBAlt_nc avInSimDist2 totInSimDist2 (codes 2800+); 54 = own-network effects without a covariate (Jin Jout transTrip1/2 transRecTrip2 transTrip.FR/FE/EE outPopMore outPopSqrtMore outPopThreshold and the ego degree effects; codes 260+); 53 = another co-evolving behavior as the covariate of the behavior-1 covariate effects (slot flag in the covariate trailer); 52 = several co-evolving networks (BATCHSETUP<k>|, MNRUN, MNOBS) and the cross-network terms 3000+; 51 = behavior shape effects quad_cc quad_nc constant threshold simAllNear simAllFar avGroup totGroup (term codes 2000+); 50 = homXTransRecTrip, sameXTransRecTrip, diffXTransRecTrip, egoXaltXRecip, sameXCycle4, sameInXCycle4, avGroupEgoX, totGroupEgoX (term codes 235-242)

/* behavior range for TERMCODE_BEHSIM, set by stata_call() once the
   behavior block is parsed (saom_change_term()'s signature has no room
   for it). */
static double saom_behsim_range = 1.0;

#define TERMCODE_BEH_LINEAR 101
#define TERMCODE_BEH_QUADRATIC 102
#define TERMCODE_BEH_AVALT 103
#define TERMCODE_BEH_AVSIM 104
/* protocol 35: RSiena's behavior effects of the network position, of the alters and the similarity family (copied from the C++, see unw_saom.do) */
#define TERMCODE_BEH_INDEG 105
#define TERMCODE_BEH_OUTDEG 106
#define TERMCODE_BEH_RECIPDEG 107
#define TERMCODE_BEH_ISOLATE 108
#define TERMCODE_BEH_OUTISOLATE 109
#define TERMCODE_BEH_TOTALT 110
#define TERMCODE_BEH_AVALTPOP 111
#define TERMCODE_BEH_TOTALTPOP 112
#define TERMCODE_BEH_MAXALT 113
#define TERMCODE_BEH_MINALT 114
#define TERMCODE_BEH_AVRECALT 115
#define TERMCODE_BEH_TOTRECALT 116
#define TERMCODE_BEH_TOTSIM 117
#define TERMCODE_BEH_AVATTHIGHER 118
#define TERMCODE_BEH_AVATTLOWER 119
#define TERMCODE_BEH_TOTATTHIGHER 120
#define TERMCODE_BEH_TOTATTLOWER 121
#define TERMCODE_BEH_AVSIMPOPALT 122
#define TERMCODE_BEH_TOTSIMPOPALT 123
#define TERMCODE_BEH_AVSIMPOPEGO 124
#define TERMCODE_BEH_EFFCOV0 125					/* protocol 36: effFrom, covariate slot tc-125 (0..7) */
#define SAOM_BEH_COVTC(tc) ((tc) >= TERMCODE_BEH_EFFCOV0 && (tc) < TERMCODE_BEH_EFFCOV0 + 8)
#define TERMCODE_BEH_XALT0 133					/* avXAlt, avSameXAlt, totXAlt, totSameXAlt x covariate slot: 133 + 8*variant + slot */
#define SAOM_BEH_XALTTC(tc) ((tc) >= TERMCODE_BEH_XALT0 && (tc) < TERMCODE_BEH_XALT0 + 32)
static double **saom_behcov_pp[8];			/* centred covariates (1-based): per covariate 1 (constant) or P (changing) value arrays, from the BATCHSETUP trailer */
static int saom_behcov_np[8];
static double saom_behcov_mean[8];
static double *saom_bdy[8];
static __thread const double *saom_tl_bdy[8];	/* protocol 57: the dyadic covariates of the current period (NULL: saom_bdy) */
static double **saom_bdypd[8];
static long saom_bdy_np = 1;			/* protocol 48: dyadic covariates of the behavior effects, n x n, row-major (i-1)*n + (j-1) */
static long saom_bdy_pending = 0;
static long saom_bdy_n = 0;		/* the covariates' raw means (RSiena's covariateMean(), the value of min / max without alters) */
static int saom_bcov_dyn[8];	/* protocol 53: covariate slot c is another co-evolving behavior (its number, 1-based from 0 = the first behavior), 0 = a fixed covariate */
static __thread double saom_tl_behscale = 1.0;	/* protocol 58: 1 / the range of the dependent behavior (the behavior-as-covariate similarity effects) */
static __thread double saom_tl_sscale = 1.0;
static __thread void *saom_tl_xg;	/* protocol 52: the OTHER network's graph for the cross-network terms (codes 3000+), set by the multi-network simulation */
static __thread const double *saom_tl_beh0;	/* protocol 51: the starting behavior of the current period/behavior (the constant effect), set in simulate_period() */
static __thread const double *saom_tl_cov[8];	/* the current period's covariates, set at the start of simulate_period() */
#define SAOM_BEH_NEWTC(tc) ((tc) >= TERMCODE_BEH_INDEG && (tc) <= TERMCODE_BEH_AVSIMPOPEGO)

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
	unsigned char *adjm;		// optional dense (n+1)x(n+1) adjacency (2026-10-01): O(1) has_edge() without hashing; NULL = use the hash table
} graph_t;

static long dyadkey(graph_t *g, long i, long j) {
	return i * (g->n + 1) + j;
}

static int has_edge(graph_t *g, long i, long j) {
	long val;
	if (g->adjm) return g->adjm[i * (g->n + 1) + j];
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
		if (g->adjm) g->adjm[i * (g->n + 1) + j] = 0;
		if (g->need_adj) { adj_remove(&g->outadj[i], j); adj_remove(&g->inadj[j], i); }
	}
	else {
		elist_ensure(g, g->nties + 1);
		g->elist_i[g->nties] = i;
		g->elist_j[g->nties] = j;
		ht_put(&g->ht, key, g->nties);
		g->nties++;
		g->dout[i]++; g->din[j]++;
		if (g->adjm) g->adjm[i * (g->n + 1) + j] = 1;
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

/* cycle4 for every alternative of one ego in one pass: out[j] = pair_cycle4_threepaths(g, actor, j) for all j.
   Every path actor->h<-k (k != actor) adds one to each out-neighbour j of k; the paths that leave through
   h == j are removed afterwards (h ranges over the out-neighbours of the actor except j, and k->j holds for
   all k in inadj[j], so they number din[j] - 1). Integer counts, identical to the pairwise port. */
static void batch_cycle4(graph_t *g, long actor, double *out) {
	long m, mm, a, h, k, j;
	for (m = 0; m < g->outadj[actor].len; m++) {
		h = g->outadj[actor].nb[m];
		for (mm = 0; mm < g->inadj[h].len; mm++) {
			k = g->inadj[h].nb[mm];
			if (k == actor) continue;
			for (a = 0; a < g->outadj[k].len; a++) out[g->outadj[k].nb[a]] += 1.0;
		}
	}
	for (m = 0; m < g->outadj[actor].len; m++) {
		j = g->outadj[actor].nb[m];
		out[j] -= (double)(g->din[j] - 1);
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

/* reciprocal degree of j: the number of actors with a tie both ways (needs outadj) */
static long saom_recdeg(graph_t *g, long j) {
	long cnt = 0, m;
	for (m = 0; m < g->outadj[j].len; m++) if (has_edge(g, g->outadj[j].nb[m], j)) cnt++;
	return cnt;
}
/* RSiena's calculateContribution() of the four effects (unsigned: "with tie minus without tie" as RSiena codes it), see unw_saom.do */
static double saom_reci_change(graph_t *g, int termcode, long i, long j, int tied) {
	int back = has_edge(g, j, i);
	double ch;
	if (termcode == TERMCODE_RECIPOP || termcode == TERMCODE_RECIPOPSQRT) {
		ch = (double)saom_recdeg(g, j) + (back ? 1.0 : 0.0);
		if (termcode == TERMCODE_RECIPOPSQRT) ch = sqrt(ch);
	}
	else if (termcode == TERMCODE_RECIACT) {
		double rd = (double)saom_recdeg(g, i);
		if (back) rd += (double)g->dout[i] + (tied ? -1.0 : 1.0);
		ch = rd;
	}
	else {
		/* RSiena's SqrtTable::sqrt(-1) reads just before its table (about 0): the square root of a negative count is taken as 0 */
		double rd = (double)saom_recdeg(g, i) - (tied ? 1.0 : 0.0), rr = rd > 0.0 ? sqrt(rd) : 0.0, dif = 0.0;
		if (back) {
			double outd = (double)g->dout[i] + (tied ? 0.0 : 1.0);
			dif = outd * ((rd + 1.0 > 0.0 ? sqrt(rd + 1.0) : 0.0) - rr);
		}
		ch = rr + dif;
	}
	return tied ? -ch : ch;
}

/* gw_kernel(d,decay) = exp(decay)*(1-(1-exp(-decay))^d) - Mata's own
   ErgmGraph-side gw_kernel() (unw_ergm.do) and native/ergm_mcmc.c's own
   identical helper, independently re-declared here rather than shared
   across files (this file's own established "never share/edit
   native/ergm_mcmc.c" convention) - used by GWESP below. */
static double gw_kernel(double d, double decay) {
	return exp(decay) * (1.0 - pow(1.0 - exp(-decay), d));
}

/* statistic of gwdspFF (fb = 0) / gwdspFB (fb = 1): sum over ordered pairs (i,h), h != i, of the weight of the number of two-paths i->k->h / common out-neighbours of i and h */
static double saom_gwdsp_stat(graph_t *g, double decay, int fb) {
	long i, k, h, a, b, n = g->n, nt;
	double tot = 0.0;
	long *cnt = (long *)calloc((size_t)(n + 1), sizeof(long));
	long *touched = (long *)malloc((size_t)(n + 1) * sizeof(long));
	for (i = 1; i <= n; i++) {
		nt = 0;
		for (a = 0; a < g->outadj[i].len; a++) {
			k = g->outadj[i].nb[a];
			adjlist_t *L = fb ? &g->inadj[k] : &g->outadj[k];
			for (b = 0; b < L->len; b++) {
				h = L->nb[b];
				if (h == i) continue;
				if (cnt[h] == 0) touched[nt++] = h;
				cnt[h]++;
			}
		}
		for (a = 0; a < nt; a++) { tot += gw_kernel((double)cnt[touched[a]], decay); cnt[touched[a]] = 0; }
	}
	free(cnt); free(touched);
	return tot;
}
/* RSiena's contribution (signed): the change of the ego's own row only */
static double saom_gwdsp_change(graph_t *g, long i, long j, double decay, int fb, int tied) {
	long a, h;
	double contr = 0.0;
	adjlist_t *L = fb ? &g->inadj[j] : &g->outadj[j];
	for (a = 0; a < L->len; a++) {
		double c;
		h = L->nb[a];
		if (h == i) continue;
		c = fb ? (double)pair_osp(g, i, h) : (double)pair_otp(g, i, h);
		if (tied) contr += gw_kernel(c, decay) - gw_kernel(c - 1.0, decay);
		else contr += gw_kernel(c + 1.0, decay) - gw_kernel(c, decay);
	}
	return tied ? -contr : contr;
}
static long saom_rr_count(graph_t *g, long i, long j) {
	long m, c = 0;
	for (m = 0; m < g->outadj[i].len; m++) {
		long k = g->outadj[i].nb[m];
		if (k != j && has_edge(g, k, i) && has_edge(g, j, k) && has_edge(g, k, j)) c++;
	}
	return c;
}
static double saom_gwesp_var(graph_t *g, int termcode, double decay, long i, long j) {
	long cnt;
	switch (termcode) {
		case TERMCODE_GWESPFB: cnt = pair_osp(g, i, j); break;
		case TERMCODE_GWESPBF: cnt = pair_isp(g, i, j); break;
		case TERMCODE_GWESPBB: cnt = pair_otp(g, j, i); break;
		default: cnt = saom_rr_count(g, i, j); break;
	}
	return gw_kernel((double)cnt, decay);
}
/* nbrDist2 (cmin = 1) / nbrDist2twice (cmin = 2): statistic and RSiena's (ego-row) contribution */
static double saom_nbrdist2_stat(graph_t *g, long cmin) {
	long i, k, h, a, b, n = g->n, nt;
	double tot = 0.0;
	long *cnt = (long *)calloc((size_t)(n + 1), sizeof(long));
	long *touched = (long *)malloc((size_t)(n + 1) * sizeof(long));
	for (i = 1; i <= n; i++) {
		nt = 0;
		for (a = 0; a < g->outadj[i].len; a++) {
			k = g->outadj[i].nb[a];
			for (b = 0; b < g->outadj[k].len; b++) {
				h = g->outadj[k].nb[b];
				if (cnt[h] == 0) touched[nt++] = h;
				cnt[h]++;
			}
		}
		for (a = 0; a < nt; a++) {
			h = touched[a];
			if (h != i && cnt[h] >= cmin && !has_edge(g, i, h)) tot += 1.0;
			cnt[h] = 0;
		}
	}
	free(cnt); free(touched);
	return tot;
}
static double saom_nbrdist2_change(graph_t *g, long i, long j, long cmin, int tied) {
	long a, h, crit = cmin - (tied ? 0 : 1);
	double ch = 0.0;
	if (pair_otp(g, i, j) >= cmin) ch -= 1.0;
	for (a = 0; a < g->outadj[j].len; a++) {
		h = g->outadj[j].nb[a];
		if (h != i && !has_edge(g, i, h) && pair_otp(g, i, h) == crit) ch += 1.0;
	}
	return tied ? -ch : ch;
}


static double saom_between_tie(graph_t *g, long i, long j) {
	return (double)g->din[i] - (has_edge(g, j, i) ? 1.0 : 0.0) - (double)pair_isp(g, i, j);
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

static double saom_cycle4sqrt_change(graph_t *g, long i, long j, int tied) {
	long a;
	double cur = 0.0, newc, tp, ch;
	for (a = 0; a < g->outadj[i].len; a++) cur += (double)pair_cycle4_threepaths(g, i, g->outadj[i].nb[a]);
	cur = floor(cur / 2.0);
	tp = (double)pair_cycle4_threepaths(g, i, j);
	newc = tied ? cur - tp : cur + tp;
	ch = fabs((newc > 0.0 ? sqrt(newc) : 0.0) - sqrt(cur));
	return tied ? -ch : ch;
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

/* per-tie value of the protocol-23 covariate effects; p1 = the similarity mean (simrecipx; its attribute is already divided by the range) */
static double cov2_val(int code, double vi, double vj, double p1) {
	switch (code) {
		case TERMCODE_DIFFX: return vj - vi;
		case TERMCODE_HIGHER: return (vi > vj) ? 1.0 : ((vi == vj) ? 0.5 : 0.0);
		case TERMCODE_EGOSQX: return vi * vi;
		case TERMCODE_ALTSQX: return vj * vj;
		case TERMCODE_SAMEXRECIP: return (vi == vj) ? 1.0 : 0.0;
		case TERMCODE_SIMRECIPX: return 1.0 - fabs(vi - vj) * saom_tl_sscale - p1;
	}
	return 0.0;
}
static int cov2_isrecip(int code) { return code == TERMCODE_SAMEXRECIP || code == TERMCODE_SIMRECIPX; }

/* protocol 39: covariate x triad / popularity / activity effects (RSiena sameXTransTrip, diffXTransTrip, simXTransTrip, homXTransTrip,
   sameXOutAct, diffXOutAct, sameXReciAct, diffXReciAct, homXOutAct, altXOutAct, inPopX, outPopX, inActX, outActX, sameXInPop, diffXInPop):
   term code 165 + variant, attribute = the (centred) covariate (simXTransTrip: x / range, p1 = similarity mean). cx_value() is RSiena's
   calculateContribution() (the simulation negates it for an existing tie), cx_tie() its tieStatistic() (the statistic is the sum over ties). */
#define TERMCODE_CX0 165
#define SAOM_CXTC(tc) ((tc) >= TERMCODE_CX0 && (tc) < TERMCODE_CX0 + 16)
static int cx_same(const double *a, long i, long j) { return fabs(a[i] - a[j]) < 1e-6; }
static long cx_twopath(graph_t *g, long i, long j) {
	long m, c = 0;
	for (m = 0; m < g->outadj[i].len; m++) if (has_edge(g, g->outadj[i].nb[m], j)) c++;
	return c;
}
static double cx_sum(graph_t *g, const double *a, long j, int in) {
	long m;
	double t = 0.0;
	adjlist_t *L = in ? &g->inadj[j] : &g->outadj[j];
	for (m = 0; m < L->len; m++) t += a[L->nb[m]];
	return t;
}
static double cx_value(graph_t *g, int v, const double *a, double p1, long i, long j) {
	long m, c = 0;
	adjlist_t *O = &g->outadj[i];
	switch (v) {
		case 0: case 1: {
			int same = (v == 0);
			double t = ((cx_same(a, j, i) != 0) == same) ? (double)cx_twopath(g, i, j) : 0.0;
			for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (((cx_same(a, h, i) != 0) == same) && has_edge(g, j, h)) t += 1.0; }
			return t;
		}
		case 2: {
			double t = (1.0 - fabs(a[i] - a[j]) * saom_tl_sscale - p1) * (double)cx_twopath(g, i, j);
			for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (has_edge(g, h, j)) t += 1.0 - fabs(a[i] - a[h]) * saom_tl_sscale - p1; }
			return t;
		}
		case 3: {
			double t = 0.0;
			if (cx_same(a, j, i)) for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (cx_same(a, h, i)) { if (has_edge(g, j, h)) t += 1.0; if (has_edge(g, h, j)) t += 1.0; } }
			return t;
		}
		case 4: case 5: {
			int same = (v == 4);
			if ((cx_same(a, j, i) != 0) == same) {
				for (m = 0; m < O->len; m++) { long h = O->nb[m]; if ((cx_same(a, h, i) != 0) == same) c++; }
				if (has_edge(g, i, j)) c--;
			}
			return 2.0 * (double)c + 1.0;
		}
		case 6: case 7: {
			int same = (v == 6);
			for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (((cx_same(a, h, i) != 0) == same) && has_edge(g, h, i)) c++; }
			if (has_edge(g, i, j)) c--;
			return 2.0 * (double)c + 1.0;
		}
		case 8: {
			for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (h != j && cx_same(a, h, j)) c++; }
			return 2.0 * (double)c + 1.0;
		}
		case 9: {
			double s2 = cx_sum(g, a, i, 0);
			if (has_edge(g, i, j)) s2 -= a[j];
			return a[j] * 2.0 * s2 + a[j] * a[j];
		}
		case 10: return cx_sum(g, a, j, 1);
		case 11: return cx_sum(g, a, j, 0);
		case 12: return cx_sum(g, a, i, 1);
		case 13: return cx_sum(g, a, i, 0);
		case 14: case 15: {
			int same = (v == 14);
			adjlist_t *I = &g->inadj[j];
			for (m = 0; m < I->len; m++) if ((cx_same(a, I->nb[m], i) != 0) == same) c++;
			if (same && !has_edge(g, i, j)) c++;
			return (double)c;
		}
	}
	return 0.0;
}
static double cx_tie(graph_t *g, int v, const double *a, double p1, long i, long j) {
	long m, c = 0;
	adjlist_t *O = &g->outadj[i];
	switch (v) {
		case 0: case 1: return ((cx_same(a, j, i) != 0) == (v == 0)) ? (double)cx_twopath(g, i, j) : 0.0;
		case 2: return (1.0 - fabs(a[i] - a[j]) * saom_tl_sscale - p1) * (double)cx_twopath(g, i, j);
		case 3:
			if (cx_same(a, j, i)) for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (cx_same(a, h, i) && has_edge(g, h, j)) c++; }
			return (double)c;
		case 4: case 5: {
			int same = (v == 4);
			if ((cx_same(a, j, i) != 0) == same) for (m = 0; m < O->len; m++) if ((cx_same(a, O->nb[m], i) != 0) == same) c++;
			return (double)c;
		}
		case 6: case 7: {
			int same = (v == 6);
			for (m = 0; m < O->len; m++) { long h = O->nb[m]; if (((cx_same(a, h, i) != 0) == same) && has_edge(g, h, i)) c++; }
			return (double)c;
		}
		case 8: for (m = 0; m < O->len; m++) if (cx_same(a, O->nb[m], j)) c++; return (double)c;
		case 9: return a[j] * cx_sum(g, a, i, 0);
		case 10: return cx_sum(g, a, j, 1);
		case 11: return cx_sum(g, a, j, 0);
		case 12: return cx_sum(g, a, i, 1);
		case 13: return cx_sum(g, a, i, 0);
		case 14: case 15: {
			int same = (v == 14);
			adjlist_t *I = &g->inadj[j];
			for (m = 0; m < I->len; m++) if ((cx_same(a, I->nb[m], i) != 0) == same) c++;
			return (double)c;
		}
	}
	return 0.0;
}

/* protocol 40: centred / combined degree effects (RSiena inPop.c, outPop.c, outAct.c, inAct.c, degPlus, degPlus.c, avDeg) and transTriads; term code
   181 + variant, p1 = the centring constant (average degree over all waves; avDeg: the user's parameter). df_value() is RSiena's
   calculateContribution() (negated by the simulation for an existing tie), df_tie() its tieStatistic(); avDeg's statistic is the ego statistic. */
#define TERMCODE_DF0 181
#define SAOM_DFTC(tc) ((tc) >= TERMCODE_DF0 && (tc) < TERMCODE_DF0 + 8)
static double df_value(graph_t *g, int v, double c, long i, long j, const double *a) {
	int ex = has_edge(g, i, j);
	double d = (double)g->dout[i];
	switch (v) {
		case 0: return (double)g->din[j] + (ex ? 0.0 : 1.0) - c;
		case 1: return (double)g->dout[j] - c;
		case 2: return (ex ? 2.0 * d - 1.0 : 2.0 * d + 1.0) - c;
		case 3: return (double)g->din[i] - c;
		case 4: case 5: return (double)g->din[j] + (ex ? 0.0 : 1.0) + (ex ? 2.0 * d - 1.0 : 2.0 * d + 1.0) - (v == 5 ? c : 0.0);
		case 6: return ((double)g->nties + d) / ((a && a[1] > 0.5) ? a[1] : (double)g->n) - c;		/* a[1] = the number of actors of a two-mode network */
		case 7: return (double)pair_otp(g, i, j);
	}
	return 0.0;
}
static double df_tie(graph_t *g, int v, double c, long i, long j) {
	switch (v) {
		case 0: return (double)g->din[j] - c;
		case 1: return (double)g->dout[j] - c;
		case 2: return (double)g->dout[i] - c;
		case 3: return (double)g->din[i] - c;
		case 4: return (double)g->din[j] + (double)g->dout[i];
		case 5: return (double)g->din[j] + (double)g->dout[i] - c;
		case 7: return (double)pair_otp(g, i, j) / 6.0;
	}
	return 0.0;
}

/* protocol 41: covariate threshold / contrast effects (RSiena egoPlusAltSqX, diffSqX, egoDiffX, altHigherEgoX, unequalX, egoLThresholdX, egoRThresholdX,
   altLThresholdX, altRThresholdX, degAbsDiffX, degPosDiffX, degNegDiffX); term code 189 + variant, attribute = the centred covariate, p1 = the
   threshold (centred scale) or unused. The first nine are values per tie (contribution = tie statistic); the deg*DiffX are ego statistics. */
#define TERMCODE_CT0 189
#define SAOM_CTTC(tc) ((tc) >= TERMCODE_CT0 && (tc) < TERMCODE_CT0 + 12)
static double ct_tieval(int v, double xi, double xj, double thr) {
	switch (v) {
		case 0: return xi * xi + xj * xj;
		case 1: return (xj - xi) * (xj - xi);
		case 2: return (xj - xi) * xi;
		case 3: return xi > xj ? -1.0 : (xi < xj ? 1.0 : 0.0);
		case 4: return fabs(xj - xi) >= 1e-6 ? 1.0 : 0.0;
		case 5: return xi <= thr + 1e-12 ? 1.0 : 0.0;
		case 6: return xi >= thr - 1e-12 ? 1.0 : 0.0;
		case 7: return xj <= thr + 1e-12 ? 1.0 : 0.0;
		case 8: return xj >= thr - 1e-12 ? 1.0 : 0.0;
	}
	return 0.0;
}
static double ct_egostat(int v, double xi, long deg) {
	long x = (long)floor(xi);
	long dd = deg - x;
	if (v == 9) return (double)(dd > 0 ? dd : -dd);
	if (v == 10) return dd > 0 ? (double)dd : 0.0;
	return dd < 0 ? (double)(-dd) : 0.0;
}
static double ct_value(graph_t *g, int v, const double *a, double p1, long i, long j, int ex) {
	if (v < 9) return ct_tieval(v, a[i], a[j], p1);
	{
		long x = (long)floor(a[i]), deg = g->dout[i];
		if (ex) deg--;
		if (v == 10) return deg >= x ? 1.0 : 0.0;
		if (v == 11) return deg < x ? -1.0 : 0.0;
		return deg < x ? -1.0 : 1.0;		/* degAbsDiffX: plus and minus; minus wins */
	}
}

/* protocol 46: further covariate network effects (term code 220 + v; attribute = the centred covariate, scaled by 1/range and with p1 = the similarity
   mean for the similarity versions, the RAW categories for homXOutAct2, p1 = c for outXMore). v: 0 crossXOutAct 1 homXOutAct2 2 outXMore 3 IndTies
   4 transTripX 5 jumpXTransTrip 6 altDist2 7 totDist2 8 simDist2 9 simEgoDist2 10 sameEgoDist2 11 altInDist2 12 totInDist2 13 simEgoInDist2
   14 sameEgoInDist2. Ports of RSiena's calculateContribution() (cz_value) and tieStatistic() / egoStatistic() (cz_tie, cz_ego). */
#define TERMCODE_CZ0 220
#define SAOM_CZTC(tc) ((tc) >= TERMCODE_CZ0 && (tc) < TERMCODE_CZ0 + 23)
static long cz_twopath(graph_t *g, long i, long h) {
	long m, c = 0;
	for (m = 0; m < g->outadj[i].len; m++) if (has_edge(g, g->outadj[i].nb[m], h)) c++;
	return c;
}
static double cz_avgout(graph_t *g, const double *a, long j, int tot) {
	long m, d = g->outadj[j].len;
	double t = 0.0;
	if (d == 0) return 0.0;
	for (m = 0; m < d; m++) t += a[g->outadj[j].nb[m]];
	return tot ? t : t / (double)d;
}
static double cz_sim(double x, double y, double p1) { return 1.0 - fabs(x - y) * saom_tl_sscale - p1; }
/* 15 homXTransRecTrip, 16 sameXTransRecTrip, 17 diffXTransRecTrip, 18 egoXaltXRecip, 19 sameXCycle4, 20 sameInXCycle4, 21 avGroupEgoX, 22 totGroupEgoX
   (protocol 50; RSiena HomCovariateTransitiveTripletsEffect, SameCovariateTransitiveReciprocatedTripletsEffect, CovariateEgoAlterEffect,
   SameCovariateFourCyclesEffect, SameInCovariateFourCyclesEffect, AverageGroupEgoEffect). p1 of the cycle effects is RSiena's parameter 1 or 2 (sqrt). */
static long cz_cyc_count(graph_t *g, const double *a, long i, long j, int in) {
	long m, m2, c = 0;
	for (m = 0; m < g->outadj[i].len; m++) {
		long h = g->outadj[i].nb[m];
		if (j == h) continue;
		if (in) {
			if (!cx_same(a, j, h)) continue;
			for (m2 = 0; m2 < g->inadj[h].len; m2++) { long k = g->inadj[h].nb[m2]; if (k != i && has_edge(g, k, j)) c++; }
		}
		else {
			for (m2 = 0; m2 < g->inadj[h].len; m2++) { long k = g->inadj[h].nb[m2]; if (k != i && cx_same(a, k, i) && has_edge(g, k, j)) c++; }
		}
	}
	return c;
}
static long cz_cyc_current(graph_t *g, const double *a, long i, int in) {
	long m, tot = 0;
	for (m = 0; m < g->outadj[i].len; m++) tot += cz_cyc_count(g, a, i, g->outadj[i].nb[m], in);
	return tot / 2;
}
static double cz_cyc_value(graph_t *g, const double *a, double p1, long i, long j, int in) {
	long cnt = cz_cyc_count(g, a, i, j, in);
	if (p1 > 1.5) {
		long cur = cz_cyc_current(g, a, i, in), nw = has_edge(g, i, j) ? cur - cnt : cur + cnt;
		return fabs(sqrt((double)nw) - sqrt((double)cur));
	}
	return (double)cnt;
}
static double cz_groupmean(graph_t *g, const double *a) {
	long k;
	double t = 0.0;
	for (k = 1; k <= g->n; k++) t += a[k];
	return g->n > 0 ? t / (double)g->n : 0.0;
}

static double cz_value(graph_t *g, int v, const double *a, double p1, long i, long j) {
	long m, d;
	double t;
	int ex = has_edge(g, i, j);
	switch (v) {
		case 15: {
			long c = 0;
			if (cx_same(a, j, i)) for (m = 0; m < g->outadj[i].len; m++) {
				long h = g->outadj[i].nb[m];
				if (!cx_same(a, h, i)) continue;
				if (has_edge(g, j, h) && has_edge(g, i, h)) c++;
				if (has_edge(g, h, j) && ex) c++;
			}
			return (double)c;
		}
		case 16: case 17: {
			double c = 0.0;
			int same = (v == 16);
			if (has_edge(g, j, i) && (cx_same(a, j, i) == same)) c = (double)cx_twopath(g, i, j);
			for (m = 0; m < g->outadj[i].len; m++) {
				long h = g->outadj[i].nb[m];
				if (!has_edge(g, h, i) || h == j) continue;
				if ((cx_same(a, h, i) == same) && has_edge(g, h, j)) c += 1.0;
			}
			return c;
		}
		case 18: return has_edge(g, j, i) ? a[i] * a[j] : 0.0;
		case 19: return cz_cyc_value(g, a, p1, i, j, 0);
		case 20: return cz_cyc_value(g, a, p1, i, j, 1);
		case 21: return cz_groupmean(g, a);
		case 22: return cz_groupmean(g, a) * (p1 > 0.5 ? p1 : (double)g->n);		/* p1 = the number of events of a two-mode network */
		case 0: {
			long ds = 0, dd = 0;
			for (m = 0; m < g->outadj[i].len; m++) { if (cx_same(a, g->outadj[i].nb[m], i)) ds++; else dd++; }
			if (ex) { if (cx_same(a, j, i)) ds--; else dd--; }
			return cx_same(a, j, i) ? (2.0 * (double)ds + 1.0) * (double)dd : (2.0 * (double)dd + 1.0) * (double)ds;
		}
		case 1: {
			long b = (long)floor(a[j] + 0.5), cnt = 0;
			if (b < 1) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) if ((long)floor(a[g->outadj[i].nb[m]] + 0.5) == b) cnt++;
			if (ex) cnt -= 2;
			{
				int root = (fabs(p1 - 2.0) < 1e-9 || fabs(p1 - 4.0) < 1e-9), avg = (p1 >= 3.0 - 1e-9);
				double ct = root ? ((double)cnt + 1.0) * sqrt((double)cnt + 1.0) - (double)cnt * sqrt((double)cnt) : 2.0 * (double)cnt + 1.0;
				if (avg) { long nb = 0, q; for (q = 1; q <= g->n; q++) if ((long)floor(a[q] + 0.5) == b) nb++; ct /= root ? sqrt((double)nb) : (double)nb; }
				return ct;
			}
		}
		case 2: {
			long outd = -(long)floor(p1 + 0.001);
			if (a[j] <= 0.0) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) if (a[g->outadj[i].nb[m]] > 0.0) outd++;
			if (ex) return outd >= 1 ? 1.0 : 0.0;
			return outd >= 0 ? 1.0 : 0.0;
		}
		case 3: {
			double ch = 0.0;
			long crit = ex ? 1 : 0;
			if (cz_twopath(g, i, j) != 0) ch -= a[j];
			for (m = 0; m < g->outadj[j].len; m++) {
				long h = g->outadj[j].nb[m];
				if (h != i && !has_edge(g, i, h) && cz_twopath(g, i, h) == crit) ch += a[h];
			}
			return ch;
		}
		case 4: {
			long instar = 0;
			t = 0.0;
			for (m = 0; m < g->outadj[i].len; m++) { long h = g->outadj[i].nb[m]; if (has_edge(g, j, h)) instar++; if (has_edge(g, h, j)) t += a[h]; }
			return a[j] * (double)instar + t;
		}
		case 5: {
			long c = 0;
			int sj = cx_same(a, j, i);
			for (m = 0; m < g->outadj[i].len; m++) {
				long h = g->outadj[i].nb[m];
				if (sj) { if (!cx_same(a, h, i) && has_edge(g, j, h)) c++; }
				else { if (cx_same(a, h, i) && has_edge(g, h, j)) c++; }
			}
			return (double)c;
		}
		case 6: return cz_avgout(g, a, j, 0);
		case 7: return cz_avgout(g, a, j, 1);
		case 8: return cz_sim(cz_avgout(g, a, i, 0), cz_avgout(g, a, j, 0), p1);
		case 9: {
			double oa = cz_avgout(g, a, j, 1);
			d = g->outadj[j].len;
			if (has_edge(g, j, i)) { oa -= a[i]; d--; }
			oa = (d >= 1) ? oa / (double)d : 0.0;
			return cz_sim(a[i], oa, p1);
		}
		case 10: case 14: {
			adjlist_t *L = (v == 10) ? &g->outadj[j] : &g->inadj[j];
			long used = 0;
			t = 0.0;
			if (L->len > 0) {
				for (m = 0; m < L->len; m++) { long h = L->nb[m]; if (h == i) continue; if (fabs(a[h] - a[i]) < 1e-12) t += 1.0; used++; }
				if (used > 0) t /= (double)used;
			}
			return t;
		}
		case 11: case 12: {
			double tot = 0.0, val;
			d = g->inadj[j].len;
			for (m = 0; m < d; m++) tot += a[g->inadj[j].nb[m]];
			if (d == 0) { val = (v == 12) ? 0.0 : 0.0; }
			else val = (v == 12) ? tot : tot / (double)d;
			if (has_edge(g, i, j)) {
				if (v == 12) val = val - a[i];
				else val = (d > 1) ? ((double)d * val - a[i]) / (double)(d - 1) : 0.0;
			}
			return val;
		}
		case 13: {
			double ia = 0.0;
			d = g->inadj[j].len;
			for (m = 0; m < d; m++) ia += a[g->inadj[j].nb[m]];
			if (has_edge(g, i, j)) { ia -= a[i]; d--; }
			ia = (d >= 1) ? ia / (double)d : 0.0;
			return cz_sim(a[i], ia, p1);
		}
	}
	return 0.0;
}
static double cz_tie(graph_t *g, int v, const double *a, double p1, long i, long j) {
	long m;
	switch (v) {
		case 15: {
			long c = 0;
			if (!cx_same(a, j, i) || !has_edge(g, j, i)) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) { long h = g->outadj[i].nb[m]; if (cx_same(a, h, i) && has_edge(g, h, j)) c++; }
			return (double)c;
		}
		case 16: case 17: return (has_edge(g, j, i) && (cx_same(a, j, i) == (v == 16))) ? (double)cx_twopath(g, i, j) : 0.0;
		case 18: return has_edge(g, j, i) ? a[i] * a[j] : 0.0;
		case 1: {
			long b = (long)floor(a[j] + 0.5), cnt = 0;
			if (b < 1) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) if ((long)floor(a[g->outadj[i].nb[m]] + 0.5) == b) cnt++;
			{
				int root = (fabs(p1 - 2.0) < 1e-9 || fabs(p1 - 4.0) < 1e-9), avg = (p1 >= 3.0 - 1e-9);
				double st = root ? sqrt((double)cnt) : (double)cnt;
				if (avg) { long nb = 0, q; for (q = 1; q <= g->n; q++) if ((long)floor(a[q] + 0.5) == b) nb++; st /= root ? sqrt((double)nb) : (double)nb; }
				return st;
			}
		}
		case 4: {
			long instar = 0;
			for (m = 0; m < g->outadj[i].len; m++) if (has_edge(g, j, g->outadj[i].nb[m])) instar++;
			return a[j] * (double)instar;
		}
		case 5: {
			long c = 0;
			if (cx_same(a, j, i)) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) { long h = g->outadj[i].nb[m]; if (cx_same(a, h, i) && has_edge(g, h, j)) c++; }
			return (double)c;
		}
		default: return cz_value(g, v, a, p1, i, j);		/* the other tie statistics equal the contribution evaluated with the tie present */
	}
}
static double cz_ego(graph_t *g, int v, const double *a, double p1, long i) {
	long m;
	if (v == 19 || v == 20) {
		double st = 0.0;
		if (g->outadj[i].len == 0) return 0.0;
		for (m = 0; m < g->outadj[i].len; m++) {
			long cnt = cz_cyc_count(g, a, i, g->outadj[i].nb[m], v == 20);
			st += p1 > 1.5 ? 0.5 * sqrt((double)cnt) : 0.25 * (double)cnt;
		}
		return st;
	}
	if (v == 21) return (double)g->outadj[i].len * cz_groupmean(g, a);
	if (v == 22) return (double)g->outadj[i].len * cz_groupmean(g, a) * (p1 > 0.5 ? p1 : (double)g->n);
	if (v == 0) {
		long ds = 0, dd = 0;
		for (m = 0; m < g->outadj[i].len; m++) { if (cx_same(a, g->outadj[i].nb[m], i)) ds++; else dd++; }
		return (double)ds * (double)dd;
	}
	{
		long outd = -(long)floor(p1 + 0.001);
		for (m = 0; m < g->outadj[i].len; m++) if (a[g->outadj[i].nb[m]] > 0.0) outd++;
		return outd > 0 ? (double)outd : 0.0;
	}
}
/* IndTies: the statistic of ego i is the sum of a over the distance-two actors (two-path, no tie), reached once */
static double cz_indties_ego(graph_t *g, const double *a, long i) {
	long m, m2;
	double st = 0.0;
	unsigned char *mark = (unsigned char *)calloc((size_t)(g->n + 1), 1);
	for (m = 0; m < g->outadj[i].len; m++) {
		long j = g->outadj[i].nb[m];
		for (m2 = 0; m2 < g->outadj[j].len; m2++) { long h = g->outadj[j].nb[m2]; if (!mark[h]) { mark[h] = 1; st += a[h]; } }
	}
	for (m = 0; m < g->outadj[i].len; m++) { long h = g->outadj[i].nb[m]; if (mark[h]) { mark[h] = 0; st -= a[h]; } }
	free(mark);
	return st;
}

/* ===================================================================
   protocol 52: cross-network terms (RSiena GenericNetworkEffect with a second dependent network, codes 3000 + v). g = the own network, the OTHER
   network is saom_tl_xg (the current simulated state in the ministeps, the START of the period in the statistics, as RSiena). The tables are
   RSiena's MixedTwoPathTable counts: # of middle actors h with a first step i -(d1)-> h in network G1 and a second step h -(d2)-> j in G2
   (F forward, B backward, R reciprocated, E "either" - for the FIRST step RSiena uses the reciprocated ties for E as well, copied).
   v: 0 crprod 1 crprodRecip 2 crprodMutual 3 from 4 fromMutual 5 fromAny 6 to 7 toBack 8 toRecip 9 cl.XWX 10 cl.XWX1 11 cl.XWX2 12 mixedInXW
   =================================================================== */
#define TERMCODE_XT0 3000
#define SAOM_XTC(tc) ((tc) >= TERMCODE_XT0 && (tc) < TERMCODE_XT0 + 1000)
static int xt_step_has(graph_t *G, char d, long h, long j) {
	switch (d) {
		case 'F': return has_edge(G, h, j);
		case 'B': return has_edge(G, j, h);
		case 'R': return has_edge(G, h, j) && has_edge(G, j, h);
		default: return has_edge(G, h, j) || has_edge(G, j, h);
	}
}
static double xt_mtp(graph_t *G1, graph_t *G2, char d1, char d2, long i, long j) {
	long m, h, c = 0;
	if (!G1 || !G2) return 0.0;
	if (d1 == 'B') {
		for (m = 0; m < G1->inadj[i].len; m++) { h = G1->inadj[i].nb[m]; if (xt_step_has(G2, d2, h, j)) c++; }
	}
	else {
		/* F: the out-ties of i; R and E (copied from RSiena): the reciprocated ties of i */
		for (m = 0; m < G1->outadj[i].len; m++) {
			h = G1->outadj[i].nb[m];
			if (d1 != 'F' && !has_edge(G1, h, i)) continue;
			if (xt_step_has(G2, d2, h, j)) c++;
		}
	}
	return (double)c;
}
static double xt_shape(double v, double par) {
	if (fabs(par - 2.0) < 0.001) return sqrt(v);
	if (fabs(par - 3.0) < 0.001) return v >= 1.0 ? 1.0 : 0.0;
	return v;
}
static double xt_gwesp(double k, double par) {
	double w = -0.01 * par, f = 1.0 - exp(w);
	return exp(-w) * (1.0 - pow(f, k));
}
static double xt_S(double x, double p1) { return p1 >= 2.0 ? sqrt(x) : x; }
static double xt_recip(double x) { return x == 0.0 ? 0.0 : 1.0 / x; }
/* common out-neighbours of i in g and h */
static double xt_common_out(graph_t *g, graph_t *h, long i) {
	long m;
	double c = 0.0;
	for (m = 0; m < g->outadj[i].len; m++) if (has_edge(h, i, g->outadj[i].nb[m])) c++;
	return c;
}

/* protocol 56: cross-network effects with a constant covariate (RSiena covarNetNet and covarA..NetNet effects, interaction1 = the OTHER network h, interaction2 = a covariate of the actors),
   codes 3100 + w; a = the covariate (centred by its mean as RSiena coCovar, 1-based; scaled by its range with p1 = the similarity mean for the sim effects). All counts are over the OTHER network h read at the
   start of the period (the statistics) or in its current state (the ministeps), the own network g only enters the WX / XW closure effects.
   w: 0 sameWW 1 diffWW 2 jumpWW 3 jumpFrom 4 jumpSharedIn 5 sameWX 6 diffWX 7 jumpWX 8 homWX 9 sameXW 10 diffXW 11 covNetNet 12 homCovNetNet 13 contrastCovNetNet
   14 allDifCovNetNet 15 covNetNetIn 16 homCovNetNetIn 17 contrastCovNetNetIn 18 allDifCovNetNetIn (= 17, as RSiena) 19 inPopIntnX 20 inActIntnX 21 outPopIntnX 22 outActIntnX
   23 sameXInPopIntn 24 sameXInActIntn 25 sameXOutPopIntn 26 sameXOutActIntn 27 altDist2W 28 totDist2W 29 simDist2W 30 altInDist2W 31 totInDist2W 32 simEgoDist2W 33 simEgoInDist2W */
#define XC_EPS 1e-6
static int xc_eq(const double *c, long x, long y) { return fabs(c[x] - c[y]) < XC_EPS; }
/* the value an average over no alters takes: RSiena's covariate mean = 0 on the centred covariate (a constant; for the dependent behavior as covariate
   it is NOT the mean of the current values, which moves during the simulation) */
static double xc_covmean(const double *c, long n) { (void)c; (void)n; return 0.0; }
/* the covariate-sum over the out- (or in-) neighbours of x in G */
static double xc_nbsum(graph_t *G, const double *c, long x, int in, long *deg) {
	long m, d = in ? G->inadj[x].len : G->outadj[x].len;
	double t = 0.0;
	for (m = 0; m < d; m++) t += c[in ? G->inadj[x].nb[m] : G->outadj[x].nb[m]];
	if (deg) *deg = d;
	return t;
}
static double xc_value(graph_t *g, int w, const double *c, double p1, long i, long j) {
	graph_t *h = (graph_t *)saom_tl_xg;
	long m, k, cnt = 0, n;
	if (!h || !c) return 0.0;
	n = h->n;
	switch (w) {
		case 0: case 1: case 2: case 5: case 6: case 7: case 8: {
			/* WW: k in out_h(i) with h(k,j); WX: k in out_h(i) with g(k,j) */
			graph_t *H2 = (w >= 5 && w <= 8) ? g : h;
			int same = (w == 0 || w == 2 || w == 5 || w == 7 || w == 8);
			if (w == 2 || w == 7) { if (xc_eq(c, i, j)) return 0.0; }
			if (w == 8) { if (!xc_eq(c, i, j)) return 0.0; }
			for (m = 0; m < h->outadj[i].len; m++) {
				k = h->outadj[i].nb[m];
				if ((xc_eq(c, k, i) != 0) == same && has_edge(H2, k, j)) cnt++;
			}
			return (double)cnt;
		}
		case 9: case 10: {
			/* XW: k in out_g(i) with h(k,j) */
			int same = (w == 9);
			for (m = 0; m < g->outadj[i].len; m++) {
				k = g->outadj[i].nb[m];
				if ((xc_eq(c, k, i) != 0) == same && has_edge(h, k, j)) cnt++;
			}
			return (double)cnt;
		}
		case 3: case 12: case 13: case 14: {
			/* jumpFrom / homCovNetNet / contrastCovNetNet / allDifCovNetNet: k in out_h(i) with h(j,k) */
			int both = (w == 14);
			if (w == 3) { if (xc_eq(c, i, j)) return 0.0; }
			else if (!xc_eq(c, i, j)) return 0.0;
			for (m = 0; m < h->outadj[i].len; m++) {
				k = h->outadj[i].nb[m];
				if (!has_edge(h, j, k)) continue;
				if (w == 3 || w == 12) { if (xc_eq(c, k, i)) cnt++; }
				else if (!xc_eq(c, k, i) && (!both || !xc_eq(c, k, j))) cnt++;
			}
			return (double)cnt;
		}
		case 4: case 16: case 17: case 18: {
			/* jumpSharedIn / homCovNetNetIn / contrastCovNetNetIn / allDifCovNetNetIn: k in in_h(i) with h(k,j) */
			if (w == 4) { if (xc_eq(c, i, j)) return 0.0; }
			else if (!xc_eq(c, i, j)) return 0.0;
			for (m = 0; m < h->inadj[i].len; m++) {
				k = h->inadj[i].nb[m];
				if (w == 4 || w == 16) { if (has_edge(h, k, j) && xc_eq(c, k, i)) cnt++; }
				else if (has_edge(h, j, k) && !xc_eq(c, k, i)) cnt++;	/* RSiena DifferentCovariateOutStar checks the tie alter -> k */
			}
			return (double)cnt;
		}
		case 11: return xc_eq(c, i, j) ? xt_mtp(h, h, 'F', 'B', i, j) : 0.0;
		case 15: return xc_eq(c, i, j) ? xt_mtp(h, h, 'B', 'F', i, j) : 0.0;
		case 19: case 20: case 21: case 22: {
			double t = xc_nbsum(h, c, (w == 19 || w == 21) ? j : i, (w == 19 || w == 20), NULL);
			return p1 >= 2.0 ? sqrt(t) : t;
		}
		case 23: case 24: case 25: case 26: {
			long x = (w == 23 || w == 25) ? j : i, q;
			int in = (w == 23 || w == 24);
			double st = 0.0, vv;
			long len = in ? h->inadj[x].len : h->outadj[x].len;
			for (m = 0; m < len; m++) { k = in ? h->inadj[x].nb[m] : h->outadj[x].nb[m]; if (xc_eq(c, k, i)) st++; }
			vv = st;
			if (in) {
				if (p1 >= 3.0 - 1e-9) { long ne = 0; for (q = 1; q <= n; q++) if (xc_eq(c, q, i)) ne++; vv = st / (double)ne; }
				if (fabs(p1 - 2.0) < 1e-9 || fabs(p1 - 4.0) < 1e-9) vv = sqrt(vv);
			}
			else if (fabs(p1 - 2.0) < 1e-9) vv = sqrt(vv);
			return vv;
		}
		case 27: case 28: {
			long deg;
			double tot = xc_nbsum(h, c, j, 0, &deg), val;
			double av = deg > 0 ? tot / (double)deg : xc_covmean(c, n);
			val = (w == 28) ? tot : av;
			if (fabs(p1 - 2.0) < 1e-9 && has_edge(h, j, i)) {
				if (deg > 1) val = (w == 28) ? val - c[i] : ((double)deg * val - c[i]) / (double)(deg - 1);
				else val = xc_covmean(c, n);
			}
			return val;
		}
		case 30: case 31: {
			long deg;
			double tot = xc_nbsum(h, c, j, 1, &deg), val;
			double av = deg > 0 ? tot / (double)deg : xc_covmean(c, n);
			val = (w == 31) ? tot : av;
			if (has_edge(h, i, j)) {
				if (w == 31) val = val - c[i];
				else val = deg > 1 ? ((double)deg * val - c[i]) / (double)(deg - 1) : xc_covmean(c, n);
			}
			return val;
		}
		case 29: {
			long di, dj;
			double ti = xc_nbsum(h, c, i, 0, &di), tj = xc_nbsum(h, c, j, 0, &dj);
			double ai = di > 0 ? ti / (double)di : xc_covmean(c, n), aj = dj > 0 ? tj / (double)dj : xc_covmean(c, n);
			return 1.0 - fabs(ai - aj) * saom_tl_sscale - p1;
		}
		case 32: case 33: {
			int in = (w == 33);
			long deg;
			double tot = xc_nbsum(h, c, j, in, &deg), av;
			if (in ? has_edge(h, i, j) : has_edge(h, j, i)) { tot -= c[i]; deg--; }
			av = deg >= 1 ? tot / (double)deg : xc_covmean(c, n);
			return 1.0 - fabs(c[i] - av) * saom_tl_sscale - p1;
		}
	}
	return 0.0;
}
/* a[1] = the average degree of the OTHER network (all waves), a[2] = that of the OWN network (RSiena NetworkLongitudinalData::averageInDegree()) */
static double xt_value(graph_t *g, int v, const double *a, double p1, long i, long j) {
	graph_t *h = (graph_t *)saom_tl_xg;
	double avO = a ? a[1] : 0.0, avG = a ? a[2] : 0.0, avSq = a ? a[3] : 0.0;
	if (!h) return 0.0;
	if (v >= 100) return xc_value(g, v - 100, a, p1, i, j);
	switch (v) {
		case 13: return xt_S((double)h->din[j], p1) - xt_S(avO, p1);
		case 14: return xt_S((double)h->din[i], p1) - xt_S(avO, p1);
		case 15: return has_edge(h, i, j) ? xt_S((double)h->din[i], p1) - xt_S(avO, p1) : 0.0;
		case 16: return xt_S((double)h->dout[j], p1) - xt_S(avO, p1);
		case 17: {
			if (p1 < 0.5) return (h->dout[i] > 0 ? log((double)h->dout[i]) : 0.0) - log(avO);
			return xt_S((double)h->dout[i], p1) - xt_S(avO, p1);
		}
		case 18: return xt_recip(xt_S((double)h->dout[i], p1));
		case 19: return xt_recip(xt_S((double)h->din[i], p1));
		case 20: return xt_recip(xt_S((double)h->dout[j], p1));
		case 21: return xt_recip(xt_S((double)h->din[j], p1));
		case 22: { long q; double t = 0.0; for (q = 1; q <= h->n; q++) t += (double)h->dout[q]; return t / (double)h->n - p1; }
		case 23: return fabs(xt_S((double)h->dout[j], p1) - xt_S((double)h->dout[i], p1));
		case 24: return (xt_S((double)h->din[j], p1) - xt_S(avO, p1)) * (xt_S((double)h->din[i], p1) - xt_S(avO, p1));
		case 25: case 26: {
			long m, d = 0;
			double st = 0.0, av = p1 >= 2.0 ? sqrt(avG) : avG;
			for (m = 0; m < h->outadj[i].len; m++) { st += xt_S((double)g->dout[h->outadj[i].nb[m]], p1) - av; d++; }
			if (v == 26 && d > 0) st /= (double)d;
			return st;
		}
		case 27: {
			long m, d = 0;
			double st = 0.0, av = p1 >= 2.0 ? sqrt(avO) : avO;
			for (m = 0; m < h->outadj[i].len; m++) { st += xt_S((double)h->din[h->outadj[i].nb[m]], p1) - av; d++; }
			return st;
		}
		case 28: case 29: case 51: {
			long m, m2, d;
			double st = 0.0, degs = 0.0;
			long *tf = (long *)calloc((size_t)(h->n + 1), sizeof(long));
			(void)d;
			for (m = 0; m < h->outadj[i].len; m++) {
				long k = h->outadj[i].nb[m];
				for (m2 = 0; m2 < h->inadj[k].len; m2++) {
					long q = h->inadj[k].nb[m2];
					if (q != i) {
						double inc = p1 >= 2.0 ? sqrt((double)(tf[q] + 1)) - sqrt((double)tf[q]) : 1.0;
						st += inc * ((double)g->dout[q] - avG);
						degs += inc;
						tf[q]++;
					}
				}
			}
			free(tf);
			if ((v == 29 || v == 51) && degs > 0.0) st /= degs;
			return st;
		}
		case 30: {
			long m, m2, cnt = 0;
			unsigned char *mk = (unsigned char *)calloc((size_t)(h->n + 1), 1);
			for (m = 0; m < h->outadj[i].len; m++) {
				long k = h->outadj[i].nb[m];
				for (m2 = 0; m2 < h->inadj[k].len; m2++) { long q = h->inadj[k].nb[m2]; if (q != i && !mk[q]) { mk[q] = 1; cnt++; } }
			}
			free(mk);
			return p1 >= 2.0 ? sqrt((double)cnt) : (double)cnt;
		}
		case 32: return xt_mtp(h, h, 'F', 'F', i, j);
		case 33: return xt_mtp(h, h, 'B', 'B', i, j);
		case 34: return xt_mtp(h, h, 'B', 'F', i, j);
		case 35: return xt_mtp(h, h, 'E', 'E', i, j);
		case 36: return xt_mtp(h, h, 'F', 'R', i, j);
		case 37: return xt_mtp(h, g, 'F', 'E', i, j);
		case 38: return xt_mtp(h, g, 'E', 'R', i, j);
		case 39: return xt_mtp(g, h, 'E', 'R', i, j);
		case 40: return xt_mtp(g, h, 'F', 'E', i, j);
		case 41: { double os = xt_mtp(h, h, 'B', 'F', i, j), den = (double)h->din[j] + (double)h->din[i] - os; return den >= 1.0 ? os / den : 0.0; }
		case 42: { double is = xt_mtp(h, h, 'F', 'B', i, j), den = (double)h->dout[j] + (double)h->dout[i] - is; return den >= 1.0 ? is / den : 0.0; }
		case 43: return xt_gwesp(xt_mtp(h, h, 'F', 'F', i, j), p1);
		case 44: return xt_gwesp(xt_mtp(h, h, 'B', 'B', i, j), p1);
		case 45: return xt_gwesp(xt_mtp(h, h, 'B', 'F', i, j), p1);
		case 46: return xt_gwesp(xt_mtp(h, h, 'F', 'B', i, j), p1);
		case 47: return xt_gwesp(xt_mtp(h, h, 'R', 'R', i, j), p1);
		case 48: {
			/* inPopOutW: the in-neighbours k of j in the OWN network (k != i): S(outdegree of k in the other network) - (centred: the average) */
			long m;
			double st = 0.0, av = (p1 >= 3.0 ? avO : 0.0);
			int root = (fabs(p1 - 2.0) < 0.001 || fabs(p1 - 4.0) < 0.001);
			if (root) av = sqrt(av);
			for (m = 0; m < g->inadj[j].len; m++) { long k = g->inadj[j].nb[m]; if (k != i) st += (root ? sqrt((double)h->dout[k]) : (double)h->dout[k]) - av; }
			return st;
		}
		case 49: case 50: {
			/* sharedTo / avAlt.2M.tie (MixedThreeCyclesFunction): the in-neighbours k of j in the OWN network */
			long m, m2;
			double st = 0.0, sumd = 1.0, avc = 0.0;
			int root = (fabs(p1 - 2.0) < 0.001 || fabs(p1 - 4.0) < 0.001), center = (p1 >= 3.0);
			if (center) { avc = (avSq - avO) / (double)(g->n - 1); if (root) avc = sqrt(avc); }
			if (v == 50) {
				long *tf = (long *)calloc((size_t)(g->n + 1), sizeof(long));
				double degs = 0.0;
				for (m = 0; m < h->outadj[i].len; m++) {
					long k = h->outadj[i].nb[m];
					for (m2 = 0; m2 < h->inadj[k].len; m2++) { long q = h->inadj[k].nb[m2]; if (q != i) { if (root) tf[q]++; else degs += 1.0; } }
				}
				if (root) { degs = 0.0; for (m = 1; m <= g->n; m++) degs += sqrt((double)tf[m]); }
				sumd = degs;
				free(tf);
			}
			for (m = 0; m < g->inadj[j].len; m++) {
				long k = g->inadj[j].nb[m];
				if (k == i) continue;
				{
					double is = xt_mtp(h, h, 'F', 'B', i, k);
					st += (root ? sqrt(is) : is) - avc;
				}
			}
			if (v == 50 && sumd > 0.0) st /= sumd;
			return st;
		}
		case 52: {
			/* doubleInPop, the CONTRIBUTION: 1 + the common in-neighbours of j in the two networks other than i, if the tie is in the other network */
			long m;
			double c = 1.0;
			if (!has_edge(h, i, j)) return 0.0;
			for (m = 0; m < g->inadj[j].len; m++) { long k = g->inadj[j].nb[m]; if (k != i && has_edge(h, k, j)) c++; }
			return p1 >= 2.0 ? sqrt(c) : c;
		}
		case 31: {
			/* doubleOutAct, the CHANGE version (the statistic version is xt_tie) */
			double c;
			if (!has_edge(h, i, j)) return 0.0;
			c = xt_common_out(g, h, i);
			if (p1 >= 2.0) return has_edge(g, i, j) ? c * sqrt(c) - (c - 1.0) * sqrt(c - 1.0) : (c + 1.0) * sqrt(c + 1.0) - c * sqrt(c);
			return has_edge(g, i, j) ? 2.0 * c - 1.0 : 2.0 * c + 1.0;
		}
		case 0: return has_edge(h, i, j) ? 1.0 : 0.0;
		case 1: return has_edge(h, j, i) ? 1.0 : 0.0;
		case 2: return (has_edge(h, i, j) && has_edge(h, j, i)) ? 1.0 : 0.0;
		case 3: { double c = xt_mtp(h, h, 'F', 'B', i, j); return p1 >= 2.0 ? sqrt(c) : c; }
		case 4: { double c = xt_mtp(h, h, 'R', 'R', i, j); return p1 >= 2.0 ? sqrt(c) : c; }
		case 5: return xt_mtp(h, h, 'F', 'B', i, j) > 0.0 ? 1.0 : 0.0;
		case 6: return xt_shape(xt_mtp(h, g, 'F', 'F', i, j), p1);
		case 7: return xt_shape(xt_mtp(h, g, 'B', 'F', i, j), p1);
		case 8: return xt_shape(xt_mtp(h, g, 'R', 'F', i, j), p1);
		case 9: return xt_mtp(g, h, 'F', 'F', i, j) + xt_mtp(g, h, 'F', 'B', i, j);
		case 10: return xt_mtp(g, h, 'F', 'F', i, j);
		case 11: return xt_mtp(g, h, 'F', 'B', i, j);
		case 12: return xt_shape(xt_mtp(g, h, 'B', 'F', i, j), p1);
	}
	return 0.0;
}
/* the tie statistic: the value itself except doubleOutAct (v 31), whose statistic is the common out-degree m (sqrt m) at a tie also present in the other network */
static double xt_tie(graph_t *g, int v, const double *a, double p1, long i, long j) {
	if (v == 31) {
		graph_t *h = (graph_t *)saom_tl_xg;
		double c;
		if (!h || !has_edge(h, i, j)) return 0.0;
		c = xt_common_out(g, h, i);
		return p1 >= 2.0 ? sqrt(c) : c;
	}
	if (v == 52) {
		graph_t *h = (graph_t *)saom_tl_xg;
		long m;
		double c = 0.0;
		if (!h || !has_edge(h, i, j)) return 0.0;
		for (m = 0; m < g->inadj[j].len; m++) if (has_edge(h, g->inadj[j].nb[m], j)) c++;
		return p1 >= 2.0 ? sqrt(c) : c;
	}
	return xt_value(g, v, a, p1, i, j);
}
static double xt_stat(graph_t *g, int termcode, const double *a, double p1) {
	long k;
	double tot = 0.0;
	int v = termcode - TERMCODE_XT0;
	for (k = 0; k < g->nties; k++) tot += xt_tie(g, v, a, p1, g->elist_i[k], g->elist_j[k]);
	return tot;
}

/* ===================================================================
   protocol 54: network effects of the own network without a covariate (RSiena GenericNetworkEffect / TransitiveTripletsEffect / OutdegreePopularityEffect), codes 260 + v.
   v: 0 Jin 1 Jout 2 transTrip1 3 transTrip2 4 transRecTrip2 = transTrip.FR 5 transTrip.FE 6 transTrip.EE 7 outPopMore 8 outPopSqrtMore 9 outPopThreshold 10 outAct_ego
   11 outActMore_ego 12 outActSqrtMore_ego 13 outMore_ego 14 divOut_ego 15 inAct_ego 16 divIn_ego 17 reciAct_ego. a[1] = the average degree of the network over all waves,
   a[2] = its average reciprocal degree. The ego effects (10-17) are the functions of the ego's degree that RSiena offers for its interactions, used here alone.
   =================================================================== */
#define TERMCODE_DG0 260
#define SAOM_DGTC(tc) ((tc) >= TERMCODE_DG0 && (tc) < TERMCODE_DG0 + 50)
#define SAOM_STARTTC(tc) ((tc) >= TERMCODE_DG0 + 36 && (tc) <= TERMCODE_DG0 + 44)	/* protocol 61: the primary-setting effects read the period's START network */
static __thread const void *saom_tl_g0 = NULL;	/* the start graph of the period (graph_t *), set by simulate_period() / NETSTAT */
static double dg_recdeg(graph_t *g, long i) {
	long m, c = 0;
	for (m = 0; m < g->outadj[i].len; m++) if (has_edge(g, g->outadj[i].nb[m], i)) c++;
	return (double)c;
}
/* RSiena NetworkWithPrimaryEffect::primaryProperties(): the primary setting of ego = its neighbours (either direction) and their neighbours, without ego; returns its size, mark[1..n] flags it */
static long prim_set(const graph_t *gp, long ego, unsigned char *mark) {
	long m, m2, j, k, deg = 0;
	for (m = 0; m <= gp->n; m++) mark[m] = 0;
	for (m = 0; m < gp->outadj[ego].len + gp->inadj[ego].len; m++) {
		j = (m < gp->outadj[ego].len) ? gp->outadj[ego].nb[m] : gp->inadj[ego].nb[m - gp->outadj[ego].len];
		if (!mark[j]) { mark[j] = 1; deg++; }
		for (m2 = 0; m2 < gp->outadj[j].len + gp->inadj[j].len; m2++) {
			k = (m2 < gp->outadj[j].len) ? gp->outadj[j].nb[m2] : gp->inadj[j].nb[m2 - gp->outadj[j].len];
			if (!mark[k]) { mark[k] = 1; deg++; }
		}
	}
	if (mark[ego]) { mark[ego] = 0; deg--; }
	return deg;
}
static double prim_transform(int v, double x) {
	if (v == 40) return log(x + 1.0);		/* primDegActLog */
	if (v == 41 || v == 44) return sqrt(x);		/* Sqrt, DiffSqrt */
	if (v == 42) return 1.0 / (x + 1.0);		/* Inv */
	return x;
}
static double dg_value(graph_t *g, int v, const double *a, double p1, long i, long j) {
	double av = a ? a[1] : 0.0, avr = a ? a[2] : 0.0, deg, os, is, den;
	int rt = (p1 >= 2.0 - 1e-9 && p1 <= 2.0 + 1e-9);
	switch (v) {
		case 0: os = xt_mtp(g, g, 'B', 'F', i, j); den = (double)g->din[j] + (double)g->din[i] - os; return den >= 1.0 ? os / den : 0.0;
		case 1: is = xt_mtp(g, g, 'F', 'B', i, j); den = (double)g->dout[j] + (double)g->dout[i] - is; return den >= 1.0 ? is / den : 0.0;
		case 2: case 3: return v == 2 ? xt_mtp(g, g, 'F', 'F', i, j) : xt_mtp(g, g, 'F', 'B', i, j);
		case 4: return xt_mtp(g, g, 'F', 'R', i, j);
		case 5: return xt_mtp(g, g, 'F', 'E', i, j);
		case 6: return xt_mtp(g, g, 'E', 'E', i, j);
		case 7: case 8: case 9: {
			double lp = p1, change = (double)g->dout[j];
			if (v == 8) { change = sqrt(change); lp = sqrt(floor(p1 + 0.5)); }
			if (change <= lp + 1e-9) change = 0.0; else change = change - lp;
			if (v == 9 && change > 1e-9) change = 1.0;
			return change;
		}
		case 10: return xt_S((double)g->dout[i], p1) - xt_S(av, p1);
		case 11: case 12: case 13: {
			double lp = floor(p1 + 0.5);
			deg = (double)g->dout[i];
			if (deg > lp) {
				if (v == 13) return 1.0;
				return v == 12 ? sqrt(deg) - sqrt(lp) : deg - lp;
			}
			return 0.0;
		}
		case 14: return xt_recip(xt_S((double)g->dout[i], p1));
		case 15: return xt_S((double)g->din[i], p1) - xt_S(av, p1);
		case 16: return xt_recip(xt_S((double)g->din[i], p1));
		case 17: return xt_S(dg_recdeg(g, i), p1) - xt_S(avr, p1);
		case 36: case 37: case 38: case 39: case 40: case 41: case 42: case 43: case 44: {
			/* the primary-setting effects, contributions (RSiena PrimaryCompressionEffect / PrimarySettingEffect): the primary setting of the CURRENT network */
			long pdc, od = (long)g->dout[i];
			unsigned char *mk = (unsigned char *)malloc((size_t)(g->n + 1));
			double r = 0.0, lp;
			pdc = prim_set(g, i, mk);
			if (v == 36) r = mk[j] ? 1.0 : 0.0;
			else if (v == 37) {
				if (mk[j]) { lp = 0.0; if (od < pdc) { lp = ((double)(pdc - od)) / p1; if (lp < 1.0) lp = 1.0; lp = log(lp); } r = -lp; }
			}
			else if (v == 38) {
				if (!mk[j]) { lp = 0.0; if (pdc < g->n - 1) { lp = ((double)(g->n - 1 - pdc)) / p1; if (lp < 1.0) lp = 1.0; lp = log(lp); } r = -lp; }
			}
			else r = prim_transform(v, (double)pdc - ((v == 43 || v == 44) ? (double)od : 0.0));
			free(mk);
			return r;
		}
		case 33: case 34: {
			/* sameXV / sameXVInPop (sameXVInPop2 is the same function without missing values): two integer covariates packed as 64 * first + second in the attribute */
			long ci = (long)floor(a[i] / 64.0), cj2 = (long)floor(a[j] + 0.5) - 64 * (long)floor(a[j] / 64.0);
			long q, m2, h, b;
			if (v == 33) return (ci == cj2 && cj2 >= 1) ? 1.0 : 0.0;
			b = cj2;
			if (ci < 1 || b < 1) return 0.0;
			{
				double cnt = 0.0, val;
				for (q = 1; q <= g->n; q++) {
					if ((long)floor(a[q] / 64.0) != ci) continue;
					for (m2 = 0; m2 < g->outadj[q].len; m2++) {
						h = g->outadj[q].nb[m2];
						if ((long)floor(a[h] + 0.5) - 64 * (long)floor(a[h] / 64.0) == b) cnt++;
					}
				}
				val = cnt;
				if (p1 >= 3.0 - 1e-9) {
					double n1 = 0.0, n2 = 0.0;
					for (q = 1; q <= g->n; q++) {
						if ((long)floor(a[q] / 64.0) == ci) n1++;
						if ((long)floor(a[q] + 0.5) - 64 * (long)floor(a[q] / 64.0) == b) n2++;
					}
					val /= (n1 * n2);
				}
				if (fabs(p1 - 2.0) < 1e-9 || fabs(p1 - 4.0) < 1e-9) val = sqrt(val);
				return val;
			}
		}
		case 23: case 24: case 25: {
			/* outOutAss / inInAss / inOutAss with RSiena's parameter (2: square roots): the contribution of OutOut-/InIn-/InOutDegreeAssortativityEffect */
			double d, ad, nsum = 0.0;
			long m, h;
			if (v == 23) {
				d = (double)g->dout[i]; ad = (double)g->dout[j];
				for (m = 0; m < g->outadj[i].len; m++) { h = g->outadj[i].nb[m]; nsum += rt ? sqrt((double)g->dout[h]) : (double)g->dout[h]; }
				if (has_edge(g, i, j)) return rt ? (nsum - sqrt(ad)) * (sqrt(d) - sqrt(d - 1.0)) + sqrt(d) * sqrt(ad) : (nsum - ad) + d * ad;
				return rt ? nsum * (sqrt(d + 1.0) - sqrt(d)) + sqrt(d + 1.0) * sqrt(ad) : nsum + (d + 1.0) * ad;
			}
			if (v == 24) { d = (double)g->din[i]; ad = (double)g->din[j] + (has_edge(g, i, j) ? 0.0 : 1.0); }
			else { d = (double)g->din[i]; ad = (double)g->dout[j]; }
			return rt ? sqrt(d) * sqrt(ad) : d * ad;
		}
		case 20: return g->din[i] == 0 ? 1.0 : 0.0;		/* inIsDegree: the tie statistic and the contribution are 1 for an in-isolate ego */
		case 21: {
			/* inStructEq: (n - 2) * structmean - |In(i) symmetric-difference In(j)| without i and j (RSiena InStructuralEquivalenceEffect); a[3] = structmean */
			double sm = a ? a[3] : 0.0;
			double common = xt_mtp(g, g, 'B', 'F', i, j);
			return ((double)g->n - 2.0) * sm - (double)g->din[i] - (double)g->din[j] + (has_edge(g, j, i) ? 1.0 : 0.0) + (has_edge(g, i, j) ? 1.0 : 0.0) + 2.0 * common;
		}
		case 22: {
			/* denseTriads, the CONTRIBUTION (parameter 5 or 6): RSiena DenseTriadsEffect::calculateContribution() with its R/F/B tables */
			int six = (fabs(p1 - 6.0) < 1e-9);
			double rr = xt_mtp(g, g, 'R', 'R', i, j);
			if (six) return has_edge(g, j, i) ? 2.0 * rr : 0.0;
			if (has_edge(g, j, i)) return 2.0 * xt_mtp(g, g, 'R', 'F', i, j) + 2.0 * xt_mtp(g, g, 'R', 'B', i, j) + 2.0 * xt_mtp(g, g, 'F', 'R', i, j) + xt_mtp(g, g, 'B', 'R', i, j) - 6.0 * rr;
			return 2.0 * rr;
		}
		case 19: return xt_S((double)g->din[j], p1) - xt_S(av, p1);		/* inPop_dya: GenericNetworkEffect(InDegreeFunction - the average in-degree), parameter 2 = square roots */
		case 18: {
			/* outInAss with RSiena's parameter (2: square roots) - OutInDegreeAssortativityEffect::calculateContribution() */
			long m, h;
			double d = (double)g->dout[i], ain = (double)g->din[j], nsum = 0.0;
			for (m = 0; m < g->outadj[i].len; m++) { h = g->outadj[i].nb[m]; nsum += rt ? sqrt((double)g->din[h]) : (double)g->din[h]; }
			if (has_edge(g, i, j)) return rt ? (nsum - sqrt(ain)) * (sqrt(d) - sqrt(d - 1.0)) + sqrt(d) * sqrt(ain) : (nsum - ain) + d * ain;
			return rt ? nsum * (sqrt(d + 1.0) - sqrt(d)) + sqrt(d + 1.0) * sqrt(ain + 1.0) : nsum + (d + 1.0) * (ain + 1.0);
		}
	}
	(void)rt;
	return 0.0;
}
static double dg_tie(graph_t *g, int v, const double *a, double p1, long i, long j) {
	if (v == 3) return xt_mtp(g, g, 'F', 'F', i, j);
	if (v == 18) return xt_S((double)g->dout[i], p1) * xt_S((double)g->din[j], p1);
	if (v == 23) return xt_S((double)g->dout[i], p1) * xt_S((double)g->dout[j], p1);
	if (v == 24) return xt_S((double)g->din[i], p1) * xt_S((double)g->din[j], p1);
	if (v == 25) return xt_S((double)g->din[i], p1) * xt_S((double)g->dout[j], p1);
	return dg_value(g, v, a, p1, i, j);
}
/* denseTriads tie statistic summed over the ties (RSiena DenseTriadsEffect::tieStatistic() with its mark array) */
static double dg_dense_stat(graph_t *g, double p1) {
	long i, m, j, h, n = g->n, k;
	int six = (fabs(p1 - 6.0) < 1e-9);
	double tot = 0.0;
	int *mark = (int *)calloc((size_t)(n + 1), sizeof(int));
	for (i = 1; i <= n; i++) {
		for (j = 1; j <= n; j++) mark[j] = 0;
		for (m = 0; m < g->inadj[i].len; m++) mark[g->inadj[i].nb[m]] = 1;
		for (m = 0; m < g->outadj[i].len; m++) { j = g->outadj[i].nb[m]; mark[j] = (mark[j] == 0) ? 1 : mark[j] + 1; }
		for (m = 0; m < g->outadj[i].len; m++) {
			long st = 0;
			j = g->outadj[i].nb[m];
			if ((six && mark[j] == 2) || (!six && mark[j] == 1)) {
				for (k = 0; k < g->outadj[j].len; k++) { h = g->outadj[j].nb[k]; if (has_edge(g, h, j) && mark[h] == 2) st++; }
			}
			else if (!six) {
				/* the union of the out- and in-neighbours of j: h in both = reciprocated with j */
				for (k = 0; k < g->outadj[j].len; k++) {
					h = g->outadj[j].nb[k];
					if (has_edge(g, h, j)) { if (mark[h] > 0) st++; }
					else if (mark[h] == 2) st++;
				}
				for (k = 0; k < g->inadj[j].len; k++) {
					h = g->inadj[j].nb[k];
					if (!has_edge(g, j, h) && mark[h] == 2) st++;
				}
			}
			tot += (double)st;
		}
	}
	free(mark);
	return tot;
}
static double dg_stat(graph_t *g, int termcode, const double *a, double p1) {
	long k;
	double tot = 0.0;
	int v = termcode - TERMCODE_DG0;
	if (v == 22) return dg_dense_stat(g, p1);
	if (v >= 36 && v <= 44) {
		/* RSiena egoStatistic(): the primary setting of the START network, the outdegree of the current one */
		const graph_t *g0 = saom_tl_g0 ? (const graph_t *)saom_tl_g0 : g;
		unsigned char *mk0 = (unsigned char *)malloc((size_t)(g->n + 1)), *mkc = (unsigned char *)malloc((size_t)(g->n + 1));
		long i, m, outside;
		for (i = 1; i <= g->n; i++) {
			long pd0 = prim_set(g0, i, mk0), pdc = prim_set(g, i, mkc), od = (long)g->dout[i];
			outside = 0;
			for (m = 0; m < g->outadj[i].len; m++) if (!mk0[g->outadj[i].nb[m]]) outside++;
			if (v == 36) tot += (double)(od - outside);
			else if (v == 37) tot += (double)(outside - od);
			else if (v == 38) tot += -(double)outside;
			else {
				double val = (double)pd0 - ((v == 43 || v == 44) ? (double)g0->dout[i] : 0.0), add = 0.0;
				if (p1 >= 2.0 - 1e-9) add = prim_transform(v, (double)pdc - ((v == 43 || v == 44) ? (double)od : 0.0));
				tot += (prim_transform(v, val) + add) * (double)od;
			}
		}
		free(mk0); free(mkc);
		return tot;
	}
	for (k = 0; k < g->nties; k++) tot += dg_tie(g, v, a, p1, g->elist_i[k], g->elist_j[k]);
	return tot;
}

static double saom_stat_term(graph_t *g, int termcode, double *a, double p1) {
	long i, k;
	double tot = 0.0;
	if (termcode >= 4000 && termcode < 5000) { termcode -= 1000; saom_tl_sscale = saom_tl_behscale; } else if (SAOM_XTC(termcode)) saom_tl_sscale = 1.0;	/* protocol 65: the cross-network terms with the dependent behavior as the covariate (code + 1000) */
	if (SAOM_XTC(termcode)) return xt_stat(g, termcode, a, p1);
	if (SAOM_DGTC(termcode)) return dg_stat(g, termcode, a, p1);
	if (termcode >= 1000) { termcode -= 1000; saom_tl_sscale = saom_tl_behscale; } else saom_tl_sscale = 1.0;
	if (SAOM_CZTC(termcode)) {
		int v = termcode - TERMCODE_CZ0;
		if (v == 0 || v == 2 || v >= 19) { for (i = 1; i <= g->n; i++) tot += cz_ego(g, v, a, p1, i); return tot; }
		if (v == 3) { for (i = 1; i <= g->n; i++) tot += cz_indties_ego(g, a, i); return tot; }
		for (k = 0; k < g->nties; k++) tot += cz_tie(g, v, a, p1, g->elist_i[k], g->elist_j[k]);
		return tot;
	}
	if (SAOM_CTTC(termcode)) {
		int v = termcode - TERMCODE_CT0;
		if (v < 9) { for (k = 0; k < g->nties; k++) tot += ct_tieval(v, a[g->elist_i[k]], a[g->elist_j[k]], p1); return tot; }
		for (i = 1; i <= g->n; i++) tot += ct_egostat(v, a[i], g->dout[i]);
		return tot;
	}
	if (SAOM_DFTC(termcode)) {
		int v = termcode - TERMCODE_DF0;
		if (v == 6) {
			double D = (double)g->nties;
			return D * (D / ((a && a[1] > 0.5) ? a[1] : (double)g->n) - p1);
		}
		for (k = 0; k < g->nties; k++) tot += df_tie(g, v, p1, g->elist_i[k], g->elist_j[k]);
		return tot;
	}
	if (SAOM_CXTC(termcode)) {
		for (k = 0; k < g->nties; k++) tot += cx_tie(g, termcode - TERMCODE_CX0, a, p1, g->elist_i[k], g->elist_j[k]);
		return tot;
	}
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
		case TERMCODE_ABSDIFFX:
			for (k = 0; k < g->nties; k++) tot += fabs(a[g->elist_j[k]] - a[g->elist_i[k]]);
			return tot;
		case TERMCODE_EGOXALTX:
			for (k = 0; k < g->nties; k++) tot += a[g->elist_i[k]] * a[g->elist_j[k]];
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
		case TERMCODE_DIFFX: case TERMCODE_HIGHER: case TERMCODE_EGOSQX: case TERMCODE_ALTSQX: case TERMCODE_SAMEXRECIP: case TERMCODE_SIMRECIPX:
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				if (cov2_isrecip(termcode) && !has_edge(g, ej, ei)) continue;
				tot += cov2_val(termcode, a[ei], a[ej], p1);
			}
			return tot;
		case TERMCODE_INPOP:
			for (i = 1; i <= g->n; i++) tot += (double)g->din[i] * (double)g->din[i];
			return tot;
		case TERMCODE_OUTPOPL:
		case TERMCODE_INACTL:
			for (i = 1; i <= g->n; i++) tot += (double)g->dout[i] * (double)g->din[i];
			return tot;
		case TERMCODE_OUTACTSQRT:
			for (i = 1; i <= g->n; i++) tot += pow((double)g->dout[i], 1.5);
			return tot;
		case TERMCODE_OUTTRUNC: case TERMCODE_OUTMORE: case TERMCODE_OUTTHRESHOLD: case TERMCODE_OUTINV: case TERMCODE_OUTSQINV:
			for (i = 1; i <= g->n; i++) tot += saom_degfun(termcode, (double)g->dout[i], p1);
			return tot;
		case TERMCODE_GWDSPFF: case TERMCODE_GWDSPFB:
			return saom_gwdsp_stat(g, p1, termcode == TERMCODE_GWDSPFB);
		case TERMCODE_GWESPFB: case TERMCODE_GWESPBF: case TERMCODE_GWESPBB: case TERMCODE_GWESPRR:
			for (k = 0; k < g->nties; k++) tot += saom_gwesp_var(g, termcode, p1, g->elist_i[k], g->elist_j[k]);
			return tot;
		case TERMCODE_NBRDIST2: case TERMCODE_NBRDIST2TWICE:
			return saom_nbrdist2_stat(g, termcode == TERMCODE_NBRDIST2 ? 1 : 2);
		case TERMCODE_CYCLE4SQRT:
			for (k = 0; k < g->nties; k++) tot += 0.5 * sqrt((double)pair_cycle4_threepaths(g, g->elist_i[k], g->elist_j[k]));
			return tot;
		case TERMCODE_BETWEEN:
			for (k = 0; k < g->nties; k++) tot += saom_between_tie(g, g->elist_i[k], g->elist_j[k]);
			return tot;
		case TERMCODE_RECIPOP: case TERMCODE_RECIPOPSQRT:
			for (i = 1; i <= g->n; i++) { double rd = (double)saom_recdeg(g, i); tot += (double)g->din[i] * (termcode == TERMCODE_RECIPOPSQRT ? sqrt(rd) : rd); }
			return tot;
		case TERMCODE_RECIACT: case TERMCODE_RECIACTSQRT:
			for (i = 1; i <= g->n; i++) { double rd = (double)saom_recdeg(g, i); tot += (double)g->dout[i] * (termcode == TERMCODE_RECIACTSQRT ? sqrt(rd) : rd); }
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
		case TERMCODE_ANTIISO:						// stat_saom_antiiso(): #{i : indegree(i)>=1 and outdegree(i)<=0}
			for (i = 1; i <= g->n; i++) tot += (g->din[i] >= 1 && g->dout[i] <= 0) ? 1.0 : 0.0;
			return tot;
		case TERMCODE_ISOLATEPOP:					// stat_saom_isolatepop(): #{j : indegree(j)==1 and outdegree(j)==0}
			for (i = 1; i <= g->n; i++) tot += (g->din[i] == 1 && g->dout[i] == 0) ? 1.0 : 0.0;
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
		case TERMCODE_SIMCOV:						// stat_saom_simcov(): sum over ties of 1-|attr[ego]-attr[alter]|/range - simMean (attr arrives as x/range, p1 = simMean)
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				tot += 1.0 - fabs(a[ei] - a[ej]) - p1;	/* protocol 9: a = x/range, p1 = similarity mean */
			}
			return tot;
		case TERMCODE_BEHEGOX:
			for (k = 0; k < g->nties; k++) tot += a[g->elist_i[k]] - p1;
			return tot;
		case TERMCODE_BEHALTX:
			for (k = 0; k < g->nties; k++) tot += a[g->elist_j[k]] - p1;
			return tot;
		case TERMCODE_BEHEGOPLUSALT:
			for (k = 0; k < g->nties; k++) tot += a[g->elist_i[k]] + a[g->elist_j[k]] - 2.0 * p1;
			return tot;
		case TERMCODE_BEHSIM:						// stat_saom_behsim(): sum over ties of 1-|z[ego]-z[alter]|/range - simMean
			for (k = 0; k < g->nties; k++) {
				long ei = g->elist_i[k], ej = g->elist_j[k];
				tot += 1.0 - fabs(a[ei] - a[ej]) / saom_behsim_range - p1;
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
			if (!g->outadj || !g->inadj) {
				for (k = 0; k < g->nties; k++) tot += (double)pair_cycle4_threepaths(g, g->elist_i[k], g->elist_j[k]);
			}
			else {
				double *c4 = (double *)calloc((size_t)(g->n + 1), sizeof(double));
				long ii, mm;
				for (ii = 1; ii <= g->n; ii++) {
					if (g->outadj[ii].len == 0) continue;
					memset(c4, 0, (size_t)(g->n + 1) * sizeof(double));
					batch_cycle4(g, ii, c4);
					for (mm = 0; mm < g->outadj[ii].len; mm++) tot += c4[g->outadj[ii].nb[mm]];
				}
				free(c4);
			}
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
	if (termcode >= 4000 && termcode < 5000) { termcode -= 1000; saom_tl_sscale = saom_tl_behscale; } else if (SAOM_XTC(termcode)) saom_tl_sscale = 1.0;	/* protocol 65: the cross-network terms with the dependent behavior as the covariate (code + 1000) */
	if (SAOM_XTC(termcode)) {
		double v2 = xt_value(g, termcode - TERMCODE_XT0, a, p1, i, j);
		return ij_exists ? -v2 : v2;
	}
	if (SAOM_DGTC(termcode)) {
		double v2 = dg_value(g, termcode - TERMCODE_DG0, a, p1, i, j);
		return ij_exists ? -v2 : v2;
	}
	if (termcode >= 1000) { termcode -= 1000; saom_tl_sscale = saom_tl_behscale; } else saom_tl_sscale = 1.0;
	if (SAOM_CZTC(termcode)) {
		double v2 = cz_value(g, termcode - TERMCODE_CZ0, a, p1, i, j);
		return ij_exists ? -v2 : v2;
	}
	if (SAOM_CXTC(termcode)) {
		double v = cx_value(g, termcode - TERMCODE_CX0, a, p1, i, j);
		return ij_exists ? -v : v;
	}
	if (SAOM_DFTC(termcode)) {
		double v = df_value(g, termcode - TERMCODE_DF0, p1, i, j, a);
		return ij_exists ? -v : v;
	}
	if (SAOM_CTTC(termcode)) {
		double v = ct_value(g, termcode - TERMCODE_CT0, a, p1, i, j, ij_exists);
		return ij_exists ? -v : v;
	}
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
		case TERMCODE_ABSDIFFX: {
			double v = fabs(a[j] - a[i]);
			return ij_exists ? -v : v;
		}
		case TERMCODE_EGOXALTX: {
			double v = a[i] * a[j];
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
		case TERMCODE_DIFFX: case TERMCODE_HIGHER: case TERMCODE_EGOSQX: case TERMCODE_ALTSQX: case TERMCODE_SAMEXRECIP: case TERMCODE_SIMRECIPX: {
			double v = cov2_val(termcode, a[i], a[j], p1);
			if (cov2_isrecip(termcode) && !has_edge(g, j, i)) v = 0.0;
			return ij_exists ? -v : v;
		}
		case TERMCODE_INPOP: {
			double d = (double)g->din[j];
			return ij_exists ? -d : d + 1.0;
		}
		case TERMCODE_OUTPOPL: {
			double d = (double)g->dout[j];
			return ij_exists ? -d : d;
		}
		case TERMCODE_INACTL: {
			double d = (double)g->din[i];
			return ij_exists ? -d : d;
		}
		case TERMCODE_OUTACTSQRT: {
			double d = (double)g->dout[i];
			return ij_exists ? -(pow(d, 1.5) - pow(d - 1.0, 1.5)) : (pow(d + 1.0, 1.5) - pow(d, 1.5));
		}
		case TERMCODE_RECIPOP: case TERMCODE_RECIPOPSQRT: case TERMCODE_RECIACT: case TERMCODE_RECIACTSQRT:
			return saom_reci_change(g, termcode, i, j, ij_exists);
		case TERMCODE_GWDSPFF: case TERMCODE_GWDSPFB:
			return saom_gwdsp_change(g, i, j, p1, termcode == TERMCODE_GWDSPFB, ij_exists);
		case TERMCODE_GWESPFB: case TERMCODE_GWESPBF: case TERMCODE_GWESPBB: case TERMCODE_GWESPRR: {
			double dg = saom_gwesp_var(g, termcode, p1, i, j);
			return ij_exists ? -dg : dg;
		}
		case TERMCODE_NBRDIST2: case TERMCODE_NBRDIST2TWICE:
			return saom_nbrdist2_change(g, i, j, termcode == TERMCODE_NBRDIST2 ? 1 : 2, ij_exists);
		case TERMCODE_CYCLE4SQRT:
			return saom_cycle4sqrt_change(g, i, j, ij_exists);
		case TERMCODE_BETWEEN: {
			double cb = saom_between_tie(g, i, j);
			return ij_exists ? -cb : cb;
		}
		case TERMCODE_OUTTRUNC: case TERMCODE_OUTMORE: case TERMCODE_OUTTHRESHOLD: case TERMCODE_OUTINV: case TERMCODE_OUTSQINV: {
			double dwo = (double)g->dout[i] - (ij_exists ? 1.0 : 0.0);
			double diff = saom_degfun(termcode, dwo + 1.0, p1) - saom_degfun(termcode, dwo, p1);
			return ij_exists ? -diff : diff;
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
			double d = 1.0 - fabs(a[i] - a[j]) - p1;
			return ij_exists ? -d : d;
		}
		case TERMCODE_BEHEGOX: {
			double d = a[i] - p1;
			return ij_exists ? -d : d;
		}
		case TERMCODE_BEHALTX: {
			double d = a[j] - p1;
			return ij_exists ? -d : d;
		}
		case TERMCODE_BEHEGOPLUSALT: {
			double d = a[i] + a[j] - 2.0 * p1;
			return ij_exists ? -d : d;
		}
		case TERMCODE_BEHSIM: {
			double d = 1.0 - fabs(a[i] - a[j]) / saom_behsim_range - p1;
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
		case TERMCODE_ANTIISO:						// change_saom_antiiso(): mechanical port
		case TERMCODE_ISOLATEPOP: {					// change_saom_isolatepop(): mechanical port (the same expression)
			long d = g->din[j];
			int cond = ij_exists ? (d <= 1) : (d == 0);
			return (cond && g->dout[j] <= 0) ? (ij_exists ? -1.0 : 1.0) : 0.0;
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
		/* protocol 12: RSiena's tie statistics of the degree effects */
		case TERMCODE_INDEGPOP: return sqrt((double)g->din[alter]);
		case TERMCODE_OUTPOP: return sqrt((double)g->dout[alter]);
		case TERMCODE_OUTACTIVITY: return (double)g->dout[ego];
		case TERMCODE_INACTIVITY: return sqrt((double)g->din[ego]);
		case TERMCODE_INPOP: return (double)g->din[alter];
		case TERMCODE_OUTPOPL: return (double)g->dout[alter];
		case TERMCODE_INACTL: return (double)g->din[ego];
		case TERMCODE_OUTACTSQRT: return sqrt((double)g->dout[ego]);
		case TERMCODE_ISOLATEPOP: return (g->dout[alter] == 0 && g->din[alter] == 1) ? 1.0 : 0.0;
		case TERMCODE_RECIPROCITY: return has_edge(g, alter, ego) ? 1.0 : 0.0;
		case TERMCODE_NODEMATCH: return (a[ego] == a[alter]) ? 1.0 : 0.0;
		case TERMCODE_NODECOV: return a[ego] + a[alter];
		case TERMCODE_NODEICOV: return a[alter];
		case TERMCODE_NODEOCOV: return a[ego];
		/* protocol 12: RSiena's tieStatistic() - transTrip the two-paths
		   ego -> h -> alter, cycle3 a third of the two-paths alter -> h ->
		   ego (before: in-shared partners and all of the two-paths; only
		   their sum over all ties was right) */
		case TERMCODE_TRANSTRIP: return (double)pair_otp(g, ego, alter);
		case TERMCODE_TRANSMEDTRIP: return (double)pair_isp(g, ego, alter);
		case TERMCODE_CYCLE3: return (double)pair_otp(g, alter, ego) / 3.0;
		case TERMCODE_SIMCOV: return 1.0 - fabs(a[ego] - a[alter]) - p1;
		case TERMCODE_BEHSIM: return 1.0 - fabs(a[ego] - a[alter]) / saom_behsim_range - p1;
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
	return 0.0;		// other node-level termcodes: rejected upstream by nwsaom.ado's interact() check (RSiena's rule plus the effects it cannot evaluate)
}

/* protocol 17: RSiena's BalanceEffect::tieStatistic() with missing data: the sum over h of (b0 - |x_ih - x_jh|) runs
   only over actors h that are not ego/alter and have no missing tie from ego or from alter (in either wave of the
   period); mh = the period's missing dyads (NULL = none) */
static double saom_balance_tie_masked(graph_t *g, double b0, long ego, long alter, dyadht_t *mh) {
	long h, dv, nvalid = 0, ndiff = 0;
	for (h = 1; h <= g->n; h++) {
		if (h == ego || h == alter) continue;
		if (mh && (ht_get(mh, dyadkey(g, ego, h), &dv) || ht_get(mh, dyadkey(g, alter, h), &dv))) continue;
		nvalid++;
		if (has_edge(g, ego, h) != has_edge(g, alter, h)) ndiff++;
	}
	return (double)nvalid * b0 - (double)ndiff;
}

/* ix_stat() below (formerly saom_stat_interact()): TERMCODE_INTERACT2's own global-statistic
   computation - sum over the network's ACTUAL EXISTING ties of the
   product of the two components' own saom_tie_stat() values, matching
   RSiena's real NetworkInteractionEffect::tieStatistic() (a product),
   summed via the same NetworkEffect::egoStatistic()/statistic() shape
   every other termcode's own saom_stat_term() case already uses. */
/* protocol 12: RSiena's NetworkInteractionEffect::egoStatistic(): when
   every component but one is an ego effect (egoX, density), the ego's
   statistic is the product of their values and the other component's
   egoStatistic (for outIso: outdegree 0); otherwise the sum over the
   ego's ties of the product of the tie statistics */
static int ix_isego(int code) { return code == TERMCODE_NODEOCOV || code == TERMCODE_OUTDEGREE; }
static double ix_stat(graph_t *g, int nc, const int *codes, double **as, const double *p1s) {
	long e, k;
	int c, nego = 0, ne = 0;
	double tot = 0.0;
	for (c = 0; c < nc; c++) { if (ix_isego(codes[c])) nego++; else ne = c; }
	if (nego == nc - 1) {
		for (e = 1; e <= g->n; e++) {
			double se = 1.0, v = 0.0;
			for (c = 0; c < nc; c++) if (c != ne) se *= saom_tie_stat(g, codes[c], as[c], p1s[c], e, e);
			if (se == 0.0) continue;
			if (codes[ne] == TERMCODE_OUTISO) v = (g->dout[e] == 0) ? 1.0 : 0.0;
			else if (codes[ne] == TERMCODE_ISOLATENET) v = (g->dout[e] == 0 && g->din[e] == 0) ? 1.0 : 0.0;
			else {
				for (k = 0; k < g->nties; k++) {
					if (g->elist_i[k] != e) continue;
					v += saom_tie_stat(g, codes[ne], as[ne], p1s[ne], e, g->elist_j[k]);
				}
			}
			tot += se * v;
		}
		return tot;
	}
	for (k = 0; k < g->nties; k++) {
		long ei = g->elist_i[k], ej = g->elist_j[k];
		double v = 1.0;
		for (c = 0; c < nc; c++) v *= saom_tie_stat(g, codes[c], as[c], p1s[c], ei, ej);
		tot += v;
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
/* protocol 49: network effects of a dyadic covariate W (RSiena WWX, cyWWX, InWWX, OutWWX, WXX, XWX, XWX1, XWX2, XXW; WWXClosureEffect, WXXClosureEffect,
   XWXClosureEffect, XXWClosureEffect). W arrives as n attribute columns, W[i][j] = attrs[base + i - 1][j] (raw: missing and the diagonal 0, never centred).
   Contribution of a tie i -> j (the value with the tie absent, negated for an existing tie) and the tie statistic, as RSiena: WXX and the closure
   effects XWX1 / XWX2 differ in contribution but share the tie statistic of the two-path form. Codes 250..258. */
#define TERMCODE_DW0 250
#define SAOM_DWTC(tc) ((tc) >= TERMCODE_DW0 && (tc) < TERMCODE_DW0 + 9)
static double dw_sum(graph_t *g, int v, double **attrs, int base, long i, long j, int forstat) {
	long n = g->n, h, m;
	double s = 0.0;
	#define DW(a, b) (attrs[base + (a) - 1][(b)])
	if (v <= 3) {
		int out1 = (v == 0 || v == 3), out2 = (v == 0 || v == 2);
		for (h = 1; h <= n; h++) {
			double wa = out1 ? DW(i, h) : DW(h, i);
			double wb;
			if (wa == 0.0) continue;
			wb = out2 ? DW(h, j) : DW(j, h);
			s += wa * wb;
		}
		return s;
	}
	if (v == 4) {
		for (h = 1; h <= n; h++) {
			double wa = DW(i, h);
			if (wa != 0.0 && has_edge(g, h, j)) s += wa;
		}
		return s;
	}
	if (v >= 5 && v <= 7) {
		int tp = (v == 5 || v == 6 || forstat), ins = (v == 5 || v == 7) && !forstat;
		for (m = 0; m < g->outadj[i].len; m++) {
			h = g->outadj[i].nb[m];
			if (tp) s += DW(h, j);
			if (ins) s += DW(j, h);
		}
		return s;
	}
	/* XXW */
	for (m = 0; m < g->inadj[i].len; m++) { h = g->inadj[i].nb[m]; s += DW(h, j); }
	if (!forstat) for (h = 1; h <= n; h++) {
		double wa = DW(i, h);
		if (wa != 0.0 && has_edge(g, j, h)) s += wa;
	}
	#undef DW
	return s;
}
static double dw_change(graph_t *g, int tc, double **attrs, int base, long i, long j, int ij_exists) {
	double c = dw_sum(g, tc - TERMCODE_DW0, attrs, base, i, j, 0);
	return ij_exists ? -c : c;
}
static double dw_stat(graph_t *g, int tc, double **attrs, int base) {
	double tot = 0.0;
	long kk;
	for (kk = 0; kk < g->nties; kk++) tot += dw_sum(g, tc - TERMCODE_DW0, attrs, base, g->elist_i[kk], g->elist_j[kk], 1);
	return tot;
}

static void ix3_slots(int k, int *attridx, double *p1, int *sA, int *sB, int *sC) {
	long code = (long)(p1[k] + 0.5);
	*sA = attridx[k] - 1;
	*sB = (int)(code % 1000) - 1;
	*sC = (int)(code / 1000) - 1;
}

static double saom_eval_change(int k, int *termcodes, int *attridx, double *p1, double **attrs,
	graph_t *g, long i, long j, int ij_exists, double *tt_arr, double *c3_arr) {
	if (termcodes[k] == TERMCODE_INTERACT3) {
		int sA, sB, sC;
		double *aA, *aB, *aC;
		ix3_slots(k, attridx, p1, &sA, &sB, &sC);
		aA = (attridx[sA] > 0) ? attrs[attridx[sA] - 1] : NULL;
		aB = (attridx[sB] > 0) ? attrs[attridx[sB] - 1] : NULL;
		aC = (attridx[sC] > 0) ? attrs[attridx[sC] - 1] : NULL;
		return saom_change_term(g, termcodes[sA], aA, p1[sA], i, j, ij_exists, tt_arr, c3_arr)
			* saom_change_term(g, termcodes[sB], aB, p1[sB], i, j, ij_exists, tt_arr, c3_arr)
			* saom_change_term(g, termcodes[sC], aC, p1[sC], i, j, ij_exists, tt_arr, c3_arr);
	}
	if (termcodes[k] == TERMCODE_INTERACT2) {
		int subA = attridx[k] - 1, subB = (int)p1[k] - 1;
		double *aA = (attridx[subA] > 0) ? attrs[attridx[subA] - 1] : NULL;
		double *aB = (attridx[subB] > 0) ? attrs[attridx[subB] - 1] : NULL;
		double cvA = saom_change_term(g, termcodes[subA], aA, p1[subA], i, j, ij_exists, tt_arr, c3_arr);
		double cvB = saom_change_term(g, termcodes[subB], aB, p1[subB], i, j, ij_exists, tt_arr, c3_arr);
		/* RSiena: product of the components' CREATION contributions,
		   negated once for a withdrawal; the components' changes are
		   signed, so their product is negated again when the tie exists
		   (before protocol 10 a withdrawal had the wrong sign) */
		return (ij_exists ? -1.0 : 1.0) * cvA * cvB;
	}
	if (SAOM_DWTC(termcodes[k])) return dw_change(g, termcodes[k], attrs, attridx[k] - 1, i, j, ij_exists);
	if (termcodes[k] == TERMCODE_DYADCOV || termcodes[k] == TERMCODE_DYADCOVRECIP) {
		double d = attrs[attridx[k] - 1 + (i - 1)][j];
		if (termcodes[k] == TERMCODE_DYADCOVRECIP && !has_edge(g, j, i)) return 0.0;
		return ij_exists ? -d : d;
	}
	if (termcodes[k] == 149) {
		/* masked higher: a pair with a missing value counts 0.5 */
		double *a = attrs[attridx[k] - 1], *m = attrs[attridx[k]];
		double v = (m[i] != 0.0 || m[j] != 0.0) ? 0.5 : cov2_val(TERMCODE_HIGHER, a[i], a[j], 0.0);
		return ij_exists ? -v : v;
	}
	{
		double *a = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
		int tc = termcodes[k], base = saom_masked_base(tc);
		return saom_change_term(g, base ? base : tc, a, p1[k], i, j, ij_exists, tt_arr, c3_arr);
	}
}

static double saom_eval_stat(int k, int *termcodes, int *attridx, double *p1, double **attrs, graph_t *g) {
	if (termcodes[k] == TERMCODE_INTERACT3) {
		int sA, sB, sC, codes[3];
		double *as[3], p1s[3];
		ix3_slots(k, attridx, p1, &sA, &sB, &sC);
		codes[0] = termcodes[sA]; codes[1] = termcodes[sB]; codes[2] = termcodes[sC];
		as[0] = (attridx[sA] > 0) ? attrs[attridx[sA] - 1] : NULL;
		as[1] = (attridx[sB] > 0) ? attrs[attridx[sB] - 1] : NULL;
		as[2] = (attridx[sC] > 0) ? attrs[attridx[sC] - 1] : NULL;
		p1s[0] = p1[sA]; p1s[1] = p1[sB]; p1s[2] = p1[sC];
		return ix_stat(g, 3, codes, as, p1s);
	}
	if (termcodes[k] == TERMCODE_INTERACT2) {
		int subA = attridx[k] - 1, subB = (int)p1[k] - 1;
		int codes[2];
		double *as[2], p1s[2];
		codes[0] = termcodes[subA]; codes[1] = termcodes[subB];
		as[0] = (attridx[subA] > 0) ? attrs[attridx[subA] - 1] : NULL;
		as[1] = (attridx[subB] > 0) ? attrs[attridx[subB] - 1] : NULL;
		p1s[0] = p1[subA]; p1s[1] = p1[subB];
		return ix_stat(g, 2, codes, as, p1s);
	}
	if (SAOM_DWTC(termcodes[k])) return dw_stat(g, termcodes[k], attrs, attridx[k] - 1);
	if (termcodes[k] == TERMCODE_DYADCOV || termcodes[k] == TERMCODE_DYADCOVRECIP) {
		double tot = 0.0;
		long kk;
		for (kk = 0; kk < g->nties; kk++) {
			long ei = g->elist_i[kk], ej = g->elist_j[kk];
			if (termcodes[k] == TERMCODE_DYADCOVRECIP && !has_edge(g, ej, ei)) continue;
			tot += attrs[attridx[k] - 1 + (ei - 1)][ej];
		}
		return tot;
	}
	if (saom_masked_base(termcodes[k])) {
		double *a = attrs[attridx[k] - 1];
		double *m = attrs[attridx[k]];
		double tot = 0.0;
		long kk, ii;
		switch (termcodes[k]) {
			case TERMCODE_NODEMATCH_M:
				for (kk = 0; kk < g->nties; kk++) {
					long ei = g->elist_i[kk], ej = g->elist_j[kk];
					if (m[ei] == 0.0 && m[ej] == 0.0 && a[ei] == a[ej]) tot += 1.0;
				}
				return tot;
			case TERMCODE_NODECOV_M:
				for (ii = 1; ii <= g->n; ii++) if (m[ii] == 0.0) tot += a[ii] * ((double)g->din[ii] + (double)g->dout[ii]);
				return tot;
			case TERMCODE_NODEICOV_M:
				for (ii = 1; ii <= g->n; ii++) if (m[ii] == 0.0) tot += a[ii] * (double)g->din[ii];
				return tot;
			case TERMCODE_NODEOCOV_M:
				for (ii = 1; ii <= g->n; ii++) if (m[ii] == 0.0) tot += a[ii] * (double)g->dout[ii];
				return tot;
			case 142: case 143: case 148: case 149: case 150: case 151: case 152: case 153: {
				int bc = termcodes[k] - 100;
				for (kk = 0; kk < g->nties; kk++) {
					long ei = g->elist_i[kk], ej = g->elist_j[kk];
					/* RSiena skips a tie when the value its statistic reads is missing: egoSqX the ego's, altSqX the alter's,
					   the others either (higher and simRecipX use the imputed values and have no masked variant) */
					if (bc == TERMCODE_HIGHER) {
						/* RSiena: a pair with a missing value counts as a tie (0.5) */
						if (cov2_isrecip(bc) && !has_edge(g, ej, ei)) continue;
						tot += (m[ei] != 0.0 || m[ej] != 0.0) ? 0.5 : cov2_val(bc, a[ei], a[ej], p1[k]);
						continue;
					}
					if (bc == TERMCODE_EGOSQX ? (m[ei] != 0.0) : (bc == TERMCODE_ALTSQX ? (m[ej] != 0.0) : (m[ei] != 0.0 || m[ej] != 0.0))) continue;
					if (cov2_isrecip(bc) && !has_edge(g, ej, ei)) continue;
					if (bc == TERMCODE_ABSDIFFX) tot += fabs(a[ej] - a[ei]);
					else if (bc == TERMCODE_EGOXALTX) tot += a[ei] * a[ej];
					else tot += cov2_val(bc, a[ei], a[ej], p1[k]);
				}
				return tot;
			}
			default:				/* TERMCODE_SIMCOV_M: a = x / range, p1 = simMean */
				for (kk = 0; kk < g->nties; kk++) {
					long ei = g->elist_i[kk], ej = g->elist_j[kk];
					if (m[ei] == 0.0 && m[ej] == 0.0) tot += 1.0 - fabs(a[ei] - a[ej]) - p1[k];
				}
				return tot;
		}
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
static void saom_mark_need_flags(int tc, int *need_adj, int *need_transtrip, int *need_cycle3);

/* need flags of every term, interaction components included */
static void saom_model_need_flags(int nterms, int *termcodes, int *attridx, double *p1, int *need_adj, int *need_transtrip, int *need_cycle3) {
	int i;
	for (i = 0; i < nterms; i++) {
		if (termcodes[i] == TERMCODE_INTERACT2) {
			int subA = attridx[i] - 1, subB = (int)p1[i] - 1;
			saom_mark_need_flags((subA >= 0 && subA < nterms) ? termcodes[subA] : -1, need_adj, need_transtrip, need_cycle3);
			saom_mark_need_flags((subB >= 0 && subB < nterms) ? termcodes[subB] : -1, need_adj, need_transtrip, need_cycle3);
		}
		else if (termcodes[i] == TERMCODE_INTERACT3) {
			int sA, sB, sC;
			ix3_slots(i, attridx, p1, &sA, &sB, &sC);
			saom_mark_need_flags((sA >= 0 && sA < nterms) ? termcodes[sA] : -1, need_adj, need_transtrip, need_cycle3);
			saom_mark_need_flags((sB >= 0 && sB < nterms) ? termcodes[sB] : -1, need_adj, need_transtrip, need_cycle3);
			saom_mark_need_flags((sC >= 0 && sC < nterms) ? termcodes[sC] : -1, need_adj, need_transtrip, need_cycle3);
		}
		else saom_mark_need_flags(termcodes[i], need_adj, need_transtrip, need_cycle3);
	}
}

static void saom_mark_need_flags(int tc, int *need_adj, int *need_transtrip, int *need_cycle3) {
	if (tc >= 1000) tc -= 1000;
	if (tc == TERMCODE_TRANSTRIP || tc == TERMCODE_CYCLE3) *need_adj = 1;
	if (tc == TERMCODE_TRANSTRIP) *need_transtrip = 1;
	if (tc == TERMCODE_CYCLE3) *need_cycle3 = 1;
	if (tc == TERMCODE_TRANSRECTRIP || tc == TERMCODE_OUTOUTASS || tc == TERMCODE_OUTINASS || tc == TERMCODE_TRANSMEDTRIP) *need_adj = 1;
	if (tc == TERMCODE_CYCLE4 || SAOM_CXTC(tc) || tc == TERMCODE_DF0 + 7 || SAOM_CZTC(tc)) *need_adj = 1;
	if (tc == TERMCODE_GWDSPFF || tc == TERMCODE_GWDSPFB || tc == TERMCODE_BETWEEN) *need_adj = 1;
	if ((tc >= TERMCODE_GWESPFB && tc <= TERMCODE_CYCLE4SQRT)) *need_adj = 1;
	if (tc == TERMCODE_RECIPOP || tc == TERMCODE_RECIPOPSQRT || tc == TERMCODE_RECIACT || tc == TERMCODE_RECIACTSQRT) *need_adj = 1;
	if (tc == TERMCODE_GWESP || tc == TERMCODE_TRANSTIES || tc == TERMCODE_BALANCE || SAOM_DWTC(tc) || SAOM_XTC(tc) || (tc >= 4000 && tc < 5000) || SAOM_DGTC(tc)) *need_adj = 1;
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
/* flags (average, alterPop, egoPop, hi, lo) of the similarity family */
static void beh_sim_flags(int tc, int *f) {
	f[0] = f[1] = f[2] = f[3] = f[4] = 0;
	switch (tc) {
		case TERMCODE_BEH_AVSIM: f[0] = 1; f[3] = 1; f[4] = 1; break;
		case TERMCODE_BEH_TOTSIM: f[3] = 1; f[4] = 1; break;
		case TERMCODE_BEH_AVATTHIGHER: f[0] = 1; f[3] = 1; break;
		case TERMCODE_BEH_AVATTLOWER: f[0] = 1; f[4] = 1; break;
		case TERMCODE_BEH_TOTATTHIGHER: f[3] = 1; break;
		case TERMCODE_BEH_TOTATTLOWER: f[4] = 1; break;
		case TERMCODE_BEH_AVSIMPOPALT: f[0] = 1; f[1] = 1; f[3] = 1; f[4] = 1; break;
		case TERMCODE_BEH_TOTSIMPOPALT: f[1] = 1; f[3] = 1; f[4] = 1; break;
		case TERMCODE_BEH_AVSIMPOPEGO: f[0] = 1; f[2] = 1; f[3] = 1; f[4] = 1; break;
	}
}
static long beh_recdeg(graph_t *g, long j) {
	long cnt = 0, m;
	for (m = 0; m < g->outadj[j].len; m++) if (has_edge(g, g->outadj[j].nb[m], j)) cnt++;
	return cnt;
}
/* statistic of one actor (new effects) */
static double beh_new_ego_stat(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i) {
	long k, nb = g->outadj[i].len;
	double zi = bv[i] - mean, st, s;
	switch (tc) {
		case TERMCODE_BEH_INDEG: return zi * (double)g->din[i];
		case TERMCODE_BEH_OUTDEG: return zi * (double)g->dout[i];
		case TERMCODE_BEH_RECIPDEG: return zi * (double)beh_recdeg(g, i);
		case TERMCODE_BEH_ISOLATE: return g->din[i] == 0 ? zi : 0.0;
		case TERMCODE_BEH_OUTISOLATE: return g->dout[i] == 0 ? zi : 0.0;
		case TERMCODE_BEH_TOTALT: case TERMCODE_BEH_AVALTPOP: case TERMCODE_BEH_TOTALTPOP: {
			int pop = (tc != TERMCODE_BEH_TOTALT), div = (tc == TERMCODE_BEH_AVALTPOP);
			if (nb == 0) return 0.0;
			s = 0.0;
			for (k = 0; k < nb; k++) { long j = g->outadj[i].nb[k]; s += (bv[j] - mean) * (pop ? (double)g->din[j] : 1.0); }
			s *= zi;
			if (div) s /= (double)nb;
			return s;
		}
		case TERMCODE_BEH_MAXALT: case TERMCODE_BEH_MINALT: {
			int minim = (tc == TERMCODE_BEH_MINALT);
			if (nb == 0) return 0.0;
			st = minim ? 1000.0 : -1000.0;
			for (k = 0; k < nb; k++) { double v = bv[g->outadj[i].nb[k]] - mean; if (minim ? v < st : v > st) st = v; }
			return st * zi;
		}
		case TERMCODE_BEH_AVRECALT: case TERMCODE_BEH_TOTRECALT: {
			long cnt = 0;
			s = 0.0;
			for (k = 0; k < nb; k++) { long j = g->outadj[i].nb[k]; if (has_edge(g, j, i)) { s += bv[j] - mean; cnt++; } }
			if (cnt == 0) return 0.0;
			s *= zi;
			if (tc == TERMCODE_BEH_AVRECALT) s /= (double)cnt;
			return s;
		}
		default: {
			int f[5];
			long cnt = 0;
			double totc = 0.0, dif;
			beh_sim_flags(tc, f);
			st = 0.0;
			for (k = 0; k < nb; k++) {
				long j = g->outadj[i].nb[k];
				dif = (bv[j] - mean) - zi;
				if (f[1]) dif *= (double)g->din[j];
				if (f[3] && dif > 0) st += dif;
				if (f[4] && dif < 0) st -= dif;
				cnt++;
				if (f[1]) totc += (double)g->din[j];
			}
			if (!f[1]) totc = (double)cnt;
			st = totc - st / range;
			if (f[3] && f[4]) st -= totc * simMean;
			if (f[0] && cnt > 0) st /= (double)cnt;
			if (f[2]) st *= (double)g->din[i];
			return st;
		}
	}
}
/* RSiena's calculateChangeContribution() (new effects) */
static double beh_new_change(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i, double diff) {
	long k, nb = g->outadj[i].len;
	double s, ch;
	switch (tc) {
		case TERMCODE_BEH_INDEG: return diff * (double)g->din[i];
		case TERMCODE_BEH_OUTDEG: return diff * (double)g->dout[i];
		case TERMCODE_BEH_RECIPDEG: return diff * (double)beh_recdeg(g, i);
		case TERMCODE_BEH_ISOLATE: return g->din[i] == 0 ? diff : 0.0;
		case TERMCODE_BEH_OUTISOLATE: return g->dout[i] == 0 ? diff : 0.0;
		case TERMCODE_BEH_TOTALT: case TERMCODE_BEH_AVALTPOP: case TERMCODE_BEH_TOTALTPOP: {
			int pop = (tc != TERMCODE_BEH_TOTALT), div = (tc == TERMCODE_BEH_AVALTPOP);
			double tota = 0.0, popsum = 0.0;
			for (k = 0; k < nb; k++) { long j = g->outadj[i].nb[k]; tota += bv[j] - mean; popsum += (bv[j] - mean) * (double)g->din[j]; }
			ch = tota;
			if (nb > 0) {
				if (pop) ch += popsum;
				else ch = diff * tota;
				if (div) ch /= (double)nb;
			}
			return ch;
		}
		case TERMCODE_BEH_MAXALT: case TERMCODE_BEH_MINALT: {
			int minim = (tc == TERMCODE_BEH_MINALT);
			if (nb == 0 || diff == 0.0) return 0.0;
			s = minim ? 1000.0 : -1000.0;
			for (k = 0; k < nb; k++) { double v = bv[g->outadj[i].nb[k]] - mean; if (minim ? v < s : v > s) s = v; }
			return s * diff;
		}
		case TERMCODE_BEH_AVRECALT: case TERMCODE_BEH_TOTRECALT: {
			long cnt = 0;
			s = 0.0;
			for (k = 0; k < nb; k++) { long j = g->outadj[i].nb[k]; if (has_edge(g, j, i)) { s += bv[j] - mean; cnt++; } }
			if (cnt == 0) return 0.0;
			ch = diff * s;
			if (tc == TERMCODE_BEH_AVRECALT) ch /= (double)cnt;
			return ch;
		}
		default: {
			int f[5];
			long nh = 0, nl = 0, ne = 0, nhp = 0, nlp = 0, nep = 0;
			double vego = bv[i], tcnt = 0.0;
			if (nb == 0) return 0.0;
			beh_sim_flags(tc, f);
			for (k = 0; k < nb; k++) {
				long j = g->outadj[i].nb[k];
				if (bv[j] > vego) { nh++; nhp += g->din[j]; }
				else if (bv[j] < vego) { nl++; nlp += g->din[j]; }
				else { ne++; nhp += g->din[j]; }		/* RSiena: the equal alters join the HIGHER popularity count */
			}
			if (f[1]) {
				if (diff > 0) { if (f[3]) tcnt += (double)nhp; if (f[4]) tcnt -= (double)nep + (double)nlp; }
				else if (diff < 0) { if (f[3]) tcnt -= (double)nhp + (double)nep; if (f[4]) tcnt += (double)nlp; }
			}
			else {
				if (diff > 0) { if (f[3]) tcnt += (double)nh; if (f[4]) tcnt -= (double)ne + (double)nl; }
				else if (diff < 0) { if (f[3]) tcnt -= (double)nh + (double)ne; if (f[4]) tcnt += (double)nl; }
			}
			ch = tcnt / range;
			if (f[0]) ch /= (double)nb;
			else if (f[3] && f[4]) ch -= (double)nb * simMean;
			if (f[2]) ch *= (double)g->din[i];
			return ch;
		}
	}
}

/* RSiena AltersCovariateAverageEffect: sum (or average) over ego's out-alters of the centred covariate (or of "same covariate value"), 0 without out-ties */
static double beh_xalt_sum(graph_t *g, int tc, long i) {
	int v = (tc - TERMCODE_BEH_XALT0) / 8, sl = (tc - TERMCODE_BEH_XALT0) % 8;
	int same = (v == 1 || v == 3), divide = (v <= 1);
	const double *cv = saom_tl_cov[sl];
	long k, nb = g->outadj[i].len;
	double t = 0.0;
	if (!cv || nb == 0) return 0.0;
	for (k = 0; k < nb; k++) {
		long j = g->outadj[i].nb[k];
		t += same ? (fabs(cv[j] - cv[i]) < 1e-6 ? 1.0 : 0.0) : cv[j];
	}
	return divide ? t / (double)nb : t;
}

/* protocol 43: RSiena behavior effects of the network x a covariate (constant or changing): term code 300 + 16 * f + slot, slot = covariate
   store slot. f: 0 avXInAlt 1 totXInAlt 2 avXRecAlt 3 totXRecAlt 4 avSameXInAlt 5 totSameXInAlt 6 avSameXRecAlt 7 totSameXRecAlt 8 avAltSameX
   9 totAltSameX 10 avRecAltSameX 11 totRecAltSameX 12 avAltAltX 13 avSimAltX 14 totSimAltX 15 minXAlt 16 maxXAlt 17 degAbsContrX 18 degPosContrX
   19 degNegContrX. bs_T() is the alter aggregate of the contribution (forstat = 0) or of the ego statistic (forstat = 1); they differ for the
   in-alter averages (RSiena computes the contribution's aggregate only for an actor with out-ties). */
#define TERMCODE_BS0 300
#define SAOM_BSTC(tc) ((tc) >= TERMCODE_BS0 && (tc) < TERMCODE_BS0 + 16 * 32)
static double bs_T(graph_t *g, const double *bv, double mean, int f, const double *cv, double cmean, long i, int forstat) {
	int kindX = (f <= 3), kindSame = (f >= 4 && f <= 7), kindZS = (f >= 8 && f <= 11), kindZX = (f == 12);
	int div = (f == 0 || f == 2 || f == 4 || f == 6 || f == 8 || f == 10 || f == 12);
	int set = (f <= 1 || f == 4 || f == 5) ? 1 : ((f == 2 || f == 3 || f == 6 || f == 7 || f == 10 || f == 11) ? 2 : 0);
	long m, nalt = 0;
	double t = 0.0;
	adjlist_t *L = (set == 1) ? &g->inadj[i] : &g->outadj[i];
	if (f == 15 || f == 16) {
		double best = 0.0;
		for (m = 0; m < g->outadj[i].len; m++) {
			double c = cv[g->outadj[i].nb[m]];
			if (nalt == 0 || (f == 15 ? c < best : c > best)) best = c;
			nalt++;
		}
		return nalt ? best : cmean;
	}
	if (!forstat && set == 1 && g->dout[i] == 0) return 0.0;
	for (m = 0; m < L->len; m++) {
		long j = L->nb[m];
		int same;
		if (set == 2 && !has_edge(g, j, i)) continue;
		same = fabs(cv[j] - cv[i]) < 1e-6;
		if (kindX) { t += cv[j]; nalt++; }
		else if (kindSame) { t += same ? 1.0 : 0.0; nalt++; }
		else if (kindZS) { if (same) { t += bv[j] - mean; nalt++; } }
		else if (kindZX) { t += (bv[j] - mean) * cv[j]; nalt++; }
	}
	if (nalt == 0) return 0.0;
	return div ? t / (double)nalt : t;
}
static double bs_contrast(graph_t *g, int f, const double *cv, long i) {
	double xi = cv[i], c = 0.0;
	long deg = g->dout[i];
	if (f == 17 || f == 18) { if ((double)deg > xi) c = (double)deg - xi; }
	if (f == 17 || f == 19) { if ((double)deg < xi) c = xi - (double)deg; }
	return c;
}
/* protocol 47: more behavior x covariate families (same term code 300 + 16 f + slot): 20 avXAltDist2 21 totXAltDist2 22 avTXAltDist2 23 totAXAltDist2
   24 avXInAltDist2 25 totXInAltDist2 26 avTXInAltDist2 27 totAXInAltDist2 (AltersDist2CovariateAverageEffect / AltersInDist2CovariateAverageEffect:
   div1 = by ego's out-degree, div2 = by the alter's out-/in-degree) 28 avSimEgoX 29 totSimEgoX 30 avAltEgoX 31 totAltEgoX (InteractionCovariateEffect:
   the covariate of the ego times the avSim / totSim / avAlt / totAlt effect; RSiena builds the similarity ones with hi = lo = false). */
#define BS2V(h) (cv ? cv[h] : bv[h] - mean)
static double bs2_T(graph_t *g, const double *bv, double mean, int f, const double *cv, long i, int forstat) {
	int in = ((f >= 24 && f < 32) || (f >= 32 && f % 8 >= 4)), div1 = (f == 20 || f == 22 || f == 24 || f == 26 || (f >= 32 && (f % 4 == 0 || f % 4 == 2))), div2 = (f == 20 || f == 23 || f == 24 || f == 27 || (f >= 32 && (f % 4 == 0 || f % 4 == 3)));
	long m, m2, nb = g->outadj[i].len;
	double sum = 0.0;
	(void)bv; (void)mean;
	if (nb == 0) return 0.0;
	for (m = 0; m < nb; m++) {
		long j = g->outadj[i].nb[m];
		double av = 0.0;
		long d;
		if (!in) {
			int tie = 0;
			d = g->outadj[j].len;
			for (m2 = 0; m2 < d; m2++) { long h = g->outadj[j].nb[m2]; if (h != i) av += BS2V(h); else tie = 1; }
			if (div2) { if (d - tie > 0) av /= (double)(d - tie); else av = 0.0; }
		}
		else {
			d = g->inadj[j].len;
			for (m2 = 0; m2 < d; m2++) { long h = g->inadj[j].nb[m2]; if (h != i) av += BS2V(h); }
			if (div2) { if (d > 1) av /= (double)(d - 1); else av = 0.0; }
		}
		sum += av;
	}
	return div1 ? sum / (double)nb : sum;
}
static double bs2_interact_T(graph_t *g, const double *bv, double mean, int f, const double *cv, long i, int forstat) {
	long m, nb = g->outadj[i].len;
	double t = 0.0;
	(void)cv; (void)forstat;
	if (f == 28 || f == 29) return 0.0;
	if (nb == 0) return 0.0;
	for (m = 0; m < nb; m++) t += bv[g->outadj[i].nb[m]] - mean;
	return (f == 30) ? t / (double)nb : t;
}

static double beh_bs_ego_stat(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i) {
	int f = (tc - TERMCODE_BS0) / 16, sl = (tc - TERMCODE_BS0) % 16;
	const double *cv = (sl < 8) ? saom_tl_cov[sl] : NULL;
	double zi = bv[i] - mean;
	if (!cv) return 0.0;
	if (f >= 20 && f <= 27) return zi * bs2_T(g, bv, mean, f, cv, i, 1);
	if (f >= 28) {
		if (f <= 29) { long nb = g->outadj[i].len; return nb == 0 ? 0.0 : cv[i] * (f == 28 ? 1.0 : (double)nb); }
		return cv[i] * zi * bs2_interact_T(g, bv, mean, f, cv, i, 1);
	}
	if (f >= 17 && f <= 19) return zi * bs_contrast(g, f, cv, i);
	if (f == 13 || f == 14) {
		long m, nb = g->outadj[i].len;
		double st = 0.0;
		for (m = 0; m < nb; m++) { long j = g->outadj[i].nb[m]; st += (1.0 - fabs(bv[i] - bv[j]) / range - simMean) * cv[j]; }
		if (f == 13 && nb > 0) st /= (double)nb;
		return st;
	}
	return zi * bs_T(g, bv, mean, f, cv, 0.0, i, 1);
}
static double beh_bs_change(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i, double diff) {
	int f = (tc - TERMCODE_BS0) / 16, sl = (tc - TERMCODE_BS0) % 16;
	const double *cv = (sl < 8) ? saom_tl_cov[sl] : NULL;
	if (!cv) return 0.0;
	if (f >= 20 && f <= 27) { long nb2 = g->outadj[i].len; return nb2 == 0 ? 0.0 : diff * bs2_T(g, bv, mean, f, cv, i, 0); }
	if (f >= 28) return diff * cv[i] * bs2_interact_T(g, bv, mean, f, cv, i, 0);
	if (f >= 17 && f <= 19) return diff * bs_contrast(g, f, cv, i);
	if (f == 13 || f == 14) {
		long m, nb = g->outadj[i].len;
		double tot = 0.0;
		if (nb == 0) return 0.0;
		for (m = 0; m < nb; m++) { long j = g->outadj[i].nb[m]; tot += (fabs(bv[i] - bv[j]) - fabs(bv[i] + diff - bv[j])) * cv[j]; }
		tot /= range;
		if (f == 13) tot /= (double)nb;
		return tot;
	}
	return diff * bs_T(g, bv, mean, f, cv, 0.0, i, 0);
}

/* protocol 44: RSiena behavior effects of the network without a covariate: term code 820 + f. f: 0 avInSim 1 totInSim 2 avInSimPopAlt 3 totInSimPopAlt
   4 avSimRecip 5 totSimRecip 6 avSimRecPop 7 totSimRecPop 8 popAlt 9 totPopAlt 10 avInAlt 11 totInAlt (RSiena SimilarityIndegreeEffect,
   ReciprocatedSimilarityEffect, PopularityAlterEffect, AverageInAlterEffect) */
#define TERMCODE_BQ0 820
#define SAOM_BQTC(tc) ((tc) >= TERMCODE_BQ0 && (tc) < TERMCODE_BQ0 + 20)
static double beh_bq_ego_stat(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i) {
	int f = tc - TERMCODE_BQ0;
	if (f >= 12) { long nb0 = g->outadj[i].len; return nb0 == 0 ? 0.0 : (bv[i] - mean) * bs2_T(g, bv, mean, 32 + (f - 12), NULL, i, 1); }
	double zi = bv[i] - mean, st = 0.0;
	long m, nb = 0;
	if (f <= 7) {
		int set = (f <= 3) ? 1 : 2, avg = (f % 2 == 0), pop = (f == 2 || f == 3 || f == 6 || f == 7);
		adjlist_t *L = (set == 1) ? &g->inadj[i] : &g->outadj[i];
		for (m = 0; m < L->len; m++) {
			long j = L->nb[m];
			double ts;
			if (set == 2 && !has_edge(g, j, i)) continue;
			ts = 1.0 - fabs(bv[i] - bv[j]) / range - simMean;
			if (pop) ts *= (double)g->din[j];
			st += ts; nb++;
		}
		if (avg && nb > 0) st /= (double)nb;
		return st;
	}
	if (f <= 9) {
		double t = 0.0;
		if (g->dout[i] == 0) return 0.0;
		for (m = 0; m < g->outadj[i].len; m++) t += (double)g->din[g->outadj[i].nb[m]];
		if (f == 8) t /= (double)g->dout[i];
		return zi * t;
	}
	for (m = 0; m < g->inadj[i].len; m++) { st += bv[g->inadj[i].nb[m]] - mean; nb++; }
	if (nb > 0) { st *= zi; if (f == 10) st /= (double)nb; }
	else st = 0.0;
	return st;
}
static double beh_bq_change(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i, double diff) {
	int f = tc - TERMCODE_BQ0;
	if (f >= 12) return g->outadj[i].len == 0 ? 0.0 : diff * bs2_T(g, bv, mean, 32 + (f - 12), NULL, i, 0);
	long m, deg;
	double tot = 0.0;
	if (f <= 7) {
		int set = (f <= 3) ? 1 : 2, avg = (f % 2 == 0), pop = (f == 2 || f == 3 || f == 6 || f == 7);
		adjlist_t *L = (set == 1) ? &g->inadj[i] : &g->outadj[i];
		deg = 0;
		for (m = 0; m < L->len; m++) {
			long j = L->nb[m];
			double ch;
			if (set == 2 && !has_edge(g, j, i)) continue;
			ch = fabs(bv[i] - bv[j]) - fabs(bv[i] + diff - bv[j]);
			if (pop) ch *= (double)g->din[j];
			tot += ch; deg++;
		}
		if (deg == 0) return 0.0;
		tot /= range;
		if (avg) tot /= (double)deg;
		return tot;
	}
	if (f <= 9) {
		double t = 0.0;
		if (g->dout[i] == 0) return 0.0;
		for (m = 0; m < g->outadj[i].len; m++) t += (double)g->din[g->outadj[i].nb[m]];
		if (f == 8) t /= (double)g->dout[i];
		return diff * t;
	}
	if (g->din[i] == 0) return 0.0;
	for (m = 0; m < g->inadj[i].len; m++) tot += bv[g->inadj[i].nb[m]] - mean;
	tot *= diff;
	if (f == 10) tot /= (double)g->din[i];
	return tot;
}

/* protocol 48: behavior effects with a DYADIC covariate (RSiena avAltW ... totSimW): term code 840 + 8 f + d, d = the dyadic covariate slot. f: 0 avAltW
   1 totAltW 2 avInAltW 3 totInAltW 4 avWAlt 5 totWAlt 6 avWInAlt 7 totWInAlt 8 avSimW 9 totSimW (DyadicCovariateAvAltEffect, SimilarityWEffect). */
#define TERMCODE_BR0 840
/* codes 840..919: parameter 1 (denominator = the number of alters); 920..999: parameter 2 (denominator = the sum of the weights) */
#define SAOM_BRTC(tc) ((tc) >= TERMCODE_BR0 && (tc) < TERMCODE_BR0 + 160)
static double beh_br_ego_stat(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i) {
	int par2 = (tc - TERMCODE_BR0) >= 80, f = ((tc - TERMCODE_BR0) % 80) / 8, d = (tc - TERMCODE_BR0) % 8;
	const double *W = saom_tl_bdy[d] ? saom_tl_bdy[d] : saom_bdy[d];
	long n = saom_bdy_n, m;
	double zi = bv[i] - mean, st = 0.0, tw = 0.0;
	long cnt = 0;
	if (!W) return 0.0;
	if (f <= 7) {
		int asw = (f <= 3), in = (f == 2 || f == 3 || f == 6 || f == 7), av = (f % 2 == 0);
		adjlist_t *L = in ? &g->inadj[i] : &g->outadj[i];
		for (m = 0; m < L->len; m++) {
			long j = L->nb[m];
			double w = W[(i - 1) * n + (j - 1)];
			st += asw ? (bv[j] - mean) * w : w;
			tw += (par2 && asw) ? w : 1.0;
		}
		st *= zi;
		if (av && fabs(tw) > 1e-12) st /= tw;
		return st;
	}
	for (m = 0; m < g->outadj[i].len; m++) {
		long j = g->outadj[i].nb[m];
		double w = W[(i - 1) * n + (j - 1)];
		st += w * (1.0 - fabs(bv[i] - bv[j]) / range - simMean);
		if (w != 0.0) cnt++;
		tw += par2 ? w : 1.0;
	}
	if (f == 8 && cnt > 0 && fabs(tw) > 1e-12) st /= tw;
	return st;
}
static double beh_br_change(graph_t *g, double *bv, int tc, double range, double simMean, double mean, long i, double diff) {
	int par2 = (tc - TERMCODE_BR0) >= 80, f = ((tc - TERMCODE_BR0) % 80) / 8, d = (tc - TERMCODE_BR0) % 8;
	const double *W = saom_tl_bdy[d] ? saom_tl_bdy[d] : saom_bdy[d];
	long n = saom_bdy_n, m;
	double tot = 0.0, tw = 0.0;
	long cnt = 0;
	(void)simMean;
	if (!W) return 0.0;
	if (f <= 7) {
		int asw = (f <= 3), in = (f == 2 || f == 3 || f == 6 || f == 7), av = (f % 2 == 0);
		adjlist_t *L = in ? &g->inadj[i] : &g->outadj[i];
		if (L->len == 0) return 0.0;
		for (m = 0; m < L->len; m++) {
			long j = L->nb[m];
			double w = W[(i - 1) * n + (j - 1)];
			tot += asw ? (bv[j] - mean) * w : w;
			tw += (par2 && asw) ? w : 1.0;
		}
		if (av) return fabs(tw) > 1e-12 ? diff * tot / tw : 0.0;
		return diff * tot;
	}
	if (g->outadj[i].len == 0) return 0.0;
	for (m = 0; m < g->outadj[i].len; m++) {
		long j = g->outadj[i].nb[m];
		double w = W[(i - 1) * n + (j - 1)];
		tot += w * (fabs(bv[i] - bv[j]) - fabs(bv[i] + diff - bv[j]));
		if (w != 0.0) cnt++;
		tw += par2 ? w : 1.0;
	}
	tot /= range;
	if (f == 8 && cnt > 0 && fabs(tw) > 1e-12) tot /= tw;
	return tot;
}

/* protocol 51: behavior shape effects (RSiena quad_cc quad_nc constant threshold simAllNear simAllFar avGroup totGroup): term code 2000 + 100 f + par,
   f: 0 quad_cc 1 quad_nc 2 constant 3 threshold 4 simAllNear 5 simAllFar 6 avGroup 7 totGroup; par = RSiena internal parameter (0..99). bv = raw behavior. */
#define TERMCODE_BH0 2000
#define SAOM_BHTC(tc) ((tc) >= TERMCODE_BH0 && (tc) < TERMCODE_BH0 + 800)
static double beh_bh_ego_stat(graph_t *g, double *bv, int tc, double mean, long i) {
	int f = (tc - TERMCODE_BH0) / 100, par = (tc - TERMCODE_BH0) % 100;
	long n = g->n, j;
	double st = 0.0;
	switch (f) {
		case 0: {
			double m = 0.0, c;
			for (j = 1; j <= n; j++) m += bv[j] - mean;
			m /= (double)n;
			c = (bv[i] - mean) - m;
			return c * c;
		}
		case 1: return bv[i] * bv[i];
		case 2: return saom_tl_beh0 ? -fabs(bv[i] - saom_tl_beh0[i]) : 0.0;
		case 3: return floor(bv[i] + 0.5) >= (double)par ? 1.0 : 0.0;
		case 4: case 5: {
			int near = (f == 4);
			double lp = (double)par, zi = bv[i];
			for (j = 1; j <= n; j++) {
				double dif = bv[j] - zi;
				if (j == i) continue;
				if (dif < 0) { if ((dif > -lp && near) || (dif <= -lp && !near)) st += lp + dif; }
				if (dif > 0) { if ((dif < lp && near) || (dif > lp && !near)) st += lp - dif; }
				if (dif == 0 && near) st += lp;
			}
			return st;
		}
		default: {
			int center = (par <= 0 ? 1 : 0);
			double sum = 0.0;
			for (j = 1; j <= n; j++) sum += bv[j] - mean;
			if (f == 6) sum /= (double)n;
			if (!center) sum += mean - (double)par;
			return sum * (bv[i] - mean);
		}
	}
}
static double beh_bh_change(graph_t *g, double *bv, int tc, double mean, long i, double diff) {
	int f = (tc - TERMCODE_BH0) / 100, par = (tc - TERMCODE_BH0) % 100;
	long n = g->n, j;
	switch (f) {
		case 0: {
			double m = 0.0;
			for (j = 1; j <= n; j++) m += bv[j];
			m /= (double)n;
			return (2.0 * bv[i] - m + diff) * diff;
		}
		case 1: return (2.0 * bv[i] + diff) * diff;
		case 2: return diff == 0.0 ? 0.0 : -1.0;
		case 3: {
			double z = bv[i];
			if (z + diff >= (double)par && z < (double)par) return 1.0;
			if (z + diff < (double)par && z >= (double)par) return -1.0;
			return 0.0;
		}
		case 4: case 5: {
			int near = (f == 4);
			long zi = (long)floor(bv[i] + 0.5), contribution = 0;
			double lp = (double)par;
			if (diff < 0) zi--;
			for (j = 1; j <= n; j++) {
				long zj = (long)floor(bv[j] + 0.5);
				if (j == i) continue;
				if (zj <= zi) { if (((double)zj > (double)zi - lp && near) || ((double)zj <= (double)zi - lp && !near)) contribution--; }
				if (zj > zi) { if (((double)zj <= (double)zi + lp && near) || ((double)zj > (double)zi + lp && !near)) contribution++; }
			}
			return diff * (double)contribution;
		}
		default: {
			int center = (par <= 0 ? 1 : 0);
			double st = 0.0;
			for (j = 1; j <= n; j++) st += bv[j] - mean;
			st += (bv[i] - mean) + diff;
			if (f == 6) st /= (double)n;
			if (!center) st += mean - (double)par;
			return diff * st;
		}
	}
}

/* protocol 55: more behavior effects of the network (RSiena IndegreeWeightedAverageGroupEffect, AverageAlterCcEffect, AverageAlterInDist2NCEffect, AverageSimilarityInDist2Effect,
   TotalGwdspAlterEffect, TotalGwdspAlterNCEffect): term code 2800 + 100 f + par. f: 0 indegAvGroup 1 indegTotGroup 2 avAlt_cc 3 totAlt_cc 4 avInAltDist2_nc 5 totInAltDist2_nc
   6 avTInAltDist2_nc 7 totAInAltDist2_nc 8 avInSimDist2 9 totInSimDist2 10 totGwdspFFAlt 11 totGwdspFBAlt 12 totGwdspFFAlt_nc 13 totGwdspFBAlt_nc. bv = raw values. */
#define TERMCODE_BU0 2800
#define SAOM_BUTC(tc) ((tc) >= TERMCODE_BU0 && (tc) < TERMCODE_BU0 + 1800)
static double bu_changesim(double zalt, double zego) {
	if (zego > zalt) return -1.0;
	if (zego < zalt - 1.0) return 1.0;
	return 2.0 * (zalt - zego) - 1.0;
}
static __thread double saom_tl_behvar = 0.0;	/* protocol 60: the pooled variance of the dependent behavior (RSiena BehaviorLongitudinalData::variance()) */
static __thread double saom_tl_bsim = 0.0;	/* the behavior's similarity mean for the bu terms */
/* RSiena DenseTriadsBehaviorEffect / DenseTriadsSimilarityEffect: the triads of ego i with at least `density' (5 or 6) of the six possible arcs. mode 0: the count; mode 1: the sum over
   the triad partners j and h of 1 - |z_i - z_x| / range - simMean (the statistic); mode 2: the sum of |oldv - z_x| - |newv - z_x| (the change contribution) */
static double bu_dense(graph_t *g, long i, int six, int mode, const double *bv, double newv, double range, double simMean) {
	long n = g->n, m, m2, j, h, q;
	double tot = 0.0;
	int *mark = (int *)calloc((size_t)(n + 1), sizeof(int));
	for (m = 0; m < g->inadj[i].len; m++) mark[g->inadj[i].nb[m]] = 1;
	for (m = 0; m < g->outadj[i].len; m++) { q = g->outadj[i].nb[m]; mark[q] = (mark[q] == 0) ? 1 : mark[q] + 1; }
	for (m = 0; m < g->outadj[i].len; m++) {
		j = g->outadj[i].nb[m];
		if (!has_edge(g, j, i)) continue;			/* the reciprocated ties of i */
		if (six) {
			for (m2 = 0; m2 < g->outadj[j].len; m2++) {
				h = g->outadj[j].nb[m2];
				if (!has_edge(g, h, j) || mark[h] != 2) continue;
				if (mode == 0) tot += 1.0;
				else if (mode == 1) tot += (1.0 - fabs(bv[i] - bv[j]) / range - simMean) + (1.0 - fabs(bv[i] - bv[h]) / range - simMean);
				else tot += fabs(bv[i] - bv[j]) - fabs(newv - bv[j]) + fabs(bv[i] - bv[h]) + (-fabs(newv - bv[h]));
			}
		}
		else {
			for (m2 = 0; m2 < g->outadj[j].len; m2++) {
				int tie, counted = 0;
				h = g->outadj[j].nb[m2];
				tie = mark[h];
				if (has_edge(g, h, j)) { if (tie > 0 && (tie != 2 || j < h)) counted = 1; }
				else if (tie == 2) counted = 1;
				if (!counted) continue;
				if (mode == 0) tot += 1.0;
				else if (mode == 1) tot += (1.0 - fabs(bv[i] - bv[j]) / range - simMean) + (1.0 - fabs(bv[i] - bv[h]) / range - simMean);
				else tot += fabs(bv[i] - bv[j]) - fabs(newv - bv[j]) + fabs(bv[i] - bv[h]) + (-fabs(newv - bv[h]));
			}
		}
	}
	free(mark);
	return six ? tot / 2.0 : tot;
}
static double beh_bu_ego_stat(graph_t *g, double *bv, int tc, double range, double mean, long i) {
	int f = (tc - TERMCODE_BU0) / 100, par = (tc - TERMCODE_BU0) % 100;
	long n = g->n, j, m, m2;
	double st = 0.0, ci = bv[i] - mean;
	switch (f) {
		case 0: case 1: {
			double sum = 0.0, wsum = 0.0;
			for (j = 1; j <= n; j++) { sum += (bv[j] - mean) * (double)g->din[j]; wsum += (double)g->din[j]; }
			if (f == 0) sum /= wsum;
			if (par > 0) sum += mean - (double)par;
			return sum * ci;
		}
		case 2: case 3: {
			long cnt = (long)g->outadj[i].len;
			double delta = 0.0;
			if (cnt == 0) return 0.0;
			for (m = 0; m < cnt; m++) st += bv[g->outadj[i].nb[m]] - mean;
			for (j = 1; j <= n; j++) delta += bv[j] - mean;
			delta /= (double)n;
			st -= (double)cnt * delta;
			st *= (ci - delta);
			if (f == 2) st /= (double)cnt;
			return st;
		}
		case 4: case 5: case 6: case 7: {
			int dv1 = (f == 4 || f == 6), dv2 = (f == 4 || f == 7);
			long cnt = 0;
			for (m = 0; m < g->outadj[i].len; m++) {
				long k = g->outadj[i].nb[m];
				double av = 0.0;
				for (m2 = 0; m2 < g->inadj[k].len; m2++) { long q = g->inadj[k].nb[m2]; if (q != i) av += bv[q]; }
				if (g->din[k] > 1 && dv2) av /= (double)(g->din[k] - 1);
				st += av;
				cnt++;
			}
			if (cnt > 0) { st *= bv[i]; if (dv1) st /= (double)cnt; }
			return st;
		}
		case 8: case 9: {
			if (g->outadj[i].len == 0) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) {
				long k = g->outadj[i].nb[m], degree = (long)g->din[k];
				if (degree > 0) {
					double inalt = 0.0;
					for (m2 = 0; m2 < g->inadj[k].len; m2++) { long q = g->inadj[k].nb[m2]; if (q != i) inalt += bv[q] - mean; else degree--; }
					if (degree > 0) { inalt /= (double)degree; st += 1.0 - fabs(ci - inalt) / range; }
				}
			}
			if (f == 8) st /= (double)g->outadj[i].len;
			return st;
		}
		case 14: case 15: {
			/* varAlt / avSimVarAlt: the variance of the out-alters' values minus the data variance, times z_i (resp. the average similarity to them) */
			long cnt = (long)g->outadj[i].len;
			double sum = 0.0, sumsq = 0.0, sim = 0.0, varalt;
			if (cnt == 0) return 0.0;
			for (m = 0; m < cnt; m++) {
				long k = g->outadj[i].nb[m];
				sum += bv[k]; sumsq += bv[k] * bv[k];
				sim += 1.0 - fabs(bv[i] - bv[k]) / range - saom_tl_bsim;
			}
			varalt = sumsq / (double)cnt - (sum / (double)cnt) * (sum / (double)cnt);
			if (f == 14) return (varalt - saom_tl_behvar) * ci;
			return (sim / (double)cnt) * (varalt - saom_tl_behvar);
		}
		case 16: return ci * bu_dense(g, i, par == 6, 0, bv, 0.0, range, 0.0);
		case 17: return bu_dense(g, i, par == 6, 1, bv, 0.0, range, saom_tl_bsim);
		default: {
			int fwd = (f == 10 || f == 12), nc = (f == 12 || f == 13);
			double add = nc ? mean : 0.0;
			for (j = 1; j <= n; j++) {
				if (j == i) continue;
				st += (bv[j] - mean + add) * xt_gwesp(xt_mtp(g, g, 'F', fwd ? 'F' : 'B', i, j), (double)par);
			}
			return st * (ci + add);
		}
	}
}
static double beh_bu_change(graph_t *g, double *bv, int tc, double range, double mean, long i, double diff) {
	int f = (tc - TERMCODE_BU0) / 100, par = (tc - TERMCODE_BU0) % 100;
	long n = g->n, j, m, m2;
	double ci = bv[i] - mean;
	switch (f) {
		case 0: case 1: {
			double st = 0.0, wn = 0.0;
			for (j = 1; j <= n; j++) { st += (bv[j] - mean) * (double)g->din[j]; wn += (double)g->din[j]; }
			st += ci * (double)g->din[i] + diff;
			if (f == 0) { wn += (double)g->din[i]; st /= wn; }
			if (par > 0) st += mean - (double)par;
			return diff * st;
		}
		case 2: case 3: {
			long od = (long)g->outadj[i].len;
			double contribution = 0.0, cm = 0.0;
			if (od == 0) return 0.0;
			for (m = 0; m < od; m++) contribution += bv[g->outadj[i].nb[m]] - mean;
			for (j = 1; j <= n; j++) cm += bv[j];
			cm /= (double)n;
			contribution += (double)od * (mean - cm);
			contribution *= diff;
			if (f == 2) contribution /= (double)od;
			return contribution;
		}
		case 4: case 5: case 6: case 7: {
			int dv1 = (f == 4 || f == 6), dv2 = (f == 4 || f == 7);
			double sum = 0.0;
			if (g->outadj[i].len == 0) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) {
				long k = g->outadj[i].nb[m];
				double av = 0.0;
				int tv = 1;
				for (m2 = 0; m2 < g->inadj[k].len; m2++) av += bv[g->inadj[k].nb[m2]];
				if (tv == 1) av -= bv[i];
				if (((long)g->din[k] - tv) > 0 && dv2) av /= (double)((long)g->din[k] - tv);
				sum += av;
			}
			sum *= diff;
			if (dv1) sum /= (double)g->outadj[i].len;
			return sum;
		}
		case 8: case 9: {
			double contribution = 0.0;
			if (diff == 0.0 || g->outadj[i].len == 0) return 0.0;
			for (m = 0; m < g->outadj[i].len; m++) {
				long k = g->outadj[i].nb[m], deg = (long)g->din[k];
				double av = 0.0;
				if (deg > 0) {
					for (m2 = 0; m2 < g->inadj[k].len; m2++) av += bv[g->inadj[k].nb[m2]] - mean;
					av -= ci;
					deg--;
				}
				if (deg > 0) {
					av /= (double)deg;
					if (diff > 0) contribution += bu_changesim(av, ci);
					else contribution -= bu_changesim(av, ci - 1.0);
				}
			}
			contribution /= range;
			if (f == 8) contribution /= (double)g->outadj[i].len;
			return contribution;
		}
		case 14: case 15: {
			long cnt = (long)g->outadj[i].len;
			double contribution = 0.0, sumsq = 0.0, tot = 0.0, varalt = 0.0, newv = bv[i] + diff;
			if (f == 14) {
				if (cnt > 1) {
					for (m = 0; m < cnt; m++) { double cz = bv[g->outadj[i].nb[m]] - mean; sumsq += cz * cz; tot += cz; }
					contribution = sumsq / (double)cnt - (tot / (double)cnt) * (tot / (double)cnt);
				}
				if (cnt > 0) { contribution -= saom_tl_behvar; contribution *= diff; }
				return contribution;
			}
			if (cnt > 0) {
				double change = 0.0;
				for (m = 0; m < cnt; m++) {
					double zj = bv[g->outadj[i].nb[m]];
					change += fabs(bv[i] - zj) - fabs(newv - zj);
					sumsq += (zj - mean) * (zj - mean); tot += zj - mean;
				}
				contribution = change / range / (double)cnt;
				varalt = sumsq / (double)cnt - (tot / (double)cnt) * (tot / (double)cnt) - saom_tl_behvar;
			}
			return contribution * varalt;
		}
		case 16: return diff * bu_dense(g, i, par == 6, 0, bv, 0.0, range, 0.0);
		case 17: return bu_dense(g, i, par == 6, 2, bv, bv[i] + diff, range, 0.0) / range;
		default: {
			int fwd = (f == 10 || f == 12), nc = (f == 12 || f == 13);
			double sum = 0.0;
			if (g->outadj[i].len == 0) return 0.0;
			for (j = 1; j <= n; j++) {
				if (j == i) continue;
				sum += (nc ? bv[j] : bv[j] - mean) * xt_gwesp(xt_mtp(g, g, 'F', fwd ? 'F' : 'B', i, j), (double)par);
			}
			return diff * sum;
		}
	}
}

static double saom_beh_stat_term(graph_t *g, double *behval, int termcode, double range, double simMean, double overallMean) {
	long i, k, od;
	double tot = 0.0, vego, sumabs;
	if (SAOM_BUTC(termcode)) {
		saom_tl_bsim = simMean;
		for (i = 1; i <= g->n; i++) tot += beh_bu_ego_stat(g, behval, termcode, range, overallMean, i);
		return tot;
	}
	if (SAOM_BHTC(termcode)) {
		for (i = 1; i <= g->n; i++) tot += beh_bh_ego_stat(g, behval, termcode, overallMean, i);
		return tot;
	}
	if (SAOM_BRTC(termcode)) {
		for (i = 1; i <= g->n; i++) tot += beh_br_ego_stat(g, behval, termcode, range, simMean, overallMean, i);
		return tot;
	}
	if (SAOM_BQTC(termcode)) {
		for (i = 1; i <= g->n; i++) tot += beh_bq_ego_stat(g, behval, termcode, range, simMean, overallMean, i);
		return tot;
	}
	if (SAOM_BSTC(termcode)) {
		for (i = 1; i <= g->n; i++) tot += beh_bs_ego_stat(g, behval, termcode, range, simMean, overallMean, i);
		return tot;
	}
	if (SAOM_BEH_XALTTC(termcode)) {
		for (i = 1; i <= g->n; i++) tot += (behval[i] - overallMean) * beh_xalt_sum(g, termcode, i);
		return tot;
	}
	if (SAOM_BEH_COVTC(termcode)) {
		const double *cv = saom_tl_cov[termcode - TERMCODE_BEH_EFFCOV0];
		if (!cv) return 0.0;
		for (i = 1; i <= g->n; i++) tot += (behval[i] - overallMean) * cv[i];
		return tot;
	}
	if (SAOM_BEH_NEWTC(termcode) || (termcode >= TERMCODE_BEH_TOTSIM && termcode <= TERMCODE_BEH_AVSIMPOPEGO)) {
		for (i = 1; i <= g->n; i++) tot += beh_new_ego_stat(g, behval, termcode, range, simMean, overallMean, i);
		return tot;
	}
	switch (termcode) {
		case TERMCODE_BEH_LINEAR:					// stat_saom_linear(): sum(values)
			for (i = 1; i <= g->n; i++) tot += behval[i];
			return tot;
		case TERMCODE_BEH_QUADRATIC:					// stat_saom_quadratic(): sum(values^2), RAW/uncentered
			for (i = 1; i <= g->n; i++) tot += behval[i] * behval[i];
			return tot;
		case TERMCODE_BEH_AVALT:					// stat_saom_avalt(): sum_i (z_i-zbar) * avg_{j in N_out(i)}(z_j-zbar) - CENTERED, as RSiena (fixed 2026-09-30)
			for (i = 1; i <= g->n; i++) {
				od = g->outadj[i].len;
				if (od == 0) continue;
				double s = 0.0;
				for (k = 0; k < od; k++) s += behval[g->outadj[i].nb[k]];
				tot += (behval[i] - overallMean) * (s / (double)od - overallMean);
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
static double saom_beh_change_term(graph_t *g, double *behval, int termcode, double overallMean, double range, double simMean,
	long i, double diff) {
	long od, k, nhigh, nlow;
	double vego;
	if (SAOM_BHTC(termcode)) return beh_bh_change(g, behval, termcode, overallMean, i, diff);
	if (SAOM_BUTC(termcode)) { saom_tl_bsim = simMean; return beh_bu_change(g, behval, termcode, range, overallMean, i, diff); }
	if (SAOM_BRTC(termcode)) return beh_br_change(g, behval, termcode, range, simMean, overallMean, i, diff);
	if (SAOM_BQTC(termcode)) return beh_bq_change(g, behval, termcode, range, simMean, overallMean, i, diff);
	if (SAOM_BSTC(termcode)) return beh_bs_change(g, behval, termcode, range, simMean, overallMean, i, diff);
	if (SAOM_BEH_XALTTC(termcode)) return diff * beh_xalt_sum(g, termcode, i);
	if (SAOM_BEH_COVTC(termcode)) return saom_tl_cov[termcode - TERMCODE_BEH_EFFCOV0] ? diff * saom_tl_cov[termcode - TERMCODE_BEH_EFFCOV0][i] : 0.0;
	if (SAOM_BEH_NEWTC(termcode)) return beh_new_change(g, behval, termcode, range, simMean, overallMean, i, diff);
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
			return diff * (s / (double)od - overallMean);		// centered, as RSiena (fixed 2026-09-30)
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
	gm->adjm = NULL;
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
/* an OPTIONAL trailing field (protocol 11 trailers): missing = `def',
   without flagging a parse error, so that an older caller still works */
static long next_long_opt(long def) {
	char *tok = strtok(NULL, " \t");
	if (!tok) return def;
	return (long)atof(tok);
}

/* two-network (multiplex) simulation - moved unchanged out of stata_call() */
static ST_retcode nn_call(char *argv[]) {
		char *nnfull, *blk0, *blk1, *blk2, *nnbuf0, *nnbuf1;
		long n1v, nties1v, nterms1v, n2v, nties2v, nterms2v;
		int tc1[MAXTERMS], tc2[MAXTERMS];
		double pp1[MAXTERMS], pp2[MAXTERMS], th1[MAXTERMS], th2[MAXTERMS];
		double rate1v, rate2v, seedv;
		graph_t g1, g2;
		rng_t rngnn;
		long ii, kk;
		double tnn, stepsnn, nch1, nch2, steps1 = 0.0, steps2 = 0.0, dist1 = 0.0, dist2 = 0.0;
		long *s1i, *s1j, *s2i, *s2j;

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

		g1.n = n1v; g1.need_adj = 0; g1.adjm = NULL;
		ht_alloc(&g1.ht, ht_next_pow2(nties1v * 2 + 16));
		g1.elist_i = NULL; g1.elist_j = NULL; g1.ecap = 0; g1.nties = 0;
		g1.dout = (long *)calloc((size_t)(n1v + 1), sizeof(long));
		g1.din  = (long *)calloc((size_t)(n1v + 1), sizeof(long));
		g1.outadj = NULL; g1.inadj = NULL;
		s1i = (long *)malloc((size_t)(nties1v > 0 ? nties1v : 1) * sizeof(long));
		s1j = (long *)malloc((size_t)(nties1v > 0 ? nties1v : 1) * sizeof(long));
		for (ii = 1; ii <= nties1v; ii++) {
			ST_double vi, vj;
			SF_vdata(1, ii, &vi);
			SF_vdata(2, ii, &vj);
			toggle(&g1, (long)vi, (long)vj);
			s1i[ii - 1] = (long)vi; s1j[ii - 1] = (long)vj;
		}

		g2.n = n2v; g2.need_adj = 0; g2.adjm = NULL;
		ht_alloc(&g2.ht, ht_next_pow2(nties2v * 2 + 16));
		g2.elist_i = NULL; g2.elist_j = NULL; g2.ecap = 0; g2.nties = 0;
		g2.dout = (long *)calloc((size_t)(n2v + 1), sizeof(long));
		g2.din  = (long *)calloc((size_t)(n2v + 1), sizeof(long));
		g2.outadj = NULL; g2.inadj = NULL;
		s2i = (long *)malloc((size_t)(nties2v > 0 ? nties2v : 1) * sizeof(long));
		s2j = (long *)malloc((size_t)(nties2v > 0 ? nties2v : 1) * sizeof(long));
		for (ii = 1; ii <= nties2v; ii++) {
			ST_double vi, vj;
			SF_vdata(3, ii, &vi);
			SF_vdata(4, ii, &vj);
			toggle(&g2, (long)vi, (long)vj);
			s2i[ii - 1] = (long)vi; s2j[ii - 1] = (long)vj;
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
					if (onNet1) steps1 += 1.0; else steps2 += 1.0;
					stepsnn += 1.0;
				}
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
		/* per-network ministep counts and end-vs-start distances: the
		   statistics and scores of the two rates under unconditional
		   estimation (protocol 5) */
		{
			dyadht_t hs;
			long dv;
			ht_alloc(&hs, ht_next_pow2(nties1v * 2 + 16));
			for (ii = 0; ii < nties1v; ii++) ht_put(&hs, dyadkey(&g1, s1i[ii], s1j[ii]), 1);
			for (ii = 0; ii < g1.nties; ii++) if (!ht_get(&hs, dyadkey(&g1, g1.elist_i[ii], g1.elist_j[ii]), &dv)) dist1 += 1.0;
			for (ii = 0; ii < nties1v; ii++) if (!has_edge(&g1, s1i[ii], s1j[ii])) dist1 += 1.0;
			ht_free(&hs);
			ht_alloc(&hs, ht_next_pow2(nties2v * 2 + 16));
			for (ii = 0; ii < nties2v; ii++) ht_put(&hs, dyadkey(&g2, s2i[ii], s2j[ii]), 1);
			for (ii = 0; ii < g2.nties; ii++) if (!ht_get(&hs, dyadkey(&g2, g2.elist_i[ii], g2.elist_j[ii]), &dv)) dist2 += 1.0;
			for (ii = 0; ii < nties2v; ii++) if (!has_edge(&g2, s2i[ii], s2j[ii])) dist2 += 1.0;
			ht_free(&hs);
		}
		SF_scal_save("__saom_native_nn_steps1", (ST_double)steps1);
		SF_scal_save("__saom_native_nn_steps2", (ST_double)steps2);
		SF_scal_save("__saom_native_nn_dist1", (ST_double)dist1);
		SF_scal_save("__saom_native_nn_dist2", (ST_double)dist2);
		/* statistics of the end networks; a cross-network effect (crprod)
		   reads the OTHER network at the START of the period, as RSiena
		   (lagged; RSiena's targets on a two-network s50 example confirm
		   it), while the ministeps above read its current state */
		{
			graph_t g1s, g2s;
			g1s.n = n1v; g1s.need_adj = 0; g1s.adjm = NULL;
			ht_alloc(&g1s.ht, ht_next_pow2(nties1v * 2 + 16));
			g1s.elist_i = NULL; g1s.elist_j = NULL; g1s.ecap = 0; g1s.nties = 0;
			g1s.dout = (long *)calloc((size_t)(n1v + 1), sizeof(long));
			g1s.din  = (long *)calloc((size_t)(n1v + 1), sizeof(long));
			g1s.outadj = NULL; g1s.inadj = NULL;
			for (ii = 0; ii < nties1v; ii++) toggle(&g1s, s1i[ii], s1j[ii]);
			g2s.n = n2v; g2s.need_adj = 0; g2s.adjm = NULL;
			ht_alloc(&g2s.ht, ht_next_pow2(nties2v * 2 + 16));
			g2s.elist_i = NULL; g2s.elist_j = NULL; g2s.ecap = 0; g2s.nties = 0;
			g2s.dout = (long *)calloc((size_t)(n2v + 1), sizeof(long));
			g2s.din  = (long *)calloc((size_t)(n2v + 1), sizeof(long));
			g2s.outadj = NULL; g2s.inadj = NULL;
			for (ii = 0; ii < nties2v; ii++) toggle(&g2s, s2i[ii], s2j[ii]);
			for (kk = 0; kk < nterms1v; kk++) {
				char statname[48];
				sprintf(statname, "__saom_native_nn_stat1_%ld", kk + 1);
				SF_scal_save(statname, saom_stat_term_nn(&g1, &g2s, tc1[kk], pp1[kk]));
			}
			for (kk = 0; kk < nterms2v; kk++) {
				char statname[48];
				sprintf(statname, "__saom_native_nn_stat2_%ld", kk + 1);
				SF_scal_save(statname, saom_stat_term_nn(&g2, &g1s, tc2[kk], pp2[kk]));
			}
			ht_free(&g1s.ht); free(g1s.elist_i); free(g1s.elist_j); free(g1s.dout); free(g1s.din);
			ht_free(&g2s.ht); free(g2s.elist_i); free(g2s.elist_j); free(g2s.dout); free(g2s.din);
		}

		free(s1i); free(s1j); free(s2i); free(s2j);
		ht_free(&g1.ht); free(g1.elist_i); free(g1.elist_j); free(g1.dout); free(g1.din);
		ht_free(&g2.ht); free(g2.elist_i); free(g2.elist_j); free(g2.dout); free(g2.din);
		return(0);
}

/* ===================================================================
   Simulation core (2026-10-01 performance rewrite).

   simulate_period() simulates ONE period from its starting state and
   returns every quantity any caller needs (statistics, scores, step and
   change counts, distances, the conditional-mode time), optionally
   keeping the final graph/behavior. It makes no Stata API calls, so it
   can run on worker threads (see the BATCH entry points further down).
   Everything it reads is either const (model_t, period_t, simparams_t)
   or owned by the call.

   The legacy single-simulation wire protocol (legacy_call()) builds these
   structs from its own argument string and frame and calls the SAME
   function with the SAME random-number draw order as before, so a given
   seed gives the same path as the pre-rewrite plugin (up to
   floating-point rounding in the last digits).

   Faster ministeps: every alternative's change statistic is now computed
   term by term over all alternatives at once (term-major, see
   eval_network_alternatives()), from dense adjacency rows (graph_t.adjm)
   instead of per-dyad hash lookups, with the utilities accumulated in the
   original term order so the arithmetic is unchanged.
   =================================================================== */

/* Optional timing counters (compile with -DSAOM_PROFILE; single-threaded
   runs only - the counters are plain globals). PROFILE| saves them as
   __saom_prof_<name> scalars (seconds, and counts) and resets them. */
#ifdef SAOM_PROFILE
#include <time.h>
static double prof_t[16];
static double prof_n[16];
static double prof_term_t[MAXTERMS], prof_term_n[MAXTERMS];
static double prof_now(void) { struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts); return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec; }
#define PROF_START(v) double v = prof_now()
#define PROF_ADD(slot, v) do { prof_t[slot] += prof_now() - (v); prof_n[slot] += 1.0; } while (0)
#else
#define PROF_START(v) do { } while (0)
#define PROF_ADD(slot, v) do { } while (0)
#endif
enum { PR_SETUP = 0, PR_ACTOR, PR_EVAL, PR_SOFTMAX, PR_APPLY, PR_BEH, PR_END, PR_WAIT };

typedef struct model_s {
	long n;
	long nterms;
	int termcodes[MAXTERMS];
	int attridx[MAXTERMS];
	double p1[MAXTERMS];
	long nattr;
	double *attrs[MAXATTR + 1];		// attrs[nattr] is the behsim slot, filled per simulation
	int need_adj, need_transtrip, need_cycle3;
	int has_behsim;
	int has_start;		/* protocol 61: a term reads the period's start network (saom_tl_g0) */
	int has_behcov;		/* protocol 45: network terms with the dependent behavior as covariate (term code + 1000, attribute slot nattr + 1) */
	long nbehterms;
	int behtermcodes[MAXBEHTERMS];
	double behminval, behmaxval, behrange, behSimMean, behOverallMean, behVariance;
	/* protocol 11 */
	int hasfntype;
	int fntype[MAXTERMS];			// network: 0 eval, 1 endowment (withdrawals only), 2 creation (new ties only)
	int behfntype[MAXBEHTERMS];		// behavior: 1 endowment (decreases only), 2 creation (increases only)
	long nstruct;				// structural (fixed) dyads, CSR by ego: struct_j[struct_off[i]..struct_off[i+1]-1]
	long nstruct_pending;			// protocol 20: structural dyads sent in the frame's last two columns (BATCHSETUP only)
	long nev_pending;			// protocol 27: composition-change events in the last four frame columns (period, time, actor, type; BATCHSETUP only)
	int ntv;				// protocol 21: attributes that vary by period (BATCHSETUP only)
	int tvcol[MAXATTR];			// their 1-based attribute columns
	long *struct_off, *struct_j;
	/* protocol 19: several co-evolving behaviors. Behavior 0 is the legacy block above (nbehterms, behtermcodes,
	   behminval..., behfntype); behaviors 1..nbeh-1 are views (bm[b]): a model_t of its own holding only that
	   behavior's terms and constants, so the single-behavior code runs unchanged on any behavior. nbehterms of the
	   MAIN model is behavior 0's (as before); nbehtermsAll the total; behoff[b] the offset of behavior b's terms in the
	   concatenated per-term arrays (statBeh, scoreBeh, thetaBeh). */
	int nbeh;
	long nbehtermsAll;			// total over behaviors (nbehterms of the main model is behavior 0's)
	long behoff[MAXBEH];
	struct model_s *bm[MAXBEH];
} model_t;

typedef struct {
	long nties;
	long *ti, *tj;			// starting ties
	double *beh0;			// starting behavior (index 1..n), NULL if no behavior
	long nmiss;			// missing dyads (0 = none); hasmiss below also covers behavior-only missingness
	int hasmiss;
	long *mi, *mj;
	double *missbeh;		// 1..n, NULL unless hasmiss
	double *xbeh0[MAXBEH];		// protocol 19: starting values of behaviors 1.., index 1..n
	double *xmissbeh[MAXBEH];	// their missingness (1..n), NULL unless hasmiss
	const double *bcov[8];			// protocol 38: this period's covariates of the behavior covariate effects
	const double *bdy[8];		// protocol 57: this period's dyadic covariates of the behavior effects (NULL = the constant ones)
	double *xattr[MAXATTR + 1];	// protocol 21: this period's values of the time-varying attributes (index = attribute column - 1), NULL = the model's own
	int haspresent;
	double *present;		// 1..n, NULL unless haspresent (with events: the actors active at the START of the period)
	long nev;			// protocol 27: composition change at fractional times: events of this period, sorted by time
	double *evt;			// event times in (0,1)
	long *eva;			// event actors (1..n)
	int *evk;			// 1 join / 2 leave
} period_t;

typedef struct {
	double theta[MAXTERMS];
	double thetaBeh[MAXBEHTERMS];		// all behaviors' coefficients, concatenated (behavior b from M->behoff[b])
	double rate, rateBeh;
	double xrateBeh[MAXBEH];		// protocol 19: rates of behaviors 1..
	int want_score;
	long condmode;
	double targetChange;
	long symtype;
	long hasratecov;		// number of ratecov() covariates K (0: none)
	double *ratecovattr;		// 0-based, K x n entries, covariate k at [k*n + i]
	double *ratecoef;		// K coefficients
	int nsr;			// protocol 42: the last nsr rate covariates are structural (degree-dependent, updated with the network)
	int srtype[MAXRC];		// their types, see sr_value()
} simparams_t;

typedef struct {
	double stat[MAXTERMS];			// end network (masked when hasmiss); behsim with the STARTING behavior
	double statBeh[MAXBEHTERMS];		// end behavior on the end network (masked)
	double statBehLag[MAXBEHTERMS];	// end behavior on the STARTING network (masked)
	double score[MAXTERMS];
	double scoreBeh[MAXBEHTERMS];
	double steps, stepsNet, stepsBeh, nchanges, nchangesBeh, netdist, behdist, t;
	double xstepsBeh[MAXBEH], xbehdist[MAXBEH], xnchangesBeh[MAXBEH];		// protocol 19: behaviors 1..
	double rcscore[MAXRC];		// ratecov() scores, one per covariate
	double rcstat[MAXRC];		// protocol 11: ratecov() statistics, sum over differing dyads of the tail's covariate
	graph_t *gfinal;			// only when keep_final: caller frees with graph_free()+free()
	double *behfinal;			// only when keep_final: caller frees
} simres_t;

/* dense adjacency is used up to this many actors (n^2 bytes per graph);
   larger networks fall back to the hash table for has_edge() */
#define DENSE_MAXN 4000

static void graph_init(graph_t *g, long n, int need_adj, long cap_hint) {
	long i;
	g->n = n;
	g->need_adj = need_adj;
	ht_alloc(&g->ht, ht_next_pow2(cap_hint * 2 + 16));
	g->elist_i = NULL; g->elist_j = NULL; g->ecap = 0; g->nties = 0;
	g->dout = (long *)calloc((size_t)(n + 1), sizeof(long));
	g->din  = (long *)calloc((size_t)(n + 1), sizeof(long));
	g->outadj = NULL; g->inadj = NULL;
	if (need_adj) {
		g->outadj = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		g->inadj  = (adjlist_t *)malloc((size_t)(n + 1) * sizeof(adjlist_t));
		for (i = 0; i <= n; i++) { adj_init(&g->outadj[i]); adj_init(&g->inadj[i]); }
	}
	g->adjm = (n <= DENSE_MAXN) ? (unsigned char *)calloc((size_t)(n + 1) * (size_t)(n + 1), 1) : NULL;
}

static void graph_free(graph_t *g) {
	long i;
	ht_free(&g->ht);
	free(g->elist_i); free(g->elist_j);
	free(g->dout); free(g->din);
	if (g->outadj) { for (i = 0; i <= g->n; i++) free(g->outadj[i].nb); free(g->outadj); }
	if (g->inadj) { for (i = 0; i <= g->n; i++) free(g->inadj[i].nb); free(g->inadj); }
	free(g->adjm);
	g->outadj = NULL; g->inadj = NULL; g->adjm = NULL;
}

/* Term-major evaluation of every alternative j of `actor': chg[k*(n+1)+j]
   receives term k's change statistic, u[j] the utility (sum over k of
   theta[k]*chg, accumulated in term order exactly as the per-alternative
   loop it replaces), and the maximum utility (including "stay" = 0) is
   returned. Alternatives excluded by composition change are skipped (u
   and chg left untouched there; callers never read them). */
static __thread double *saom_c4buf = NULL;
static __thread long saom_c4cap = 0;

static double eval_network_alternatives(const model_t *M, const simparams_t *P, graph_t *g,
	double **attrs, long actor, const double *presentArr, double *tt_arr, double *c3_arr,
	double *chg, double *u, unsigned char *ijx) {

	long n = M->n, j, k, stride = n + 1;
	const unsigned char *row = g->adjm ? g->adjm + actor * stride : NULL;
	double maxu = 0.0;

	for (j = 1; j <= n; j++) ijx[j] = row ? row[j] : (unsigned char)has_edge(g, actor, j);

	for (k = 0; k < M->nterms; k++) {
		double *c = chg + k * stride;
		int tc = M->termcodes[k];
#ifdef SAOM_PROFILE
		double pt0 = prof_now();
#endif
		double *a = (tc != TERMCODE_INTERACT2 && tc != TERMCODE_INTERACT3 && M->attridx[k] > 0) ? attrs[M->attridx[k] - 1] : NULL;
		double p1 = M->p1[k];
		switch (tc) {
			case TERMCODE_OUTDEGREE:
				for (j = 1; j <= n; j++) c[j] = ijx[j] ? -1.0 : 1.0;
				break;
			case TERMCODE_RECIPROCITY:
				if (g->adjm) {
					const unsigned char *col = g->adjm + actor;
					for (j = 1; j <= n; j++) c[j] = col[j * stride] ? (ijx[j] ? -1.0 : 1.0) : 0.0;
				}
				else for (j = 1; j <= n; j++) c[j] = has_edge(g, j, actor) ? (ijx[j] ? -1.0 : 1.0) : 0.0;
				break;
			case TERMCODE_NODEMATCH:
				for (j = 1; j <= n; j++) c[j] = (a[actor] != a[j]) ? 0.0 : (ijx[j] ? -1.0 : 1.0);
				break;
			case TERMCODE_NODECOV:
				for (j = 1; j <= n; j++) { double v = a[actor] + a[j]; c[j] = ijx[j] ? -v : v; }
				break;
			case TERMCODE_NODEICOV:
				for (j = 1; j <= n; j++) c[j] = ijx[j] ? -a[j] : a[j];
				break;
			case TERMCODE_NODEOCOV:
				for (j = 1; j <= n; j++) c[j] = ijx[j] ? -a[actor] : a[actor];
				break;
			case TERMCODE_TRANSTRIP:
				for (j = 1; j <= n; j++) c[j] = ijx[j] ? -tt_arr[j] : tt_arr[j];
				break;
			case TERMCODE_CYCLE3:
				for (j = 1; j <= n; j++) c[j] = ijx[j] ? -c3_arr[j] : c3_arr[j];
				break;
			case TERMCODE_CYCLE4:
				if (g->outadj && g->inadj) {
					if (saom_c4cap < n + 1) { free(saom_c4buf); saom_c4buf = (double *)malloc((size_t)(n + 1) * sizeof(double)); saom_c4cap = n + 1; }
					memset(saom_c4buf, 0, (size_t)(n + 1) * sizeof(double));
					batch_cycle4(g, actor, saom_c4buf);
					for (j = 1; j <= n; j++) c[j] = ijx[j] ? -saom_c4buf[j] : saom_c4buf[j];
				}
				else for (j = 1; j <= n; j++) {
					if (j == actor) continue;
					if (presentArr && presentArr[j] == 0.0) continue;
					c[j] = saom_eval_change((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs, g, actor, j, ijx[j], tt_arr, c3_arr);
				}
				break;
			case TERMCODE_SIMCOV:
				for (j = 1; j <= n; j++) { double d = 1.0 - fabs(a[actor] - a[j]) - p1; c[j] = ijx[j] ? -d : d; }
				break;
			case TERMCODE_BEHSIM:
				for (j = 1; j <= n; j++) { double d = 1.0 - fabs(a[actor] - a[j]) / saom_behsim_range - p1; c[j] = ijx[j] ? -d : d; }
				break;
			default:
				for (j = 1; j <= n; j++) {
					if (j == actor) continue;
					if (presentArr && presentArr[j] == 0.0) continue;
					c[j] = saom_eval_change((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs, g, actor, j, ijx[j], tt_arr, c3_arr);
				}
				break;
		}
		/* protocol 11, endowment/creation (SaomNetworkFullChangeGated()):
		   an endowment term counts only for withdrawals, a creation term
		   only for new ties */
		if (M->hasfntype && M->fntype[k] != 0) {
			if (M->fntype[k] == 1) { for (j = 1; j <= n; j++) if (!ijx[j]) c[j] = 0.0; }
			else { for (j = 1; j <= n; j++) if (ijx[j]) c[j] = 0.0; }
		}
#ifdef SAOM_PROFILE
		prof_term_t[k] += prof_now() - pt0;
		prof_term_n[k] += 1.0;
#endif
	}
	for (j = 1; j <= n; j++) {
		double uj = 0.0;
		if (j == actor) continue;
		if (presentArr && presentArr[j] == 0.0) continue;
		for (k = 0; k < M->nterms; k++) uj += P->theta[k] * chg[k * stride + j];
		u[j] = uj;
		if (uj > maxu) maxu = uj;
	}
	return maxu;
}

/* Lagged/end behavior statistics on graph `gs' (edge list read directly),
   behavior values `bz' (already masked by the caller). */
static void beh_stats_on_edges(const model_t *M, long ne, const long *ei, const long *ej,
	const double *bz, double *out) {
	long n = M->n, i, d, k;
	double *sumz = (double *)calloc((size_t)(n + 1), sizeof(double));
	double *sumabs = (double *)calloc((size_t)(n + 1), sizeof(double));
	double *odl = (double *)calloc((size_t)(n + 1), sizeof(double));
	for (d = 0; d < ne; d++) {
		odl[ei[d]] += 1.0;
		sumz[ei[d]] += bz[ej[d]];
	}
	for (d = 0; d < ne; d++) sumabs[ei[d]] += fabs(bz[ej[d]] - bz[ei[d]]);
	graph_t gl; int haveg = 0;
	for (k = 0; k < M->nbehterms; k++) {
		double tot = 0.0;
		switch (M->behtermcodes[k]) {
			case TERMCODE_BEH_LINEAR:
				for (i = 1; i <= n; i++) tot += bz[i];
				break;
			case TERMCODE_BEH_QUADRATIC:
				for (i = 1; i <= n; i++) tot += bz[i] * bz[i];
				break;
			case TERMCODE_BEH_AVALT:
				for (i = 1; i <= n; i++) if (odl[i] > 0.0) tot += (bz[i] - M->behOverallMean) * (sumz[i] / odl[i] - M->behOverallMean);
				break;
			case TERMCODE_BEH_AVSIM:
				for (i = 1; i <= n; i++) if (odl[i] > 0.0) tot += 1.0 - (sumabs[i] / M->behrange) / odl[i] - M->behSimMean;
				break;
			default:
				if (M->behtermcodes[k] >= TERMCODE_BEH_INDEG) {		// network-position / alter effects: evaluate on a graph of the edge list
					if (!haveg) { graph_init(&gl, n, 1, ne); for (d = 0; d < ne; d++) toggle(&gl, ei[d], ej[d]); haveg = 1; }
					tot = saom_beh_stat_term(&gl, (double *)bz, M->behtermcodes[k], M->behrange, M->behSimMean, M->behOverallMean);
				}
				break;
		}
		out[k] = tot;
	}
	if (haveg) graph_free(&gl);
	free(sumz); free(sumabs); free(odl);
}

/* RSiena's behavior endowment statistic (protocol 12; see
   SaomBehaviorPatchEndowCreation() in unw_saom.do): the sum over actors
   with dd > 0 of the effect's egoEndowmentStatistic(dd, c), c the centred
   current values, dd = initial - current (both 0 for missing actors), the
   alters from the (masked) starting network's ties li -> lj. The creation
   statistic is minus this with -dd. */
static double beh_endow_stat(int code, long n, long ne, const long *li, const long *lj,
	const double *c, const double *dd, const double *missb) {
	long i, e;
	double s = 0.0;
	if (code == TERMCODE_BEH_LINEAR) {
		for (i = 1; i <= n; i++) if (dd[i] > 0) s -= dd[i];
		return s;
	}
	if (code == TERMCODE_BEH_QUADRATIC) {
		for (i = 1; i <= n; i++) if (dd[i] > 0) s += c[i] * c[i] - (c[i] + dd[i]) * (c[i] + dd[i]);
		return s;
	}
	{
		double *a = (double *)calloc((size_t)(n + 1), sizeof(double));
		double *b = (double *)calloc((size_t)(n + 1), sizeof(double));
		double *k = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (e = 0; e < ne; e++) {
			long ei = li[e], ej = lj[e];
			if (code == TERMCODE_BEH_AVALT) {
				a[ei] += c[ej];
				b[ei] += c[ej] + dd[ej];
				k[ei] += 1.0;
			}
			else {
				if (missb && missb[ej] != 0.0) continue;
				a[ei] += fabs(c[ej] - c[ei]);
				b[ei] += fabs(c[ej] + dd[ej] - c[ei] - dd[ei]);
				k[ei] += 1.0;
			}
		}
		for (i = 1; i <= n; i++) {
			if (dd[i] <= 0 || k[i] == 0.0) continue;
			if (code == TERMCODE_BEH_AVALT) s += (c[i] * a[i] - (c[i] + dd[i]) * b[i]) / k[i];
			else {
				if (missb && missb[i] != 0.0) continue;
				s += (a[i] - b[i]) / k[i];
			}
		}
		free(a); free(b); free(k);
	}
	return s;
}

/* protocol 42: RSiena's structural rate effects (outRate, inRate, recipRate and the Inv / Log versions of StructuralRateEffect): the covariate of
   actor a is f(degree), type 1 out, 2 in, 3 reciprocal; 4-6 1/(d+1) of out / in / reciprocal degree; 7-9 log(d+1) of them */
static double sr_value(graph_t *g, int type, long a) {
	double d;
	int kind = (type <= 3) ? type : ((type <= 6) ? type - 3 : type - 6);
	d = (kind == 1) ? (double)g->dout[a] : (kind == 2 ? (double)g->din[a] : (double)saom_recdeg(g, a));
	if (type <= 3) return d;
	if (type <= 6) return 1.0 / (d + 1.0);
	return log(d + 1.0);
}

static int simulate_period(const model_t *M, const period_t *PD, const simparams_t *P,
	unsigned long long seed, int keep_final, simres_t *R) {

	long n = M->n, i, k, stride = n + 1;
	graph_t g, gm, g0s;
	int have_gm = 0;
	rng_t rng;
	{ int jc; for (jc = 0; jc < 8; jc++) { saom_tl_cov[jc] = PD->bcov[jc]; saom_tl_bdy[jc] = PD->bdy[jc]; } }
	saom_tl_beh0 = PD->beh0;
	saom_tl_behscale = (M->behrange > 0.0) ? 1.0 / M->behrange : 1.0;
	saom_tl_behvar = M->behVariance;
	double t, steps = 0.0, nchanges = 0.0, nchangesBeh = 0.0, stepsNet = 0.0, stepsBeh = 0.0;
	double *behval = NULL, *attrs[MAXATTR + 1];
	double *behc = NULL, *behc0 = NULL;		// protocol 45: centred live / starting behavior for the network terms that read it
	double *dyncov[8] = {NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};	// protocol 53: live copies of the covariate slots that are another behavior
	double *behvalb[MAXBEH];		// protocol 19: current values of every behavior (behvalb[0] == behval)
	double xsteps[MAXBEH], xnch[MAXBEH];	// ministeps / changes of behaviors 1..
	int bsel;
	long b;
	dyadht_t horig, missht;
	long simDist = 0;
	long npresent = n;
	long *presentIdxArr = NULL;
	double *presloc = NULL;		/* protocol 27: the active set while the period's composition changes */
	double *wbase_rc = NULL;
	dyadht_t hstart;
	long evi = 0;
	double *wfull_rc = NULL, totw_rc = 0.0, covrateSum_rc[MAXRC], rcscore[MAXRC];
	long krc, nrc = P->hasratecov;
	double *rcval = NULL;
	const double *rcv = P->ratecovattr;
	int condcap = 0;
	int hasmiss = PD->hasmiss;

	PROF_START(pt_setup);
	memset(R, 0, sizeof(simres_t));
	for (k = 0; k < M->nattr; k++) attrs[k] = PD->xattr[k] ? PD->xattr[k] : M->attrs[k];
	attrs[M->nattr] = NULL;
	attrs[M->nattr + 1] = NULL;

	graph_init(&g, n, M->need_adj, PD->nties);
	for (i = 0; i < PD->nties; i++) toggle(&g, PD->ti[i], PD->tj[i]);
	if (M->has_start) {
		graph_init(&g0s, n, 1, PD->nties);
		for (i = 0; i < PD->nties; i++) toggle(&g0s, PD->ti[i], PD->tj[i]);
		saom_tl_g0 = &g0s;
	}
	else saom_tl_g0 = NULL;

	if (P->condmode) {
		ht_alloc(&horig, ht_next_pow2(PD->nties * 2 + 16));
		for (i = 0; i < g.nties; i++) ht_put(&horig, dyadkey(&g, g.elist_i[i], g.elist_j[i]), 1);
	}
	for (b = 0; b < MAXBEH; b++) { behvalb[b] = NULL; xsteps[b] = 0.0; xnch[b] = 0.0; }
	if (M->nbehterms > 0) {
		behval = (double *)malloc((size_t)(n + 1) * sizeof(double));
		memcpy(behval, PD->beh0, (size_t)(n + 1) * sizeof(double));
		if (M->has_behsim) attrs[M->nattr] = behval;
		behvalb[0] = behval;
		if (M->has_behcov) {
			long q;
			behc = (double *)calloc((size_t)(n + 1), sizeof(double));
			behc0 = (double *)calloc((size_t)(n + 1), sizeof(double));
			for (q = 1; q <= n; q++) { behc[q] = behval[q] - M->behOverallMean; behc0[q] = PD->beh0[q] - M->behOverallMean; }
			attrs[M->nattr + 1] = behc;
		}
		for (b = 1; b < M->nbeh; b++) {
			behvalb[b] = (double *)malloc((size_t)(n + 1) * sizeof(double));
			memcpy(behvalb[b], PD->xbeh0[b], (size_t)(n + 1) * sizeof(double));
		}
		{
			int sl2;
			for (sl2 = 0; sl2 < 8; sl2++) {
				dyncov[sl2] = NULL;
				if (saom_bcov_dyn[sl2] >= 1 && saom_bcov_dyn[sl2] < M->nbeh && PD->bcov[sl2]) {
					dyncov[sl2] = (double *)malloc((size_t)(n + 1) * sizeof(double));
					memcpy(dyncov[sl2], PD->bcov[sl2], (size_t)(n + 1) * sizeof(double));
					saom_tl_cov[sl2] = dyncov[sl2];
				}
			}
		}
	}
	if (hasmiss) {
		ht_alloc(&missht, ht_next_pow2(PD->nmiss * 2 + 16));
		for (i = 0; i < PD->nmiss; i++) ht_put(&missht, dyadkey(&g, PD->mi[i], PD->mj[i]), 1);
	}
	if (PD->haspresent) {
		presentIdxArr = (long *)malloc((size_t)n * sizeof(long));
		npresent = 0;
		for (i = 1; i <= n; i++) if (PD->present[i] != 0.0) presentIdxArr[npresent++] = i;
	}
	if (PD->nev > 0 && PD->haspresent) {
		presloc = (double *)malloc((size_t)(n + 1) * sizeof(double));
		memcpy(presloc, PD->present, (size_t)(n + 1) * sizeof(double));
		ht_alloc(&hstart, ht_next_pow2(PD->nties * 2 + 16));
		for (i = 0; i < PD->nties; i++) ht_put(&hstart, dyadkey(&g, PD->ti[i], PD->tj[i]), 1);
	}

	rng_seed(&rng, seed);
	t = 0.0;
	PROF_ADD(PR_SETUP, pt_setup);
	{
		double *u = (double *)malloc((size_t)(n + 1) * sizeof(double));
		double *ev = (double *)malloc((size_t)(n + 1) * sizeof(double));
		double *availbuf = (M->nstruct > 0) ? (double *)malloc((size_t)(n + 1) * sizeof(double)) : NULL;
		double *tt_arr = M->need_transtrip ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
		double *c3_arr = M->need_cycle3 ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
		double *chg = (double *)malloc((size_t)(n + 1) * (size_t)(M->nterms > 0 ? M->nterms : 1) * sizeof(double));
		unsigned char *ijx = (unsigned char *)malloc((size_t)(n + 1));
		double *score = R->score;
		double *scoreBeh = R->scoreBeh;
		double rate = P->rate, rateBeh = P->rateBeh;
		double grandRate;
		int symB = (P->symtype == 1 || P->symtype == 2 || P->symtype == 3);
		double sumw2_rc = 0.0, sumw2x_rc[MAXRC], Sp_rc[MAXRC], symGfac_rc = 0.0, symdlogG_rc[MAXRC];
		for (krc = 0; krc < MAXRC; krc++) { covrateSum_rc[krc] = 0.0; rcscore[krc] = 0.0; sumw2x_rc[krc] = 0.0; Sp_rc[krc] = 0.0; symdlogG_rc[krc] = 0.0; }
		if (P->hasratecov) {
			/* K covariates (protocol 9): w_i = exp(sum_k b_k x_ik); every
			   score term below is linear in the covariate, one per k */
			wfull_rc = (double *)malloc((size_t)n * sizeof(double));
			wbase_rc = (double *)malloc((size_t)n * sizeof(double));
			if (P->nsr > 0) { rcval = (double *)malloc((size_t)(n * nrc) * sizeof(double)); memcpy(rcval, P->ratecovattr, (size_t)(n * nrc) * sizeof(double)); rcv = rcval; }
			for (i = 0; i < n; i++) {
				double eta = 0.0;
				for (krc = 0; krc < nrc; krc++) eta += P->ratecoef[krc] * rcv[krc * n + i];
				wfull_rc[i] = exp(eta);
				wbase_rc[i] = wfull_rc[i];
				/* composition change: an absent actor has rate 0 (RSiena's calculateRates()) */
				if (PD->haspresent && PD->present[i + 1] == 0.0) wfull_rc[i] = 0.0;
				/* a two-mode network: a node with no free alternative (an event) never acts */
				if (M->nstruct > 0 && M->struct_off[i + 2] - M->struct_off[i + 1] >= n - 1) { wfull_rc[i] = 0.0; wbase_rc[i] = 0.0; }
				totw_rc += wfull_rc[i];
				sumw2_rc += wfull_rc[i] * wfull_rc[i];
				for (krc = 0; krc < nrc; krc++) {
					Sp_rc[krc] += rcv[krc * n + i] * wfull_rc[i];
					sumw2x_rc[krc] += wfull_rc[i] * wfull_rc[i] * rcv[krc * n + i];
				}
			}
			for (krc = 0; krc < nrc; krc++) covrateSum_rc[krc] = rate * Sp_rc[krc];
			if (symB) {
				/* RSiena's pairwise (B) model types with a rate covariate
				   (DependentVariable::calculateRates(), NetworkVariable::
				   calculateModelTypeBProbabilities()): actor rates
				   lambda_i = lambda * w_i, total rate (sum lambda_i)^2 -
				   sum lambda_i^2, the actor drawn proportional to w_i and
				   the alter proportional to w_j among the others.  Here
				   rate = lambda^2 * (n - 1), the scale on which the rate
				   of the model without covariate is the per-actor rate. */
				symGfac_rc = (totw_rc * totw_rc - sumw2_rc) / (double)(n - 1);
				for (krc = 0; krc < nrc; krc++) {
					covrateSum_rc[krc] = rate * (2.0 * totw_rc * Sp_rc[krc] - 2.0 * sumw2x_rc[krc]) / (double)(n - 1);
					symdlogG_rc[krc] = (2.0 * totw_rc * Sp_rc[krc] - 2.0 * sumw2x_rc[krc]) / (totw_rc * totw_rc - sumw2_rc);
				}
			}
		}
		grandRate = P->hasratecov ? (symB ? rate * symGfac_rc : rate * totw_rc) : ((double)npresent * rate + (double)npresent * (M->nbehterms > 0 ? rateBeh : 0.0));
		if (M->nbeh > 1) for (b = 1; b < M->nbeh; b++) grandRate += (double)npresent * P->xrateBeh[b];
		/* conditional mode (RSiena's conditional estimation): steps until
		   the distance from the starting network reaches the target, at
		   least one step (EpochSimulation::runEpoch() checks after each
		   step); dyads missing at either end of the period do not count */
		while (P->condmode ? (steps == 0.0 || simDist < P->targetChange) : (t < 1.0)) {
			/* RSiena's guard (EpochSimulation::runEpoch(): "Unlikely to
			   terminate this epoch: more than 1000000 steps"): a
			   conditional period that does not reach the observed distance
			   within a million ministeps is abandoned; the time is then
			   returned as missing (SV_missval), which the caller reports */
			if (P->condmode && steps >= 1000000.0) { condcap = 1; break; }
			double dt_rc = -log(rng_unif(&rng)) / grandRate;
			/* protocol 27: composition change at fractional times (EpochSimulation::makeNextCompositionChange()):
			   an event that falls before the next ministep is made first and the waiting time redrawn */
			while (presloc && evi < PD->nev && PD->evt[evi] <= t + dt_rc) {
				long ea = PD->eva[evi], ej;
				double te = PD->evt[evi];
				if (P->hasratecov && P->want_score) for (krc = 0; krc < nrc; krc++) rcscore[krc] -= (te - t) * covrateSum_rc[krc];
				t = te;
				if (PD->evk[evi] == 1) {
					presloc[ea] = 1.0;
					/* a joiner switches on the ties of the start network to the active actors (actOnJoiner()) */
					for (ej = 1; ej <= n; ej++) {
						long dv;
						if (ej == ea || presloc[ej] == 0.0) continue;
						if (ht_get(&hstart, dyadkey(&g, ea, ej), &dv) && !has_edge(&g, ea, ej)) toggle(&g, ea, ej);
						if (ht_get(&hstart, dyadkey(&g, ej, ea), &dv) && !has_edge(&g, ej, ea)) toggle(&g, ej, ea);
					}
				}
				else {
					presloc[ea] = 0.0;
					/* a leaver loses all its ties (actOnLeaver()) */
					for (ej = 1; ej <= n; ej++) {
						if (ej == ea) continue;
						if (has_edge(&g, ea, ej)) toggle(&g, ea, ej);
						if (has_edge(&g, ej, ea)) toggle(&g, ej, ea);
					}
				}
				npresent = 0;
				for (i = 1; i <= n; i++) if (presloc[i] != 0.0) presentIdxArr[npresent++] = i;
				if (P->hasratecov) {
					totw_rc = 0.0;
					sumw2_rc = 0.0;
					for (krc = 0; krc < MAXRC; krc++) { Sp_rc[krc] = 0.0; sumw2x_rc[krc] = 0.0; }
					for (i = 0; i < n; i++) {
						wfull_rc[i] = (presloc[i + 1] != 0.0) ? wbase_rc[i] : 0.0;
						totw_rc += wfull_rc[i];
						sumw2_rc += wfull_rc[i] * wfull_rc[i];
						for (krc = 0; krc < nrc; krc++) {
							Sp_rc[krc] += rcv[krc * n + i] * wfull_rc[i];
							sumw2x_rc[krc] += wfull_rc[i] * wfull_rc[i] * rcv[krc * n + i];
						}
					}
					for (krc = 0; krc < nrc; krc++) covrateSum_rc[krc] = rate * Sp_rc[krc];
					if (symB) {
						symGfac_rc = (totw_rc * totw_rc - sumw2_rc) / (double)(n - 1);
						for (krc = 0; krc < nrc; krc++) {
							covrateSum_rc[krc] = rate * (2.0 * totw_rc * Sp_rc[krc] - 2.0 * sumw2x_rc[krc]) / (double)(n - 1);
							symdlogG_rc[krc] = (2.0 * totw_rc * Sp_rc[krc] - 2.0 * sumw2x_rc[krc]) / (totw_rc * totw_rc - sumw2_rc);
						}
					}
				}
				grandRate = P->hasratecov ? (symB ? rate * symGfac_rc : rate * totw_rc) : ((double)npresent * rate + (double)npresent * (M->nbehterms > 0 ? rateBeh : 0.0));
				if (M->nbeh > 1) for (b = 1; b < M->nbeh; b++) grandRate += (double)npresent * P->xrateBeh[b];
				evi++;
				dt_rc = -log(rng_unif(&rng)) / grandRate;
			}
			t += dt_rc;
			if (P->hasratecov && P->want_score && (P->condmode || t < 1.0)) for (krc = 0; krc < nrc; krc++) rcscore[krc] -= dt_rc * covrateSum_rc[krc];
			if (P->condmode || t < 1.0) {
				int actNet = 1;
				bsel = 0;
				if (M->nbehterms > 0) {
					double uvar = rng_unif(&rng) * grandRate;
					actNet = (uvar <= (double)npresent * rate);
					if (!actNet && M->nbeh > 1) {
						/* protocol 19: the acting behavior in proportion to its rate (the same single uniform) */
						double rem = uvar - (double)npresent * rate;
						for (b = 0; b < M->nbeh; b++) {
							double rb = (double)npresent * (b == 0 ? rateBeh : P->xrateBeh[b]);
							if (rem <= rb || b == M->nbeh - 1) { bsel = (int)b; break; }
							rem -= rb;
						}
					}
				}
				if (actNet && (P->symtype == 1 || P->symtype == 2 || P->symtype == 3)) {
					/* B-family symmetric ministep - see the long comment in the
					   pre-rewrite stata_call() (git history) for the derivation;
					   logic unchanged. */
					long actor;
					long alter;
					int ij_exists, accepted;
					double u_actor = 0.0, u_alter = 0.0, prob, pEgo = 0.0, pAlt = 0.0;
					double chg_actor[MAXTERMS], chg_alter[MAXTERMS];
					/* ratecov(): the acting actor is drawn with probability
					   proportional to exp(ratecoef * x_i), as in the directed
					   branch below (before 2026-10-01 this branch drew
					   uniformly, so the covariate only rescaled the rate) */
					if (P->hasratecov) {
						double drawA = rng_unif(&rng) * totw_rc, cumA = 0.0;
						long ii;
						actor = n;
						for (ii = 0; ii < n; ii++) {
							cumA += wfull_rc[ii];
							if (drawA <= cumA) { actor = ii + 1; break; }
						}
						if (P->want_score) for (krc = 0; krc < nrc; krc++) rcscore[krc] += rcv[krc * n + actor - 1];
					}
					else actor = PD->haspresent ? presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)] : 1 + (long)(rng_unif(&rng) * (double)n);
					if (P->hasratecov) {
						/* alter proportional to w_j among the others: RSiena's
						   calculateModelTypeBProbabilities() redraws while the
						   alter is the actor, which is the same distribution;
						   drawn here directly from the others, so that an actor
						   holding nearly all the weight cannot stall the loop.
						   Then the score of log P(actor, alter) and of
						   log(total rate). */
						{
							double drawB = rng_unif(&rng) * (totw_rc - wfull_rc[actor - 1]), cumB = 0.0;
							long jj;
							alter = (actor == n) ? n - 1 : n;
							for (jj = 0; jj < n; jj++) {
								if (jj == actor - 1) continue;
								cumB += wfull_rc[jj];
								if (drawB <= cumB) { alter = jj + 1; break; }
							}
						}
						if (P->want_score) {
							double wa = wfull_rc[actor - 1];
							for (krc = 0; krc < nrc; krc++)
								rcscore[krc] += rcv[krc * n + alter - 1] - Sp_rc[krc] / totw_rc
									- (Sp_rc[krc] - wa * rcv[krc * n + actor - 1]) / (totw_rc - wa)
									+ symdlogG_rc[krc];
						}
					}
					else {
						/* RSiena (calculateModelTypeBProbabilities()): the alter is drawn in proportion to the alters' RATES, which are 0 for an
						   inactive actor - unlike the directed and the unilateral models, where inactive actors stay among the alters */
						if (PD->haspresent) { do { alter = presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)]; } while (alter == actor); }
						else { do { alter = 1 + (long)(rng_unif(&rng) * (double)n); } while (alter == actor); }
					}
					ij_exists = has_edge(&g, actor, alter);
					for (k = 0; k < M->nterms; k++) {
						double cv_actor = saom_eval_change((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs, &g, actor, alter, ij_exists, NULL, NULL);
						double cv_alter = saom_eval_change((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs, &g, alter, actor, ij_exists, NULL, NULL);
						u_actor += P->theta[k] * cv_actor;
						u_alter += P->theta[k] * cv_alter;
						chg_actor[k] = cv_actor;
						chg_alter[k] = cv_alter;
					}
					/* acceptance probabilities (RSiena's pairwise model types):
					   BFORCE (modelType 4) the actor alone, sigma(u_actor);
					   BAGREE (5) creation needs both, pEgo*pAlt, deletion either,
					   pEgo + pAlt - pEgo*pAlt; BJOINT (6) sigma(u_actor + u_alter).
					   For BAGREE RSiena 1.6.6 (NetworkVariable.cpp,
					   calculateSymmetricTieFlipProbabilities()) computes the alter's
					   probability as 1/(1+exp(u_alter)) when u_alter > 0 and as
					   exp(u_alter)/(1+exp(u_alter)) otherwise, i.e.
					   sigma(-|u_alter|); reproduced here as is. Before 2026-10-01
					   nwsaom used sigma(-u_alter) throughout (the first branch
					   only). Scores: RSiena's accumulateSymmetricModelScores(). */
					if (P->symtype == 2) prob = stable_logistic(u_actor);
					else if (P->symtype == 3) {
						pEgo = stable_logistic(u_actor);
						pAlt = stable_logistic(-fabs(u_alter));
						prob = ij_exists ? (pEgo + pAlt - pEgo * pAlt) : (pEgo * pAlt);
					}
					else prob = stable_logistic(u_actor + u_alter);
					accepted = (rng_unif(&rng) < prob);
					if (P->want_score) {
						/* d log P(outcome) / d theta for the model type (the
						   score-function Jacobian of phases 1 and 3) */
						for (k = 0; k < M->nterms; k++) {
							double sk;
							if (P->symtype == 2) sk = ((accepted ? 1.0 : 0.0) - prob) * chg_actor[k];
							else if (P->symtype == 3) {
								if (!ij_exists) {
									double g = (1.0 - pEgo) * chg_actor[k] + (1.0 - pAlt) * chg_alter[k];
									sk = accepted ? g : -prob * g / (1.0 - prob);
								}
								else {
									if (accepted) sk = (pEgo * (1.0 - pEgo) * (1.0 - pAlt) * chg_actor[k] + pAlt * (1.0 - pAlt) * (1.0 - pEgo) * chg_alter[k]) / prob;
									else sk = -(pEgo * chg_actor[k] + pAlt * chg_alter[k]);
								}
							}
							else sk = ((accepted ? 1.0 : 0.0) - prob) * (chg_actor[k] + chg_alter[k]);
							score[k] += sk;
						}
					}
					stepsNet += 1.0;
					if (accepted) {
						toggle(&g, actor, alter);
						toggle(&g, alter, actor);
						nchanges += 1.0;
						if (rcval && wfull_rc) {
							/* protocol 70: structural rate covariates in a pairwise (non-directed) model: the two actors' covariates follow
							   the network, the sums behind the total rate (sum w)^2 - sum w^2 and its score are rebuilt */
							long aa[2], q;
							aa[0] = actor; aa[1] = alter;
							for (q = 0; q < 2; q++) {
								long a0 = aa[q] - 1, s2;
								double eta = 0.0;
								for (s2 = 0; s2 < P->nsr; s2++) rcval[(nrc - P->nsr + s2) * n + a0] = sr_value(&g, P->srtype[s2], aa[q]);
								for (krc = 0; krc < nrc; krc++) eta += P->ratecoef[krc] * rcval[krc * n + a0];
								wfull_rc[a0] = exp(eta); wbase_rc[a0] = wfull_rc[a0];
							}
							totw_rc = 0.0; sumw2_rc = 0.0;
							for (krc = 0; krc < nrc; krc++) { Sp_rc[krc] = 0.0; sumw2x_rc[krc] = 0.0; }
							for (i = 0; i < n; i++) {
								totw_rc += wfull_rc[i];
								sumw2_rc += wfull_rc[i] * wfull_rc[i];
								for (krc = 0; krc < nrc; krc++) {
									Sp_rc[krc] += rcval[krc * n + i] * wfull_rc[i];
									sumw2x_rc[krc] += wfull_rc[i] * wfull_rc[i] * rcval[krc * n + i];
								}
							}
							symGfac_rc = (totw_rc * totw_rc - sumw2_rc) / (double)(n - 1);
							for (krc = 0; krc < nrc; krc++) {
								covrateSum_rc[krc] = rate * (2.0 * totw_rc * Sp_rc[krc] - 2.0 * sumw2x_rc[krc]) / (double)(n - 1);
								symdlogG_rc[krc] = (2.0 * totw_rc * Sp_rc[krc] - 2.0 * sumw2x_rc[krc]) / (totw_rc * totw_rc - sumw2_rc);
							}
							grandRate = rate * symGfac_rc;
						}
						/* both arcs change: distance steps of two, as RSiena's
						   symmetric networks */
						if (P->condmode) {
							long origval;
							if (!(hasmiss && ht_get(&missht, dyadkey(&g, actor, alter), &origval))) {
								int newstate = has_edge(&g, actor, alter);
								int origstate = ht_get(&horig, dyadkey(&g, actor, alter), &origval);
								if (newstate == origstate) simDist -= 2; else simDist += 2;
							}
						}
					}
				}
				else if (actNet) {
					long actor, j, choice;
					const double *avail;
					double maxu, stayterm, denom, draw, cum;
					PROF_START(pt_a);
					if (P->hasratecov) {
						double drawA = rng_unif(&rng) * totw_rc, cumA = 0.0;
						long ii;
						actor = n;
						for (ii = 0; ii < n; ii++) {
							cumA += wfull_rc[ii];
							if (drawA <= cumA) { actor = ii + 1; break; }
						}
						if (P->want_score) for (krc = 0; krc < nrc; krc++) rcscore[krc] += rcv[krc * n + actor - 1];
					} else {
						actor = PD->haspresent ? presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)] : 1 + (long)(rng_unif(&rng) * (double)n);
					}

					if (M->need_transtrip) {
						memset(tt_arr, 0, (size_t)(n + 1) * sizeof(double));
						batch_otp_plus_osp(&g, actor, tt_arr);
					}
					if (M->need_cycle3) {
						memset(c3_arr, 0, (size_t)(n + 1) * sizeof(double));
						batch_otp_reverse(&g, actor, c3_arr);
					}

					PROF_ADD(PR_ACTOR, pt_a);
					PROF_START(pt_e);
					/* protocol 11, structural(): fixed dyads of the actor are
					   not among its alternatives (as absent actors) */
					avail = NULL;	/* RSiena: an inactive actor stays among the alters of an active ego (NetworkVariable::calculatePermissibleChanges()) */
					if (M->nstruct > 0 && M->struct_off[actor + 1] > M->struct_off[actor]) {
						long q;
						for (j = 1; j <= n; j++) availbuf[j] = 1.0;
						for (q = M->struct_off[actor]; q < M->struct_off[actor + 1]; q++) availbuf[M->struct_j[q]] = 0.0;
						avail = availbuf;
					}
					maxu = eval_network_alternatives(M, P, &g, attrs, actor, avail, tt_arr, c3_arr, chg, u, ijx);
					PROF_ADD(PR_EVAL, pt_e);
					PROF_START(pt_s);

					stayterm = exp(0.0 - maxu);
					denom = stayterm;
					for (j = 1; j <= n; j++) {
						if (j == actor) continue;
						if (avail && avail[j] == 0.0) continue;
						ev[j] = exp(u[j] - maxu);
						denom += ev[j];
					}

					draw = rng_unif(&rng) * denom;
					cum = stayterm;
					choice = 0;
					if (draw > cum) {
						for (j = 1; j <= n; j++) {
							if (j == actor) continue;
							if (avail && avail[j] == 0.0) continue;
							cum += ev[j];
							choice = j;
							if (draw <= cum) break;
						}
					}
					if (P->want_score) {
						for (k = 0; k < M->nterms; k++) {
							double ebar_k = 0.0, chosen_k;
							const double *c = chg + k * stride;
							for (j = 1; j <= n; j++) {
								if (j == actor) continue;
								if (avail && avail[j] == 0.0) continue;
								ebar_k += (ev[j] / denom) * c[j];
							}
							chosen_k = (choice != 0) ? c[choice] : 0.0;
							score[k] += chosen_k - ebar_k;
						}
					}
					stepsNet += 1.0;
					PROF_ADD(PR_SOFTMAX, pt_s);
					if (choice != 0) {
						/* non-directed relation, unilateral initiative (RSiena
						   modelType 2 AFORCE, 3 AAGREE; NetworkVariable::
						   makeChange()): the actor chooses as in the directed
						   model; the tie then changes in both directions, for
						   AAGREE a new tie only if the alter confirms it, with
						   probability sigma(alter's utility of the change)
						   (checkAlterAgreement(); score addAlterAgreementScores()).
						   RSiena also runs the confirmation for the no-change
						   option (alter == ego), which changes nothing; not
						   reproduced. */
						int symA = (P->symtype == 4 || P->symtype == 5);
						int doit = 1;
						if (P->symtype == 5 && !ijx[choice]) {
							double ua = 0.0, pa, ca[MAXTERMS];
							for (k = 0; k < M->nterms; k++) {
								ca[k] = saom_eval_change((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs, &g, choice, actor, 0, NULL, NULL);
								ua += P->theta[k] * ca[k];
							}
							pa = stable_logistic(ua);
							doit = (rng_unif(&rng) < pa);
							if (P->want_score) for (k = 0; k < M->nterms; k++) score[k] += (doit ? (1.0 - pa) : -pa) * ca[k];
						}
						if (doit) {
							PROF_START(pt_ap);
							toggle(&g, actor, choice);
							if (symA) toggle(&g, choice, actor);
							PROF_ADD(PR_APPLY, pt_ap);
							nchanges += 1.0;
							if (rcval && wfull_rc) {
								/* protocol 42: the structural rate covariates of the two actors involved change with the network */
								long aa[2], q;
								aa[0] = actor; aa[1] = choice;
								for (q = 0; q < 2; q++) {
									long a0 = aa[q] - 1, s2;
									double wold = wfull_rc[a0], eta = 0.0, wnew;
									if (M->nstruct > 0 && M->struct_off[a0 + 2] - M->struct_off[a0 + 1] >= n - 1) continue;	/* an event of a two-mode network never acts */
									totw_rc -= wold;
									for (krc = 0; krc < nrc; krc++) Sp_rc[krc] -= rcval[krc * n + a0] * wold;
									for (s2 = 0; s2 < P->nsr; s2++) rcval[(nrc - P->nsr + s2) * n + a0] = sr_value(&g, P->srtype[s2], aa[q]);
									for (krc = 0; krc < nrc; krc++) eta += P->ratecoef[krc] * rcval[krc * n + a0];
									wnew = exp(eta);
									wfull_rc[a0] = wnew; wbase_rc[a0] = wnew;
									totw_rc += wnew;
									for (krc = 0; krc < nrc; krc++) Sp_rc[krc] += rcval[krc * n + a0] * wnew;
								}
								for (krc = 0; krc < nrc; krc++) covrateSum_rc[krc] = rate * Sp_rc[krc];
								grandRate = rate * totw_rc;
							}
							if (P->condmode) {
								long origval;
								if (!(hasmiss && ht_get(&missht, dyadkey(&g, actor, choice), &origval))) {
									int newstate = has_edge(&g, actor, choice);
									int origstate = ht_get(&horig, dyadkey(&g, actor, choice), &origval);
									double dstep = symA ? 2.0 : 1.0;
									if (newstate == origstate) simDist -= dstep; else simDist += dstep;
								}
							}
						}
					}
				}
				else {
					PROF_START(pt_b);
					const model_t *Mb = bsel ? M->bm[bsel] : M;
					double *bv = behvalb[bsel];
					const double *thB = P->thetaBeh + M->behoff[bsel];
					double *scB = scoreBeh + M->behoff[bsel];
					long actor = PD->haspresent ? presentIdxArr[(long)(rng_unif(&rng) * (double)npresent)] : 1 + (long)(rng_unif(&rng) * (double)n);
					double cur = bv[actor];
					double chgDown[MAXBEHTERMS], chgUp[MAXBEHTERMS];
					double uDown = 0.0, uUp = 0.0, maxu2 = 0.0, denom2, draw2, diff;
					int hasDown = (cur > Mb->behminval), hasUp = (cur < Mb->behmaxval);

					if (hasDown) {
						for (k = 0; k < Mb->nbehterms; k++) {
							chgDown[k] = (M->hasfntype && Mb->behfntype[k] == 2) ? 0.0 : saom_beh_change_term(&g, bv, Mb->behtermcodes[k], Mb->behOverallMean, Mb->behrange, Mb->behSimMean, actor, -1.0);
							uDown += thB[k] * chgDown[k];
						}
						if (uDown > maxu2) maxu2 = uDown;
					}
					if (hasUp) {
						for (k = 0; k < Mb->nbehterms; k++) {
							chgUp[k] = (M->hasfntype && Mb->behfntype[k] == 1) ? 0.0 : saom_beh_change_term(&g, bv, Mb->behtermcodes[k], Mb->behOverallMean, Mb->behrange, Mb->behSimMean, actor, 1.0);
							uUp += thB[k] * chgUp[k];
						}
						if (uUp > maxu2) maxu2 = uUp;
					}
					denom2 = exp(0.0 - maxu2);
					if (hasDown) denom2 += exp(uDown - maxu2);
					if (hasUp) denom2 += exp(uUp - maxu2);
					if (P->want_score) {
						for (k = 0; k < Mb->nbehterms; k++) {
							double ebar_k = 0.0;
							if (hasDown) ebar_k += (exp(uDown - maxu2) / denom2) * chgDown[k];
							if (hasUp) ebar_k += (exp(uUp - maxu2) / denom2) * chgUp[k];
							scB[k] -= ebar_k;
						}
					}
					draw2 = rng_unif(&rng) * denom2;
					diff = 0.0;
					if (hasDown && draw2 <= exp(uDown - maxu2)) {
						diff = -1.0;
						bv[actor] = cur - 1.0;
						if (behc && bsel == 0) behc[actor] = bv[actor] - M->behOverallMean;
						{ int sl3; for (sl3 = 0; sl3 < 8; sl3++) if (dyncov[sl3] && saom_bcov_dyn[sl3] == bsel) dyncov[sl3][actor] = bv[actor] - Mb->behOverallMean; }
						if (P->want_score) for (k = 0; k < Mb->nbehterms; k++) scB[k] += chgDown[k];
					}
					else {
						if (hasDown) draw2 -= exp(uDown - maxu2);
						if (draw2 <= exp(0.0 - maxu2)) diff = 0.0;
						else {
							diff = 1.0;
							bv[actor] = cur + 1.0;
							if (behc && bsel == 0) behc[actor] = bv[actor] - M->behOverallMean;
							{ int sl3; for (sl3 = 0; sl3 < 8; sl3++) if (dyncov[sl3] && saom_bcov_dyn[sl3] == bsel) dyncov[sl3][actor] = bv[actor] - Mb->behOverallMean; }
							if (P->want_score) for (k = 0; k < Mb->nbehterms; k++) scB[k] += chgUp[k];
						}
					}
					if (diff != 0.0) { if (bsel == 0) nchangesBeh += 1.0; else xnch[bsel] += 1.0; }
					if (bsel == 0) stepsBeh += 1.0; else xsteps[bsel] += 1.0;
					PROF_ADD(PR_BEH, pt_b);
				}
				steps += 1.0;
			}
		}
		/* EpochSimulation::runEpoch(): setLeaversBack() when the period has composition events - the ties and the
		   behavior values of the actors still inactive go back to the start of the period */
		if (presloc) {
			long ia, ja;
			for (ia = 1; ia <= n; ia++) {
				if (presloc[ia] != 0.0) continue;
				for (ja = 1; ja <= n; ja++) {
					long dv;
					if (ja == ia) continue;
					if ((ht_get(&hstart, dyadkey(&g, ia, ja), &dv) ? 1 : 0) != has_edge(&g, ia, ja)) toggle(&g, ia, ja);
					if ((ht_get(&hstart, dyadkey(&g, ja, ia), &dv) ? 1 : 0) != has_edge(&g, ja, ia)) toggle(&g, ja, ia);
				}
				if (M->nbehterms > 0) {
					behval[ia] = PD->beh0[ia];
					for (b = 1; b < M->nbeh; b++) behvalb[b][ia] = PD->xbeh0[b][ia];
				}
			}
			ht_free(&hstart);
		}
		free(u); free(ev); free(tt_arr); free(c3_arr); free(chg); free(ijx); free(availbuf);
	}
	if (presloc) free(presloc);
	if (wbase_rc) free(wbase_rc);
	if (wfull_rc) free(wfull_rc);
	if (rcval) free(rcval);
	if (P->condmode) ht_free(&horig);
	PROF_START(pt_end);

	{ int sl4; for (sl4 = 0; sl4 < 8; sl4++) if (dyncov[sl4]) saom_tl_cov[sl4] = PD->bcov[sl4]; }	/* the statistics read the covariate behaviors at the START of the period (lagged) */
	R->steps = steps; R->stepsNet = stepsNet; R->stepsBeh = stepsBeh;
	R->nchanges = nchanges; R->nchangesBeh = nchangesBeh; R->t = condcap ? SV_missval : t;
	for (b = 1; b < M->nbeh; b++) { R->xstepsBeh[b] = xsteps[b]; R->xnchangesBeh[b] = xnch[b]; }
	for (krc = 0; krc < MAXRC; krc++) R->rcscore[krc] = rcscore[krc];

	/* distances from the start state (the rate statistics of
	   unconditional estimation), missing dyads/actors excluded; the
	   network distance for every model, the behavior distance and the
	   lagged behavior statistics only with a behavior */
	{
		long d, dv;
		double nd = 0.0;
		{
			/* start ties as a hash (or dense) set */
			dyadht_t hs;
			ht_alloc(&hs, ht_next_pow2(PD->nties * 2 + 16));
			for (d = 0; d < PD->nties; d++) ht_put(&hs, dyadkey(&g, PD->ti[d], PD->tj[d]), 1);
			for (d = 0; d < g.nties; d++) {
				long key = dyadkey(&g, g.elist_i[d], g.elist_j[d]);
				if (ht_get(&hs, key, &dv)) continue;
				if (hasmiss && ht_get(&missht, key, &dv)) continue;
				nd += 1.0;
				for (krc = 0; krc < nrc; krc++) R->rcstat[krc] += P->ratecovattr[krc * n + g.elist_i[d] - 1];
			}
			for (d = 0; d < PD->nties; d++) {
				if (has_edge(&g, PD->ti[d], PD->tj[d])) continue;
				if (hasmiss && ht_get(&missht, dyadkey(&g, PD->ti[d], PD->tj[d]), &dv)) continue;
				nd += 1.0;
				for (krc = 0; krc < nrc; krc++) R->rcstat[krc] += P->ratecovattr[krc * n + PD->ti[d] - 1];
			}
			ht_free(&hs);
		}
		R->netdist = nd;
	}
	if (M->nbehterms > 0) {
		long d, dv;
		long *li = (long *)malloc((size_t)(PD->nties > 0 ? PD->nties : 1) * sizeof(long));
		long *lj = (long *)malloc((size_t)(PD->nties > 0 ? PD->nties : 1) * sizeof(long));
		long ne = 0;
		for (d = 0; d < PD->nties; d++) {
			if (hasmiss && ht_get(&missht, dyadkey(&g, PD->ti[d], PD->tj[d]), &dv)) continue;
			li[ne] = PD->ti[d]; lj[ne] = PD->tj[d]; ne++;
		}
		for (b = 0; b < M->nbeh; b++) {
			const model_t *Mb = b ? M->bm[b] : M;
			const double *b0 = b ? PD->xbeh0[b] : PD->beh0;
			const double *mbb = b ? PD->xmissbeh[b] : PD->missbeh;
			double *bvb = behvalb[b];
			double bd = 0.0;
			saom_tl_beh0 = b0;
			for (i = 1; i <= n; i++) {
				if (hasmiss && mbb[i] != 0.0) continue;
				bd += fabs(bvb[i] - b0[i]);
			}
			if (b == 0) R->behdist = bd; else R->xbehdist[b] = bd;

			/* lagged behavior statistics: end behavior on the STARTING network */
			{
				double *bz = bvb, *bzm = NULL;
				if (hasmiss) {
					bzm = (double *)malloc((size_t)(n + 1) * sizeof(double));
					for (i = 1; i <= n; i++) bzm[i] = (mbb[i] != 0.0) ? Mb->behOverallMean : bvb[i];
					bz = bzm;
				}
				beh_stats_on_edges(Mb, ne, li, lj, bz, R->statBehLag + M->behoff[b]);
				free(bzm);
			}
		}
		free(li); free(lj);
		if (M->has_behsim) attrs[M->nattr] = (double *)PD->beh0;		// behsim statistic: STARTING behavior
		if (behc0) attrs[M->nattr + 1] = behc0;
	}

	if (hasmiss) {
		build_masked_graph(&g, &gm, &missht, g.need_adj);
		have_gm = 1;
	}
	for (k = 0; k < M->nterms; k++) R->stat[k] = saom_eval_stat((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs, have_gm ? &gm : &g);
	if (M->nbehterms > 0) {
		for (b = 0; b < M->nbeh; b++) {
			const model_t *Mb = b ? M->bm[b] : M;
			const double *mbb = b ? PD->xmissbeh[b] : PD->missbeh;
			double *behval_use = behvalb[b], *behval_masked = NULL;
			if (hasmiss) {
				behval_masked = (double *)malloc((size_t)(n + 1) * sizeof(double));
				for (i = 1; i <= n; i++) behval_masked[i] = (mbb[i] != 0.0) ? Mb->behOverallMean : behvalb[b][i];
				behval_use = behval_masked;
			}
			saom_tl_beh0 = b ? PD->xbeh0[b] : PD->beh0;
			for (k = 0; k < Mb->nbehterms; k++) R->statBeh[M->behoff[b] + k] = saom_beh_stat_term(have_gm ? &gm : &g, behval_use, Mb->behtermcodes[k], Mb->behrange, Mb->behSimMean, Mb->behOverallMean);
			free(behval_masked);
		}
	}
	/* protocol 11, endowment/creation statistics (RSiena's
	   endowmentStatistic()/creationStatistic(), SaomNetworkPatchEndowCreation()
	   and SaomBehaviorPatchEndowCreation()): network outdegree/reciprocity
	   endowment = minus the sum over LOST ties of their tie statistic in the
	   starting network (1, or x_ji), creation = the sum over GAINED ties of
	   it in the end network; behavior endowment = the sum of the (masked)
	   decreases, creation = of the increases */
	if (M->hasfntype) {
		long d, dv;
		int needs = 0;
		for (k = 0; k < M->nterms; k++) if (M->fntype[k] != 0) needs = 1;
		if (needs) {
			dyadht_t hs;
			ht_alloc(&hs, ht_next_pow2(PD->nties * 2 + 16));
			for (d = 0; d < PD->nties; d++) ht_put(&hs, dyadkey(&g, PD->ti[d], PD->tj[d]), 1);
			graph_t gs;
			int need_gs = 0;
			for (k = 0; k < M->nterms; k++) if (M->fntype[k] != 0 && M->termcodes[k] != TERMCODE_OUTDEGREE && M->termcodes[k] != TERMCODE_RECIPROCITY) need_gs = 1;
			if (need_gs) {			/* protocol 14: the start network, for the tie statistic of other dyadic effects */
				graph_init(&gs, n, M->need_adj, PD->nties);
				for (d = 0; d < PD->nties; d++) toggle(&gs, PD->ti[d], PD->tj[d]);
			}
			for (k = 0; k < M->nterms; k++) {
				int rec;
				double v = 0.0;
				if (M->fntype[k] == 0) continue;
				if (M->termcodes[k] != TERMCODE_OUTDEGREE && M->termcodes[k] != TERMCODE_RECIPROCITY) {
					/* RSiena endowmentStatistic() / creationStatistic(): minus the sum over LOST ties of the
					   effect's tie statistic in the start network; the sum over GAINED ties of it in the end network */
					double *ak = (M->attridx[k] > 0) ? attrs[M->attridx[k] - 1] : NULL;
					if (M->fntype[k] == 1) {
						for (d = 0; d < PD->nties; d++) {
							if (has_edge(&g, PD->ti[d], PD->tj[d])) continue;
							if (hasmiss && ht_get(&missht, dyadkey(&g, PD->ti[d], PD->tj[d]), &dv)) continue;
							v -= (M->termcodes[k] == TERMCODE_BALANCE && hasmiss) ? saom_balance_tie_masked(&gs, M->p1[k], PD->ti[d], PD->tj[d], &missht) : saom_tie_stat(&gs, M->termcodes[k], ak, M->p1[k], PD->ti[d], PD->tj[d]);
						}
					}
					else {
						graph_t *ge = have_gm ? &gm : &g;
						for (d = 0; d < ge->nties; d++) {
							long ei = ge->elist_i[d], ej = ge->elist_j[d];
							if (has_edge(&gs, ei, ej)) continue;
							v += (M->termcodes[k] == TERMCODE_BALANCE && hasmiss) ? saom_balance_tie_masked(&g, M->p1[k], ei, ej, &missht) :
							saom_tie_stat((M->termcodes[k] == TERMCODE_OUTACTIVITY || M->termcodes[k] == TERMCODE_INACTIVITY || M->termcodes[k] == TERMCODE_INACTL || M->termcodes[k] == TERMCODE_OUTACTSQRT) ? &gs : (have_gm ? &gm : &g),
								M->termcodes[k], ak, M->p1[k], ei, ej);   /* protocol 29: the ego-activity effects use the START network degrees (RSiena: they override endowmentStatistic(), which creationStatistic() reuses) */
						}
					}
					R->stat[k] = v;
					continue;
				}
				rec = (M->termcodes[k] == TERMCODE_RECIPROCITY);
				if (M->fntype[k] == 1) {
					for (d = 0; d < PD->nties; d++) {
						if (has_edge(&g, PD->ti[d], PD->tj[d])) continue;
						v -= rec ? (ht_get(&hs, dyadkey(&g, PD->tj[d], PD->ti[d]), &dv) ? 1.0 : 0.0) : 1.0;
					}
				}
				else {
					for (d = 0; d < g.nties; d++) {
						long ei = g.elist_i[d], ej = g.elist_j[d];
						if (ht_get(&hs, dyadkey(&g, ei, ej), &dv)) continue;
						v += rec ? (has_edge(&g, ej, ei) ? 1.0 : 0.0) : 1.0;
					}
				}
				R->stat[k] = v;
			}
			if (need_gs) graph_free(&gs);
			ht_free(&hs);
		}
		if (M->nbehterms > 0) {
			/* RSiena's behavior endowment/creation statistics on the
			   (masked) starting network (protocol 12), for every behavior (protocol 19) */
			long d, dv, ne = 0;
			long *li = (long *)malloc((size_t)(PD->nties > 0 ? PD->nties : 1) * sizeof(long));
			long *lj = (long *)malloc((size_t)(PD->nties > 0 ? PD->nties : 1) * sizeof(long));
			double *cc = (double *)calloc((size_t)(n + 1), sizeof(double));
			double *dd = (double *)calloc((size_t)(n + 1), sizeof(double));
			double *nd = (double *)calloc((size_t)(n + 1), sizeof(double));
			for (d = 0; d < PD->nties; d++) {
				if (hasmiss && ht_get(&missht, dyadkey(&g, PD->ti[d], PD->tj[d]), &dv)) continue;
				li[ne] = PD->ti[d]; lj[ne] = PD->tj[d]; ne++;
			}
			for (b = 0; b < M->nbeh; b++) {
				const model_t *Mb = b ? M->bm[b] : M;
				const double *b0 = b ? PD->xbeh0[b] : PD->beh0;
				const double *mb = hasmiss ? (b ? PD->xmissbeh[b] : PD->missbeh) : NULL;
				for (i = 1; i <= n; i++) {
					cc[i] = 0.0; dd[i] = 0.0; nd[i] = 0.0;
					if (mb && mb[i] != 0.0) continue;
					cc[i] = behvalb[b][i] - Mb->behOverallMean;
					dd[i] = b0[i] - behvalb[b][i];
					nd[i] = -dd[i];
				}
				for (k = 0; k < Mb->nbehterms; k++) {
					double v;
					if (Mb->behfntype[k] == 0) continue;
					if (Mb->behfntype[k] == 1) v = beh_endow_stat(Mb->behtermcodes[k], n, ne, li, lj, cc, dd, mb);
					else v = -beh_endow_stat(Mb->behtermcodes[k], n, ne, li, lj, cc, nd, mb);
					R->statBeh[M->behoff[b] + k] = v;
					R->statBehLag[M->behoff[b] + k] = v;
				}
			}
			free(li); free(lj); free(cc); free(dd); free(nd);
		}
	}
	if (have_gm) free_graph(&gm);
	if (hasmiss) ht_free(&missht);
	free(presentIdxArr);

	PROF_ADD(PR_END, pt_end);
	free(behc); free(behc0);
	{ int sl5; for (sl5 = 0; sl5 < 8; sl5++) free(dyncov[sl5]); }
	if (M->has_start) { graph_free(&g0s); saom_tl_g0 = NULL; }
	if (keep_final) {
		R->gfinal = (graph_t *)malloc(sizeof(graph_t));
		*R->gfinal = g;
		R->behfinal = behval;
	}
	else {
		graph_free(&g);
		free(behval);
		for (b = 1; b < MAXBEH; b++) free(behvalb[b]);
	}
	return 0;
}

/* ===================================================================
   Threads (portable: pthreads, or Win32 threads on Windows)
   =================================================================== */
#if defined(_WIN32)
#include <windows.h>
typedef HANDLE saom_thread_t;
typedef CRITICAL_SECTION saom_mutex_t;
#define SAOM_MUTEX_INIT(m) InitializeCriticalSection(m)
#define SAOM_MUTEX_LOCK(m) EnterCriticalSection(m)
#define SAOM_MUTEX_UNLOCK(m) LeaveCriticalSection(m)
#define SAOM_MUTEX_DESTROY(m) DeleteCriticalSection(m)
#else
#include <pthread.h>
#include <unistd.h>
typedef pthread_t saom_thread_t;
typedef pthread_mutex_t saom_mutex_t;
#define SAOM_MUTEX_INIT(m) pthread_mutex_init(m, NULL)
#define SAOM_MUTEX_LOCK(m) pthread_mutex_lock(m)
#define SAOM_MUTEX_UNLOCK(m) pthread_mutex_unlock(m)
#define SAOM_MUTEX_DESTROY(m) pthread_mutex_destroy(m)
#endif
#if defined(__APPLE__)
#include <sys/sysctl.h>
#endif

static long saom_physical_cores(void) {
#if defined(_WIN32)
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	return (long)si.dwNumberOfProcessors;
#elif defined(__APPLE__)
	int v = 0;
	size_t len = sizeof(v);
	if (sysctlbyname("hw.physicalcpu", &v, &len, NULL, 0) == 0 && v > 0) return (long)v;
	return 1;
#else
	long v = sysconf(_SC_NPROCESSORS_ONLN);
	return v > 0 ? v : 1;
#endif
}

/* ===================================================================
   BATCH entry points (2026-10-01): the estimator's per-fit data stay
   resident here between calls, and one call runs many independent
   simulations on worker threads.

     BATCHSETUP|<header>   reads the frame once (all periods' starting
                           ties, attributes, behavior, missingness,
                           presence) and stores it in batch_cur->
     BATCHRUN|<params>     runs K replicates x P periods; unit (k, pd)
                           uses its own random stream seeded from
                           (seed, k, pd), so results do not depend on the
                           number of threads. Writes a K x W Stata matrix.
     BATCHCLEAN|           frees the resident data.

   Worker threads call only simulate_period() (no Stata API).
   =================================================================== */

typedef struct {
	int ready;
	model_t M;
	long P;				// periods
	period_t *per;		// P entries
	double **attrmem;	// nattr arrays of n+1
	long symtype;		// protocol 11: non-directed model type
	long nrc;		// protocol 11: ratecov() covariates
	double *rcattr;		// nrc x n
	long nsr;		// protocol 42: structural rate covariates (the last nsr of the nrc columns)
	int srtype[MAXRC];
	double **rcper;		// per period: rcattr with the structural columns computed from the starting network
} batch_state_t;

#define MAXNETS 4
static batch_state_t batch_states[MAXNETS];		/* protocol 52: slot 0 = the model of BATCHSETUP; slots 1.. = further dependent networks (BATCHSETUP1| ...) */
static batch_state_t *batch_cur = &batch_states[0];

static void batch_free(void) {
	long pd, k;
	if (!batch_cur->ready) return;
	for (pd = 0; pd < batch_cur->P; pd++) {
		period_t *p = &batch_cur->per[pd];
		free(p->ti); free(p->tj); free(p->beh0); free(p->mi); free(p->mj); free(p->missbeh); free(p->present); free(p->evt); free(p->eva); free(p->evk);
		{ long b; for (b = 1; b < MAXBEH; b++) { free(p->xbeh0[b]); free(p->xmissbeh[b]); } }
		{ long a; for (a = 0; a <= MAXATTR; a++) free(p->xattr[a]); }
	}
	{ long b; for (b = 1; b < MAXBEH; b++) free(batch_cur->M.bm[b]); }
	free(batch_cur->per);
	for (k = 0; k < batch_cur->M.nattr; k++) free(batch_cur->attrmem[k]);
	free(batch_cur->attrmem);
	free(batch_cur->M.struct_off); free(batch_cur->M.struct_j);
	free(batch_cur->rcattr);
	if (batch_cur->rcper) { long q; for (q = 0; q < batch_cur->P; q++) free(batch_cur->rcper[q]); free(batch_cur->rcper); }
	memset(batch_cur, 0, sizeof(*batch_cur));
}

static unsigned long long unit_seed(unsigned long long seed, long k, long pd) {
	unsigned long long x = seed ^ (0x9E3779B97F4A7C15ULL * (unsigned long long)(k + 1)) ^ (0xC2B2AE3D27D4EB4FULL * (unsigned long long)(pd + 1));
	return splitmix64_next(&x);
}

typedef struct {
	const model_t *M;
	const period_t *per;
	const simparams_t *prm;		// P entries (rates differ by period)
	long K, P;
	unsigned long long seed;
	simres_t *res;			// K*P
	long next;
	saom_mutex_t mu;
} batch_job_t;

static void batch_worker_loop(batch_job_t *J) {
	for (;;) {
		long u;
		SAOM_MUTEX_LOCK(&J->mu);
		u = J->next++;
		SAOM_MUTEX_UNLOCK(&J->mu);
		if (u >= J->K * J->P) break;
		{
			long k = u / J->P, pd = u % J->P;
			simulate_period(J->M, &J->per[pd], &J->prm[pd], unit_seed(J->seed, k, pd), 0, &J->res[u]);
		}
	}
}
#if defined(_WIN32)
static DWORD WINAPI batch_worker(LPVOID arg) { batch_worker_loop((batch_job_t *)arg); return 0; }
#else
static void *batch_worker(void *arg) { batch_worker_loop((batch_job_t *)arg); return NULL; }
#endif

static void batch_run_units(batch_job_t *J, long nthreads) {
	long t, nunits = J->K * J->P;
	saom_thread_t *th;
	if (nthreads > nunits) nthreads = nunits;
	if (nthreads < 1) nthreads = 1;
	J->next = 0;
	SAOM_MUTEX_INIT(&J->mu);
	if (nthreads == 1) { batch_worker_loop(J); SAOM_MUTEX_DESTROY(&J->mu); return; }
	th = (saom_thread_t *)malloc((size_t)nthreads * sizeof(saom_thread_t));
	for (t = 1; t < nthreads; t++) {
#if defined(_WIN32)
		th[t] = CreateThread(NULL, 0, batch_worker, J, 0, NULL);
#else
		pthread_create(&th[t], NULL, batch_worker, J);
#endif
	}
	batch_worker_loop(J);		// the calling thread works too
	for (t = 1; t < nthreads; t++) {
#if defined(_WIN32)
		WaitForSingleObject(th[t], INFINITE);
		CloseHandle(th[t]);
#else
		pthread_join(th[t], NULL);
#endif
	}
	free(th);
	SAOM_MUTEX_DESTROY(&J->mu);
}

/* BATCHSETUP|n P nattr nterms [tc ai p1]*nterms nbeh [behtc]*nbeh behmin
   behmax simMean overallMean hasmiss haspresent ntiestot nmisstot
   Frame variables, in this order (the plugin call's varlist):
     1-3  e_pd e_i e_j          stacked starting ties, rows 1..ntiestot
     then a1..a_nattr           attributes, rows 1..n
     then b1..bP (if nbeh>0)    starting behavior per period, rows 1..n
     then m_pd m_i m_j (hasmiss) stacked missing dyads, rows 1..nmisstot
     then mb1..mbP (hasmiss)    behavior missingness per period
     then pr1..prP (haspresent) presence per period */
/* protocol 11 model trailer (optional; absent = none of these):
     hasfn [fntype]*nterms [behfntype]*nbehterms   (hasfn = 0: no fields)
     nstruct [ego alter]*nstruct                    (structural dyads)
   The structural dyads become a CSR list by ego (1-based). */
/* structural dyads (ego si[k], alter sj[k]) as a CSR list by ego (1-based) */
static void build_struct_csr(model_t *M, long nst, const long *si, const long *sj) {
	long k, i;
	M->nstruct = nst;
	M->struct_off = (long *)calloc((size_t)(M->n + 2), sizeof(long));
	M->struct_j = (long *)malloc((size_t)(nst > 0 ? nst : 1) * sizeof(long));
	for (k = 0; k < nst; k++) if (si[k] >= 1 && si[k] <= M->n) M->struct_off[si[k] + 1]++;
	for (i = 1; i <= M->n + 1; i++) M->struct_off[i] += M->struct_off[i - 1];
	{
		long *fill = (long *)calloc((size_t)(M->n + 2), sizeof(long));
		for (k = 0; k < nst; k++) {
			if (si[k] < 1 || si[k] > M->n) continue;
			M->struct_j[M->struct_off[si[k]] + fill[si[k]]] = sj[k];
			fill[si[k]]++;
		}
		free(fill);
	}
}

static void parse_model_trailer11(model_t *M) {
	long k, nst, *si, *sj;
	M->hasfntype = (int)next_long_opt(0);
	if (M->hasfntype) {
		for (k = 0; k < M->nterms; k++) M->fntype[k] = (int)next_long();
		for (k = 0; k < M->nbehterms; k++) M->behfntype[k] = (int)next_long();
	}
	nst = next_long_opt(0);
	M->nstruct = nst;
	M->nstruct_pending = 0;
	M->struct_off = NULL;
	M->struct_j = NULL;
	if (nst < 0) {
		/* protocol 20: -N = N structural dyads in the last two frame columns (read at the end of BATCHSETUP) */
		M->nstruct = 0;
		M->nstruct_pending = -nst;
	}
	else if (nst > 0) {
		si = (long *)malloc((size_t)nst * sizeof(long));
		sj = (long *)malloc((size_t)nst * sizeof(long));
		for (k = 0; k < nst; k++) { si[k] = next_long(); sj[k] = next_long(); }
		build_struct_csr(M, nst, si, sj);
		free(si); free(sj);
	}
}

static ST_retcode batch_setup(char *arg) {
	model_t *M;
	long n, P, i, k, pd, ntot, nmtot, col;
	int hasmiss, haspresent;
	char *tok0;

	batch_free();
	M = &batch_cur->M;
	memset(M, 0, sizeof(model_t));
	tok0 = strtok(arg, " \t");
	if (!tok0) { SF_error("saom_sim: BATCHSETUP empty\n"); return 198; }
	n = (long)atof(tok0);
	P = next_long();
	M->n = n;
	M->nattr = next_long();
	M->nterms = next_long();
	if (M->nterms > MAXTERMS || M->nattr > MAXATTR - 1) { SF_error("saom_sim: BATCHSETUP too many terms/attributes\n"); return 198; }
	for (k = 0; k < M->nterms; k++) {
		M->termcodes[k] = (int)next_long();
		M->attridx[k] = (int)next_long();
		M->p1[k] = next_double();
	}
	M->nbehterms = next_long();
	if (M->nbehterms > MAXBEHTERMS) { SF_error("saom_sim: BATCHSETUP too many behavior terms\n"); return 198; }
	M->nbeh = (M->nbehterms > 0) ? 1 : 0;
	M->nbehtermsAll = M->nbehterms;
	M->behoff[0] = 0;
	for (k = 0; k < M->nbehterms; k++) M->behtermcodes[k] = (int)next_long();
	M->behminval = next_double();
	M->behmaxval = next_double();
	M->behSimMean = next_double();
	M->behOverallMean = next_double();
	M->behrange = M->behmaxval - M->behminval;
	hasmiss = (int)next_long();
	haspresent = (int)next_long();
	ntot = next_long();
	nmtot = next_long();
	/* protocol 11 trailer: model trailer, then the simulation type
	   (symtype) and the ratecov() covariates (K, then K x n values) */
	parse_model_trailer11(M);
	batch_cur->symtype = next_long_opt(0);
	batch_cur->nrc = next_long_opt(0);
	if (batch_cur->nrc < 0 || batch_cur->nrc > MAXRC) { SF_error("saom_sim: BATCHSETUP too many ratecov() covariates\n"); return 198; }
	if (batch_cur->nrc > 0) {
		batch_cur->rcattr = (double *)malloc((size_t)(n * batch_cur->nrc) * sizeof(double));
		for (i = 0; i < n * batch_cur->nrc; i++) batch_cur->rcattr[i] = next_double();
	}
	/* protocol 19: behaviors 1.. (trailer: nbx, then per extra behavior its term count, term codes, behmin behmax
	   simMean overallMean and the endowment/creation code of every term) */
	{
		long nbx = next_long_opt(0), b, kk;
		if (nbx < 0 || nbx + 1 > MAXBEH) { SF_error("saom_sim: BATCHSETUP too many behaviors\n"); return 198; }
		for (b = 1; b <= nbx; b++) {
			model_t *V = (model_t *)calloc(1, sizeof(model_t));
			long nt = next_long();
			if (nt < 1 || M->nbehtermsAll + nt > MAXBEHTERMS) { SF_error("saom_sim: BATCHSETUP too many behavior terms\n"); return 198; }
			V->n = n;
			V->nbehterms = nt;
			for (kk = 0; kk < nt; kk++) V->behtermcodes[kk] = (int)next_long();
			V->behminval = next_double();
			V->behmaxval = next_double();
			V->behSimMean = next_double();
			V->behOverallMean = next_double();
			V->behrange = V->behmaxval - V->behminval;
			for (kk = 0; kk < nt; kk++) {
				V->behfntype[kk] = (int)next_long();
				if (V->behfntype[kk] != 0) M->hasfntype = 1;
			}
			M->bm[b] = V;
			M->behoff[b] = M->nbehtermsAll;
			M->nbehtermsAll += nt;
			M->nbeh++;
		}
	}
	/* protocol 21: attributes that vary by period (ntv, then their 1-based attribute columns) */
	M->ntv = (int)next_long_opt(0);
	if (M->ntv < 0 || M->ntv > MAXATTR - 1) { SF_error("saom_sim: BATCHSETUP too many time-varying attributes\n"); return 198; }
	for (k = 0; k < M->ntv; k++) M->tvcol[k] = (int)next_long();
	/* protocol 27: number of composition-change events (their four frame columns follow the structural ones) */
	M->nev_pending = next_long_opt(0);
	/* protocol 36/38: covariates of the behavior covariate terms (count; per covariate: number of periods 1 or P, then that many x n centred values) */
	{
		long nc = next_long_opt(0), c, ii, q;
		if (nc < 0 || nc > 8) { SF_error("saom_sim: BATCHSETUP too many behavior covariates\n"); return 198; }
		for (c = 0; c < 8; c++) {
			if (saom_behcov_pp[c]) { for (q = 0; q < saom_behcov_np[c]; q++) free(saom_behcov_pp[c][q]); free(saom_behcov_pp[c]); }
			saom_behcov_pp[c] = NULL; saom_behcov_np[c] = 0;
		}
		for (c = 0; c < nc; c++) {
			long np = next_long();
			if (np != 1 && np != P) { SF_error("saom_sim: BATCHSETUP behavior covariate with a wrong number of periods\n"); return 198; }
			saom_behcov_pp[c] = (double **)calloc((size_t)np, sizeof(double *));
			saom_behcov_np[c] = (int)np;
			for (q = 0; q < np; q++) {
				saom_behcov_pp[c][q] = (double *)calloc((size_t)(n + 1), sizeof(double));
				for (ii = 1; ii <= n; ii++) saom_behcov_pp[c][q][ii] = next_double();
			}
			saom_behcov_mean[c] = next_double();
		}
		for (c = 0; c < 8; c++) saom_bcov_dyn[c] = 0;
		for (c = 0; c < nc; c++) saom_bcov_dyn[c] = (int)next_long_opt(0);
	}
	/* protocol 48: dyadic covariates of the behavior effects: the count here, the n x n values in the frame's last columns (column j of covariate c = row j of W, rows 1..n) */
	{
		long nd = next_long_opt(0), c;
		if (nd < 0 || nd > 8) { SF_error("saom_sim: BATCHSETUP too many dyadic behavior covariates\n"); return 198; }
		long np = 1;
		if (nd > 0) np = next_long();
		if (np < 1 || np > 64) { SF_error("saom_sim: BATCHSETUP bad number of dyadic covariate periods\n"); return 198; }
		for (c = 0; c < 8; c++) {
			if (saom_bdypd[c]) { long q; for (q = 0; q < saom_bdy_np; q++) free(saom_bdypd[c][q]); free(saom_bdypd[c]); saom_bdypd[c] = NULL; }
			saom_bdy[c] = NULL;
		}
		saom_bdy_n = n;
		saom_bdy_np = np;
		saom_bdy_pending = nd;
	}
	/* protocol 42: structural rate covariates (count, then their types) */
	batch_cur->nsr = next_long_opt(0);
	if (batch_cur->nsr < 0 || batch_cur->nsr > MAXRC) { SF_error("saom_sim: BATCHSETUP too many structural rate effects\n"); return 198; }
	for (k = 0; k < batch_cur->nsr; k++) batch_cur->srtype[k] = (int)next_long();
	{ char *tv = strtok(NULL, " \t"); M->behVariance = tv ? atof(tv) : 0.0; }		/* protocol 60: the pooled variance of the behavior (varAlt, avSimVarAlt) */
	if (wire_parse_error) { SF_error("saom_sim: BATCHSETUP argument string ran out of fields\n"); return 198; }

	saom_model_need_flags((int)M->nterms, M->termcodes, M->attridx, M->p1, &M->need_adj, &M->need_transtrip, &M->need_cycle3);
	for (k = 0; k < M->nterms; k++) if (SAOM_DYNTC(M->termcodes[k])) M->has_behsim = 1;
	for (k = 0; k < M->nbehterms; k++) if (M->behtermcodes[k] == TERMCODE_BEH_AVALT || M->behtermcodes[k] == TERMCODE_BEH_AVSIM || SAOM_BEH_NEWTC(M->behtermcodes[k]) || SAOM_BEH_XALTTC(M->behtermcodes[k]) || SAOM_BSTC(M->behtermcodes[k]) || SAOM_BQTC(M->behtermcodes[k]) || SAOM_BRTC(M->behtermcodes[k]) || SAOM_BUTC(M->behtermcodes[k])) M->need_adj = 1;
	if (M->has_behsim && M->nbehterms == 0 && batch_cur == &batch_states[0]) { SF_error("saom_sim: behsim needs a co-evolving behavior\n"); return 198; }
	saom_behsim_range = (M->behrange > 0.0) ? M->behrange : 1.0;
	if (M->has_behsim) for (k = 0; k < M->nterms; k++) if (SAOM_DYNTC(M->termcodes[k])) M->attridx[k] = (int)(M->nattr + 1);
	for (k = 0; k < M->nterms; k++) if (SAOM_STARTTC(M->termcodes[k])) M->has_start = 1;
	for (k = 0; k < M->nterms; k++) if ((M->termcodes[k] >= 1000 && M->termcodes[k] < 2000) || (M->termcodes[k] >= 4000 && M->termcodes[k] < 5000)) { M->has_behcov = 1; M->attridx[k] = (int)(M->nattr + 2); }
	if (M->has_behcov && (M->nbehterms == 0 || M->nattr + 2 > MAXATTR)) { SF_error("saom_sim: network terms with the behavior as covariate need a co-evolving behavior\n"); return 198; }

	{ long b2, k2; for (b2 = 1; b2 < M->nbeh; b2++) for (k2 = 0; k2 < M->bm[b2]->nbehterms; k2++) if (M->bm[b2]->behtermcodes[k2] == TERMCODE_BEH_AVALT || M->bm[b2]->behtermcodes[k2] == TERMCODE_BEH_AVSIM || SAOM_BEH_NEWTC(M->bm[b2]->behtermcodes[k2]) || SAOM_BEH_XALTTC(M->bm[b2]->behtermcodes[k2]) || SAOM_BSTC(M->bm[b2]->behtermcodes[k2]) || SAOM_BQTC(M->bm[b2]->behtermcodes[k2]) || SAOM_BRTC(M->bm[b2]->behtermcodes[k2]) || SAOM_BUTC(M->bm[b2]->behtermcodes[k2])) M->need_adj = 1; }

	{ long q; for (q = 0; q < batch_cur->nsr; q++) { int ty = batch_cur->srtype[q]; int kd = (ty <= 3) ? ty : ((ty <= 6) ? ty - 3 : ty - 6); if (kd == 3) M->need_adj = 1; } }
	batch_cur->P = P;
	batch_cur->per = (period_t *)calloc((size_t)P, sizeof(period_t));
	{ long c, q; for (c = 0; c < 8; c++) if (saom_behcov_pp[c]) for (q = 0; q < P; q++) batch_cur->per[q].bcov[c] = saom_behcov_pp[c][saom_behcov_np[c] == 1 ? 0 : q]; }
	batch_cur->attrmem = (double **)calloc((size_t)(M->nattr > 0 ? M->nattr : 1), sizeof(double *));

	/* starting ties, stacked */
	{
		long *cnt = (long *)calloc((size_t)P, sizeof(long));
		for (i = 1; i <= ntot; i++) { ST_double v; SF_vdata(1, i, &v); cnt[(long)v - 1]++; }
		for (pd = 0; pd < P; pd++) {
			batch_cur->per[pd].ti = (long *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(long));
			batch_cur->per[pd].tj = (long *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(long));
			batch_cur->per[pd].nties = 0;
		}
		for (i = 1; i <= ntot; i++) {
			ST_double vp, vi, vj;
			period_t *p;
			SF_vdata(1, i, &vp); SF_vdata(2, i, &vi); SF_vdata(3, i, &vj);
			p = &batch_cur->per[(long)vp - 1];
			p->ti[p->nties] = (long)vi; p->tj[p->nties] = (long)vj; p->nties++;
		}
		free(cnt);
	}
	/* protocol 42: per period the rate covariates, the structural columns from the period's starting network */
	batch_cur->rcper = NULL;
	if (batch_cur->nsr > 0) {
		long pdq, sq, a, c0 = batch_cur->nrc - batch_cur->nsr, e2;
		if (c0 < 0) { SF_error("saom_sim: BATCHSETUP more structural rate effects than rate covariates\n"); return 198; }
		batch_cur->rcper = (double **)calloc((size_t)P, sizeof(double *));
		for (pdq = 0; pdq < P; pdq++) {
			graph_t gt;
			period_t *pq = &batch_cur->per[pdq];
			double *arr = (double *)malloc((size_t)(n * batch_cur->nrc) * sizeof(double));
			memcpy(arr, batch_cur->rcattr, (size_t)(n * batch_cur->nrc) * sizeof(double));
			graph_init(&gt, n, 1, pq->nties + 8);
			for (e2 = 0; e2 < pq->nties; e2++) toggle(&gt, pq->ti[e2], pq->tj[e2]);
			for (sq = 0; sq < batch_cur->nsr; sq++) for (a = 1; a <= n; a++) arr[(c0 + sq) * n + a - 1] = sr_value(&gt, batch_cur->srtype[sq], a);
			graph_free(&gt);
			batch_cur->rcper[pdq] = arr;
		}
	}
	col = 4;
	for (k = 0; k < M->nattr; k++) {
		batch_cur->attrmem[k] = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); batch_cur->attrmem[k][i] = SF_is_missing(v) ? 0.0 : v; }
		M->attrs[k] = batch_cur->attrmem[k];
		col++;
	}
	if (M->nbehterms > 0) {
		for (pd = 0; pd < P; pd++) {
			double *b = (double *)calloc((size_t)(n + 1), sizeof(double));
			for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); b[i] = v; }
			batch_cur->per[pd].beh0 = b;
			col++;
		}
	}
	if (hasmiss) {
		long *cnt = (long *)calloc((size_t)P, sizeof(long));
		for (i = 1; i <= nmtot; i++) { ST_double v; SF_vdata((int)col, i, &v); cnt[(long)v - 1]++; }
		for (pd = 0; pd < P; pd++) {
			batch_cur->per[pd].hasmiss = 1;
			batch_cur->per[pd].mi = (long *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(long));
			batch_cur->per[pd].mj = (long *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(long));
			batch_cur->per[pd].nmiss = 0;
		}
		for (i = 1; i <= nmtot; i++) {
			ST_double vp, vi, vj;
			period_t *p;
			SF_vdata((int)col, i, &vp); SF_vdata((int)(col + 1), i, &vi); SF_vdata((int)(col + 2), i, &vj);
			p = &batch_cur->per[(long)vp - 1];
			p->mi[p->nmiss] = (long)vi; p->mj[p->nmiss] = (long)vj; p->nmiss++;
		}
		free(cnt);
		col += 3;
		for (pd = 0; pd < P; pd++) {
			double *mb = (double *)calloc((size_t)(n + 1), sizeof(double));
			if (M->nbehterms > 0) {
				for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); mb[i] = v; }
			}
			batch_cur->per[pd].missbeh = mb;
			if (M->nbehterms > 0) col++;
		}
	}
	if (haspresent) {
		for (pd = 0; pd < P; pd++) {
			double *pr = (double *)calloc((size_t)(n + 1), sizeof(double));
			for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); pr[i] = v; }
			batch_cur->per[pd].present = pr;
			batch_cur->per[pd].haspresent = 1;
			col++;
		}
	}
	/* protocol 19: starting values (and missingness) of behaviors 1.. per period, the last columns of the frame */
	{
		long b;
		for (b = 1; b < M->nbeh; b++) {
			for (pd = 0; pd < P; pd++) {
				double *bb = (double *)calloc((size_t)(n + 1), sizeof(double));
				for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); bb[i] = v; }
				batch_cur->per[pd].xbeh0[b] = bb;
				col++;
			}
			for (pd = 0; pd < P; pd++) {
				double *mm = (double *)calloc((size_t)(n + 1), sizeof(double));
				if (hasmiss) { for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); mm[i] = v; } col++; }
				batch_cur->per[pd].xmissbeh[b] = mm;
			}
		}
	}
	{
		long j;
		for (j = 0; j < M->ntv; j++) {
			for (pd = 0; pd < P; pd++) {
				double *xa = (double *)calloc((size_t)(n + 1), sizeof(double));
				for (i = 1; i <= n; i++) { ST_double v; SF_vdata((int)col, i, &v); xa[i] = v; }
				batch_cur->per[pd].xattr[M->tvcol[j] - 1] = xa;
				col++;
			}
		}
	}
	if (M->nstruct_pending > 0) {
		long q, np = M->nstruct_pending;
		long *si = (long *)malloc((size_t)np * sizeof(long)), *sj = (long *)malloc((size_t)np * sizeof(long));
		for (q = 0; q < np; q++) {
			ST_double a, b2;
			SF_vdata((int)col, q + 1, &a); SF_vdata((int)(col + 1), q + 1, &b2);
			si[q] = (long)a; sj[q] = (long)b2;
		}
		build_struct_csr(M, np, si, sj);
		free(si); free(sj);
		col += 2;
	}
	if (M->nev_pending > 0) {
		long q, ne = M->nev_pending;
		long *cnt = (long *)calloc((size_t)P, sizeof(long));
		for (q = 1; q <= ne; q++) { ST_double v; SF_vdata((int)col, q, &v); cnt[(long)v - 1]++; }
		for (pd = 0; pd < P; pd++) {
			period_t *pp = &batch_cur->per[pd];
			pp->nev = 0;
			pp->evt = (double *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(double));
			pp->eva = (long *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(long));
			pp->evk = (int *)malloc((size_t)(cnt[pd] > 0 ? cnt[pd] : 1) * sizeof(int));
		}
		for (q = 1; q <= ne; q++) {
			ST_double vp, vt, va, vk;
			period_t *pp;
			SF_vdata((int)col, q, &vp); SF_vdata((int)(col + 1), q, &vt); SF_vdata((int)(col + 2), q, &va); SF_vdata((int)(col + 3), q, &vk);
			pp = &batch_cur->per[(long)vp - 1];
			pp->evt[pp->nev] = vt; pp->eva[pp->nev] = (long)va; pp->evk[pp->nev] = (int)vk; pp->nev++;
		}
		free(cnt);
		col += 4;
	}
	if (saom_bdy_pending > 0) {
		long c, jj, ii;
		long q;
		for (c = 0; c < saom_bdy_pending; c++) {
			saom_bdypd[c] = (double **)calloc((size_t)saom_bdy_np, sizeof(double *));
			for (q = 0; q < saom_bdy_np; q++) {
				saom_bdypd[c][q] = (double *)calloc((size_t)(n * n), sizeof(double));
				for (jj = 1; jj <= n; jj++) {
					for (ii = 1; ii <= n; ii++) { ST_double v; SF_vdata((int)col, ii, &v); saom_bdypd[c][q][(ii - 1) * n + (jj - 1)] = v; }
					col++;
				}
			}
			saom_bdy[c] = saom_bdypd[c][0];
		}
		if (saom_bdy_np > 1) {
			long pdx;
			for (pdx = 0; pdx < batch_cur->P; pdx++) for (c = 0; c < saom_bdy_pending; c++) batch_cur->per[pdx].bdy[c] = saom_bdypd[c][pdx < saom_bdy_np ? pdx : saom_bdy_np - 1];
		}
		saom_bdy_pending = 0;
	}
	batch_cur->ready = 1;
	SF_scal_save("__saom_native_version", (ST_double)SAOM_NATIVE_VERSION);
	return 0;
}

/* BATCHRUN|K seed nthreads want_score condmode
            [thetaNet]*nterms [thetaBeh]*nbeh [rateNet]*P [rateBeh]*P [target]*P
   Output: the plugin call's varlist, W variables in the current frame,
   rows 1..K (Stata matrices are too small in Stata/BE for K3 = 1000):
     condmode=0: W = 2*(nterms+nbeh) + 6*P:
       sum over periods of (stat, statBehLag), sum of (score, scoreBeh),
       then per period: netdist behdist stepsNet stepsBeh nchanges nchangesBeh
     condmode=1: W = P, the conditional-simulation time per period;
     condmode=2: conditional simulation, the mode-0 columns with a 7th
       per-period column (after nchangesBeh), the simulated time. */
static ST_retcode batch_run(char *arg) {
	model_t *M = &batch_cur->M;
	long K, nthreads, pd, k, u, P, pNet, pBeh, W, c;
	unsigned long long seed;
	int want_score, condmode, perper = 0;
	char *tok0;
	simparams_t *prm;
	batch_job_t J;
	simres_t *res;
	double rcoef[MAXRC];

	if (!batch_cur->ready) { SF_error("saom_sim: BATCHRUN without BATCHSETUP\n"); return 198; }
	P = batch_cur->P;
	pNet = M->nterms;
	pBeh = M->nbehtermsAll;
	tok0 = strtok(arg, " \t");
	if (!tok0) { SF_error("saom_sim: BATCHRUN empty\n"); return 198; }
	K = (long)atof(tok0);
	seed = (unsigned long long)next_double();
	nthreads = next_long();
	want_score = (int)next_long();
	condmode = (int)next_long();
	prm = (simparams_t *)calloc((size_t)P, sizeof(simparams_t));
	{
		double th[MAXTERMS], thb[MAXBEHTERMS];
		for (k = 0; k < pNet; k++) th[k] = next_double();
		for (k = 0; k < M->nbehterms; k++) thb[k] = next_double();
		for (pd = 0; pd < P; pd++) {
			memcpy(prm[pd].theta, th, sizeof(th));
			memcpy(prm[pd].thetaBeh, thb, sizeof(thb));
			prm[pd].want_score = want_score;
			prm[pd].condmode = (condmode != 0);
		}
		for (pd = 0; pd < P; pd++) prm[pd].rate = next_double();
		for (pd = 0; pd < P; pd++) prm[pd].rateBeh = next_double();
		for (pd = 0; pd < P; pd++) prm[pd].targetChange = next_double();
		/* protocol 11: the ratecov() coefficients (nrc of them) */
		for (k = 0; k < batch_cur->nrc; k++) rcoef[k] = next_double();
		/* protocol 18: optional trailing flag, per-period statistics and scores appended to the output */
		perper = (int)next_long_opt(0);
		/* protocol 19: the coefficients and rates of behaviors 1.. */
		if (M->nbeh > 1) {
			long b2;
			for (b2 = 1; b2 < M->nbeh; b2++) for (k = 0; k < M->bm[b2]->nbehterms; k++) thb[M->behoff[b2] + k] = next_double();
			for (pd = 0; pd < P; pd++) memcpy(prm[pd].thetaBeh, thb, sizeof(thb));
			for (b2 = 1; b2 < M->nbeh; b2++) for (pd = 0; pd < P; pd++) prm[pd].xrateBeh[b2] = next_double();
		}
		for (pd = 0; pd < P; pd++) {
			prm[pd].symtype = batch_cur->symtype;
			prm[pd].hasratecov = batch_cur->nrc;
			prm[pd].ratecovattr = batch_cur->rcper ? batch_cur->rcper[pd] : batch_cur->rcattr;
			prm[pd].nsr = (int)batch_cur->nsr;
			memcpy(prm[pd].srtype, batch_cur->srtype, sizeof(batch_cur->srtype));
			prm[pd].ratecoef = rcoef;
		}
	}
	if (wire_parse_error) { free(prm); SF_error("saom_sim: BATCHRUN argument string ran out of fields\n"); return 198; }
	if (nthreads <= 0) nthreads = saom_physical_cores();
	/* a small job (phase 2: one replicate, a few periods) on a small
	   network is cheaper than waking threads for it; the result does not
	   depend on this choice */
	if (K * P <= 8) {
		double maxrate = 0.0;
		for (pd = 0; pd < P; pd++) if (prm[pd].rate + prm[pd].rateBeh > maxrate) maxrate = prm[pd].rate + prm[pd].rateBeh;
		if ((double)M->n * (double)M->n * maxrate * (double)(M->nterms + 1) < 5.0e5) nthreads = 1;
	}

	res = (simres_t *)calloc((size_t)(K * P), sizeof(simres_t));
	J.M = M; J.per = batch_cur->per; J.prm = prm; J.K = K; J.P = P; J.seed = seed; J.res = res;
	batch_run_units(&J, nthreads);

	/* condmode 2 = conditional simulation with the full output of mode 0
	   plus a 7th per-period column, the simulated time */
	/* protocol 11: with ratecov(), 2*nrc more columns at the end: per
	   covariate the statistic and the score, summed over periods */
	W = (condmode == 1) ? P : (2 * (pNet + pBeh) + (condmode == 2 ? 7 : 6) * P + 2 * batch_cur->nrc);
	for (k = 0; k < K; k++) {
		if (condmode == 1) {
			for (pd = 0; pd < P; pd++) SF_vstore((int)(pd + 1), (int)(k + 1), res[k * P + pd].t);
			continue;
		}
		{
			double acc[2 * (MAXTERMS + MAXBEHTERMS)];
			memset(acc, 0, sizeof(acc));
			for (pd = 0; pd < P; pd++) {
				simres_t *r = &res[k * P + pd];
				for (c = 0; c < pNet; c++) acc[c] += r->stat[c];
				for (c = 0; c < pBeh; c++) acc[pNet + c] += r->statBehLag[c];
				for (c = 0; c < pNet; c++) acc[pNet + pBeh + c] += r->score[c];
				for (c = 0; c < pBeh; c++) acc[2 * pNet + pBeh + c] += r->scoreBeh[c];
			}
			for (c = 0; c < 2 * (pNet + pBeh); c++) SF_vstore((int)(c + 1), (int)(k + 1), acc[c]);
			for (pd = 0; pd < P; pd++) {
				simres_t *r = &res[k * P + pd];
				long base = 2 * (pNet + pBeh) + (condmode == 2 ? 7 : 6) * pd + 1;
				SF_vstore((int)base, (int)(k + 1), r->netdist);
				SF_vstore((int)(base + 1), (int)(k + 1), r->behdist);
				SF_vstore((int)(base + 2), (int)(k + 1), r->stepsNet);
				SF_vstore((int)(base + 3), (int)(k + 1), r->stepsBeh);
				SF_vstore((int)(base + 4), (int)(k + 1), r->nchanges);
				SF_vstore((int)(base + 5), (int)(k + 1), r->nchangesBeh);
				if (condmode == 2) SF_vstore((int)(base + 6), (int)(k + 1), r->t);
			}
			if (perper && condmode != 1) {
				/* protocol 18: per period, the statistics (network, lagged behavior), the scores (network, behavior)
				   and per ratecov() covariate the statistic and the score; RSiena's derivative matrix is the sum over
				   the periods of the covariance of that period's score and deviation */
				long wper = 2 * (pNet + pBeh) + 2 * batch_cur->nrc;
				long base1 = 2 * (pNet + pBeh) + (condmode == 2 ? 7 : 6) * P + 2 * batch_cur->nrc + 1;
				for (pd = 0; pd < P; pd++) {
					simres_t *r = &res[k * P + pd];
					long b2 = base1 + wper * pd, kr;
					for (c = 0; c < pNet; c++) SF_vstore((int)(b2 + c), (int)(k + 1), r->stat[c]);
					for (c = 0; c < pBeh; c++) SF_vstore((int)(b2 + pNet + c), (int)(k + 1), r->statBehLag[c]);
					for (c = 0; c < pNet; c++) SF_vstore((int)(b2 + pNet + pBeh + c), (int)(k + 1), r->score[c]);
					for (c = 0; c < pBeh; c++) SF_vstore((int)(b2 + 2 * pNet + pBeh + c), (int)(k + 1), r->scoreBeh[c]);
					for (kr = 0; kr < batch_cur->nrc; kr++) {
						SF_vstore((int)(b2 + 2 * (pNet + pBeh) + 2 * kr), (int)(k + 1), r->rcstat[kr]);
						SF_vstore((int)(b2 + 2 * (pNet + pBeh) + 2 * kr + 1), (int)(k + 1), r->rcscore[kr]);
					}
				}
			}
			if (M->nbeh > 1 && condmode != 1) {
				/* protocol 19: last columns, per period and behavior 1..: behdist, stepsBeh, nchangesBeh */
				long wper0 = 2 * (pNet + pBeh) + 2 * batch_cur->nrc;
				long baseX = 2 * (pNet + pBeh) + (condmode == 2 ? 7 : 6) * P + 2 * batch_cur->nrc + (perper ? P * wper0 : 0) + 1, b2;
				for (pd = 0; pd < P; pd++) {
					simres_t *r = &res[k * P + pd];
					for (b2 = 1; b2 < M->nbeh; b2++) {
						long bx = baseX + 3 * ((b2 - 1) * P + pd);
						SF_vstore((int)bx, (int)(k + 1), r->xbehdist[b2]);
						SF_vstore((int)(bx + 1), (int)(k + 1), r->xstepsBeh[b2]);
						SF_vstore((int)(bx + 2), (int)(k + 1), r->xnchangesBeh[b2]);
					}
				}
			}
			if (batch_cur->nrc > 0) {
				long base0 = 2 * (pNet + pBeh) + (condmode == 2 ? 7 : 6) * P + 1;
				long kr;
				for (kr = 0; kr < batch_cur->nrc; kr++) {
					double sc = 0.0, st = 0.0;
					for (pd = 0; pd < P; pd++) { sc += res[k * P + pd].rcscore[kr]; st += res[k * P + pd].rcstat[kr]; }
					SF_vstore((int)(base0 + 2 * kr), (int)(k + 1), st);
					SF_vstore((int)(base0 + 2 * kr + 1), (int)(k + 1), sc);
				}
			}
		}
	}
	(void)u; (void)W;
	free(res);
	free(prm);
	return 0;
}

/* ===================================================================
   protocol 52: several co-evolving dependent networks (up to MAXNETS, all one-mode directed, same actor set). BATCHSETUP<k>| fills the slot of network k
   (its model, its attributes, its period start ties); MNRUN simulates K replicates of all P periods of all networks together (EpochSimulation: a
   variable chosen in proportion to its total rate, then an actor), MNOBS evaluates the statistics of the OBSERVED end networks. A cross-network term
   reads the other network (saom_tl_xg): the current simulated state in the ministeps, the START of the period in the statistics.
   No composition change, no missing data, no behaviors in this version.
   =================================================================== */
static long mn_count_diff(graph_t *a, graph_t *b) {
	long k, d = 0;
	for (k = 0; k < a->nties; k++) if (!has_edge(b, a->elist_i[k], a->elist_j[k])) d++;
	for (k = 0; k < b->nties; k++) if (!has_edge(a, b->elist_i[k], b->elist_j[k])) d++;
	return d;
}
#define BEHNET2 10000		/* protocol 64: a behavior term whose code is >= BEHNET2 is driven by the SECOND network (code - BEHNET2) */
static int simulate_period_mn(int nnet, const model_t **Ms, const period_t **PDs, const simparams_t **Ps, unsigned long long seed, simres_t *R) {
	long n = Ms[0]->n, i, k, j, kk;
	int net;
	graph_t g[MAXNETS], g0[MAXNETS];
	double *attrs[MAXNETS][MAXATTR + 2];
	double *u[MAXNETS], *ev[MAXNETS], *tt[MAXNETS], *c3[MAXNETS], *chg[MAXNETS];
	unsigned char *ijx = (unsigned char *)malloc((size_t)(n + 1));
	rng_t rng;
	double t = 0.0, grand = 0.0, stride = (double)(n + 1);
	/* protocol 64: a co-evolving behavior (the behavior terms are those of the first network's model) */
	const model_t *M0 = Ms[0];
	int hasb = (M0->nbehterms > 0);
	double *bv = NULL, *behc = NULL, *behc0 = NULL, rateB = Ps[0]->rateBeh;
	(void)stride;
	if (hasb) {
		int sl;
		bv = (double *)malloc((size_t)(n + 1) * sizeof(double));
		memcpy(bv, PDs[0]->beh0, (size_t)(n + 1) * sizeof(double));
		behc = (double *)calloc((size_t)(n + 1), sizeof(double));
		behc0 = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) { behc[i] = bv[i] - M0->behOverallMean; behc0[i] = PDs[0]->beh0[i] - M0->behOverallMean; }
		for (sl = 0; sl < 8; sl++) { saom_tl_cov[sl] = PDs[0]->bcov[sl]; saom_tl_bdy[sl] = PDs[0]->bdy[sl]; }
		saom_tl_beh0 = PDs[0]->beh0;
		saom_tl_behscale = (M0->behrange > 0.0) ? 1.0 / M0->behrange : 1.0;
		saom_tl_behvar = M0->behVariance;
		saom_behsim_range = (M0->behrange > 0.0) ? M0->behrange : 1.0;
		grand += (double)n * rateB;
	}
	for (net = 0; net < nnet; net++) {
		const model_t *M = Ms[net];
		const period_t *PD = PDs[net];
		memset(&R[net], 0, sizeof(simres_t));
		for (k = 0; k < M->nattr; k++) attrs[net][k] = PD->xattr[k] ? PD->xattr[k] : M->attrs[k];
		attrs[net][M->nattr] = (hasb && M->has_behsim) ? bv : NULL;
		attrs[net][M->nattr + 1] = hasb ? behc : NULL;
		graph_init(&g[net], n, 1, PD->nties);
		graph_init(&g0[net], n, 1, PD->nties);
		for (i = 0; i < PD->nties; i++) { toggle(&g[net], PD->ti[i], PD->tj[i]); toggle(&g0[net], PD->ti[i], PD->tj[i]); }
		u[net] = (double *)malloc((size_t)(n + 1) * sizeof(double));
		ev[net] = (double *)malloc((size_t)(n + 1) * sizeof(double));
		tt[net] = M->need_transtrip ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
		c3[net] = M->need_cycle3 ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
		chg[net] = (double *)malloc((size_t)(n + 1) * (size_t)(M->nterms > 0 ? M->nterms : 1) * sizeof(double));
		grand += (double)n * Ps[net]->rate;
	}
	rng_seed(&rng, seed);
	while (1) {
		double uvar, cumr = 0.0, maxu, stayterm, denom, draw, cum;
		long actor, choice;
		const model_t *M;
		const simparams_t *P;
		double *score;
		int isbeh = 0;
		t += -log(rng_unif(&rng)) / grand;
		if (t >= 1.0) break;
		uvar = rng_unif(&rng) * grand;
		net = nnet - 1;
		for (kk = 0; kk < nnet; kk++) { cumr += (double)n * Ps[kk]->rate; if (uvar <= cumr) { net = (int)kk; break; } }
		if (hasb && uvar > cumr) isbeh = 1;
		if (isbeh) {
			/* the behavior ministep: the behavior terms read the first network, or the second for the terms with code >= BEHNET2 */
			double chgDown[MAXBEHTERMS], chgUp[MAXBEHTERMS], uDown = 0.0, uUp = 0.0, maxu2 = 0.0, denom2, draw2, cur;
			const double *thB = Ps[0]->thetaBeh;
			int hasDown, hasUp;
			long ba = 1 + (long)(rng_unif(&rng) * (double)n);
			cur = bv[ba];
			hasDown = (cur > M0->behminval);
			hasUp = (cur < M0->behmaxval);
			if (hasDown) {
				for (k = 0; k < M0->nbehterms; k++) {
					int code = M0->behtermcodes[k];
					graph_t *gg = (code >= BEHNET2) ? &g[1] : &g[0];
					chgDown[k] = saom_beh_change_term(gg, bv, (code >= BEHNET2) ? code - BEHNET2 : code, M0->behOverallMean, M0->behrange, M0->behSimMean, ba, -1.0);
					uDown += thB[k] * chgDown[k];
				}
				if (uDown > maxu2) maxu2 = uDown;
			}
			if (hasUp) {
				for (k = 0; k < M0->nbehterms; k++) {
					int code = M0->behtermcodes[k];
					graph_t *gg = (code >= BEHNET2) ? &g[1] : &g[0];
					chgUp[k] = saom_beh_change_term(gg, bv, (code >= BEHNET2) ? code - BEHNET2 : code, M0->behOverallMean, M0->behrange, M0->behSimMean, ba, 1.0);
					uUp += thB[k] * chgUp[k];
				}
				if (uUp > maxu2) maxu2 = uUp;
			}
			denom2 = exp(0.0 - maxu2);
			if (hasDown) denom2 += exp(uDown - maxu2);
			if (hasUp) denom2 += exp(uUp - maxu2);
			if (Ps[0]->want_score) {
				for (k = 0; k < M0->nbehterms; k++) {
					double ebar_k = 0.0;
					if (hasDown) ebar_k += (exp(uDown - maxu2) / denom2) * chgDown[k];
					if (hasUp) ebar_k += (exp(uUp - maxu2) / denom2) * chgUp[k];
					R[0].scoreBeh[k] -= ebar_k;
				}
			}
			draw2 = rng_unif(&rng) * denom2;
			if (hasDown && draw2 <= exp(uDown - maxu2)) {
				bv[ba] = cur - 1.0;
				behc[ba] = bv[ba] - M0->behOverallMean;
				if (Ps[0]->want_score) for (k = 0; k < M0->nbehterms; k++) R[0].scoreBeh[k] += chgDown[k];
				R[0].nchangesBeh += 1.0;
			}
			else {
				if (hasDown) draw2 -= exp(uDown - maxu2);
				if (!(draw2 <= exp(0.0 - maxu2))) {
					bv[ba] = cur + 1.0;
					behc[ba] = bv[ba] - M0->behOverallMean;
					if (Ps[0]->want_score) for (k = 0; k < M0->nbehterms; k++) R[0].scoreBeh[k] += chgUp[k];
					R[0].nchangesBeh += 1.0;
				}
			}
			R[0].stepsBeh += 1.0;
			continue;
		}
		M = Ms[net];
		P = Ps[net];
		score = R[net].score;
		actor = 1 + (long)(rng_unif(&rng) * (double)n);
		saom_tl_xg = &g[(net + 1) % nnet];
		if (M->need_transtrip) { memset(tt[net], 0, (size_t)(n + 1) * sizeof(double)); batch_otp_plus_osp(&g[net], actor, tt[net]); }
		if (M->need_cycle3) { memset(c3[net], 0, (size_t)(n + 1) * sizeof(double)); batch_otp_reverse(&g[net], actor, c3[net]); }
		maxu = eval_network_alternatives(M, P, &g[net], attrs[net], actor, NULL, tt[net], c3[net], chg[net], u[net], ijx);
		stayterm = exp(0.0 - maxu);
		denom = stayterm;
		for (j = 1; j <= n; j++) {
			if (j == actor) continue;
			ev[net][j] = exp(u[net][j] - maxu);
			denom += ev[net][j];
		}
		draw = rng_unif(&rng) * denom;
		cum = stayterm;
		choice = 0;
		if (draw > cum) {
			for (j = 1; j <= n; j++) {
				if (j == actor) continue;
				cum += ev[net][j];
				choice = j;
				if (draw <= cum) break;
			}
		}
		if (P->want_score) {
			for (k = 0; k < M->nterms; k++) {
				double ebar = 0.0;
				const double *c = chg[net] + k * (n + 1);
				for (j = 1; j <= n; j++) { if (j == actor) continue; ebar += (ev[net][j] / denom) * c[j]; }
				score[k] += (choice != 0 ? c[choice] : 0.0) - ebar;
			}
		}
		R[net].stepsNet += 1.0;
		if (choice != 0) {
			toggle(&g[net], actor, choice);
			if (P->symtype == 4) toggle(&g[net], choice, actor);		/* protocol 62: a non-directed member (forcing: the actor's choice changes the tie in both directions, as RSiena AFORCE) */
			R[net].nchanges += 1.0;
		}
	}
	for (net = 0; net < nnet; net++) {
		const model_t *M = Ms[net];
		saom_tl_xg = &g0[(net + 1) % nnet];
		if (hasb) { attrs[net][M->nattr + 1] = behc0; if (M->has_behsim) attrs[net][M->nattr] = (double *)PDs[0]->beh0; }		/* the statistics of the terms with the behavior as covariate use the STARTING behavior */
		for (k = 0; k < M->nterms; k++) R[net].stat[k] = saom_eval_stat((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs[net], &g[net]);
		R[net].netdist = (double)mn_count_diff(&g[net], &g0[net]);
	}
	if (hasb) {
		/* the behavior statistics: the END behavior on the STARTING network (the first, or the second for the BEHNET2 terms) */
		model_t Mc1 = *M0, Mc2 = *M0;
		long ne0 = PDs[0]->nties, ne1 = PDs[1]->nties;
		double *out2 = (double *)calloc((size_t)(M0->nbehterms > 0 ? M0->nbehterms : 1), sizeof(double));
		double bd = 0.0;
		saom_tl_xg = NULL;
		for (k = 0; k < M0->nbehterms; k++) {
			int code = M0->behtermcodes[k];
			Mc1.behtermcodes[k] = (code >= BEHNET2) ? TERMCODE_BEH_LINEAR : code;
			Mc2.behtermcodes[k] = (code >= BEHNET2) ? code - BEHNET2 : TERMCODE_BEH_LINEAR;
		}
		saom_tl_beh0 = PDs[0]->beh0;
		beh_stats_on_edges(&Mc1, ne0, PDs[0]->ti, PDs[0]->tj, bv, R[0].statBehLag);
		beh_stats_on_edges(&Mc2, ne1, PDs[1]->ti, PDs[1]->tj, bv, out2);
		for (k = 0; k < M0->nbehterms; k++) if (M0->behtermcodes[k] >= BEHNET2) R[0].statBehLag[k] = out2[k];
		for (i = 1; i <= n; i++) bd += fabs(bv[i] - PDs[0]->beh0[i]);
		R[0].behdist = bd;
		free(out2);
	}
	saom_tl_xg = NULL;
	for (net = 0; net < nnet; net++) {
		graph_free(&g[net]);
		graph_free(&g0[net]);
		free(u[net]); free(ev[net]); free(tt[net]); free(c3[net]); free(chg[net]);
	}
	free(ijx);
	free(bv); free(behc); free(behc0);
	return 0;
}

typedef struct {
	int nnet;
	const model_t *M[MAXNETS];
	const period_t *per[MAXNETS];		/* per[k] = the P periods of network k */
	const simparams_t *prm[MAXNETS];	/* prm[k] = P entries */
	long K, P;
	unsigned long long seed;
	simres_t *res;				/* K * P * nnet */
	long next;
	saom_mutex_t mu;
} mn_job_t;
static void mn_worker_loop(mn_job_t *J) {
	for (;;) {
		long u;
		SAOM_MUTEX_LOCK(&J->mu);
		u = J->next++;
		SAOM_MUTEX_UNLOCK(&J->mu);
		if (u >= J->K * J->P) break;
		{
			long k = u / J->P, pd = u % J->P;
			const period_t *pds[MAXNETS];
			const simparams_t *pss[MAXNETS];
			int q;
			for (q = 0; q < J->nnet; q++) { pds[q] = &J->per[q][pd]; pss[q] = &J->prm[q][pd]; }
			simulate_period_mn(J->nnet, J->M, pds, pss, unit_seed(J->seed, k, pd), &J->res[u * J->nnet]);
		}
	}
}
#if defined(_WIN32)
static DWORD WINAPI mn_worker(LPVOID arg) { mn_worker_loop((mn_job_t *)arg); return 0; }
#else
static void *mn_worker(void *arg) { mn_worker_loop((mn_job_t *)arg); return NULL; }
#endif
static void mn_run_units(mn_job_t *J, long nthreads) {
	long t, nunits = J->K * J->P;
	saom_thread_t *th;
	if (nthreads > nunits) nthreads = nunits;
	if (nthreads < 1) nthreads = 1;
	J->next = 0;
	SAOM_MUTEX_INIT(&J->mu);
	if (nthreads == 1) { mn_worker_loop(J); SAOM_MUTEX_DESTROY(&J->mu); return; }
	th = (saom_thread_t *)malloc((size_t)nthreads * sizeof(saom_thread_t));
	for (t = 1; t < nthreads; t++) {
#if defined(_WIN32)
		th[t] = CreateThread(NULL, 0, mn_worker, J, 0, NULL);
#else
		pthread_create(&th[t], NULL, mn_worker, J);
#endif
	}
	mn_worker_loop(J);
	for (t = 1; t < nthreads; t++) {
#if defined(_WIN32)
		WaitForSingleObject(th[t], INFINITE);
		CloseHandle(th[t]);
#else
		pthread_join(th[t], NULL);
#endif
	}
	free(th);
	SAOM_MUTEX_DESTROY(&J->mu);
}

/* MNRUN|K seed nthreads want_score nnet  then per network its coefficients, then per network its P rates.
   Output (the plugin varlist, K rows): per period, per network: statistics (nterms), scores (nterms), distance, ministeps, changes. */
static ST_retcode mn_run(char *arg) {
	long K, nthreads, P = 0, pd, k, q, c, W;
	unsigned long long seed;
	int want_score, nnet, net;
	char *tok0;
	simparams_t *prm[MAXNETS];
	mn_job_t J;
	simres_t *res;
	tok0 = strtok(arg, " 	");
	if (!tok0) { SF_error("saom_sim: MNRUN empty\n"); return 198; }
	K = (long)atof(tok0);
	seed = (unsigned long long)next_double();
	nthreads = next_long();
	want_score = (int)next_long();
	nnet = (int)next_long();
	if (nnet < 2 || nnet > MAXNETS) { SF_error("saom_sim: MNRUN needs 2 to 4 networks\n"); return 198; }
	for (net = 0; net < nnet; net++) {
		if (!batch_states[net].ready) { SF_error("saom_sim: MNRUN without BATCHSETUP for every network\n"); return 198; }
		if (net == 0) P = batch_states[0].P;
		else if (batch_states[net].P != P) { SF_error("saom_sim: MNRUN networks with different numbers of periods\n"); return 198; }
	}
	for (net = 0; net < nnet; net++) {
		prm[net] = (simparams_t *)calloc((size_t)P, sizeof(simparams_t));
		for (k = 0; k < batch_states[net].M.nterms; k++) {
			double th = next_double();
			for (pd = 0; pd < P; pd++) prm[net][pd].theta[k] = th;
		}
		for (pd = 0; pd < P; pd++) { prm[net][pd].want_score = want_score; prm[net][pd].symtype = batch_states[net].symtype; }
	}
	if (batch_states[0].M.nbehterms > 0) {
		/* protocol 64: the coefficients of the behavior terms (after the networks'), the rates of the behavior after the networks' */
		for (k = 0; k < batch_states[0].M.nbehterms; k++) {
			double th = next_double();
			for (pd = 0; pd < P; pd++) prm[0][pd].thetaBeh[k] = th;
		}
	}
	for (net = 0; net < nnet; net++) for (pd = 0; pd < P; pd++) prm[net][pd].rate = next_double();
	if (batch_states[0].M.nbehterms > 0) for (pd = 0; pd < P; pd++) prm[0][pd].rateBeh = next_double();
	if (wire_parse_error) { for (net = 0; net < nnet; net++) free(prm[net]); SF_error("saom_sim: MNRUN argument string ran out of fields\n"); return 198; }
	if (nthreads <= 0) nthreads = saom_physical_cores();
	res = (simres_t *)calloc((size_t)(K * P * nnet), sizeof(simres_t));
	J.nnet = nnet; J.K = K; J.P = P; J.seed = seed; J.res = res;
	for (net = 0; net < nnet; net++) { J.M[net] = &batch_states[net].M; J.per[net] = batch_states[net].per; J.prm[net] = prm[net]; }
	mn_run_units(&J, nthreads);
	W = 0;
	for (net = 0; net < nnet; net++) W += 2 * batch_states[net].M.nterms + 3;
	for (k = 0; k < K; k++) {
		c = 0;
		for (pd = 0; pd < P; pd++) {
			for (net = 0; net < nnet; net++) {
				simres_t *r = &res[(k * P + pd) * nnet + net];
				long nt = batch_states[net].M.nterms;
				for (q = 0; q < nt; q++) SF_vstore((int)(++c), (int)(k + 1), r->stat[q]);
				for (q = 0; q < nt; q++) SF_vstore((int)(++c), (int)(k + 1), r->score[q]);
				SF_vstore((int)(++c), (int)(k + 1), r->netdist);
				SF_vstore((int)(++c), (int)(k + 1), r->stepsNet);
				SF_vstore((int)(++c), (int)(k + 1), r->nchanges);
			}
			if (batch_states[0].M.nbehterms > 0) {
				simres_t *r = &res[(k * P + pd) * nnet];
				long nb = batch_states[0].M.nbehterms;
				for (q = 0; q < nb; q++) SF_vstore((int)(++c), (int)(k + 1), r->statBehLag[q]);
				for (q = 0; q < nb; q++) SF_vstore((int)(++c), (int)(k + 1), r->scoreBeh[q]);
				SF_vstore((int)(++c), (int)(k + 1), r->behdist);
				SF_vstore((int)(++c), (int)(k + 1), r->stepsBeh);
				SF_vstore((int)(++c), (int)(k + 1), r->nchangesBeh);
			}
		}
	}
	(void)W;
	free(res);
	for (net = 0; net < nnet; net++) free(prm[net]);
	return 0;
}

/* MNOBS|nnet nedges: the statistics of the OBSERVED end networks, one period at a time; the plugin varlist: network, period, i, j (nedges rows, the
   end ties of network `network` in period `period`, 1-based) then the output columns (row 1): per period, per network the nterms statistics and the
   distance from the period's start network. The other network is the START network of the period (RSiena). */
static ST_retcode mn_obs(char *arg) {
	long nedges, P = 0, e, pd, k, c;
	int nnet, net;
	char *tok0;
	graph_t ge[MAXNETS], g0[MAXNETS];
	double *attrs[MAXNETS][MAXATTR + 2];
	tok0 = strtok(arg, " \t");
	if (!tok0) { SF_error("saom_sim: MNOBS empty\n"); return 198; }
	nnet = (int)atof(tok0);
	nedges = next_long();
	if (nnet < 2 || nnet > MAXNETS) return 198;
	for (net = 0; net < nnet; net++) {
		if (!batch_states[net].ready) { SF_error("saom_sim: MNOBS without BATCHSETUP for every network\n"); return 198; }
		P = batch_states[net].P;
	}
	c = 0;
	for (pd = 0; pd < P; pd++) {
		long n = batch_states[0].M.n;
		for (net = 0; net < nnet; net++) {
			const model_t *M = &batch_states[net].M;
			const period_t *PD = &batch_states[net].per[pd];
			graph_init(&ge[net], n, 1, nedges + 8);
			graph_init(&g0[net], n, 1, PD->nties + 8);
			for (e = 0; e < PD->nties; e++) toggle(&g0[net], PD->ti[e], PD->tj[e]);
			for (k = 0; k < M->nattr; k++) attrs[net][k] = PD->xattr[k] ? PD->xattr[k] : M->attrs[k];
			attrs[net][M->nattr] = NULL;
			attrs[net][M->nattr + 1] = NULL;
			if (batch_states[0].M.nbehterms > 0) {
				/* protocol 64: the terms with the behavior as covariate read the STARTING behavior of the period, centred */
				long q;
				double *bc = (double *)calloc((size_t)(n + 1), sizeof(double));
				for (q = 1; q <= n; q++) bc[q] = batch_states[0].per[pd].beh0[q] - batch_states[0].M.behOverallMean;
				attrs[net][M->nattr + 1] = bc;
				if (M->has_behsim) attrs[net][M->nattr] = (double *)batch_states[0].per[pd].beh0;
				saom_behsim_range = (batch_states[0].M.behrange > 0.0) ? batch_states[0].M.behrange : 1.0;
			}
		}
		for (e = 1; e <= nedges; e++) {
			ST_double vn, vp, vi, vj;
			SF_vdata(1, (int)e, &vn); SF_vdata(2, (int)e, &vp); SF_vdata(3, (int)e, &vi); SF_vdata(4, (int)e, &vj);
			if ((long)vp == pd + 1 && (int)vn >= 1 && (int)vn <= nnet) toggle(&ge[(int)vn - 1], (long)vi, (long)vj);
		}
		for (net = 0; net < nnet; net++) {
			const model_t *M = &batch_states[net].M;
			saom_tl_xg = &g0[(net + 1) % nnet];
			for (k = 0; k < M->nterms; k++) SF_vstore((int)(5 + c++), 1, saom_eval_stat((int)k, (int *)M->termcodes, (int *)M->attridx, (double *)M->p1, attrs[net], &ge[net]));
			SF_vstore((int)(5 + c++), 1, (double)mn_count_diff(&ge[net], &g0[net]));
		}
		saom_tl_xg = NULL;
		for (net = 0; net < nnet; net++) { graph_free(&ge[net]); graph_free(&g0[net]); if (batch_states[0].M.nbehterms > 0) free(attrs[net][batch_states[net].M.nattr + 1]); }
	}
	return 0;
}

/* ===================================================================
   Legacy single-simulation call (the wire protocol documented in this
   file's header): parse, read the frame into model_t/period_t, run
   simulate_period() with the caller's seed, write everything back
   exactly as before.
   =================================================================== */
static ST_retcode legacy_call(char *arg0) {
	char *argbuf;
	model_t M;
	period_t PD;
	simparams_t P;
	simres_t R;
	long n, directed, nties_in, i, k, nmissdyads, hasmissl, haspresentNet;
	unsigned long long rngseed;
	double *attrmem[MAXATTR];
	graph_t *g;

	memset(&M, 0, sizeof(M));
	memset(&PD, 0, sizeof(PD));
	memset(&P, 0, sizeof(P));

	argbuf = (char *)malloc(strlen(arg0) + 1);
	strcpy(argbuf, arg0);
	{
		char *tok0 = strtok(argbuf, " \t");
		if (!tok0) { free(argbuf); SF_error("saom_sim: empty argument string\n"); return(198); }
		n = (long)atof(tok0);
	}
	M.n = n;
	directed  = next_long();
	nties_in  = next_long();
	P.rate    = next_double();
	rngseed   = (unsigned long long)next_double();
	M.nattr   = next_long();
	M.nterms  = next_long();
	if (M.nterms > MAXTERMS) { SF_error("saom_sim: too many terms\n"); free(argbuf); return(198); }
	if (M.nattr > MAXATTR) { SF_error("saom_sim: too many attribute arrays\n"); free(argbuf); return(198); }
	for (i = 0; i < M.nterms; i++) {
		M.termcodes[i] = (int)next_long();
		M.attridx[i] = (int)next_long();
		M.p1[i] = next_double();
	}
	saom_model_need_flags((int)M.nterms, M.termcodes, M.attridx, M.p1, &M.need_adj, &M.need_transtrip, &M.need_cycle3);
	for (i = 0; i < M.nterms; i++) P.theta[i] = next_double();
	P.want_score = (int)next_long();

	M.nbehterms = next_long();
	M.nbeh = (M.nbehterms > 0) ? 1 : 0;
	M.nbehtermsAll = M.nbehterms;
	M.behoff[0] = 0;
	if (M.nbehterms > MAXBEHTERMS) { SF_error("saom_sim: too many behavior terms\n"); free(argbuf); return(198); }
	for (i = 0; i < M.nbehterms; i++) {
		M.behtermcodes[i] = (int)next_long();
		if (M.behtermcodes[i] == TERMCODE_BEH_AVALT || M.behtermcodes[i] == TERMCODE_BEH_AVSIM || SAOM_BEH_NEWTC(M.behtermcodes[i]) || SAOM_BEH_XALTTC(M.behtermcodes[i]) || SAOM_BSTC(M.behtermcodes[i]) || SAOM_BQTC(M.behtermcodes[i]) || SAOM_BRTC(M.behtermcodes[i]) || SAOM_BUTC(M.behtermcodes[i])) M.need_adj = 1;
	}
	for (i = 0; i < M.nbehterms; i++) P.thetaBeh[i] = next_double();
	if (M.nbehterms > 0) {
		P.rateBeh = next_double();
		M.behminval = next_double();
		M.behmaxval = next_double();
		M.behSimMean = next_double();
		M.behOverallMean = next_double();
		M.behrange = M.behmaxval - M.behminval;
	}
	else {
		M.behrange = 1.0;
	}
	P.condmode = next_long();
	P.targetChange = next_double();
	hasmissl = next_long();
	nmissdyads = next_long();
	haspresentNet = next_long();
	P.symtype = next_long();
	P.hasratecov = next_long();
	P.ratecovattr = NULL;
	P.ratecoef = NULL;
	P.nsr = 0;
	if (P.hasratecov < 0 || P.hasratecov > MAXRC) { free(argbuf); SF_error("saom_sim: too many ratecov() covariates\n"); return(198); }
	if (P.hasratecov) {
		/* K covariates: K x n values, then K coefficients (K = 1: the
		   protocol-7 layout) */
		P.ratecovattr = (double *)malloc((size_t)(n * P.hasratecov) * sizeof(double));
		P.ratecoef = (double *)malloc((size_t)P.hasratecov * sizeof(double));
		for (i = 0; i < n * P.hasratecov; i++) P.ratecovattr[i] = next_double();
		for (i = 0; i < P.hasratecov; i++) P.ratecoef[i] = next_double();
	}
	parse_model_trailer11(&M);
	free(argbuf);

	if (wire_parse_error) { free(P.ratecovattr); SF_error("saom_sim: wire-protocol argument string ran out of fields (a Mata/native field-count mismatch) - refusing to simulate on partially-parsed input\n"); return(198); }
	SF_scal_save("__saom_native_version", (ST_double)SAOM_NATIVE_VERSION);
	for (i = 0; i < M.nterms; i++) if (SAOM_DYNTC(M.termcodes[i])) M.has_behsim = 1;
	/* only a model that uses behsim sets the (process-wide) range: the version probe, a single call without behavior,
	   must not reset the range of a batch model that is set up */
	if (M.has_behsim) saom_behsim_range = (M.behrange > 0.0) ? M.behrange : 1.0;
	if (M.has_behsim && M.nbehterms == 0) { free(P.ratecovattr); SF_error("saom_sim: behsim needs a co-evolving behavior (nbehterms > 0)\n"); return(198); }
	if (M.has_behsim && M.nattr >= MAXATTR) { free(P.ratecovattr); SF_error("saom_sim: too many attribute arrays for behsim\n"); return(198); }
	if (!directed) { free(P.ratecovattr); SF_error("saom_sim: directed networks only\n"); return(198); }
	if (M.has_behsim) for (i = 0; i < M.nterms; i++) if (SAOM_DYNTC(M.termcodes[i])) M.attridx[i] = (int)(M.nattr + 1);
	for (i = 0; i < M.nterms; i++) if (SAOM_STARTTC(M.termcodes[i])) M.has_start = 1;
	for (i = 0; i < M.nterms; i++) if ((M.termcodes[i] >= 1000 && M.termcodes[i] < 2000) || (M.termcodes[i] >= 4000 && M.termcodes[i] < 5000)) { M.has_behcov = 1; M.attridx[i] = (int)(M.nattr + 2); }
	if (M.has_behcov && (M.nbehterms == 0 || M.nattr + 2 > MAXATTR)) { free(P.ratecovattr); SF_error("saom_sim: network terms with the behavior as covariate need a co-evolving behavior\n"); return(198); }

	for (k = 0; k < M.nattr; k++) {
		attrmem[k] = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(3 + k), i, &v);
			attrmem[k][i] = SF_is_missing(v) ? 0.0 : v;
		}
		M.attrs[k] = attrmem[k];
	}
	PD.nties = nties_in;
	PD.ti = (long *)malloc((size_t)(nties_in > 0 ? nties_in : 1) * sizeof(long));
	PD.tj = (long *)malloc((size_t)(nties_in > 0 ? nties_in : 1) * sizeof(long));
	for (i = 1; i <= nties_in; i++) {
		ST_double vi, vj;
		SF_vdata(1, i, &vi);
		SF_vdata(2, i, &vj);
		PD.ti[i - 1] = (long)vi;
		PD.tj[i - 1] = (long)vj;
	}
	if (M.nbehterms > 0) {
		PD.beh0 = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(3 + M.nattr), i, &v);
			PD.beh0[i] = v;
		}
	}
	if (hasmissl) {
		long basecol = 3 + M.nattr + (M.nbehterms > 0 ? 1 : 0);
		PD.hasmiss = 1;
		PD.nmiss = nmissdyads;
		PD.mi = (long *)malloc((size_t)(nmissdyads > 0 ? nmissdyads : 1) * sizeof(long));
		PD.mj = (long *)malloc((size_t)(nmissdyads > 0 ? nmissdyads : 1) * sizeof(long));
		for (i = 0; i < nmissdyads; i++) {
			ST_double vi, vj;
			SF_vdata((int)basecol, i + 1, &vi);
			SF_vdata((int)(basecol + 1), i + 1, &vj);
			PD.mi[i] = (long)vi;
			PD.mj[i] = (long)vj;
		}
		PD.missbeh = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)(basecol + 2), i, &v);
			PD.missbeh[i] = v;
		}
	}
	if (haspresentNet) {
		long presentcol = 3 + M.nattr + (M.nbehterms > 0 ? 1 : 0) + (hasmissl ? 3 : 0);
		PD.haspresent = 1;
		PD.present = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (i = 1; i <= n; i++) {
			ST_double v;
			SF_vdata((int)presentcol, i, &v);
			PD.present[i] = v;
		}
	}

	simulate_period(&M, &PD, &P, rngseed, 1, &R);

	if (P.want_score) {
		for (k = 0; k < M.nterms; k++) {
			char nm[40];
			sprintf(nm, "__saom_native_score%ld", k + 1);
			SF_scal_save(nm, R.score[k]);
		}
		for (k = 0; k < M.nbehterms; k++) {
			char nm[40];
			sprintf(nm, "__saom_native_scorebeh%ld", k + 1);
			SF_scal_save(nm, R.scoreBeh[k]);
		}
	}
	g = R.gfinal;
	for (i = 0; i < g->nties; i++) {
		SF_vstore(1, i + 1, (ST_double)g->elist_i[i]);
		SF_vstore(2, i + 1, (ST_double)g->elist_j[i]);
	}
	SF_scal_save("__saom_native_nties_out", (ST_double)g->nties);
	SF_scal_save("__saom_native_steps", (ST_double)R.steps);
	SF_scal_save("__saom_native_nchanges", (ST_double)R.nchanges);
	SF_scal_save("__saom_native_condtime", (ST_double)R.t);
	SF_scal_save("__saom_native_rcscore", (ST_double)R.rcscore[0]);
	for (i = 0; i < P.hasratecov; i++) {
		char rcnm[48];
		snprintf(rcnm, sizeof(rcnm), "__saom_native_rcscore%ld", (long)(i + 1));
		SF_scal_save(rcnm, (ST_double)R.rcscore[i]);
	}
	SF_scal_save("__saom_native_stepsnet", (ST_double)R.stepsNet);
	SF_scal_save("__saom_native_stepsbeh", (ST_double)R.stepsBeh);
	SF_scal_save("__saom_native_netdist", (ST_double)R.netdist);
	for (k = 0; k < M.nterms; k++) {
		char nm[40];
		sprintf(nm, "__saom_native_stat%ld", k + 1);
		SF_scal_save(nm, R.stat[k]);
	}
	if (M.nbehterms > 0) {
		for (i = 1; i <= n; i++) SF_vstore((int)(3 + M.nattr), i, (ST_double)R.behfinal[i]);
		SF_scal_save("__saom_native_nchangesbeh", (ST_double)R.nchangesBeh);
		for (k = 0; k < M.nbehterms; k++) {
			char nm[48];
			sprintf(nm, "__saom_native_statbeh%ld", k + 1);
			SF_scal_save(nm, R.statBeh[k]);
			sprintf(nm, "__saom_native_statbehlag%ld", k + 1);
			SF_scal_save(nm, R.statBehLag[k]);
		}
	}
	graph_free(g);
	free(g);
	free(R.behfinal);
	for (k = 0; k < M.nattr; k++) free(attrmem[k]);
	free(PD.ti); free(PD.tj); free(PD.beh0); free(PD.mi); free(PD.mj); free(PD.missbeh); free(PD.present);
	free(P.ratecovattr);
	free(P.ratecoef);
	free(M.struct_off); free(M.struct_j);
	return(0);
}

#ifdef SAOM_PROFILE
static double prof_calls = 0.0;
#endif
/* protocol 46: NETSTAT|n ne termcode p1 - the observed statistic of ONE network term evaluated by the plugin's own saom_stat_term(), so that a
   native-only term needs no Mata twin for its target. Data in the current frame: columns 1, 2 = the arcs (ne rows), column 3 = the attribute
   (n rows, 1-based actors). The value is returned in the scalar __saom_netstat_val. */
static ST_retcode netstat_cmd(char *arg) {
	long n, ne, i, ne0 = 0;
	graph_t g0n;
	int tc;
	double p1, *a, val;
	graph_t g;
	char *tok = strtok(arg, " \t");
	if (!tok) return 198;
	n = (long)atof(tok);
	tok = strtok(NULL, " \t"); ne = (long)atof(tok);
	tok = strtok(NULL, " \t"); tc = (int)atof(tok);
	tok = strtok(NULL, " \t"); p1 = atof(tok);
	tok = strtok(NULL, " \t"); saom_tl_behscale = tok ? atof(tok) : 1.0;	/* protocol 58: 1 / behavior range for the sim effects with the behavior as covariate */
	tok = strtok(NULL, " \t"); ne0 = tok ? (long)atof(tok) : 0;			/* protocol 61: the arcs of the period's start network in the last two columns */
	graph_init(&g, n, 1, ne + 8);
	for (i = 1; i <= ne; i++) {
		ST_double v1, v2;
		SF_vdata(1, i, &v1); SF_vdata(2, i, &v2);
		toggle(&g, (long)v1, (long)v2);
	}
	a = (double *)calloc((size_t)(n + 1), sizeof(double));
	for (i = 1; i <= n; i++) { ST_double v; SF_vdata(3, i, &v); a[i] = v; }
	if (SAOM_DWTC(tc)) {
		/* protocol 49: the dyadic matrix W in the columns 4 .. 3 + n (column j = W[., j]) */
		double **cols = (double **)calloc((size_t)n, sizeof(double *));
		long jj, ii;
		for (ii = 0; ii < n; ii++) cols[ii] = (double *)calloc((size_t)(n + 1), sizeof(double));
		for (jj = 1; jj <= n; jj++) for (ii = 1; ii <= n; ii++) { ST_double v; SF_vdata((int)(3 + jj), ii, &v); cols[ii - 1][jj] = v; }
		val = dw_stat(&g, tc, cols, 0);
		for (ii = 0; ii < n; ii++) free(cols[ii]);
		free(cols);
	}
	else {
		if (ne0 > 0) {
			long nv = (long)SF_nvars();
			graph_init(&g0n, n, 1, ne0 + 8);
			for (i = 1; i <= ne0; i++) { ST_double v1, v2; SF_vdata((int)(nv - 1), i, &v1); SF_vdata((int)nv, i, &v2); toggle(&g0n, (long)v1, (long)v2); }
			saom_tl_g0 = &g0n;
		}
		val = saom_stat_term(&g, tc, a, p1);
		if (ne0 > 0) { graph_free(&g0n); saom_tl_g0 = NULL; }
	}
	SF_scal_save("__saom_netstat_val", (ST_double)val);
	free(a);
	graph_free(&g);
	return 0;
}

/* protocol 47: BEHSTAT|n ne termcode range simMean mean - the observed statistic of ONE behavior term (saom_beh_stat_term()) so that a native-only
   behavior effect needs no Mata twin for its target. Current frame: columns 1, 2 = the arcs (ne rows), column 3 = the behavior (raw, n rows),
   column 4 = a covariate (centred, n rows; offered in every covariate slot). Result in the scalar __saom_behstat_val. */
static ST_retcode behstat_cmd(char *arg) {
	long n, ne, i;
	int tc, sl, hasdy;
	double range, simMean, mean, *bv, *cv, val;
	graph_t g;
	char *tok = strtok(arg, " \t");
	if (!tok) return 198;
	n = (long)atof(tok);
	tok = strtok(NULL, " \t"); ne = (long)atof(tok);
	tok = strtok(NULL, " \t"); tc = (int)atof(tok);
	tok = strtok(NULL, " \t"); range = atof(tok);
	tok = strtok(NULL, " \t"); simMean = atof(tok);
	tok = strtok(NULL, " \t"); mean = atof(tok);
	tok = strtok(NULL, " \t"); hasdy = tok ? (int)atof(tok) : 0;
	tok = strtok(NULL, " \t"); saom_tl_behvar = tok ? atof(tok) : 0.0;		/* protocol 60 */
	graph_init(&g, n, 1, ne + 8);
	for (i = 1; i <= ne; i++) {
		ST_double v1, v2;
		SF_vdata(1, i, &v1); SF_vdata(2, i, &v2);
		toggle(&g, (long)v1, (long)v2);
	}
	bv = (double *)calloc((size_t)(n + 1), sizeof(double));
	cv = (double *)calloc((size_t)(n + 1), sizeof(double));
	for (i = 1; i <= n; i++) { ST_double v; SF_vdata(3, i, &v); bv[i] = v; SF_vdata(4, i, &v); cv[i] = v; }
	for (sl = 0; sl < 8; sl++) saom_tl_cov[sl] = cv;
	{
		double *dy = NULL, *olddy[8];
		long jj, ii;
		for (sl = 0; sl < 8; sl++) { olddy[sl] = saom_bdy[sl]; saom_tl_bdy[sl] = NULL; }
		if (hasdy) {
			dy = (double *)calloc((size_t)(n * n), sizeof(double));
			for (jj = 1; jj <= n; jj++) for (ii = 1; ii <= n; ii++) { ST_double v; SF_vdata((int)(4 + jj), ii, &v); dy[(ii - 1) * n + (jj - 1)] = v; }
			for (sl = 0; sl < 8; sl++) saom_bdy[sl] = dy;
			saom_bdy_n = n;
				}
		val = saom_beh_stat_term(&g, bv, tc, range, simMean, mean);
		for (sl = 0; sl < 8; sl++) saom_bdy[sl] = olddy[sl];
		free(dy);
	}
	for (sl = 0; sl < 8; sl++) saom_tl_cov[sl] = NULL;
	SF_scal_save("__saom_behstat_val", (ST_double)val);
	free(bv); free(cv);
	graph_free(&g);
	return 0;
}


/* protocol 63: CONTRIBK|pd k - the change contributions of every ego i (row) and every alternative j (variable j of the call) for network
   term k (1-based) on the START network of period pd (1-based) of the resident BATCHSETUP model: the statistic change when the tie i -> j is
   toggled (RSiena's getChangeContributions()). Used by estat importance. The diagonal (no change) is 0. */
static ST_retcode contrib_cmd(char *arg) {
	long pd, kk, n, i, j, stride;
	const model_t *M;
	const period_t *PD;
	graph_t g, g0s;
	double *cbv = NULL, *cbc = NULL, *attrs[MAXATTR + 2], *tt_arr = NULL, *c3_arr = NULL, *chg, *u;
	unsigned char *ijx;
	simparams_t P;
	long actor, k;
	char *tok = strtok(arg, " \t");
	if (!tok || !batch_cur->ready) return 198;
	pd = (long)atof(tok);
	tok = strtok(NULL, " \t"); if (!tok) return 198;
	kk = (long)atof(tok);
	M = &batch_cur->M;
	if (pd < 1 || pd > batch_cur->P || kk < 1 || kk > M->nterms) return 198;
	PD = &batch_cur->per[pd - 1];
	n = M->n;
	stride = n + 1;
	if ((long)SF_nvars() < n || (long)SF_nobs() < n) return 198;
	memset(&P, 0, sizeof(P));
	for (k = 0; k < M->nattr; k++) attrs[k] = PD->xattr[k] ? PD->xattr[k] : M->attrs[k];
	attrs[M->nattr] = NULL;
	attrs[M->nattr + 1] = NULL;
	if (M->nbehterms > 0 && PD->beh0) {		// network terms that read the behavior: the behavior at the start of the period
		long q;
		cbv = (double *)malloc((size_t)(n + 1) * sizeof(double));
		memcpy(cbv, PD->beh0, (size_t)(n + 1) * sizeof(double));
		if (M->has_behsim) attrs[M->nattr] = cbv;
		if (M->has_behcov) {
			cbc = (double *)calloc((size_t)(n + 1), sizeof(double));
			for (q = 1; q <= n; q++) cbc[q] = cbv[q] - M->behOverallMean;
			attrs[M->nattr + 1] = cbc;
		}
	}
	{ int jc; for (jc = 0; jc < 8; jc++) { saom_tl_cov[jc] = PD->bcov[jc]; saom_tl_bdy[jc] = PD->bdy[jc]; } }
	saom_tl_beh0 = PD->beh0;
	saom_tl_behscale = (M->behrange > 0.0) ? 1.0 / M->behrange : 1.0;
	saom_tl_behvar = M->behVariance;
	graph_init(&g, n, M->need_adj, PD->nties);
	for (i = 0; i < PD->nties; i++) toggle(&g, PD->ti[i], PD->tj[i]);
	if (M->has_start) {
		graph_init(&g0s, n, 1, PD->nties);
		for (i = 0; i < PD->nties; i++) toggle(&g0s, PD->ti[i], PD->tj[i]);
		saom_tl_g0 = &g0s;
	}
	else saom_tl_g0 = NULL;
	tt_arr = M->need_transtrip ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
	c3_arr = M->need_cycle3 ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
	chg = (double *)calloc((size_t)(n + 1) * (size_t)(M->nterms > 0 ? M->nterms : 1), sizeof(double));
	u = (double *)calloc((size_t)(n + 1), sizeof(double));
	ijx = (unsigned char *)malloc((size_t)(n + 1));
	for (actor = 1; actor <= n; actor++) {
		if (M->need_transtrip) { memset(tt_arr, 0, (size_t)(n + 1) * sizeof(double)); batch_otp_plus_osp(&g, actor, tt_arr); }
		if (M->need_cycle3) { memset(c3_arr, 0, (size_t)(n + 1) * sizeof(double)); batch_otp_reverse(&g, actor, c3_arr); }
		eval_network_alternatives(M, &P, &g, attrs, actor, NULL, tt_arr, c3_arr, chg, u, ijx);
		for (j = 1; j <= n; j++) SF_vstore((int)j, (int)actor, (j == actor) ? 0.0 : chg[(kk - 1) * stride + j]);
	}
	free(cbv); free(cbc); free(tt_arr); free(c3_arr); free(chg); free(u); free(ijx);
	graph_free(&g);
	if (M->has_start) { graph_free(&g0s); saom_tl_g0 = NULL; }
	return 0;
}

/* protocol 66: CONTRIBB|pd k - the change contributions of behavior term k (1-based) for every actor (row) on the START network and START
   behavior of period pd of the resident BATCHSETUP model: variable 1 = the statistic change when the actor's behavior goes down by one,
   variable 2 = up by one; missing when the option is outside the range. Used by estat importance for fits with a behavior. */
static ST_retcode contribb_cmd(char *arg) {
	long pd, kk, n, i, actor;
	const model_t *M;
	const period_t *PD;
	graph_t g;
	double *bv;
	char *tok = strtok(arg, " \t");
	if (!tok || !batch_cur->ready) return 198;
	pd = (long)atof(tok);
	tok = strtok(NULL, " \t"); if (!tok) return 198;
	kk = (long)atof(tok);
	M = &batch_cur->M;
	if (pd < 1 || pd > batch_cur->P || M->nbehterms < 1 || kk < 1 || kk > M->nbehterms) return 198;
	PD = &batch_cur->per[pd - 1];
	n = M->n;
	if ((long)SF_nvars() < 2 || (long)SF_nobs() < n) return 198;
	{ int jc; for (jc = 0; jc < 8; jc++) { saom_tl_cov[jc] = PD->bcov[jc]; saom_tl_bdy[jc] = PD->bdy[jc]; } }
	saom_tl_beh0 = PD->beh0;
	saom_tl_behscale = (M->behrange > 0.0) ? 1.0 / M->behrange : 1.0;
	saom_tl_behvar = M->behVariance;
	graph_init(&g, n, M->need_adj, PD->nties);
	for (i = 0; i < PD->nties; i++) toggle(&g, PD->ti[i], PD->tj[i]);
	bv = (double *)malloc((size_t)(n + 1) * sizeof(double));
	memcpy(bv, PD->beh0, (size_t)(n + 1) * sizeof(double));
	for (actor = 1; actor <= n; actor++) {
		double cur = bv[actor];
		double dn = SV_missval, up = SV_missval;
		if (cur > M->behminval) dn = saom_beh_change_term(&g, bv, M->behtermcodes[kk - 1], M->behOverallMean, M->behrange, M->behSimMean, actor, -1.0);
		if (cur < M->behmaxval) up = saom_beh_change_term(&g, bv, M->behtermcodes[kk - 1], M->behOverallMean, M->behrange, M->behSimMean, actor, 1.0);
		SF_vstore(1, (int)actor, dn);
		SF_vstore(2, (int)actor, up);
	}
	free(bv);
	graph_free(&g);
	return 0;
}

STDLL stata_call(int argc, char *argv[]) {
	wire_parse_error = 0;
#ifdef SAOM_PROFILE
	prof_calls += 1.0;
#endif
	if (argc < 1) { SF_error("saom_sim: missing argument string\n"); return(198); }
	if (strncmp(argv[0], "NNMULTIPLEX|", 12) == 0) return nn_call(argv);
	if (strncmp(argv[0], "BATCHSETUP", 10) == 0 && (argv[0][10] == '|' || (argv[0][10] >= '0' && argv[0][10] < '0' + MAXNETS && argv[0][11] == '|'))) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		int slot = (argv[0][10] == '|') ? 0 : argv[0][10] - '0';
		strcpy(buf, argv[0] + (argv[0][10] == '|' ? 11 : 12));
		batch_cur = &batch_states[slot];
		rc = batch_setup(buf);
		batch_cur = &batch_states[0];
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "MNRUN|", 6) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 6);
		rc = mn_run(buf);
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "MNOBS|", 6) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 6);
		rc = mn_obs(buf);
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "BATCHRUN|", 9) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 9);
		rc = batch_run(buf);
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "BATCHCLEAN|", 11) == 0) { int sl; for (sl = MAXNETS - 1; sl >= 0; sl--) { batch_cur = &batch_states[sl]; batch_free(); } batch_cur = &batch_states[0]; return 0; }
	if (strncmp(argv[0], "BEHSTAT|", 8) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 8);
		rc = behstat_cmd(buf);
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "CONTRIBK|", 9) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 9);
		rc = contrib_cmd(buf);
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "CONTRIBB|", 9) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 9);
		rc = contribb_cmd(buf);
		free(buf);
		return rc;
	}
	if (strncmp(argv[0], "NETSTAT|", 8) == 0) {
		char *buf = (char *)malloc(strlen(argv[0]) + 1);
		ST_retcode rc;
		strcpy(buf, argv[0] + 8);
		rc = netstat_cmd(buf);
		free(buf);
		return rc;
	}
#ifdef SAOM_PROFILE
	if (strncmp(argv[0], "PROFILE|", 8) == 0) {
		const char *nm[8] = {"setup", "actor", "eval", "softmax", "apply", "beh", "end", "wait"};
		int q;
		char buf[64];
		for (q = 0; q < 8; q++) {
			sprintf(buf, "__saom_prof_%s", nm[q]); SF_scal_save(buf, prof_t[q]);
			sprintf(buf, "__saom_profn_%s", nm[q]); SF_scal_save(buf, prof_n[q]);
		}
		for (q = 0; q < MAXTERMS; q++) {
			sprintf(buf, "__saom_prof_term%d", q + 1); SF_scal_save(buf, prof_term_t[q]);
		}
		SF_scal_save("__saom_prof_calls", prof_calls);
		memset(prof_t, 0, sizeof(prof_t)); memset(prof_n, 0, sizeof(prof_n));
		memset(prof_term_t, 0, sizeof(prof_term_t)); memset(prof_term_n, 0, sizeof(prof_term_n));
		return 0;
	}
#endif
	if (strncmp(argv[0], "NCORES|", 7) == 0) { SF_scal_save("__saom_native_ncores", (ST_double)saom_physical_cores()); return 0; }
	return legacy_call(argv[0]);
}
