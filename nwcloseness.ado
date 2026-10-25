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
	syntax [anything(name=netname)] [, GENerate(string) nosym replace force silent BINary TWOmode legacy *]
	if "`sym'" == "" {
		local symopt "sym"
	}
	// _nwsyntax is a deprecated pure wrapper around _nwsyntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of _nwsyntax's other exports, so calling it
	// directly is a safe, direct simplification.
	_nwsyntax `netname', max(9999)
	
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
	// generate() is required (suite-wide generate()-required style
	// decision, 2026-09-05): nwcloseness's whole purpose is producing
	// these variables, so - matching Stata's own egen/predict convention
	// - there is no default name to silently fall back to.
	local gencount : word count `generate'
	if (`gencount' == 0) {
		di "{err}option {bf:generate()} required - needs exactly 3 names (closeness, farness, nearness)."
		error 198
	}
	if (`gencount' != 3) {
		di "{err}Option {bf:generate()} needs exactly 3 names (closeness, farness, nearness); got `gencount'."
		error 198
	}
	local generate_all ""
	
	set more off
	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		_nwtimeguard, command(nwcloseness) nodes(`nodes') model(bfs) netobj(`netobj') rate(6.6e8) alternative(Closeness needs one breadth-first search from every node. Compute it for a part of the network (nwsubset), or use nwdegree, nwpagerank or nwevcent, which scale to millions of ties.) `force'
		preserve
		// The farness of a node is the sum of its distances to the nodes it can reach. With a plugin of the current
		// generation it comes from one breadth-first search per node over the stored ties (kernel 25, O(nodes x ties),
		// no n x n matrix: 98 s and 6.4 GB at 20,000 nodes before); the distance matrix of nwgeodesic is still built
		// when geodesic_options are passed (alpha, unconnected, ...) or the plugin is older.
		local __fastcl 0
		// the hop-count kernel is the binary closeness: used when the network has no tie values or binary is given
		if `"`options'"' == "" & ("`binary'" != "" | "`valued'" == "false") {
			mata: st_local("__fastcl", strofreal(nwg_comb_version() >= 5))
		}
		if `__fastcl' {
			tempname __symnet
			local __src `netname_temp'
			if "`symopt'" != "" {
				nwsym `netname_temp', generate(`__symnet')
				local __src `__symnet'
			}
			_nwsyntax `__src'
			mata: reach = nw_distance_sums(`netobj', 0, 0)
			mata: far = reach[., 1]
			mata: reach = reach[., 2]
			if "`symopt'" != "" {
				nwdrop `__symnet'
			}
		}
		else {
			qui nwgeodesic `netname_temp', name(_tempgeodesic) `symopt' `binary' `options'
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
			_nwsyntax _tempgeodesic
			mata: st_numscalar("r(mindistance)", min(*`netobj'->get_matrix()))
			mata: far = rowsum(*`netobj'->get_matrix())

			// number of other nodes each node can reach (the diagonal of the
			// distance matrix is 0 or missing and is not counted)
			mata: reach = rowsum((*`netobj'->get_matrix()) :< .) :- (diagonal(*`netobj'->get_matrix()) :< .)
		}
		_nwsyntax `netname_temp'

		mata: nearness = J(`nodes', 1,1) :/ far
		// Closeness is the number of nodes a node can reach divided by
		// the sum of its distances to them (igraph's definition). On a
		// connected network that is (nodes - 1) * nearness; legacy keeps
		// (nodes - 1) * nearness whatever the connectedness.
		mata: st_local("__disc", strofreal(max(reach :< (`nodes' - 1))))
		if `__disc' & "`legacy'" == "" {
			mata: closeness = reach :/ far
		}
		else {
			mata: closeness = nearness :* (`nodes' - 1)
		}
		if `__disc' {
			if "`legacy'" == "" {
				local __how "uses only the nodes each node can reach (as igraph)"
			}
			else {
				local __how "is (nodes - 1) / farness and can exceed 1 (legacy)"
			}
			noi di "{txt}Warning: network {bf:`netname_temp'} is not connected; closeness `__how'. Specify {bf:unconnected()} to give missing paths a length."
		}
		if "`twomode'" != "" {
			// Borgatti and Everett (1997): the smallest possible farness of a node is reached when it is tied to every
			// node of the other mode (distance 1) and every other node of its own mode is at distance 2
			if "`is2mode'" != "true" {
				noi di "{err}Option {bf:twomode} needs a two-mode network; `netname_temp' is one-mode."
				error 198
			}
			mata: __md = strtoreal(`netobj'->get_modes())'; __n1 = sum(__md :== 1); __n2 = sum(__md :== 2); closeness = ((__md :== 1) :* (__n2 + 2 * (__n1 - 1)) :+ (__md :== 2) :* (__n1 + 2 * (__n2 - 1))) :* nearness
			mata: mata drop __md __n1 __n2
		}
		local _closeness : word 1 of `generate'
		local _farness : word 2 of `generate'
		local _nearness : word 3 of `generate'
		if !`__fastcl' {
			nwdrop _tempgeodesic
		}
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
		mata: mata drop closeness far nearness reach
		
		local k = `k' + 1	
	}
	mata: st_rclear()
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{hline 40}"
		di "{txt}    Closeness centrality"
		sum `generate_all'
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
