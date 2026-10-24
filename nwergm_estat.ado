
capture program drop nwergm_estat
program define nwergm_estat, rclass
	gettoken subcmd rest : 0, parse(" ,")
	local subcmd = lower(trim("`subcmd'"))
	if "`subcmd'" == "mcmcdiag" {
		nwergm_estat_mcmcdiag `rest'
		return add
		capture noisily _nwergm_mcdiag
		capture return add
	}
	else if "`subcmd'" == "gof" {
		nwergm_estat_gof `rest'
		return add
	}
	else if "`subcmd'" == "ic" {
		nwergm_estat_ic
		return add
	}
	else {
		di as err "estat `subcmd' not allowed after nwergm"
		exit 321
	}
end

capture program drop nwergm_estat_mcmcdiag
program define nwergm_estat_mcmcdiag, rclass
	syntax [, PLOT NAME(string) PVALUE(real 0.05) EPS(real 0.1)]

	if `"`e(cmd)'"' != "nwergm" {
		di as err "last nwergm estimates not found"
		exit 301
	}
	if `"`e(method)'"' != "mcmle" {
		di as err "{bf:estat mcmcdiag} is only available after {bf:method(mcmle)} - MPLE fits involve no MCMC simulation."
		exit 498
	}
	// harmonisation unit 154: e(mcmcsample) is now optional (nwergm's
	// own nomcmcsample) - a clear, specific error here beats letting
	// the st_matrix() read a few lines below fail with a generic
	// "matrix not found".
	capture confirm matrix e(mcmcsample)
	if _rc {
		di as err "{bf:estat mcmcdiag} needs {bf:e(mcmcsample)}, which the preceding {bf:nwergm} call did not post (it was run with {bf:nomcmcsample}). Refit without {bf:nomcmcsample} to use {bf:estat mcmcdiag}."
		exit 498
	}

	// Heidelberger-Welch's own critical value, resolved from the fixed
	// 4-level table this file's own header comment (above
	// ergm_heidel_diag() in unw_ergm.do) derives directly from coda's
	// real pcramer() via uniroot() - see that comment for why this is
	// exactly equivalent to coda::heidel.diag's own continuous p-value
	// test at each of these four standard levels, not an approximation.
	if `pvalue' == 0.10 local __ergm_hwcrit = 0.3473049202
	else if `pvalue' == 0.05 local __ergm_hwcrit = 0.4613612936
	else if `pvalue' == 0.025 local __ergm_hwcrit = 0.5806146822
	else if `pvalue' == 0.01 local __ergm_hwcrit = 0.7434593138
	else {
		di as err "{bf:pvalue()} must be one of 0.10, 0.05, 0.025, or 0.01 - the Heidelberger-Welch stationarity test is evaluated against a fixed table of Cramer-von-Mises critical values (see unw_ergm.do's own header comment on ergm_heidel_diag() for why), not a continuously computed p-value."
		exit 198
	}

	tempname bmat
	matrix `bmat' = e(b)
	local p = colsof(`bmat')
	local names : colnames `bmat'

	tempname samp
	mata: `samp' = st_matrix("e(mcmcsample)")

	di
	di as txt "MCMC diagnostics for the final simulation (nwergm, method(mcmle))"
	di as txt "Sample size:{col 22}={res}  " %6.0f e(mcmc_samplesize)
	di as txt "Burn-in:{col 22}={res}  " %6.0f e(mcmc_burnin)
	di as txt "Thinning interval:{col 22}={res}  " %6.0f e(mcmc_interval)
	di as txt "Acceptance rate:{col 22}={res}  " %6.4f e(mcmc_acceptrate)
	di
	tempname __essm
	matrix `__essm' = J(1, `p', .)
	matrix colnames `__essm' = `names'
	di as txt "{hline 16}{c TT}{hline 11}{hline 11}{hline 12}{hline 9}"
	di as txt %-16s "Statistic" "{c |}" %10s "Mean" %11s "SD" %12s "Autocorr" %9s "ESS"
	di as txt "{hline 16}{c +}{hline 11}{hline 11}{hline 12}{hline 9}"
	forvalues k = 1/`p' {
		local nm : word `k' of `names'
		mata: st_local("__ergm_mn", strofreal(mean(`samp'[.,`k'])))
		mata: st_local("__ergm_sd", strofreal(sqrt(variance(`samp'[.,`k']))))
		mata: st_local("__ergm_rho", strofreal(ergm_lag1_autocorr(`samp')[`k']))
		// ESS as coda::effectiveSize(): n*var(x)/spectrum0.ar(x), the
		// spectral density at 0 from an AR(p) fit (ergm_spec0_scalar()).
		// The lag-1 formula n(1-rho)/(1+rho) used before assumed geometric
		// decay and overstated ESS severalfold for slowly mixing chains.
		mata: __ergm_essx = `samp'[.,`k'] :- mean(`samp'[.,`k'])
		mata: __ergm_esss = ergm_spec0_scalar(__ergm_essx)
		mata: st_local("__ergm_ess", strofreal(__ergm_esss > 0 ? rows(__ergm_essx)*variance(__ergm_essx)/__ergm_esss : 0))
		capture mata: mata drop __ergm_essx __ergm_esss
		matrix `__essm'[1, `k'] = `__ergm_ess'
		di as txt %-16s "`nm'" "{c |}" as res %10.4f `__ergm_mn' %11.4f `__ergm_sd' %12.4f `__ergm_rho' %9.1f `__ergm_ess'
	}
	di as txt "{hline 16}{c BT}{hline 11}{hline 11}{hline 12}{hline 9}"
	di

	// Formal convergence diagnostics (harmonisation unit 144): the two
	// coda-package tests behind R ergm's own mcmc.diagnostics() - see
	// unw_ergm.do's own header comment above ergm_geweke_z()/
	// ergm_heidel_diag() for the full port account (ported directly from
	// coda's real current source, cross-certified against real coda
	// output on synthetic reference series - cscripts/test_nwergm_mcmcdiag.do).
	tempname __gew __hd
	mata: st_matrix("`__gew'", ergm_geweke_z(`samp'))
	mata: st_matrix("`__hd'", ergm_heidel_diag(`samp', `__ergm_hwcrit', `eps'))
	tempname __gew_m __hd_m
	mata: `__gew_m' = st_matrix("`__gew'")
	mata: `__hd_m' = st_matrix("`__hd'")

	di as txt "Geweke diagnostic (first 10% vs. last 50% of the retained sample):"
	di as txt "{hline 16}{c TT}{hline 11}{hline 11}"
	di as txt %-16s "Statistic" "{c |}" %10s "z" %10s "p-value"
	di as txt "{hline 16}{c +}{hline 11}{hline 11}"
	forvalues k = 1/`p' {
		local nm : word `k' of `names'
		mata: st_local("__ergm_gz", strofreal(`__gew_m'[1,`k']))
		mata: st_local("__ergm_gp", strofreal(2*(1-normal(abs(`__gew_m'[1,`k'])))))
		if abs(`__ergm_gz') > 1.96 {
			di as txt %-16s "`nm'" "{c |}" as err %10.3f `__ergm_gz' %10.4f `__ergm_gp' "  *"
		}
		else {
			di as txt %-16s "`nm'" "{c |}" as res %10.3f `__ergm_gz' %10.4f `__ergm_gp'
		}
	}
	di as txt "{hline 16}{c BT}{hline 11}{hline 11}"
	di as txt "Note: |z| > 1.96 (flagged {bf:*}) rejects convergence of that parameter's own chain at the 5% level (Geweke 1992) - a large systematic difference between the retained sample's own early and late portions, not proof either way for a borderline z."
	di

	di as txt "Heidelberger-Welch stationarity + halfwidth test (pvalue=`pvalue', eps=`eps'):"
	di as txt "{hline 16}{c TT}{hline 12}{hline 10}{hline 12}{hline 11}"
	di as txt %-16s "Statistic" "{c |}" %11s "Stationary" %9s "Start" %11s "Halfwidth" %10s "HW test"
	di as txt "{hline 16}{c +}{hline 12}{hline 10}{hline 12}{hline 11}"
	forvalues k = 1/`p' {
		local nm : word `k' of `names'
		mata: st_local("__ergm_hstest", strofreal(`__hd_m'[`k',1]))
		if `__ergm_hstest' == 1 {
			mata: st_local("__ergm_hstart", strofreal(`__hd_m'[`k',2]))
			mata: st_local("__ergm_hhw", strofreal(`__hd_m'[`k',6]))
			mata: st_local("__ergm_hhtest", strofreal(`__hd_m'[`k',4]))
			local __ergm_httext = cond(`__ergm_hhtest'==1, "passed", "failed")
			di as txt %-16s "`nm'" "{c |}" as res %11s "passed" %9.0f `__ergm_hstart' %11.4f `__ergm_hhw' %10s "`__ergm_httext'"
		}
		else {
			di as txt %-16s "`nm'" "{c |}" as err %11s "FAILED" %9s "-" %11s "n/a" %10s "n/a"
		}
	}
	di as txt "{hline 16}{c BT}{hline 12}{hline 10}{hline 12}{hline 11}"
	di as txt "Note: {bf:Stationary} = passed a Cramer-von-Mises test on the chain's own cumulative-sum path (Heidelberger & Welch 1983), discarding an increasing initial fraction (up to 50%) until it does - {bf:Start} is the first retained iteration once it passes, {bf:FAILED} means no discard fraction achieved stationarity. {bf:HW test} additionally requires the retained portion's own 95% CI halfwidth to be within {bf:eps()} (default 10%) of its own mean - a separate, stricter precision check, only meaningful once stationarity itself has passed."
	di

	return matrix ess = `__essm'
	return matrix geweke = `__gew'
	return matrix heidel = `__hd'

	if e(converged) == 1 {
		di as txt "MCMLE's own convergence test was satisfied after " %3.0f e(mcmle_iterations) " iteration(s)."
	}
	else {
		di as err "Warning: MCMLE did NOT satisfy its own convergence test - treat these diagnostics, and the fitted coefficients, with caution."
	}
	di as txt "Note: a satisfied convergence test is a necessary check, not proof of a converged fit - inspect the autocorrelation/ESS above, and consider increasing {bf:mcmcsamplesize()}/{bf:mcmleiterations()} if acceptance rate or ESS looks poor."

	return scalar acceptrate = e(mcmc_acceptrate)

	if "`plot'" != "" {
		if "`name'" == "" {
			local name "mcmcdiag"
		}
		tempvar drawidx
		tempname sampmat
		matrix `sampmat' = e(mcmcsample)
		preserve
		qui drop _all
		// e(b)'s own column names ("gwesp_.5" for a term like
		// gwesp(.5)) are not legal Stata variable names (a period is
		// not a legal variable-name character), so loaded as plain,
		// sequentially named mcmcv1/mcmcv2/... variables instead; the
		// real term name is used only in plot titles/axis labels,
		// where it is just text, never a variable reference.
		qui svmat double `sampmat', names(mcmcv)
		qui gen `drawidx' = _n
		local __combine_list ""
		forvalues k = 1/`p' {
			local nm : word `k' of `names'
			tempname tr`k' de`k'
			qui twoway line mcmcv`k' `drawidx', ///
				name(`tr`k'', replace) ///
				title("`nm': trace", size(small)) ///
				xtitle("MCMC draw") ytitle("") ///
				legend(off) nodraw
			// ERGM sufficient statistics (edge counts, shared-partner
			// counts, ...) are integer-valued and often take few
			// distinct values over an MCMC run on a small network -
			// `kdensity's own default (Silverman-rule) bandwidth is
			// tuned for continuous data and visibly under-smooths
			// this kind of sparse/discrete support, producing a
			// spurious multi-modal "wiggle" that has nothing to do
			// with the actual sampling distribution. Widened by a
			// fixed multiplier on top of Stata's own default rather
			// than a from-scratch bandwidth rule - good enough to
			// suppress the artifact without materially oversmoothing
			// a genuinely continuous statistic's own density.
			qui kdensity mcmcv`k', nograph
			local __bw = 3 * r(bwidth)
			qui twoway kdensity mcmcv`k', bwidth(`__bw') ///
				name(`de`k'', replace) ///
				title("`nm': density", size(small)) ///
				xtitle("`nm'") ytitle("") ///
				legend(off) nodraw
			local __combine_list `"`__combine_list' `tr`k'' `de`k''"'
		}
		graph combine `__combine_list', cols(2) ///
			title("MCMC diagnostics: trace and density per statistic", size(medium)) ///
			name(`name', replace)
		foreach __g of local __combine_list {
			capture graph drop `__g'
		}
		restore
		di as txt "(plot saved as {bf:`name'}; each row is one model statistic's MCMC trace and density from the final simulation)"
	}

	mata: mata drop `samp'
	// BUGFIX (real fix, verified - this comment previously concluded no
	// fix was possible; that conclusion was itself wrong, corrected here):
	// a stale nonzero `_rc' from an earlier internal `capture' (of which
	// this program, like nwergm_estat_gof above it, has several - e.g.
	// around `graph drop' inside the `plot' block) persists through any
	// ORDINARY subsequent command, success or not - confirmed directly by
	// isolated probe that `local'/`di'/`qui summarize'/a bare `mata:' line
	// all leave a prior failed-capture's `_rc' completely untouched. What
	// actually resets it: wrapping a command that can never fail in
	// `capture' itself - `capture' explicitly manages `_rc' as part of
	// its own contract, which an uncaptured command does not. The
	// earlier "trailing harmless `local'" fix attempt failed for exactly
	// this reason (no `capture' wrapper), not because the underlying
	// problem is unfixable.
	capture qui local __nwergm_estat_rcreset = 1
end

capture program drop nwergm_estat_gof
program define nwergm_estat_gof, rclass
	_nwergm_gof `0'
	return add
end


/*
	Own copy of nwergm.ado's own ergm_bridge_from_netobj() (identical
	logic, distinct name). Found by direct trial that Mata functions
	defined at a DIFFERENT .ado file's own file scope do not reliably
	remain callable from a SEPARATE .ado file's own later, separate
	auto-load event, even after that first file's own command has
	already run successfully in the same session (confirmed: right
	after a successful `nwergm mynet, edges' call - which itself
	internally calls ergm_bridge_from_netobj() - a direct
	`mata: mata query'/`capture mata: mata which ergm_bridge_from_netobj()'
	check from the SAME session shows it no longer resolvable; it IS
	reliably available from a `run nwergm.ado' - as opposed to normal
	command auto-load - which is why this was missed until a plain
	cscript-style dev-mode test, not an ad hoc scratch script using
	`run', first exercised it). Each `.ado' file that needs this bridge
	must define its own copy at its own file scope, exactly like
	nwergm.ado's own copy - this is not a case of unwanted duplication,
	it is the same established, working pattern applied per-file.
*/
capture mata: mata drop nwergm_estat_bridge_from_netobj()
mata:
void nwergm_estat_bridge_from_netobj(pointer(class nw_def scalar) scalar netobj,
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

// GOF-plot support (estat gof, plot): full degree and geodesic-distance
// DISTRIBUTIONS, not just the summary means the plain (non-plot) table
// above reports - the Statnet plot.gof() analogue. Computed directly in
// Mata from the same dense adjacency matrix already built for both the
// observed and each simulated draw, rather than round-tripping each
// draw through nwset/nwgeodesic/nwtriads again (as the summary-table
// code above does for a single mean) - nsim() draws x a full BFS each
// would otherwise mean nsim() more nw_def object creations per plot,
// pure overhead for a plot that only ever needed the raw distances.
capture mata: mata drop ergm_gof_degdist()
capture mata: mata drop ergm_gof_geodist()
mata:
real rowvector ergm_gof_degdist(real matrix M, real scalar maxdeg) {
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

real rowvector ergm_gof_geodist(real matrix M, real scalar maxdist) {
	// Unweighted BFS from every node on the 0/1 adjacency matrix M
	// (symmetric for undirected). counts[1..maxdist] = proportion of
	// ordered pairs i!=j at that exact distance; counts[maxdist+1] =
	// unreached (including disconnected) pairs - the "NR" category
	// Statnet's own gof plot shows as its own final bar.
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

// Per-column (min, p25, median, p75, max) across simulated draws, via a
// plain nearest-rank method on the sorted column - not a claim to match
// any particular textbook quantile convention exactly (R's boxplot() and
// Stata's own `summarize, detail' each use their own), just enough to
// draw a representative box/whisker range for a visual GOF comparison.
real matrix ergm_gof_summary5(real matrix draws) {
	real scalar ncol, nrow, k, i
	real colvector col
	real matrix out

	nrow = rows(draws)
	ncol = cols(draws)
	out = J(ncol, 5, .)
	for (k=1; k<=ncol; k++) {
		col = sort(draws[.,k], 1)
		out[k,1] = col[1]
		out[k,2] = col[ceil(0.25*nrow)]
		out[k,3] = col[ceil(0.50*nrow)]
		out[k,4] = col[ceil(0.75*nrow)]
		out[k,5] = col[nrow]
	}
	return(out)
}
end


capture program drop nwergm_estat_ic
program define nwergm_estat_ic, rclass
	if missing(e(ll)) {
		di as err "no log-likelihood was stored for this fit (it was fitted with the nologlik option)"
		exit 498
	}
	tempname M
	matrix `M' = (e(N), e(ll_0), e(ll), e(df_m), e(aic), e(bic))
	matrix colnames `M' = N ll(null) ll(model) df AIC BIC
	matrix rownames `M' = `e(depvar)'
	di
	di as txt "Akaike's information criterion and Bayesian information criterion"
	di
	di as txt "{hline 13}{c TT}{hline 63}"
	di as txt %12s "Model" " {c |}" %9s "N" %13s "ll(null)" %13s "ll(model)" %6s "df" %10s "AIC" %10s "BIC"
	di as txt "{hline 13}{c +}{hline 63}"
	di as txt %12s abbrev("`e(depvar)'", 12) " {c |}" as res %9.0g e(N) %13.5g e(ll_0) %13.5g e(ll) %6.0f e(df_m) %10.5g e(aic) %10.5g e(bic)
	di as txt "{hline 13}{c BT}{hline 63}"
	di as txt "Note: BIC uses N = number of informative dyads; MC std. err. of the log-likelihood = " as res %7.5g e(ll_se)
	return matrix S = `M'
end
