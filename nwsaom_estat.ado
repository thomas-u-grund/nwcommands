*! version 0.3.1 28aug2026 nwcommands: post-estimation for nwsaom (harmonisation units 21+26, RSiena-faithful GOF + co-evolution, N-wave)
/*
	nwsaom_estat.ado -- post-estimation commands for nwsaom (SAOM/
	Method-of-Moments). v1: `estat gof` only.

	See docs/SAOM_ROADMAP.md ("GOF (estat gof)" and "Co-evolution
	(network + behavior)") and docs/SAOM_ARCHITECTURE.md for the design
	account.

	HARMONISATION UNIT 26 (co-evolution) added a fourth default auxiliary
	statistic, `behavior` (RSiena's own `BehaviorDistribution`), whenever
	the last `nwsaom` fit in memory used `behavior()` - see the roadmap's
	own unit-26 entry for the full account, including a real Stata
	`tempname`-recycling bug found and fixed while wiring this in (every
	Mata-persistent object in this file now uses an explicit, namespaced
	name - `__nwsaom_gof_densemat` etc. - rather than `tempname`, which is
	only safe for objects that never outlive the ISSUING program).

	HARMONISATION UNIT 21 - COMPLETE REBUILD, replacing units 19-20's own
	Statnet/`nwergm'-style GOF (mean degree/avg geodesic/triad-census
	table, box-and-whisker plot) entirely, per explicit user direction
	("build the gof plot entirely like in Rsiena. drop anything else").
	That earlier version was ported from `nwergm_estat.ado`'s own `estat
	gof` WITHOUT first checking whether it matches how real RSiena itself
	does GOF - it does not, a real process gap caught only when the user
	asked directly. Verified this time BEFORE writing any code (this
	session's own established discipline): the installed RSiena package
	retains its function bodies even without raw source files
	(`get(..., envir=asNamespace("RSiena"))` reads them directly).
	Real RSiena's own GOF (`sienaGOF()`/`plot.sienaGOF()`, rsiena's own R
	source) is a fundamentally different, more rigorous methodology than
	Statnet's own descriptive comparison:

	1. AUXILIARY STATISTICS, not raw model terms - a user-chosen summary
	   function of the network (RSiena's own standard trio: out-degree
	   distribution, in-degree distribution, geodesic distance
	   distribution - `OutdegreeDistribution`/`IndegreeDistribution`/
	   `GeodesicDistribution` in real RSiena). This file's own v1 scope
	   matched that trio exactly (`stats()` option, default "outdegree
	   indegree geodesic"). **Harmonisation unit 162 added a fifth
	   `stats()` value, `triad`** - RSiena's own `TriadCensus`, the full
	   16-category MAN census, reusing `nwtriads`' real census machinery
	   (see `nwsaom_gof_triadvec` below) exactly the way `nwergm_estat.ado`
	   already does for its own (differently-structured) GOF report. A
	   genuine, disclosed difference from the other three auxiliary
	   statistics: `TriadCensus` returns RAW counts, not proportions -
	   verified directly against the installed RSiena package's own R
	   source rather than assumed by analogy to the other three.

	2. A REAL HYPOTHESIS TEST (Mahalanobis distance, Lospinoso & Snijders
	   2019), not just an eyeball comparison - verified EXACTLY from
	   RSiena's own `applyTest()` closure inside `sienaGOF()`:
	     a       = cov(simulated draws)              // k x k
	     ainv    = ginv(a)                            // Moore-Penrose
	               pseudoinverse (Mata: pinv()) - REQUIRED, not merely
	               convenient: a distribution's own categories are
	               collinear (e.g. out-degree proportions sum to 1), so
	               `a' is genuinely rank-deficient, and a plain inverse
	               would not exist.
	     simMHD  = for each simulated draw, (draw-mean)' ainv (draw-mean)
	     obsMHD  = (observed-mean)' ainv (observed-mean)
	     p       = P(simMHD >= obsMHD), estimated as the empirical
	               proportion of simulated draws whose own MHD exceeds
	               the observed's - a permutation-style p-value, NOT a
	               chi-square/normal-theory one (`twoTailed=FALSE' is
	               RSiena's own default, matching this file's own
	               default: reject for a SMALL p, i.e. the observed
	               network is an outlier relative to the simulated
	               distribution).
	   `saom_gof_mhdtest()' below is a direct, faithful port of this
	   exact construction.

	3. POOLING ACROSS PERIODS BY SUMMATION is real RSiena's own DEFAULT
	   (`join=TRUE' in `sienaGOF()' - not merely one option among several,
	   the one nobody has to ask for) - the auxiliary-statistic VECTOR is
	   summed across every period before the single MHD test is run, the
	   exact same "sum-across-periods" pooling convention this codebase
	   already uses for theta/the Jacobian (harmonisation units 17-18,
	   SaomEstimateRMMulti() - unw_saom.do) - genuinely consistent with
	   an already-established design choice, not a new one invented for
	   GOF. **Harmonisation unit 162 implemented `join=FALSE` too**, as
	   the Stata-idiomatic `join(off)` option - a SEPARATE MHD test (and
	   violin) per wave-period, REPLACING the pooled test entirely rather
	   than adding to it (matching real RSiena's own semantics: `join` is
	   a single toggle, not two independent reports). The pooled
	   (default) computation path is untouched by this addition - the
	   per-period vectors are accumulated ALONGSIDE the existing pooled
	   ones during the very same simulation loop (no extra simulation
	   work), and the reporting loop below simply branches on which set
	   of vectors to feed the (unmodified) MHD test with.

	4. THE PLOT: a VIOLIN (kernel density shape) per category, not a
	   plain box-and-whisker - real RSiena's own `panel.violin()` +
	   a thin embedded `panel.bwplot(box.ratio=0.1)` + dashed 2.5th/
	   97.5th percentile envelope lines + the OBSERVED value as a
	   red connected line/points/labels (`plot.sienaGOF()`'s own exact
	   `panelFunction`) + the test's own p-value as the plot's x-axis
	   title (RSiena's own `xlabel = paste("p:", round(x$p,3))`) - this
	   file's own `nwsaom_estat_gofviolin' below reproduces all of this
	   via Stata's own `kdensity'+`twoway rarea, horizontal' (Stata has
	   no native violin geom; this is the standard community DIY
	   technique - a real, own reimplementation, not a literal Lattice
	   port, since Stata's own graphics engine is not R's `lattice').

	Simulation source differs, disclosed: real RSiena's own `iterations`
	reuses networks ALREADY simulated and stored during the fit itself
	(`returnDeps=TRUE'); `nwsaom` has no such storage today, so this file
	runs `nsim' FRESH post-hoc simulations instead (same "restart fresh
	from each period's own observed starting wave, never chained" rule
	SaomEstimateRM()/SaomEstimateRMMulti() themselves already use). This
	does not change the STATISTICAL construction (the MHD test is
	agnostic to how the reference distribution's draws were generated,
	only that they are genuine, independent draws at the fitted
	parameters) - disclosed as a real, deliberate architectural
	difference, not silently glossed over.
*/

capture program drop nwsaom_estat
program define nwsaom_estat, rclass
	gettoken subcmd rest : 0, parse(" ,")
	local subcmd = lower(trim("`subcmd'"))
	if "`subcmd'" == "gof" {
		nwsaom_estat_gof `rest'
		// see nwergm_estat.ado's own identical `return add' - without
		// it, r() results set inside nwsaom_estat_gof (a SEPARATE
		// rclass program) do not survive as this program's own return
		// values once it exits.
		return add
	}
	else if "`subcmd'" == "mems" {
		nwsaom_estat_mems `rest'
		return add
	}
	else {
		di as err "estat `subcmd' not allowed after nwsaom - only {bf:gof} and {bf:mems} are currently supported."
		exit 321
	}
end

capture program drop nwsaom_estat_gof
program define nwsaom_estat_gof, rclass
	syntax [, NSIM(integer 50) SEED(integer -1) STATS(string) MAXDEG(integer 15) ///
		MAXDIST(integer 6) TWOTAILED NAME(string) JOIN(string)]

	// harmonisation unit 162: real RSiena's own `join=FALSE' (sienaGOF()'s
	// non-default option) - a SEPARATE MHD test per wave-period instead of
	// pooling (summing) the auxiliary statistic across periods first. Only
	// two states exist, so a plain string toggle (empty = default
	// join=TRUE/pooled, "off" = join=FALSE/per-period) rather than a
	// numlist/onoff-typed option - matches this codebase's own existing
	// idiom for similar binary "off" switches (e.g. `nonative').
	if !inlist("`join'", "", "off") {
		di as err "join() only accepts {bf:off} (v1 scope - omit join() entirely for the default pooled/join=TRUE behavior)."
		exit 198
	}
	local __gof_join = ("`join'" != "off")

	if `"`e(cmd)'"' != "nwsaom" {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	capture mata: __nwsaom_last_M.nparam()
	if _rc {
		di as err "no fitted nwsaom model available for simulation - re-run nwsaom before estat gof."
		exit 498
	}
	if `seed' != -1 {
		set seed `seed'
	}
	if `nsim' < 5 {
		di as err "nsim() must be at least 5 - the Mahalanobis test needs a genuine reference distribution, not a handful of draws."
		exit 198
	}

	// --- harmonisation unit 26: co-evolution models default to a FOURTH
	// auxiliary statistic, `behavior' (RSiena's own BehaviorDistribution),
	// alongside the existing network trio - per explicit user requirement,
	// a co-evolution model's own GOF check must cover more than just
	// network structure. e(has_behavior) is ALWAYS present (0 or 1) for
	// any nwsaom fit, old or new, so this check is safe regardless of
	// which model produced the estimates in memory.
	local __gof_coev = e(has_behavior)
	if "`stats'" == "" {
		if `__gof_coev' local stats "outdegree indegree geodesic behavior"
		else local stats "outdegree indegree geodesic"
	}
	foreach __gof_s of local stats {
		if !inlist("`__gof_s'", "outdegree", "indegree", "geodesic", "behavior", "triad") {
			di as err "stats() only supports {bf:outdegree}, {bf:indegree}, {bf:geodesic}, {bf:behavior}, {bf:triad} (v1 scope; got `__gof_s')."
			exit 198
		}
		if "`__gof_s'" == "behavior" & !`__gof_coev' {
			di as err "stats(behavior) requires a co-evolution fit (nwsaom's own {bf:behavior()} option) - the last nwsaom estimates in memory have no behavior variable."
			exit 198
		}
	}

	local nodes = e(nodes)
	local nwaves = e(nwaves)
	local nperiods = `nwaves' - 1

	tempname bmat
	matrix `bmat' = e(b)

	// per-period rate(s): e(rate) (scalar) for the exactly-two-wave
	// wave1()/wave2() path, e(rates) (1 x nperiods matrix) for the
	// waves() path (harmonisation unit 17) - `confirm matrix' is the
	// reliable way to tell which is actually present (e(rate) is a
	// scalar, not testable via a string-macro check).
	capture confirm matrix e(rates)
	if _rc == 0 {
		tempname __gof_ratesmat
		matrix `__gof_ratesmat' = e(rates)
		forvalues __pd = 1/`nperiods' {
			local __gof_rate`__pd' = `__gof_ratesmat'[1,`__pd']
		}
	}
	else {
		local __gof_rate1 = e(rate)
	}
	// harmonisation unit 26: co-evolution's own SEPARATE behavior rate,
	// per-period just like the network rate above ("extend it to N
	// waves" - e(rates_beh), a 1 x nperiods matrix, for the waves()
	// path; e(rate_beh), a scalar, for the exactly-two-wave path).
	capture confirm matrix e(rates_beh)
	if _rc == 0 {
		tempname __gof_ratesbehmat
		matrix `__gof_ratesbehmat' = e(rates_beh)
		forvalues __pd = 1/`nperiods' {
			local __gof_ratebeh`__pd' = `__gof_ratesbehmat'[1,`__pd']
		}
	}
	else {
		local __gof_ratebeh1 = e(rate_beh)
	}

	capture mata: mata drop __nwsaom_gof_cfg
	if `__gof_coev' {
		// harmonisation unit 26: co-evolution is Mata-only in v1 (no
		// native port yet, docs/SAOM_ROADMAP.md's own unit-26 entry) -
		// SaomNativeSetup() only knows about the NETWORK model and would
		// silently ignore the co-evolving behavior's own influence on
		// the network if used here, so it is not even attempted.
		local __gof_usenative = 0
		local __nwsaom_gof_pnet = e(p_net)
	}
	else {
		mata: __nwsaom_gof_cfg = SaomNativeSetup(__nwsaom_last_M)
		mata: st_numscalar("__nwsaom_gof_native", __nwsaom_gof_cfg.eligible & SaomNativeAvailable())
		local __gof_usenative = __nwsaom_gof_native
	}

	// --- observed auxiliary-statistic vectors, POOLED (summed) across
	// every period - real RSiena's own `join=TRUE' default (this file's
	// own header comment), the same pooling convention
	// SaomEstimateRMMulti() already uses for theta/the Jacobian. Behavior
	// (unit 26, N-wave extension) is now pooled the SAME way: each
	// period `pd' contributes its own ENDING wave's behavior
	// distribution, via __nwsaom_last_Behwaves[pd+1] (the pointer array
	// nwsaom.ado itself builds over all N waves) - not the old
	// two-wave-only hardcoded __nwsaom_beh_endvals.
	foreach __gof_s of local stats {
		if "`__gof_s'" == "geodesic" local __gof_k`__gof_s' = `maxdist' + 1
		else if "`__gof_s'" == "behavior" {
			mata: st_local("__gof_kbehavior", strofreal(__nwsaom_beh_maxval - __nwsaom_beh_minval + 1))
		}
		else if "`__gof_s'" == "triad" local __gof_k`__gof_s' = 16
		else local __gof_k`__gof_s' = `maxdeg' + 2
		mata: __nwsaom_gof_obs_`__gof_s' = J(1, `__gof_k`__gof_s'', 0)
		// join(off): also need each period's own UN-pooled vector kept
		// separately (see the accumulation loop below) - initialized here
		// alongside the pooled accumulator so both stay in lockstep.
		if !`__gof_join' {
			forvalues __pd = 1/`nperiods' {
				mata: __nwsaom_gof_obsP`__pd'_`__gof_s' = J(1, `__gof_k`__gof_s'', 0)
			}
		}
	}
	forvalues __pd = 1/`nperiods' {
		local __pdend = `__pd' + 1
		if `__gof_coev' & strpos(" `stats' ", " behavior ") {
			mata: __nwsaom_gof_thisval = saom_gof_behdist(*__nwsaom_last_Behwaves[`__pdend'], __nwsaom_beh_minval, __nwsaom_beh_maxval)
			mata: __nwsaom_gof_obs_behavior = __nwsaom_gof_obs_behavior + __nwsaom_gof_thisval
			if !`__gof_join' mata: __nwsaom_gof_obsP`__pd'_behavior = __nwsaom_gof_thisval
		}
		// NOT `tempname' here (real, found-the-hard-way bug, harmonisation
		// unit 26): a Stata `tempname' string is only guaranteed unique
		// for the ISSUING PROGRAM's own lifetime - once that program
		// returns, Stata's own allocator is free to reissue the SAME
		// underlying name to a LATER, unrelated tempname() call. Every
		// `__td_*' object nwsaom.ado itself builds via `tempname' (e.g.
		// `__td_recip') is a MATA variable meant to persist indefinitely
		// (referenced by pointer from __nwsaom_last_M's own `td' array,
		// unw_ergm.do), entirely outside Stata's own tempname lifecycle -
		// if a LATER `tempname' call in THIS program happens to be
		// reissued that same string and then does `mata: `name' = ...',
		// it silently overwrites the SAME Mata variable `td' still
		// points to, corrupting the model out from under it (confirmed:
		// this manifested as "[6,6] found where scalar required" inside
		// change_mutual() - a real ErgmTermData variable had been
		// clobbered with a to_dense() 6x6 matrix by exactly this
		// mechanism). Explicit, namespaced Mata names side-step the
		// entire Stata-tempname-recycling risk.
		mata: __nwsaom_gof_densemat = __nwsaom_last_G`__pdend'.to_dense()
		foreach __gof_s of local stats {
			if "`__gof_s'" == "outdegree" {
				mata: __nwsaom_gof_thisval = saom_gof_degdist(__nwsaom_gof_densemat, `maxdeg')
				mata: __nwsaom_gof_obs_outdegree = __nwsaom_gof_obs_outdegree + __nwsaom_gof_thisval
				if !`__gof_join' mata: __nwsaom_gof_obsP`__pd'_outdegree = __nwsaom_gof_thisval
			}
			if "`__gof_s'" == "indegree" {
				mata: __nwsaom_gof_thisval = saom_gof_indegdist(__nwsaom_gof_densemat, `maxdeg')
				mata: __nwsaom_gof_obs_indegree = __nwsaom_gof_obs_indegree + __nwsaom_gof_thisval
				if !`__gof_join' mata: __nwsaom_gof_obsP`__pd'_indegree = __nwsaom_gof_thisval
			}
			if "`__gof_s'" == "geodesic" {
				mata: __nwsaom_gof_thisval = saom_gof_geodist(__nwsaom_gof_densemat, `maxdist')
				mata: __nwsaom_gof_obs_geodesic = __nwsaom_gof_obs_geodesic + __nwsaom_gof_thisval
				if !`__gof_join' mata: __nwsaom_gof_obsP`__pd'_geodesic = __nwsaom_gof_thisval
			}
			// harmonisation unit 162: full 16-category MAN triad census,
			// RSiena's own TriadCensus() auxiliary statistic - see
			// nwsaom_gof_triadvec's own header comment below for why this
			// needs a real temporary NWdef network (nwtriads' own real
			// census machinery), not a pure-Mata function like the three
			// distributions above.
			if "`__gof_s'" == "triad" {
				nwsaom_gof_triadvec __nwsaom_gof_densemat __nwsaom_gof_thisval
				mata: __nwsaom_gof_obs_triad = __nwsaom_gof_obs_triad + __nwsaom_gof_thisval
				if !`__gof_join' mata: __nwsaom_gof_obsP`__pd'_triad = __nwsaom_gof_thisval
			}
		}
		mata: mata drop __nwsaom_gof_densemat
	}
	capture mata: mata drop __nwsaom_gof_thisval

	// --- simulated auxiliary-statistic matrices (nsim x k per stat) -
	// each ROW is one FULL replicate: one fresh simulated draw PER
	// PERIOD (never chained across periods or draws, matching
	// SaomEstimateRM()/SaomEstimateRMMulti()'s own simulation contract),
	// summed across periods into a single pooled vector for that
	// replicate - matches the observed side's own identical pooling. For
	// a co-evolution fit, EVERY replicate simulates network and behavior
	// JOINTLY (SaomSimulateIntervalCoev(), unw_saom.do) regardless of
	// which stats() were actually requested - the fitted coefficients
	// were estimated jointly, so a network-only simulation would not be
	// faithful to the fitted model even when only network statistics are
	// being checked.
	foreach __gof_s of local stats {
		mata: __nwsaom_gof_sim_`__gof_s' = J(`nsim', `__gof_k`__gof_s'', 0)
		if !`__gof_join' {
			forvalues __pd = 1/`nperiods' {
				mata: __nwsaom_gof_simP`__pd'_`__gof_s' = J(`nsim', `__gof_k`__gof_s'', 0)
			}
		}
	}
	// harmonisation unit 26, N-wave extension: the behavior overallMean
	// used by SaomBehavior.init() is pooled across ALL N waves - the
	// same pooling SaomEstimateRMCoevMulti() itself uses (unw_saom.do)
	// for the very same field - not just the two endpoint waves.
	if `__gof_coev' {
		mata: __nwsaom_gof_allbehvals = *__nwsaom_last_Behwaves[1]
		forvalues __w = 2/`nwaves' {
			mata: __nwsaom_gof_allbehvals = __nwsaom_gof_allbehvals \ *__nwsaom_last_Behwaves[`__w']
		}
		mata: st_numscalar("__nwsaom_gof_behmean", mean(__nwsaom_gof_allbehvals))
		local __gof_behoverallmean = __nwsaom_gof_behmean
		mata: mata drop __nwsaom_gof_allbehvals
	}
	forvalues __s = 1/`nsim' {
		foreach __gof_s of local stats {
			mata: __nwsaom_gof_row_`__gof_s' = J(1, `__gof_k`__gof_s'', 0)
		}
		forvalues __pd = 1/`nperiods' {
			mata: __nwsaom_gof_Gwork = ErgmGraph()
			mata: SaomCopyGraph(__nwsaom_last_G`__pd', __nwsaom_gof_Gwork)
			if `__gof_coev' {
				// N-wave extension: seed THIS period's own simulation from
				// THIS period's own starting wave
				// (__nwsaom_last_Behwaves[__pd]), not always wave 1, and
				// use THIS period's own behavior rate, not a single shared
				// scalar.
				// avsim's own data-derived similarityMean constant
				// (harmless 0 whenever avsim was not in the fitted
				// model) - reused from the persisted __nwsaom_last_Mbeh,
				// exactly as nwsaom.ado itself already computed it once
				// at fit time, not recomputed here.
				mata: __nwsaom_gof_Behwork = SaomBehavior()
				mata: __nwsaom_gof_Behwork.init(*__nwsaom_last_Behwaves[`__pd'], __nwsaom_beh_minval, __nwsaom_beh_maxval, `__gof_behoverallmean', __nwsaom_last_Mbeh.simMean)
				mata: __nwsaom_gof_coevres = SaomSimulateIntervalCoev(__nwsaom_gof_Gwork, __nwsaom_last_M, st_matrix("`bmat'")[1,1..`__nwsaom_gof_pnet'], ///
					__nwsaom_gof_Behwork, __nwsaom_last_Mbeh, st_matrix("`bmat'")[1,(`__nwsaom_gof_pnet'+1)..cols(st_matrix("`bmat'"))], `__gof_rate`__pd'', `__gof_ratebeh`__pd'')
				if strpos(" `stats' ", " behavior ") {
					mata: __nwsaom_gof_thisval = saom_gof_behdist(__nwsaom_gof_Behwork.values, __nwsaom_beh_minval, __nwsaom_beh_maxval)
					mata: __nwsaom_gof_row_behavior = __nwsaom_gof_row_behavior + __nwsaom_gof_thisval
					if !`__gof_join' mata: __nwsaom_gof_simP`__pd'_behavior[`__s',.] = __nwsaom_gof_thisval
				}
			}
			else if `__gof_usenative' {
				mata: __nwsaom_gof_cres = SaomSimulateIntervalNative(__nwsaom_gof_Gwork, __nwsaom_last_M, __nwsaom_gof_cfg, st_matrix("`bmat'"), `__gof_rate`__pd'', 1, 0)
			}
			else {
				mata: __nwsaom_gof_cres = SaomSimulateIntervalCounted(__nwsaom_gof_Gwork, __nwsaom_last_M, st_matrix("`bmat'"), `__gof_rate`__pd'')
			}
			// see the observed-side block above (harmonisation unit 26)
			// for why this is an explicit Mata name, not `tempname'.
			mata: __nwsaom_gof_densemat = __nwsaom_gof_Gwork.to_dense()
			foreach __gof_s of local stats {
				if "`__gof_s'" == "outdegree" {
					mata: __nwsaom_gof_thisval = saom_gof_degdist(__nwsaom_gof_densemat, `maxdeg')
					mata: __nwsaom_gof_row_outdegree = __nwsaom_gof_row_outdegree + __nwsaom_gof_thisval
					if !`__gof_join' mata: __nwsaom_gof_simP`__pd'_outdegree[`__s',.] = __nwsaom_gof_thisval
				}
				if "`__gof_s'" == "indegree" {
					mata: __nwsaom_gof_thisval = saom_gof_indegdist(__nwsaom_gof_densemat, `maxdeg')
					mata: __nwsaom_gof_row_indegree = __nwsaom_gof_row_indegree + __nwsaom_gof_thisval
					if !`__gof_join' mata: __nwsaom_gof_simP`__pd'_indegree[`__s',.] = __nwsaom_gof_thisval
				}
				if "`__gof_s'" == "geodesic" {
					mata: __nwsaom_gof_thisval = saom_gof_geodist(__nwsaom_gof_densemat, `maxdist')
					mata: __nwsaom_gof_row_geodesic = __nwsaom_gof_row_geodesic + __nwsaom_gof_thisval
					if !`__gof_join' mata: __nwsaom_gof_simP`__pd'_geodesic[`__s',.] = __nwsaom_gof_thisval
				}
				if "`__gof_s'" == "triad" {
					nwsaom_gof_triadvec __nwsaom_gof_densemat __nwsaom_gof_thisval
					mata: __nwsaom_gof_row_triad = __nwsaom_gof_row_triad + __nwsaom_gof_thisval
					if !`__gof_join' mata: __nwsaom_gof_simP`__pd'_triad[`__s',.] = __nwsaom_gof_thisval
				}
			}
			mata: mata drop __nwsaom_gof_densemat
		}
		foreach __gof_s of local stats {
			mata: __nwsaom_gof_sim_`__gof_s'[`__s',.] = __nwsaom_gof_row_`__gof_s'
		}
	}
	capture mata: mata drop __nwsaom_gof_Gwork __nwsaom_gof_cres __nwsaom_gof_Behwork __nwsaom_gof_coevres __nwsaom_gof_thisval

	// --- the Mahalanobis test + violin plot, per auxiliary statistic.
	local __gof_twotailed = ("`twotailed'" != "")
	di
	di as txt "Goodness of fit (nwsaom), Mahalanobis-distance test (Lospinoso & Snijders 2019, real RSiena's own sienaGOF() construction), " `nsim' " simulated repl. at the fitted coefficients"
	if `__gof_join' {
		if `nperiods' > 1 di as txt "(pooled across all " `nperiods' " periods by summation - real RSiena's own join=TRUE default)"
	}
	else {
		di as txt "(join(off): a SEPARATE test per period - real RSiena's own join=FALSE, replacing the pooled test entirely)"
	}
	di as txt "{hline 60}"
	foreach __gof_s of local stats {
	  if `__gof_join' {
		mata: st_numscalar("__nwsaom_gof_p", .)
		mata: st_numscalar("__nwsaom_gof_obsmhd", .)
		mata: saom_gof_mhdtest(__nwsaom_gof_sim_`__gof_s', __nwsaom_gof_obs_`__gof_s', `__gof_twotailed', "__nwsaom_gof_p", "__nwsaom_gof_obsmhd")
		local __gof_pval = __nwsaom_gof_p
		local __gof_mhd = __nwsaom_gof_obsmhd

		local __gof_label = proper("`__gof_s'")
		di as txt %-14s "`__gof_label'" "{c |}" as res " Mahalanobis dist. = " %8.3f `__gof_mhd' as txt "   p = " as res %6.3f `__gof_pval' ///
			as txt cond(`__gof_pval' < 0.05, " (evidence AGAINST fit)", " (no evidence against fit)")

		local __gof_thisname = cond("`name'"=="", "gof_`__gof_s'", "`name'_`__gof_s'")
		local __gof_behminval = 0
		if "`__gof_s'" == "behavior" mata: st_local("__gof_behminval", strofreal(__nwsaom_beh_minval))
		nwsaom_estat_gofviolin __nwsaom_gof_sim_`__gof_s' __nwsaom_gof_obs_`__gof_s' ///
			"`__gof_label' distribution" "`__gof_thisname'" `__gof_k`__gof_s'' `__gof_pval' "`__gof_s'" `maxdeg' `maxdist' `__gof_behminval'

		return scalar p_`__gof_s' = `__gof_pval'
		return scalar mhd_`__gof_s' = `__gof_mhd'
	  }
	  else {
		forvalues __pd = 1/`nperiods' {
			mata: st_numscalar("__nwsaom_gof_p", .)
			mata: st_numscalar("__nwsaom_gof_obsmhd", .)
			mata: saom_gof_mhdtest(__nwsaom_gof_simP`__pd'_`__gof_s', __nwsaom_gof_obsP`__pd'_`__gof_s', `__gof_twotailed', "__nwsaom_gof_p", "__nwsaom_gof_obsmhd")
			local __gof_pval = __nwsaom_gof_p
			local __gof_mhd = __nwsaom_gof_obsmhd

			local __gof_label = proper("`__gof_s'") + " (period `__pd')"
			di as txt %-24s "`__gof_label'" "{c |}" as res " Mahalanobis dist. = " %8.3f `__gof_mhd' as txt "   p = " as res %6.3f `__gof_pval' ///
				as txt cond(`__gof_pval' < 0.05, " (evidence AGAINST fit)", " (no evidence against fit)")

			local __gof_thisname = cond("`name'"=="", "gof_`__gof_s'_p`__pd'", "`name'_`__gof_s'_p`__pd'")
			local __gof_behminval = 0
			if "`__gof_s'" == "behavior" mata: st_local("__gof_behminval", strofreal(__nwsaom_beh_minval))
			nwsaom_estat_gofviolin __nwsaom_gof_simP`__pd'_`__gof_s' __nwsaom_gof_obsP`__pd'_`__gof_s' ///
				"`__gof_label' distribution" "`__gof_thisname'" `__gof_k`__gof_s'' `__gof_pval' "`__gof_s'" `maxdeg' `maxdist' `__gof_behminval'

			return scalar p_`__gof_s'_p`__pd' = `__gof_pval'
			return scalar mhd_`__gof_s'_p`__pd' = `__gof_mhd'
		}
	  }
	}
	di as txt "{hline 60}"
	di as txt "Note: p < 0.05 (RSiena convention) is evidence AGAINST the fitted model on that auxiliary statistic - the observed network is then an outlier relative to what the fitted model actually simulates. One-tailed by default (twotailed not requested); each violin's own x-axis title shows its p-value, matching real RSiena's plot.sienaGOF() convention exactly."

	capture mata: mata drop __nwsaom_gof_cfg
	foreach __gof_s of local stats {
		capture mata: mata drop __nwsaom_gof_obs_`__gof_s' __nwsaom_gof_sim_`__gof_s' __nwsaom_gof_row_`__gof_s'
		if !`__gof_join' {
			forvalues __pd = 1/`nperiods' {
				capture mata: mata drop __nwsaom_gof_obsP`__pd'_`__gof_s' __nwsaom_gof_simP`__pd'_`__gof_s'
			}
		}
	}
	// BUGFIX: a bare (uncaptured) trivial `local' does NOT reset a stale
	// nonzero _rc left by an earlier failed internal `capture' above (of
	// which this program has several, e.g. around the mata drops just
	// above and nwtriads/nwgeodesic calls elsewhere in this file) -
	// confirmed by direct empirical test (see nwergm_estat.ado's own
	// identical, now-fixed bug for the full account). Only a command
	// wrapped in `capture' itself resets _rc, since `capture' explicitly
	// manages it as part of its own contract; an uncaptured command,
	// however trivial or substantive, does not touch a pre-existing
	// stale value at all.
	capture qui local __nwsaom_gof_donothing = 0
end

// Full 16-category MAN triad census (harmonisation unit 162), matching
// real RSiena's own TriadCensus() auxiliary statistic EXACTLY: RAW
// counts, NOT normalized to proportions the way outdegree/indegree/
// geodesic above are - verified directly against the installed RSiena
// package's own R source (`get("TriadCensus", envir=asNamespace("RSiena"))`):
// `tc[1] <- 1/6*N*(N-1)*(N-2) - sum(tc[2:16])`, i.e. the "003" (empty
// triad) count is derived by subtraction from the total triad count,
// with every category left as a plain count - a genuine, disclosed
// difference from this file's other three auxiliary statistics, not an
// oversight (matches this whole effort's own standing instruction: when
// in doubt, mimic what R/RSiena actually does). SAOM networks are always
// directed (docs/SAOM_ROADMAP.md: "SAOM's own ministep formulation is
// inherently directed" - undirected relations remain unimplemented, and
// nwsaom's own e()-space never stores a directedness flag at all, unlike
// nwergm), so this always requests the full 16-category census, matching
// RSiena's own unconditional `levls = 1:16` default - no undirected-
// network special case is needed here the way nwergm_estat.ado's own
// analogous triad-census code needs one (nwergm supports both
// directednesses).
//
// Reuses nwtriads' own real MAN-census machinery via a temporary NWdef
// network materialized from the dense adjacency matrix - the SAME
// preserve/nwset/nwtriads/nwdrop idiom nwergm_estat.ado's own triad-
// census code already established (including its own documented,
// pre-existing nwtriads zero-tie crash defense, wrapped in `capture'
// here too since a near-empty simulated draw is a real possibility).
// Category order matches nwtriads.ado's own r(_XXX) scalar set exactly
// (and nwergm_estat.ado's own identical `__gof_triadcats' ordering) -
// nwsaom_estat_gofviolin's own triad x-axis labels below MUST stay in
// this same order.
capture program drop nwsaom_gof_triadvec
program define nwsaom_gof_triadvec
	args matname outname

	preserve
	qui drop _all
	mata: st_numscalar("__nwsaom_gof_triadn", rows(`matname'))
	qui set obs `=__nwsaom_gof_triadn'
	capture nwdrop __nwsaom_gof_triadtmp
	qui nwset, mat(`matname') directed name(__nwsaom_gof_triadtmp) nooutput
	capture qui nwtriads __nwsaom_gof_triadtmp
	if _rc == 0 {
		// st_numscalar("r(...)") - NOT a bare `r(_003)` call, which is
		// Stata's own r()-result syntax and not valid inside a Mata
		// expression at all (caught immediately: "_003 not found", r(3499),
		// the first time this ran).
		mata: `outname' = (st_numscalar("r(_003)"), st_numscalar("r(_012)"), st_numscalar("r(_021D)"), st_numscalar("r(_021U)"), st_numscalar("r(_021C)"), st_numscalar("r(_030T)"), st_numscalar("r(_030C)"), st_numscalar("r(_102)"), st_numscalar("r(_111D)"), st_numscalar("r(_111U)"), st_numscalar("r(_120D)"), st_numscalar("r(_120U)"), st_numscalar("r(_120C)"), st_numscalar("r(_210)"), st_numscalar("r(_201)"), st_numscalar("r(_300)"))
	}
	else {
		mata: `outname' = J(1,16,0)
	}
	capture nwdrop __nwsaom_gof_triadtmp
	restore
	// same _rc-staleness class as nwsaom_estat_gof's own fix above -
	// `restore' does not reset a stale _rc left by the `capture nwdrop'
	// just above it if that happened to fail, so callers of this helper
	// could otherwise inherit a leaked, unrelated stale _rc.
	capture qui local __nwsaom_triadvec_donothing = 0
end

// ===========================================================================
// Mata helpers (harmonisation unit 21). saom_gof_degdist()/_geodist() are
// this file's own pre-existing (unit 20) auxiliary-statistic generators,
// kept as-is; saom_gof_indegdist() and saom_gof_mhdtest() are new.
// Independently reimplemented under SAOM-specific names throughout, NOT a
// dependency on nwergm_estat.ado's own identically-purposed functions - see
// this file's own header comment for why a distinct copy, not a shared
// dependency on the concurrent nwergm session's own runtime state, is the
// deliberate, established pattern here.
// ===========================================================================
capture mata: mata drop saom_gof_degdist()
capture mata: mata drop saom_gof_indegdist()
capture mata: mata drop saom_gof_geodist()
capture mata: mata drop saom_gof_mhdtest()
mata:
// OUT-degree distribution (rowsum of the directed adjacency matrix - RSiena's
// own OutdegreeDistribution()). counts[1..maxdeg+1] = exact out-degree
// 0..maxdeg, counts[maxdeg+2] = "maxdeg+" overflow category.
real rowvector saom_gof_degdist(real matrix M, real scalar maxdeg) {
	real scalar n, i, d
	real colvector deg
	real rowvector counts

	n = rows(M)
	deg = rowsum(M)
	counts = J(1, maxdeg+2, 0)
	for (i=1; i<=n; i++) {
		d = deg[i]
		if (d > maxdeg) d = maxdeg + 1
		counts[d+1] = counts[d+1] + 1
	}
	return(counts / n)
}

// IN-degree distribution (colsum of the directed adjacency matrix - RSiena's
// own IndegreeDistribution()) - the mirror-image of saom_gof_degdist() above,
// same maxdeg+2-category convention so both share one x-axis scale.
real rowvector saom_gof_indegdist(real matrix M, real scalar maxdeg) {
	real scalar n, i, d
	real rowvector indeg
	real rowvector counts

	n = cols(M)
	indeg = colsum(M)
	counts = J(1, maxdeg+2, 0)
	for (i=1; i<=n; i++) {
		d = indeg[i]
		if (d > maxdeg) d = maxdeg + 1
		counts[d+1] = counts[d+1] + 1
	}
	return(counts / n)
}

// Unweighted BFS from every node, respecting DIRECTION (M[i,j]=1 means i->j;
// SAOM is always directed). counts[1..maxdist] = proportion of ordered pairs
// i!=j at that exact distance; counts[maxdist+1] = unreached pairs ("NR") -
// RSiena's own GeodesicDistribution().
real rowvector saom_gof_geodist(real matrix M, real scalar maxdist) {
	real scalar n, s, i, j, d, npairs
	real colvector dist, frontier, newfrontier
	real rowvector counts

	n = rows(M)
	counts = J(1, maxdist+1, 0)
	for (s=1; s<=n; s++) {
		dist = J(n,1,.)
		dist[s] = 0
		frontier = s
		d = 0
		while (length(frontier) > 0 & d < maxdist) {
			d++
			newfrontier = J(0,1,0)
			for (i=1; i<=length(frontier); i++) {
				for (j=1; j<=n; j++) {
					if (M[frontier[i],j] & dist[j]==.) {
						dist[j] = d
						newfrontier = newfrontier \ j
					}
				}
			}
			frontier = newfrontier
		}
		for (j=1; j<=n; j++) {
			if (j==s) continue
			if (dist[j]==.) counts[maxdist+1] = counts[maxdist+1] + 1
			else counts[dist[j]] = counts[dist[j]] + 1
		}
	}
	npairs = n*(n-1)
	if (npairs > 0) counts = counts / npairs
	return(counts)
}

// Behavior-value distribution (harmonisation unit 26, co-evolution) -
// RSiena's own BehaviorDistribution() auxiliary statistic, confirmed
// present in the installed RSiena's own live namespace (unlike
// GeodesicDistribution - unit 21's own disclosure). counts[k] =
// proportion of actors whose current value equals minval+k-1, for
// k=1..(maxval-minval+1) - no overflow category needed, unlike the
// degree distributions above: every value a behavior ministep can ever
// produce is already clamped to [minval,maxval] by construction
// (SaomBehaviorMinistep()'s own range guard, unw_saom.do).
real rowvector saom_gof_behdist(real colvector vals, real scalar minval, real scalar maxval) {
	real scalar n, i, k, ncat
	real rowvector counts

	n = rows(vals)
	ncat = maxval - minval + 1
	counts = J(1, ncat, 0)
	for (i=1; i<=n; i++) {
		k = vals[i] - minval + 1
		counts[k] = counts[k] + 1
	}
	return(counts / n)
}

// Mahalanobis-distance goodness-of-fit test - a DIRECT, faithful port of
// real RSiena's own applyTest() closure inside sienaGOF() (verified line by
// line against the installed package's own R source, see this file's own
// header comment - not a re-derivation). `sims' is nsim x k (one simulated
// replicate per row), `obs' is 1 x k (the pooled observed vector). Returns
// (by writing into the NAMED Stata scalars `pname'/`obsmhdname' - Mata
// arguments are pass-by-reference for named variables, the standard idiom
// this codebase already uses elsewhere for multi-output Mata calls from
// Stata) the empirical one-/two-tailed p-value and the observed vector's
// own Mahalanobis distance from the simulated mean.
void saom_gof_mhdtest(real matrix sims, real rowvector obs, real scalar twotailed,
	string scalar pname, string scalar obsmhdname) {

	real matrix a, ainv, centered
	real rowvector expectation, centobs
	real rowvector simMHD
	real scalar nsim, r, obsMHD, p

	nsim = rows(sims)
	a = variance(sims)
	ainv = pinv(a)
	expectation = mean(sims)
	centered = sims :- expectation
	simMHD = J(1, nsim, 0)
	for (r=1; r<=nsim; r++) simMHD[r] = centered[r,.] * ainv * centered[r,.]'
	centobs = obs - expectation
	obsMHD = centobs * ainv * centobs'

	if (twotailed) p = 1 - abs(1 - 2*sum(obsMHD :<= simMHD)/nsim)
	else p = sum(obsMHD :<= simMHD) / nsim

	st_numscalar(pname, p)
	st_numscalar(obsmhdname, obsMHD)
}
end

// Renders one violin panel: kernel-density violin per category (Stata has no
// native violin geom - this is the standard `kdensity' + `twoway rarea,
// horizontal' DIY technique, a real own implementation, not a lattice port)
// + a thin embedded box (IQR) + dashed 2.5th/97.5th percentile envelope
// lines + the OBSERVED value as a red connected line/points - reproducing
// real RSiena's own plot.sienaGOF() panelFunction (violin + panel.bwplot
// box.ratio=0.1 + dashed percentile lines + red observed overlay, see this
// file's own header comment for the exact citation) as closely as Stata's
// own graphics primitives allow. The p-value from the matching MHD test is
// shown as the x-axis title, matching RSiena's own `xlab = paste("p:", ...)'.
capture program drop nwsaom_estat_gofviolin
program define nwsaom_estat_gofviolin
	args simmat obsvec title graphname ncat pval statkind maxdeg maxdist behminval

	preserve
	qui drop _all
	mata: st_addobs(rows(`simmat'))
	forvalues __c = 1/`ncat' {
		mata: st_store(., st_addvar("double", "v`__c'"), `simmat'[.,`__c'])
	}

	// per-category summary: median, p25/p75 (thin embedded box), p2.5/p97.5
	// (dashed envelope) - RSiena's own default perc=0.05, i.e. a 95%
	// envelope.
	tempname __gv_summ
	mata: `__gv_summ' = J(`ncat', 5, .)
	forvalues __c = 1/`ncat' {
		qui summarize v`__c', detail
		mata: `__gv_summ'[`__c',1] = st_numscalar("r(p50)")
		mata: `__gv_summ'[`__c',2] = st_numscalar("r(p25)")
		mata: `__gv_summ'[`__c',3] = st_numscalar("r(p75)")
	}
	mata: st_local("__gv_nsim", strofreal(rows(`simmat')))
	local __gv_lo = max(1, round(`__gv_nsim' * 0.025))
	local __gv_hi = round(`__gv_nsim' * 0.975)
	forvalues __c = 1/`ncat' {
		qui mata: st_matrix("__gv_sorted", sort(`simmat'[.,`__c'], 1))
		mata: `__gv_summ'[`__c',4] = st_matrix("__gv_sorted")[`__gv_lo',1]
		mata: `__gv_summ'[`__c',5] = st_matrix("__gv_sorted")[`__gv_hi',1]
	}

	// --- violin polygons: one kdensity per category, normalized to a
	// fixed max half-width (0.4, leaving a gap between adjacent
	// integer-spaced categories), stacked into ONE long dataset with a
	// missing-value separator row between categories so a SINGLE
	// `twoway rarea ..., horizontal' layer renders every violin without
	// spuriously connecting one category's shape to the next.
	tempname __gv_stack
	mata: `__gv_stack' = J(0, 3, .)		// xlo, xhi, y
	// `kdensity ..., generate() n(50)' needs at least 50 OBSERVATIONS in
	// the current dataset to store its own 50-point grid (missing
	// values in v1..vK beyond the original `nsim' rows are harmless -
	// kdensity's own density estimate only ever uses the NON-missing
	// values of its own input variable, regardless of how many total
	// rows exist).
	qui set obs `=max(_N, 50)'
	forvalues __c = 1/`ncat' {
		cap drop kx ky
		qui kdensity v`__c', n(50) generate(kx ky) nograph
		// kdensity's own 50-point grid always lands in rows 1..50,
		// regardless of the dataset's own (possibly larger, if
		// nsim>50) total row count - reading exactly those 50 rows
		// (not `.', all rows) avoids pulling in kdensity's own missing
		// tail beyond its grid.
		qui summarize ky in 1/50, meanonly
		local __gv_maxdens = r(max)
		if `__gv_maxdens' <= 0 local __gv_maxdens = 1
		qui gen double __gv_hw = 0.4 * ky / `__gv_maxdens'
		mata: `__gv_stack' = `__gv_stack' \ (`__c' :- st_data((1::50),"__gv_hw"), `__c' :+ st_data((1::50),"__gv_hw"), st_data((1::50),"kx")) \ (.,.,.)
		drop kx ky __gv_hw
	}
	qui drop _all
	mata: st_addobs(rows(`__gv_stack'))
	mata: st_store(., st_addvar("double", "vxlo"), `__gv_stack'[.,1])
	mata: st_store(., st_addvar("double", "vxhi"), `__gv_stack'[.,2])
	mata: st_store(., st_addvar("double", "vy"), `__gv_stack'[.,3])
	mata: mata drop `__gv_stack'

	// --- box/envelope/observed overlay dataset: one row per category.
	qui set obs `=max(_N,`ncat')'
	mata: st_store((1::`ncat'), st_addvar("double", "cat"), (1::`ncat'))
	mata: st_store((1::`ncat'), st_addvar("double", "bmedian"), `__gv_summ'[.,1])
	mata: st_store((1::`ncat'), st_addvar("double", "bp25"), `__gv_summ'[.,2])
	mata: st_store((1::`ncat'), st_addvar("double", "bp75"), `__gv_summ'[.,3])
	mata: st_store((1::`ncat'), st_addvar("double", "envlo"), `__gv_summ'[.,4])
	mata: st_store((1::`ncat'), st_addvar("double", "envhi"), `__gv_summ'[.,5])
	mata: st_store((1::`ncat'), st_addvar("double", "obsval"), `obsvec'')
	mata: mata drop `__gv_summ'

	local __gv_xtitle = `"p: `pval'"'
	local __gv_xlabopt ""
	if "`statkind'" == "behavior" {
		// harmonisation unit 26: every category is an EXACT, bounded
		// behavior value (minval..maxval) - no overflow/"NR" category
		// at all, unlike the network distributions below (every
		// simulated/observed value is clamped to [minval,maxval] by
		// SaomBehaviorMinistep()'s own construction, unw_saom.do).
		forvalues __c = 1/`ncat' {
			local __gv_thislab = `behminval' + `__c' - 1
			local __gv_xlabopt `"`__gv_xlabopt' `__c' "`__gv_thislab'""'
		}
	}
	else if "`statkind'" == "triad" {
		// Order MUST match nwsaom_gof_triadvec's own output vector order
		// exactly (both above).
		local __gv_triadlabs "003 012 021D 021U 021C 030T 030C 102 111D 111U 120D 120U 120C 210 201 300"
		local __gv_c = 0
		foreach __gv_lab of local __gv_triadlabs {
			local __gv_c = `__gv_c' + 1
			local __gv_xlabopt `"`__gv_xlabopt' `__gv_c' "`__gv_lab'""'
		}
	}
	else {
		local __gv_lastlabel = cond("`statkind'"=="geodesic", "NR", "`maxdeg'+")
		forvalues __c = 1/`=`ncat'-1' {
			local __gv_thislab = cond("`statkind'"=="geodesic", "`__c'", "`=`__c'-1'")
			local __gv_xlabopt `"`__gv_xlabopt' `__c' "`__gv_thislab'""'
		}
		local __gv_xlabopt `"`__gv_xlabopt' `ncat' "`__gv_lastlabel'""'
	}

	// Category on the X-axis (matching real RSiena's own `scales$x$labels
	// = key' convention), statistic value on the Y-axis. Only the violin
	// itself (`rarea', drawing an X-RANGE as a function of Y - the
	// opposite of `rarea's own default "Y-range as a function of X")
	// needs `horizontal'; every other layer is plotted in its normal,
	// default (y, x) orientation - a fixed category position on X, the
	// actual statistic value on Y.
	twoway (rarea vxlo vxhi vy, horizontal fcolor(gs14) lcolor(gs10) lwidth(vthin)) ///
		(rcap bp75 bp25 cat, lcolor(black) lwidth(medium)) ///
		(scatter bmedian cat, msymbol(diamond) mcolor(black) msize(small)) ///
		(line envlo cat, lpattern(dash) lcolor(gs8) lwidth(medthin)) ///
		(line envhi cat, lpattern(dash) lcolor(gs8) lwidth(medthin)) ///
		(connected obsval cat, lcolor(red) mcolor(red) msymbol(circle) lwidth(medthin)), ///
		xlabel(`__gv_xlabopt', angle(0) labsize(vsmall)) ///
		ytitle("Statistic") xtitle("`__gv_xtitle'") ///
		title("`title'", size(small)) legend(off) name(`graphname', replace)
	restore

	di as txt "(plot saved as {bf:`graphname'}; violin = simulated distribution's own shape, thin black bar = interquartile range, dashed gray lines = 95% envelope, red = observed)"
end

// ===========================================================================
// estat mems (MEMs, Duxbury's netmediate package): "Micro Effects on Macro
// Structure" - a mediation-style sensitivity analysis asking "how much does
// a chosen MICRO-level effect (one of this model's own coefficients) change
// a MACRO-level network summary the user supplies?", scoped and derived
// against the real installed `netmediate' R package's own source (not
// guessed - `deparse(body(netmediate:::MEMS_saom))` and
// `deparse(args(netmediate::MEMS))`, both read directly). Real algorithm:
//   1. Draw `nsim' theta vectors from MASS::mvrnorm(mu=e(b), Sigma=e(V),
//      empirical=TRUE) - "empirical=TRUE" is not an ordinary MVN draw, it
//      is an EXACT-MOMENT-MATCHING construction (confirmed from MASS's own
//      real source, `deparse(MASS::mvrnorm)`): the nsim draws' OWN sample
//      mean/covariance equal e(b)/e(V) EXACTLY (up to floating point), not
//      merely asymptotically as nsim -> infinity. MASS's own real
//      construction whitens via an SVD; `saom_mems_draw_theta()' below
//      achieves the IDENTICAL statistical guarantee (exact sample
//      mean/covariance) via a Cholesky-based whitening instead - a
//      different but equally valid route to the same property (which
//      orthogonal transform is used has no bearing on the validity of the
//      resulting Monte Carlo estimate), disclosed here since it is not a
//      bit-for-bit RNG-path replication (impossible anyway - Mata's RNG
//      stream is unrelated to R's).
//   2. For each of `interval()' (default 0 1, matching netmediate's own
//      default exactly), scale ONLY the named `effect()' coefficient in
//      each theta draw by that interval value (0 = as if the effect did
//      not operate at all; 1 = its actual fitted strength), then simulate
//      ONE fresh network forward from the model's own OBSERVED wave1 under
//      that scaled theta (reusing the exact same
//      SaomSimulateIntervalNative()/SaomSimulateIntervalCounted() machinery
//      `estat gof' already uses for its own post-hoc simulations - same
//      "restart fresh from the observed starting wave" convention, no
//      chaining).
//   3. Apply the user's own `macro()' Stata program (one macro-level
//      network summary, e.g. density/centralization/segregation - the
//      user's own choice, matching netmediate's own `macro_function'
//      argument) to each simulated network.
//   4. Report the paired difference (macro at interval=1 minus macro at
//      interval=0, pooled across every draw and consecutive interval pair
//      when interval() has more than 2 values, matching real
//      `netmediate:::MEMS_saom''s own `mean(diff_data, na.rm=TRUE)' over
//      the WHOLE matrix): mean ("MEMS" estimate), SD, a 95% PERCENTILE
//      interval (R's own default `quantile()' algorithm - type 7, linear
//      interpolation on the sorted sample - `saom_mems_quantile()' below),
//      a Monte Carlo p-value (the literal real formula: the proportion of
//      draws whose SIGN is opposite the overall mean effect - NOT doubled,
//      confirmed from source, a specific convention not the usual
//      two-sided count), and "Prop. Change in M" (mean of
//      diff/macro-at-interval-1, excluding non-finite ratios - confirmed
//      from source that ONLY the point estimate is reported for this row,
//      no SE/CI/p-value, matching netmediate's own summary matrix, which
//      leaves those cells as NA).
//
// v1 scope, disclosed: exactly-two-wave (`wave1()'/`wave2()'), network-only
// fits - co-evolution (`behavior()'), multi-wave (`waves()'), `symmetric',
// and multiplex are all rejected with a clear message rather than silently
// mishandled (each adds real complexity in real RSiena's own MEMS
// construction too - e.g. a genuine multi-period forward simulation chained
// through each period's own simulated, not observed, end state - not
// chased here). The VanderWeele E-value sensitivity bound (netmediate's own
// `sensitivity_ev' argument, default TRUE there) is NOT implemented - a
// disclosed, deliberately narrower v1 (real netmediate's own bootstrap
// implementation of it has what looks like a genuine copy-paste bug,
// `CI_upper_boot <- E_fun(CI_lower_boot)' reusing the LOWER bound twice -
// not something to faithfully reproduce, and correctly reimplementing it
// was not this pass's own priority). No common-random-numbers pairing
// between a draw's own interval=0/interval=1 simulations either (each
// simulation call draws its own fresh randomness) - only the THETA draw
// itself is shared across a row's own interval values, matching what the
// real source's own `theta2 <- theta; theta2[,idx] <- theta2[,idx]*interval'
// construction guarantees and no more.
// ===========================================================================

capture program drop nwsaom_estat_mems
program define nwsaom_estat_mems, rclass
	syntax , EFFECT(string) MACRO(string) [NSIM(integer 500) SEED(integer -1) INTERVAL(numlist sort) NODOTS]

	if `"`e(cmd)'"' != "nwsaom" {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	capture mata: __nwsaom_last_M.nparam()
	if _rc {
		di as err "no fitted nwsaom model available for simulation - re-run nwsaom before estat mems."
		exit 498
	}
	if e(has_behavior) {
		di as err "estat mems does not yet support co-evolution ({bf:behavior()}) fits - v1 scope, network-only (see this file's own header comment on why)."
		exit 498
	}
	capture confirm matrix e(rates)
	if _rc == 0 {
		di as err "estat mems does not yet support multi-wave ({bf:waves()}) fits - v1 scope, exactly two waves ({bf:wave1()}/{bf:wave2()})."
		exit 498
	}
	capture confirm scalar e(rate)
	if _rc {
		di as err "estat mems requires an ordinary two-wave network-only nwsaom fit (no {bf:symmetric}, multiplex, or other v1-excluded combination)."
		exit 498
	}

	if "`interval'" == "" local interval "0 1"
	local __mems_nint : word count `interval'
	if `__mems_nint' < 2 {
		di as err "interval() needs at least two values (default: 0 1)."
		exit 198
	}
	if `nsim' < 20 {
		di as err "nsim() must be at least 20 - MEMs needs a genuine Monte Carlo reference distribution, not a handful of draws."
		exit 198
	}

	if `seed' != -1 set seed `seed'

	tempname bmat Vmat
	matrix `bmat' = e(b)
	matrix `Vmat' = e(V)
	local __mems_names : colnames `bmat'
	local __mems_effpos : list posof "`effect'" in __mems_names
	if `__mems_effpos' == 0 {
		di as err "effect(`effect') is not one of this fitted model's own coefficients. Available: `__mems_names'"
		exit 198
	}

	local __mems_rate = e(rate)

	// Validate macro() with a real trial call (on the observed starting
	// network) BEFORE burning time on nsim simulations - there is no
	// reliable way to check "is this a defined Stata program" without
	// actually calling it (Stata's own `which'/`confirm' only recognize
	// built-ins and ado-files ON DISK, confirmed directly - a real, easy
	// mistake: an EARLIER version of this check used `capture which
	// `macro'', which ALWAYS failed for a plain in-session `program
	// define'd macro(), caught only by an actual end-to-end test, not by
	// inspection). This also catches a macro() that exists but has the
	// wrong calling convention (no r(stat), wrong argument count) up
	// front, with a clear message, rather than nsim calls deep into a
	// long-running loop.
	mata: __nwsaom_mems_trialmat = __nwsaom_last_G1.to_dense()
	capture nwsaom_mems_callmacro __nwsaom_mems_trialmat "`macro'"
	if _rc {
		di as err "macro(`macro') failed on a trial call using the observed starting network (rc=`=_rc'). `macro' must be a defined Stata program taking ONE argument (a network name) and returning its own macro-level statistic in r(stat) - e.g. a program that runs args netname, then nwsummarize on that network name with the matonly option, then return scalar stat = r(density)."
		mata: mata drop __nwsaom_mems_trialmat
		exit 498
	}
	mata: mata drop __nwsaom_mems_trialmat

	mata: st_matrix("__mems_theta", saom_mems_draw_theta(st_matrix("`bmat'"), st_matrix("`Vmat'"), `nsim'))

	capture mata: mata drop __nwsaom_mems_cfg
	mata: __nwsaom_mems_cfg = SaomNativeSetup(__nwsaom_last_M)
	mata: st_numscalar("__nwsaom_mems_native", __nwsaom_mems_cfg.eligible & SaomNativeAvailable())
	local __mems_usenative = __nwsaom_mems_native

	mata: __nwsaom_mems_outdata = J(`nsim', `__mems_nint', .)

	local __mems_i = 0
	foreach __mems_ival of local interval {
		local ++__mems_i
		if "`nodots'" == "" di as text "interval `__mems_ival': " _continue
		forvalues __mems_s = 1/`nsim' {
			mata: __nwsaom_mems_theta_s = st_matrix("__mems_theta")[`__mems_s',.]
			mata: __nwsaom_mems_theta_s[1,`__mems_effpos'] = __nwsaom_mems_theta_s[1,`__mems_effpos'] * (`__mems_ival')
			mata: __nwsaom_mems_Gwork = ErgmGraph()
			mata: SaomCopyGraph(__nwsaom_last_G1, __nwsaom_mems_Gwork)
			if `__mems_usenative' {
				mata: SaomSimulateIntervalNative(__nwsaom_mems_Gwork, __nwsaom_last_M, __nwsaom_mems_cfg, __nwsaom_mems_theta_s, `__mems_rate', 1, 0)
			}
			else {
				mata: SaomSimulateIntervalCounted(__nwsaom_mems_Gwork, __nwsaom_last_M, __nwsaom_mems_theta_s, `__mems_rate')
			}
			mata: __nwsaom_mems_densemat = __nwsaom_mems_Gwork.to_dense()
			nwsaom_mems_callmacro __nwsaom_mems_densemat "`macro'"
			mata: __nwsaom_mems_outdata[`__mems_s',`__mems_i'] = `r(stat)'
			mata: mata drop __nwsaom_mems_densemat __nwsaom_mems_Gwork __nwsaom_mems_theta_s
			if "`nodots'" == "" & mod(`__mems_s',50)==0 di as text "." _continue
		}
		if "`nodots'" == "" di ""
	}

	tempname __mems_resmat
	mata: st_matrix("`__mems_resmat'", saom_mems_report(__nwsaom_mems_outdata, `__mems_nint'))
	local __mems_est = `__mems_resmat'[1,1]
	local __mems_sd = `__mems_resmat'[1,2]
	local __mems_lo = `__mems_resmat'[1,3]
	local __mems_hi = `__mems_resmat'[1,4]
	local __mems_pval = `__mems_resmat'[1,5]
	local __mems_prop = `__mems_resmat'[1,6]

	di as text "{hline}"
	di as text "MEMs (Micro Effects on Macro Structure) - Duxbury, via " as result "`macro'"
	di as text "Micro process: " as result "`effect'" as text "  Interval: " as result "`interval'" as text "  nsim: " as result `nsim'
	di as text "{hline}"
	di as text "{col 1}{c |}{col 15}Estimate{col 27}Std. Dev.{col 40}[95% CI]{col 62}MC p-val"
	di as text "{hline}"
	di as text "MEMS{col 15}{res}" %8.4f `__mems_est' as text "{col 27}{res}" %8.4f `__mems_sd' as text "{col 40}{res}" %8.4f `__mems_lo' as text " , " %8.4f `__mems_hi' as text "{col 62}{res}" %6.4f `__mems_pval'
	di as text "Prop. Change in M{col 40}{res}" %8.4f `__mems_prop'
	di as text "{hline}"
	di as text "(MEMS = mean difference in {bf:`macro'} between interval=`=word("`interval'",`__mems_nint')' and interval=`=word("`interval'",1)'; Prop. Change in M = that difference as a proportion of the interval=`=word("`interval'",`__mems_nint')' value; MC p-val = proportion of draws with the opposite sign - a real, disclosed simplification vs real netmediate/RSiena: independent simulation randomness per draw, no common-random-numbers pairing, and the VanderWeele E-value sensitivity bound is not yet implemented)"

	return scalar mems = `__mems_est'
	return scalar mems_sd = `__mems_sd'
	return scalar mems_lb = `__mems_lo'
	return scalar mems_ub = `__mems_hi'
	return scalar mems_p = `__mems_pval'
	return scalar propchange = `__mems_prop'
	return local effect "`effect'"
	return local macro "`macro'"

	capture mata: mata drop __nwsaom_mems_cfg __nwsaom_mems_outdata
	capture qui local __nwsaom_mems_donothing = 0
end

/* nwsaom_mems_callmacro: builds a real, temporary NWdef network from a dense
   Mata adjacency matrix and calls the user's own `macro' program on it,
   returning its own r(stat) - the exact same "dense matrix -> temporary
   nwset network -> read back r()" round trip nwsaom_gof_triadvec() already
   established above for calling nwtriads per simulated replicate. */
capture program drop nwsaom_mems_callmacro
program define nwsaom_mems_callmacro, rclass
	args matname macroname

	preserve
	qui drop _all
	mata: st_numscalar("__nwsaom_mems_n", rows(`matname'))
	qui set obs `=__nwsaom_mems_n'
	capture nwdrop __nwsaom_mems_tmpnet
	qui nwset, mat(`matname') directed name(__nwsaom_mems_tmpnet) nooutput
	`macroname' __nwsaom_mems_tmpnet
	return scalar stat = r(stat)
	capture nwdrop __nwsaom_mems_tmpnet
	restore
	// same _rc-staleness class as nwsaom_estat_gof's/nwsaom_gof_triadvec's
	// own fix - `restore' does not reset a stale _rc left by a failed
	// `capture nwdrop' just above it.
	capture qui local __nwsaom_mems_donothing = 0
end

// ===========================================================================
// Mata helpers for estat mems (see that program's own header comment for
// the full derivation/source-verification account).
// ===========================================================================
mata:

/* saom_mems_draw_theta(): nsim draws from an "empirical" (exact
   sample-moment-matching) MVN(b, V) - see this section's own header
   comment for the real MASS::mvrnorm(empirical=TRUE) derivation and why
   this Cholesky-based route achieves the identical statistical guarantee
   via a different (but equally valid) internal transform. */
real matrix saom_mems_draw_theta(real rowvector b, real matrix V, real scalar nsim) {
	real matrix Z, Zc, S, L, A, Zw, Lv

	Z = rnormal(nsim, cols(b), 0, 1)
	Zc = Z :- J(nsim, 1, 1) * mean(Z)			// exact column mean 0
	S = cross(Zc, Zc) / (nsim - 1)				// Zc's own (near-identity) sample covariance
	L = cholesky(S)						// S = L*L'
	A = luinv(L')
	Zw = Zc * A						// Zw'Zw/(nsim-1) == I(cols(b)) EXACTLY
	Lv = cholesky(V)					// V = Lv*Lv'
	return(J(nsim, 1, 1) * b + Zw * Lv')			// sample mean == b, sample covariance == V EXACTLY
}

/* saom_mems_quantile(): R's own default `quantile()' algorithm (type 7,
   linear interpolation on the sorted sample) - matches
   `quantile(diff_data, 0.025)'/`quantile(diff_data, 0.975)' in real
   netmediate's own source exactly. */
real scalar saom_mems_quantile(real colvector x, real scalar p) {
	real colvector xs
	real scalar n, h, lo, hi

	xs = sort(x, 1)
	n = length(xs)
	h = (n - 1) * p + 1
	lo = floor(h)
	hi = ceil(h)
	if (lo < 1) lo = 1
	if (hi > n) hi = n
	return(xs[lo] + (h - lo) * (xs[hi] - xs[lo]))
}

/* saom_mems_report(): the real netmediate:::MEMS_saom() summary-matrix
   construction (see this section's own header comment) - pools every
   consecutive interval-pair difference (matching `diff_data' there, and
   its own whole-matrix `mean()'/`sd()'/`quantile()' calls) rather than
   assuming interval() has exactly 2 values, though that IS the default and
   by far the common case. Returns (est, sd, lo, hi, pval, propest) as a
   plain rowvector - no Mata globals (this codebase's own established
   discipline, see e.g. unw_ergm.do's own "avoids needing genuine Mata
   'global' variables" comment) - the calling .ado program reads it back
   via a single `st_matrix()' round trip. */
real rowvector saom_mems_report(real matrix outdata, real scalar nint) {
	real matrix diffdata, propdata
	real colvector pooled, pooledprop
	real scalar est, sd, lo, hi, pval, propest

	diffdata = outdata[., 2::nint] - outdata[., 1::(nint - 1)]
	pooled = vec(diffdata)

	est = mean(pooled)
	sd = sqrt(variance(pooled))
	lo = saom_mems_quantile(pooled, 0.025)
	hi = saom_mems_quantile(pooled, 0.975)
	if (est < 0) pval = sum(pooled :> 0) / length(pooled)
	else pval = sum(pooled :< 0) / length(pooled)

	propdata = diffdata :/ outdata[., 2::nint]
	pooledprop = vec(propdata)
	pooledprop = select(pooledprop, pooledprop :< .)		// drop non-finite (division by an exact-0 macro value)
	propest = mean(pooledprop)

	return((est, sd, lo, hi, pval, propest))
}
end
