*! Date        : 24aug2014
*! Version     : 1.0.4
*! Author      : Thomas Grund, Linkoping University
*! Email	   : thomas.u.grund@gmail.com

* Calculates actor closeness centrality according to Sabidussi (1966)
* See Wassermann & Faust (1994, p. 184)

capture program drop nwcloseness
program nwcloseness
	version 9
	// BUGFIX: `nosym' used to fall through the trailing `*' catch-all
	// straight into the internal nwgeodesic call - but nwgeodesic's own
	// real toggle is opt-IN `sym' (default: never symmetrize), so
	// forwarding `nosym' (a negation of an option that was never
	// enabled to begin with) was a pure no-op - nwcloseness's default
	// output and its own documented "nosym" opt-out were identical, and
	// this package's own documented default ("the network is otherwise
	// symmetrized... unless nosym is specified") never actually
	// happened; true symmetrized results were only reachable via the
	// entirely undocumented `sym' geodesic option.
	//
	// Declaring `nosym' in the syntax line makes Stata's own parser
	// define a local named after the STEM - `sym', not `nosym' - set
	// to the literal string "nosym" when the caller passes the option,
	// empty otherwise (`nosym' itself is never populated at all) - the
	// same convention nwbetween.ado's own identical symmetrize-by-
	// default toggle already uses (see its own comment for the same
	// finding). Confirmed directly with an isolated minimal repro
	// before trusting this (an initial attempt here mistakenly checked
	// `nosym' itself, always empty, before catching the error and
	// fixing it to check `sym' instead, matching nwbetween's own
	// working pattern exactly).
	syntax [anything(name=netname)] [, GENerate(string) nosym replace *]
	if "`sym'" == "" {
		local symopt "sym"
	}
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname', max(9999)
	
	if `networks' > 1 {
		local k = 1
	}
	_nwsetobs `netname'
	
	// BUGFIX: generate() silently fell back to the hardcoded default
	// names whenever it didn't contain exactly 3 words - a caller
	// supplying 1 or 2 names (a plausible attempt to just rename the
	// closeness variable) got no error and their requested name was
	// never created. Now errors clearly instead of silently discarding
	// it.
	local gencount : word count `generate'
	if (`gencount' != 0 & `gencount' != 3) {
		di "{err}Option {bf:generate()} needs exactly 3 names (closeness, farness, nearness); got `gencount'."
		error 198
	}
	if (`gencount' == 0) {
		local generate = "_closeness _farness _nearness"
	}
	local generate_all ""
	
	set more off
	qui foreach netname_temp in `netname' {
		preserve
		qui nwgeodesic `netname_temp', name(_tempgeodesic) `symopt' `options'
		nwname _tempgeodesic
		// PERFORMANCE FIX: nwtomata's own mat() option copies the network's
		// full n x n matrix into a second, separately-named Mata matrix
		// (confirmed via direct source inspection of _nwtomata.ado:
		// `mat' = (*`netobj'->get_matrix())`, an unavoidable full copy for
		// a NAMED handle) purely so that copy can immediately be handed to
		// min()/rowsum() and discarded - both of those are read-only
		// reductions that work identically on a dereferenced pointer
		// directly, with no copy needed at all. Same accessor
		// (`netobj'->get_matrix()) as nwtomata used internally, same
		// values, only the redundant intermediate copy is removed -
		// verified byte-identical against the prior nwtomata-based version
		// in cscripts/test_nwcloseness.do.
		nw_syntax _tempgeodesic
		mata: st_numscalar("r(mindistance)", min(*`netobj'->get_matrix()))
		mata: far = rowsum(*`netobj'->get_matrix())

		if `r(mindistance)' < 0 {
			mata: far = J(`nodes', 1, .)
			noi di "{txt}Warning: network {bf:`netname_temp'} not connected; specify {bf:unconnected()} to obtain results.
			nwdrop _tempgeodesic
			exit
		}
		
		nw_syntax `netname_temp'

		mata: nearness = J(`nodes', 1,1) :/ far
		mata: closeness = nearness :* (`nodes' - 1)
		local _closeness : word 1 of `generate'
		local _farness : word 2 of `generate'
		local _nearness : word 3 of `generate'
		nwdrop _tempgeodesic
		restore

		_nwsetobs `netname_temp'
		// _nwsetobs only ensures enough observations exist - it does
		// not align row i with node i of `netname_temp' specifically
		// (a real, separate bug found while adding netlist test
		// coverage: without this sync, st_store below wrote into
		// whatever rows happened to be there, silently misplacing
		// and even losing data for every network after the first).
		// _nwdatasync is this package's own established mechanism for
		// that alignment (see e.g. nwdegree's netlist support).
		tempvar included
		_nwdatasync `netname_temp', generate(`included')

		// BUGFIX: nwcloseness had no `replace' option and no
		// "already exists" guard at all, unlike every sibling command
		// in this group (nwdegree/nwbetween/nwevcent/nwkatz/nw2degree
		// all require explicit `replace' before overwriting an
		// existing output variable) - it always silently clobbered
		// _closeness/_farness/_nearness (or any generate() name) on
		// every call, with no warning.
		foreach c in `_closeness'`k' `_farness'`k' `_nearness'`k' {
			capture confirm variable `c', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`c'} already exists; use {bf:replace}"
				err 99
			}
		}

		qui capture drop `_closeness'`k'
		qui gen `_closeness'`k' = .
		qui capture drop `_farness'`k'
		qui gen `_farness'`k' = .
		qui capture drop `_nearness'`k'
		qui gen `_nearness'`k' =.
		
		mata: st_store((1::`nodes'),"`_closeness'`k'",closeness)
		mata: st_store((1::`nodes'),"`_farness'`k'",far)
		mata: st_store((1::`nodes'),"`_nearness'`k'",nearness)
	
		local generate_all "`generate_all' `_closeness'`k' `_farness'`k' `_nearness'`k'"
		capture drop `included'
		mata: mata drop closeness far nearness
		
		local k = `k' + 1	
	}
	mata: st_rclear()
	di "{hline 40}"
	di "{txt}  Network name: {res}`netname'"
	di "{hline 40}"
	di "{txt}    Closeness centrality"
	sum `generate_all'
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
