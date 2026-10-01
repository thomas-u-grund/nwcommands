/*
	unw_saom.do -- native SAOM (stochastic actor-oriented model) estimation
	core for nwcommands (nwsaom).

	See docs/SAOM_ROADMAP.md (scope/status) and docs/SAOM_ARCHITECTURE.md
	(design reference) for the full account. Summary: this file reuses
	`nwergm`'s own ErgmGraph/ErgmModel/ErgmTermData classes and stat_X/
	change_X term functions (defined in unw_ergm.do) READ-ONLY - never
	edits that file - because a SAOM ministep's per-alternative
	objective-function delta is, for every v1 effect (outdegree,
	reciprocity, nodematch), mathematically identical to nwergm's own
	dyad-local change statistic for that same term. See
	docs/SAOM_ARCHITECTURE.md's "The reuse is not a shortcut - it is
	mathematically exact" section for the derivation.

	Compiled into the same lnwcommands.mlib as unw_core.do/unw_ergm.do
	once both this initiative and the concurrent nwergm work are merged
	(see lib/build.do). Until then, dev/testing sources this file live:
	`do unw_ergm.do` then `do unw_saom.do`, matching every existing
	cscripts/test_nwergm_*.do script's own convention - never rebuilds
	lib/lnwcommands.mlib, which is currently mid-edit by a concurrent
	session working on nwergm.

	Clean-room implementation against the published SAOM statistical
	definition (Snijders 1996, 2001, 2005 "Models for Longitudinal
	Network Data"; Snijders, van de Bunt & Steglich 2010 "Introduction to
	stochastic actor-based models for network dynamics" - the Method of
	Moments / Robbins-Monro estimator these describe is v1's own
	estimator). No RSiena source code, comment, or identifier is copied
	here.
*/

set matastrict on

mata:

/* ===================================================================
   SaomMinistep: one actor's single-tie-change opportunity.

   Actor i chooses among "toggle tie i->j" for every j != i, plus "no
   change", via a multinomial logit over the objective-function delta
   theta . M.full_change(G,i,j) - the SAME dyad-local change-statistic
   machinery nwergm's own MCMC already uses (see this file's own header
   and docs/SAOM_ARCHITECTURE.md). "No change" is the reference
   alternative (utility normalized to 0, standard for a multinomial
   logit with one baseline category).

   Mutates G in place (via G.toggle()) if a real alternative is drawn.
   Returns the chosen j (1..n), or 0 if "no change" was drawn - callers
   that don't need this (e.g. SaomSimulateInterval) can discard it.

   `present' (harmonisation unit 33, composition change - "joiners and
   leavers", Huisman and Snijders 2003; see docs/SAOM_ROADMAP.md's own
   unit-33 entry for the full method/scope account) is an OPTIONAL
   trailing n x 1 real colvector, 1/0 per actor - when supplied, an
   ABSENT actor (present[j]==0) is never offered as an alternative j
   (excluded from the choice set entirely, exactly as if it did not
   exist for this ministep - matching real RSiena's own joiners/
   leavers construction: an absent actor cannot be tied TO during its
   own absence). Omitting `present' entirely (every pre-existing call
   site) is IDENTICAL to passing an all-ones vector - a true no-op,
   zero behavior change for any caller not yet updated for composition
   change. Does NOT restrict which actor i itself may be i - callers
   own that restriction (SaomSimulateInterval's own actor-draw step,
   for the SAME reason: presence gates the RATE/opportunity, decided at
   the caller level).
   =================================================================== */
/* SaomNetworkFullChangeGated(): harmonisation unit 167 (network-side
   endowment/creation) - the network-side analogue of
   SaomBehaviorModel::full_change()'s own `fntype' direction gating
   above, but deliberately built as a SEPARATE, SAOM-owned wrapper
   around ErgmModel::full_change() rather than a new field on
   ErgmModel itself - ErgmModel is also nwergm's own static-ERGM
   estimation class, which has no "before/after direction" concept at
   all (a static ERGM has no ministep, only tie-present-or-not), so a
   `fntype'-style field added directly there would leak SAOM-only
   semantics into every nwergm code path forever. `fntype' here is
   instead an ordinary parameter, threaded through by whichever SAOM
   caller needs it - ErgmModel/unw_ergm.do is untouched by this unit.

   Gating rule verified directly against real RSiena C++ source
   (`NetworkVariable.cpp`'s own `calculateTieFlipContributions()`,
   the exact same real source the behavior-side gate above was
   verified against): a creation-role move is a toggle FROM untied TO
   tied (`!G.has_edge(i,j)' BEFORE the toggle); an endowment-role move
   is a toggle FROM tied TO untied (`G.has_edge(i,j)' BEFORE the
   toggle) - i.e. "does this ministep create a new tie, or withdraw an
   existing one", evaluated on G's CURRENT (pre-toggle) state, exactly
   mirroring the behavior-side gate's own "is this ministep a value
   increase or decrease" check on `diff's sign. An eval-type term
   (fntype=0) is unaffected, exactly as on the behavior side. */
real rowvector SaomNetworkFullChangeGated(class ErgmModel scalar M, real rowvector fntype,
	class ErgmGraph scalar G, real scalar i, real scalar j){

	real rowvector out, full
	real scalar t, creation

	full = M.full_change(G, i, j)
	creation = !G.has_edge(i, j)		// BEFORE the toggle: untied -> tied is a creation-role move
	out = J(1, cols(full), 0)
	for (t=1; t<=cols(full); t++) {
		if (fntype[t] == 1 & creation) continue	// endowment: only on withdrawals (tied -> untied)
		if (fntype[t] == 2 & !creation) continue	// creation: only on new ties (untied -> tied)
		out[t] = full[t]
	}
	return(out)
}

/* SaomStructuralMatchesWaves(): structural zeros/ones ("expansion",
   2026-09-02) - nwsaom.ado's own registration-time validation helper.
   Returns 1 iff every dyad marked `structural[i,j]==1' holds the SAME
   tie value in BOTH `Gstart' and `Gend' - a frozen dyad that genuinely
   differs between the two observed waves means something toggled it
   despite being declared structurally fixed, a real data/declaration
   mismatch nwsaom.ado rejects with a clear error rather than silently
   simulating from an inconsistent starting assumption. */
real scalar SaomStructuralMatchesWaves(class ErgmGraph scalar Gstart,
	class ErgmGraph scalar Gend, real matrix structural) {

	real scalar n, i, j

	n = Gstart.n
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i == j) continue
			if (structural[i,j] != 1) continue
			if (Gstart.has_edge(i,j) != Gend.has_edge(i,j)) return(0)
		}
	}
	return(1)
}

real scalar SaomMinistep(class ErgmGraph scalar G, class ErgmModel scalar M,
	real rowvector theta, real scalar i, | real colvector present, real rowvector fntype,
	real matrix structural) {

	real scalar n, j, k, maxu, denom, draw, cum, choice, haspresent, hasfntype, hasstructural
	real rowvector u
	real rowvector chg

	n = G.n
	haspresent = (args() >= 5)
	// CONTENT-based (not args()>=6) - matching SaomNetCtxInit()'s own
	// content-based hasnetgate convention, since a caller reaching
	// past fntype to supply `structural' must pass SOME fntype value in
	// this slot even when it doesn't genuinely want gating (Mata's own
	// optional-argument ordering rule) - an args()-count check would
	// wrongly read that filler as a real fntype request.
	hasfntype = (args() >= 6) & (cols(fntype) > 0) & any(fntype :!= 0)
	// Structural zeros/ones ("expansion", 2026-09-02 - RSiena's own
	// dyad-level frozen-tie mechanism, see this file's own "Structural
	// zeros/ones" header comment above SaomBuildStructuralMask() for the
	// full design account). CONTENT-based detection (rows(structural)>0),
	// NOT args()-count-based - this file's own established lesson
	// (content-based hasnetgate/hasratecov in SaomNetCtxInit()): an args()==7 check would break the moment any FURTHER
	// optional argument is added after this one, forcing every future
	// caller reaching past it to also look "structural-active" even when
	// passing an empty filler matrix.
	hasstructural = (rows(structural) > 0)
	u = J(1, n, 0)		// u[j] for j!=i; u[i] itself unused (self-toggle undefined)
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
		if (hasstructural) if (structural[i,j] == 1) continue
		chg = hasfntype ? SaomNetworkFullChangeGated(M, fntype, G, i, j) : M.full_change(G, i, j)
		u[j] = theta * chg'
	}

	// numerically stable softmax over {u[1..n excl. i, excl. absent, excl. structural], 0 for "stay"}
	maxu = 0	// "stay"'s own utility, always included as a candidate max
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
		if (hasstructural) if (structural[i,j] == 1) continue
		if (u[j] > maxu) maxu = u[j]
	}

	denom = exp(0 - maxu)	// "stay"'s own exp term
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
		if (hasstructural) if (structural[i,j] == 1) continue
		denom = denom + exp(u[j] - maxu)
	}

	draw = runiform(1,1) * denom
	cum = exp(0 - maxu)
	if (draw <= cum) {
		return(0)	// "stay" drawn - no toggle
	}
	choice = 0
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
		if (hasstructural) if (structural[i,j] == 1) continue
		cum = cum + exp(u[j] - maxu)
		choice = j	// last alternative enumerated so far - fallback if draw==denom exactly (floating-point edge case)
		if (draw <= cum) break
	}

	G.toggle(i, choice)
	return(choice)
}

/* ===================================================================
   SaomSimulateInterval: forward-simulate G from "start of period" to
   "end of period" under a constant, actor-homogeneous rate function.

   Continuous-time construction: with n actors each at constant rate
   `rate`, the pooled process is Poisson(n*rate) over the unit interval
   [0,1) - so successive waiting times are i.i.d. Exponential(n*rate),
   and conditional on an opportunity occurring, the acting actor is
   uniform over 1..n (no Poisson-count generator needed). See
   docs/SAOM_ARCHITECTURE.md's "The interval simulator" section.

   Mutates G in place. Returns the number of ministeps executed (used
   for rate re-estimation by the caller).

   `present' (harmonisation unit 33, composition change - same optional,
   backward-compatible convention as SaomMinistep()'s own identical
   parameter, see its own header comment for the full account): when
   supplied, restricts BOTH which actor gets to act (drawn uniformly
   from PRESENT actors only, not 1..n) AND the pooled rate (scaled by
   the PRESENT actor count, not G.n - real RSiena's own joiners/leavers
   construction: absent actors get no activation opportunities at all,
   so they cannot contribute to the pooled rate either), and is passed
   through to SaomMinistep() unchanged so an absent actor is also never
   offered as a tie-target alternative. Omitting `present' is IDENTICAL
   to every actor being present - a true no-op for every pre-existing
   call site.
   =================================================================== */
real scalar SaomSimulateInterval(class ErgmGraph scalar G, class ErgmModel scalar M,
	real rowvector theta, real scalar rate, | real colvector present) {

	real scalar t, steps, i, picked, haspresent, npresent
	real colvector presentIdx

	haspresent = (args() == 5)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = G.n

	t = 0
	steps = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / (npresent * rate)
		if (t < 1) {
			if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
			else i = ceil(runiform(1,1) * G.n)
			if (haspresent) picked = SaomMinistep(G, M, theta, i, present)
			else picked = SaomMinistep(G, M, theta, i)
			steps = steps + 1
		}
	}
	return(steps)
}

/* ===================================================================
   SaomSimulateConditionalTime: conditional simulation, as in RSiena's
   CONDITIONAL estimation (its default for a single dependent network):
   ministeps at reference rate 1 until the current DISTANCE from the
   starting network (dyads that differ from Gstart; a toggle that
   restores a starting value lowers it, as in RSiena's
   EpochSimulation::runEpoch()) reaches `targetChange'; returns the
   elapsed time. Averaged over replicates at given effects, the elapsed
   time estimates the rate that reproduces the target distance.

   The estimators do not call this (conditional estimation uses the
   conditional mode of the interval simulators, which also return the
   statistics and scores - see SaomEstimateNet()). It is kept, with its
   native counterpart
   SaomSimulateCondTimeNative() and the batch condmode=1 of
   SaomBatchRun(), as a simulation utility; cscripts/test_nwsaom_native.do
   checks the native version against it.
   =================================================================== */
real scalar SaomSimulateConditionalTime(class ErgmGraph scalar G, class ErgmGraph scalar Gstart,
	class ErgmModel scalar M, real rowvector theta, real scalar targetChange) {

	real scalar t, simDist, i, picked

	t = 0
	simDist = 0
	while (simDist < targetChange) {
		t = t - ln(runiform(1,1)) / G.n		// reference rate = 1 (verified, see this function's own header comment)
		i = ceil(runiform(1,1) * G.n)
		picked = SaomMinistep(G, M, theta, i)
		if (picked != 0) {
			// EpochSimulation::runEpoch()'s own stopping check compares
			// `simulatedDistance()' - CURRENT distance from the STARTING
			// network - against the target, NOT a monotonic count of
			// accepted toggles (a real, easy-to-miss subtlety: a toggle
			// that reverts a dyad back to its OWN starting value REDUCES
			// simulatedDistance, it does not count as "more progress" the
			// way a naive accepted-change counter would) - confirmed
			// directly from source, not assumed (see this function's own
			// header comment for the account, including the real,
			// disclosed numerical finding this correction was based on).
			if (G.has_edge(i, picked) == Gstart.has_edge(i, picked)) simDist = simDist - 1
			else simDist = simDist + 1
		}
	}
	return(t)
}

/* ===================================================================
   SaomScoredResult / SaomSimulateIntervalScored: a SEPARATE interval
   simulator for the Mata path of SaomEstimateNet()'s phases 1 and 3
   (Jacobian estimation) - see docs/SAOM_ARCHITECTURE.md's
   "Robbins-Monro estimation" section. Deliberately not a modification of SaomMinistep/
   SaomSimulateInterval above (those stay exactly as certified in
   harmonisation unit 1 and are still what phase 2/3 and the native
   backend use) - this is a parallel implementation that additionally
   accumulates the ministep-choice SCORE vector, the standard
   likelihood-ratio/score-function derivative-estimator identity real
   RSiena's own `derivativeFromScoresAndDeviations()` (rsiena/R/phase1.r)
   uses: for a multinomial-logit ministep with utilities u_j =
   theta.chg(i,j), d/dtheta E[chg] = chg(chosen) - E_p[chg] (the CHOSEN
   alternative's own change-statistic vector minus its softmax-
   probability-weighted average over every alternative, including
   "stay", whose own chg is the zero vector by definition). Summed over
   every ministep in the simulated interval, this gives d/dtheta of the
   interval's own expected final statistic - the Jacobian phases 1 and 3
   of SaomEstimateNet() need (Cov(deviation, score) across many
   independent replicates, matching RSiena's own construction exactly).
   =================================================================== */
struct SaomScoredResult {
	real scalar steps
	real scalar t			// elapsed time (conditional simulation: the time the target distance took)
	real scalar nchanges		// ACCEPTED ministeps only (excludes "stay"); the rate's statistic is the end-vs-start distance instead (SaomEstimateNet())
	real rowvector score
	real rowvector rcscore		// one entry per ratecov() variable (2026-10-01: several); harmonisation unit 172 - covariate-rate coefficient's own SCORE (a compensated-counting-process martingale score, NOT a moment statistic), ONLY populated by SaomSimIntScoredRateCov(); see that function's own header comment for the real-RSiena-verified formula this reproduces (DependentVariable.cpp's accumulateRateScores())
}

struct SaomScoredResult scalar SaomSimulateIntervalScored(class ErgmGraph scalar G,
	class ErgmModel scalar M, real rowvector theta, real scalar rate, | real colvector present,
	real rowvector fntype, real matrix structural, real scalar condtarget, real matrix distmask) {

	struct SaomScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg
	real scalar iscond, hasdm, simDist
	real matrix dflip
	real scalar t, n, p, i, j, k, maxu, denom, draw, cum, choice, haspresent, npresent, hasfntype, hasstructural
	real colvector presentIdx

	n = G.n
	p = M.nparam()
	res.score = J(1, p, 0)
	res.steps = 0
	res.nchanges = 0

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as SaomMinistep()/
	// SaomSimulateInterval()'s own identical parameter; see
	// SaomSimulateInterval()'s own header account. `structural'
	// ("expansion", 2026-09-02) - see SaomMinistep()'s own header
	// comment for the full design account; CONTENT-based detection
	// throughout (not args()==), matching this file's own hasnetgate/
	// hasratecov lesson.
	// conditional simulation (RSiena's conditional estimation, see
	// SaomEstimateNet()): run until the distance from the starting network
	// reaches `condtarget' (at least one step); `distmask' flags dyads not
	// counted (missing at either end of the period); condtarget missing or
	// < 0 = the ordinary unit interval
	iscond = 0
	if (args() >= 8) iscond = (condtarget < . & condtarget >= 0)
	hasdm = 0
	if (args() >= 9) hasdm = (rows(distmask) > 0)
	simDist = 0
	if (iscond) dflip = J(G.n, G.n, 0)
	haspresent = (args() >= 5)
	hasfntype = (args() >= 6) & (cols(fntype) > 0) & any(fntype :!= 0)
	hasstructural = (rows(structural) > 0)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = n

	t = 0
	while (iscond ? (res.steps == 0 | simDist < condtarget) : (t < 1)) {
		// RSiena's guard against a conditional period that cannot reach
		// the observed distance (see SaomCondTimeCheck())
		if (iscond & res.steps >= 1000000) {
			t = .
			break
		}
		t = t - ln(runiform(1,1)) / (npresent * rate)
		if (iscond | t < 1) {
			if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
			else i = ceil(runiform(1,1) * n)

			chgmat = J(n, p, 0)
			u = J(1, n, 0)
			maxu = 0
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				if (hasstructural) if (structural[i,j] == 1) continue
				chgmat[j,.] = hasfntype ? SaomNetworkFullChangeGated(M, fntype, G, i, j) : M.full_change(G, i, j)
				u[j] = theta * chgmat[j,.]'
				if (u[j] > maxu) maxu = u[j]
			}

			denom = exp(0 - maxu)
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				if (hasstructural) if (structural[i,j] == 1) continue
				denom = denom + exp(u[j] - maxu)
			}

			ebar = J(1, p, 0)
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				if (hasstructural) if (structural[i,j] == 1) continue
				ebar = ebar + (exp(u[j]-maxu)/denom) * chgmat[j,.]
			}

			draw = runiform(1,1) * denom
			cum = exp(0 - maxu)
			choice = 0
			chosen_chg = J(1, p, 0)
			if (draw > cum) {
				for (j=1; j<=n; j++) {
					if (j == i) continue
					if (haspresent) if (present[j] == 0) continue
					if (hasstructural) if (structural[i,j] == 1) continue
					cum = cum + exp(u[j] - maxu)
					choice = j
					if (draw <= cum) break
				}
				chosen_chg = chgmat[choice, .]
			}

			res.score = res.score + (chosen_chg - ebar)
			if (choice != 0) {
				G.toggle(i, choice)
				res.nchanges = res.nchanges + 1
				if (iscond) {
					if (hasdm) {
						if (distmask[i, choice] == 0) {
							dflip[i, choice] = 1 - dflip[i, choice]
							simDist = simDist + (dflip[i, choice] ? 1 : -1)
						}
					}
					else {
						dflip[i, choice] = 1 - dflip[i, choice]
						simDist = simDist + (dflip[i, choice] ? 1 : -1)
					}
				}
			}
			res.steps = res.steps + 1
		}
	}
	res.t = t
	return(res)
}

/* ===================================================================
   SaomCountedResult / SaomSimulateIntervalCounted: like
   SaomSimulateInterval() (same ministep loop, via SaomMinistep() -
   unmodified, still the certified unit-1 sampler) but ALSO tracks
   `nchanges` (accepted ministeps only) alongside `steps` (all
   opportunities; SaomEstimateNet()'s rate score is steps/rate - active
   actors). Kept separate
   from SaomSimulateInterval() itself (not a signature change) since
   that function's plain "returns steps" contract is relied on elsewhere
   (units 1-5 tests, direct callers) and changing it would be a needless
   breaking change for callers that only ever wanted the step count.
   =================================================================== */
struct SaomCountedResult {
	real scalar steps
	real scalar t			// elapsed time (conditional simulation: the time the target distance took)
	real scalar nchanges
	real rowvector stat		// harmonisation unit 14 - ONLY populated by SaomSimulateIntervalNative(); SaomSimulateIntervalCounted() (the Mata path) leaves it empty, since callers on that path already call M.full_statistic() themselves as before
	real rowvector score		// harmonisation unit 16 - ONLY populated by SaomSimulateIntervalNative() when called with want_score=1 (phase 1's own native path); empty otherwise
	real scalar netdist		// SaomSimulateIntervalNative() only: dyads in which the final network differs from the start (missing dyads excluded)
	real rowvector rcscore		// one entry per ratecov() variable; ratecov (native-first) - the covariate-rate coefficient's own martingale score, ONLY populated by SaomSimulateIntervalNative() when called with a genuine ratecov (hasratecov) request AND want_score=1; matches SaomScoredResult's own identical-purpose field (SaomSimIntScoredRateCov(), the Mata reference this native path reproduces)
}

struct SaomCountedResult scalar SaomSimulateIntervalCounted(class ErgmGraph scalar G,
	class ErgmModel scalar M, real rowvector theta, real scalar rate, | real colvector present,
	real rowvector fntype, real matrix structural, real scalar condtarget, real matrix distmask) {

	struct SaomCountedResult scalar res
	real scalar iscond, hasdm, simDist
	real matrix dflip
	real scalar t, i, picked, haspresent, npresent, hasfntype, hasstructural
	real colvector presentIdx

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as SaomSimulateInterval()'s own
	// identical parameter; see its own header comment for the full
	// account. harmonisation unit 167: `fntype' (network endow/creation
	// gating) is a further optional trailing argument, same chained
	// convention - reaching it requires `present' to also be supplied
	// (Mata's own optional-argument ordering rule), matching this
	// file's own established "a fntype-only caller passes an
	// all-present placeholder" precedent (see SaomEstimateRM()'s own
	// header comment on placeholders). `structural'
	// ("expansion", 2026-09-02) is a further trailing argument, same
	// chained convention - see SaomMinistep()'s own header comment for
	// the full design account; CONTENT-based detection (not args()==),
	// matching this file's own hasnetgate/hasratecov lesson.
	// conditional simulation (RSiena's conditional estimation, see
	// SaomEstimateNet()): run until the distance from the starting network
	// reaches `condtarget' (at least one step); `distmask' flags dyads not
	// counted (missing at either end of the period); condtarget missing or
	// < 0 = the ordinary unit interval
	iscond = 0
	if (args() >= 8) iscond = (condtarget < . & condtarget >= 0)
	hasdm = 0
	if (args() >= 9) hasdm = (rows(distmask) > 0)
	simDist = 0
	if (iscond) dflip = J(G.n, G.n, 0)
	haspresent = (args() >= 5)
	hasfntype = (args() >= 6) & (cols(fntype) > 0) & any(fntype :!= 0)
	hasstructural = (rows(structural) > 0)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = G.n

	res.steps = 0
	res.nchanges = 0
	t = 0
	while (iscond ? (res.steps == 0 | simDist < condtarget) : (t < 1)) {
		// RSiena's guard against a conditional period that cannot reach
		// the observed distance (see SaomCondTimeCheck())
		if (iscond & res.steps >= 1000000) {
			t = .
			break
		}
		t = t - ln(runiform(1,1)) / (npresent * rate)
		if (iscond | t < 1) {
			if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
			else i = ceil(runiform(1,1) * G.n)
			if (hasstructural) picked = SaomMinistep(G, M, theta, i, (haspresent ? present : J(G.n,1,1)), (hasfntype ? fntype : J(1,0,0)), structural)
			else if (hasfntype) picked = SaomMinistep(G, M, theta, i, present, fntype)
			else if (haspresent) picked = SaomMinistep(G, M, theta, i, present)
			else picked = SaomMinistep(G, M, theta, i)
			if (picked != 0) {
				res.nchanges = res.nchanges + 1
				if (iscond) {
					if (hasdm) {
						if (distmask[i, picked] == 0) {
							dflip[i, picked] = 1 - dflip[i, picked]
							simDist = simDist + (dflip[i, picked] ? 1 : -1)
						}
					}
					else {
						dflip[i, picked] = 1 - dflip[i, picked]
						simDist = simDist + (dflip[i, picked] ? 1 : -1)
					}
				}
			}
			res.steps = res.steps + 1
		}
	}
	res.t = t
	return(res)
}

/* ===================================================================
   Covariate-dependent rate ("ratecov()", nwsaom's port of RSiena's own
   covariate-dependent rate effect - real name/mechanism verified
   directly from RSiena 1.6.6's C++ source, not guessed: `
   DependentVariable::updateCovariateRates()` sets
   `lcovariateRates[i] = exp(sum_k beta_k * x_k(i))`, and
   `calculateRates()` sets actor i's own total opportunity rate to
   `lcovariateRates[i] * structuralRate(i)` - i.e. `rate_i = rate0 *
   exp(beta*x_i)`, a log-linear multiplicative rate covariate. In real
   RSiena's own Method-of-Moments estimator this coefficient IS jointly
   Robbins-Monro-estimated (its own real target statistic, verified
   from `StatisticCalculator.cpp`: sum over dyads that differ between
   the two waves of the ACTING actor's own covariate value).
   SaomEstimateNet() estimates beta jointly with the effects and the
   rate, with that statistic and the compensated counting-process score
   (rcscore) computed below.

   Deliberately separate functions (not new optional trailing args on
   SaomSimulateIntervalCounted/Scored above) - mirrors this file's own
   SaomNetworkFullChangeGated() precedent (a parallel wrapper, not a
   change to shared machinery) so every existing call site and every
   already-certified model is providably unaffected when ratecov isn't
   requested. `ratecovattr` weights are computed ONCE (exp() is not
   free) since they don't change across ministeps within one simulated
   interval (composition change subsets the SAME fixed weight vector
   by whichever actors are currently present, it does not change any
   actor's own underlying rate).
   =================================================================== */
struct SaomCountedResult scalar SaomSimIntCountedRateCov(class ErgmGraph scalar G,
	class ErgmModel scalar M, real rowvector theta, real scalar rate,
	real matrix ratecovattr, real rowvector ratecoef, | real colvector present,
	real rowvector fntype, real scalar condtarget, real matrix distmask) {

	struct SaomCountedResult scalar res
	real scalar iscond, hasdm, simDist
	real matrix dflip
	real scalar t, i, k, picked, haspresent, npresent, hasfntype, totw, draw, cum
	real colvector presentIdx
	real rowvector wfull, w

	// conditional simulation (RSiena's conditional estimation, see
	// SaomEstimateNet()): run until the distance from the starting network
	// reaches `condtarget' (at least one step); `distmask' flags dyads not
	// counted (missing at either end of the period); condtarget missing or
	// < 0 = the ordinary unit interval
	iscond = 0
	if (args() >= 9) iscond = (condtarget < . & condtarget >= 0)
	hasdm = 0
	if (args() >= 10) hasdm = (rows(distmask) > 0)
	simDist = 0
	if (iscond) dflip = J(G.n, G.n, 0)
	haspresent = (args() >= 7)
	hasfntype = 0
	if (args() >= 8) hasfntype = (cols(fntype) > 0) & any(fntype :!= 0)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = G.n

	// several ratecov() variables: w_i = exp(sum_k ratecoef_k x_ik)
	wfull = exp(ratecovattr * ratecoef')'

	res.steps = 0
	res.nchanges = 0
	t = 0
	while (iscond ? (res.steps == 0 | simDist < condtarget) : (t < 1)) {
		// RSiena's guard against a conditional period that cannot reach
		// the observed distance (see SaomCondTimeCheck())
		if (iscond & res.steps >= 1000000) {
			t = .
			break
		}
		w = haspresent ? wfull[presentIdx] : wfull
		totw = sum(w)
		t = t - ln(runiform(1,1)) / totw / rate
		if (iscond | t < 1) {
			draw = runiform(1,1) * totw
			cum = 0
			k = npresent
			for (i=1; i<=length(w); i++) {
				cum = cum + w[i]
				if (draw <= cum) {
					k = i
					break
				}
			}
			i = haspresent ? presentIdx[k] : k
			if (hasfntype) picked = SaomMinistep(G, M, theta, i, present, fntype)
			else if (haspresent) picked = SaomMinistep(G, M, theta, i, present)
			else picked = SaomMinistep(G, M, theta, i)
			if (picked != 0) {
				res.nchanges = res.nchanges + 1
				if (iscond) {
					if (hasdm) {
						if (distmask[i, picked] == 0) {
							dflip[i, picked] = 1 - dflip[i, picked]
							simDist = simDist + (dflip[i, picked] ? 1 : -1)
						}
					}
					else {
						dflip[i, picked] = 1 - dflip[i, picked]
						simDist = simDist + (dflip[i, picked] ? 1 : -1)
					}
				}
			}
			res.steps = res.steps + 1
		}
	}
	res.t = t
	return(res)
}

struct SaomScoredResult scalar SaomSimIntScoredRateCov(class ErgmGraph scalar G,
	class ErgmModel scalar M, real rowvector theta, real scalar rate,
	real matrix ratecovattr, real rowvector ratecoef, | real colvector present,
	real rowvector fntype, real scalar condtarget, real matrix distmask) {

	struct SaomScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg, wfull, w
	real scalar iscond, hasdm, simDist
	real matrix dflip
	real scalar t, n, p, i, k, j, maxu, denom, draw, cum, choice, haspresent, npresent, hasfntype, totw, tau
	real rowvector covrateSum
	real colvector presentIdx

	n = G.n
	p = M.nparam()
	res.score = J(1, p, 0)
	res.steps = 0
	res.nchanges = 0
	res.rcscore = J(1, cols(ratecovattr), 0)

	// conditional simulation (RSiena's conditional estimation, see
	// SaomEstimateNet()): run until the distance from the starting network
	// reaches `condtarget' (at least one step); `distmask' flags dyads not
	// counted (missing at either end of the period); condtarget missing or
	// < 0 = the ordinary unit interval
	iscond = 0
	if (args() >= 9) iscond = (condtarget < . & condtarget >= 0)
	hasdm = 0
	if (args() >= 10) hasdm = (rows(distmask) > 0)
	simDist = 0
	if (iscond) dflip = J(G.n, G.n, 0)
	haspresent = (args() >= 7)
	hasfntype = 0
	if (args() >= 8) hasfntype = (cols(fntype) > 0) & any(fntype :!= 0)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = n

	// several ratecov() variables: w_i = exp(sum_k ratecoef_k x_ik)
	wfull = exp(ratecovattr * ratecoef')'
	// harmonisation unit 172: sum_i ratecovattr[i]*wfull[i] over ALL n
	// actors (never the present-restricted subset - ratecov()'s own v1
	// scope never combines with composition change, see nwsaom.ado's own
	// rejection of that combination), matching RSiena's real
	// calculateScoreSumTerms() exactly ("for (i=0;i<n();i++) timesRate +=
	// covariate->value(i)*lrate[i]" - always the FULL actor set, not
	// whichever subset happened to be eligible for the ministep just
	// selected).
	// real bug, found and fixed via direct evidence (not inspection): a
	// proper compensated-counting-process score must have mean exactly 0
	// under simulation at ANY parameter value (a martingale property,
	// not merely "at the truth") - a direct K0-replicate probe found
	// mean(score) nonzero by ~100 of its own standard errors, decisively
	// ruling out ordinary Monte Carlo noise. Root cause: `lrate[i]' in
	// RSiena's own real source is the actor's FULL combined rate
	// (basicRate * covariateRate[i] * ...), but `wfull[i]' here is the
	// covariate contribution ALONE (this function's own overall `rate'
	// argument is applied separately, only inside the waiting-time draw
	// below) - omitting that same `rate' factor here under-scaled the
	// compensator relative to the jump term, which fires at the TRUE
	// combined rate `rate*wfull[i]'. Fixed by including it explicitly.
	covrateSum = rate * (wfull * ratecovattr)

	t = 0
	while (iscond ? (res.steps == 0 | simDist < condtarget) : (t < 1)) {
		// RSiena's guard against a conditional period that cannot reach
		// the observed distance (see SaomCondTimeCheck())
		if (iscond & res.steps >= 1000000) {
			t = .
			break
		}
		w = haspresent ? wfull[presentIdx] : wfull
		totw = sum(w)
		tau = - ln(runiform(1,1)) / totw / rate
		t = t + tau
		if (iscond | t < 1) {
			// harmonisation unit 172: the REAL covariate-rate score,
			// verified directly from RSiena's own C++ source
			// (DependentVariable.cpp's accumulateRateScores(): a
			// compensated-counting-process martingale score, not a
			// moment/target-comparable statistic - "+covariate[selected
			// actor]" at each jump (this ministep OPPORTUNITY, whether or
			// not it ends in an accepted change - real RSiena's own
			// jump/compensator pair increments on every SELECTED actor,
			// gated only by realizing tau<1, matching this function's own
			// existing `if (t<1)' gate), "-tau*sum(covariate*rate)"
			// continuously between jumps (`calculateScoreSumTerms()"'s
			// own `lconstantCovariateSumTerm', verified as `sum_i
			// covariate[i]*lrate[i]' from its own real source). This is
			// what makes Cov(deviation, this score) a CORRECTLY-SIGNED
			// Jacobian for ratecoef (the earlier Var()-based proxy this unit
			// tried first was a genuine, disclosed design error - it can
			// never represent a negative true derivative, which direct
			// recovery testing found this exact problem can have).
			// Compensator term first (does not depend on which actor i
			// ends up being drawn) - the jump term is added right after i
			// is determined, a few lines below.
			res.rcscore = res.rcscore - tau * covrateSum
			draw = runiform(1,1) * totw
			cum = 0
			k = npresent
			for (i=1; i<=length(w); i++) {
				cum = cum + w[i]
				if (draw <= cum) {
					k = i
					break
				}
			}
			i = haspresent ? presentIdx[k] : k
			res.rcscore = res.rcscore + ratecovattr[i,.]	// harmonisation unit 172 - the jump term, see this function's own header comment above

			chgmat = J(n, p, 0)
			u = J(1, n, 0)
			maxu = 0
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				chgmat[j,.] = hasfntype ? SaomNetworkFullChangeGated(M, fntype, G, i, j) : M.full_change(G, i, j)
				u[j] = theta * chgmat[j,.]'
				if (u[j] > maxu) maxu = u[j]
			}

			denom = exp(0 - maxu)
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				denom = denom + exp(u[j] - maxu)
			}

			ebar = J(1, p, 0)
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				ebar = ebar + (exp(u[j]-maxu)/denom) * chgmat[j,.]
			}

			draw = runiform(1,1) * denom
			cum = exp(0 - maxu)
			choice = 0
			chosen_chg = J(1, p, 0)
			if (draw > cum) {
				for (j=1; j<=n; j++) {
					if (j == i) continue
					if (haspresent) if (present[j] == 0) continue
					cum = cum + exp(u[j] - maxu)
					choice = j
					if (draw <= cum) break
				}
				chosen_chg = chgmat[choice, .]
			}

			res.score = res.score + (chosen_chg - ebar)
			if (choice != 0) {
				G.toggle(i, choice)
				res.nchanges = res.nchanges + 1
				if (iscond) {
					if (hasdm) {
						if (distmask[i, choice] == 0) {
							dflip[i, choice] = 1 - dflip[i, choice]
							simDist = simDist + (dflip[i, choice] ? 1 : -1)
						}
					}
					else {
						dflip[i, choice] = 1 - dflip[i, choice]
						simDist = simDist + (dflip[i, choice] ? 1 : -1)
					}
				}
			}
			res.steps = res.steps + 1
		}
	}
	res.t = t
	return(res)
}

/* ===================================================================
   SAOM-native effect library: unlike unit 1's effects (outdegree,
   reciprocity, nodematch - and unit 2's nodecov/nodeicov/nodeocov,
   registered directly from nwsaom.ado using nwergm's own stat_nodecov/
   change_nodecov etc.), these two effects are NOT reused from
   unw_ergm.do - see docs/SAOM_ARCHITECTURE.md's "The reuse is not a
   shortcut" section for why the reuse argument only holds for effects
   whose global ERGM statistic is a simple sum of single-actor-local
   contributions. Popularity/activity effects fail that test (a toggle
   on (i,j) changes ANOTHER actor h's own popularity statistic too,
   whenever h also ties to j), so they need their own fresh
   change-statistic derivation - done here, from the published SAOM
   effect definitions (Snijders et al.), not ported.

   IMPORTANT ASYMMETRY (expected, not a bug): change_saom_X(G,i,j,td)
   below returns actor i's own LOCAL objective-function delta (what
   SaomMinistep needs) - it is NOT required to equal, and for these two
   effects genuinely does NOT equal, stat_saom_X(G_after) -
   stat_saom_X(G_before) (the GLOBAL network statistic's own delta),
   because toggling (i,j) can change OTHER actors' own local
   contributions too (every other actor h with an existing tie to j
   sees ITS OWN popularity statistic change when j's indegree changes).
   This is fine: change() is only ever used for the ACTING actor's own
   ministep choice; stat() is only ever evaluated directly (never
   incrementally accumulated via change()) at the end of a simulated
   interval, via the estimators' calls to M.full_statistic(). Contrast
   with unit 1/2's effects, where this asymmetry happens not to arise
   (see their own header comments) - do not assume every future SAOM
   effect shares that property.
   =================================================================== */

/*
   Indegree popularity (Snijders' default sqrt-transformed "popularity"
   effect - the square root avoids the degeneracy plain linear
   popularity is prone to). Global statistic: S(x) = sum_j
   indegree(j)^1.5 (each of j's indegree(j) incoming arcs contributes
   sqrt(indegree(j)) once). Actor i's own local contribution: s_i(x) =
   sum_{j: x_ij=1} sqrt(indegree(j)).

   Derivation of the ministep delta (actor i toggling tie i->j; d =
   indegree(j) BEFORE this toggle):
     - creating i->j (previously absent): j newly enters i's own sum,
       contributing sqrt(d+1) (j's indegree after the toggle, which
       this very toggle raises by 1) - so delta = sqrt(d+1).
     - deleting i->j (previously present): j leaves i's own sum, whose
       prior contribution was sqrt(d) (d already includes the tie
       being removed) - so delta = -sqrt(d).
   Directed-graph indegree only (G.din) - undirected v1 out of scope,
   matching unit 1's own reciprocity/nodematch (both meaningful only on
   a directed relation, per docs/SAOM_ROADMAP.md's v1 scope).
*/
real rowvector stat_saom_indegpop(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar j, tot

	tot = 0
	for (j=1; j<=G.n; j++) tot = tot + G.din[j]^1.5
	return(tot)
}
real rowvector change_saom_indegpop(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d

	d = G.din[j]
	return(G.has_edge(i,j) ? -sqrt(d) : sqrt(d+1))
}

/*
   Outdegree activity (squared own out-degree - actors already sending
   many ties are differentially more/less likely to send further ones).
   Global statistic: S(x) = sum_i outdegree(i)^2. Actor i's own local
   contribution is this same term read as i's OWN statistic: s_i(x) =
   x_i+^2.

   Derivation of the ministep delta (actor i toggling tie i->j; d =
   i's OWN out-degree BEFORE this toggle):
     - creating i->j: d' = d+1, delta = (d+1)^2 - d^2 = 2d+1.
     - deleting i->j: d' = d-1, delta = (d-1)^2 - d^2 = -(2d-1).
   Unlike indegree popularity above, this effect genuinely IS a
   single-actor-local quantity in the SAME sense unit 1's effects are
   (toggling i's own tie only ever changes i's OWN out-degree, never
   another actor's) - so here, unusually for a non-reused effect,
   change() DOES equal the global stat's own delta too. Kept as a
   freshly-derived function anyway (not reused from unw_ergm.do) since
   no ERGM term computes this squared-degree form.
*/
real rowvector stat_saom_outactivity(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + G.dout[i]^2
	return(tot)
}
real rowvector change_saom_outactivity(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d

	d = G.degree_out(i)
	return(G.has_edge(i,j) ? -(2*d - 1) : (2*d + 1))
}

/*
   isolateNet (harmonisation unit 34 - RSiena's own "network-isolate",
   from the effect-catalog priority list's own "isolate-related
   effects" entry): counts TRUE isolates - actors with BOTH indegree
   AND outdegree exactly 0. Global statistic: S(x) = #{i : indegree(i)=0
   AND outdegree(i)=0}.

   Derivation of the ministep delta (actor i toggling arc i->j),
   verified directly against RSiena's real IsolateNetEffect.cpp source,
   not assumed: that file's own calculateContribution() returns a raw
   value under an "as if CREATING" convention that RSiena's simulation
   engine (NetworkVariable.cpp's own calculateTieFlipContributions(),
   read directly too, not guessed) then NEGATES whenever the toggle is
   actually a WITHDRAWAL (outTieExists(alter) true) - reconciling that
   raw source with this codebase's own "signed delta already reflects
   current state" change() convention (see change_edges()'s own
   identical pattern in unw_ergm.do) confirms the simplification below.

   IMPORTANT ASYMMETRY (expected, not a bug - the SAME kind this
   section's own header comment already warns indegpopularity/
   outactivity have, discovered here the hard way via a FAILED global-
   recompute certification attempt before being corrected to the right
   test, not assumed correct on the first try): unlike outIso below,
   change_saom_isolatenet() returns ONLY actor i's OWN local ministep
   contribution (exactly what RSiena's own calculateContribution() is -
   an ego's own choice-relevant delta, never a global-statistic delta),
   which genuinely does NOT equal the GLOBAL isolate count's own
   before/after difference: creating i->j also raises j's OWN indegree,
   which can independently flip j's OWN isolate status too (if j was
   itself isolated, gaining an incoming tie un-isolates j) - a SECOND
   actor's own local contribution changing from the SAME toggle, exactly
   the multi-actor spillover indegpopularity/outactivity already have.
   change_saom_isolatenet()'s own delta below is i's own local piece
   only; RSiena's own real ministep sum still gets every OTHER affected
   actor's own contribution correctly, because each actor's own
   contribution is evaluated separately when THAT actor is later
   activated - this function is never called to represent j's own share
   of a toggle i itself did not initiate.

   i's OWN isolate status requires indegree(i)==0 (never affected by
   i's own outgoing-tie choices):
     - if indegree(i) != 0: i can never be an isolate either way -
       delta = 0 always, regardless of the toggle.
     - else (indegree(i)==0): currently an isolate iff outdegree(i)==0.
       - creating i->j (i currently NOT tied to j): new outdegree >= 1,
         never an isolate afterward.
       - deleting i->j (i currently tied to j, so outdegree(i)>=1,
         i.e. NOT currently an isolate): new outdegree =
         outdegree(i)-1; becomes an isolate afterward iff
         outdegree(i)==1 before the toggle.
*/
real rowvector stat_saom_isolatenet(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + (G.din[i]==0 & G.dout[i]==0)
	return(tot)
}
real rowvector change_saom_isolatenet(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar cur_isolate, new_isolate

	if (G.din[i] != 0) return(0)
	cur_isolate = (G.dout[i] == 0)
	if (G.has_edge(i,j)) new_isolate = (G.dout[i] - 1 == 0)
	else new_isolate = 0
	return(new_isolate - cur_isolate)
}

/*
   outIso (harmonisation unit 34 - RSiena's own "out-isolate"): counts
   actors with outdegree exactly 0, regardless of indegree - a WEAKER
   condition than isolateNet's own true-isolate definition above (which
   additionally requires indegree=0 too). Global statistic:
   S(x) = #{i : outdegree(i)=0}.

   Derivation of the ministep delta, verified directly against RSiena's
   real TruncatedOutdegreeEffect.cpp source - EffectFactory.cpp's own
   dispatch table confirms "outIso" maps to that class with
   (right=true, outIso=true, lc=1), not a separate dedicated class -
   same "as-if-creating, framework-negates on withdrawal" convention as
   isolateNet above, reconciled the identical way, case by case against
   the raw source (not assumed by analogy alone). Unlike isolateNet
   above, this effect genuinely IS single-actor-local (no asymmetry,
   confirmed by a passing GLOBAL-recompute certification, not just
   assumed by analogy): toggling i's own outgoing tie changes i's own
   outdegree only - it changes j's own INdegree, which this
   outdegree-only condition never reads - so no OTHER actor's own
   isolate-by-this-definition status can ever be touched by i's own
   ministep. Only i's own outdegree is relevant here (no indegree gate
   at all, unlike isolateNet):
     - creating i->j (i currently NOT tied to j): new outdegree =
       outdegree(i)+1 >= 1, never an isolate afterward.
     - deleting i->j (i currently tied to j, so outdegree(i)>=1, i.e.
       NOT currently an isolate): new outdegree = outdegree(i)-1;
       becomes an isolate afterward iff outdegree(i)==1 before the
       toggle.
*/
real rowvector stat_saom_outiso(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + (G.dout[i]==0)
	return(tot)
}
real rowvector change_saom_outiso(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar cur_isolate, new_isolate

	cur_isolate = (G.dout[i] == 0)
	if (G.has_edge(i,j)) new_isolate = (G.dout[i] - 1 == 0)
	else new_isolate = 0
	return(new_isolate - cur_isolate)
}

/*
   antiIso/antiInIso/antiInIso2/isolatePop (harmonisation unit 36 - the
   alter-indexed isolate family deferred when isolateNet/outIso were
   built, per docs/SAOM_ROADMAP.md's own "correctly scoped OUT, not
   attempted" note). Verified directly against RSiena 1.6.6's own real
   C++ source (fetched fresh from CRAN, not from memory or the general
   SAOM literature - this file's own established discipline):
   EffectFactory.cpp's dispatch confirms
     antiIso     -> AntiIsolateEffect(outAlso=true,  minDegree=1)
     antiInIso   -> AntiIsolateEffect(outAlso=false, minDegree=1)
     antiInIso2  -> AntiIsolateEffect(outAlso=false, minDegree=2)
     isolatePop  -> IsolatePopEffect(outgoing=true)
   (in3Plus, AntiIsolateEffect(false,3), is a fifth sibling RSiena
   exposes but this unit's own scope - matching the roadmap's own
   named list - does not include; add it later the same mechanical way
   if ever wanted, using the minDegree>=2 branch below with 3 in place
   of 2).

   UNLIKE isolateNet, these four are ALTER-indexed, not ego-indexed:
   AntiIsolateEffect.cpp's own calculateContribution(alter) reads
   ONLY alter's indegree/outdegree, never ego's own degree at all -
   this codebase already has a precedent for that exact shape
   (change_saom_indegpop() above, which reads G.din[j] not G.din[i]),
   so no new architecture is needed, contrary to what this family's
   "structurally different" framing in the roadmap might suggest at
   first glance - the real complication instead turned out to be
   getting each of the two DISTINCT branches of RSiena's own
   calculateContribution() exactly right (see below), not the
   alter-vs-ego indexing itself.

   A REAL first-attempt certification failure here too (this file's
   own established "test before trusting" discipline, after
   isolateNet's own identical experience): reasoning alone suggested
   these four condition ONLY on alter j's degree, so toggling i->j
   should only ever flip j's OWN indicator, giving outIso's own
   "no spillover, matches the raw global before/after difference
   exactly" property - this reasoning is INCOMPLETE and was caught
   empirically, not assumed correct. It holds exactly for
   antiInIso/antiInIso2 (their condition reads ONLY alter's indegree,
   confirmed spillover-free by a 3000-toggle global-recompute check,
   maxerr=0). It does NOT hold for antiIso/isolatePop, because both
   ALSO gate on alter's own OUTdegree - and creating/removing i->j
   changes i's OWN outdegree too. If i itself independently satisfies
   (or stops satisfying) the same indegree+outdegree condition as a
   result, i's OWN membership in the global count flips as a pure
   side effect of i's own choice, a genuine second actor's own status
   changing from the SAME toggle - exactly isolateNet's own multi-
   actor-spillover shape, confirmed by a real, reproducible mismatch
   (first found at a global-recompute maxerr of 1.0 over 3000 random
   toggles, root-caused to exactly this outdegree side effect, not a
   formula error - change_saom_antiiso()/change_saom_isolatepop()
   themselves are correct, verified below against the RIGHT target
   once identified). Each of the four is therefore certified against
   whichever of this codebase's own three EXISTING certification
   shapes actually matches its own statistic's structure (not
   assumed to be interchangeable, and not a fourth new pattern):
     antiInIso/antiInIso2: outIso's own "no spillover, exact global
       before/after match" shape (maxerr=0, both a 15- and 30-node
       network, 3000 toggles each).
     antiIso: isolateNet's own "genuine spillover, ego's local piece
       only" shape - change_saom_antiiso() exactly predicts ALTER j's
       own before/after membership delta (indicator(din[j]>=1 &
       dout[j]<=0)), maxerr=0 across 3000 toggles - but NOT the full
       global sum's own delta, by the same design as isolateNet.
     isolatePop: indegpop's own "ego = sum over ego's own current
       ties of a per-alter value" shape - change_saom_isolatepop()
       exactly predicts EGO i's own local sum (sum over i's current
       out-neighbors k of indicator(din[k]==1 & dout[k]==0)) before/
       after delta, maxerr=0 across 3000 toggles (mirroring
       saom_ego_indegpop()'s own certification style exactly) - NOT
       alter j's own single-node membership the way antiIso needs
       (confirmed these are genuinely different targets: testing
       isolatePop's change function against antiIso's own alter-
       membership target fails, at exactly the boundary case where
       the two effects' underlying statistics diverge - see the
       stat_saom_isolatepop() vs stat_saom_antiiso() distinction
       below).

   RSiena's own calculateContribution(alter) for AntiIsolateEffect has
   TWO branches depending on minDegree, reproduced literally below
   rather than "cleaned up" into one formula - the two are NOT
   algebraically the same shape even at minDegree=1 (the tied branch
   for minDegree<=1 is `degree<=1`, not `degree==minDegree`; verified
   by literal reading of AntiIsolateEffect.cpp's own source comment
   "The following could be combined in one statement but this would
   require more comparisons" - confirming the split is deliberate, not
   an oversight to be simplified away):
     minDegree<=1 (antiIso, antiInIso): raw = (degree<=0) if not tied,
       (degree<=1) if tied [degree<=0 is impossible while tied, since
       i itself is one of j's in-neighbors then, so this reduces to
       degree==1 in practice but is written as RSiena's own `<=1` for
       a literal port]; antiIso ALSO requires alter's own outdegree=0.
     minDegree=2 (antiInIso2): raw = (degree==1) if not tied,
       (degree==2) if tied - genuinely the OTHER shape, not a
       parametrized generalization of the minDegree<=1 case.
   Every RSiena NetworkVariable evaluation-effect contribution is then
   sign-flipped by the simulation engine on a withdrawal
   (NetworkVariable.cpp's own calculateTieFlipContributions(), read
   directly - confirmed to apply uniformly to every effect, not
   something isolateNet/outIso's own header comment discovered as a
   special case of those two effects specifically) - already folded
   into the tied ? -1 : 1 below, matching every change_saom_X()
   function's own "already-signed, ready-to-return" convention.

   isolatePop's own change function is DERIVED separately (from
   IsolatePopEffect.cpp's own calculateContribution, outgoing=true
   branch) but turns out to be ALGEBRAICALLY IDENTICAL to antiIso's -
   confirmed by direct comparison of both derivations, not assumed
   from the similar names. Their GLOBAL statistics genuinely differ,
   though (stat_saom_X below): antiIso counts nodes with indegree>=1
   AND outdegree=0 (any positive indegree), while isolatePop's own
   egoStatistic is left at NetworkEffect's DEFAULT ("sum over ego's
   own current ties of tieStatistic(alter)", the SAME shape
   indegpop/outactivity already use - AntiIsolateEffect, by contrast,
   OVERRIDES egoStatistic() entirely with its own all-nodes sum,
   exactly because - per its own source comment - "it also applies to
   two-mode networks [so] it cannot be represented as a sum over ego"),
   which reduces algebraically (grouping the tie-sum by alter, since
   indegree(j) many ties share the same tieStatistic(j) term and the
   indicator only fires when indegree(j)==1 exactly, making that
   count-times-indicator collapse to a plain 0/1) to: the count of
   nodes with indegree EXACTLY 1 and outdegree 0 - a strictly narrower
   condition than antiIso's own indegree>=1, not the same statistic
   despite the identical per-toggle change formula.
*/
real rowvector stat_saom_antiiso(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + (G.din[i]>=1 & G.dout[i]<=0)
	return(tot)
}
real rowvector change_saom_antiiso(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d, tied, cond

	d = G.din[j]
	tied = G.has_edge(i,j)
	cond = tied ? (d<=1) : (d==0)
	if (cond & G.dout[j]<=0) return(tied ? -1 : 1)
	return(0)
}

real rowvector stat_saom_antiiniso(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + (G.din[i]>=1)
	return(tot)
}
real rowvector change_saom_antiiniso(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d, tied, cond

	d = G.din[j]
	tied = G.has_edge(i,j)
	cond = tied ? (d<=1) : (d==0)
	return(cond ? (tied ? -1 : 1) : 0)
}

real rowvector stat_saom_antiiniso2(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + (G.din[i]>=2)
	return(tot)
}
real rowvector change_saom_antiiniso2(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d, tied, cond

	d = G.din[j]
	tied = G.has_edge(i,j)
	cond = tied ? (d==2) : (d==1)
	return(cond ? (tied ? -1 : 1) : 0)
}

real rowvector stat_saom_isolatepop(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar j, tot

	tot = 0
	for (j=1; j<=G.n; j++) tot = tot + (G.din[j]==1 & G.dout[j]==0)
	return(tot)
}
real rowvector change_saom_isolatepop(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d, tied, cond

	d = G.din[j]
	tied = G.has_edge(i,j)
	cond = (G.dout[j]==0) & (tied ? (d<=1) : (d==0))
	return(cond ? (tied ? -1 : 1) : 0)
}

/* ===================================================================
   Harmonisation unit 37: three effects from RSiena's own real,
   current effect catalog (`getEffects()`'s "eval" rows for a network
   dependent variable, RSiena 1.6.6 - confirmed via direct inspection,
   not guessed from the SAOM literature), picked as a small, genuinely
   commonly-used batch rather than attempting the full 70+-effect
   remaining catalog in one pass (docs/SAOM_ROADMAP.md's own framing).
   All three verified against the REAL RSiena C++ source
   (github.com/stocnet/rsiena, src/model/effects, fetched fresh this
   unit) - default/base parameterization only in each case (v1 scope,
   matching every other multi-parameter effect's own history in this
   file, e.g. gwesp's own fixed-decay-first precedent): `transTies`'s
   sqrt-free base case, `transRecTrip`'s only parameterization (it has
   none), `outOutAss`'s non-`sqrt` (parameter=1) case - each source
   file's own "root"/parameter-2 branch is left as a disclosed,
   well-scoped follow-on, not silently dropped.

   `cycle4` (four-cycles) was investigated and DELIBERATELY NOT
   included this unit: its real C++ source (`FourCyclesEffect.cpp`)
   builds its 3-path count via `Network::inTies()`/`outTies()`
   iterators whose exact directed-vs-undirected semantics could not be
   confirmed from the source alone without a materially larger dive
   into RSiena's own `Network`/`OneModeNetwork` class hierarchy (four-
   cycles are also a more naturally UNDIRECTED concept in the SAOM
   literature generally, and `nwsaom` does not support undirected
   networks at all yet - see docs/SAOM_ROADMAP.md's own "Undirected
   relations" v1-exclusion). Implementing it with an unverified
   directedness assumption risks a silently wrong effect - left for a
   dedicated follow-on unit that can verify directedness empirically
   against real R output on both a directed and (once supported)
   undirected test network, rather than guessed here.
   =================================================================== */

/*
   IMPORTANT, disclosed property shared by ALL THREE effects below
   (transRecTrip/outOutAss/inInAss): each has a GENUINE multi-actor
   spillover, the same class of thing isolateNet (unit 34) was first
   found to have - change_saom_X() below correctly computes ONLY ego
   i's OWN local ministep delta (exactly matching RSiena's own real
   `calculateContribution`, which is itself scoped to ego's own
   out-neighborhood via `preprocessEgo`), NOT the raw graph-wide
   before/after difference in stat_saom_X(). Toggling i's own tie to j
   can also change OTHER actors' own separate local statistics (e.g.
   for outOutAss: any existing arc (h,i) uses outdeg(i) as its OWN
   alter-degree factor, so i's outdegree changing retroactively shifts
   h's own separate s_h(x) too) - by SAOM's own "myopic actor" design
   (an actor's ministep utility never accounts for how its own action
   affects OTHER actors' statistics), this is correct and NOT a bug,
   but it DOES mean a naive "stat_saom_X(before)+change_saom_X()==
   stat_saom_X(after)" test is the WRONG certification methodology for
   these three (a real first-attempt failure this unit hit directly,
   root-caused via a hand-traced counterexample before concluding it
   was a methodology error rather than a code bug - see
   cscripts/test_nwsaom_mata.do's own unit 37 certify test, which
   instead compares against ego i's own recomputed LOCAL statistic
   only, matching unit 36's own isolateNet-shape precedent, and passes
   at exactly 0.00e+00 across three network sizes). stat_saom_X() below
   remains the correct TRUE graph-wide statistic for the target/
   simulated-endpoint comparison MoM estimation actually needs - only
   the per-toggle CHANGE function is ego-scoped.
*/

/*
   transRecTrip (RSiena's own "transitive reciprocated triplets" -
   like transTrip above, but only counting two-paths i->h->j where the
   FINAL leg is itself reciprocated). Verified directly against the
   real `TransitiveReciprocatedTripletsEffect.cpp`:
   s_i(x) = sum_j x_ij * x_ji * OTP(i,j) - summed only over i's own
   MUTUALLY-tied out-neighbors j, weighted by the ordinary (non-
   reciprocity-filtered) two-path count OTP(i,j).

   Change-statistic derivation (toggling arc (i,j), ego i, alter j; all
   quantities BEFORE the toggle), re-derived from the global statistic
   above to confirm the real source's own two-term split
   (`contribution1` + `pRBTable`):

   (1) The (i,j) term itself: x_ji * OTP(i,j) - if j already ties back
       to i, toggling (i,j) adds/removes this whole term (OTP(i,j) is
       independent of x_ij itself, same no-self-loop argument as
       transTies above). Matches `contribution1`.

   (2) For every OTHER out-neighbor h of i that is ALSO reciprocated
       (x_ih=1 AND x_hi=1, h != j): toggling (i,j) makes j a new/lost
       candidate bridge k=j for OTP(i,h) exactly when j->h. Since h is
       a DIFFERENT term in the sum (s_i's own h-th summand, weighted by
       the ALREADY-mutual x_ih*x_hi, unaffected by toggling (i,j)),
       each such h contributes exactly +-1 (not scaled by OTP(i,h)
       itself, since only ONE candidate bridge - j - is changing).
       Matches `pRBTable`'s own real semantics ("i<->h<-j": h mutually
       tied to i, and j->h) exactly.
*/
real rowvector stat_saom_transrectrip(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		if (G.has_edge(ties[k,2], ties[k,1])) tot = tot + G.shared_partners_otp(ties[k,1], ties[k,2])
	}
	return(tot)
}
real rowvector change_saom_transrectrip(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar tied, delta, h, k
	real rowvector outnbrs

	tied = G.has_edge(i,j)
	delta = G.has_edge(j,i) ? G.shared_partners_otp(i,j) : 0

	outnbrs = G.neighbors_out(i)
	for (k=1; k<=cols(outnbrs); k++) {
		h = outnbrs[k]
		if (h == j) continue
		if (G.has_edge(h,i) & G.has_edge(j,h)) delta++
	}
	return(tied ? -delta : delta)
}

/*
   outOutAss (RSiena's own "out-out degree assortativity"): actors
   with high out-degree preferentially tie to other high-out-degree
   actors (or the reverse, for a negative coefficient). Verified
   directly against the real `OutOutDegreeAssortativityEffect.cpp`,
   default (non-`sqrt`, `internalEffectParameter()==1`) case only:
   s_i(x) = sum_j x_ij * outdeg(i) * outdeg(j).

   Change-statistic derivation (toggling arc (i,j), ego i, alter j; all
   degrees read BEFORE the toggle), re-derived from the global
   statistic to confirm the real source's own
   `neighborDegreeSum`/`ldegree` construction: toggling (i,j) changes
   BOTH the (i,j) term itself AND every OTHER existing out-tie term
   (i,h) (h in i's current out-neighbors), since outdeg(i) itself
   changes by 1 - unlike transTies/transRecTrip above, this effect's
   own delta is NOT confined to a single third-party bridge check.
   CREATING: new term (ldegree+1)*outdeg(j), plus every existing term's
   own +outdeg(h) increment (outdeg(i) rising by 1) summed over i's
   CURRENT out-neighbors = neighborDegreeSum. Matches the source's own
   "else" (no out-tie yet) branch exactly. DELETING (j is currently one
   of the out-neighbors summed into neighborDegreeSum): removes the
   (i,j) term itself (ldegree*outdeg(j)) plus every REMAINING term's
   own -outdeg(h) decrement, summed over the OTHER out-neighbors
   (neighborDegreeSum - outdeg(j)). Matches the source's own
   "outTieExists" branch exactly.
*/
real rowvector stat_saom_outoutass(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.degree_out(ties[k,1]) * G.degree_out(ties[k,2])
	return(tot)
}
real rowvector change_saom_outoutass(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar tied, ldegree, alterdeg, neighborsum, delta, k
	real rowvector outnbrs

	tied = G.has_edge(i,j)
	ldegree = G.degree_out(i)
	alterdeg = G.degree_out(j)
	outnbrs = G.neighbors_out(i)
	neighborsum = 0
	for (k=1; k<=cols(outnbrs); k++) neighborsum = neighborsum + G.degree_out(outnbrs[k])

	if (tied) {
		delta = (neighborsum - alterdeg) + ldegree*alterdeg
		return(-delta)
	}
	else {
		delta = neighborsum + (ldegree+1)*alterdeg
		return(delta)
	}
}

/*
   inInAss (RSiena's own "in-in degree assortativity" - a sibling of
   outOutAss above, but structurally SIMPLER, not merely a degree-
   direction relabeling: verified directly against the real
   `InInDegreeAssortativityEffect.cpp`, which is genuinely different in
   shape from `OutOutDegreeAssortativityEffect.cpp`, not just in-degree
   substituted for out-degree.
   s_i(x) = sum_j x_ij * indeg(i) * indeg(j).

   Change-statistic derivation (toggling arc (i,j), ego i, alter j; all
   degrees read BEFORE the toggle): unlike outOutAss, toggling ego's
   own OUT-tie to j never changes ego's own IN-degree (in-degree counts
   INCOMING ties, unaffected by i's own outgoing choices) - so EVERY
   other existing out-tie term (i,h), h != j, is completely unaffected
   (indeg(i) unchanged, indeg(h) unchanged - h's own indegree only
   changes if h itself gains/loses an incoming tie, and this toggle's
   only incoming-tie effect is on j, not h). Only the (i,j) term itself
   is affected, via j's own indegree changing by +-1:
   CREATING: new term = indeg(i) * (indeg(j)+1) - matches the source's
   own `if (!outTieExists(alter)) alterDegree++` then multiply.
   DELETING: removed term = indeg(i) * indeg(j) (indeg(j) read BEFORE
   removal already includes this very tie) - matches the source's own
   "outTieExists" branch, which leaves alterDegree unincremented.
*/
real rowvector stat_saom_ininass(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.degree_in(ties[k,1]) * G.degree_in(ties[k,2])
	return(tot)
}
real rowvector change_saom_ininass(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar tied, egodeg, alterdeg, delta

	tied = G.has_edge(i,j)
	egodeg = G.degree_in(i)
	alterdeg = G.degree_in(j)
	delta = egodeg * (tied ? alterdeg : alterdeg + 1)
	return(tied ? -delta : delta)
}

/*
   outInAss (RSiena's own "out-in degree assortativity" - harmonisation
   unit 165, the first of the two directions explicitly left "still
   remaining" by unit 37 above): actors with high OUT-degree
   preferentially tie to actors with high IN-degree. Verified directly
   against the real `OutInDegreeAssortativityEffect.cpp` (fetched
   fresh, cached locally from unit 37's own earlier fetch), default
   (non-`sqrt`) case only:
   s_i(x) = sum_j x_ij * outdeg(i) * indeg(j).

   This is NOT simply outOutAss with indeg substituted for outdeg in
   the alter role - the real source's own `preprocessEgo` builds
   `lneighborDegreeSum` from alters' IN-degree (not out-degree, as
   outOutAss does), and - the genuine asymmetry a naive
   degree-substitution guess would miss - toggling (i,j) changes
   ALTER's own in-degree too (an out-tie FROM i IS an in-tie TO j),
   unlike outOutAss where toggling ego's own out-tie never changes
   alter's own out-degree. Change-statistic derivation (toggling arc
   (i,j), ego i, alter j; all degrees read BEFORE the toggle),
   confirmed term-for-term against the source's own `else`
   (creating)/`if (outTieExists)` (deleting) branches:

   CREATING (j not currently an out-neighbor): the new (i,j) term is
   (ldegree+1)*(alterdeg+1) - BOTH factors shift, since creating the
   tie raises ego's own out-degree AND alter's own in-degree
   simultaneously. Every OTHER existing out-tie term (i,h), h!=j, gets
   +indeg(h) from ego's own out-degree rising by 1 (alter h's own
   in-degree is unaffected by this toggle) - summed over i's CURRENT
   out-neighbors (j not yet among them) = neighborsum. Matches the
   source's own `lneighborDegreeSum + (ldegree+1)*(alterDegree+1)`
   exactly (note the `+1` on alterDegree too - the one detail a
   degree-substitution guess from outOutAss would miss).

   DELETING (j currently an out-neighbor, already counted in
   neighborsum): the (i,j) term itself (ldegree*alterdeg, read BEFORE
   removal) disappears entirely. Every REMAINING out-tie term (i,h),
   h!=j, loses -indeg(h) from ego's own out-degree falling by 1 -
   summed over the OTHER out-neighbors = neighborsum - alterdeg.
   Matches the source's own `(lneighborDegreeSum - alterDegree) +
   ldegree*alterDegree` exactly.

   Same genuine multi-actor spillover class as outOutAss/inInAss/
   isolateNet above (toggling (i,j) also shifts OTHER actors' own
   summands wherever alter j appears as someone else's alter, since
   j's own in-degree changed) - change_saom_outinass() below is
   correctly scoped to ego i's own local ministep delta only, matching
   RSiena's real per-ego `calculateContribution` exactly; see this
   file's own header comment above stat_saom_transrectrip for why a
   naive graph-wide before/after test is the wrong certification
   methodology for this whole effect family.
*/
real rowvector stat_saom_outinass(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.degree_out(ties[k,1]) * G.degree_in(ties[k,2])
	return(tot)
}
real rowvector change_saom_outinass(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar tied, ldegree, alterdeg, neighborsum, delta, k
	real rowvector outnbrs

	tied = G.has_edge(i,j)
	ldegree = G.degree_out(i)
	alterdeg = G.degree_in(j)
	outnbrs = G.neighbors_out(i)
	neighborsum = 0
	for (k=1; k<=cols(outnbrs); k++) neighborsum = neighborsum + G.degree_in(outnbrs[k])

	if (tied) {
		delta = (neighborsum - alterdeg) + ldegree*alterdeg
		return(-delta)
	}
	else {
		delta = neighborsum + (ldegree+1)*(alterdeg+1)
		return(delta)
	}
}

/*
   inOutAss (RSiena's own "in-out degree assortativity" - harmonisation
   unit 165, the second of unit 37's own deferred directions): actors
   with high IN-degree preferentially tie to actors with high
   OUT-degree. Verified directly against the real
   `InOutDegreeAssortativityEffect.cpp`: structurally the SIMPLEST of
   all four assortativity directions (simpler even than inInAss) -
   `calculateContribution` reads `egoDegree = inDegree(ego)` and
   `alterDegree = outDegree(alter)` and returns their PLAIN PRODUCT
   with no `outTieExists` branching and no `preprocessEgo`/neighbor-sum
   machinery at all, because NEITHER factor is affected by toggling
   arc (i,j) in either direction: ego's own IN-degree only changes via
   ties INTO i (unaffected by i's own outgoing choice), and alter's own
   OUT-degree only changes via ties OUT OF j (i->j is not one of j's
   own outgoing ties). s_i(x) = sum_j x_ij * indeg(i) * outdeg(j), and
   toggling (i,j) only ever adds/removes this ONE term at its own
   BEFORE-toggle value - no spillover onto ego's own other out-tie
   terms (matching inInAss's own already-established simpler shape,
   confirmed here to be shared by this direction too, not merely
   assumed by analogy).
*/
real rowvector stat_saom_inoutass(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.degree_in(ties[k,1]) * G.degree_out(ties[k,2])
	return(tot)
}
real rowvector change_saom_inoutass(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar tied, egodeg, alterdeg, delta

	tied = G.has_edge(i,j)
	egodeg = G.degree_in(i)
	alterdeg = G.degree_out(j)
	delta = egodeg * alterdeg
	return(tied ? -delta : delta)
}

/*
   Transitive triplets (harmonisation unit 4 - Snijders et al.'s
   "transTrip", the archetypal SAOM structural effect): s_i(x) = sum_j
   sum_h x_ij * x_ih * x_hj - for actor i, the number of ordered pairs
   (j,h) of i's own out-neighbors such that h also ties to j (i is
   involved in a transitive triangle i->j, i->h, h->j).

   Derivation of the ministep delta (actor i toggling arc i->j; all
   quantities read on the graph BEFORE this toggle, matching every
   other change() function's own contract): splitting the double sum
   by which factor the toggled arc (i,j) supplies -
     - as the "i->j" factor (summation index j itself): contributes
       x_ij * |{h in N_out(i): h->j}| = x_ij * OTP(i,j), reusing
       ErgmGraph's own already-certified shared_partners_otp() (unit
       91/93, docs/ERGM_ROADMAP.md) rather than a fresh traversal - OTP
       is EXACTLY "count of i's out-neighbors h with h->j" by its own
       definition (#{k: i->k, k->j}).
     - as the "i->h" factor (summation index h itself): contributes
       x_ij * |{j' in N_out(i): j->j'}| = x_ij * OSP(i,j), again
       reusing shared_partners_osp() unmodified (#{k: i->k, j->k}
       exactly matches "i's out-neighbors j' with j->j'" once relabeled
       k=j').
     - no other term in the double sum can equal the toggled arc
       (i,j) (the third factor is x_hj', a DIFFERENT dyad from (i,j)
       unless h=i, excluded since h ranges over i's own out-neighbors
       and this package has no self-loops).
   So: creating i->j -> delta = OTP(i,j)+OSP(i,j); deleting i->j ->
   delta = -(OTP(i,j)+OSP(i,j)). Global statistic (used only by
   full_statistic(), never accumulated via change()): for each existing
   arc h->j, the number of actors i with BOTH i->h and i->j is exactly
   ISP(h,j) (#{k: k->h, k->j}) - so S(x) = sum over existing arcs (h,j)
   of shared_partners_isp(h,j), again pure reuse of an existing
   certified primitive, no new traversal.
*/
real rowvector stat_saom_transtrip(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.shared_partners_isp(ties[k,1], ties[k,2])
	return(tot)
}
real rowvector change_saom_transtrip(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = G.shared_partners_otp(i,j) + G.shared_partners_osp(i,j)
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
   Transitive MEDIATED triplets ("transMedTrip", RSiena's own real,
   DISTINCT sibling of transTrip above - verified from RSiena's real
   TransitiveMediatedTripletsEffect.cpp source, cached this session at
   /private/tmp/rsiena_src/RSiena/src/model/effects/): calculateContribution
   AND tieStatistic are BOTH literally `pOutStarTable()->get(alter)` alone
   (no OTP/OSP combination the way transTrip needs) - confirmed from
   NetworkCache.cpp's own real table construction that OutStarTable is
   built as `TwoPathTable(BACKWARD, FORWARD)`: first step BACKWARD from
   ego i (h->i) then FORWARD from the SAME h (h->j), i.e. exactly
   #{h: h->i AND h->j} = ISP(i,j) - the number of actors with an
   incoming tie to BOTH i and j. This is genuinely NOT the same
   quantity as transTrip's own OTP(i,j)+OSP(i,j) (a real, distinct
   RSiena effect, not a duplicate) despite both eventually reusing the
   same shared_partners_isp() primitive somewhere. Zero new derivation
   needed beyond that primitive - both this stat/change pair below and
   the native/saom_sim.c port (TERMCODE_TRANSMEDTRIP) call it directly,
   matching transTrip's own established two-primitive-reuse discipline.
   Sign convention (ij_exists ? -delta : delta) matches every other
   ministep effect in this file - RSiena's own calculateContribution has
   no explicit sign branch because its OWN framework applies the
   create/withdraw distinction outside individual effect classes, not a
   discrepancy with this file's internal toggle-delta representation.
*/
real rowvector stat_saom_transmedtrip(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.shared_partners_isp(ties[k,1], ties[k,2])
	return(tot)
}
real rowvector change_saom_transmedtrip(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = G.shared_partners_isp(i,j)
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
   in3Plus (RSiena real effect, `EffectFactory.cpp': "in3Plus" -> new
   AntiIsolateEffect(pEffectInfo, false, 3) - the SAME class already
   certified for antiInIso (minDegree=1)/antiInIso2 (minDegree=2) above,
   just with the threshold raised to 3: alter-indexed, counts actors with
   indegree>=3, spillover-free (matches antiInIso2's own exact shape -
   the change function only fires when the TOGGLED alter's own indegree
   crosses the threshold, never touching any third actor's own count).
*/
real rowvector stat_saom_in3plus(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + (G.din[i]>=3)
	return(tot)
}
real rowvector change_saom_in3plus(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar d, tied, cond

	d = G.din[j]
	tied = G.has_edge(i,j)
	cond = tied ? (d==3) : (d==2)
	return(cond ? (tied ? -1 : 1) : 0)
}

/*
   reciAct/reciPop (RSiena real effects "reciAct"/"reciPop") - INVESTIGATED,
   NOT SHIPPED (unlike in3Plus above, which the same investigation
   confirmed correct, maxerr=0e+00). Both formulas below were transcribed
   faithfully from the real RecipdegreeActivityEffect.cpp/
   RecipdegreePopularityEffect.cpp `calculateContribution()' source
   (default/non-sqrt parameterization, not guessed), but certification
   against the "ego's own recomputed local statistic before/after the
   toggle equals before + predicted delta" property - the SAME
   methodology that already certifies every other myopic-actor effect in
   this file (indegpopularity/outactivity/outoutass/etc.) - failed with a
   large, consistent (not noise-sized: 15-40 vs an expected ~0) discrepancy
   on both a 10- and a 16-node network, 3000 toggles each. This suggests
   RSiena's own `calculateContribution()' for these two specific effects
   may represent an ABSOLUTE per-alternative multinomial-logit score
   rather than an incremental delta of a "local statistic" the way most
   other effects in this codebase's own convention already do - a genuine
   semantic difference this investigation did not have time to fully
   resolve, not a transcription error (the C++ formulas below are ported
   verbatim). Kept here as plain comments (not live Mata code, and not
   registered in nwsaom.ado's own term dispatch) so a future attempt has
   the real, source-verified starting formulas on record rather than
   having to re-derive them from scratch:

   stat_saom_reciact(G, td): global/observed statistic - sum over ties
   (ego,alter) of ego's own reciprocal degree (mutual-tie count) = sum
   over nodes of outdegree(node)*reciprocalDegree(node) (confirmed from
   `tieStatistic()': contributes reciprocalDegree(ego) once per tie).
       tot = 0
       for (i=1; i<=G.n; i++) tot = tot + G.degree_out(i)*cols(G.mutual_neighbors(i))
       return(tot)

   change_saom_reciact(G, i, j, td): ministep delta, ported verbatim from
   `calculateContribution()' - i=ego, j=candidate alter.
       rdegree = cols(G.mutual_neighbors(i))
       if (G.has_edge(j,i)) {
           rdegree = rdegree + G.degree_out(i)
           if (G.has_edge(i,j)) rdegree--
           else rdegree++
       }
       return(rdegree)

   stat_saom_recipop(G, td): global/observed statistic - sum over ties
   (ego,alter) of alter's own reciprocal degree (confirmed from
   `tieStatistic()': returns reciprocalDegree(alter) as-is) = sum over
   nodes of indegree(node)*reciprocalDegree(node).
       tot = 0
       for (i=1; i<=G.n; i++) tot = tot + G.din[i]*cols(G.mutual_neighbors(i))
       return(tot)

   change_saom_recipop(G, i, j, td): ministep delta, ported verbatim -
   alter j's own current reciprocal degree, +1 if i already ties to j
   (creating this candidate tie would make the pair mutual).
       degree = cols(G.mutual_neighbors(j))
       if (G.has_edge(i,j)) degree++
       return(degree)
*/

/*
   3-cycles (harmonisation unit 5 - RSiena's "cycle3"): s_i(x) = sum_j
   sum_h x_ij * x_jh * x_hi - the number of directed 3-cycles i->j->h->i
   actor i participates in as the cycle's own start/end point. Genuinely
   different from transitive triplets above (a CYCLIC configuration, not
   a hierarchical/transitive one): both i->j and j->h and h->i must all
   point "forward around the loop", not converge on a shared third node.

   Derivation of the ministep delta (actor i toggling arc i->j; j0
   denotes the specific alter being toggled, to avoid clashing with the
   formula's own bound variable j): the toggled arc (i,j0) appears in
   the double sum ONLY as the "i->j" factor (summation index j=j0) -
   sum_h x_j0,h * x_h,i = |{h: j0->h, h->i}|, exactly OTP(j0,i)
   (#{k: j0->k, k->i}) by definition, reused unmodified. It cannot
   appear as either of the other two factors (x_jh is dyad (j,h), never
   equal to ordered dyad (i,j0) unless j=i - excluded, j ranges over
   i's own out-neighbors and there are no self-loops; x_hi is dyad
   (h,i), the OPPOSITE-direction arc from (i,j0), a genuinely different
   dyad).
   So: creating i->j -> delta = OTP(j,i); deleting i->j -> delta =
   -OTP(j,i) (note the SWAPPED argument order vs. transitive triplets
   above - a real, easy-to-get-backwards detail, not a typo: transitive
   triplets needs OTP(i,j), 3-cycles needs OTP(j,i)). Global statistic:
   for each existing arc i->j, the count of h completing a 3-cycle
   (j->h->i) is exactly OTP(j,i) - so S(x) = sum over existing arcs
   (i,j) of shared_partners_otp(j,i).
*/
real rowvector stat_saom_cycle3(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.shared_partners_otp(ties[k,2], ties[k,1])
	return(tot)
}
real rowvector change_saom_cycle3(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = G.shared_partners_otp(j,i)
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
   cycle4 (four-cycles, harmonisation unit 168) - deferred by unit 37
   pending a directedness verification of RSiena's own real source,
   now completed: `FourCyclesEffect.cpp`'s own `countThreePaths(i,
   pNetwork, counters)` walks `pNetwork->outTies(i)` for the first leg
   (i->h), then `pNetwork->inTies(h)` for the second (k->h, i.e. h's
   own IN-neighbors), then `pNetwork->outTies(k)` for the third
   (k->j). This construction is GENUINELY directed - it deliberately
   uses `outTies'/`inTies' as two distinct sets at different points in
   the same traversal, which only differ from each other on a directed
   network (on an undirected network they would be identical, and the
   whole "directed vs undirected" question this unit was blocked on
   would simply be moot). Since it is a real, well-defined directed
   construction rather than an undirected concept smuggled onto
   directed data, it fits nwsaom's directed-only architecture exactly
   the same way `cycle3' (a directed 3-cycle count) already does - no
   further ambiguity to resolve.

   Base (non-`lroot'/sqrt) case only - v1 scope, matching every other
   multi-parameter RSiena effect in this file's own "fixed/base
   parameterization first" precedent (gwesp/gwdegree's own history).
   `FourCyclesEffect::tieStatistic()' returns `counters[alter] * 0.25'
   per existing out-tie (the 0.25 divisor RSiena's own source comment
   explains as "avoid counting each 4-cycle four times") -
   `stat_saom_cycle4()' below reproduces this exactly, not a rescaled
   equivalent, so fitted coefficients match RSiena's own reported
   magnitude directly, not just up to a constant multiple.

   `calculateContribution(alter)' (non-`lroot' branch) returns exactly
   `this->lcounters[alter]' - RSiena's own per-ego, per-candidate-alter
   THREE-PATH COUNT, with no separate exists/doesn't-exist branch,
   because for this LINEAR (non-sqrt) case the magnitude of the change
   is symmetric in direction: creating tie i->j ADDS exactly this many
   completed 4-cycles' worth of contribution, removing it REMOVES the
   identical amount - matching every other already-implemented
   effect's own `change_saom_X()' contract in this file (a plain
   signed delta keyed off `G.has_edge(i,j)', not RSiena's own
   create/remove-branching convention verbatim, since nwsaom's own
   architecture already has ITS uniform change-function contract).

   CRITICAL: `calculateContribution()' does NOT carry the `* 0.25'
   `tieStatistic()' has - a real asymmetry in RSiena's own real
   source, re-checked verbatim, not an oversight to "fix" into
   consistency. `tieStatistic()`'s own 0.25 exists specifically to
   correct the GLOBAL statistic's own quadruple-counting (each true
   4-cycle is seen once by EACH of its own 4 member ties when summed
   over every tie in the network); `calculateContribution()' is a
   single ministep's own per-actor decision value, never summed across
   ties the way the global statistic is, so there is no analogous
   over-counting there to correct. A first version of this port
   mistakenly applied the SAME 0.25 to both functions (an easy trap -
   both read `lcounters[alter]' verbatim) - caught via a real R
   comparison finding a STABLE (not noisy) ~3.8x-too-large fitted
   coefficient (1.6 vs RSiena's own 0.42 on real s50 data, consistent
   across two seeds) that resolved almost exactly to RSiena's own value
   once divided by 4 (0.402 vs 0.4233) - the tell that pointed straight
   at a missing/extra 4x scaling rather than a genuine estimation-noise
   gap. `change_saom_cycle4()' below is therefore UNSCALED (matching
   `calculateContribution()' exactly); `stat_saom_cycle4()' above keeps
   the `* 0.25' (matching `tieStatistic()' exactly) - the two
   functions' own scale genuinely differ by design, not a bug to
   reconcile into one shared constant.

   `_saom_cycle4_threepaths(G,i,j)' below is `countThreePaths(i)[j]'
   from ego i's own perspective - a NEW primitive, not a reuse of
   `shared_partners_otp()'/etc. (those are two-arc "shared partner"
   counts; this is a genuinely different three-arc traversal with a
   direction reversal at the middle step). It is inherently ego-i-
   local by construction (reads only i's own out-neighbors and their
   own in-neighbors' own out-neighbors in the CURRENT graph state),
   matching RSiena's own `calculateContribution''s ego-scoping exactly
   - so `change_saom_cycle4()' needs no special third-party-spillover
   handling in ITS OWN definition. The GLOBAL statistic
   `stat_saom_cycle4()' still has the SAME kind of spillover unit 37's
   own `outOutAss'/`inInAss' already found (toggling (i,j) changes
   OTHER (i',j') pairs' own three-path counts too) - so this effect's
   own certification must compare against ego i's own RECOMPUTED LOCAL
   statistic (unit 36/37's own established methodology), never a naive
   graph-wide before/after diff, which would fail exactly the way
   `outOutAss'/`inInAss' first did.
*/
real scalar _saom_cycle4_threepaths(class ErgmGraph scalar G, real scalar i, real scalar j){
	real scalar h, k, hidx, kidx, tot
	real rowvector houts, kins

	tot = 0
	houts = G.neighbors_out(i)
	for (hidx=1; hidx<=cols(houts); hidx++) {
		h = houts[hidx]
		if (h == j) continue
		kins = G.neighbors_in(h)
		for (kidx=1; kidx<=cols(kins); kidx++) {
			k = kins[kidx]
			if (k == i) continue
			if (G.has_edge(k,j)) tot++
		}
	}
	return(tot)
}
real rowvector stat_saom_cycle4(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + _saom_cycle4_threepaths(G, ties[k,1], ties[k,2])
	return(tot * 0.25)
}
real rowvector change_saom_cycle4(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = _saom_cycle4_threepaths(G, i, j)
	return(G.has_edge(i,j) ? -delta : delta)
}

/* crprod (multiplex SAOM Stage 2, docs/SAOM_ROADMAP.md): the first
   cross-network effect, RSiena's own real "netA: netB" term - verified
   directly from real RSiena 1.6.6 source (`getEffects()` on a genuine
   two-network dataset confirms "crprod" is the real shortName;
   src/model/effects/EffectFactory.cpp dispatches it to
   `GenericNetworkEffect(pEffectInfo, new OutTieFunction(interactionName1()))`;
   OutTieFunction::value(alter) (generic/OutTieFunction.cpp) returns
   `pNetworkCache()->outTieValue(alter)` - the OTHER network's own
   current out-tie value from ego to alter; GenericNetworkEffect's own
   single-function constructor (generic/GenericNetworkEffect.cpp) uses
   that SAME function for both `calculateContribution` (the change
   statistic) and `tieStatistic` (the observed-statistic accumulator) -
   confirmed, not assumed, since GenericNetworkEffect ALSO has a
   two-function constructor for effects where those differ). This is
   therefore structurally IDENTICAL to nwergm's own `edgecov()`
   (stat_edgecov()/change_edgecov() above in unw_ergm.do) - sum over
   ties of a per-dyad value read from a second source - except the
   "source" here is a LIVE second network's current adjacency, not a
   static covariate matrix, which is exactly what `td.xnet` (a pointer
   the estimator keeps re-pointed at whichever ErgmGraph copy is
   currently "the other network" for this simulation replicate - see
   its own field comment on ErgmTermData) is for. No third-party/
   multi-actor spillover: toggling (i,j) in G changes only (i,j)'s own
   contribution, since (*td.xnet).has_edge(i,j) does not depend on G at
   all - the SAME dyad-independent shape edgecov() already has, so no
   ego-local-statistic certification subtlety applies here (unlike
   isolateNet/transRecTrip/outOutAss and friends). */
real rowvector stat_crprod(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + (*td.xnet).has_edge(ties[k,1], ties[k,2])
	return(tot)
}
real rowvector change_crprod(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar v

	v = (*td.xnet).has_edge(i, j)
	return(G.has_edge(i,j) ? -v : v)
}

/* ===================================================================
   Harmonisation unit 9 (docs/SAOM_ROADMAP.md): three more effects,
   each independently VERIFIED against the real RSiena C++ source
   (github.com/stocnet/rsiena, src/model/effects, per-effect .cpp files - read directly,
   per the user's own "always check against real R results and code"
   instruction) before being derived/implemented here, not assumed from
   the general SAOM literature.

   Outdegree popularity (sqrt) - RSiena's OutdegreePopularityEffect.cpp:
   calculateContribution(alter) = sqrt(outDegree(alter)) with NO +/-1
   adjustment for create vs. delete (verified: toggling ego's own tie
   to alter never changes alter's own OUT-degree, only alter's
   IN-degree - unlike indegree-popularity above, which unit 3 already
   derived and independently verified matches
   IndegreePopularityEffect.cpp's own +1-on-create adjustment exactly).
   s_i(x) = sum_{j: x_ij=1} sqrt(outdegree(j)); global
   S(x) = sum_j sqrt(outdegree(j)) * indegree(j).
*/
real rowvector stat_saom_outpop(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar j, tot

	tot = 0
	for (j=1; j<=G.n; j++) tot = tot + sqrt(G.dout[j]) * G.din[j]
	return(tot)
}
real rowvector change_saom_outpop(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = sqrt(G.dout[j])
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
   Indegree activity (sqrt) - RSiena's IndegreeActivityEffect.cpp:
   calculateContribution(alter) = sqrt(inDegree(EGO)) - note this reads
   the EGO's own indegree, not alter's, and does NOT depend on `alter`
   at all (verified directly from source: no `alter` parameter used in
   the formula) - so every "create" alternative gets the SAME additive
   contribution, and every "delete" alternative the same negative one.
   s_i(x) = sum_{j: x_ij=1} sqrt(indegree(i)) = outdegree(i)*sqrt(indegree(i));
   global S(x) = sum_i outdegree(i)*sqrt(indegree(i)).
*/
real rowvector stat_saom_inact(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot

	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + G.dout[i] * sqrt(G.din[i])
	return(tot)
}
real rowvector change_saom_inact(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = sqrt(G.din[i])
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
   Covariate similarity ("simX") - RSiena's CovariateSimilarityEffect.cpp
   + Covariate.cpp's own similarity(a,b) = 1 - |a-b|/range - similarityMean.
   Dyad-local, no create/delete adjustment (verified directly from
   source - calculateContribution(alter) just returns actor_similarity()
   unconditionally, the same "no adjustment needed" shape as nodematch/
   nodecov). v1 DISCLOSED SIMPLIFICATION: omits the similarityMean
   centering term - a fixed constant subtracted from every dyad's score
   in real RSiena purely to reduce confounding with the density/outdegree
   parameter (itself always present in this package's own v1 models,
   unit 1) - since it is a per-toggle CONSTANT offset, omitting it
   changes how density and simX's own coefficients split credit for the
   overall tie count, not whether the model can represent the data;
   both parameters remain jointly identified. `td.decay` (otherwise
   unused by this term - a generic scalar slot ErgmTermData already
   carries for nwergm's own gwesp-family terms) is repurposed to cache
   `range = max(attr)-min(attr)`, computed once at term-registration
   time rather than recomputed on every change-statistic call.
*/
real rowvector stat_saom_simcov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		tot = tot + 1 - abs(td.attr[ties[k,1]] - td.attr[ties[k,2]]) / td.decay - _saom_center0(td)
	}
	return(tot)
}
real rowvector change_saom_simcov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	// RSiena's simX: similarity minus its mean over all pairs (td.center,
	// SaomSimMean(); 2026-10-01, before: not centered)
	delta = 1 - abs(td.attr[i] - td.attr[j]) / td.decay - _saom_center0(td)
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
   behsim: similarity on the CO-EVOLVING behavior (RSiena's simX with the
   dependent behavior as interaction1, e.g. "drinking similarity" - the
   standard selection effect of a co-evolution model). Same tie-level
   quantity as simcov() above, but (1) the values are the behavior's
   CURRENT simulated values, which change during a simulated period, and
   (2) centered by the behavior's own similarity mean, exactly as RSiena
   centers simX:

       s_i(x) = sum_j x_ij * (1 - |z_i - z_j|/range - simMean)

   range = observed behavior range (max-min over all waves), simMean =
   saom_similarity_mean() (the same constant avsim uses). Checked against
   RSiena 1.6.6's own target statistic on s50 (end-of-period network,
   START-of-period behavior - see SaomCoevStatNet() below), which it
   reproduces to machine precision.

   td.attr holds the behavior values the term reads. The co-evolution
   simulators keep it in step with the simulated behavior
   (SaomBehSimSync()/SaomBehSimSetValue()); the estimators set it to the
   period's STARTING behavior before computing a statistic.
   td.decay = range, td.center = simMean.
*/
real rowvector stat_saom_behsim(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		tot = tot + 1 - abs(td.attr[ties[k,1]] - td.attr[ties[k,2]]) / td.decay - td.center
	}
	return(tot)
}
real rowvector change_saom_behsim(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = 1 - abs(td.attr[i] - td.attr[j]) / td.decay - td.center
	return(G.has_edge(i,j) ? -delta : delta)
}

/* SaomBehSimSync(): point every behsim term of M at the behavior values
   `vals' (the whole vector). SaomBehSimSetValue(): update actor i only,
   after a behavior ministep changed its value. Both are no-ops for a model
   without behsim. M.td is an untyped pointer rowvector, so the field is
   reached through a typed intermediate pointer (see the crprod note in
   SaomEstimateRMCoevNetNet()). */
void SaomBehSimSync(class ErgmModel scalar M, real colvector vals){
	real scalar t
	pointer(class ErgmTermData scalar) scalar ptd

	for (t=1; t<=M.nterms; t++) {
		if (M.names[t] != "behsim") continue
		ptd = M.td[t]
		(*ptd).attr = vals
	}
}
void SaomBehSimSetValue(class ErgmModel scalar M, real scalar i, real scalar v){
	real scalar t
	real colvector a
	pointer(class ErgmTermData scalar) scalar ptd

	for (t=1; t<=M.nterms; t++) {
		if (M.names[t] != "behsim") continue
		ptd = M.td[t]
		a = (*ptd).attr		// (*ptd).attr[i] = v is not a valid lvalue in Mata
		a[i] = v
		(*ptd).attr = a
	}
}
real scalar SaomHasBehSim(class ErgmModel scalar M){
	return(anyof(M.names, "behsim"))
}

/*
	GWESP (harmonisation unit 22, CORRECTED - see this codebase's own
	change history: the FIRST version of this term wrongly reused
	nwergm's own change_gwesp_otp() directly, on the assumption that a
	SAOM ministep's own change statistic always equals the full
	ERGM/MCMC-style "how does the global statistic change when this
	dyad toggles" delta - true for outdegree/reciprocity/nodematch
	(units 1-2) and, it turns out, transtrip/cycle3 (units 4-5, whose
	own single-term formulas happen to have zero cross-tie spillover),
	but NOT true here. Caught only by reading real RSiena's own
	GenericNetworkEffect.cpp (the actual C++ wrapper class RSiena uses
	for `gwespFF`), not assumed: `GenericNetworkEffect::
	calculateContribution(alter)` is EXACTLY
	`this->lpEffectFunction->value(alter)' - i.e. JUST the GwespFunction
	kernel's own lookup for the (ego,alter) dyad's OWN CURRENT
	shared-partner count, no delta computation, no neighbor-adjustment
	loops at all. `nwergm`'s own change_gwesp_otp() (own-dyad term PLUS
	TWO neighbor loops, na/nb, computing how the toggle ripples onto
	OTHER already-existing ties' own shared-partner counts) is the
	CORRECT formula for what an ERGM MCMC toggle does to the GLOBAL
	sum - but real RSiena's own actor-level ministep evaluation function
	for this specific effect is a genuinely SIMPLER approximation that
	ignores that ripple entirely (a real, documented characteristic of
	RSiena's own "Generic" effect framework for nonlinear
	geometrically-weighted terms, not a bug in nwergm - each package's
	own construction is internally consistent, they are just genuinely
	DIFFERENT mathematical objects for this specific effect).
	stat_gwesp()/stat_gwesp_otp() (unw_ergm.do, reused UNCHANGED for the
	GLOBAL/observed statistic - RSiena's own `tieStatistic()` DOES match
	that formula exactly, confirmed separately and unaffected by this
	correction) are still reused directly; only the MINISTEP/change
	formula below is SAOM-specific, reusing just the gw_kernel() helper
	(also unaffected - the kernel itself was always correct), not the
	full change_gwesp_otp() function.
*/
real rowvector change_saom_gwesp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = gw_kernel(G.shared_partners_otp(i,j), td.decay)
	return(G.has_edge(i,j) ? -delta : delta)
}

/*
	transTies (harmonisation unit 23). Applying the lesson unit 22's own
	correction just established (read the ACTUAL ministep-contribution
	class, not just a statistic/kernel helper) FROM THE START: real
	RSiena's own `TransitiveTiesEffect.cpp' (verified directly,
	`stocnet/rsiena' on GitHub - not a "Generic"-wrapped effect like
	`gwespFF', its OWN dedicated `NetworkEffect'-derived class) has:

	    calculateContribution(alter=j) = CriticalInStarTable(j)
	        + (TwoPathTable(j) > 0 ? 1 : 0)

	"Suppose we introduce the tie from ego i to alter j, which causes
	another tie (i,h) to become transitive... <(i,h),(j,h)> is one of
	the critical in-stars between i and j" (RSiena's own comment,
	verbatim) - i.e. CriticalInStar(j) = #{h : (i,h) is an EXISTING tie,
	currently NOT transitive (OTP(i,h)==0), that WOULD become
	transitive if i->j were added (requires j->h)}. Mapped onto
	nwergm's own change_transitiveties() (unw_ergm.do) structure
	directly:
	  - RSiena's own "TwoPathTable(j)>0 ? 1 : 0" term = nwergm's own
	    "own dyad" term (`shared_partners_otp(i,j)>=1', sign-flipped for
	    deletion) - OTP(i,j) is itself invariant to toggling arc i->j
	    (j can never serve as its own intermediate), so this correctly
	    represents the NEW/removed term's own value either way.
	  - RSiena's own "CriticalInStarTable(j)" = EXACTLY nwergm's own
	    "nb" loop (neighbors_out(j) with i->b already existing: does
	    OTP(i,b) cross the >=1 threshold due to the NEW two-path
	    i->j->b?) - both count EXISTING ties (i,b)/(i,h) becoming newly
	    transitive due to THIS SAME mechanism.
	  - nwergm's own "na" loop (neighbors_in(i) with a->j existing: does
	    OTP(a,j) cross the threshold?) is about OTHER ACTORS' ties
	    (a,j), NOT i's own - RSiena's own comment restricts ENTIRELY to
	    "(i,h)" ties, never mentioning any "(a,j)" case. This is the
	    SAME "myopic actor" restriction transtrip/cycle3 (units 4-5)
	    already correctly apply (an actor's own ministep utility never
	    accounts for how its action affects OTHER actors' own
	    statistics) - the loop nwergm's own GENERIC ERGM change function
	    needs (since an MCMC toggle's effect on the GLOBAL sum
	    legitimately includes every actor's own ties) but a SAOM
	    ministep must not.

	UNLIKE gwesp() (harmonisation unit 22): this effect has its OWN
	dedicated RSiena class, not a "Generic effect" wrapper - its own
	ministep formula genuinely IS the exact ego-restricted gradient of
	s_i(x) = sum over i's own existing ties h of indicator(OTP(i,h)>=1)
	(own dyad + ripple onto i's OWN other ties, no approximation - see
	this term's own certification, which uses the standard ego-level
	brute-force methodology successfully, unlike gwesp()'s own).
*/
real rowvector change_saom_transties(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, b, m, oldb
	real rowvector nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = delta * (G.shared_partners_otp(i,j) >= 1)

	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		if (!G.has_edge(i,b)) continue
		oldb = G.shared_partners_otp(i,b)
		chg = chg + ((oldb+delta>=1) - (oldb>=1))
	}
	return(chg)
}

/*
   Structural balance (harmonisation unit 25 - RSiena's "balance"),
   verified against the real source FIRST (`stocnet/rsiena`,
   `src/model/effects/BalanceEffect.cpp` + the R-side `calcBalmean()`
   in `R/sienaDataCreate.r`) per this whole initiative's own established
   discipline - not derived from the SIENA manual's formula alone.

   Manual formula: s_i(x) = sum_j x_ij * sum_{h!=i,j} (b0 - |x_ih-x_jh|),
   where b0 ("balanceMean") is a DATA-DERIVED constant (NOT a free
   parameter, NOT user-supplied) - the empirical mean of |x_ih-x_jh|
   over every valid distinct actor triple (i,j,h) in the observed data,
   pooled by SUMMING numerators/denominators separately THEN dividing
   ONCE at the end (confirmed from `calcBalmean()`'s own `for (k in
   1:(dims[3]-1))` loop - pooled across every PERIOD-BASE wave, i.e.
   every observation except the very last, matching this codebase's own
   established summation-pooling convention for theta/Jacobian (units
   17-18) and GOF auxiliary statistics (`join=TRUE`, unit 21)). This
   package has no missing-tie support (v1 scope), so `saom_balance_mean()`
   below omits `calcBalmean()`'s own missing-data bookkeeping entirely -
   every actor h has exactly n-1 valid rows.

   RSiena's own `BalanceEffect::calculateContribution(alter)` is its OWN
   dedicated `NetworkEffect`-derived class (like `TransitiveTiesEffect`,
   unit 23 - NOT a "Generic effect" wrapper like `gwespFF`, unit 22), so
   it computes a real, state-independent-of-(i,alter) delta, algebraically
   engineered (via explicit `inTieExists()`/`outTieExists()` corrections)
   to represent "the value of s_i if tie (i,alter) were set to 1"
   regardless of whether that tie currently exists - exactly this
   codebase's own `has_edge(i,j) ? -val : val` convention, just with the
   sign correction folded INTO the algebra rather than applied
   externally (cross-checked against the simplest possible RSiena effect,
   `DensityEffect::calculateContribution()`, which always returns the
   constant 1 regardless of create/remove direction - confirming RSiena's
   own framework, not the individual effect class, normally applies the
   sign; `BalanceEffect` instead self-corrects via the same
   `outDegree(ego)-1` trick used below, which is mathematically
   equivalent).

   Re-deriving `calculateContribution()`'s own "A-B" decomposition in
   this codebase's own primitives (`degree_out()`, `has_edge()`,
   `shared_partners_osp()`=RSiena's own "InStarTable" - confirmed via
   `NetworkCache.cpp`'s own header comment, "the number of in-stars
   between i and j equals ... traverse (i,h) followed by an incoming tie
   of h", i.e. #{h: i->h AND alter->h}, EXACTLY `shared_partners_osp()`'s
   own #{k: i->k, j->k} definition already certified for transtrip/
   cycle3/transties above; `shared_partners_otp()`=RSiena's own
   "TwoPathTable"):

       val = (n-2)*b0 - degree_out(alter)
             + 2*shared_partners_osp(i,alter) + 2*shared_partners_otp(i,alter)
             + (has_edge(alter,i) ? 1 : 0)
             - 2*(degree_out(i) - (has_edge(i,alter) ? 1 : 0))

   with the actual ministep delta = `has_edge(i,alter) ? -val : val'.
   `stat_saom_balance()`'s own per-tie term is a SEPARATE (but
   algebraically consistent) re-derivation of `tieStatistic()`, verified
   by directly transcribing its merge-iterator logic into a closed form:
   for an EXISTING tie (i,j), `tieStatistic()` = (n-2)*b0 - D(i,j), where
   D(i,j) = |{h!=i,j : x_ih != x_jh}| = (degree_out(i)-1) +
   (degree_out(j) - (has_edge(j,i)?1:0)) - 2*shared_partners_osp(i,j) (a
   symmetric-difference-of-out-neighborhoods count, algebraically
   |Oi|+|Oj|-2|Oi∩Oj| with Oi/Oj excluding i,j themselves - the merge-walk
   in `tieStatistic()` correctly excludes h=i,j via its own "flagged
   invalid actor" mechanism, confirmed by direct inspection of the C++).

   Certified via the STANDARD ego-level brute-force methodology (like
   transTies, unit 23, NOT gwesp()'s own weaker standard, unit 22) -
   `BalanceEffect` is a dedicated class, so its formula is expected to be
   the exact gradient of `s_i(x) = sum over i's own existing ties j of
   [(n-2)*b0 - D(i,j)]` - confirmed to actually pass, not merely assumed
   (`cscripts/test_nwsaom_mata.do`'s own unit 25 certify test).
*/
real scalar saom_balance_mean(pointer(class ErgmGraph scalar) rowvector Gbases){
	class ErgmGraph scalar G
	real scalar k, K, n, h, indeg, tempra, temprb

	tempra = 0
	temprb = 0
	K = cols(Gbases)
	for (k=1; k<=K; k++) {
		G = *Gbases[k]
		n = G.n
		for (h=1; h<=n; h++) {
			indeg = G.degree_in(h)
			tempra = tempra + 2*indeg*((n-1)-indeg)
		}
		temprb = temprb + n*(n-1)*(n-2)
	}
	return(tempra/temprb)
}

real rowvector stat_saom_balance(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, i, j, n, b0, D, tot

	n = G.n
	b0 = td.decay
	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		i = ties[k,1]
		j = ties[k,2]
		D = (G.degree_out(i)-1) + (G.degree_out(j) - (G.has_edge(j,i)?1:0)) - 2*G.shared_partners_osp(i,j)
		tot = tot + ((n-2)*b0 - D)
	}
	return(tot)
}

/* ===================================================================
   SaomCheckThetaBound: harmonisation unit 29 - real RSiena's own
   thetaBound safeguard, verified directly from source
   (`R/phase2.r`'s own per-ITERATION check, executed immediately after
   EVERY Robbins-Monro update step - `if (max(abs(z$theta[!z$fixed])) >
   z$thetaBound) { ... stop("thetaBound should be set higher.") }` in
   batch/non-interactive mode; `R/initializeFRAN.r`'s own
   `if(is.null(z$thetaBound)) z$thetaBound <- 50` gives the default
   this port reuses exactly).

   A real, disclosed gap this codebase had until now: NO estimator here
   previously had ANY such check, for ANY effect (confirmed by direct
   grep - zero prior matches for "thetaBound" anywhere in this file).
   Surfaced by harmonisation unit 28's own confirmed finding: a genuine
   identification failure (a saturation ridge in a co-evolution
   behavior effect's own joint parameter space, root-caused via a
   direct response-surface sweep, not assumed - see
   docs/SAOM_ROADMAP.md's own unit-28 entry for the full account) could
   previously run theta to +-100 or more before eventually crashing
   downstream with an opaque Mata conformability/missing-value error
   eventually. This does NOT fix any underlying identification problem
   - neither does real RSiena's own identical check - it only turns a
   silent, confusing runaway into an explicit, immediately diagnosable
   stop the moment it happens, exactly matching real RSiena's own
   behavior (`stop()` in batch mode) rather than continuing until some
   LATER, unrelated-looking failure. Called at the SAME point in EVERY
   phase-2 Robbins-Monro loop this file has (SaomEstimateRM()/
   SaomEstimateRMMulti()/SaomEstimateRMCoev()/SaomEstimateRMCoevMulti()) -
   immediately after `theta`'s own per-iteration update, before the
   next iteration's own simulation call, matching RSiena's own exact
   placement.

   Deliberately self-contained (errprintf()/exit() directly, NOT a call
   to unw_core.do's own error_handle()) - unw_core.do is not always
   sourced alongside unw_saom.do (e.g. cscripts/test_nwsaom_mata.do's
   own header only does "do unw_ergm.do" then "do unw_saom.do", never
   "do unw_core.do" - confirmed the hard way: an earlier version of
   this function called error_handle() directly and broke that whole
   test suite with "error_handle() not found", a real regression caught
   by running it, not assumed safe).
   =================================================================== */
void SaomCheckThetaBound(real rowvector theta, real scalar thetaBound) {
	if (max(abs(theta)) > thetaBound) {
		errprintf("SAOM estimation diverged during phase 2: a coefficient's own magnitude exceeded thetaBound (" + strofreal(thetaBound) + ") after a Robbins-Monro update step - matching real RSiena's own safeguard (R/phase2.r), which halts under the identical condition rather than let an update run away. This usually signals a genuine identification problem for this specific model/data combination (a real, diagnosed example: a co-evolution behavior effect's own joint parameter direction turning out to be an unidentified saturation ridge), not a software defect. Try a narrower effect specification, a larger/different dataset, or different starting values (theta0()/theta0beh()).\n")
		exit(498)
	}
}

/* ===================================================================
   SaomCheckCovarianceFinite: a second, related safeguard found while
   writing the book's own real endowment/creation example on real
   Glasgow data (harmonisation unit 28/29's own weak-identification
   diagnosis) - `thetaBound' catches theta itself running away during
   phase 2, but a genuinely weakly-identified model can ALSO leave
   theta comfortably under thetaBound while phase 3's own SEPARATE
   Jacobian (Dhat3, no diagonalize blend - see this file's own phase-3
   header comments) is too close to singular to invert reliably,
   producing missing values in `fit.V' that previously reached the
   user only as Stata's own opaque "estimates post: matrix has missing
   values" - a real, confirmed gap (not a hypothetical), found on real
   data, not a toy case. Same self-contained errprintf()/exit()
   convention as SaomCheckThetaBound() (no error_handle() dependency -
   see that function's own header comment for why), called right after
   `fit.V' is computed in every estimator.
   =================================================================== */
/* SaomCondTimeCheck(): under conditional estimation a simulated period
   that does not reach the observed distance within a million ministeps
   is abandoned and returns a missing time (native/saom_sim.c and the
   Mata simulators), as RSiena stops with "Unlikely to terminate this
   epoch: more than 1000000 steps" (EpochSimulation::runEpoch()). Before
   2026-10-01 such a period ran on indefinitely. */
/* SaomSetEngine(): which simulator a fit used, for e(engine) ("native"
   or "mata") and the note nwsaom prints when it is Mata (2026-10-01; a
   model the plugin covers must never fall back silently). */
void SaomSetEngine(real scalar native, string scalar reason) {
	external string scalar __nwsaom_engine, __nwsaom_engine_why
	__nwsaom_engine = (native ? "native" : "mata")
	__nwsaom_engine_why = (native ? "" : reason)
}

void SaomCondTimeCheck(real matrix T) {
	if (hasmissing(T)) {
		errprintf("SAOM simulation: a simulated period did not reach the observed distance within 1000000 ministeps (RSiena: Unlikely to terminate this epoch: more than 1000000 steps). The estimates probably diverged (e.g. a phase-1 derivative estimated from too few simulations, k0()); try the default k0(), other starting values (theta0()), or a narrower model.\n")
		exit(498)
	}
}

void SaomCheckCovarianceFinite(real matrix V) {
	if (hasmissing(V)) {
		errprintf("SAOM estimation's own phase-3 covariance matrix (e(V)) contains missing values - the phase-3 Jacobian was too close to singular to invert reliably. This is a further symptom of the SAME kind of weak identification thetaBound exists to catch - theta itself stayed within thetaBound's own limit, but the separate phase-3 covariance computation still broke down, which usually signals a genuine identification problem for this specific model/data combination, not a software defect. Try a narrower effect specification, a larger/different dataset, or different starting values (theta0()/theta0beh()).\n")
		exit(505)
	}
}

real rowvector change_saom_balance(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar n, b0, val

	n = G.n
	b0 = td.decay
	val = (n-2)*b0 - G.degree_out(j) ///
		+ 2*G.shared_partners_osp(i,j) + 2*G.shared_partners_otp(i,j) ///
		+ (G.has_edge(j,i) ? 1 : 0) ///
		- 2*(G.degree_out(i) - (G.has_edge(i,j) ? 1 : 0))
	return(G.has_edge(i,j) ? -val : val)
}

/* ===================================================================
   Interaction effects (RSiena's includeInteraction()): a two-way
   product term between two ALREADY-REGISTERED "dyadic" (tie-summed)
   network effects. Direct port of RSiena's real NetworkInteractionEffect
   (confirmed from RSiena/src/model/effects/NetworkInteractionEffect.cpp,
   cached at /private/tmp/rsiena_src/RSiena/): calculateContribution() =
   product of the two components' own calculateContribution();
   tieStatistic() = product of the two components' own tieStatistic() -
   a GENUINELY DIFFERENT formula for any component with ministep
   neighbor-spillover (transties/outoutass/ininass/outinass/inoutass/
   cycle4/balance - confirmed from RSiena's own real
   NetworkEffect::egoStatistic()/tieStatistic() vs
   calculateContribution() split, RSiena/src/model/effects/
   NetworkEffect.cpp), identical to it for every other (spillover-free)
   effect. The native/saom_sim.c port (TERMCODE_INTERACT2) mirrors this
   Mata implementation exactly - see that termcode's own #define comment
   and its saom_tie_stat()/saom_eval_change() header comments for the
   parallel account.

   Wire-protocol note: unw_ergm.do's own ErgmModel::addterm()/
   ErgmModel::full_change()/full_statistic() dispatch every term through
   a UNIFORM (G,[i,j,]td) signature with no access to the surrounding
   model M - so an interaction term cannot reach its own two component
   effects' chgfn/statfn pointers or td objects through that generic
   path (and unw_ergm.do is READ ONLY for this initiative - see this
   file's own header comment). Instead, EVERYTHING an interaction needs
   is packed into its OWN td at registration time (nwsaom.ado), reusing
   three existing ErgmTermData fields no SAOM main-effect term needs for
   anything else: td.sptype holds "nameA|nameB" (both component names,
   split on "|"); td.levels holds (decayA \ decayB) (2x1 - only
   gwesp/simcov/balance ever read a decay); td.attr holds (attrA \ attrB)
   stacked into ONE 2*n x 1 colvector (rows 1..n = component A's own
   attribute array, or a harmless all-zero placeholder if component A
   doesn't use one; rows n+1..2n = component B's) - n is always
   G.n, so unpacking needs no extra bookkeeping. This is a
   self-contained, purely-additive convention entirely on nwsaom's own
   side, touching no unw_ergm.do field's existing meaning for any other
   term.
   =================================================================== */

/* _saom_tiestat: tieStatistic(ego,alter) for a SINGLE component
   effect, named `nm' - a literal copy of that effect's own tie-loop
   summand in its stat_saom_X()/stat_X() function above (not
   re-derived), i.e. exactly what that function sums over G.all_ties()
   already. Restricted to the "dyadic" termcode subset that has a
   well-defined tieStatistic() at all - nwsaom.ado's own interact()
   eligibility check rejects every node-level/"ego effect" name
   (indegpopularity, outactivity, outpopularity, inactivity, isolatenet,
   outiso, antiiniso, antiiniso2, inplus3) before an interaction naming
   one of them can ever reach here. */
real scalar _saom_tiestat(class ErgmGraph scalar G, string scalar nm,
	real colvector a, real scalar decay, real scalar ego, real scalar alter, | real scalar center){

	real scalar nterm, b0, D

	if (nm == "outdegree") return(1)
	if (nm == "reciprocity") return(G.has_edge(alter, ego) ? 1 : 0)
	if (nm == "nodematch") return(a[ego] == a[alter] ? 1 : 0)
	if (nm == "nodecov") return(a[ego] + a[alter])
	if (nm == "nodeicov") return(a[alter])
	if (nm == "nodeocov") return(a[ego])
	if (nm == "transtrip" | nm == "transmedtrip") return(G.shared_partners_isp(ego, alter))
	if (nm == "cycle3") return(G.shared_partners_otp(alter, ego))
	if (nm == "simcov") return(1 - abs(a[ego] - a[alter]) / decay - (args() >= 7 ? center : 0))
	if (nm == "transrectrip") return(G.has_edge(alter, ego) ? G.shared_partners_otp(ego, alter) : 0)
	if (nm == "outoutass") return(G.degree_out(ego) * G.degree_out(alter))
	if (nm == "ininass") return(G.degree_in(ego) * G.degree_in(alter))
	if (nm == "outinass") return(G.degree_out(ego) * G.degree_in(alter))
	if (nm == "inoutass") return(G.degree_in(ego) * G.degree_out(alter))
	if (nm == "cycle4") return(0.25 * _saom_cycle4_threepaths(G, ego, alter))
	if (nm == "gwesp") return(gw_kernel(G.shared_partners_otp(ego, alter), decay))
	if (nm == "transties") return(G.shared_partners_otp(ego, alter) >= 1 ? 1 : 0)
	if (nm == "balance") {
		nterm = G.n - 2
		b0 = decay
		D = (G.degree_out(ego) - 1) + (G.degree_out(alter) - (G.has_edge(alter, ego) ? 1 : 0)) - 2 * G.shared_partners_osp(ego, alter)
		return(nterm * b0 - D)
	}
	return(0)		// node-level/"ego effect" name - rejected upstream, never reached in practice
}

/* _saom_tiechange: calculateContribution(alter), the ministep CHANGE
   contribution for a single component effect `nm' - a literal copy of
   that effect's own change_saom_X()/change_X() Mata function above (not
   re-derived), including the neighbor-spillover loops those seven
   termcodes (transties/outoutass/ininass/outinass/inoutass/cycle4/
   balance) genuinely have and _saom_tiestat() above deliberately does
   NOT (see this section's own header comment for why these are two
   different functions, per RSiena's own real source). */
real scalar _saom_tiechange(class ErgmGraph scalar G, string scalar nm,
	real colvector a, real scalar decay, real scalar i, real scalar j, | real scalar center){

	real scalar tied, delta, chg, egodeg, alterdeg, ldegree, neighborsum, oldb, b0, n, val, k, h
	real rowvector nb

	tied = G.has_edge(i, j)

	if (nm == "outdegree") return(tied ? -1 : 1)
	if (nm == "reciprocity") {
		if (!G.has_edge(j, i)) return(0)
		return(tied ? -1 : 1)
	}
	if (nm == "nodematch") {
		if (a[i] != a[j]) return(0)
		return(tied ? -1 : 1)
	}
	if (nm == "nodecov") {
		delta = a[i] + a[j]
		return(tied ? -delta : delta)
	}
	if (nm == "nodeicov") return(tied ? -a[j] : a[j])
	if (nm == "nodeocov") return(tied ? -a[i] : a[i])
	if (nm == "transtrip") {
		delta = G.shared_partners_otp(i, j) + G.shared_partners_osp(i, j)
		return(tied ? -delta : delta)
	}
	if (nm == "transmedtrip") {
		delta = G.shared_partners_isp(i, j)
		return(tied ? -delta : delta)
	}
	if (nm == "cycle3") {
		delta = G.shared_partners_otp(j, i)
		return(tied ? -delta : delta)
	}
	if (nm == "simcov") {
		delta = 1 - abs(a[i] - a[j]) / decay - (args() >= 7 ? center : 0)
		return(tied ? -delta : delta)
	}
	if (nm == "transrectrip") {
		delta = G.has_edge(j, i) ? G.shared_partners_otp(i, j) : 0
		nb = G.neighbors_out(i)
		for (k=1; k<=cols(nb); k++) {
			h = nb[k]
			if (h == j) continue
			if (G.has_edge(h, i) & G.has_edge(j, h)) delta++
		}
		return(tied ? -delta : delta)
	}
	if (nm == "outoutass") {
		ldegree = G.degree_out(i)
		alterdeg = G.degree_out(j)
		nb = G.neighbors_out(i)
		neighborsum = 0
		for (k=1; k<=cols(nb); k++) neighborsum = neighborsum + G.degree_out(nb[k])
		if (tied) return(-((neighborsum - alterdeg) + ldegree*alterdeg))
		return(neighborsum + (ldegree+1)*alterdeg)
	}
	if (nm == "ininass") {
		egodeg = G.degree_in(i)
		alterdeg = G.degree_in(j)
		delta = egodeg * (tied ? alterdeg : alterdeg + 1)
		return(tied ? -delta : delta)
	}
	if (nm == "outinass") {
		ldegree = G.degree_out(i)
		alterdeg = G.degree_in(j)
		nb = G.neighbors_out(i)
		neighborsum = 0
		for (k=1; k<=cols(nb); k++) neighborsum = neighborsum + G.degree_in(nb[k])
		if (tied) return(-((neighborsum - alterdeg) + ldegree*alterdeg))
		return(neighborsum + (ldegree+1)*(alterdeg+1))
	}
	if (nm == "inoutass") {
		egodeg = G.degree_in(i)
		alterdeg = G.degree_out(j)
		delta = egodeg * alterdeg
		return(tied ? -delta : delta)
	}
	if (nm == "cycle4") {			// UNSCALED (no *0.25) - matches change_saom_cycle4()/RSiena's own real FourCyclesEffect::calculateContribution() exactly (unlike this SAME effect's own tieStatistic(), which _saom_tiestat() above DOES scale by 0.25 - a real, previously-caught asymmetry, see native/saom_sim.c's own TERMCODE_CYCLE4 comment)
		delta = _saom_cycle4_threepaths(G, i, j)
		return(tied ? -delta : delta)
	}
	if (nm == "gwesp") {
		delta = gw_kernel(G.shared_partners_otp(i, j), decay)
		return(tied ? -delta : delta)
	}
	if (nm == "transties") {
		delta = tied ? -1 : 1
		chg = delta * (G.shared_partners_otp(i, j) >= 1)
		nb = G.neighbors_out(j)
		for (k=1; k<=cols(nb); k++) {
			b0 = nb[k]
			if (b0 == i) continue
			if (!G.has_edge(i, b0)) continue
			oldb = G.shared_partners_otp(i, b0)
			chg = chg + ((oldb+delta>=1) - (oldb>=1))
		}
		return(chg)
	}
	if (nm == "balance") {
		n = G.n
		b0 = decay
		val = (n-2)*b0 - G.degree_out(j) ///
			+ 2*G.shared_partners_osp(i,j) + 2*G.shared_partners_otp(i,j) ///
			+ (G.has_edge(j,i) ? 1 : 0) ///
			- 2*(G.degree_out(i) - (tied ? 1 : 0))
		return(tied ? -val : val)
	}
	return(0)		// node-level/"ego effect" name - rejected upstream, never reached in practice
}

/* SaomBuildInteractTd(): nwsaom.ado's own registration-time helper -
   looks up the two (or three, "expansion" 2026-09-02 - see
   stat_saom_interact()'s own header comment) named component effects
   among M's ALREADY-ADDED terms (by name; every one must already be
   registered as its own main-effect term, giving a clear error
   otherwise rather than ever guessing) and packs tdout: td.sptype =
   "nameA|nameB" (two-way) or "nameA|nameB|nameC" (three-way, nameC
   passed as ""for two-way - the OMITTED case, distinct from an empty
   name being an error), td.levels = (decayA \ decayB [\ decayC]),
   td.attr = (attrA \ attrB [\ attrC]) stacked into 2*n or 3*n rows (a
   zero-filled placeholder for whichever component does not use an
   attribute array - every eligible name has rows(attr) EITHER 0
   (unused) or exactly n, so this check is unambiguous). `n' is the
   caller's own actor count (not re-derived from G, since this runs at
   REGISTRATION time, before any per-model G object need be in scope
   here). */
/* _SaomInteractComponent(): the term instance an interact() component
   names. A component is either an effect type (M.names: "nodematch",
   "transtrip", ...), which must then occur exactly once, or a
   coefficient name (M.coefnames: "samex_smoke1", "egox_alcohol1",
   ...), which names one instance when a covariate effect is given for
   several variables (2026-10-01). Returns the instance index; *type
   receives the instance's effect type. */
real scalar _SaomInteractComponent(class ErgmModel scalar M, string scalar nm, string scalar type) {
	real scalar si, found, nfound, ci

	found = 0
	nfound = 0
	for (si=1; si<=M.nterms; si++) {
		if (M.names[si] == nm) {
			nfound++
			if (found == 0) found = si
		}
	}
	if (nfound > 1) {
		errprintf("nwsaom: interact() names the effect type '" + nm + "', which this model has for several variables; name one by its coefficient name as shown in e(b) (e.g. samex_smoke1#transtrip).\n")
		exit(error(198))
	}
	if (found == 0) {
		ci = 0
		for (si=1; si<=M.nterms; si++) {
			if (M.npar[si] == 1 & M.coefnames[ci + 1] == nm) found = si
			ci = ci + M.npar[si]
		}
	}
	if (found == 0) {
		errprintf("nwsaom: interact() names '" + nm + "' as a component effect, but it is not itself included in this model - add it as its own main effect first.\n")
		exit(error(198))
	}
	type = M.names[found]
	return(found)
}

real scalar _saom_center0(class ErgmTermData scalar td) {
	return(td.center < . ? td.center : 0)
}

/* SaomSimMean(): RSiena's similarity mean of a covariate
   (rangeAndSimilarity() in sienaDataCreate.r): the mean of
   1 - |x_i - x_j| / range over all ordered pairs i != j; 0 for a
   constant covariate. simX/simcov() subtracts it from every tie's
   similarity. */
real scalar SaomSimMean(real colvector x) {
	real scalar n, r, i, tot

	n = rows(x)
	r = max(x) - min(x)
	if (r == 0 | n < 2) return(0)
	tot = 0
	for (i=1; i<=n; i++) tot = tot + sum(1 :- abs(x[i] :- x) :/ r) - 1
	return(tot / (n * (n - 1)))
}

void SaomBuildInteractTd(class ErgmModel scalar M, real scalar n,
	string scalar nameA, string scalar nameB, string scalar nameC, class ErgmTermData scalar tdout){

	real scalar subA, subB, subC, threeway
	string scalar tA, tB, tC
	class ErgmTermData scalar tdA, tdB, tdC

	threeway = (nameC != "")
	tA = ""
	tB = ""
	tC = ""
	subA = _SaomInteractComponent(M, nameA, tA)
	subB = _SaomInteractComponent(M, nameB, tB)
	subC = (threeway ? _SaomInteractComponent(M, nameC, tC) : 0)
	tdA = *M.td[subA]
	tdB = *M.td[subB]
	// td.sptype holds the component TYPES (stat/change dispatch on them);
	// td.levels the components' decays, followed by the component
	// instance indices (SaomNativeSetup() uses those, so that the right
	// instance is found when an effect type occurs several times)
	if (threeway) {
		tdC = *M.td[subC]
		tdout.sptype = tA + "|" + tB + "|" + tC
		tdout.levels = (tdA.decay \ tdB.decay \ tdC.decay \ subA \ subB \ subC \
			_saom_center0(tdA) \ _saom_center0(tdB) \ _saom_center0(tdC))
		tdout.attr = ((rows(tdA.attr) == n ? tdA.attr : J(n, 1, 0)) \
			(rows(tdB.attr) == n ? tdB.attr : J(n, 1, 0)) \
			(rows(tdC.attr) == n ? tdC.attr : J(n, 1, 0)))
	}
	else {
		tdout.sptype = tA + "|" + tB
		tdout.levels = (tdA.decay \ tdB.decay \ subA \ subB \ _saom_center0(tdA) \ _saom_center0(tdB))
		tdout.attr = ((rows(tdA.attr) == n ? tdA.attr : J(n, 1, 0)) \ (rows(tdB.attr) == n ? tdB.attr : J(n, 1, 0)))
	}
}

/* stat_saom_interact()/change_saom_interact(): the TERMCODE_INTERACT2
   registration pair (nwsaom.ado's own addterm() call), unpacking td's
   own "nameA|nameB" or "nameA|nameB|nameC" (td.sptype),
   (decayA \ decayB [\ decayC]) (td.levels), and stacked
   (attrA \ attrB [\ attrC]) (td.attr, 2*G.n or 3*G.n rows) - see this
   section's own header comment for why this packing exists. Three-way
   interactions ("expansion", 2026-09-02 - RSiena's own OPTIONAL third
   effect in includeInteraction(), confirmed directly from its real
   source: NetworkInteractionEffect::tieStatistic() simply multiplies
   in a third component's own tieStatistic() when present, no other
   change to the formula) are detected via cols(nms) == 5 (tokens()
   returns the "|" delimiters themselves as their own tokens - real
   names live at positions 1/3/5, not 1/2/3, confirmed directly). Mata
   only - native/saom_sim.c's own TERMCODE_INTERACT2 wire protocol only
   has room for two component slot references (attridx/p1); a genuine
   third slot needs new wire-protocol fields, a disclosed follow-on -
   see SaomNativeSetup()'s own eligible=0 gate for cols(nms)>3. */
/* the c-th component's centering constant (simcov's similarity mean),
   stored after the decays and instance indices in td.levels; 0 for
   interactions registered before 2026-10-01 */
real scalar _saom_ixcenter(class ErgmTermData scalar td, real scalar c, real scalar threeway) {
	real scalar k
	k = (threeway ? 3 : 2)
	if (rows(td.levels) < 3*k) return(0)
	return(td.levels[2*k + c])
}

real rowvector stat_saom_interact(class ErgmGraph scalar G, class ErgmTermData scalar td){
	string rowvector nms
	real matrix ties
	real scalar n, k, tot, threeway
	real colvector aA, aB, aC

	nms = tokens(td.sptype, "|")
	threeway = (cols(nms) == 5)
	n = G.n
	aA = td.attr[1::n]
	aB = td.attr[(n+1)::(2*n)]
	if (threeway) aC = td.attr[(2*n+1)::(3*n)]
	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		tot = tot + _saom_tiestat(G, nms[1], aA, td.levels[1], ties[k,1], ties[k,2], _saom_ixcenter(td, 1, threeway)) *
			_saom_tiestat(G, nms[3], aB, td.levels[2], ties[k,1], ties[k,2], _saom_ixcenter(td, 2, threeway)) *
			(threeway ? _saom_tiestat(G, nms[5], aC, td.levels[3], ties[k,1], ties[k,2], _saom_ixcenter(td, 3, threeway)) : 1)
	}
	return(tot)
}
real rowvector change_saom_interact(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	string rowvector nms
	real scalar n, threeway
	real colvector aA, aB, aC
	real scalar cvA, cvB, cvC

	nms = tokens(td.sptype, "|")
	threeway = (cols(nms) == 5)
	n = G.n
	aA = td.attr[1::n]
	aB = td.attr[(n+1)::(2*n)]
	cvA = _saom_tiechange(G, nms[1], aA, td.levels[1], i, j, _saom_ixcenter(td, 1, threeway))
	cvB = _saom_tiechange(G, nms[3], aB, td.levels[2], i, j, _saom_ixcenter(td, 2, threeway))
	// RSiena (NetworkInteractionEffect::calculateContribution(), then
	// NetworkVariable::calculateTieFlipContributions()): the product of
	// the components' contributions for CREATING the tie, negated once
	// when the tie exists. The components' changes are signed (negative
	// for a withdrawal), so for two components their product must be
	// negated again (for three the signs already give -1). Before
	// 2026-10-01 a two-way interaction had the wrong sign on withdrawals.
	if (!threeway) return((G.has_edge(i, j) ? -1 : 1) * cvA * cvB)
	aC = td.attr[(2*n+1)::(3*n)]
	cvC = _saom_tiechange(G, nms[5], aC, td.levels[3], i, j, _saom_ixcenter(td, 3, threeway))
	return(cvA * cvB * cvC)
}

/* ===================================================================
   SaomCopyGraph: deep-copy an ErgmGraph's edge structure onto a fresh
   graph of the same size/directedness - SaomEstimateRM needs a clean
   restart from the OBSERVED starting-wave network for every phase-2/
   phase-3 simulation run (runs are never chained), and ErgmGraph has
   reference semantics (asarray-backed), so a plain `Gcopy = G` would
   alias the same underlying adjacency storage, not copy it.
   =================================================================== */
void SaomCopyGraph(class ErgmGraph scalar Gsrc, class ErgmGraph scalar Gdst) {
	real matrix ties
	real scalar k

	Gdst.init(Gsrc.n, Gsrc.directed)
	ties = Gsrc.all_ties()
	for (k=1; k<=rows(ties); k++) {
		Gdst.toggle(ties[k,1], ties[k,2])
	}
}

/* ===================================================================
   SaomCountDiffering: symmetric difference (Hamming distance) between
   two same-node-set directed graphs - the rate's statistic in
   SaomEstimateNet() (simulated end network vs the period's starting
   observation; the target is the observed distance between the two
   waves, RSiena's "distance"). Equals the sum of
   nwturnover's own "dissolved" and "formed" tie counts, computed
   directly here rather than via that command since only the scalar
   count is needed, not its full per-node/Jaccard reporting.
   =================================================================== */
real scalar SaomCountDiffering(class ErgmGraph scalar G1, class ErgmGraph scalar G2) {
	real matrix t1, t2
	real scalar k, cnt

	t1 = G1.all_ties()
	t2 = G2.all_ties()
	cnt = 0
	for (k=1; k<=rows(t1); k++) if (!G2.has_edge(t1[k,1], t1[k,2])) cnt++
	for (k=1; k<=rows(t2); k++) if (!G1.has_edge(t2[k,1], t2[k,2])) cnt++
	return(cnt)
}

/* ===================================================================
   SaomCovariateDifferingSum (harmonisation unit 172): the OBSERVED
   target for a covariate-dependent rate effect's own coefficient -
   verified directly from RSiena's real C++ source
   (StatisticCalculator.cpp's calculateNetworkRateStatistics(),
   "covariate" rateType branch): sum, over every tie in the wave-1/
   wave-2 SYMMETRIC DIFFERENCE network, of the covariate value at that
   tie's own tail ("iter.ego()" in RSiena's own directed-network
   iterator convention - the acting/initiating actor, i.e. this
   function's own `t1[k,1]'/`t2[k,1]', exactly mirroring
   SaomCountDiffering()'s own unweighted loop shape one level up but
   weighted by ratecovattr[tail] instead of counting 1 per differing
   dyad. SaomEstimateRM() calls this SAME function again on each
   simulated interval's own (Gobs_start, Gwork-after-simulating) pair for
   the simulated-side counterpart of this moment - NOT an accumulated
   per-toggle sum (a real, disclosed design correction: an earlier
   version of this unit accumulated ratecovattr[actor] over every
   ACCEPTED ministep during simulation, mirroring how nchanges/rate_hist
   already work for the plain rate parameter - direct testing found this
   diverges wildly from the net-difference quantity here whenever a
   simulated interval revisits/reverts the same dyad multiple times
   (observed directly: 179 accumulated vs. 23 net-difference on the same
   interval), which real RSiena's own StatisticCalculator.cpp settles
   unambiguously - it operates on `pDifference', the FINAL symmetric
   difference, never an accumulated running total. Fixed by calling this
   same function on the simulated graph too, mirroring exactly how
   `M.full_statistic(Gwork)' (a final-state snapshot, not an
   accumulator) already works for the eval parameters' own deviation).
   =================================================================== */
real rowvector SaomCovariateDifferingSum(class ErgmGraph scalar G1, class ErgmGraph scalar G2,
	real matrix ratecovattr) {

	real matrix t1, t2
	real scalar k
	real rowvector s

	// one column per ratecov() variable, one entry per column
	t1 = G1.all_ties()
	t2 = G2.all_ties()
	s = J(1, cols(ratecovattr), 0)
	for (k=1; k<=rows(t1); k++) if (!G2.has_edge(t1[k,1], t1[k,2])) s = s + ratecovattr[t1[k,1],.]
	for (k=1; k<=rows(t2); k++) if (!G1.has_edge(t2[k,1], t2[k,2])) s = s + ratecovattr[t2[k,1],.]
	return(s)
}

/* ===================================================================
   Missing data (harmonisation unit 35, docs/SAOM_ROADMAP.md's own
   unit-35 entry has the full RSiena Section 5.3.2 source account).
   Two independent mechanisms, matching RSiena's own real design:

   (1) IMPUTATION (SaomImputeNetworkWave/SaomImputeBehaviorWave below) -
   fills in a determinate STARTING value for every missing dyad/actor
   BEFORE simulation begins, so ministeps have an ordinary, fully-
   determined graph/behavior to start from (composition change, by
   contrast, restricts WHO can act; missing data does not restrict
   ministep eligibility at all - every actor/dyad participates
   normally in simulation once imputed). Network: last-observation-
   carried-forward per dyad (RSiena's own convention), 0 if never
   observed. Behavior: previous observation, else next observation,
   else the observationwise (cross-sectional, same-wave) mode.

   (2) STATISTIC MASKING (SaomMaskedStatistic/SaomMaskedBehaviorStatistic
   below) - RSiena's manual: "the tie variable ... must provide valid
   data both at the beginning and at the end of a period for being
   counted in the respective statistics." A dyad/actor missing at
   EITHER endpoint wave of a period is excluded from BOTH the observed
   target statistic AND every simulated replicate's own final
   statistic for that period, so the moment condition (target minus
   simulated) is not biased by the exclusion. Network: excluded dyads
   are forced to 0 (matching sparse-network absence as the neutral
   default). Behavior: RSiena's own rule operates on CENTERED values
   ("the value is replaced by 0 ... equivalent to the overall mean") -
   reproduced here at the RAW-value level (excluded actors' values are
   set to Beh.overallMean before computing the statistic) rather than
   by rewriting each behavior effect's own formula to work in centered
   space, since "raw value = overallMean" is exactly "centered value =
   0" for ANY effect, uniformly, with zero changes to already-certified
   stat_saom_X()/change_saom_X() code.

   Both masking helpers build a fresh scratch copy (SaomCopyGraph() /
   a fresh SaomBehavior) and call the EXISTING, unmodified
   M.full_statistic()/Mbeh.full_statistic() on it - reusing every
   already-certified term's own statistic function rather than adding
   per-term masking logic, the same reuse strategy this file already
   uses throughout (e.g. SaomCopyGraph() + M.full_statistic() for
   every ordinary phase-2/3 simulated-statistic computation above).
   =================================================================== */
/* SaomCountDifferingMasked: the RATE parameter's own target statistic
   (SaomCountDiffering above), but excluding masked dyads from the
   count - matching RSiena's own "valid at both endpoint waves" rule
   applied to the rate's own target/simulated statistic, not just the
   eval-parameter one. */
real scalar SaomCountDifferingMasked(class ErgmGraph scalar G1, class ErgmGraph scalar G2,
	real matrix missMaskPeriod) {

	real matrix t1, t2
	real scalar k, cnt

	t1 = G1.all_ties()
	t2 = G2.all_ties()
	cnt = 0
	for (k=1; k<=rows(t1); k++) {
		if (missMaskPeriod[t1[k,1], t1[k,2]] != 0) continue
		if (!G2.has_edge(t1[k,1], t1[k,2])) cnt++
	}
	for (k=1; k<=rows(t2); k++) {
		if (missMaskPeriod[t2[k,1], t2[k,2]] != 0) continue
		if (!G1.has_edge(t2[k,1], t2[k,2])) cnt++
	}
	return(cnt)
}

/* SaomMaskToDyadList: converts an n x n 0/1 missingness mask into a
   sparse (i,j) dyad list - harmonisation unit 35's own NATIVE port
   needs this exactly ONCE per fit (the wire protocol's own sparse
   mv1/mv2 convention, native/saom_sim.c's "MISSING DATA" header
   section), NOT once per native call. A real, measured performance bug
   found via direct benchmark, not assumed safe: the FIRST version of
   this conversion lived INSIDE SaomSimulateIntervalNative() itself
   (recomputed on every one of the hundreds-to-thousands of native
   calls a single Robbins-Monro fit makes) and used matrix-growing
   concatenation (`missdyads = missdyads \ (i,j)`) - fine for a ONE-TIME
   cost, but O(n^2) reallocation repeated per call completely erased
   the native speed advantage (a direct benchmark found ZERO improvement
   over the pure-Mata fallback, contradicting this unit's own explicit
   purpose). Fixed by hoisting this conversion here, called once by each
   estimator right where `cfg = SaomNativeSetup(M)' is already decided
   once per fit (not per call) - the SAME `use_native'-gated, decide-
   once-never-in-a-loop discipline docs/SAOM_ARCHITECTURE.md's own
   "Native backend" section already documents for every OTHER native
   dispatch decision in this file. */
real matrix SaomMaskToDyadList(real matrix missMask) {
	real matrix out
	real scalar n, i, j

	n = rows(missMask)
	out = J(0, 2, 0)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (missMask[i,j] != 0) out = out \ (i,j)
		}
	}
	return(out)
}

/* SaomBuildMaskedGraph: a scratch copy of G with every masked dyad
   forced to 0 - the shared primitive behind SaomMaskedStatistic()
   below AND SaomMaskedBehaviorStatistic() further down this file.
   Exposing this as its own function (rather than leaving the masking
   loop inlined only inside SaomMaskedStatistic(), as it originally
   was) was a real, needed fix found via a direct certification
   failure: a network-dependent behavior effect (avAlt) read the RAW,
   UNMASKED graph when SaomMaskedBehaviorStatistic() only masked its
   own VALUES, so a corrupted/masked dyad could still corrupt an
   unrelated (behavior-unmasked) actor's own avAlt reading via its
   alters' true (masked) ties - see SaomMaskedBehaviorStatistic()'s own
   header comment for the full account. */
class ErgmGraph scalar SaomBuildMaskedGraph(class ErgmGraph scalar G, real matrix missMaskPeriod) {
	class ErgmGraph scalar Gm
	real scalar n, i, j

	n = G.n
	Gm = ErgmGraph()
	SaomCopyGraph(G, Gm)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (missMaskPeriod[i,j] != 0 & Gm.has_edge(i,j)) Gm.toggle(i,j)
		}
	}
	return(Gm)
}

real rowvector SaomMaskedStatistic(class ErgmGraph scalar G, class ErgmModel scalar M,
	real matrix missMaskPeriod) {

	return(M.full_statistic(SaomBuildMaskedGraph(G, missMaskPeriod)))
}

/* SaomBuildLostTiesGraph()/SaomBuildGainedTiesGraph(): harmonisation unit
   167 (network-side endowment/creation) - the network-side analogue of
   SaomBuildMaskedGraph() above, built the same way (a scratch
   SaomCopyGraph() then selectively toggled), but for a different
   purpose: constructing the two DERIVED networks RSiena's own real
   `NetworkEffect.cpp' evaluates an endowment/creation term's own
   observed statistic on (`statistic(pSummationTieNetwork)', X=initial/
   Y=lost-ties-network for endowment, X=initial/Y=gained-ties-network for
   creation - see SaomNetworkPatchEndowCreation()'s own header comment
   for the full citation). "Lost ties" = tied in Gstart, untied in Gend
   (a withdrawal); "gained ties" = untied in Gstart, tied in Gend (a
   creation) - each dyad visited exactly once (no double-toggle risk),
   directed/undirected branching matching stat_hamming()'s own established
   dyad-enumeration convention in unw_ergm.do. */
class ErgmGraph scalar SaomBuildLostTiesGraph(class ErgmGraph scalar Gstart, class ErgmGraph scalar Gend) {
	class ErgmGraph scalar Gl
	real scalar n, i, j

	n = Gstart.n
	Gl = ErgmGraph()
	SaomCopyGraph(Gstart, Gl)
	if (Gl.directed) {
		for (i=1; i<=n; i++) {
			for (j=1; j<=n; j++) {
				if (i==j) continue
				if (Gl.has_edge(i,j) & !(Gstart.has_edge(i,j) & !Gend.has_edge(i,j))) Gl.toggle(i,j)
			}
		}
	}
	else {
		for (i=1; i<=n-1; i++) {
			for (j=i+1; j<=n; j++) {
				if (Gl.has_edge(i,j) & !(Gstart.has_edge(i,j) & !Gend.has_edge(i,j))) Gl.toggle(i,j)
			}
		}
	}
	return(Gl)
}

class ErgmGraph scalar SaomBuildGainedTiesGraph(class ErgmGraph scalar Gstart, class ErgmGraph scalar Gend) {
	class ErgmGraph scalar Gg
	real scalar n, i, j

	n = Gend.n
	Gg = ErgmGraph()
	SaomCopyGraph(Gend, Gg)
	if (Gg.directed) {
		for (i=1; i<=n; i++) {
			for (j=1; j<=n; j++) {
				if (i==j) continue
				if (Gg.has_edge(i,j) & !(Gend.has_edge(i,j) & !Gstart.has_edge(i,j))) Gg.toggle(i,j)
			}
		}
	}
	else {
		for (i=1; i<=n-1; i++) {
			for (j=i+1; j<=n; j++) {
				if (Gg.has_edge(i,j) & !(Gend.has_edge(i,j) & !Gstart.has_edge(i,j))) Gg.toggle(i,j)
			}
		}
	}
	return(Gg)
}

/* SaomNetworkPatchEndowCreation(): replaces the endowment/creation slots
   of an already-computed statistic vector `stat' (from the end network)
   by RSiena's endowment and creation statistics (NetworkEffect.cpp's
   endowmentStatistic()/creationStatistic()):
     endowment: minus the sum, over ties LOST between Gstart and Gend, of
                the effect's tie statistic in the STARTING network;
     creation:  the sum, over ties GAINED, of the tie statistic in the END
                network.
   Tie statistics: 1 for outdegree, x_ji for reciprocity. On s50 waves
   1-2 this gives RSiena's targets exactly (reciprocity endowment -35,
   creation 27; outdegree endowment -56 and creation 36 on the isoiso
   test data). A term with another name falls back to evaluating its
   statistic on the lost-/gained-ties network. (Before 2026-10-01 every
   term used that fallback: right for the outdegree count up to sign,
   but for reciprocity it counted dyads lost or gained in BOTH directions
   - 14 and 10 on s50 - a statistic that barely responds to the
   parameter; and the positive sign of the outdegree endowment count
   made its phase-1 derivative negative.) */
real rowvector SaomNetworkPatchEndowCreation(class ErgmModel scalar M, real rowvector fntype,
	real rowvector stat, class ErgmGraph scalar Gstart, class ErgmGraph scalar Gend) {

	class ErgmGraph scalar Glost, Ggained
	real rowvector out, part
	real matrix ties
	real scalar t, k, pos, built_lost, built_gained, recip, v
	string scalar nm

	out = stat
	built_lost = 0
	built_gained = 0
	pos = 1
	for (t=1; t<=M.nterms; t++) {
		if (fntype[t] == 0) {
			pos = pos + M.npar[t]
			continue
		}
		nm = M.names[t]
		if (strpos(nm, "outdegree") == 1 | strpos(nm, "reciprocity") == 1) {
			recip = (strpos(nm, "reciprocity") == 1)
			v = 0
			if (fntype[t] == 1) {
				ties = Gstart.all_ties()
				for (k=1; k<=rows(ties); k++) {
					if (Gend.has_edge(ties[k,1], ties[k,2])) continue
					v = v - (recip ? Gstart.has_edge(ties[k,2], ties[k,1]) : 1)
				}
			}
			else {
				ties = Gend.all_ties()
				for (k=1; k<=rows(ties); k++) {
					if (Gstart.has_edge(ties[k,1], ties[k,2])) continue
					v = v + (recip ? Gend.has_edge(ties[k,2], ties[k,1]) : 1)
				}
			}
			out[pos] = v
		}
		else if (fntype[t] == 1) {
			if (!built_lost) {
				Glost = SaomBuildLostTiesGraph(Gstart, Gend)
				built_lost = 1
			}
			part = (*M.statfn[t])(Glost, *M.td[t])
			for (k=1; k<=M.npar[t]; k++) out[pos+k-1] = part[k]
		}
		else {
			if (!built_gained) {
				Ggained = SaomBuildGainedTiesGraph(Gstart, Gend)
				built_gained = 1
			}
			part = (*M.statfn[t])(Ggained, *M.td[t])
			for (k=1; k<=M.npar[t]; k++) out[pos+k-1] = part[k]
		}
		pos = pos + M.npar[t]
	}
	return(out)
}

/* SaomImputeNetworkWave: mutates G in place, forcing every dyad marked
   missing (missMask[i,j]!=0) to `lastObserved's own current value
   (last-observation-carried-forward - lastObserved starts at all-0,
   matching "impute 0 if a wave-1 dyad is missing / never yet
   observed"), and returns an UPDATED lastObserved reflecting every
   dyad that WAS observed at this wave (for the next wave's own call).
   Called once per wave, in temporal order, by the .ado data-prep
   layer - not relied on inside any estimator, since starting graphs
   are built once, before estimation, exactly like every other
   ErgmGraph this file's estimators receive already-built. */
real matrix SaomImputeNetworkWave(class ErgmGraph scalar G, real matrix missMask,
	real matrix lastObserved) {

	real scalar n, i, j, curval
	real matrix updated

	n = G.n
	updated = lastObserved
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (missMask[i,j] == 0) updated[i,j] = G.has_edge(i,j)
			else {
				curval = G.has_edge(i,j)
				if (curval != lastObserved[i,j]) G.toggle(i,j)
			}
		}
	}
	return(updated)
}

/* SaomBehaviorModeAtWave: observationwise mode - the mode of every
   OTHER actor's own observed value at wave `w' (used only as the
   last-resort fallback for an actor missing at every single wave). */
real scalar SaomBehaviorModeAtWave(pointer(real colvector) rowvector rawBeh,
	pointer(real colvector) rowvector missBeh, real scalar w, real scalar n) {

	real colvector allvals, uniq
	real scalar i, k, best, bestcount, cnt

	allvals = J(0, 1, 0)
	for (i=1; i<=n; i++) {
		if ((*missBeh[w])[i] == 0) allvals = allvals \ (*rawBeh[w])[i]
	}
	if (rows(allvals) == 0) return(0)
	uniq = uniqrows(allvals)
	best = uniq[1]
	bestcount = 0
	for (k=1; k<=rows(uniq); k++) {
		cnt = sum(allvals :== uniq[k])
		if (cnt > bestcount) {
			bestcount = cnt
			best = uniq[k]
		}
	}
	return(best)
}

/* SaomImputeBehaviorWave: imputed values for ALL actors at wave `w' -
   previous observation (scanning backward), else next observation
   (scanning forward - unlike the network side, this needs visibility
   across ALL waves at once, since "next" can be any later wave), else
   the observationwise mode. Called once per wave by the .ado data-prep
   layer, exactly like SaomImputeNetworkWave. */
real colvector SaomImputeBehaviorWave(pointer(real colvector) rowvector rawBeh,
	pointer(real colvector) rowvector missBeh, real scalar nwaves, real scalar n,
	real scalar w) {

	real colvector imputed
	real scalar i, wprime, found

	imputed = J(n, 1, 0)
	for (i=1; i<=n; i++) {
		if ((*missBeh[w])[i] == 0) {
			imputed[i] = (*rawBeh[w])[i]
			continue
		}
		found = 0
		for (wprime=w-1; wprime>=1; wprime--) {
			if ((*missBeh[wprime])[i] == 0) {
				imputed[i] = (*rawBeh[wprime])[i]
				found = 1
				break
			}
		}
		if (found) continue
		for (wprime=w+1; wprime<=nwaves; wprime++) {
			if ((*missBeh[wprime])[i] == 0) {
				imputed[i] = (*rawBeh[wprime])[i]
				found = 1
				break
			}
		}
		if (found) continue
		imputed[i] = SaomBehaviorModeAtWave(rawBeh, missBeh, w, n)
	}
	return(imputed)
}

/* ===================================================================
   SaomNativeConfig: native (C) backend eligibility/dispatch config,
   populated by SaomNativeSetup() (defined later in this file, alongside
   the rest of the native-backend dispatch code) - declared here,
   textually before SaomEstimateRM's own use of it below, because Mata
   requires a struct's fields to be known at the point it is used as a
   variable TYPE (unlike plain function calls, which may forward-
   reference a function defined later in the same compiled block).
   =================================================================== */
struct SaomNativeConfig {
	real scalar eligible
	string scalar whynot		// why not eligible: the first term the plugin does not cover
	real rowvector fntype		// protocol 11: network endowment/creation codes per term (set by the estimator)
	real matrix structpairs		// protocol 11: structural (fixed) dyads, k x 2 (set by the estimator)
	real scalar needv11		// protocol 11 needed (endowment/creation, three-way interactions, large models)
	real rowvector termcodes	// one per term instance in M, in M's own order
	real rowvector attridx		// 0 = no attribute needed; else 1-based column into attrmat
	real rowvector p1		// one generic scalar per term instance (only simcov uses it - the covariate's own range); 0 for every other term
	real matrix attrmat		// one column per term instance that needs an attribute array (harmonisation unit 10: NOT deduplicated across terms sharing the same underlying variable - simple over maximally compact, matches MAXATTR's own generous cap)
}

/* Co-evolution's own native-config counterpart (harmonisation unit 26)
   - declared here for the same forward-reference reason as
   SaomNativeConfig above (SaomEstimateRMCoev()/SaomEstimateRMCoevMulti()
   use it as a variable TYPE before SaomBehaviorNativeSetup() itself is
   defined). No attrmat/attridx/p1 - none of linear/quadratic/avalt/
   avsim take a per-term attribute array, unlike some network terms. */
struct SaomBehaviorNativeConfig {
	real scalar eligible
	real rowvector termcodes	// one per term instance in Mbeh, in Mbeh's own order
	real rowvector fntype		// protocol 11: endowment (1)/creation (2) codes per term
}

/* ===================================================================
   SaomFit: result of SaomEstimateRM() (two waves) and
   SaomEstimateRMMulti() (two or more waves).
   =================================================================== */
struct SaomFit {
	real rowvector theta		// estimated effect coefficients (length M.nparam())
	real rowvector tratio		// RSiena convergence t-ratio per effect, phase-3 mean deviation / sd (= tconv[1..p])
	real scalar rate		// SaomEstimateRM(): the ESTIMATED rate
	real scalar rate_tratio		// SaomEstimateRM(): phase-3 t-ratio of the rate's distance statistic
	real scalar rate_se		// SaomEstimateRM(): standard error of the rate (sandwich covariance)
	real matrix theta_path		// phase-2 subphase-end effect coefficients (nsub x nparam), for diagnostics
	real rowvector rates		// one ESTIMATED rate per inter-wave period (both estimators)
	real rowvector rate_tratios	// per period, same convention as rate_tratio
	real rowvector rate_ses		// per period, standard errors
	real matrix V			// covariance of theta (effects only)
	real matrix Vfull		// covariance of every estimated parameter: theta, rates, ratecoef (in that order)
	real rowvector tconv		// RSiena convergence t-ratios, mean deviation / sd, same order as Vfull
	real scalar tconvMax		// RSiena overall maximum convergence ratio, sqrt(m' S^-1 m)
	real rowvector rmfixed		// 1 for a parameter held fixed at its starting value because its phase-1 derivative was non-positive (see SaomEstimateNet())
	real rowvector ratecoef		// ratecov(): estimated covariate-rate coefficient(s), one per variable
	real rowvector ratecoef_se
	real rowvector ratecoef_tratio
	real scalar rate_actor		// SaomEstimateRM(): the rate on nwsaom's per-actor scale (differs from rate for symmetric models, see SaomSymRateToRSiena())
	real scalar cond		// 1: conditional estimation (RSiena's default for one network); the rates are then mean phase-3 times, rate_se(s) their SDs, rate_tratio(s) missing
	real rowvector ratecoef_fixed	// ratecov(): 1 if ratecoef was held fixed at its starting value (non-positive derivative), see rmfixed
}

/* ===================================================================
   Network-only estimation: Method of Moments, CONDITIONAL (RSiena's
   default for one dependent network, cond = TRUE) or UNCONDITIONAL
   (sienaAlgorithmCreate(cond = FALSE), nwsaom's `unconditional' option).

   Parameters, in this internal order (unconditional):
     theta (p effects), one network rate per period, and, with
     ratecov(), the covariate-rate coefficient; conditional: the same
     without the rates (see the CONDITIONAL paragraph below).
   Every one of them is an ordinary Method-of-Moments parameter,
   estimated jointly in phases 1-3 with the same multi-subphase
   Robbins-Monro algorithm RSiena uses (rsiena/R/phase1.r, phase2.r,
   phase3.r; nsub=4, firstg=0.2, reduceg=0.5, diagonalize=0.2,
   truncation=5, n2minimum = trunc(max(5, 7+#parameters)*2.52) and
   *2.52 per subphase, n2maximum = n2minimum+200).

   Statistics, per period:
     effects: the effect statistics of the simulated end network (masked
              for missing data; endowment/creation effects on the lost/
              gained-ties networks), summed over periods;
     rate:    the DISTANCE between the simulated end network and the
              period's starting observation (number of differing dyads,
              missing dyads excluded); the target is the observed
              distance between the period's two waves;
     ratecoef: sum over the differing dyads of the tail actor's
              covariate value (RSiena's covariate rate statistic).
   Scores (phase-1 and phase-3 Jacobians, by the score-function method):
   the effect score is the sum over ministeps of the chosen minus the
   expected change statistic; the rate score is (ministeps)/rate minus
   (active actors) - with ratecov() the actors' rate weights
   exp(ratecoef*x_i) are summed instead of counted; the ratecoef score
   is RSiena's compensated counting-process score.

   CONDITIONAL estimation (C.cond = 1, RSiena's default for a single
   dependent network - initializeFRAN(): !maxlike & one dependent
   variable, and not with composition change): the rates are removed from
   the parameter vector; every period is simulated at rate 1 until the
   distance from its starting observation reaches the observed distance
   (at least one ministep; missing dyads not counted; symmetric networks
   in steps of two, as EpochSimulation::runEpoch() and
   NetworkVariable::makeChange()), with the effect statistics and scores
   of the network at that point; a period's rate is the mean of those
   simulated times over the phase-3 replicates and its reported standard
   error their standard deviation (terminateFRAN(): colMeans/sd of
   z$ntim). A ratecov() coefficient stays a Method-of-Moments parameter,
   as in RSiena (only the basic rates are conditioned on). The two
   estimators are consistent for the same model but differ in finite
   samples: on s50, RSiena's conditional and unconditional estimates
   differ by up to 0.3 SE. Unconditional starting values for the rates:
   rate0() when given, else RSiena's closed form
   n_active*(0.2 + 2*distance)/(n_active*(n_active-1) + 1).

   Phase 1 ends with RSiena's partial quasi-Newton step (phase1.2):
   0.5*firstg times Dinv*mean(deviation), scaled so that no parameter
   moves by more than 1 and no rate by more than half its value.
   Phase 2: a rate update that would more than halve a rate is limited
   to halving it (RSiena's positivity rule for rate parameters). If the
   plain Jacobian lets an effect run past |50| (thetaBound), the fit is
   retried once with every parameter whose phase-1 derivative diagonal
   is non-positive FIXED at its starting value (RSiena's last-resort
   treatment in phase1.r: zero cross terms, unit diagonal, no updates,
   excluded from the bound; standard error 0), reported in
   rmfixed/ratecoef_fixed. Phase 3: K3 replicates at the final estimate
   give the convergence t-ratios (the overall maximum over the free
   parameters) and the sandwich covariance Dinv3 * cov(deviations) *
   Dinv3' with the raw phase-3 Jacobian (RSiena's phase3.r).

   The algorithm itself lives in SaomRMCore(), shared with the
   two-network estimator SaomEstimateRMCoevNetNet().
   =================================================================== */
struct SaomNetCtx {
	pointer(class ErgmGraph scalar) rowvector Gwaves
	pointer(class ErgmModel scalar) scalar Mp	// set by SaomEstimateNet()
	struct SaomNativeConfig scalar cfg
	real scalar use_native, use_batch, native_netdist
	real scalar cond		// 1: conditional estimation (set by the caller before SaomNetCtxInit(); 0 under composition change)
	real matrix lastT		// conditional: elapsed times of the last K replicates (K x P)
	real scalar P, p, ptot, n
	real scalar hasmiss, haspresent, hasnetgate, hasstructural, hasratecov, symtype
	real matrix target		// P x p
	real rowvector targetRate	// 1 x P
	real matrix targetRateCov	// P x K (ratecov only; K = ratecov() variables)
	real matrix presentPd		// n x P, all ones without composition change
	real rowvector npresentPd
	pointer(real matrix) rowvector missMaskPd
	real matrix missDyadsPd		// stacked (period, i, j)
	real rowvector fntype
	real matrix structural
	real matrix ratecovattr		// n x K
}

/* Fills the context: targets, native dispatch. presentPd is n x P (or
   0 x 0), missMaskPd one n x n mask per period (or empty). */
void SaomNetCtxInit(struct SaomNetCtx scalar C, pointer(class ErgmGraph scalar) rowvector Gwaves,
	class ErgmModel scalar M, real matrix presentPd, pointer(real matrix) rowvector missMaskPd,
	real rowvector fntype, real matrix ratecovattr, real scalar symtype, real matrix structural) {
	string scalar why

	real scalar pd, ver
	real matrix mdt

	C.Gwaves = Gwaves
	C.P = cols(Gwaves) - 1
	C.n = (*Gwaves[1]).n
	C.p = M.nparam()
	C.haspresent = (rows(presentPd) > 0)
	C.presentPd = (C.haspresent ? presentPd : J(C.n, C.P, 1))
	C.npresentPd = colsum(C.presentPd :!= 0)
	C.hasmiss = 0
	if (cols(missMaskPd) > 0) {
		for (pd=1; pd<=C.P; pd++) if (any(*missMaskPd[pd] :!= 0)) C.hasmiss = 1
	}
	C.missMaskPd = missMaskPd
	C.hasnetgate = (cols(fntype) > 0)
	if (C.hasnetgate) C.hasnetgate = any(fntype :!= 0)
	C.fntype = fntype
	C.hasstructural = (rows(structural) > 0)
	C.structural = structural
	// hasratecov = number of ratecov() variables (0: none)
	C.hasratecov = (rows(ratecovattr) > 0 ? cols(ratecovattr) : 0)
	C.ratecovattr = ratecovattr
	C.symtype = symtype
	// RSiena (initializeFRAN()): conditional estimation is not used with
	// composition change
	if (C.cond) {
		if (C.haspresent) if (min(C.npresentPd) < C.n) C.cond = 0
	}
	C.ptot = C.p + (C.cond ? 0 : C.P) + C.hasratecov

	C.target = J(C.P, C.p, 0)
	C.targetRate = J(1, C.P, 0)
	C.targetRateCov = J(C.P, max((C.hasratecov, 1)), 0)
	for (pd=1; pd<=C.P; pd++) {
		if (C.hasmiss) {
			C.target[pd,.] = SaomMaskedStatistic(*Gwaves[pd+1], M, *missMaskPd[pd])
			C.targetRate[pd] = SaomCountDifferingMasked(*Gwaves[pd], *Gwaves[pd+1], *missMaskPd[pd])
		}
		else {
			C.target[pd,.] = M.full_statistic(*Gwaves[pd+1])
			C.targetRate[pd] = SaomCountDiffering(*Gwaves[pd], *Gwaves[pd+1])
		}
		if (C.hasnetgate) C.target[pd,.] = SaomNetworkPatchEndowCreation(M, fntype, C.target[pd,.], *Gwaves[pd], *Gwaves[pd+1])
		if (C.hasratecov) C.targetRateCov[pd,.] = SaomCovariateDifferingSum(*Gwaves[pd], *Gwaves[pd+1], ratecovattr)
	}

	// native dispatch, decided once per fit. Endowment/creation gating
	// and structural zeros/ones exist only in Mata. The distance
	// statistic comes from the plugin from protocol 5 on; with an older
	// binary the simulated graph is read back and the distance counted
	// in Mata. The threaded batch path covers the plain, missing-data and
	// composition-change cases.
	C.cfg = SaomNativeSetup(M)
	// protocol 11: endowment/creation and structural() run natively too
	if (C.hasnetgate) C.cfg.fntype = fntype
	if (C.hasstructural) C.cfg.structpairs = SaomMaskToDyadList(structural :== 1)
	C.use_native = C.cfg.eligible & SaomNativeAvailable()
	ver = (C.use_native ? SaomNativePluginVersion() : 0)
	if ((C.hasnetgate | C.hasstructural) & ver < 11) C.use_native = 0
	// conditional estimation needs protocol 6 (missing-aware distance,
	// symmetric distance, batch condmode 2); older binaries: Mata
	if (C.cond & ver < 6) C.use_native = 0
	// symmetric (pairwise) models with ratecov() draw the alter by the
	// covariate as RSiena does from protocol 7 on
	if (C.symtype != 0 & C.hasratecov & ver < 7) C.use_native = 0
	// several ratecov() variables from protocol 9 on
	if (C.hasratecov > 1 & ver < 9) C.use_native = 0
	// unilateral-initiative model types (forcing, confirmation) from
	// protocol 8 on
	if (C.symtype >= 4 & ver < 8) C.use_native = 0
	why = ""
	if (!SaomNativeAvailable()) why = "no native plugin for this platform"
	else if (!C.cfg.eligible) why = C.cfg.whynot
	else why = "native plugin too old for this model"
	SaomSetEngine(C.use_native, why)
	C.native_netdist = (ver >= 5)
	// the threaded batch path: every model from protocol 11 on
	C.use_batch = C.use_native & (ver >= 5) & ((!C.hasratecov & C.symtype == 0 & !C.hasnetgate & !C.hasstructural) | ver >= 11)
	if (C.symtype != 0 & !C.use_native) {
		errprintf("SAOM estimation of a non-directed relation (symmetric, symtype()) requires the native (C) backend, protocol 8 or later for symtype(forcing)/(confirmation); it is not available for this model/platform (there is no Mata fallback for these ministeps).\n")
		exit(198)
	}
	C.missDyadsPd = J(0, 3, 0)
	if (C.use_native & C.hasmiss) {
		for (pd=1; pd<=C.P; pd++) {
			mdt = SaomMaskToDyadList(*missMaskPd[pd])
			if (rows(mdt) > 0) C.missDyadsPd = C.missDyadsPd \ (J(rows(mdt), 1, pd), mdt)
		}
	}
	if (C.use_batch) {
		SaomBatchSetup(Gwaves, C.P, C.cfg, J(1, 0, 0), J(1, 0, NULL), 0, 0, 0, 0,
			C.hasmiss, C.missDyadsPd, J(C.n, C.P, 0), C.haspresent, C.presentPd,
			J(1, 0, 0), C.symtype, (C.hasratecov ? C.ratecovattr : J(0, 0, 0)))
	}
}

/* One replicate over every period at parameter vector `par' (internal
   order): deviations from the targets in `dev', scores in `sco'
   (1 x ptot each; scores only when want_score). */
void SaomNetReplicate(struct SaomNetCtx scalar C, class ErgmModel scalar M,
	real rowvector par, real scalar want_score, real rowvector dev, real rowvector sco) {

	struct SaomCountedResult scalar cres
	struct SaomScoredResult scalar sres
	class ErgmGraph scalar Gwork
	real rowvector theta, stat
	real colvector pres, presNat
	real matrix mdy
	real scalar pd, p, P, rate, steps, netdist, active, rebuild, K
	real rowvector ratecoef, rcstat, rcscore, rcix

	p = C.p
	P = C.P
	theta = par[1..p]
	K = C.hasratecov
	rcix = (K ? (C.ptot-K+1)..C.ptot : J(1, 0, 0))
	ratecoef = (K ? par[rcix] : 0)
	dev = J(1, C.ptot, 0)
	sco = J(1, C.ptot, 0)
	for (pd=1; pd<=P; pd++) {
		rate = par[p + pd]
		pres = C.presentPd[., pd]
		presNat = (C.haspresent ? pres : J(0, 1, 0))
		rcstat = J(1, max((K, 1)), 0)
		rcscore = J(1, max((K, 1)), 0)
		if (C.use_native) {
			mdy = J(0, 2, 0)
			if (C.hasmiss) {
				mdy = select(C.missDyadsPd[., 2..3], C.missDyadsPd[., 1] :== pd)
				if (rows(mdy) == 0) mdy = J(0, 2, 0)
			}
			rebuild = C.hasratecov | !C.native_netdist
			if (rebuild) {
				Gwork = ErgmGraph()
				SaomCopyGraph(*C.Gwaves[pd], Gwork)
				if (C.hasratecov) cres = SaomSimulateIntervalNative(Gwork, M, C.cfg, theta, rate, 1, want_score, mdy, presNat, C.symtype, C.ratecovattr, ratecoef)
				else cres = SaomSimulateIntervalNative(Gwork, M, C.cfg, theta, rate, 1, want_score, mdy, presNat, C.symtype)
				if (C.hasratecov) {
					rcstat = SaomCovariateDifferingSum(*C.Gwaves[pd], Gwork, C.ratecovattr)
					if (want_score) rcscore = cres.rcscore
				}
				if (C.native_netdist) netdist = cres.netdist
				else if (C.hasmiss) netdist = SaomCountDifferingMasked(*C.Gwaves[pd], Gwork, *C.missMaskPd[pd])
				else netdist = SaomCountDiffering(*C.Gwaves[pd], Gwork)
			}
			else {
				cres = SaomSimulateIntervalNative(*C.Gwaves[pd], M, C.cfg, theta, rate, 0, want_score, mdy, presNat, C.symtype)
				netdist = cres.netdist
			}
			stat = cres.stat
			steps = cres.steps
			if (want_score) sco[1..p] = sco[1..p] + cres.score
		}
		else {
			Gwork = ErgmGraph()
			SaomCopyGraph(*C.Gwaves[pd], Gwork)
			if (want_score) {
				if (C.hasratecov) sres = SaomSimIntScoredRateCov(Gwork, M, theta, rate, C.ratecovattr, ratecoef, pres, C.fntype)
				else if (C.hasnetgate) sres = SaomSimulateIntervalScored(Gwork, M, theta, rate, pres, C.fntype)
				else if (C.hasstructural) sres = SaomSimulateIntervalScored(Gwork, M, theta, rate, pres, J(1, 0, 0), C.structural)
				else if (C.haspresent) sres = SaomSimulateIntervalScored(Gwork, M, theta, rate, pres)
				else sres = SaomSimulateIntervalScored(Gwork, M, theta, rate)
				steps = sres.steps
				sco[1..p] = sco[1..p] + sres.score
				if (C.hasratecov) rcscore = sres.rcscore
			}
			else {
				if (C.hasratecov) cres = SaomSimIntCountedRateCov(Gwork, M, theta, rate, C.ratecovattr, ratecoef, pres, C.fntype)
				else if (C.hasnetgate) cres = SaomSimulateIntervalCounted(Gwork, M, theta, rate, pres, C.fntype)
				else if (C.hasstructural) cres = SaomSimulateIntervalCounted(Gwork, M, theta, rate, pres, J(1, 0, 0), C.structural)
				else if (C.haspresent) cres = SaomSimulateIntervalCounted(Gwork, M, theta, rate, pres)
				else cres = SaomSimulateIntervalCounted(Gwork, M, theta, rate)
				steps = cres.steps
			}
			if (C.hasmiss) {
				stat = SaomMaskedStatistic(Gwork, M, *C.missMaskPd[pd])
				netdist = SaomCountDifferingMasked(*C.Gwaves[pd], Gwork, *C.missMaskPd[pd])
			}
			else {
				stat = M.full_statistic(Gwork)
				netdist = SaomCountDiffering(*C.Gwaves[pd], Gwork)
			}
			if (C.hasnetgate) stat = SaomNetworkPatchEndowCreation(M, C.fntype, stat, *C.Gwaves[pd], Gwork)
			if (C.hasratecov) rcstat = SaomCovariateDifferingSum(*C.Gwaves[pd], Gwork, C.ratecovattr)
		}
		dev[1..p] = dev[1..p] + (stat - C.target[pd, .])
		dev[p + pd] = netdist - C.targetRate[pd]
		if (K) dev[rcix] = dev[rcix] + (rcstat - C.targetRateCov[pd,.])
		if (want_score) {
			active = (K ? sum(exp(C.ratecovattr * ratecoef')) : C.npresentPd[pd])
			// pairwise models with ratecov(): total rate rate * (S^2 -
			// sum w^2) / (n - 1), see saom_sim.c
			if (C.hasratecov & C.symtype >= 1 & C.symtype <= 3) active = (active^2 - sum(exp(2 :* (C.ratecovattr * ratecoef')))) / (C.n - 1)
			sco[p + pd] = steps / rate - active
			if (K) sco[rcix] = sco[rcix] + rcscore
		}
	}
}

/* Symmetric (pairwise, RSiena model types BFORCE/BAGREE/BJOINT) models:
   the rate on RSiena's scale.

   nwsaom simulates a pairwise ministep as: an actor at rate rho (the
   per-actor rate of every other nwsaom model), an alter uniformly among
   the m - 1 others (m: actors present), so an ordered pair (i, j) is
   chosen at rate rho / (m - 1).  RSiena (DependentVariable::
   calculateRates(), NetworkVariable::calculateModelTypeBProbabilities())
   gives each actor the basic rate lambda, chooses the actor and then the
   alter by these rates, with total rate (sum lambda_i)^2 - sum lambda_i^2
   = m (m - 1) lambda^2, so a pair at rate lambda^2.  The two agree with
   lambda^2 = rho / (m - 1).  With ratecov() both use actor rates
   lambda * w_i, w_i = exp(ratecoef * x_i), and rho = lambda^2 (n - 1)
   (saom_sim.c), so the same conversion holds with m = n.

   Reported rate:
     unconditional estimation: lambda = sqrt(rho / (m - 1)), the basic
       rate parameter RSiena estimates; its SE by the delta method,
       se(lambda) = se(rho) / (2 sqrt(rho (m - 1)));
     conditional estimation: RSiena reports the mean phase-3 time taken
       at basic rate 1 to reach the observed distance (terminateFRAN(),
       z$rate = colMeans(z$ntim)).  At basic rate 1 pairs occur at rate
       1, in nwsaom's conditional simulation (rho = 1) at rate 1/(m - 1),
       so RSiena's time is nwsaom's time / (m - 1): rate and SD are
       divided by m - 1.  This is on the scale of lambda^2, not lambda
       (RSiena's own convention for these model types: the time at basic
       rate 1 equals lambda^2), so conditional and unconditional rates of
       a symmetric model are not directly comparable, in RSiena as here.
   The convergence t-ratio of the rate is scale-free and unchanged; the
   per-actor rate rho is kept in fit.rate_actor. */
real scalar SaomSymRateScale(struct SaomNetCtx scalar C) {
	return((C.hasratecov ? C.n : C.npresentPd[1]) - 1)
}

void SaomSymRateToRSiena(struct SaomFit scalar fit, struct SaomNetCtx scalar C, real scalar p) {
	real scalar m1, rho, d

	m1 = SaomSymRateScale(C)
	if (fit.cond) {
		fit.rate = fit.rate / m1
		fit.rate_se = fit.rate_se / m1
	}
	else {
		rho = fit.rate
		d = 1 / (2 * sqrt(rho * m1))
		fit.rate = sqrt(rho / m1)
		fit.rate_se = fit.rate_se * d
		fit.Vfull[p+1, .] = fit.Vfull[p+1, .] :* d
		fit.Vfull[., p+1] = fit.Vfull[., p+1] :* d
	}
}

/* Conditional counterpart of SaomNetReplicate() (RSiena's conditional
   estimation, C.cond == 1): every period is simulated at rate 1 until the
   distance from its starting observation reaches the observed distance;
   `par' = (theta, [ratecoef]); the elapsed times go to `tim' (1 x P). */
void SaomNetReplicateCond(struct SaomNetCtx scalar C, class ErgmModel scalar M,
	real rowvector par, real scalar want_score, real rowvector dev, real rowvector sco,
	real rowvector tim) {

	struct SaomCountedResult scalar cres
	struct SaomScoredResult scalar sres
	class ErgmGraph scalar Gwork
	real rowvector theta, stat, fnarg
	real colvector pres, presNat
	real matrix rcattr
	real matrix mdy, dm
	real scalar pd, p, P, ct, K
	real rowvector ratecoef, rcstat, rcscore, rcix

	p = C.p
	P = C.P
	theta = par[1..p]
	K = C.hasratecov
	rcix = (K ? (C.ptot-K+1)..C.ptot : J(1, 0, 0))
	ratecoef = (K ? par[rcix] : 0)
	rcattr = (K ? C.ratecovattr : J(0, 1, 0))
	fnarg = (C.hasnetgate ? C.fntype : J(1, 0, 0))
	dev = J(1, C.ptot, 0)
	sco = J(1, C.ptot, 0)
	tim = J(1, P, 0)
	for (pd=1; pd<=P; pd++) {
		ct = C.targetRate[pd]
		pres = C.presentPd[., pd]
		presNat = (C.haspresent ? pres : J(0, 1, 0))
		dm = (C.hasmiss ? *C.missMaskPd[pd] : J(0, 0, 0))
		rcstat = J(1, max((K, 1)), 0)
		rcscore = J(1, max((K, 1)), 0)
		Gwork = ErgmGraph()
		if (C.use_native) {
			mdy = J(0, 2, 0)
			if (C.hasmiss) {
				mdy = select(C.missDyadsPd[., 2..3], C.missDyadsPd[., 1] :== pd)
				if (rows(mdy) == 0) mdy = J(0, 2, 0)
			}
			if (C.hasratecov) {
				SaomCopyGraph(*C.Gwaves[pd], Gwork)
				cres = SaomSimulateIntervalNative(Gwork, M, C.cfg, theta, 1, 1, want_score, mdy, presNat, C.symtype, rcattr, ratecoef, ct)
				rcstat = SaomCovariateDifferingSum(*C.Gwaves[pd], Gwork, C.ratecovattr)
				if (want_score) rcscore = cres.rcscore
			}
			else cres = SaomSimulateIntervalNative(*C.Gwaves[pd], M, C.cfg, theta, 1, 0, want_score, mdy, presNat, C.symtype, rcattr, 0, ct)
			stat = cres.stat
			tim[pd] = cres.t
			if (want_score) sco[1..p] = sco[1..p] + cres.score
		}
		else {
			SaomCopyGraph(*C.Gwaves[pd], Gwork)
			if (want_score) {
				if (C.hasratecov) sres = SaomSimIntScoredRateCov(Gwork, M, theta, 1, C.ratecovattr, ratecoef, pres, fnarg, ct, dm)
				else sres = SaomSimulateIntervalScored(Gwork, M, theta, 1, pres, fnarg, (C.hasstructural ? C.structural : J(0, 0, 0)), ct, dm)
				sco[1..p] = sco[1..p] + sres.score
				if (C.hasratecov) rcscore = sres.rcscore
				tim[pd] = sres.t
			}
			else {
				if (C.hasratecov) cres = SaomSimIntCountedRateCov(Gwork, M, theta, 1, C.ratecovattr, ratecoef, pres, fnarg, ct, dm)
				else cres = SaomSimulateIntervalCounted(Gwork, M, theta, 1, pres, fnarg, (C.hasstructural ? C.structural : J(0, 0, 0)), ct, dm)
				tim[pd] = cres.t
			}
			stat = (C.hasmiss ? SaomMaskedStatistic(Gwork, M, *C.missMaskPd[pd]) : M.full_statistic(Gwork))
			if (C.hasnetgate) stat = SaomNetworkPatchEndowCreation(M, C.fntype, stat, *C.Gwaves[pd], Gwork)
			if (C.hasratecov) rcstat = SaomCovariateDifferingSum(*C.Gwaves[pd], Gwork, C.ratecovattr)
		}
		dev[1..p] = dev[1..p] + (stat - C.target[pd, .])
		if (K) {
			dev[rcix] = dev[rcix] + (rcstat - C.targetRateCov[pd,.])
			if (want_score) sco[rcix] = sco[rcix] + rcscore
		}
	}
}

/* K replicates at `par': K x ptot deviations `Z' and scores `S'. */
void SaomNetSimMany(struct SaomNetCtx scalar C, class ErgmModel scalar M,
	real rowvector par, real scalar K, real scalar want_score, real matrix Z, real matrix S) {

	real matrix out
	real rowvector dev, sco, tim
	real scalar k, pd, p, b

	p = C.p
	Z = J(K, C.ptot, 0)
	S = J(K, C.ptot, 0)
	if (C.cond) {
		// conditional: the elapsed times are kept in C.lastT (K x P); the
		// rate estimate is their mean over phase 3 (RSiena terminateFRAN())
		C.lastT = J(K, C.P, 0)
		if (C.use_batch) {
			if (C.hasratecov) out = SaomBatchRun(C.P, p, 0, par[1..p], J(1, 0, 0), J(1, C.P, 1), J(1, 0, 0), C.targetRate, K, want_score, 2, par[(C.ptot-C.hasratecov+1)..C.ptot])
			else out = SaomBatchRun(C.P, p, 0, par[1..p], J(1, 0, 0), J(1, C.P, 1), J(1, 0, 0), C.targetRate, K, want_score, 2)
			Z[., 1..p] = out[., 1..p] :- colsum(C.target)
			if (want_score) S[., 1..p] = out[., (p+1)..(2*p)]
			for (pd=1; pd<=C.P; pd++) C.lastT[., pd] = out[., 2*p + 7*(pd-1) + 7]
			if (C.hasratecov) SaomBatchRateCovCols(C, out, 2*p + 7*C.P, want_score, Z, S)
			SaomCondTimeCheck(C.lastT)
			return
		}
		for (k=1; k<=K; k++) {
			SaomNetReplicateCond(C, M, par, want_score, dev, sco, tim)
			Z[k,.] = dev
			S[k,.] = sco
			C.lastT[k,.] = tim
		}
		SaomCondTimeCheck(C.lastT)
		return
	}
	if (C.use_batch) {
		if (C.hasratecov) out = SaomBatchRun(C.P, p, 0, par[1..p], J(1, 0, 0), par[(p+1)..(p+C.P)], J(1, 0, 0), J(1, 0, 0), K, want_score, 0, par[(C.ptot-C.hasratecov+1)..C.ptot])
		else out = SaomBatchRun(C.P, p, 0, par[1..p], J(1, 0, 0), par[(p+1)..(p+C.P)], J(1, 0, 0), J(1, 0, 0), K, want_score, 0)
		Z[., 1..p] = out[., 1..p] :- colsum(C.target)
		if (want_score) S[., 1..p] = out[., (p+1)..(2*p)]
		for (pd=1; pd<=C.P; pd++) {
			b = 2*p + 6*(pd-1)
			Z[., p+pd] = out[., b+1] :- C.targetRate[pd]
			if (want_score) S[., p+pd] = out[., b+3] / par[p+pd] :- SaomActiveRate(C, par, pd)
		}
		if (C.hasratecov) SaomBatchRateCovCols(C, out, 2*p + 6*C.P, want_score, Z, S)
		return
	}
	for (k=1; k<=K; k++) {
		SaomNetReplicate(C, M, par, want_score, dev, sco)
		Z[k,.] = dev
		S[k,.] = sco
	}
}

/* the batch path's ratecov() columns: per covariate the summed statistic
   and score after column `base' */
void SaomBatchRateCovCols(struct SaomNetCtx scalar C, real matrix out, real scalar base,
	real scalar want_score, real matrix Z, real matrix S) {
	real scalar kk, K, c0
	K = C.hasratecov
	c0 = C.ptot - K
	for (kk=1; kk<=K; kk++) {
		Z[., c0+kk] = out[., base + 2*kk - 1] :- colsum(C.targetRateCov[., kk])
		if (want_score) S[., c0+kk] = out[., base + 2*kk]
	}
}

/* the rate score's compensator: steps/rate minus this (the total rate
   divided by the rate), as in SaomNetReplicate() */
real scalar SaomActiveRate(struct SaomNetCtx scalar C, real rowvector par, real scalar pd) {
	real scalar active, K
	real rowvector ratecoef
	K = C.hasratecov
	if (!K) return(C.npresentPd[pd])
	ratecoef = par[(C.ptot-K+1)..C.ptot]
	active = sum(exp(C.ratecovattr * ratecoef'))
	if (C.symtype >= 1 & C.symtype <= 3) active = (active^2 - sum(exp(2 :* (C.ratecovattr * ratecoef')))) / (C.n - 1)
	return(active)
}

/* SaomRMCore() callback: K replicates at `par' */
void SaomNetSimManyCB(struct SaomNetCtx scalar C, real rowvector par, real scalar K,
	real scalar want_score, real matrix Z, real matrix S) {
	SaomNetSimMany(C, *C.Mp, par, K, want_score, Z, S)
}

struct SaomNetFit {
	real rowvector par		// theta, rates, ratecoef
	real rowvector tratio		// = tconv (kept for the wrappers' field names)
	real rowvector tconv		// mean/sd, 1 x ptot
	real scalar tconvMax
	real matrix Vfull
	real matrix theta_path		// nsub x p
	real rowvector rmfixed		// 1 x ptot
	real matrix T			// conditional estimation: phase-3 times, K3 x P
}

/* SaomRMCore: the three-phase Robbins-Monro algorithm (see the header
   comment above SaomNetCtx) over a parameter vector whose first `p'
   entries are effects. `simfn' simulates K replicates at a parameter
   vector: (*simfn)(C, par, K, want_score, Z, S) fills K x ptot
   deviations Z and scores S. `israte' flags rate parameters (positivity
   rule), `bounded' the parameters thetaBound applies to. Used by
   SaomEstimateNet() and SaomEstimateRMCoevNetNet(). */
struct SaomNetFit scalar SaomRMCore(transmorphic C, pointer(function) scalar simfn,
	real rowvector par0, real scalar p, real rowvector israte, real rowvector bounded,
	real scalar K0, real scalar K3, real scalar firstg) {

	struct SaomNetFit scalar fit
	real matrix Zdev, Zsco, Dhat, DhatDec, Dinv, DinvOrig, DinvDec, msf, sfinvcov, Z1, S1, Z3, S3, Sc3, Dhat3
	real rowvector par, par1, dev, prevdev, prod0, prod1, ac, stdcap, thav, fchange, changestep, thprev, m3
	real rowvector rmfixed, rmfixedDec
	real scalar ptot, k, nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real scalar attempt, diverged
	real rowvector n2minimum, n2maximum

	ptot = cols(par0)

	// --- Phase 1: Jacobian by the score-function method
	(*simfn)(C, par0, K0, 1, Zdev, Zsco)
	Dhat = ((Zdev :- mean(Zdev))' * (Zsco :- mean(Zsco))) / K0
	rmfixedDec = J(1, ptot, 0)
	DhatDec = Dhat
	for (k=1; k<=ptot; k++) {
		if (Dhat[k,k] <= 0) {
			rmfixedDec[k] = 1
			DhatDec[k,.] = J(1, ptot, 0)
			DhatDec[.,k] = J(ptot, 1, 0)
			DhatDec[k,k] = 1
		}
	}
	DinvOrig = luinv(0.8 * Dhat + 0.2 * diag(diagonal(Dhat)))		// not symmetric: luinv, not invsym
	DinvDec = luinv(0.8 * DhatDec + 0.2 * diag(diagonal(DhatDec)))
	msf = variance(Zdev)
	sfinvcov = invsym(msf + 0.0001 * I(ptot))

	// quasi-Newton step after phase 1 (RSiena's phase1.2): half of firstg
	// times the full step, scaled down so that no parameter moves by more
	// than 1, and a rate by at most half its value
	par1 = (DinvOrig * mean(Zdev)')' * (0.5 * firstg)
	if (hasmissing(par1)) par1 = J(1, ptot, 0)
	if (max(abs(par1)) > 1) par1 = par1 / max(abs(par1))
	for (k=1; k<=ptot; k++) if (israte[k] & par1[k] >= par0[k]) par1[k] = 0.5 * par0[k]
	par1 = par0 - par1

	// --- Phase 2: multi-subphase Robbins-Monro
	nsub = 4
	reduceg = 0.5
	n2min0 = max((5, 7 + ptot))
	n2minimum = J(1, nsub, 0)
	n2maximum = J(1, nsub, 0)
	n2minimum[1] = trunc(n2min0 * 2.52)
	n2maximum[1] = n2minimum[1] + 200
	for (k=2; k<=nsub; k++) {
		n2minimum[k] = trunc(n2minimum[k-1] * 2.52)
		n2maximum[k] = n2minimum[k] + 200
	}

	attempt = 1
	while (1) {
		if (attempt == 1) {
			Dinv = DinvOrig
			rmfixed = J(1, ptot, 0)
		}
		else {
			// the plain attempt diverged: retry with the parameters whose
			// derivative estimate is non-positive FIXED at their starting
			// values, as RSiena does (phase1.r: decoupled from the others,
			// never updated, excluded from thetaBound)
			Dinv = DinvDec
			rmfixed = rmfixedDec
			for (k=1; k<=ptot; k++) {
				if (rmfixed[k]) printf("{txt}note: parameter %f of the Robbins-Monro estimation has a non-positive derivative estimate (%9.6f) and could not be estimated on this data; as RSiena does (R/phase1.r), it is kept fixed at its starting value (standard error 0). The other parameters are estimated.\n", k, Dhat[k,k])
			}
		}
		stdcap = J(1, ptot, 1)
		for (k=1; k<=ptot; k++) {
			stdcap[k] = 1 / sqrt(max((Dinv[k,.] * msf * Dinv[k,.]', 0)))
			if (stdcap[k] > 1) stdcap[k] = 1
		}

		par = par1
		for (k=1; k<=ptot; k++) if (rmfixed[k]) par[k] = par0[k]
		fit.theta_path = J(nsub, p, 0)
		gain = firstg
		diverged = 0
		for (subphase=1; subphase<=nsub; subphase++) {
			thav = par
			thavn = 1
			prod0 = J(1, ptot, 0)
			prod1 = J(1, ptot, 0)
			prevdev = J(1, ptot, 0)
			nit = 0
			maxacor = 1
			while (1) {
				nit = nit + 1
				(*simfn)(C, par, 1, 0, Z1, S1)
				dev = Z1[1,.]

				// autocorrelation on the raw deviation, odd/even pairs (phase2.r)
				if (mod(nit,2) == 1) prevdev = dev
				else {
					prod0 = prod0 + dev:^2
					prod1 = prod1 + dev:*prevdev
				}
				// Mahalanobis truncation
				maxRatio = sqrt((dev * sfinvcov * dev') / ptot)
				if (maxRatio > 5 & maxRatio > 0) dev = 5 * dev / maxRatio
				// double averaging: the step uses the cumulative deviation
				if (nit == 1) changestep = dev
				else changestep = changestep + dev
				fchange = gain * ((changestep * Dinv') :* stdcap) :* (1 :- rmfixed)

				thprev = par
				par = (thav / thavn) - fchange
				for (k=1; k<=ptot; k++) if (israte[k] & par[k] < 0.5*thprev[k]) par[k] = 0.5*thprev[k]
				thav = thav + par
				thavn = thavn + 1
				if (max(abs(select(par, bounded :& !rmfixed))) > 50) {
					diverged = 1
					break
				}

				if (nit >= 2) {
					ac = J(1, ptot, -1)
					for (k=1; k<=ptot; k++) if (prod0[k] > 1e-12) ac[k] = prod1[k] / prod0[k]
					maxacor = max(ac)
				}
				if (nit >= n2maximum[subphase]) break
				if (nit >= n2minimum[subphase] & maxacor < 1e-10) break
			}
			if (diverged) break
			par = thav / thavn
			fit.theta_path[subphase, .] = par[1..p]
			gain = gain * reduceg
		}
		if (!diverged) break
		if (attempt >= 2) {
			SaomCheckThetaBound(select(par, bounded :& !rmfixed), 50)
			break
		}
		attempt = attempt + 1
	}
	fit.par = par
	fit.rmfixed = rmfixed

	// --- Phase 3: convergence check and sandwich covariance
	(*simfn)(C, par, K3, 1, Z3, Sc3)
	m3 = mean(Z3)
	S3 = variance(Z3)
	fit.tconv = J(1, ptot, 0)
	for (k=1; k<=ptot; k++) if (S3[k,k] > 1e-10) fit.tconv[k] = m3[k] / sqrt(S3[k,k])
	fit.tratio = fit.tconv
	if (max(rmfixed) == 0) fit.tconvMax = sqrt(max((m3 * invsym(S3) * m3', 0)))
	else fit.tconvMax = sqrt(max((select(m3, !rmfixed) * invsym(select(select(S3, !rmfixed'), !rmfixed)) * select(m3, !rmfixed)', 0)))
	Dhat3 = ((Z3 :- m3)' * (Sc3 :- mean(Sc3))) / K3
	// a fixed parameter gets no standard error (0): decoupled Jacobian,
	// no variance
	for (k=1; k<=ptot; k++) {
		if (rmfixed[k]) {
			Dhat3[k,.] = J(1, ptot, 0)
			Dhat3[.,k] = J(ptot, 1, 0)
			Dhat3[k,k] = 1
			S3[k,.] = J(1, ptot, 0)
			S3[.,k] = J(ptot, 1, 0)
		}
	}
	Dinv = luinv(Dhat3)
	fit.Vfull = Dinv * S3 * Dinv'
	SaomCheckCovarianceFinite(fit.Vfull)
	return(fit)
}

struct SaomNetFit scalar SaomEstimateNet(struct SaomNetCtx scalar C, class ErgmModel scalar M,
	real rowvector par0, real scalar K0, real scalar K3, real scalar firstg) {

	struct SaomNetFit scalar fit
	real rowvector israte

	C.Mp = &M
	israte = J(1, C.ptot, 0)
	if (!C.cond) israte[(C.p+1)..(C.p+C.P)] = J(1, C.P, 1)
	// thetaBound applies to the effects and ratecoef, not to the rates
	fit = SaomRMCore(C, &SaomNetSimManyCB(), par0, C.p, israte, 1 :- israte, K0, K3, firstg)
	// conditional: the rate of a period is the mean phase-3 time to reach
	// the observed distance, its reported standard error the standard
	// deviation of those times (RSiena's terminateFRAN(): z$rate <-
	// colMeans(z$ntim), z$vrate <- apply(z$ntim, 2, sd))
	if (C.cond) fit.T = C.lastT
	if (C.use_batch) SaomBatchCleanup()
	if (C.use_native) SaomNativeCleanupFrame()
	return(fit)
}

/* SaomCondRequested(): conditional estimation for the network-only
   wrappers when the Mata external __nwsaom_cond is 1 (set by nwsaom.ado:
   RSiena's default, off with the `unconditional' option); unset or 0 =
   unconditional (the default for direct Mata calls). */
real scalar SaomCondRequested(){
	pointer(real scalar) scalar pc
	pc = findexternal("__nwsaom_cond")
	if (pc == NULL) return(0)
	if (*pc == .) return(0)
	return(*pc != 0)
}

/* closed-form starting rate (RSiena's effects.r): n_active*(0.2 +
   2*distance)/(n_active*(n_active-1) + 1) */
real scalar SaomRateStart(real scalar nactive, real scalar distance) {
	return(nactive * (0.2 + 2*distance) / (nactive*(nactive-1) + 1))
}

/* RSiena's data-derived starting value for the outdegree (density)
   effect (getNetworkStartingVals()): per period, alpha = log(p01/p10)/2
   with p01 = P(tie created | absent), p10 = P(tie dropped | present),
   both clamped to [.02, .98]; periods are weighted by the precision
   4/(p00/n01 + p11/n10); the result is clamped to [-3, 3]. `symmetric':
   every tie is stored in both directions, counted once. */
real scalar SaomOutdegreeStart(pointer(class ErgmGraph scalar) rowvector Gwaves,
	| real scalar symmetric) {

	real matrix A, B
	real scalar pd, P, n, c00, c01, c10, c11, p01, p10, p00, p11, h
	real rowvector alpha, prec

	P = cols(Gwaves) - 1
	n = (*Gwaves[1]).n
	h = ((args() >= 2 & symmetric != 0) ? 2 : 1)
	alpha = J(1, P, 0)
	prec = J(1, P, 0)
	for (pd=1; pd<=P; pd++) {
		A = (*Gwaves[pd]).to_dense()
		B = (*Gwaves[pd+1]).to_dense()
		c01 = floor((sum((1 :- A) :* B)) / h)
		c10 = floor((sum(A :* (1 :- B))) / h)
		c11 = floor((sum(A :* B)) / h)
		c00 = floor((n*(n-1) - sum(A :| B)) / h)
		p01 = (c00 + c01 >= 1 ? c01 / (c00 + c01) : 0.5)
		p10 = (c10 + c11 >= 1 ? c10 / (c10 + c11) : 0.5)
		p01 = min((max((p01, 0.02)), 0.98))
		p10 = min((max((p10, 0.02)), 0.98))
		alpha[pd] = 0.5 * ln(p01 / p10)
		p00 = (c00 + c01 >= 1 ? c00 / (c00 + c01) : 0)
		p11 = (c10 + c11 >= 1 ? c11 / (c10 + c11) : 0)
		p00 = min((max((p00, 0.02)), 0.98))
		p11 = min((max((p11, 0.02)), 0.98))
		prec[pd] = (c01 * c10 >= 1 ? 4 / (p00/c01 + p11/c10) : 1e-6)
	}
	return(min((max((sum(alpha :* prec) / sum(prec), -3)), 3)))
}

/* ===================================================================
   SaomEstimateRM: two waves. A wrapper around SaomEstimateNet() (one
   period); see there for the estimator.

   Gobs_start, Gobs_end: the observed waves (read-only).
   theta0: starting values of the effects; rate0: starting value of the
     rate (missing or <= 0: the closed form).
   K0, K3: phase-1 and phase-3 replicates; firstg: phase-2 initial gain.
   Optional, in this order (a later one requires the earlier ones;
   placeholders: an all-ones `present', an all-zero `missMask', an
   all-zero `fntype', a 0 x 1 `ratecovattr'):
     present (n x 1, composition change), missMask (n x n, 1 = dyad
     missing at either wave), fntype (network endowment/creation codes
     per term), ratecovattr (ratecov() covariate) and ratecoef (its
     starting value), symtype (0 directed, 1 BJOINT, 2 BFORCE, 3 BAGREE, 4 AFORCE, 5 AAGREE),
     structural (n x n, 1 = structurally fixed dyad).
   =================================================================== */
struct SaomFit scalar SaomEstimateRM(class ErgmGraph scalar Gobs_start,
	class ErgmGraph scalar Gobs_end, class ErgmModel scalar M,
	real rowvector theta0, real scalar rate0,
	real scalar K0, real scalar K3, real scalar firstg, | real colvector present,
	real matrix missMask, real rowvector fntype,
	real matrix ratecovattr, real rowvector ratecoef, real scalar symtype,
	real matrix structural) {

	struct SaomFit scalar fit
	struct SaomNetCtx scalar C
	struct SaomNetFit scalar nf
	pointer(real matrix) rowvector mm
	real matrix presentArg, structArg
	real rowvector fnArg, par0
	real matrix rcArg
	real scalar nargs, symArg, p, k

	nargs = args()
	presentArg = J(0, 0, 0)
	mm = J(1, 0, NULL)
	fnArg = J(1, 0, 0)
	rcArg = J(0, 1, 0)
	symArg = 0
	structArg = J(0, 0, 0)
	if (nargs >= 9) presentArg = present
	if (nargs >= 10) {
		if (rows(missMask) > 0) mm = (&missMask)
	}
	if (nargs >= 11) fnArg = fntype
	if (nargs >= 12) rcArg = ratecovattr
	if (nargs >= 14) symArg = symtype
	if (nargs >= 15) structArg = structural

	C.cond = SaomCondRequested()
	SaomNetCtxInit(C, (&Gobs_start, &Gobs_end), M, presentArg, mm, fnArg, rcArg, symArg, structArg)
	p = C.p
	par0 = theta0
	// symmetric (pairwise) models: rate0() is on RSiena's scale, see
	// SaomSymRateScale()
	if (!C.cond) par0 = par0, ((rate0 < . & rate0 > 0) ? ((C.symtype >= 1 & C.symtype <= 3) ? rate0^2 * SaomSymRateScale(C) : rate0) : SaomRateStart(C.npresentPd[1], C.targetRate[1]))
	// one starting value per ratecov() variable (a single value is used
	// for all of them)
	if (C.hasratecov) par0 = par0, (nargs >= 13 ? (cols(ratecoef) == C.hasratecov ? ratecoef : J(1, C.hasratecov, ratecoef[1])) : J(1, C.hasratecov, 0))

	nf = SaomEstimateNet(C, M, par0, K0, K3, firstg)

	fit.theta = nf.par[1..p]
	fit.tratio = nf.tratio[1..p]
	fit.theta_path = nf.theta_path
	fit.Vfull = nf.Vfull
	fit.V = nf.Vfull[1..p, 1..p]
	fit.tconv = nf.tconv
	fit.tconvMax = nf.tconvMax
	fit.rmfixed = nf.rmfixed
	fit.cond = C.cond
	if (C.cond) {
		fit.rate = mean(nf.T)
		fit.rate_se = sqrt(variance(nf.T))
		fit.rate_tratio = .
	}
	else {
		fit.rate = nf.par[p+1]
		fit.rate_tratio = nf.tratio[p+1]
		fit.rate_se = sqrt(nf.Vfull[p+1, p+1])
	}
	fit.rate_actor = fit.rate
	// pairwise (B) types only; the unilateral (A) types use the per-actor
	// rate, which is RSiena's rate for them
	if (C.symtype >= 1 & C.symtype <= 3) SaomSymRateToRSiena(fit, C, p)
	fit.rates = fit.rate
	fit.rate_tratios = fit.rate_tratio
	fit.rate_ses = fit.rate_se
	if (C.hasratecov) {
		k = C.ptot - C.hasratecov
		fit.ratecoef = nf.par[(k+1)..C.ptot]
		fit.ratecoef_se = sqrt(diagonal(nf.Vfull)[(k+1)..C.ptot])'
		fit.ratecoef_tratio = nf.tratio[(k+1)..C.ptot]
		fit.ratecoef_fixed = nf.rmfixed[(k+1)..C.ptot]
	}
	return(fit)
}

/* ===================================================================
   SaomEstimateRMMulti: two or more waves. The effects are shared by
   every period (their statistics are summed over periods, as in RSiena),
   each period has its own rate. A wrapper around SaomEstimateNet().

   Gwaves: pointers to the observed waves, in temporal order (read-only).
   Optional: presentMat (n x nwaves, actor present at each wave; an
   actor is active in a period when present at both of its waves),
   missMaskPd (one n x n mask per period), rates0 (starting rates, one
   per period; empty or missing entries: the closed form). Placeholders
   to reach a later argument: J(0,0,0) and J(1,0,NULL).
   =================================================================== */
struct SaomFit scalar SaomEstimateRMMulti(pointer(class ErgmGraph scalar) rowvector Gwaves,
	class ErgmModel scalar M, real rowvector theta0, real scalar K0, real scalar K3,
	real scalar firstg, | real matrix presentMat, pointer(real matrix) rowvector missMaskPd,
	real rowvector rates0) {

	struct SaomFit scalar fit
	struct SaomNetCtx scalar C
	struct SaomNetFit scalar nf
	pointer(real matrix) rowvector mm
	real matrix presentPd
	real rowvector par0, r0
	real scalar P, pd, p, nargs

	nargs = args()
	P = cols(Gwaves) - 1
	presentPd = J(0, 0, 0)
	if (nargs >= 7) {
		if (rows(presentMat) > 0) {
			presentPd = J(rows(presentMat), P, 0)
			for (pd=1; pd<=P; pd++) presentPd[.,pd] = presentMat[.,pd] :* presentMat[.,pd+1]
		}
	}
	mm = J(1, 0, NULL)
	if (nargs >= 8) mm = missMaskPd

	C.cond = SaomCondRequested()
	SaomNetCtxInit(C, Gwaves, M, presentPd, mm, J(1, 0, 0), J(0, 1, 0), 0, J(0, 0, 0))
	p = C.p
	r0 = J(1, P, .)
	if (nargs >= 9) {
		if (cols(rates0) == P) r0 = rates0
		else if (cols(rates0) == 1) r0 = J(1, P, rates0)
	}
	for (pd=1; pd<=P; pd++) if (!(r0[pd] < . & r0[pd] > 0)) r0[pd] = SaomRateStart(C.npresentPd[pd], C.targetRate[pd])
	par0 = (C.cond ? theta0 : (theta0, r0))

	nf = SaomEstimateNet(C, M, par0, K0, K3, firstg)

	fit.theta = nf.par[1..p]
	fit.tratio = nf.tratio[1..p]
	fit.theta_path = nf.theta_path
	fit.Vfull = nf.Vfull
	fit.V = nf.Vfull[1..p, 1..p]
	fit.tconv = nf.tconv
	fit.tconvMax = nf.tconvMax
	fit.rmfixed = nf.rmfixed
	fit.cond = C.cond
	if (C.cond) {
		fit.rates = mean(nf.T)
		fit.rate_ses = sqrt(diagonal(variance(nf.T)))'
		fit.rate_tratios = J(1, P, .)
	}
	else {
		fit.rates = nf.par[(p+1)..(p+P)]
		fit.rate_tratios = nf.tratio[(p+1)..(p+P)]
		fit.rate_ses = sqrt(diagonal(nf.Vfull)[(p+1)..(p+P)])'
	}
	return(fit)
}

/* ===================================================================
   Co-evolution (harmonisation unit 26, docs/SAOM_ROADMAP.md "Co-evolution
   (network + behavior)" - DESIGN section has the full source-verification
   account). This section adds a SECOND kind of dependent variable - a
   bounded integer-valued actor attribute ("behavior") that evolves
   ALONGSIDE the network between the same observed waves - so that
   selection (network effects depending on the behavior, already
   implemented: simcov()/nodeicov()/nodeocov()) and influence (behavior
   effects depending on the network) can be estimated JOINTLY in one
   model, the gap this codebase's own docs/book chapter explicitly
   disclosed as not yet implemented.

   SaomBehavior: the behavior-side analogue of ErgmGraph - owns the
   actor-level current values (mutated in place by ministeps, exactly
   like ErgmGraph.toggle() mutates edges) plus the fixed, observed-data-
   derived constants (min/max/range/overallMean) every behavior effect
   below needs. `values' uses real (not integer) storage for uniformity
   with every other Mata numeric array in this codebase, but every value
   a ministep ever writes is a whole number by construction (initial
   integer values, changed only by +1/-1/0).
   =================================================================== */
class SaomBehavior {
	real scalar n
	real colvector values		// current, mutated in place by SaomBehaviorMinistep()
	real scalar minval
	real scalar maxval
	real scalar range		// maxval - minval, RSiena's own "range" (observed, not simulated)
	real scalar overallMean	// mean of every OBSERVED wave's own values, pooled - fixed for the whole model, matching RSiena's own BehaviorLongitudinalData::overallMean()
	real scalar simMean		// RSiena's own data-derived "similarityMean" constant (avsim only) - see saom_similarity_mean() below; defaults to 0 (harmless for every OTHER effect, which never reads this field)

	void init()
	real scalar value()
	void setvalue()
	real scalar centeredValue()
	void setsimmean()
}

void SaomBehavior::init(real colvector initvals, real scalar minv, real scalar maxv, real scalar mean0, | real scalar simmean0){
	n = rows(initvals)
	values = initvals
	minval = minv
	maxval = maxv
	range = maxv - minv
	overallMean = mean0
	simMean = (args()==5 ? simmean0 : 0)
}

void SaomBehavior::setsimmean(real scalar sm){
	simMean = sm
}

real scalar SaomBehavior::value(real scalar i){
	return(values[i])
}

void SaomBehavior::setvalue(real scalar i, real scalar v){
	values[i] = v
}

real scalar SaomBehavior::centeredValue(real scalar i){
	return(values[i] - overallMean)
}

/*
   Behavior effects (v1 scope: linear shape, quadratic shape, avAlt -
   see docs/SAOM_ROADMAP.md's own unit-26 DESIGN section for exactly
   which RSiena source file/formula each is verified against, and which
   are explicitly deferred - avSim, endowment/creation functions). Every
   stat/change function takes (Beh, G) uniformly, even though linear/
   quadratic never touch G - avAlt needs it, and a uniform signature
   lets SaomBehaviorModel below dispatch through one function-pointer
   type regardless of which specific effect is wired in, matching
   ErgmModel's own established "uniform signature across genuinely
   different terms" convention.
*/

/*
   Linear shape (RSiena's own LinearShapeEffect.cpp) - the behavior-side
   analogue of `outdegree': REQUIRED in every co-evolution model, same
   "baseline, always-included" role. Ministep delta for actor i changing
   by `diff' (in {-1,0,1}) is exactly `diff' (calculateChangeContribution()
   returns the raw difference, unmodified). Global/observed statistic is
   the UNCENTERED sum of every actor's own current value
   (egoStatistic() returns currentValues[ego] directly, no centering).
*/
real rowvector stat_saom_linear(class SaomBehavior scalar Beh, class ErgmGraph scalar G){
	return(sum(Beh.values))
}
real scalar change_saom_linear(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i, real scalar diff){
	return(diff)
}

/*
   Quadratic shape (RSiena's own QuadraticShapeEffect.cpp) - captures
   whether actors' own behavior tends toward the extremes of its
   observed range (positive coefficient) or the middle (negative). A
   real, easy-to-miss subtlety caught only by reading the actual C++
   source, not the SIENA manual, and kept exactly as RSiena has it
   rather than "corrected" toward internal consistency (see this file's
   own unit-26 DESIGN account for why): the MINISTEP delta uses the
   CENTERED value (`2*centeredValue(i) + diff) * diff' - the exact
   algebraic delta of `(centeredValue(i)+diff)^2 - centeredValue(i)^2'),
   but the GLOBAL/observed statistic (egoStatistic() in the real source)
   sums the RAW, UNCENTERED `value_i^2' - two genuinely different scales
   for the same effect, both needed, matching RSiena's own real numbers
   being this codebase's own certification standard throughout.
*/
real rowvector stat_saom_quadratic(class SaomBehavior scalar Beh, class ErgmGraph scalar G){
	return(sum(Beh.values :* Beh.values))
}
real scalar change_saom_quadratic(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i, real scalar diff){
	return((2*Beh.centeredValue(i) + diff) * diff)
}

/*
   Average alter ("avAlt", RSiena's own AverageAlterEffect.cpp,
   divide=TRUE/alterPopularity=FALSE construction - the canonical
   INFLUENCE effect): s_i(x) = value_i * avg_{j in N_out(i)}(value_j), 0
   if i has no out-ties (confirmed from source: both the ministep delta
   and egoStatistic() guard on outDegree(i)>0, no fallback term). A
   positive coefficient means actors' own behavior moves toward their
   network neighbors' own average behavior - the influence side of
   co-evolution, the reason this whole unit exists. Ministep delta for
   actor i changing by `diff': `diff * avg_{j in N_out(i)}(value_j)' -
   PURELY linear in diff (no diff^2 term, unlike quadratic shape),
   because only i's own value changes during this ministep, never the
   alters' own (confirmed algebraically from the source: `contribution =
   difference * totalAlterValue(actor)', no self-interaction term).
*/
/* CENTERED values (fixed 2026-09-30). RSiena's AverageAlterEffect works
   on centered values throughout: the statistic is
   sum_i (z_i - zbar) * avg_{j in N_out(i)} (z_j - zbar) and the ministep
   contribution is diff * avg_{j in N_out(i)} (z_j - zbar), zbar =
   overallMean. The earlier version used raw values in both. For the
   change statistic that is not a reparametrization: the raw version adds
   diff*zbar for every actor WITH out-ties only, a different model. Checked
   against RSiena 1.6.6's target statistic on s50 (31.8586 for period 1,
   which only the centered formula reproduces). */
real rowvector stat_saom_avalt(class SaomBehavior scalar Beh, class ErgmGraph scalar G){
	real scalar i, tot
	real rowvector nb

	tot = 0
	for (i=1; i<=G.n; i++) {
		nb = G.neighbors_out(i)
		if (cols(nb) == 0) continue
		tot = tot + Beh.centeredValue(i) * (mean(Beh.values[nb']) - Beh.overallMean)
	}
	return(tot)
}
real scalar change_saom_avalt(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i, real scalar diff){
	real rowvector nb

	nb = G.neighbors_out(i)
	if (cols(nb) == 0) return(0)
	return(diff * (mean(Beh.values[nb']) - Beh.overallMean))
}

/*
   Average similarity ("avSim", RSiena's own SimilarityEffect.cpp,
   average=TRUE/alterPopularity=FALSE/egoPopularity=FALSE/hi=TRUE/
   lo=TRUE construction - confirmed directly from the real C++ source
   AND from EffectFactory.cpp's own `effectName == "avSim"' branch,
   `new SimilarityEffect(pEffectInfo, true, false, false, true, true)',
   not guessed from the SIENA manual): a SECOND, alternative influence
   parameterization to `avalt' above - instead of pulling an actor's own
   value toward its neighbors' own AVERAGE VALUE, `avsim' pulls it
   toward maximizing its own AVERAGE SIMILARITY to neighbors
   (sim(a,b) = 1 - |a-b|/range), net of a DATA-DERIVED "similarityMean"
   centering constant (RSiena's own `b0'-style constant, exactly the
   same role `balance''s own `balanceMean' plays on the network side -
   see `saom_similarity_mean()' below).

   `calculateChangeContribution()' (the ministep delta), re-derived
   algebraically from source for the exactly-two `diff' values a
   behavior ministep ever proposes (RSiena's own `numberAlterHigher(i)'/
   `numberAlterLower(i)'/`numberAlterEqual(i)' count out-neighbors with
   CURRENT value strictly greater/less/equal to actor i's own CURRENT
   value - confirmed from `NetworkDependentBehaviorEffect::
   preprocessEgo()'): for `diff'=+1, `totalChange' =
   `numberAlterHigher-numberAlterEqual-numberAlterLower' =
   `2*numberAlterHigher-outDegree(i)' (since the three counts sum to
   `outDegree(i)'); for `diff'=-1, `totalChange' =
   `2*numberAlterLower(i)-outDegree(i)' by the same algebra. Both are
   then divided by `range*outDegree(i)' (the `average=TRUE' branch) -
   `similarityMean' does NOT enter the ministep delta at all (only the
   GLOBAL statistic below is centered - confirmed directly from source:
   the centering `if' block in `calculateChangeContribution()' is
   INSIDE the `else' of `if (this->laverage)', so it is skipped whenever
   `average=TRUE', exactly `avsim''s own case).

   `egoStatistic()' (the global/observed statistic), for actor i with
   `outDegree(i)>0': `avg_{j in N_out(i)}(sim(value_i,value_j)) -
   similarityMean' - re-derived directly from the accumulator logic
   (`statistic = totalCount - sum(|diff_j|)/range', which is exactly
   `sum_j sim(value_i,value_j)' since `totalCount=outDegree(i)' here,
   then centered by `-outDegree(i)*similarityMean' and averaged by
   `/outDegree(i)'). 0 for an actor with no out-ties (confirmed: the
   real source's own `outDegree(ego)==0' short-circuit leaves
   `statistic' at its initial value 0, matching `avalt''s own identical
   convention above).
*/
real rowvector stat_saom_avsim(class SaomBehavior scalar Beh, class ErgmGraph scalar G){
	real scalar i, tot, od, vego, sumabs, k
	real rowvector nb

	tot = 0
	for (i=1; i<=G.n; i++) {
		nb = G.neighbors_out(i)
		od = cols(nb)
		if (od == 0) continue
		vego = Beh.value(i)
		sumabs = 0
		for (k=1; k<=od; k++) sumabs = sumabs + abs(Beh.value(nb[k]) - vego)
		tot = tot + (1 - (sumabs/Beh.range)/od - Beh.simMean)
	}
	return(tot)
}
real scalar change_saom_avsim(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i, real scalar diff){
	real rowvector nb
	real scalar od, vego, nhigh, nlow, k

	if (diff == 0) return(0)
	nb = G.neighbors_out(i)
	od = cols(nb)
	if (od == 0) return(0)
	vego = Beh.value(i)
	nhigh = 0
	nlow = 0
	for (k=1; k<=od; k++) {
		if (Beh.value(nb[k]) > vego) nhigh++
		else if (Beh.value(nb[k]) < vego) nlow++
	}
	if (diff > 0) return((2*nhigh - od) / (Beh.range * od))
	else return((2*nlow - od) / (Beh.range * od))
}

/*
   `saom_similarity_mean()': the data-derived `similarityMean' constant
   `avsim' needs (see above) - verified directly against the R-side
   `rangeAndSimilarity()' (`R/sienaDataCreate.r'), which is what
   actually computes it (the C++ side only ever reads a pre-computed
   value off the data object, `BehaviorLongitudinalData::
   similarityMean()' - confirmed by grepping `siena07internals.cpp',
   there is no C++-side computation to re-derive here). Pooled EXACTLY
   like `saom_balance_mean()' above: every PERIOD-BASE wave (i.e. every
   observed wave except the very last - confirmed from
   `rangeAndSimilarity(tmpmat[, -ncol(tmpmat)], rr)''s own column
   slice), every ORDERED pair of distinct actors within that wave,
   averaged as `sim(a,b) = 1-|a-b|/range' over the whole pooled set (sum
   of numerators over sum of counts, not an average of per-wave means -
   same summed-pooling convention as `balanceMean'/theta/the Jacobian
   throughout this codebase). A real, easy-to-miss quirk kept faithfully
   (verified directly from `rangeAndSimilarity()''s own `zeroOrNA(var(...))'
   branch, NOT invented): if every pooled base-wave value is IDENTICAL
   (zero variance), `simMean' is defined as exactly 0 - NOT the 1 the
   general formula would otherwise give when every pairwise difference
   is 0 (`1-0/range=1'). This only matters for a degenerate,
   already-unusable dataset (a behavior with no variation at all cannot
   identify ANY behavior effect), but is kept exactly as RSiena has it
   per this whole package's own certification standard.
*/
real scalar saom_similarity_mean(pointer(real colvector) rowvector Behwaves, real scalar range){
	real scalar nwaves, nbase, n, w, i, j, simTotal, simCnt
	real colvector v, allbase

	nwaves = cols(Behwaves)
	nbase = nwaves - 1
	if (nbase < 1) return(0)

	allbase = *Behwaves[1]
	for (w=2; w<=nbase; w++) allbase = allbase \ *Behwaves[w]
	if (variance(allbase) <= 0) return(0)

	simTotal = 0
	simCnt = 0
	for (w=1; w<=nbase; w++) {
		v = *Behwaves[w]
		n = rows(v)
		for (i=1; i<=n; i++) {
			for (j=1; j<=n; j++) {
				if (j == i) continue
				simTotal = simTotal + (1 - abs(v[i]-v[j])/range)
				simCnt++
			}
		}
	}
	return(simCnt==0 ? 0 : simTotal/simCnt)
}

/* ===================================================================
   SaomBehaviorModel: the behavior-side analogue of ErgmModel - a
   minimal term registry (no curved-parameter support, no native-backend
   plumbing, no MPLE - none of those apply to a v1 behavior model),
   mirroring ErgmModel's own addterm()/nparam()/full_statistic()/
   full_change() pattern exactly for the parts that DO carry over.
   =================================================================== */
class SaomBehaviorModel {
	real scalar nterms
	string rowvector names
	pointer rowvector statfn	// pointer(real rowvector function(SaomBehavior, ErgmGraph)) scalar
	pointer rowvector chgfn	// pointer(real scalar function(SaomBehavior, ErgmGraph, real scalar, real scalar)) scalar
	string rowvector coefnames	// one per term (every v1 behavior effect is single-parameter)
	real scalar simMean		// avsim's own data-derived constant, computed ONCE by nwsaom.ado (saom_similarity_mean()) and stored here - mirrors ErgmTermData's own td.decay convention for balance's data-derived mean; 0 (harmless) whenever avsim is not in the model
	real rowvector fntype		// harmonisation unit 28 - one per term: 0=eval (default, every existing v1 effect), 1=endowment, 2=creation - see full_change()'s own header comment for the direction-gating this drives

	void init()
	void addterm()
	real scalar nparam()
	real rowvector full_statistic()
	real rowvector full_change()
	void setsimmean()
}

void SaomBehaviorModel::init(){
	nterms = 0
	names = J(1, 0, "")
	statfn = J(1, 0, NULL)
	chgfn = J(1, 0, NULL)
	coefnames = J(1, 0, "")
	simMean = 0
	fntype = J(1, 0, 0)
}

void SaomBehaviorModel::setsimmean(real scalar sm){
	simMean = sm
}

void SaomBehaviorModel::addterm(string scalar name,
	pointer(real rowvector function) scalar sfn,
	pointer(real scalar function) scalar cfn,
	string scalar cname, | real scalar ftype){

	nterms++
	names = (names, name)
	statfn = (statfn, sfn)
	chgfn = (chgfn, cfn)
	coefnames = (coefnames, cname)
	fntype = (fntype, (args()==5 ? ftype : 0))
}

real scalar SaomBehaviorModel::nparam(){
	return(nterms)
}

real rowvector SaomBehaviorModel::full_statistic(class SaomBehavior scalar Beh, class ErgmGraph scalar G){
	real rowvector out
	real scalar t

	out = J(1, nterms, 0)
	for (t=1; t<=nterms; t++) out[t] = (*statfn[t])(Beh, G)[1]
	return(out)
}

/* SaomMaskedBehaviorStatistic - harmonisation unit 35 (missing data),
   see the "Missing data" header comment further up this file for the
   full design account. Reuses the EXISTING, unmodified
   Mbeh.full_statistic() on a scratch SaomBehavior copy whose masked
   actors' values are set to Beh.overallMean - equivalent to RSiena's
   own "replace the centered value by 0" rule at the raw-value level,
   for any behavior effect, with zero changes to already-certified
   stat_saom_X()/change_saom_X() code.

   `missMaskPeriodNet' (n x n) - REQUIRED, not optional, unlike its
   name might suggest - is used to build the SAME masked graph copy
   SaomMaskedStatistic() itself computes (SaomBuildMaskedGraph()),
   passed to Mbeh.full_statistic() INSTEAD of the raw G. A real,
   corrected bug: network-DEPENDENT behavior effects (avAlt/avSim, which
   read a behavior-unmasked actor's own ALTERS' current values) would
   otherwise read the raw, un-masked graph even when the model also has
   an active missnet() - a masked/corrupted dyad could then corrupt an
   otherwise-fully-observed actor's own avAlt/avSim reading via that
   actor's real (masked) ties, never excluded from the target/simulated
   statistic the way the network side's own outdegree/reciprocity
   statistics correctly are. Found via a direct, measured certification
   failure (SaomEstimateRMCoevMulti()'s own missing-data recovery test,
   cscripts/test_nwsaom_mata.do's saom_test_unit35_coevmulti_rec(),
   diverged severely and repeatably on thetaBeh before this fix, not an
   occasional fluke). Behavior-only missing data (no missnet()) passes
   an all-zero network mask here (nwsaom.ado's own established "never
   branch at the call site" convention), so this graph-masking is a
   pure no-op (SaomBuildMaskedGraph() returns an unmodified copy) in
   that case, at the cost of one harmless extra graph copy. */
real rowvector SaomMaskedBehaviorStatistic(class SaomBehavior scalar Beh,
	class ErgmGraph scalar G, class SaomBehaviorModel scalar Mbeh,
	real colvector missMaskPeriodBeh, real matrix missMaskPeriodNet) {

	class SaomBehavior scalar Bm
	real scalar i, n

	n = Beh.n
	Bm = SaomBehavior()
	Bm.init(Beh.values, Beh.minval, Beh.maxval, Beh.overallMean, Beh.simMean)
	for (i=1; i<=n; i++) {
		if (missMaskPeriodBeh[i] != 0) Bm.setvalue(i, Beh.overallMean)
	}
	return(Mbeh.full_statistic(Bm, SaomBuildMaskedGraph(G, missMaskPeriodNet)))
}

/* full_change(): harmonisation unit 28 - endowment/creation direction
   gating, verified directly against real RSiena source
   (NetworkVariable.cpp's own calculateTieFlipContributions(): "The
   endowment effects have non-zero contributions on tie withdrawals
   only" / "The tie creation effects have non-zero contributions on tie
   creation only" - the behavior-side analogue,
   BehaviorVariable::totalEndowmentContribution(), gates identically on
   `difference' sign). An endowment-type term (fntype=1) contributes
   ONLY when `diff' is a DOWN move (diff<0); a creation-type term
   (fntype=2) contributes ONLY when `diff' is an UP move (diff>0); an
   eval-type term (fntype=0, every existing v1 effect) is unaffected,
   contributing at every diff exactly as before. Reuses each term's own
   ALREADY-CERTIFIED eval change_saom_X() function directly for the
   gated formula (verified for `linear' specifically: RSiena's own
   `egoEndowmentStatistic()'/`egoStatistic()' pair for
   LinearShapeEffect.cpp uses the SAME raw `difference' formula in both
   the eval and endowment/creation cases, just restricted to one sign -
   see docs/SAOM_ROADMAP.md's own unit-28 entry for the full
   derivation) - NOT a generic claim true of every possible effect,
   which is exactly why v1 scope is `linear' only (see nwsaom.ado's own
   validation). */
real rowvector SaomBehaviorModel::full_change(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i, real scalar diff){
	real rowvector out
	real scalar t

	out = J(1, nterms, 0)
	for (t=1; t<=nterms; t++) {
		if (fntype[t] == 1 & diff >= 0) continue
		if (fntype[t] == 2 & diff <= 0) continue
		out[t] = (*chgfn[t])(Beh, G, i, diff)
	}
	return(out)
}

/* SaomBehaviorPatchEndowCreation(): harmonisation unit 28 - replaces
   the endowment/creation-type slots of an ALREADY-COMPUTED joint
   (network+behavior) statistic vector with their own REAL target,
   computed directly from a (starting values, current/final values)
   pair rather than via `full_statistic()' (which only ever evaluates a
   SINGLE behavior snapshot, the right contract for every eval-type
   term but not for endowment/creation - see NetworkEffect.cpp's own
   `statistic(pSummationTieNetwork)' - X=initial/Y=lost-ties-network for
   endowment, X=initial/Y=gained-ties-network for creation - the
   behavior-side analogue this function ports, restricted to `linear'
   per this unit's own v1 scope: RSiena's own `LinearShapeEffect::
   egoEndowmentStatistic()' sums the raw signed difference over actors
   whose value DECREASED - `sum(d :* (d:<0))' below is exactly that,
   re-derived in this codebase's own (end-start) sign convention;
   creation is the exact mirror, RSiena's own
   `creationStatistic()' trick of summing over GAINED changes instead
   of lost ones). Used identically for the OBSERVED target (startvals=
   Behobs_start_values, currentvals=Behobs_end_values) and for EVERY
   simulated replicate's own deviation (startvals=Behobs_start_values,
   currentvals=Behwork.values - Behwork always starts each replicate
   from Behobs_start_values by construction, matching the SAME
   (initial, current) pairing real RSiena's own construction uses). */
real rowvector SaomBehaviorPatchEndowCreation(class SaomBehaviorModel scalar Mbeh, real rowvector stat,
	real scalar pNet, real colvector startvals, real colvector currentvals){

	real scalar t
	real colvector d

	d = currentvals - startvals
	for (t=1; t<=Mbeh.nterms; t++) {
		if (Mbeh.fntype[t] == 1) stat[pNet+t] = sum(d :* (d :< 0))
		else if (Mbeh.fntype[t] == 2) stat[pNet+t] = sum(d :* (d :> 0))
	}
	return(stat)
}

/* SaomMaskCoevEndowCreationValues: harmonisation unit 35 (missing
   data) masking for SaomBehaviorPatchEndowCreation() above - a design
   choice reasoned from first principles (RSiena's own manual does not
   spell out this specific endowment/creation-under-missing-data
   combination directly), not a direct RSiena-source citation like the
   rest of this unit's own masking rules. Endowment/creation statistics
   are sums of `currentvals - startvals' (a DIFFERENCE), so "exclude
   this actor" means forcing that actor's own difference to exactly 0
   (`currentvals[i] := startvals[i]'), NOT replacing the raw value with
   overallMean the way SaomMaskedBehaviorStatistic() does for ordinary
   eval-type eval effects - the two masking rules are genuinely
   different because the two statistic FORMS are genuinely different
   (a level vs. a difference), even though both express the same
   underlying intent ("this actor contributes nothing to this period's
   own statistic"). */
real colvector SaomMaskCoevEndowCreationValues(real colvector currentvals,
	real colvector startvals, real colvector missMaskBeh) {

	real colvector out
	real scalar i, n

	n = rows(currentvals)
	out = currentvals
	for (i=1; i<=n; i++) if (missMaskBeh[i] != 0) out[i] = startvals[i]
	return(out)
}

/* ===================================================================
   SaomBehaviorMinistep: one actor's own behavior ministep - exactly
   THREE alternatives (down/stay/up, clamped at the observed min/max
   range), confirmed directly from RSiena's own BehaviorVariable.cpp
   (`this->lprobabilities = new double[3]', `nextIntWithProbabilities(3,
   ...)'), NOT up to n-1 alternatives the way a network ministep has -
   the same multinomial-logit/softmax construction Chapter 22's own
   McFadden formula documents (docs/SAOM_ROADMAP.md's own DESIGN
   section), now over 3 alternatives instead of n. Mutates Beh in place
   via Beh.setvalue() if a real change is drawn. Returns the chosen
   diff (-1, 0, or +1).
   =================================================================== */
real scalar SaomBehaviorMinistep(class SaomBehavior scalar Beh, class ErgmGraph scalar G,
	class SaomBehaviorModel scalar Mbeh, real rowvector theta, real scalar i) {

	real scalar cur, uDown, uUp, maxu, denom, draw, diff
	real rowvector chg

	cur = Beh.value(i)

	uDown = .
	if (cur > Beh.minval) {
		chg = Mbeh.full_change(Beh, G, i, -1)
		uDown = theta * chg'
	}
	uUp = .
	if (cur < Beh.maxval) {
		chg = Mbeh.full_change(Beh, G, i, 1)
		uUp = theta * chg'
	}

	// numerically stable softmax over {uDown (if valid), 0 for "stay", uUp (if valid)}
	maxu = 0
	if (uDown != . & uDown > maxu) maxu = uDown
	if (uUp != . & uUp > maxu) maxu = uUp

	denom = exp(0 - maxu)
	if (uDown != .) denom = denom + exp(uDown - maxu)
	if (uUp != .) denom = denom + exp(uUp - maxu)

	draw = runiform(1,1) * denom
	diff = 0
	if (uDown != .) {
		if (draw <= exp(uDown - maxu)) {
			diff = -1
			Beh.setvalue(i, cur - 1)
			return(diff)
		}
		draw = draw - exp(uDown - maxu)
	}
	if (draw <= exp(0 - maxu)) {
		return(0)	// "stay" drawn
	}
	// only uUp's own share remains
	diff = 1
	Beh.setvalue(i, cur + 1)
	return(diff)
}

/* ===================================================================
   Joint (network + behavior) simulation and estimation - the rest of
   harmonisation unit 26. Shipped Mata-only first (matching gwesp/
   transties/balance's own precedent, unit 22/23/25: ship
   correct-and-slow first, port to C only once certified) - a native
   (C) port now also exists (SaomSimulateIntervalCoevNative(),
   further below), used automatically whenever every term on BOTH
   sides has native coverage; SaomSimulateIntervalCoevScored() below
   remains the certified reference/fallback, always available. Mirrors
   RSiena's own multi-variable race directly (confirmed from
   `EpochSimulation.cpp`'s own `chooseVariable()`/`drawTimeIncrement()`,
   docs/SAOM_ROADMAP.md's own unit-26 DESIGN section): ONE pooled
   exponential waiting time drawn from the GRAND total rate (network's
   own total rate + behavior's own total rate), then the acting
   VARIABLE is chosen with probability proportional to its own share of
   the grand total, then an actor uniformly within that variable
   (constant, actor-homogeneous rate - matching the network side's own
   existing v1 scope), then that variable's own ministep runs.
   =================================================================== */

/*
   Behavior rate: no dedicated closed-form formula exists in RSiena's
   own R source the way `networkRateEffects()` has one for the network
   (confirmed by direct search - no `behaviorRateEffects` function
   exists); real RSiena's own logic lives in `getBehaviorStartingVals()`
   (R/sienaDataCreate.r). v1 disclosed simplification (see
   docs/SAOM_ROADMAP.md's own unit-26 DESIGN section): use that
   function's own general (non-binary) branch core formula uniformly -
   `max(var(wave-to-wave differences), 0.1 + mean(|differences|))` -
   for both binary and multi-level behavior variables, skipping
   RSiena's own separate binary-specific logistic formula and its own
   `tendency` starting-value refinement (which only affects
   Robbins-Monro's own starting point for the linear-shape coefficient,
   not correctness).
*/
real scalar SaomBehaviorRateStart(real colvector startvals, real colvector endvals) {
	real colvector d

	d = endvals - startvals
	return(max((variance(d), 0.1 + mean(abs(d)))))
}

/* SaomBehaviorRateStartMasked: harmonisation unit 35 (missing data) -
   the SAME closed-form starting-rate formula above, but with every
   masked actor's own difference forced to 0 (excluded, "no apparent
   change" - the same neutral-difference convention
   SaomMaskCoevEndowCreationValues() already uses) before the variance/
   mean(abs()) computation. A real, measured gap this codebase's own
   network-side rate formula did NOT have (SaomEstimateRM()/Multi()
   start from the MASKED target distance -
   see SaomCountDifferingMasked()) but this behavior-side formula
   originally did: with `d' computed from RAW, unmasked endvals, even a
   handful of corrupted/imputed-placeholder actor values among a small
   n could dominate variance(d)/mean(abs(d)) and badly miscalibrate the
   whole period's own simulation rate (found via a real, direct
   certification failure - SaomEstimateRMCoevMulti()'s own missing-data
   recovery test occasionally diverged severely on thetaBeh before this
   fix, cscripts/test_nwsaom_mata.do's saom_test_unit35_coevmulti_rec()). */
real scalar SaomBehaviorRateStartMasked(real colvector startvals, real colvector endvals,
	real colvector missMaskBeh) {

	real colvector d
	real scalar i, n

	d = endvals - startvals
	n = rows(d)
	for (i=1; i<=n; i++) if (missMaskBeh[i] != 0) d[i] = 0
	return(max((variance(d), 0.1 + mean(abs(d)))))
}

/* ===================================================================
   SaomSimulateIntervalCoev: plain (non-scored) joint interval
   simulator - the co-evolution analogue of SaomSimulateInterval(),
   directly reusing the already-certified SaomMinistep()/
   SaomBehaviorMinistep() unmodified (unlike the scored version below,
   which must duplicate their internals to also expose the
   softmax-weighted expected-change vector). Mutates G and Beh in
   place. Used wherever a FITTED co-evolution model needs simulating
   forward (postestimation GOF, etc.) - estimation itself uses the
   scored version below.
   =================================================================== */
struct SaomCoevResult {
	real scalar steps
	real scalar nchangesNet
	real scalar nchangesBeh
	real scalar stepsNet		// ministep opportunities of each variable (the rate scores need them separately)
	real scalar stepsBeh
}

struct SaomCoevResult scalar SaomSimulateIntervalCoev(
	class ErgmGraph scalar G, class ErgmModel scalar M, real rowvector thetaNet,
	class SaomBehavior scalar Beh, class SaomBehaviorModel scalar Mbeh, real rowvector thetaBeh,
	real scalar rateNet, real scalar rateBeh, | real colvector present) {

	struct SaomCoevResult scalar res
	real scalar t, i, picked, totalRateNet, totalRateBeh, grandRate, draw, haspresent, npresent, hasbehsim
	real colvector presentIdx

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as every other simulator's own
	// identical parameter; see SaomSimulateInterval()'s own header
	// comment for the full account.
	haspresent = (args() == 9)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = G.n

	res.steps = 0
	res.nchangesNet = 0
	res.nchangesBeh = 0
	res.stepsNet = 0
	res.stepsBeh = 0
	totalRateNet = npresent * rateNet
	totalRateBeh = npresent * rateBeh
	grandRate = totalRateNet + totalRateBeh
	hasbehsim = SaomHasBehSim(M)
	if (hasbehsim) SaomBehSimSync(M, Beh.values)	// behsim reads the CURRENT behavior

	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / grandRate
		if (t < 1) {
			draw = runiform(1,1) * grandRate
			if (draw <= totalRateNet) {
				if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
				else i = ceil(runiform(1,1) * G.n)
				if (haspresent) picked = SaomMinistep(G, M, thetaNet, i, present)
				else picked = SaomMinistep(G, M, thetaNet, i)
				if (picked != 0) res.nchangesNet = res.nchangesNet + 1
				res.stepsNet = res.stepsNet + 1
			}
			else {
				if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
				else i = ceil(runiform(1,1) * Beh.n)
				picked = SaomBehaviorMinistep(Beh, G, Mbeh, thetaBeh, i)
				if (picked != 0) {
					res.nchangesBeh = res.nchangesBeh + 1
					if (hasbehsim) SaomBehSimSetValue(M, i, Beh.value(i))
				}
				res.stepsBeh = res.stepsBeh + 1
			}
			res.steps = res.steps + 1
		}
	}
	return(res)
}

/* ===================================================================
   SaomSimulateIntervalCoevScored: the SCORED joint interval simulator
   Robbins-Monro estimation needs (phases 1 and 3 - see
   SaomEstimateRMCoev() below), the co-evolution analogue of
   SaomSimulateIntervalScored(). Deliberately a PARALLEL implementation
   duplicating SaomMinistep()'s/SaomBehaviorMinistep()'s own internals
   (not a call-through), same rationale as
   SaomSimulateIntervalScored()'s own header comment: it needs the
   softmax-weighted EXPECTED change vector (`ebar') alongside the
   CHOSEN alternative's own change vector at every ministep, which the
   plain ministep functions don't expose.

   Score-function identity, generalized to two competing variables
   (verified algebraically, not assumed - see docs/SAOM_ROADMAP.md's
   own unit-26 DESIGN section): at any given ministep, only ONE
   variable acts (chosen via the constant, theta-independent rate
   race), and that variable's own choice probability depends ONLY on
   its OWN theta (via its own evaluation function) - the OTHER
   variable's theta contributes exactly ZERO to this specific
   ministep's own score, since neither the rate-based variable
   selection nor the acting variable's own softmax depends on it. So
   the joint score is simply the concatenation of "network score
   contribution when network acts, zero otherwise" and "behavior score
   contribution when behavior acts, zero otherwise", accumulated
   ministep by ministep exactly as SaomSimulateIntervalScored() already
   does for the network-only case.
   =================================================================== */
struct SaomCoevScoredResult {
	real scalar steps
	real scalar nchangesNet
	real scalar nchangesBeh
	real rowvector scoreNet
	real rowvector scoreBeh
	real rowvector stat		// harmonisation unit 31 - ONLY populated by SaomSimulateIntervalCoevNative() (the native path finally gets the SAME unit-14 optimization SaomSimulateIntervalNative() already had); SaomSimulateIntervalCoevScored() (the Mata path) leaves it empty, matching res.stat's own established convention on the network-only side
	real rowvector statBeh		// harmonisation unit 31 - behavior-side counterpart to `stat' above, same convention
	real scalar stepsNet		// ministep opportunities of each variable - the rate parameters' scores (stepsX/rateX - npresent) need them separately
	real scalar stepsBeh
	real rowvector statBehLag	// native path only (protocol >= 3): behavior statistics of the simulated end behavior on the period's STARTING network (the lagged statistics the co-evolution estimator uses), masked like SaomCoevStatBeh()
	real scalar netdist		// native path only: number of dyads in which the simulated end network differs from the start network (missing dyads excluded) - the network rate's moment statistic
}

struct SaomCoevScoredResult scalar SaomSimulateIntervalCoevScored(
	class ErgmGraph scalar G, class ErgmModel scalar M, real rowvector thetaNet,
	class SaomBehavior scalar Beh, class SaomBehaviorModel scalar Mbeh, real rowvector thetaBeh,
	real scalar rateNet, real scalar rateBeh, | real colvector present) {

	struct SaomCoevScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg, chgDown, chgUp
	real scalar t, n, pNet, pBeh, i, j, maxu, denom, draw, draw2, cum, choice, haspresent, npresent
	real scalar totalRateNet, totalRateBeh, grandRate, cur, uDown, uUp, diff, hasbehsim
	real colvector presentIdx

	n = G.n
	pNet = M.nparam()
	pBeh = Mbeh.nparam()
	res.scoreNet = J(1, pNet, 0)
	res.scoreBeh = J(1, pBeh, 0)
	res.steps = 0
	res.nchangesNet = 0
	res.nchangesBeh = 0
	res.stepsNet = 0
	res.stepsBeh = 0
	hasbehsim = SaomHasBehSim(M)
	if (hasbehsim) SaomBehSimSync(M, Beh.values)	// behsim reads the CURRENT behavior

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as every other simulator's own
	// identical parameter (see SaomSimulateInterval()'s own header
	// comment for the full account). A SINGLE `present' vector gates
	// BOTH variables - network and behavior share the same actor set in
	// co-evolution, so one presence mask suffices for which actor gets
	// ANY kind of ministep opportunity, and (network only) which actors
	// are eligible tie-target alternatives.
	haspresent = (args() == 9)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = n

	totalRateNet = npresent * rateNet
	totalRateBeh = npresent * rateBeh
	grandRate = totalRateNet + totalRateBeh

	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / grandRate
		if (t < 1) {
			draw = runiform(1,1) * grandRate
			if (draw <= totalRateNet) {
				// --- network ministep, scored (SaomSimulateIntervalScored()'s own inner logic, unmodified) ---
				if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
				else i = ceil(runiform(1,1) * n)
				chgmat = J(n, pNet, 0)
				u = J(1, n, 0)
				maxu = 0
				for (j=1; j<=n; j++) {
					if (j == i) continue
					if (haspresent) if (present[j] == 0) continue
					chgmat[j,.] = M.full_change(G, i, j)
					u[j] = thetaNet * chgmat[j,.]'
					if (u[j] > maxu) maxu = u[j]
				}
				denom = exp(0 - maxu)
				for (j=1; j<=n; j++) {
					if (j == i) continue
					if (haspresent) if (present[j] == 0) continue
					denom = denom + exp(u[j] - maxu)
				}
				ebar = J(1, pNet, 0)
				for (j=1; j<=n; j++) {
					if (j == i) continue
					if (haspresent) if (present[j] == 0) continue
					ebar = ebar + (exp(u[j]-maxu)/denom) * chgmat[j,.]
				}
				draw2 = runiform(1,1) * denom
				cum = exp(0 - maxu)
				choice = 0
				chosen_chg = J(1, pNet, 0)
				if (draw2 > cum) {
					for (j=1; j<=n; j++) {
						if (j == i) continue
						if (haspresent) if (present[j] == 0) continue
						cum = cum + exp(u[j] - maxu)
						choice = j
						if (draw2 <= cum) break
					}
					chosen_chg = chgmat[choice, .]
				}
				res.scoreNet = res.scoreNet + (chosen_chg - ebar)
				if (choice != 0) {
					G.toggle(i, choice)
					res.nchangesNet = res.nchangesNet + 1
				}
				res.stepsNet = res.stepsNet + 1
			}
			else {
				// --- behavior ministep, scored (SaomBehaviorMinistep()'s own 3-alternative logic, extended to track ebar/chosen_chg) ---
				if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
				else i = ceil(runiform(1,1) * Beh.n)
				cur = Beh.value(i)

				uDown = .
				chgDown = J(1, pBeh, 0)
				if (cur > Beh.minval) {
					chgDown = Mbeh.full_change(Beh, G, i, -1)
					uDown = thetaBeh * chgDown'
				}
				uUp = .
				chgUp = J(1, pBeh, 0)
				if (cur < Beh.maxval) {
					chgUp = Mbeh.full_change(Beh, G, i, 1)
					uUp = thetaBeh * chgUp'
				}

				maxu = 0
				if (uDown != . & uDown > maxu) maxu = uDown
				if (uUp != . & uUp > maxu) maxu = uUp

				denom = exp(0 - maxu)
				if (uDown != .) denom = denom + exp(uDown - maxu)
				if (uUp != .) denom = denom + exp(uUp - maxu)

				ebar = J(1, pBeh, 0)
				if (uDown != .) ebar = ebar + (exp(uDown-maxu)/denom) * chgDown
				if (uUp != .) ebar = ebar + (exp(uUp-maxu)/denom) * chgUp
				// "stay"'s own change vector is the zero vector - contributes nothing to ebar

				draw2 = runiform(1,1) * denom
				diff = 0
				chosen_chg = J(1, pBeh, 0)
				if (uDown != . & draw2 <= exp(uDown - maxu)) {
					diff = -1
					chosen_chg = chgDown
					Beh.setvalue(i, cur - 1)
				}
				else {
					if (uDown != .) draw2 = draw2 - exp(uDown - maxu)
					if (draw2 <= exp(0 - maxu)) {
						diff = 0
					}
					else {
						diff = 1
						chosen_chg = chgUp
						Beh.setvalue(i, cur + 1)
					}
				}
				res.scoreBeh = res.scoreBeh + (chosen_chg - ebar)
				if (diff != 0) {
					res.nchangesBeh = res.nchangesBeh + 1
					if (hasbehsim) SaomBehSimSetValue(M, i, Beh.value(i))
				}
				res.stepsBeh = res.stepsBeh + 1
			}
			res.steps = res.steps + 1
		}
	}
	return(res)
}

/* ===================================================================
   Multiplex SAOM, Stage 1 (two networks co-evolving, WITHIN-network
   effects only - no cross-network effects yet, see docs/SAOM_ROADMAP.md's
   own multiplex entry for the full scoping account and the concrete
   follow-on work this deliberately leaves open).

   RSiena's own real mechanism, verified from source
   (EpochSimulation.cpp's chooseVariable()/chooseActor(): a variable is
   picked with probability proportional to its own totalRate() among ALL
   of a model's dependent variables, then an actor within that variable
   proportional to that variable's own per-actor rate) is a fully GENERIC
   N-variable-of-mixed-type mechanism - network+behavior co-evolution
   (SaomEstimateRMCoev() above) and network+network (here) are the exact
   SAME underlying process in real RSiena, just instantiated with
   different variable types. nwsaom's own SaomEstimateRMCoev() is
   hardcoded for exactly one ErgmModel + one SaomBehaviorModel rather
   than a true N-variable list; rather than generalize that (a
   materially larger refactor touching the already-certified,
   heavily-relied-on net+behavior path), this is a PARALLEL
   implementation for exactly two ErgmModel/ErgmGraph instances -
   simpler in some ways than the net+behavior case, since both
   "variables" are the identical class (no SaomBehavior-specific
   min/max-value clamping, endowment/creation patching, or
   overallMean/simMean bookkeeping to carry).

   The two-network scored simulator below is NOT new logic - both of its
   branches are the IDENTICAL network-ministep mechanism already
   certified inside SaomSimulateIntervalCoevScored()'s own network
   branch (softmax over M.full_change() across every alternative alter,
   ebar/chosen_chg score-function bookkeeping), instantiated once per
   network rather than once for network + once for behavior. This is
   deliberately a duplication, not a call-through, matching this file's
   own established rationale elsewhere for why the scored simulators
   are hand-duplicated rather than composed (the softmax-weighted
   ebar/chosen_chg pair isn't exposed by the plain, unscored ministep
   helpers).

   v1 Stage-1 scope, matching how SaomEstimateRM() itself started before
   later units added present()/missMask()/N-wave chaining incrementally:
   exactly two waves, no composition change, no missing data, no native
   (C) port (falls through to pure Mata unconditionally) - each a
   disclosed, concretely-specified follow-on in docs/SAOM_ROADMAP.md,
   not a silent gap.
   =================================================================== */
struct SaomCoevNetNetScoredResult {
	real scalar steps
	real scalar steps1		// ministeps of network 1 (the rate-1 score is steps1/rate1 - n)
	real scalar steps2
	real scalar dist1		// native only: dyads in which network 1's end state differs from its start
	real scalar dist2
	real scalar nchanges1
	real scalar nchanges2
	real rowvector score1
	real rowvector score2
	real rowvector stat1		// native-only (SaomSimIntCoevNNNative()): the final simulated statistic vector for network 1, computed natively on the same final graph state - lets the caller skip a second Mata full_statistic() pass, mirroring the single-network native path's own res.stat optimization. Empty on the Mata path (SaomSimulateIntervalCoevNetNet() never sets it) - callers must branch on which simulator they called, not on whether this field happens to be populated.
	real rowvector stat2		// same, network 2
}

/* Native-first (per direct instruction) eligibility/termcode mapping for
   the two-network multiplex case - a SEPARATE, deliberately minimal
   helper from SaomNativeSetup() (the single-network mapping), not an
   extension of it: reusing SaomNativeSetup() directly would flag
   "crprod" as unrecognized and force cfg.eligible=0 for every multiplex
   model, since that function's own dispatch table has no entry for a
   cross-network effect (crprod was built Mata-only; this is its own
   first native consumer). v1 scope, matching
   SaomSimIntCoevNNNative()'s own restricted termcode set:
   outdegree/reciprocity/crprod only - anything else (nodecov, transtrip,
   isolatenet, ...) forces the existing, fully-general Mata fallback for
   the whole model, never a silent partial/wrong native run. */
struct SaomNNNativeConfig {
	real rowvector termcodes1, p1_1, termcodes2, p1_2
	real scalar eligible
}
struct SaomNNNativeConfig scalar SaomNativeSetupNN(class ErgmModel scalar M1, class ErgmModel scalar M2){
	struct SaomNNNativeConfig scalar cfg
	real scalar t
	string scalar nm

	cfg.termcodes1 = J(1, M1.nterms, 0)
	cfg.p1_1 = J(1, M1.nterms, 0)
	cfg.termcodes2 = J(1, M2.nterms, 0)
	cfg.p1_2 = J(1, M2.nterms, 0)
	cfg.eligible = 1

	for (t=1; t<=M1.nterms; t++) {
		nm = M1.names[t]
		if (nm == "outdegree") cfg.termcodes1[t] = 1
		else if (nm == "reciprocity") cfg.termcodes1[t] = 2
		else if (nm == "crprod") cfg.termcodes1[t] = 22
		else cfg.eligible = 0
	}
	for (t=1; t<=M2.nterms; t++) {
		nm = M2.names[t]
		if (nm == "outdegree") cfg.termcodes2[t] = 1
		else if (nm == "reciprocity") cfg.termcodes2[t] = 2
		else if (nm == "crprod") cfg.termcodes2[t] = 22
		else cfg.eligible = 0
	}
	return(cfg)
}

/* Native-first (per direct instruction) two-network ministep simulator -
   direct C port of SaomSimulateIntervalCoevNetNet() immediately above
   (native/saom_sim.c's own new argc>=3-dispatched branch in
   stata_call()), NOT a wrapper around the Mata version. Unlike that
   function, this one operates on G1/G2's OWN OBSERVED ties directly
   (never mutates them - the native side builds its own internal
   graph_t copies from the ties written to the frame below) and returns
   the FINAL simulated statistic vector (`res.stat1'/`res.stat2')
   computed natively on that final state, so the caller needs neither a
   SaomCopyGraph() working-copy pair NOR a second M.full_statistic()
   pass - eliminating both real, measured costs the Mata phase-2 loop
   otherwise pays on every single replicate. Score is NOT supported
   (returned as all-zero) - phase 1's own smaller-replicate Jacobian
   estimate, which needs it, stays on the Mata path; this native path is
   used for phase 2 only, where the actual 42x benchmark gap lived. */
/* SaomSetupNNFrame: writes G1/G2's OWN OBSERVED starting ties into the
   shared __saom_native_nn frame ONCE. Split out of
   SaomSimIntCoevNNNative() below after a direct A/B measurement found
   the two-graph native path giving only a modest ~1.27x speedup
   (70.7s vs the Mata path's 89.9s) despite the ministep loop itself
   being fully native - traced to this exact function re-calling
   G1.all_ties()/G2.all_ties() (an O(n) materialization) and rewriting
   the dataset via st_store()/st_addvar()/st_addobs() on EVERY SINGLE
   phase-2 replicate, even though G1obs_start/G2obs_start (the only
   graphs the native phase-2 loop ever reads - see
   SaomEstimateRMCoevNetNet()'s own phase-2 branch, which passes
   G1obs_start/G2obs_start directly, never a working copy) are fixed for
   the ENTIRE phase-2 loop. Call this ONCE before that loop starts;
   SaomSimIntCoevNNNative() itself now only ever updates theta/rate/seed
   per replicate - it does not touch the dataset at all. Returns the two
   real starting tie counts (needed by every per-replicate argstr, cheap
   to keep as plain scalars rather than re-deriving from `nn' each call). */
struct SaomNNFrameSetup {
	real matrix ties1, ties2
}
struct SaomNNFrameSetup scalar SaomSetupNNFrame(class ErgmGraph scalar G1, class ErgmGraph scalar G2){
	struct SaomNNFrameSetup scalar nn
	real scalar n, nties1, nties2, neededrows, junk
	string scalar origframe

	n = G1.n
	nn.ties1 = G1.all_ties()
	nn.ties2 = G2.all_ties()
	nties1 = rows(nn.ties1)
	nties2 = rows(nn.ties2)

	// sized for the full dyad space, not just the starting tie count -
	// the plugin writes back however many ties the simulation ends
	// with (which can exceed the starting count) into these SAME
	// columns, and every subsequent replicate's own re-write (in
	// SaomSimIntCoevNNNative() below) must fit in the space sized here -
	// this is a ONE-TIME check, done once for the whole phase-2 loop.
	neededrows = max((nties1, nties2, n*(n-1), 1))

	origframe = st_framecurrent()
	stata("capture frame create __saom_native_nn")
	st_framecurrent("__saom_native_nn")
	if (st_nvar() == 0) {
		junk = st_addvar("double", "v1"); junk = st_addvar("double", "v2")
		junk = st_addvar("double", "v3"); junk = st_addvar("double", "v4")
	}
	if (st_nobs() < neededrows) st_addobs(neededrows - st_nobs())
	st_framecurrent(origframe)
	return(nn)
}

struct SaomCoevNetNetScoredResult scalar SaomSimIntCoevNNNative(
	real scalar n, real matrix ties1, real rowvector tc1, real rowvector p1a, real rowvector theta1,
	real matrix ties2, real rowvector tc2, real rowvector p2a, real rowvector theta2,
	real scalar rate1, real scalar rate2){

	struct SaomCoevNetNetScoredResult scalar res
	real scalar nterms1, nterms2, nties1, nties2, i, rngseed
	string scalar argstr0, argstr1, argstr2, argstrnn, cmd
	string scalar origframe

	nterms1 = cols(tc1)
	nterms2 = cols(tc2)
	nties1 = rows(ties1)
	nties2 = rows(ties2)

	origframe = st_framecurrent()
	st_framecurrent("__saom_native_nn")
	// re-write the OBSERVED starting ties fresh before every single
	// replicate - cheap (a plain st_store() of an already-computed
	// matrix, not a graph traversal) but essential for correctness: the
	// plugin overwrites these same columns with its own FINAL simulated
	// state on return (see native/saom_sim.c's own write-back), and
	// every phase-2 replicate must restart from the true observed
	// network, never chain from the PRIOR replicate's own end state
	// (exactly matching the Mata path's own fresh SaomCopyGraph() per
	// iteration) - the real correctness bug an earlier version of this
	// optimization had, caught before certification, not after.
	if (nties1 > 0) st_store((1::nties1), ("v1","v2"), ties1)
	if (nties2 > 0) st_store((1::nties2), ("v3","v4"), ties2)

	rngseed = floor(runiform(1,1) * 2147483647)

	argstr0 = strofreal(n) + " " + strofreal(nties1) + " " + strofreal(nterms1)
	for (i=1; i<=nterms1; i++) argstr0 = argstr0 + " " + strofreal(tc1[i]) + " " + strofreal(p1a[i], "%25.17g") + " " + strofreal(theta1[i], "%25.17g")
	argstr0 = argstr0 + " " + strofreal(rate1, "%25.17g")

	argstr1 = strofreal(n) + " " + strofreal(nties2) + " " + strofreal(nterms2)
	for (i=1; i<=nterms2; i++) argstr1 = argstr1 + " " + strofreal(tc2[i]) + " " + strofreal(p2a[i], "%25.17g") + " " + strofreal(theta2[i], "%25.17g")
	argstr1 = argstr1 + " " + strofreal(rate2, "%25.17g")

	argstr2 = strofreal(rngseed, "%12.0f")

	// Single combined string (matching every other native call site's own
	// convention in this file - see e.g. SaomEstimateRM()'s own
	// single-graph `plugin call`), NOT three separate quoted arguments -
	// harmonisation follow-up unit testing whether the three-string form
	// itself was the source of a ~45ms/call anomaly measured on the
	// original three-string version. "NNMULTIPLEX|" is a sentinel prefix
	// the C side checks for BEFORE falling back to the ordinary
	// single-graph parse, since dispatch can no longer key off argc
	// (both paths now pass argc==1).
	argstrnn = "NNMULTIPLEX|" + argstr0 + "|" + argstr1 + "|" + argstr2

	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")
	cmd = "plugin call saomnativesim v1 v2 v3 v4, " + char(34) + argstrnn + char(34)
	stata(cmd)

	res.steps = st_numscalar("__saom_native_nn_steps")
	res.steps1 = st_numscalar("__saom_native_nn_steps1")		// protocol >= 5
	res.steps2 = st_numscalar("__saom_native_nn_steps2")
	res.dist1 = st_numscalar("__saom_native_nn_dist1")
	res.dist2 = st_numscalar("__saom_native_nn_dist2")
	res.nchanges1 = st_numscalar("__saom_native_nn_nch1")
	res.nchanges2 = st_numscalar("__saom_native_nn_nch2")
	// Real score-function values (harmonisation follow-up): the C side
	// now accumulates the SAME "chosen - E_p[change]" identity the
	// single-graph native path already certifies, per network - no
	// longer the all-zero stub that blocked phase 1/3 from ever using
	// this native path (they need a real score for the Jacobian/
	// t-ratio, phase 2 does not, which is why phase 2 alone could use
	// this function safely before this fix).
	res.score1 = J(1, nterms1, 0)
	for (i=1; i<=nterms1; i++) res.score1[i] = st_numscalar("__saom_native_nn_score1_" + strofreal(i))
	res.score2 = J(1, nterms2, 0)
	for (i=1; i<=nterms2; i++) res.score2[i] = st_numscalar("__saom_native_nn_score2_" + strofreal(i))
	res.stat1 = J(1, nterms1, 0)
	for (i=1; i<=nterms1; i++) res.stat1[i] = st_numscalar("__saom_native_nn_stat1_" + strofreal(i))
	res.stat2 = J(1, nterms2, 0)
	for (i=1; i<=nterms2; i++) res.stat2[i] = st_numscalar("__saom_native_nn_stat2_" + strofreal(i))

	st_framecurrent(origframe)
	return(res)
}

struct SaomCoevNetNetScoredResult scalar SaomSimulateIntervalCoevNetNet(
	class ErgmGraph scalar G1, class ErgmModel scalar M1, real rowvector theta1,
	class ErgmGraph scalar G2, class ErgmModel scalar M2, real rowvector theta2,
	real scalar rate1, real scalar rate2) {

	struct SaomCoevNetNetScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg
	real scalar t, n, p1, p2, i, j, maxu, denom, draw, draw2, cum, choice
	real scalar totalRate1, totalRate2, grandRate

	n = G1.n
	p1 = M1.nparam()
	p2 = M2.nparam()
	res.score1 = J(1, p1, 0)
	res.score2 = J(1, p2, 0)
	res.steps = 0
	res.steps1 = 0
	res.steps2 = 0
	res.nchanges1 = 0
	res.nchanges2 = 0

	totalRate1 = n * rate1
	totalRate2 = n * rate2
	grandRate = totalRate1 + totalRate2

	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / grandRate
		if (t < 1) {
			draw = runiform(1,1) * grandRate
			if (draw <= totalRate1) {
				// --- network 1 ministep, scored - identical mechanism to
				// SaomSimulateIntervalCoevScored()'s own network branch.
				i = ceil(runiform(1,1) * n)
				chgmat = J(n, p1, 0)
				u = J(1, n, 0)
				maxu = 0
				for (j=1; j<=n; j++) {
					if (j == i) continue
					chgmat[j,.] = M1.full_change(G1, i, j)
					u[j] = theta1 * chgmat[j,.]'
					if (u[j] > maxu) maxu = u[j]
				}
				denom = exp(0 - maxu)
				for (j=1; j<=n; j++) {
					if (j == i) continue
					denom = denom + exp(u[j] - maxu)
				}
				ebar = J(1, p1, 0)
				for (j=1; j<=n; j++) {
					if (j == i) continue
					ebar = ebar + (exp(u[j]-maxu)/denom) * chgmat[j,.]
				}
				draw2 = runiform(1,1) * denom
				cum = exp(0 - maxu)
				choice = 0
				chosen_chg = J(1, p1, 0)
				if (draw2 > cum) {
					for (j=1; j<=n; j++) {
						if (j == i) continue
						cum = cum + exp(u[j] - maxu)
						choice = j
						if (draw2 <= cum) break
					}
					chosen_chg = chgmat[choice, .]
				}
				res.score1 = res.score1 + (chosen_chg - ebar)
				if (choice != 0) {
					G1.toggle(i, choice)
					res.nchanges1 = res.nchanges1 + 1
				}
				res.steps1 = res.steps1 + 1
			}
			else {
				// --- network 2 ministep, scored - same mechanism, second network.
				i = ceil(runiform(1,1) * n)
				chgmat = J(n, p2, 0)
				u = J(1, n, 0)
				maxu = 0
				for (j=1; j<=n; j++) {
					if (j == i) continue
					chgmat[j,.] = M2.full_change(G2, i, j)
					u[j] = theta2 * chgmat[j,.]'
					if (u[j] > maxu) maxu = u[j]
				}
				denom = exp(0 - maxu)
				for (j=1; j<=n; j++) {
					if (j == i) continue
					denom = denom + exp(u[j] - maxu)
				}
				ebar = J(1, p2, 0)
				for (j=1; j<=n; j++) {
					if (j == i) continue
					ebar = ebar + (exp(u[j]-maxu)/denom) * chgmat[j,.]
				}
				draw2 = runiform(1,1) * denom
				cum = exp(0 - maxu)
				choice = 0
				chosen_chg = J(1, p2, 0)
				if (draw2 > cum) {
					for (j=1; j<=n; j++) {
						if (j == i) continue
						cum = cum + exp(u[j] - maxu)
						choice = j
						if (draw2 <= cum) break
					}
					chosen_chg = chgmat[choice, .]
				}
				res.score2 = res.score2 + (chosen_chg - ebar)
				if (choice != 0) {
					G2.toggle(i, choice)
					res.nchanges2 = res.nchanges2 + 1
				}
				res.steps2 = res.steps2 + 1
			}
			res.steps = res.steps + 1
		}
	}
	return(res)
}

/* SaomEstimateRMCoevNetNet: two co-evolving networks (nwsaom multiplex),
   two waves. Unconditional Method of Moments, as RSiena estimates any
   model with more than one dependent variable: parameters (theta1,
   theta2, rate1, rate2), estimated jointly by SaomRMCore(). Statistics:
   each network's effect statistics on its end state, and each network's
   distance from its starting observation (the rate statistics, targets
   = the observed distances); rate scores steps_k/rate_k - n.
   A cross-network effect (crprod: a tie of network 1 in a dyad where
   network 2 has a tie) reads the other network's CURRENT state in the
   ministeps but its START-of-period state in the statistics (targets and
   simulated), as RSiena does: on a two-network s50 example RSiena's
   crprod targets are sum(x1(t2) * x2(t1)). */
struct SaomCoevNetNetFit {
	real rowvector theta1
	real rowvector theta2
	real scalar rate1
	real scalar rate2
	real scalar rate1SE
	real scalar rate2SE
	real rowvector tratio1
	real rowvector tratio2
	real scalar rate1Tratio
	real scalar rate2Tratio
	real rowvector tconv		// RSiena convergence t-ratios: theta1, theta2, rate1, rate2
	real scalar tconvMax
	real matrix V			// theta1, theta2
	real matrix Vfull		// theta1, theta2, rate1, rate2
}

struct SaomNNCtx {
	pointer(class ErgmGraph scalar) scalar G1s, G2s
	pointer(class ErgmModel scalar) scalar M1, M2
	struct SaomNNNativeConfig scalar nncfg
	struct SaomNNFrameSetup scalar nnframe
	real scalar use_native, n, p1, p2
	real rowvector target		// 1 x (p1+p2)
	real rowvector targetRate	// 1 x 2
}

/* points every crprod term of M1 at network x1 and of M2 at x2 */
void SaomNNPointCrprod(class ErgmModel scalar M1, class ErgmModel scalar M2,
	pointer(class ErgmGraph scalar) scalar x1, pointer(class ErgmGraph scalar) scalar x2) {

	pointer(class ErgmTermData scalar) scalar tdp	// M.td is an untyped pointer rowvector: go through a typed pointer (matastrict)
	real scalar k

	for (k=1; k<=M1.nterms; k++) {
		if (M1.names[k] == "crprod") {
			tdp = M1.td[k]
			(*tdp).xnet = x1
		}
	}
	for (k=1; k<=M2.nterms; k++) {
		if (M2.names[k] == "crprod") {
			tdp = M2.td[k]
			(*tdp).xnet = x2
		}
	}
}

/* SaomRMCore() callback: K replicates at `par' = (theta1, theta2, rate1, rate2) */
void SaomNNSimManyCB(struct SaomNNCtx scalar C, real rowvector par, real scalar K,
	real scalar want_score, real matrix Z, real matrix S) {

	struct SaomCoevNetNetScoredResult scalar sres
	class ErgmGraph scalar G1work, G2work
	real rowvector th1, th2, simstat
	real scalar k, p, r1, r2, d1, d2

	p = C.p1 + C.p2
	th1 = par[1..C.p1]
	th2 = par[(C.p1+1)..p]
	r1 = par[p+1]
	r2 = par[p+2]
	Z = J(K, p+2, 0)
	S = J(K, p+2, 0)
	for (k=1; k<=K; k++) {
		if (C.use_native) {
			sres = SaomSimIntCoevNNNative(C.n, C.nnframe.ties1, C.nncfg.termcodes1, C.nncfg.p1_1, th1, C.nnframe.ties2, C.nncfg.termcodes2, C.nncfg.p1_2, th2, r1, r2)
			simstat = (sres.stat1, sres.stat2)		// crprod lagged by the plugin
			d1 = sres.dist1
			d2 = sres.dist2
		}
		else {
			G1work = ErgmGraph()
			SaomCopyGraph(*C.G1s, G1work)
			G2work = ErgmGraph()
			SaomCopyGraph(*C.G2s, G2work)
			SaomNNPointCrprod(*C.M1, *C.M2, &G2work, &G1work)	// ministeps: current state
			sres = SaomSimulateIntervalCoevNetNet(G1work, *C.M1, th1, G2work, *C.M2, th2, r1, r2)
			SaomNNPointCrprod(*C.M1, *C.M2, C.G2s, C.G1s)		// statistics: lagged
			simstat = ((*C.M1).full_statistic(G1work), (*C.M2).full_statistic(G2work))
			d1 = SaomCountDiffering(*C.G1s, G1work)
			d2 = SaomCountDiffering(*C.G2s, G2work)
		}
		Z[k,.] = (simstat - C.target, d1 - C.targetRate[1], d2 - C.targetRate[2])
		S[k,.] = (sres.score1, sres.score2, sres.steps1 / r1 - C.n, sres.steps2 / r2 - C.n)
	}
}

struct SaomCoevNetNetFit scalar SaomEstimateRMCoevNetNet(
	class ErgmGraph scalar G1obs_start, class ErgmGraph scalar G1obs_end, class ErgmModel scalar M1,
	class ErgmGraph scalar G2obs_start, class ErgmGraph scalar G2obs_end, class ErgmModel scalar M2,
	real rowvector theta01, real rowvector theta02,
	real scalar K0, real scalar K3, real scalar firstg) {
	string scalar why

	struct SaomCoevNetNetFit scalar fit
	struct SaomNNCtx scalar C
	struct SaomNetFit scalar nf
	real rowvector par0, israte
	real scalar p, n

	n = G1obs_start.n
	C.G1s = &G1obs_start
	C.G2s = &G2obs_start
	C.M1 = &M1
	C.M2 = &M2
	C.n = n
	C.p1 = M1.nparam()
	C.p2 = M2.nparam()
	p = C.p1 + C.p2

	// the native two-network path needs protocol 5 (per-network ministep
	// counts, distances and lagged crprod statistics)
	C.nncfg = SaomNativeSetupNN(M1, M2)
	C.use_native = C.nncfg.eligible & SaomNativeAvailable()
	if (C.use_native) C.use_native = (SaomNativePluginVersion() >= 5)
	why = ""
	if (!SaomNativeAvailable()) why = "no native plugin for this platform"
	else if (!C.nncfg.eligible) why = "an effect without a native implementation"
	else why = "native plugin too old for this model"
	SaomSetEngine(C.use_native, why)
	if (C.use_native) C.nnframe = SaomSetupNNFrame(G1obs_start, G2obs_start)

	// targets: end networks, crprod lagged (the other network at the start)
	SaomNNPointCrprod(M1, M2, &G2obs_start, &G1obs_start)
	C.target = (M1.full_statistic(G1obs_end), M2.full_statistic(G2obs_end))
	C.targetRate = (SaomCountDiffering(G1obs_start, G1obs_end), SaomCountDiffering(G2obs_start, G2obs_end))

	par0 = (theta01, theta02, SaomRateStart(n, C.targetRate[1]), SaomRateStart(n, C.targetRate[2]))
	israte = (J(1, p, 0), 1, 1)
	nf = SaomRMCore(C, &SaomNNSimManyCB(), par0, p, israte, 1 :- israte, K0, K3, firstg)

	fit.theta1 = nf.par[1..C.p1]
	fit.theta2 = nf.par[(C.p1+1)..p]
	fit.rate1 = nf.par[p+1]
	fit.rate2 = nf.par[p+2]
	fit.Vfull = nf.Vfull
	fit.V = nf.Vfull[1..p, 1..p]
	fit.rate1SE = sqrt(nf.Vfull[p+1, p+1])
	fit.rate2SE = sqrt(nf.Vfull[p+2, p+2])
	fit.tratio1 = nf.tratio[1..C.p1]
	fit.tratio2 = nf.tratio[(C.p1+1)..p]
	fit.rate1Tratio = nf.tratio[p+1]
	fit.rate2Tratio = nf.tratio[p+2]
	fit.tconv = nf.tconv
	fit.tconvMax = nf.tconvMax
	return(fit)
}

/* ===================================================================
   Co-evolution estimation (network + behavior): UNCONDITIONAL Method of
   Moments, as RSiena does it whenever a model has two or more dependent
   variables (rewritten 2026-09-30).

   Parameters, in this internal order:
     thetaNet (pNet), thetaBeh (pBeh), network rates (one per period),
     behavior rates (one per period).
   The rates are ordinary Method-of-Moments parameters here, estimated
   jointly with every other parameter in phases 1-3. Their statistics, per
   period, are the DISTANCE between the simulated end state and the
   period's starting observation:
     network rate:  number of dyads in which the simulated network differs
                    from the starting network (missing dyads excluded);
     behavior rate: sum_i |z_i(simulated end) - z_i(start)| (missing actors
                    excluded).
   Targets are the same distances between consecutive observed waves
   (RSiena 1.6.6 reports exactly these as the rate targets on s50: 115/106
   network, 27/33 behavior). The score of a constant rate lambda for a
   period is (number of that variable's ministeps)/lambda - (number of
   active actors), the derivative of the exponential waiting-time
   likelihood over the unit interval. The network-only estimator,
   SaomEstimateNet(), treats its rates the same way.

   Cross-variable statistics are LAGGED, as in RSiena (Snijders, Steglich
   & Schweinberger 2007): a network effect that reads the behavior (behsim)
   is evaluated on the end-of-period network with the START-of-period
   behavior, and a behavior effect that reads the network (avalt, avsim)
   on the end-of-period behavior with the START-of-period network, for
   both the observed targets and the simulated statistics. Verified
   against RSiena's per-period targets on s50 (simX 13.521/8.475, avAlt
   31.859/22.050). The ministep change statistics always use the current
   simulated state.

   Robbins-Monro schedule, truncation, diagonalization and phase-3
   sandwich covariance are those of SaomEstimateNet(), over the extended
   parameter vector. A rate
   update that would more than halve the rate is limited to halving it
   (RSiena's positivity rule for rate parameters in phase 2).
   =================================================================== */
struct SaomCoevCtx {
	pointer(class ErgmGraph scalar) rowvector Gwaves
	pointer(class ErgmGraph scalar) rowvector GpStat	// per period: the starting network the behavior statistics are evaluated on (masked when missing data are present)
	pointer(real colvector) rowvector Behwaves
	pointer(real matrix) rowvector missMaskNetPd
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	real scalar behminval, behmaxval, overallMean, simMean
	real scalar use_native, use_batch, hasmiss, haspresent, needsExtras
	real scalar nperiods, pNet, pBeh, p, ptot, n
	real matrix target			// nperiods x p
	real rowvector targetRateNet, targetRateBeh, npresentPd
	real matrix missDyadsPd		// stacked (period, i, j)
	real matrix missBehPd			// n x nperiods, 0/1
	real matrix presentPd			// n x nperiods, 0/1
}

/* behavior statistics on a given (lagged) network, missing actors set to
   the overall mean (SaomMaskedBehaviorStatistic()'s rule, without
   rebuilding the masked graph on every call) */
real rowvector SaomCoevStatBeh(class SaomBehavior scalar Beh, class ErgmGraph scalar Gstat,
	class SaomBehaviorModel scalar Mbeh, real colvector missBeh) {

	class SaomBehavior scalar Bm
	real scalar i

	if (max((missBeh \ 0)) == 0) return(Mbeh.full_statistic(Beh, Gstat))
	Bm = SaomBehavior()
	Bm.init(Beh.values, Beh.minval, Beh.maxval, Beh.overallMean, Beh.simMean)
	for (i=1; i<=Beh.n; i++) if (missBeh[i] != 0) Bm.setvalue(i, Beh.overallMean)
	return(Mbeh.full_statistic(Bm, Gstat))
}

/* One simulated replicate over every period at parameter vector `theta'
   (internal order, see above). Returns the deviation from the targets in
   `dev' and the score in `sco' (both 1 x ptot). */
void SaomCoevReplicate(struct SaomCoevCtx scalar C, class ErgmModel scalar M,
	class SaomBehaviorModel scalar Mbeh, real rowvector theta,
	real rowvector dev, real rowvector sco) {

	struct SaomCoevScoredResult scalar sres
	class ErgmGraph scalar Gwork
	class SaomBehavior scalar Behwork
	real rowvector thetaNet, thetaBeh, statNet, statBeh, simstat
	real colvector behStart, missBeh
	real scalar pd, rateNet, rateBeh, distNet, distBeh, P, hasbehsim
	real matrix mdy

	P = C.nperiods
	thetaNet = theta[1..C.pNet]
	thetaBeh = theta[(C.pNet+1)..C.p]
	dev = J(1, C.ptot, 0)
	sco = J(1, C.ptot, 0)
	hasbehsim = SaomHasBehSim(M)

	for (pd=1; pd<=P; pd++) {
		rateNet = theta[C.p + pd]
		rateBeh = theta[C.p + P + pd]
		behStart = *C.Behwaves[pd]
		missBeh = C.missBehPd[., pd]
		Behwork = SaomBehavior()
		Behwork.init(behStart, C.behminval, C.behmaxval, C.overallMean, C.simMean)

		if (C.use_native) {
			if (C.needsExtras) {
				mdy = (rows(C.missDyadsPd) ? select(C.missDyadsPd[.,2..3], C.missDyadsPd[.,1] :== pd) : J(0, 2, 0))
				if (rows(mdy) == 0) mdy = J(0, 2, 0)
				sres = SaomSimulateIntervalCoevNative(*C.Gwaves[pd], M, C.cfg, thetaNet, Behwork, Mbeh, C.cfgBeh, thetaBeh, rateNet, rateBeh, 0, mdy, missBeh, C.presentPd[., pd])
			}
			else sres = SaomSimulateIntervalCoevNative(*C.Gwaves[pd], M, C.cfg, thetaNet, Behwork, Mbeh, C.cfgBeh, thetaBeh, rateNet, rateBeh, 0)
			statNet = sres.stat		// behsim already evaluated with the starting behavior by the plugin
			statBeh = sres.statBehLag	// lagged, computed by the plugin
			distNet = sres.netdist
		}
		else {
			Gwork = ErgmGraph()
			SaomCopyGraph(*C.Gwaves[pd], Gwork)
			if (C.haspresent) sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, rateNet, rateBeh, C.presentPd[., pd])
			else sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, rateNet, rateBeh)
			if (hasbehsim) SaomBehSimSync(M, behStart)		// lagged: behsim statistic uses the starting behavior
			if (C.hasmiss) {
				statNet = SaomMaskedStatistic(Gwork, M, *C.missMaskNetPd[pd])
				distNet = SaomCountDifferingMasked(*C.Gwaves[pd], Gwork, *C.missMaskNetPd[pd])
			}
			else {
				statNet = M.full_statistic(Gwork)
				distNet = SaomCountDiffering(*C.Gwaves[pd], Gwork)
			}
			// lagged: behavior statistics on the period's STARTING network
			statBeh = SaomCoevStatBeh(Behwork, *C.GpStat[pd], Mbeh, missBeh)
		}
		simstat = SaomBehaviorPatchEndowCreation(Mbeh, (statNet, statBeh), C.pNet, behStart,
			(C.hasmiss ? SaomMaskCoevEndowCreationValues(Behwork.values, behStart, missBeh) : Behwork.values))
		distBeh = sum(abs(Behwork.values - behStart) :* (1 :- missBeh))

		dev[1..C.p] = dev[1..C.p] + (simstat - C.target[pd, .])
		dev[C.p + pd] = distNet - C.targetRateNet[pd]
		dev[C.p + P + pd] = distBeh - C.targetRateBeh[pd]
		sco[1..C.p] = sco[1..C.p] + (sres.scoreNet, sres.scoreBeh)
		sco[C.p + pd] = sres.stepsNet / rateNet - C.npresentPd[pd]
		sco[C.p + P + pd] = sres.stepsBeh / rateBeh - C.npresentPd[pd]
	}
}

/* K replicates at `theta' (internal order): K x ptot deviations `Z' and
   scores `S'. Batch (threaded native) path when available, otherwise K
   calls of SaomCoevReplicate(). */
void SaomCoevSimMany(struct SaomCoevCtx scalar C, class ErgmModel scalar M,
	class SaomBehaviorModel scalar Mbeh, real rowvector theta, real scalar K,
	real scalar want_score, real matrix Z, real matrix S) {

	real matrix out
	real rowvector dev, sco, tsum
	real scalar k, pd, P, p, b

	P = C.nperiods
	p = C.p
	Z = J(K, C.ptot, 0)
	S = J(K, C.ptot, 0)
	if (C.use_batch) {
		out = SaomBatchRun(P, C.pNet, C.pBeh, theta[1..C.pNet], theta[(C.pNet+1)..p],
			theta[(p+1)..(p+P)], theta[(p+P+1)..C.ptot], J(1, 0, 0), K, want_score, 0)
		tsum = colsum(C.target)
		Z[., 1..p] = out[., 1..p] :- tsum
		S[., 1..p] = out[., (p+1)..(2*p)]
		for (pd=1; pd<=P; pd++) {
			b = 2*p + 6*(pd-1)
			Z[., p+pd] = out[., b+1] :- C.targetRateNet[pd]
			Z[., p+P+pd] = out[., b+2] :- C.targetRateBeh[pd]
			S[., p+pd] = out[., b+3] / theta[p+pd] :- C.npresentPd[pd]
			S[., p+P+pd] = out[., b+4] / theta[p+P+pd] :- C.npresentPd[pd]
		}
		return
	}
	for (k=1; k<=K; k++) {
		SaomCoevReplicate(C, M, Mbeh, theta, dev, sco)
		Z[k,.] = dev
		S[k,.] = sco
	}
}

struct SaomCoevMultiFit {
	real rowvector thetaNet
	real rowvector thetaBeh
	real rowvector ratesNet		// 1 x nperiods, ESTIMATED
	real rowvector ratesBeh		// 1 x nperiods, ESTIMATED
	real rowvector ratesNetSE		// 1 x nperiods
	real rowvector ratesBehSE		// 1 x nperiods
	real rowvector tratioNet		// RSiena's convergence t-ratio, phase-3 mean deviation / sd (= the matching tconv entries)
	real rowvector tratioBeh
	real rowvector rateNetTratios		// 1 x nperiods, same, on the rate's distance statistic
	real rowvector rateBehTratios		// 1 x nperiods
	real rowvector tconv		// RSiena's convergence t-ratio mean/sd, 1 x ptot in the order: effects (net, beh), network rates, behavior rates
	real scalar tconvMax		// RSiena's overall maximum convergence ratio, sqrt(m' S^-1 m)
	real matrix V			// effects only, (pNet+pBeh) x (pNet+pBeh)
	real matrix Vfull		// every parameter incl. rates, internal order
}

struct SaomCoevMultiFit scalar SaomEstimateRMCoevMulti(
	pointer(class ErgmGraph scalar) rowvector Gwaves,
	class ErgmModel scalar M,
	pointer(real colvector) rowvector Behwaves, real scalar behminval, real scalar behmaxval,
	class SaomBehaviorModel scalar Mbeh,
	real rowvector theta0Net, real rowvector theta0Beh,
	real scalar K0, real scalar K3, real scalar firstg, | real matrix presentMat,
	pointer(real matrix) rowvector missMaskNetPd, pointer(real colvector) rowvector missMaskBehPd) {
	string scalar why

	struct SaomCoevMultiFit scalar fit
	struct SaomCoevCtx scalar C
	class ErgmGraph scalar Gp, Gpend
	class SaomBehavior scalar Behpend
	real matrix Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3, Zsco3
	real matrix Ddev3, Dsco3, Dhat3, Dinv3, missDyadsPdTmp, S3, Z1, S1
	real rowvector theta, theta0, dev, sco, prevdev, prod0, prod1, ac, stdcap
	real rowvector thav, fchange, changestep, ratesNet0, ratesBeh0, thprev, m3
	real scalar pd, k, nwaves, P, p, ptot, n, hasbehsim
	real scalar nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real rowvector n2minimum, n2maximum
	real colvector allbehvals, missBehZero

	nwaves = cols(Gwaves)
	P = nwaves - 1
	n = (*Gwaves[1]).n
	C.Gwaves = Gwaves
	C.Behwaves = Behwaves
	C.nperiods = P
	C.n = n
	C.pNet = M.nparam()
	C.pBeh = Mbeh.nparam()
	p = C.pNet + C.pBeh
	ptot = p + 2*P
	C.p = p
	C.ptot = ptot
	C.behminval = behminval
	C.behmaxval = behmaxval
	hasbehsim = SaomHasBehSim(M)

	// composition change (present) and missing data - same optional
	// arguments and per-period derivation as before
	C.haspresent = (args() >= 12)
	C.presentPd = J(n, P, 1)
	if (C.haspresent) {
		for (pd=1; pd<=P; pd++) C.presentPd[.,pd] = presentMat[.,pd] :* presentMat[.,pd+1]
	}
	C.npresentPd = colsum(C.presentPd)
	C.hasmiss = (args() == 14)
	missBehZero = J(n, 1, 0)
	C.missBehPd = J(n, P, 0)
	if (C.hasmiss) {
		C.missMaskNetPd = missMaskNetPd
		for (pd=1; pd<=P; pd++) C.missBehPd[.,pd] = *missMaskBehPd[pd]
	}
	C.needsExtras = C.hasmiss | C.haspresent

	// native dispatch: every term on both sides natively covered, and a
	// plugin new enough for unconditional estimation (protocol >= 3)
	C.cfg = SaomNativeSetup(M)
	C.cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	C.use_native = C.cfg.eligible & C.cfgBeh.eligible & SaomNativeAvailable()
	C.use_batch = 0
	if (C.use_native) {
		k = SaomNativePluginVersion()
		C.use_native = (k >= 3)
		C.use_batch = (k >= 4)
		// behavior endowment/creation from protocol 11 on
		if (any(C.cfgBeh.fntype :!= 0) & k < 11) {
			C.use_native = 0
			C.use_batch = 0
		}
	}
	why = ""
	if (!SaomNativeAvailable()) why = "no native plugin for this platform"
	else if (!C.cfg.eligible) why = C.cfg.whynot
	else if (!C.cfgBeh.eligible) why = "a behavior effect without a native implementation (e.g. an endowment/creation split)"
	else why = "native plugin too old for this model"
	SaomSetEngine(C.use_native, why)
	C.missDyadsPd = J(0, 3, 0)
	if (C.use_native & C.hasmiss) {
		for (pd=1; pd<=P; pd++) {
			missDyadsPdTmp = SaomMaskToDyadList(*missMaskNetPd[pd])
			if (rows(missDyadsPdTmp) > 0) C.missDyadsPd = C.missDyadsPd \ (J(rows(missDyadsPdTmp), 1, pd), missDyadsPdTmp)
		}
	}

	allbehvals = *Behwaves[1]
	for (pd=2; pd<=nwaves; pd++) allbehvals = allbehvals \ *Behwaves[pd]
	C.overallMean = mean(allbehvals)
	C.simMean = Mbeh.simMean

	// per period: lagged statistic network, targets, distance targets,
	// closed-form rate starting values
	C.GpStat = J(1, P, NULL)
	C.target = J(P, p, 0)
	C.targetRateNet = J(1, P, 0)
	C.targetRateBeh = J(1, P, 0)
	ratesNet0 = J(1, P, 0)
	ratesBeh0 = J(1, P, 0)
	for (pd=1; pd<=P; pd++) {
		Gp = *Gwaves[pd]
		Gpend = *Gwaves[pd+1]
		if (C.hasmiss) C.GpStat[pd] = &(SaomBuildMaskedGraph(*Gwaves[pd], *missMaskNetPd[pd]))
		else C.GpStat[pd] = Gwaves[pd]
		Behpend = SaomBehavior()
		Behpend.init(*Behwaves[pd+1], behminval, behmaxval, C.overallMean, C.simMean)
		if (hasbehsim) SaomBehSimSync(M, *Behwaves[pd])		// lagged: starting behavior
		if (C.hasmiss) C.target[pd,.] = (SaomMaskedStatistic(Gpend, M, *missMaskNetPd[pd]), SaomCoevStatBeh(Behpend, *C.GpStat[pd], Mbeh, C.missBehPd[.,pd]))
		else C.target[pd,.] = (M.full_statistic(Gpend), SaomCoevStatBeh(Behpend, *C.GpStat[pd], Mbeh, missBehZero))
		C.target[pd,.] = SaomBehaviorPatchEndowCreation(Mbeh, C.target[pd,.], C.pNet, *Behwaves[pd],
			(C.hasmiss ? SaomMaskCoevEndowCreationValues(*Behwaves[pd+1], *Behwaves[pd], C.missBehPd[.,pd]) : *Behwaves[pd+1]))

		if (C.hasmiss) C.targetRateNet[pd] = SaomCountDifferingMasked(Gp, Gpend, *missMaskNetPd[pd])
		else C.targetRateNet[pd] = SaomCountDiffering(Gp, Gpend)
		C.targetRateBeh[pd] = sum(abs((*Behwaves[pd+1] - *Behwaves[pd]) :* (1 :- C.missBehPd[.,pd])))

		ratesNet0[pd] = C.npresentPd[pd] * (0.2 + 2*C.targetRateNet[pd]) / (C.npresentPd[pd]*(C.npresentPd[pd]-1) + 1)
		ratesBeh0[pd] = (C.hasmiss ? SaomBehaviorRateStartMasked(*Behwaves[pd], *Behwaves[pd+1], C.missBehPd[.,pd]) : SaomBehaviorRateStart(*Behwaves[pd], *Behwaves[pd+1]))
	}

	theta0 = (theta0Net, theta0Beh, ratesNet0, ratesBeh0)

	if (C.use_batch) {
		if (C.hasmiss & rows(C.missDyadsPd) == 0) C.missDyadsPd = J(0, 3, 0)
		SaomBatchSetup(Gwaves, P, C.cfg, C.cfgBeh.termcodes, Behwaves, behminval, behmaxval,
			C.simMean, C.overallMean, C.hasmiss, C.missDyadsPd, C.missBehPd, C.haspresent, C.presentPd,
			C.cfgBeh.fntype)
	}

	// --- Phase 1: Jacobian by the score-function method
	SaomCoevSimMany(C, M, Mbeh, theta0, K0, 1, Zdev, Zsco)
	Ddev = Zdev :- mean(Zdev)
	Dsco = Zsco :- mean(Zsco)
	Dhat = (Ddev' * Dsco) / K0
	temp = 0.8 * Dhat + 0.2 * diag(diagonal(Dhat))
	Dinv = luinv(temp)

	msf = variance(Zdev)
	sfinvcov = invsym(msf + 0.0001 * I(ptot))
	stdcap = J(1, ptot, 1)
	for (k=1; k<=ptot; k++) {
		stdcap[k] = 1 / sqrt(max((Dinv[k,.] * msf * Dinv[k,.]', 0)))
		if (stdcap[k] > 1) stdcap[k] = 1
	}

	// --- Phase 2: Robbins-Monro, same schedule as before
	nsub = 4
	reduceg = 0.5
	gain = firstg
	n2min0 = max((5, 7 + ptot))
	n2minimum = J(1, nsub, 0)
	n2maximum = J(1, nsub, 0)
	n2minimum[1] = trunc(n2min0 * 2.52)
	n2maximum[1] = n2minimum[1] + 200
	for (k=2; k<=nsub; k++) {
		n2minimum[k] = trunc(n2minimum[k-1] * 2.52)
		n2maximum[k] = n2minimum[k] + 200
	}

	theta = theta0
	for (subphase=1; subphase<=nsub; subphase++) {
		thav = theta
		thavn = 1
		prod0 = J(1, ptot, 0)
		prod1 = J(1, ptot, 0)
		prevdev = J(1, ptot, 0)
		nit = 0
		maxacor = 1

		while (1) {
			nit = nit + 1
			SaomCoevSimMany(C, M, Mbeh, theta, 1, 0, Z1, S1)
			dev = Z1[1,.]

			if (mod(nit,2) == 1) prevdev = dev
			else {
				prod0 = prod0 + dev:^2
				prod1 = prod1 + dev:*prevdev
			}

			maxRatio = sqrt((dev * sfinvcov * dev') / ptot)
			if (maxRatio > 5 & maxRatio > 0) dev = 5 * dev / maxRatio

			if (nit == 1) changestep = dev
			else changestep = changestep + dev
			fchange = gain * ((changestep * Dinv') :* stdcap)

			thprev = theta
			theta = (thav / thavn) - fchange
			// rates stay positive: never more than halve one in a step
			for (k=p+1; k<=ptot; k++) if (theta[k] < 0.5*thprev[k]) theta[k] = 0.5*thprev[k]
			thav = thav + theta
			thavn = thavn + 1
			SaomCheckThetaBound(theta[1..p], 50)

			if (nit >= 2) {
				ac = J(1, ptot, -1)
				for (k=1; k<=ptot; k++) {
					if (prod0[k] > 1e-12) ac[k] = prod1[k] / prod0[k]
				}
				maxacor = max(ac)
			}

			if (nit >= n2maximum[subphase]) break
			if (nit >= n2minimum[subphase] & maxacor < 1e-10) break
		}

		theta = thav / thavn
		gain = gain * reduceg
	}

	fit.thetaNet = theta[1..C.pNet]
	fit.thetaBeh = theta[(C.pNet+1)..p]
	fit.ratesNet = theta[(p+1)..(p+P)]
	fit.ratesBeh = theta[(p+P+1)..ptot]

	// --- Phase 3: convergence check and sandwich covariance
	SaomCoevSimMany(C, M, Mbeh, theta, K3, 1, Zphase3, Zsco3)

	m3 = mean(Zphase3)
	S3 = variance(Zphase3)
	fit.tconv = J(1, ptot, 0)
	for (k=1; k<=ptot; k++) if (S3[k,k] > 1e-10) fit.tconv[k] = m3[k] / sqrt(S3[k,k])
	fit.tconvMax = sqrt(max((m3 * invsym(S3) * m3', 0)))

	// t-ratios on RSiena's scale (the matching entries of tconv)
	fit.tratioNet = fit.tconv[1..C.pNet]
	fit.tratioBeh = fit.tconv[(C.pNet+1)..p]
	fit.rateNetTratios = fit.tconv[(p+1)..(p+P)]
	fit.rateBehTratios = fit.tconv[(p+P+1)..ptot]

	Ddev3 = Zphase3 :- m3
	Dsco3 = Zsco3 :- mean(Zsco3)
	Dhat3 = (Ddev3' * Dsco3) / K3
	Dinv3 = luinv(Dhat3)
	fit.Vfull = Dinv3 * S3 * Dinv3'
	SaomCheckCovarianceFinite(fit.Vfull)
	fit.V = fit.Vfull[1..p, 1..p]
	fit.ratesNetSE = sqrt(diagonal(fit.Vfull)[(p+1)..(p+P)])'
	fit.ratesBehSE = sqrt(diagonal(fit.Vfull)[(p+P+1)..ptot])'

	if (hasbehsim) SaomBehSimSync(M, *Behwaves[1])
	if (C.use_batch) SaomBatchCleanup()
	if (C.use_native) SaomNativeCleanupFrame()

	return(fit)
}

/* ===================================================================
   SaomEstimateRMCoev: the two-wave case, a thin wrapper around
   SaomEstimateRMCoevMulti() (one period). Same arguments and result
   fields as before; rateNet/rateBeh are now ESTIMATED, with standard
   errors (rateNetSE/rateBehSE).
   =================================================================== */
struct SaomCoevFit {
	real rowvector thetaNet
	real rowvector thetaBeh
	real scalar rateNet
	real scalar rateBeh
	real scalar rateNetSE
	real scalar rateBehSE
	real rowvector tratioNet
	real rowvector tratioBeh
	real scalar rateNetTratio
	real scalar rateBehTratio
	real rowvector tconv		// RSiena convergence t-ratios: effects, network rate, behavior rate
	real scalar tconvMax
	real matrix V		// joint (pNet+pBeh) x (pNet+pBeh) covariance
	real matrix Vfull
}

struct SaomCoevFit scalar SaomEstimateRMCoev(
	class ErgmGraph scalar Gobs_start, class ErgmGraph scalar Gobs_end, class ErgmModel scalar M,
	real colvector Behobs_start_values, real colvector Behobs_end_values,
	real scalar behminval, real scalar behmaxval, class SaomBehaviorModel scalar Mbeh,
	real rowvector theta0Net, real rowvector theta0Beh,
	real scalar K0, real scalar K3, real scalar firstg, | real colvector present,
	real matrix missMaskNet, real colvector missMaskBeh) {

	struct SaomCoevFit scalar fit
	struct SaomCoevMultiFit scalar mf
	pointer(class ErgmGraph scalar) rowvector Gw
	pointer(real colvector) rowvector Bw
	pointer(real matrix) rowvector mnp
	pointer(real colvector) rowvector mbp

	Gw = (&Gobs_start, &Gobs_end)
	Bw = (&Behobs_start_values, &Behobs_end_values)
	if (args() == 16) {
		mnp = (&missMaskNet)
		mbp = (&missMaskBeh)
		mf = SaomEstimateRMCoevMulti(Gw, M, Bw, behminval, behmaxval, Mbeh, theta0Net, theta0Beh, K0, K3, firstg, (present, present), mnp, mbp)
	}
	else if (args() >= 14) {
		mf = SaomEstimateRMCoevMulti(Gw, M, Bw, behminval, behmaxval, Mbeh, theta0Net, theta0Beh, K0, K3, firstg, (present, present))
	}
	else {
		mf = SaomEstimateRMCoevMulti(Gw, M, Bw, behminval, behmaxval, Mbeh, theta0Net, theta0Beh, K0, K3, firstg)
	}

	fit.thetaNet = mf.thetaNet
	fit.thetaBeh = mf.thetaBeh
	fit.rateNet = mf.ratesNet[1]
	fit.rateBeh = mf.ratesBeh[1]
	fit.rateNetSE = mf.ratesNetSE[1]
	fit.rateBehSE = mf.ratesBehSE[1]
	fit.tratioNet = mf.tratioNet
	fit.tratioBeh = mf.tratioBeh
	fit.rateNetTratio = mf.rateNetTratios[1]
	fit.rateBehTratio = mf.rateBehTratios[1]
	fit.tconv = mf.tconv
	fit.tconvMax = mf.tconvMax
	fit.V = mf.V
	fit.Vfull = mf.Vfull
	return(fit)
}

/* ===================================================================
   Native (C) backend dispatch (harmonisation unit 6, docs/SAOM_ROADMAP.md
   "Native (C) backend"). Mirrors unw_ergm.do's own ErgmNativeAvailable()/
   ErgmNativePluginPath()/ErgmNativeSetup() pattern exactly, but for
   `native/saom_sim.c` (a wholly separate plugin file/program name/frame
   name from nwergm's own - see saom_sim.c's own header and this
   project's coordination note - never shares state with the concurrent
   nwergm session's own native work).

   SCOPE (harmonisation unit 10, extended from unit 6's original
   3-term set; further extended to add isolatenet/outiso, see the
   dedicated roadmap entry): covers all 15 network terms unw_saom.do
   currently implements - outdegree, reciprocity, nodematch, nodecov,
   nodeicov, nodeocov, indegpopularity, outactivity, outpopularity,
   inactivity, transtrip, cycle3, simcov, isolatenet, outiso
   (native/saom_sim.c's own termcode dispatch was extended in lockstep -
   see its own header comment). Extended after a
   direct RSiena speed benchmark found the pure-Mata fallback 400x+
   slower than real RSiena for ANY model using a non-native term - see
   docs/SAOM_ROADMAP.md's own account. A model using a term OUTSIDE this
   set (a future, not-yet-natively-ported effect) is simply not eligible
   - SaomNativeSetup() returns cfg.eligible=0 and the caller falls back
   to the pure-Mata SaomSimulateInterval()/SaomSimulateIntervalCounted(),
   never a silent partial fallback mid-run.
   =================================================================== */

/*
	TWO genuinely different lookup strategies are needed (harmonisation
	2026-09-02, docs/CERTIFICATION.md - see unw_ergm.do's own
	ErgmNativePluginPath() for the full account), tried in order:
	 (1) `findfile()` on the platform-specific basename alone - what
	     actually finds the plugin after a real `net install`, which
	     flattens every package "f" line into
	     PLUS/<firstletter-of-basename>/<basename>, discarding any
	     declared subdirectory entirely. Distinct per-platform basenames
	     (macOS and Windows used to share the bare "saom_sim.plugin"
	     name; only Unix had its own "_unix" suffix) are exactly what
	     let this same flat PLUS folder hold all three platforms'
	     binaries at once without collision.
	 (2) a manually-constructed path relative to nwsaom.ado's own
	     directory, `lib/plugins/<os>/<name>' - unreachable after a real
	     net install (per (1) above) but still needed for a raw git
	     checkout (`adopath ++ <repo-root>`): `findfile()` does not
	     search subdirectories of a plain adopath entry, so the nested
	     lib/plugins/<os>/ layout the repo itself uses is invisible to
	     strategy (1) alone.
*/
string scalar SaomNativePluginFilename(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("saom_sim_windows.plugin")
	if (os == "Unix") return("saom_sim_unix.plugin")
	return("saom_sim_macos.plugin")
}

string scalar SaomNativePluginSubdir(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("windows")
	if (os == "Unix") return("unix")
	return("macos")
}

/* Lookup order (changed 2026-09-30): the plugin that sits next to the
   nwsaom.ado actually being run (a git checkout's lib/plugins/<os>/)
   comes FIRST, findfile() on the flat basename (a net install) second.
   The old order let a stale `net install`ed copy in PLUS shadow a
   checkout's freshly built plugin, so a checkout silently ran an old
   binary - for co-evolution, one too old for unconditional estimation,
   which then fell back to the pure-Mata simulator (minutes instead of
   seconds). After a real net install there is no lib/plugins/ next to
   nwsaom.ado, so the findfile() branch is what applies there. */
string scalar SaomNativePluginPath(){
	string scalar fname, found, full, dir, fn, cand
	pointer(string scalar) scalar ovr

	// testing/benchmarking hook: a Mata external string
	// __nwsaom_saom_plugin, when set, names the plugin file to use
	ovr = findexternal("__nwsaom_saom_plugin")
	if (ovr != NULL) if (*ovr != "") return(*ovr)

	fname = SaomNativePluginFilename()
	full = findfile("nwsaom.ado")
	if (full != "") {
		pathsplit(full, dir, fn)
		cand = pathjoin(pathjoin(dir, "lib"),
			pathjoin("plugins", pathjoin(SaomNativePluginSubdir(), fname)))
		if (fileexists(cand)) return(cand)
	}
	found = findfile(fname)
	return(found)
}

/* Returns 0 (never errors) on any platform where lib/plugins/saom_sim.plugin
   was not built - currently macOS only (arm64+x86_64 universal, native/Makefile's
   `make macos-saom_sim`); Windows/Linux users transparently get the
   existing, fully-functional Mata backend instead. */
real scalar SaomNativeAvailable(){
	string scalar p

	p = SaomNativePluginPath()
	if (p == "") return(0)
	return(fileexists(p))
}

/* Populates termcodes/attridx/p1/attrmat from M's own term NAMES (the
   Stata-side dispatch in nwsaom.ado always registers these under
   exactly these names - see its own addterm() calls) - never re-derives
   eligibility from anything else. eligible=0 the moment any UNRECOGNIZED
   term name is found; still finishes building the arrays for the terms
   scanned so far, but the caller must check `eligible` before ever
   using them (matching ErgmNativeSetup()'s own "populate as a side
   effect, caller checks the return value first" contract).

   Harmonisation unit 10 ("learn lessons that help for all other
   effects", after a direct RSiena speed benchmark found the pure-Mata
   fallback 400x+ slower than real RSiena for ANY model using a
   non-native term - docs/SAOM_ROADMAP.md): extended from the original
   3-term set to all 13 terms unw_saom.do currently implements -
   native/saom_sim.c's own termcode dispatch was extended in lockstep
   (see its own header comment). Every term needing an attribute array
   gets its OWN column in `attrmat` (not deduplicated even if two terms
   happen to share the same underlying covariate) - simple over
   maximally compact, matching `MAXATTR`'s own generous cap in the C
   plugin. */
struct SaomNativeConfig scalar SaomNativeSetup(class ErgmModel scalar M){
	struct SaomNativeConfig scalar cfg
	class ErgmTermData scalar tdt
	real scalar t, nextattr, subA, subB, subC, si, hassimcov, needv9, needv10
	string scalar nm
	string rowvector nms

	hassimcov = 0
	needv9 = 0
	needv10 = 0
	cfg.needv11 = 0
	cfg.whynot = ""
	cfg.fntype = J(1, M.nterms, 0)
	cfg.structpairs = J(0, 2, 0)
	cfg.termcodes = J(1, M.nterms, 0)
	cfg.attridx = J(1, M.nterms, 0)
	cfg.p1 = J(1, M.nterms, 0)
	cfg.attrmat = J(0, 0, 0)	// built up column by column below, one per attribute-needing term
	cfg.eligible = 1
	nextattr = 0

	for (t=1; t<=M.nterms; t++) {
		nm = M.names[t]
		if (nm == "outdegree") cfg.termcodes[t] = 1
		// protocol 11: the endowment/creation terms are outdegree or
		// reciprocity gated by their function type (cfg.fntype, set by the
		// estimator from its own fntype list)
		else if (nm == "outdegreeendow" | nm == "outdegreecreation") {
			cfg.termcodes[t] = 1
			cfg.needv11 = 1
		}
		else if (nm == "reciprocityendow" | nm == "reciprocitycreation") {
			cfg.termcodes[t] = 2
			cfg.needv11 = 1
		}
		else if (nm == "reciprocity") cfg.termcodes[t] = 2
		else if (nm == "nodematch") {
			cfg.termcodes[t] = 3
			tdt = *M.td[t]
			nextattr++
			cfg.attridx[t] = nextattr
			cfg.attrmat = (cols(cfg.attrmat)==0 ? tdt.attr : (cfg.attrmat, tdt.attr))
		}
		else if (nm == "nodecov") {
			cfg.termcodes[t] = 4
			tdt = *M.td[t]
			nextattr++
			cfg.attridx[t] = nextattr
			cfg.attrmat = (cols(cfg.attrmat)==0 ? tdt.attr : (cfg.attrmat, tdt.attr))
		}
		else if (nm == "nodeicov") {
			cfg.termcodes[t] = 5
			tdt = *M.td[t]
			nextattr++
			cfg.attridx[t] = nextattr
			cfg.attrmat = (cols(cfg.attrmat)==0 ? tdt.attr : (cfg.attrmat, tdt.attr))
		}
		else if (nm == "nodeocov") {
			cfg.termcodes[t] = 6
			tdt = *M.td[t]
			nextattr++
			cfg.attridx[t] = nextattr
			cfg.attrmat = (cols(cfg.attrmat)==0 ? tdt.attr : (cfg.attrmat, tdt.attr))
		}
		else if (nm == "indegpopularity") cfg.termcodes[t] = 7
		else if (nm == "outactivity") cfg.termcodes[t] = 8
		else if (nm == "outpopularity") cfg.termcodes[t] = 9
		else if (nm == "inactivity") cfg.termcodes[t] = 10
		else if (nm == "transtrip") cfg.termcodes[t] = 11
		else if (nm == "cycle3") cfg.termcodes[t] = 12
		else if (nm == "simcov") {
			// protocol 9: the plugin gets x / range and the similarity
			// mean, d = 1 - |a_i - a_j| - p1
			cfg.termcodes[t] = 13
			tdt = *M.td[t]
			nextattr++
			cfg.attridx[t] = nextattr
			cfg.attrmat = (cols(cfg.attrmat)==0 ? tdt.attr / tdt.decay : (cfg.attrmat, tdt.attr / tdt.decay))
			cfg.p1[t] = _saom_center0(tdt)
			hassimcov = 1
		}
		else if (nm == "behsim") {
			// TERMCODE_BEHSIM (native/saom_sim.c): the plugin supplies the
			// behavior values itself (its own live behavior array), so no
			// attribute column; p1 carries the similarity mean, the range
			// comes from the behavior block of the wire protocol.
			cfg.termcodes[t] = 31
			tdt = *M.td[t]
			cfg.p1[t] = tdt.center
		}
		else if (nm == "isolatenet") cfg.termcodes[t] = 14
		else if (nm == "outiso") cfg.termcodes[t] = 15
		else if (nm == "transrectrip") cfg.termcodes[t] = 16
		else if (nm == "outoutass") cfg.termcodes[t] = 17
		else if (nm == "ininass") cfg.termcodes[t] = 18
		else if (nm == "outinass") cfg.termcodes[t] = 19
		else if (nm == "inoutass") cfg.termcodes[t] = 20
		else if (nm == "cycle4") cfg.termcodes[t] = 21
		else if (nm == "transmedtrip") cfg.termcodes[t] = 23
		else if (nm == "antiiniso") cfg.termcodes[t] = 24
		else if (nm == "antiiniso2") cfg.termcodes[t] = 25
		else if (nm == "in3plus") cfg.termcodes[t] = 29
		else if (nm == "antiiso" | nm == "isolatepop") {
			// protocol 9 (2026-10-01; before, these two ran in Mata)
			cfg.termcodes[t] = (nm == "antiiso" ? 32 : 33)
			needv9 = 1
		}
		else if (nm == "gwesp") {
			cfg.termcodes[t] = 26
			tdt = *M.td[t]
			cfg.p1[t] = tdt.decay
		}
		else if (nm == "transties") cfg.termcodes[t] = 27
		else if (nm == "balance") {
			cfg.termcodes[t] = 28
			tdt = *M.td[t]
			cfg.p1[t] = tdt.decay
		}
		else if (nm == "interact") {
			// TERMCODE_INTERACT2 (native/saom_sim.c's own #define comment
			// has the full design account): attridx/p1 are REPURPOSED here
			// to carry the two component effects' own 1-based TERM-INSTANCE
			// indices (into this SAME model's own termcodes[]/attridx[]/p1[]
			// arrays), not an attrmat column index/decay value - resolved by
			// NAME (td.sptype's own "nameA|nameB", see
			// stat_saom_interact()'s own header comment) against every
			// OTHER already-registered term in this model. Requires both
			// component names to already be registered as their own
			// main-effect terms BEFORE the interaction term itself -
			// enforced at the Stata/Mata layer (nwsaom.ado always adds an
			// interact()'s own two components first) - eligible=0 (falls
			// back to the fully-certified Mata path) if either name cannot
			// be found, rather than ever guessing.
			tdt = *M.td[t]
			nms = tokens(tdt.sptype, "|")
			if (cols(nms) > 3) {
				// three-way interact(): TERMCODE_INTERACT3 (protocol 11),
				// components A in attridx, B and C in p1 = B + 1000*C
				subA = 0
				subB = 0
				subC = 0
				if (rows(tdt.levels) >= 6) {
					subA = tdt.levels[4]
					subB = tdt.levels[5]
					subC = tdt.levels[6]
				}
				if (subA == 0 | subB == 0 | subC == 0) {
					cfg.eligible = 0
					if (cfg.whynot == "") cfg.whynot = "three-way interact() registered before 2026-10-01"
				}
				else {
					cfg.termcodes[t] = 34
					cfg.attridx[t] = subA
					cfg.p1[t] = subB + 1000 * subC
					cfg.needv11 = 1
				}
			}
			else {
				subA = 0
				subB = 0
				// component instances recorded by SaomBuildInteractTd()
				// (td.levels = decays, then instance indices)
				if (rows(tdt.levels) >= 4) {
					subA = tdt.levels[3]
					subB = tdt.levels[4]
				}
				else {
					for (si=1; si<=M.nterms; si++) {
						if (si == t) continue
						if (M.names[si] == nms[1] & subA == 0) subA = si
						if (M.names[si] == nms[3] & subB == 0) subB = si
					}
				}
				if (subA == 0 | subB == 0) {
					cfg.eligible = 0
					if (cfg.whynot == "") cfg.whynot = "interact() component not found"
				}
				else {
					cfg.termcodes[t] = 30
					cfg.attridx[t] = subA
					cfg.p1[t] = subB
					// the withdrawal sign of an interaction is right from
					// protocol 10 on
					needv10 = 1
				}
			}
		}
		else {
			cfg.eligible = 0
			if (cfg.whynot == "") cfg.whynot = "effect " + nm
		}
	}
	// the plugin's fixed limits (native/saom_sim.c MAXTERMS 32, MAXATTR 24
	// with one slot kept for behsim); larger models run in Mata
	// the plugin's limits (native/saom_sim.c MAXTERMS 256, MAXATTR 128 with
	// one slot kept for behsim; protocol 11, before: 32 and 24)
	if (M.nterms > 256 | cols(cfg.attrmat) > 127) {
		cfg.eligible = 0
		if (cfg.whynot == "") cfg.whynot = "more than 256 effects or 127 covariate arrays"
	}
	if (M.nterms > 32 | cols(cfg.attrmat) > 23) cfg.needv11 = 1
	if (cfg.eligible & cfg.needv11) {
		if (SaomNativePluginVersion() < 11) {
			cfg.eligible = 0
			if (cfg.whynot == "") cfg.whynot = "plugin older than protocol 11 (endowment/creation, three-way interact(), or a large model)"
		}
	}
	// before protocol 9 the limits were 16 terms and 7 attribute arrays
	if (cfg.eligible & needv10) {
		if (SaomNativePluginVersion() < 10) {
			cfg.eligible = 0
			if (cfg.whynot == "") cfg.whynot = "plugin older than protocol 10 (interact())"
		}
	}
	if (cfg.eligible & (M.nterms > 16 | cols(cfg.attrmat) > 7 | hassimcov | needv9)) {
		if (SaomNativePluginVersion() < 9) {
			cfg.eligible = 0
			if (cfg.whynot == "") cfg.whynot = "plugin older than protocol 9 (simx(), antiiso, isolatepop, or more than 16 effects)"
		}
	}
	return(cfg)
}

/* Behavior-side counterpart to SaomNativeSetup() (harmonisation unit
   26) - ALL four v1 behavior effects (linear/quadratic/avalt/avsim)
   have native coverage from the start (native/saom_sim.c's own
   TERMCODE_BEH_* dispatch), unlike the network side's own gradual
   13-of-many rollout, since there are only ever four of them.

   Harmonisation unit 28: endowment/creation-type terms (fntype!=0,
   SaomBehaviorModel::full_change()'s own header comment) are NOT
   natively covered - the C plugin's own saom_beh_change_term()
   dispatch has no concept of direction-gating by type, so a term with
   fntype!=0 unconditionally flips cfg.eligible=0 regardless of its own
   NAME already being recognized, forcing the fully-certified Mata
   fallback for the WHOLE model (never a silent partial/wrong native
   run that would ignore the gating). */
struct SaomBehaviorNativeConfig scalar SaomBehaviorNativeSetup(class SaomBehaviorModel scalar Mbeh){
	struct SaomBehaviorNativeConfig scalar cfg
	real scalar t
	string scalar nm

	cfg.termcodes = J(1, Mbeh.nterms, 0)
	cfg.fntype = J(1, Mbeh.nterms, 0)
	cfg.eligible = 1
	for (t=1; t<=Mbeh.nterms; t++) {
		nm = Mbeh.names[t]
		// protocol 11: endowment/creation terms are the eval term gated by
		// the direction of the change (the caller checks the version)
		cfg.fntype[t] = Mbeh.fntype[t]
		if (strpos(nm, "_endow")) nm = subinstr(nm, "_endow", "")
		if (strpos(nm, "_creation")) nm = subinstr(nm, "_creation", "")
		if (nm == "linear") cfg.termcodes[t] = 101
		else if (nm == "quadratic") cfg.termcodes[t] = 102
		else if (nm == "avalt") cfg.termcodes[t] = 103
		else if (nm == "avsim") cfg.termcodes[t] = 104
		else cfg.eligible = 0
	}
	return(cfg)
}

/*
   Native counterpart to SaomSimulateIntervalCounted() - same contract
   (mutates G in place to the simulated end-of-interval network, returns
   total ministep opportunities, accepted-change count and, from plugin
   protocol 5, the end-vs-start distance `netdist')
   - but the entire simulation loop runs inside ONE `plugin call` to
   native/saom_sim.c, never crossing
   the Mata/native boundary per ministep (see saom_sim.c's own header
   and docs/SAOM_ARCHITECTURE.md's "Native backend" section). Callers
   MUST check cfg.eligible (from SaomNativeSetup()) first - this
   function does not re-derive eligibility itself, matching
   ErgmNativeSampleCore()'s own established contract.

   Frame/wire-protocol details (dedicated frame, v1/v2 edge-list
   columns, attribute columns, argstr layout) directly mirror
   ErgmNativeSampleCore() (unw_ergm.do) - same pattern, independent
   frame name ("__saom_native", never "__ergm_native") and independent
   plugin program name ("saomnativesim", never "ergmnativemcmc") so the
   two initiatives' native calls cannot collide even if both run in the
   same Stata session.
*/
/* SaomTrailer11(): the protocol-11 model trailer of the plugin's wire
   string (native/saom_sim.c parse_model_trailer11()): endowment/creation
   codes of the network and behavior terms, and the structural dyads.
   Older plugins ignore it (the model is then not sent to them: see the
   version checks in the estimators). */
string scalar SaomTrailer11(struct SaomNativeConfig scalar cfg, real scalar nterms, real rowvector behfntype) {
	string scalar s
	real rowvector fn
	real scalar i, hasfn

	fn = J(1, nterms, 0)
	if (cols(cfg.fntype) == nterms) fn = cfg.fntype
	hasfn = any(fn :!= 0)
	if (cols(behfntype) > 0) hasfn = hasfn | any(behfntype :!= 0)
	if (hasfn) {
		s = " 1"
		for (i=1; i<=nterms; i++) s = s + " " + strofreal(fn[i])
		for (i=1; i<=cols(behfntype); i++) s = s + " " + strofreal(behfntype[i])
	}
	else s = " 0"
	s = s + " " + strofreal(rows(cfg.structpairs))
	for (i=1; i<=rows(cfg.structpairs); i++) s = s + " " + strofreal(cfg.structpairs[i,1]) + " " + strofreal(cfg.structpairs[i,2])
	return(s)
}

struct SaomCountedResult scalar SaomSimulateIntervalNative(class ErgmGraph scalar G, class ErgmModel scalar M,
	struct SaomNativeConfig scalar cfg, real rowvector theta, real scalar rate, real scalar rebuild_g,
	real scalar want_score, | real matrix missDyads, real colvector present, real scalar symtype,
	real matrix ratecovattr, real rowvector ratecoef, real scalar condtarget){

	struct SaomCountedResult scalar res
	real matrix ties, newties
	real scalar n, nties, nattr, i, k, rngseed, nties_out, __junk, neededrows, neededvars, hasmiss, nmissdyads, haspresentNet, symtypearg, hasratecov, iscondnat
	string scalar origframe, argstr, cmd, attrvarlist
	string rowvector attrvarnames

	// symtype (undirected/symmetric relations, native-first): a 10th,
	// backward-compatible optional trailing arg, matching missDyads'/
	// present's own established "args()-gated, every pre-existing caller
	// omits it" convention in this same function - see native/saom_sim.c's
	// own header comment on the wire-protocol field this feeds.
	symtypearg = (args() >= 10) ? symtype : 0

	// ratecov (covariate-dependent rate, native-first per direct
	// instruction): TWO more trailing args, 11th/12th. CONTENT-based
	// gating (rows(ratecovattr)>0), not arg-count-based - this file's own
	// established, hard-learned fix for the identical class of bug
	// symtype's own header comment already documents (a later caller
	// needing to reach a MORE-trailing argument, without genuinely
	// wanting this one, would otherwise still have to supply SOME
	// placeholder for ratecovattr/ratecoef to get there - args()>=12
	// alone would wrongly read as hasratecov=true for that caller too).
	// hasratecov = number of ratecov() variables (columns of ratecovattr)
	hasratecov = (args() >= 12) ? (rows(ratecovattr) > 0 ? cols(ratecovattr) : 0) : 0

	n = G.n
	ties = G.all_ties()
	nties = rows(ties)
	nattr = cols(cfg.attrmat)

	// harmonisation unit 35 (missing data, native port) - see
	// native/saom_sim.c's own "MISSING DATA" header section for the
	// full wire-protocol/masking account. `missDyads' is OPTIONAL and
	// backward-compatible (every pre-existing caller omits it) - a
	// PRE-COMPUTED sparse (i,j) dyad list (SaomMaskToDyadList(),
	// computed ONCE per fit by the caller, NOT the raw n x n mask -
	// see that function's own header comment for the real performance
	// bug this avoids: converting the mask to a sparse list on EVERY
	// one of the hundreds-to-thousands of native calls a single fit
	// makes completely erased the native speed advantage). `hasmiss'
	// is CONTENT-based (rows(missDyads)>0), not arg-count-based - a
	// real, corrected bug: since a composition-change-only caller must
	// still supply an EMPTY missDyads placeholder to reach the trailing
	// `present' argument, an arg-count check ("was missDyads passed at
	// all") would incorrectly report hasmiss=true for that fit too,
	// corrupting the __saom_native frame's own column layout (see
	// SaomMaskToDyadList()'s own header comment for the sibling
	// performance bug this same investigation found in this area).
	if (args() >= 8) nmissdyads = rows(missDyads)
	else nmissdyads = 0
	hasmiss = (nmissdyads > 0)

	// harmonisation unit 33 (composition change, native port) - see
	// native/saom_sim.c's own "COMPOSITION CHANGE" header section.
	// `present' is OPTIONAL, only reachable alongside `missDyads' (Mata's
	// own optional-argument ordering rule) - a composition-change-only
	// caller passes an empty missDyads placeholder (J(0,2,0)) to reach
	// it, matching this file's own established convention for the
	// reverse case (a missing-data-only caller already passes an
	// all-present placeholder to the ESTIMATOR's own present parameter).
	haspresentNet = 0
	if (args() >= 9) haspresentNet = (rows(present) > 0)

	// worst case: the simulated network densifies up to the full
	// directed dyad space (n*(n-1)) before the interval ends - the frame
	// must have enough rows for whatever nties_out the plugin returns,
	// not just the STARTING tie count (matches ErgmNativeSampleCore()'s
	// own identical "size for the full dyad space" defensiveness in
	// unw_ergm.do).
	neededrows = max((n, nties, n*(n-1), 1))
	neededvars = 2 + nattr + (hasmiss ? 3 : 0) + (haspresentNet ? 1 : 0)

	origframe = st_framecurrent()
	stata("capture frame create __saom_native")
	st_framecurrent("__saom_native")

	// harmonisation unit 12 (performance pass, see docs/SAOM_ROADMAP.md's
	// "Native backend performance" entry): this frame is now REUSED across
	// every call within one SaomEstimateRM() run instead of being dropped
	// and recreated on EVERY plugin call - a direct controlled A/B
	// (unit 11) found frame create/drop overhead, not the ministep loop
	// itself, dominates wall time at realistic Robbins-Monro call volumes
	// (hundreds to low thousands of calls per fit, all sharing the same
	// `n`). The common case after the first call: `st_nvar()` already
	// matches `neededvars` and `st_nobs()` already covers `neededrows`, so
	// st_addvar()/st_addobs() below are both skipped entirely. Only
	// rebuilt from scratch if the existing frame's own variable count
	// doesn't match what THIS call needs (a different model/n reusing the
	// same frame name across separate fits in one Stata session, or a
	// stray __saom_native left by an interrupted prior run) - never
	// silently reused with a stale/mismatched layout. SaomEstimateRM()
	// drops this frame once, via SaomNativeCleanupFrame(), after its own
	// last native call - not here, not per call.
	if (st_nvar() > 0 & st_nvar() != neededvars) {
		st_framecurrent(origframe)
		stata("frame drop __saom_native")
		stata("frame create __saom_native")
		st_framecurrent("__saom_native")
	}

	attrvarlist = ""
	attrvarnames = J(1, nattr, "")
	for (i=1; i<=nattr; i++) attrvarnames[i] = "a" + strofreal(i)

	if (st_nvar() == 0) {
		__junk = st_addvar("double", "v1")
		__junk = st_addvar("double", "v2")
		for (i=1; i<=nattr; i++) __junk = st_addvar("double", attrvarnames[i])
		if (hasmiss) {
			__junk = st_addvar("double", "mv1")
			__junk = st_addvar("double", "mv2")
			__junk = st_addvar("double", "missbeh")
		}
		if (haspresentNet) __junk = st_addvar("double", "present")
	}
	for (i=1; i<=nattr; i++) attrvarlist = attrvarlist + " " + attrvarnames[i]

	if (st_nobs() < neededrows) st_addobs(neededrows - st_nobs())

	for (i=1; i<=nattr; i++) st_store((1::n), attrvarnames[i], cfg.attrmat[1::n, i])
	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)
	// harmonisation unit 35 - see native/saom_sim.c's own "MISSING DATA"
	// header section. `missbeh' is always written all-zero here (this
	// wrapper is network-only, never behavior-aware) - the shared
	// masking-graph machinery on the C side always reads it, harmlessly,
	// whenever hasmiss=1.
	if (hasmiss) {
		if (nmissdyads > 0) st_store((1::nmissdyads), ("mv1","mv2"), missDyads)
		st_store((1::n), "missbeh", J(n, 1, 0))
	}
	// harmonisation unit 33 (composition change, native port) - see
	// native/saom_sim.c's own "COMPOSITION CHANGE" header section.
	if (haspresentNet) st_store((1::n), "present", present)

	rngseed = floor(runiform(1,1) * 2147483647)

	argstr = strofreal(n) + " " + strofreal(G.directed) + " " + strofreal(nties) + " " +
		strofreal(rate, "%25.17g") + " " + strofreal(rngseed, "%12.0f") + " " + strofreal(nattr) + " " + strofreal(M.nterms)
	for (i=1; i<=M.nterms; i++) {
		argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i], "%25.17g")
	}
	for (i=1; i<=M.nterms; i++) argstr = argstr + " " + strofreal(theta[i], "%25.17g")
	argstr = argstr + " " + strofreal(want_score)		// harmonisation unit 16 - trailing field, see native/saom_sim.c's own stata_call() parsing
	argstr = argstr + " 0"		// harmonisation unit 26: nbehterms=0 - the network-only wire-protocol footprint is now "no further fields at all"; see SaomSimulateIntervalCoevNative() below for the co-evolution counterpart that supplies real behavior fields here
	// condmode/targetChange: conditional simulation when `condtarget' (13th
	// argument) is given and >= 0 (SaomEstimateNet()'s conditional
	// estimation), the unit interval otherwise
	iscondnat = 0
	if (args() >= 13) iscondnat = (condtarget < . & condtarget >= 0)
	if (iscondnat) argstr = argstr + " 1 " + strofreal(condtarget, "%12.0f")
	else argstr = argstr + " 0 0"
	argstr = argstr + " " + strofreal(hasmiss) + " " + strofreal(nmissdyads)		// harmonisation unit 35 - see native/saom_sim.c's own "MISSING DATA" header section
	argstr = argstr + " " + strofreal(haspresentNet)		// harmonisation unit 33 (native port) - see native/saom_sim.c's own "COMPOSITION CHANGE" header section
	argstr = argstr + " " + strofreal(symtypearg)		// undirected/symmetric relations (native-first) - see native/saom_sim.c's own header comment on this field
	argstr = argstr + " " + strofreal(hasratecov)		// ratecov (native-first) - see native/saom_sim.c's own header comment on this field
	if (hasratecov) {
		// K covariates: K x n values (variable by variable), then K
		// coefficients; K = 1 is the protocol-7 layout unchanged
		for (k=1; k<=hasratecov; k++) {
			for (i=1; i<=n; i++) argstr = argstr + " " + strofreal(ratecovattr[i,k], "%25.17g")
		}
		for (k=1; k<=hasratecov; k++) argstr = argstr + " " + strofreal(ratecoef[k], "%25.17g")
	}
	argstr = argstr + SaomTrailer11(cfg, M.nterms, J(1, 0, 0))

	// see ErgmNativeSampleCore()'s own header comment for why `capture`
	// here is correct (an already-defined plugin program cannot be
	// redefined within the same session) rather than masking a genuine
	// failure - a bad path/corrupt plugin still surfaces at `plugin call`.
	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")

	cmd = "plugin call saomnativesim v1 v2" + attrvarlist + (hasmiss ? " mv1 mv2 missbeh" : "") + (haspresentNet ? " present" : "") + ", " + char(34) + argstr + char(34)
	stata(cmd)

	nties_out = st_numscalar("__saom_native_nties_out")
	res.steps = st_numscalar("__saom_native_steps")
	res.nchanges = st_numscalar("__saom_native_nchanges")
	res.netdist = st_numscalar("__saom_native_netdist")		// protocol >= 5 (network-only models too)
	res.t = st_numscalar("__saom_native_condtime")

	// harmonisation unit 14: the plugin now ALSO returns the full
	// statistic vector directly (saom_stat_term(), native/saom_sim.c),
	// computed on the SAME final graph state the edge list below
	// reflects - so SaomEstimateRM()'s own native path can use res.stat
	// in place of a second M.full_statistic(Gwork) pass (see that
	// function's own header comment for the measured cost this avoids).
	res.stat = J(1, M.nterms, 0)
	for (i=1; i<=M.nterms; i++) res.stat[i] = st_numscalar("__saom_native_stat" + strofreal(i))

	// harmonisation unit 16: phase 1's own score-function derivative
	// estimator (mirrors SaomSimulateIntervalScored()'s own construction
	// exactly, computed natively - see that Mata function's own header
	// comment for the score derivation this ports).
	if (want_score) {
		res.score = J(1, M.nterms, 0)
		for (i=1; i<=M.nterms; i++) res.score[i] = st_numscalar("__saom_native_score" + strofreal(i))
	}
	if (hasratecov) {
		res.rcscore = J(1, hasratecov, 0)
		for (k=1; k<=hasratecov; k++) res.rcscore[k] = st_numscalar("__saom_native_rcscore" + strofreal(k))
	}

	// harmonisation unit 15 (performance pass, see docs/SAOM_ROADMAP.md's
	// own "Native backend performance" entry): `G' was read-only above
	// (only G.n/G.all_ties()/G.directed) - reconstructing it into the
	// FINAL simulated network is only needed by callers that actually
	// inspect G afterward (the test suite's own equivalence checks).
	// SaomEstimateRM()'s own native-path calls stopped needing this the
	// moment unit 14 gave them `res.stat' directly - profiling found
	// SaomCopyGraph() plus this same toggle()-per-tie reconstruction
	// loop, run BEFORE and AFTER every one of hundreds-to-thousands of
	// calls per fit, was itself a real, avoidable cost once the ONLY
	// reason for the round trip (getting a final G to hand to
	// M.full_statistic()) no longer applies. `rebuild_g=0' skips BOTH
	// the newties read-back and the toggle() loop entirely, leaving G
	// completely untouched - which is exactly what lets
	// SaomEstimateRM() pass its own `Gobs_start' directly instead of a
	// fresh SaomCopyGraph() copy (G is never mutated in this mode, so
	// the caller's own object stays pristine for the next iteration).
	if (rebuild_g) {
		if (nties_out > 0) newties = st_data((1::nties_out), ("v1","v2"))
		else newties = J(0, 2, 0)
		G.init(n, 1)
		for (i=1; i<=rows(newties); i++) G.toggle(newties[i,1], newties[i,2])
	}

	st_framecurrent(origframe)

	return(res)
}

/* ===================================================================
   SaomSimulateCondTimeNative: native (C) counterpart to
   SaomSimulateConditionalTime() above (see there): same frame/argstr
   contract as SaomSimulateIntervalNative(), rate 1, and
   `condmode=1'/`targetChange' select native/saom_sim.c's conditional
   stopping rule. Not used by the estimators; certified against the Mata
   version in cscripts/test_nwsaom_native.do.
   =================================================================== */
real scalar SaomSimulateCondTimeNative(class ErgmGraph scalar G, class ErgmGraph scalar Gstart,
	class ErgmModel scalar M, struct SaomNativeConfig scalar cfg, real rowvector theta, real scalar targetChange) {

	real matrix ties
	real scalar n, nties, nattr, i, rngseed, neededrows, neededvars, __junk, condtime
	string scalar origframe, argstr, cmd, attrvarlist
	string rowvector attrvarnames

	n = G.n
	ties = Gstart.all_ties()
	nties = rows(ties)
	nattr = cols(cfg.attrmat)

	neededrows = max((n, nties, n*(n-1), 1))
	neededvars = 2 + nattr

	origframe = st_framecurrent()
	stata("capture frame create __saom_native")
	st_framecurrent("__saom_native")

	if (st_nvar() > 0 & st_nvar() != neededvars) {
		st_framecurrent(origframe)
		stata("frame drop __saom_native")
		stata("frame create __saom_native")
		st_framecurrent("__saom_native")
	}

	attrvarlist = ""
	attrvarnames = J(1, nattr, "")
	for (i=1; i<=nattr; i++) attrvarnames[i] = "a" + strofreal(i)

	if (st_nvar() == 0) {
		__junk = st_addvar("double", "v1")
		__junk = st_addvar("double", "v2")
		for (i=1; i<=nattr; i++) __junk = st_addvar("double", attrvarnames[i])
	}
	for (i=1; i<=nattr; i++) attrvarlist = attrvarlist + " " + attrvarnames[i]

	if (st_nobs() < neededrows) st_addobs(neededrows - st_nobs())

	for (i=1; i<=nattr; i++) st_store((1::n), attrvarnames[i], cfg.attrmat[1::n, i])
	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)

	rngseed = floor(runiform(1,1) * 2147483647)

	// rate=1 (the verified reference rate, NOT a fitted value),
	// want_score=0, nbehterms=0, condmode=1 - see this function's own
	// header comment.
	argstr = strofreal(n) + " " + strofreal(G.directed) + " " + strofreal(nties) + " " +
		strofreal(1) + " " + strofreal(rngseed, "%12.0f") + " " + strofreal(nattr) + " " + strofreal(M.nterms)
	for (i=1; i<=M.nterms; i++) {
		argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i], "%25.17g")
	}
	for (i=1; i<=M.nterms; i++) argstr = argstr + " " + strofreal(theta[i], "%25.17g")
	argstr = argstr + " 0"		// want_score=0
	argstr = argstr + " 0"		// nbehterms=0
	argstr = argstr + " 1 " + strofreal(targetChange, "%25.17g")		// condmode=1, targetChange
	argstr = argstr + " 0 0"		// hasmiss=0/nmissdyads=0: conditional mode supports neither missing data nor the fields below, but the wire protocol's trailing fields are a fixed contract every caller supplies
	argstr = argstr + " 0"		// haspresentNet=0
	argstr = argstr + " 0"		// symtype=0
	argstr = argstr + " 0"		// hasratecov=0

	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")

	cmd = "plugin call saomnativesim v1 v2" + attrvarlist + ", " + char(34) + argstr + char(34)
	stata(cmd)

	condtime = st_numscalar("__saom_native_condtime")

	st_framecurrent(origframe)

	return(condtime)
}

/*
   Native counterpart to SaomSimulateIntervalCoevScored() (harmonisation
   unit 26) - same wire-protocol/frame contract as
   SaomSimulateIntervalNative() above (v1/v2 edge-list columns,
   attribute columns, dedicated __saom_native frame - see that
   function's own header comment), extended with ONE further column
   (behavior values, right after the last attribute column) and the
   trailing "nbehterms [behtermcode]*nbehterms [thetaBeh]*nbehterms
   rateBeh behminval behmaxval behSimMean behOverallMean" wire fields
   native/saom_sim.c's own stata_call() parses after `want_score' -
   ALWAYS want_score=1 here (unlike the network-only function's own
   optional flag), since every phase of SaomEstimateRMCoev()/
   SaomEstimateRMCoevMulti() needs both scoreNet and scoreBeh. Callers
   MUST check BOTH cfg.eligible (network terms) AND cfgBeh.eligible
   (behavior terms) first - this function does not re-derive either.

   `res.stat'/`res.statBeh' (harmonisation unit 31, per explicit user
   direction "yes, look into it" after co-evolution's own ~3.2x-slower-
   than-RSiena gap was profiled and root-caused to EXACTLY this: every
   phase-1/2/3 iteration was paying a full, pure-Mata M.full_statistic()
   + Mbeh.full_statistic() re-derivation on top of the already-fast
   native ministep simulation - the SAME cost class unit 14 already
   eliminated for the network-only path, just never extended here when
   co-evolution was built). native/saom_sim.c's own stata_call()
   ALREADY computed and wrote back both `__saom_native_stat%d' and
   `__saom_native_statbeh%d' unconditionally (harmonisation unit 14/26
   - verified directly by reading that file, not assumed) - this was
   purely a Mata-side gap, nothing needed on the C side at all. `G'/
   `Beh' are the SAME final graph/behavior-values written back either
   way; `rebuild_g' (new parameter, same explicit caller-controlled
   convention as SaomSimulateIntervalNative()'s own identical flag,
   harmonisation unit 15) skips the edge-list-toggle reconstruction
   loop entirely when the caller only needs `res.stat'/`res.statBeh'
   (every current SaomEstimateRMCoev()/SaomEstimateRMCoevMulti() call
   site) - `Beh.values' is always written back regardless (needed by
   every caller, a separate, already-cheap st_data() read, not the
   toggle loop this flag controls).
*/
struct SaomCoevScoredResult scalar SaomSimulateIntervalCoevNative(
	class ErgmGraph scalar G, class ErgmModel scalar M, struct SaomNativeConfig scalar cfg, real rowvector theta,
	class SaomBehavior scalar Beh, class SaomBehaviorModel scalar Mbeh, struct SaomBehaviorNativeConfig scalar cfgBeh,
	real rowvector thetaBeh, real scalar rateNet, real scalar rateBeh, real scalar rebuild_g,
	| real matrix missDyads, real colvector missMaskBeh, real colvector present){

	struct SaomCoevScoredResult scalar res
	real matrix ties, newties
	real scalar n, nties, nattr, i, rngseed, nties_out, __junk, neededrows, neededvars, pBeh, hasmiss, nmissdyads, haspresentNet
	string scalar origframe, argstr, cmd, attrvarlist, behvarname

	n = G.n
	ties = G.all_ties()
	nties = rows(ties)
	nattr = cols(cfg.attrmat)
	pBeh = Mbeh.nparam()

	// harmonisation unit 35 (missing data, native port) - same design
	// as SaomSimulateIntervalNative()'s own identical parameter (see
	// SaomMaskToDyadList()'s own header comment for why `missDyads' is
	// a PRE-COMPUTED sparse dyad list, not the raw n x n mask); see
	// native/saom_sim.c's own "MISSING DATA" header section. Both
	// `missDyads'/`missMaskBeh' are required TOGETHER when supplied
	// (Mata's own optional-argument ordering rule) - a network-only
	// missing-data fit still passes an all-zero missMaskBeh, matching
	// the SAME "never branch at the call site" convention
	// nwsaom.ado/unw_saom.do already use elsewhere for this unit.
	// `hasmiss' is CONTENT-based (nmissdyads>0 OR missMaskBeh has any
	// masked actor), not arg-count-based - see
	// SaomSimulateIntervalNative()'s own identical fix for the real bug
	// this corrects (a composition-change-only caller must still supply
	// EMPTY missDyads/missMaskBeh placeholders to reach the trailing
	// `present' argument). Checking BOTH missDyads and missMaskBeh's
	// own content (not just one) correctly covers a missnet()-only fit,
	// a missbeh()-only fit (nmissdyads==0 but missMaskBeh has real
	// content), and both together.
	if (args() >= 12) nmissdyads = rows(missDyads)
	else nmissdyads = 0
	hasmiss = 0
	if (args() >= 13) hasmiss = (nmissdyads > 0) | (max(missMaskBeh) > 0)

	// harmonisation unit 33 (composition change, native port) - see
	// SaomSimulateIntervalNative()'s own identical parameter and
	// native/saom_sim.c's own "COMPOSITION CHANGE" header section.
	// `present' is only reachable alongside `missDyads'/`missMaskBeh'
	// (Mata's own optional-argument ordering rule).
	haspresentNet = (args() == 14)

	neededrows = max((n, nties, n*(n-1), 1))
	neededvars = 3 + nattr + (hasmiss ? 3 : 0) + (haspresentNet ? 1 : 0)		// v1, v2, behavior column, + attributes (one more than SaomSimulateIntervalNative()'s own neededvars - see this function's own header comment)

	origframe = st_framecurrent()
	stata("capture frame create __saom_native")
	st_framecurrent("__saom_native")

	if (st_nvar() > 0 & st_nvar() != neededvars) {
		st_framecurrent(origframe)
		stata("frame drop __saom_native")
		stata("frame create __saom_native")
		st_framecurrent("__saom_native")
	}

	attrvarlist = ""
	if (st_nvar() == 0) {
		__junk = st_addvar("double", "v1")
		__junk = st_addvar("double", "v2")
		for (i=1; i<=nattr; i++) __junk = st_addvar("double", "a" + strofreal(i))
		__junk = st_addvar("double", "vbeh")
		if (hasmiss) {
			__junk = st_addvar("double", "mv1")
			__junk = st_addvar("double", "mv2")
			__junk = st_addvar("double", "missbeh")
		}
		if (haspresentNet) __junk = st_addvar("double", "present")
	}
	for (i=1; i<=nattr; i++) attrvarlist = attrvarlist + " a" + strofreal(i)
	behvarname = "vbeh"

	if (st_nobs() < neededrows) st_addobs(neededrows - st_nobs())

	for (i=1; i<=nattr; i++) st_store((1::n), "a" + strofreal(i), cfg.attrmat[1::n, i])
	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)
	st_store((1::n), behvarname, Beh.values)
	// harmonisation unit 35 - see native/saom_sim.c's own "MISSING DATA"
	// header section.
	if (hasmiss) {
		if (nmissdyads > 0) st_store((1::nmissdyads), ("mv1","mv2"), missDyads)
		st_store((1::n), "missbeh", missMaskBeh)
	}
	// harmonisation unit 33 (composition change, native port).
	if (haspresentNet) st_store((1::n), "present", present)

	rngseed = floor(runiform(1,1) * 2147483647)

	argstr = strofreal(n) + " " + strofreal(G.directed) + " " + strofreal(nties) + " " +
		strofreal(rateNet, "%25.17g") + " " + strofreal(rngseed, "%12.0f") + " " + strofreal(nattr) + " " + strofreal(M.nterms)
	for (i=1; i<=M.nterms; i++) {
		argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i], "%25.17g")
	}
	for (i=1; i<=M.nterms; i++) argstr = argstr + " " + strofreal(theta[i], "%25.17g")
	argstr = argstr + " 1"		// want_score - always 1, see this function's own header comment
	argstr = argstr + " " + strofreal(pBeh)
	for (i=1; i<=pBeh; i++) argstr = argstr + " " + strofreal(cfgBeh.termcodes[i])
	for (i=1; i<=pBeh; i++) argstr = argstr + " " + strofreal(thetaBeh[i], "%25.17g")
	argstr = argstr + " " + strofreal(rateBeh, "%25.17g") + " " + strofreal(Beh.minval, "%25.17g") + " " + strofreal(Beh.maxval, "%25.17g") +
		" " + strofreal(Beh.simMean, "%25.17g") + " " + strofreal(Beh.overallMean, "%25.17g")
	argstr = argstr + " 0 0"		// harmonisation unit 30: condmode=0/targetChange=0 - conditional mode is not used by the estimators
	argstr = argstr + " " + strofreal(hasmiss) + " " + strofreal(nmissdyads)		// harmonisation unit 35 - see native/saom_sim.c's own "MISSING DATA" header section
	argstr = argstr + " " + strofreal(haspresentNet)		// harmonisation unit 33 (native port) - see native/saom_sim.c's own "COMPOSITION CHANGE" header section
	argstr = argstr + " 0"		// undirected/symmetric relations (native-first): symtype=0 - the co-evolution path does not yet support symmetric relations (out of scope for this unit), same FIXED-trailer contract
	argstr = argstr + " 0"		// ratecov (native-first): hasratecov=0 - ratecov() is rejected together with co-evolution at the .ado layer (v1 scope), same FIXED-trailer contract
	argstr = argstr + SaomTrailer11(cfg, M.nterms, (cols(cfgBeh.fntype) == Mbeh.nterms ? cfgBeh.fntype : J(1, Mbeh.nterms, 0)))

	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")

	cmd = "plugin call saomnativesim v1 v2" + attrvarlist + " " + behvarname + (hasmiss ? " mv1 mv2 missbeh" : "") + (haspresentNet ? " present" : "") + ", " + char(34) + argstr + char(34)
	stata(cmd)

	nties_out = st_numscalar("__saom_native_nties_out")
	res.steps = st_numscalar("__saom_native_steps")
	res.nchangesNet = st_numscalar("__saom_native_nchanges")
	res.nchangesBeh = st_numscalar("__saom_native_nchangesbeh")

	res.scoreNet = J(1, M.nterms, 0)
	for (i=1; i<=M.nterms; i++) res.scoreNet[i] = st_numscalar("__saom_native_score" + strofreal(i))
	res.scoreBeh = J(1, pBeh, 0)
	for (i=1; i<=pBeh; i++) res.scoreBeh[i] = st_numscalar("__saom_native_scorebeh" + strofreal(i))

	// harmonisation unit 31 - see this function's own header comment.
	res.stat = J(1, M.nterms, 0)
	for (i=1; i<=M.nterms; i++) res.stat[i] = st_numscalar("__saom_native_stat" + strofreal(i))
	res.statBeh = J(1, pBeh, 0)
	for (i=1; i<=pBeh; i++) res.statBeh[i] = st_numscalar("__saom_native_statbeh" + strofreal(i))
	// unconditional co-evolution estimation (plugin protocol version 2)
	res.stepsNet = st_numscalar("__saom_native_stepsnet")
	res.stepsBeh = st_numscalar("__saom_native_stepsbeh")
	res.netdist = st_numscalar("__saom_native_netdist")
	res.statBehLag = J(1, pBeh, 0)
	for (i=1; i<=pBeh; i++) res.statBehLag[i] = st_numscalar("__saom_native_statbehlag" + strofreal(i))

	if (rebuild_g) {
		if (nties_out > 0) newties = st_data((1::nties_out), ("v1","v2"))
		else newties = J(0, 2, 0)
		G.init(n, 1)
		for (i=1; i<=rows(newties); i++) G.toggle(newties[i,1], newties[i,2])
	}

	Beh.values = st_data((1::n), behvarname)

	st_framecurrent(origframe)

	return(res)
}

/* RSiena's coCovar(centered = TRUE) (sienaDataCreate.r): a constant
   covariate is stored minus its mean, missing values imputed by it (0
   after centring). SaomCovPrep(): one variable, its mean in `m';
   SaomCovPrepMat(): every column. */
real colvector SaomCovPrep(real colvector x, real scalar center, real scalar m) {
	real colvector y
	real scalar i
	m = mean(select(x, x :< .))
	y = x
	for (i=1; i<=rows(y); i++) if (y[i] >= .) y[i] = m
	if (center) y = y :- m
	return(y)
}
real matrix SaomCovPrepMat(real matrix X, real scalar center) {
	real matrix Y
	real scalar k, m
	Y = X
	for (k=1; k<=cols(X); k++) Y[., k] = SaomCovPrep(X[., k], center, m)
	return(Y)
}

/* RSiena's effect names (getEffects() effectName) of the effects of a fit,
   in e(b) order, "|"-separated: covariate effects with their variable
   ("alcohol1 ego", "same smoke1"), interactions joined by " x ",
   endowment/creation marked, behavior effects with the behavior's name. */
string scalar _SaomRSLabel1(string scalar term, string scalar coef, real scalar symmetric, real scalar decay) {
	string scalar v
	real scalar u
	u = strpos(coef, "_")
	v = (u ? substr(coef, u + 1, .) : "")
	if (term == "outdegree") return(symmetric ? "degree (density)" : "outdegree (density)")
	if (term == "outdegreeendow") return("outdegree (density) [endowment]")
	if (term == "outdegreecreation") return("outdegree (density) [creation]")
	if (term == "reciprocity") return("reciprocity")
	if (term == "reciprocityendow") return("reciprocity [endowment]")
	if (term == "reciprocitycreation") return("reciprocity [creation]")
	if (term == "nodematch") return("same " + v)
	if (term == "nodeicov") return(v + " alter")
	if (term == "nodeocov") return(v + " ego")
	if (term == "nodecov") return(v + " ego and alt")
	if (term == "simcov") return(v + " similarity")
	if (term == "transtrip") return("transitive triplets")
	if (term == "transmedtrip") return("transitive mediated triplets")
	if (term == "transrectrip") return("transitive recipr. triplets")
	if (term == "cycle3") return("3-cycles")
	if (term == "cycle4") return("4 cycles (1)")
	if (term == "transties") return("transitive ties")
	if (term == "balance") return("balance")
	if (term == "gwesp") return("GWESP I -> K -> J (" + strofreal(round(100 * decay)) + ")")
	if (term == "indegpopularity") return("indegree - popularity (sqrt)")
	if (term == "outpopularity") return("outdegree - popularity (sqrt)")
	if (term == "outactivity") return("outdegree - activity")
	if (term == "inactivity") return("indegree - activity (sqrt)")
	if (term == "isolatenet") return("network-isolate")
	if (term == "outiso") return("out-isolate")
	if (term == "antiiso") return("anti isolates")
	if (term == "antiiniso") return("anti in-isolates")
	if (term == "antiiniso2") return("anti in-near-isolates")
	if (term == "in3plus") return("indegree at least 3")
	if (term == "isolatepop") return("isolate - popularity")
	if (term == "outoutass") return("out-out degree^(1/1) assortativity")
	if (term == "outinass") return("out-in degree^(1/1) assortativity")
	if (term == "inoutass") return("in-out degree^(1/1) assortativity")
	if (term == "ininass") return("in-in degree^(1/1) assortativity")
	return(coef)
}

string scalar SaomRSienaLabels(class ErgmModel scalar M, real scalar symmetric, string scalar behname, | pointer(class SaomBehaviorModel scalar) scalar Mbp) {
	string rowvector lab, nms
	string scalar out, nm, base, l
	real scalar t, ci, k, idx, pass, isego
	class ErgmTermData scalar tdt

	lab = J(1, M.nterms, "")
	ci = 0
	for (t=1; t<=M.nterms; t++) {
		tdt = *M.td[t]
		if (M.names[t] == "behsim") lab[t] = behname + " similarity"
		else if (M.names[t] != "interact") lab[t] = _SaomRSLabel1(M.names[t], M.coefnames[ci + 1], symmetric, tdt.decay)
		ci = ci + M.npar[t]
	}
	// interactions: the components' labels joined by " x ", RSiena's ego
	// effects (interactionType "ego") first
	for (t=1; t<=M.nterms; t++) {
		if (M.names[t] != "interact") continue
		tdt = *M.td[t]
		nms = tokens(tdt.sptype, "|")
		l = ""
		for (pass=1; pass<=2; pass++) {
			for (k=1; k<=(cols(nms)+1)/2; k++) {
				isego = anyof(("nodeocov", "inactivity", "isolatenet", "antiiso", "antiiniso", "antiiniso2", "inplus3", "isolatepop"), nms[2*k-1])
				if ((pass == 1) != isego) continue
				idx = (rows(tdt.levels) >= (cols(nms)+1)/2 * 2 ? tdt.levels[(cols(nms)+1)/2 + k] : 0)
				l = l + (l != "" ? " x " : "") + (idx > 0 ? lab[idx] : nms[2*k-1])
			}
		}
		lab[t] = l
	}
	out = invtokens(lab, "|")
	if (args() >= 4) {
		for (t=1; t<=(*Mbp).nterms; t++) {
			nm = (*Mbp).names[t]
			base = subinstr(subinstr(nm, "_endow", ""), "_creation", "")
			if (base == "linear") l = behname + " linear shape"
			else if (base == "quadratic") l = behname + " quadratic shape"
			else if (base == "avalt") l = behname + " average alter"
			else if (base == "avsim") l = behname + " average similarity"
			else l = behname + " " + base
			if ((*Mbp).fntype[t] == 1) l = l + " [endowment]"
			if ((*Mbp).fntype[t] == 2) l = l + " [creation]"
			out = out + "|" + l
		}
	}
	return(out)
}

/* estat gof (nwsaom_estat.ado): one simulated period of the fitted model,
   in the plugin when it covers the model (2026-10-01; before, co-evolution
   gof always ran in Mata, and network gof ignored endowment/creation,
   structural(), ratecov() and present()). Model details persisted by
   nwsaom.ado: __nwsaom_last_fntype, __nwsaom_last_struct,
   __nwsaom_last_present. Returns 1 if the plugin ran it. */
transmorphic _SaomGofExt(string scalar nm, transmorphic dflt) {
	pointer scalar p
	p = findexternal(nm)
	if (p == NULL) return(dflt)
	return(*p)
}

real scalar SaomGofSimNet(class ErgmGraph scalar G, class ErgmModel scalar M,
	real rowvector theta, real scalar rate, real scalar symtype,
	real matrix rcattr, real rowvector rccoef) {

	struct SaomNativeConfig scalar cfg
	struct SaomCountedResult scalar r
	real rowvector fn
	real matrix st
	real colvector pr
	real scalar native, hasfn, hasst, haspr

	fn = _SaomGofExt("__nwsaom_last_fntype", J(1, 0, 0))
	st = _SaomGofExt("__nwsaom_last_struct", J(0, 0, 0))
	pr = _SaomGofExt("__nwsaom_last_present", J(0, 1, 0))
	if (cols(fn) != M.nterms) fn = J(1, M.nterms, 0)
	hasfn = any(fn :!= 0)
	hasst = (rows(st) > 0)
	haspr = (rows(pr) > 0)
	cfg = SaomNativeSetup(M)
	native = cfg.eligible & SaomNativeAvailable()
	if (native & (hasfn | hasst | cols(rccoef) > 1)) native = (SaomNativePluginVersion() >= 11)
	if (native) {
		if (hasfn) cfg.fntype = fn
		if (hasst) cfg.structpairs = SaomMaskToDyadList(st :== 1)
		if (rows(rcattr) > 0) r = SaomSimulateIntervalNative(G, M, cfg, theta, rate, 1, 0, J(0, 2, 0), (haspr ? pr : J(0, 1, 0)), symtype, rcattr, rccoef)
		else r = SaomSimulateIntervalNative(G, M, cfg, theta, rate, 1, 0, J(0, 2, 0), (haspr ? pr : J(0, 1, 0)), symtype)
		return(1)
	}
	if (symtype != 0) {
		errprintf("estat gof needs the native (C) simulator for a non-directed fit.\n")
		exit(498)
	}
	if (rows(rcattr) > 0) r = SaomSimIntCountedRateCov(G, M, theta, rate, rcattr, rccoef, (haspr ? pr : J(G.n, 1, 1)), fn)
	else r = SaomSimulateIntervalCounted(G, M, theta, rate, (haspr ? pr : J(G.n, 1, 1)), fn, (hasst ? st : J(0, 0, 0)))
	return(0)
}

real scalar SaomGofSimCoev(class ErgmGraph scalar G, class ErgmModel scalar M, real rowvector thetaNet,
	class SaomBehavior scalar Beh, class SaomBehaviorModel scalar Mbeh, real rowvector thetaBeh,
	real scalar rateNet, real scalar rateBeh) {

	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	struct SaomCoevScoredResult scalar r
	struct SaomCoevResult scalar rm
	real scalar native

	cfg = SaomNativeSetup(M)
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	native = cfg.eligible & cfgBeh.eligible & SaomNativeAvailable()
	if (native) native = (SaomNativePluginVersion() >= (any(cfgBeh.fntype :!= 0) ? 11 : 3))
	if (native) {
		r = SaomSimulateIntervalCoevNative(G, M, cfg, thetaNet, Beh, Mbeh, cfgBeh, thetaBeh, rateNet, rateBeh, 1)
		return(1)
	}
	rm = SaomSimulateIntervalCoev(G, M, thetaNet, Beh, Mbeh, thetaBeh, rateNet, rateBeh)
	return(0)
}

/* SaomNativePluginVersion(): the saom_sim plugin's protocol version
   (native/saom_sim.c's SAOM_NATIVE_VERSION), obtained from one trivial
   probe call (2 actors, rate 0, so no ministep runs). 0 when the plugin is
   missing or predates the version scalar. The co-evolution estimators need
   version >= 3 (per-variable ministep counts, network distance, behsim, lagged behavior statistics,
   centered avAlt); with an older binary they use the Mata simulator. The
   network-only estimator needs version >= 5 for the network distance of
   a network-only model and for its batch path; with an older binary it
   reads the simulated network back and counts the distance in Mata. */
real scalar SaomNativePluginVersion(){
	string scalar origframe
	real scalar v, __junk

	if (!SaomNativeAvailable()) return(0)
	origframe = st_framecurrent()
	stata("capture frame drop __saom_native_probe")
	stata("frame create __saom_native_probe")
	st_framecurrent("__saom_native_probe")
	st_addobs(2)
	__junk = st_addvar("double", ("v1", "v2"))
	stata("capture scalar drop __saom_native_version")
	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")
	// n directed nties rate seed nattr nterms [tc ai p1] theta want_score
	// nbehterms condmode target hasmiss nmiss haspresent symtype hasratecov
	stata("capture plugin call saomnativesim v1 v2, " + char(34) + "2 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0" + char(34))
	st_framecurrent(origframe)
	stata("capture frame drop __saom_native_probe")
	v = st_numscalar("__saom_native_version")
	if (rows(v) == 0) return(0)
	if (v == .) return(0)
	return(v)
}

/* ===================================================================
   Batch simulation (plugin protocol >= 4, 2026-10-01): the estimator
   hands the plugin every period's starting data ONCE
   (SaomBatchSetup()), then asks for K independent simulations at a time
   (SaomBatchRun()); the plugin runs them on worker threads. Replicate k,
   period pd draws from its own random stream seeded from (seed, k, pd),
   with `seed' drawn from Stata's RNG once per SaomBatchRun() call, so a
   given `set seed' gives the same result whatever the number of threads.

   SaomCores(): threads to use - the Mata external __nwsaom_cores (set
   by nwsaom.ado's cores() option), 0 or unset = all physical cores.
   =================================================================== */
real scalar SaomCores(){
	pointer(real scalar) scalar p
	p = findexternal("__nwsaom_cores")
	if (p == NULL) return(0)
	if (*p == .) return(0)
	return(*p)
}

void SaomBatchSetup(pointer(class ErgmGraph scalar) rowvector Gwaves, real scalar P,
	struct SaomNativeConfig scalar cfg, real rowvector behtermcodes,
	pointer(real colvector) rowvector Behwaves, real scalar behmin, real scalar behmax,
	real scalar simMean, real scalar overallMean, real scalar hasmiss, real matrix missDyadsPd,
	real matrix missBehPd, real scalar haspresent, real matrix presentPd,
	| real rowvector behfntype, real scalar symtype, real matrix rcattr) {

	real matrix E, t
	real scalar k
	real scalar n, pd, nattr, nbeh, nrows, i, junk
	string rowvector names
	string scalar origframe, argstr

	n = (*Gwaves[1]).n
	E = J(0, 3, 0)
	for (pd=1; pd<=P; pd++) {
		t = (*Gwaves[pd]).all_ties()
		if (rows(t) > 0) E = E \ (J(rows(t), 1, pd), t)
	}
	nattr = cols(cfg.attrmat)
	nbeh = cols(behtermcodes)
	nrows = max((rows(E), n, rows(missDyadsPd), 1))

	names = ("e_pd", "e_i", "e_j")
	for (i=1; i<=nattr; i++) names = names, "a" + strofreal(i)
	if (nbeh > 0) for (pd=1; pd<=P; pd++) names = names, "b" + strofreal(pd)
	if (hasmiss) {
		names = names, ("m_pd", "m_i", "m_j")
		if (nbeh > 0) for (pd=1; pd<=P; pd++) names = names, "mb" + strofreal(pd)
	}
	if (haspresent) for (pd=1; pd<=P; pd++) names = names, "pr" + strofreal(pd)

	origframe = st_framecurrent()
	stata("capture frame drop __saom_batch")
	stata("frame create __saom_batch")
	st_framecurrent("__saom_batch")
	st_addobs(nrows)
	junk = st_addvar("double", names)
	if (rows(E) > 0) st_store((1::rows(E)), ("e_pd", "e_i", "e_j"), E)
	for (i=1; i<=nattr; i++) st_store((1::n), "a" + strofreal(i), cfg.attrmat[1::n, i])
	if (nbeh > 0) for (pd=1; pd<=P; pd++) st_store((1::n), "b" + strofreal(pd), *Behwaves[pd])
	if (hasmiss) {
		if (rows(missDyadsPd) > 0) st_store((1::rows(missDyadsPd)), ("m_pd", "m_i", "m_j"), missDyadsPd)
		if (nbeh > 0) for (pd=1; pd<=P; pd++) st_store((1::n), "mb" + strofreal(pd), missBehPd[., pd])
	}
	if (haspresent) for (pd=1; pd<=P; pd++) st_store((1::n), "pr" + strofreal(pd), presentPd[., pd])

	argstr = "BATCHSETUP|" + strofreal(n) + " " + strofreal(P) + " " + strofreal(nattr) + " " + strofreal(cols(cfg.termcodes))
	for (i=1; i<=cols(cfg.termcodes); i++) argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i], "%25.17g")
	argstr = argstr + " " + strofreal(nbeh)
	for (i=1; i<=nbeh; i++) argstr = argstr + " " + strofreal(behtermcodes[i])
	argstr = argstr + " " + strofreal(behmin, "%25.17g") + " " + strofreal(behmax, "%25.17g") + " " + strofreal(simMean, "%25.17g") + " " + strofreal(overallMean, "%25.17g")
	argstr = argstr + " " + strofreal(hasmiss) + " " + strofreal(haspresent) + " " + strofreal(rows(E)) + " " + strofreal(rows(missDyadsPd))
	// protocol 11 trailer: model trailer, symtype, ratecov() covariates
	argstr = argstr + SaomTrailer11(cfg, cols(cfg.termcodes), (args() >= 15 ? behfntype : J(1, nbeh, 0)))
	argstr = argstr + " " + strofreal(args() >= 16 ? symtype : 0)
	if (args() >= 17 & rows(rcattr) > 0) {
		argstr = argstr + " " + strofreal(cols(rcattr))
		for (k=1; k<=cols(rcattr); k++) for (i=1; i<=n; i++) argstr = argstr + " " + strofreal(rcattr[i,k], "%25.17g")
	}
	else argstr = argstr + " 0"

	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")
	stata("plugin call saomnativesim " + invtokens(names) + ", " + char(34) + argstr + char(34))
	st_framecurrent(origframe)
	stata("capture frame drop __saom_batch")
}

/* K replicates at the given parameters. condmode=0: K x (2*(pNet+pBeh)
   + 6*P) - summed statistics (network, then lagged behavior), summed
   scores, then per period (netdist, behdist, stepsNet, stepsBeh,
   nchanges, nchangesBeh). condmode=1: K x P conditional times (rates
   must be 1 and `targets' the per-period target distances). condmode=2:
   conditional simulation (rates 1, `targets' the distances) with the
   condmode-0 output plus a 7th per-period column, the time. */
real matrix SaomBatchRun(real scalar P, real scalar pNet, real scalar pBeh,
	real rowvector thetaNet, real rowvector thetaBeh, real rowvector ratesNet,
	real rowvector ratesBeh, real rowvector targets, real scalar K,
	real scalar want_score, real scalar condmode, | real rowvector ratecoef) {

	real scalar W, i, seed, junk, nrc
	string rowvector names
	string scalar origframe, argstr
	real matrix out

	// protocol 11: with ratecov(), per covariate the summed statistic and
	// score in 2 more columns
	nrc = (args() >= 12 ? cols(ratecoef) : 0)
	W = (condmode == 1) ? P : 2*(pNet + pBeh) + (condmode == 2 ? 7 : 6)*P + 2*nrc
	names = J(1, W, "")
	for (i=1; i<=W; i++) names[i] = "o" + strofreal(i)
	origframe = st_framecurrent()
	// phase 2 calls this once per Robbins-Monro step: only touch the
	// frame when it is missing or too small
	if (!st_frameexists("__saom_batch_out")) stata("frame create __saom_batch_out")
	st_framecurrent("__saom_batch_out")
	if (st_nvar() < W) for (i=st_nvar()+1; i<=W; i++) junk = st_addvar("double", names[i])
	if (st_nobs() < K) st_addobs(K - st_nobs())

	seed = floor(runiform(1,1) * 2147483647)
	argstr = "BATCHRUN|" + strofreal(K) + " " + strofreal(seed, "%12.0f") + " " + strofreal(SaomCores()) + " " + strofreal(want_score) + " " + strofreal(condmode)
	for (i=1; i<=pNet; i++) argstr = argstr + " " + strofreal(thetaNet[i], "%25.17g")
	for (i=1; i<=pBeh; i++) argstr = argstr + " " + strofreal(thetaBeh[i], "%25.17g")
	for (i=1; i<=P; i++) argstr = argstr + " " + strofreal(ratesNet[i], "%25.17g")
	for (i=1; i<=P; i++) argstr = argstr + " " + strofreal((cols(ratesBeh) ? ratesBeh[i] : 0), "%25.17g")
	for (i=1; i<=P; i++) argstr = argstr + " " + strofreal((cols(targets) ? targets[i] : 0), "%25.17g")
	for (i=1; i<=nrc; i++) argstr = argstr + " " + strofreal(ratecoef[i], "%25.17g")

	stata("plugin call saomnativesim " + invtokens(names) + ", " + char(34) + argstr + char(34))
	out = st_data((1::K), names)
	st_framecurrent(origframe)
	return(out)
}

void SaomBatchCleanup(){
	stata("capture plugin call saomnativesim, " + char(34) + "BATCHCLEAN|" + char(34))
	stata("capture frame drop __saom_batch_out")
}

/* Drops the persistent __saom_native frame (harmonisation unit 12 -
   see SaomSimulateIntervalNative()'s own header comment for why it is
   no longer dropped/recreated on every call). SaomEstimateRM() calls
   this exactly once, after its own last native call, so nothing lingers
   in the user's Stata session once a fit finishes. Safe to call even
   when the frame was never created (use_native was false the whole run,
   or the native path was never actually reached) - `capture` swallows
   the "frame does not exist" case exactly as the old per-call drop
   already did. */
void SaomNativeCleanupFrame() {
	stata("capture frame drop __saom_native")
}

end
