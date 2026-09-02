
capture program drop nwdynam
program nwdynam, eclass
	version 14
	syntax [anything(name=netname)] [, SUBMODEL(string) INERTIA RECIP INDEG OUTDEG TRANS CYCLE COMMONSENDER COMMONRECEIVER FOUR NODETRANS SAME(varname numeric) DIFF(varname numeric) SIM(varname numeric) EGO(varname numeric) ALTER(varname numeric) TERTIUS(varname numeric) EGOALTERINT(varlist numeric min=2 max=2) INERTIAWINDOW(real -1) RECIPWINDOW(real -1) INDEGWINDOW(real -1) OUTDEGWINDOW(real -1) WEIGHTEDINERTIA WEIGHTEDRECIP WEIGHTEDINDEG WEIGHTEDOUTDEG OPPORTUNITIES(varlist numeric min=2 max=2) TIE(string) INTERCEPT SEED(integer -1)]
	set more off

	nw_syntax `netname', max(1)

	// `__nwdynam_n1' (mode-1 actor count, contiguous indices 1..n1 in
	// this package's own combined actor-index convention) - 0 sentinel
	// for "not two-mode", matching this file's own -1/1e300 "not given"
	// sentinel conventions elsewhere. Extracted unconditionally right
	// after nw_syntax (cheap even when unused) since both the two-mode
	// effect-eligibility checks below and the Mata dispatch at the very
	// end need it.
	if "`is2mode'" == "true" {
		mata: st_numscalar("__nwdynam_n1", `netobj'->get_nodes_mode1())
		local __nwdynam_n1 = __nwdynam_n1
		scalar drop __nwdynam_n1
	}
	else {
		local __nwdynam_n1 = 0
	}

	if "`istemporal'" != "true" | "`temporaltype'" != "event" {
		di as error "nwdynam requires a network declared via nwset's eventtime() option (an event-type temporal network) - see {help nwset##temporal:nwset}."
		error 198
	}

	// Unit 1 (choice) and Unit 2 (rate, NO intercept) are both
	// implemented - see unw_dynam.do's own header CORRECTION comment
	// for why the rate sub-model turned out to be tractable without
	// real timestamps after all (an ordinal partial likelihood over
	// the sender risk set, same convention as {help nwrem} and this
	// command's own choice sub-model), once no intercept is requested.
	// A WITH-INTERCEPT rate model is a genuinely different, harder
	// continuous-time hazard (confirmed directly from goldfish's own
	// teaching1.Rmd vignette - an intercept-only rate model's own
	// log-likelihood is sensitive to the actual scale of elapsed time)
	// and remains explicitly deferred - there is no way to request an
	// intercept from this command yet, so it is never silently dropped
	// rather than fit. choice_coordination ("expansion batch 11",
	// resolved 2026-09-02, user: "do choice_coordination now") is
	// goldfish's own THIRD DyNAM sub-model - a genuinely different
	// "multinomial-multinomial" joint likelihood over unordered actor
	// pairs (Stadtfeld, Hollway & Block 2017), for undirected
	// ("coordination") tie-formation events, not a flag on choice - see
	// unw_dynam.do's own header comment (above dynam_coord_loglik_
	// grad_multi()) for the formula and its real-goldfish verification.
	if "`submodel'" == "" local submodel "choice"
	if !inlist("`submodel'", "choice", "rate", "choice_coordination") {
		di as error "submodel() must be choice, rate, or choice_coordination - see {help nwdynam}."
		error 198
	}

	// Two-mode (bipartite) networks (added 2026-09-02, "expansion batch
	// 9" - user: "continue"). Previously rejected outright, matching
	// nwrem.ado's own guard - but that guard's own stated reason
	// ("nwset's own twomode/eventtime() composability wasn't available
	// yet") was resolved 2026-08-31 (see docs/ROADMAP.md's "Two-mode/
	// temporal architecture initiative"), and unw_dynam.do's own
	// 14-effect Multi engine was never actually checked against a
	// two-mode dyad space until now - it has been, directly against
	// real goldfish (see unw_dynam.do's own header comment on the
	// choice/rate engines for the exact verification and the REAL,
	// goldfish-side per-effect eligibility found - NOT the same as
	// goldfish's own documented `isTwoMode` column, which several
	// direct tests contradicted). goldfish's own architecture assumes
	// a STRICTLY ONE-DIRECTIONAL bipartite dependent network - every
	// event's sender is drawn from node set 1, every receiver from node
	// set 2, never the reverse - matching this package's own
	// contiguous mode-1-then-mode-2 combined actor-index convention
	// (mode 1 = indices 1..n1, mode 2 = n1+1..n, established by
	// nwset's own bipartite ingestion, already reused by nwergm's own
	// bipartite() support). Validated below, once the real event data
	// is available, rather than assumed.
	// choice/rate v1 scope (docs/DYNAM_ROADMAP.md scope decision 1,
	// resolved 2026-09-02): directed-only. A two-mode network reports
	// `directed' == false from nw_syntax (confirmed directly - ERGM's
	// own bipartite convention, where ties have no inherent direction),
	// even though a two-mode DyNAM event network IS inherently
	// directional in the sender/receiver sense goldfish itself assumes
	// (mode 1 always sends, mode 2 always receives) - so the `directed'
	// check is skipped for two-mode networks under choice/rate and real
	// event-level directionality is validated separately below instead,
	// once the actual event data is read.
	// choice_coordination v1 scope (resolved 2026-09-02): the OPPOSITE
	// requirement - a genuinely UNDIRECTED, ONE-MODE network (goldfish's
	// own coordination model is defined over an undirected dependent
	// network; two-mode coordination is a real, disclosed gap - see
	// unw_dynam.do's own header comment on DynamCoordFitMulti for why
	// its own P=p.*p' joint construction needs the actor-1/actor-2
	// candidate pools to be the SAME size, not yet investigated for this
	// package's own two-mode convention).
	if "`submodel'" == "choice_coordination" {
		if "`is2mode'" == "true" {
			di as error "submodel(choice_coordination) does not yet support two-mode (bipartite) networks - see {help nwdynam}."
			error 198
		}
		if "`directed'" == "true" {
			di as error "submodel(choice_coordination) requires an UNDIRECTED network (goldfish's own coordination model is for undirected tie-formation events) - declare `netname' via {opt nwset ..., undirected eventtime()} - see {help nwdynam}."
			error 198
		}
	}
	else if "`directed'" != "true" & "`is2mode'" != "true" {
		di as error "nwdynam requires a directed network for submodel(choice) or submodel(rate) - see {help nwdynam}."
		error 198
	}

	// Effect selection (docs/DYNAM_ROADMAP.md's own "effect selection"
	// scope item, resolved 2026-09-02) - each sub-model's own fixed
	// effect list is individually selectable via a boolean flag (or,
	// for the attribute effects added below, a valued option) per
	// effect, matching nwrem.ado's own per-effect-flag convention.
	// `indeg` means something different in each sub-model (the
	// candidate RECEIVER's own in-degree for choice, "alter" type; the
	// candidate SENDER's own in-degree for rate, "ego" type - see
	// {help nwdynam}) - the SAME flag name is reused deliberately
	// (matching goldfish's own indeg() effect, whose type is likewise
	// inferred from context, not a separate option), not two
	// differently-named options for what the reference implementation
	// itself treats as one effect family. Giving NO effect option at
	// all preserves nwdynam's own original behavior exactly (all of
	// the chosen sub-model's STRUCTURAL effects fit together) - flags
	// are for narrowing the set, not a mandatory selection the way
	// {help nwrem}'s own effect options are (nwrem never had an
	// all-effects default to preserve; nwdynam already did, before this
	// option existed, so silently requiring explicit selection now
	// would be a breaking change).
	//
	// same()/diff()/sim()/ego()/alter() (docs/DYNAM_ROADMAP.md's "effect
	// expansion" scope item, added 2026-09-02) are VALUED options, not
	// booleans, and - matching goldfish's own effect table exactly -
	// each applies to exactly ONE sub-model: same()/diff()/sim()/alter()
	// choice only (there is no rate-side "same actor as themselves"
	// concept for the dyadic same/diff/sim effects; alter() is
	// dyadic-adjacent - "the candidate's own value" - but still
	// choice-only per goldfish's own table); ego() rate only. `ego()`
	// and `alter()` are the SAME underlying idea (a candidate's own
	// static covariate value, no comparison to anyone) under
	// goldfish's own DIFFERENT names for whichever sub-model's own
	// candidate role it is ("ego" for the rate sub-model's candidate
	// sender; "alter" for the choice sub-model's candidate receiver) -
	// not this package's own naming choice. Unlike the structural
	// flags, none of these five are ever included by the "give
	// nothing, get everything" default (a variable name cannot have a
	// sensible default) - only ever active when a variable is actually
	// named.
	if "`submodel'" == "choice" {
		if "`ego'" != "" {
			di as error "ego() is a rate sub-model effect ({bf:submodel(rate)}), not available with submodel(choice) - see {help nwdynam}."
			error 198
		}
		// outdeg (added 2026-09-02, "expansion batch 5" - user checked
		// this file's own help text against goldfish and found
		// "outdeg: rate sub-model only" WRONG; goldfish's own effect
		// table lists outdeg as valid for BOTH sub-models. `outdeg'
		// means something different in each, exactly like `indeg'
		// already does (candidate RECEIVER's own out-degree here,
		// "alter" type; candidate SENDER's own out-degree under
		// submodel(rate), "ego" type - see unw_dynam.do's own header
		// comment) - the same flag name is reused deliberately, not two
		// differently-named options.
		//
		// trans/cycle/commonsender/commonreceiver/four/nodetrans
		// (added 2026-09-02, "expansion batch 6" - user: "work your way
		// through the list", a systematic audit against goldfish's FULL
		// effect catalog). The first five are genuinely choice-only per
		// goldfish's own table (two-path closure statistics, dyadic);
		// `nodetrans' is - like `indeg'/`outdeg' - valid under BOTH
		// sub-models (same flag name reused deliberately, same
		// convention as those two).
		//
		// egoalterint()/tertius() (added 2026-09-02, "expansion batch
		// 7", continuing the same audit). `egoalterint()' is
		// choice-only (needs both a sender and a candidate role, same
		// structural reason as inertia/recip/same/diff/sim - see
		// unw_dynam.do's own header comment); `tertius()' - like
		// `indeg'/`outdeg'/`nodetrans' - is valid under BOTH sub-models.
		local __nwdynam_effnames "inertia recip indeg same diff sim alter outdeg trans cycle commonsender commonreceiver four nodetrans egoalterint tertius tie"
		local __nwdynam_defaulteffs "inertia recip indeg"
	}
	else if "`submodel'" == "rate" {
		if "`inertia'`recip'`same'`diff'`sim'`alter'`trans'`cycle'`commonsender'`commonreceiver'`four'`egoalterint'`tie'" != "" {
			di as error "inertia/recip/same()/diff()/sim()/alter()/trans/cycle/commonsender/commonreceiver/four/egoalterint()/tie() are choice sub-model effects ({bf:submodel(choice)}), not available with submodel(rate) - see {help nwdynam}."
			error 198
		}
		local __nwdynam_effnames "indeg outdeg ego nodetrans tertius"
		local __nwdynam_defaulteffs "indeg outdeg"
	}
	else {
		// choice_coordination ("expansion batch 11", 2026-09-02): twelve
		// effects, chosen because each is confirmed BOTH real-
		// goldfish-eligible for choice_coordination (checked directly,
		// not trusted from goldfish's own self-contradicting vignette
		// table - see unw_dynam.do's own header comment on
		// dynam_coord_loglik_grad_multi()) AND already buildable from a
		// reusable state matrix or per-actor covariate in this engine.
		// `recip'/`outdeg'/`cycle'/`commonsender'/`commonreceiver'/
		// `ego' are all confirmed REJECTED by real goldfish for
		// choice_coordination (recip/outdeg structurally make no sense
		// for an undirected tie - no direction to reciprocate, indeg and
		// outdeg coincide). `nodetrans'/`trans' ("batch 12", 2026-09-02),
		// `tertius()'/`four' ("batch 13", 2026-09-02), `egoalterint()'
		// ("batch 14", 2026-09-02, completing the original batch 11
		// eligibility sweep), and `tie()' ("batch 16", 2026-09-02,
		// extending batch 15's own cross-network capability - the
		// simplest possible addition here, since the coordination engine
		// already needs the FULL n x n statistic matrix for every
		// effect, so `S_tie' is literally `tiemat' itself) complete this
		// engine's own currently-wired effect set. `tertiusDiff'/
		// `mixedTrans' remain real-goldfish-eligible but not yet wired -
		// a real, disclosed gap, not a blanket restriction.
		if "`recip'`outdeg'`cycle'`commonsender'`commonreceiver'`ego'" != "" {
			di as error "recip/outdeg/cycle/commonsender/commonreceiver/ego() are not available with submodel(choice_coordination) - only inertia/indeg/same()/diff()/sim()/alter()/nodetrans/trans/tertius()/four/egoalterint()/tie() are wired for this sub-model so far (a real, disclosed gap for tertiusDiff/mixedTrans) - see {help nwdynam}."
			error 198
		}
		local __nwdynam_effnames "inertia indeg same diff sim alter nodetrans trans tertius four egoalterint tie"
		local __nwdynam_defaulteffs "inertia indeg"
	}

	// Two-mode effect eligibility (added 2026-09-02, "expansion batch
	// 9"). goldfish's own DOCUMENTED `isTwoMode` column (per its own
	// doc/goldfishEffects.Rmd) turned out NOT to reliably predict which
	// effects actually work on a two-mode network - direct testing
	// against real goldfish found several effects the table marks
	// eligible (`recip`, `outdeg` choice-side, `commonReceiver`,
	// `indeg` rate-side) hard-REJECTED by goldfish's own engine at
	// runtime, each with a genuine structural reason: goldfish's own
	// two-mode DyNAM architecture is STRICTLY one-directional (mode 1
	// only ever sends, mode 2 only ever receives), so any effect that
	// would need mode 1's own in-ties or mode 2's own out-ties is
	// undefined (there are none, by construction) - `recip` (does the
	// candidate have a tie BACK to the sender - impossible, mode 2
	// never sends), `outdeg` choice-side (candidate's own out-degree -
	// impossible, mode 2 never sends), `commonReceiver`/`indeg`
	// rate-side both need the SAME missing role. A few effects goldfish
	// DOES accept for two-mode (`commonSender`, `four`) gave
	// non-degenerate fits that naive risk-set-only reasoning could not
	// explain, matching goldfish's own doc warning ("we omit the
	// difference in the computation of the statistics when isTwoMode
	// is used") - some effects genuinely redefine their own formula for
	// two-mode. This was confirmed to run DEEPER than expected: direct
	// comparison against goldfish's own reconstructed statistics
	// (`preprocessingOnly=TRUE`, same technique as the `four()`/
	// `tertius()` fixes elsewhere in this file) found `same()` and
	// `ego()` ALSO silently wrong under the naive combined-vector
	// approach originally attempted here - goldfish's own internal
	// two-mode array applies its usual "zero the self-tie" convention
	// by raw ROW-INDEX-EQUALS-COLUMN-INDEX matching even though row and
	// column span two GENUINELY DIFFERENT node sets in a two-mode
	// network (so e.g. person-index-1 vs org-index-1 gets zeroed as if
	// they were "the same actor," despite being different actors in
	// different modes) - a real goldfish-internal representation detail
	// that could not be confidently reverse-engineered in the time
	// available. Given this, EVERY attribute effect (`same`/`diff`/
	// `sim`/`alter`/`ego`/`egoalterint`/`tertius`) is rejected for
	// two-mode, not just the structurally-impossible ones - disclosed
	// as a genuine unresolved gap, not silently shipped with an
	// unverified formula. Verified WORKING and implemented, with an
	// EXACT numerical match to real goldfish: `inertia`, `indeg`
	// (choice, alter type), `outdeg` (rate, ego type) - see
	// unw_dynam.do's own header comment for the numbers.
	// `nodeTrans`/`trans`/`cycle` are excluded per goldfish's own
	// `isTwoMode=×` table entries (not independently re-verified, since
	// every OTHER table entry that WAS re-verified turned out
	// unreliable in at least one direction - disclosed, not assumed
	// safe either way). Windowed and weighted effects are not yet
	// verified for two-mode at all - rejected outright rather than
	// silently combined.
	if "`is2mode'" == "true" {
		if "`submodel'" == "choice" {
			local __nwdynam_defaulteffs "inertia indeg"
			if "`recip'" != "" {
				di as error "recip is not supported for two-mode (bipartite) networks - goldfish itself rejects it (mode 2 never sends, so a candidate can never have a tie back to the sender) - see {help nwdynam}."
				error 198
			}
			if "`outdeg'" != "" {
				di as error "outdeg is not supported for two-mode (bipartite) networks under submodel(choice) - goldfish itself rejects it (mode 2 never sends, so a candidate has no out-degree) - see {help nwdynam}."
				error 198
			}
			foreach __nwdynam_e in trans cycle commonsender commonreceiver four nodetrans tertius same diff sim alter egoalterint {
				if "``__nwdynam_e''" != "" {
					di as error "`__nwdynam_e' is not yet verified for two-mode (bipartite) networks - see {help nwdynam}."
					error 198
				}
			}
		}
		else {
			local __nwdynam_defaulteffs "outdeg"
			if "`indeg'" != "" {
				di as error "indeg is not supported for two-mode (bipartite) networks under submodel(rate) - goldfish itself rejects it (mode 1 never receives, so a candidate sender has no in-degree) - see {help nwdynam}."
				error 198
			}
			foreach __nwdynam_e in nodetrans tertius ego {
				if "``__nwdynam_e''" != "" {
					di as error "`__nwdynam_e' is not yet verified for two-mode (bipartite) networks - see {help nwdynam}."
					error 198
				}
			}
		}
		if `inertiawindow' != -1 | `recipwindow' != -1 | `indegwindow' != -1 | `outdegwindow' != -1 {
			di as error "windowed effects are not yet verified for two-mode (bipartite) networks - see {help nwdynam}."
			error 198
		}
		if "`weightedinertia'`weightedrecip'`weightedindeg'`weightedoutdeg'" != "" {
			di as error "weighted effects are not yet verified for two-mode (bipartite) networks - see {help nwdynam}."
			error 198
		}
	}

	// inertiawindow()/recipwindow() (docs/DYNAM_ROADMAP.md's "effect
	// expansion" scope item, batch 3, added 2026-09-02 - user request
	// "implement window effects," REDESIGNED twice after user feedback:
	// first to two independent plain options (a nested suboption
	// syntax, e.g. inertia(window(#)), "does not feel like Stata or
	// the rest of nwcommands"), then a second time so that GIVING the
	// window option is itself sufficient to activate its own effect -
	// "handle it how we handled gwesp in nwergm... recipwindow would
	// not require recip." Matching {help nwergm}'s own `gwesp(real)`
	// convention exactly: there is no separate "include gwesp" flag,
	// giving `gwesp(0.5)` both selects the term AND sets its own
	// parameter in one step - `inertiawindow(#)`/`recipwindow(#)` now
	// work the same way for `inertia`/`recip`. `-1` sentinel = "not
	// given," matching {opt seed()}'s own established convention in
	// this same file.
	local __nwdynam_windowinertia = 1e300
	local __nwdynam_windowrecip = 1e300
	if `inertiawindow' != -1 {
		if "`submodel'" != "choice" {
			di as error "inertiawindow() only applies to the choice sub-model's inertia effect - see {help nwdynam}."
			error 198
		}
		if `inertiawindow' <= 0 {
			di as error "inertiawindow() must be a positive number (in the same time units as the network's own eventtime())."
			error 198
		}
		local __nwdynam_windowinertia = `inertiawindow'
		local inertia "inertia"
	}
	if `recipwindow' != -1 {
		if "`submodel'" != "choice" {
			di as error "recipwindow() only applies to the choice sub-model's recip effect - see {help nwdynam}."
			error 198
		}
		if `recipwindow' <= 0 {
			di as error "recipwindow() must be a positive number (in the same time units as the network's own eventtime())."
			error 198
		}
		local __nwdynam_windowrecip = `recipwindow'
		local recip "recip"
	}

	// indegwindow()/outdegwindow() (added 2026-09-02, user follow-up
	// "can we make [window] also available for the rate part of the
	// model?", immediately after inertiawindow()/recipwindow()'s own
	// gwesp-style self-activation redesign): the SAME self-activating
	// convention, for the rate sub-model's own indeg/outdeg effects.
	// goldfish's own doc/goldfishEffects.Rmd effect table confirms
	// `window` is a real argument on indeg/outdeg and that both apply to
	// the rate sub-model (see unw_dynam.do's own
	// dynam_rate_loglik_grad_multi() header comment for the exact
	// formula and its real-goldfish verification). Rate-only, matching
	// inertiawindow()/recipwindow()'s own choice-only restriction (the
	// SAME flag name `indeg` already means a different thing per
	// sub-model - see the effect-selection comment above - so
	// indegwindow() is unambiguous once restricted to submodel(rate)).
	local __nwdynam_windowindeg = 1e300
	local __nwdynam_windowoutdeg = 1e300
	if `indegwindow' != -1 {
		if "`submodel'" != "rate" {
			di as error "indegwindow() only applies to the rate sub-model's indeg effect - see {help nwdynam}."
			error 198
		}
		if `indegwindow' <= 0 {
			di as error "indegwindow() must be a positive number (in the same time units as the network's own eventtime())."
			error 198
		}
		local __nwdynam_windowindeg = `indegwindow'
		local indeg "indeg"
	}
	if `outdegwindow' != -1 {
		if "`submodel'" != "rate" {
			di as error "outdegwindow() only applies to the rate sub-model's outdeg effect - see {help nwdynam}."
			error 198
		}
		if `outdegwindow' <= 0 {
			di as error "outdegwindow() must be a positive number (in the same time units as the network's own eventtime())."
			error 198
		}
		local __nwdynam_windowoutdeg = `outdegwindow'
		local outdeg "outdeg"
	}

	// weightedinertia/weightedrecip/weightedindeg/weightedoutdeg (added
	// 2026-09-02, "expansion batch 8" - user: "work your way through
	// the list"): goldfish's own `weighted=TRUE' argument on
	// inertia/recip/indeg/outdeg - the effect reads the cumulative
	// COUNT of prior events for that dyad/actor instead of binary
	// presence. Self-activating, matching inertiawindow()/recipwindow()'s
	// own gwesp-style convention exactly - no separate boolean flag
	// needed. `weightedindeg'/`weightedoutdeg' are valid under BOTH
	// sub-models (goldfish's own table confirms this, unlike
	// indegwindow()/outdegwindow() which remain rate-only - a real,
	// disclosed choice-side windowing gap, not a weighted one).
	// Mutually exclusive with that SAME effect's own window - not yet
	// verified together against goldfish, so rejected outright rather
	// than silently picking one.
	local __nwdynam_weightedinertia = 0
	local __nwdynam_weightedrecip = 0
	local __nwdynam_weightedindeg = 0
	local __nwdynam_weightedoutdeg = 0
	if "`weightedinertia'" != "" {
		if "`submodel'" != "choice" {
			di as error "weightedinertia only applies to the choice sub-model's inertia effect - see {help nwdynam}."
			error 198
		}
		if `__nwdynam_windowinertia' < 1e300 {
			di as error "weightedinertia cannot be combined with inertiawindow() - see {help nwdynam}."
			error 198
		}
		local __nwdynam_weightedinertia = 1
		local inertia "inertia"
	}
	if "`weightedrecip'" != "" {
		if "`submodel'" != "choice" {
			di as error "weightedrecip only applies to the choice sub-model's recip effect - see {help nwdynam}."
			error 198
		}
		if `__nwdynam_windowrecip' < 1e300 {
			di as error "weightedrecip cannot be combined with recipwindow() - see {help nwdynam}."
			error 198
		}
		local __nwdynam_weightedrecip = 1
		local recip "recip"
	}
	if "`weightedindeg'" != "" {
		if "`submodel'" == "choice_coordination" {
			di as error "weightedindeg is not yet supported for submodel(choice_coordination) - a real, disclosed v1 gap - see {help nwdynam}."
			error 198
		}
		if "`submodel'" == "rate" & `__nwdynam_windowindeg' < 1e300 {
			di as error "weightedindeg cannot be combined with indegwindow() - see {help nwdynam}."
			error 198
		}
		local __nwdynam_weightedindeg = 1
		local indeg "indeg"
	}
	if "`weightedoutdeg'" != "" {
		if "`submodel'" == "choice_coordination" {
			di as error "weightedoutdeg is not available with submodel(choice_coordination) - outdeg itself is not either (indeg and outdeg coincide for an undirected network) - see {help nwdynam}."
			error 198
		}
		if "`submodel'" == "rate" & `__nwdynam_windowoutdeg' < 1e300 {
			di as error "weightedoutdeg cannot be combined with outdegwindow() - see {help nwdynam}."
			error 198
		}
		local __nwdynam_weightedoutdeg = 1
		local outdeg "outdeg"
	}

	// intercept ("expansion batch 17", 2026-09-02, continuing the
	// goldfish-comparison list) - the genuinely continuous-time
	// competing-risks hazard variant this file's own header comment
	// always described as deferred. Unlike the NO-intercept rate model
	// (which reduces to the same ordinal partial likelihood as
	// everything else in this package, using only event ORDER, never
	// real elapsed time), giving `intercept' makes the model genuinely
	// sensitive to the ACTUAL SCALE of elapsed real time between events
	// (`netname''s own eventtime() values) - matching goldfish's own
	// `dep ~ 1 + ...' convention (a literal `1' as the first formula
	// term requests an intercept; verified directly against goldfish's
	// own `parseIntercept()' source). submodel(rate) only - matching
	// goldfish's own DyNAM architecture, where only the rate sub-model
	// has ever had an intercept concept (the choice sub-model's own
	// conditional logit has no intercept term at all, by construction).
	// v1 scope (a real, disclosed limit, not silently narrow): window,
	// `weighted=TRUE', and two-mode support are NOT yet verified
	// together with `intercept' - see unw_dynam.do's own header comment
	// above dynam_rateint_loglik_grad_multi() for the exact formula and
	// its real-goldfish verification (dev/dynam_unit20_
	// rateintercept_crosscheck.R/.do).
	if "`intercept'" != "" {
		if "`submodel'" != "rate" {
			di as error "intercept only applies to submodel(rate) - see {help nwdynam}."
			error 198
		}
		if `__nwdynam_n1' > 0 {
			di as error "intercept is not yet verified together with two-mode (bipartite) networks - a real, disclosed v1 gap - see {help nwdynam}."
			error 198
		}
		if `__nwdynam_windowindeg' < 1e300 | `__nwdynam_windowoutdeg' < 1e300 {
			di as error "intercept is not yet verified together with indegwindow()/outdegwindow() - a real, disclosed v1 gap - see {help nwdynam}."
			error 198
		}
		if `__nwdynam_weightedindeg' | `__nwdynam_weightedoutdeg' {
			di as error "intercept is not yet verified together with weightedindeg/weightedoutdeg - a real, disclosed v1 gap - see {help nwdynam}."
			error 198
		}
	}

	local __nwdynam_anygiven = 0
	foreach __nwdynam_e of local __nwdynam_effnames {
		if "``__nwdynam_e''" != "" local __nwdynam_anygiven = 1
	}

	local __nwdynam_active ""
	local __nwdynam_sep ""
	local __nwdynam_collabs ""
	local __nwdynam_nactive = 0
	foreach __nwdynam_e of local __nwdynam_effnames {
		local __nwdynam_isdefault : list posof "`__nwdynam_e'" in __nwdynam_defaulteffs
		if "``__nwdynam_e''" != "" | (`__nwdynam_anygiven' == 0 & `__nwdynam_isdefault' > 0) {
			local __nwdynam_active "`__nwdynam_active'`__nwdynam_sep'1"
			local __nwdynam_collabs "`__nwdynam_collabs' `__nwdynam_e'"
			local __nwdynam_nactive = `__nwdynam_nactive' + 1
		}
		else {
			local __nwdynam_active "`__nwdynam_active'`__nwdynam_sep'0"
		}
		local __nwdynam_sep ","
	}

	// The full ORIGINAL-structural-effects-only case (whether reached
	// via the default or by naming exactly those effects explicitly),
	// with NEITHER effect windowed, reuses the ORIGINAL, native-eligible
	// Unit1/RateUnit1 engine - any other active set (a genuine subset,
	// any attribute effect, OR any window) dispatches to the Mata-only
	// Multi engine instead (unw_dynam.do's own header comment: no
	// native backend for anything but the exact original fixed set yet,
	// a real, disclosed follow-on). Checked against the EXACT
	// active-vector string rather than a effect count, since
	// `__nwdynam_effnames' is now longer than the native engine's own
	// fixed 3/2-effect scope.
	if "`submodel'" == "choice" {
		local __nwdynam_usemulti = ("`__nwdynam_active'" != "1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0") | (`__nwdynam_windowinertia' < 1e300) | (`__nwdynam_windowrecip' < 1e300) | `__nwdynam_weightedinertia' | `__nwdynam_weightedrecip' | `__nwdynam_weightedindeg' | `__nwdynam_weightedoutdeg' | (`__nwdynam_n1' > 0) | ("`opportunities'" != "") | ("`tie'" != "")
	}
	else if "`submodel'" == "rate" {
		local __nwdynam_usemulti = ("`__nwdynam_active'" != "1,1,0,0,0") | (`__nwdynam_windowindeg' < 1e300) | (`__nwdynam_windowoutdeg' < 1e300) | `__nwdynam_weightedindeg' | `__nwdynam_weightedoutdeg' | (`__nwdynam_n1' > 0)
	}
	// choice_coordination has no native-eligible fixed-effect-set engine
	// at all (unlike choice/rate's own DynamFitUnit1/DynamFitRateUnit1)
	// - always dispatches to DynamCoordFitMulti, so `__nwdynam_usemulti'
	// is left unset/unused for this submodel (the final dispatch below
	// branches on `submodel' directly instead).

	// same()/diff()/sim()/ego()/alter() covariates: read from the
	// CURRENT Stata dataset by row position 1..nodes, matching
	// nwrem.ado's own covsnd()/covrec()/covint() convention exactly
	// (see that file's own comment) - NOT from the event-list dataset
	// `netname' itself was declared from. Static only (v1 scope,
	// matching unw_rem.do's own covariate units).
	tempname __nwdynam_same __nwdynam_diff __nwdynam_sim __nwdynam_ego __nwdynam_alter __nwdynam_tertius
	foreach __nwdynam_cv in same diff sim ego alter tertius {
		if "``__nwdynam_cv''" != "" {
			capture confirm numeric variable ``__nwdynam_cv''
			if _rc {
				di as error "``__nwdynam_cv'' is not a numeric variable in the current dataset - `__nwdynam_cv'() must be a per-actor covariate, one row per node in the same order as `netname''s own actors (see {help nwload}'s {bf:xvars} option to load that dataset first)."
				error 198
			}
			capture assert _N == `nodes'
			if _rc {
				di as error "the current dataset has `=_N' observations but `netname' has `nodes' actors - `__nwdynam_cv'() requires exactly one row per actor, in actor order (see {help nwload}'s {bf:xvars} option)."
				error 198
			}
			mata: `__nwdynam_`__nwdynam_cv'' = st_data(1::`nodes', "``__nwdynam_cv''")'
		}
		else {
			mata: `__nwdynam_`__nwdynam_cv'' = J(1, `nodes', 0)
		}
	}

	// egoalterint() takes TWO variables at once (goldfish's own
	// two-argument egoAlterInt(attribute1, attribute2)) - handled
	// separately from the single-varname loop above.
	tempname __nwdynam_egoalterint1 __nwdynam_egoalterint2
	if "`egoalterint'" != "" {
		local __nwdynam_ea1 : word 1 of `egoalterint'
		local __nwdynam_ea2 : word 2 of `egoalterint'
		capture assert _N == `nodes'
		if _rc {
			di as error "the current dataset has `=_N' observations but `netname' has `nodes' actors - egoalterint() requires exactly one row per actor, in actor order (see {help nwload}'s {bf:xvars} option)."
			error 198
		}
		mata: `__nwdynam_egoalterint1' = st_data(1::`nodes', "`__nwdynam_ea1'")'
		mata: `__nwdynam_egoalterint2' = st_data(1::`nodes', "`__nwdynam_ea2'")'
	}
	else {
		mata: `__nwdynam_egoalterint1' = J(1, `nodes', 0)
		mata: `__nwdynam_egoalterint2' = J(1, `nodes', 0)
	}

	if `seed' != -1 {
		set seed `seed'
	}

	tempname __nwdynam_events
	mata: `__nwdynam_events' = *(`netobj'->get_eventlist())
	mata: st_numscalar("__nwdynam_nevents", rows(`__nwdynam_events'))
	local nevents = __nwdynam_nevents
	scalar drop __nwdynam_nevents

	if `nevents' < 2 {
		di as error "nwdynam needs at least 2 events to fit a model; `netname' has `nevents'."
		error 2001
	}

	// opportunities() ("expansion batch 10", added 2026-09-02, user:
	// "work your way through it" - continuing the goldfish-comparison
	// list) - goldfish's own `opportunitiesList' estimationInit
	// argument, choice sub-model only (goldfish's own documentation:
	// "ONLY for choice models"). Takes exactly TWO variables from the
	// CURRENT Stata dataset: an event sequence number (1..`nevents',
	// matching `netname''s own chronological event order) and an actor
	// ID (1..`nodes'), ONE ROW PER (event, available-actor) PAIR - a
	// genuinely different dataset SHAPE from same()/diff()/sim()/
	// alter()/ego()/tertius()/egoalterint() (one row per ACTOR) or the
	// event-level dataset `netname' itself was declared from, so
	// opportunities() cannot be combined with those seven options in
	// the same call (a real, disclosed v1 limitation - the current
	// dataset cannot simultaneously have both shapes). Mechanics
	// (numeric node indices, not labels; the sender's own
	// self-exclusion still applies regardless of whether it is itself
	// listed) derived from a real toy example against goldfish FIRST -
	// see unw_dynam.do's own header comment and
	// dev/dynam_unit13_opportunities_crosscheck.R/.do for the
	// real-goldfish verification.
	tempname __nwdynam_oppmat
	if "`opportunities'" != "" {
		if "`submodel'" != "choice" {
			di as error "opportunities() only applies to the choice sub-model (goldfish's own opportunitiesList is choice-only) - see {help nwdynam}."
			error 198
		}
		local __nwdynam_oppev : word 1 of `opportunities'
		local __nwdynam_oppact : word 2 of `opportunities'
		capture assert `__nwdynam_oppev' >= 1 & `__nwdynam_oppev' <= `nevents' if !missing(`__nwdynam_oppev')
		if _rc {
			di as error "`__nwdynam_oppev' must be between 1 and `nevents' (the event sequence number, matching `netname''s own chronological event order) - see {help nwdynam}."
			error 198
		}
		capture assert `__nwdynam_oppact' >= 1 & `__nwdynam_oppact' <= `nodes' if !missing(`__nwdynam_oppact')
		if _rc {
			di as error "`__nwdynam_oppact' must be between 1 and `nodes' (the actor ID, matching `netname''s own actor order) - see {help nwdynam}."
			error 198
		}
		mata: `__nwdynam_oppmat' = J(`nevents', `nodes', 0)
		mata: st_view(__nwdynam_oppview=., ., "`__nwdynam_oppev' `__nwdynam_oppact'")
		mata: for (__nwdynam_oi=1; __nwdynam_oi<=rows(__nwdynam_oppview); __nwdynam_oi++) `__nwdynam_oppmat'[__nwdynam_oppview[__nwdynam_oi,1], __nwdynam_oppview[__nwdynam_oi,2]] = 1
		mata: mata drop __nwdynam_oppview __nwdynam_oi
	}
	else {
		mata: `__nwdynam_oppmat' = J(0, 0, 0)
	}

	// tie() ("cross-network effects, v1 scope", added 2026-09-02,
	// continuing the goldfish-comparison list after choice_coordination's
	// own effect list was completed) - goldfish's own `tie(network, ...)'
	// effect, `s(i,j,t,x) = I(x_ij>0)' (unweighted only in this v1),
	// identical in shape to `inertia()' but reading a SEPARATE,
	// EXOGENOUS network instead of the dependent one. v1 scope (a real,
	// disclosed limit, not silently narrow): `tie()' takes the NAME of
	// an already-declared, ORDINARY (non-event) network - resolved via
	// {help nw_syntax}'s own `other()' prefix mechanism so its own
	// locals (`__nwdynam_tienet_netobj' etc.) never clash with the
	// primary network's own already-resolved locals. Genuinely
	// dynamically-evolving cross-network effects (where the SECOND
	// network is itself event-declared and changes over time, matching
	// goldfish's own full generality) remain a real, disclosed follow-on
	// - this v1 only supports a STATIC exogenous network, verified
	// directly against real goldfish on exactly that case (see
	// unw_dynam.do's own header comment above the `tie_i' construction
	// for the exact formula and dev/dynam_unit18_tie_crosscheck.R/.do
	// for the real-goldfish verification). Valid for BOTH
	// submodel(choice) and submodel(choice_coordination) (added "batch
	// 16", 2026-09-02 - the coordination engine's own full-matrix
	// requirement made this the simplest possible addition: `S_tie' is
	// literally `tiemat' itself, no computation at all, verified
	// directly against real goldfish - see dev/dynam_unit19_
	// coordination_tie_crosscheck.R/.do), matching goldfish's own effect
	// table exactly; rejected under submodel(rate) (goldfish's own table
	// shows `tie' as choice/choice_coordination only).
	tempname __nwdynam_tiemat
	if "`tie'" != "" {
		if "`submodel'" == "rate" {
			di as error "tie() only applies to submodel(choice) or submodel(choice_coordination) - see {help nwdynam}."
			error 198
		}
		nw_syntax `tie', other(__nwdynam_tienet_) max(1)
		if "`__nwdynam_tienet_istemporal'" == "true" {
			di as error "tie(`tie') is an event-type (eventtime()-declared) network - tie() in this release only supports a STATIC exogenous network (a real, disclosed v1 scope limit; genuinely dynamically-evolving cross-network effects are not yet implemented) - see {help nwdynam}."
			error 198
		}
		if `__nwdynam_tienet_nodes' != `nodes' {
			di as error "tie(`tie') has `__nwdynam_tienet_nodes' actors but `netname' has `nodes' - tie() requires the exogenous network to have exactly the same number of actors, in the same order (row/index correspondence, not label matching) - see {help nwdynam}."
			error 198
		}
		mata: `__nwdynam_tiemat' = `__nwdynam_tienet_netobj'->get_matrix_unvalued_copy()
	}
	else {
		mata: `__nwdynam_tiemat' = J(0, 0, 0)
	}

	// Two-mode direction validation: goldfish's own architecture (and
	// this package's own contiguous mode-1-then-mode-2 actor-index
	// convention) assumes every event's sender is mode 1 (index <= n1)
	// and every receiver is mode 2 (index > n1) - never the reverse.
	// Checked directly against the real event data rather than assumed
	// true of any two-mode network a user might declare.
	if `__nwdynam_n1' > 0 {
		mata: st_numscalar("__nwdynam_baddir", sum((`__nwdynam_events'[.,1] :> `__nwdynam_n1') :| (`__nwdynam_events'[.,2] :<= `__nwdynam_n1')))
		local __nwdynam_baddir = __nwdynam_baddir
		scalar drop __nwdynam_baddir
		if `__nwdynam_baddir' > 0 {
			di as error "nwdynam requires every event's sender to be mode 1 and receiver to be mode 2 for a two-mode (bipartite) network - `netname' has `__nwdynam_baddir' event(s) violating this (matching goldfish's own one-directional two-mode DyNAM architecture) - see {help nwdynam}."
			error 198
		}
	}

	if "`submodel'" == "choice" {
		if `__nwdynam_usemulti' {
			mata: DynamChoiceFitMulti(`__nwdynam_events', `nodes', (`__nwdynam_active'), `__nwdynam_same', `__nwdynam_diff', `__nwdynam_sim', `__nwdynam_alter', `__nwdynam_tertius', `__nwdynam_egoalterint1', `__nwdynam_egoalterint2', `__nwdynam_windowinertia', `__nwdynam_windowrecip', `__nwdynam_weightedinertia', `__nwdynam_weightedrecip', `__nwdynam_weightedindeg', `__nwdynam_weightedoutdeg', `__nwdynam_n1', `__nwdynam_oppmat', `__nwdynam_tiemat', "__nwdynam_b", "__nwdynam_V", "__nwdynam_ll")
		}
		else {
			mata: DynamFitUnit1(`__nwdynam_events', `nodes', "__nwdynam_b", "__nwdynam_V", "__nwdynam_ll")
		}
		local __nwdynam_title "Dynamic Network Actor Model, choice sub-model (conditional logit, MLE)"
		local __nwdynam_hdr "Dynamic Network Actor Model - choice sub-model (MLE)"
	}
	else if "`submodel'" == "rate" {
		if "`intercept'" != "" {
			mata: DynamRateInterceptFitMulti(`__nwdynam_events', `nodes', (`__nwdynam_active'), `__nwdynam_ego', `__nwdynam_tertius', "__nwdynam_b", "__nwdynam_V", "__nwdynam_ll")
			local __nwdynam_collabs "Intercept`__nwdynam_collabs'"
			local __nwdynam_title "Dynamic Network Actor Model, rate sub-model, WITH intercept (continuous-time competing-risks hazard, MLE)"
			local __nwdynam_hdr "Dynamic Network Actor Model - rate sub-model, with intercept (MLE)"
		}
		else if `__nwdynam_usemulti' {
			mata: DynamRateFitMulti(`__nwdynam_events', `nodes', (`__nwdynam_active'), `__nwdynam_ego', `__nwdynam_tertius', `__nwdynam_windowindeg', `__nwdynam_windowoutdeg', `__nwdynam_weightedindeg', `__nwdynam_weightedoutdeg', `__nwdynam_n1', "__nwdynam_b", "__nwdynam_V", "__nwdynam_ll")
			local __nwdynam_title "Dynamic Network Actor Model, rate sub-model, no intercept (ordinal partial likelihood, MLE)"
			local __nwdynam_hdr "Dynamic Network Actor Model - rate sub-model, no intercept (MLE)"
		}
		else {
			mata: DynamFitRateUnit1(`__nwdynam_events', `nodes', "__nwdynam_b", "__nwdynam_V", "__nwdynam_ll")
			local __nwdynam_title "Dynamic Network Actor Model, rate sub-model, no intercept (ordinal partial likelihood, MLE)"
			local __nwdynam_hdr "Dynamic Network Actor Model - rate sub-model, no intercept (MLE)"
		}
	}
	else {
		mata: DynamCoordFitMulti(`__nwdynam_events', `nodes', (`__nwdynam_active'), `__nwdynam_same', `__nwdynam_diff', `__nwdynam_sim', `__nwdynam_alter', `__nwdynam_tertius', `__nwdynam_egoalterint1', `__nwdynam_egoalterint2', `__nwdynam_tiemat', "__nwdynam_b", "__nwdynam_V", "__nwdynam_ll")
		local __nwdynam_title "Dynamic Network Actor Model, choice_coordination sub-model (multinomial-multinomial, MLE)"
		local __nwdynam_hdr "Dynamic Network Actor Model - choice_coordination sub-model (MLE)"
	}
	mata: mata drop `__nwdynam_events' `__nwdynam_same' `__nwdynam_diff' `__nwdynam_sim' `__nwdynam_ego' `__nwdynam_alter' `__nwdynam_tertius' `__nwdynam_egoalterint1' `__nwdynam_egoalterint2' `__nwdynam_oppmat' `__nwdynam_tiemat'

	tempname b V
	matrix `b' = __nwdynam_b
	matrix `V' = __nwdynam_V
	matrix colnames `b' = `__nwdynam_collabs'
	matrix colnames `V' = `__nwdynam_collabs'
	matrix rownames `V' = `__nwdynam_collabs'
	local __nwdynam_ll = __nwdynam_ll
	matrix drop __nwdynam_b __nwdynam_V
	scalar drop __nwdynam_ll

	ereturn post `b' `V', obs(`nevents')
	ereturn local cmd "nwdynam"
	ereturn local title "`__nwdynam_title'"
	ereturn local depvar "`netname'"
	ereturn local submodel "`submodel'"
	ereturn local effects "`=trim("`__nwdynam_collabs'")'"
	ereturn scalar N = `nevents'
	ereturn scalar nodes = `nodes'
	ereturn scalar ll = `__nwdynam_ll'

	di as text "{hline 60}"
	di as text "`__nwdynam_hdr'"
	di as text "Network: " as result "`netname'" _col(40) as text "Actors: " as result `nodes'
	di as text "Events: " as result `nevents' _col(40) as text "Log likelihood: " as result %9.4f `__nwdynam_ll'
	di as text "{hline 60}"
	ereturn display
end
