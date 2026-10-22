*! version 0.1.0 22oct2026 nwcommands: multi-group meta-analysis of separate nwsaom fits (RSiena's siena08)
/*
	nwsaom_meta -- combine the estimates of the same nwsaom model fitted to several networks (groups), as RSiena's siena08
	(Snijders & Baerveldt 2003): for every effect the IWLS random-effects mean, the t test, Fisher's combination of one-sided tests, the
	heterogeneity test, and the maximum likelihood mean and between-group standard deviation with profile-likelihood intervals.
	The fits are given as stored estimates (estimates store). Mata functions: unw_saom.do (SaomMeta*).
*/
program nwsaom_meta, rclass
	version 14
	syntax namelist(min=2) [, BOUND(real 10) ALPHA(real 0.05) MAXIT(integer 20) RATES NOTABLE]
	if `alpha' <= 0 | `alpha' >= 1 {
		di "{err}{bf:alpha()} must be between 0 and 1."
		error 198
	}
	local ng : word count `namelist'
	tempname B SE R b V names0
	local first 1
	local k 0
	foreach nm of local namelist {
		capture quietly estimates restore `nm'
		if _rc {
			di "{err}stored estimates {bf:`nm'} not found (use {bf:estimates store `nm'} after each {bf:nwsaom} fit)."
			error 111
		}
		matrix `b' = e(b)
		matrix `V' = e(V)
		local cn : colnames `b'
		local nb = colsof(`b')
		matrix `SE' = J(1, `nb', .)
		forvalues j = 1/`nb' {
			matrix `SE'[1, `j'] = sqrt(`V'[`j', `j'])
		}
		if "`rates'" != "" {
			capture confirm matrix e(rates)
			if !_rc {
				tempname rt
				matrix `rt' = e(rates)
				local np = colsof(`rt')
				forvalues j = 1/`np' {
					matrix `b' = `b', `rt'[1, `j']
					matrix `SE' = `SE', `rt'[2, `j']
					local cn "`cn' rate_period`j'"
				}
				local nb = colsof(`b')
			}
		}
		if `first' {
			matrix `B' = `b'
			matrix `R' = `SE'
			local names0 "`cn'"
			local nb0 = `nb'
			local first 0
		}
		else {
			if `nb' != `nb0' | "`cn'" != "`names0'" {
				di "{err}the fits must have the same effects in the same order; {bf:`nm'} differs from {bf:`: word 1 of `namelist''}."
				error 198
			}
			matrix `B' = `B' \ `b'
			matrix `R' = `R' \ `SE'
		}
	}
	tempname M
	mata: st_matrix("`M'", SaomMeta(st_matrix("`B'"), st_matrix("`R'"), `bound', `alpha', `maxit'))
	local rn ""
	foreach c of local names0 {
		local c = subinstr("`c'", ".", "_", .)
		local rn "`rn' `c'"
	}
	matrix rownames `M' = `rn'
	matrix colnames `M' = n_used corr corr_p iwls_mean iwls_se iwls_t iwls_p iwls_sd Tsq Tsq_p Q Q_p ml_mean ml_se mu_lo mu_hi ml_sd sd_lo sd_hi fisher_right fisher_right_p fisher_left fisher_left_p level
	if "`notable'" == "" {
		di
		di as text "Meta-analysis of {result:`ng'} fits (RSiena siena08): estimates with a standard error of at least " as result `bound' as text " are excluded"
		di as text "Tests of mean parameters use a t distribution with n-1 d.f. (n = number of included groups)."
		di
		di as text "{bf:IWLS estimates} (Snijders & Baerveldt 2003)"
		di as text "{hline 13}{c TT}{hline 66}"
		di as text %12s "effect" " {c |}" %4s "n" %10s "mean" %9s "s.e." %8s "t" %8s "p" %9s "sd" %9s "Q" %8s "p(Q)"
		di as text "{hline 13}{c +}{hline 66}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %4.0f `M'[`i', 1] %10.4f `M'[`i', 4] %9.4f `M'[`i', 5] %8.2f `M'[`i', 6] %8.3f `M'[`i', 7] %9.4f `M'[`i', 8] %9.2f `M'[`i', 11] %8.3f `M'[`i', 12]
		}
		di as text "{hline 13}{c BT}{hline 66}"
		di
		di as text "{bf:Maximum likelihood under normality} with " as result %3.0f 100*(1-`alpha') as text "% profile-likelihood intervals"
		di as text "{hline 13}{c TT}{hline 80}"
		di as text %12s "effect" " {c |}" %9s "mean" %9s "s.e." %10s "lower" %9s "upper" %10s "sd" %9s "lower" %9s "upper"
		di as text "{hline 13}{c +}{hline 80}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %9.4f `M'[`i', 13] %9.4f `M'[`i', 14] %10.4f `M'[`i', 15] %9.4f `M'[`i', 16] %10.4f `M'[`i', 17] %9.4f `M'[`i', 18] %9.4f `M'[`i', 19]
		}
		di as text "{hline 13}{c BT}{hline 80}"
		di
		di as text "{bf:Fisher's combination of one-sided tests} (chi-squared, 2n d.f.)"
		di as text "{hline 13}{c TT}{hline 44}"
		di as text %12s "effect" " {c |}" %10s "right" %8s "p" %10s "left" %8s "p"
		di as text "{hline 13}{c +}{hline 44}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %10.3f `M'[`i', 20] %8.3f `M'[`i', 21] %10.3f `M'[`i', 22] %8.3f `M'[`i', 23]
		}
		di as text "{hline 13}{c BT}{hline 44}"
		di as text "Correlation of estimates and standard errors (Spearman, t approximation for p): see r(meta) columns corr, corr_p."
	}
	return matrix meta = `M'
	return matrix theta = `B'
	return matrix se = `R'
	return scalar groups = `ng'
end
