
capture program drop nwbalance
program nwbalance
	version 9
	syntax [anything(name=netname)] [, generate(string)]
	set more off
	
	// BUGFIX: word 2/word 3 were swapped relative to both the .sthlp's
	// own documented namelist order (ratio, balanced count, closed
	// count) and the two locals' own hardcoded defaults just below
	// (_baltriad is word 2's default, _clotriad is word 3's default) - a
	// custom 3-name generate() list silently put the closed-triad count
	// into the user's "balanced" variable and vice versa.
	local balance : word 2 of `generate'
	local closed : word 3 of `generate'
	local B : word 1 of `generate'
	if "`closed'" == "" {
		local closed "_clotriad"
	}
	if "`balance'" == "" {
		local balance = "_baltriad"
	}
	if "`B'" == "" {
		local B = "_balance"
	}


	unw_defs
	_nwsyntax `netname', max(1)
	_nwdatasync `netname'
	local original "`netname'"

	// PERFORMANCE/CORRECTNESS FIX: this command used to implement its own
	// independent Stata-level nwtoedge/reshape-wide/reshape-long x2/merge
	// m:m x2 pipeline here to enumerate every closed triad. It was
	// confirmed (alpha-audit critical finding) to be outright broken for
	// directed networks - silently missing obviously-closed triads
	// entirely in some structures (e.g. a directed 3-cycle) and producing
	// non-integer triad counts in others (e.g. a complete tournament) -
	// and separately crashed with a raw "n not found -- data already
	// wide" error on any network with zero ties at all, since the empty
	// edge list broke the reshape chain before the (already-present)
	// zero-closed-triads guard could ever run. calculate_balance() in
	// unw_core.do now implements the identical computation natively in
	// Mata via sparse has_edge()/edge_weight() enumeration (one pass per
	// unordered triple, i<j<k, visited exactly once) - correct for both
	// directed and undirected networks by construction, and naturally
	// returns an all-zero result for a zero-tie network with no special
	// casing needed. See that function's own header comment for the
	// documented directed-network "tied in some direction" convention.
	capture drop `B'
	capture drop `balance'
	capture drop `closed'
	qui gen `balance' = .
	qui gen `closed' = .

	qui if _N < `nodes' {
		set obs `nodes'
	}
	_nwsyntax `netname'

	tempname __nw_bal
	mata: `__nw_bal' = `netobj'->calculate_balance()
	mata: st_store((1::`nodes'), ("`closed'","`balance'"), `__nw_bal')
	mata: mata drop `__nw_bal'

	qui gen `B' = `balance' / `closed'

	qui sum `closed'
	local r1 = r(sum) / 3
	qui sum `balance'
	local r2 = r(sum) / 3
	mata: st_rclear()
	mata: st_numscalar("r(closed_triad)", `r1')
	mata: st_numscalar("r(balanced_triad)", `r2')
	mata: st_numscalar("r(unbalanced_triad)", `=`r1' - `r2'')
	mata: st_numscalar("r(balance)", `=`r2' / `r1'')

	noi di "{hline 40}"
	noi di "{txt}  Network name: {res}`netname'"
	noi di "{hline 40}"
	noi di "{txt}    Closed triad: {res}`r(closed_triad)'"
	noi di "{txt}    Balanced triad: {res}`r(balanced_triad)'"
	noi di "{txt}    Unbalanced triad: {res}`r(unbalanced_triad)'"

end
