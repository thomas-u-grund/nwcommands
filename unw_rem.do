/*
	unw_rem.do -- native relational event model (REM) estimation core
	for nwcommands (nwrem).

	See docs/REM_ROADMAP.md (scope/status) and docs/REM_ARCHITECTURE.md
	(design). Standalone engine - deliberately reuses NOTHING from
	unw_ergm.do/unw_saom.do (see REM_ROADMAP.md's own "Why a separate
	engine" section: the shared-engine question was raised and
	explicitly declined, since REM's per-event O(n^2) risk-set
	evaluation is structurally unlike ERGM's MCMC toggle-accept or
	SAOM's discrete ministeps, and a shared generic engine risks the
	same abstraction tax native/ergm_mcmc.c's own hot-loop work has
	spent real effort avoiding).

	Clean-room implementation against the published REM statistical
	framework (Butts, C.T. (2008). "A Relational Event Framework for
	Social Action." Sociological Methodology, 38(1), 155-200) and this
	project's own docs/REM_R_STUDY.md (which records what
	relevent::rem.dyad's likelihood/effects compute and why - verified
	directly against relevent's own public C source and empirical
	behavior on toy input, never copied from it). No relevent source
	code, comment, or identifier is present here - see
	docs/REM_PROVENANCE.md.

	Sourced live during development (`do unw_rem.do`), matching
	unw_saom.do's own convention - not yet compiled into
	lib/lnwcommands.mlib (see REM_ROADMAP.md's "one rebuild at the end,
	not mid-flight" rule).
*/

capture mata: mata drop RemState()
capture mata: mata drop RemFitUnit1()
capture mata: mata drop rem_loglik_unit1()
capture mata: mata drop rem_eval_unit1()

mata:
mata set matastrict off

/*
	RemState -- the sorted event stream plus incrementally-maintained
	per-actor cumulative in/out-degree, used by the unit-1 degree
	effects (NODSnd/NIDRec). Row i of cumindeg/cumoutdeg holds the
	cumulative degree from events 1..(i-1) ONLY (strictly prior
	history, no lookahead into event i itself) - this is the exact
	semantics docs/REM_R_STUDY.md section 3a empirically verified
	against relevent::acl.deg()'s own output on a toy sequence, not
	assumed from the "cumulative" naming alone.
*/
class RemState {
	real matrix events     // nevents x 3: (sender, receiver, time), SORTED ascending by time
	real scalar n          // number of actors
	real scalar nevents
	real matrix cumindeg   // nevents x n
	real matrix cumoutdeg  // nevents x n

	void init()
	void build_degree_accumulators()
}

void RemState::init(real matrix rawevents, real scalar nn) {
	real colvector ord
	real scalar k

	// REM's risk set is defined over i!=j dyads by convention (matching
	// relevent's own "selfloops are not permitted" - see
	// docs/REM_R_STUDY.md) - reject rather than silently drop, since a
	// silently-dropped self-loop event would change nevents without
	// the caller necessarily noticing.
	for (k=1; k<=rows(rawevents); k++) {
		if (rawevents[k,1] == rawevents[k,2]) {
			_error("nwrem: event " + strofreal(k) + " has sender == receiver (self-loop); relational event models are defined over i != j dyads only.")
		}
	}

	n = nn
	// get_eventlist() makes no ordering guarantee (confirmed by reading
	// unw_core.do's own nwattime_slice_event(), which scans unordered) -
	// the ordinal partial likelihood requires chronological order.
	ord = order(rawevents[.,3], 1)
	events = rawevents[ord,.]
	nevents = rows(events)
}

void RemState::build_degree_accumulators() {
	real scalar i, s, r
	cumindeg = J(nevents, n, 0)
	cumoutdeg = J(nevents, n, 0)
	for (i=2; i<=nevents; i++) {
		cumindeg[i,.] = cumindeg[i-1,.]
		cumoutdeg[i,.] = cumoutdeg[i-1,.]
		s = events[i-1,1]
		r = events[i-1,2]
		cumoutdeg[i,s] = cumoutdeg[i,s] + 1
		cumindeg[i,r] = cumindeg[i,r] + 1
	}
}

/*
	Unit 1 ordinal partial log-likelihood: NODSnd (sender's normalized
	out-degree) + NIDRec (receiver's normalized in-degree). theta =
	(theta_nodsnd, theta_nidrec) -- NO intercept term: an intercept is
	constant across the entire risk set at every event and cancels out
	exactly in the softmax normalizer below, exactly like Cox
	proportional-hazards models have no identifiable baseline-hazard
	intercept in their own partial likelihood. Found empirically while
	testing this exact function (optimize() reported "flat region
	encountered" for an intercept parameter; direct likelihood
	evaluation confirmed zero sensitivity to it) - see
	docs/REM_R_STUDY.md section 1b for the full account, including why
	this also explains why none of relevent's own 24 named effects is a
	generic intercept.

	For event i with realized sender s, receiver r:
	  ll_i = lrm[s,r] - log( sum over all (j,k), j!=k, of exp(lrm[j,k]) )
	where lrm[j,k] = theta_nodsnd*NODSnd_j(i) + theta_nidrec*NIDRec_k(i)
	-- the standard Cox-style partial likelihood (see
	docs/REM_R_STUDY.md section 2), verified against relevent's own
	drem_n2llik_R() structure (read to confirm, not copied).

	First-event convention (i=1, no prior events): NODSnd/NIDRec both
	defined as 1/(n-1) for every actor, exactly matching relevent's own
	explicit fallback for this case (see docs/REM_R_STUDY.md section 3a
	- corrected there too after this project's own earlier reading of
	a partial source excerpt wrongly concluded this was left undefined).

	Analytic gradient (implemented alongside the likelihood, not
	deferred as originally planned in docs/REM_R_STUDY.md section 5 -
	brought forward after observing wide estimate-to-estimate variance
	under numerical-gradient BFGS during unit-1's own simulate-then-
	recover testing; the analytic score is the standard multinomial-
	logit/Cox-partial-likelihood form: for each event, the realized
	dyad's own effect value minus its expectation under the risk set's
	own softmax distribution P):

	  d ll_i / d theta_nodsnd = NODSnd_s(i) - sum_j NODSnd_j(i) * P(j sends)
	  d ll_i / d theta_nidrec = NIDRec_r(i) - sum_k NIDRec_k(i) * P(k receives)

	where P(j sends) = rowsum of P over receivers, P(k receives) =
	colsum of P over senders - P itself being lrm's own softmax
	(exactly the same normalization the log-likelihood already
	computes, so both are produced together in one pass over events
	rather than recomputed separately).
*/
void rem_loglik_grad_unit1(real rowvector theta, pointer(class RemState scalar) scalar pS,
		real scalar ll, real rowvector grad) {
	real scalar i, s, r, priorn, mx, lrsum, j, n
	real rowvector nodsnd_i, nidrec_i
	real matrix lrm, P

	n = (*pS).n
	ll = 0
	grad = J(1, 2, 0)
	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]
		priorn = i - 1

		if (priorn == 0) {
			// CORRECTION (found on closer reading of relevent's C
			// source while implementing units 2/5): relevent does NOT
			// leave the first event as undefined 0/0, as this
			// project's own earlier read of a partial excerpt of
			// lambda() wrongly concluded (docs/REM_R_STUDY.md section
			// 3a's original text) - the full switch case has an
			// explicit `if(it>0){...}else{dv[j]=1.0/(nv-1.0)}` branch.
			// Matched exactly here now that the correct formula is
			// known, rather than keeping a knowingly-divergent choice
			// that was only ever motivated by a mistaken belief that
			// relevent's own behavior was undefined.
			nodsnd_i = J(1, n, 1 :/ (n - 1))
			nidrec_i = J(1, n, 1 :/ (n - 1))
		}
		else {
			nodsnd_i = (*pS).cumoutdeg[i,.] :/ priorn
			nidrec_i = (*pS).cumindeg[i,.] :/ priorn
		}

		// Mata's :+ does NOT broadcast an n x 1 column against a 1 x n
		// row into an outer-sum n x n matrix (unlike NumPy/R) -
		// replicate explicitly via matrix multiplication by a
		// conformable ones-vector instead, which is always
		// well-defined regardless of broadcast semantics.
		lrm = (theta[1] :* nodsnd_i') * J(1, n, 1) :+ J(n, 1, 1) * (theta[2] :* nidrec_i)
		for (j=1; j<=n; j++) lrm[j,j] = -1e300   // exclude j==k from the risk set

		mx = max(lrm)
		P = exp(lrm :- mx)
		lrsum = mx + ln(sum(P))
		ll = ll + (lrm[s,r] - lrsum)

		P = P :/ sum(P)   // proper softmax probability matrix over the risk set
		grad[1] = grad[1] + (nodsnd_i[s] - sum(nodsnd_i :* rowsum(P)'))
		grad[2] = grad[2] + (nidrec_i[r] - sum(nidrec_i :* colsum(P)))
	}
}

/*
	Pure log-likelihood wrapper (no gradient) - used by certification
	tests/diagnostics that only need the ll value at a given theta.
*/
real scalar rem_loglik_unit1(real rowvector theta, pointer(class RemState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	rem_loglik_grad_unit1(theta, pS, ll, grad)
	return(ll)
}

void rem_eval_unit1(real scalar todo, real rowvector theta, pointer(class RemState scalar) scalar pS,
		real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	rem_loglik_grad_unit1(theta, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	RemFitUnit1() -- fits the unit-1 model (NODSnd + NIDRec, no
	intercept - see rem_loglik_unit1()'s own comment for why) via
	Mata's own built-in optimize() (BFGS, numerical gradient for
	this first unit - see docs/REM_R_STUDY.md section 5 for why an
	external optimizer dependency is unnecessary and why an analytic
	gradient is deferred). Returns coefficients + SEs into Stata via
	st_matrix()/st_numscalar(), consumed by nwrem.ado.
*/
void RemFitUnit1(real matrix eventmat, real scalar n, string scalar bname, string scalar vname, string scalar llname) {
	class RemState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat
	real matrix V

	S = RemState()
	S.init(eventmat, n)
	S.build_degree_accumulators()

	// A starting value of exactly all-zero makes every off-diagonal
	// lrm cell numerically identical (flat), which can degenerate
	// optimize()'s finite-difference gradient probe at the very first
	// step ("flat region encountered") - a small nonzero perturbation
	// breaks the symmetry without biasing the result. Still not
	// bulletproof on its own: found via this project's own doc-example
	// testing that a genuinely tiny event count (e.g. 3 events on 3
	// actors, almost no degree variation to speak of) can still hit
	// the same "flat region" failure even with an analytic gradient
	// supplied. Rather than push a larger minimum-event-count
	// requirement onto every caller, retry with escalating starting
	// perturbations and, as a last resort, the derivative-free
	// Nelder-Mead technique (immune to this specific failure mode,
	// since it never evaluates a gradient) before giving up.
	// _optimize() (not optimize()) returns an error CODE instead of
	// throwing, via optimize_result_errorcode() - Mata has no
	// try/catch, this is the documented way to attempt something that
	// might fail and decide programmatically whether to retry.
	real scalar attempt, ok, errcode
	real matrix starts
	starts = (0.01,0.01 \ 0.3,-0.3 \ -0.3,0.3 \ 1,-1)
	ok = 0
	for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &rem_eval_unit1())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, 40)
		errcode = _optimize(S_opt)
		if (errcode == 0) {
			theta_hat = optimize_result_params(S_opt)
			ok = 1
		}
	}
	if (ok == 0) {
		// Last resort: Nelder-Mead never evaluates a gradient at all,
		// so it cannot hit this specific "flat region" failure mode -
		// slower to converge, only reached when every gradient-based
		// attempt above has already failed.
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &rem_eval_unit1())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, (0.01,0.01))
		optimize_init_argument(S_opt, 1, &S)
		optimize_init_technique(S_opt, "nm")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		theta_hat = optimize(S_opt)
	}
	V = optimize_result_V_oim(S_opt)

	st_matrix(bname, theta_hat)
	st_matrix(vname, V)
	st_numscalar(llname, optimize_result_value(S_opt))
}

/*
	Units 2 and 5, extended by unit 4's static covariate effects
	(CovSnd/CovRec/CovInt/CovEvent) and unit 3's recency-rank effects
	(RSndSnd/RRecSnd): a generalized multi-effect engine, replacing
	unit 1's hardcoded 2-parameter design now that a third effect
	FAMILY exists (inertia, unit 2) which is a genuine per-DYAD
	statistic, not decomposable into a sender-only + receiver-only
	marginal the way every unit-1/5 degree effect is. `active` selects
	which of 14 known effects (fixed order below) enter the model;
	theta has exactly sum(active) elements, in that same relative
	order. Every formula below was read from relevent's own C source
	(src/relevent.c's lambda()/logrm_rceff()/logrm_normint()/
	logrm_irr()/acl_adj()) to verify this project's own independent
	derivation - never copied into Mata (see docs/REM_PROVENANCE.md).

	Fixed effect order:
	  1  NODSnd     row(sender)    = out-degree share
	  2  NIDRec     col(receiver)  = in-degree share
	  3  NIDSnd     row(sender)    = in-degree share
	  4  NODRec     col(receiver)  = out-degree share
	  5  NTDegSnd   row(sender)    = total-degree share
	  6  NTDegRec   col(receiver)  = total-degree share
	  7  FrPSndSnd  dyad(j,k)      = fraction of j's own past SENDS that went to k
	  8  FrRecSnd   dyad(j,k)      = fraction of j's own past RECEIVES that came from k
	  9  CovSnd     row(sender)    = user-supplied per-actor covariate (static, unit 4)
	  10 CovRec     col(receiver)  = user-supplied per-actor covariate (static, unit 4)
	  11 CovInt     row+col(both)  = user-supplied per-actor covariate, ego AND alter, summed (static, unit 4)
	  12 CovEvent   dyad(j,k)      = user-supplied n x n pairwise covariate matrix (static, unit 4)
	  13 RSndSnd    dyad(j,k)      = 1/(recency rank of k among j's own past SENDS), 0 if j never sent to k
	  14 RRecSnd    dyad(j,k)      = 1/(recency rank of k among j's own past RECEIPTS), 0 if j never received from k

	Effects 1-6 (degree family, unit 1 + unit 5) use the SAME 1/(n-1)
	first-event fallback as rem_loglik_grad_unit1() - see that
	function's own comment for why (matches relevent exactly, corrected
	from an earlier misreading). Effects 7-8 (inertia family, unit 2)
	use relevent's own fallback for a zero denominator: coef/(n-1),
	the same uniform "nothing known yet" contribution degree effects
	use at i=1, applied here whenever the relevant marginal degree is
	still zero (not only at i=1 - e.g. an actor who has never sent
	anything yet has cumoutdeg==0 for FrPSndSnd's own denominator at
	ANY event, not just the first).

	Effects 9-11 (unit 4a, static covariates only - v1 scope, matching
	relevent's own `ctimed=FALSE` case): each takes its OWN independent
	per-actor covariate vector (covsndvec/covrecvec/covintvec - NOT
	forced to share one, since a real model may want e.g. "seniority
	affects sending" and "department affects receiving" as genuinely
	different variables at once, exactly as relevent's own covar$CovSnd/
	CovRec/CovInt are independent arrays). Pass J(1,n,0) for whichever
	vector(s) correspond to inactive effects - never read when
	active[e]==0.

	Effect 12 (unit 4b, CovEvent): relevent's own dyadic/pair
	covariate, mode=4 "event-wise" in logrm_rceff() (relevent's C
	source, read to verify - see docs/REM_PROVENANCE.md): unlike
	effects 9-11 (a per-actor value broadcast across rows or columns),
	CovEvent supplies an INDEPENDENT value for every ordered (j,k)
	dyad directly - `lrm[j,k] += theta*covevmat[j,k]`, no broadcasting
	at all. This is a genuinely different data shape (n x n, not
	1 x n), which is exactly why it was deferred out of unit 4a: it
	needed its own input path rather than reusing covsndvec's. Static
	only in v1 (matches relevent's own `ctimed=FALSE` case, same as
	effects 9-11) - pass J(n,n,0) when inactive, never read in that
	case.

	Effects 13-14 (unit 3, recency-rank): relevent's own
	`logrm_irr()`/`accum_rrl_R()` (read to verify, not copied) maintain,
	per actor, an ORDERED (most-recent-first) list of past contact
	partners and add `coef/rank` to the log-rate matrix for each -
	NOT a fraction like FrPSndSnd/FrRecSnd (effects 7-8, which use
	relative FREQUENCY of past contact) but a reciprocal RANK (only
	"how recently", never "how often"). Reimplemented here without
	relevent's own per-actor linked-list bookkeeping: an n x n
	`lastcontact` matrix (`lastcontact[j,k]` = the index of the most
	recent PRIOR event, if any, where j sent to k; 0 if never) is
	maintained incrementally (same "update AFTER using this event's
	own pre-event state" discipline as `cij`), and at each event the
	full per-effect matrix is built by RANKING each row (RSndSnd) or
	column (RRecSnd) of `lastcontact` via `rem_rank_reciprocal()`
	(below) - relevent's own `rrl$out`/`rrl$in` lists are exactly the
	same information (per-actor recency-ordered partner lists),
	reimplemented via a dense matrix + per-row/column sort since Mata
	has no convenient sparse ordered-list primitive to match relevent's
	own R-list-based approach. `lastcontact[j,k]` values are strictly
	increasing along a single actor's own real event history, so no
	value can tie with another for the SAME row/column, making rank a
	well-defined strict ordering; an actor never contacted (row/column
	entirely 0) contributes nothing to any candidate dyad - exactly
	relevent's own "empty list -> no lrm contribution" behavior at the
	very first event, generalized to every subsequent point where an
	actor still has no relevant history.

	theta-index mapping (which slot of the compacted theta/grad vector
	each active effect occupies) is computed ONCE before the event loop
	via idx[], not recomputed per (event, j, k) triple - correctness
	does not depend on this, but O(nevents*n^2) redundant colsum() calls
	would have been a real, easily-avoided cost.
*/
/*
	rem_rank_reciprocal() -- given a real colvector v (n x 1) of "last
	contact index" values (larger = more recent; 0 = never contacted),
	returns a real rowvector (1 x n) where entry k is 1/rank(v[k]) if
	v[k]>0 (rank 1 = the single largest/most-recent value among v's own
	nonzero entries), or 0 if v[k]==0. Shared by both RSndSnd (applied
	to a ROW of `lastcontact`) and RRecSnd (applied to a COLUMN) -
	same ranking logic either way, only which slice of `lastcontact` is
	passed in differs.
*/
real rowvector rem_rank_reciprocal(real colvector v) {
	real scalar nn, i, nz
	real colvector nzidx, ord
	real rowvector res

	nn = rows(v)
	res = J(1, nn, 0)
	nzidx = selectindex(v :> 0)
	nz = length(nzidx)
	if (nz > 0) {
		ord = order(v[nzidx], -1)   // descending: ord[1] indexes (within nzidx) the most recent contact
		for (i=1; i<=nz; i++) {
			res[nzidx[ord[i]]] = 1 :/ i
		}
	}
	return(res)
}
void rem_loglik_grad_multi(real rowvector theta, real rowvector active,
		real rowvector covsndvec, real rowvector covrecvec, real rowvector covintvec,
		real matrix covevmat,
		pointer(class RemState scalar) scalar pS, real scalar ll, real rowvector grad) {
	real scalar i, s, r, priorn, mx, lrsum, j, k, n, e, fallback
	real rowvector odeg_frac, ideg_frac, tdeg_frac, gradfull, idx
	real matrix lrm, P, cij, eff7mat, eff8mat, lastcontact, eff13mat, eff14mat

	n = (*pS).n
	ll = 0
	gradfull = J(1, 14, 0)
	cij = J(n, n, 0)   // cumulative i->j raw counts, strictly prior to event i (incremental)
	lastcontact = J(n, n, 0)   // lastcontact[j,k] = index of most recent PRIOR event where j sent to k (0 = never), incremental
	fallback = 1 :/ (n - 1)

	idx = J(1, 14, 0)
	j = 0
	for (e=1; e<=14; e++) {
		if (active[e]) {
			j = j + 1
			idx[e] = j
		}
	}

	for (i=1; i<=(*pS).nevents; i++) {
		s = (*pS).events[i,1]
		r = (*pS).events[i,2]
		priorn = i - 1

		if (priorn == 0) {
			odeg_frac = J(1, n, fallback)
			ideg_frac = J(1, n, fallback)
			tdeg_frac = J(1, n, fallback)
		}
		else {
			odeg_frac = (*pS).cumoutdeg[i,.] :/ priorn
			ideg_frac = (*pS).cumindeg[i,.] :/ priorn
			tdeg_frac = ((*pS).cumoutdeg[i,.] :+ (*pS).cumindeg[i,.]) :/ (2 * priorn)
		}

		// eff7mat[j,k] / eff8mat[j,k]: the inertia effect values for
		// EVERY candidate dyad at this event - built once per event
		// (not per j,k pair) since each row j only depends on j.
		if (active[7]) {
			eff7mat = J(n, n, fallback)
			for (j=1; j<=n; j++) {
				if ((*pS).cumoutdeg[i,j] != 0) eff7mat[j,.] = cij[j,.] :/ (*pS).cumoutdeg[i,j]
			}
		}
		if (active[8]) {
			eff8mat = J(n, n, fallback)
			for (j=1; j<=n; j++) {
				if ((*pS).cumindeg[i,j] != 0) eff8mat[j,.] = cij[.,j]' :/ (*pS).cumindeg[i,j]
			}
		}

		// eff13mat[j,k] (RSndSnd) / eff14mat[j,k] (RRecSnd): recency-rank
		// reciprocal effect matrices - RSndSnd ranks each ROW of
		// `lastcontact` (j's own past outgoing contacts); RRecSnd ranks
		// each COLUMN (j's own past incoming contacts, i.e. who has sent
		// TO j), same "rank a column, place into a row" pattern eff8mat
		// already uses for FrRecSnd above. No fallback for a never-
		// contacted actor (unlike effects 7-8's coef/(n-1)) - relevent's
		// own logrm_irr() contributes nothing at all for an empty
		// recency list, matched exactly via rem_rank_reciprocal()'s own
		// all-zero return in that case.
		if (active[13]) {
			eff13mat = J(n, n, 0)
			for (j=1; j<=n; j++) {
				eff13mat[j,.] = rem_rank_reciprocal(lastcontact[j,.]')
			}
		}
		if (active[14]) {
			eff14mat = J(n, n, 0)
			for (j=1; j<=n; j++) {
				eff14mat[j,.] = rem_rank_reciprocal(lastcontact[.,j])
			}
		}

		lrm = J(n, n, 0)
		if (active[1]) lrm = lrm :+ theta[idx[1]] :* odeg_frac' * J(1,n,1)
		if (active[2]) lrm = lrm :+ J(n,1,1) * (theta[idx[2]] :* ideg_frac)
		if (active[3]) lrm = lrm :+ theta[idx[3]] :* ideg_frac' * J(1,n,1)
		if (active[4]) lrm = lrm :+ J(n,1,1) * (theta[idx[4]] :* odeg_frac)
		if (active[5]) lrm = lrm :+ theta[idx[5]] :* tdeg_frac' * J(1,n,1)
		if (active[6]) lrm = lrm :+ J(n,1,1) * (theta[idx[6]] :* tdeg_frac)
		if (active[7]) lrm = lrm :+ theta[idx[7]] :* eff7mat
		if (active[8]) lrm = lrm :+ theta[idx[8]] :* eff8mat
		if (active[9]) lrm = lrm :+ theta[idx[9]] :* covsndvec' * J(1,n,1)
		if (active[10]) lrm = lrm :+ J(n,1,1) * (theta[idx[10]] :* covrecvec)
		if (active[11]) lrm = lrm :+ theta[idx[11]] :* (covintvec' * J(1,n,1) :+ J(n,1,1) * covintvec)
		if (active[12]) lrm = lrm :+ theta[idx[12]] :* covevmat
		if (active[13]) lrm = lrm :+ theta[idx[13]] :* eff13mat
		if (active[14]) lrm = lrm :+ theta[idx[14]] :* eff14mat
		for (j=1; j<=n; j++) lrm[j,j] = -1e300   // exclude j==k from the risk set

		mx = max(lrm)
		P = exp(lrm :- mx)
		lrsum = mx + ln(sum(P))
		ll = ll + (lrm[s,r] - lrsum)
		P = P :/ sum(P)

		// analytic gradient: realized effect value minus its
		// expectation under P, same structure as rem_loglik_grad_unit1
		if (active[1]) gradfull[1] = gradfull[1] + (odeg_frac[s] - sum(odeg_frac :* rowsum(P)'))
		if (active[2]) gradfull[2] = gradfull[2] + (ideg_frac[r] - sum(ideg_frac :* colsum(P)))
		if (active[3]) gradfull[3] = gradfull[3] + (ideg_frac[s] - sum(ideg_frac :* rowsum(P)'))
		if (active[4]) gradfull[4] = gradfull[4] + (odeg_frac[r] - sum(odeg_frac :* colsum(P)))
		if (active[5]) gradfull[5] = gradfull[5] + (tdeg_frac[s] - sum(tdeg_frac :* rowsum(P)'))
		if (active[6]) gradfull[6] = gradfull[6] + (tdeg_frac[r] - sum(tdeg_frac :* colsum(P)))
		if (active[7]) gradfull[7] = gradfull[7] + (eff7mat[s,r] - sum(eff7mat :* P))
		if (active[8]) gradfull[8] = gradfull[8] + (eff8mat[s,r] - sum(eff8mat :* P))
		if (active[9]) gradfull[9] = gradfull[9] + (covsndvec[s] - sum(covsndvec :* rowsum(P)'))
		if (active[10]) gradfull[10] = gradfull[10] + (covrecvec[r] - sum(covrecvec :* colsum(P)))
		if (active[11]) gradfull[11] = gradfull[11] + ((covintvec[s] + covintvec[r]) - sum((covintvec' * J(1,n,1) :+ J(n,1,1) * covintvec) :* P))
		if (active[12]) gradfull[12] = gradfull[12] + (covevmat[s,r] - sum(covevmat :* P))
		if (active[13]) gradfull[13] = gradfull[13] + (eff13mat[s,r] - sum(eff13mat :* P))
		if (active[14]) gradfull[14] = gradfull[14] + (eff14mat[s,r] - sum(eff14mat :* P))

		cij[s,r] = cij[s,r] + 1   // update AFTER using this event's own pre-event state
		lastcontact[s,r] = i     // update AFTER using this event's own pre-event state
	}

	grad = J(1, 0, 0)
	for (e=1; e<=14; e++) if (active[e]) grad = (grad, gradfull[e])
}

/*
	Pure log-likelihood wrapper for the multi-effect engine (no
	gradient) - used by certification tests/diagnostics, same role as
	rem_loglik_unit1() for the unit-1-only engine.
*/
real scalar rem_loglik_multi(real rowvector theta, real rowvector active,
		real rowvector covsndvec, real rowvector covrecvec, real rowvector covintvec,
		real matrix covevmat,
		pointer(class RemState scalar) scalar pS) {
	real scalar ll
	real rowvector grad
	rem_loglik_grad_multi(theta, active, covsndvec, covrecvec, covintvec, covevmat, pS, ll, grad)
	return(ll)
}

void rem_eval_multi(real scalar todo, real rowvector theta, pointer(real rowvector) scalar pActive,
		pointer(real rowvector) scalar pCovSnd, pointer(real rowvector) scalar pCovRec,
		pointer(real rowvector) scalar pCovInt, pointer(real matrix) scalar pCovEvent,
		pointer(class RemState scalar) scalar pS,
		real scalar y, real rowvector g, real matrix H) {
	real rowvector grad
	rem_loglik_grad_multi(theta, *pActive, *pCovSnd, *pCovRec, *pCovInt, *pCovEvent, pS, y, grad)
	if (todo >= 1) g = grad
}

/*
	RemFitMulti() -- generalized fit for any subset of the 11 effects
	above. `activevec` = 11-element 0/1 rowvector (fixed order, see
	rem_loglik_grad_multi()'s own header comment). `covsndvec'/
	`covrecvec'/`covintvec' are each a 1 x n per-actor covariate vector
	(pass J(1,n,0) for any not needed, matching whichever of
	active[9]/active[10]/active[11] are 0 - never read in that case).
	Same retry-then-Nelder-Mead robustness strategy as RemFitUnit1().
*/
void RemFitMulti(real matrix eventmat, real scalar n, real rowvector activevec,
		real rowvector covsndvec, real rowvector covrecvec, real rowvector covintvec,
		real matrix covevmat,
		string scalar bname, string scalar vname, string scalar llname) {
	class RemState scalar S
	transmorphic S_opt
	real rowvector theta0, theta_hat
	real matrix V
	real scalar nparams, attempt, ok, errcode
	real matrix starts

	S = RemState()
	S.init(eventmat, n)
	S.build_degree_accumulators()

	nparams = sum(activevec)
	if (nparams == 0) _error("nwrem: at least one effect must be selected.")

	// Performance fix (found via direct profiling, docs/REM_ROADMAP.md's
	// own "optimizer performance" entry): the multi-minute slowdown
	// observed when fitting several correlated degree effects together
	// was never about per-call cost at the SCALE this fix was originally
	// tuned on (n=8) - it was FAILING BFGS attempts each burning
	// 30-200+ internal iterations before finally giving up. Two changes
	// addressed this: (1) a hard iteration cap per attempt, so a
	// genuinely bad starting point fails in a bounded number of
	// iterations instead of grinding for ones that were never going to
	// converge; (2) small, FIXED-magnitude random perturbations
	// (previously scaled up to +-0.8 per dimension by the final
	// attempt) rather than escalating ones - large simultaneous
	// perturbations across several correlated parameters push the
	// log-rate matrix into numerically extreme territory that plausibly
	// caused some of the "flat region" failures directly, independent
	// of the iteration-count problem.
	//
	// CORRECTED, found via real repeated-run wall-clock benchmarking at
	// a LARGER scale than the original fix was tuned on (n=30, 2000
	// events, 8 degree/inertia effects together, dev/rem_benchmark_multi.do):
	// the original comment's own claim that a single likelihood/gradient
	// evaluation is "essentially free (<1ms)" is WRONG at this scale -
	// directly profiled at ~97.5ms per evaluation on this exact dataset,
	// two orders of magnitude higher than assumed. That single wrong
	// number invalidated the original cap's own reasoning: a "cheap,
	// fails-fast" 40-iteration attempt actually costs ~4 seconds here,
	// not a fraction of one, so a bad-luck run exhausting many attempts
	// (worse still, tripling `nstarts` in an EARLIER version of this
	// fix, since more expensive attempts is not the same improvement as
	// more cheap ones) could still run for minutes. The corrected
	// values below are chosen from what this same profiling run showed
	// directly: a SUCCESSFUL attempt converges in roughly 11-15
	// iterations, so `maxiter=20` gives real convergence a comfortable
	// margin while capping a truly failing attempt's own cost near two
	// seconds, not four; `nstarts=16` (matching the ORIGINAL n=8-scale
	// tuning, not the since-reverted 48) keeps the worst-case BFGS+NR
	// cost bounded near a minute even if every single attempt fails,
	// which the Nelder-Mead fallback below's own tightened cap then
	// backstops. Reusing the SAME already-tuned magnitude schedule
	// (0.15 to 2.4 across the 16 attempts) rather than extending to
	// LARGER untested perturbations - a larger magnitude range is
	// exactly what this fix's own first paragraph already found can
	// cause more "flat region" failures directly, not fewer.
	real scalar maxiter, nstarts
	maxiter = 20
	nstarts = 16
	starts = J(nstarts, nparams, 0)
	for (attempt=1; attempt<=nstarts; attempt++) {
		starts[attempt,.] = (runiform(1,nparams) :- 0.5) :* (0.15 * (mod(attempt-1, 16) + 1))
	}

	ok = 0
	for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
		theta0 = starts[attempt,.]
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &rem_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, theta0)
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &covsndvec)
		optimize_init_argument(S_opt, 3, &covrecvec)
		optimize_init_argument(S_opt, 4, &covintvec)
		optimize_init_argument(S_opt, 5, &covevmat)
		optimize_init_argument(S_opt, 6, &S)
		optimize_init_technique(S_opt, "bfgs")
		optimize_init_which(S_opt, "max")
		optimize_init_tracelevel(S_opt, "none")
		optimize_init_conv_warning(S_opt, "off")
		optimize_init_conv_maxiter(S_opt, maxiter)
		errcode = _optimize(S_opt)
		if (errcode == 0) {
			theta_hat = optimize_result_params(S_opt)
			ok = 1
		}
	}
	if (ok == 0) {
		// Newton-Raphson before Nelder-Mead: still gradient-based (so
		// still fast/precise), but a different step-selection strategy
		// than BFGS - worth trying before falling back to a
		// derivative-free method entirely.
		for (attempt=1; attempt<=rows(starts) & ok==0; attempt++) {
			theta0 = starts[attempt,.]
			S_opt = optimize_init()
			optimize_init_evaluator(S_opt, &rem_eval_multi())
			optimize_init_evaluatortype(S_opt, "d1")
			optimize_init_params(S_opt, theta0)
			optimize_init_argument(S_opt, 1, &activevec)
			optimize_init_argument(S_opt, 2, &covsndvec)
			optimize_init_argument(S_opt, 3, &covrecvec)
			optimize_init_argument(S_opt, 4, &covintvec)
			optimize_init_argument(S_opt, 5, &covevmat)
			optimize_init_argument(S_opt, 6, &S)
			optimize_init_technique(S_opt, "nr")
			optimize_init_which(S_opt, "max")
			optimize_init_tracelevel(S_opt, "none")
			optimize_init_conv_warning(S_opt, "off")
			optimize_init_conv_maxiter(S_opt, maxiter)
			errcode = _optimize(S_opt)
			if (errcode == 0) {
				theta_hat = optimize_result_params(S_opt)
				ok = 1
			}
		}
	}
	if (ok == 0) {
		// Last resort: derivative-free Nelder-Mead, given a genuinely
		// spread-out (not uniform) starting vector so its own initial
		// simplex construction has real variation to work with.
		//
		// PERFORMANCE FIX (found via real benchmark timing, not assumed:
		// the ORIGINAL version of this comment claimed NM "does not
		// suffer the same many-wasted-iterations failure mode" as
		// BFGS/NR and left it uncapped - wrong, in a different way than
		// BFGS/NR's own failure mode. BFGS/NR waste iterations on a bad
		// START; NM can waste iterations CONVERGING SLOWLY along a
		// genuinely flat ridge (docs/REM_ROADMAP.md's own degree-effect
		// collinearity finding) even from a perfectly good start,
		// since derivative-free methods are inherently slow to converge
		// along a flat direction. Confirmed directly: repeated real
		// 8-effect benchmark runs on identical data (dev/rem_benchmark_multi.do)
		// varied from ~8s to over 100s run to run - the slow runs were
		// falling through to this exact uncapped NM stage, each
		// iteration costing real time at this dataset's own scale
		// (n=30, 2000 events: ~97.5ms per likelihood/gradient
		// evaluation, directly profiled - the BFGS/NR fix above's own
		// updated comment has the full account of why the ORIGINAL
		// "essentially free" assumption this whole file's performance
		// tuning rested on was wrong at this scale). A cap of 300
		// iterations (~30 seconds worst case at this per-iteration
		// cost, comfortably more than any successful convergence this
		// package's own testing has ever needed) bounds worst-case
		// runtime; if it is not enough, `optimize()` raises a clear
		// Mata "convergence not achieved" error rather than running
		// indefinitely - a bounded, legible failure is a better outcome
		// for a real caller than an unbounded slow success.
		S_opt = optimize_init()
		optimize_init_evaluator(S_opt, &rem_eval_multi())
		optimize_init_evaluatortype(S_opt, "d1")
		optimize_init_params(S_opt, starts[rows(starts),.])
		optimize_init_argument(S_opt, 1, &activevec)
		optimize_init_argument(S_opt, 2, &covsndvec)
		optimize_init_argument(S_opt, 3, &covrecvec)
		optimize_init_argument(S_opt, 4, &covintvec)
		optimize_init_argument(S_opt, 5, &covevmat)
		optimize_init_argument(S_opt, 6, &S)
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

end
