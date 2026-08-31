*! version 0.3.0 28aug2026 nwcommands: stochastic actor-oriented model (SAOM) estimation, v1 (+ harmonisation unit 26 co-evolution, N-wave, avsim, native backend)
/*
	nwsaom.ado -- user-facing layer for SAOM (Snijders-style stochastic
	actor-oriented model) estimation between two observed network waves.

	See docs/SAOM_ROADMAP.md (scope/status) and docs/SAOM_ARCHITECTURE.md
	(design). v1 scope: exactly two waves, fixed actor set, directed
	relation, Method of Moments / Robbins-Monro estimation. Effect
	family (harmonisation units 1-5, 9): outdegree, reciprocity,
	nodematch (homophily); nodecov/nodeicov/nodeocov (covariate
	main/alter/ego effects - direct nwergm reuse, see unw_saom.do's own
	header); indegpopularity/outpopularity (sqrt-transformed
	in/outdegree popularity), outactivity (squared outdegree activity),
	inactivity (sqrt-transformed indegree activity), transtrip
	(transitive triplets), cycle3 (directed 3-cycles), simcov
	(covariate similarity), transties (harmonisation unit 23, RSiena's
	transTies - triadic closure via simple tie count rather than
	transtrip's weighted triplet count), and balance (harmonisation unit
	25, RSiena's structural balance - the first freshly-derived effect
	with a DATA-DEPENDENT constant, "balanceMean", computed automatically
	from the observed wave data rather than user-supplied) - these nine
	are FRESHLY DERIVED for SAOM, not reused from nwergm, each
	independently verified against the real RSiena C++ source before
	implementation (see unw_saom.do's own "SAOM-native effect library"
	section for why/how). egox()/altx()/samex()/simx() (harmonisation
	unit 24) are
	pure RSiena-naming aliases for nodeocov()/nodeicov()/nodematch()/
	simcov() respectively - same math, same wiring, just RSiena's own
	names for users coming from that package (see this file's own
	"RSiena naming aliases" comment below). Mata engine lives
	in unw_saom.do (SaomMinistep()/SaomSimulateInterval()/SaomEstimateRM()),
	which itself reuses nwergm's own ErgmGraph/ErgmModel/ErgmTermData
	classes and stat_X()/change_X() term functions - READ ONLY, never
	edited by this initiative (see docs/SAOM_ROADMAP.md's coordination
	note: a separate session works on nwergm concurrently).

	The NWdef -> ErgmGraph bridge below is this file's OWN copy of
	nwergm.ado's ergm_bridge_from_netobj() (identical logic), not a
	shared call into nwergm.ado - matching nwergm_estat.ado's own
	established precedent of keeping its own copy of that same helper
	rather than depending on nwergm.ado's runtime state.
*/

capture mata: mata drop __nwsaom_bridge_from_netobj()
mata:
void __nwsaom_bridge_from_netobj(pointer(class nw_def scalar) scalar netobj,
	class ErgmGraph scalar G){
	real scalar i, k
	real matrix nb

	for (i=1; i<=G.n; i++) {
		nb = netobj->neighbors(i)
		for (k=1; k<=rows(nb); k++) {
			G.toggle(i, nb[k])
		}
	}
}
end

/* Multiplex SAOM, Stage 1 (nwsaom_multiplex, below): builds both
   networks' ErgmGraph/ErgmModel objects (outdegree+reciprocity only,
   see nwsaom_multiplex's own header comment for the full scoping
   account), runs the joint fit, and posts theta1/theta2/V/rate1/rate2
   straight into Stata via st_matrix()/st_numscalar() - one real Mata
   FUNCTION, called via a single one-line `mata: fname(...)' from
   nwsaom_multiplex's own body, matching this file's OWN universal
   convention for embedding non-trivial Mata logic inside a Stata
   program (every other program in this file calls out to a real,
   file-scope Mata function via one-line `mata: cmd' invocations -
   never an inline multi-line `mata:'/`end' block nested inside a
   `program ... end' body with Stata code continuing afterward). A
   first attempt used exactly that nested inline-block shape and hit a
   real, reproducible bug: Stata's own parser closed the OUTER `program
   define' at the INNER mata block's own `end', silently dropping
   everything meant to run after it (confirmed directly by extracting
   the isolated program body and observing execution fall through to
   bare top-level prompts immediately after the inner `end', rather
   than continuing inside the program) - this codebase's own
   file-scope-Mata-function convention exists for exactly this reason,
   not by accident. */
capture mata: mata drop __nwsaom_mp_fit_and_post()
mata:
void __nwsaom_mp_fit_and_post(
	pointer(class nw_def scalar) scalar netobj1a, pointer(class nw_def scalar) scalar netobj1b,
	pointer(class nw_def scalar) scalar netobj2a, pointer(class nw_def scalar) scalar netobj2b,
	real scalar n, real rowvector theta01, real rowvector theta02,
	real scalar K0, real scalar K3, real scalar firstg,
	real scalar wantcrprod, real scalar wantcrprodb,
	string scalar bname, string scalar Vname, string scalar rate1name, string scalar rate2name,
	string scalar ncoefname) {

	class ErgmGraph scalar G1a, G1b, G2a, G2b
	class ErgmModel scalar M1, M2
	class ErgmTermData scalar td1a, td1b, td1c, td2a, td2b, td2c
	struct SaomCoevNetNetFit scalar fit

	G1a = ErgmGraph()
	G1a.init(n, 1)
	__nwsaom_bridge_from_netobj(netobj1a, G1a)
	G1b = ErgmGraph()
	G1b.init(n, 1)
	__nwsaom_bridge_from_netobj(netobj1b, G1b)
	G2a = ErgmGraph()
	G2a.init(n, 1)
	__nwsaom_bridge_from_netobj(netobj2a, G2a)
	G2b = ErgmGraph()
	G2b.init(n, 1)
	__nwsaom_bridge_from_netobj(netobj2b, G2b)

	M1 = ErgmModel()
	M1.init()
	td1a = ErgmTermData()
	M1.addterm("outdegree", 1, &stat_edges(), &change_edges(), td1a, ("outdegree"))
	td1b = ErgmTermData()
	M1.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td1b, ("reciprocity"))
	// crprod (Stage 2): net1's own effect list gets a term reading net2's
	// CURRENT tie state - td1c.xnet itself is left NULL here; it is
	// re-pointed at whichever G2 working copy is "live" for a given
	// simulation replicate by SaomEstimateRMCoevNetNet() itself (see that
	// function's own "crprod" re-pointing loops), not set once here,
	// since G2a/G2b (the OBSERVED start/end networks) are never what a
	// ministep actually reads mid-simulation.
	if (wantcrprod) {
		td1c = ErgmTermData()
		M1.addterm("crprod", 1, &stat_crprod(), &change_crprod(), td1c, ("crprod"))
	}

	M2 = ErgmModel()
	M2.init()
	td2a = ErgmTermData()
	M2.addterm("outdegree", 1, &stat_edges(), &change_edges(), td2a, ("outdegree"))
	td2b = ErgmTermData()
	M2.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), td2b, ("reciprocity"))
	if (wantcrprodb) {
		td2c = ErgmTermData()
		M2.addterm("crprod", 1, &stat_crprod(), &change_crprod(), td2c, ("crprod"))
	}

	fit = SaomEstimateRMCoevNetNet(G1a, G1b, M1, G2a, G2b, M2, theta01, theta02, K0, K3, firstg)

	st_matrix(bname, (fit.theta1, fit.theta2))
	st_matrix(Vname, fit.V)
	st_numscalar(rate1name, fit.rate1)
	st_numscalar(rate2name, fit.rate2)
	// Coefficient names built here (not hardcoded in nwsaom_multiplex's
	// own Stata code) since the column count/order now varies with
	// wantcrprod/wantcrprodb - posted as one space-separated string
	// Stata reads back into `matrix colnames', the same "Mata decides,
	// Stata just applies" split this file's own single-network dispatch
	// already uses elsewhere for variable-length coefficient lists.
	st_global(ncoefname, invtokens(("net1_" :+ M1.coefnames, "net2_" :+ M2.coefnames)))
}
end

capture program drop nwsaom
program nwsaom, eclass
	version 14
	if `"`1'"' == "multiplex" | `"`1'"' == "multiplex," {
		// `gettoken' consumes a comma attached to "multiplex" (Stata's
		// own tokenizer attaches a trailing comma to whatever word
		// immediately precedes it when nothing else sits between them)
		// as PART of the extracted token, dropping it from the
		// remainder entirely - confirmed directly, not assumed - so the
		// comma must be re-supplied explicitly before forwarding, or
		// nwsaom_multiplex's own "syntax , options" sees a bare
		// options string with no leading comma and misreads it as an
		// unwanted varlist.
		gettoken __saom_sub 0 : 0
		nwsaom_multiplex , `0'
		exit
	}
	syntax [, WAVE1(string) WAVE2(string) WAVES(string) OUTDEGREE RECIPROCITY NODEMATCH(string) ///
		OUTDEGREEENDOW OUTDEGREECREATION RECIPROCITYENDOW RECIPROCITYCREATION ///
		NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		INDEGPOPULARITY OUTACTIVITY TRANSTRIP TRANSMEDTRIP CYCLE3 CYCLE4 OUTPOPULARITY INACTIVITY SIMCOV(string) ///
		ISOLATENET OUTISO ANTIISO ANTIINISO ANTIINISO2 INPLUS3 ISOLATEPOP ///
		TRANSRECTRIP OUTOUTASS ININASS OUTINASS INOUTASS ///
		GWESP(string) TRANSTIES BALANCE INTERACT(string) ///
		EGOX(string) ALTX(string) SAMEX(string) SIMX(string) ///
		BEHAVIOR(string) LINEAR LINEARENDOW LINEARCREATION QUADRATIC QUADRATICENDOW QUADRATICCREATION ///
		AVALT AVALTENDOW AVALTCREATION AVSIM AVSIMENDOW AVSIMCREATION BEHTHETA0(string) ///
		PRESENT(string) MISSNET(string) MISSBEH(string) ///
		RATECOV(string) RATECOVCOEF(string) SYMMETRIC SYMTYPE(string) ///
		RATE0(real 1) THETA0(string) K0(integer 50) K3(integer 1000) ///
		FIRSTG(real 0.2) SEED(integer -1) ]
	set more off

	// --- RSiena naming aliases (harmonisation unit 24): egoX/altX/sameX/
	// simX are RSiena's OWN names for the SAME effects this package
	// already implements under Statnet-style naming - nodeocov()=egoX,
	// nodeicov()=altX, nodematch()=sameX, simcov()=simX (confirmed via
	// this file's own nodecov/nodeicov/nodeocov comment above, unit 2's
	// header in unw_saom.do, and unit 9's simcov derivation). Pure
	// naming/documentation, per docs/SAOM_ROADMAP.md's "egoX proper"
	// entry - no new math, each alias resolves to the exact SAME
	// addterm()/change_X() wiring as its Statnet-named counterpart.
	// Specifying both a term and its RSiena alias is an error (ambiguous
	// duplicate, not a meaningfully different request). The coefficient
	// label follows whichever spelling the user actually typed, so
	// egox(x) shows as "egox_x" in e(b), not "nodeocov_x".
	local __nwsaom_egolab "nodeocov"
	if "`egox'" != "" {
		if "`nodeocov'" != "" {
			di as error "specify only one of nodeocov() or egox() - they are the same effect (egox() is RSiena's own name for nwcommands' own nodeocov())"
			exit 198
		}
		local nodeocov "`egox'"
		local __nwsaom_egolab "egox"
	}
	local __nwsaom_altlab "nodeicov"
	if "`altx'" != "" {
		if "`nodeicov'" != "" {
			di as error "specify only one of nodeicov() or altx() - they are the same effect (altx() is RSiena's own name for nwcommands' own nodeicov())"
			exit 198
		}
		local nodeicov "`altx'"
		local __nwsaom_altlab "altx"
	}
	local __nwsaom_samelab "nodematch"
	if "`samex'" != "" {
		if "`nodematch'" != "" {
			di as error "specify only one of nodematch() or samex() - they are the same effect (samex() is RSiena's own name for nwcommands' own nodematch())"
			exit 198
		}
		local nodematch "`samex'"
		local __nwsaom_samelab "samex"
	}
	local __nwsaom_simlab "simcov"
	if "`simx'" != "" {
		if "`simcov'" != "" {
			di as error "specify only one of simcov() or simx() - they are the same effect (simx() is RSiena's own name for nwcommands' own simcov())"
			exit 198
		}
		local simcov "`simx'"
		local __nwsaom_simlab "simx"
	}

	// --- wave-set resolution: EITHER wave1()/wave2() (exactly two waves,
	// the original v1 surface - dispatches to SaomEstimateRM(), UNCHANGED
	// behavior) OR waves(namelist) (harmonisation unit 17, "3+ wave
	// chaining" - two or more waves, ordered, dispatches to
	// SaomEstimateRMMulti()). Never both, never neither. See
	// docs/SAOM_ROADMAP.md's own "Open design questions" entry on why
	// wave1()/wave2() was originally built as two distinct arguments
	// rather than a list - that reasoning no longer applies now that
	// chaining is actually implemented, but wave1()/wave2() is kept
	// as-is (not deprecated) since it is already certified/tested and
	// changing nothing there costs nothing.
	local __nwsaom_multi = 0
	if "`waves'" != "" {
		if "`wave1'" != "" | "`wave2'" != "" {
			di "{err}specify either {bf:wave1(netname)}/{bf:wave2(netname)} (exactly two waves) or {bf:waves(namelist)} (two or more waves), not both."
			error 198
		}
		local __nwsaom_wavelist "`waves'"
		local __nwsaom_nwaves : word count `waves'
		if `__nwsaom_nwaves' < 2 {
			di "{err}option {bf:waves()} requires at least two network names, in temporal order."
			error 198
		}
		local __nwsaom_multi = 1
	}
	else {
		if "`wave1'" == "" | "`wave2'" == "" {
			di "{err}options {bf:wave1(netname)} and {bf:wave2(netname)} are both required together - or use {bf:waves(nw1 nw2 ...)} for two or more waves."
			error 198
		}
		local __nwsaom_wavelist "`wave1' `wave2'"
		local __nwsaom_nwaves = 2
	}
	// harmonisation unit 167: outdegreeendow+outdegreecreation together are
	// a valid, RSiena-native ALTERNATIVE to plain outdegree (same
	// evaluation-vs-endow/creation-role choice unit 28/166 already
	// established on the behavior side) - satisfies the same required-
	// baseline network effect either way.
	if "`outdegree'" == "" & "`outdegreeendow'" == "" {
		di "{err}option {bf:outdegree} (or {bf:outdegreeendow}+{bf:outdegreecreation}) is required - every nwsaom v1 model includes an outdegree (density) effect, matching nwergm's own edges-required convention."
		error 198
	}

	// --- behavior(): harmonisation unit 26 (co-evolution), N-wave
	// support added per explicit user direction ("extend it to N
	// waves") - works with EITHER wave1()/wave2() (dispatches to
	// SaomEstimateRMCoev()) OR waves() (dispatches to
	// SaomEstimateRMCoevMulti(), mirroring SaomEstimateRMMulti()'s own
	// established "chain periods, pool theta, keep rate per-period"
	// pattern - now for BOTH variables, unit 26's own DESIGN section,
	// docs/SAOM_ROADMAP.md). One Stata variable per wave, same "one
	// name per wave" convention as waves() itself - ONE behavior
	// variable only (v1 scope; multiple co-evolving behaviors remain
	// out of scope).
	local __nwsaom_coev = 0
	if "`behavior'" != "" {
		local __nwsaom_nbeh : word count `behavior'
		if `__nwsaom_nbeh' != `__nwsaom_nwaves' {
			di "{err}{bf:behavior()} must supply exactly `__nwsaom_nwaves' variable name(s), one per wave, in the same temporal order."
			error 198
		}
		// harmonisation unit 28 ("endowment/creation functions"):
		// linearendow+linearcreation together are a valid, RSiena-native
		// ALTERNATIVE baseline to plain linear (RSiena's own manual, "the
		// model specifications of ... (creation & endowment) are
		// equivalent" to evaluation alone, up to reparametrization -
		// docs/SAOM_ROADMAP.md's own unit-28 entry has the full citation).
		// Combining `linear' with either is refused (all three roles for
		// one effect together is exactly collinear - RSiena's own manual:
		// "never in all three, because this leads to collinearity"), and
		// linearendow/linearcreation must be given TOGETHER (this port's
		// certified infrastructure covers only the paired case, not a
		// single non-evaluation role alone).
		if "`linear'" != "" & ("`linearendow'" != "" | "`linearcreation'" != "") {
			di "{err}specify either {bf:linear} (a single evaluation-only baseline) or {bf:linearendow}+{bf:linearcreation} together - not both; using an effect in all three roles (evaluation, creation, endowment) is exactly collinear."
			error 198
		}
		if ("`linearendow'" != "" & "`linearcreation'" == "") | ("`linearendow'" == "" & "`linearcreation'" != "") {
			di "{err}{bf:linearendow} and {bf:linearcreation} must be specified together - this port does not (yet) support a single non-evaluation role alone. Use plain {bf:linear} instead if you only want the evaluation-only baseline."
			error 198
		}
		if "`linear'" == "" & "`linearendow'" == "" {
			di "{err}every co-evolution model requires a baseline linear shape effect: either {bf:linear}, or {bf:linearendow}+{bf:linearcreation} together - matching {bf:outdegree}'s own required-baseline convention on the network side."
			error 198
		}
		// harmonisation unit 166: quadratic/avalt/avsim endowment/creation
		// splits - confirmed as real, offered RSiena effect/type
		// combinations (RSiena's own getEffects() lists endow/creation
		// rows for quad/avAlt/avSim exactly as it does for linear - fetched
		// live, not assumed) - generalizes unit 28's own linearendow/
		// linearcreation mechanism, which was never specific to `linear`
		// in the underlying engine (SaomBehaviorModel::addterm()'s own
		// `fntype` argument and full_change()'s direction-gating already
		// work for ANY behavior change-statistic function - see
		// unw_saom.do's own full_change() header comment). Same
		// "both together, not with the eval role" collinearity rule as
		// linearendow/linearcreation, applied per effect.
		foreach __nwsaom_ec_eff in quadratic avalt avsim {
			local __nwsaom_ec_e = "``__nwsaom_ec_eff'endow'"
			local __nwsaom_ec_c = "``__nwsaom_ec_eff'creation'"
			local __nwsaom_ec_plain = "``__nwsaom_ec_eff''"
			if "`__nwsaom_ec_plain'" != "" & ("`__nwsaom_ec_e'" != "" | "`__nwsaom_ec_c'" != "") {
				di "{err}specify either {bf:`__nwsaom_ec_eff'} (evaluation-only) or {bf:`__nwsaom_ec_eff'endow}+{bf:`__nwsaom_ec_eff'creation} together - not both; using an effect in all three roles (evaluation, creation, endowment) is exactly collinear."
				error 198
			}
			if ("`__nwsaom_ec_e'" != "" & "`__nwsaom_ec_c'" == "") | ("`__nwsaom_ec_e'" == "" & "`__nwsaom_ec_c'" != "") {
				di "{err}{bf:`__nwsaom_ec_eff'endow} and {bf:`__nwsaom_ec_eff'creation} must be specified together - a single non-evaluation role alone is not supported (same restriction as {bf:linearendow}/{bf:linearcreation})."
				error 198
			}
		}
		local __nwsaom_coev = 1
	}
	else if "`linear'" != "" | "`linearendow'" != "" | "`linearcreation'" != "" | "`quadratic'" != "" | "`quadraticendow'" != "" | "`quadraticcreation'" != "" | "`avalt'" != "" | "`avaltendow'" != "" | "`avaltcreation'" != "" | "`avsim'" != "" | "`avsimendow'" != "" | "`avsimcreation'" != "" {
		di "{err}{bf:linear}/{bf:linearendow}/{bf:linearcreation}/{bf:quadratic}/{bf:avalt}/{bf:avsim} (and their {bf:endow}/{bf:creation} variants) are behavior effects and require {bf:behavior()} to be specified."
		error 198
	}

	// --- validate EVERY wave (not just a pairwise check) - 2mode/
	// temporal/valued/directed status and node count must all agree
	// across the WHOLE wave set, matching the same per-pair checks the
	// original wave1()/wave2() path always ran, generalized to N waves.
	local nodes = .
	forvalues __w = 1/`__nwsaom_nwaves' {
		local __wname : word `__w' of `__nwsaom_wavelist'
		nw_syntax `__wname', max(1) other(w`__w')
		if "`w`__w'is2mode'" == "true" {
			di "{err}nwsaom does not support two-mode (bipartite) networks."
			error 198
		}
		if "`w`__w'istemporal'" == "true" {
			di "{err}nwsaom estimates on ordinary static wave snapshots; no wave() network may itself carry {bf:nwset}-style temporal metadata (build an explicit static slice first, e.g. via {bf:nwattime})."
			error 198
		}
		if "`w`__w'valued'" == "true" {
			di "{err}nwsaom v1 estimates on binary ties only; a valued/weighted wave network is not yet supported."
			error 198
		}
		if "`w`__w'directed'" != "true" {
			di "{err}nwsaom requires a network stored as directed - SAOM's own ministep formulation is inherently directed (an actor controls only its own outgoing ties). To model a genuinely symmetric/undirected relation, store the data as directed (each tie coded both ways) and use the {bf:symmetric} option, which adds a mutual-consent ministep on top of that same directed storage."
			error 198
		}
		if `__w' == 1 local nodes = `w1nodes'
		else if `w`__w'nodes' != `nodes' {
			di "{err}every wave must have the same number of nodes - nwsaom always uses a FIXED, common actor set across every wave; an actor not present at every wave still needs a row in each wave's own network, marked absent via {bf:present()}, not omitted from the network itself."
			error 198
		}
	}

	// --- present(): composition change ("joiners and leavers", harmonisation
	// unit 33) - one 0/1 Stata variable per wave, same "one variable per
	// wave" convention behavior() already uses, marking which actors are
	// present (eligible to act or be tied to) at each wave. An actor
	// present at BOTH endpoint waves of a given inter-wave period is
	// treated as present for that WHOLE period (this package's own
	// whole-period-only scope decision - see docs/SAOM_ROADMAP.md's own
	// unit-33 entry); an actor absent from either endpoint is excluded
	// from that period's own simulation entirely. Optional - omitting
	// present() entirely is a true no-op (every actor present the whole
	// time), matching every pre-existing model.
	local __nwsaom_haspresent = 0
	if "`present'" != "" {
		local __nwsaom_npresent : word count `present'
		if `__nwsaom_npresent' != `__nwsaom_nwaves' {
			di "{err}option {bf:present()} must supply exactly `__nwsaom_nwaves' variable name(s), one per wave, in the same temporal order."
			error 198
		}
		local __nwsaom_haspresent = 1
	}

	// --- missnet()/missbeh(): missing tie/behavior data (harmonisation
	// unit 35), matching RSiena's own real Section 5.3.2 mechanism -
	// missnet() takes one n x n 0/1 MATRIX name per wave (1=dyad
	// missing at that wave; a raw Stata matrix, not an nwset network
	// object - a deliberate, disclosed design choice that avoids any
	// dependency on nwset/NWdef's own data model, which this initiative
	// does not own), missbeh() takes one 0/1 VARIABLE per wave
	// (matching present()'s own "one variable per wave" convention),
	// marking which actors' behavior value is missing at that wave.
	// Missing dyads/actors are (a) IMPUTED for simulation-starting-value
	// purposes (last-observation-carried-forward for the network,
	// previous/next/observationwise-mode for behavior -
	// unw_saom.do's own SaomImputeNetworkWave()/SaomImputeBehaviorWave()),
	// and (b) EXCLUDED from every period's own target/simulated
	// statistic if missing at EITHER endpoint wave (unw_saom.do's own
	// SaomMaskedStatistic()/SaomMaskedBehaviorStatistic() - see those
	// functions' own header comments for the full account, including
	// why behavior-side masking uses overallMean rather than 0).
	// Optional - omitting missnet()/missbeh() entirely is a true no-op
	// (every dyad/actor fully observed), matching every pre-existing
	// model; combines freely with present() (composition change) and
	// behavior() (co-evolution).
	local __nwsaom_hasmissnet = 0
	if "`missnet'" != "" {
		local __nwsaom_nmissnet : word count `missnet'
		if `__nwsaom_nmissnet' != `__nwsaom_nwaves' {
			di "{err}option {bf:missnet()} must supply exactly `__nwsaom_nwaves' matrix name(s), one per wave, in the same temporal order."
			error 198
		}
		local __nwsaom_hasmissnet = 1
	}
	local __nwsaom_hasmissbeh = 0
	if "`missbeh'" != "" {
		if `__nwsaom_coev' == 0 {
			di "{err}option {bf:missbeh()} requires {bf:behavior()} to be specified."
			error 198
		}
		local __nwsaom_nmissbeh : word count `missbeh'
		if `__nwsaom_nmissbeh' != `__nwsaom_nwaves' {
			di "{err}option {bf:missbeh()} must supply exactly `__nwsaom_nwaves' variable name(s), one per wave, in the same temporal order."
			error 198
		}
		local __nwsaom_hasmissbeh = 1
	}
	local __nwsaom_hasmiss = (`__nwsaom_hasmissnet' | `__nwsaom_hasmissbeh')

	// --- harmonisation unit 167 (network-side endowment/creation):
	// outdegreeendow/outdegreecreation and reciprocityendow/
	// reciprocitycreation are a real, RSiena-native alternative role split
	// for the two network effects RSiena's own getEffects() confirms offer
	// endow/creation types (density=outdegree, recip=reciprocity - see
	// docs/SAOM_ROADMAP.md's own unit-166 entry for the live-fetched
	// evidence). Same "both roles together, not with the plain role"
	// collinearity rule as the behavior-side splits (unit 28/166), applied
	// per effect, ORTHOGONAL to every other effect's own choice - the
	// unit-166 bug (folding a role-split into a shared if/else-if
	// baseline-resolution chain) is avoided from the start here by never
	// building one at all.
	foreach __nwsaom_nec_eff in outdegree reciprocity {
		local __nwsaom_nec_e = "``__nwsaom_nec_eff'endow'"
		local __nwsaom_nec_c = "``__nwsaom_nec_eff'creation'"
		local __nwsaom_nec_plain = "``__nwsaom_nec_eff''"
		if "`__nwsaom_nec_plain'" != "" & ("`__nwsaom_nec_e'" != "" | "`__nwsaom_nec_c'" != "") {
			di "{err}specify either {bf:`__nwsaom_nec_eff'} (evaluation-only) or {bf:`__nwsaom_nec_eff'endow}+{bf:`__nwsaom_nec_eff'creation} together - not both; using an effect in all three roles (evaluation, creation, endowment) is exactly collinear."
			error 198
		}
		if ("`__nwsaom_nec_e'" != "" & "`__nwsaom_nec_c'" == "") | ("`__nwsaom_nec_e'" == "" & "`__nwsaom_nec_c'" != "") {
			di "{err}{bf:`__nwsaom_nec_eff'endow} and {bf:`__nwsaom_nec_eff'creation} must be specified together - a single non-evaluation role alone is not supported (same restriction as {bf:linearendow}/{bf:linearcreation})."
			error 198
		}
	}
	local __nwsaom_hasnetgate = ("`outdegreeendow'" != "" | "`reciprocityendow'" != "")
	// v1 scope restriction, disclosed not silently degraded: network
	// endow/creation reuses SaomEstimateRM()'s own missing-data code path
	// internally (see that function's own header comment on the chained-
	// optional-argument design), and has not been extended to
	// co-evolution/multi-wave/composition-change/real-missing-data at all
	// - each is a genuinely separate, untested combination this unit
	// deliberately did not attempt (matching this whole roadmap effort's
	// own standing instruction against forcing a rushed, undertested
	// change to correctness-critical shared code).
	if `__nwsaom_hasnetgate' {
		if `__nwsaom_coev' | `__nwsaom_multi' {
			di "{err}{bf:outdegreeendow}/{bf:reciprocityendow} (network-side endowment/creation) is not yet supported for co-evolution or multi-wave models - v1 scope is the exactly-two-wave, network-only case only."
			error 198
		}
		if `__nwsaom_haspresent' {
			di "{err}{bf:outdegreeendow}/{bf:reciprocityendow} cannot currently be combined with {bf:present()} (composition change) - not yet supported together."
			error 198
		}
		if `__nwsaom_hasmissnet' {
			di "{err}{bf:outdegreeendow}/{bf:reciprocityendow} cannot currently be combined with {bf:missnet()} - not yet supported together."
			error 198
		}
	}

	local __nwsaom_hasratecov = ("`ratecov'" != "")
	if `__nwsaom_hasratecov' & "`ratecovcoef'" == "" local ratecovcoef "0"
	// v1 scope restriction, disclosed not silently degraded - same
	// reasoning and same narrow scope as outdegreeendow/reciprocityendow
	// immediately above: this reuses SaomEstimateRM()'s own chained-
	// optional-argument machinery, not yet extended to co-evolution/
	// multi-wave/composition-change/missing-data.
	if `__nwsaom_hasratecov' {
		if `__nwsaom_coev' | `__nwsaom_multi' {
			di "{err}{bf:ratecov()} is not yet supported for co-evolution or multi-wave models - v1 scope is the exactly-two-wave, network-only case only."
			error 198
		}
		if `__nwsaom_haspresent' {
			di "{err}{bf:ratecov()} cannot currently be combined with {bf:present()} (composition change) - not yet supported together."
			error 198
		}
		if `__nwsaom_hasmissnet' {
			di "{err}{bf:ratecov()} cannot currently be combined with {bf:missnet()} - not yet supported together."
			error 198
		}
	}

	if `seed' != -1 {
		set seed `seed'
	}

	// --- build one ErgmGraph per wave, named __nwsaom_last_G1.._G`N' -
	// literal Mata variable names (matching the ORIGINAL wave1()/wave2()
	// code's own convention exactly, just generalized to N waves via
	// Stata's own loop-index interpolation into the name - NOT Stata
	// `tempname`-indirected, since these are Mata-namespace variables
	// already guarded by their own `capture mata: mata drop`, not
	// Stata locals/matrices that need tempname hygiene). The
	// exactly-two-wave path ends up with __nwsaom_last_G1/_G2, i.e. the
	// EXACT same two Mata variable names the original code always used -
	// so the existing SaomEstimateRM() call below needs no change at all.
	forvalues __w = 1/`__nwsaom_nwaves' {
		capture mata: mata drop __nwsaom_last_G`__w'
		mata: __nwsaom_last_G`__w' = ErgmGraph()
		mata: __nwsaom_last_G`__w'.init(`nodes', 1)
		mata: __nwsaom_bridge_from_netobj(`w`__w'netobj', __nwsaom_last_G`__w')
	}

	// --- missnet(): impute missing dyads via last-observation-carried-
	// forward (harmonisation unit 35, SaomImputeNetworkWave() -
	// unw_saom.do), mutating each wave's own ErgmGraph IN PLACE, in
	// temporal order, BEFORE anything else touches these graphs (the
	// multi-wave pointer array, period-base graphs for balance(), etc.)
	// - every downstream use already sees the imputed, fully-
	// determinate network. `__nwsaom_missnet_w`__w'' (the raw 0/1
	// missingness matrices, read once here) are kept around under
	// their own names - the period-level union masks the estimator
	// itself needs are derived from them further below, once
	// `__nwsaom_multi'/`__nwsaom_coev' dispatch is known.
	if `__nwsaom_hasmissnet' {
		capture mata: mata drop __nwsaom_missnet_last
		mata: __nwsaom_missnet_last = J(`nodes', `nodes', 0)
		forvalues __w = 1/`__nwsaom_nwaves' {
			local __wmiss : word `__w' of `missnet'
			confirm matrix `__wmiss'
			if rowsof(`__wmiss') != `nodes' | colsof(`__wmiss') != `nodes' {
				di "{err}option {bf:missnet()} matrices must be `nodes' x `nodes' (one row/column per actor) - `__wmiss' is not."
				error 198
			}
			capture mata: mata drop __nwsaom_missnet_w`__w'
			mata: __nwsaom_missnet_w`__w' = st_matrix("`__wmiss'")
			mata: st_local("__nwsaom_missnet_ok", strofreal(all((__nwsaom_missnet_w`__w' :== 0) :| (__nwsaom_missnet_w`__w' :== 1))))
			if `__nwsaom_missnet_ok' == 0 {
				di "{err}option {bf:missnet()} matrices must be coded 0/1 (0=observed, 1=missing) - `__wmiss' has a value outside {0,1}."
				error 198
			}
			mata: __nwsaom_missnet_last = SaomImputeNetworkWave(__nwsaom_last_G`__w', __nwsaom_missnet_w`__w', __nwsaom_missnet_last)
		}
	}

	// multi-wave path only: assemble the pointer array
	// SaomEstimateRMMulti() needs (the standard "collection of class
	// instances" idiom already established by ErgmModel.td, unw_ergm.do).
	if `__nwsaom_multi' {
		local __nwsaom_ptrlist ""
		forvalues __w = 1/`__nwsaom_nwaves' {
			if `__w' == 1 local __nwsaom_ptrlist "&__nwsaom_last_G1"
			else local __nwsaom_ptrlist "`__nwsaom_ptrlist', &__nwsaom_last_G`__w'"
		}
		capture mata: mata drop __nwsaom_last_Gwaves
		mata: __nwsaom_last_Gwaves = (`__nwsaom_ptrlist')
	}

	// --- symmetric (undirected/symmetric relations, native-first): RSiena's
	// own BJOINT mutual-consent model type (real NetworkModelType enum,
	// source-verified - see native/saom_sim.c's own header comment for
	// the full mechanism). v1 scope, disclosed: exactly-two-wave,
	// network-only, no missing data/composition change/covariate rate -
	// each of those is a real, orthogonal follow-on, not attempted here.
	// Storage stays DIRECTED (the "requires directed networks" check
	// above is unchanged and still applies) - `symmetric' does not ask
	// for a different NWdef storage mode, only a different ministep
	// mechanism on data that happens to already be tie-symmetric.
	if "`symmetric'" != "" {
		if `__nwsaom_multi' | `__nwsaom_coev' | `__nwsaom_hasnetgate' {
			di "{err}{bf:symmetric} is v1 scope: exactly two waves ({bf:wave1()}/{bf:wave2()}, not {bf:waves()}), network-only (no {bf:behavior()}), and none of {bf:outdegreeendow()}/{bf:reciprocityendow()} - each a real, disclosed follow-on, not yet combinable with {bf:symmetric}. {bf:ratecov()}/{bf:present()}/{bf:missnet()} ARE now combinable with {bf:symmetric} (see below)."
			error 198
		}
		if "`reciprocity'" != "" {
			di "{err}{bf:reciprocity} is not meaningful under {bf:symmetric} - every tie is reciprocated by construction once both directions are forced equal, so this effect's own statistic is a constant (RSiena itself does not offer {bf:recip} for a non-directed dependent variable)."
			error 198
		}
		// symtype(): which of RSiena's own real B-family symmetric model
		// types (NetworkModelType enum, source-verified from
		// NetworkVariable.cpp) drives the mutual-consent ministep -
		// default {bf:joint} (RSiena's own BJOINT, this option's original
		// and only behavior before this addition, so plain {bf:symmetric}
		// with no {bf:symtype()} is unchanged). {bf:force}/{bf:agree} are
		// RSiena's own BFORCE/BAGREE, native-first per standing
		// instruction (native/saom_sim.c's own `symtype' dispatch, no
		// Mata fallback exists for any of the three, matching the
		// existing joint-only behavior). A-family
		// (AFORCE/AAGREE)/DOUBLESTEP*/NETCONTEMP are real RSiena model
		// types too but use a structurally different call path in
		// RSiena's own source (not the B-family switch these three
		// share) - not attempted here, a disclosed follow-on.
		local __nwsaom_symtypeval = 1
		if "`symtype'" != "" {
			local __nwsaom_symtype_lc = lower("`symtype'")
			if "`__nwsaom_symtype_lc'" == "joint" local __nwsaom_symtypeval = 1
			else if "`__nwsaom_symtype_lc'" == "force" local __nwsaom_symtypeval = 2
			else if "`__nwsaom_symtype_lc'" == "agree" local __nwsaom_symtypeval = 3
			else {
				di "{err}{bf:symtype()} must be {bf:joint} (default, RSiena's BJOINT), {bf:force} (BFORCE), or {bf:agree} (BAGREE) - got {bf:`symtype''}."
				error 198
			}
		}
		// Effect-meaningfulness audit for `symmetric', beyond reciprocity
		// above: checked against real RSiena 1.6.6's own getEffects()
		// output (not derived/assumed) - built a symmetric-data
		// sienaDependent and a directed one side by side and diffed
		// their own `type=="eval"' shortName sets. RSiena auto-detects
		// symmetry from the data itself (no explicit type= argument
		// needed - printing the resulting siena data object reports
		// "Type: oneMode, symmetric") and silently drops every
		// direction-dependent effect whose own indegree/outdegree
		// distinction collapses once in==out==degree for every actor,
		// consistent with algebra (e.g. `outPop's own
		// sqrt(outdeg)*indeg formula reduces to indeg^1.5, identical to
		// `inPop, so RSiena drops `outPop as a redundant duplicate
		// rather than a meaningless one) but confirmed from the real
		// tool rather than derived by hand for every effect. The four
		// directional degree-assortativity effects (outOutAss/inInAss/
		// outInAss/inOutAss) all reduce to the SAME statistic once
		// symmetric; RSiena keeps exactly one canonical name
		// (`outInAss) and drops the other three - `outinass' is
		// therefore the one of this family still ALLOWED here,
		// mirroring RSiena's own real choice, not an arbitrary pick.
		// `antiIso' is dropped while `antiInIso'/`antiInIso2' are BOTH
		// kept (a real, non-obvious asymmetry in RSiena's own table,
		// not derivable from the effect names alone) - matched exactly,
		// not guessed. `transTrip' is dropped for symmetric (RSiena
		// offers a differently-formulated `transTriads' there instead,
		// which this package does not implement), while `cycle4',
		// `isolateNet', `outIso', `gwesp', `transTies', and `balance'
		// all remain genuinely offered by RSiena for a symmetric
		// relation and are left unrestricted here. Every covariate-based
		// effect (`nodecov'/`nodeicov'/`nodeocov'/`nodematch'/`simcov'
		// and their egoX/altX/sameX/simX aliases) was independently
		// confirmed still offered (RSiena's own egoX/altX/sameX/simX
		// shortNames appear unchanged in the symmetric effect table) -
		// only compound covariate x directed-structural-effect
		// interactions RSiena itself does not offer for symmetric data
		// are absent, and this package implements none of those
		// interaction forms regardless, so no restriction is needed for
		// the covariate family.
		if "`cycle3'" != "" | "`inactivity'" != "" | "`outpopularity'" != "" | "`ininass'" != "" | "`inoutass'" != "" | "`outoutass'" != "" | "`antiiso'" != "" | "`isolatepop'" != "" | "`transrectrip'" != "" | "`transtrip'" != "" {
			di "{err}under {bf:symmetric}, {bf:cycle3}/{bf:inactivity}/{bf:outpopularity}/{bf:ininass}/{bf:inoutass}/{bf:outoutass}/{bf:antiiso}/{bf:isolatepop}/{bf:transrectrip}/{bf:transtrip} are each either a constant, an exact duplicate of an already-available effect, or an effect real RSiena itself does not offer for a non-directed relation (confirmed against RSiena's own real {bf:getEffects()} output, not assumed) - {bf:outdegree}/{bf:indegpopularity}/{bf:outactivity}/{bf:cycle4}/{bf:isolatenet}/{bf:outiso}/{bf:antiiniso}/{bf:antiiniso2}/{bf:outinass}/{bf:gwesp}/{bf:transties}/{bf:balance} and every covariate effect remain available."
			error 198
		}
		// data-level symmetry check - a real, disclosed requirement, not
		// silently assumed: `symmetric' only changes the ministep
		// MECHANISM, it never symmetrizes the input data itself.
		mata: st_numscalar("__nwsaom_symchk1", max(abs(__nwsaom_last_G1.to_dense() - __nwsaom_last_G1.to_dense()')))
		mata: st_numscalar("__nwsaom_symchk2", max(abs(__nwsaom_last_G2.to_dense() - __nwsaom_last_G2.to_dense()')))
		if __nwsaom_symchk1 > 0 | __nwsaom_symchk2 > 0 {
			di "{err}{bf:symmetric} requires both wave networks to already be tie-symmetric (x_ij == x_ji for every dyad) - {bf:symmetric} selects RSiena's own BJOINT mutual-consent SIMULATION mechanism, it does not symmetrize asymmetric input data for you."
			error 198
		}
	}
	else if "`symtype'" != "" {
		di "{err}{bf:symtype()} requires {bf:symmetric} - it selects which of RSiena's real B-family symmetric model types {bf:symmetric} itself uses, it is not a standalone option."
		error 198
	}

	// --- present(): build the n x nwaves 0/1 presence matrix
	// (harmonisation unit 33) - one column per wave, read from whatever
	// dataset is current at call time (same convention behavior()'s own
	// per-wave variables already use). `__nwsaom_present1' (a single n x
	// 1 vector, present at BOTH wave1 and wave2) is what the two-wave
	// SaomEstimateRM()/SaomEstimateRMCoev() path needs; the full n x
	// nwaves `__nwsaom_presentmat' is what SaomEstimateRMMulti()/
	// SaomEstimateRMCoevMulti() derive per-period presence from
	// themselves.
	if `__nwsaom_haspresent' {
		capture mata: mata drop __nwsaom_presentmat __nwsaom_present1
		mata: __nwsaom_presentmat = J(`nodes', `__nwsaom_nwaves', 1)
		forvalues __w = 1/`__nwsaom_nwaves' {
			local __wpres : word `__w' of `present'
			confirm variable `__wpres'
			capture assert inlist(`__wpres', 0, 1)
			if _rc {
				di "{err}option {bf:present()} variables must be coded 0/1 (0=absent, 1=present) - `__wpres' has a value outside {0,1}."
				error 198
			}
			mata: __nwsaom_presentmat[.,`__w'] = st_data(1::`nodes', "`__wpres'")
		}
		mata: __nwsaom_present1 = __nwsaom_presentmat[.,1] :* __nwsaom_presentmat[.,2]
	}
	// harmonisation unit 35: the estimators' own `present'/`presentMat'
	// parameter must be supplied whenever `missMask'/`missMaskPd' is
	// (Mata's optional-argument ordering rule - an earlier optional
	// cannot be skipped to reach a later one) - a missing-data-only
	// model (no present()) still needs an all-present placeholder here.
	else if `__nwsaom_hasmiss' {
		capture mata: mata drop __nwsaom_presentmat __nwsaom_present1
		mata: __nwsaom_presentmat = J(`nodes', `__nwsaom_nwaves', 1)
		mata: __nwsaom_present1 = J(`nodes', 1, 1)
	}

	// --- missnet(): derive the PERIOD-level union mask(s) the
	// estimators themselves take (a dyad is excluded from a period's
	// own target/simulated statistics if missing at EITHER endpoint
	// wave - unw_saom.do's own SaomMaskedStatistic()/
	// SaomCountDifferingMasked() header comments). `__nwsaom_missmask1'
	// (single n x n, period 1 = wave1->wave2) is what the two-wave
	// SaomEstimateRM()/SaomEstimateRMCoev() path needs; the pointer
	// array `__nwsaom_missmaskpd' (one n x n mask per period) is what
	// SaomEstimateRMMulti()/SaomEstimateRMCoevMulti() need. Whenever
	// missnet() was NOT given but missbeh() was (behavior-only missing
	// data), every period's own network mask is all-zero (fully
	// observed dyads) - built the same way so the estimator call sites
	// below never need to branch on missnet() vs missbeh() separately.
	if `__nwsaom_hasmiss' {
		local __nwsaom_nperiods = `__nwsaom_nwaves' - 1
		forvalues __pd = 1/`__nwsaom_nperiods' {
			local __pd1 = `__pd'
			local __pd2 = `__pd' + 1
			capture mata: mata drop __nwsaom_missmaskpd`__pd'
			if `__nwsaom_hasmissnet' {
				mata: __nwsaom_missmaskpd`__pd' = (__nwsaom_missnet_w`__pd1' :| __nwsaom_missnet_w`__pd2')
			}
			else {
				mata: __nwsaom_missmaskpd`__pd' = J(`nodes', `nodes', 0)
			}
		}
		capture mata: mata drop __nwsaom_missmask1
		mata: __nwsaom_missmask1 = __nwsaom_missmaskpd1
		if `__nwsaom_multi' {
			local __nwsaom_missptrlist ""
			forvalues __pd = 1/`__nwsaom_nperiods' {
				if `__pd' == 1 local __nwsaom_missptrlist "&__nwsaom_missmaskpd1"
				else local __nwsaom_missptrlist "`__nwsaom_missptrlist', &__nwsaom_missmaskpd`__pd'"
			}
			capture mata: mata drop __nwsaom_missmaskptr
			mata: __nwsaom_missmaskptr = (`__nwsaom_missptrlist')
		}
	}

	// --- period-BASE graphs (harmonisation unit 25, balance()): every
	// wave except the last one - G1 alone for the wave1()/wave2() path
	// (one period), G1..G{N-1} for waves() (N-1 periods) - matching
	// RSiena's own calcBalmean() pooling scope EXACTLY (`for (k in
	// 1:(dims[3]-1))`, R/sienaDataCreate.r). Built unconditionally (not
	// gated on `balance' being requested) since it costs nothing and
	// keeps this block next to its own sibling pointer-array assembly
	// above rather than duplicated inside the balance()-specific wiring
	// below.
	local __nwsaom_nbases = `__nwsaom_nwaves' - 1
	local __nwsaom_baseptrlist ""
	forvalues __w = 1/`__nwsaom_nbases' {
		if `__w' == 1 local __nwsaom_baseptrlist "&__nwsaom_last_G1"
		else local __nwsaom_baseptrlist "`__nwsaom_baseptrlist', &__nwsaom_last_G`__w'"
	}
	capture mata: mata drop __nwsaom_last_Gbases
	mata: __nwsaom_last_Gbases = (`__nwsaom_baseptrlist')

	// --- build the model: one addterm() call per requested effect,
	// same "effect list order fixes coefficient/theta0 order" convention
	// as nwergm.ado's own term dispatch.
	capture mata: mata drop __nwsaom_last_M
	mata: __nwsaom_last_M = ErgmModel()
	mata: __nwsaom_last_M.init()

	// --- harmonisation unit 167: outdegreeendow/outdegreecreation and
	// reciprocityendow/reciprocitycreation register TWO separate ErgmModel
	// terms per role-split effect (each its own coefficient), both
	// pointing at the SAME underlying stat_edges()/change_edges() (or
	// stat_mutual()/change_mutual()) machinery unmodified - the gating
	// that makes one contribute only on withdrawals and the other only on
	// new ties lives entirely OUTSIDE ErgmModel, in
	// SaomNetworkFullChangeGated()/SaomNetworkPatchEndowCreation()
	// (unw_saom.do), driven by the PARALLEL `__nwsaom_netfntype_list'
	// built alongside `__nwsaom_efflist' below (0=eval, 1=endow, 2=creation,
	// one code per network term in the SAME order they were added to
	// __nwsaom_last_M - padded with trailing zeros for every later,
	// always-eval network effect once every option has been processed,
	// see this file's own SaomEstimateRM() dispatch call further below).
	if "`outdegreeendow'" != "" {
		tempname __td_ode __td_odc
		mata: `__td_ode' = ErgmTermData()
		mata: `__td_odc' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outdegreeendow", 1, &stat_edges(), &change_edges(), `__td_ode', ("outdegreeendow"))
		mata: __nwsaom_last_M.addterm("outdegreecreation", 1, &stat_edges(), &change_edges(), `__td_odc', ("outdegreecreation"))
		local __nwsaom_efflist "outdegreeendow outdegreecreation"
		local __nwsaom_netfntype_list "1 2"
	}
	else {
		tempname __td_od
		mata: `__td_od' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outdegree", 1, &stat_edges(), &change_edges(), `__td_od', ("outdegree"))
		local __nwsaom_efflist "outdegree"
		local __nwsaom_netfntype_list "0"
	}

	if "`reciprocityendow'" != "" {
		tempname __td_rece __td_recc
		mata: `__td_rece' = ErgmTermData()
		mata: `__td_recc' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("reciprocityendow", 1, &stat_mutual(), &change_mutual(), `__td_rece', ("reciprocityendow"))
		mata: __nwsaom_last_M.addterm("reciprocitycreation", 1, &stat_mutual(), &change_mutual(), `__td_recc', ("reciprocitycreation"))
		local __nwsaom_efflist "`__nwsaom_efflist' reciprocityendow reciprocitycreation"
		local __nwsaom_netfntype_list "`__nwsaom_netfntype_list' 1 2"
	}
	else if "`reciprocity'" != "" {
		tempname __td_recip
		mata: `__td_recip' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), `__td_recip', ("reciprocity"))
		local __nwsaom_efflist "`__nwsaom_efflist' reciprocity"
		local __nwsaom_netfntype_list "`__nwsaom_netfntype_list' 0"
	}

	if "`nodematch'" != "" {
		confirm variable `nodematch'
		tempname __td_nm
		mata: `__td_nm' = ErgmTermData()
		mata: `__td_nm'.attr = st_data(1::`nodes', "`nodematch'")
		mata: __nwsaom_last_M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), `__td_nm', ("`__nwsaom_samelab'_`nodematch'"))
		local __nwsaom_efflist "`__nwsaom_efflist' `__nwsaom_samelab'(`nodematch')"
	}

	// --- nodecov()/nodeicov()/nodeocov(): direct reuse of nwergm's own
	// stat_nodecov()/change_nodecov() etc. (unw_ergm.do) - each a
	// genuine single-actor-local SAOM effect (nodeocov = standard
	// RSiena "ego" effect, nodeicov = standard "alter" effect, nodecov
	// = their combined sum). See docs/SAOM_ROADMAP.md unit 2.
	if "`nodecov'" != "" {
		confirm variable `nodecov'
		tempname __td_nc
		mata: `__td_nc' = ErgmTermData()
		mata: `__td_nc'.attr = st_data(1::`nodes', "`nodecov'")
		mata: __nwsaom_last_M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), `__td_nc', ("nodecov_`nodecov'"))
		local __nwsaom_efflist "`__nwsaom_efflist' nodecov(`nodecov')"
	}
	if "`nodeicov'" != "" {
		confirm variable `nodeicov'
		tempname __td_nic
		mata: `__td_nic' = ErgmTermData()
		mata: `__td_nic'.attr = st_data(1::`nodes', "`nodeicov'")
		mata: __nwsaom_last_M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), `__td_nic', ("`__nwsaom_altlab'_`nodeicov'"))
		local __nwsaom_efflist "`__nwsaom_efflist' `__nwsaom_altlab'(`nodeicov')"
	}
	if "`nodeocov'" != "" {
		confirm variable `nodeocov'
		tempname __td_noc
		mata: `__td_noc' = ErgmTermData()
		mata: `__td_noc'.attr = st_data(1::`nodes', "`nodeocov'")
		mata: __nwsaom_last_M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), `__td_noc', ("`__nwsaom_egolab'_`nodeocov'"))
		local __nwsaom_efflist "`__nwsaom_efflist' `__nwsaom_egolab'(`nodeocov')"
	}

	// --- indegpopularity/outactivity: freshly-derived SAOM-native
	// effects (unw_saom.do's own "SAOM-native effect library" section) -
	// NOT ports of any nwergm term. See docs/SAOM_ROADMAP.md unit 3.
	if "`indegpopularity'" != "" {
		tempname __td_ip
		mata: `__td_ip' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("indegpopularity", 1, &stat_saom_indegpop(), &change_saom_indegpop(), `__td_ip', ("indegpopularity"))
		local __nwsaom_efflist "`__nwsaom_efflist' indegpopularity"
	}
	if "`outactivity'" != "" {
		tempname __td_oa
		mata: `__td_oa' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outactivity", 1, &stat_saom_outactivity(), &change_saom_outactivity(), `__td_oa', ("outactivity"))
		local __nwsaom_efflist "`__nwsaom_efflist' outactivity"
	}

	// --- isolatenet/outiso (harmonisation unit 34): freshly-derived
	// SAOM-native effects, verified directly against RSiena's own real
	// IsolateNetEffect.cpp/TruncatedOutdegreeEffect.cpp source - see
	// unw_saom.do's own "SAOM-native effect library" section for the
	// full derivation, including a real, disclosed genuine multi-actor
	// spillover isolatenet has (creating a tie also changes the
	// ALTER's own indegree, which can independently change the alter's
	// own isolate status too) that outiso does not.
	if "`isolatenet'" != "" {
		tempname __td_isn
		mata: `__td_isn' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("isolatenet", 1, &stat_saom_isolatenet(), &change_saom_isolatenet(), `__td_isn', ("isolatenet"))
		local __nwsaom_efflist "`__nwsaom_efflist' isolatenet"
	}
	if "`outiso'" != "" {
		tempname __td_oiso
		mata: `__td_oiso' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outiso", 1, &stat_saom_outiso(), &change_saom_outiso(), `__td_oiso', ("outiso"))
		local __nwsaom_efflist "`__nwsaom_efflist' outiso"
	}

	// --- antiiso/antiiniso/antiiniso2/isolatepop (harmonisation unit 36):
	// the alter-indexed isolate family deferred alongside isolatenet/
	// outiso above - verified directly against RSiena's own real
	// AntiIsolateEffect.cpp/IsolatePopEffect.cpp source (fetched fresh
	// from CRAN), not assumed by name similarity to isolatenet/outiso.
	// See unw_saom.do's own header comment on these four for the full
	// derivation, including why (unlike isolatenet) none of these four
	// has a multi-actor spillover - their own change() already captures
	// the FULL global-statistic delta for a given toggle.
	if "`antiiso'" != "" {
		tempname __td_aiso
		mata: `__td_aiso' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("antiiso", 1, &stat_saom_antiiso(), &change_saom_antiiso(), `__td_aiso', ("antiiso"))
		local __nwsaom_efflist "`__nwsaom_efflist' antiiso"
	}
	if "`antiiniso'" != "" {
		tempname __td_ains
		mata: `__td_ains' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("antiiniso", 1, &stat_saom_antiiniso(), &change_saom_antiiniso(), `__td_ains', ("antiiniso"))
		local __nwsaom_efflist "`__nwsaom_efflist' antiiniso"
	}
	if "`antiiniso2'" != "" {
		tempname __td_ains2
		mata: `__td_ains2' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("antiiniso2", 1, &stat_saom_antiiniso2(), &change_saom_antiiniso2(), `__td_ains2', ("antiiniso2"))
		local __nwsaom_efflist "`__nwsaom_efflist' antiiniso2"
	}
	// in3plus (RSiena's real "in3Plus" - EffectFactory.cpp dispatches it to
	// the SAME AntiIsolateEffect class as antiInIso/antiInIso2, just with
	// minDegree=3 - see unw_saom.do's own header comment). Exposed as the
	// `inplus3' OPTION (digit moved to the end) rather than `in3plus'
	// because Stata's own `syntax' command silently rejects any option
	// name with a digit followed by more letters (confirmed directly:
	// `syntax [, IN3PLUS]' makes "option in3plus not allowed" fire even
	// on an exact, non-abbreviated match - a real, general `syntax'
	// limitation, not specific to this term) - every OTHER identifier
	// (the Mata function names, the addterm() term-name string, and the
	// resulting coefficient's own row name/label) stays "in3plus"
	// unchanged, since Mata identifiers and matrix row names are not
	// subject to this restriction.
	if "`inplus3'" != "" {
		tempname __td_in3p
		mata: `__td_in3p' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("in3plus", 1, &stat_saom_in3plus(), &change_saom_in3plus(), `__td_in3p', ("in3plus"))
		local __nwsaom_efflist "`__nwsaom_efflist' in3plus"
	}
	if "`isolatepop'" != "" {
		tempname __td_ipop
		mata: `__td_ipop' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("isolatepop", 1, &stat_saom_isolatepop(), &change_saom_isolatepop(), `__td_ipop', ("isolatepop"))
		local __nwsaom_efflist "`__nwsaom_efflist' isolatepop"
	}

	// --- transrectrip/outoutass (harmonisation unit 37): a small batch
	// from RSiena's own real remaining effect catalog, verified directly
	// against TransitiveReciprocatedTripletsEffect.cpp/
	// OutOutDegreeAssortativityEffect.cpp - see unw_saom.do's own header
	// comments on each for the full derivation. Default/base
	// parameterization only (no sqrt-root variants) - v1 scope.
	// (transties itself already exists - harmonisation unit 23, above -
	// discovered mid-unit and NOT re-implemented here; see docs/SAOM_ROADMAP.md
	// unit 37's own account of this near-duplication.)
	if "`transrectrip'" != "" {
		tempname __td_trt
		mata: `__td_trt' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("transrectrip", 1, &stat_saom_transrectrip(), &change_saom_transrectrip(), `__td_trt', ("transrectrip"))
		local __nwsaom_efflist "`__nwsaom_efflist' transrectrip"
	}
	if "`outoutass'" != "" {
		tempname __td_ooa
		mata: `__td_ooa' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outoutass", 1, &stat_saom_outoutass(), &change_saom_outoutass(), `__td_ooa', ("outoutass"))
		local __nwsaom_efflist "`__nwsaom_efflist' outoutass"
	}
	if "`ininass'" != "" {
		tempname __td_iia
		mata: `__td_iia' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("ininass", 1, &stat_saom_ininass(), &change_saom_ininass(), `__td_iia', ("ininass"))
		local __nwsaom_efflist "`__nwsaom_efflist' ininass"
	}

	// --- outinass/inoutass (harmonisation unit 165): the two remaining
	// directed-assortativity directions unit 37 above explicitly left
	// "still remaining" - verified directly against the real
	// OutInDegreeAssortativityEffect.cpp/InOutDegreeAssortativityEffect.cpp,
	// see unw_saom.do's own header comments on each for the full
	// derivation (outinass is NOT a mechanical degree-substitution of
	// outoutass - a real asymmetry in the source's own creating-branch
	// formula would have been missed by that shortcut).
	if "`outinass'" != "" {
		tempname __td_oia
		mata: `__td_oia' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outinass", 1, &stat_saom_outinass(), &change_saom_outinass(), `__td_oia', ("outinass"))
		local __nwsaom_efflist "`__nwsaom_efflist' outinass"
	}
	if "`inoutass'" != "" {
		tempname __td_ioa
		mata: `__td_ioa' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("inoutass", 1, &stat_saom_inoutass(), &change_saom_inoutass(), `__td_ioa', ("inoutass"))
		local __nwsaom_efflist "`__nwsaom_efflist' inoutass"
	}

	// --- transtrip/cycle3: freshly-derived SAOM-native structural
	// effects (harmonisation units 4-5), reusing ErgmGraph's own
	// already-certified shared_partners_otp()/_osp()/_isp() PRIMITIVES
	// internally (see unw_saom.do's own header comments on each for the
	// exact derivation). See docs/SAOM_ROADMAP.md units 4-5.
	if "`transtrip'" != "" {
		tempname __td_tt
		mata: `__td_tt' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("transtrip", 1, &stat_saom_transtrip(), &change_saom_transtrip(), `__td_tt', ("transtrip"))
		local __nwsaom_efflist "`__nwsaom_efflist' transtrip"
	}
	// transMedTrip (RSiena's real, distinct sibling of transTrip - see
	// unw_saom.do's own header comment on stat_saom_transmedtrip() for
	// the source-verified derivation): pure ISP(ego,alter), not
	// transTrip's own OTP+OSP combination.
	if "`transmedtrip'" != "" {
		tempname __td_tmt
		mata: `__td_tmt' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("transmedtrip", 1, &stat_saom_transmedtrip(), &change_saom_transmedtrip(), `__td_tmt', ("transmedtrip"))
		local __nwsaom_efflist "`__nwsaom_efflist' transmedtrip"
	}
	// reciact/recipop (RSiena's real "reciAct"/"reciPop") were investigated
	// and NOT shipped - see unw_saom.do's own header comment (right after
	// in3plus above) for the full account: both formulas are transcribed
	// verbatim from real RSiena C++ source, but failed this project's own
	// standard local-recompute certification, suggesting a semantic
	// difference in what calculateContribution() represents for these two
	// effects specifically - left as a documented starting point, not
	// registered here.
	if "`cycle3'" != "" {
		tempname __td_c3
		mata: `__td_c3' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("cycle3", 1, &stat_saom_cycle3(), &change_saom_cycle3(), `__td_c3', ("cycle3"))
		local __nwsaom_efflist "`__nwsaom_efflist' cycle3"
	}
	// cycle4 (harmonisation unit 168): RSiena's own four-cycles effect,
	// deferred by unit 37 pending a directedness verification that unit
	// 168 completed - see unw_saom.do's own header comment above
	// stat_saom_cycle4() for the full source-verified derivation.
	if "`cycle4'" != "" {
		tempname __td_c4
		mata: `__td_c4' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("cycle4", 1, &stat_saom_cycle4(), &change_saom_cycle4(), `__td_c4', ("cycle4"))
		local __nwsaom_efflist "`__nwsaom_efflist' cycle4"
	}

	// --- gwesp(): harmonisation unit 22 ("GWESP reuse verification" per
	// explicit user direction), CORRECTED after a real bug was caught on
	// direct follow-up ("build the gof plot entirely like in Rsiena" ->
	// GWESP scrutiny -> checking nwsaom's own gwespFF ministep formula
	// against RSiena's own real GenericNetworkEffect.cpp source, not
	// assumed). The GLOBAL/observed statistic is still DIRECT reuse of
	// nwergm's own already-certified stat_gwesp() (unw_ergm.do,
	// read-only reference) - RSiena's own tieStatistic() confirmed to
	// match that formula exactly. The MINISTEP/change statistic is NOT
	// nwergm's own change_gwesp() - that is the full ERGM/MCMC-style
	// "how does the global statistic change when this dyad toggles"
	// delta (own-dyad term plus two neighbor-adjustment loops), the
	// wrong standard here: real RSiena's own actual ministep
	// contribution for `gwespFF' (`GenericNetworkEffect::
	// calculateContribution()') is JUST the GwespFunction kernel's own
	// lookup for the (ego,alter) dyad's OWN current shared-partner
	// count - no neighbor loops at all, a genuinely simpler
	// approximation specific to RSiena's own "Generic" effect
	// framework for nonlinear geometrically-weighted terms (see
	// unw_saom.do's own change_saom_gwesp() header comment for the full
	// account). `td.sptype' is ALWAYS forced to "OTP" here (never left
	// empty, unlike nwergm.ado's own optional type() - an empty sptype
	// falls through to stat_gwesp()'s own UNDIRECTED default branch,
	// wrong for a network that is always directed here). `decay' is
	// nwergm's own DIRECT convention (Statnet's own gwesp(decay=)
	// scale) - NOT RSiena's own user-facing "parameter", which is 100x
	// this value (RSiena's own default parm=69 corresponds to decay(.69)
	// here - confirmed directly from RSiena's real GwespFunction.cpp
	// source: `weight = -0.01 * parameter'; unaffected by this
	// correction). NOT YET natively ported (v1 Mata-only) -
	// SaomNativeSetup() correctly falls back to the pure-Mata path for
	// any model using this term.
	if "`gwesp'" != "" {
		confirm number `gwesp'
		tempname __td_gw
		mata: `__td_gw' = ErgmTermData()
		mata: `__td_gw'.decay = `gwesp'
		mata: `__td_gw'.sptype = "OTP"
		mata: __nwsaom_last_M.addterm("gwesp", 1, &stat_gwesp(), &change_saom_gwesp(), `__td_gw', ("gwesp_`gwesp'"))
		local __nwsaom_efflist "`__nwsaom_efflist' gwesp(`gwesp')"
	}

	// --- transties: harmonisation unit 23. NO free parameter (unlike
	// gwesp() - RSiena's own transTies has none either), so a plain
	// flag like transtrip/cycle3. The GLOBAL/observed statistic is
	// direct reuse of nwergm's own already-certified
	// stat_transitiveties() (unw_ergm.do, read-only reference) - RSiena's
	// own tieStatistic() confirmed to match exactly. The MINISTEP/change
	// statistic is unw_saom.do's own NEW change_saom_transties() - NOT
	// nwergm's own change_transitiveties() (see that new function's own
	// header comment for the full derivation from real RSiena source:
	// nwergm's own version includes a "na" spillover loop onto OTHER
	// actors' own ties that real RSiena's own TransitiveTiesEffect.cpp
	// explicitly excludes from a SAOM actor's own ministep utility -
	// the SAME "myopic actor" restriction transtrip/cycle3 already
	// apply, applying the lesson unit 22's own correction established:
	// read the actual RSiena ministep-contribution class BEFORE wiring
	// anything, not just a statistic formula). NOT YET natively ported
	// (v1 Mata-only).
	if "`transties'" != "" {
		tempname __td_tt2
		mata: `__td_tt2' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("transties", 1, &stat_transitiveties(), &change_saom_transties(), `__td_tt2', ("transties"))
		local __nwsaom_efflist "`__nwsaom_efflist' transties"
	}

	// --- balance: harmonisation unit 25. NO user-supplied free
	// parameter - RSiena's own "balanceMean" (b0 in the SIENA manual's
	// formula) is a DATA-DERIVED constant computed from the observed
	// period-BASE wave(s) (`__nwsaom_last_Gbases', built above,
	// unconditionally, right after the per-wave ErgmGraph objects),
	// exactly matching real RSiena's own `calcBalmean()`
	// (`R/sienaDataCreate.r`) - pooled across periods by SUMMING
	// numerators/denominators then dividing ONCE (same convention as
	// unit 17/18's theta/Jacobian pooling and unit 21's GOF
	// `join=TRUE`), not a per-period average. Reuses the `decay' scalar
	// field for this constant (same convention already established for
	// gwesp()'s decay and simcov()'s range). See unw_saom.do's own
	// `saom_balance_mean()'/`stat_saom_balance()'/`change_saom_balance()'
	// header comment for the full derivation from real RSiena source
	// (`BalanceEffect.cpp`) - a dedicated, non-"Generic effect" RSiena
	// class like transties (unit 23), so its ministep formula is the
	// exact ego-restricted gradient, certified via the standard
	// ego-level brute-force methodology. NOT YET natively ported (v1
	// Mata-only).
	if "`balance'" != "" {
		tempname __td_bal
		mata: `__td_bal' = ErgmTermData()
		mata: `__td_bal'.decay = saom_balance_mean(__nwsaom_last_Gbases)
		mata: __nwsaom_last_M.addterm("balance", 1, &stat_saom_balance(), &change_saom_balance(), `__td_bal', ("balance"))
		local __nwsaom_efflist "`__nwsaom_efflist' balance"
	}

	// --- outpopularity/inactivity/simcov: harmonisation unit 9, each
	// independently verified against the real RSiena C++ source (see
	// unw_saom.do's own header comments) before implementation. See
	// docs/SAOM_ROADMAP.md unit 9.
	if "`outpopularity'" != "" {
		tempname __td_op
		mata: `__td_op' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("outpopularity", 1, &stat_saom_outpop(), &change_saom_outpop(), `__td_op', ("outpopularity"))
		local __nwsaom_efflist "`__nwsaom_efflist' outpopularity"
	}
	if "`inactivity'" != "" {
		tempname __td_ia
		mata: `__td_ia' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("inactivity", 1, &stat_saom_inact(), &change_saom_inact(), `__td_ia', ("inactivity"))
		local __nwsaom_efflist "`__nwsaom_efflist' inactivity"
	}
	if "`simcov'" != "" {
		confirm variable `simcov'
		tempname __td_sc
		mata: `__td_sc' = ErgmTermData()
		mata: `__td_sc'.attr = st_data(1::`nodes', "`simcov'")
		mata: `__td_sc'.decay = max(`__td_sc'.attr) - min(`__td_sc'.attr)
		mata: __nwsaom_last_M.addterm("simcov", 1, &stat_saom_simcov(), &change_saom_simcov(), `__td_sc', ("`__nwsaom_simlab'_`simcov'"))
		local __nwsaom_efflist "`__nwsaom_efflist' `__nwsaom_simlab'(`simcov')"
	}

	// --- interact(): two-way interaction effects (RSiena's own
	// includeInteraction()) between two effects ALREADY added above as
	// their own main-effect terms - see unw_saom.do's own
	// "Interaction effects" header comment (right after
	// change_saom_balance()) for the full design/derivation account
	// (direct port of RSiena's real NetworkInteractionEffect, confirmed
	// from RSiena/src/model/effects/NetworkInteractionEffect.cpp).
	// Syntax mirrors Stata's own factor-variable `#' for a familiar,
	// multiple-pairs-in-one-option shape: interact(effect1#effect2
	// [effect3#effect4 ...]). Restricted to the "dyadic" (tie-summed)
	// effect subset that has a well-defined tieStatistic() at all - the
	// node-level/nonlinear-in-degree effects (indegpopularity,
	// outactivity, outpopularity, inactivity, isolatenet, outiso,
	// antiiso, antiiniso, antiiniso2, inplus3 - RSiena's own "ego
	// effects") are rejected here with a clear message, matching
	// TERMCODE_INTERACT2's own #define comment in native/saom_sim.c.
	// egox()/altx()/samex()/simx() (RSiena's own aliases, this file's
	// own top-of-program section) are accepted here too, resolved to
	// their canonical Statnet-style name before lookup - the interacting
	// effect must already appear in the model under THAT canonical name
	// (SaomBuildInteractTd()'s own name-based lookup against
	// __nwsaom_last_M, unw_saom.do), regardless of which spelling
	// originally added it. Three-way interactions (RSiena's optional
	// third effect) and behavior-behavior/network-behavior interactions
	// are a disclosed, not-yet-built follow-up (docs/SAOM_ROADMAP.md).
	if "`interact'" != "" {
		local __nwsaom_ixok "outdegree reciprocity nodematch nodecov nodeicov nodeocov transtrip cycle3 simcov transrectrip outoutass ininass outinass inoutass cycle4 transmedtrip gwesp transties balance"
		local __nwsaom_ixn = 0
		foreach __nwsaom_ixpair of local interact {
			local __nwsaom_ixwords = subinstr("`__nwsaom_ixpair'", "#", " ", .)
			local __nwsaom_ixnw : word count `__nwsaom_ixwords'
			if `__nwsaom_ixnw' != 2 {
				di "{err}interact() expects effect1#effect2 pairs (two-way interactions only in this version); got: `__nwsaom_ixpair'"
				error 198
			}
			local __nwsaom_ixa : word 1 of `__nwsaom_ixwords'
			local __nwsaom_ixb : word 2 of `__nwsaom_ixwords'
			if "`__nwsaom_ixa'" == "samex" local __nwsaom_ixa "nodematch"
			if "`__nwsaom_ixa'" == "simx" local __nwsaom_ixa "simcov"
			if "`__nwsaom_ixa'" == "altx" local __nwsaom_ixa "nodeicov"
			if "`__nwsaom_ixa'" == "egox" local __nwsaom_ixa "nodeocov"
			if "`__nwsaom_ixb'" == "samex" local __nwsaom_ixb "nodematch"
			if "`__nwsaom_ixb'" == "simx" local __nwsaom_ixb "simcov"
			if "`__nwsaom_ixb'" == "altx" local __nwsaom_ixb "nodeicov"
			if "`__nwsaom_ixb'" == "egox" local __nwsaom_ixb "nodeocov"
			local __nwsaom_ixposa : list posof "`__nwsaom_ixa'" in __nwsaom_ixok
			local __nwsaom_ixposb : list posof "`__nwsaom_ixb'" in __nwsaom_ixok
			if `__nwsaom_ixposa' == 0 | `__nwsaom_ixposb' == 0 {
				di "{err}interact() only supports interactions between dyadic (tie-level) effects, which have a well-defined per-tie contribution to multiply - not the node-level effects ({bf:indegpopularity outactivity outpopularity inactivity isolatenet outiso antiiso antiiniso antiiniso2 inplus3}). Got: `__nwsaom_ixa'#`__nwsaom_ixb'"
				error 198
			}
			local __nwsaom_ixn = `__nwsaom_ixn' + 1
			tempname __td_ix`__nwsaom_ixn'
			mata: `__td_ix`__nwsaom_ixn'' = ErgmTermData()
			mata: SaomBuildInteractTd(__nwsaom_last_M, `nodes', "`__nwsaom_ixa'", "`__nwsaom_ixb'", `__td_ix`__nwsaom_ixn'')
			mata: __nwsaom_last_M.addterm("interact", 1, &stat_saom_interact(), &change_saom_interact(), `__td_ix`__nwsaom_ixn'', ("interact_`__nwsaom_ixa'_`__nwsaom_ixb'"))
			local __nwsaom_efflist "`__nwsaom_efflist' interact(`__nwsaom_ixa'#`__nwsaom_ixb')"
		}
	}

	mata: st_local("__nwsaom_p", strofreal(__nwsaom_last_M.nparam()))

	// --- behavior model: harmonisation unit 26. `linear'/`quadratic'/
	// `avalt' independently verified against real RSiena source
	// (LinearShapeEffect.cpp/QuadraticShapeEffect.cpp/
	// AverageAlterEffect.cpp - docs/SAOM_ROADMAP.md's own unit-26
	// DESIGN section has the full account) and certified via ego-level
	// brute-force recomputation (cscripts/test_nwsaom_mata.do's own
	// unit 26). Coefficient names prefixed `beh_' at the OUTPUT-NAMING
	// level only (SaomBehaviorModel's own coefnames stay plain
	// "linear"/"quadratic"/"avalt", matching unw_saom.do's own
	// established convention) - per explicit user requirement, the
	// coefficient table must show which effects belong to the behavior
	// side clearly, not just append them indistinguishably after the
	// network effects.
	local __nwsaom_pbeh = 0
	if `__nwsaom_coev' {
		capture mata: mata drop __nwsaom_last_Mbeh
		mata: __nwsaom_last_Mbeh = SaomBehaviorModel()
		mata: __nwsaom_last_Mbeh.init()

		local __nwsaom_endowcreation = 0
		local __nwsaom_effbeh ""
		// Baseline role (mutually exclusive: plain `linear' eval, or the
		// linearendow/linearcreation split) - ALWAYS resolved first and
		// unconditionally, independent of whatever quadratic/avalt/avsim
		// roles are added below. Harmonisation unit 166 generalized
		// quadratic/avalt/avsim's own role-splits to be genuinely
		// ORTHOGONAL to this baseline choice (any combination of "plain
		// or split" per effect is valid) rather than folding
		// quadraticendow into this same if/else-if chain as unit 166's
		// own first draft mistakenly did - that draft required the user
		// to type `quadraticendow'/`quadraticcreation' WITHOUT `linear',
		// silently relying on this block's own internal auto-added
		// `linear' term, which the top-of-program required-baseline
		// validation above (checking `linear'/`linearendow' literally)
		// had no way to know about - caught immediately by the first
		// real smoke test ("every co-evolution model requires a baseline
		// linear shape effect..." fired even though a linear term WAS
		// being added internally). Fixed by making the baseline
		// resolution unconditional and orthogonal, matching how
		// avalt/avsim's own splits already worked correctly from the
		// start.
		if "`linearendow'" != "" {
			// harmonisation unit 28 (endowment/creation functions):
			// SHIPPED, protected by SaomCheckThetaBound() (harmonisation
			// unit 29, unw_saom.do) - real RSiena's own manual (fetched
			// and read directly, not from memory) documents this exact
			// combination as an inherent WEAK-IDENTIFICATION property,
			// not a defect: "if a given effect is similarly strong for
			// the creation and maintenance of ties the statistical power
			// will decrease by this split" and "this would lead to large
			// standard errors" - the same manual's own advice is to
			// START without creation/endowment and add them only "if
			// there is enough data". A ground-truth recovery test
			// (docs/SAOM_ROADMAP.md's own unit-28/unit-29 entries) found
			// that even a MODEST true theta pair can, on a given finite
			// dataset, push the Robbins-Monro update into a genuinely
			// ill-conditioned direction (a near-singular phase-1 Jacobian
			// along the theta_endow/theta_creation "sum" direction) -
			// exactly the scenario real RSiena's own thetaBound safeguard
			// exists to catch (its own R/phase2.r checks the identical
			// condition at the identical point, `cat()`/`stop()`ping the
			// same way) - confirmed directly against RSiena's own R
			// source, not assumed. If this model specification hits that
			// error, real RSiena would very plausibly hit it too on the
			// same data; the fix is the same one RSiena's manual
			// recommends: drop back to plain `linear', or supply better
			// starting values via `behtheta0()'.
			mata: __nwsaom_last_Mbeh.addterm("linear_endow", &stat_saom_linear(), &change_saom_linear(), "beh_linear_endow", 1)
			mata: __nwsaom_last_Mbeh.addterm("linear_creation", &stat_saom_linear(), &change_saom_linear(), "beh_linear_creation", 2)
			local __nwsaom_effbeh "linearendow linearcreation"
			local __nwsaom_endowcreation = 1
		}
		else {
			mata: __nwsaom_last_Mbeh.addterm("linear", &stat_saom_linear(), &change_saom_linear(), "beh_linear")
			local __nwsaom_effbeh "linear"
		}
		// Quadratic role (mutually exclusive: plain, or the unit-166
		// quadraticendow/quadraticcreation split) - orthogonal to the
		// baseline resolved above, same generic fntype=1/2 mechanism
		// linearendow/linearcreation already established.
		if "`quadratic'" != "" {
			mata: __nwsaom_last_Mbeh.addterm("quadratic", &stat_saom_quadratic(), &change_saom_quadratic(), "beh_quadratic")
			local __nwsaom_effbeh "`__nwsaom_effbeh' quadratic"
		}
		else if "`quadraticendow'" != "" {
			mata: __nwsaom_last_Mbeh.addterm("quadratic_endow", &stat_saom_quadratic(), &change_saom_quadratic(), "beh_quadratic_endow", 1)
			mata: __nwsaom_last_Mbeh.addterm("quadratic_creation", &stat_saom_quadratic(), &change_saom_quadratic(), "beh_quadratic_creation", 2)
			local __nwsaom_effbeh "`__nwsaom_effbeh' quadraticendow quadraticcreation"
			local __nwsaom_endowcreation = 1
		}
		if "`avalt'" != "" {
			mata: __nwsaom_last_Mbeh.addterm("avalt", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt")
			local __nwsaom_effbeh "`__nwsaom_effbeh' avalt"
		}
		else if "`avaltendow'" != "" {
			mata: __nwsaom_last_Mbeh.addterm("avalt_endow", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt_endow", 1)
			mata: __nwsaom_last_Mbeh.addterm("avalt_creation", &stat_saom_avalt(), &change_saom_avalt(), "beh_avalt_creation", 2)
			local __nwsaom_effbeh "`__nwsaom_effbeh' avaltendow avaltcreation"
			local __nwsaom_endowcreation = 1
		}
		if "`avsim'" != "" {
			mata: __nwsaom_last_Mbeh.addterm("avsim", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim")
			local __nwsaom_effbeh "`__nwsaom_effbeh' avsim"
		}
		else if "`avsimendow'" != "" {
			mata: __nwsaom_last_Mbeh.addterm("avsim_endow", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim_endow", 1)
			mata: __nwsaom_last_Mbeh.addterm("avsim_creation", &stat_saom_avsim(), &change_saom_avsim(), "beh_avsim_creation", 2)
			local __nwsaom_effbeh "`__nwsaom_effbeh' avsimendow avsimcreation"
			local __nwsaom_endowcreation = 1
		}
		local __nwsaom_efflist "`__nwsaom_efflist' [behavior: `__nwsaom_effbeh']"

		// --- behavior data: one Stata variable per wave, read from
		// whatever dataset is current at call time (same convention
		// nodeicov()/simcov() etc. already use). Built per-wave, one
		// Mata colvector each, exactly mirroring __nwsaom_last_G`__w''s
		// own "one persistent Mata object per wave" convention above -
		// min/max/overallMean pool across EVERY wave (not just the
		// first/last), matching real RSiena's own BehaviorLongitudinalData
		// scope: a single set of constants for the whole variable,
		// computed once, not period-specific. `__nwsaom_beh_startvals'/
		// `__nwsaom_beh_endvals' (wave 1's own / the LAST wave's own
		// values) are kept as their own names too - still exactly what
		// the two-wave SaomEstimateRMCoev() path needs, unchanged.
		capture mata: mata drop __nwsaom_beh_minval __nwsaom_beh_maxval __nwsaom_beh_startvals __nwsaom_beh_endvals __nwsaom_last_Behwaves
		mata: __nwsaom_beh_minval = .
		mata: __nwsaom_beh_maxval = .
		// harmonisation unit 35: min/max pooled over OBSERVED entries
		// only when missbeh() is active - a missing cell's own raw
		// Stata value (Stata's own `.', an out-of-range sentinel, or
		// simply stale) must never widen/corrupt behminval/behmaxval.
		// (overallMean itself is computed inside the estimator from the
		// already-imputed start/end - or pooled multi-wave - values, an
		// existing, unchanged convention; imputed values are always
		// drawn from genuinely observed data elsewhere, so this does
		// not need the same observed-only filtering min/max needs here.)
		forvalues __w = 1/`__nwsaom_nwaves' {
			local __wbeh : word `__w' of `behavior'
			confirm variable `__wbeh'
			capture mata: mata drop __nwsaom_beh_w`__w' __nwsaom_missbeh_w`__w' __nwsaom_beh_obs`__w'
			mata: __nwsaom_beh_w`__w' = st_data(1::`nodes', "`__wbeh'")
			if `__nwsaom_hasmissbeh' {
				local __wmissbeh : word `__w' of `missbeh'
				confirm variable `__wmissbeh'
				capture assert inlist(`__wmissbeh', 0, 1)
				if _rc {
					di "{err}option {bf:missbeh()} variables must be coded 0/1 (0=observed, 1=missing) - `__wmissbeh' has a value outside {0,1}."
					error 198
				}
				mata: __nwsaom_missbeh_w`__w' = st_data(1::`nodes', "`__wmissbeh'")
			}
			else mata: __nwsaom_missbeh_w`__w' = J(`nodes', 1, 0)
			mata: __nwsaom_beh_obs`__w' = select(__nwsaom_beh_w`__w', __nwsaom_missbeh_w`__w' :== 0)
			mata: st_local("__nwsaom_beh_nobs`__w'", strofreal(rows(__nwsaom_beh_obs`__w')))
			if `__nwsaom_beh_nobs`__w'' > 0 {
				mata: __nwsaom_beh_minval = (__nwsaom_beh_minval==. ? min(__nwsaom_beh_obs`__w') : min((__nwsaom_beh_minval, min(__nwsaom_beh_obs`__w'))))
				mata: __nwsaom_beh_maxval = (__nwsaom_beh_maxval==. ? max(__nwsaom_beh_obs`__w') : max((__nwsaom_beh_maxval, max(__nwsaom_beh_obs`__w'))))
			}
		}

		// --- missbeh(): impute missing actor-values (harmonisation unit
		// 35, SaomImputeBehaviorWave() - previous observation, else
		// next, else the observationwise mode), REPLACING each wave's
		// own raw __nwsaom_beh_w`__w' with the imputed version - needs
		// visibility across every wave at once (unlike the network
		// side's own pure-forward LOCF), so it runs as its own pass
		// AFTER every wave's raw/missingness data is loaded above.
		if `__nwsaom_hasmissbeh' {
			local __nwsaom_rawbehptrlist ""
			local __nwsaom_missbehptrlist ""
			forvalues __w = 1/`__nwsaom_nwaves' {
				if `__w' == 1 {
					local __nwsaom_rawbehptrlist "&__nwsaom_beh_w1"
					local __nwsaom_missbehptrlist "&__nwsaom_missbeh_w1"
				}
				else {
					local __nwsaom_rawbehptrlist "`__nwsaom_rawbehptrlist', &__nwsaom_beh_w`__w'"
					local __nwsaom_missbehptrlist "`__nwsaom_missbehptrlist', &__nwsaom_missbeh_w`__w'"
				}
			}
			capture mata: mata drop __nwsaom_rawbehptr __nwsaom_missbehptr
			mata: __nwsaom_rawbehptr = (`__nwsaom_rawbehptrlist')
			mata: __nwsaom_missbehptr = (`__nwsaom_missbehptrlist')
			forvalues __w = 1/`__nwsaom_nwaves' {
				mata: __nwsaom_beh_w`__w' = SaomImputeBehaviorWave(__nwsaom_rawbehptr, __nwsaom_missbehptr, `__nwsaom_nwaves', `nodes', `__w')
			}
		}

		mata: __nwsaom_beh_startvals = __nwsaom_beh_w1
		mata: __nwsaom_beh_endvals = __nwsaom_beh_w`__nwsaom_nwaves'

		local __nwsaom_behptrlist ""
		forvalues __w = 1/`__nwsaom_nwaves' {
			if `__w' == 1 local __nwsaom_behptrlist "&__nwsaom_beh_w1"
			else local __nwsaom_behptrlist "`__nwsaom_behptrlist', &__nwsaom_beh_w`__w'"
		}
		mata: __nwsaom_last_Behwaves = (`__nwsaom_behptrlist')

		// --- missbeh(): derive the PERIOD-level union mask(s) the
		// co-evolution estimators themselves take (same "missing at
		// either endpoint wave" rule as the network side above).
		// `__nwsaom_missmaskbeh1' (single n x 1) is what the two-wave
		// SaomEstimateRMCoev() path needs; the pointer array
		// `__nwsaom_missmaskbehptr' (one n x 1 mask per period) is what
		// SaomEstimateRMCoevMulti() needs. Built whenever ANY missing
		// data is active (missnet() alone still needs an all-zero
		// behavior mask, same "never branch at the call site" rationale
		// as the network side's own missnet()-only case above).
		if `__nwsaom_hasmiss' {
			forvalues __pd = 1/`__nwsaom_nperiods' {
				local __pd1 = `__pd'
				local __pd2 = `__pd' + 1
				capture mata: mata drop __nwsaom_missmaskbehpd`__pd'
				if `__nwsaom_hasmissbeh' {
					mata: __nwsaom_missmaskbehpd`__pd' = (__nwsaom_missbeh_w`__pd1' :| __nwsaom_missbeh_w`__pd2')
				}
				else {
					mata: __nwsaom_missmaskbehpd`__pd' = J(`nodes', 1, 0)
				}
			}
			capture mata: mata drop __nwsaom_missmaskbeh1
			mata: __nwsaom_missmaskbeh1 = __nwsaom_missmaskbehpd1
			if `__nwsaom_multi' {
				local __nwsaom_missbehptrlist2 ""
				forvalues __pd = 1/`__nwsaom_nperiods' {
					if `__pd' == 1 local __nwsaom_missbehptrlist2 "&__nwsaom_missmaskbehpd1"
					else local __nwsaom_missbehptrlist2 "`__nwsaom_missbehptrlist2', &__nwsaom_missmaskbehpd`__pd'"
				}
				capture mata: mata drop __nwsaom_missmaskbehptr
				mata: __nwsaom_missmaskbehptr = (`__nwsaom_missbehptrlist2')
			}
		}

		// avsim's own data-derived "similarityMean" constant - computed
		// ONCE here (saom_similarity_mean(), unw_saom.do) and stored on
		// the persisted Mbeh, mirroring balance's own td.decay
		// convention (unit 25): the estimator reads it off Mbeh rather
		// than recomputing it, and estat gof (nwsaom_estat.ado) reuses
		// the SAME persisted value for its own post-fit simulations,
		// exactly as balance's own mean already is. Harmless (never
		// read) whenever avsim was not requested.
		if "`avsim'" != "" {
			mata: __nwsaom_last_Mbeh.setsimmean(saom_similarity_mean(__nwsaom_last_Behwaves, __nwsaom_beh_maxval - __nwsaom_beh_minval))
		}

		mata: st_local("__nwsaom_pbeh", strofreal(__nwsaom_last_Mbeh.nparam()))
	}

	capture mata: mata drop __nwsaom_theta0
	if "`theta0'" == "" {
		mata: __nwsaom_theta0 = J(1, `__nwsaom_p', 0)
	}
	else {
		local __nwsaom_nt : word count `theta0'
		if `__nwsaom_nt' != `__nwsaom_p' {
			di "{err}theta0() must supply exactly `__nwsaom_p' starting value(s) - one per requested effect, in the order: `__nwsaom_efflist'."
			error 198
		}
		mata: __nwsaom_theta0 = strtoreal(tokens("`theta0'"))
	}

	// --- behtheta0(): same size-checked-starting-value convention as
	// theta0() above, but for the behavior side (harmonisation unit
	// 26) - kept as a SEPARATE option rather than folding into theta0()
	// itself, since the two sides are genuinely different parameter
	// blocks (fit jointly, but each with its own effect list/ordering).
	// NAMED `behtheta0', not the more obvious `theta0beh' - a real,
	// independently-discovered Stata `syntax' command limitation
	// (confirmed via a minimal isolated repro, not assumed): an option
	// name that is a PREFIX of another `(string)'-type option's name
	// (here `theta0' is a prefix of `theta0beh') is never recognized by
	// `syntax', regardless of declaration order - `option theta0beh()
	// not allowed' even when passed in full. This option was silently
	// broken since it was introduced (harmonisation unit 26) because no
	// test ever exercised it (cscripts/test_nwsaom_ado.do had zero
	// mentions of it before this fix) - found only while building the
	// harmonisation-unit-28 real-RSiena cross-check (dev/
	// saom_rsiena_crosscheck_endow.do), which needed to warm-start from
	// RSiena's own fitted values.
	capture mata: mata drop __nwsaom_theta0beh
	if `__nwsaom_coev' {
		if "`behtheta0'" == "" {
			mata: __nwsaom_theta0beh = J(1, `__nwsaom_pbeh', 0)
		}
		else {
			local __nwsaom_ntbeh : word count `behtheta0'
			if `__nwsaom_ntbeh' != `__nwsaom_pbeh' {
				di "{err}behtheta0() must supply exactly `__nwsaom_pbeh' starting value(s) - one per requested behavior effect, in the order: `__nwsaom_effbeh'."
				error 198
			}
			mata: __nwsaom_theta0beh = strtoreal(tokens("`behtheta0'"))
		}
	}

	capture mata: mata drop __nwsaom_fit
	if `__nwsaom_coev' & `__nwsaom_multi' {
		// harmonisation unit 26 ("extend it to N waves"): joint
		// network+behavior Method of Moments / Robbins-Monro, chained
		// across every period - see SaomEstimateRMCoevMulti()'s own
		// header comment (unw_saom.do) and docs/SAOM_ROADMAP.md's
		// unit-26 entry for the full account.
		capture mata: mata drop __nwsaom_fit_coevmulti
		if `__nwsaom_hasmiss' {
			// harmonisation unit 35: missing data - `present'/`presentMat'
			// is guaranteed built above (real or an all-present
			// placeholder) whenever `hasmiss' is true, matching Mata's own
			// optional-argument ordering rule.
			mata: __nwsaom_fit_coevmulti = SaomEstimateRMCoevMulti(__nwsaom_last_Gwaves, __nwsaom_last_M, ///
				__nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
				__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg', __nwsaom_presentmat, ///
				__nwsaom_missmaskptr, __nwsaom_missmaskbehptr)
		}
		else if `__nwsaom_haspresent' {
			mata: __nwsaom_fit_coevmulti = SaomEstimateRMCoevMulti(__nwsaom_last_Gwaves, __nwsaom_last_M, ///
				__nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
				__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg', __nwsaom_presentmat)
		}
		else {
			mata: __nwsaom_fit_coevmulti = SaomEstimateRMCoevMulti(__nwsaom_last_Gwaves, __nwsaom_last_M, ///
				__nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
				__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg')
		}
	}
	else if `__nwsaom_coev' {
		// harmonisation unit 26: joint network+behavior Method of
		// Moments / Robbins-Monro - see SaomEstimateRMCoev()'s own
		// header comment (unw_saom.do) and docs/SAOM_ROADMAP.md's
		// unit-26 entry for the full three-phase account.
		capture mata: mata drop __nwsaom_fit_coev
		if `__nwsaom_hasmiss' {
			mata: __nwsaom_fit_coev = SaomEstimateRMCoev(__nwsaom_last_G1, __nwsaom_last_G2, __nwsaom_last_M, ///
				__nwsaom_beh_startvals, __nwsaom_beh_endvals, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
				__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg', __nwsaom_present1, ///
				__nwsaom_missmask1, __nwsaom_missmaskbeh1)
		}
		else if `__nwsaom_haspresent' {
			mata: __nwsaom_fit_coev = SaomEstimateRMCoev(__nwsaom_last_G1, __nwsaom_last_G2, __nwsaom_last_M, ///
				__nwsaom_beh_startvals, __nwsaom_beh_endvals, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
				__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg', __nwsaom_present1)
		}
		else {
			mata: __nwsaom_fit_coev = SaomEstimateRMCoev(__nwsaom_last_G1, __nwsaom_last_G2, __nwsaom_last_M, ///
				__nwsaom_beh_startvals, __nwsaom_beh_endvals, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
				__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg')
		}
	}
	else if `__nwsaom_multi' {
		// harmonisation unit 17: theta is POOLED/shared across every
		// period, rate is period-specific - see SaomEstimateRMMulti()'s
		// own header comment (unw_saom.do) for the real-RSiena
		// verification this pooling convention is based on.
		if `__nwsaom_hasmiss' {
			mata: __nwsaom_fit = SaomEstimateRMMulti(__nwsaom_last_Gwaves, ///
				__nwsaom_last_M, __nwsaom_theta0, `k0', `k3', `firstg', __nwsaom_presentmat, __nwsaom_missmaskptr)
		}
		else if `__nwsaom_haspresent' {
			mata: __nwsaom_fit = SaomEstimateRMMulti(__nwsaom_last_Gwaves, ///
				__nwsaom_last_M, __nwsaom_theta0, `k0', `k3', `firstg', __nwsaom_presentmat)
		}
		else {
			mata: __nwsaom_fit = SaomEstimateRMMulti(__nwsaom_last_Gwaves, ///
				__nwsaom_last_M, __nwsaom_theta0, `k0', `k3', `firstg')
		}
	}
	else {
		if "`symmetric'" != "" & `__nwsaom_hasmiss' {
			// symmetric + missnet()/missbeh() combined (native-first):
			// native/saom_sim.c's own actor/alter draw under symtype
			// already restricts to `presentIdxArr' on BOTH sides (read
			// directly in the C source before wiring this branch, not
			// assumed) - `__nwsaom_present1'/`__nwsaom_missmask1' are
			// already built above (shared with every other branch), just
			// reused here instead of the symmetric-only branch's all-
			// present/no-miss placeholders.
			mata: __nwsaom_symmiss_fntype = J(1, __nwsaom_last_M.nterms, 0)
			mata: __nwsaom_symmiss_ratecovattr = J(0, 1, 0)
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_present1, __nwsaom_missmask1, __nwsaom_symmiss_fntype, __nwsaom_symmiss_ratecovattr, 0, `__nwsaom_symtypeval')
		}
		else if "`symmetric'" != "" & `__nwsaom_haspresent' {
			// symmetric + present() only (composition change WITHOUT
			// missnet()/missbeh()) - same reuse, no-miss mask built
			// alongside __nwsaom_present1 above whenever haspresent (see
			// that block's own header comment).
			mata: __nwsaom_sympres_fntype = J(1, __nwsaom_last_M.nterms, 0)
			mata: __nwsaom_sympres_ratecovattr = J(0, 1, 0)
			mata: __nwsaom_sympres_nomiss = J(`nodes', `nodes', 0)
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_present1, __nwsaom_sympres_nomiss, __nwsaom_sympres_fntype, __nwsaom_sympres_ratecovattr, 0, `__nwsaom_symtypeval')
		}
		else if "`symmetric'" != "" & `__nwsaom_hasratecov' {
			// symmetric + ratecov() combined (native-first): native/
			// saom_sim.c's own ministep loop already gates `hasratecov'
			// (weighted actor/rate selection) and `symtype' (the two-
			// sided BJOINT/BFORCE/BAGREE ministep decision) as two
			// INDEPENDENT flags in the same code path - confirmed
			// directly by reading the C source before wiring this branch,
			// not assumed from the two features simply existing
			// separately. Real ratecovattr built the same way the plain
			// ratecov() branch below does (not the all-zero placeholder
			// the symmetric-only branch uses), since here it is genuinely
			// wanted.
			mata: __nwsaom_symrc_allpresent = J(`nodes', 1, 1)
			mata: __nwsaom_symrc_nomiss = J(`nodes', `nodes', 0)
			mata: __nwsaom_symrc_fntype = J(1, __nwsaom_last_M.nterms, 0)
			mata: __nwsaom_symrc_ratecovattr = st_data(1::`nodes', "`ratecov'")
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_symrc_allpresent, __nwsaom_symrc_nomiss, __nwsaom_symrc_fntype, __nwsaom_symrc_ratecovattr, `ratecovcoef', `__nwsaom_symtypeval')
		}
		else if "`symmetric'" != "" {
			// symmetric: reaching SaomEstimateRM()'s own trailing
			// `symtype' argument requires present/missMask/fntype/
			// ratecovattr/ratecoef to also be supplied first (Mata's own
			// optional-argument ordering rule) - all-present/all-zero/
			// all-eval-fntype no-op placeholders, the SAME already-
			// established pattern hasnetgate/hasratecov use below for the
			// identical reason.
			mata: __nwsaom_sym_allpresent = J(`nodes', 1, 1)
			mata: __nwsaom_sym_nomiss = J(`nodes', `nodes', 0)
			mata: __nwsaom_sym_fntype = J(1, __nwsaom_last_M.nterms, 0)
			mata: __nwsaom_sym_ratecovattr = J(0, 1, 0)
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_sym_allpresent, __nwsaom_sym_nomiss, __nwsaom_sym_fntype, __nwsaom_sym_ratecovattr, 0, `__nwsaom_symtypeval')
		}
		else if `__nwsaom_hasratecov' {
			// Same chained-optional-argument placeholders `hasnetgate'
			// already established above (all-present, all-eval fntype,
			// no missing data) - ratecov() v1 scope requires the plain
			// two-wave case, validated earlier in this program.
			local __nwsaom_ratecov_ntf : word count `__nwsaom_netfntype_list'
			local __nwsaom_ratecov_ntf_commas : subinstr local __nwsaom_netfntype_list " " ",", all
			mata: st_local("__nwsaom_ratecov_pad", strofreal(__nwsaom_last_M.nterms - `__nwsaom_ratecov_ntf'))
			if "`__nwsaom_ratecov_ntf_commas'" != "" {
				mata: __nwsaom_ratecov_fntype = (`__nwsaom_ratecov_ntf_commas', J(1, `__nwsaom_ratecov_pad', 0))
			}
			else {
				mata: __nwsaom_ratecov_fntype = J(1, __nwsaom_last_M.nterms, 0)
			}
			mata: __nwsaom_ratecov_allpresent = J(`nodes', 1, 1)
			mata: __nwsaom_ratecov_nomiss = J(`nodes', `nodes', 0)
			mata: __nwsaom_ratecovattr = st_data(1::`nodes', "`ratecov'")
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_ratecov_allpresent, __nwsaom_ratecov_nomiss, __nwsaom_ratecov_fntype, __nwsaom_ratecovattr, `ratecovcoef')
		}
		else if `__nwsaom_hasnetgate' {
			// harmonisation unit 167: reaching SaomEstimateRM()'s own
			// `fntype' trailing argument requires `present'/`missMask' to
			// also be supplied (Mata's own optional-argument ordering
			// rule) - an all-present vector and an all-zero missMask
			// matrix are both already-established, tested no-op
			// placeholders elsewhere in this file (see that function's own
			// header comment). `__nwsaom_netfntype_n' is however many
			// role-coded slots outdegree/reciprocity's own registration
			// above actually produced (1, 2, 3, or 4); every network term
			// added AFTER that point (nodematch/nodecov/etc. - none of
			// which support endow/creation in this pass) is implicitly
			// eval-type, so the vector is zero-padded up to the model's
			// own final `nterms' count here, once every option has
			// finished registering its own term(s).
			local __nwsaom_netfntype_n : word count `__nwsaom_netfntype_list'
			// Mata's own (a,b,c) row-vector literal needs COMMA
			// separators, not the plain-whitespace separators
			// `__nwsaom_netfntype_list' uses for Stata's own `: word
			// count' to work - converted here, right at the Mata
			// interpolation boundary, rather than storing commas in the
			// Stata local itself (which would break `word count' above).
			local __nwsaom_netfntype_commas : subinstr local __nwsaom_netfntype_list " " ",", all
			mata: st_local("__nwsaom_netfntype_pad", strofreal(__nwsaom_last_M.nterms - `__nwsaom_netfntype_n'))
			mata: __nwsaom_netfntype = (`__nwsaom_netfntype_commas', J(1, `__nwsaom_netfntype_pad', 0))
			mata: __nwsaom_allpresent1 = J(`nodes', 1, 1)
			mata: __nwsaom_nomissmask1 = J(`nodes', `nodes', 0)
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_allpresent1, __nwsaom_nomissmask1, __nwsaom_netfntype)
		}
		else if `__nwsaom_hasmiss' {
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_present1, __nwsaom_missmask1)
		}
		else if `__nwsaom_haspresent' {
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg', __nwsaom_present1)
		}
		else {
			mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
				__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg')
		}
	}

	tempname b tratio V
	if `__nwsaom_coev' & `__nwsaom_multi' {
		mata: st_local("__nwsaom_coefnames", invtokens(__nwsaom_last_M.coefnames) + " " + invtokens(__nwsaom_last_Mbeh.coefnames))
		mata: st_matrix("`b'", (__nwsaom_fit_coevmulti.thetaNet, __nwsaom_fit_coevmulti.thetaBeh))
		mata: st_matrix("`tratio'", (__nwsaom_fit_coevmulti.tratioNet, __nwsaom_fit_coevmulti.tratioBeh))
		mata: st_matrix("`V'", __nwsaom_fit_coevmulti.V)
	}
	else if `__nwsaom_coev' {
		mata: st_local("__nwsaom_coefnames", invtokens(__nwsaom_last_M.coefnames) + " " + invtokens(__nwsaom_last_Mbeh.coefnames))
		mata: st_matrix("`b'", (__nwsaom_fit_coev.thetaNet, __nwsaom_fit_coev.thetaBeh))
		mata: st_matrix("`tratio'", (__nwsaom_fit_coev.tratioNet, __nwsaom_fit_coev.tratioBeh))
		mata: st_matrix("`V'", __nwsaom_fit_coev.V)
	}
	else {
		mata: st_local("__nwsaom_coefnames", invtokens(__nwsaom_last_M.coefnames))
		mata: st_matrix("`b'", __nwsaom_fit.theta)
		mata: st_matrix("`tratio'", __nwsaom_fit.tratio)
		mata: st_matrix("`V'", __nwsaom_fit.V)
	}
	matrix colnames `b' = `__nwsaom_coefnames'
	matrix colnames `tratio' = `__nwsaom_coefnames'
	matrix rownames `tratio' = tratio
	matrix colnames `V' = `__nwsaom_coefnames'
	matrix rownames `V' = `__nwsaom_coefnames'

	local __nwsaom_depname : word 1 of `__nwsaom_wavelist'
	local __nwsaom_lastwave : word `__nwsaom_nwaves' of `__nwsaom_wavelist'
	local __nwsaom_depname "`__nwsaom_depname'_to_`__nwsaom_lastwave'"

	// harmonisation unit 18: e(V), real RSiena's own sandwich-formula
	// covariance matrix (verified against RSiena's actual R source, see
	// unw_saom.do's own header comment on SaomEstimateRM()'s phase 3 for
	// the full derivation/citation) - posting it alongside `b' makes
	// Stata's own standard `ereturn display` machinery report Std. Err./
	// z/P>|z|/95% CI automatically, the normal estimation-command
	// convention, instead of the disclosed "no SEs yet" gap earlier
	// nwsaom versions carried.
	ereturn post `b' `V', depname("`__nwsaom_depname'") obs(`nodes')
	ereturn local cmd "nwsaom"
	// harmonisation unit 19 ("GOF"): `estat' only forwards to a
	// command's own e(estat_cmd) program (confirmed directly from the
	// real Stata `estat.ado' dispatch mechanism, matching nwergm.ado's
	// own identical convention - not naming-convention-based, an
	// explicit e()-return is required) - without this, `estat gof'
	// fails with a generic "estat gof not valid" before ever reaching
	// nwsaom_estat.ado at all.
	ereturn local estat_cmd "nwsaom_estat"
	ereturn local title "Stochastic actor-oriented model (Method of Moments)"
	ereturn local waves "`__nwsaom_wavelist'"
	ereturn scalar N = `nodes'
	ereturn scalar nodes = `nodes'
	ereturn scalar nwaves = `__nwsaom_nwaves'
	ereturn matrix tratio = `tratio'
	ereturn scalar has_behavior = `__nwsaom_coev'
	ereturn scalar p_net = `__nwsaom_p'

	if `__nwsaom_coev' & `__nwsaom_multi' {
		// harmonisation unit 26 ("extend it to N waves"): FOUR separate
		// rate series (network/behavior, each per-period) - the
		// coev+multi analogue of unit 17's own e(rates)/e(rate_tratios)
		// matrices, doubled since there are two dependent variables now.
		tempname ratesnet ratetrnet ratesbeh ratetrbeh
		mata: st_matrix("`ratesnet'", __nwsaom_fit_coevmulti.ratesNet)
		mata: st_matrix("`ratetrnet'", __nwsaom_fit_coevmulti.rateNetTratios)
		mata: st_matrix("`ratesbeh'", __nwsaom_fit_coevmulti.ratesBeh)
		mata: st_matrix("`ratetrbeh'", __nwsaom_fit_coevmulti.rateBehTratios)
		local __nwsaom_periodnames ""
		forvalues __p = 1/`=`__nwsaom_nwaves'-1' {
			local __nwsaom_periodnames "`__nwsaom_periodnames' period`__p'"
		}
		matrix colnames `ratesnet' = `__nwsaom_periodnames'
		matrix colnames `ratetrnet' = `__nwsaom_periodnames'
		matrix colnames `ratesbeh' = `__nwsaom_periodnames'
		matrix colnames `ratetrbeh' = `__nwsaom_periodnames'
		matrix rownames `ratesnet' = rate
		matrix rownames `ratetrnet' = rate_tratio
		matrix rownames `ratesbeh' = rate_beh
		matrix rownames `ratetrbeh' = rate_beh_tratio
		ereturn local waves "`__nwsaom_wavelist'"
		ereturn local behavior "`behavior'"

		di as text "{hline}"
		di as text "SAOM co-evolution (Method of Moments), waves: " as result "`__nwsaom_wavelist'"
		di as text "Actors: " as result `nodes' _col(40) as text "Periods: " as result `=`__nwsaom_nwaves'-1'
		di as text "Behavior: " as result "`behavior'"
		di as text "{hline}"
		ereturn display
		di as text "Rate parameters (one per inter-wave period):"
		matlist `ratesnet', format(%9.4f)
		matlist `ratesbeh', format(%9.4f)

		ereturn matrix rates = `ratesnet'
		ereturn matrix rate_tratios = `ratetrnet'
		ereturn matrix rates_beh = `ratesbeh'
		ereturn matrix rate_beh_tratios = `ratetrbeh'
	}
	else if `__nwsaom_coev' {
		// harmonisation unit 26: TWO separate rate parameters, one per
		// dependent variable - matching how each variable's own rate is
		// independently targeted (docs/SAOM_ROADMAP.md's own unit-26
		// entry). Both surfaced clearly (not just the network's own
		// e(rate), per explicit user requirement), and the coefficient
		// table already shows both variables' effects distinctly via
		// the `beh_' prefix set when the behavior model was built above.
		mata: st_local("__nwsaom_rate", strofreal(__nwsaom_fit_coev.rateNet))
		mata: st_local("__nwsaom_ratetr", strofreal(__nwsaom_fit_coev.rateNetTratio))
		mata: st_local("__nwsaom_ratebeh", strofreal(__nwsaom_fit_coev.rateBeh))
		mata: st_local("__nwsaom_ratebehtr", strofreal(__nwsaom_fit_coev.rateBehTratio))
		ereturn scalar rate = `__nwsaom_rate'
		ereturn scalar rate_tratio = `__nwsaom_ratetr'
		ereturn scalar rate_beh = `__nwsaom_ratebeh'
		ereturn scalar rate_beh_tratio = `__nwsaom_ratebehtr'
		ereturn local wave1 "`wave1'"
		ereturn local wave2 "`wave2'"
		ereturn local behavior "`behavior'"

		di as text "{hline}"
		di as text "SAOM co-evolution (Method of Moments), waves: " as result "`wave1'" as text " -> " as result "`wave2'"
		di as text "Actors: " as result `nodes' _col(40) as text "Network rate: " as result %6.3f `__nwsaom_rate'
		di as text "Behavior: " as result "`behavior'" _col(40) as text "Behavior rate: " as result %6.3f `__nwsaom_ratebeh'
		di as text "{hline}"
		ereturn display
	}
	else if `__nwsaom_multi' {
		// harmonisation unit 17: multi-wave models report e(rates)/
		// e(rate_tratios) as 1 x nperiods MATRICES (one column per
		// inter-wave period) instead of the scalar e(rate)/e(rate_tratio)
		// the exactly-two-wave path reports - there is genuinely more
		// than one rate value here, matching real RSiena's own
		// per-period rate reporting (verified directly, see
		// SaomEstimateRMMulti()'s own header comment).
		tempname rates ratetr ratese
		mata: st_matrix("`rates'", __nwsaom_fit.rates)
		mata: st_matrix("`ratetr'", __nwsaom_fit.rate_tratios)
		mata: st_matrix("`ratese'", __nwsaom_fit.rate_ses)
		local __nwsaom_periodnames ""
		forvalues __p = 1/`=`__nwsaom_nwaves'-1' {
			local __nwsaom_periodnames "`__nwsaom_periodnames' period`__p'"
		}
		matrix colnames `rates' = `__nwsaom_periodnames'
		matrix colnames `ratetr' = `__nwsaom_periodnames'
		matrix colnames `ratese' = `__nwsaom_periodnames'
		matrix rownames `rates' = rate
		matrix rownames `ratetr' = rate_tratio
		matrix rownames `ratese' = rate_se

		di as text "{hline}"
		di as text "SAOM (Method of Moments), waves: " as result "`__nwsaom_wavelist'"
		di as text "Actors: " as result `nodes' _col(40) as text "Periods: " as result `=`__nwsaom_nwaves'-1'
		di as text "{hline}"
		ereturn display
		di as text "Rate parameters (one per inter-wave period):"
		matlist `rates', format(%9.4f)
		di as text "Rate standard errors (real RSiena's own reported convention, raw SD not SE-of-mean):"
		matlist `ratese', format(%9.4f)

		ereturn matrix rates = `rates'
		ereturn matrix rate_tratios = `ratetr'
		ereturn matrix rates_se = `ratese'
	}
	else {
		mata: st_local("__nwsaom_rate", strofreal(__nwsaom_fit.rate))
		mata: st_local("__nwsaom_ratetr", strofreal(__nwsaom_fit.rate_tratio))
		mata: st_local("__nwsaom_ratese", strofreal(__nwsaom_fit.rate_se))
		ereturn scalar rate = `__nwsaom_rate'
		ereturn scalar rate_tratio = `__nwsaom_ratetr'
		ereturn scalar rate_se = `__nwsaom_ratese'
		ereturn local wave1 "`wave1'"
		ereturn local wave2 "`wave2'"
		if `__nwsaom_hasratecov' {
			mata: st_local("__nwsaom_ratecoef", strofreal(__nwsaom_fit.ratecoef))
			mata: st_local("__nwsaom_ratecoef_se", strofreal(__nwsaom_fit.ratecoef_se))
			mata: st_local("__nwsaom_ratecoef_tr", strofreal(__nwsaom_fit.ratecoef_tratio))
			mata: st_local("__nwsaom_ratecoef_fx", strofreal(__nwsaom_fit.ratecoef_fixed))
			ereturn scalar ratecoef = `__nwsaom_ratecoef'
			ereturn scalar ratecoef_se = `__nwsaom_ratecoef_se'
			ereturn scalar ratecoef_tratio = `__nwsaom_ratecoef_tr'
			ereturn scalar ratecoef_fixed = `__nwsaom_ratecoef_fx'
		}

		di as text "{hline}"
		di as text "SAOM (Method of Moments), waves: " as result "`wave1'" as text " -> " as result "`wave2'"
		di as text "Actors: " as result `nodes' _col(40) as text "Estimated rate: " as result %6.3f `__nwsaom_rate' as text " (" as result %5.3f `__nwsaom_ratese' as text ")"
		di as text "{hline}"
		ereturn display
		if `__nwsaom_hasratecov' {
			di as text "Covariate-rate coefficient (" as result "`ratecov'" as text "): " as result %9.4f `__nwsaom_ratecoef' as text " (se " as result %6.4f `__nwsaom_ratecoef_se' as text ")" _continue
			if `__nwsaom_ratecoef_fx' di as text " - left at its starting value; the data did not identify it reliably (e(ratecoef_fixed)==1)"
			else di ""
		}
	}
end

/* ===================================================================
   nwsaom multiplex: Stage 1 of multiplex/multi-relation SAOM support
   (docs/SAOM_ROADMAP.md's own "v1-scope exclusions" entry) - two
   networks co-evolving, WITHIN-network effects only (outdegree +
   reciprocity on each), no cross-network effects yet. A separate,
   self-contained subcommand (matching nwergm's own `nwergm simulate'
   dispatch precedent above) rather than folding a second network into
   the main `nwsaom' syntax/dispatch above - keeps this Stage-1 addition
   at ZERO regression risk to every existing single-network/co-evolution
   model, which the main command's own already-large option surface
   (present()/missnet()/waves()/behavior()/ratecov()/etc.) would
   otherwise have to reason about jointly with a second network.

   Mata engine: SaomSimulateIntervalCoevNetNet()/SaomEstimateRMCoevNetNet()
   (unw_saom.do) - a parallel implementation of SaomEstimateRMCoev()'s
   own three-phase joint Robbins-Monro structure for two ErgmModel/
   ErgmGraph instances instead of one ErgmModel + one SaomBehaviorModel,
   verified against RSiena's own real EpochSimulation.cpp source
   (chooseVariable()/chooseActor(): a rate-proportional choice among ALL
   of a model's dependent variables is a fully generic mechanism -
   network+behavior and network+network co-evolution are the SAME
   underlying RSiena process, just different variable types).

   Stage 2 (docs/SAOM_ROADMAP.md): adds the first real cross-network
   effect, `crprod()` - RSiena's own real "netA: netB" term (verified
   from real RSiena 1.6.6 source - see stat_crprod()/change_crprod()'s
   own header comment in unw_saom.do for the full account). `crprod`
   adds it to net1's own effect list (net1's ties rewarded/penalized by
   the SAME dyad's current state in net2); `crprodb` is the mirror,
   adding it to net2's own list reading net1 - independent flags, either
   or both may be given. Still v1 Stage-1/2 scope, disclosed not
   silently narrowed: exactly two waves per network, outdegree+
   reciprocity(+crprod) only, no composition change/missing data. Fully
   native (C) across all three Robbins-Monro phases (phase 1's Jacobian,
   phase 2's own theta updates, phase 3's sandwich covariance) whenever
   eligible - stale note removed here since an earlier version of this
   comment predated that work and was never updated afterward.
   =================================================================== */
capture program drop nwsaom_multiplex
program define nwsaom_multiplex, eclass
	version 14
	syntax , NETAWAVE1(string) NETAWAVE2(string) NETBWAVE1(string) NETBWAVE2(string) ///
		[ THETA01(string) THETA02(string) K0(integer 30) K3(integer 200) FIRSTG(real 0.2) seed(integer -1) CRPROD CRPRODB ]

	if `seed' != -1 set seed `seed'

	nw_syntax `netawave1', max(1) other(w1a)
	nw_syntax `netawave2', max(1) other(w1b)
	nw_syntax `netbwave1', max(1) other(w2a)
	nw_syntax `netbwave2', max(1) other(w2b)

	foreach __w in w1a w1b w2a w2b {
		if "``__w'directed'" != "true" {
			di "{err}nwsaom multiplex requires directed networks, matching plain nwsaom's own v1 scope."
			error 198
		}
		if "``__w'is2mode'" == "true" {
			di "{err}nwsaom multiplex does not support two-mode (bipartite) networks."
			error 198
		}
	}
	if `w1anodes' != `w1bnodes' | `w1anodes' != `w2anodes' | `w1anodes' != `w2bnodes' {
		di "{err}every network/wave passed to nwsaom multiplex must share the same, fixed number of nodes."
		error 198
	}
	local nodes = `w1anodes'

	local wantcrprod = ("`crprod'" != "")
	local wantcrprodb = ("`crprodb'" != "")

	// Mata row-vector literal syntax needs COMMA-separated elements
	// (`(0, 0)', not `(0 0)') - confirmed directly, not assumed (the
	// space-separated form is a genuine parse error, "invalid
	// expression"), so theta01()/theta02() must be given comma-separated
	// too if a user overrides the default. Default length now tracks
	// whether crprod()/crprodb() add a third parameter to that network's
	// own effect list.
	if "`theta01'" == "" local theta01 = cond(`wantcrprod', "0, 0, 0", "0, 0")
	if "`theta02'" == "" local theta02 = cond(`wantcrprodb', "0, 0, 0", "0, 0")

	tempname b V
	// Single one-line call into a real, file-scope Mata function
	// (__nwsaom_mp_fit_and_post(), defined near __nwsaom_bridge_from_netobj()
	// above) rather than an inline multi-line `mata:'/`end' block nested
	// inside this program body - see that function's own header comment
	// for the real, reproducible parser bug the earlier inline-block
	// version hit (Stata silently closed THIS `program define' at the
	// inline block's own `end', dropping everything meant to run after
	// it) and why this codebase's own file-scope-Mata-function
	// convention exists.
	mata: __nwsaom_mp_fit_and_post(`w1anetobj', `w1bnetobj', `w2anetobj', `w2bnetobj', `nodes', (`theta01'), (`theta02'), `k0', `k3', `firstg', `wantcrprod', `wantcrprodb', "`b'", "`V'", "__nwsaom_mp_rate1", "__nwsaom_mp_rate2", "__NWSAOM_MP_COEFNAMES__")

	// Coefficient names/count now vary with crprod()/crprodb() (Mata's
	// own M1.coefnames/M2.coefnames, the actual source of truth for what
	// each ErgmModel really contains) rather than the old fixed 4-column
	// literal - posted back as a Stata global (cleared immediately after
	// reading) since `matrix colnames' needs a plain token list, not a
	// Mata return value directly.
	local __mp_coefnames "$__NWSAOM_MP_COEFNAMES__"
	macro drop __NWSAOM_MP_COEFNAMES__
	matrix colnames `b' = `__mp_coefnames'
	matrix colnames `V' = `__mp_coefnames'
	matrix rownames `V' = `__mp_coefnames'

	ereturn post `b' `V', obs(`nodes')
	ereturn scalar rate1 = __nwsaom_mp_rate1
	ereturn scalar rate2 = __nwsaom_mp_rate2
	ereturn local cmd "nwsaom_multiplex"

	di as text "{hline}"
	if `wantcrprod' | `wantcrprodb' di as text "Multiplex SAOM (Stage 2: crprod cross-network effect), Method of Moments"
	else di as text "Multiplex SAOM (Stage 1: within-network effects only), Method of Moments"
	di as text "{hline}"
	ereturn display
	di as text "note: net1's own opportunity rate = " %6.3f e(rate1) ", net2's own = " %6.3f e(rate2) "."
end
