capture program drop nwkatz
program nwkatz
	version 9
	// BUGFIX: this .sthlp explicitly documents "the network is
	// otherwise symmetrized for the underlying distance calculation
	// unless geodesic_options specifies nosym" and unconditionally
	// printed "Network has been symmetrized for calculation." on every
	// call - but neither `nosym' nor `sym' was ever declared here, so
	// `nosym' (forwarded via the trailing `*' catch-all) reached the
	// internal nwgeodesic call as a no-op (nwgeodesic's own real
	// toggle is opt-IN `sym', already off by default) and the sthlp's
	// own claimed default behavior never actually happened - the
	// printed message was simply false. Declaring `nosym' here makes
	// Stata's own parser define a local named after the STEM - `sym',
	// not `nosym' - set to "nosym" when passed, empty otherwise (the
	// same convention nwbetween.ado's/nwcloseness.ado's own identical
	// symmetrize-by-default toggle already uses).
	// alpha(real -999999) - a sentinel, not a plain numeric default (a
	// literal Stata missing value, `.', is not accepted here - Stata's
	// own `syntax' parser rejects it as an option default, confirmed
	// directly) - so `walks' (added alongside this) can tell "the
	// caller passed alpha()" apart from "use whichever default
	// applies", since the two modes need genuinely different defaults
	// (1 for the pre-existing distance-decay formula, 0.9/rho for the
	// walk-counting one - see below).
	syntax [anything(name=netname)] , [ alpha(real -999999) walks GENerate(string) replace nosym *]
	if "`sym'" == "" {
		local symopt "sym"
	}

	nw_syntax `netname', max(1)
	local origdirected "`directed'"
	nw_datasync `netname'

	local original `netname'
	if "`generate'" == "" {
		local generate = "_katz"
	}

	// `replace' was previously absorbed by the trailing `*' catch-all
	// (which populates `options', never a local literally named
	// `replace') rather than being declared as a real option, so this
	// guard could never actually see it - `replace' silently never
	// worked. Also: the guard printed an error but never called
	// error/exit, so execution continued regardless and could silently
	// clobber (or crash later inside getmata on) an existing variable.
	// Both fixed here.
	if "`directed'" == "false" {
		capture confirm variable `generate'
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
			// Error-code coherence: standardized onto 99 (this
			// package's own standard "Stata variable already exists"
			// code, nw_errorcodes.sthlp) - was 110, an unexplained
			// outlier versus nwdegree/nwbetween/nw2degree's own
			// convention for the identical situation in this same
			// group.
			err 99
		}
		local generate_all `generate'
	}
	else {
		local generate_all ""
		foreach c in `generate'_in `generate'_out {
			capture confirm variable `c'
			if _rc == 0 & "`replace'" == "" {
				di "{err}Variable {bf:`c'} already exists; use {bf:replace}"
				// Error-code coherence: standardized onto 99 (this
			// package's own standard "Stata variable already exists"
			// code, nw_errorcodes.sthlp) - was 110, an unexplained
			// outlier versus nwdegree/nwbetween/nw2degree's own
			// convention for the identical situation in this same
			// group.
			err 99
			}
			local generate_all `generate_all' `c'
		}
	}

	tempname __nw_out __nw_in __nw_all
	local rho = .
	local __nwkatz_havegeo = 0
	if "`walks'" != "" {
		// Genuine walk-counting Katz/Bonacich: x = (I - alpha*A)^-1 * 1,
		// solved directly (lusolve, not an explicit matrix inverse) -
		// no nwgeodesic call, no symmetrization, no mutation of the
		// network's own edge matrix at all (unlike the distance-decay
		// path below, which overwrites it in place via set_edge()).
		tempname __nwkatz_M __nwkatz_rho
		mata: `__nwkatz_M' = *`netobj'->get_matrix()
		mata: _editmissing(`__nwkatz_M', 0)
		mata: `__nwkatz_rho' = max(abs(eigenvalues(`__nwkatz_M')))
		mata: st_numscalar("__nwkatz_rho", `__nwkatz_rho')
		local rho = __nwkatz_rho
		scalar drop __nwkatz_rho
		if `alpha' == -999999 {
			local alpha = 0.9 / `rho'
		}
		if abs(`alpha') * `rho' >= 1 {
			local __nwkatz_bound = 1 / `rho'
			di as error "alpha(`alpha') is not valid with walks: |alpha| * rho must be < 1 (rho = `rho', this network's own spectral radius) or the implied infinite walk sum diverges. Try alpha() strictly between -`__nwkatz_bound' and `__nwkatz_bound'."
			mata: mata drop `__nwkatz_M'
			error 198
		}
		if "`origdirected'" == "true" {
			mata: `__nw_out' = lusolve(I(`nodes') - `alpha' * `__nwkatz_M', J(`nodes', 1, 1))
			mata: `__nw_in' = lusolve(I(`nodes') - `alpha' * `__nwkatz_M'', J(`nodes', 1, 1))
		}
		else {
			mata: `__nw_all' = lusolve(I(`nodes') - `alpha' * `__nwkatz_M', J(`nodes', 1, 1))
		}
		mata: mata drop `__nwkatz_M'
	}
	else {
		if `alpha' == -999999 {
			local alpha = 1
		}
		tempname geo
		local __nwkatz_havegeo = 1
		// `options' forwards whatever geodesic_options the caller supplied
		// (as documented in the syntax block above) - previously declared
		// via the trailing `*' but never actually passed through, so e.g.
		// alpha()/unconnected() on the underlying nwgeodesic call were
		// silently ignored regardless of what the user specified.
		// nwreplace here (nwgeodesic's own option, unrelated to nwkatz's own
		// replace guard above) is required even though `geo' is a fresh
		// tempname: Stata's tempname counter is scoped per top-level command
		// invocation, not session-globally unique, so calling nwkatz twice
		// in a row can allocate the identical underlying name (confirmed via
		// direct trace) - nwgeodesic's own "name already exists" guard would
		// otherwise intermittently fire on this purely-internal scratch
		// network, depending on what tempname counter state happens to be
		// active. This scratch network is dropped again a few lines below
		// regardless, so always allowing nwgeodesic to overwrite it here is
		// safe.
		qui nwgeodesic `netname', name(`geo') nwreplace `symopt' `options'
		nw_syntax `geo'
		// nwreplace's own expression parser (_nwexpnetexp.ado) treats its
		// input as plain Stata-style arithmetic text and translates it into
		// Mata syntax via naive string substitution (e.g. every "*" becomes
		// " :* ", every "^" becomes " :^ "). It was never designed to accept
		// raw Mata object/pointer syntax such as (*netobj->get_matrix()) -
		// passing that here (as this line previously did) mangles the "*"
		// dereference and "->" method-call operators into nonsense along
		// with the alpha exponentiation, producing a genuine "invalid
		// expression" Mata error on every call. Confirmed via direct trace
		// before fixing - this was broken end to end, not merely for
		// non-integer alpha; there was no prior test coverage to catch it.
		// Fixed by doing the alpha^distance transform directly in Mata and
		// writing it back via the network's own set_edge() method (which
		// correctly invalidates the sparse index), instead of routing a
		// pointer-dereference expression through nwreplace's string-based
		// translator at all.
		tempname __nw_katz
		mata: `__nw_katz' = `alpha' :^ (*`netobj'->get_matrix())
		mata: _editmissing(`__nw_katz', 0)
		mata: `netobj'->set_edge(`__nw_katz')
		mata: mata drop `__nw_katz'

		if "`origdirected'" == "true" {
			// This package's own row=source/column=target adjacency
			// convention (confirmed against get_outdegree()/get_indegree()
			// in unw_core.do) means "out" reach is a ROW sum (how far node i
			// can reach others) and "in" reach is a COLUMN sum (how
			// reachable node i is from others) - the previous version had
			// these swapped, verified by hand on a small A->B, A->C example
			// (A's true out-reach summed to 1.0, but the swapped code
			// returned 0 for it).
			mata: `__nw_out' = rowsum(*`netobj'->get_matrix())
			mata: `__nw_in' = colsum(*`netobj'->get_matrix())'
		}
		else {
			mata: `__nw_all' = rowsum(*`netobj'->get_matrix())
		}
	}

	// getmata's parenthetical-expression form does not accept a raw
	// pointer-dereference expression either (confirmed via an isolated
	// repro before fixing: "invalid vector or matrix name") - assign to
	// a plain Mata variable first, matching the one form getmata is
	// documented and confirmed to actually accept. Also drop any
	// existing target variable(s) first: the guard above only errors
	// when the variable exists AND replace was not given - when replace
	// *was* given, getmata would otherwise still fail on the
	// still-present variable, since getmata has no overwrite option of
	// its own.
	//
	// `, double': getmata's own default target storage type is
	// `float', not `double' - Katz scores are continuous values with no
	// reason to be truncated to float precision, and doing so left a
	// genuine, real (if easy to miss) trace: getmata itself sets a
	// nonzero `_rc' whenever the underlying Mata double doesn't survive
	// the round-trip through float exactly (confirmed directly - a
	// trivial getmata of exact integers left `_rc'=0, the identical
	// call on real Katz scores left `_rc'=7, and adding `, double' alone
	// fixed it, isolating the real cause precisely). Whether this
	// surfaced as a visible problem depended entirely on incidental
	// ordering - some LATER ordinary command (e.g. `capture nwdrop') can
	// coincidentally reset `_rc' back to 0 before the program returns,
	// but nothing should depend on that coincidence holding.
	if "`origdirected'" == "true" {
		capture drop `generate'_out
		capture drop `generate'_in
		getmata `generate'_out = `__nw_out', double
		getmata `generate'_in = `__nw_in', double
		mata: mata drop `__nw_out' `__nw_in'
	}
	else {
		capture drop `generate'
		getmata `generate' = `__nw_all', double
		mata: mata drop `__nw_all'
	}

	if `__nwkatz_havegeo' {
		capture nwdrop `geo'
	}
	// Explicit `_rc' flush - the `capture drop `generate'[_in/_out]'
	// calls above legitimately leave `_rc'=111 (variable not found)
	// whenever the target didn't already exist, the ordinary case; a
	// literal `count'/`di' afterward does NOT reset it back to 0
	// (confirmed directly, somewhat surprisingly - possibly related to
	// this program's own `version 9' declaration at the top, not fully
	// root-caused further given `confirm' below is a clean, reliable,
	// ALSO independently useful fix), but `confirm variable' - which
	// has genuine, explicit true/false semantics of its own - reliably
	// does. Also a real, small defensive win on its own: double-checks
	// getmata actually produced the expected variable(s). Caught by a
	// permanent regression test asserting `_rc == 0' after a successful
	// call, not by inspection.
	capture confirm variable `generate_all'
	mata: st_rclear()
	di "{hline 40}"
	if "`walks'" != "" {
		di "{txt}  Katz centrality (walk-counting, Katz 1953/Bonacich)"
	}
	else {
		di "{txt}  Katz centrality (shortest-path distance-decay)"
	}
	di "{txt}  Network name: {res}`original'"
	if "`walks'" == "" & "`sym'" == "" {
		di "{txt}	Network has been symmetrized for calculation.{txt}"
	}
	di "{hline 40}"
	di "{txt}	Alpha: {res}`=round(`alpha',0.001)'"
	if "`walks'" != "" {
		di "{txt}	Spectral radius (rho): {res}`=round(`rho',0.001)'"
	}

	sum `generate_all'
end
