*! _nwsaom_rsnotes (split out of nwsaom.ado: a program of another ado-file is dropped without a trace when Stata evicts it, so cross-file helpers need their own file)
/* RSiena's names of the covariate, interaction and behavior effects
   (e(rsiena_labels)), and the covariates' centring means (e(covmeans);
   RSiena's coCovar default), 2026-10-01 */
capture program drop _nwsaom_rsnotes
program define _nwsaom_rsnotes
	local names : colnames e(b)
	local nn : word count `names'
	// the labels, "|"-separated in e(b) order, into lab1, lab2, ...
	local rest `"`e(rsiena_labels)'"'
	forvalues k = 1/`nn' {
		local p = strpos(`"`rest'"', "|")
		if `p' > 0 {
			local lab`k' = substr(`"`rest'"', 1, `p' - 1)
			local rest = substr(`"`rest'"', `p' + 1, .)
		}
		else {
			local lab`k' `"`rest'"'
			local rest ""
		}
	}
	local first 1
	local k 0
	foreach nm of local names {
		local ++k
		// structural effects keep their obvious names; show the
		// covariate, interaction, behavior and gwesp effects
		if strpos("`nm'", "_") == 0 continue
		if `first' di as text "RSiena effect names:"
		local first 0
		if udstrlen("`nm'") > 29 local nm = usubstr("`nm'", 1, 28) + "~"
		di as text "  " %-30s "`nm'" as result `"`lab`k''"'
	}
	capture confirm matrix e(ratecoefs)
	if !_rc {
		local rn : colnames e(ratecoefs)
		foreach v of local rn {
			if `first' di as text "RSiena effect names:"
			local first 0
			di as text "  " %-30s "ratecoef (`v')" as result "effect `v' on rate"
		}
	}
	capture confirm matrix e(covmeans)
	if !_rc {
		tempname cm
		matrix `cm' = e(covmeans)
		local cn : colnames `cm'
		if e(centered) == 0 di as text "Covariates not centred ({bf:nocenter}); their means:"
		else di as text "Covariates centred by their means, as RSiena's coCovar(centered = TRUE):"
		local i 0
		foreach v of local cn {
			local ++i
			di as text "  " %-30s "`v'" as result %9.3f `cm'[1,`i']
		}
	}
end
