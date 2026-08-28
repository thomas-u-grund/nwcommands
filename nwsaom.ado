*! version 0.1.0 28aug2026 nwcommands: stochastic actor-oriented model (SAOM) estimation, v1
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

capture program drop nwsaom
program nwsaom, eclass
	version 14
	syntax [, WAVE1(string) WAVE2(string) WAVES(string) OUTDEGREE RECIPROCITY NODEMATCH(string) ///
		NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		INDEGPOPULARITY OUTACTIVITY TRANSTRIP CYCLE3 OUTPOPULARITY INACTIVITY SIMCOV(string) ///
		GWESP(string) TRANSTIES BALANCE ///
		EGOX(string) ALTX(string) SAMEX(string) SIMX(string) ///
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
	if "`outdegree'" == "" {
		di "{err}option {bf:outdegree} is required - every nwsaom v1 model includes an outdegree (density) effect, matching nwergm's own edges-required convention."
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
			di "{err}nwsaom requires directed networks - SAOM's ministep formulation is inherently directed (an actor controls only its own outgoing ties). See docs/SAOM_ROADMAP.md for why undirected relations are out of v1 scope."
			error 198
		}
		if `__w' == 1 local nodes = `w1nodes'
		else if `w`__w'nodes' != `nodes' {
			di "{err}every wave must have the same number of nodes - nwsaom v1 assumes a fixed actor set (no composition change/joiners-leavers)."
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

	local __nwsaom_efflist "outdegree"

	tempname __td_od
	mata: `__td_od' = ErgmTermData()
	mata: __nwsaom_last_M.addterm("outdegree", 1, &stat_edges(), &change_edges(), `__td_od', ("outdegree"))

	if "`reciprocity'" != "" {
		tempname __td_recip
		mata: `__td_recip' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), `__td_recip', ("reciprocity"))
		local __nwsaom_efflist "`__nwsaom_efflist' reciprocity"
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
	if "`cycle3'" != "" {
		tempname __td_c3
		mata: `__td_c3' = ErgmTermData()
		mata: __nwsaom_last_M.addterm("cycle3", 1, &stat_saom_cycle3(), &change_saom_cycle3(), `__td_c3', ("cycle3"))
		local __nwsaom_efflist "`__nwsaom_efflist' cycle3"
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

	mata: st_local("__nwsaom_p", strofreal(__nwsaom_last_M.nparam()))

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

	capture mata: mata drop __nwsaom_fit
	if `__nwsaom_multi' {
		// harmonisation unit 17: theta is POOLED/shared across every
		// period, rate is period-specific - see SaomEstimateRMMulti()'s
		// own header comment (unw_saom.do) for the real-RSiena
		// verification this pooling convention is based on.
		mata: __nwsaom_fit = SaomEstimateRMMulti(__nwsaom_last_Gwaves, ///
			__nwsaom_last_M, __nwsaom_theta0, `k0', `k3', `firstg')
	}
	else {
		mata: __nwsaom_fit = SaomEstimateRM(__nwsaom_last_G1, __nwsaom_last_G2, ///
			__nwsaom_last_M, __nwsaom_theta0, `rate0', `k0', `k3', `firstg')
	}

	mata: st_local("__nwsaom_coefnames", invtokens(__nwsaom_last_M.coefnames))

	tempname b tratio V
	mata: st_matrix("`b'", __nwsaom_fit.theta)
	mata: st_matrix("`tratio'", __nwsaom_fit.tratio)
	mata: st_matrix("`V'", __nwsaom_fit.V)
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

	if `__nwsaom_multi' {
		// harmonisation unit 17: multi-wave models report e(rates)/
		// e(rate_tratios) as 1 x nperiods MATRICES (one column per
		// inter-wave period) instead of the scalar e(rate)/e(rate_tratio)
		// the exactly-two-wave path reports - there is genuinely more
		// than one rate value here, matching real RSiena's own
		// per-period rate reporting (verified directly, see
		// SaomEstimateRMMulti()'s own header comment).
		tempname rates ratetr
		mata: st_matrix("`rates'", __nwsaom_fit.rates)
		mata: st_matrix("`ratetr'", __nwsaom_fit.rate_tratios)
		local __nwsaom_periodnames ""
		forvalues __p = 1/`=`__nwsaom_nwaves'-1' {
			local __nwsaom_periodnames "`__nwsaom_periodnames' period`__p'"
		}
		matrix colnames `rates' = `__nwsaom_periodnames'
		matrix colnames `ratetr' = `__nwsaom_periodnames'
		matrix rownames `rates' = rate
		matrix rownames `ratetr' = rate_tratio

		di as text "{hline}"
		di as text "SAOM (Method of Moments), waves: " as result "`__nwsaom_wavelist'"
		di as text "Actors: " as result `nodes' _col(40) as text "Periods: " as result `=`__nwsaom_nwaves'-1'
		di as text "{hline}"
		ereturn display
		di as text "Rate parameters (one per inter-wave period):"
		matlist `rates', format(%9.4f)

		ereturn matrix rates = `rates'
		ereturn matrix rate_tratios = `ratetr'
		di as text "note: e(rates)/e(rate_tratios) hold ONE value per inter-wave period (real RSiena's own" ///
			" convention for 3+ wave models, verified directly against a real RSiena fit - see" ///
			" docs/SAOM_ROADMAP.md's own harmonisation unit 17 entry); theta is POOLED across every" ///
			" period, matching real RSiena's own multi-period Method-of-Moments formulation."
	}
	else {
		mata: st_local("__nwsaom_rate", strofreal(__nwsaom_fit.rate))
		mata: st_local("__nwsaom_ratetr", strofreal(__nwsaom_fit.rate_tratio))
		ereturn scalar rate = `__nwsaom_rate'
		ereturn scalar rate_tratio = `__nwsaom_ratetr'
		ereturn local wave1 "`wave1'"
		ereturn local wave2 "`wave2'"

		di as text "{hline}"
		di as text "SAOM (Method of Moments), waves: " as result "`wave1'" as text " -> " as result "`wave2'"
		di as text "Actors: " as result `nodes' _col(40) as text "Estimated rate: " as result %6.3f `__nwsaom_rate'
		di as text "{hline}"
		ereturn display
		di as text "note: the rate parameter (harmonisation unit 8) is RSiena's own verified closed-form" ///
			" starting-value formula, not yet refined via simulation the way the effects above are - so" ///
			" e(rate_tratio) reflects that known gap (disclosed ~14% vs. real RSiena on its own reference" ///
			" dataset), not an RM convergence failure; expect it far from zero."
	}
	di as text "note: e(tratio) holds phase-3 convergence t-ratios for the effects above (RSiena convention:" ///
		" |t| well under 1 indicates good convergence) - a SEPARATE diagnostic from the Std. Err./z/P>|z|" ///
		" columns just displayed above, which come from e(V) (harmonisation unit 18, real RSiena's own" ///
		" sandwich-formula covariance matrix - see docs/SAOM_ROADMAP.md)."
end
