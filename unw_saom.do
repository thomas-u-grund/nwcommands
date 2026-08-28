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
   =================================================================== */
real scalar SaomMinistep(class ErgmGraph scalar G, class ErgmModel scalar M,
	real rowvector theta, real scalar i) {

	real scalar n, j, k, maxu, denom, draw, cum, choice
	real rowvector u
	real rowvector chg

	n = G.n
	u = J(1, n, 0)		// u[j] for j!=i; u[i] itself unused (self-toggle undefined)
	for (j=1; j<=n; j++) {
		if (j == i) continue
		chg = M.full_change(G, i, j)
		u[j] = theta * chg'
	}

	// numerically stable softmax over {u[1..n excl. i], 0 for "stay"}
	maxu = 0	// "stay"'s own utility, always included as a candidate max
	for (j=1; j<=n; j++) {
		if (j == i) continue
		if (u[j] > maxu) maxu = u[j]
	}

	denom = exp(0 - maxu)	// "stay"'s own exp term
	for (j=1; j<=n; j++) {
		if (j == i) continue
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
   =================================================================== */
real scalar SaomSimulateInterval(class ErgmGraph scalar G, class ErgmModel scalar M,
	real rowvector theta, real scalar rate) {

	real scalar t, steps, i, picked

	t = 0
	steps = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / (G.n * rate)
		if (t < 1) {
			i = ceil(runiform(1,1) * G.n)
			picked = SaomMinistep(G, M, theta, i)
			steps = steps + 1
		}
	}
	return(steps)
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
	class ErgmModel scalar M, real rowvector theta, real scalar rate) {

	struct SaomScoredResult scalar res
	real matrix chgmat
	real rowvector u, ebar, chosen_chg
	real scalar t, n, p, i, j, k, maxu, denom, draw, cum, choice

	n = G.n
	p = M.nparam()
	res.score = J(1, p, 0)
	res.steps = 0
	res.nchanges = 0

	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / (n * rate)
		if (t < 1) {
			i = ceil(runiform(1,1) * n)

			chgmat = J(n, p, 0)
			u = J(1, n, 0)
			maxu = 0
			for (j=1; j<=n; j++) {
				if (j == i) continue
				chgmat[j,.] = M.full_change(G, i, j)
				u[j] = theta * chgmat[j,.]'
				if (u[j] > maxu) maxu = u[j]
			}

			denom = exp(0 - maxu)
			for (j=1; j<=n; j++) {
				if (j == i) continue
				denom = denom + exp(u[j] - maxu)
			}

			ebar = J(1, p, 0)
			for (j=1; j<=n; j++) {
				if (j == i) continue
				ebar = ebar + (exp(u[j]-maxu)/denom) * chgmat[j,.]
			}

			draw = runiform(1,1) * denom
			cum = exp(0 - maxu)
			choice = 0
			chosen_chg = J(1, p, 0)
			if (draw > cum) {
				for (j=1; j<=n; j++) {
					if (j == i) continue
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
	class ErgmModel scalar M, real rowvector theta, real scalar rate) {

	struct SaomCountedResult scalar res
	real scalar t, i, picked

	res.steps = 0
	res.nchanges = 0
	t = 0
	while (t < 1) {
		t = t - ln(runiform(1,1)) / (G.n * rate)
		if (t < 1) {
			i = ceil(runiform(1,1) * G.n)
			picked = SaomMinistep(G, M, theta, i)
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

/* ===================================================================
   SaomFit: result of SaomEstimateRM.
   =================================================================== */
struct SaomFit {
	real rowvector theta		// final estimated coefficients (length M.nparam())
	real rowvector tratio		// phase-3 convergence t-ratio per eval parameter
	real scalar rate		// jointly-estimated rate parameter (harmonisation unit 8) - ONLY populated by SaomEstimateRM() (exactly-two-wave path)
	real scalar rate_tratio		// phase-3 convergence t-ratio for the rate parameter's own moment - ONLY populated by SaomEstimateRM()
	real matrix theta_path		// phase-2 subphase-end eval-theta history (nsub x nparam), for diagnostics
	real rowvector rates		// harmonisation unit 17 - ONE rate per inter-wave period, ONLY populated by SaomEstimateRMMulti() (2+ wave path); real RSiena's own convention confirmed by direct 3-wave cross-check (see docs/SAOM_ROADMAP.md) - theta is POOLED/shared across periods, rate is period-specific
	real rowvector rate_tratios	// harmonisation unit 17 - phase-3 convergence t-ratio per period's own rate moment, ONLY populated by SaomEstimateRMMulti()
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
   starting value (~14% - a real, further RM-driven refinement this unit
   did not chase down, given the two rejected attempts above already
   spent considerable budget establishing what does NOT work); shipping
   the verified closed form is a strictly better, safer choice than
   either rejected iterative scheme, both of which landed FURTHER from
   the true value than this simple formula does. Tracked as a smaller,
   disclosed remaining gap in docs/SAOM_ROADMAP.md.
   =================================================================== */
struct SaomFit scalar SaomEstimateRM(class ErgmGraph scalar Gobs_start,
	class ErgmGraph scalar Gobs_end, class ErgmModel scalar M,
	real rowvector theta0, real scalar rate0,
	real scalar K0, real scalar K3, real scalar firstg) {

	struct SaomFit scalar fit
	struct SaomNativeConfig scalar cfg
	struct SaomScoredResult scalar sres
	struct SaomCountedResult scalar cres
	class ErgmGraph scalar Gwork
	real rowvector target, theta, dev, prevdev, prod0, prod1, ac, stdcap
	real rowvector thav, fchange, changestep
	real matrix Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3
	real matrix Zsco3, Ddev3, Dsco3, Dhat3, Dinv3	// harmonisation unit 18
	real scalar p, k, use_native, targetRate, ratecur, nch
	real scalar nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real rowvector n2minimum, n2maximum
	real matrix theta_hist
	real colvector rate_hist

	p = M.nparam()
	target = M.full_statistic(Gobs_end)
	targetRate = SaomCountDiffering(Gobs_start, Gobs_end)

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
	ratecur = Gobs_start.n * (0.2 + 2*targetRate) / (Gobs_start.n*(Gobs_start.n-1) + 1)

	// --- native (C) backend dispatch, decided ONCE per model, never
	// inside a loop - see docs/SAOM_ARCHITECTURE.md's "Native backend"
	// section.
	cfg = SaomNativeSetup(M)
	use_native = cfg.eligible & SaomNativeAvailable()

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
			sres = SaomSimulateIntervalScored(Gwork, M, theta0, ratecur)
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
				cres = SaomSimulateIntervalCounted(Gwork, M, theta, ratecur)
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
			sres = SaomSimulateIntervalScored(Gwork, M, fit.theta, fit.rate)
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
	real scalar firstg) {

	struct SaomFit scalar fit
	struct SaomNativeConfig scalar cfg
	struct SaomScoredResult scalar sres
	struct SaomCountedResult scalar cres
	class ErgmGraph scalar Gwork, Gp, Gpend
	real matrix target, Zdev, Zsco, Ddev, Dsco, Dhat, temp, Dinv, msf, sfinvcov, Zphase3, rate_hist
	real matrix Zsco3, Ddev3, Dsco3, Dhat3, Dinv3	// harmonisation unit 18
	real rowvector theta, dev, devp, prevdev, prod0, prod1, ac, stdcap
	real rowvector thav, fchange, changestep, ratecur, targetRate
	real scalar p, k, pd, nwaves, nperiods, use_native, nch
	real scalar nsub, subphase, gain, reduceg, n2min0, maxRatio, thavn, nit, maxacor
	real rowvector n2minimum, n2maximum
	real matrix theta_hist

	nwaves = cols(Gwaves)
	nperiods = nwaves - 1
	p = M.nparam()

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
		// per period rather than assumed).
		ratecur[pd] = Gp.n * (0.2 + 2*targetRate[pd]) / (Gp.n*(Gp.n-1) + 1)
	}

	cfg = SaomNativeSetup(M)
	use_native = cfg.eligible & SaomNativeAvailable()

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
				sres = SaomSimulateIntervalScored(Gwork, M, theta0, ratecur[pd])
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
					cres = SaomSimulateIntervalCounted(Gwork, M, theta, ratecur[pd])
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
				sres = SaomSimulateIntervalScored(Gwork, M, fit.theta, fit.rates[pd])
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
