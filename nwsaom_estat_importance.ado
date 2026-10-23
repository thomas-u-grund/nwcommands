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
	if e(has_behavior) == 1 {
		di as err "estat importance is not yet available for fits with a behavior (network effects only)."
		exit 198
	}
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
	mata: SaomImportanceRun(__nwsaom_imp_Gs, `nper', __nwsaom_last_M, st_matrix("e(b)")[1, 1..`p'])
	capture mata: mata drop __nwsaom_imp_Gs
	tempname RI I sg sgs RH
	matrix `RI' = __nwsaom_imp_RI
	matrix `I' = __nwsaom_imp_I
	matrix `sgs' = __nwsaom_imp_sigmas
	matrix `sg' = __nwsaom_imp_sigma
	matrix `RH' = __nwsaom_imp_RH

	di
	di as txt "Relative importance of effects (RSiena's sienaRI); expected over the actors at the start of each period"
	if "`e(symtype)'" != "" di as txt "Non-directed network: effect sizes are for the forcing model (RSiena modelType 2), as in RSiena."
	di as txt "{hline 78}"
	di as txt %-22s "effect" %10s "estimate" %9s "s.e." %10s "sigma" %12s "semi-std." _continue
	forvalues pd = 1/`nper' {
		di as txt %9s "RI p`pd'" _continue
	}
	di
	forvalues k = 1/`p' {
		local nm : word `k' of `names'
		local se = sqrt(`V'[`k', `k'])
		di as res %-22s abbrev("`nm'", 22) %10.4f `b'[1, `k'] %9.4f `se' %10.4f `sg'[`k', 1] %12.4f `b'[1, `k'] * `sg'[`k', 1] _continue
		forvalues pd = 1/`nper' {
			di as res %9.4f `RI'[`k', `pd'] _continue
		}
		di
	}
	di as txt "{hline 78}"
	di as txt "Certainty R_H of the actors' choices:" _continue
	forvalues pd = 1/`nper' {
		di as res %9.4f `RH'[1, `pd'] _continue
	}
	di
	di as txt "RI: expected relative importance of the effect (shares sum to 1 within a period); semi-std. = estimate x sigma."
	capture scalar drop __nwsaom_imp_bad
	matrix rownames `RI' = `names'
	matrix rownames `I' = `names'
	matrix rownames `sgs' = `names'
	return matrix ri = `RI'
	return matrix importance = `I'
	return matrix sigma_period = `sgs'
	return matrix sigma = `sg'
	return matrix certainty = `RH'
end
