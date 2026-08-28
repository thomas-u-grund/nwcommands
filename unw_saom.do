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
real scalar SaomMinistep(class ErgmGraph scalar G, class ErgmModel scalar M,
	real rowvector theta, real scalar i, | real colvector present) {

	real scalar n, j, k, maxu, denom, draw, cum, choice, haspresent
	real rowvector u
	real rowvector chg

	n = G.n
	haspresent = (args() == 5)
	u = J(1, n, 0)		// u[j] for j!=i; u[i] itself unused (self-toggle undefined)
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
		chg = M.full_change(G, i, j)
		u[j] = theta * chg'
	}

	// numerically stable softmax over {u[1..n excl. i, excl. absent], 0 for "stay"}
	maxu = 0	// "stay"'s own utility, always included as a candidate max
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
		if (u[j] > maxu) maxu = u[j]
	}

	denom = exp(0 - maxu)	// "stay"'s own exp term
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (haspresent) if (present[j] == 0) continue
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
   SaomSimulateConditionalTime: harmonisation unit 27 (rate parameter
   refinement). Real RSiena's own DEFAULT estimation method for a
   SINGLE dependent variable (a plain network-only SAOM - not
   co-evolution, see below) is CONDITIONAL, not unconditional -
   verified directly from source, not assumed:
   `R/initializeFRAN.r`'s own `x$cconditional <- !x$maxlike &&
   (length(depvarnames) == 1)` (Method-of-Moments AND exactly one
   dependent variable -> conditional by default), confirmed live via
   `trace()` on the installed RSiena package itself (not just reading
   source): `phase2.1' genuinely never sees a rate row in its own
   `z$theta'/`z$pp' for a real 2-effect (density+reciprocity) fit on
   RSiena's own s50 data (`z$pp=2', `z$posj=(FALSE,FALSE)') - directly
   reproducing and confirming an EARLIER live trace this same
   conclusion was already independently drawn from (unit 8's own
   record above) - the rate row is REMOVED from the joint
   theta/Jacobian vector entirely (`R/initializeFRAN.r`'s own
   `z$theta <- z$theta[-z$condvar]'), not merely fixed or left at its
   starting value.

   Under conditional estimation, real RSiena does not run each
   simulated ministep interval for a FIXED unit time [0,1) the way
   `SaomSimulateInterval()' above does - it runs UNTIL the CURRENT
   simulated network's own DISTANCE FROM THE STARTING NETWORK reaches a
   fixed target (the observed Hamming distance between waves), at a
   REFERENCE per-actor rate (verified = 1: `R/terminateFRAN.r`'s own
   `z$rate <- colMeans(z$ntim)' applies NO further scaling to the
   elapsed time `ntim' recorded during this conditional run - see the
   algebraic derivation below for why that pins the reference rate at
   exactly 1). Confirmed directly from the real C++ source, not
   assumed: `EpochSimulation::runEpoch()`'s own stopping check is
   `this->lpConditioningVariable->simulatedDistance() >=
   this->ltargetChange', where `targetChange' is set, via
   `siena07setup.cpp`'s own `setupModelOptions()`, from
   `initializeFRAN.r`'s own `attr(f, "change") <-
   sapply(f, function(xx) as.integer(attr(xx$depvars[[z$condname]],
   "distance")))' - and that `"distance"' attribute is computed in
   `sienaDataCreate.r` as `sum(mydiff != 0)' where `mydiff = wave2 -
   wave1' - the exact same raw Hamming-distance definition
   `SaomCountDiffering()' (below) already computes, confirming the
   TARGET count itself matches exactly.

   **A real, disclosed numerical finding, kept in the record**: an
   initial implementation of this function tracked a naive MONOTONIC
   counter of accepted toggles (matching `SaomCountDiffering()`'s own
   "accepted changes" moment used elsewhere in this file) and stopping
   once that counter reached the target - this reproduced RSiena's own
   real s50 rate value only very roughly (own test: ~2.5 vs RSiena's
   own real ~5.5, off by more than 2x, confirmed to scale PERFECTLY
   LINEARLY with the target count when re-tested at 1x/1.5x/2x that
   target - ruling out an off-by-a-constant-factor bug and pointing
   instead at the STOPPING CONDITION itself being wrong). Root-caused
   directly against `EpochSimulation.cpp`'s own real source (not
   guessed): `simulatedDistance()` is NOT a monotonic accepted-change
   counter - it is the CURRENT network's own live Hamming distance from
   the STARTING network, which DECREASES whenever an accepted toggle
   happens to revert a dyad back to its own starting value (not merely
   "no progress" - active regression), a real, easy-to-miss subtlety a
   naive counter cannot represent. Fixed by tracking this SIGNED
   distance explicitly (`simDist' below, incremented when a toggled
   dyad newly DIFFERS from `Gstart', decremented when it newly MATCHES
   `Gstart' again) - re-tested directly against the real RSiena s50
   reference after the fix (see docs/SAOM_ROADMAP.md's own unit-27
   entry for the exact before/after numbers).

   Algebraic derivation of the reference rate (still valid under the
   corrected, signed-distance stopping rule, since it depends only on
   linearity in the target count, confirmed empirically above): for a
   homogeneous rate-c Poisson ministep process, the expected elapsed
   time to reach a fixed target K (by whichever stopping RULE actually
   defines "reaching K") is `K/(n*c*effectiveRate(theta))' for some
   theta-dependent constant `effectiveRate' capturing how fast
   simulatedDistance grows per unit time; the TRUE per-[0,1]-period
   rate R satisfies the SAME relationship over one real period, giving
   `R = c * E[elapsed time]' - collapsing to `R = E[elapsed time]'
   exactly when c=1, matching `z$rate <- colMeans(z$ntim)`'s own lack
   of a multiplier. The AVERAGE elapsed time across many independent
   conditional runs, at the FINAL fitted theta, is therefore itself a
   genuine, real-RSiena-verified estimator of the refined rate - not a
   heuristic.

   `SaomEstimateRM()'/`SaomEstimateRMMulti()' below use this AFTER
   phase 3 (once theta is finalized) purely to REFINE the reported
   rate value - phases 1/2/3's own THETA estimation stay fully
   UNCONDITIONAL, unchanged from the already-certified/cross-validated
   construction (unit 7's own s50 cross-check already found
   unconditional eval-parameter estimates within ~1-2% of RSiena's own
   real, conditionally-estimated ones - switching phases 1-3 to full
   conditional simulation would be a substantially larger, higher-risk
   redesign for a fidelity gain this package's own existing evidence
   suggests is small; see docs/SAOM_ROADMAP.md's own unit-27 entry for
   the full disclosed scope decision). Reuses `SaomMinistep()'
   unmodified (the same certified unit-1 sampler every other plain
   simulator here already reuses), just replacing the STOPPING
   CONDITION (`t<1' -> `nchanges<targetChanges').

   Co-evolution's own rate parameters are DELIBERATELY NOT refined
   this way: real RSiena's own `x$cconditional' default requires
   EXACTLY ONE dependent variable (`length(depvarnames)==1') - a
   co-evolution model has TWO (network + behavior), so real RSiena
   itself falls back to UNCONDITIONAL estimation there by default,
   the SAME closed-form-starting-value convention `SaomEstimateRMCoev()'/
   `SaomEstimateRMCoevMulti()' already use - refining THEIR rates this
   way would NOT be matching real RSiena's own default behavior, it
   would be inventing a different one.
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
   simulator used ONLY by SaomEstimateRM's own phase 1 (Jacobian
   estimation) - see that function's own header comment and
   docs/SAOM_ARCHITECTURE.md's "Robbins-Monro estimation" section for
   why. Deliberately not a modification of SaomMinistep/
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
   interval's own expected final statistic - exactly the Jacobian
   SaomEstimateRM's phase 1 needs (Cov(deviation, score) across many
   independent replicates, matching RSiena's own construction exactly).
   =================================================================== */
struct SaomScoredResult {
	real scalar steps
	real scalar nchanges		// ACCEPTED ministeps only (excludes "stay") - the rate parameter's own moment statistic, see SaomEstimateRM's own header comment (harmonisation unit 8)
	real rowvector score
}

struct SaomScoredResult scalar SaomSimulateIntervalScored(class ErgmGraph scalar G,
	class ErgmModel scalar M, real rowvector theta, real scalar rate, | real colvector present) {

	struct SaomScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg
	real scalar t, n, p, i, j, k, maxu, denom, draw, cum, choice, haspresent, npresent
	real colvector presentIdx

	n = G.n
	p = M.nparam()
	res.score = J(1, p, 0)
	res.steps = 0
	res.nchanges = 0

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as SaomMinistep()/
	// SaomSimulateInterval()'s own identical parameter; see
	// SaomSimulateInterval()'s own header comment for the full account.
	haspresent = (args() == 5)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = n

	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / (npresent * rate)
		if (t < 1) {
			if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
			else i = ceil(runiform(1,1) * n)

			chgmat = J(n, p, 0)
			u = J(1, n, 0)
			maxu = 0
			for (j=1; j<=n; j++) {
				if (j == i) continue
				if (haspresent) if (present[j] == 0) continue
				chgmat[j,.] = M.full_change(G, i, j)
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
			}
			res.steps = res.steps + 1
		}
	}
	return(res)
}

/* ===================================================================
   SaomCountedResult / SaomSimulateIntervalCounted: like
   SaomSimulateInterval() (same ministep loop, via SaomMinistep() -
   unmodified, still the certified unit-1 sampler) but ALSO tracks
   `nchanges` (accepted ministeps only) alongside `steps` (all
   opportunities) - used by SaomEstimateRM's phases 2-3, which need both
   for the joint rate/theta update (harmonisation unit 8). Kept separate
   from SaomSimulateInterval() itself (not a signature change) since
   that function's plain "returns steps" contract is relied on elsewhere
   (units 1-5 tests, direct callers) and changing it would be a needless
   breaking change for callers that only ever wanted the step count.
   =================================================================== */
struct SaomCountedResult {
	real scalar steps
	real scalar nchanges
	real rowvector stat		// harmonisation unit 14 - ONLY populated by SaomSimulateIntervalNative(); SaomSimulateIntervalCounted() (the Mata path) leaves it empty, since callers on that path already call M.full_statistic() themselves as before
	real rowvector score		// harmonisation unit 16 - ONLY populated by SaomSimulateIntervalNative() when called with want_score=1 (phase 1's own native path); empty otherwise
}

struct SaomCountedResult scalar SaomSimulateIntervalCounted(class ErgmGraph scalar G,
	class ErgmModel scalar M, real rowvector theta, real scalar rate, | real colvector present) {

	struct SaomCountedResult scalar res
	real scalar t, i, picked, haspresent, npresent
	real colvector presentIdx

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as SaomSimulateInterval()'s own
	// identical parameter; see its own header comment for the full
	// account.
	haspresent = (args() == 5)
	if (haspresent) {
		presentIdx = selectindex(present)
		npresent = length(presentIdx)
	}
	else npresent = G.n

	res.steps = 0
	res.nchanges = 0
	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / (npresent * rate)
		if (t < 1) {
			if (haspresent) i = presentIdx[ceil(runiform(1,1) * npresent)]
			else i = ceil(runiform(1,1) * G.n)
			if (haspresent) picked = SaomMinistep(G, M, theta, i, present)
			else picked = SaomMinistep(G, M, theta, i)
			if (picked != 0) res.nchanges = res.nchanges + 1
			res.steps = res.steps + 1
		}
	}
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
   interval, via SaomEstimateRM's calls to M.full_statistic(). Contrast
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
		tot = tot + 1 - abs(td.attr[ties[k,1]] - td.attr[ties[k,2]]) / td.decay
	}
	return(tot)
}
real rowvector change_saom_simcov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta

	delta = 1 - abs(td.attr[i] - td.attr[j]) / td.decay
	return(G.has_edge(i,j) ? -delta : delta)
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
		errprintf("SAOM estimation diverged during phase 2: a coefficient's own magnitude exceeded thetaBound (" + strofreal(thetaBound) + ") after a Robbins-Monro update step - matching real RSiena's own safeguard (R/phase2.r), which halts under the identical condition rather than let an update run away. This usually signals a genuine identification problem for this specific model/data combination (a real, diagnosed example - a co-evolution behavior effect's own joint parameter direction turning out to be an unidentified saturation ridge - is documented in docs/SAOM_ROADMAP.md's own harmonisation unit 28 entry), not a software defect. Try a narrower effect specification, a larger/different dataset, or different starting values (theta0()/theta0beh()).\n")
		exit(498)
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
   two same-node-set directed graphs - the observed target statistic
   for the RATE parameter's own moment condition (harmonisation unit 8,
   see SaomEstimateRM's own header comment). Equals the sum of
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
}

/* ===================================================================
   SaomFit: result of SaomEstimateRM.
   =================================================================== */
struct SaomFit {
	real rowvector theta		// final estimated coefficients (length M.nparam())
	real rowvector tratio		// phase-3 convergence t-ratio per eval parameter
	real scalar rate		// rate parameter - closed-form starting value UNLESS refined (harmonisation unit 27 - see below), ONLY populated by SaomEstimateRM() (exactly-two-wave path)
	real scalar rate_tratio		// phase-3 convergence t-ratio for the rate parameter's own moment - ONLY populated by SaomEstimateRM()
	real scalar rate_se		// harmonisation unit 27 - genuine standard error of the REFINED rate estimate (SaomSimulateConditionalTime()'s own K3-replicate mean, real RSiena's own conditional-estimation construction) - 0 whenever refinement was not run (should not happen for SaomEstimateRM's own network-only path, always run there)
	real matrix theta_path		// phase-2 subphase-end eval-theta history (nsub x nparam), for diagnostics
	real rowvector rates		// harmonisation unit 17 - ONE rate per inter-wave period, ONLY populated by SaomEstimateRMMulti() (2+ wave path); real RSiena's own convention confirmed by direct 3-wave cross-check (see docs/SAOM_ROADMAP.md) - theta is POOLED/shared across periods, rate is period-specific
	real rowvector rate_tratios	// harmonisation unit 17 - phase-3 convergence t-ratio per period's own rate moment, ONLY populated by SaomEstimateRMMulti()
	real rowvector rate_ses		// harmonisation unit 27 - one refined-rate standard error per period, ONLY populated by SaomEstimateRMMulti()
	real matrix V			// harmonisation unit 18 - p x p covariance matrix for theta (eval parameters only, matching real RSiena's own Method-of-Moments scope - rate excluded, see this unit's own header comment), populated by BOTH SaomEstimateRM() and SaomEstimateRMMulti()
}

/* ===================================================================
   SaomEstimateRM: Method of Moments / Robbins-Monro estimation.

   Harmonisation unit 7 (docs/SAOM_ROADMAP.md): REWRITTEN to faithfully
   match real RSiena's own algorithm (rsiena/R/phase1.r, phase2.r,
   phase3.r - read directly from the actual RSiena source, not assumed),
   after a direct RSiena cross-check (dev/saom_rsiena_crosscheck.R/.do)
   on RSiena's own s50 tutorial dataset found v1's original single-
   phase-2/diagonal-Jacobian design landing correct in sign and order of
   magnitude but ~10-20% low vs. real RSiena, even with a 3x larger
   iteration budget - pointing at a structural gap, not insufficient
   iterations. See docs/SAOM_ROADMAP.md's "External validation" entry
   for the full evidence trail and docs/SAOM_ARCHITECTURE.md for the
   element-by-element account of what changed and why. Real RSiena
   defaults reused directly (not re-derived): nsub=4 subphases,
   firstg=0.2, reduceg=0.5, truncation=5, diagonalize=0.2
   (sienaModelCreate.r) - the multi-subphase n2minimum/n2maximum
   schedule (n2min0=max(5,7+p), each subphase's own minimum =
   trunc(previous*2.52), maximum = minimum+200 - siena07.r) is
   reproduced exactly, not approximated.

   Gobs_start: the observed starting-wave network (read-only - copied
     internally before every simulation run, never mutated).
   Gobs_end: the observed ending-wave network - its M.full_statistic()
     value is the eval-parameter target; the count of dyads differing
     from Gobs_start is the RATE parameter's own target (see below).
   M: the model (term list) - shared between Gobs_start's and any
     simulated graph's evaluation, since terms are graph-agnostic
     functions.
   theta0: starting coefficient vector (length M.nparam()).
   rate0: starting rate value.
   K0: phase-1 replicate count (Jacobian estimation via the real
     score-function derivative estimator - see SaomSimulateIntervalScored()).
   K3: phase-3 replicate count (convergence diagnostics).
   firstg: phase-2 starting gain (RSiena default 0.2, sienaModelCreate.r).

   HARMONISATION UNIT 8 (docs/SAOM_ROADMAP.md): the rate parameter is
   now genuinely estimated from the data via RSiena's own verified
   CLOSED-FORM starting-value formula (previously it just echoed back
   whatever rate0 was fed in - a real bug, not merely imprecise).

   **Two prior attempts within this same unit were tried and rejected -
   kept in the record, not silently erased (docs/SAOM_ROADMAP.md has the
   full account):**
   (1) Joining rate into the SAME (p+1)-dimensional Jacobian/multi-
   subphase machinery as the eval parameters, modeled on the rate-score
   formula in RSiena's C++ source (src/model/variables/
   DependentVariable.cpp's calculateMaximumLikelihoodRateScores()).
   Directly instrumenting the real, installed RSiena package at runtime
   (R's own trace() on phase2.1()/phase1.1()/robmon(), not just reading
   source) proved this formula is for the MAXIMUM LIKELIHOOD method
   specifically (x$maxlike=TRUE) - for the Method of Moments default
   this file implements, z$pp EXCLUDES the rate row entirely (confirmed
   live: pp=2, posj=(FALSE,FALSE) at phase 1 entry for a 2-effect
   model). Made the fit WORSE (rate ~55% low, from ~9% low).
   (2) A decoupled, closed-form-derivative multiplicative update
   (rate_new = rate_old*(targetRate/nchanges_sim)^gain, targetRate =
   observed Hamming distance between waves) - statistically well-
   motivated (a Poisson-thinning Newton step) but converged to the SAME
   wrong fixed point (~55% low) REGARDLESS of starting value, proving
   the miscalibration was in the MOMENT CONDITION itself (raw Hamming
   distance as the accepted-change target), not the update mechanism.

   **What actually closed the gap**: found by grep'ing RSiena's own R
   source for "distance"/"Jaccard" near effect initialization
   (effects.r), not by further guessing - `networkRateEffects()`'s own
   caller computes a data-driven STARTING rate value via
   `startRate <- nactors * (0.2 + 2*distance) / (matcnt + 1)` (directed
   case; matcnt = valid dyad count, n*(n-1) with no missing data;
   distance = the SAME Hamming-distance quantity SaomCountDiffering()
   already computes). Verified by direct trial to reproduce RSiena's own
   real printed `getEffects()` initial value EXACTLY (4.696042, s50
   wave1-2, both computed independently and compared to 6 significant
   figures) - not a guess, a confirmed match to the real formula.
   RSiena's own FINAL fitted rate (5.4725) is somewhat higher than this
   starting value (~14%); shipping the verified closed form here is a
   strictly better, safer choice than either rejected iterative scheme
   above, both of which landed FURTHER from the true value than this
   simple formula does - `ratecur` (this variable) is used as-is
   throughout phases 1-3 as the FIXED simulation rate, exactly as
   before.

   **Status update, harmonisation unit 27**: the ~14% starting-value
   gap above is now CLOSED for `fit.rate` itself (the value actually
   reported/returned) - see `SaomSimulateConditionalTime()`'s own
   header comment further below for the real mechanism this closes it
   with (real RSiena's own CONDITIONAL-estimation construction,
   verified directly from source and confirmed live against the
   installed RSiena package). `ratecur` (this comment's own variable)
   remains the FIXED rate used to drive phases 1-3's own THETA
   estimation, unchanged - only the FINAL reported `fit.rate` (computed
   after phase 3, once theta is settled) is refined.
   =================================================================== */
struct SaomFit scalar SaomEstimateRM(class ErgmGraph scalar Gobs_start,
	class ErgmGraph scalar Gobs_end, class ErgmModel scalar M,
	real rowvector theta0, real scalar rate0,
	real scalar K0, real scalar K3, real scalar firstg, | real colvector present) {

	struct SaomFit scalar fit
	struct SaomNativeConfig scalar cfg
	struct SaomScoredResult scalar sres
	struct SaomCountedResult scalar cres
	class ErgmGraph scalar Gwork
	real rowvector target, theta, dev, prevdev, prod0, prod1, ac, stdcap
	real rowvector thav, fchange, changestep
	real matrix Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3
	real matrix Zsco3, Ddev3, Dsco3, Dhat3, Dinv3	// harmonisation unit 18
	real scalar p, k, use_native, targetRate, ratecur, nch, haspresent, npresent
	real scalar nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real rowvector n2minimum, n2maximum
	real matrix theta_hist
	real colvector rate_hist, condTimes

	p = M.nparam()
	target = M.full_statistic(Gobs_end)
	targetRate = SaomCountDiffering(Gobs_start, Gobs_end)

	// --- harmonisation unit 33 (composition change - "joiners and
	// leavers"): `present' (n x 1, 1/0 per actor) is OPTIONAL and
	// backward-compatible - omitting it entirely (every pre-existing
	// caller) is IDENTICAL to every actor being present. When supplied:
	// (a) `npresent' replaces Gobs_start.n in the rate formula below -
	// only present actors get activation opportunities, so they are
	// what the rate scales by (matching the same principle
	// SaomSimulateInterval()'s own `present' parameter already applies
	// to the SIMULATION side); (b) the native backend is force-disabled
	// (`use_native=0' unconditionally) - it has no composition-change
	// support yet, a disclosed, scoped-out follow-up (see
	// docs/SAOM_ROADMAP.md's own unit-33 entry) - every phase below
	// therefore always takes its own Mata-fallback branch when
	// composition change is active, matching this package's own
	// established "ship correct-and-slow first" precedent; (c) the
	// post-hoc conditional rate-refinement loop (units 27/30) is
	// SKIPPED entirely - real RSiena's own manual states composition
	// change forces unconditional estimation (Section 7.12.1), and the
	// conditional-simulation construction that loop relies on
	// (SaomSimulateConditionalTime()) has no presence-restriction
	// support either.
	haspresent = (args() == 9)
	if (haspresent) npresent = length(selectindex(present))
	else npresent = Gobs_start.n

	// --- Rate: RSiena's own verified closed-form starting-value formula
	// (effects.r's networkRateEffects() caller; see this function's own
	// header comment for the derivation and the two rejected iterative
	// alternatives) - directed, no-missing-data case. Computed once,
	// up front, and used as a FIXED rate throughout phases 1-3 (matching
	// how v1 originally treated rate0, just now data-derived and
	// verified instead of an arbitrary user-supplied constant). rate0 is
	// still accepted as a parameter (nwsaom.ado's own rate0() option)
	// but no longer used - kept in the signature to avoid an unrelated
	// wave of call-site churn; superseded entirely by this formula.
	ratecur = npresent * (0.2 + 2*targetRate) / (npresent*(npresent-1) + 1)

	// --- native (C) backend dispatch, decided ONCE per model, never
	// inside a loop - see docs/SAOM_ARCHITECTURE.md's "Native backend"
	// section. Force-disabled under composition change (see above).
	cfg = SaomNativeSetup(M)
	use_native = cfg.eligible & SaomNativeAvailable() & !haspresent

	// --- Phase 1: real Jacobian via the score-function derivative
	// estimator (RSiena's own derivativeFromScoresAndDeviations(),
	// rsiena/R/phase1.r) - Dhat[k,l] = Cov(deviation_k, score_l) across
	// K0 independent replicates, blended 80/20 with its own diagonal
	// (diagonalize=0.2, sienaModelCreate.r default) before inverting.
	// EVAL PARAMETERS ONLY (p-dimensional) - the rate parameter is
	// deliberately excluded from this machinery, see this function's
	// own header comment for why (a real, corrected mistake).
	Zdev = J(K0, p, 0)
	Zsco = J(K0, p, 0)
	for (k=1; k<=K0; k++) {
		if (use_native) {
			// harmonisation unit 16 (performance pass, see
			// docs/SAOM_ROADMAP.md's own "Native backend performance"
			// entry): SaomSimulateIntervalScored() was NEVER natively
			// ported (unit 6 onward only covered SaomMinistep()/
			// SaomSimulateInterval(), the phase-2/3 sampler) - a real,
			// substantial gap once phase 2/3 got fast, since this
			// function's own O(n) per-ministep M.full_change() Mata
			// calls, times K0 independent replicates, could dominate
			// total fit time once nothing else does. cres.stat/
			// cres.score are native/saom_sim.c's own direct port of
			// this same score-function derivative-estimator identity
			// (want_score=1) - no SaomCopyGraph()/rebuild needed, same
			// unit-15 rationale (Gobs_start is read-only here too).
			cres = SaomSimulateIntervalNative(Gobs_start, M, cfg, theta0, ratecur, 0, 1)
			Zdev[k,.] = cres.stat - target
			Zsco[k,.] = cres.score
		}
		else {
			Gwork = ErgmGraph()
			SaomCopyGraph(Gobs_start, Gwork)
			if (haspresent) sres = SaomSimulateIntervalScored(Gwork, M, theta0, ratecur, present)
			else sres = SaomSimulateIntervalScored(Gwork, M, theta0, ratecur)
			Zdev[k,.] = M.full_statistic(Gwork) - target
			Zsco[k,.] = sres.score
		}
	}
	Ddev = Zdev :- mean(Zdev)
	Dsco = Zsco :- mean(Zsco)
	Dhat = (Ddev' * Dsco) / K0				// Dhat[k,l] = Cov(dev_k, score_l)
	temp = 0.8 * Dhat + 0.2 * diag(diagonal(Dhat))		// diagonalize=0.2 blend
	Dinv = luinv(temp)	// temp (the blended Jacobian) is NOT generally symmetric - invsym() would silently assume symmetry and give a wrong result; luinv() is Mata's general (LU-based) square-matrix inverse, matching R's own generic solve(temp) exactly

	msf = variance(Zdev)					// phase-1 deviation covariance (p x p)
	sfinvcov = invsym(msf + 0.0001 * I(p))			// for Mahalanobis truncation
	stdcap = J(1, p, 1)
	for (k=1; k<=p; k++) {
		stdcap[k] = 1 / sqrt(max((Dinv[k,.] * msf * Dinv[k,.]', 0)))	// diag(Dinv*msf*Dinv')[k]
		if (stdcap[k] > 1) stdcap[k] = 1		// pmin(standardization,1)
	}

	// --- Phase 2: real multi-subphase Robbins-Monro (rsiena/R/phase2.r,
	// siena07.r's own n2minimum/n2maximum schedule) for the eval
	// parameters. Rate is fixed at `ratecur` throughout (see above).
	nsub = 4
	reduceg = 0.5
	gain = firstg
	n2min0 = max((5, 7 + p))
	n2minimum = J(1, nsub, 0)
	n2maximum = J(1, nsub, 0)
	n2minimum[1] = trunc(n2min0 * 2.52)
	n2maximum[1] = n2minimum[1] + 200
	for (k=2; k<=nsub; k++) {
		n2minimum[k] = trunc(n2minimum[k-1] * 2.52)
		n2maximum[k] = n2minimum[k] + 200
	}

	theta = theta0
	theta_hist = J(nsub, p, 0)

	for (subphase=1; subphase<=nsub; subphase++) {
		thav = theta
		thavn = 1
		prod0 = J(1, p, 0)
		prod1 = J(1, p, 0)
		prevdev = J(1, p, 0)
		nit = 0
		maxacor = 1

		while (1) {
			nit = nit + 1
			if (use_native) {
				// harmonisation unit 15: no SaomCopyGraph() needed - G is
				// never mutated when rebuild_g=0, so Gobs_start itself can
				// be passed directly (see SaomSimulateIntervalNative()'s
				// own header comment).
				cres = SaomSimulateIntervalNative(Gobs_start, M, cfg, theta, ratecur, 0, 0)
				dev = cres.stat - target		// harmonisation unit 14 - native's own full_statistic() port, see that function's own header comment
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gobs_start, Gwork)
				if (haspresent) cres = SaomSimulateIntervalCounted(Gwork, M, theta, ratecur, present)
				else cres = SaomSimulateIntervalCounted(Gwork, M, theta, ratecur)
				dev = M.full_statistic(Gwork) - target
			}

			// autocorrelation bookkeeping on the RAW (pre-truncation,
			// pre-double-averaging) deviation, odd/even-paired exactly
			// as phase2.r's own doIterations() does.
			if (mod(nit,2) == 1) prevdev = dev
			else {
				prod0 = prod0 + dev:^2
				prod1 = prod1 + dev:*prevdev
			}

			// Mahalanobis truncation (diagg=FALSE branch, truncation=5)
			maxRatio = sqrt((dev * sfinvcov * dev') / p)
			if (maxRatio > 5 & maxRatio > 0) dev = 5 * dev / maxRatio

			// double-averaging (doubleAveraging=0 default: always on
			// from subphase 1 onward) - fra fed into the update is the
			// CUMULATIVE sum of (truncated) deviations since this
			// subphase attempt began, not the single-iteration value.
			if (nit == 1) changestep = dev
			else changestep = changestep + dev
			// changestep here temporarily holds the running SUM (sumfra
			// in RSiena's own naming) - reused below for the actual
			// preconditioned step to avoid a second p-length temp.
			fchange = gain * ((changestep * Dinv') :* stdcap)

			theta = (thav / thavn) - fchange
			thav = thav + theta
			thavn = thavn + 1
			SaomCheckThetaBound(theta, 50)		// harmonisation unit 29 - see that function's own header comment

			if (nit >= 2) {
				ac = J(1, p, -1)
				for (k=1; k<=p; k++) {
					if (prod0[k] > 1e-12) ac[k] = prod1[k] / prod0[k]
				}
				maxacor = max(ac)
			}

			if (nit >= n2maximum[subphase]) break
			if (nit >= n2minimum[subphase] & maxacor < 1e-10) break
		}

		theta = thav / thavn
		theta_hist[subphase, .] = theta
		gain = gain * reduceg
	}

	fit.theta = theta
	fit.rate = ratecur
	fit.theta_path = theta_hist

	// --- Phase 3: convergence diagnostics (kept as v1's own original
	// design - RSiena's own phase 3 diagnostic machinery, sienaTimeTest/
	// Wald-style, is a separate, larger item; t-ratios here remain the
	// same "mean deviation / SE" construction). Also collects SCORES
	// now (harmonisation unit 18, "e(V) covariance matrix" per explicit
	// user direction) - needed for the phase-3-based Jacobian the
	// covariance formula below uses; native calls already support this
	// (want_score=1, unit 16's own wire protocol), so the Mata fallback
	// switches from SaomSimulateIntervalCounted() to
	// SaomSimulateIntervalScored() (phase 1's own scored simulator) to
	// match. ---
	Zphase3 = J(K3, p, 0)
	Zsco3 = J(K3, p, 0)
	rate_hist = J(K3, 1, 0)
	for (k=1; k<=K3; k++) {
		if (use_native) {
			// harmonisation unit 15 - see phase 2's own identical comment above
			cres = SaomSimulateIntervalNative(Gobs_start, M, cfg, fit.theta, fit.rate, 0, 1)
			Zphase3[k, .] = cres.stat - target		// harmonisation unit 14
			Zsco3[k, .] = cres.score			// harmonisation unit 18
			nch = cres.nchanges
		}
		else {
			Gwork = ErgmGraph()
			SaomCopyGraph(Gobs_start, Gwork)
			if (haspresent) sres = SaomSimulateIntervalScored(Gwork, M, fit.theta, fit.rate, present)
			else sres = SaomSimulateIntervalScored(Gwork, M, fit.theta, fit.rate)
			Zphase3[k, .] = M.full_statistic(Gwork) - target
			Zsco3[k, .] = sres.score
			nch = sres.nchanges
		}
		rate_hist[k] = nch - targetRate
	}

	fit.tratio = J(1, p, 0)
	for (k=1; k<=p; k++) {
		if (K3 > 1 & variance(Zphase3[.,k]) > 1e-10) {
			fit.tratio[k] = mean(Zphase3[.,k]) / sqrt(variance(Zphase3[.,k]) / K3)
		}
	}
	fit.rate_tratio = 0
	if (K3 > 1 & variance(rate_hist) > 1e-10) {
		fit.rate_tratio = mean(rate_hist) / sqrt(variance(rate_hist) / K3)
	}

	// --- harmonisation unit 18: covariance matrix for theta, RSiena's
	// own real formula - verified directly from RSiena's actual R
	// source (rsiena/R/phase3.r's CalculateDerivative3()/PotentialNR()/
	// phase3.2(), not assumed): a FRESH Jacobian estimated from PHASE
	// 3's own score/deviation data (same Cov(deviation,score)/K3
	// construction as phase 1's own Dhat above, but deliberately NO
	// diagonalize=0.2 blend - real RSiena's own `PotentialNR()` inverts
	// the RAW phase-3 derivative matrix `dfrac' directly for this step;
	// the diagonalize blend is specific to phase 2's own regularized RM
	// update, not reused here), then the standard M-estimator sandwich:
	// V = Dinv3 * Cov(Zphase3) * Dinv3' (real RSiena's own
	// `z$dinv %*% z$msfc %*% t(z$dinv)`, confirmed by reading the
	// installed package's own function bodies via R - z$msfc is
	// z$msf = cov(z$sf) with no further adjustment for an all-free-
	// parameters model, matching v1's own scope: no fixed parameters).
	Ddev3 = Zphase3 :- mean(Zphase3)
	Dsco3 = Zsco3 :- mean(Zsco3)
	Dhat3 = (Ddev3' * Dsco3) / K3
	Dinv3 = luinv(Dhat3)
	fit.V = Dinv3 * variance(Zphase3) * Dinv3'

	// --- harmonisation unit 27: rate refinement, real RSiena's own
	// CONDITIONAL-estimation construction (verified directly from
	// source - see SaomSimulateConditionalTime()'s own header comment
	// for the full account) - K3 independent conditional runs AT THE
	// FINAL FITTED theta, each simulated (at reference rate 1) until
	// `targetRate' accepted changes occur; the refined rate is the mean
	// elapsed time across those K3 runs, its own SE the usual mean's
	// own SE. Native-dispatched when available (harmonisation unit 30,
	// SaomSimulateCondTimeNative() - see its own header comment:
	// a direct RSiena benchmark found THIS loop alone accounted for
	// essentially the entire ~22x gap network-only fits had vs. real
	// RSiena, the one thing in this estimator that had never been
	// ported native before now), falling back to the pure-Mata
	// SaomSimulateConditionalTime() reference otherwise - same
	// `use_native' gate phases 1-3 above already use.
	// harmonisation unit 33: composition change forces UNCONDITIONAL
	// estimation (real RSiena's own manual, Section 7.12.1) - the
	// conditional-simulation construction this refinement loop relies
	// on (SaomSimulateConditionalTime()) has no presence-restriction
	// support, so it is skipped entirely here, leaving `fit.rate' at
	// its closed-form starting value (`ratecur', already set above)
	// unrefined - matching co-evolution's own identical fallback
	// (a different reason, same resulting convention: `fit.rate_se'
	// stays 0, signalling "not refined" exactly as co-evolution fits
	// already do for their own rate).
	if (!haspresent) {
		condTimes = J(K3, 1, 0)
		for (k=1; k<=K3; k++) {
			if (use_native) {
				condTimes[k] = SaomSimulateCondTimeNative(Gobs_start, Gobs_start, M, cfg, fit.theta, targetRate)
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gobs_start, Gwork)
				condTimes[k] = SaomSimulateConditionalTime(Gwork, Gobs_start, M, fit.theta, targetRate)
			}
		}
		if (use_native) SaomNativeCleanupFrame()
		fit.rate = mean(condTimes)
		// real RSiena's own reported rate "Standard Error" (terminateFRAN.r's
		// own `z$vrate <- apply(z$ntim, 2, sd)') is the RAW standard
		// deviation of the per-replicate elapsed-time draws, NOT a standard
		// error of the MEAN (not divided by sqrt(K3)) - confirmed by direct
		// comparison against a live RSiena trace's own printed report
		// (docs/SAOM_ROADMAP.md's own unit-27 entry has the exact numbers) -
		// matched here exactly, not the more conventional sqrt(var/K3).
		fit.rate_se = sqrt(variance(condTimes))
	}
	else fit.rate_se = 0

	// harmonisation unit 12: drop the persistent __saom_native frame
	// here, once, rather than SaomSimulateIntervalNative() dropping and
	// recreating it on every one of its own many calls throughout phases
	// 1-3 above (see that function's own header comment).
	if (use_native) SaomNativeCleanupFrame()

	return(fit)
}

/* ===================================================================
   SaomEstimateRMMulti: Method of Moments / Robbins-Monro estimation
   across 2+ waves (harmonisation unit 17, "sketch out roadmap ... 3+
   wave chaining" per explicit user direction).

   Generalizes SaomEstimateRM() (kept completely UNTOUCHED above - zero
   regression risk to the already-certified/heavily-optimized exactly-
   two-wave path) to `nwaves' >= 2 observed waves, i.e. `nperiods' =
   nwaves-1 inter-wave periods. VERIFIED against real RSiena before
   writing any estimation code (not assumed): a real 3-wave RSiena fit
   on RSiena's own s501/s502/s503 tutorial data (`Rscript`, RSiena
   1.6.6, `recip` effect) came back with:

       Rate parameter period 1   5.7901  (0.9459)
       Rate parameter period 2   4.4809  (0.6780)
       eval outdegree (density) -2.3709  (0.1029)
       eval reciprocity          2.8408  (0.1765)

   - i.e. real RSiena's own multi-period model POOLS the eval
   parameters (theta) across every period into ONE joint estimate, while
   the RATE parameter is period-specific (one value per period) -
   exactly Snijders' own published Method-of-Moments formulation (the
   pooled moment condition equates the SUM across periods of simulated
   sufficient statistics to the SUM across periods of observed ones).
   This function implements exactly that: each phase-1/2/3 iteration
   simulates EVERY period from its own observed starting wave (using
   that period's own rate), and SUMS the resulting deviations/scores
   across periods before the shared Jacobian/Robbins-Monro update -
   otherwise byte-for-byte the SAME algorithm as SaomEstimateRM() above
   (same nsub=4/firstg/reduceg/diagonalize=0.2/truncation=5 real-RSiena
   defaults, same double-averaging/autocorrelation-based early stopping),
   just looped over periods wherever SaomEstimateRM() touches a single
   Gobs_start/Gobs_end pair. See docs/SAOM_ROADMAP.md's own "3+ wave
   chaining" entry for the real-data cross-check this was certified
   against.

   Gwaves: pointer array of `nwaves' ErgmGraph instances, in temporal
     order (Gwaves[1] = first observed wave, ..., Gwaves[nwaves] = last).
     Each is read-only throughout (same "never mutated" contract as
     Gobs_start above) - the standard Mata idiom for a collection of
     class instances in this codebase (matches ErgmModel.td's own
     `pointer rowvector` design, unw_ergm.do).
   =================================================================== */
struct SaomFit scalar SaomEstimateRMMulti(pointer(class ErgmGraph scalar) rowvector Gwaves,
	class ErgmModel scalar M, real rowvector theta0, real scalar K0, real scalar K3,
	real scalar firstg, | real matrix presentMat) {

	struct SaomFit scalar fit
	struct SaomNativeConfig scalar cfg
	struct SaomScoredResult scalar sres
	struct SaomCountedResult scalar cres
	class ErgmGraph scalar Gwork, Gp, Gpend
	real matrix target, Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3, rate_hist
	real matrix Zsco3, Ddev3, Dsco3, Dhat3, Dinv3	// harmonisation unit 18
	real rowvector theta, dev, devp, prevdev, prod0, prod1, ac, stdcap
	real rowvector thav, fchange, changestep, ratecur, targetRate
	real scalar p, k, pd, nwaves, nperiods, use_native, nch, haspresent
	real scalar nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real rowvector n2minimum, n2maximum, npresentPd
	real matrix theta_hist, presentPd
	real colvector condTimes

	nwaves = cols(Gwaves)
	nperiods = nwaves - 1
	p = M.nparam()

	// harmonisation unit 33 (composition change): `presentMat' is n x
	// nwaves (one column per WAVE, matching behavior()'s own "one
	// variable per wave" convention), OPTIONAL and backward-compatible
	// (same convention as SaomEstimateRM()'s own identical parameter -
	// see its own header comment for the full account). Actor i is
	// present during period pd (between wave pd and wave pd+1) iff
	// present at BOTH endpoint waves (this package's own whole-period-
	// only scope decision, docs/SAOM_ROADMAP.md's unit-33 entry) -
	// `presentPd' (n x nperiods) derives this ONCE, up front, via
	// elementwise multiplication (equivalent to AND for 0/1 indicators).
	haspresent = (args() == 7)
	if (haspresent) {
		presentPd = J(rows(presentMat), nperiods, 0)
		for (pd=1; pd<=nperiods; pd++) presentPd[.,pd] = presentMat[.,pd] :* presentMat[.,pd+1]
		npresentPd = J(1, nperiods, 0)
		for (pd=1; pd<=nperiods; pd++) npresentPd[pd] = length(selectindex(presentPd[.,pd]))
	}

	target = J(nperiods, p, 0)
	targetRate = J(1, nperiods, 0)
	ratecur = J(1, nperiods, 0)
	for (pd=1; pd<=nperiods; pd++) {
		Gp = *Gwaves[pd]
		Gpend = *Gwaves[pd+1]
		target[pd,.] = M.full_statistic(Gpend)
		targetRate[pd] = SaomCountDiffering(Gp, Gpend)
		// same closed-form starting-rate formula as SaomEstimateRM()'s
		// own header comment derives - applied per period, using that
		// period's own start-wave n (fixed actor set across waves per
		// v1 scope, so identical n every period, but computed faithfully
		// per period rather than assumed) - or, under composition
		// change, that period's own PRESENT actor count instead (same
		// principle as SaomEstimateRM()'s own identical adjustment).
		if (haspresent) ratecur[pd] = npresentPd[pd] * (0.2 + 2*targetRate[pd]) / (npresentPd[pd]*(npresentPd[pd]-1) + 1)
		else ratecur[pd] = Gp.n * (0.2 + 2*targetRate[pd]) / (Gp.n*(Gp.n-1) + 1)
	}

	cfg = SaomNativeSetup(M)
	use_native = cfg.eligible & SaomNativeAvailable() & !haspresent

	// --- Phase 1: pooled Jacobian - SUM the per-period deviation/score
	// across periods before building Dhat, otherwise identical to
	// SaomEstimateRM()'s own phase 1.
	Zdev = J(K0, p, 0)
	Zsco = J(K0, p, 0)
	for (k=1; k<=K0; k++) {
		dev = J(1, p, 0)
		devp = J(1, p, 0)		// score accumulator (reusing devp to avoid a second p-length temp)
		for (pd=1; pd<=nperiods; pd++) {
			Gp = *Gwaves[pd]
			if (use_native) {
				cres = SaomSimulateIntervalNative(Gp, M, cfg, theta0, ratecur[pd], 0, 1)
				dev = dev + (cres.stat - target[pd,.])
				devp = devp + cres.score
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gp, Gwork)
				if (haspresent) sres = SaomSimulateIntervalScored(Gwork, M, theta0, ratecur[pd], presentPd[.,pd])
				else sres = SaomSimulateIntervalScored(Gwork, M, theta0, ratecur[pd])
				dev = dev + (M.full_statistic(Gwork) - target[pd,.])
				devp = devp + sres.score
			}
		}
		Zdev[k,.] = dev
		Zsco[k,.] = devp
	}
	Ddev = Zdev :- mean(Zdev)
	Dsco = Zsco :- mean(Zsco)
	Dhat = (Ddev' * Dsco) / K0
	temp = 0.8 * Dhat + 0.2 * diag(diagonal(Dhat))
	Dinv = luinv(temp)

	msf = variance(Zdev)
	sfinvcov = invsym(msf + 0.0001 * I(p))
	stdcap = J(1, p, 1)
	for (k=1; k<=p; k++) {
		stdcap[k] = 1 / sqrt(max((Dinv[k,.] * msf * Dinv[k,.]', 0)))
		if (stdcap[k] > 1) stdcap[k] = 1
	}

	// --- Phase 2: pooled multi-subphase Robbins-Monro - identical
	// schedule/truncation/double-averaging/autocorrelation logic to
	// SaomEstimateRM()'s own phase 2, just summing `dev' across periods
	// each iteration before the Mahalanobis truncation/update.
	nsub = 4
	reduceg = 0.5
	gain = firstg
	n2min0 = max((5, 7 + p))
	n2minimum = J(1, nsub, 0)
	n2maximum = J(1, nsub, 0)
	n2minimum[1] = trunc(n2min0 * 2.52)
	n2maximum[1] = n2minimum[1] + 200
	for (k=2; k<=nsub; k++) {
		n2minimum[k] = trunc(n2minimum[k-1] * 2.52)
		n2maximum[k] = n2minimum[k] + 200
	}

	theta = theta0
	theta_hist = J(nsub, p, 0)

	for (subphase=1; subphase<=nsub; subphase++) {
		thav = theta
		thavn = 1
		prod0 = J(1, p, 0)
		prod1 = J(1, p, 0)
		prevdev = J(1, p, 0)
		nit = 0
		maxacor = 1

		while (1) {
			nit = nit + 1
			dev = J(1, p, 0)
			for (pd=1; pd<=nperiods; pd++) {
				Gp = *Gwaves[pd]
				if (use_native) {
					cres = SaomSimulateIntervalNative(Gp, M, cfg, theta, ratecur[pd], 0, 0)
					dev = dev + (cres.stat - target[pd,.])
				}
				else {
					Gwork = ErgmGraph()
					SaomCopyGraph(Gp, Gwork)
					if (haspresent) cres = SaomSimulateIntervalCounted(Gwork, M, theta, ratecur[pd], presentPd[.,pd])
					else cres = SaomSimulateIntervalCounted(Gwork, M, theta, ratecur[pd])
					dev = dev + (M.full_statistic(Gwork) - target[pd,.])
				}
			}

			if (mod(nit,2) == 1) prevdev = dev
			else {
				prod0 = prod0 + dev:^2
				prod1 = prod1 + dev:*prevdev
			}

			maxRatio = sqrt((dev * sfinvcov * dev') / p)
			if (maxRatio > 5 & maxRatio > 0) dev = 5 * dev / maxRatio

			if (nit == 1) changestep = dev
			else changestep = changestep + dev
			fchange = gain * ((changestep * Dinv') :* stdcap)

			theta = (thav / thavn) - fchange
			thav = thav + theta
			thavn = thavn + 1
			SaomCheckThetaBound(theta, 50)		// harmonisation unit 29 - see that function's own header comment

			if (nit >= 2) {
				ac = J(1, p, -1)
				for (k=1; k<=p; k++) {
					if (prod0[k] > 1e-12) ac[k] = prod1[k] / prod0[k]
				}
				maxacor = max(ac)
			}

			if (nit >= n2maximum[subphase]) break
			if (nit >= n2minimum[subphase] & maxacor < 1e-10) break
		}

		theta = thav / thavn
		theta_hist[subphase, .] = theta
		gain = gain * reduceg
	}

	fit.theta = theta
	fit.rates = ratecur
	fit.theta_path = theta_hist

	// --- Phase 3: pooled convergence diagnostics for theta, PLUS
	// per-period rate diagnostics (rate_hist is now a K3 x nperiods
	// matrix, one column per period's own accepted-change moment,
	// matching SaomEstimateRM()'s own single-column construction
	// generalized across periods).
	Zphase3 = J(K3, p, 0)
	Zsco3 = J(K3, p, 0)		// harmonisation unit 18 - pooled score (summed across periods, same convention as `dev' below)
	rate_hist = J(K3, nperiods, 0)
	for (k=1; k<=K3; k++) {
		dev = J(1, p, 0)
		devp = J(1, p, 0)
		for (pd=1; pd<=nperiods; pd++) {
			Gp = *Gwaves[pd]
			if (use_native) {
				cres = SaomSimulateIntervalNative(Gp, M, cfg, fit.theta, fit.rates[pd], 0, 1)
				dev = dev + (cres.stat - target[pd,.])
				devp = devp + cres.score
				nch = cres.nchanges
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gp, Gwork)
				if (haspresent) sres = SaomSimulateIntervalScored(Gwork, M, fit.theta, fit.rates[pd], presentPd[.,pd])
				else sres = SaomSimulateIntervalScored(Gwork, M, fit.theta, fit.rates[pd])
				dev = dev + (M.full_statistic(Gwork) - target[pd,.])
				devp = devp + sres.score
				nch = sres.nchanges
			}
			rate_hist[k,pd] = nch - targetRate[pd]
		}
		Zphase3[k, .] = dev
		Zsco3[k, .] = devp
	}

	fit.tratio = J(1, p, 0)
	for (k=1; k<=p; k++) {
		if (K3 > 1 & variance(Zphase3[.,k]) > 1e-10) {
			fit.tratio[k] = mean(Zphase3[.,k]) / sqrt(variance(Zphase3[.,k]) / K3)
		}
	}
	fit.rate_tratios = J(1, nperiods, 0)
	for (pd=1; pd<=nperiods; pd++) {
		if (K3 > 1 & variance(rate_hist[.,pd]) > 1e-10) {
			fit.rate_tratios[pd] = mean(rate_hist[.,pd]) / sqrt(variance(rate_hist[.,pd]) / K3)
		}
	}

	// harmonisation unit 18: same real-RSiena-verified sandwich formula
	// as SaomEstimateRM()'s own phase 3 (see that function's own header
	// comment for the full derivation/citation), applied to the POOLED
	// (summed-across-periods) phase-3 deviation/score matrices - the
	// natural, principled generalization of the same construction,
	// consistent with how the point estimate itself already pools
	// across periods (this function's own header comment).
	Ddev3 = Zphase3 :- mean(Zphase3)
	Dsco3 = Zsco3 :- mean(Zsco3)
	Dhat3 = (Ddev3' * Dsco3) / K3
	Dinv3 = luinv(Dhat3)
	fit.V = Dinv3 * variance(Zphase3) * Dinv3'

	// --- harmonisation unit 27: rate refinement, per period - same
	// real-RSiena-verified conditional-simulation construction as
	// SaomEstimateRM()'s own identical block (see
	// SaomSimulateConditionalTime()'s own header comment for the full
	// account), applied independently to EACH period (own starting
	// wave, own targetRate[pd]), matching how the network side already
	// tracks rate per-period (unit 17). Native-dispatched when available
	// (harmonisation unit 30 - see SaomEstimateRM()'s own identical
	// block for the full account of why).
	// harmonisation unit 33: composition change forces UNCONDITIONAL
	// estimation - see SaomEstimateRM()'s own identical block for the
	// full account. `fit.rates' stays at its closed-form value (set
	// before phase 3 above) when skipped; `fit.rate_ses' is set to all
	// zeros, matching the "not refined" signal SaomEstimateRM() already
	// uses.
	if (!haspresent) {
		fit.rates = J(1, nperiods, 0)
		fit.rate_ses = J(1, nperiods, 0)
		for (pd=1; pd<=nperiods; pd++) {
			Gp = *Gwaves[pd]
			condTimes = J(K3, 1, 0)
			for (k=1; k<=K3; k++) {
				if (use_native) {
					condTimes[k] = SaomSimulateCondTimeNative(Gp, Gp, M, cfg, fit.theta, targetRate[pd])
				}
				else {
					Gwork = ErgmGraph()
					SaomCopyGraph(Gp, Gwork)
					condTimes[k] = SaomSimulateConditionalTime(Gwork, Gp, M, fit.theta, targetRate[pd])
				}
			}
			fit.rates[pd] = mean(condTimes)
			fit.rate_ses[pd] = sqrt(variance(condTimes))
		}
	}
	else fit.rate_ses = J(1, nperiods, 0)

	if (use_native) SaomNativeCleanupFrame()

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
real rowvector stat_saom_avalt(class SaomBehavior scalar Beh, class ErgmGraph scalar G){
	real scalar i, tot, m
	real rowvector nb

	tot = 0
	for (i=1; i<=G.n; i++) {
		nb = G.neighbors_out(i)
		if (cols(nb) == 0) continue
		tot = tot + Beh.value(i) * mean(Beh.values[nb'])
	}
	return(tot)
}
real scalar change_saom_avalt(class SaomBehavior scalar Beh, class ErgmGraph scalar G, real scalar i, real scalar diff){
	real rowvector nb

	nb = G.neighbors_out(i)
	if (cols(nb) == 0) return(0)
	return(diff * mean(Beh.values[nb']))
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
}

struct SaomCoevResult scalar SaomSimulateIntervalCoev(
	class ErgmGraph scalar G, class ErgmModel scalar M, real rowvector thetaNet,
	class SaomBehavior scalar Beh, class SaomBehaviorModel scalar Mbeh, real rowvector thetaBeh,
	real scalar rateNet, real scalar rateBeh) {

	struct SaomCoevResult scalar res
	real scalar t, i, picked, totalRateNet, totalRateBeh, grandRate, draw

	res.steps = 0
	res.nchangesNet = 0
	res.nchangesBeh = 0
	totalRateNet = G.n * rateNet
	totalRateBeh = Beh.n * rateBeh
	grandRate = totalRateNet + totalRateBeh

	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / grandRate
		if (t < 1) {
			draw = runiform(1,1) * grandRate
			if (draw <= totalRateNet) {
				i = ceil(runiform(1,1) * G.n)
				picked = SaomMinistep(G, M, thetaNet, i)
				if (picked != 0) res.nchangesNet = res.nchangesNet + 1
			}
			else {
				i = ceil(runiform(1,1) * Beh.n)
				picked = SaomBehaviorMinistep(Beh, G, Mbeh, thetaBeh, i)
				if (picked != 0) res.nchangesBeh = res.nchangesBeh + 1
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
}

struct SaomCoevScoredResult scalar SaomSimulateIntervalCoevScored(
	class ErgmGraph scalar G, class ErgmModel scalar M, real rowvector thetaNet,
	class SaomBehavior scalar Beh, class SaomBehaviorModel scalar Mbeh, real rowvector thetaBeh,
	real scalar rateNet, real scalar rateBeh, | real colvector present) {

	struct SaomCoevScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg, chgDown, chgUp
	real scalar t, n, pNet, pBeh, i, j, maxu, denom, draw, draw2, cum, choice, haspresent, npresent
	real scalar totalRateNet, totalRateBeh, grandRate, cur, uDown, uUp, diff
	real colvector presentIdx

	n = G.n
	pNet = M.nparam()
	pBeh = Mbeh.nparam()
	res.scoreNet = J(1, pNet, 0)
	res.scoreBeh = J(1, pBeh, 0)
	res.steps = 0
	res.nchangesNet = 0
	res.nchangesBeh = 0

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
				if (diff != 0) res.nchangesBeh = res.nchangesBeh + 1
			}
			res.steps = res.steps + 1
		}
	}
	return(res)
}

/* ===================================================================
   SaomEstimateRMCoev: joint Method of Moments / Robbins-Monro
   estimation across network + behavior - the co-evolution analogue of
   SaomEstimateRM(), mirroring its exact three-phase structure (phase 1
   Jacobian via the score-function derivative estimator, phase 2
   multi-subphase Robbins-Monro with RSiena's own nsub=4/firstg=0.2/
   reduceg=0.5/n2minimum-n2maximum schedule, phase 3 sandwich
   covariance) over the JOINT (pNet+pBeh)-dimensional parameter/
   statistic space, rather than reinventing the estimator. Native (C)
   dispatch available (SaomSimulateIntervalCoevNative() below),
   used automatically whenever every network AND behavior term in the
   model has native coverage - falls back to the pure-Mata
   SaomSimulateIntervalCoevScored() otherwise, never a silent partial
   native run.

   Two waves only (v1 scope, matching SaomEstimateRM's own exactly-
   two-wave scope before waves() chaining generalized it, unit 17 -
   chaining a co-evolution model across 3+ waves is a further,
   not-yet-scoped extension). Two SEPARATE, FIXED rate parameters (one
   per variable, each its own verified closed-form starting value -
   network's own formula unchanged, behavior's own via
   SaomBehaviorRateStart() above), matching how the network side's own
   rate is fixed-not-refined throughout phases 1-3 already.
   =================================================================== */
struct SaomCoevFit {
	real rowvector thetaNet
	real rowvector thetaBeh
	real scalar rateNet
	real scalar rateBeh
	real rowvector tratioNet
	real rowvector tratioBeh
	real scalar rateNetTratio
	real scalar rateBehTratio
	real matrix V		// joint (pNet+pBeh) x (pNet+pBeh) covariance
}

struct SaomCoevFit scalar SaomEstimateRMCoev(
	class ErgmGraph scalar Gobs_start, class ErgmGraph scalar Gobs_end, class ErgmModel scalar M,
	real colvector Behobs_start_values, real colvector Behobs_end_values,
	real scalar behminval, real scalar behmaxval, class SaomBehaviorModel scalar Mbeh,
	real rowvector theta0Net, real rowvector theta0Beh,
	real scalar K0, real scalar K3, real scalar firstg, | real colvector present) {

	struct SaomCoevFit scalar fit
	struct SaomCoevScoredResult scalar sres
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	class ErgmGraph scalar Gwork
	class SaomBehavior scalar Behwork, Behend
	real rowvector target, theta0, theta, dev, prevdev, prod0, prod1, ac, stdcap, simstat
	real rowvector thav, fchange, changestep, thetaNet, thetaBeh
	real matrix Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3, Zsco3
	real matrix Ddev3, Dsco3, Dhat3, Dinv3, theta_hist
	real scalar pNet, pBeh, p, k, targetRateNet, targetRateBeh, ratecurNet, ratecurBeh
	real scalar overallMean, simMean, nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor, use_native
	real scalar haspresent, npresent
	real rowvector n2minimum, n2maximum
	real colvector rateNetHist, rateBehHist

	pNet = M.nparam()
	pBeh = Mbeh.nparam()
	p = pNet + pBeh

	// harmonisation unit 33 (composition change) - same optional,
	// backward-compatible convention as SaomEstimateRM()'s own identical
	// parameter (see its own header comment for the full account). A
	// SINGLE `present' vector gates both variables, exactly like
	// SaomSimulateIntervalCoevScored()'s own identical parameter.
	haspresent = (args() == 14)
	if (haspresent) npresent = length(selectindex(present))
	else npresent = Gobs_start.n

	// native (C) dispatch (harmonisation unit 26 - see
	// SaomSimulateIntervalCoevNative()'s own header comment):
	// eligible only if EVERY network term AND every behavior term has
	// native coverage - a mixed model with even one unsupported term on
	// either side falls back to the pure-Mata path entirely, never a
	// silent partial native run (matches SaomNativeSetup()'s own
	// established "all or nothing" contract). Force-disabled under
	// composition change (harmonisation unit 33 - no native support yet,
	// a disclosed, scoped-out follow-up).
	cfg = SaomNativeSetup(M)
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	use_native = cfg.eligible & cfgBeh.eligible & SaomNativeAvailable() & !haspresent

	overallMean = mean((Behobs_start_values \ Behobs_end_values))
	// avsim's own data-derived `similarityMean' constant (harmless 0 for
	// every other behavior effect) - computed ONCE by nwsaom.ado itself
	// (saom_similarity_mean()) and stored on Mbeh, mirroring exactly how
	// `balance''s own data-derived mean is stored per-term in an
	// ErgmTermData `td.decay' and simply READ here, not recomputed.
	simMean = Mbeh.simMean

	Behend = SaomBehavior()
	Behend.init(Behobs_end_values, behminval, behmaxval, overallMean, simMean)
	target = (M.full_statistic(Gobs_end), Mbeh.full_statistic(Behend, Gobs_end))
	// harmonisation unit 28: endowment/creation-type behavior terms get
	// their own REAL target here, overwriting the full_statistic()-based
	// placeholder above (see SaomBehaviorPatchEndowCreation()'s own
	// header comment) - a no-op whenever no such term is in the model.
	target = SaomBehaviorPatchEndowCreation(Mbeh, target, pNet, Behobs_start_values, Behobs_end_values)

	targetRateNet = SaomCountDiffering(Gobs_start, Gobs_end)
	targetRateBeh = sum(abs(Behobs_end_values - Behobs_start_values))

	ratecurNet = npresent * (0.2 + 2*targetRateNet) / (npresent*(npresent-1) + 1)
	ratecurBeh = SaomBehaviorRateStart(Behobs_start_values, Behobs_end_values)

	theta0 = (theta0Net, theta0Beh)

	// --- Phase 1: joint Jacobian, same Cov(deviation,score)/diagonalize
	// construction as SaomEstimateRM()'s own phase 1, now over the full
	// (pNet+pBeh)-dimensional joint space.
	Zdev = J(K0, p, 0)
	Zsco = J(K0, p, 0)
	for (k=1; k<=K0; k++) {
		Behwork = SaomBehavior()
		Behwork.init(Behobs_start_values, behminval, behmaxval, overallMean, simMean)

		if (use_native) {
			// harmonisation unit 32 (performance pass, same rationale as
			// unit 15's identical fix on the network-only side): no
			// SaomCopyGraph() needed here - `rebuild_g=0' means G is
			// never mutated, so Gobs_start itself can be passed directly.
			sres = SaomSimulateIntervalCoevNative(Gobs_start, M, cfg, theta0Net, Behwork, Mbeh, cfgBeh, theta0Beh, ratecurNet, ratecurBeh, 0)
			simstat = (sres.stat, sres.statBeh)
		}
		else {
			Gwork = ErgmGraph()
			SaomCopyGraph(Gobs_start, Gwork)
			if (haspresent) sres = SaomSimulateIntervalCoevScored(Gwork, M, theta0Net, Behwork, Mbeh, theta0Beh, ratecurNet, ratecurBeh, present)
			else sres = SaomSimulateIntervalCoevScored(Gwork, M, theta0Net, Behwork, Mbeh, theta0Beh, ratecurNet, ratecurBeh)
			simstat = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
		}
		simstat = SaomBehaviorPatchEndowCreation(Mbeh, simstat, pNet, Behobs_start_values, Behwork.values)
		Zdev[k,.] = simstat - target
		Zsco[k,.] = (sres.scoreNet, sres.scoreBeh)
	}
	Ddev = Zdev :- mean(Zdev)
	Dsco = Zsco :- mean(Zsco)
	Dhat = (Ddev' * Dsco) / K0
	temp = 0.8 * Dhat + 0.2 * diag(diagonal(Dhat))
	Dinv = luinv(temp)

	msf = variance(Zdev)
	sfinvcov = invsym(msf + 0.0001 * I(p))
	stdcap = J(1, p, 1)
	for (k=1; k<=p; k++) {
		stdcap[k] = 1 / sqrt(max((Dinv[k,.] * msf * Dinv[k,.]', 0)))
		if (stdcap[k] > 1) stdcap[k] = 1
	}

	// --- Phase 2: joint Robbins-Monro, identical subphase schedule to
	// SaomEstimateRM()'s own phase 2, over the joint parameter vector.
	nsub = 4
	reduceg = 0.5
	gain = firstg
	n2min0 = max((5, 7 + p))
	n2minimum = J(1, nsub, 0)
	n2maximum = J(1, nsub, 0)
	n2minimum[1] = trunc(n2min0 * 2.52)
	n2maximum[1] = n2minimum[1] + 200
	for (k=2; k<=nsub; k++) {
		n2minimum[k] = trunc(n2minimum[k-1] * 2.52)
		n2maximum[k] = n2minimum[k] + 200
	}

	theta = theta0
	theta_hist = J(nsub, p, 0)

	for (subphase=1; subphase<=nsub; subphase++) {
		thav = theta
		thavn = 1
		prod0 = J(1, p, 0)
		prod1 = J(1, p, 0)
		prevdev = J(1, p, 0)
		nit = 0
		maxacor = 1

		while (1) {
			nit = nit + 1
			Behwork = SaomBehavior()
			Behwork.init(Behobs_start_values, behminval, behmaxval, overallMean, simMean)

			thetaNet = theta[1..pNet]
			thetaBeh = theta[(pNet+1)..p]
			if (use_native) {
				// harmonisation unit 32 - see phase 1's own identical
				// comment above.
				sres = SaomSimulateIntervalCoevNative(Gobs_start, M, cfg, thetaNet, Behwork, Mbeh, cfgBeh, thetaBeh, ratecurNet, ratecurBeh, 0)
				simstat = (sres.stat, sres.statBeh)
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gobs_start, Gwork)
				if (haspresent) sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, ratecurNet, ratecurBeh, present)
				else sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, ratecurNet, ratecurBeh)
				simstat = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
			}
			simstat = SaomBehaviorPatchEndowCreation(Mbeh, simstat, pNet, Behobs_start_values, Behwork.values)
			dev = simstat - target

			if (mod(nit,2) == 1) prevdev = dev
			else {
				prod0 = prod0 + dev:^2
				prod1 = prod1 + dev:*prevdev
			}

			maxRatio = sqrt((dev * sfinvcov * dev') / p)
			if (maxRatio > 5 & maxRatio > 0) dev = 5 * dev / maxRatio

			if (nit == 1) changestep = dev
			else changestep = changestep + dev
			fchange = gain * ((changestep * Dinv') :* stdcap)

			theta = (thav / thavn) - fchange
			thav = thav + theta
			thavn = thavn + 1
			SaomCheckThetaBound(theta, 50)		// harmonisation unit 29 - see that function's own header comment

			if (nit >= 2) {
				ac = J(1, p, -1)
				for (k=1; k<=p; k++) {
					if (prod0[k] > 1e-12) ac[k] = prod1[k] / prod0[k]
				}
				maxacor = max(ac)
			}

			if (nit >= n2maximum[subphase]) break
			if (nit >= n2minimum[subphase] & maxacor < 1e-10) break
		}

		theta = thav / thavn
		theta_hist[subphase, .] = theta
		gain = gain * reduceg
	}

	fit.thetaNet = theta[1..pNet]
	fit.thetaBeh = theta[(pNet+1)..p]
	fit.rateNet = ratecurNet
	fit.rateBeh = ratecurBeh

	// --- Phase 3: joint sandwich covariance, identical construction to
	// SaomEstimateRM()'s own phase 3, over the joint space - plus
	// SEPARATE rate t-ratio diagnostics for each variable's own rate
	// (network's own nchanges vs targetRateNet, behavior's own
	// nchanges vs targetRateBeh - two independent moment checks, not a
	// joint one, matching how each variable's own rate is a separate,
	// independently-targeted parameter).
	Zphase3 = J(K3, p, 0)
	Zsco3 = J(K3, p, 0)
	rateNetHist = J(K3, 1, 0)
	rateBehHist = J(K3, 1, 0)
	for (k=1; k<=K3; k++) {
		Behwork = SaomBehavior()
		Behwork.init(Behobs_start_values, behminval, behmaxval, overallMean, simMean)

		if (use_native) {
			// harmonisation unit 32 - see phase 1's own identical
			// comment above.
			sres = SaomSimulateIntervalCoevNative(Gobs_start, M, cfg, fit.thetaNet, Behwork, Mbeh, cfgBeh, fit.thetaBeh, ratecurNet, ratecurBeh, 0)
			simstat = (sres.stat, sres.statBeh)
		}
		else {
			Gwork = ErgmGraph()
			SaomCopyGraph(Gobs_start, Gwork)
			if (haspresent) sres = SaomSimulateIntervalCoevScored(Gwork, M, fit.thetaNet, Behwork, Mbeh, fit.thetaBeh, ratecurNet, ratecurBeh, present)
			else sres = SaomSimulateIntervalCoevScored(Gwork, M, fit.thetaNet, Behwork, Mbeh, fit.thetaBeh, ratecurNet, ratecurBeh)
			simstat = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
		}
		simstat = SaomBehaviorPatchEndowCreation(Mbeh, simstat, pNet, Behobs_start_values, Behwork.values)
		Zphase3[k, .] = simstat - target
		Zsco3[k, .] = (sres.scoreNet, sres.scoreBeh)
		rateNetHist[k] = sres.nchangesNet - targetRateNet
		rateBehHist[k] = sres.nchangesBeh - targetRateBeh
	}

	fit.tratioNet = J(1, pNet, 0)
	for (k=1; k<=pNet; k++) {
		if (K3 > 1 & variance(Zphase3[.,k]) > 1e-10) {
			fit.tratioNet[k] = mean(Zphase3[.,k]) / sqrt(variance(Zphase3[.,k]) / K3)
		}
	}
	fit.tratioBeh = J(1, pBeh, 0)
	for (k=1; k<=pBeh; k++) {
		if (K3 > 1 & variance(Zphase3[.,pNet+k]) > 1e-10) {
			fit.tratioBeh[k] = mean(Zphase3[.,pNet+k]) / sqrt(variance(Zphase3[.,pNet+k]) / K3)
		}
	}
	fit.rateNetTratio = 0
	if (K3 > 1 & variance(rateNetHist) > 1e-10) {
		fit.rateNetTratio = mean(rateNetHist) / sqrt(variance(rateNetHist) / K3)
	}
	fit.rateBehTratio = 0
	if (K3 > 1 & variance(rateBehHist) > 1e-10) {
		fit.rateBehTratio = mean(rateBehHist) / sqrt(variance(rateBehHist) / K3)
	}

	Ddev3 = Zphase3 :- mean(Zphase3)
	Dsco3 = Zsco3 :- mean(Zsco3)
	Dhat3 = (Ddev3' * Dsco3) / K3
	Dinv3 = luinv(Dhat3)
	fit.V = Dinv3 * variance(Zphase3) * Dinv3'

	if (use_native) SaomNativeCleanupFrame()

	return(fit)
}

/* ===================================================================
   SaomEstimateRMCoevMulti: co-evolution across 3+ waves (harmonisation
   unit 26, "N-wave co-evolution" per explicit user direction - "extend
   it to N waves"). Generalizes SaomEstimateRMCoev() (kept completely
   UNTOUCHED above, zero regression risk to the already-certified
   two-wave path) to `nwaves' >= 2 waves / `nperiods' = nwaves-1 periods,
   the EXACT same relationship SaomEstimateRMMulti() already established
   for the network-only case (unit 17) - mirrored here, not reinvented:
   theta (BOTH network and behavior) is POOLED/shared across every
   period by summing per-period deviations/scores before the Jacobian/
   Robbins-Monro update (same convention this whole codebase already
   uses for theta pooling, GOF's own join=TRUE, and the two-wave
   SaomEstimateRMCoev's own network+behavior concatenation), while EACH
   variable's own rate stays PER-PERIOD (network rate per period,
   matching unit 17's own `fit.rates'; behavior rate per period,
   genuinely new here) - four separate per-period rate series in total,
   not two.

   Native (C) dispatch (harmonisation unit 26 native port) available
   exactly like SaomEstimateRMCoev()'s own two-wave case - see
   SaomSimulateIntervalCoevNative()'s own header comment.
   =================================================================== */
struct SaomCoevMultiFit {
	real rowvector thetaNet
	real rowvector thetaBeh
	real rowvector ratesNet		// 1 x nperiods
	real rowvector ratesBeh		// 1 x nperiods
	real rowvector tratioNet
	real rowvector tratioBeh
	real rowvector rateNetTratios		// 1 x nperiods
	real rowvector rateBehTratios		// 1 x nperiods
	real matrix V
}

struct SaomCoevMultiFit scalar SaomEstimateRMCoevMulti(
	pointer(class ErgmGraph scalar) rowvector Gwaves,
	class ErgmModel scalar M,
	pointer(real colvector) rowvector Behwaves, real scalar behminval, real scalar behmaxval,
	class SaomBehaviorModel scalar Mbeh,
	real rowvector theta0Net, real rowvector theta0Beh,
	real scalar K0, real scalar K3, real scalar firstg) {

	struct SaomCoevMultiFit scalar fit
	struct SaomCoevScoredResult scalar sres
	struct SaomNativeConfig scalar cfg
	struct SaomBehaviorNativeConfig scalar cfgBeh
	class ErgmGraph scalar Gwork, Gp, Gpend
	class SaomBehavior scalar Behwork, Behpend
	real matrix target, Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3, Zsco3
	real matrix Ddev3, Dsco3, Dhat3, Dinv3, theta_hist, rateNetHist, rateBehHist
	real rowvector theta, theta0, dev, prevdev, prod0, prod1, ac, stdcap, simstat
	real rowvector thav, fchange, changestep, thetaNet, thetaBeh
	real rowvector ratesNet, ratesBeh, targetRateNet, targetRateBeh
	real scalar pNet, pBeh, p, k, pd, nwaves, nperiods, overallMean, simMean, nch, use_native
	real scalar nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real rowvector n2minimum, n2maximum
	real colvector allbehvals

	nwaves = cols(Gwaves)
	nperiods = nwaves - 1
	pNet = M.nparam()
	pBeh = Mbeh.nparam()
	p = pNet + pBeh

	// native (C) dispatch - see SaomEstimateRMCoev()'s own identical
	// comment above (this function mirrors that one's dispatch exactly,
	// just re-checked here since it is a separate function).
	cfg = SaomNativeSetup(M)
	cfgBeh = SaomBehaviorNativeSetup(Mbeh)
	use_native = cfg.eligible & cfgBeh.eligible & SaomNativeAvailable()

	// overallMean pools EVERY wave's own behavior values (not just the
	// two endpoints of one period) - matching real RSiena's own
	// BehaviorLongitudinalData::overallMean() scope, and the two-wave
	// SaomEstimateRMCoev()'s own identical convention generalized to N
	// waves.
	allbehvals = *Behwaves[1]
	for (pd=2; pd<=nwaves; pd++) allbehvals = allbehvals \ *Behwaves[pd]
	overallMean = mean(allbehvals)
	// avsim's own data-derived `similarityMean' constant - read off Mbeh,
	// where nwsaom.ado already computed and stored it once (see
	// SaomEstimateRMCoev()'s own identical comment above).
	simMean = Mbeh.simMean

	target = J(nperiods, p, 0)
	targetRateNet = J(1, nperiods, 0)
	targetRateBeh = J(1, nperiods, 0)
	ratesNet = J(1, nperiods, 0)
	ratesBeh = J(1, nperiods, 0)
	for (pd=1; pd<=nperiods; pd++) {
		Gp = *Gwaves[pd]
		Gpend = *Gwaves[pd+1]
		Behpend = SaomBehavior()
		Behpend.init(*Behwaves[pd+1], behminval, behmaxval, overallMean, simMean)
		target[pd,.] = (M.full_statistic(Gpend), Mbeh.full_statistic(Behpend, Gpend))
		// harmonisation unit 28 - see SaomEstimateRMCoev()'s own identical
		// comment above; this period's own starting wave is *Behwaves[pd].
		target[pd,.] = SaomBehaviorPatchEndowCreation(Mbeh, target[pd,.], pNet, *Behwaves[pd], *Behwaves[pd+1])

		targetRateNet[pd] = SaomCountDiffering(Gp, Gpend)
		targetRateBeh[pd] = sum(abs(*Behwaves[pd+1] - *Behwaves[pd]))

		ratesNet[pd] = Gp.n * (0.2 + 2*targetRateNet[pd]) / (Gp.n*(Gp.n-1) + 1)
		ratesBeh[pd] = SaomBehaviorRateStart(*Behwaves[pd], *Behwaves[pd+1])
	}

	theta0 = (theta0Net, theta0Beh)

	// --- Phase 1: pooled joint Jacobian - SUM the per-period joint
	// (network+behavior) deviation/score across periods, otherwise
	// identical to SaomEstimateRMCoev()'s own phase 1.
	Zdev = J(K0, p, 0)
	Zsco = J(K0, p, 0)
	for (k=1; k<=K0; k++) {
		dev = J(1, p, 0)
		prevdev = J(1, p, 0)		// score accumulator (reusing prevdev to avoid a second p-length temp before phase 2 needs it for its own purpose)
		for (pd=1; pd<=nperiods; pd++) {
			Gp = *Gwaves[pd]
			Behwork = SaomBehavior()
			Behwork.init(*Behwaves[pd], behminval, behmaxval, overallMean, simMean)
			if (use_native) {
				// harmonisation unit 32 - see SaomEstimateRMCoev()'s own
				// phase 1 identical comment.
				sres = SaomSimulateIntervalCoevNative(Gp, M, cfg, theta0Net, Behwork, Mbeh, cfgBeh, theta0Beh, ratesNet[pd], ratesBeh[pd], 0)
				simstat = (sres.stat, sres.statBeh)
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gp, Gwork)
				sres = SaomSimulateIntervalCoevScored(Gwork, M, theta0Net, Behwork, Mbeh, theta0Beh, ratesNet[pd], ratesBeh[pd])
				simstat = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
			}
			simstat = SaomBehaviorPatchEndowCreation(Mbeh, simstat, pNet, *Behwaves[pd], Behwork.values)
			dev = dev + (simstat - target[pd,.])
			prevdev = prevdev + (sres.scoreNet, sres.scoreBeh)
		}
		Zdev[k,.] = dev
		Zsco[k,.] = prevdev
	}
	Ddev = Zdev :- mean(Zdev)
	Dsco = Zsco :- mean(Zsco)
	Dhat = (Ddev' * Dsco) / K0
	temp = 0.8 * Dhat + 0.2 * diag(diagonal(Dhat))
	Dinv = luinv(temp)

	msf = variance(Zdev)
	sfinvcov = invsym(msf + 0.0001 * I(p))
	stdcap = J(1, p, 1)
	for (k=1; k<=p; k++) {
		stdcap[k] = 1 / sqrt(max((Dinv[k,.] * msf * Dinv[k,.]', 0)))
		if (stdcap[k] > 1) stdcap[k] = 1
	}

	// --- Phase 2: pooled joint multi-subphase Robbins-Monro - identical
	// schedule/truncation/double-averaging/autocorrelation logic to
	// SaomEstimateRMCoev()'s own phase 2, summing `dev' across periods
	// each iteration.
	nsub = 4
	reduceg = 0.5
	gain = firstg
	n2min0 = max((5, 7 + p))
	n2minimum = J(1, nsub, 0)
	n2maximum = J(1, nsub, 0)
	n2minimum[1] = trunc(n2min0 * 2.52)
	n2maximum[1] = n2minimum[1] + 200
	for (k=2; k<=nsub; k++) {
		n2minimum[k] = trunc(n2minimum[k-1] * 2.52)
		n2maximum[k] = n2minimum[k] + 200
	}

	theta = theta0
	theta_hist = J(nsub, p, 0)

	for (subphase=1; subphase<=nsub; subphase++) {
		thav = theta
		thavn = 1
		prod0 = J(1, p, 0)
		prod1 = J(1, p, 0)
		prevdev = J(1, p, 0)
		nit = 0
		maxacor = 1

		while (1) {
			nit = nit + 1
			thetaNet = theta[1..pNet]
			thetaBeh = theta[(pNet+1)..p]
			dev = J(1, p, 0)
			for (pd=1; pd<=nperiods; pd++) {
				Gp = *Gwaves[pd]
				Behwork = SaomBehavior()
				Behwork.init(*Behwaves[pd], behminval, behmaxval, overallMean, simMean)
				if (use_native) {
					// harmonisation unit 32 - see SaomEstimateRMCoev()'s
					// own phase 1 identical comment.
					sres = SaomSimulateIntervalCoevNative(Gp, M, cfg, thetaNet, Behwork, Mbeh, cfgBeh, thetaBeh, ratesNet[pd], ratesBeh[pd], 0)
					simstat = (sres.stat, sres.statBeh)
				}
				else {
					Gwork = ErgmGraph()
					SaomCopyGraph(Gp, Gwork)
					sres = SaomSimulateIntervalCoevScored(Gwork, M, thetaNet, Behwork, Mbeh, thetaBeh, ratesNet[pd], ratesBeh[pd])
					simstat = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
				}
				simstat = SaomBehaviorPatchEndowCreation(Mbeh, simstat, pNet, *Behwaves[pd], Behwork.values)
				dev = dev + (simstat - target[pd,.])
			}

			if (mod(nit,2) == 1) prevdev = dev
			else {
				prod0 = prod0 + dev:^2
				prod1 = prod1 + dev:*prevdev
			}

			maxRatio = sqrt((dev * sfinvcov * dev') / p)
			if (maxRatio > 5 & maxRatio > 0) dev = 5 * dev / maxRatio

			if (nit == 1) changestep = dev
			else changestep = changestep + dev
			fchange = gain * ((changestep * Dinv') :* stdcap)

			theta = (thav / thavn) - fchange
			thav = thav + theta
			thavn = thavn + 1
			SaomCheckThetaBound(theta, 50)		// harmonisation unit 29 - see that function's own header comment

			if (nit >= 2) {
				ac = J(1, p, -1)
				for (k=1; k<=p; k++) {
					if (prod0[k] > 1e-12) ac[k] = prod1[k] / prod0[k]
				}
				maxacor = max(ac)
			}

			if (nit >= n2maximum[subphase]) break
			if (nit >= n2minimum[subphase] & maxacor < 1e-10) break
		}

		theta = thav / thavn
		theta_hist[subphase, .] = theta
		gain = gain * reduceg
	}

	fit.thetaNet = theta[1..pNet]
	fit.thetaBeh = theta[(pNet+1)..p]
	fit.ratesNet = ratesNet
	fit.ratesBeh = ratesBeh

	// --- Phase 3: pooled joint sandwich covariance, PLUS per-period,
	// per-variable rate diagnostics (rateNetHist/rateBehHist are each
	// K3 x nperiods, one column per period's own accepted-change
	// moment - the co-evolution analogue of SaomEstimateRMMulti()'s own
	// single rate_hist, now doubled since there are two variables).
	Zphase3 = J(K3, p, 0)
	Zsco3 = J(K3, p, 0)
	rateNetHist = J(K3, nperiods, 0)
	rateBehHist = J(K3, nperiods, 0)
	for (k=1; k<=K3; k++) {
		dev = J(1, p, 0)
		prevdev = J(1, p, 0)
		for (pd=1; pd<=nperiods; pd++) {
			Gp = *Gwaves[pd]
			Behwork = SaomBehavior()
			Behwork.init(*Behwaves[pd], behminval, behmaxval, overallMean, simMean)
			if (use_native) {
				// harmonisation unit 32 - see SaomEstimateRMCoev()'s own
				// phase 1 identical comment.
				sres = SaomSimulateIntervalCoevNative(Gp, M, cfg, fit.thetaNet, Behwork, Mbeh, cfgBeh, fit.thetaBeh, ratesNet[pd], ratesBeh[pd], 0)
				simstat = (sres.stat, sres.statBeh)
			}
			else {
				Gwork = ErgmGraph()
				SaomCopyGraph(Gp, Gwork)
				sres = SaomSimulateIntervalCoevScored(Gwork, M, fit.thetaNet, Behwork, Mbeh, fit.thetaBeh, ratesNet[pd], ratesBeh[pd])
				simstat = (M.full_statistic(Gwork), Mbeh.full_statistic(Behwork, Gwork))
			}
			simstat = SaomBehaviorPatchEndowCreation(Mbeh, simstat, pNet, *Behwaves[pd], Behwork.values)
			dev = dev + (simstat - target[pd,.])
			prevdev = prevdev + (sres.scoreNet, sres.scoreBeh)
			rateNetHist[k,pd] = sres.nchangesNet - targetRateNet[pd]
			rateBehHist[k,pd] = sres.nchangesBeh - targetRateBeh[pd]
		}
		Zphase3[k, .] = dev
		Zsco3[k, .] = prevdev
	}

	fit.tratioNet = J(1, pNet, 0)
	for (k=1; k<=pNet; k++) {
		if (K3 > 1 & variance(Zphase3[.,k]) > 1e-10) {
			fit.tratioNet[k] = mean(Zphase3[.,k]) / sqrt(variance(Zphase3[.,k]) / K3)
		}
	}
	fit.tratioBeh = J(1, pBeh, 0)
	for (k=1; k<=pBeh; k++) {
		if (K3 > 1 & variance(Zphase3[.,pNet+k]) > 1e-10) {
			fit.tratioBeh[k] = mean(Zphase3[.,pNet+k]) / sqrt(variance(Zphase3[.,pNet+k]) / K3)
		}
	}
	fit.rateNetTratios = J(1, nperiods, 0)
	fit.rateBehTratios = J(1, nperiods, 0)
	for (pd=1; pd<=nperiods; pd++) {
		if (K3 > 1 & variance(rateNetHist[.,pd]) > 1e-10) {
			fit.rateNetTratios[pd] = mean(rateNetHist[.,pd]) / sqrt(variance(rateNetHist[.,pd]) / K3)
		}
		if (K3 > 1 & variance(rateBehHist[.,pd]) > 1e-10) {
			fit.rateBehTratios[pd] = mean(rateBehHist[.,pd]) / sqrt(variance(rateBehHist[.,pd]) / K3)
		}
	}

	Ddev3 = Zphase3 :- mean(Zphase3)
	Dsco3 = Zsco3 :- mean(Zsco3)
	Dhat3 = (Ddev3' * Dsco3) / K3
	Dinv3 = luinv(Dhat3)
	fit.V = Dinv3 * variance(Zphase3) * Dinv3'

	if (use_native) SaomNativeCleanupFrame()

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
   3-term set): covers all 13 terms unw_saom.do currently implements -
   outdegree, reciprocity, nodematch, nodecov, nodeicov, nodeocov,
   indegpopularity, outactivity, outpopularity, inactivity, transtrip,
   cycle3, simcov (native/saom_sim.c's own termcode dispatch was
   extended in lockstep - see its own header comment). Extended after a
   direct RSiena speed benchmark found the pure-Mata fallback 400x+
   slower than real RSiena for ANY model using a non-native term - see
   docs/SAOM_ROADMAP.md's own account. A model using a term OUTSIDE this
   set (a future, not-yet-natively-ported effect) is simply not eligible
   - SaomNativeSetup() returns cfg.eligible=0 and the caller falls back
   to the pure-Mata SaomSimulateInterval()/SaomSimulateIntervalCounted(),
   never a silent partial fallback mid-run.
   =================================================================== */

string scalar SaomNativeInstallDir(){
	string scalar full, dir, fn

	full = findfile("nwsaom.ado")
	if (full == "") return("")
	pathsplit(full, dir, fn)
	return(dir)
}

string scalar SaomNativePluginSubdir(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("windows")
	if (os == "Unix") return("unix")
	return("macos")
}

string scalar SaomNativePluginFilename(){
	if (st_global("c(os)") == "Unix") return("saom_sim_unix.plugin")
	return("saom_sim.plugin")
}

string scalar SaomNativePluginPath(){
	string scalar dir

	dir = SaomNativeInstallDir()
	if (dir == "") return("")
	return(pathjoin(pathjoin(dir, "lib"),
		pathjoin("plugins", pathjoin(SaomNativePluginSubdir(), SaomNativePluginFilename()))))
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
	real scalar t, nextattr
	string scalar nm

	cfg.termcodes = J(1, M.nterms, 0)
	cfg.attridx = J(1, M.nterms, 0)
	cfg.p1 = J(1, M.nterms, 0)
	cfg.attrmat = J(0, 0, 0)	// built up column by column below, one per attribute-needing term
	cfg.eligible = 1
	nextattr = 0

	for (t=1; t<=M.nterms; t++) {
		nm = M.names[t]
		if (nm == "outdegree") cfg.termcodes[t] = 1
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
			cfg.termcodes[t] = 13
			tdt = *M.td[t]
			nextattr++
			cfg.attridx[t] = nextattr
			cfg.attrmat = (cols(cfg.attrmat)==0 ? tdt.attr : (cfg.attrmat, tdt.attr))
			cfg.p1[t] = tdt.decay
		}
		else cfg.eligible = 0
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
	cfg.eligible = 1
	for (t=1; t<=Mbeh.nterms; t++) {
		nm = Mbeh.names[t]
		if (Mbeh.fntype[t] != 0) {
			cfg.eligible = 0
			continue
		}
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
   both total ministep opportunities AND accepted-change count, needed
   for the joint rate/theta Robbins-Monro update, harmonisation unit 8)
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
struct SaomCountedResult scalar SaomSimulateIntervalNative(class ErgmGraph scalar G, class ErgmModel scalar M,
	struct SaomNativeConfig scalar cfg, real rowvector theta, real scalar rate, real scalar rebuild_g,
	real scalar want_score){

	struct SaomCountedResult scalar res
	real matrix ties, newties
	real scalar n, nties, nattr, i, rngseed, nties_out, __junk, neededrows, neededvars
	string scalar origframe, argstr, cmd, attrvarlist
	string rowvector attrvarnames

	n = G.n
	ties = G.all_ties()
	nties = rows(ties)
	nattr = cols(cfg.attrmat)

	// worst case: the simulated network densifies up to the full
	// directed dyad space (n*(n-1)) before the interval ends - the frame
	// must have enough rows for whatever nties_out the plugin returns,
	// not just the STARTING tie count (matches ErgmNativeSampleCore()'s
	// own identical "size for the full dyad space" defensiveness in
	// unw_ergm.do).
	neededrows = max((n, nties, n*(n-1), 1))
	neededvars = 2 + nattr

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
	}
	for (i=1; i<=nattr; i++) attrvarlist = attrvarlist + " " + attrvarnames[i]

	if (st_nobs() < neededrows) st_addobs(neededrows - st_nobs())

	for (i=1; i<=nattr; i++) st_store((1::n), attrvarnames[i], cfg.attrmat[1::n, i])
	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)

	rngseed = floor(runiform(1,1) * 2147483647)

	argstr = strofreal(n) + " " + strofreal(G.directed) + " " + strofreal(nties) + " " +
		strofreal(rate) + " " + strofreal(rngseed) + " " + strofreal(nattr) + " " + strofreal(M.nterms)
	for (i=1; i<=M.nterms; i++) {
		argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i])
	}
	for (i=1; i<=M.nterms; i++) argstr = argstr + " " + strofreal(theta[i])
	argstr = argstr + " " + strofreal(want_score)		// harmonisation unit 16 - trailing field, see native/saom_sim.c's own stata_call() parsing
	argstr = argstr + " 0"		// harmonisation unit 26: nbehterms=0 - the network-only wire-protocol footprint is now "no further fields at all"; see SaomSimulateIntervalCoevNative() below for the co-evolution counterpart that supplies real behavior fields here
	argstr = argstr + " 0 0"		// harmonisation unit 30: condmode=0/targetChange=0 - fixed-interval mode, unchanged behavior; see SaomSimulateCondTimeNative() below for the conditional-mode counterpart

	// see ErgmNativeSampleCore()'s own header comment for why `capture`
	// here is correct (an already-defined plugin program cannot be
	// redefined within the same session) rather than masking a genuine
	// failure - a bad path/corrupt plugin still surfaces at `plugin call`.
	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")

	cmd = "plugin call saomnativesim v1 v2" + attrvarlist + ", " + char(34) + argstr + char(34)
	stata(cmd)

	nties_out = st_numscalar("__saom_native_nties_out")
	res.steps = st_numscalar("__saom_native_steps")
	res.nchanges = st_numscalar("__saom_native_nchanges")

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
   SaomSimulateConditionalTime() above - harmonisation unit 30
   (performance pass), per explicit user direction after a real,
   measured finding: a direct RSiena benchmark (dev/
   saom_rsiena_benchmark.R/.do) found SaomEstimateRM()'s own network-
   only path ~22x slower than real RSiena on s50 data, and a targeted
   profiling pass (isolating harmonisation unit 27's own post-phase-3
   refinement loop and timing it alone, both against the full fit's own
   total time) found that loop alone accounted for essentially ALL of
   it - K3=1000 pure-Mata SaomSimulateConditionalTime() replicates,
   the one thing in this whole estimator that had never been ported
   native (every phase 1/2/3 call already dispatches to
   SaomSimulateIntervalNative() when available). This function is a
   direct structural port: same frame/argstr contract as
   SaomSimulateIntervalNative() (reused verbatim below, not
   reinvented), but simpler - no attributes/behavior/score needed for
   this refinement loop's own purpose (only the elapsed continuous TIME
   matters), `rate' is ALWAYS passed as 1 (the verified reference rate,
   see SaomSimulateConditionalTime()'s own header comment for why), and
   `condmode=1'/`targetChange' select native/saom_sim.c's own
   "CONDITIONAL MODE" stopping rule (see that file's own header
   comment) instead of the fixed-interval one every other native call
   site uses. Statistically certified against SaomSimulateConditionalTime()
   (the reference/fallback/oracle, unchanged) exactly like every other
   native/Mata pair in this file - see cscripts/test_nwsaom_native.do.
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
		strofreal(1) + " " + strofreal(rngseed) + " " + strofreal(nattr) + " " + strofreal(M.nterms)
	for (i=1; i<=M.nterms; i++) {
		argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i])
	}
	for (i=1; i<=M.nterms; i++) argstr = argstr + " " + strofreal(theta[i])
	argstr = argstr + " 0"		// want_score=0
	argstr = argstr + " 0"		// nbehterms=0
	argstr = argstr + " 1 " + strofreal(targetChange)		// condmode=1, targetChange

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
	real rowvector thetaBeh, real scalar rateNet, real scalar rateBeh, real scalar rebuild_g){

	struct SaomCoevScoredResult scalar res
	real matrix ties, newties
	real scalar n, nties, nattr, i, rngseed, nties_out, __junk, neededrows, neededvars, pBeh
	string scalar origframe, argstr, cmd, attrvarlist, behvarname

	n = G.n
	ties = G.all_ties()
	nties = rows(ties)
	nattr = cols(cfg.attrmat)
	pBeh = Mbeh.nparam()

	neededrows = max((n, nties, n*(n-1), 1))
	neededvars = 3 + nattr		// v1, v2, behavior column, + attributes (one more than SaomSimulateIntervalNative()'s own neededvars - see this function's own header comment)

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
	}
	for (i=1; i<=nattr; i++) attrvarlist = attrvarlist + " a" + strofreal(i)
	behvarname = "vbeh"

	if (st_nobs() < neededrows) st_addobs(neededrows - st_nobs())

	for (i=1; i<=nattr; i++) st_store((1::n), "a" + strofreal(i), cfg.attrmat[1::n, i])
	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)
	st_store((1::n), behvarname, Beh.values)

	rngseed = floor(runiform(1,1) * 2147483647)

	argstr = strofreal(n) + " " + strofreal(G.directed) + " " + strofreal(nties) + " " +
		strofreal(rateNet) + " " + strofreal(rngseed) + " " + strofreal(nattr) + " " + strofreal(M.nterms)
	for (i=1; i<=M.nterms; i++) {
		argstr = argstr + " " + strofreal(cfg.termcodes[i]) + " " + strofreal(cfg.attridx[i]) + " " + strofreal(cfg.p1[i])
	}
	for (i=1; i<=M.nterms; i++) argstr = argstr + " " + strofreal(theta[i])
	argstr = argstr + " 1"		// want_score - always 1, see this function's own header comment
	argstr = argstr + " " + strofreal(pBeh)
	for (i=1; i<=pBeh; i++) argstr = argstr + " " + strofreal(cfgBeh.termcodes[i])
	for (i=1; i<=pBeh; i++) argstr = argstr + " " + strofreal(thetaBeh[i])
	argstr = argstr + " " + strofreal(rateBeh) + " " + strofreal(Beh.minval) + " " + strofreal(Beh.maxval) +
		" " + strofreal(Beh.simMean) + " " + strofreal(Beh.overallMean)
	argstr = argstr + " 0 0"		// harmonisation unit 30: condmode=0/targetChange=0 - conditional mode is network-only, never used on the co-evolution path (real RSiena's own conditional-estimation default requires exactly one dependent variable - see SaomSimulateConditionalTime()'s own header comment)

	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")

	cmd = "plugin call saomnativesim v1 v2" + attrvarlist + " " + behvarname + ", " + char(34) + argstr + char(34)
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
