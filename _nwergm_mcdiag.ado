*! _nwergm_mcdiag.ado -- the report of R's mcmc.diagnostics() for the final MCMC sample of an nwergm fit
capture program drop _nwergm_mcdiag
program _nwergm_mcdiag, rclass
	version 14
	syntax [, PLOT NAME(string) PVALUE(real 0.05) EPS(real 0.1)]
	if `"`e(cmd)'"' != "nwergm" | `"`e(method)'"' != "mcmle" exit
	capture confirm matrix e(mcmcsample)
	if _rc exit
	if e(curved) == 1 {
		di as txt "(R-style sample diagnostics are not shown for models with curved terms)"
		exit
	}
	capture mata: __nwergm_last_M.nparam()
	if _rc exit
	local depvar `"`e(depvar)'"'
	capture _nwsyntax `depvar', max(1)
	if _rc {
		di as txt "(network `depvar' is no longer loaded; the R-style sample diagnostics need it for the observed statistics)"
		exit
	}
	local dir = ("`e(directed)'" == "true")
	tempname obsG obsstat C
	mata: `obsG' = ErgmGraph()
	mata: `obsG'.init(`nodes', `dir')
	mata: ergm_bridge_obs(`netobj', `obsG', `dir')
	mata: `obsstat' = __nwergm_last_M.full_statistic(`obsG')
	mata: mata drop `obsG'
	mata: `C' = st_matrix("e(mcmcsample)") :- `obsstat'
	mata: `C' = `C'[., selectindex(__nwergm_last_M.isfixed :== 0)]
	local names : colnames e(b)
	mata: st_local("keepnames", invtokens(tokens("`names'")[selectindex(__nwergm_last_M.isfixed :== 0)]))
	local thin = e(mcmc_interval)
	if "`e(mcmc_interval_final)'" != "" local thin = e(mcmc_interval_final)
	mata: st_local("n", strofreal(rows(`C')))
	mata: st_local("p", strofreal(cols(`C')))
	if `p' == 0 {
		mata: mata drop `obsstat' `C'
		exit
	}

	// ---- 1. summary (coda)
	tempname SUM Q
	mata: ergm_mcdiag_summary(`C', "`SUM'", "`Q'")
	matrix rownames `SUM' = `keepnames'
	matrix rownames `Q' = `keepnames'
	di
	di as txt "Sample statistics summary (centered at the observed statistics):"
	di
	di as txt "1. Empirical mean and standard deviation for each variable,"
	di as txt "   plus standard error of the mean:"
	di
	di as txt %-16s "" %12s "Mean" %12s "SD" %12s "Naive SE" %16s "Time-series SE"
	local k 0
	foreach nm of local keepnames {
		local ++k
		di as txt %-16s abbrev("`nm'", 16) as res %12.5g `SUM'[`k',1] %12.5g `SUM'[`k',2] %12.5g `SUM'[`k',3] %16.5g `SUM'[`k',4]
	}
	di
	di as txt "2. Quantiles for each variable:"
	di
	di as txt %-16s "" %12s "2.5%" %12s "25%" %12s "50%" %12s "75%" %12s "97.5%"
	local k 0
	foreach nm of local keepnames {
		local ++k
		di as txt %-16s abbrev("`nm'", 16) as res %12.5g `Q'[`k',1] %12.5g `Q'[`k',2] %12.5g `Q'[`k',3] %12.5g `Q'[`k',4] %12.5g `Q'[`k',5]
	}

	// ---- 2. are the sample statistics different from observed?
	tempname DT
	mata: ergm_mcdiag_obstest(`C', "`DT'")
	matrix rownames `DT' = diff. test_stat. P-val.
	local cn "`keepnames' (Omni)"
	di
	di as txt "Are sample statistics significantly different from observed?"
	di
	di as txt %-14s "" _c
	foreach nm of local keepnames {
		di as txt %16s abbrev("`nm'", 14) _c
	}
	di as txt %16s "(Omni)"
	local rows "diff. test_stat. P-val."
	local lbl1 "diff."
	local lbl2 "test stat."
	local lbl3 "P-val."
	forvalues r = 1/3 {
		di as txt %-14s "`lbl`r''" _c
		forvalues k = 1/`=`p'+1' {
			if `DT'[`r',`k'] >= . di as txt %16s "NA" _c
			else di as res %16.5g `DT'[`r',`k'] _c
		}
		di
	}

	// ---- 3. cross-correlations and autocorrelation
	tempname XC AC
	mata: ergm_mcdiag_corr(`C', "`XC'", "`AC'")
	matrix colnames `XC' = `keepnames'
	matrix rownames `XC' = `keepnames'
	di
	di as txt "Sample statistics cross-correlations:"
	di
	di as txt %-16s "" _c
	foreach nm of local keepnames {
		di as txt %16s abbrev("`nm'", 14) _c
	}
	di
	local k 0
	foreach nm of local keepnames {
		local ++k
		di as txt %-16s abbrev("`nm'", 16) _c
		forvalues j = 1/`p' {
			di as res %16.7f `XC'[`k',`j'] _c
		}
		di
	}
	matrix colnames `AC' = `keepnames'
	di
	di as txt "Sample statistics auto-correlation:"
	di as txt "Chain 1"
	di as txt %-16s "" _c
	foreach nm of local keepnames {
		di as txt %16s abbrev("`nm'", 14) _c
	}
	di
	forvalues l = 0/5 {
		di as txt %-16s "Lag `=`l'*`thin''" _c
		forvalues j = 1/`p' {
			di as res %16.7f `AC'[`=`l'+1',`j'] _c
		}
		di
	}

	// ---- 4. Geweke burn-in diagnostic
	tempname GW
	mata: ergm_mcdiag_geweke(`C', "`GW'")
	di
	di as txt "Sample statistics burn-in diagnostic (Geweke):"
	di as txt "Chain 1"
	di
	di as txt "Fraction in 1st window = 0.1"
	di as txt "Fraction in 2nd window = 0.5"
	di
	di as txt %-16s "" %16s "z-score" %22s "Individual P-value"
	local k 0
	foreach nm of local keepnames {
		local ++k
		di as txt %-16s abbrev("`nm'", 16) as res %16.7f `GW'[1,`k'] %22.7f `GW'[2,`k']
	}
	di as txt "Joint P-value (lower = worse):  " as res %9.7f `GW'[2,`p'+1]
	di
	di as txt "Note: MCMC diagnostics shown here are from the last round of simulation, prior to computation of final parameter estimates. Because the final estimates are refinements of those used for this simulation run, these diagnostics may understate model performance. To directly assess the performance of the final model on in-model statistics, please use {bf:estat gof}."

	return matrix summary = `SUM'
	return matrix quantiles = `Q'
	return matrix obstest = `DT'
	return matrix crosscorr = `XC'
	return matrix autocorr = `AC'
	return matrix geweke = `GW'
	mata: mata drop `obsstat' `C'
end
