*! _nwsaom_tconvtable (split out of nwsaom.ado: a program of another ado-file is dropped without a trace when Stata evicts it, so cross-file helpers need their own file)
/* Convergence t-ratios on RSiena's scale (phase-3 mean deviation / its
   standard deviation, e(tconv)) for every parameter including the rates,
   two per line within 80 columns, then RSiena's overall maximum
   convergence ratio e(tconv_max). */
capture program drop _nwsaom_tconvtable
program define _nwsaom_tconvtable
	syntax [, DETail]
	tempname m
	matrix `m' = e(tconv)
	local names : colnames `m'
	local k = colsof(`m')
	if "`detail'" != "" {
		di as text "Convergence t-ratios (|t| < 0.1 good; overall maximum ratio < 0.25 good):"
		forvalues j = 1/`k' {
			local nm : word `j' of `names'
			if udstrlen("`nm'") > 24 local nm = usubstr("`nm'", 1, 23) + "~"
			if mod(`j', 2) == 1 di as text "  " %-24s "`nm'" as result %8.3f `m'[1,`j'] _continue
			else di as text "      " %-24s "`nm'" as result %8.3f `m'[1,`j']
		}
		if mod(`k', 2) == 1 di ""
		di as text "Overall maximum convergence ratio: " as result %6.3f e(tconv_max)
	}
	else {
		local bad ""
		forvalues j = 1/`k' {
			if abs(`m'[1,`j']) >= 0.1 {
				local nm : word `j' of `names'
				local bad "`bad' `nm' (`: di %5.3f `m'[1,`j']')"
			}
		}
		local ok = e(tconv_max) < 0.25
		di as text "Overall maximum convergence ratio: " as result %5.3f e(tconv_max) _continue
		if `ok' & "`bad'" == "" di as text " (good; all t-ratios below 0.1)"
		else if `ok' di as text " (below 0.25)"
		else di as text " ({bf:not converged}: should be below 0.25)"
		if "`bad'" != "" di as text "Convergence t-ratios of 0.1 or more in absolute value:" as result "`bad'"
		if !`ok' di as text "Refit starting from these estimates with theta0(); see {help nwsaom}."
	}
	if "`e(engine)'" == "mata" {
		di as text "(simulated in Mata, not the native plugin: `e(engine_why)')"
	}
end
