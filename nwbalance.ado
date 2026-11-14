
capture program drop nwbalance
program nwbalance
	version 9
	syntax [anything(name=netname)] [, generate(string) reps(integer 0) seed(string)]
	set more off
	if `reps' < 0 {
		di "{err}reps() must be 0 or a positive number of draws."
		exit 198
	}
	
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

	// 3.20.1: reps() compares the share of balanced triads with random signs on the same ties: every tie
	// keeps its place and is positive with the observed share of positive ties as probability,
	// independently of the others
	if `reps' > 0 {
		if `r1' == 0 {
			noi di "{txt}  No closed triads: there is nothing to compare with random signs."
			exit
		}
		local obsbal = `r2' / `r1'
		if "`seed'" != "" set seed `seed'
		nwtomatafast `netname'
		local srcmata "`r(mata)'"
		tempname nul
		mata: `nul' = nw_balance_null(`srcmata', `reps', `obsbal')
		mata: st_local("ppos", strofreal(`nul'[1], "%18.0g"))
		mata: st_local("nmean", strofreal(`nul'[2], "%18.0g"))
		mata: st_local("nsd", strofreal(`nul'[3], "%18.0g"))
		mata: st_local("nge", strofreal(`nul'[4], "%18.0g"))
		mata: mata drop `nul'
		local expect = (1 + (2 * `ppos' - 1)^3) / 2
		mata: st_rclear()
		mata: st_numscalar("r(closed_triad)", `r1')
		mata: st_numscalar("r(balanced_triad)", `r2')
		mata: st_numscalar("r(unbalanced_triad)", `=`r1' - `r2'')
		mata: st_numscalar("r(balance)", `obsbal')
		mata: st_numscalar("r(reps)", `reps')
		mata: st_numscalar("r(p_positive)", `ppos')
		mata: st_numscalar("r(null_mean)", `nmean')
		mata: st_numscalar("r(null_sd)", `nsd')
		mata: st_numscalar("r(null_ge)", `nge')
		mata: st_numscalar("r(null_expected)", `expect')
		noi di "{hline 40}"
		noi di "{txt}  Random signs on the observed ties, `reps' draws"
		noi di "{txt}    Share of ties positive:    {res}" %6.3f `ppos'
		noi di "{txt}    Share balanced, observed:  {res}" %6.3f `obsbal'
		noi di "{txt}    Share balanced, random:    {res}" %6.3f `nmean' "{txt}  (sd {res}" %5.3f `nsd' "{txt})"
		noi di "{txt}    Expected by formula:       {res}" %6.3f `expect'
		noi di "{txt}    Draws at least as balanced: {res}`nge'{txt} of `reps'"
	}

end

capture mata: mata drop nw_balance_null()
mata:
// random signs on the ties of a signed network: returns (share of ties positive, mean and sd of the
// share of balanced closed triads over the draws, number of draws with a share >= obs). A pair is tied
// when either direction is; its sign is that of i->j if present, else of j->i (as in nwbalance).
real rowvector nw_balance_null(real matrix A0, real scalar reps, real scalar obs)
{
	real matrix A, V, E, T
	real scalar n, i, j, ne, nt, r, p
	real colvector k, sg, s, b

	n = rows(A0)
	A = editmissing(A0, 0)
	_diag(A, 0)
	V = A + (A :== 0) :* A'
	E = J(n, n, 0)
	ne = 0
	sg = J(0, 1, .)
	for (i = 1; i < n; i++) {
		for (j = i + 1; j <= n; j++) {
			if (V[i, j] != 0) {
				ne++
				E[i, j] = ne
				E[j, i] = ne
				sg = sg \ (V[i, j] > 0)
			}
		}
	}
	p = mean(sg)
	T = J(0, 3, .)
	for (i = 1; i < n - 1; i++) {
		for (j = i + 1; j < n; j++) {
			if (!E[i, j]) continue
			k = select(((j + 1)::n), (E[(j + 1)::n, i] :> 0) :& (E[(j + 1)::n, j] :> 0))
			if (length(k)) T = T \ (J(rows(k), 1, E[i, j]), E[k, i], E[k, j])
		}
	}
	nt = rows(T)
	b = J(reps, 1, .)
	for (r = 1; r <= reps; r++) {
		s = 2 :* (runiform(ne, 1) :< p) :- 1
		b[r] = mean((s[T[., 1]] :* s[T[., 2]] :* s[T[., 3]]) :> 0)
	}
	return((p, mean(b), (reps > 1 ? sqrt(variance(b)) : 0), sum(b :>= obs - 1e-12)))
}
end
