/*
	unw_dynam.do -- native Dynamic Network Actor Model (DyNAM) estimation
	core for nwcommands (nwdynam).

	See docs/DYNAM_ROADMAP.md (scope/status) - a deliberately SEPARATE
	engine from unw_rem.do, matching that document's own "why
	architecturally distinct" reasoning: DyNAM factors the relational-
	event likelihood into a rate sub-model (who acts, and when) and a
	choice sub-model (given the sender, whom they choose - a
	conditional/multinomial logit, implemented as Unit 1).

	CORRECTION (found empirically while deriving Unit 2, the rate
	sub-model - see dev/dynam_unit2_rate_toy_crosscheck.R): this file's
	own Unit 1 header originally characterized the rate sub-model as
	necessarily "a genuine continuous-time competing-risks hazard...
	architecturally different from this package's own ordinal-partial-
	likelihood convention." That is only true of goldfish's own
	WITH-INTERCEPT rate model (its own teaching1.Rmd vignette's real
	waiting-time discussion, e.g. "an intercept of -14 means a waiting
	time of 334 hours," is specifically about that variant). The
	NO-intercept rate model - verified directly against goldfish's own
	numeric output on both a hand-traceable 3-actor/4-event toy example
	and the real Social_Evolution dataset, matching to full double
	precision - turns out to be EXACTLY the same ordinal partial
	likelihood (Cox-style, no real time values used at all) as
	unw_rem.do's own rem_loglik_grad_unit1() and this file's own choice
	sub-model, just with a different risk set (all n actors, competing
	to be the next SENDER) and different predictors (indeg/outdeg, ego
	type - an actor's own degree, not a candidate's). The genuinely
	harder, real-continuous-time-hazard variant remains an explicitly
	deferred future extension (WITH an intercept term) - not the entire
	rate sub-model, as originally scoped.

	Clean-room implementation against the published DyNAM statistical
	framework (Stadtfeld, C., Block, P. (2017). "Interactions, Actors,
	and Time: Dynamic Network Actor Models for Relational Events."
	Sociological Science 4, 318-352) and this project's own
	dev/dynam_unit1_crosscheck.R, which records the exact effect
	definitions and reference coefficients read DIRECTLY from the
	`goldfish` R package's own installed documentation
	(doc/goldfishEffects.Rmd) and fit on its own bundled Social_Evolution
	dataset - never copied from goldfish's source code (goldfish is
	GPL (>= 3), not a licensing concern, but this project's own
	established practice, matching docs/REM_PROVENANCE.md's precedent
	for nwrem/relevent, is independent derivation verified against
	documented behavior, not transcription).

	Sourced live during development (`do unw_dynam.do`), matching
	unw_rem.do's/unw_saom.do's own convention - not yet compiled into
	lib/lnwcommands.mlib (see REM_ROADMAP.md's "one rebuild at the end,
	not mid-flight" rule, followed here too).

	SCOPE (v1 - see docs/DYNAM_ROADMAP.md for the full disclosure):
	- Unit 1 (choice sub-model): three effects (inertia, recip,
	  indeg-alter), all UNWEIGHTED/binary (goldfish's own
	  weighted=FALSE default).
	- Unit 2 (rate sub-model, NO intercept): two effects (indeg-ego,
	  outdeg-ego), same ordinal-partial-likelihood convention as Unit 1
	  and unw_rem.do, just over the full n-actor sender risk set.
	Both units: directed networks only, full risk set (every actor
	always eligible - no composition change/eligibility restriction
	modeling yet). The WITH-INTERCEPT rate model (a genuine
	continuous-time hazard on real inter-event waiting times - see this
	file's own CORRECTION comment above) remains explicitly deferred,
	not silently unsupported - nwdynam.ado rejects an intercept request
	with a clear error rather than pretending to fit it.

	EFFECT SELECTION (added 2026-09-02, docs/DYNAM_ROADMAP.md's own
	"effect selection" scope item - the FIRST of the two items grouped
	under "effect selection/expansion" there; NEW effect families
	beyond these five - same/diff/sim/tertius/closure effects from
	goldfish's own wider catalog - remain the separate, not-yet-started
	"expansion" half, deliberately out of scope here) - matching
	unw_rem.do's own units-2-5 precedent EXACTLY: rem_loglik_grad_unit1()/
	RemFitUnit1() were kept untouched and rem_loglik_grad_multi()/
	RemFitMulti() added ALONGSIDE them as a generalized, selectable
	engine, rather than rewriting the already-verified unit-1 functions
	in place. The same pattern here: dynam_choice_loglik_grad_unit1()/
	DynamFitUnit1() (and their native-backed counterparts) are UNCHANGED
	- still always fit all three choice effects, still eligible for
	native acceleration - and dynam_choice_loglik_grad_multi()/
	DynamChoiceFitMulti() (Mata-only, no native backend yet - a real,
	disclosed follow-on, matching REM's own units-2-5 arc which also
	shipped Mata-first with no native backend at all to this day) are
	added for genuine SUBSET selection. nwdynam.ado dispatches to
	whichever is actually needed: the full-effect-set case (the
	original, still-default behavior) keeps its native speed path;
	requesting a proper subset uses the new Mata-only multi engine.
*/

capture mata: mata drop DynamState()
capture mata: mata drop DynamFitUnit1()
capture mata: mata drop dynam_choice_loglik_unit1()
capture mata: mata drop dynam_choice_eval_unit1()
capture mata: mata drop DynamFitRateUnit1()
capture mata: mata drop dynam_rate_loglik_unit1()
capture mata: mata drop dynam_rate_eval_unit1()
capture mata: mata drop DynamNativePluginFilename()
capture mata: mata drop DynamNativePluginSubdir()
capture mata: mata drop DynamNativePluginPath()
capture mata: mata drop DynamNativeAvailable()
capture mata: mata drop dynam_choice_eval_unit1_native()
capture mata: mata drop dynam_rate_eval_unit1_native()
capture mata: mata drop dynam_choice_loglik_grad_multi()
capture mata: mata drop dynam_choice_loglik_multi()
capture mata: mata drop dynam_choice_eval_multi()
capture mata: mata drop DynamChoiceFitMulti()
capture mata: mata drop dynam_rate_loglik_grad_multi()
capture mata: mata drop dynam_rate_loglik_multi()
capture mata: mata drop dynam_rate_eval_multi()
capture mata: mata drop DynamRateFitMulti()

mata:
mata set matastrict off

/*
	DynamState -- the sorted event stream. Deliberately simpler than
	unw_rem.do's own RemState (no cumulative degree accumulator
	matrices precomputed up front) - the choice sub-model's own three
	v1 effects are all functions of a single incrementally-maintained
	BINARY tie matrix (see dynam_choice_loglik_grad_unit1() below), not
	of raw per-actor event counts the way REM's NODSnd/NIDRec are, so
	there is nothing analogous to build_degree_accumulators() to
	precompute here.
*/
class DynamState {
	real matrix events     // nevents x 3: (sender, receiver, time), SORTED ascending by time
	real scalar n          // number of actors
	real scalar nevents

	void init()
}

void DynamState::init(real matrix rawevents, real scalar nn) {
	real colvector ord
	real scalar k

	// Matching unw_rem.do's own RemState::init() self-loop rejection -
	// DyNAM's choice sub-model risk set is defined over i != j
	// candidate receivers only (a sender cannot choose itself), so a
	// self-loop event has no well-defined receiver-set position and
	// must be rejected outright, not silently dropped.
	for (k=1; k<=rows(rawevents); k++) {
		if (rawevents[k,1] == rawevents[k,2]) {
			_error("nwdynam: event " + strofreal(k) + " has sender == receiver (self-loop); DyNAM's choice sub-model is defined over i != j dyads only.")
		}
	}

	n = nn
	// get_eventlist() makes no ordering guarantee (see unw_rem.do's own
	// RemState::init() comment, verified there by reading
	// unw_core.do's nwattime_slice_event()) - the choice sub-model's
	// own incrementally-updated tie matrix requires chronological
	// order.
	ord = order(rawevents[.,3], 1)
	events = rawevents[ord,.]
	nevents = rows(events)
}

/*
	Native (C) plugin dispatch (native/dynam_sim.c) - own dedicated
	functions, mirroring unw_ergm.do's own ErgmNative* pattern (a single
	plugin serving one command's own engine) rather than unw_core.do's
	shared NativeGraph* dispatcher (which serves several graph-algorithm
	commands sharing one plugin) - DyNAM is its own third/fourth engine,
	same "why a separate engine" reasoning docs/DYNAM_ROADMAP.md already
	gives for keeping unw_dynam.do independent of unw_rem.do.

	UNLIKE ergm_mcmc.c/saom_sim.c (a full sampling/simulation loop lives
	entirely in C, called once per outer MCMC-step/ministep from Mata),
	dynam_sim.c accelerates only the log-likelihood/gradient EVALUATION
	at a given theta - Mata's own optimize() still drives the outer
	BFGS/Nelder-Mead loop unchanged (see dynam_sim.c's own header for
	why: reimplementing an optimizer in C is a real, avoidable risk this
	design does not need to take). `DynamNativeAvailable()` below
	follows the exact same "return 0, never error, caller falls back to
	Mata" contract as `ErgmNativeAvailable()`/`NativeGraphAvailable()`.

	TWO genuinely different lookup strategies are needed (harmonisation
	2026-09-02, docs/CERTIFICATION.md), tried in order:
	 (1) `findfile()` on the platform-specific basename alone - what
	     actually finds the plugin after a real `net install`, which
	     flattens every package "f" line into
	     PLUS/<firstletter-of-basename>/<basename>, discarding any
	     declared subdirectory entirely (verified directly by installing
	     a real test package into a scratch PLUS directory). Distinct
	     per-platform basenames (macOS and Windows used to share the
	     bare "dynam_sim.plugin" name; only Unix had its own "_unix"
	     suffix) are exactly what let this same flat PLUS folder hold
	     all three platforms' binaries at once without collision.
	 (2) a manually-constructed path relative to nwdynam.ado's own
	     directory, `lib/plugins/<os>/<name>' - unreachable after a real
	     net install (per (1) above, since net install has no
	     subdirectory concept at all) but still needed for a raw git
	     checkout (`adopath ++ <repo-root>`, this project's own
	     dev-mode/regression-testing convention): `findfile()` does not
	     search subdirectories of a plain adopath entry (confirmed
	     directly - only PLUS's own single-letter-subfolder convention
	     gets that treatment), so the nested lib/plugins/<os>/ layout
	     the repo itself uses is invisible to strategy (1) alone.
*/
string scalar DynamNativePluginFilename(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("dynam_sim_windows.plugin")
	if (os == "Unix") return("dynam_sim_unix.plugin")
	return("dynam_sim_macos.plugin")
}

string scalar DynamNativePluginSubdir(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("windows")
	if (os == "Unix") return("unix")
	return("macos")
}

string scalar DynamNativePluginPath(){
	string scalar fname, found, full, dir, fn

	fname = DynamNativePluginFilename()
	found = findfile(fname)
	if (found != "") return(found)

	full = findfile("nwdynam.ado")
	if (full == "") return("")
	pathsplit(full, dir, fn)
	return(pathjoin(pathjoin(dir, "lib"),
		pathjoin("plugins", pathjoin(DynamNativePluginSubdir(), fname))))
}

real scalar DynamNativeAvailable(){
	string scalar p

	p = DynamNativePluginPath()
	if (p == "") return(0)
	return(fileexists(p))
}

/*
	Native-backed evaluator callbacks - same (todo, theta, pS, y, g, H)
	signature `optimize()` expects as the Mata evaluators
	(dynam_choice_eval_unit1()/dynam_rate_eval_unit1() below), so either
	can be passed to `optimize_init_evaluator()` interchangeably. Assume
	the caller (DynamFitUnit1()/DynamFitRateUnit1()) has ALREADY: (1)
	switched to a temporary frame holding v1=sender/v2=receiver for all
	`(*pS).nevents` events, set up ONCE before the optimizer loop begins
	(not re-marshaled on every call - a plugin invocation carries no
	state between calls, but the SAME already-populated input frame
	stays current across every one of these calls throughout the fit,
	matching dynam_sim.c's own header comment); (2) already issued
	`capture program dynamnative, plugin using(...)` once. Each call
	here passes only the few theta values that actually change call to
	call, at full double precision (`%25.17g`, matching
	unw_saom.do's own established convention for passing real-valued
	optimizer parameters into a native plugin - NOT `strofreal()`'s own
	lower-precision default format, which would silently degrade BFGS's
	own convergence precision).
*/
void dynam_choice_eval_unit1_native(real scalar todo, real rowvector theta, pointer(class DynamState scalar) scalar pS,
		real scalar y, real rowvector g, real matrix H) {
	string scalar argstr
	real matrix res

	argstr = strofreal(1) + " " + strofreal((*pS).n) + " " + strofreal((*pS).nevents) + " " + strofreal(theta[1], "%25.17g") + " " + strofreal(theta[2], "%25.17g") + " " + strofreal(theta[3], "%25.17g")
	stata("plugin call dynamnative v1 v2 v3, " + char(34) + argstr + char(34))
	res = st_data((1::4), "v3")
	y = res[1,1]
	if (todo >= 1) g = res[2::4,1]'
}

void dynam_rate_eval_unit1_native(real scalar todo, real rowvector theta, pointer(class DynamState scalar) scalar pS,
		real scalar y, real rowvector g, real matrix H) {
	string scalar argstr
	real matrix res

	argstr = strofreal(2) + " " + strofreal((*pS).n) + " " + strofreal((*pS).nevents) + " " + strofreal(theta[1], "%25.17g") + " " + strofreal(theta[2], "%25.17g")
	stata("plugin call dynamnative v1 v2 v3, " + char(34) + argstr + char(34))
	res = st_data((1::3), "v3")
	y = res[1,1]
	if (todo >= 1) g = res[2::3,1]'
}

/*
	DyNAM choice sub-model, v1 Unit 1: inertia + recip + indeg(alter),
	all unweighted/binary - three effect definitions read DIRECTLY from
	goldfish's own doc/goldfishEffects.Rmd (not guessed, not copied -
	see dev/dynam_unit1_crosscheck.R for the exact passages and the
	live R fit this was checked against):

	  inertia(s,j) = I(tie[s,j] > 0)   -- has s EVER sent to j before now?
	  recip(s,j)   = I(tie[j,s] > 0)   -- has j EVER sent to s before now?
	  indeg(j)     = colsum(tie[.,j])  -- j's own in-degree (count of
	                                       DISTINCT actors who have sent
	                                       to j before now) - "alter
	                                       type", per goldfishEffects.Rmd's
	                                       own type=c("alter","ego")
	                                       argument: the choice
	                                       sub-model always uses alter
	                                       type (candidate receiver's
	                                       own in-degree), never ego
	                                       type (that is the rate
	                                       sub-model's own use of
	                                       indeg(), not yet implemented
	                                       here)

	where tie[.,.] is a binary n x n matrix - NOT a raw event-count
	accumulator like unw_rem.do's own cij (a real, deliberate
	difference: goldfish's own default weighted=FALSE means REPEAT
	contacts do not inflate inertia/recip/indeg further, only the FIRST
	occurrence of a tie flips the corresponding cell from 0 to 1) -
	updated incrementally, STRICTLY prior to the current event (no
	lookahead), same "update AFTER using this event's own pre-event
	state" discipline as unw_rem.do's own cij/lastcontact.

	No first-event special-casing is needed (unlike unw_rem.do's own
	1/(n-1) fallback for its own degree-FRACTION effects, which divide
	by the number of prior events): tie starts all-zero, so
	inertia/recip/indeg are all simply 0 for every candidate at the
	first event - a well-defined value requiring no fallback branch,
	since these are counts/indicators, not fractions with an undefined
	0/0 at i=1.

	Risk set for event i: sender s_i is taken directly from the DATA
	(not modeled - that is the separate, not-yet-built rate sub-model,
	see this file's own header comment and docs/DYNAM_ROADMAP.md).
	Every other actor j != s_i is a candidate receiver - a standard
	conditional (multinomial) logit over n-1 candidates, structurally
	the same softmax-over-risk-set machinery as unw_rem.do's own
	rem_loglik_grad_unit1(), but the risk set here is exactly ONE row
	(s_i's own row of a full n x n log-rate matrix), not the full n x n
	dyad space at once, since the sender is conditioned on rather than
	competing for the event itself.
*/
void dynam_choice_loglik_grad_unit1(real rowvector theta, pointer(class DynamState scalar) scalar pS,
		real scalar ll, real rowvector grad) {
	real scalar i, s, r, n, mx, lrsum
	real matrix tie
	real rowvector inertia_i, recip_i, indeg_i, lp, P

	n = (*pS).n
	ll = 0
	grad = J(1, 3, 0)
	tie = J(n, n, 0)

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]

		inertia_i = tie[s,.]
		recip_i = tie[.,s]'
		indeg_i = colsum(tie)

		lp = theta[1] :* inertia_i :+ theta[2] :* recip_i :+ theta[3] :* indeg_i
		lp[s] = -1e300   // sender cannot choose itself - exclude from the risk set

		mx = max(lp)
		P = exp(lp :- mx)
		lrsum = mx + ln(sum(P))
		ll = ll + (lp[r] - lrsum)

		P = P :/ sum(P)   // proper softmax probability row over the risk set
		grad[1] = grad[1] + (inertia_i[r] - sum(inertia_i :* P))
		grad[2] = grad[2] + (recip_i[r] - sum(recip_i :* P))
		grad[3] = grad[3] + (indeg_i[r] - sum(indeg_i :* P))

		tie[s,r] = 1   // update AFTER using this event's own pre-event state
	}
}

/*
	Pure log-likelihood wrapper (no gradient) - same role as
	unw_rem.do's own rem_loglik_unit1(), used by certification
	tests/diagnostics that only need the ll value at a given theta.
*/
real scalar dynam_choice_loglik_unit1(real rowvector theta, pointer(class DynamState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	dynam_choice_loglik_grad_unit1(theta, pS, ll, grad)
	return(ll)
}

void dynam_choice_eval_unit1(real scalar todo, real rowvector theta, pointer(class DynamState scalar) scalar pS,
		real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	dynam_choice_loglik_grad_unit1(theta, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	DynamFitUnit1() -- fits the v1 Unit 1 choice sub-model (inertia +
	recip + indeg, no selection - all three always active, matching
	unw_rem.do's own rem_loglik_grad_unit1()/RemFitUnit1() precedent of
	a hardcoded small effect set before a later unit generalizes to a
	selectable multi-effect design, see docs/DYNAM_ROADMAP.md's own
	scope note). Same retry-with-escalating-perturbation-then-
	Nelder-Mead robustness strategy as RemFitUnit1() - see that
	function's own comment for why (avoiding optimize()'s "flat region
	encountered" failure at a too-symmetric starting point).
*/
void DynamFitUnit1(real matrix eventmat, real scalar n, string scalar bname, string scalar vname, string scalar llname) {
	class DynamState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat
	real matrix V
	real scalar attempt, ok, errcode, usenative, nobs_needed, __junk
	real matrix starts
	string scalar origframe
	pointer(void) scalar evalfunc

	S = DynamState()
	S.init(eventmat, n)

	// See this file's own DynamNativeAvailable() comment: falls back to
	// the pure-Mata evaluator transparently (never errors) on any
	// platform lacking a built dynam_sim plugin.
	usenative = DynamNativeAvailable()
	if (usenative) {
		origframe = st_framecurrent()
		stata("capture frame drop __nwdynam_native")
		stata("frame create __nwdynam_native")
		st_framecurrent("__nwdynam_native")
		nobs_needed = max((S.nevents, 4))
		st_addobs(nobs_needed)
		__junk = st_addvar("double", "v1")
		__junk = st_addvar("double", "v2")
		__junk = st_addvar("double", "v3")
		st_store((1::S.nevents), ("v1","v2"), S.events[.,(1,2)])
		// See unw_ergm.do's ErgmNativeSampleCore()'s own identical
		// comment on why redefining an already-loaded plugin-type
		// program is left in place rather than dropped first.
		stata("capture program dynamnative, plugin using(" + char(34) + DynamNativePluginPath() + char(34) + ")")
		evalfunc = &dynam_choice_eval_unit1_native()
	}
	else {
		evalfunc = &dynam_choice_eval_unit1()
	}

	starts = (0.01,0.01,0.01 \ 0.3,-0.3,0.1 \ -0.3,0.3,-0.1 \ 1,-1,0.5)
	ok = 0
	for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, evalfunc)
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 60)
		errcode = _optimize(S_opt)
		if (errcode == 0) {
			theta_hat = optimize_result_params(S_opt)
			ok = 1
		}
	}
	if (ok == 0) {
		// Last resort: derivative-free Nelder-Mead, same rationale as
		// RemFitUnit1()'s own fallback.
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, evalfunc)
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, (0.01,0.01,0.01))
		optimize_init_argument(S_opt, 1, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 300)
		theta_hat = optimize(S_opt)
	}
	V = optimize_result_V_oim(S_opt)

	if (usenative) {
		st_framecurrent(origframe)
		stata("capture frame drop __nwdynam_native")
	}

	st_matrix(bname, theta_hat)
	st_matrix(vname, V)
	st_numscalar(llname, optimize_result_value(S_opt))
}

/*
	DyNAM rate sub-model, Unit 2, NO-intercept case: indeg + outdeg,
	both "ego" type (an actor's OWN in/out degree - count of DISTINCT
	partners, unweighted - see this file's own header CORRECTION
	comment for how this formula was found, and dynam_choice_loglik_grad_unit1()'s
	own comment for why binary tie-presence rather than a raw event
	count is the right structure, same reasoning applies here).

	Risk set for event k: ALL n actors compete to be the next sender -
	unlike the choice sub-model (whose risk set is one already-known
	sender's own row, n-1 candidates), here every actor including the
	eventual non-senders is a candidate, so no "exclude self" step is
	needed (there is no "self" to exclude - the realized sender IS one
	of the n candidates, not compared against itself).

	  indeg_ego(i)  = colsum(tie[.,i])   -- count of distinct actors who have sent TO i before now
	  outdeg_ego(i) = rowsum(tie[i,.])   -- count of distinct actors i has sent TO before now

	ll_k = lp[s_k] - log(sum_i exp(lp[i]))   where lp[i] = theta[1]*indeg_ego(i) + theta[2]*outdeg_ego(i)

	Same incremental binary tie-matrix update as the choice sub-model
	("update AFTER using this event's own pre-event state") - in fact
	the exact same tie matrix, if both sub-models were ever fit
	together in one pass; kept as two independent functions here
	(matching goldfish's own separately-callable subModel="rate"/
	subModel="choice", and this file's own "two conditionally
	independent sub-models" framing) rather than sharing state across
	calls, since a caller may want either one alone.
*/
void dynam_rate_loglik_grad_unit1(real rowvector theta, pointer(class DynamState scalar) scalar pS,
		real scalar ll, real rowvector grad) {
	real scalar i, s, r, n, mx, lrsum
	real matrix tie
	real rowvector indeg_i, outdeg_i, lp, P

	n = (*pS).n
	ll = 0
	grad = J(1, 2, 0)
	tie = J(n, n, 0)

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]

		indeg_i = colsum(tie :> 0)
		outdeg_i = rowsum(tie :> 0)'

		lp = theta[1] :* indeg_i :+ theta[2] :* outdeg_i

		mx = max(lp)
		P = exp(lp :- mx)
		lrsum = mx + ln(sum(P))
		ll = ll + (lp[s] - lrsum)

		P = P :/ sum(P)   // proper softmax probability row over the risk set (all n actors)
		grad[1] = grad[1] + (indeg_i[s] - sum(indeg_i :* P))
		grad[2] = grad[2] + (outdeg_i[s] - sum(outdeg_i :* P))

		tie[s,r] = 1   // update AFTER using this event's own pre-event state
	}
}

real scalar dynam_rate_loglik_unit1(real rowvector theta, pointer(class DynamState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	dynam_rate_loglik_grad_unit1(theta, pS, ll, grad)
	return(ll)
}

void dynam_rate_eval_unit1(real scalar todo, real rowvector theta, pointer(class DynamState scalar) scalar pS,
		real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	dynam_rate_loglik_grad_unit1(theta, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	DynamFitRateUnit1() -- fits the Unit 2 (rate, no-intercept) model.
	Same retry-with-escalating-perturbation-then-Nelder-Mead robustness
	strategy as DynamFitUnit1()/RemFitUnit1().
*/
void DynamFitRateUnit1(real matrix eventmat, real scalar n, string scalar bname, string scalar vname, string scalar llname) {
	class DynamState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat
	real matrix V
	real scalar attempt, ok, errcode, usenative, nobs_needed, __junk
	real matrix starts
	string scalar origframe
	pointer(void) scalar evalfunc

	S = DynamState()
	S.init(eventmat, n)

	usenative = DynamNativeAvailable()
	if (usenative) {
		origframe = st_framecurrent()
		stata("capture frame drop __nwdynam_native")
		stata("frame create __nwdynam_native")
		st_framecurrent("__nwdynam_native")
		nobs_needed = max((S.nevents, 3))
		st_addobs(nobs_needed)
		__junk = st_addvar("double", "v1")
		__junk = st_addvar("double", "v2")
		__junk = st_addvar("double", "v3")
		st_store((1::S.nevents), ("v1","v2"), S.events[.,(1,2)])
		stata("capture program dynamnative, plugin using(" + char(34) + DynamNativePluginPath() + char(34) + ")")
		evalfunc = &dynam_rate_eval_unit1_native()
	}
	else {
		evalfunc = &dynam_rate_eval_unit1()
	}

	starts = (0.01,0.01 \ 0.3,-0.3 \ -0.3,0.3 \ 1,-1)
	ok = 0
	for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, evalfunc)
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 60)
		errcode = _optimize(S_opt)
		if (errcode == 0) {
			theta_hat = optimize_result_params(S_opt)
			ok = 1
		}
	}
	if (ok == 0) {
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, evalfunc)
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, (0.01,0.01))
		optimize_init_argument(S_opt, 1, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 300)
		theta_hat = optimize(S_opt)
	}
	V = optimize_result_V_oim(S_opt)

	if (usenative) {
		st_framecurrent(origframe)
		stata("capture frame drop __nwdynam_native")
	}

	st_matrix(bname, theta_hat)
	st_matrix(vname, V)
	st_numscalar(llname, optimize_result_value(S_opt))
}

/*
	Choice sub-model, generalized/selectable engine (docs/DYNAM_ROADMAP.md's
	"effect selection" scope item - see this file's own header comment
	for how this relates to dynam_choice_loglik_grad_unit1() above).
	`active` is a 6-element 0/1 rowvector, fixed order (1=inertia,
	2=recip, 3=indeg, 4=same, 5=diff, 6=sim - the first three matching
	dynam_choice_loglik_grad_unit1()'s own effect order exactly; effects
	4-6 added 2026-09-02, "effect EXPANSION" - see this function's own
	header note below) - theta has sum(active) elements, in that same
	relative order. Effects 1-3: otherwise identical math to the unit-1
	function (same tie-matrix bookkeeping, same colsum(tie) computation
	of indeg_i - NOT the native port's own incremental-count
	optimization, since this is the MATA REFERENCE and should stay in
	the same form already verified against goldfish, not silently
	re-derive a different-but-equivalent formulation here too).

	Effects 4-6 (same/diff/sim - docs/DYNAM_ROADMAP.md's "effect
	expansion" scope item, formulas read directly from goldfish's own
	doc/goldfishEffects.Rmd, not guessed): static per-actor ATTRIBUTE
	effects, not structural ones - a candidate's own value never changes
	across the fit, so (unlike inertia/recip/indeg) these need no
	incremental per-event state at all, just the sender's OWN attribute
	value broadcast against every candidate's:
	  same(s,j) = I(z_s = z_j)     -- homophily (same value)
	  diff(s,j) = |z_s - z_j|      -- heterophily (absolute difference)
	  sim(s,j)  = -|z_s - z_j|     -- homophily (similar value) - EXACTLY
	              -diff, by construction (goldfish's own documented
	              relationship, confirmed empirically: sim's coefficient
	              is diff's own coefficient with the sign flipped, same
	              |value|, same SE, same logLik - see
	              dev/dynam_unit4_attreffects_crosscheck.do). REAL
	              CONSEQUENCE, found while writing cscripts/test_nwdynam_ado.do:
	              diff() and sim() on the SAME variable are perfectly
	              collinear (one is an exact linear function of the
	              other), so a joint model including both is genuinely
	              UNIDENTIFIED - only the difference of their two
	              coefficients is estimable, not each separately. This
	              surfaced as a real optimizer failure ("flat region
	              encountered" / "simplex delta required"), not a
	              convergence-tuning problem to engineer around - using
	              two DIFFERENT variables for diff() and sim() together
	              is fine (they are then genuinely different dyadic
	              quantities); nwdynam.ado does not detect or reject the
	              same-variable case automatically (matching this
	              package's own general stance of not second-guessing
	              genuinely valid model specifications - a user might
	              deliberately want this contrast tested and hit the
	              expected non-identification directly).
	`same`/`diff`/`sim` each read from their OWN independent covariate
	vector (samevec/diffvec/simvec - NOT forced to share one variable,
	matching unw_rem.do's own covsndvec/covrecvec/covintvec convention
	of independent per-effect covariates - a real model may want a
	different variable for each). Static only, matching unw_rem.do's own
	v1 covariate scope (unit 4a). goldfish's own effect table confirms
	these apply to the CHOICE (and choice_coordination) sub-model only,
	never rate - no rate-side counterpart exists, matching
	dynam_rate_loglik_grad_multi()'s own unchanged 2-effect scope.

	Effect 7 (alter - "expansion batch 2", added 2026-09-02): the
	simplest possible attribute effect, per goldfish's own
	doc/goldfishEffects.Rmd - `s(i,j,t,z) = z_j`, the candidate
	receiver's OWN static covariate value, broadcast directly with no
	comparison to the sender at all (unlike same/diff/sim, which are
	genuinely dyadic). goldfish's own table confirms `alter` is
	choice-sub-model-only (never rate) - its rate-side counterpart is
	`ego` (effect 3 of dynam_rate_loglik_grad_multi() below, `r(i,t,z) =
	z_i`), a DIFFERENT effect name for what is really the same
	"static per-actor level" idea applied to the opposite sub-model's
	own risk-set role (candidate receiver vs. candidate sender) -
	matching goldfish's own naming exactly, not invented here.

	`windowinertia`/`windowrecip` ("effect expansion batch 3, added
	2026-09-02, user request "implement window effects," REDESIGNED
	same day as a per-effect suboption after user follow-up "check our
	goldfish syntax... make window a suboption of the effects... control
	this per effect" - `nwdynam.ado`'s own comment has the full account
	of why a single shared window scalar was replaced with two
	independent ones): a real-time recency cutoff on `inertia`/`recip`
	INDEPENDENTLY (goldfish's own `window=` argument is per-effect, not
	shared across a whole model - `inertia(net, window="7 days")` and
	`recip(net, window="1 day")` can genuinely differ in the same
	goldfish formula, and this engine now matches that exactly, not an
	earlier single-shared-window approximation of it). `indeg`/`outdeg`/
	`ego`/`alter` remain UNWINDOWED in this batch, a real, disclosed
	scope limit, not silently extended to match. >=1e300 means "no
	window" for that specific effect (the original always-sticky
	behavior, bit-identical to before this batch - see below); any
	finite value activates real-time filtering for THAT effect only.
	Formula, derived empirically and verified against real goldfish (not
	guessed - see dev/dynam_unit6_window_crosscheck.do and its own
	header comment for the toy-example-first derivation this project's
	own established discipline requires): a tie i->j counts as PRESENT
	at the current event's own evaluation time if and only if the MOST
	RECENT prior i->j event happened within that effect's own window of
	the current event's own timestamp (inclusive: `t_current -
	t_lastcontact <= window`) - NOT a decaying weight, a hard cutoff; a
	tie can EXPIRE (revert to absent) once its own most recent contact
	falls outside the window, even though it was present a moment
	before. This is a REAL DEPARTURE from every other effect in this
	file: the ordinal partial likelihood itself still uses only event
	ORDER (this file's own CORRECTION comment on the rate sub-model's
	own no-intercept case still holds - no waiting-time HAZARD term
	enters the likelihood), but window-eligible STATISTICS now read real
	elapsed time as a FILTER on which historical events still count,
	which the engine previously never touched at all -
	`(*pS).events[.,3]` (the time column DynamState already carries but
	effects 1-7 above never read) is used here for the first time.

	Implementation: the previous binary `tie` matrix is replaced by
	`lastcontact` (real time of the most recent i->j event, sentinel
	-1e300 for "never" - matching this file's own -1e300
	risk-set-exclusion sentinel convention). When both windows are
	inactive, `lastcontact[s,.] :> -1e300` reproduces the OLD `tie[s,.]`
	binary presence check exactly (bit-identical - verified directly,
	not merely argued, via dev/dynam_unit6_window_crosscheck.do's own
	regression check against the pre-window numbers); `indeg` (still
	unwindowed) is likewise derived from `lastcontact :> -1e300` rather
	than a separately-maintained matrix, so only ONE tracking structure
	is kept, not three redundant ones.

	Effect 8 (outdeg, "expansion batch 5", added 2026-09-02, user
	report that the help file's own "outdeg: rate sub-model only" label
	was checked against goldfish's own doc/goldfishEffects.Rmd and found
	WRONG - goldfish's own "Structural Effects" table lists outdeg as
	valid for BOTH rate and choice, not rate-only; this was a genuine
	missing effect, not a correct scope restriction): the choice
	sub-model's own "alter type" outdegree, `s(i,j,t,x) = sum_l
	I(x(t)_jl>0)` per goldfish's own doc - candidate j's own out-degree
	(how many distinct receivers j has themselves contacted), broadcast
	with no comparison to the sender, mirroring `indeg`'s own "alter
	type" shape exactly but transposed (`indeg` sums lastcontact's own
	COLUMN j - who has contacted j; `outdeg` sums its own ROW j - who j
	has contacted). Reuses the SAME `lastcontact` matrix already
	maintained for `inertia`/`recip`/`indeg` - no new tracking structure
	needed. Verified against real goldfish - see
	dev/dynam_unit8_choiceoutdeg_crosscheck.do. UNWINDOWED in this batch
	(matching `indeg`'s own still-unwindowed choice-side status,
	disclosed above) - a real, disclosed scope limit for a future batch,
	not silently extended to match `outdegwindow()`'s own existing
	RATE-side-only scope.

	The user separately asked, in the same exchange, whether
	`inertia`/`recip`/`same`/`diff`/`sim` (the OTHER effects the help
	file marks choice-only) could likewise be added to the rate
	sub-model. They cannot, and this is a structural fact about
	goldfish's own two sub-models, not an arbitrary scope choice:
	`inertia`/`recip`/`same`/`diff`/`sim` are all genuinely DYADIC
	statistics `s(i,j,t,x)` comparing a specific SENDER i against a
	specific CANDIDATE RECEIVER j (e.g. `recip`: does j have a recent
	tie back to i; `same`: do i and j share a covariate level) - the
	rate sub-model's own `r(i,t,x)` has no receiver role at all (it is a
	single-actor hazard over who acts next), so a dyadic comparison has
	no argument to compare i against. `indeg`/`outdeg` are the exception
	precisely because they are NOT dyadic - each is a property of a
	SINGLE actor (in-degree or out-degree), expressible identically
	whether that actor is playing the rate sub-model's own "candidate
	sender" role or the choice sub-model's own "candidate receiver"
	role. `alter`'s own single-actor analogue already exists under
	goldfish's own different name for the rate sub-model - `ego` (effect
	3 of dynam_rate_loglik_grad_multi() below) - so there is no missing
	"alter for rate" to add either; it was already implemented under its
	goldfish-given name in expansion batch 2.

	Effects 9-14 ("expansion batch 6", added 2026-09-02, user: "work
	your way through the list" - a systematic audit against goldfish's
	FULL effect catalog, not just the ones already covered): the
	two-path closure effects (`trans`, `cycle`, `commonSender`,
	`commonReceiver`, `four`) and `nodeTrans`, per goldfish's own
	doc/goldfishEffects.Rmd formulas, computed on the DEPENDENT network
	itself (goldfish's own stated default when no explicit network
	argument is given - "For network effects, this would be either an
	explanatory network or the dependent network (the default)"). Using
	an EXOGENOUS network instead (goldfish's own `trans(othernet)`, or
	the two-network `mixedTrans`/`mixedCycle`/`mixedCommonSender`/
	`mixedCommonReceiver` variants) is a real, disclosed scope limit for
	a future batch - nwdynam has no mechanism yet for an effect to read
	a network other than the one being predicted.

	All five closure effects are two-path counts over the SAME binary
	presence matrix `A` (`lastcontact :> -1e300`, reusing the existing
	tracking structure exactly like `indeg`/`outdeg` already do) -
	computed via matrix products rather than a per-candidate loop, since
	each is a full ROW (or column) of a single n x n product:
	  trans_i(j)          = sum_k A[i,k]A[k,j]        = (A*A)[i,.]
	  cycle_i(j)           = sum_k A[j,k]A[k,i]        = (A*A)[.,i]'
	  commonSender_i(j)    = sum_k A[k,i]A[k,j]        = (A'*A)[i,.]
	  commonReceiver_i(j)  = sum_k A[i,k]A[j,k]        = (A*A')[i,.]
	  four_i(j)            = sum_kl A[i,k]A[l,k]A[l,j], k,l NOT IN {i,j}
	                           and k != l (see correction below)
	with `i` bound to the realized sender `s` at each event (each is
	genuinely dyadic - varies by candidate `j`, matching `inertia`'s own
	sender-dependent shape, not `indeg`'s own candidate-only shape).

	`four` needed a REAL correction beyond the naive matrix product,
	found by direct comparison against goldfish's own reconstructed
	statistic matrix (via `estimate(..., preprocessingOnly=TRUE)`'s own
	`dependentStatsChange` deltas), not assumed from the documented
	formula alone: the naive `(A*(A'*A))[i,.]` (matching trans/cycle/
	commonSender/commonReceiver's own pattern exactly) reproduced
	trans/cycle/commonSender/commonReceiver bit-for-bit but was
	systematically almost DOUBLE goldfish's own real `four` values and
	produced a wildly wrong fitted coefficient (1.644 vs goldfish's own
	0.897, logLik off by 660) - `four`'s own doc/goldfishEffects.Rmd
	prose ("closes more three-paths i->k<-l->j") requires i, j, k, l to
	be four GENUINELY DISTINCT actors, unlike the other four closure
	effects' own two-path formulas (which only involve 3 roles, i/j/k,
	where the existing zero-diagonal convention already excludes every
	degenerate case automatically). The closed-form correction, derived
	and verified via a small hand-traceable random toy network (n=6)
	against a full four-nested-loop brute-force distinct-actors
	computation BEFORE touching this file, then confirmed on real data
	(matching goldfish's own reconstructed statistic matrix off-diagonal
	to within rounding):
	  four_i(j) = (A*(A'*A))[i,j] - A[i,j] * (rowsum(A[i,.]) +
	              diagonal(A'*A)[j] - A[i,j])
	subtracting exactly the k=i, k=j, and l=i contributions from the
	naive sum (l=j and k=k self-loop contributions are already zero via
	the existing zero-diagonal convention, so only these three terms
	needed an explicit correction). Re-verified against real goldfish
	after the fix - see dev/dynam_unit9_closure_crosscheck.do - matching
	to within 8e-6 on the coefficient, 0.02 on logLik.
	`nodeTrans` (the one BOTH-submodel effect in this batch, per
	goldfish's own table) is different in kind: `r(i) = sum_j A[i,j] *
	(A*A)[i,j]`, a property of a SINGLE actor with no dependence on the
	realized sender at all (matching `indeg`/`outdeg`'s own
	candidate-only shape, computed once per event as `rowsum(A :* (A*A))`
	and reused directly for every candidate/actor).
	`A*A`/`A'*A`/`A*A'` are each computed CONDITIONALLY, only when an
	effect that needs them is active (`needAA`/`needAtA`/`needAAt`), to
	avoid the O(n^3) matrix-multiply cost when none of these 6 effects
	are requested - every other existing effect remains exactly as cheap
	as before this batch. UNWINDOWED in this batch, a real disclosed
	scope limit (goldfish's own table shows `window` IS valid on these
	effects; matching the already-disclosed unwindowed status of
	choice's own `indeg`, not silently extended to match). Verified
	against real goldfish on Social_Evolution - see
	dev/dynam_unit9_closure_crosscheck.R/.do, including a genuine
	multi-effect model (`inertia + recip + trans + cycle + commonSender
	+ commonReceiver` together) matching to within 0.01 on every
	coefficient. `commonReceiver` triggers a real goldfish-side
	`isTwoMode = TRUE` auto-detection WARNING (not an error) on this
	directed dataset - a goldfish-internal heuristic quirk, not caused
	by anything in nwdynam - checked directly and found NOT to change
	goldfish's own reported coefficient from what the directed,
	isTwoMode=FALSE formula above predicts (matched to within 0.001).

	Effects 15-16 ("expansion batch 7", added 2026-09-02, continuing
	"work your way through the list"): `egoAlterInt` and `tertius`, per
	goldfish's own doc/goldfishEffects.Rmd formulas.

	Effect 15 (egoAlterInt): `s(i,j,t,z1,z2) = z1_i * z2_j` - the
	SENDER's own covariate 1 value multiplied by the CANDIDATE's own
	covariate 2 value (an interaction, not a comparison - the two
	covariates can be the same variable or different ones, matching
	goldfish's own two-argument `egoAlterInt(attribute1, attribute2)`).
	Choice-only per goldfish's own table (needs both a sender role and a
	candidate-receiver role - the same structural reason `inertia`/
	`recip`/`same`/`diff`/`sim` are choice-only, see the earlier comment
	in this same header).

	Effect 16 (tertius, "alter" type for choice / "ego" type for rate -
	the SAME underlying computation reused across both engines exactly
	like `nodeTrans`, since it is a property of a single actor with no
	dependence on the realized sender): goldfish's own formula -
	`s(i,j,t,x,z) = mean_{k: x_kj>0}(z_k)` - the MEAN covariate value of
	the candidate's own in-neighbors (senders who have contacted them),
	on the DEPENDENT network itself (goldfish's own default network
	argument, matching the closure-effect batch's own scope decision).
	v1 scope, disclosed: only goldfish's own DEFAULT `aggregateFun`
	(mean) is supported - `sum`/`max`/other custom aggregation functions
	are not requestable. Computed via `tertiusnumer = tertiusvec * A`
	(matrix product: for each candidate j, sums the covariate values of
	everyone who has contacted them) and `tertiusdenom = indeg_i`
	(already computed each event, reused directly rather than a
	redundant `colsum(A)`), with an explicit `hasin' mask to avoid 0/0
	propagating as a Mata missing value.

	ISOLATE IMPUTATION - a real, documented-vs-actual discrepancy found
	by direct comparison, not trusted from the doc alone (same
	discipline as the `four()` fix above): goldfish's own doc/
	goldfishEffects.Rmd states "When a node does not have in-neighbors,
	the tertius effect is imputed as the average of the aggregate
	values of nodes with in-neighbors." Implementing that literally
	first (a `hasin'-weighted global mean of every non-isolated actor's
	own tertius value) produced a coefficient wildly different from
	real goldfish (1.153 off, logLik off by 151 on `choice ~ tertius`
	alone). `estimate(..., preprocessingOnly=TRUE)`'s own
	`dependentStatsChange` deltas were reconstructed into goldfish's own
	actual statistic matrix for BOTH sub-models (same technique as the
	`four()` investigation) and compared directly against the
	global-mean-imputed values: every non-isolated actor matched
	EXACTLY, but every isolated actor's own real value was 0, not the
	documented global mean - confirmed on both the choice (candidate
	role) and rate (single-actor role) sub-models independently, ruling
	out a submodel-specific explanation. The documented "Note" does not
	match goldfish 1.6.12's own actual runtime behavior for this
	dataset - isolates are imputed as 0, full stop, matching this
	engine's own pre-existing sentinel convention for "nothing here yet"
	elsewhere in the file. Implemented as verified, not as documented.
	Re-verified against real goldfish on Social_Evolution after the fix
	- see dev/dynam_unit10_tertius_egoalterint_crosscheck.R/.do -
	matching to within 0.01 on every coefficient, including `tertius`
	under BOTH sub-models and a genuine 3-effect combined choice model
	(`inertia + alter + egoAlterInt`).

	`n1' ("expansion batch 9", two-mode/bipartite support, added
	2026-09-02, user: "continue" - the user's own explicit go-ahead
	after being shown the remaining large architectural items).
	Previously rejected outright by nwdynam.ado - see that file's own
	updated comment for why the guard's stated reason no longer holds
	and what was verified before lifting it.

	MECHANISM: `n1' is the mode-1 actor count (0 = not two-mode). This
	package's own combined actor-index convention (established by
	nwset's own bipartite ingestion, already reused by nwergm's own
	bipartite() support) puts mode-1 actors at indices 1..n1 and mode-2
	at n1+1..n, contiguous. goldfish's own two-mode DyNAM architecture
	assumes a STRICTLY ONE-DIRECTIONAL bipartite dependent network -
	confirmed directly via a hand-built toy affiliation network (people
	sending to orgs, never the reverse) - every event's sender is drawn
	from node set 1 ("nodes"), every candidate/receiver from node set 2
	("nodes2"), never mixed. Implemented as a simple risk-set MASK on
	top of the existing engine: choice sub-model excludes mode-1 actors
	from the candidate set (`lp[1..n1] = -1e300`); rate sub-model
	excludes mode-2 actors from the "who acts next" risk set
	(`lp[(n1+1)..n] = -1e300`). Hand-traced against goldfish's own
	`dependentStatsChange` deltas (same `preprocessingOnly=TRUE'
	technique used for `four()'/`tertius()' above) for `inertia' on a
	tiny 2-person/2-org/4-event example FIRST, confirming the naive
	"just restrict the risk set, formula unchanged" hypothesis holds for
	genuinely dyadic tie-presence effects - only THEN extended to a
	larger (6-person/4-org/60-event) toy dataset for full verification.

	PER-EFFECT ELIGIBILITY - goldfish's own documented `isTwoMode`
	column (doc/goldfishEffects.Rmd) turned out UNRELIABLE as a
	predictor of which effects actually work for two-mode - checked
	directly, not trusted: several effects the table marks eligible
	(`recip`, `outdeg` choice-side/alter-type, `commonReceiver`, `indeg`
	rate-side/ego-type) are hard-REJECTED by goldfish's own engine at
	runtime, each for the SAME real structural reason - goldfish's own
	one-directional architecture means mode 1 has no in-ties and mode 2
	has no out-ties, so any effect needing that missing role is
	undefined, not just usually-zero. These rejections are MIRRORED
	here (not silently allowed to produce a degenerate fit).

	A DEEPER finding, going beyond simple risk-set restriction: a few
	effects goldfish DOES accept for two-mode (`commonSender`, `four`)
	produced NON-degenerate fits that pure risk-set-restriction
	reasoning could not explain, matching goldfish's own doc warning
	("we omit the difference in the computation of the statistics when
	isTwoMode is used") - meaning some effects genuinely redefine their
	own formula for two-mode, not just their risk set. This was
	confirmed to run deeper than expected: direct comparison against
	goldfish's own reconstructed statistics found `same()` and `ego()` -
	the SIMPLEST possible attribute effects, a plain value comparison
	and a plain value broadcast respectively - ALSO silently wrong under
	the naive "read one combined covariate vector spanning both modes"
	approach originally attempted here (`same()` off by a large margin;
	`ego()` off by a smaller but still real margin). Investigating why
	revealed goldfish's own internal two-mode statistic array applies
	its ordinary "zero the self-tie" convention by matching raw ROW
	INDEX to raw COLUMN INDEX, even though rows and columns span two
	GENUINELY DIFFERENT node sets in a two-mode network (so
	person-index-3 and org-index-3 get treated as "the same actor" for
	self-exclusion purposes, despite being unrelated actors in different
	modes) - a real goldfish-internal representation quirk that could
	not be confidently reverse-engineered into a correct general formula
	in the time available. Given this, EVERY attribute effect (`same`/
	`diff`/`sim`/`alter`/`ego`/`egoAlterInt`/`tertius`) is rejected for
	two-mode in nwdynam.ado, not just the ones goldfish itself hard-
	rejects - a disclosed, unresolved gap, not a silently-shipped guess.

	VERIFIED WORKING, with an EXACT numerical match to real goldfish on
	the 6-person/4-org/60-event toy dataset (dev/dynam_unit12_twomode_
	crosscheck.R/.do): `inertia` (choice: -0.42729, alone; -0.73342
	alongside `indeg`), `indeg` alter-type (choice: 0.12673 alone;
	0.23018 alongside `inertia`), `outdeg` ego-type (rate: 0.23797) -
	matching to within 1e-5 on every coefficient. `nodeTrans`/`trans`/
	`cycle` are excluded per goldfish's own `isTwoMode=×` table entries
	(not independently re-verified, since every OTHER table entry that
	WAS re-verified turned out unreliable in at least one direction -
	disclosed, not assumed safe either way). `commonSender`/`four`
	(goldfish accepts them, but with the unexplained formula difference
	above) and windowed/weighted effects (not yet verified together with
	two-mode at all) remain real, disclosed gaps for a future batch.
*/
void dynam_choice_loglik_grad_multi(real rowvector theta, real rowvector active,
		real matrix covmat, real rowvector windowvec, real rowvector weightvec, real scalar n1,
		real matrix oppmat, real matrix tiemat,
		pointer(class DynamState scalar) scalar pS, real scalar ll, real rowvector grad) {
	real scalar i, s, r, n, mx, lrsum, j, e, tcur, nowindowinertia, nowindowrecip
	real scalar needAA, needAtA, needAAt, windowinertia, windowrecip
	real scalar weightedinertia, weightedrecip, weightedindeg, weightedoutdeg
	real matrix lastcontact, tiecount, A, AA, AtA, AAt, AAtA
	real rowvector inertia_i, recip_i, indeg_i, outdeg_i, same_i, diff_i, sim_i
	real rowvector trans_i, cycle_i, commonsender_i, commonreceiver_i, four_i, nodetrans_i
	real rowvector egoalterint_i, tertius_i, tertiusnumer, tertiusdenom, hasin, tie_i
	real rowvector lp, P, gradfull, idx
	real rowvector samevec, diffvec, simvec, altervec, tertiusvec, egoalterint1vec, egoalterint2vec

	// `covmat' bundles every per-actor covariate vector into ONE 7 x n
	// matrix (row 1=same, 2=diff, 3=sim, 4=alter, 5=tertius,
	// 6=egoalterint1, 7=egoalterint2), `windowvec' bundles both window
	// scalars into ONE 1 x 2 vector (1=windowinertia, 2=windowrecip),
	// and `weightvec' bundles the four `weighted=TRUE' modifier flags
	// into ONE 1 x 4 vector (1=inertia, 2=recip, 3=indeg, 4=outdeg) -
	// rather than passing each as its own optimize_init_argument()
	// slot. Stata's own optimize() framework caps optimize_init_argument()
	// at index 9 (confirmed directly by a minimal repro, not assumed -
	// the previous 11-separate-argument design for this function hit
	// that cap exactly, silently (`invalid argument index'), once
	// egoAlterInt/tertius pushed the count past it in "expansion batch
	// 7"). Bundling into matrices instead of separate arguments keeps
	// this function's own outer signature FIXED regardless of how many
	// more per-actor covariates or modifier flags a future batch adds -
	// only `covmat'/`weightvec' grow, no new optimize_init_argument()
	// slot ever needed again.
	samevec = covmat[1,.]
	diffvec = covmat[2,.]
	simvec = covmat[3,.]
	altervec = covmat[4,.]
	tertiusvec = covmat[5,.]
	egoalterint1vec = covmat[6,.]
	egoalterint2vec = covmat[7,.]
	windowinertia = windowvec[1]
	windowrecip = windowvec[2]
	weightedinertia = weightvec[1]
	weightedrecip = weightvec[2]
	weightedindeg = weightvec[3]
	weightedoutdeg = weightvec[4]

	n = (*pS).n
	ll = 0
	gradfull = J(1, 17, 0)
	lastcontact = J(n, n, -1e300)
	tiecount = J(n, n, 0)
	same_i = J(1, n, 0)
	diff_i = J(1, n, 0)
	sim_i = J(1, n, 0)
	nowindowinertia = (windowinertia >= 1e300)
	nowindowrecip = (windowrecip >= 1e300)
	needAA = active[9] | active[10] | active[14]
	needAtA = active[11] | active[13]
	needAAt = active[12]
	if (active[15]) egoalterint_i = J(1, n, 0)

	idx = J(1, 17, 0)
	j = 0
	for (e=1; e<=17; e++) {
		if (active[e]) {
			j = j + 1
			idx[e] = j
		}
	}

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]
		tcur = (*pS).events[i,3]

		if (weightedinertia) inertia_i = tiecount[s,.]
		else if (nowindowinertia) inertia_i = (lastcontact[s,.] :> -1e300)
		else inertia_i = ((tcur :- lastcontact[s,.]) :<= windowinertia)
		if (weightedrecip) recip_i = tiecount[.,s]'
		else if (nowindowrecip) recip_i = (lastcontact[.,s]' :> -1e300)
		else recip_i = ((tcur :- lastcontact[.,s])' :<= windowrecip)
		if (weightedindeg) indeg_i = colsum(tiecount)
		else indeg_i = colsum(lastcontact :> -1e300)
		if (active[8]) {
			if (weightedoutdeg) outdeg_i = rowsum(tiecount)'
			else outdeg_i = rowsum(lastcontact :> -1e300)'
		}
		if (active[4]) same_i = (samevec :== samevec[s])
		if (active[5]) diff_i = abs(diffvec :- diffvec[s])
		if (active[6]) sim_i = -abs(simvec :- simvec[s])
		if (active[15]) egoalterint_i = egoalterint1vec[s] :* egoalterint2vec

		if (needAA | needAtA | needAAt) A = (lastcontact :> -1e300)
		if (needAA) AA = A * A
		if (needAtA) AtA = A' * A
		if (needAAt) AAt = A * A'
		if (active[9]) trans_i = AA[s,.]
		if (active[10]) cycle_i = AA[.,s]'
		if (active[11]) commonsender_i = AtA[s,.]
		if (active[12]) commonreceiver_i = AAt[s,.]
		if (active[13]) {
			AAtA = A * AtA
			four_i = AAtA[s,.] :- A[s,.] :* (rowsum(A[s,.]) :+ diagonal(AtA)' :- A[s,.])
		}
		if (active[14]) nodetrans_i = rowsum(A :* AA)'
		if (active[16]) {
			if (needAA==0 & needAtA==0 & needAAt==0) A = (lastcontact :> -1e300)
			tertiusnumer = tertiusvec * A
			// Always the count of DISTINCT in-neighbors, never the
			// weighted indegree - `indeg_i' above may itself be
			// weighted (`weightedindeg') if `indeg' is ALSO active in
			// the SAME model, which must not silently change tertius's
			// own denominator.
			tertiusdenom = colsum(A)
			hasin = (tertiusdenom :> 0)
			tertius_i = hasin :* (tertiusnumer :/ (tertiusdenom :+ (1 :- hasin)))
		}

		// tie() ("cross-network effects, v1 scope", added 2026-09-02):
		// unweighted presence in a SEPARATE, STATIC exogenous network
		// (`tiemat', an n x n 0/1 matrix, unchanging across events - not
		// itself an event-declared/evolving network, a real, disclosed
		// v1 scope limit) - `s(i,j,t,x) = I(x_ij>0)' per goldfish's own
		// doc/goldfishEffects.Rmd, identical in shape to `inertia' but
		// reading a FIXED matrix instead of the incrementally-tracked
		// `lastcontact'. Verified directly against real goldfish (see
		// dev/dynam_unit18_tie_crosscheck.R/.do) - `tiemat' has 0 rows
		// when tie() was not given (matching `oppmat''s own "not given"
		// sentinel convention), skipping the row-extraction entirely.
		if (active[17]) tie_i = tiemat[s,.]

		lp = J(1, n, 0)
		if (active[1]) lp = lp :+ theta[idx[1]] :* inertia_i
		if (active[2]) lp = lp :+ theta[idx[2]] :* recip_i
		if (active[3]) lp = lp :+ theta[idx[3]] :* indeg_i
		if (active[4]) lp = lp :+ theta[idx[4]] :* same_i
		if (active[5]) lp = lp :+ theta[idx[5]] :* diff_i
		if (active[6]) lp = lp :+ theta[idx[6]] :* sim_i
		if (active[7]) lp = lp :+ theta[idx[7]] :* altervec
		if (active[8]) lp = lp :+ theta[idx[8]] :* outdeg_i
		if (active[9]) lp = lp :+ theta[idx[9]] :* trans_i
		if (active[10]) lp = lp :+ theta[idx[10]] :* cycle_i
		if (active[11]) lp = lp :+ theta[idx[11]] :* commonsender_i
		if (active[12]) lp = lp :+ theta[idx[12]] :* commonreceiver_i
		if (active[13]) lp = lp :+ theta[idx[13]] :* four_i
		if (active[14]) lp = lp :+ theta[idx[14]] :* nodetrans_i
		if (active[15]) lp = lp :+ theta[idx[15]] :* egoalterint_i
		if (active[16]) lp = lp :+ theta[idx[16]] :* tertius_i
		if (active[17]) lp = lp :+ theta[idx[17]] :* tie_i
		lp[s] = -1e300
		// Two-mode: mode-1 actors (indices 1..n1, which already
		// includes the sender itself, so this subsumes the line above)
		// can never be a CANDIDATE - goldfish's own architecture
		// assumes mode 2 only ever receives (see nwdynam.ado's own
		// two-mode comment for the real-goldfish verification this
		// mirrors).
		if (n1 > 0) lp[1..n1] = J(1, n1, -1e300)
		// opportunitiesList (goldfish's own estimationInit argument,
		// choice sub-model only): per-event candidate restriction -
		// actors NOT marked available for event i are excluded from the
		// risk set for THAT event only, matching goldfish's own
		// behavior exactly (verified directly: the sender's own
		// self-exclusion above still applies unconditionally regardless
		// of whether the sender itself is listed as "available").
		// `oppmat' has 0 rows when opportunitiesList was not given (the
		// sentinel for "no restriction," skipping this entirely).
		if (rows(oppmat) > 0) lp = lp :+ (oppmat[i,.] :== 0) :* (-1e300)

		mx = max(lp)
		P = exp(lp :- mx)
		lrsum = mx + ln(sum(P))
		ll = ll + (lp[r] - lrsum)

		P = P :/ sum(P)
		if (active[1]) gradfull[1] = gradfull[1] + (inertia_i[r] - sum(inertia_i :* P))
		if (active[2]) gradfull[2] = gradfull[2] + (recip_i[r] - sum(recip_i :* P))
		if (active[3]) gradfull[3] = gradfull[3] + (indeg_i[r] - sum(indeg_i :* P))
		if (active[4]) gradfull[4] = gradfull[4] + (same_i[r] - sum(same_i :* P))
		if (active[5]) gradfull[5] = gradfull[5] + (diff_i[r] - sum(diff_i :* P))
		if (active[6]) gradfull[6] = gradfull[6] + (sim_i[r] - sum(sim_i :* P))
		if (active[7]) gradfull[7] = gradfull[7] + (altervec[r] - sum(altervec :* P))
		if (active[8]) gradfull[8] = gradfull[8] + (outdeg_i[r] - sum(outdeg_i :* P))
		if (active[9]) gradfull[9] = gradfull[9] + (trans_i[r] - sum(trans_i :* P))
		if (active[10]) gradfull[10] = gradfull[10] + (cycle_i[r] - sum(cycle_i :* P))
		if (active[11]) gradfull[11] = gradfull[11] + (commonsender_i[r] - sum(commonsender_i :* P))
		if (active[12]) gradfull[12] = gradfull[12] + (commonreceiver_i[r] - sum(commonreceiver_i :* P))
		if (active[13]) gradfull[13] = gradfull[13] + (four_i[r] - sum(four_i :* P))
		if (active[14]) gradfull[14] = gradfull[14] + (nodetrans_i[r] - sum(nodetrans_i :* P))
		if (active[15]) gradfull[15] = gradfull[15] + (egoalterint_i[r] - sum(egoalterint_i :* P))
		if (active[16]) gradfull[16] = gradfull[16] + (tertius_i[r] - sum(tertius_i :* P))
		if (active[17]) gradfull[17] = gradfull[17] + (tie_i[r] - sum(tie_i :* P))

		lastcontact[s,r] = tcur
		tiecount[s,r] = tiecount[s,r] + 1
	}

	grad = J(1, 0, 0)
	for (e=1; e<=17; e++) if (active[e]) grad = (grad, gradfull[e])
}

real scalar dynam_choice_loglik_multi(real rowvector theta, real rowvector active,
		real matrix covmat, real rowvector windowvec, real rowvector weightvec, real scalar n1,
		real matrix oppmat, real matrix tiemat,
		pointer(class DynamState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	dynam_choice_loglik_grad_multi(theta, active, covmat, windowvec, weightvec, n1, oppmat, tiemat, pS, ll, grad)
	return(ll)
}

void dynam_choice_eval_multi(real scalar todo, real rowvector theta, pointer(real rowvector) scalar pActive,
		pointer(real matrix) scalar pCovmat, pointer(real rowvector) scalar pWindowVec, pointer(real rowvector) scalar pWeightVec,
		pointer(real scalar) scalar pN1, pointer(real matrix) scalar pOppmat, pointer(real matrix) scalar pTiemat,
		pointer(class DynamState scalar) scalar pS, real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	dynam_choice_loglik_grad_multi(theta, *pActive, *pCovmat, *pWindowVec, *pWeightVec, *pN1, *pOppmat, *pTiemat, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	DynamChoiceFitMulti() -- fits any nonempty subset of the choice
	sub-model's 16 effects. Mata-only (no native backend for a genuine
	subset yet - see this file's own header comment for why: a real,
	disclosed follow-on, not silently missing). Random-perturbation
	multi-start strategy (not a fixed small start-point table like
	DynamFitUnit1()'s own 3-parameter-only table) since nparams now
	varies with how many effects are selected - matching unw_rem.do's
	own RemFitMulti() precedent for the identical reason. `samevec'/
	`diffvec'/`simvec'/`altervec'/`tertiusvec'/`egoalterint1vec'/
	`egoalterint2vec' are each a 1 x n per-actor covariate vector - pass
	J(1,n,0) for any not needed (never read when the corresponding
	active[] entry is 0), matching unw_rem.do's own covsndvec/covrecvec/
	covintvec convention exactly. `windowinertia'/`windowrecip' each
	>=1e300 means no window for that specific effect (matching
	goldfish's own per-effect window= argument, not a single shared
	window across the whole model) - see dynam_choice_loglik_grad_multi()'s
	own header comment for the exact windowing formula and how it was
	verified. `weightedinertia'/`weightedrecip'/`weightedindeg'/
	`weightedoutdeg' (added "expansion batch 8") are boolean-valued (1/0)
	- when set, that effect reads the cumulative COUNT of prior events
	for that dyad/actor instead of binary presence, matching goldfish's
	own `weighted=TRUE' argument; mutually exclusive with that same
	effect's own window in this implementation (not validated inside
	Mata - `nwdynam.ado' rejects the combination before it ever reaches
	here). This function's OWN external signature (7 separate covariate
	vectors + 2 window scalars + 4 weighted flags) is unchanged in
	SHAPE from before the covmat/windowvec/weightvec bundling refactor -
	it builds the bundled arguments internally (via Mata's `\'
	vertical-stack operator for `covmat', plain literal vectors for
	`windowvec'/`weightvec') before handing them to
	optimize_init_argument(), so every existing caller (nwdynam.ado,
	every dev/ crosscheck) needed only the 4 new trailing weighted-flag
	arguments added, not a restructuring; only the INTERNAL
	argument-passing to the optimizer needed to change to stay under
	Stata's own 9-argument optimize_init_argument() cap (see
	dynam_choice_loglik_grad_multi()'s own header comment for the
	discovery). `n1' (added "expansion batch 9", two-mode support) is
	the mode-1 actor count (0 = not two-mode, matching this file's own
	sentinel conventions) - when positive, mode-1 actors (indices
	1..n1) are excluded from the choice sub-model's own candidate risk
	set entirely, matching goldfish's own one-directional two-mode
	architecture (see dynam_choice_loglik_grad_multi()'s own header
	comment for the real-goldfish verification and the per-effect
	two-mode eligibility this required). `oppmat' ("expansion batch
	10", opportunitiesList support) is an nevents x n 0/1 matrix - row i
	marks which actors are an available candidate for event i (0 rows
	= not given, meaning no restriction, matching goldfish's own
	default). Choice sub-model only, matching goldfish's own
	`opportunitiesList' scope exactly (its own documentation states
	"ONLY for choice models").
*/
void DynamChoiceFitMulti(real matrix eventmat, real scalar n, real rowvector activevec,
		real rowvector samevec, real rowvector diffvec, real rowvector simvec, real rowvector altervec,
		real rowvector tertiusvec, real rowvector egoalterint1vec, real rowvector egoalterint2vec,
		real scalar windowinertia, real scalar windowrecip,
		real scalar weightedinertia, real scalar weightedrecip, real scalar weightedindeg, real scalar weightedoutdeg,
		real scalar n1, real matrix oppmat, real matrix tiemat,
		string scalar bname, string scalar vname, string scalar llname) {
	class DynamState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat, windowvec, weightvec
	real matrix V, covmat
	real scalar nparams, attempt, ok, errcode, nstarts
	real matrix starts

	S = DynamState()
	S.init(eventmat, n)

	covmat = (samevec \ diffvec \ simvec \ altervec \ tertiusvec \ egoalterint1vec \ egoalterint2vec)
	windowvec = (windowinertia, windowrecip)
	weightvec = (weightedinertia, weightedrecip, weightedindeg, weightedoutdeg)

	nparams = sum(activevec)
	if (nparams == 0) _error("nwdynam: at least one effect must be selected.")

	nstarts = 8
	starts = J(nstarts, nparams, 0)
	for (attempt=1; attempt<=nstarts; attempt++) {
		starts[attempt,.] = (runiform(1,nparams) :- 0.5) :* (0.15 * (mod(attempt-1, nstarts) + 1))
	}

	ok = 0
	for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_choice_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &covmat)
		optimize_init_argument(S_opt, 3, &windowvec)
		optimize_init_argument(S_opt, 4, &weightvec)
		optimize_init_argument(S_opt, 5, &n1)
		optimize_init_argument(S_opt, 6, &oppmat)
		optimize_init_argument(S_opt, 7, &tiemat)
		optimize_init_argument(S_opt, 8, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 60)
		errcode = _optimize(S_opt)
		if (errcode == 0) {
			theta_hat = optimize_result_params(S_opt)
			ok = 1
		}
	}
	if (ok == 0) {
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_choice_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, J(1, nparams, 0.01))
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &covmat)
		optimize_init_argument(S_opt, 3, &windowvec)
		optimize_init_argument(S_opt, 4, &weightvec)
		optimize_init_argument(S_opt, 5, &n1)
		optimize_init_argument(S_opt, 6, &oppmat)
		optimize_init_argument(S_opt, 7, &tiemat)
		optimize_init_argument(S_opt, 8, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 300)
		theta_hat = optimize(S_opt)
	}
	V = optimize_result_V_oim(S_opt)

	st_matrix(bname, theta_hat)
	st_matrix(vname, V)
	st_numscalar(llname, optimize_result_value(S_opt))
}

/*
	Rate sub-model, generalized/selectable engine - same role as
	dynam_choice_loglik_grad_multi() above, for the rate sub-model's own
	effects (1=indeg, 2=outdeg, matching dynam_rate_loglik_grad_unit1()'s
	own order; 3=ego, added 2026-09-02 - "expansion batch 2").

	Effect 3 (ego): the simplest possible attribute effect, per
	goldfish's own doc/goldfishEffects.Rmd - `r(i,t,z) = z_i`, the
	candidate (potential next sender)'s OWN static covariate value,
	broadcast directly with no comparison at all - the rate-side
	counterpart of the choice sub-model's own `alter` effect
	(dynam_choice_loglik_grad_multi()'s effect 7), matching goldfish's
	own naming exactly (`ego` for rate, `alter` for choice - the SAME
	underlying "static per-actor level" idea, just named for whichever
	risk-set role that sub-model's own candidates play). goldfish's own
	effect table confirms `ego` is rate-sub-model-only (never choice).

	`windowindeg`/`windowoutdeg` (added 2026-09-02, user follow-up "can
	we make [window] also available for the rate part of the model?",
	immediately after the choice-side inertiawindow()/recipwindow()
	self-activation redesign): a real-time recency cutoff on indeg/outdeg
	INDEPENDENTLY, exactly mirroring windowinertia/windowrecip's own
	semantics and >=1e300 "no window" sentinel. goldfish's own
	doc/goldfishEffects.Rmd effect table lists `window` as a real
	argument on indeg/outdeg and confirms both apply to the RATE
	sub-model (not just choice). Formula (same shape as the choice
	engine's own inertia/recip window, re-derived and verified against
	real goldfish here rather than assumed identical - see
	dev/dynam_unit7_ratewindow_crosscheck.R/.do): windowed indeg for
	candidate i counts only senders j whose MOST RECENT prior j->i event
	happened within the window of the current event's own timestamp;
	windowed outdeg for candidate i counts only receivers j whose most
	recent prior i->j event is within the window - the same
	`t_current - t_lastcontact <= window` hard cutoff, not a decaying
	weight. Implementation mirrors the choice engine exactly: the
	previous binary `tie` matrix is replaced by `lastcontact` (real time
	of the most recent i->j event, sentinel -1e300 for "never"). When
	both windows are inactive, `lastcontact :> -1e300` reproduces the
	OLD `tie :> 0` binary presence check exactly (bit-identical -
	verified directly via dev/dynam_unit7_ratewindow_crosscheck.do's own
	no-window regression sub-check against unit1's pre-window numbers).
*/
void dynam_rate_loglik_grad_multi(real rowvector theta, real rowvector active,
		real rowvector egovec, real rowvector tertiusvec, real scalar windowindeg, real scalar windowoutdeg,
		real scalar weightedindeg, real scalar weightedoutdeg, real scalar n1,
		pointer(class DynamState scalar) scalar pS, real scalar ll, real rowvector grad) {
	real scalar i, s, r, n, mx, lrsum, j, e, tcur, nowindowindeg, nowindowoutdeg
	real matrix lastcontact, tiecount, A, AA
	real rowvector indeg_i, outdeg_i, nodetrans_i, tertius_i, tertiusnumer, tertiusdenom, hasin, lp, P, gradfull, idx

	n = (*pS).n
	ll = 0
	gradfull = J(1, 5, 0)
	lastcontact = J(n, n, -1e300)
	tiecount = J(n, n, 0)
	nowindowindeg = (windowindeg >= 1e300)
	nowindowoutdeg = (windowoutdeg >= 1e300)

	idx = J(1, 5, 0)
	j = 0
	for (e=1; e<=5; e++) {
		if (active[e]) {
			j = j + 1
			idx[e] = j
		}
	}

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]
		tcur = (*pS).events[i,3]

		if (weightedindeg) indeg_i = colsum(tiecount)
		else if (nowindowindeg) indeg_i = colsum(lastcontact :> -1e300)
		else indeg_i = colsum((tcur :- lastcontact) :<= windowindeg)
		if (weightedoutdeg) outdeg_i = rowsum(tiecount)'
		else if (nowindowoutdeg) outdeg_i = rowsum(lastcontact :> -1e300)'
		else outdeg_i = rowsum((tcur :- lastcontact) :<= windowoutdeg)'
		if (active[4] | active[5]) A = (lastcontact :> -1e300)
		if (active[4]) {
			AA = A * A
			nodetrans_i = rowsum(A :* AA)'
		}
		if (active[5]) {
			tertiusnumer = tertiusvec * A
			// Always the count of DISTINCT in-neighbors, never the
			// weighted indegree - see the choice engine's own identical
			// comment above dynam_choice_loglik_grad_multi().
			tertiusdenom = colsum(A)
			hasin = (tertiusdenom :> 0)
			tertius_i = hasin :* (tertiusnumer :/ (tertiusdenom :+ (1 :- hasin)))
		}

		lp = J(1, n, 0)
		if (active[1]) lp = lp :+ theta[idx[1]] :* indeg_i
		if (active[2]) lp = lp :+ theta[idx[2]] :* outdeg_i
		if (active[3]) lp = lp :+ theta[idx[3]] :* egovec
		if (active[4]) lp = lp :+ theta[idx[4]] :* nodetrans_i
		if (active[5]) lp = lp :+ theta[idx[5]] :* tertius_i
		// Two-mode: mode-2 actors (indices n1+1..n) can never be the
		// next sender - goldfish's own architecture assumes mode 1
		// only ever sends (see nwdynam.ado's own two-mode comment for
		// the real-goldfish verification this mirrors).
		if (n1 > 0) lp[(n1+1)..n] = J(1, n-n1, -1e300)

		mx = max(lp)
		P = exp(lp :- mx)
		lrsum = mx + ln(sum(P))
		ll = ll + (lp[s] - lrsum)

		P = P :/ sum(P)
		if (active[1]) gradfull[1] = gradfull[1] + (indeg_i[s] - sum(indeg_i :* P))
		if (active[2]) gradfull[2] = gradfull[2] + (outdeg_i[s] - sum(outdeg_i :* P))
		if (active[3]) gradfull[3] = gradfull[3] + (egovec[s] - sum(egovec :* P))
		if (active[4]) gradfull[4] = gradfull[4] + (nodetrans_i[s] - sum(nodetrans_i :* P))
		if (active[5]) gradfull[5] = gradfull[5] + (tertius_i[s] - sum(tertius_i :* P))

		lastcontact[s,r] = tcur
		tiecount[s,r] = tiecount[s,r] + 1
	}

	grad = J(1, 0, 0)
	for (e=1; e<=5; e++) if (active[e]) grad = (grad, gradfull[e])
}

real scalar dynam_rate_loglik_multi(real rowvector theta, real rowvector active,
		real rowvector egovec, real rowvector tertiusvec, real scalar windowindeg, real scalar windowoutdeg,
		real scalar weightedindeg, real scalar weightedoutdeg, real scalar n1,
		pointer(class DynamState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	dynam_rate_loglik_grad_multi(theta, active, egovec, tertiusvec, windowindeg, windowoutdeg, weightedindeg, weightedoutdeg, n1, pS, ll, grad)
	return(ll)
}

void dynam_rate_eval_multi(real scalar todo, real rowvector theta, pointer(real rowvector) scalar pActive,
		pointer(real rowvector) scalar pEgo, pointer(real rowvector) scalar pTertius,
		pointer(real rowvector) scalar pModVec,
		pointer(class DynamState scalar) scalar pS, real scalar y, real rowvector g, real matrix H) {
	real rowvector grad, modvec
	modvec = *pModVec
	dynam_rate_loglik_grad_multi(theta, *pActive, *pEgo, *pTertius, modvec[1], modvec[2], modvec[3], modvec[4], modvec[5], pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	DynamRateFitMulti() -- fits any nonempty subset of the rate
	sub-model's 5 effects (1=indeg, 2=outdeg, 3=ego, 4=nodeTrans, 5=
	tertius - added 2026-09-02, "expansion batch 6"/"batch 7", both
	SAME both-submodel effects as dynam_choice_loglik_grad_multi()'s own
	effects 14/16; see that function's own header comment for the exact
	formulas). Same Mata-only, random-start strategy as
	DynamChoiceFitMulti(). `egovec'/`tertiusvec' are each a 1 x n
	per-actor covariate vector - pass J(1,n,0) if the corresponding
	active[] entry is 0 (never read in that case).
	`windowindeg'/`windowoutdeg' each >=1e300 means no window for that
	specific effect (matching windowinertia/windowrecip's own
	convention in DynamChoiceFitMulti()). `nodeTrans`/`tertius` are both
	UNWINDOWED in this batch, matching their choice-side counterparts'
	own disclosed scope limit. `weightedindeg'/`weightedoutdeg' (added
	"expansion batch 8") mirror the choice engine's own weighted flags -
	when set, that effect reads the cumulative COUNT of prior events for
	that actor instead of the count of distinct partners, matching
	goldfish's own `weighted=TRUE'. `n1' (added "expansion batch 9",
	two-mode support) is the mode-1 actor count (0 = not two-mode) -
	when positive, mode-2 actors (indices n1+1..n) are excluded from
	the rate sub-model's own risk set entirely, matching goldfish's own
	one-directional two-mode architecture (see
	dynam_rate_loglik_grad_multi()'s own header comment). This
	function's OWN external signature (separate named scalar
	arguments) is unchanged in SHAPE - internally these five are
	bundled into ONE `modvec' before being handed to
	optimize_init_argument(), since adding `n1' as a further separate
	slot would have reached Stata's own 9-argument
	optimize_init_argument() cap (see dynam_choice_loglik_grad_multi()'s
	own header comment for the discovery) - matching the choice engine's
	own covmat/windowvec/weightvec bundling precedent.
*/
void DynamRateFitMulti(real matrix eventmat, real scalar n, real rowvector activevec,
		real rowvector egovec, real rowvector tertiusvec, real scalar windowindeg, real scalar windowoutdeg,
		real scalar weightedindeg, real scalar weightedoutdeg, real scalar n1,
		string scalar bname, string scalar vname, string scalar llname) {
	class DynamState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat, modvec
	real matrix V
	real scalar nparams, attempt, ok, errcode, nstarts
	real matrix starts

	S = DynamState()
	S.init(eventmat, n)

	modvec = (windowindeg, windowoutdeg, weightedindeg, weightedoutdeg, n1)

	nparams = sum(activevec)
	if (nparams == 0) _error("nwdynam: at least one effect must be selected.")

	nstarts = 8
	starts = J(nstarts, nparams, 0)
	for (attempt=1; attempt<=nstarts; attempt++) {
		starts[attempt,.] = (runiform(1,nparams) :- 0.5) :* (0.15 * (mod(attempt-1, nstarts) + 1))
	}

	ok = 0
	for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_rate_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &egovec)
		optimize_init_argument(S_opt, 3, &tertiusvec)
		optimize_init_argument(S_opt, 4, &modvec)
		optimize_init_argument(S_opt, 5, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 60)
		errcode = _optimize(S_opt)
		if (errcode == 0) {
			theta_hat = optimize_result_params(S_opt)
			ok = 1
		}
	}
	if (ok == 0) {
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_rate_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, J(1, nparams, 0.01))
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &egovec)
		optimize_init_argument(S_opt, 3, &tertiusvec)
		optimize_init_argument(S_opt, 4, &modvec)
		optimize_init_argument(S_opt, 5, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 300)
		theta_hat = optimize(S_opt)
	}
	V = optimize_result_V_oim(S_opt)

	st_matrix(bname, theta_hat)
	st_matrix(vname, V)
	st_numscalar(llname, optimize_result_value(S_opt))
}

/*
	WITH-INTERCEPT rate sub-model ("expansion batch 17", 2026-09-02,
	continuing the goldfish-comparison list) - the genuinely
	continuous-time competing-risks hazard variant this file's own
	header CORRECTION comment always said remained deferred: unlike the
	NO-intercept rate model (which reduces to the SAME ordinal partial
	likelihood as everything else in this package, using only the ORDER
	events happen in, never real elapsed time), giving an intercept makes
	the model genuinely sensitive to the ACTUAL SCALE of elapsed time
	between events (goldfish's own teaching1.Rmd vignette: "an intercept
	of -14 means a waiting time of 334 hours").

	FORMULA, derived from a real toy example against goldfish FIRST (an
	intercept is requested via a literal `1' as the first formula term,
	e.g. `dep ~ 1 + indeg(net)' - confirmed directly via goldfish's own
	`parseIntercept()'; `dep ~ 1' ALONE, with no other term, hits a real
	goldfish-internal bug unrelated to this package, `strsplit(): non-
	character argument' - not investigated further, out of scope, worked
	around by always fitting at least one real effect alongside the
	intercept in every crosscheck). Each actor i is an independent
	Poisson clock with hazard `exp(beta'X_i(t))'; the FIRST observed
	event contributes only `beta'X_{s_1}' (goldfish does not assume any
	risk period exists before the first observed event - confirmed
	directly: including a hazard-integral term for the very first event
	produced a real, wrong number until this was found and removed).
	Every SUBSEQUENT event k contributes
	  beta'X_{s_k} - (t_k - t_{k-1}) * sum_i exp(beta'X_i)
	summed over the full observed sequence - the standard competing-
	exponential-clocks log-likelihood (Cox-style), verified to match
	real goldfish EXACTLY (not within tolerance) on two independent toy
	fits (`rate ~ 1 + indeg`, `rate ~ 1 + outdeg`, real - not sequential -
	timestamps) - see dev/dynam_unit20_rateintercept_crosscheck.R/.do.
	The gradient (verified against numerical differentiation to ~1e-9,
	and confirmed ~0 at goldfish's own reported MLE) is the same
	"observed minus expected" score for every event but the first:
	  d logL_k/dbeta_j = X_{s_k,j} - dt_k * sum_i exp(beta'X_i) * X_{i,j}
	(k=1: just `X_{s_1,j}', no dt term), with the intercept itself
	simply X_{i,intercept}=1 for every actor.

	SCOPE: the intercept is ALWAYS included (theta[1], not an `active[]'
	toggle - matching goldfish's own "give `1' as a formula term"
	convention, not a boolean flag) alongside any subset of the SAME
	five rate-submodel effects (`indeg'/`outdeg'/`ego'/`nodetrans'/
	`tertius') the NO-intercept engine already has - reusing their own
	already-verified statistic-building code unchanged, only the
	AGGREGATION differs. `nodeTrans'/`tertius' remain UNWINDOWED and
	unweighted here too, matching their own scope limit in the
	NO-intercept engine.

	Window/`weighted=TRUE'/two-mode combined with the intercept
	("expansion batch 18", 2026-09-02) - each verified independently
	against real goldfish on a toy network with real, unevenly-spaced
	timestamps BEFORE this code was written (see dev/dynam_unit21_
	rateintercept_twomode_crosscheck.R, dynam_unit21b_..._window_...R,
	dynam_unit21c_..._weighted_...R): the SAME statistic swaps the
	no-intercept engine already uses (`indeg_i'/`outdeg_i' read from a
	real-time window or a cumulative weighted count instead of the
	full-history distinct-neighbor count; mode-2 actors masked to
	-1e300 in `lp' so their hazard underflows to ~0) turned out to
	compose correctly with the hazard-integral aggregation exactly as
	written, with no further correction needed - confirmed by exact
	agreement with real goldfish on all three, not merely assumed from
	the no-intercept case. Two-mode is verified here with `outdeg' only
	(goldfish itself rejects `indeg' - an "ego"-type effect - on a
	two-mode RATE sub-model; already established for the no-intercept
	engine, see dynam_rate_loglik_grad_multi()'s own header).
*/
void dynam_rateint_loglik_grad_multi(real rowvector theta, real rowvector active,
		real rowvector egovec, real rowvector tertiusvec, real rowvector modvec,
		pointer(class DynamState scalar) scalar pS, real scalar ll, real rowvector grad) {
	real scalar i, s, r, n, j, e, tcur, tprev, dt, intercept
	real scalar windowindeg, windowoutdeg, weightedindeg, weightedoutdeg, n1
	real scalar nowindowindeg, nowindowoutdeg
	real matrix lastcontact, tiecount, A, AA
	real rowvector indeg_i, outdeg_i, nodetrans_i, tertius_i, tertiusnumer, tertiusdenom, hasin
	real rowvector lp, haz, gradfull, idx

	n = (*pS).n
	ll = 0
	gradfull = J(1, 6, 0)
	lastcontact = J(n, n, -1e300)
	tiecount = J(n, n, 0)
	intercept = theta[1]

	windowindeg = modvec[1]
	windowoutdeg = modvec[2]
	weightedindeg = modvec[3]
	weightedoutdeg = modvec[4]
	n1 = modvec[5]
	nowindowindeg = (windowindeg >= 1e300)
	nowindowoutdeg = (windowoutdeg >= 1e300)

	idx = J(1, 5, 0)
	j = 1
	for (e=1; e<=5; e++) {
		if (active[e]) {
			j = j + 1
			idx[e] = j
		}
	}

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]
		tcur = (*pS).events[i,3]

		if (weightedindeg) indeg_i = colsum(tiecount)
		else if (nowindowindeg) indeg_i = colsum(lastcontact :> -1e300)
		else indeg_i = colsum((tcur :- lastcontact) :<= windowindeg)
		if (weightedoutdeg) outdeg_i = rowsum(tiecount)'
		else if (nowindowoutdeg) outdeg_i = rowsum(lastcontact :> -1e300)'
		else outdeg_i = rowsum((tcur :- lastcontact) :<= windowoutdeg)'
		if (active[4] | active[5]) A = (lastcontact :> -1e300)
		if (active[4]) {
			AA = A * A
			nodetrans_i = rowsum(A :* AA)'
		}
		if (active[5]) {
			tertiusnumer = tertiusvec * A
			tertiusdenom = colsum(A)
			hasin = (tertiusdenom :> 0)
			tertius_i = hasin :* (tertiusnumer :/ (tertiusdenom :+ (1 :- hasin)))
		}

		lp = J(1, n, intercept)
		if (active[1]) lp = lp :+ theta[idx[1]] :* indeg_i
		if (active[2]) lp = lp :+ theta[idx[2]] :* outdeg_i
		if (active[3]) lp = lp :+ theta[idx[3]] :* egovec
		if (active[4]) lp = lp :+ theta[idx[4]] :* nodetrans_i
		if (active[5]) lp = lp :+ theta[idx[5]] :* tertius_i
		// Two-mode: mode-2 actors can never be the next sender - see
		// dynam_rate_loglik_grad_multi()'s own identical comment. Here
		// this also correctly zeroes their contribution to the hazard
		// SUM below (exp(-1e300) underflows to 0), not just the
		// softmax the no-intercept engine uses.
		if (n1 > 0) lp[(n1+1)..n] = J(1, n-n1, -1e300)

		if (i == 1) {
			ll = ll + lp[s]
			gradfull[1] = gradfull[1] + 1
			if (active[1]) gradfull[idx[1]] = gradfull[idx[1]] + indeg_i[s]
			if (active[2]) gradfull[idx[2]] = gradfull[idx[2]] + outdeg_i[s]
			if (active[3]) gradfull[idx[3]] = gradfull[idx[3]] + egovec[s]
			if (active[4]) gradfull[idx[4]] = gradfull[idx[4]] + nodetrans_i[s]
			if (active[5]) gradfull[idx[5]] = gradfull[idx[5]] + tertius_i[s]
		}
		else {
			dt = tcur - tprev
			haz = exp(lp)
			ll = ll + lp[s] - dt * sum(haz)
			gradfull[1] = gradfull[1] + (1 - dt * sum(haz))
			if (active[1]) gradfull[idx[1]] = gradfull[idx[1]] + (indeg_i[s] - dt * sum(haz :* indeg_i))
			if (active[2]) gradfull[idx[2]] = gradfull[idx[2]] + (outdeg_i[s] - dt * sum(haz :* outdeg_i))
			if (active[3]) gradfull[idx[3]] = gradfull[idx[3]] + (egovec[s] - dt * sum(haz :* egovec))
			if (active[4]) gradfull[idx[4]] = gradfull[idx[4]] + (nodetrans_i[s] - dt * sum(haz :* nodetrans_i))
			if (active[5]) gradfull[idx[5]] = gradfull[idx[5]] + (tertius_i[s] - dt * sum(haz :* tertius_i))
		}

		lastcontact[s,r] = tcur
		tiecount[s,r] = tiecount[s,r] + 1
		tprev = tcur
	}

	grad = gradfull[1..1]
	for (e=1; e<=5; e++) if (active[e]) grad = (grad, gradfull[idx[e]])
}

real scalar dynam_rateint_loglik_multi(real rowvector theta, real rowvector active,
		real rowvector egovec, real rowvector tertiusvec, real rowvector modvec,
		pointer(class DynamState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	dynam_rateint_loglik_grad_multi(theta, active, egovec, tertiusvec, modvec, pS, ll, grad)
	return(ll)
}

void dynam_rateint_eval_multi(real scalar todo, real rowvector theta, pointer(real rowvector) scalar pActive,
		pointer(real rowvector) scalar pEgovec, pointer(real rowvector) scalar pTertiusvec,
		pointer(real rowvector) scalar pModvec,
		pointer(class DynamState scalar) scalar pS, real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	dynam_rateint_loglik_grad_multi(theta, *pActive, *pEgovec, *pTertiusvec, *pModvec, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	DynamRateInterceptFitMulti() -- fits the WITH-INTERCEPT rate
	sub-model (see dynam_rateint_loglik_grad_multi()'s own header
	comment for the formula and its real-goldfish verification,
	including the window/weighted/two-mode combinations added in
	"expansion batch 18"). The intercept is ALWAYS estimated (theta[1]);
	`activevec' selects any subset of the same five rate effects the
	NO-intercept engine has. `windowindeg'/`windowoutdeg' each >=1e300
	means no window for that effect; `weightedindeg'/`weightedoutdeg'
	mirror the no-intercept engine's own flags; `n1' is the mode-1 actor
	count (0 = not two-mode) - all five bundled into ONE `modvec'
	argument for the same optimize_init_argument()-cap reason as
	DynamRateFitMulti()'s own modvec. Multi-start strategy matches every
	other Multi engine in this file.
*/
void DynamRateInterceptFitMulti(real matrix eventmat, real scalar n, real rowvector activevec,
		real rowvector egovec, real rowvector tertiusvec,
		real scalar windowindeg, real scalar windowoutdeg,
		real scalar weightedindeg, real scalar weightedoutdeg, real scalar n1,
		string scalar bname, string scalar vname, string scalar llname) {
	class DynamState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat, modvec
	real matrix V_best
	real scalar nparams, attempt, nconverged, errcode, nstarts, thisval, bestval
	real matrix starts

	S = DynamState()
	S.init(eventmat, n)

	modvec = (windowindeg, windowoutdeg, weightedindeg, weightedoutdeg, n1)

	nparams = 1 + sum(activevec)

	nstarts = 8
	starts = J(nstarts, nparams, 0)
	for (attempt=1; attempt<=nstarts; attempt++) {
		starts[attempt,.] = (runiform(1,nparams) :- 0.5) :* (0.15 * (mod(attempt-1, nstarts) + 1))
	}

	// Same non-concavity caution as DynamCoordFitMulti() (see its own
	// header comment for the discovery): the intercept's own hazard-sum
	// term is not guaranteed to leave this surface globally concave, so
	// every start is run (not just until the first "success") and every
	// value needed from the winning attempt is extracted immediately,
	// never deferred to after the loop.
	nconverged = 0
	bestval = .
	for (attempt=1; attempt<=rows(starts); attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_rateint_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &egovec)
		optimize_init_argument(S_opt, 3, &tertiusvec)
		optimize_init_argument(S_opt, 4, &modvec)
		optimize_init_argument(S_opt, 5, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 100)
		errcode = _optimize(S_opt)
		if (errcode == 0 & optimize_result_converged(S_opt) == 1) {
			thisval = optimize_result_value(S_opt)
			if (nconverged == 0 | thisval > bestval) {
				bestval = thisval
				theta_hat = optimize_result_params(S_opt)
				V_best = optimize_result_V_oim(S_opt)
			}
			nconverged = nconverged + 1
		}
	}
	if (nconverged == 0) {
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_rateint_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, J(1, nparams, 0.01))
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &egovec)
		optimize_init_argument(S_opt, 3, &tertiusvec)
		optimize_init_argument(S_opt, 4, &modvec)
		optimize_init_argument(S_opt, 5, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 300)
		theta_hat = optimize(S_opt)
		bestval = optimize_result_value(S_opt)
		V_best = optimize_result_V_oim(S_opt)
	}

	st_matrix(bname, theta_hat)
	st_matrix(vname, V_best)
	st_numscalar(llname, bestval)
}

/*
	choice_coordination sub-model ("expansion batch 11", 2026-09-02, user:
	"do choice_coordination now"): goldfish's own third DyNAM sub-model, a
	genuinely different likelihood from `choice' (a single conditional
	logit over one sender's own candidate receivers) - a "multinomial-
	multinomial" joint model over UNORDERED actor pairs, for undirected
	("coordination") tie-formation events where neither actor plays a
	privileged sender/receiver role (Stadtfeld, Hollway & Block 2017,
	"Dynamic Network Actor Models: Investigating Coordination Ties through
	Time," Sociological Methodology 47(1), equations 6/9/11).

	FORMULA, derived from goldfish's own C++ source
	(src/compute_coordination_selection.cpp in the CRAN 1.6.12 source
	tarball - the paper's own prose was not relied on, the actual
	production code was read directly), then independently verified
	against a REAL goldfish fit on two toy examples (not merely read and
	trusted): for each event, build the full n x n matrix of linear
	predictors beta'S(a,b) for every ordered candidate pair a!=b (the SAME
	per-effect statistic formulas as the plain `choice' sub-model - every
	`update_DyNAM_choice_coordination_X' function in goldfish's own
	namespace is confirmed, by direct inspection, to be a THIN WRAPPER
	calling the identical `update_DyNAM_choice_X' used by plain choice;
	only the AGGREGATION differs, not the statistics). Then:
	  p(a,b) = exp(beta'S(a,b)) / sum_{b'!=a} exp(beta'S(a,b'))   -- row-
	    normalized: an ordinary choice-submodel probability that a, as
	    sender, would pick b.
	  P(a,b) = p(a,b) * p(b,a)                                    -- the
	    (unnormalized) joint mass that a and b select EACH OTHER.
	  Pnorm(a,b) = P(a,b) / (sum(P)/2)                            -- P is
	    symmetric by construction (P(a,b)=P(b,a)), so accu(P) double-
	    counts every unordered pair; dividing by 2 normalizes Pnorm to a
	    genuine probability distribution over the n*(n-1)/2 unordered
	    candidate pairs.
	  loglik contribution = ln(Pnorm(sender,receiver)).
	Verified EXACTLY (to 6 decimal places) against a real goldfish fit on
	a 4-actor/4-event toy network (inertia only, converged coefficient
	-4.172212, goldfish's own reported logLik -5.729604) and, separately,
	a 6-actor/12-event toy network with TWO effects (inertia + same(),
	converged coefficients -0.4636/-0.5638, goldfish's own reported logLik
	-31.33132) - see dev/dynam_unit14_coordination_crosscheck.R/.do.

	GRADIENT: derived by hand from the loglik formula above (not
	transcribed from goldfish's own C++ loop, though independently
	confirmed to reduce to the same quantity), then verified against
	numerical differentiation to ~3.5e-9. For each active effect k with
	per-event statistic matrix S_k(a,b):
	  dlogp_k(a,b) = S_k(a,b) - sum_{b'} p(a,b') * S_k(a,b')   -- the
	    usual "observed minus row-expected" softmax score, computed for
	    EVERY row a (not just the observed sender), since the aggregate
	    term below needs every pair's own score.
	  d loglik_event/dbeta_k = [dlogp_k(sender,receiver) +
	    dlogp_k(receiver,sender)] - sum_{a,b} Pnorm(a,b) * dlogp_k(a,b)
	The second (subtracted) term was originally derived, matching
	goldfish's own C++ structure exactly, as a sum over unordered pairs
	a<b of Pnorm(a,b)*[dlogp_k(a,b)+dlogp_k(b,a)] - algebraically
	simplified (confirmed both symbolically and via a direct numeric
	check) to the single full-matrix elementwise sum sum(Pnorm :* S_k')
	shown above, avoiding an O(n^2) Mata for-loop per effect per event.

	SCOPE (disclosed rather than silently narrow): ten effects -
	`inertia', `indeg' (alter-type, matching choice's own), `same',
	`diff', `sim', `alter' (batch 11), `nodeTrans' and `trans' (batch
	12), plus `tertius' and `four' (batch 13, added 2026-09-02) - chosen
	because each is confirmed (by direct inspection of goldfish's own
	registered effect functions, not the vignette's own
	effect-eligibility table, which self-contradicts on `alter' - the
	table lists it "x" for choice_coordination while its OWN
	accompanying prose text says the opposite, and a direct
	`preprocessingOnly=TRUE' test against real goldfish confirms the
	PROSE is correct) to be BOTH real-goldfish-eligible for
	choice_coordination AND already buildable from an existing full n x n
	state matrix (`lastcontact', or `A'/`AA'/`AtA' for the closure
	family) or trivial per-actor broadcast in this engine. `recip',
	`outdeg', `ego', `cycle', `commonSender', `commonReceiver' are
	confirmed REJECTED by real goldfish itself for choice_coordination
	(structurally sensible - an undirected tie has no direction to
	reciprocate, and indeg/outdeg coincide for an undirected network so
	only one is offered). `nodeTrans'/`tertius' turned out to need NO new
	full-matrix logic beyond what `indeg' already computes: both are
	properties of the CANDIDATE alone (`rowsum(A:*AA)'' for nodeTrans,
	the same alter-type mean-covariate ratio plain choice's own tertius
	uses), broadcasting identically. `trans' - unlike plain choice's own
	`trans_i = AA[s,.]' (one row, the actual sender) - needs the FULL
	`AA' matrix directly (`AA[a,b]' already equals the two-path count
	for ANY a as sender, b as candidate). `four' needed the genuinely
	NEW full-matrix adaptation plain choice's own distinct-actors
	correction implies: `four_i(j) = (A*(A'*A))[i,j] - A[i,j]*
	(rowsum(A[i,.]) + diagonal(A'*A)[j] - A[i,j])' generalizes to
	`S_four(a,b) = AAtA[a,b] - A[a,b]*(rowsum(A[a,.]) +
	diagonal(AtA)[b] - A[a,b])' - note the diagonal correction term is
	indexed by the CANDIDATE b, not the sender a, a genuine
	transcription pitfall caught directly (a first R draft indexed it by
	a instead, reproducing a real but WRONG number, -32.039 vs.
	goldfish's own -32.288, until corrected). All four verified directly
	against real goldfish on the SAME 6-actor/12-event toy network batch
	11 used (see dev/dynam_unit15_coordination_closure_crosscheck.R/.do
	for nodeTrans/trans, dev/dynam_unit16_coordination_tertius_four_
	crosscheck.R/.do for tertius/four). `egoAlterInt', `tie',
	`tertiusDiff', `mixedTrans' remain confirmed real-goldfish-ELIGIBLE
	(via the same direct test) but NOT YET WIRED - a real, disclosed
	follow-on for a later batch. Two-mode (bipartite) coordination
	networks are likewise out of scope - goldfish's own C++ code has a
	`twomode_or_reflexive' flag suggesting real support exists there, but
	its own joint P=p.*p' construction requires the actor-1 and actor-2
	candidate pools to be the SAME SIZE (a square matrix), a real
	structural question not yet investigated for this package's own
	two-mode convention. No windowing or `weighted=TRUE' support yet
	either (goldfish's own effect signatures allow both on several of
	these effects) - all real, disclosed gaps.
*/
void dynam_coord_loglik_grad_multi(real rowvector theta, real rowvector active,
		real matrix covmat, real matrix tiemat,
		pointer(class DynamState scalar) scalar pS, real scalar ll, real rowvector grad) {
	real scalar i, s, r, n, j, e, tcur, Z
	real matrix lastcontact, statmat, praw, p, P, Pnorm, S_inertia, S_indeg, S_same, S_diff, S_sim, S_alter
	real matrix A, AA, AtA, AAtA, S_nodetrans, S_trans, S_tertius, S_four, S_egoalterint, S_tie
	real rowvector samevec, diffvec, simvec, altervec, tertiusvec, egoalterint1vec, egoalterint2vec
	real rowvector indegvec, nodetransvec, idx, gradfull
	real rowvector tertiusnumer, tertiusdenom, hasin
	real colvector rmax, rs, dg
	real matrix dlogp, colrep, rowrep

	samevec = covmat[1,.]
	diffvec = covmat[2,.]
	simvec = covmat[3,.]
	altervec = covmat[4,.]
	tertiusvec = covmat[5,.]
	egoalterint1vec = covmat[6,.]
	egoalterint2vec = covmat[7,.]

	n = (*pS).n
	ll = 0
	gradfull = J(1, 12, 0)
	lastcontact = J(n, n, -1e300)

	idx = J(1, 12, 0)
	j = 0
	for (e=1; e<=12; e++) {
		if (active[e]) {
			j = j + 1
			idx[e] = j
		}
	}

	// Mata's `:' elementwise operators do NOT broadcast a plain row
	// vector against its own transpose (1 x n vs n x 1) the way they
	// broadcast an n x n matrix against an n x 1 column (confirmed
	// directly - a first draft assumed the former worked too and hit a
	// real conformability error) - so the outer same/diff/sim/alter
	// matrices are built explicitly via J()-replication instead.
	// same()/diff()/sim()/alter() never depend on event history, so
	// they are computed ONCE here, outside the event loop, not
	// recomputed every event.
	colrep = samevec' * J(1, n, 1)
	rowrep = J(n, 1, 1) * samevec
	S_same = (colrep :== rowrep)
	colrep = diffvec' * J(1, n, 1)
	rowrep = J(n, 1, 1) * diffvec
	S_diff = abs(colrep :- rowrep)
	colrep = simvec' * J(1, n, 1)
	rowrep = J(n, 1, 1) * simvec
	S_sim = -abs(colrep :- rowrep)
	S_alter = J(n, 1, 1) * altervec
	// egoAlterInt: sender a's own covariate1 TIMES candidate b's own
	// covariate2 - an outer product, matching plain choice's own
	// `egoalterint_i = egoalterint1vec[s] :* egoalterint2vec' exactly
	// (that IS the outer product's row s already). Static like
	// same/diff/sim/alter, computed once here.
	S_egoalterint = egoalterint1vec' * egoalterint2vec
	// tie() ("cross-network effects, v1 scope", extended to
	// choice_coordination 2026-09-02): presence in a SEPARATE, STATIC
	// exogenous network - identical in shape to plain choice's own
	// `tie_i = tiemat[s,.]' but, since choice_coordination already needs
	// the FULL n x n statistic matrix for every effect (not just one
	// row), `S_tie' is simply `tiemat' itself - no computation at all,
	// the simplest possible addition. `tiemat' has 0 rows when tie() was
	// not given (matching every other "not given" sentinel convention in
	// this engine). Verified directly against real goldfish (see
	// dev/dynam_unit19_coordination_tie_crosscheck.R/.do).
	if (active[12]) S_tie = tiemat

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]
		tcur = (*pS).events[i,3]

		S_inertia = (lastcontact :> -1e300)
		indegvec = colsum(S_inertia)
		S_indeg = J(n, 1, 1) * indegvec
		if (active[7] | active[8] | active[9] | active[10]) {
			A = S_inertia
			AA = A * A
		}
		// nodeTrans (candidate b's own embeddedness in transitive
		// structures) - a property of b alone, not a sender/candidate
		// comparison, exactly like `indeg' - broadcasts across every row
		// a. `trans' (two-paths sender->k->candidate) - unlike the plain
		// choice engine's own `trans_i = AA[s,.]' (one row, the actual
		// sender), the FULL matrix version needed here is simply AA
		// itself: AA[a,b] already equals the two-path count for ANY a
		// as sender, b as candidate. Both verified directly against real
		// goldfish (dev/dynam_unit15_coordination_closure_crosscheck.R/
		// .do) before being wired in.
		if (active[7]) {
			nodetransvec = rowsum(A :* AA)'
			S_nodetrans = J(n, 1, 1) * nodetransvec
		}
		if (active[8]) S_trans = AA
		// tertius (candidate b's own mean covariate over ITS in-
		// neighbors) - like nodeTrans, a property of b alone (matching
		// plain choice's own tertius_i, which likewise never varies by
		// sender), so broadcasts across every row a exactly like
		// nodeTrans/indeg. Imputed 0 when b has no in-neighbors yet,
		// matching plain choice's own verified-not-documented behavior.
		if (active[9]) {
			tertiusnumer = tertiusvec * A
			tertiusdenom = colsum(A)
			hasin = (tertiusdenom :> 0)
			S_tertius = J(n, 1, 1) * (hasin :* (tertiusnumer :/ (tertiusdenom :+ (1 :- hasin))))
		}
		// four (three-paths a->k<-l->b, k!=l, all four actors distinct)
		// - unlike nodeTrans/tertius, this genuinely needs the FULL
		// matrix, since (per plain choice's own already-verified
		// distinct-actors correction) the subtracted term depends on
		// BOTH a (`rowsum(A[a,.])') and b (`diagonal(AtA)[b]') - the
		// diagonal term is indexed by the CANDIDATE b, not the sender a
		// (confirmed directly: an initial R draft indexed it by a
		// instead by mistranscribing plain choice's own `diagonal(AtA)
		// [j]' where j is the candidate, and it reproduced a real but
		// WRONG number until corrected - see dev/dynam_unit16_
		// coordination_tertius_four_crosscheck.R/.do).
		if (active[10]) {
			AtA = A' * A
			AAtA = A * AtA
			rs = rowsum(A)
			dg = diagonal(AtA)
			S_four = AAtA :- A :* ((rs * J(1,n,1)) :+ (J(n,1,1) * dg') :- A)
		}

		statmat = J(n, n, 0)
		if (active[1]) statmat = statmat :+ theta[idx[1]] :* S_inertia
		if (active[2]) statmat = statmat :+ theta[idx[2]] :* S_indeg
		if (active[3]) statmat = statmat :+ theta[idx[3]] :* S_same
		if (active[4]) statmat = statmat :+ theta[idx[4]] :* S_diff
		if (active[5]) statmat = statmat :+ theta[idx[5]] :* S_sim
		if (active[6]) statmat = statmat :+ theta[idx[6]] :* S_alter
		if (active[7]) statmat = statmat :+ theta[idx[7]] :* S_nodetrans
		if (active[8]) statmat = statmat :+ theta[idx[8]] :* S_trans
		if (active[9]) statmat = statmat :+ theta[idx[9]] :* S_tertius
		if (active[10]) statmat = statmat :+ theta[idx[10]] :* S_four
		if (active[11]) statmat = statmat :+ theta[idx[11]] :* S_egoalterint
		if (active[12]) statmat = statmat :+ theta[idx[12]] :* S_tie

		rmax = rowmax(statmat)
		praw = exp(statmat :- rmax)
		_diag(praw, 0)
		p = praw :/ rowsum(praw)

		P = p :* p'
		Z = sum(P) / 2
		Pnorm = P :/ Z

		ll = ll + ln(Pnorm[s,r])

		if (active[1]) {
			dlogp = S_inertia :- rowsum(p :* S_inertia)
			gradfull[1] = gradfull[1] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[2]) {
			dlogp = S_indeg :- rowsum(p :* S_indeg)
			gradfull[2] = gradfull[2] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[3]) {
			dlogp = S_same :- rowsum(p :* S_same)
			gradfull[3] = gradfull[3] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[4]) {
			dlogp = S_diff :- rowsum(p :* S_diff)
			gradfull[4] = gradfull[4] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[5]) {
			dlogp = S_sim :- rowsum(p :* S_sim)
			gradfull[5] = gradfull[5] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[6]) {
			dlogp = S_alter :- rowsum(p :* S_alter)
			gradfull[6] = gradfull[6] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[7]) {
			dlogp = S_nodetrans :- rowsum(p :* S_nodetrans)
			gradfull[7] = gradfull[7] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[8]) {
			dlogp = S_trans :- rowsum(p :* S_trans)
			gradfull[8] = gradfull[8] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[9]) {
			dlogp = S_tertius :- rowsum(p :* S_tertius)
			gradfull[9] = gradfull[9] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[10]) {
			dlogp = S_four :- rowsum(p :* S_four)
			gradfull[10] = gradfull[10] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[11]) {
			dlogp = S_egoalterint :- rowsum(p :* S_egoalterint)
			gradfull[11] = gradfull[11] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}
		if (active[12]) {
			dlogp = S_tie :- rowsum(p :* S_tie)
			gradfull[12] = gradfull[12] + ((dlogp[s,r] + dlogp[r,s]) - sum(Pnorm :* dlogp))
		}

		lastcontact[s,r] = tcur
		lastcontact[r,s] = tcur
	}

	grad = J(1, 0, 0)
	for (e=1; e<=12; e++) if (active[e]) grad = (grad, gradfull[e])
}

real scalar dynam_coord_loglik_multi(real rowvector theta, real rowvector active,
		real matrix covmat, real matrix tiemat,
		pointer(class DynamState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	dynam_coord_loglik_grad_multi(theta, active, covmat, tiemat, pS, ll, grad)
	return(ll)
}

void dynam_coord_eval_multi(real scalar todo, real rowvector theta, pointer(real rowvector) scalar pActive,
		pointer(real matrix) scalar pCovmat, pointer(real matrix) scalar pTiemat,
		pointer(class DynamState scalar) scalar pS, real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	dynam_coord_loglik_grad_multi(theta, *pActive, *pCovmat, *pTiemat, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	DynamCoordFitMulti() -- fits any nonempty subset of choice_coordination's
	eight effects (six from "batch 11," plus `nodeTrans'/`trans' added
	"batch 12" - see dynam_coord_loglik_grad_multi()'s own header
	comment for the formula, its real-goldfish verification, and the
	disclosed remaining scope). `eventmat' rows are unordered actor pairs (any
	order - the likelihood is symmetric in sender/receiver by
	construction, confirmed directly), one per undirected tie-formation
	event, matching `nwset ..., eventtime() undirected''s own raw
	`get_eventlist()' output (confirmed directly: no auto-symmetrization,
	one row per declared event). Same random-perturbation multi-start
	strategy as `DynamChoiceFitMulti'/`DynamRateFitMulti'. Only 3
	`optimize_init_argument()' slots used (activevec, covmat, S) - no
	risk yet of the 9-slot cap that forced the `covmat'/`windowvec'/
	`weightvec' bundling in the choice engine, but the SAME bundling
	convention (one matrix argument for per-actor covariates) is used
	from the start here too, so future growth (windowing, weighting,
	closure effects) never needs a signature change.
*/
void DynamCoordFitMulti(real matrix eventmat, real scalar n, real rowvector activevec,
		real rowvector samevec, real rowvector diffvec, real rowvector simvec, real rowvector altervec,
		real rowvector tertiusvec, real rowvector egoalterint1vec, real rowvector egoalterint2vec,
		real matrix tiemat,
		string scalar bname, string scalar vname, string scalar llname) {
	class DynamState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat
	real matrix V_best, covmat
	real scalar nparams, attempt, nconverged, errcode, nstarts, thisval, bestval
	real matrix starts

	S = DynamState()
	S.init(eventmat, n)

	covmat = (samevec \ diffvec \ simvec \ altervec \ tertiusvec \ egoalterint1vec \ egoalterint2vec)

	nparams = sum(activevec)
	if (nparams == 0) _error("nwdynam: at least one effect must be selected.")

	nstarts = 8
	starts = J(nstarts, nparams, 0)
	for (attempt=1; attempt<=nstarts; attempt++) {
		starts[attempt,.] = (runiform(1,nparams) :- 0.5) :* (0.15 * (mod(attempt-1, nstarts) + 1))
	}

	// Unlike the plain choice/rate sub-models (an ordinary softmax,
	// globally concave, so the FIRST attempt _optimize() completes
	// without error is trustworthy as the unique optimum), the
	// coordination sub-model's own P=p.*p' joint construction is a
	// PRODUCT of two softmax probabilities, not guaranteed concave -
	// found directly, not assumed: a first draft here accepted any
	// `_optimize()' call that returned errcode 0, which does NOT mean
	// the optimizer actually reached a stationary point (Stata's own
	// `_optimize()' returns 0 whenever the numerical procedure
	// completes without a fatal error, including stopping early at
	// `conv_maxiter' with a real gradient still far from zero) - this
	// silently accepted a converged-looking but WRONG two-effect
	// coordinate on a real toy example (inertia+same: landed at
	// (-0.399,0.056), true joint MLE (-0.464,-0.564), confirmed by
	// hand-evaluating this file's own dynam_coord_loglik_grad_multi()
	// directly at both points - the reported gradient at the accepted
	// point was (0.04,-3.64), nowhere near zero). Fixed two ways: (1)
	// require `optimize_result_converged()' == 1, not just errcode==0;
	// (2) run EVERY start (not just until the first "success") and
	// keep the BEST (highest loglik) among the genuinely converged
	// ones, since a non-concave surface can have more than one
	// stationary point and the first one reached is not guaranteed
	// global. A SECOND real bug found while fixing the first: keeping
	// only a saved `S_opt' HANDLE from the winning attempt and reading
	// `optimize_result_V_oim()'/`optimize_result_value()' off it AFTER
	// the loop ended silently returned a DIFFERENT (later) attempt's
	// own results instead - confirmed directly by tracing the starts
	// matrix and each attempt's own converged value, which showed the
	// function's own final answer matching a LATER attempt's results,
	// not the one flagged as best. `optimize_init()' handles are not
	// safe to keep across later `optimize_init()' calls reusing the
	// same Mata variable - every value needed from the winning attempt
	// (`theta_hat', `V_best', `bestval') is now extracted into a plain
	// value INSIDE the loop, the instant that attempt is found to be
	// the new best, never deferred to after the loop.
	nconverged = 0
	bestval = .
	for (attempt=1; attempt<=rows(starts); attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_coord_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &covmat)
		optimize_init_argument(S_opt, 3, &tiemat)
		optimize_init_argument(S_opt, 4, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 100)
		errcode = _optimize(S_opt)
		if (errcode == 0 & optimize_result_converged(S_opt) == 1) {
			thisval = optimize_result_value(S_opt)
			if (nconverged == 0 | thisval > bestval) {
				bestval = thisval
				theta_hat = optimize_result_params(S_opt)
				V_best = optimize_result_V_oim(S_opt)
			}
			nconverged = nconverged + 1
		}
	}
	if (nconverged == 0) {
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &dynam_coord_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, J(1, nparams, 0.01))
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &covmat)
		optimize_init_argument(S_opt, 3, &tiemat)
		optimize_init_argument(S_opt, 4, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 300)
		theta_hat = optimize(S_opt)
		bestval = optimize_result_value(S_opt)
		V_best = optimize_result_V_oim(S_opt)
	}

	st_matrix(bname, theta_hat)
	st_matrix(vname, V_best)
	st_numscalar(llname, bestval)
}

end
