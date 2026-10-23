*! version 0.1.0 23oct2026 nwcommands: estat importance after nwsaom
/*
	estat importance: the relative importance of the effects (RSiena's sienaRI()
	/ interpret_size()). At the start network of every inter-wave period, the
	change contribution of every actor and every possible tie change is
	computed (by the plugin); the importance of an effect is how much the
	actors' choice probabilities change when its coefficient is set to 0
	(L1 distance), expressed as a share of all effects. Also reported: the
	semi-standardised estimates (coefficient times the within-actor standard
	deviation of the effect's contributions) and the certainty R_H of the
	actors' choices.

	Available after fits of a one-mode (directed or non-directed) or two-mode network without behavior,
	endowment/creation effects, missing-data or composition-change options.
*/
capture program drop nwsaom_estat_importance
program define nwsaom_estat_importance, rclass
	syntax

	if `"`e(cmd)'"' != "nwsaom" {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	capture mata: __nwsaom_last_M.nparam()
	if _rc {
		di as err "no fitted nwsaom model available - re-run nwsaom before estat importance."
		exit 498
	}
	local coev = (e(has_behavior) == 1)
	mata: st_numscalar("__nwsaom_imp_bad", any(_SaomGofExt("__nwsaom_last_fntype", J(1, 0, 0)) :!= 0) | rows(_SaomGofExt("__nwsaom_last_present", J(0, 1, 0))) > 0)
	if scalar(__nwsaom_imp_bad) == 1 {
		di as err "estat importance is not available with endowment/creation effects, present() or missing-data options (as in RSiena's sienaRI)."
		exit 198
	}
	local nwaves = e(nwaves)
	local nper = `nwaves' - 1
	tempname b V
	matrix `b' = e(b)
	matrix `V' = e(V)
	local names : colnames `b'
	local p : word count `names'
	local gs ""
	forvalues pd = 1/`nper' {
		local gs `gs'`=cond(`pd' > 1, ", ", "")'&__nwsaom_last_G`pd'
	}
	mata: __nwsaom_imp_Gs = (`gs')
	if `coev' {
		mata: st_local("pnet", strofreal(__nwsaom_last_M.nparam()))
		mata: SaomImportanceRunB(__nwsaom_imp_Gs, `nper', __nwsaom_last_M, st_matrix("e(b)")[1, 1..`pnet'], __nwsaom_last_Mbeh, __nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval, st_matrix("e(b)")[1, (`pnet'+1)..`p'])
	}
	else {
		local pnet = `p'
		mata: SaomImportanceRun(__nwsaom_imp_Gs, `nper', __nwsaom_last_M, st_matrix("e(b)")[1, 1..`p'])
	}
	capture mata: mata drop __nwsaom_imp_Gs
	tempname RI I sg sgs RH RIb Ib sgb sgsb RHb
	matrix `RI' = __nwsaom_imp_RI
	matrix `I' = __nwsaom_imp_I
	matrix `sgs' = __nwsaom_imp_sigmas
	matrix `sg' = __nwsaom_imp_sigma
	matrix `RH' = __nwsaom_imp_RH
	local names_net ""
	local names_beh ""
	forvalues k = 1/`p' {
		local nm : word `k' of `names'
		if `k' <= `pnet' local names_net `names_net' `nm'
		else local names_beh `names_beh' `nm'
	}

	di
	di as txt "Relative importance of effects (RSiena's sienaRI); expected over the actors at the start of each period"
	if "`e(symtype)'" != "" di as txt "Non-directed network: effect sizes are for the forcing model (RSiena modelType 2), as in RSiena."
	if `coev' di as txt "Network effects"
	nwsaom_imp_table, names(`names_net') first(1) b(`b') v(`V') sg(`sg') ri(`RI') rh(`RH') nper(`nper')
	if `coev' {
		matrix `RIb' = __nwsaom_impb_RI
		matrix `Ib' = __nwsaom_impb_I
		matrix `sgsb' = __nwsaom_impb_sigmas
		matrix `sgb' = __nwsaom_impb_sigma
		matrix `RHb' = __nwsaom_impb_RH
		di
		di as txt "Behavior effects (the options are changing by -1, 0, +1)"
		nwsaom_imp_table, names(`names_beh') first(`=`pnet'+1') b(`b') v(`V') sg(`sgb') ri(`RIb') rh(`RHb') nper(`nper')
		matrix rownames `RIb' = `names_beh'
		matrix rownames `Ib' = `names_beh'
		matrix rownames `sgsb' = `names_beh'
		return matrix ri_beh = `RIb'
		return matrix importance_beh = `Ib'
		return matrix sigma_period_beh = `sgsb'
		return matrix sigma_beh = `sgb'
		return matrix certainty_beh = `RHb'
	}
	di as txt "RI: expected relative importance of the effect (shares sum to 1 within a period); semi-std. = estimate x sigma."
	capture scalar drop __nwsaom_imp_bad
	matrix rownames `RI' = `names_net'
	matrix rownames `I' = `names_net'
	matrix rownames `sgs' = `names_net'
	return matrix ri = `RI'
	return matrix importance = `I'
	return matrix sigma_period = `sgs'
	return matrix sigma = `sg'
	return matrix certainty = `RH'
end

capture program drop nwsaom_imp_table
program define nwsaom_imp_table
	syntax , NAMES(string) FIRST(integer) B(name) V(name) SG(name) RI(name) RH(name) NPER(integer)
	local p : word count `names'
	di as txt "{hline 78}"
	di as txt %-22s "effect" %10s "estimate" %9s "s.e." %10s "sigma" %12s "semi-std." _continue
	forvalues pd = 1/`nper' {
		di as txt %9s "RI p`pd'" _continue
	}
	di
	forvalues j = 1/`p' {
		local nm : word `j' of `names'
		local k = `first' + `j' - 1
		local se = sqrt(`v'[`k', `k'])
		di as res %-22s abbrev("`nm'", 22) %10.4f `b'[1, `k'] %9.4f `se' %10.4f `sg'[`j', 1] %12.4f `b'[1, `k'] * `sg'[`j', 1] _continue
		forvalues pd = 1/`nper' {
			di as res %9.4f `ri'[`j', `pd'] _continue
		}
		di
	}
	di as txt "{hline 78}"
	di as txt "Certainty R_H of the actors' choices:" _continue
	forvalues pd = 1/`nper' {
		di as res %9.4f `rh'[1, `pd'] _continue
	}
	di
end
