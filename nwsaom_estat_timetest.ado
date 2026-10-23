*! version 0.1.0 23oct2026 nwcommands: estat timetest after nwsaom
/*
	estat timetest: test of time heterogeneity (RSiena's sienaTimeTest).
	For every effect of the fitted model it asks whether the parameter is the
	same in all inter-wave periods, with a score-type test of period-specific
	deviations (effect x dummy for periods 2..P) against the model fitted. No
	new fit is needed beyond the one in memory, which must have at least three
	waves (two periods).

	With fixrates the rate parameters are treated as known (as RSiena's
	sienaTimeTest does); by default they are estimated together with the
	effects, which is the score test of a model with a fixed time dummy.

	Reported: a joint test of all deviations, one test per effect (d.f. = P-1),
	and one test per effect and period with the one-step estimate of the
	deviation.
*/
capture program drop nwsaom_estat_timetest
program define nwsaom_estat_timetest, rclass
	syntax [, EFFects(string) FIXRates ]

	if !inlist(`"`e(cmd)'"', "nwsaom", "nwsaom_multinet") {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	local nwaves = e(nwaves)
	if `nwaves' < 3 {
		di as err "estat timetest needs at least three waves (two periods)."
		exit 198
	}
	local nper = `nwaves' - 1
	capture mata: st_numscalar("__nwsaom_tt_have", rows(__nwsaom_score_Zp))
	if _rc {
		di as err "estat timetest is not available for this fit."
		exit 198
	}
	tempname b
	matrix `b' = e(b)
	local names : colnames `b'
	local p : word count `names'
	mata: st_local("nall", strofreal(cols(__nwsaom_score_par)))
	if "`effects'" == "" local effects `names'
	local flags ""
	forvalues i = 1/`nall' {
		local nm : word `i' of `names'
		local flags `flags' `=(`i' <= `p' & "`: list nm & effects'" != "")'
	}
	foreach w of local effects {
		if !`: list w in names' {
			di as err "effects(): `w' is not an effect of the fitted model (`names')."
			exit 198
		}
	}
	mata: SaomTimeTestRun(`nper', strtoreal(tokens("`flags'")), `p', ("`fixrates'" != ""))
	tempname joint eff ind
	matrix `joint' = __nwsaom_tt_joint
	matrix `eff' = __nwsaom_tt_effect
	matrix `ind' = __nwsaom_tt_indiv
	tempname idx
	matrix `idx' = __nwsaom_tt_eff
	local ne = colsof(`idx')

	di
	di as txt "Test of time heterogeneity (score-type test; RSiena's sienaTimeTest)"
	di as txt "{hline 70}"
	di as txt "Joint test of all period-specific deviations:  c = " as res %9.4f `joint'[1,1] as txt "   d.f. = " as res `joint'[1,2] ///
		as txt "   p-value = " as res %6.4f chi2tail(`joint'[1,2], `joint'[1,1])
	di
	di as txt "Test of each effect (is its parameter the same in all periods?)"
	di as txt %-24s "effect" %10s "c" %6s "d.f." %10s "p-value"
	local rows ""
	forvalues j = 1/`ne' {
		local k = `idx'[1, `j']
		local nm : word `k' of `names'
		di as res %-24s "`nm'" %10.3f `eff'[`j', 1] %6.0f `eff'[`j', 2] %10.4f chi2tail(`eff'[`j', 2], `eff'[`j', 1])
		local rows `rows' `nm'
	}
	di
	di as txt "Period-specific deviations (one-step estimates) and separate tests"
	di as txt %-24s "effect" %8s "period" %12s "deviation" %10s "c" %10s "p-value"
	local r 0
	forvalues j = 1/`ne' {
		local k = `idx'[1, `j']
		local nm : word `k' of `names'
		forvalues q = 2/`nper' {
			local ++r
			di as res %-24s "`nm'" %8.0f `ind'[`r', 3] %12.4f `ind'[`r', 2] %10.3f `ind'[`r', 1] %10.4f chi2tail(1, `ind'[`r', 1])
		}
	}
	matrix colnames `eff' = c df
	matrix colnames `ind' = c deviation period
	capture scalar drop __nwsaom_tt_have
	return scalar chi2 = `joint'[1,1]
	return scalar df = `joint'[1,2]
	return scalar p = chi2tail(`joint'[1,2], `joint'[1,1])
	return matrix effect = `eff'
	return matrix individual = `ind'
end
