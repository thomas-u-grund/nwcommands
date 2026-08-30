
capture program drop nwergm
program nwergm, eclass
	version 14
	if `"`1'"' == "simulate" {
		gettoken __ergm_sub 0 : 0
		nwergm_simulate `0'
		exit
	}
	syntax [anything(name=netname)] [, edges mutual ///
		NODEMATCH(string) NODEMATCHDIFF(string) NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		EDGECOV(string) ABSDIST(string) NODEFACTOR(string) NODEMIX(string) ///
		GWESP(string) GWDSP(string) GWNSP(string) GWDEGREE(string) GWODEGREE(string) GWIDEGREE(string) ///
		GWESPFREE(string) GWDEGREEFREE(string) GWDSPFREE(string) GWODEGREEFREE(string) GWIDEGREEFREE(string) GWNSPFREE(string) ///
		DEGREE(string) ODEGREE(string) IDEGREE(string) CONCURRENT TRIANGLE CTRIPLE ///
		NODEIFACTOR(string) NODEOFACTOR(string) ///
		KSTAR(string) ISTAR(string) OSTAR(string) ///
		DEGRANGE(string) DEGRANGETO(string) ODEGRANGE(string) ODEGRANGETO(string) ///
		IDEGRANGE(string) IDEGRANGETO(string) ESP(string) DSP(string) ///
		TRANSITIVETIES CYCLICALTIES HAMMING(string) SENDER RECEIVER ///
		BCOV1(string) BCOV2(string) BFACTOR1(string) BFACTOR2(string) ///
		BDEGREE1(string) BDEGREE2(string) BSTAR1(string) BSTAR2(string) ///
		BNODEMATCH1(string) BNODEMATCH2(string) BGWDEGREE1(string) BGWDEGREE2(string) ///
		TYPE(string) FREEDYADS(string) BLOCKDIAG(string) FIXDENSITY ///
		METHOD(string) MCMCBURNIN(integer 3000) MCMCINTERVAL(integer 50) ///
		MCMCSAMPLESIZE(integer 3000) MCMLEITERATIONS(integer 20) ///
		PROPOSAL(string) SEED(integer -1) VERBOSE SPCACHE NOMCMCSAMPLE NONATIVE ]
	set more off

	if "`edges'" == "" {
		di "{err}option {bf:edges} is required - every v1 nwergm model includes an edges term."
		error 198
	}
	// fixdensity (constraints, third piece - see docs/ERGM_ROADMAP.md's
	// "Constraints beyond v1's free binary dyad space" row): R ergm's
	// own `constraints=~edges'. Unlike freedyads()/blockdiag() (which
	// restrict WHICH single dyad the ordinary proposal may touch),
	// this holds the total tie COUNT invariant via a compound tie/
	// non-tie swap move (ergm_propose_swap()/ErgmMCMCSampleSwap(),
	// unw_ergm.do) - a genuinely different proposal shape, not a masked
	// variant of the existing one, so it cannot be combined with
	// freedyads()/blockdiag() in v1 (each is its own self-contained
	// dyad-space restriction). `edges' itself becomes uninformative
	// under this constraint (its statistic never changes across the
	// whole chain, so it carries zero information about theta) -
	// mimicking real R ergm's own observed behavior here (confirmed
	// directly: R fits `edges' anyway and reports its coefficient fixed
	// at exactly 0 with a "will be ignored" warning) is not attempted
	// via this project's own still-incomplete general isfixed-through-
	// MCMLE machinery (docs/ERGM_ROADMAP.md's own disclosed gap) -
	// instead, `edges' is simply never registered as an estimated term
	// for a fixdensity model (the user must still type `edges' per the
	// check just above, for a consistent model-specification syntax,
	// but at least one OTHER term is required, checked below).
	if "`fixdensity'" != "" {
		if "`freedyads'" != "" | "`blockdiag'" != "" {
			di "{err}fixdensity cannot currently be combined with freedyads()/blockdiag() - v1 supports one dyad-space constraint at a time."
			error 198
		}
		if "`method'" != "" & "`method'" != "mcmle" {
			di "{err}fixdensity requires {bf:method(mcmle)} - a fixed-density fit cannot be a plain MPLE (that never runs MCMC at all, so there is no proposal for the constraint to restrict)."
			error 198
		}
		local method "mcmle"
	}
	// freedyads() now has a masked TNT variant too (ergm_propose_tnt_masked(),
	// docs/ERGM_ROADMAP.md's "Constraints beyond v1's free binary dyad
	// space" row) - freedyads() alone no longer needs its own special
	// default, `proposal()' defaults to `tnt' exactly as it does without
	// freedyads().
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 6556
	if "`method'" != "" {
		_opts_oneof "mple mcmle" "method" "`method'" 6556
	}
	local __ergm_type_explicit = ("`type'" != "")
	local type = upper("`type'")
	if "`type'" == "" local type "OTP"
	_opts_oneof "OTP ITP OSP ISP RTP" "type" "`type'" 6556

	nw_syntax `netname', max(1)

	// --- network-type validation (Part IV/XXII/XXIII/XXIV): reject,
	// never silently reinterpret.
	//
	// Bipartite (two-mode) support (harmonisation unit 155 Stage 1 +
	// unit 156 Stage 2, per
	// /Users/tgrund/.claude/plans/dreamy-popping-deer.md): R's own ergm
	// package requires bipartite networks to be undirected
	// (docs/ERGM_STATNET_STUDY.md:401) - a real modeling constraint (a
	// directed two-mode dyad space has no standard ERGM treatment in
	// the reference implementation this package studies), not a v1
	// simplification - so directed+two-mode is rejected unconditionally
	// below, not merely "not yet implemented". v1's own bipartite term
	// scope is `edges' plus the dyad-independent bcov1()/bcov2()/
	// bfactor1()/bfactor2() family (Stage 2 - Stata option names for R
	// ergm's own b1cov()/b2cov()/b1factor()/b2factor() terms; the digit
	// had to move to the END of the option name because Stata's own
	// `syntax' command rejects any option name with a digit followed by
	// a letter - confirmed directly: a literal `B1COV(string)' syntax
	// declaration fails with "option b1cov() not allowed" at the FIRST
	// call, a genuine Stata-language constraint discovered empirically
	// mid-implementation, not a design choice. Every internal name that
	// is NOT a Stata option identifier - the Mata function names
	// (stat_b1cov()/change_b1cov()/etc.), the term registry's own name
	// string ("b1cov" passed to addterm()), and the fitted coefficient's
	// own display name ("b1cov_<var>") - is NOT subject to this
	// constraint and keeps R's own exact naming, so a fitted model's
	// coefficient table still reads `b1cov_age' etc., matching what an
	// R ergm user would recognize; only the four OPTION names a caller
	// types on the nwergm command line differ.), plus the dyad-
	// DEPENDENT bdegree1()/bdegree2()/bstar1()/bstar2() family (Stage 3,
	// unit 157 - same digit-at-the-end option-name rename, for the same
	// Stata `syntax' reason, as R's own b1degree()/b2degree()/
	// b1star()/b2star()). Every ONE-MODE-ONLY term (mutual/triangle/
	// gwesp/nodematch/nodecov/degree/kstar/etc.) is rejected explicitly
	// so a bipartite model never silently gets a one-mode term's change
	// statistic applied to a rectangular dyad space it was never
	// derived for.
	if "`is2mode'" == "true" & "`directed'" == "true" {
		di "{err}nwergm does not support directed two-mode (bipartite) networks; {bf:`netname'} is directed and two-mode."
		di "{err}Bipartite ERGMs are undirected only, matching the reference implementation this package studies (R's ergm package) - there is no standard directed two-mode dyad-space treatment to fall back to."
		error 198
	}
	if "`is2mode'" == "true" {
		local __ergm_b2mode_otherterm = ("`mutual'"!="") + ("`nodematch'"!="") + ("`nodematchdiff'"!="") + ("`nodecov'"!="") + ("`nodeicov'"!="") + ("`nodeocov'"!="") + ("`edgecov'"!="") + ("`absdist'"!="") + ("`nodefactor'"!="") + ("`nodemix'"!="") + ("`gwesp'"!="") + ("`gwdsp'"!="") + ("`gwnsp'"!="") + ("`gwdegree'"!="") + ("`gwodegree'"!="") + ("`gwidegree'"!="") + ("`gwespfree'"!="") + ("`gwdegreefree'"!="") + ("`gwdspfree'"!="") + ("`gwodegreefree'"!="") + ("`gwidegreefree'"!="") + ("`gwnspfree'"!="") + ("`degree'"!="") + ("`odegree'"!="") + ("`idegree'"!="") + ("`concurrent'"!="") + ("`triangle'"!="") + ("`ctriple'"!="") + ("`nodeifactor'"!="") + ("`nodeofactor'"!="") + ("`kstar'"!="") + ("`istar'"!="") + ("`ostar'"!="") + ("`degrange'"!="") + ("`degrangeto'"!="") + ("`odegrange'"!="") + ("`odegrangeto'"!="") + ("`idegrange'"!="") + ("`idegrangeto'"!="") + ("`esp'"!="") + ("`dsp'"!="") + ("`transitiveties'"!="") + ("`cyclicalties'"!="") + ("`hamming'"!="")
		if `__ergm_b2mode_otherterm' > 0 {
			di "{err}nwergm's bipartite (two-mode) support currently covers only {bf:edges}/{bf:bcov1()}/{bf:bcov2()}/{bf:bfactor1()}/{bf:bfactor2()}/{bf:bdegree1()}/{bf:bdegree2()}/{bf:bstar1()}/{bf:bstar2()}/{bf:bnodematch1()}/{bf:bnodematch2()}/{bf:bgwdegree1()}/{bf:bgwdegree2()}; {bf:`netname'} is two-mode and this model requests at least one other (one-mode-only) term."
			di "{err}nwergm never silently applies a one-mode term's change statistic to a two-mode dyad space it was never derived for."
			error 198
		}
	}
	else {
		// bcov1()/bcov2()/bfactor1()/bfactor2()/bdegree1()/bdegree2()/
		// bstar1()/bstar2()/bnodematch1()/bnodematch2()/bgwdegree1()/
		// bgwdegree2() (R ergm's own b1cov()/b2cov()/b1factor()/
		// b2factor()/b1degree()/b2degree()/b1star()/b2star()/
		// b1nodematch()/b2nodematch()/gwb1degree()/gwb2degree()) are
		// bipartite-only by their own real R ergm definition (confirmed
		// directly from R's own current Rd docs before implementing,
		// not guessed: b1cov's own description literally states "This
		// term may only be used with bipartite networks", and
		// b1degree()/b1star()/b1nodematch()/gwb1degree() likewise) -
		// rejected on a one-mode network with the same "reject, never
		// silently reinterpret" discipline `mutual' (directed-only)
		// already uses below.
		if "`bcov1'`bcov2'`bfactor1'`bfactor2'`bdegree1'`bdegree2'`bstar1'`bstar2'`bnodematch1'`bnodematch2'`bgwdegree1'`bgwdegree2'" != "" {
			di "{err}options {bf:bcov1()}/{bf:bcov2()}/{bf:bfactor1()}/{bf:bfactor2()}/{bf:bdegree1()}/{bf:bdegree2()}/{bf:bstar1()}/{bf:bstar2()}/{bf:bnodematch1()}/{bf:bnodematch2()}/{bf:bgwdegree1()}/{bf:bgwdegree2()} require a two-mode (bipartite) network; {bf:`netname'} is one-mode."
			di "{err}Use {bf:nodematch()}/{bf:nodecov()}/{bf:nodefactor()}/{bf:degree()}/{bf:kstar()}/{bf:gwdegree()} for a one-mode network's own analogous effect."
			error 198
		}
	}
	if "`istemporal'" == "true" {
		di "{err}nwergm estimates static ERGMs only; {bf:`netname'} carries temporal metadata."
		di "{err}nwergm never silently collapses a temporal network to a single slice - build an explicit static network first (e.g. via nwattime) and estimate on that."
		error 198
	}
	if "`valued'" == "true" {
		di "{err}nwergm estimates binary ERGMs only; {bf:`netname'} is valued/weighted."
		di "{err}nwergm never silently dichotomizes tie values or drops signs. Valued ERGMs are a separate, larger future initiative."
		error 198
	}
	if "`mutual'" != "" & "`directed'" != "true" {
		di "{err}option {bf:mutual} requires a directed network; {bf:`netname'} is undirected."
		error 198
	}
	// v1 scope: at most one curved term per model (harmonisation unit
	// 141 - refactored from unit 140's own pairwise "cannot combine
	// with X" checks, which stopped scaling once a 5th curved option
	// (gwodegreefree()/gwidegreefree(), this unit) would have needed
	// 10 pairwise checks total instead of one count). Computed ONCE,
	// before any of the five options' own validation blocks below, so
	// each block can just check `` `__ergm_ncurved' > 1 `` instead of
	// naming every other curved option individually.
	local __ergm_ncurved = ("`gwespfree'"!="") + ("`gwdegreefree'"!="") + ("`gwdspfree'"!="") + ("`gwodegreefree'"!="") + ("`gwidegreefree'"!="") + ("`gwnspfree'"!="")

	// gwespfree() (harmonisation unit 136 MPLE, unit 138 MCMLE): curved
	// (free-decay) gwesp - the first user-facing curved term. Dyad-
	// dependent like any other gwesp-family term, so method() auto-
	// selection (below, unchanged) already picks mcmle by default and
	// mple only when explicitly requested - no special-casing needed
	// here now that both methods are actually implemented. Undirected
	// v1 scope only, matching gwesp() itself.
	if "`gwespfree'" != "" {
		if "`gwesp'" != "" {
			di "{err}options {bf:gwesp()} and {bf:gwespfree()} cannot both be specified - a gwesp term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if "`esp'" != "" {
			di "{err}options {bf:esp()} and {bf:gwespfree()} cannot both be specified - gwespfree() already spans every achievable shared-partner count, so combining it with an explicit esp() subset would be redundant/collinear."
			error 198
		}
		if `__ergm_ncurved' > 1 {
			di "{err}option {bf:gwespfree()} cannot be combined with another curved option - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwespfree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwesp()} with {bf:type()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 3 {
			di "{err}option {bf:gwespfree()} needs at least 3 nodes (gwesp itself needs a real shared-partner count to be achievable)."
			error 198
		}
		// method(mple) only, for now (harmonisation unit 138): the
		// underlying curved-MCMLE plumbing (ErgmMCMLE()'s own
		// per-iteration eta->theta snap-back, delta-method SEs,
		// missing-value degeneracy guard - unw_ergm.do) is built and
		// does not regress the non-curved path, but direct testing on
		// two independent real networks (one where R's own reference
		// implementation independently failed identically -
		// "Unconstrained MCMC sampling did not mix at all" - and a
		// second, unrelated network) both drove the chain to a 0%
		// Metropolis-Hastings acceptance rate even after adding
		// backtracking robustness to the projection step itself. This
		// is a genuinely deeper problem than a local fix - the OUTER
		// eta-space Newton step's own step-length damping (calibrated
		// for the full, unconstrained eta space) does not yet account
		// for how differently a step behaves once snapped onto the
		// much lower-dimensional curved manifold - not yet solved, so
		// not yet exposed to users. See docs/ERGM_ROADMAP.md.
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwespfree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	// gwdegreefree() (harmonisation unit 139): curved (free-decay)
	// gwdegree, mirroring gwespfree()'s own exact pattern - reuses the
	// already-certified stat_degree()/change_degree() machinery
	// (degree(d)=0 always contributes exactly zero to the geometric
	// sum by construction, gw_kernel(0,alpha)=exp(alpha)*(1-1)=0
	// regardless of alpha, so d=1..(nodes-1) already covers every
	// value that can matter). method(mple) only, same reasoning as
	// gwespfree(). Undirected v1 scope only, matching gwdegree() itself.
	if "`gwdegreefree'" != "" {
		if "`gwdegree'" != "" {
			di "{err}options {bf:gwdegree()} and {bf:gwdegreefree()} cannot both be specified - a gwdegree term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if `__ergm_ncurved' > 1 {
			di "{err}option {bf:gwdegreefree()} cannot be combined with another curved option - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`degree'" != "" {
			di "{err}options {bf:degree()} and {bf:gwdegreefree()} cannot both be specified - gwdegreefree() already spans every achievable degree value, so combining it with an explicit degree() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwdegreefree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwodegree()}/{bf:gwidegree()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 2 {
			di "{err}option {bf:gwdegreefree()} needs at least 2 nodes."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwdegreefree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	// gwdspfree() (harmonisation unit 140): curved (free-decay)
	// gwdsp, mirroring gwespfree()'s/gwdegreefree()'s own exact
	// pattern - reuses the already-certified stat_dsp()/change_dsp()
	// machinery directly. Unlike gwesp's own d=1..(nodes-2) range,
	// gwdsp examines shared partners over EVERY dyad (tied or not),
	// but the achievable shared-partner COUNT for any one dyad is
	// still bounded by nodes-2 (every other node is a candidate
	// shared partner) - same maxd formula as gwespfree(), different
	// underlying dyad universe. method(mple) only, same reasoning as
	// the other two curved options. Undirected v1 scope only, matching
	// gwdsp() itself.
	if "`gwdspfree'" != "" {
		if "`gwdsp'" != "" {
			di "{err}options {bf:gwdsp()} and {bf:gwdspfree()} cannot both be specified - a gwdsp term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if `__ergm_ncurved' > 1 {
			di "{err}option {bf:gwdspfree()} cannot be combined with another curved option - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`dsp'" != "" {
			di "{err}options {bf:dsp()} and {bf:gwdspfree()} cannot both be specified - gwdspfree() already spans every achievable shared-partner count, so combining it with an explicit dsp() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwdspfree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwdsp()} with {bf:type()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 3 {
			di "{err}option {bf:gwdspfree()} needs at least 3 nodes (gwdsp itself needs a real shared-partner count to be achievable)."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwdspfree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	// gwnspfree() (harmonisation unit 152): curved (free-decay) gwnsp -
	// the last of the five fixed-decay GW terms this package implements
	// to gain a curved counterpart (gwespfree/gwdegreefree/gwdspfree/
	// gwodegreefree/gwidegreefree already done). Deferred out of the
	// original units 136-141 mechanical-reuse pass because gwnsp itself
	// (unlike gwesp/gwdsp/gwdegree/gwodegree/gwidegree) has no
	// standalone per-count statistic of its own - stat_gwnsp() is a
	// thin composition (stat_gwdsp() - stat_gwesp()) with nothing to
	// hand the curved eta-space machinery directly. This unit added the
	// missing piece, stat_nsp()/change_nsp() (unw_ergm.do), built the
	// same way: nsp(d) = dsp(d) - esp(d), a definitional tautology (a
	// dyad with d shared partners is either tied - esp's own domain -
	// or untied - nsp's own domain - never both, never neither),
	// certified against an independent direct-enumeration oracle before
	// use. Same maxd formula as gwdspfree() (nsp, like dsp, is defined
	// over EVERY dyad, tied or not, but the achievable per-dyad count is
	// still bounded by nodes-2). method(mple) only, undirected v1 scope,
	// same reasoning as every other curved option.
	if "`gwnspfree'" != "" {
		if "`gwnsp'" != "" {
			di "{err}options {bf:gwnsp()} and {bf:gwnspfree()} cannot both be specified - a gwnsp term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if `__ergm_ncurved' > 1 {
			di "{err}option {bf:gwnspfree()} cannot be combined with another curved option - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwnspfree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwnsp()} with {bf:type()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 3 {
			di "{err}option {bf:gwnspfree()} needs at least 3 nodes (gwnsp itself needs a real shared-partner count to be achievable)."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwnspfree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	// gwodegreefree()/gwidegreefree() (harmonisation unit 141): the
	// first DIRECTED curved terms - every curved option so far
	// (gwespfree/gwdegreefree/gwdspfree) has been undirected-only, but
	// stat_odegree()/change_odegree()/stat_idegree()/change_idegree()
	// already exist (unit 90's own degree-count family) and the whole
	// curved-MPLE pipeline (ErgmCurvedMPLEFit, theta_to_eta, the
	// Jacobian) never actually assumed undirected-ness anywhere - it
	// operates purely on eta-space design-matrix columns, agnostic to
	// what network-level property they came from. Registered under
	// "odegree"/"idegree" respectively; d ranges 1..(nodes-1) (an
	// out-/in-degree is bounded by the number of OTHER nodes, same
	// bound as total degree).
	if "`gwodegreefree'" != "" {
		if "`gwodegree'" != "" {
			di "{err}options {bf:gwodegree()} and {bf:gwodegreefree()} cannot both be specified - a gwodegree term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if `__ergm_ncurved' > 1 {
			di "{err}option {bf:gwodegreefree()} cannot be combined with another curved option - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`odegree'" != "" {
			di "{err}options {bf:odegree()} and {bf:gwodegreefree()} cannot both be specified - gwodegreefree() already spans every achievable out-degree value, so combining it with an explicit odegree() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" != "true" {
			di "{err}option {bf:gwodegreefree()} requires a directed network; {bf:`netname'} is undirected. Use {bf:gwdegreefree()} for an undirected network."
			error 198
		}
		if `nodes' < 2 {
			di "{err}option {bf:gwodegreefree()} needs at least 2 nodes."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwodegreefree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	if "`gwidegreefree'" != "" {
		if "`gwidegree'" != "" {
			di "{err}options {bf:gwidegree()} and {bf:gwidegreefree()} cannot both be specified - a gwidegree term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if `__ergm_ncurved' > 1 {
			di "{err}option {bf:gwidegreefree()} cannot be combined with another curved option - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`idegree'" != "" {
			di "{err}options {bf:idegree()} and {bf:gwidegreefree()} cannot both be specified - gwidegreefree() already spans every achievable in-degree value, so combining it with an explicit idegree() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" != "true" {
			di "{err}option {bf:gwidegreefree()} requires a directed network; {bf:`netname'} is undirected. Use {bf:gwdegreefree()} for an undirected network."
			error 198
		}
		if `nodes' < 2 {
			di "{err}option {bf:gwidegreefree()} needs at least 2 nodes."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwidegreefree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	if ("`nodeicov'" != "" | "`nodeocov'" != "") & "`directed'" != "true" {
		di "{err}options {bf:nodeicov()}/{bf:nodeocov()} require a directed network; {bf:`netname'} is undirected."
		error 198
	}
	// gwesp()/gwdsp()/gwnsp()/esp()/dsp() now support directed networks
	// too (harmonisation unit 91) via one of five directed shared-
	// partner definitions - OTP ("outgoing two-path", i->k->j, R ergm's
	// own default), ITP ("incoming two-path", i<-k<-j), OSP ("outgoing
	// shared partner", i->k<-j), ISP ("incoming shared partner",
	// i<-k->j), or RTP ("reciprocated two-path", i<->k<->j - a shared
	// partner only through a mutual tie on each leg) - selected by the
	// shared `type()' option and applied uniformly to every one of these
	// five terms present in the same model (a per-term `type=' the way R
	// ergm's own arglist allows is not offered - nwergm's own
	// option-string convention for these terms is already just a bare
	// decay/numlist, not a nested sub-syntax, and one shared-partner
	// definition per model covers the realistic use case without that
	// added parsing complexity). `nwergm.ado' sets `td.sptype' to the
	// resolved `type' automatically for these terms whenever
	// `directed'=="true", leaving the undirected/UTP path (`td.sptype'
	// left blank) completely untouched for undirected networks -
	// matching R ergm's own documented override ("if and only if the
	// network is undirected, the UTP routine is used ... irrespective of
	// the user's selection"). All five directed types R ergm itself
	// offers are now implemented - none remain outstanding.
	if `__ergm_type_explicit' & "`directed'" != "true" {
		di "{err}note: option {bf:type()} only affects directed networks; {bf:`netname'} is undirected, so the undirected shared-partner definition is used regardless."
	}
	if `__ergm_type_explicit' & "`gwesp'`gwdsp'`gwnsp'`esp'`dsp'" == "" {
		di "{err}note: option {bf:type()} has no effect - no {bf:gwesp()}/{bf:gwdsp()}/{bf:gwnsp()}/{bf:esp()}/{bf:dsp()} term was requested."
	}
	if ("`gwodegree'" != "" | "`gwidegree'" != "") & "`directed'" != "true" {
		di "{err}options {bf:gwodegree()}/{bf:gwidegree()} require a directed network; {bf:`netname'} is undirected. Use {bf:gwdegree()} for an undirected network."
		error 198
	}
	if "`degree'" != "" & "`directed'" == "true" {
		di "{err}option {bf:degree()} is undirected only; {bf:`netname'} is directed. Use {bf:odegree()}/{bf:idegree()} for a directed network."
		error 198
	}
	if ("`odegree'" != "" | "`idegree'" != "") & "`directed'" != "true" {
		di "{err}options {bf:odegree()}/{bf:idegree()} require a directed network; {bf:`netname'} is undirected. Use {bf:degree()} for an undirected network."
		error 198
	}
	if "`concurrent'" != "" & "`directed'" == "true" {
		di "{err}option {bf:concurrent} (v1 scope) is undirected only; {bf:`netname'} is directed."
		error 198
	}
	if "`triangle'" != "" & "`directed'" == "true" {
		di "{err}option {bf:triangle} is undirected only; {bf:`netname'} is directed. Use {bf:ctriple} for a directed network."
		error 198
	}
	if "`ctriple'" != "" & "`directed'" != "true" {
		di "{err}option {bf:ctriple} requires a directed network; {bf:`netname'} is undirected. Use {bf:triangle} for an undirected network."
		error 198
	}
	if ("`nodeifactor'" != "" | "`nodeofactor'" != "") & "`directed'" != "true" {
		di "{err}options {bf:nodeifactor()}/{bf:nodeofactor()} require a directed network; {bf:`netname'} is undirected. Use {bf:nodefactor()} for an undirected network."
		error 198
	}
	if "`kstar'" != "" & "`directed'" == "true" {
		di "{err}option {bf:kstar()} is undirected only; {bf:`netname'} is directed. Use {bf:ostar()}/{bf:istar()} for a directed network."
		error 198
	}
	if ("`ostar'" != "" | "`istar'" != "") & "`directed'" != "true" {
		di "{err}options {bf:ostar()}/{bf:istar()} require a directed network; {bf:`netname'} is undirected. Use {bf:kstar()} for an undirected network."
		error 198
	}
	if "`degrange'" != "" & "`directed'" == "true" {
		di "{err}option {bf:degrange()} is undirected only; {bf:`netname'} is directed. Use {bf:odegrange()}/{bf:idegrange()} for a directed network."
		error 198
	}
	if ("`odegrange'" != "" | "`idegrange'" != "") & "`directed'" != "true" {
		di "{err}options {bf:odegrange()}/{bf:idegrange()} require a directed network; {bf:`netname'} is undirected. Use {bf:degrange()} for an undirected network."
		error 198
	}
	// esp()/dsp() now support directed networks too (wave 5) via the
	// same automatic OTP default as gwesp()/gwdsp()/gwnsp() above.
	if ("`transitiveties'" != "" | "`cyclicalties'" != "") & "`directed'" != "true" {
		di "{err}options {bf:transitiveties}/{bf:cyclicalties} require a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if ("`sender'" != "" | "`receiver'" != "") & "`directed'" != "true" {
		di "{err}options {bf:sender}/{bf:receiver} require a directed network; {bf:`netname'} is undirected."
		error 198
	}

	if `seed' != -1 {
		set seed `seed'
	}

	// --- build the ErgmGraph from the current NWdef network (one-time
	// read via the already-established sparse accessors; ErgmGraph
	// itself never touches NWdef again after this point - it is, by
	// design, fully decoupled from NWdef; see unw_ergm.do's own header
	// comment). The bridge itself (ergm_bridge_from_netobj(), defined
	// once at file scope below) lives here, in the .ado integration
	// layer, not in either decoupled Mata subsystem.
	// every Mata-side tempname created below is appended to this list
	// (in expanded, literal-name form) so it can be dropped in one shot
	// at the end of the program - a one-line interactive `mata: X = ...'
	// call creates a permanent, top-level Mata variable that is NEVER
	// garbage-collected on its own (unlike a proper Mata function's own
	// locals), so without this bookkeeping every nwergm call leaks one
	// object per term instance into the ambient Mata workspace. Left
	// unfixed, this eventually collides with Mata objects Stata's own
	// machinery creates internally (e.g. `estimates table'/`esttab'),
	// surfacing as a baffling "Mata object __NNNNNN already exists".
	local __ergm_matatemps ""

	// __nwergm_last_G/__nwergm_last_M are DELIBERATE fixed-name Mata
	// singletons, not tempnames - `estat gof' (nwergm_estat.ado) needs to
	// find this call's own fitted graph/model again later, in a SEPARATE
	// program invocation with no access to this program's own locals.
	// Each new nwergm call replaces (never accumulates) the previous
	// call's singleton, guarded exactly like ergm_bridge_from_netobj()'s
	// own redefinition guard below - this is a single, well-managed
	// object, not the unmanaged per-call accumulation unit 73 fixed.
	capture mata: mata drop __nwergm_last_G
	mata: __nwergm_last_G = ErgmGraph()
	mata: __nwergm_last_G.init(`nodes', ("`directed'"=="true"))
	mata: ergm_bridge_from_netobj(`netobj', __nwergm_last_G, ("`directed'"=="true"))
	// harmonisation unit 155 (bipartite Stage 1): set_bipartite() is
	// called AFTER ergm_bridge_from_netobj() (order does not matter for
	// correctness - set_bipartite() only touches the new mode fields,
	// never G.elist/G.edgepos - but matches enable_sp_cache()'s own
	// established "opt-in flag set right after the graph is populated"
	// placement below). get_modes() returns a string rowvector of
	// "1"/"2" keyed by NWdef's own node index - the SAME index
	// ergm_bridge_from_netobj() just used via netobj->neighbors(i), so
	// no reordering is needed or performed (this package's own
	// deliberate no-reordering convention - see the approved plan's own
	// "Key architecture decision" section).
	if "`is2mode'" == "true" {
		mata: __nwergm_last_G.set_bipartite(strtoreal(`netobj'->get_modes())')
	}
	// freedyads(netname) (constraints, first piece - see
	// docs/ERGM_ROADMAP.md's "Constraints beyond v1's free binary dyad
	// space" row): R ergm's own `constraints=~fixallbut(free)` - `free'
	// is a SECOND network whose own ties mark which dyads of `netname'
	// are eligible to vary during MCMC; every dyad NOT tied in `free' is
	// held fixed at its OBSERVED value in `netname' for the rest of this
	// fit. Deliberately only touches __nwergm_last_G (the proposal-time
	// object) via set_dyadmask() below - never __nwergm_last_M or its
	// own full_statistic()/MPLE design-matrix machinery, which must keep
	// reading the network's real observed ties regardless of the mask
	// (a fixed dyad still contributes its true observed state to every
	// term's sufficient statistic; only the MCMC PROPOSAL is restricted
	// from ever touching it) - this is the whole point of "fixed", not
	// "deleted". Same nw_syntax()-based resolution as edgecov()/hamming()
	// above, reusing get_matrix_mod(0,...) as hamming() does (a binary
	// tie-presence matrix is exactly a boolean eligibility mask).
	if "`freedyads'" != "" {
		local __ergm_fd_n : word count `freedyads'
		if `__ergm_fd_n' > 1 {
			di "{err}freedyads() takes exactly one network (got `__ergm_fd_n': `freedyads'')."
			error 198
		}
		nw_syntax `freedyads', max(1) other(fd)
		if `fdnodes' != `nodes' {
			di "{err}freedyads() network {bf:`freedyads'} has a different number of nodes than {bf:`netname'}."
			error 198
		}
		mata: __nwergm_last_G.set_dyadmask(*(`fdnetobj'->get_matrix_mod(0,("`directed'"=="true"))))
	}
	// blockdiag(varname) (constraints, second piece - see
	// docs/ERGM_ROADMAP.md's "Constraints beyond v1's free binary dyad
	// space" row): R ergm's own `constraints=~blockdiag(attr)` - `varname'
	// is a categorical node attribute; only same-block dyads (equal
	// varname value) are eligible to vary during MCMC. Builds its own
	// eligibility mask (_ergm_blockdiag_mask()) and feeds it through the
	// EXACT SAME set_dyadmask()/masked-proposal/native machinery
	// freedyads() already uses - not a parallel constraint mechanism.
	// v1 supports one dyad-eligibility constraint at a time (matching
	// freedyads()'s own initial narrow scope) rather than an arbitrary
	// intersection of several.
	if "`blockdiag'" != "" {
		if "`freedyads'" != "" {
			di "{err}blockdiag() cannot currently be combined with freedyads() - v1 supports one dyad-eligibility constraint at a time."
			error 198
		}
		confirm variable `blockdiag'
		mata: __nwergm_last_G.set_dyadmask(_ergm_blockdiag_mask(st_data(1::`nodes', "`blockdiag'")))
	}
	// captured HERE, before any MCMC ever runs: __nwergm_last_G's own
	// .nties mutates throughout MCMLE's own simulation (it IS the live
	// MCMC state, not a frozen copy of the observed network - see its
	// own class header comment), so reading e(ties) from it AFTER
	// ErgmMCMLE() returns would report the last SIMULATED tie count, not
	// the true observed one. A genuine bug of exactly this shape existed
	// in this file from unit 72 through unit 75 (`e(ties)` was read from
	// `__nwergm_last_G.nties` after fitting, in the method(mcmle) branch
	// below), caught only once `estat gof` (Part XX) needed a genuinely
	// correct observed density and its own reported "Observed" column
	// didn't match the true network by hand-inspection.
	mata: st_local("__ergm_obsties", strofreal(__nwergm_last_G.nties))

	// --- spcache (Part XXV performance work, docs/CERTIFICATION.md unit
	// 82/132): the incremental shared-partner cache exists and is fully
	// certified, but is NOT auto-enabled by default - unit 82's own
	// direct A/B benchmarking found it a NET LOSS below roughly degree
	// 30-40 (the realistic case for most fitted sparse models, where
	// TNT's high acceptance rate makes the cache's own per-toggle
	// maintenance cost dominate its O(1) lookup savings). This is the
	// disclosed, deliberate opt-in the roadmap called for: the user, who
	// knows their own network's density, decides. Only the undirected
	// shared-partner definition (`shared_partners()') is cached - the
	// directed OTP/ITP/OSP/ISP/RTP paths use their own dedicated,
	// uncached primitives (see their own header comments), so the option
	// has no effect on a directed network. Applies to BOTH MPLE and
	// MCMLE fits (build_mple_data() toggles the same __nwergm_last_G
	// singleton the MCMC sampler uses, so MPLE's own design-matrix
	// construction benefits identically) - this spcache option itself is
	// still surfaced only on the MCMLE branch below (e(spcache)), a
	// genuinely narrower thing than e(native): spcache only ever helps
	// the Mata build_mple_data() path (native's own MPLE build,
	// harmonisation unit 145, does not use or need the Mata-level
	// shared-partner cache at all, since it never calls
	// common_neighbors()/shared_partners() from Mata in the first
	// place), so an MPLE fit that routes through native has nothing for
	// e(spcache) to report regardless.
	local __ergm_spcache_relevant = ("`gwesp'"!="" | "`gwdsp'"!="" | "`gwnsp'"!="" | "`esp'"!="" | "`dsp'"!="" | "`triangle'"!="" | "`ctriple'"!="")
	local __ergm_spcache_used = 0
	if "`spcache'" != "" {
		if "`directed'" == "true" {
			di "{err}note: option {bf:spcache} has no effect on a directed network; the incremental shared-partner cache only implements the undirected shared-partner definition."
		}
		else if !`__ergm_spcache_relevant' {
			di "{err}note: option {bf:spcache} has no effect without gwesp()/gwdsp()/gwnsp()/esp()/dsp()/triangle/ctriple; none of those terms was requested."
		}
		else {
			mata: __nwergm_last_G.enable_sp_cache()
			local __ergm_spcache_used = 1
		}
	}

	// --- build the model: one addterm() call per requested term.
	capture mata: mata drop __nwergm_last_M
	mata: __nwergm_last_M = ErgmModel()
	mata: __nwergm_last_M.init()

	// fixdensity: `edges' is never registered as an estimated term (see
	// this option's own validation-block comment above for why) - the
	// user still typed `edges' (required, checked above) for a
	// consistent model-specification syntax, it just contributes
	// nothing to the fitted parameter vector.
	if "`fixdensity'" == "" {
		tempname __td_edges
		mata: `__td_edges' = ErgmTermData()
		mata: __nwergm_last_M.addterm("edges", 1, &stat_edges(), &change_edges(), `__td_edges', ("edges"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_edges'"
	}

	if "`mutual'" != "" {
		tempname __td_mutual
		mata: `__td_mutual' = ErgmTermData()
		mata: __nwergm_last_M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), `__td_mutual', ("mutual"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_mutual'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodematch {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nm`__ergm_termidx'
		mata: `__td_nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), `__td_nm`__ergm_termidx'', ("nodematch_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nm`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodecov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nc`__ergm_termidx'
		mata: `__td_nc`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nc`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), `__td_nc`__ergm_termidx'', ("nodecov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nc`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeicov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ni`__ergm_termidx'
		mata: `__td_ni`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ni`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), `__td_ni`__ergm_termidx'', ("nodeicov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ni`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeocov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_no`__ergm_termidx'
		mata: `__td_no`__ergm_termidx'' = ErgmTermData()
		mata: `__td_no`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), `__td_no`__ergm_termidx'', ("nodeocov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_no`__ergm_termidx''"
	}

	// --- term-expansion wave 1 (harmonisation unit 88): absdist,
	// nodematch(diff=TRUE) (a separate nodematchdiff() option, per this
	// file's own header comment on why a suboption on nodematch() itself
	// was not used), nodefactor, nodemix - see unw_ergm.do's own header
	// comment on these four terms for the full statistical definitions.
	local __ergm_termidx = 0
	foreach __ergm_v of local absdist {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ad`__ergm_termidx'
		mata: `__td_ad`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ad`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("absdist", 1, &stat_absdist(), &change_absdist(), `__td_ad`__ergm_termidx'', ("absdist_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ad`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodematchdiff {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nmd`__ergm_termidx'
		mata: `__td_nmd`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nmd`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nmd`__ergm_termidx''.levels = uniqrows(`__td_nmd`__ergm_termidx''.attr)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nmd`__ergm_termidx''.levels)))
		tempname __ergm_levvec
		mata: st_matrix("`__ergm_levvec'", `__td_nmd`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodematch_`__ergm_v'_`=`__ergm_levvec'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodematch_diff", `__ergm_nlev', &stat_nodematch_diff(), &change_nodematch_diff(), `__td_nmd`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nmd`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodefactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nf`__ergm_termidx'
		mata: `__td_nf`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nf`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		// Omit the first (lowest-sorted) level by default, matching R
		// ergm's own nodefactor(attr, base=1) convention (harmonisation
		// unit 90, docs/CERTIFICATION.md) - fresh verification of R's
		// current InitErgmTerm.R confirmed nodefactor sums, per level,
		// "number of times a node with that attribute appears in an
		// edge"; for an undirected network this equals 2*edges once ALL
		// levels are summed, making the FULL-level parameterization
		// exactly collinear with the already-present `edges' term (one
		// level's own coefficient is unidentified) - precisely the
		// redundancy R's own `base' convention exists to avoid. An
		// earlier version of this term (unit 88) shipped without this
		// omission; `stat_nodefactor()'/`change_nodefactor()' themselves
		// needed NO change to fix this - both are already fully generic
		// over whatever `td.levels' holds, so this is a pure `nwergm.ado'
		// construction-time fix.
		mata: `__td_nf`__ergm_termidx''.levels = uniqrows(`__td_nf`__ergm_termidx''.attr)
		mata: `__td_nf`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nf`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nf`__ergm_termidx''.levels)))
		tempname __ergm_levvec2
		mata: st_matrix("`__ergm_levvec2'", `__td_nf`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodefactor_`__ergm_v'_`=`__ergm_levvec2'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodefactor", `__ergm_nlev', &stat_nodefactor(), &change_nodefactor(), `__td_nf`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nf`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodemix {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_mx`__ergm_termidx'
		mata: `__td_mx`__ergm_termidx'' = ErgmTermData()
		mata: `__td_mx`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __ergm_lv = uniqrows(`__td_mx`__ergm_termidx''.attr)
		mata: __ergm_np = rows(__ergm_lv)
		mata: __ergm_lp = J(0,2,0)
		mata: for (__ergm_a=1; __ergm_a<=__ergm_np; __ergm_a++) for (__ergm_b=__ergm_a; __ergm_b<=__ergm_np; __ergm_b++) __ergm_lp = __ergm_lp \ (__ergm_lv[__ergm_a], __ergm_lv[__ergm_b])
		mata: `__td_mx`__ergm_termidx''.levelpairs = __ergm_lp
		mata: st_local("__ergm_nlp", strofreal(rows(__ergm_lp)))
		tempname __ergm_lpmat
		mata: st_matrix("`__ergm_lpmat'", __ergm_lp)
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlp' {
			local __ergm_cnames "`__ergm_cnames' nodemix_`__ergm_v'_`=`__ergm_lpmat'[`__k',1]'_`=`__ergm_lpmat'[`__k',2]'"
		}
		mata: __nwergm_last_M.addterm("nodemix", `__ergm_nlp', &stat_nodemix(), &change_nodemix(), `__td_mx`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_mx`__ergm_termidx''"
		capture mata: mata drop __ergm_lv __ergm_np __ergm_lp __ergm_a __ergm_b
	}

	// --- bipartite (two-mode) Stage 2 terms (harmonisation unit 156):
	// bcov1()/bcov2() (R ergm's own b1cov()/b2cov(), renamed as Stata
	// options only - see the network-type validation block above for
	// why) mirror nodecov()'s own exact registration pattern (one
	// coefficient per requested variable, dyad-independent);
	// bfactor1()/bfactor2() (R's b1factor()/b2factor()) mirror
	// nodefactor()'s own exact pattern (one coefficient per non-base
	// level, `_ergm_drop_base_level()' - see nodefactor()'s own header
	// comment above for why the base level is dropped: the full-level
	// parameterization is exactly collinear with `edges'). The
	// network-type validation above already guarantees these four are
	// only ever registered when `is2mode'=="true". Every internal name
	// below (the `addterm()' registry name, the fitted coefficient's
	// own display name) intentionally keeps R's exact "b1cov"/"b2cov"/
	// "b1factor"/"b2factor" spelling - only the OPTION name differs.
	local __ergm_termidx = 0
	foreach __ergm_v of local bcov1 {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_b1c`__ergm_termidx'
		mata: `__td_b1c`__ergm_termidx'' = ErgmTermData()
		mata: `__td_b1c`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("b1cov", 1, &stat_b1cov(), &change_b1cov(), `__td_b1c`__ergm_termidx'', ("b1cov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_b1c`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local bcov2 {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_b2c`__ergm_termidx'
		mata: `__td_b2c`__ergm_termidx'' = ErgmTermData()
		mata: `__td_b2c`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("b2cov", 1, &stat_b2cov(), &change_b2cov(), `__td_b2c`__ergm_termidx'', ("b2cov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_b2c`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local bfactor1 {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_b1f`__ergm_termidx'
		mata: `__td_b1f`__ergm_termidx'' = ErgmTermData()
		mata: `__td_b1f`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		// BUGFIX (harmonisation unit 156, caught via a real end-to-end
		// smoke test, not by inspection): the level set must be built
		// from the MODE-1 nodes' own attribute values only, never the
		// full node vector `nodefactor()' correctly uses (every node
		// contributes to plain nodefactor's own credit, but only
		// mode-1 nodes ever contribute to b1factor's). The covariate is
		// typically left missing (.) for the OTHER mode's nodes (it has
		// no meaning there) - reading the full vector via uniqrows()
		// picked up "." itself as a spurious extra "level" (Mata sorts
		// missing after every real value), producing a bogus
		// `b1factor_<var>_.' coefficient column no real dyad could ever
		// activate. Confirmed directly: a bipartite smoke test with
		// `grp' defined only on the 6 mode-1 nodes (missing on the 4
		// mode-2 nodes) produced levels (1, 2, .) instead of (1, 2).
		mata: `__td_b1f`__ergm_termidx''.levels = uniqrows(`__td_b1f`__ergm_termidx''.attr[__nwergm_last_G.mode1nodes])
		mata: `__td_b1f`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_b1f`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_b1f`__ergm_termidx''.levels)))
		tempname __ergm_levvec_b1f
		mata: st_matrix("`__ergm_levvec_b1f'", `__td_b1f`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' b1factor_`__ergm_v'_`=`__ergm_levvec_b1f'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("b1factor", `__ergm_nlev', &stat_b1factor(), &change_b1factor(), `__td_b1f`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_b1f`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local bfactor2 {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_b2f`__ergm_termidx'
		mata: `__td_b2f`__ergm_termidx'' = ErgmTermData()
		mata: `__td_b2f`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		// BUGFIX: mode-2 mirror of b1factor()'s own fix above - see its
		// comment for the full account.
		mata: `__td_b2f`__ergm_termidx''.levels = uniqrows(`__td_b2f`__ergm_termidx''.attr[__nwergm_last_G.mode2nodes])
		mata: `__td_b2f`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_b2f`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_b2f`__ergm_termidx''.levels)))
		tempname __ergm_levvec_b2f
		mata: st_matrix("`__ergm_levvec_b2f'", `__td_b2f`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' b2factor_`__ergm_v'_`=`__ergm_levvec_b2f'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("b2factor", `__ergm_nlev', &stat_b2factor(), &change_b2factor(), `__td_b2f`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_b2f`__ergm_termidx''"
	}

	// --- bipartite (two-mode) Stage 3 terms (harmonisation unit 157):
	// bdegree1()/bdegree2()/bstar1()/bstar2() (R ergm's own b1degree()/
	// b2degree()/b1star()/b2star(), Stata-option-name-renamed for the
	// same reason as Stage 2's own bcov1()/etc. - see the network-type
	// validation block above) mirror degree()'s/kstar()'s own exact
	// registration pattern (`strtoreal(tokens(...))'' for the numlist).
	// Dyad-DEPENDENT (see unw_ergm.do's own header comment on this
	// family) - deliberately NOT added to the `__ergm_dind' MPLE-
	// eligibility check below (mirrors how plain degree()/kstar() are
	// excluded from it too), so a bipartite model using any of these
	// four correctly defaults to method(mcmle), exercising the Stage-1
	// bipartite MCMC proposal for real.
	if "`bdegree1'" != "" {
		tempname __td_bd1
		mata: `__td_bd1' = ErgmTermData()
		mata: `__td_bd1'.levels = strtoreal(tokens("`bdegree1'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_bd1'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `bdegree1' {
			local __ergm_cnames "`__ergm_cnames' b1degree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("b1degree", `__ergm_ndeg', &stat_b1degree(), &change_b1degree(), `__td_bd1', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_bd1'"
	}
	if "`bdegree2'" != "" {
		tempname __td_bd2
		mata: `__td_bd2' = ErgmTermData()
		mata: `__td_bd2'.levels = strtoreal(tokens("`bdegree2'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_bd2'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `bdegree2' {
			local __ergm_cnames "`__ergm_cnames' b2degree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("b2degree", `__ergm_ndeg', &stat_b2degree(), &change_b2degree(), `__td_bd2', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_bd2'"
	}
	if "`bstar1'" != "" {
		tempname __td_bs1
		mata: `__td_bs1' = ErgmTermData()
		mata: `__td_bs1'.levels = strtoreal(tokens("`bstar1'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_bs1'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `bstar1' {
			local __ergm_cnames "`__ergm_cnames' b1star_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("b1star", `__ergm_nk', &stat_b1star(), &change_b1star(), `__td_bs1', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_bs1'"
	}
	if "`bstar2'" != "" {
		tempname __td_bs2
		mata: `__td_bs2' = ErgmTermData()
		mata: `__td_bs2'.levels = strtoreal(tokens("`bstar2'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_bs2'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `bstar2' {
			local __ergm_cnames "`__ergm_cnames' b2star_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("b2star", `__ergm_nk', &stat_b2star(), &change_b2star(), `__td_bs2', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_bs2'"
	}

	// --- bipartite (two-mode) Stage 4 terms (harmonisation unit 162):
	// bnodematch1()/bnodematch2() (R ergm's own b1nodematch()/
	// b2nodematch(), default-parameter scope only - no diff()/alpha()/
	// beta()/byb2attr()/byb1attr(), a disclosed scope decision, see
	// unw_ergm.do's own header comment on these terms for the full
	// account and the real-R-output validation this derivation was
	// checked against) and bgwdegree1()/bgwdegree2() (R's own
	// gwb1degree()/gwb2degree(), FIXED-decay only - same v1 scope note
	// as plain gwdegree() above). Both families are genuinely dyad-
	// DEPENDENT (a same-attribute two-star count, or a GW-weighted
	// degree sum, both react to more than just the toggled dyad's own
	// two endpoints - see unw_ergm.do), so neither is added to the
	// MPLE-eligibility check below, matching plain kstar()/gwdegree()'s
	// own treatment exactly.
	local __ergm_termidx = 0
	foreach __ergm_v of local bnodematch1 {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_b1nm`__ergm_termidx'
		mata: `__td_b1nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_b1nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("b1nodematch", 1, &stat_b1nodematch(), &change_b1nodematch(), `__td_b1nm`__ergm_termidx'', ("b1nodematch_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_b1nm`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local bnodematch2 {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_b2nm`__ergm_termidx'
		mata: `__td_b2nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_b2nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("b2nodematch", 1, &stat_b2nodematch(), &change_b2nodematch(), `__td_b2nm`__ergm_termidx'', ("b2nodematch_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_b2nm`__ergm_termidx''"
	}
	if "`bgwdegree1'" != "" {
		tempname __td_bgwd1
		mata: `__td_bgwd1' = ErgmTermData()
		mata: `__td_bgwd1'.decay = `bgwdegree1'
		mata: __nwergm_last_M.addterm("bgwdegree1", 1, &stat_bgwdegree1(), &change_bgwdegree1(), `__td_bgwd1', ("bgwdegree1_`bgwdegree1'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_bgwd1'"
	}
	if "`bgwdegree2'" != "" {
		tempname __td_bgwd2
		mata: `__td_bgwd2' = ErgmTermData()
		mata: `__td_bgwd2'.decay = `bgwdegree2'
		mata: __nwergm_last_M.addterm("bgwdegree2", 1, &stat_bgwdegree2(), &change_bgwdegree2(), `__td_bgwd2', ("bgwdegree2_`bgwdegree2'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_bgwd2'"
	}

	// --- term-expansion wave 2 (harmonisation unit 90): degree(numlist)/
	// odegree(numlist)/idegree(numlist), concurrent, triangle, ctriple -
	// see unw_ergm.do's own header comment on these terms for the full
	// statistical definitions and R-ergm cross-checks. All dyad-
	// DEPENDENT (each depends on more than just its own two endpoints'
	// attributes), so none of these are added to the MPLE-eligibility
	// check below - matching mutual/every geometrically-weighted term.
	if "`degree'" != "" {
		tempname __td_deg
		mata: `__td_deg' = ErgmTermData()
		mata: `__td_deg'.levels = strtoreal(tokens("`degree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_deg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `degree' {
			local __ergm_cnames "`__ergm_cnames' degree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("degree", `__ergm_ndeg', &stat_degree(), &change_degree(), `__td_deg', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_deg'"
	}
	if "`odegree'" != "" {
		tempname __td_odeg
		mata: `__td_odeg' = ErgmTermData()
		mata: `__td_odeg'.levels = strtoreal(tokens("`odegree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_odeg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `odegree' {
			local __ergm_cnames "`__ergm_cnames' odegree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("odegree", `__ergm_ndeg', &stat_odegree(), &change_odegree(), `__td_odeg', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_odeg'"
	}
	if "`idegree'" != "" {
		tempname __td_ideg
		mata: `__td_ideg' = ErgmTermData()
		mata: `__td_ideg'.levels = strtoreal(tokens("`idegree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_ideg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `idegree' {
			local __ergm_cnames "`__ergm_cnames' idegree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("idegree", `__ergm_ndeg', &stat_idegree(), &change_idegree(), `__td_ideg', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ideg'"
	}
	if "`concurrent'" != "" {
		tempname __td_conc
		mata: `__td_conc' = ErgmTermData()
		mata: __nwergm_last_M.addterm("concurrent", 1, &stat_concurrent(), &change_concurrent(), `__td_conc', ("concurrent"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_conc'"
	}
	if "`triangle'" != "" {
		tempname __td_tri
		mata: `__td_tri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), `__td_tri', ("triangle"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_tri'"
	}
	if "`ctriple'" != "" {
		tempname __td_ctri
		mata: `__td_ctri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("ctriple", 1, &stat_ctriple(), &change_ctriple(), `__td_ctri', ("ctriple"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ctri'"
	}

	// --- term-expansion wave 3 (harmonisation unit 91): nodeifactor()/
	// nodeofactor() (directed analogues of nodefactor(), same base-level
	// omission), kstar()/istar()/ostar() (general k-star family, k as a
	// numlist), degrange()/odegrange()/idegrange() (semi-open-interval
	// degree counts, from()/to() as paired numlists).
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeofactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nof`__ergm_termidx'
		mata: `__td_nof`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nof`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nof`__ergm_termidx''.levels = uniqrows(`__td_nof`__ergm_termidx''.attr)
		mata: `__td_nof`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nof`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nof`__ergm_termidx''.levels)))
		tempname __ergm_levvec3
		mata: st_matrix("`__ergm_levvec3'", `__td_nof`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeofactor_`__ergm_v'_`=`__ergm_levvec3'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodeofactor", `__ergm_nlev', &stat_nodeofactor(), &change_nodeofactor(), `__td_nof`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nof`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeifactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nif`__ergm_termidx'
		mata: `__td_nif`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nif`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nif`__ergm_termidx''.levels = uniqrows(`__td_nif`__ergm_termidx''.attr)
		mata: `__td_nif`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nif`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nif`__ergm_termidx''.levels)))
		tempname __ergm_levvec4
		mata: st_matrix("`__ergm_levvec4'", `__td_nif`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeifactor_`__ergm_v'_`=`__ergm_levvec4'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodeifactor", `__ergm_nlev', &stat_nodeifactor(), &change_nodeifactor(), `__td_nif`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nif`__ergm_termidx''"
	}

	if "`kstar'" != "" {
		tempname __td_kstar
		mata: `__td_kstar' = ErgmTermData()
		mata: `__td_kstar'.levels = strtoreal(tokens("`kstar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_kstar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `kstar' {
			local __ergm_cnames "`__ergm_cnames' kstar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("kstar", `__ergm_nk', &stat_kstar(), &change_kstar(), `__td_kstar', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_kstar'"
	}
	if "`ostar'" != "" {
		tempname __td_ostar
		mata: `__td_ostar' = ErgmTermData()
		mata: `__td_ostar'.levels = strtoreal(tokens("`ostar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_ostar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `ostar' {
			local __ergm_cnames "`__ergm_cnames' ostar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("ostar", `__ergm_nk', &stat_ostar(), &change_ostar(), `__td_ostar', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ostar'"
	}
	if "`istar'" != "" {
		tempname __td_istar
		mata: `__td_istar' = ErgmTermData()
		mata: `__td_istar'.levels = strtoreal(tokens("`istar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_istar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `istar' {
			local __ergm_cnames "`__ergm_cnames' istar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("istar", `__ergm_nk', &stat_istar(), &change_istar(), `__td_istar', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_istar'"
	}

	if "`degrange'" != "" {
		local __ergm_ndr : word count `degrange'
		if "`degrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`degrangeto'"
			local __ergm_ndto : word count `degrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}degrange() and degrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_dr
		mata: `__td_dr' = ErgmTermData()
		mata: `__td_dr'.levelpairs = strtoreal(tokens("`degrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' degrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("degrange", `__ergm_ndr', &stat_degrange(), &change_degrange(), `__td_dr', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_dr'"
	}
	if "`odegrange'" != "" {
		local __ergm_ndr : word count `odegrange'
		if "`odegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`odegrangeto'"
			local __ergm_ndto : word count `odegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}odegrange() and odegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_odr
		mata: `__td_odr' = ErgmTermData()
		mata: `__td_odr'.levelpairs = strtoreal(tokens("`odegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' odegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("odegrange", `__ergm_ndr', &stat_odegrange(), &change_odegrange(), `__td_odr', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_odr'"
	}
	if "`idegrange'" != "" {
		local __ergm_ndr : word count `idegrange'
		if "`idegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`idegrangeto'"
			local __ergm_ndto : word count `idegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}idegrange() and idegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_idr
		mata: `__td_idr' = ErgmTermData()
		mata: `__td_idr'.levelpairs = strtoreal(tokens("`idegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' idegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("idegrange", `__ergm_ndr', &stat_idegrange(), &change_idegrange(), `__td_idr', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_idr'"
	}

	// --- term-expansion wave 4 (harmonisation unit 91 continuation):
	// esp(d)/dsp(d), fixed non-geometric shared-partner-count terms.
	// Wave 5 extended these (and gwesp/gwdsp/gwnsp below) to directed
	// networks via R ergm's own default directed shared-partner
	// definition (OTP) - `td.sptype' is set to "OTP" automatically
	// whenever the network is directed, left blank (UTP) otherwise.
	if "`esp'" != "" {
		local __ergm_nd : word count `esp'
		tempname __td_esp
		mata: `__td_esp' = ErgmTermData()
		mata: `__td_esp'.levels = strtoreal(tokens("`esp'"))'
		if "`directed'" == "true" {
			mata: `__td_esp'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `esp' {
			local __ergm_cnames "`__ergm_cnames' esp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("esp", `__ergm_nd', &stat_esp(), &change_esp(), `__td_esp', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_esp'"
	}
	if "`dsp'" != "" {
		local __ergm_nd : word count `dsp'
		tempname __td_dsp
		mata: `__td_dsp' = ErgmTermData()
		mata: `__td_dsp'.levels = strtoreal(tokens("`dsp'"))'
		if "`directed'" == "true" {
			mata: `__td_dsp'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `dsp' {
			local __ergm_cnames "`__ergm_cnames' dsp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("dsp", `__ergm_nd', &stat_dsp(), &change_dsp(), `__td_dsp', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_dsp'"
	}

	// --- term-expansion wave 6 (harmonisation unit 91 continuation):
	// transitiveties/cyclicalties, directed-only, built on wave 5's OTP
	// shared-partner machinery.
	if "`transitiveties'" != "" {
		tempname __td_tt
		mata: `__td_tt' = ErgmTermData()
		mata: __nwergm_last_M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), `__td_tt', ("transitiveties"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_tt'"
	}
	if "`cyclicalties'" != "" {
		tempname __td_ct
		mata: `__td_ct' = ErgmTermData()
		mata: __nwergm_last_M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), `__td_ct', ("cyclicalties"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ct'"
	}

	// --- term-expansion wave 7 (harmonisation unit 91 continuation):
	// sender()/receiver() (per-node out-/in-degree fixed effects, base=1
	// omitted, matching R ergm's own default) - a thin convenience
	// wrapper: the node's own identity (1..nodes) IS the "attribute",
	// reusing the already-certified stat_nodeofactor()/stat_nodeifactor()
	// with zero new Mata code.
	if "`sender'" != "" {
		tempname __td_send
		mata: `__td_send' = ErgmTermData()
		mata: `__td_send'.attr = (1::`nodes')
		mata: `__td_send'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' sender`__k'"
		}
		mata: __nwergm_last_M.addterm("sender", `nodes'-1, &stat_nodeofactor(), &change_nodeofactor(), `__td_send', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_send'"
	}
	if "`receiver'" != "" {
		tempname __td_recv
		mata: `__td_recv' = ErgmTermData()
		mata: `__td_recv'.attr = (1::`nodes')
		mata: `__td_recv'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' receiver`__k'"
		}
		mata: __nwergm_last_M.addterm("receiver", `nodes'-1, &stat_nodeifactor(), &change_nodeifactor(), `__td_recv', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_recv'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local edgecov {
		local ++__ergm_termidx
		tempname __td_ec`__ergm_termidx'
		mata: `__td_ec`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(ec`__ergm_termidx')
		if `ec`__ergm_termidx'nodes' != `nodes' {
			di "{err}edgecov() network {bf:`__ergm_v'} has a different number of nodes than {bf:`netname'}."
			error 198
		}
		mata: `__td_ec`__ergm_termidx''.edgecovmat = *(`ec`__ergm_termidx'netobj'->get_matrix_mod(1,("`directed'"=="true")))
		mata: __nwergm_last_M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), `__td_ec`__ergm_termidx'', ("edgecov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ec`__ergm_termidx''"
	}

	// --- hamming(netname): Hamming distance to a reference network,
	// same nw_syntax()-based network-name resolution as edgecov() above,
	// but a BINARY reference (get_matrix_mod(0,...), not (1,...) -
	// hamming distance cares only about tie/no-tie agreement, not
	// covariate weight).
	local __ergm_termidx = 0
	foreach __ergm_v of local hamming {
		local ++__ergm_termidx
		tempname __td_hm`__ergm_termidx'
		mata: `__td_hm`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(hm`__ergm_termidx')
		if `hm`__ergm_termidx'nodes' != `nodes' {
			di "{err}hamming() network {bf:`__ergm_v'} has a different number of nodes than {bf:`netname'}."
			error 198
		}
		mata: `__td_hm`__ergm_termidx''.edgecovmat = *(`hm`__ergm_termidx'netobj'->get_matrix_mod(0,("`directed'"=="true")))
		mata: __nwergm_last_M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), `__td_hm`__ergm_termidx'', ("hamming_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_hm`__ergm_termidx''"
	}

	if "`gwesp'" != "" {
		confirm number `gwesp'
		tempname __td_gwesp
		mata: `__td_gwesp' = ErgmTermData()
		mata: `__td_gwesp'.decay = `gwesp'
		if "`directed'" == "true" {
			mata: `__td_gwesp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), `__td_gwesp', ("gwesp_`gwesp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwesp'"
		// ErgmGraph::enable_sp_cache() (Part XXV performance work,
		// docs/CERTIFICATION.md unit 82) is DELIBERATELY NOT called here.
		// It was built, exhaustively certified for correctness, wired in,
		// and then measured directly against this suite's own realistic
		// GWESP benchmarks (100-node and 500-node sparse networks) - and
		// found to make BOTH slower (100-node: 23.1s -> 39.3s; a clean,
		// controlled A/B test isolating the cache as the only variable),
		// not faster. Root cause, fully characterized: TNT's own
		// acceptance rate on a FITTED sparse model is very high (83-93%
		// measured directly, not assumed) - so toggle()'s own cache-
		// maintenance cost (paid on nearly every proposal, not
		// occasionally) dominates the cheaper O(1) lookup's own savings
		// at the LOW degree (~4-6) these realistic benchmark networks
		// have. A degree sweep at a matched high acceptance rate found
		// the cache only becomes a net win around degree ~30-40+ (1.6x
		// faster there; 1.6-2x SLOWER at degree 4-20) - well above what
		// either benchmark network has. Kept unwired rather than removed
		// entirely: the machinery itself is correct and useful for
		// genuinely dense networks, just not a good default for the
		// sparse case this package's own realistic test networks
		// represent. See docs/CERTIFICATION.md unit 82 and
		// docs/ERGM_ROADMAP.md's own Performance section for the full,
		// disclosed account - the same "implement, measure, and report
		// honestly even when the obvious optimization does not pan out"
		// discipline this project used for the batch-means variance
		// estimator (unit 80).
	}
	if "`gwdsp'" != "" {
		confirm number `gwdsp'
		tempname __td_gwdsp
		mata: `__td_gwdsp' = ErgmTermData()
		mata: `__td_gwdsp'.decay = `gwdsp'
		if "`directed'" == "true" {
			mata: `__td_gwdsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), `__td_gwdsp', ("gwdsp_`gwdsp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdsp'"
	}
	if "`gwnsp'" != "" {
		confirm number `gwnsp'
		tempname __td_gwnsp
		mata: `__td_gwnsp' = ErgmTermData()
		mata: `__td_gwnsp'.decay = `gwnsp'
		if "`directed'" == "true" {
			mata: `__td_gwnsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), `__td_gwnsp', ("gwnsp_`gwnsp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwnsp'"
	}
	if "`gwdegree'" != "" {
		confirm number `gwdegree'
		tempname __td_gwdeg
		mata: `__td_gwdeg' = ErgmTermData()
		mata: `__td_gwdeg'.decay = `gwdegree'
		mata: __nwergm_last_M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), `__td_gwdeg', ("gwdegree_`gwdegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdeg'"
	}
	if "`gwodegree'" != "" {
		confirm number `gwodegree'
		tempname __td_gwod
		mata: `__td_gwod' = ErgmTermData()
		mata: `__td_gwod'.decay = `gwodegree'
		mata: __nwergm_last_M.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), `__td_gwod', ("gwodegree_`gwodegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwod'"
	}
	if "`gwidegree'" != "" {
		confirm number `gwidegree'
		tempname __td_gwid
		mata: `__td_gwid' = ErgmTermData()
		mata: `__td_gwid'.decay = `gwidegree'
		mata: __nwergm_last_M.addterm("gwidegree", 1, &stat_gwidegree(), &change_gwidegree(), `__td_gwid', ("gwidegree_`gwidegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwid'"
	}
	// gwespfree() (harmonisation unit 136): registered as a curved
	// `esp' term spanning EVERY achievable shared-partner count
	// 1..(nodes-2) - reusing the already-certified stat_esp()/
	// change_esp() machinery directly, not new statistic/change code
	// (curved-ness is an estimation-side property, not a per-term one -
	// see unw_ergm.do's own ErgmModel::curved comment). Deliberately
	// registered LAST (after every other term) so its own 2 theta
	// columns are always the final 2 in theta-space regardless of what
	// else is in the model - the MPLE code below relies on this to
	// build a starting theta without needing a general "find this
	// term's own theta position" accessor.
	if "`gwespfree'" != "" {
		confirm number `gwespfree'
		// Harmonisation unit 145: `nodes-2' is the theoretical worst
		// case (every dyad, on a maximally clustered network, shares
		// partners with every other node) - real networks fall far
		// short of it, and the curved-MPLE Newton-Raphson loop's own
		// cost scales with the SQUARE of this per-count basis width
		// (docs/CERTIFICATION.md unit 145's own profiling: a 418-node
		// real network registered 416 columns for a true maximum
		// edgewise-shared-partner value of 10). Registered at the TRUE
		// maximum reachable edgewise-shared-partner value across every
		// dyad's own change statistic (ergm_graph_max_shared_partners(),
		// unw_ergm.do, PLUS ONE - see that function's own header comment
		// for why the +1 is required: a single dyad's toggle can raise
		// a DIFFERENT, already-adjacent dyad's own shared-partner count
		// by one, not just the toggled dyad's own value, so the network's
		// current true maximum alone is not itself always reachable-safe).
		mata: st_local("__ergm_maxdeg", strofreal(ergm_graph_max_shared_partners(__nwergm_last_G) + 1))
		local __ergm_curved_maxd = max(1, min(`nodes' - 2, `__ergm_maxdeg'))
		tempname __td_gwespfree
		mata: `__td_gwespfree' = ErgmTermData()
		mata: `__td_gwespfree'.levels = (1..`__ergm_curved_maxd')'
		// addterm()'s own cnames must have length npar (here
		// __ergm_curved_maxd, the ETA-space dimension - one name per
		// achievable shared-partner count) - NOT the 2-dimensional
		// THETA-space this term is ultimately reported in. These names
		// are internal/intermediate only (never shown to the user - the
		// MPLE code below replaces the whole coefficient vector with
		// the 2 theta-space names "gwesp_weight"/"gwesp_decay" before
		// ereturn post), given a distinct "gwespfree_" prefix so they
		// cannot collide with an ordinary esp() term's own "espN" names
		// in any diagnostic that displays them before that replacement.
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwespfree_`__k'"
		}
		mata: __nwergm_last_M.addterm("esp", `__ergm_curved_maxd', &stat_esp(), &change_esp(), `__td_gwespfree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwespfree'"
	}
	// gwdegreefree() (harmonisation unit 139): mirrors gwespfree()'s
	// own exact pattern, registered under "degree" (reusing
	// stat_degree()/change_degree() directly) spanning every
	// achievable degree value 1..(nodes-1) - d=0 is safe to omit
	// entirely, since gw_kernel(0,alpha)=exp(alpha)*(1-1)=0 for any
	// alpha, so it can never contribute to the geometric sum. Also
	// registered LAST (after gwespfree(), which the mutual-exclusivity
	// check above guarantees cannot coexist with this one anyway), for
	// the same "always the final 2 theta columns" reason gwespfree()
	// documents at its own registration site.
	if "`gwdegreefree'" != "" {
		confirm number `gwdegreefree'
		// Harmonisation unit 145: same rationale as gwespfree()'s own
		// registration site above - a single dyad toggle changes
		// exactly one node's own degree by +-1, so no dyad's change
		// statistic can ever touch a degree value above the network's
		// own current maximum degree PLUS ONE (the toggle-on case) -
		// tighter than the theoretical `nodes-1' worst case on any real
		// network that is not itself nearly complete.
		mata: st_local("__ergm_maxdeg", strofreal(ergm_graph_maxdegree(__nwergm_last_G, "total")))
		local __ergm_curved_maxd = max(1, min(`nodes' - 1, `__ergm_maxdeg' + 1))
		tempname __td_gwdegreefree
		mata: `__td_gwdegreefree' = ErgmTermData()
		mata: `__td_gwdegreefree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwdegreefree_`__k'"
		}
		mata: __nwergm_last_M.addterm("degree", `__ergm_curved_maxd', &stat_degree(), &change_degree(), `__td_gwdegreefree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdegreefree'"
	}
	// gwdspfree() (harmonisation unit 140): mirrors the other two
	// curved options' own exact pattern, registered under "dsp"
	// (reusing stat_dsp()/change_dsp() directly).
	if "`gwdspfree'" != "" {
		confirm number `gwdspfree'
		// Harmonisation unit 145: same TRUE shared-partner-count bound
		// (plus one - see ergm_graph_max_shared_partners()'s own header
		// comment) as gwespfree()'s own registration site above (DSP is
		// the identical common-neighbor concept, evaluated over every
		// dyad rather than only tied ones).
		mata: st_local("__ergm_maxdeg", strofreal(ergm_graph_max_shared_partners(__nwergm_last_G) + 1))
		local __ergm_curved_maxd = max(1, min(`nodes' - 2, `__ergm_maxdeg'))
		tempname __td_gwdspfree
		mata: `__td_gwdspfree' = ErgmTermData()
		mata: `__td_gwdspfree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwdspfree_`__k'"
		}
		mata: __nwergm_last_M.addterm("dsp", `__ergm_curved_maxd', &stat_dsp(), &change_dsp(), `__td_gwdspfree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdspfree'"
	}
	// gwnspfree() (harmonisation unit 152): mirrors gwdspfree()'s own
	// exact pattern, registered under "nsp" (reusing the new
	// stat_nsp()/change_nsp() - nsp(d) = dsp(d) - esp(d), unw_ergm.do).
	if "`gwnspfree'" != "" {
		confirm number `gwnspfree'
		// same TRUE shared-partner-count bound (plus one) as
		// gwdspfree()'s own registration site - nsp, like dsp, is
		// defined over every dyad (tied or not), so the same bound
		// applies.
		mata: st_local("__ergm_maxdeg", strofreal(ergm_graph_max_shared_partners(__nwergm_last_G) + 1))
		local __ergm_curved_maxd = max(1, min(`nodes' - 2, `__ergm_maxdeg'))
		tempname __td_gwnspfree
		mata: `__td_gwnspfree' = ErgmTermData()
		mata: `__td_gwnspfree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwnspfree_`__k'"
		}
		mata: __nwergm_last_M.addterm("nsp", `__ergm_curved_maxd', &stat_nsp(), &change_nsp(), `__td_gwnspfree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwnspfree'"
	}
	// gwodegreefree()/gwidegreefree() (harmonisation unit 141): mirror
	// the other curved options' own exact pattern, registered under
	// "odegree"/"idegree" (reusing stat_odegree()/change_odegree() and
	// stat_idegree()/change_idegree() directly).
	if "`gwodegreefree'" != "" {
		confirm number `gwodegreefree'
		// Harmonisation unit 145: same rationale as gwdegreefree()'s
		// own registration site above, bounded by out-degree (the
		// direction this term's own change statistic actually touches)
		// rather than total degree.
		mata: st_local("__ergm_maxdeg", strofreal(ergm_graph_maxdegree(__nwergm_last_G, "out")))
		local __ergm_curved_maxd = max(1, min(`nodes' - 1, `__ergm_maxdeg' + 1))
		tempname __td_gwodegreefree
		mata: `__td_gwodegreefree' = ErgmTermData()
		mata: `__td_gwodegreefree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwodegreefree_`__k'"
		}
		mata: __nwergm_last_M.addterm("odegree", `__ergm_curved_maxd', &stat_odegree(), &change_odegree(), `__td_gwodegreefree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwodegreefree'"
	}
	if "`gwidegreefree'" != "" {
		confirm number `gwidegreefree'
		// Harmonisation unit 145: same rationale, bounded by in-degree.
		mata: st_local("__ergm_maxdeg", strofreal(ergm_graph_maxdegree(__nwergm_last_G, "in")))
		local __ergm_curved_maxd = max(1, min(`nodes' - 1, `__ergm_maxdeg' + 1))
		tempname __td_gwidegreefree
		mata: `__td_gwidegreefree' = ErgmTermData()
		mata: `__td_gwidegreefree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwidegreefree_`__k'"
		}
		mata: __nwergm_last_M.addterm("idegree", `__ergm_curved_maxd', &stat_idegree(), &change_idegree(), `__td_gwidegreefree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwidegreefree'"
	}

	// fixdensity dropped `edges' as an estimated term above - a model
	// needs at least one other term to actually estimate anything.
	if "`fixdensity'" != "" {
		mata: st_local("__ergm_nterms_check", strofreal(__nwergm_last_M.nterms))
		if `__ergm_nterms_check' == 0 {
			di "{err}fixdensity requires at least one term besides {bf:edges} (which is dropped, not estimated, under this constraint - see {bf:Remarks})."
			error 198
		}
	}

	// Unified curved-model flag/starting-value (harmonisation unit
	// 139): v1 scope allows at most one curved term per model (the
	// mutual-exclusivity checks above enforce this), so exactly one of
	// `gwespfree'/`gwdegreefree' can be non-empty at this point -
	// `__ergm_curved' and `__ergm_curved_start' let every downstream
	// curved-path branch (MPLE fit, e(curved), MCMLE gating) check ONE
	// flag instead of repeating "gwespfree() OR gwdegreefree()"
	// everywhere.
	local __ergm_curved = `__ergm_ncurved'
	if "`gwespfree'" != "" local __ergm_curved_start "`gwespfree'"
	else if "`gwdegreefree'" != "" local __ergm_curved_start "`gwdegreefree'"
	else if "`gwdspfree'" != "" local __ergm_curved_start "`gwdspfree'"
	else if "`gwnspfree'" != "" local __ergm_curved_start "`gwnspfree'"
	else if "`gwodegreefree'" != "" local __ergm_curved_start "`gwodegreefree'"
	else local __ergm_curved_start "`gwidegreefree'"

	// dyad-independent iff only edges/nodematch/nodecov/nodeicov/nodeocov/
	// edgecov/absdist/nodematchdiff/nodefactor/nodemix are present (mutual
	// and every geometrically-weighted term, including gwdsp/gwnsp, are
	// dyad-dependent - gwdsp/gwnsp no less than gwesp, since shared-
	// partner counts are just as nonlocal for untied dyads as for tied
	// ones; degree()/odegree()/idegree()/concurrent/triangle/ctriple are
	// ALSO dyad-dependent - unit 90 - since each depends on more than
	// just its own two endpoints' attributes, via other nodes' degrees
	// or shared third parties).
	// nodeofactor()/nodeifactor() are dyad-independent (like nodefactor -
	// their change stat depends only on the toggled dyad's own endpoint
	// attribute, not on other dyads' state), so they are deliberately
	// excluded from this check. kstar/ostar/istar/degrange/odegrange/
	// idegrange are all degree-based and so are dyad-dependent (wave 3).
	local __ergm_dind = (`"`mutual'"'=="" & `"`gwesp'"'=="" & `"`gwdsp'"'=="" & `"`gwnsp'"'=="" & `"`gwdegree'"'=="" & `"`gwodegree'"'=="" & `"`gwidegree'"'=="" & `"`degree'"'=="" & `"`odegree'"'=="" & `"`idegree'"'=="" & `"`concurrent'"'=="" & `"`triangle'"'=="" & `"`ctriple'"'=="" & `"`kstar'"'=="" & `"`ostar'"'=="" & `"`istar'"'=="" & `"`degrange'"'=="" & `"`odegrange'"'=="" & `"`idegrange'"'=="" & `"`esp'"'=="" & `"`dsp'"'=="" & "`transitiveties'"=="" & "`cyclicalties'"=="" & "`gwespfree'"=="" & "`gwdegreefree'"=="" & "`gwdspfree'"=="" & "`gwodegreefree'"=="" & "`gwidegreefree'"=="" & "`bdegree1'"=="" & "`bdegree2'"=="" & "`bstar1'"=="" & "`bstar2'"=="" & "`bnodematch1'"=="" & "`bnodematch2'"=="" & "`bgwdegree1'"=="" & "`bgwdegree2'"=="")
	if "`method'" == "" {
		local method = cond(`__ergm_dind', "mple", "mcmle")
	}
	if "`method'" == "mple" & !`__ergm_dind' {
		di "{txt}Note: {bf:method(mple)} requested for a dyad-dependent model - reporting pseudolikelihood, NOT full ERGM maximum likelihood."
	}

	// Built directly as a Mata matrix and handed straight to st_store()
	// below - NEVER routed through an intermediate Stata MATRIX
	// (st_matrix()), which is fine at the tiny scale of this suite's own
	// certification networks but catastrophically slow (effectively
	// hangs - confirmed directly: a trivial 999000x4 st_matrix() call
	// alone did not complete in over 2 minutes, where the equivalent
	// st_store() directly from Mata took 0.008 seconds) once ndyads
	// scales into the hundreds of thousands - i.e. any directed model
	// with a few hundred nodes or more. Stata matrices are architected
	// for small structures (coefficient vectors, VCV matrices), not
	// bulk per-observation data - the dataset/variable system st_store()
	// targets is what Stata itself uses for that, and performs
	// accordingly. Found and fixed while building the R-vs-Stata
	// benchmark suite's own large-network control case
	// (docs/CERTIFICATION.md harmonisation unit 81).
	tempname __nw_D
	// Harmonisation unit 145: route the design-matrix build through the
	// native (C) backend when eligible, exactly the same "is this whole
	// model's own term set inside the native plugin's coverage"
	// eligibility check the MCMLE path below already uses
	// (ErgmNativeSetup() - side-effects populate __nwergm_last_M's own
	// native_termcodes/attridx/p1/p2/attrmat, then ErgmNativeBuildMPLEData()
	// reads them straight off, exactly mirroring ErgmNativeSampleCore()'s
	// own contract). The `2' argument is a proposal code MPLE never
	// uses (no MCMC runs on this path at all) - passed only because
	// ErgmNativeSetup()'s own signature requires one. Falls back to the
	// original Mata build_mple_data() call unchanged whenever native is
	// unavailable or this model's own terms fall outside its coverage
	// (e.g. edgecov()/hamming(), or more parameters than the plugin's own
	// hard-coded MAXTERMS/MAXATTR bounds) - no model is ever left broken,
	// only unaccelerated, matching every other native-eligibility check
	// in this file.
	// BUGFIX pattern already established at this file's own MCMLE call
	// site below: ErgmNativeSetup()'s own return value, called bare,
	// would auto-display as a stray unexplained integer - read
	// eligibility off __nwergm_last_M.native_enabled (the side effect
	// it sets) via st_local() instead, never the bare Mata return.
	// nonative (harmonisation unit 160): an explicit escape hatch to force
	// the Mata backend even on an otherwise native-eligible model - added
	// because unit 160 made edgecov()/hamming() (the last remaining
	// non-native term family) native-eligible too, which left NO way for
	// a user (or this package's own certification suite, e.g. the
	// spcache-purity test in cscripts/test_nwergm_ado.do) to deliberately
	// exercise the Mata code path on a real fit anymore. `ErgmNativeSetup()'
	// is simply never called when set, so `__nwergm_last_M.native_enabled'
	// stays at its own default 0 - identical in effect to every other
	// "native unavailable" case already handled below.
	if "`nonative'" == "" {
		mata: __ergm_mple_native_setup_rc = ErgmNativeSetup(__nwergm_last_M, 2, __nwergm_last_G)
		mata: mata drop __ergm_mple_native_setup_rc
	}
	mata: st_local("__ergm_mple_native_used", strofreal(__nwergm_last_M.native_enabled))
	if `__ergm_mple_native_used' {
		mata: `__nw_D' = ErgmNativeBuildMPLEData(__nwergm_last_M, __nwergm_last_G)
	}
	else {
		mata: `__nw_D' = __nwergm_last_M.build_mple_data(__nwergm_last_G)
	}
	local __ergm_matatemps "`__ergm_matatemps' `__nw_D'"
	mata: st_local("__ergm_nrows", strofreal(rows(`__nw_D')))
	mata: st_local("__ergm_p", strofreal(cols(`__nw_D')-1))

	tempname __ergm_coefnames
	mata: st_local("__ergm_coefnames", invtokens(__nwergm_last_M.coefnames))

	tempname __b_mple __V_mple
	// Curved gwesp (harmonisation unit 136): fit directly in THETA-space
	// via ErgmCurvedMPLEFit() (unw_ergm.do) - Newton-Raphson/Fisher
	// scoring on the SAME pseudolikelihood the ordinary closed-form
	// `logit' call below maximizes, chain-ruled through the certified
	// theta_to_eta()/theta_to_eta_jacobian() (units 133-134). This
	// replaces `logit' entirely for a curved model (fits every
	// coefficient, ordinary and curved, jointly in one loop) rather
	// than running `logit' and then transforming its result - a first
	// version of this feature did exactly that (fit the unconstrained
	// eta MLE via `logit', then project down to theta), and direct
	// testing against R on a well-identified 15-node network found it
	// landing at a materially different, wrong-signed local point -
	// see ErgmCurvedMPLEFit()'s own header comment for the full
	// account of why directly optimizing the true objective is the
	// correct fix, not a patch on the old approach. Whichever curved
	// term is present (harmonisation unit 139 generalized this from
	// gwespfree() alone to gwespfree()/gwdegreefree()), its own
	// weight/decay theta columns are always the LAST 2 (registered
	// last, by construction - see its own addterm() call above), so a
	// starting theta of (0-vector, weight0=0, decay0=`__ergm_curved_start')
	// is built directly rather than needing a general "find this term's
	// own theta position" accessor.
	if `__ergm_curved' {
		tempname __ergm_curvedconv
		// Harmonisation unit 146: try the curved fit entirely natively
		// first (design-matrix build AND Newton-Raphson, one plugin
		// call) when eligible - `ErgmNativeCurvedMPLEFit()' returns 0
		// (rather than erroring) on the one real failure mode it can
		// hit (a singular final information matrix), in which case
		// falling back to the Mata `ErgmCurvedMPLEFit()' on the
		// already-built `__nw_D' below is both correct and cheap (no
		// re-fetching of anything, `__nw_D' was already built above
		// regardless of which path fits it).
		local __ergm_curved_native_used = 0
		if `__ergm_mple_native_used' {
			mata: st_local("__ergm_curved_native_used", strofreal(ErgmNativeCurvedMPLEFit(__nwergm_last_M, __nwergm_last_G, `__ergm_curved_start', "`__b_mple'", "`__V_mple'", "`__ergm_curvedconv'")))
		}
		if !`__ergm_curved_native_used' {
			mata: __ergm_theta_start = (J(1, __nwergm_last_M.ntheta()-2, 0), 0, `__ergm_curved_start')
			mata: ErgmCurvedMPLEFit(__nwergm_last_M, `__nw_D', __ergm_theta_start, 100, 1e-10, "`__b_mple'", "`__V_mple'", "`__ergm_curvedconv'")
			mata: mata drop __ergm_theta_start
		}
		mata: st_local("__ergm_curved_converged", strofreal(st_matrix("`__ergm_curvedconv'")[1,1]))
		mata: st_local("__ergm_coefnames", invtokens(__nwergm_last_M.theta_coefnames()))
		if `__ergm_curved_converged' == 0 {
			di "{err}note: the curved MPLE fit did not converge within 100 Newton-Raphson iterations - treat these results with caution."
		}
	}
	else {
		local __ergm_xlist ""
		forvalues __k = 1/`__ergm_p' {
			local __ergm_xlist "`__ergm_xlist' __ergm_x`__k'"
		}

		preserve
		qui drop _all
		qui set obs `__ergm_nrows'
		foreach __v of local __ergm_xlist {
			qui gen double `__v' = .
		}
		qui gen double __ergm_y = .
		mata: st_store(., tokens("`__ergm_xlist' __ergm_y"), `__nw_D')

		// BUGFIX: a fully edgeless (zero-tie) network - an MPLE fit
		// where the outcome never varies - used to crash completely
		// silently (only "r(2000);", no explanatory text at all) from
		// this bare, uncaptured `logit' call, unlike this command's
		// otherwise consistently friendly "{err}...{txt}" validation
		// messages for every other rejected input. `restore' still
		// needs to run regardless of failure, or a caught error here
		// would leave the caller's own dataset in the modified,
		// mid-preserve state (the same class of bug already fixed once
		// in nwrename.ado this same pass).
		capture qui logit __ergm_y `__ergm_xlist', noconstant
		if _rc != 0 {
			local __ergm_mple_rc = _rc
			restore
			di "{err}The MPLE fit did not converge (outcome does not vary - e.g. a fully edgeless network with no ties at all). Cannot estimate this model."
			error `__ergm_mple_rc'
		}
		matrix `__b_mple' = e(b)
		matrix `__V_mple' = e(V)
		restore
	}

	if "`method'" == "mple" {
		// logit's own e(b)/e(V) (non-curved path only - the curved
		// path's own ErgmCurvedMPLEFit() posts plain, unstriped
		// matrices directly) carry an equation-name stripe (the
		// depvar's own name, e.g. "__ergm_y:__ergm_x1") - blanked
		// explicitly before assigning fresh colnames/rownames, or a
		// stale/mismatched stripe between b and V makes `ereturn post`
		// fail with a "name conflict" (r(507)) - the exact same bug
		// class already found and fixed once in nwqap.ado (see its own
		// header comment). Harmless no-op on the curved path's own
		// already-unstriped matrices.
		capture matrix coleq `__b_mple' = _
		capture matrix coleq `__V_mple' = _
		capture matrix roweq `__V_mple' = _
		matrix colnames `__b_mple' = `__ergm_coefnames'
		matrix rownames `__V_mple' = `__ergm_coefnames'
		matrix colnames `__V_mple' = `__ergm_coefnames'

		ereturn post `__b_mple' `__V_mple', depname(`netname') obs(`__ergm_nrows')
		ereturn local cmd "nwergm"
		ereturn local title "Exponential-family random graph model (MPLE)"
		ereturn local depvar "`netname'"
		ereturn local method "mple"
		ereturn local directed "`directed'"
		ereturn local estat_cmd "nwergm_estat"
		ereturn scalar N = `__ergm_nrows'
		ereturn scalar nodes = `nodes'
		ereturn scalar ties = `__ergm_obsties'
		ereturn scalar curved = `__ergm_curved'
		// Harmonisation unit 145: report whether the design-matrix build
		// itself used the native backend, mirroring e(native) on the
		// MCMLE branch below - previously only ever set there, leaving
		// an MPLE fit's own e(native) undefined even when native routing
		// was actually used for it.
		ereturn scalar native = `__ergm_mple_native_used'

		nwergm_display "`netname'" "`nodes'" "`directed'" "MPLE" "" ""
		if `__ergm_curved' {
			di "{txt}Note: {bf:decay} is an ESTIMATED (curved) parameter here, fit via Newton-Raphson directly on the pseudolikelihood in theta-space - not expected to be bit-identical to R ergm's own BFGS-based curved MPLE (a different exact optimization path to the same objective), but should agree closely on a well-identified model."
		}
	}
	else {
		tempname __theta0
		// Curved gwesp (harmonisation unit 138): `__b_mple' is now
		// THETA-space for a curved model (unit 136's own MPLE change -
		// it reports gwesp_weight/gwesp_decay directly, not raw
		// eta-space esp() coefficients), but ErgmMCMLE() needs an
		// ETA-space starting vector (the actual MCMC sampling weight,
		// regardless of curved-ness). `__ergm_theta_c0_mcmle' - the
		// curved MPLE's own theta_hat, kept as a live Mata variable
		// rather than round-tripped through a Stata matrix - doubles
		// as ErgmMCMLE()'s own optional starting point for its
		// internal per-iteration eta->theta projection, so the MCMLE
		// loop warm-starts from the SAME point MPLE already found
		// rather than a generic (0,...,0,alpha0) restart.
		if `__ergm_curved' {
			mata: __ergm_theta_c0_mcmle = st_matrix("`__b_mple'")
			mata: `__theta0' = __nwergm_last_M.theta_to_eta(__ergm_theta_c0_mcmle)
		}
		else {
			mata: `__theta0' = st_matrix("`__b_mple'")
		}
		local __ergm_matatemps "`__ergm_matatemps' `__theta0'"

		// freedyads() now has a masked TNT variant too
		// (ergm_propose_tnt_masked() - docs/ERGM_ROADMAP.md's
		// "Constraints beyond v1's free binary dyad space" row) - picks
		// the masked form of whichever proposal() was actually
		// requested/defaulted to, rather than forcing uniform.
		// BUGFIX (blockdiag() addition): this must also fire for a
		// blockdiag()-only model (has_dyadmask==1 exactly the same way
		// freedyads() sets it, via the SAME set_dyadmask() call) - an
		// `if "`freedyads''!=""' check alone would silently pick the
		// UNMASKED proposal for a blockdiag()-only model, completely
		// ignoring the constraint during MCMC despite G.has_dyadmask
		// being correctly set. Caught before shipping, not after.
		if "`freedyads'" != "" | "`blockdiag'" != "" {
			// BUGFIX (harmonisation unit 168): __ergm_propcode was
			// hardcoded to 1 (uniform) on this branch regardless of
			// which masked proposal was actually picked just above -
			// harmless before this unit (a masked model was ALWAYS
			// Mata-only, and the Mata fallback path uses `__ergm_propfn'
			// directly, never this code), but M.native_proposal (which
			// this code DOES feed, via ErgmNativeSetup()'s own
			// proposal_code argument) is now read by the native masked
			// TNT port's own wire-protocol argstr - left wrong, every
			// masked+tnt native call would have silently told the C
			// plugin to run uniform instead. Caught reading this code
			// while wiring up that port, before it ever shipped.
			if "`proposal'" == "tnt" {
				local __ergm_propfn "&ergm_propose_tnt_masked()"
				local __ergm_propcode 2
			}
			else {
				local __ergm_propfn "&ergm_propose_uniform_masked()"
				local __ergm_propcode 1
			}
		}
		else if "`proposal'" == "tnt" {
			local __ergm_propfn "&ergm_propose_tnt()"
			local __ergm_propcode 2
		}
		else {
			local __ergm_propfn "&ergm_propose_uniform()"
			local __ergm_propcode 1
		}

		// Native (C) MCMC backend eligibility (harmonisation unit 83;
		// scope relaxed considerably, unit 91 follow-on - see
		// unw_ergm.do's own ErgmNativeSetup() header comment for the
		// full current term list) - decided ONCE here, before any MCMC
		// runs, never inside ErgmMCMLE()'s own loop. Sets
		// __nwergm_last_M.native_enabled; ErgmMCMCSample()/
		// ErgmMCMCSampleDiag() (called internally by ErgmMCMLE() below)
		// check that field themselves and fall back to the unmodified
		// Mata sampler whenever it is 0 - a model using any term outside
		// the native backend's own current scope, or a platform with no
		// compiled lib/plugins/ergm_mcmc.plugin, is completely
		// unaffected by this call. See unw_ergm.do's own "Native (C)
		// MCMC backend" section and docs/ERGM_ARCHITECTURE.md for the
		// full design.
		// BUGFIX: ErgmNativeSetup() returns real scalar (1/0, whether the
		// native backend ended up eligible) - calling it bare left Mata
		// auto-displaying that return value as a stray, unexplained "1"
		// (or "0") before anything else this command prints. The
		// eligibility flag itself is read straight off
		// __nwergm_last_M.native_enabled on the next line regardless, so
		// the return value was never actually needed here at all.
		// nonative (unit 160): see the identical MPLE-path comment above -
		// skips ErgmNativeSetup() entirely, leaving native_enabled at its
		// own default 0.
		if "`nonative'" == "" {
			mata: __ergm_native_setup_rc = ErgmNativeSetup(__nwergm_last_M, `__ergm_propcode', __nwergm_last_G)
			mata: mata drop __ergm_native_setup_rc
		}
		// fixdensity: force native off unconditionally (no native port
		// for this constraint - see ErgmMCMCSampleSwap()'s own header in
		// unw_ergm.do) regardless of whether ErgmNativeSetup() ran above
		// or was skipped via nonative - this is the single place that
		// sets M.fixed_density=1, guaranteed to run before ErgmMCMLE()
		// is ever called below.
		if "`fixdensity'" != "" {
			mata: __nwergm_last_M.fixed_density = 1
			mata: __nwergm_last_M.native_enabled = 0
			mata: __nwergm_last_M.native_enabled_sample = 0
		}
		// native_enabled_sample (unit 168), not native_enabled: for a
		// freedyads()-masked model native_enabled itself is forced to 0
		// (MPLE has no mask awareness), but MCMC sampling - all of
		// what an MCMLE fit's own e(native) diagnostic is actually
		// describing here - now genuinely can and does run natively.
		// Reporting native_enabled would misleadingly show e(native)==0
		// for a masked fit whose sampling loop ran on the C plugin the
		// whole time. For an unmasked model the two fields are always
		// equal, so this is a no-op change there.
		mata: st_local("__ergm_native_used", strofreal(__nwergm_last_M.native_enabled_sample))

		tempname __fit
		if `__ergm_curved' {
			mata: `__fit' = ErgmMCMLE(__nwergm_last_M, __nwergm_last_G, `__theta0', `mcmleiterations', `mcmcburnin', `mcmcinterval', `mcmcsamplesize', `__ergm_propfn', ("`verbose'"!=""), __ergm_theta_c0_mcmle)
			mata: mata drop __ergm_theta_c0_mcmle
		}
		else {
			mata: `__fit' = ErgmMCMLE(__nwergm_last_M, __nwergm_last_G, `__theta0', `mcmleiterations', `mcmcburnin', `mcmcinterval', `mcmcsamplesize', `__ergm_propfn', ("`verbose'"!=""))
		}
		local __ergm_matatemps "`__ergm_matatemps' `__fit'"

		tempname __b_mcmle __V_mcmle
		if `__ergm_curved' {
			// Curved gwesp (harmonisation unit 138): `__fit'.coef is
			// still eta-space (ErgmMCMLE() itself never reports
			// theta directly - see its own header comment); the
			// reported fit is `__fit'.coef_theta, with `__fit'.vcov
			// (eta-space) transformed via the exact same delta-method
			// formula ErgmCurvedMPLEFit() already uses internally,
			// evaluated at the converged theta rather than a
			// Newton-Raphson optimum.
			//
			// Curved MCMLE degeneracy guard: measured directly during
			// this unit's own development that a curved model CAN
			// drive the underlying MCMC chain into a genuinely
			// degenerate region (100% Metropolis-Hastings acceptance,
			// a classic stuck-chain signature) on a real test network -
			// confirmed as a genuine difficulty of the statistical
			// problem itself, not a bug specific to this
			// implementation, since R ergm's OWN reference
			// implementation independently failed outright
			// ("Unconstrained MCMC sampling did not mix at all") on
			// the identical network. Unlike R, nothing here previously
			// detected this and it silently reported a "converged"
			// fit with missing coef_theta entries cascading into a
			// nonsensical result - checked and refused explicitly now,
			// matching this project's own "never silently report a
			// wrong answer" convention, rather than chasing full
			// robustness against MCMC degeneracy (a substantially
			// larger undertaking, and one R's own mature
			// implementation does not fully solve either).
			mata: st_local("__ergm_curved_degenerate", strofreal(missing(`__fit'.coef_theta) > 0))
			if `__ergm_curved_degenerate' {
				di "{err}The curved MCMLE fit did not produce a valid result - the underlying MCMC chain likely became degenerate for this model/network combination (this is a genuine difficulty of curved-decay estimation in general, not specific to this package; R's own ergm can fail identically with 'Unconstrained MCMC sampling did not mix at all' on a hard case). Try a different starting decay value, a longer {bf:mcmcburnin()}, or a simpler model."
				error 430
			}
			mata: st_matrix("`__b_mcmle'", `__fit'.coef_theta)
			mata: __ergm_Jac_mcmle = __nwergm_last_M.theta_to_eta_jacobian(`__fit'.coef_theta)
			mata: st_matrix("`__V_mcmle'", invsym(__ergm_Jac_mcmle' * invsym(`__fit'.vcov) * __ergm_Jac_mcmle))
			mata: mata drop __ergm_Jac_mcmle
			mata: st_local("__ergm_coefnames", invtokens(__nwergm_last_M.theta_coefnames()))
		}
		else {
			mata: st_matrix("`__b_mcmle'", `__fit'.coef)
			mata: st_matrix("`__V_mcmle'", `__fit'.vcov)
		}
		// captured into plain locals, NOT e(name)-style scalars: `ereturn
		// post' below clears whatever the e() results namespace
		// currently holds, so referencing `e(converged)' AFTER that
		// call (as this code originally, incorrectly, did) reads back
		// missing - the exact same "r(x) is only published once the
		// program exits" confusion already found and fixed once in this
		// package's own nw2project.ado, here for e() instead of r().
		mata: st_local("__ergm_converged", strofreal(`__fit'.converged))
		mata: st_local("__ergm_niter", strofreal(`__fit'.niter))
		mata: st_local("__ergm_acceptrate", strofreal(`__fit'.acceptrate))
		mata: st_local("__ergm_interval_final", strofreal(`__fit'.final_interval))

		matrix coleq `__b_mcmle' = _
		matrix coleq `__V_mcmle' = _
		matrix roweq `__V_mcmle' = _
		matrix colnames `__b_mcmle' = `__ergm_coefnames'
		matrix rownames `__V_mcmle' = `__ergm_coefnames'
		matrix colnames `__V_mcmle' = `__ergm_coefnames'

		ereturn post `__b_mcmle' `__V_mcmle', depname(`netname') obs(`__ergm_nrows')
		ereturn local cmd "nwergm"
		ereturn local title "Exponential-family random graph model (MCMLE)"
		ereturn local depvar "`netname'"
		ereturn local method "mcmle"
		ereturn local directed "`directed'"
		ereturn local proposal "`proposal'"
		ereturn local estat_cmd "nwergm_estat"
		ereturn scalar N = `__ergm_nrows'
		ereturn scalar nodes = `nodes'
		ereturn scalar converged = `__ergm_converged'
		ereturn scalar mcmle_iterations = `__ergm_niter'
		ereturn scalar mcmc_acceptrate = `__ergm_acceptrate'
		ereturn scalar mcmc_burnin = `mcmcburnin'
		ereturn scalar mcmc_interval = `mcmcinterval'
		// The interval actually used for the LAST MCMLE iteration and the
		// final diagnostics simulation (harmonisation unit 85) - may
		// exceed `e(mcmc_interval)' (the caller-supplied starting value)
		// when the adaptive-interval mechanism grew it because the
		// achieved effective MCMC sample size fell short of the target
		// floor; equal to `e(mcmc_interval)' whenever no growth was ever
		// triggered (the ordinary case for small/well-mixing models).
		ereturn scalar mcmc_interval_final = `__ergm_interval_final'
		// 1 if this model's own term list was eligible for the native
		// (C) MCMC backend and the compiled plugin was actually used for
		// this run's own simulations; 0 if the Mata sampler ran instead
		// (either because a term outside the native backend's current
		// scope was present, or no compiled plugin exists for this
		// platform) - see docs/ERGM_ARCHITECTURE.md's own "Native (C)
		// MCMC backend" section for exactly which terms are covered
		// today. Purely informational: both backends are certified
		// statistically indistinguishable (cscripts/test_nwergm_native.do)
		// and nothing about interpreting results differs based on this
		// flag - it exists so a user curious about performance can see,
		// without guessing, whether their own specific model got the
		// native speedup.
		ereturn scalar native = `__ergm_native_used'
		// 1 if the Mata incremental shared-partner cache (spcache option,
		// off by default - see this call's own build-up comment above)
		// was actually enabled for this fit, 0 otherwise. Purely
		// informational, like e(native); has no effect when e(native)==1
		// (the native backend never uses this Mata-level cache at all).
		ereturn scalar spcache = `__ergm_spcache_used'
		ereturn scalar curved = `__ergm_curved'
		ereturn scalar mcmc_samplesize = `mcmcsamplesize'
		ereturn scalar ties = `__ergm_obsties'
		// the final simulation's own sufficient-statistic draws
		// (samplesize x nparam), doubling as nwergm's basic MCMC
		// diagnostics sample (Part XIX) - consumed by `estat mcmcdiag'
		// (nwergm_estat.ado). Columns are unnamed (no natural row/column
		// stripe applies to a raw draw-by-draw sample); `estat mcmcdiag'
		// pulls coefficient names from e(b) instead.
		//
		// PERFORMANCE NOTE, `nomcmcsample' (harmonisation unit 154):
		// docs/ERGM_ROADMAP.md's own unit-81 entry flagged this as a
		// "related, lower-priority risk" and guessed the fix would need
		// "reworking estat mcmcdiag's own matrix-based consumption of
		// e(mcmcsample)" - directly profiled before acting on that
		// guess, and it was WRONG in an important way: `estat mcmcdiag'`'s
		// own READ of e(mcmcsample) (`= st_matrix(...)`, Mata reading FROM
		// a Stata matrix) is fast regardless of size (0.004s at
		// 100,000x15). The entire cost lives here, in THIS bulk WRITE
		// (`st_matrix("name", data)`, Mata writing INTO a Stata matrix) -
		// confirmed by direct timing to be slow (34s+ at 100,000x15)
		// REGARDLESS of the destination name (a plain local matrix name
		// costs exactly the same as writing to "e(mcmcsample)" directly,
		// ruling out any e()-specific overhead) - a genuine architectural
		// property of Stata's own matrix engine at bulk-data scale (the
		// same class of cost unit 81 found for the MPLE design matrix),
		// not a `nwergm`-specific inefficiency and not fixable by
		// restructuring the READ side at all. Since e(mcmcsample) is
		// documented, public API (unlike unit 81's own purely-internal
		// MPLE design matrix, which never needed to exist as a genuine
		// Stata matrix at all), this write cannot be avoided when a
		// caller actually wants the sample - but a caller who only wants
		// the coefficient table, and does not intend to call `estat
		// mcmcdiag' or inspect e(mcmcsample) directly, can now skip
		// paying it via `nomcmcsample'. Default (posting it) is
		// unchanged, so this is purely additive - no existing model or
		// test loses e(mcmcsample) unless it opts out.
		if "`nomcmcsample'" == "" {
			mata: st_matrix("e(mcmcsample)", `__fit'.finalsample)
		}

		if `__ergm_converged' == 0 {
			di "{err}Warning: MCMLE did NOT satisfy its own convergence test after `__ergm_niter' iterations."
			di "{err}Results are reported but should not be treated as a converged fit - consider increasing mcmleiterations()/mcmcsamplesize()."
		}

		nwergm_display "`netname'" "`nodes'" "`directed'" "MCMLE" "`__ergm_converged'" "`__ergm_niter'" "`mcmcsamplesize'"
		if `__ergm_curved' {
			di "{txt}Note: {bf:decay} is an ESTIMATED (curved) parameter here. Each MCMLE iteration's own eta-space Newton-step target is projected back onto the 2-parameter (weight, decay) curved manifold before the next simulation - a disclosed simplification of R ergm's own curved-model machinery, not expected to be bit-identical to it."
		}
	}

	mata: mata drop `__ergm_matatemps'
end

capture program drop nwergm_display
program nwergm_display
	args netname nodes directed method converged niter mcmcsamplesize

	di
	di "{txt}Exponential-family random graph model"
	di
	di "{txt}Network:{col 24}={res}  `netname'"
	di "{txt}Nodes:{col 24}={res}  `nodes'"
	di "{txt}Ties:{col 24}={res}  `=e(ties)'"
	di "{txt}Directed:{col 24}={res}  " cond("`directed'"=="true","Yes","No")
	di "{txt}Estimation:{col 24}={res}  `method'"
	if "`method'" == "MCMLE" {
		di "{txt}MCMC sample size:{col 24}={res}  `mcmcsamplesize'"
	}
	di
	ereturn display
	di
	if "`method'" == "MCMLE" {
		if "`converged'" == "1" {
			di "{txt}MCMLE converged after `niter' iteration(s)."
		}
		else {
			di "{err}MCMLE did not converge after `niter' iteration(s)."
		}
	}
	else {
		di "{txt}Maximum pseudolikelihood estimate (not full ERGM maximum likelihood unless the model is dyad-independent)."
	}
end

/*
	nwergm simulate (Part X's own example syntax): draws one or more
	networks from a fully-specified ERGM (fixed theta, not estimated),
	via the same native MCMC engine nwergm's own estimation path uses.
	v1 scope deliberately covers only the terms needing no external
	covariate data (edges/mutual/the gw family) - see this program's own
	SMCL doc header above ("Simulation" section) for the full rationale
	and docs/ERGM_ROADMAP.md for extending this to covariate terms.
*/
capture program drop nwergm_simulate
program nwergm_simulate
	version 14
	syntax anything(name=nodes) , edges [mutual ///
		NODEMATCH(string) NODEMATCHDIFF(string) NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		EDGECOV(string) ABSDIST(string) NODEFACTOR(string) NODEMIX(string) ///
		GWESP(real 0) GWDSP(real 0) GWNSP(real 0) GWDEGREE(real 0) GWODEGREE(real 0) GWIDEGREE(real 0) ///
		DEGREE(string) ODEGREE(string) IDEGREE(string) CONCURRENT TRIANGLE CTRIPLE ///
		NODEIFACTOR(string) NODEOFACTOR(string) ///
		KSTAR(string) ISTAR(string) OSTAR(string) ///
		DEGRANGE(string) DEGRANGETO(string) ODEGRANGE(string) ODEGRANGETO(string) ///
		IDEGRANGE(string) IDEGRANGETO(string) ESP(string) DSP(string) ///
		TRANSITIVETIES CYCLICALTIES HAMMING(string) SENDER RECEIVER ///
		TYPE(string) ///
		THETA(numlist) directed NSIM(integer 1) MCMCBURNIN(integer 3000) ///
		MCMCINTERVAL(integer 50) PROPOSAL(string) SEED(integer -1) GENERATE(string) SPCACHE ]

	confirm integer number `nodes'
	if `nodes' < 2 {
		di "{err}nwergm simulate needs at least 2 nodes."
		error 198
	}
	if "`theta'" == "" {
		di "{err}option {bf:theta()} is required - one coefficient per requested term, in the same order the term options are listed (edges first)."
		error 198
	}
	if "`mutual'" != "" & "`directed'" == "" {
		di "{err}option {bf:mutual} requires {bf:directed}."
		error 198
	}
	if (`gwodegree' != 0 | `gwidegree' != 0) & "`directed'" == "" {
		di "{err}options {bf:gwodegree()}/{bf:gwidegree()} require {bf:directed}. Use {bf:gwdegree()} for an undirected simulation."
		error 198
	}
	// gwesp()/gwdsp()/gwnsp()/esp()/dsp() support directed simulation too
	// (matching the estimation path above) via one of four directed
	// shared-partner definitions selected by `type()' (default OTP) -
	// no directedness restriction on these terms themselves.
	local __ergm_type_explicit = ("`type'" != "")
	local type = upper("`type'")
	if "`type'" == "" local type "OTP"
	_opts_oneof "OTP ITP OSP ISP RTP" "type" "`type'" 6556
	if `__ergm_type_explicit' & "`directed'" == "" {
		di "{err}note: option {bf:type()} only affects directed simulation; without {bf:directed}, the undirected shared-partner definition is used regardless."
	}
	if `__ergm_type_explicit' & (`gwesp'==0 & `gwdsp'==0 & `gwnsp'==0 & "`esp'`dsp'"=="") {
		di "{err}note: option {bf:type()} has no effect - no {bf:gwesp()}/{bf:gwdsp()}/{bf:gwnsp()}/{bf:esp()}/{bf:dsp()} term was requested."
	}
	if ("`nodeicov'" != "" | "`nodeocov'" != "") & "`directed'" == "" {
		di "{err}options {bf:nodeicov()}/{bf:nodeocov()} require {bf:directed}."
		error 198
	}
	if "`degree'" != "" & "`directed'" != "" {
		di "{err}option {bf:degree()} is undirected only. Use {bf:odegree()}/{bf:idegree()} for a directed simulation."
		error 198
	}
	if ("`odegree'" != "" | "`idegree'" != "") & "`directed'" == "" {
		di "{err}options {bf:odegree()}/{bf:idegree()} require {bf:directed}. Use {bf:degree()} for an undirected simulation."
		error 198
	}
	if "`concurrent'" != "" & "`directed'" != "" {
		di "{err}option {bf:concurrent} (v1 scope) is undirected only."
		error 198
	}
	if "`triangle'" != "" & "`directed'" != "" {
		di "{err}option {bf:triangle} is undirected only. Use {bf:ctriple} for a directed simulation."
		error 198
	}
	if "`ctriple'" != "" & "`directed'" == "" {
		di "{err}option {bf:ctriple} requires {bf:directed}. Use {bf:triangle} for an undirected simulation."
		error 198
	}
	if ("`nodeifactor'" != "" | "`nodeofactor'" != "") & "`directed'" == "" {
		di "{err}options {bf:nodeifactor()}/{bf:nodeofactor()} require {bf:directed}. Use {bf:nodefactor()} for an undirected simulation."
		error 198
	}
	if "`kstar'" != "" & "`directed'" != "" {
		di "{err}option {bf:kstar()} is undirected only. Use {bf:ostar()}/{bf:istar()} for a directed simulation."
		error 198
	}
	if ("`ostar'" != "" | "`istar'" != "") & "`directed'" == "" {
		di "{err}options {bf:ostar()}/{bf:istar()} require {bf:directed}. Use {bf:kstar()} for an undirected simulation."
		error 198
	}
	if "`degrange'" != "" & "`directed'" != "" {
		di "{err}option {bf:degrange()} is undirected only. Use {bf:odegrange()}/{bf:idegrange()} for a directed simulation."
		error 198
	}
	if ("`odegrange'" != "" | "`idegrange'" != "") & "`directed'" == "" {
		di "{err}options {bf:odegrange()}/{bf:idegrange()} require {bf:directed}. Use {bf:degrange()} for an undirected simulation."
		error 198
	}
	if ("`transitiveties'" != "" | "`cyclicalties'" != "") & "`directed'" == "" {
		di "{err}options {bf:transitiveties}/{bf:cyclicalties} require {bf:directed}."
		error 198
	}
	if ("`sender'" != "" | "`receiver'" != "") & "`directed'" == "" {
		di "{err}options {bf:sender}/{bf:receiver} require {bf:directed}."
		error 198
	}
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 6556
	if "`generate'" == "" local generate "ergmsim"
	if `seed' != -1 {
		set seed `seed'
	}

	local __ergm_matatemps ""

	capture mata: mata drop __nwergm_last_M
	mata: __nwergm_last_M = ErgmModel()
	mata: __nwergm_last_M.init()

	tempname td_edges
	mata: `td_edges' = ErgmTermData()
	mata: __nwergm_last_M.addterm("edges", 1, &stat_edges(), &change_edges(), `td_edges', ("edges"))
	local ntermtok "edges"
	local __ergm_matatemps "`__ergm_matatemps' `td_edges'"

	if "`mutual'" != "" {
		tempname td_mutual
		mata: `td_mutual' = ErgmTermData()
		mata: __nwergm_last_M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), `td_mutual', ("mutual"))
		local ntermtok "`ntermtok' mutual"
		local __ergm_matatemps "`__ergm_matatemps' `td_mutual'"
	}

	// --- node-covariate terms (ported from the estimation path above):
	// read directly via st_data(1::nodes, "varname") from the ACTIVE
	// Stata dataset, exactly as estimation itself does - a network
	// object is not involved at all in this read, so nothing about
	// simulation-vs-estimation changes it. The caller needs `nodes'
	// observations with the named variable(s) already loaded (e.g.
	// `set obs 20' + `gen mygroup = ...' before calling simulate) -
	// documented in nwergm.sthlp's own Simulation section.
	local __ergm_termidx = 0
	foreach __ergm_v of local nodematch {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nm`__ergm_termidx'
		mata: `__td_nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), `__td_nm`__ergm_termidx'', ("nodematch_`__ergm_v'"))
		local ntermtok "`ntermtok' nodematch_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nm`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodecov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nc`__ergm_termidx'
		mata: `__td_nc`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nc`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), `__td_nc`__ergm_termidx'', ("nodecov_`__ergm_v'"))
		local ntermtok "`ntermtok' nodecov_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nc`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeicov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ni`__ergm_termidx'
		mata: `__td_ni`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ni`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), `__td_ni`__ergm_termidx'', ("nodeicov_`__ergm_v'"))
		local ntermtok "`ntermtok' nodeicov_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ni`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeocov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_no`__ergm_termidx'
		mata: `__td_no`__ergm_termidx'' = ErgmTermData()
		mata: `__td_no`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), `__td_no`__ergm_termidx'', ("nodeocov_`__ergm_v'"))
		local ntermtok "`ntermtok' nodeocov_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_no`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local absdist {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ad`__ergm_termidx'
		mata: `__td_ad`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ad`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("absdist", 1, &stat_absdist(), &change_absdist(), `__td_ad`__ergm_termidx'', ("absdist_`__ergm_v'"))
		local ntermtok "`ntermtok' absdist_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ad`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodematchdiff {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nmd`__ergm_termidx'
		mata: `__td_nmd`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nmd`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nmd`__ergm_termidx''.levels = uniqrows(`__td_nmd`__ergm_termidx''.attr)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nmd`__ergm_termidx''.levels)))
		tempname __ergm_levvec
		mata: st_matrix("`__ergm_levvec'", `__td_nmd`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodematch_`__ergm_v'_`=`__ergm_levvec'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodematch_diff", `__ergm_nlev', &stat_nodematch_diff(), &change_nodematch_diff(), `__td_nmd`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nmd`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodefactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nf`__ergm_termidx'
		mata: `__td_nf`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nf`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nf`__ergm_termidx''.levels = uniqrows(`__td_nf`__ergm_termidx''.attr)
		mata: `__td_nf`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nf`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nf`__ergm_termidx''.levels)))
		tempname __ergm_levvec2
		mata: st_matrix("`__ergm_levvec2'", `__td_nf`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodefactor_`__ergm_v'_`=`__ergm_levvec2'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodefactor", `__ergm_nlev', &stat_nodefactor(), &change_nodefactor(), `__td_nf`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nf`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodemix {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_mx`__ergm_termidx'
		mata: `__td_mx`__ergm_termidx'' = ErgmTermData()
		mata: `__td_mx`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __ergm_lv = uniqrows(`__td_mx`__ergm_termidx''.attr)
		mata: __ergm_np = rows(__ergm_lv)
		mata: __ergm_lp = J(0,2,0)
		mata: for (__ergm_a=1; __ergm_a<=__ergm_np; __ergm_a++) for (__ergm_b=__ergm_a; __ergm_b<=__ergm_np; __ergm_b++) __ergm_lp = __ergm_lp \ (__ergm_lv[__ergm_a], __ergm_lv[__ergm_b])
		mata: `__td_mx`__ergm_termidx''.levelpairs = __ergm_lp
		mata: st_local("__ergm_nlp", strofreal(rows(__ergm_lp)))
		tempname __ergm_lpmat
		mata: st_matrix("`__ergm_lpmat'", __ergm_lp)
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlp' {
			local __ergm_cnames "`__ergm_cnames' nodemix_`__ergm_v'_`=`__ergm_lpmat'[`__k',1]'_`=`__ergm_lpmat'[`__k',2]'"
		}
		mata: __nwergm_last_M.addterm("nodemix", `__ergm_nlp', &stat_nodemix(), &change_nodemix(), `__td_mx`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_mx`__ergm_termidx''"
		capture mata: mata drop __ergm_lv __ergm_np __ergm_lp __ergm_a __ergm_b
	}

	// --- structural terms with no covariate data at all: numlist-
	// parameterized (degree()/odegree()/idegree()/kstar()/ostar()/
	// istar()/degrange()/odegrange()/idegrange()/esp()/dsp()) or plain
	// flags (concurrent/triangle/ctriple/transitiveties/cyclicalties) -
	// ported verbatim from the estimation path, which needs nothing
	// beyond the term's own parameters either.
	if "`degree'" != "" {
		tempname __td_deg
		mata: `__td_deg' = ErgmTermData()
		mata: `__td_deg'.levels = strtoreal(tokens("`degree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_deg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `degree' {
			local __ergm_cnames "`__ergm_cnames' degree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("degree", `__ergm_ndeg', &stat_degree(), &change_degree(), `__td_deg', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_deg'"
	}
	if "`odegree'" != "" {
		tempname __td_odeg
		mata: `__td_odeg' = ErgmTermData()
		mata: `__td_odeg'.levels = strtoreal(tokens("`odegree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_odeg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `odegree' {
			local __ergm_cnames "`__ergm_cnames' odegree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("odegree", `__ergm_ndeg', &stat_odegree(), &change_odegree(), `__td_odeg', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_odeg'"
	}
	if "`idegree'" != "" {
		tempname __td_ideg
		mata: `__td_ideg' = ErgmTermData()
		mata: `__td_ideg'.levels = strtoreal(tokens("`idegree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_ideg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `idegree' {
			local __ergm_cnames "`__ergm_cnames' idegree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("idegree", `__ergm_ndeg', &stat_idegree(), &change_idegree(), `__td_ideg', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ideg'"
	}
	if "`concurrent'" != "" {
		tempname __td_conc
		mata: `__td_conc' = ErgmTermData()
		mata: __nwergm_last_M.addterm("concurrent", 1, &stat_concurrent(), &change_concurrent(), `__td_conc', ("concurrent"))
		local ntermtok "`ntermtok' concurrent"
		local __ergm_matatemps "`__ergm_matatemps' `__td_conc'"
	}
	if "`triangle'" != "" {
		tempname __td_tri
		mata: `__td_tri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), `__td_tri', ("triangle"))
		local ntermtok "`ntermtok' triangle"
		local __ergm_matatemps "`__ergm_matatemps' `__td_tri'"
	}
	if "`ctriple'" != "" {
		tempname __td_ctri
		mata: `__td_ctri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("ctriple", 1, &stat_ctriple(), &change_ctriple(), `__td_ctri', ("ctriple"))
		local ntermtok "`ntermtok' ctriple"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ctri'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeofactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nof`__ergm_termidx'
		mata: `__td_nof`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nof`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nof`__ergm_termidx''.levels = uniqrows(`__td_nof`__ergm_termidx''.attr)
		mata: `__td_nof`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nof`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nof`__ergm_termidx''.levels)))
		tempname __ergm_levvec3
		mata: st_matrix("`__ergm_levvec3'", `__td_nof`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeofactor_`__ergm_v'_`=`__ergm_levvec3'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodeofactor", `__ergm_nlev', &stat_nodeofactor(), &change_nodeofactor(), `__td_nof`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nof`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeifactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nif`__ergm_termidx'
		mata: `__td_nif`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nif`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nif`__ergm_termidx''.levels = uniqrows(`__td_nif`__ergm_termidx''.attr)
		mata: `__td_nif`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nif`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nif`__ergm_termidx''.levels)))
		tempname __ergm_levvec4
		mata: st_matrix("`__ergm_levvec4'", `__td_nif`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeifactor_`__ergm_v'_`=`__ergm_levvec4'[1,`__k']'"
		}
		mata: __nwergm_last_M.addterm("nodeifactor", `__ergm_nlev', &stat_nodeifactor(), &change_nodeifactor(), `__td_nif`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nif`__ergm_termidx''"
	}

	if "`kstar'" != "" {
		tempname __td_kstar
		mata: `__td_kstar' = ErgmTermData()
		mata: `__td_kstar'.levels = strtoreal(tokens("`kstar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_kstar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `kstar' {
			local __ergm_cnames "`__ergm_cnames' kstar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("kstar", `__ergm_nk', &stat_kstar(), &change_kstar(), `__td_kstar', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_kstar'"
	}
	if "`ostar'" != "" {
		tempname __td_ostar
		mata: `__td_ostar' = ErgmTermData()
		mata: `__td_ostar'.levels = strtoreal(tokens("`ostar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_ostar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `ostar' {
			local __ergm_cnames "`__ergm_cnames' ostar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("ostar", `__ergm_nk', &stat_ostar(), &change_ostar(), `__td_ostar', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ostar'"
	}
	if "`istar'" != "" {
		tempname __td_istar
		mata: `__td_istar' = ErgmTermData()
		mata: `__td_istar'.levels = strtoreal(tokens("`istar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_istar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `istar' {
			local __ergm_cnames "`__ergm_cnames' istar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("istar", `__ergm_nk', &stat_istar(), &change_istar(), `__td_istar', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_istar'"
	}

	if "`degrange'" != "" {
		local __ergm_ndr : word count `degrange'
		if "`degrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`degrangeto'"
			local __ergm_ndto : word count `degrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}degrange() and degrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_dr
		mata: `__td_dr' = ErgmTermData()
		mata: `__td_dr'.levelpairs = strtoreal(tokens("`degrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' degrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("degrange", `__ergm_ndr', &stat_degrange(), &change_degrange(), `__td_dr', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_dr'"
	}
	if "`odegrange'" != "" {
		local __ergm_ndr : word count `odegrange'
		if "`odegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`odegrangeto'"
			local __ergm_ndto : word count `odegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}odegrange() and odegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_odr
		mata: `__td_odr' = ErgmTermData()
		mata: `__td_odr'.levelpairs = strtoreal(tokens("`odegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' odegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("odegrange", `__ergm_ndr', &stat_odegrange(), &change_odegrange(), `__td_odr', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_odr'"
	}
	if "`idegrange'" != "" {
		local __ergm_ndr : word count `idegrange'
		if "`idegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`idegrangeto'"
			local __ergm_ndto : word count `idegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}idegrange() and idegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_idr
		mata: `__td_idr' = ErgmTermData()
		mata: `__td_idr'.levelpairs = strtoreal(tokens("`idegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' idegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("idegrange", `__ergm_ndr', &stat_idegrange(), &change_idegrange(), `__td_idr', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_idr'"
	}

	if "`esp'" != "" {
		local __ergm_nd : word count `esp'
		tempname __td_esp
		mata: `__td_esp' = ErgmTermData()
		mata: `__td_esp'.levels = strtoreal(tokens("`esp'"))'
		if "`directed'" != "" {
			mata: `__td_esp'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `esp' {
			local __ergm_cnames "`__ergm_cnames' esp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("esp", `__ergm_nd', &stat_esp(), &change_esp(), `__td_esp', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_esp'"
	}
	if "`dsp'" != "" {
		local __ergm_nd : word count `dsp'
		tempname __td_dsp2
		mata: `__td_dsp2' = ErgmTermData()
		mata: `__td_dsp2'.levels = strtoreal(tokens("`dsp'"))'
		if "`directed'" != "" {
			mata: `__td_dsp2'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `dsp' {
			local __ergm_cnames "`__ergm_cnames' dsp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("dsp", `__ergm_nd', &stat_dsp(), &change_dsp(), `__td_dsp2', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_dsp2'"
	}

	if "`transitiveties'" != "" {
		tempname __td_tt
		mata: `__td_tt' = ErgmTermData()
		mata: __nwergm_last_M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), `__td_tt', ("transitiveties"))
		local ntermtok "`ntermtok' transitiveties"
		local __ergm_matatemps "`__ergm_matatemps' `__td_tt'"
	}
	if "`cyclicalties'" != "" {
		tempname __td_ct
		mata: `__td_ct' = ErgmTermData()
		mata: __nwergm_last_M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), `__td_ct', ("cyclicalties"))
		local ntermtok "`ntermtok' cyclicalties"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ct'"
	}

	// sender()/receiver(): per-node out-/in-degree fixed effects, base=1
	// omitted - the node's own identity (1..nodes) IS the "attribute",
	// reusing stat_nodeofactor()/stat_nodeifactor() with no new Mata code,
	// exactly as the estimation path does.
	if "`sender'" != "" {
		tempname __td_send
		mata: `__td_send' = ErgmTermData()
		mata: `__td_send'.attr = (1::`nodes')
		mata: `__td_send'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' sender`__k'"
		}
		mata: __nwergm_last_M.addterm("sender", `nodes'-1, &stat_nodeofactor(), &change_nodeofactor(), `__td_send', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_send'"
	}
	if "`receiver'" != "" {
		tempname __td_recv
		mata: `__td_recv' = ErgmTermData()
		mata: `__td_recv'.attr = (1::`nodes')
		mata: `__td_recv'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' receiver`__k'"
		}
		mata: __nwergm_last_M.addterm("receiver", `nodes'-1, &stat_nodeifactor(), &change_nodeifactor(), `__td_recv', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_recv'"
	}

	// --- dyadic-covariate terms: edgecov()/hamming() reference ANOTHER
	// already-loaded network (not a plain variable) - resolved via
	// nw_syntax exactly as the estimation path does, just checked
	// against the `nodes' argument instead of an observed netname's own
	// size (simulate has no observed network to compare against).
	local __ergm_termidx = 0
	foreach __ergm_v of local edgecov {
		local ++__ergm_termidx
		tempname __td_ec`__ergm_termidx'
		mata: `__td_ec`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(ec`__ergm_termidx')
		if `ec`__ergm_termidx'nodes' != `nodes' {
			di "{err}edgecov() network {bf:`__ergm_v'} has a different number of nodes than requested ({bf:`nodes'})."
			error 198
		}
		mata: `__td_ec`__ergm_termidx''.edgecovmat = *(`ec`__ergm_termidx'netobj'->get_matrix_mod(1,("`directed'"!="")))
		mata: __nwergm_last_M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), `__td_ec`__ergm_termidx'', ("edgecov_`__ergm_v'"))
		local ntermtok "`ntermtok' edgecov_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ec`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local hamming {
		local ++__ergm_termidx
		tempname __td_hm`__ergm_termidx'
		mata: `__td_hm`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(hm`__ergm_termidx')
		if `hm`__ergm_termidx'nodes' != `nodes' {
			di "{err}hamming() network {bf:`__ergm_v'} has a different number of nodes than requested ({bf:`nodes'})."
			error 198
		}
		mata: `__td_hm`__ergm_termidx''.edgecovmat = *(`hm`__ergm_termidx'netobj'->get_matrix_mod(0,("`directed'"!="")))
		mata: __nwergm_last_M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), `__td_hm`__ergm_termidx'', ("hamming_`__ergm_v'"))
		local ntermtok "`ntermtok' hamming_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_hm`__ergm_termidx''"
	}

	if `gwesp' != 0 {
		tempname td_gwesp
		mata: `td_gwesp' = ErgmTermData()
		mata: `td_gwesp'.decay = `gwesp'
		if "`directed'" != "" {
			mata: `td_gwesp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), `td_gwesp', ("gwesp"))
		local ntermtok "`ntermtok' gwesp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwesp'"
	}
	if `gwdsp' != 0 {
		tempname td_gwdsp
		mata: `td_gwdsp' = ErgmTermData()
		mata: `td_gwdsp'.decay = `gwdsp'
		if "`directed'" != "" {
			mata: `td_gwdsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), `td_gwdsp', ("gwdsp"))
		local ntermtok "`ntermtok' gwdsp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwdsp'"
	}
	if `gwnsp' != 0 {
		tempname td_gwnsp
		mata: `td_gwnsp' = ErgmTermData()
		mata: `td_gwnsp'.decay = `gwnsp'
		if "`directed'" != "" {
			mata: `td_gwnsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), `td_gwnsp', ("gwnsp"))
		local ntermtok "`ntermtok' gwnsp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwnsp'"
	}
	if `gwdegree' != 0 {
		tempname td_gwdeg
		mata: `td_gwdeg' = ErgmTermData()
		mata: `td_gwdeg'.decay = `gwdegree'
		mata: __nwergm_last_M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), `td_gwdeg', ("gwdegree"))
		local ntermtok "`ntermtok' gwdegree"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwdeg'"
	}
	if `gwodegree' != 0 {
		tempname td_gwod
		mata: `td_gwod' = ErgmTermData()
		mata: `td_gwod'.decay = `gwodegree'
		mata: __nwergm_last_M.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), `td_gwod', ("gwodegree"))
		local ntermtok "`ntermtok' gwodegree"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwod'"
	}
	if `gwidegree' != 0 {
		tempname td_gwid
		mata: `td_gwid' = ErgmTermData()
		mata: `td_gwid'.decay = `gwidegree'
		mata: __nwergm_last_M.addterm("gwidegree", 1, &stat_gwidegree(), &change_gwidegree(), `td_gwid', ("gwidegree"))
		local ntermtok "`ntermtok' gwidegree"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwid'"
	}

	local nterm : word count `ntermtok'
	local nth : word count `theta'
	if `nth' != `nterm' {
		di "{err}theta() supplies `nth' coefficient(s) but `nterm' term(s) were requested (`ntermtok') - exactly one coefficient per term, in listed order."
		error 198
	}
	tempname thetamat
	matrix `thetamat' = J(1, `nterm', 0)
	forvalues __k = 1/`nterm' {
		matrix `thetamat'[1,`__k'] = `: word `__k' of `theta''
	}

	// spcache: same option/cache as the main nwergm program (see its own
	// build-up comment), computed ONCE here rather than per-draw below.
	// Note the cost-benefit here is even less favorable than in
	// estimation: each simulated draw gets a FRESH ErgmGraph (see the
	// loop below), so the cache's O(sum deg^2) build cost is paid nsim
	// times over, against only `mcmcburnin' toggles of benefit per draw
	// (not an entire MCMLE run's worth) - offered for consistency with
	// the estimation command, not because it is expected to help here.
	local __ergm_spcache_relevant = (`gwesp'!=0 | `gwdsp'!=0 | `gwnsp'!=0 | "`esp'"!="" | "`dsp'"!="" | "`triangle'"!="" | "`ctriple'"!="")
	if "`spcache'" != "" {
		if "`directed'" != "" {
			di "{err}note: option {bf:spcache} has no effect on a directed simulation; the incremental shared-partner cache only implements the undirected shared-partner definition."
		}
		else if !`__ergm_spcache_relevant' {
			di "{err}note: option {bf:spcache} has no effect without gwesp()/gwdsp()/gwnsp()/esp()/dsp()/triangle/ctriple; none of those terms was requested."
		}
	}
	local __ergm_spcache_used = ("`spcache'"!="" & "`directed'"=="" & `__ergm_spcache_relevant')

	// BUGFIX: used to render the simulated draw's dense adjacency matrix
	// as a literal Stata matrix-expression string (ErgmMatToLiteral())
	// and hand that to nwset's own mat() option, which hits Stata's own
	// "too many tokens" command-line limit somewhere around 16 nodes
	// (confirmed directly - see nwergm_estat.ado's identical fix for the
	// full account) - `nwergm ..., simulate' was completely broken for
	// any network that size or larger, not merely slow. Fixed the same
	// way: pass the matrix as a bare Mata variable name instead of a
	// literal expression string, which nwset's own mat() option already
	// accepts directly (the same pattern nwrandom.ado's own generators
	// already use) and has no size limit to hit.
	tempname __ergm_simmat
	forvalues __s = 1/`nsim' {
		capture mata: mata drop __nwergm_last_G
		mata: __nwergm_last_G = ErgmGraph()
		mata: __nwergm_last_G.init(`nodes', ("`directed'"!=""))
		// enable_sp_cache() only when the user explicitly opted in via
		// spcache (see this program's own build-up comment above for why
		// it is off by default and why simulate's own cost-benefit is
		// even less favorable than estimation's).
		if `__ergm_spcache_used' {
			mata: __nwergm_last_G.enable_sp_cache()
		}
		// ErgmNativeSetup() is likewise deliberately NOT called on this
		// path (harmonisation unit 83): this loop calls ErgmMCMCSample()
		// once PER SIMULATED NETWORK with samplesize=1, so `nsim' native
		// plugin calls would each pay the native boundary's own fixed
		// per-call overhead (frame create/drop, program define, dataset
		// construction) for a single-row draw - exactly the "crossing
		// the boundary too often" architecture this unit's own governing
		// instructions warn against. __nwergm_last_M.native_enabled
		// therefore simply stays at its ErgmModel::init() default of 0
		// here, so every draw runs on the unmodified Mata sampler.
		mata: __gof_discard = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, st_matrix("`thetamat'"), `mcmcburnin', `mcmcinterval', 1, `=cond("`proposal'"=="tnt","&ergm_propose_tnt()","&ergm_propose_uniform()")')
		mata: `__ergm_simmat' = __nwergm_last_G.to_dense()

		local __ergm_simname = cond(`nsim'==1, "`generate'", "`generate'_`__s'")
		capture nwdrop `__ergm_simname'
		qui drop _all
		qui set obs `nodes'
		nwset, mat(`__ergm_simmat') `=cond("`directed'"!="","directed","undirected")' name(`__ergm_simname')
	}

	mata: mata drop __nwergm_last_M __nwergm_last_G __gof_discard `__ergm_simmat' `__ergm_matatemps'
end

/*
	Bridge from an NWdef network to a fresh ErgmGraph: one-time read via
	NWdef's own neighbors() sparse accessor, undirected ties added once
	each (nb[k] <= i skipped, since ErgmGraph.toggle() already mirrors
	an undirected tie in both directions internally). Defined once at
	file scope (guarded, matching nwqap.ado's own established pattern
	for file-scope Mata helpers) rather than inside the program body -
	redefining a Mata function on every single nwergm call would error
	on the second call within the same session ("already exists").
*/
capture mata: mata drop ergm_bridge_from_netobj()
mata:
void ergm_bridge_from_netobj(pointer(class nw_def scalar) scalar netobj,
	class ErgmGraph scalar G, real scalar directed){
	real scalar i, k
	real matrix nb

	for (i=1; i<=G.n; i++) {
		nb = netobj->neighbors(i)
		for (k=1; k<=rows(nb); k++) {
			if (!directed & nb[k] <= i) continue
			G.toggle(i, nb[k])
		}
	}
}
end
