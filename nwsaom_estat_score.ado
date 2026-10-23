*! version 0.1.0 23oct2026 nwcommands: estat score after nwsaom
/*
	estat score: the generalised score-type test of Schweinberger (2012),
	RSiena's test_parameter(method = "score") / the test = TRUE effects of siena07.

	The model is fitted with the effects to be tested held fixed at the
	restricted values (nwsaom ..., fix(effects) theta0(...); RSiena's
	fix = TRUE, test = TRUE). The test then asks whether freeing them would
	improve the fit, using only the phase-3 simulations of the restricted
	model. Reported: the joint chi-squared test, each tested effect
	separately (two-sided chi-squared and one-sided normal variate), and the
	one-step estimates of all parameters.

	tested(effects) restricts the test to some of the fixed effects; the
	others stay fixed and are treated as redundant.
*/
capture program drop nwsaom_estat_score
program define nwsaom_estat_score, rclass
	syntax [, TESTED(string) ]

	if `"`e(cmd)'"' != "nwsaom" {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	capture mata: st_numscalar("__nwsaom_score_have", rows(__nwsaom_score_D))
	if _rc {
		di as err "estat score needs a fit with fix(): fit the restricted model (the effects to be tested held fixed with fix() at their restricted values) first."
		exit 198
	}
	tempname b
	matrix `b' = e(b)
	local names : colnames `b'
	local p : word count `names'
	mata: st_numscalar("__nwsaom_score_nfix", sum(__nwsaom_score_fix))
	mata: st_numscalar("__nwsaom_score_same", cols(__nwsaom_score_par) >= `p')
	if scalar(__nwsaom_score_nfix) == 0 | scalar(__nwsaom_score_same) == 0 {
		di as err "estat score needs a fit with fix(): fit the restricted model (the effects to be tested held fixed with fix() at their restricted values) first."
		exit 198
	}
	local testlist ""
	mata: st_local("fixedflags", invtokens(strofreal(__nwsaom_score_fix)))
	local nall : word count `fixedflags'
	local fixednames ""
	forvalues i = 1/`p' {
		local f : word `i' of `fixedflags'
		if `f' == 1 local fixednames `fixednames' `: word `i' of `names''
	}
	if "`tested'" == "" local tested "`fixednames'"
	foreach w of local tested {
		if !`: list w in fixednames' {
			di as err "tested(): `w' is not a fixed effect (fixed: `fixednames')."
			exit 198
		}
	}
	local flags ""
	forvalues i = 1/`nall' {
		local nm : word `i' of `names'
		local flags `flags' `=(`i' <= `p' & "`: list nm & tested'" != "")'
	}
	mata: SaomScoreRun(strtoreal(tokens("`flags'")))
	local df = scalar(__nwsaom_score_df)
	local c = scalar(__nwsaom_score_c)
	local pv = chi2tail(`df', `c')

	di
	di as txt "Generalised score-type test of the model restricted by:"
	local j 0
	foreach w of local tested {
		local ++j
		local pos : list posof "`w'" in names
		di as txt "  (`j')  " as res %-24s "`w'" as txt " = " as res %9.4f `b'[1, `pos']
	}
	di as txt "{hline 60}"
	di as txt "Joint test:  c = " as res %9.4f `c' as txt "   d.f. = " as res `df' as txt "   p-value = " as res %6.4f `pv'
	tempname sep
	matrix `sep' = __nwsaom_score_res
	if `df' == 1 {
		di as txt "One-sided (normal variate): " as res %9.4f scalar(__nwsaom_score_oneS)
	}
	else {
		local j 0
		foreach w of local tested {
			local ++j
			di as txt "  (`j') `w' separately: c = " as res %8.4f `sep'[`j', 1] as txt "  d.f. = 1  p-value = " as res %6.4f chi2tail(1, `sep'[`j', 1]) ///
				as txt "   one-sided: " as res %8.4f `sep'[`j', 2]
		}
	}
	tempname os
	matrix `os' = __nwsaom_score_onestep
	local onames `names'
	forvalues i = `=`p'+1'/`nall' {
		local onames `onames' rate`=`i'-`p''
	}
	matrix colnames `os' = `onames'
	di
	di as txt "One-step estimates (restricted estimate plus the one-step correction):"
	forvalues i = 1/`nall' {
		local nm : word `i' of `onames'
		di as txt "  " %-24s "`nm'" as res %9.4f `os'[1, `i']
	}
	capture scalar drop __nwsaom_score_have __nwsaom_score_nfix __nwsaom_score_same
	return scalar chi2 = `c'
	return scalar df = `df'
	return scalar p = `pv'
	return matrix separate = `sep'
	return matrix onestep = `os'
end
