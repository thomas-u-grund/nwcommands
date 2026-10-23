*! version 0.2.0 24oct2026 nwcommands: maximum likelihood estimation of a SAOM (Robbins-Monro on the score of the augmented data) after nwsaom
/*
	nwsaom_ml -- called by nwsaom with the option ml, after the method of moments fit (whose estimates are the starting values).
	The estimates, standard errors and rates replace those of the fit in e(); everything else of the fit (so that estat works) is kept.
	The algorithm is in the plugin (MLRUN, native/saom_ml.c); the Mata wrapper is SaomMLRun() in unw_saom.do.
*/
capture program drop nwsaom_ml
program nwsaom_ml, eclass
	version 14
	syntax [, N1(integer 50) NSUB(integer 4) NSTART2(integer 100) N3(integer 1000) MULT(real 5) NMH(integer 0) GAIN(real 0.2) SEED(integer -1) THETA0(numlist) RATE0(numlist >0) NOTABLE]
	if `"`e(cmd)'"' != "nwsaom" {
		di as err "nwsaom ml works on the model of the last nwsaom fit."
		exit 301
	}
	capture mata: __nwsaom_last_M.nparam()
	if _rc {
		di as err "no fitted nwsaom model available."
		exit 498
	}
	if e(twomode) == 1 | `"`e(symtype)'"' != "" | `"`e(ratecov)'"' != "" {
		di as err "maximum likelihood estimation covers one directed one-mode network with at most one co-evolving behavior, without two-mode data, non-directed models or rate covariates."
		exit 198
	}
	mata: st_numscalar("__nwsaom_ml_bad", any(_SaomGofExt("__nwsaom_last_fntype", J(1, 0, 0)) :!= 0) | rows(_SaomGofExt("__nwsaom_last_present", J(0, 1, 0))) > 0 | rows(_SaomGofExt("__nwsaom_last_struct", J(0, 0, 0))) > 0)
	if scalar(__nwsaom_ml_bad) == 1 {
		di as err "maximum likelihood estimation does not cover endowment/creation effects, present()/joinat()/leaveat(), structural() or missing-data options."
		exit 198
	}
	local nwaves = e(nwaves)
	local nper = `nwaves' - 1
	local coev = (e(has_behavior) == 1)
	local NR = `nper' * (1 + `coev')
	tempname b rt out bb VV rr rrb
	matrix `b' = e(b)
	local names : colnames `b'
	local K = colsof(`b')
	_nwsaom_getrates `nper' `coev'
	matrix `rt' = r(rt)
	if "`theta0'" != "" {
		forvalues k = 1/`K' {
			matrix `b'[1, `k'] = `: word `k' of `theta0''
		}
	}
	if "`rate0'" != "" {
		forvalues pd = 1/`NR' {
			matrix `rt'[1, `pd'] = `: word `pd' of `rate0''
		}
	}
	if `seed' < 0 local seed = floor(runiform() * 1e9) + 1
	local gs ""
	forvalues pd = 1/`nwaves' {
		local gs `gs'`=cond(`pd' > 1, ", ", "")'&__nwsaom_last_G`pd'
	}
	if `coev' local mbs "__nwsaom_last_Mbeh, __nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval"
	else {
		capture mata: mata drop __nwsaom_ml_Mb0 __nwsaom_ml_Bw0
		mata: __nwsaom_ml_Mb0 = SaomBehaviorModel()
		mata: __nwsaom_ml_Bw0 = J(1, 0, NULL)
		local mbs "__nwsaom_ml_Mb0, __nwsaom_ml_Bw0, 0, 0"
	}
	mata: __nwsaom_ml_Gs = (`gs')
	di as txt "Maximum likelihood: phase 1 `n1' iterations, phase 2 `nsub' subphases from `nstart2' iterations, phase 3 `n3' iterations ..."
	mata: st_matrix("`out'", SaomMLRun(__nwsaom_ml_Gs, `nper', __nwsaom_last_M, `coev', `mbs', st_matrix("`b'"), st_matrix("`rt'"), `n1', `nsub', `nstart2', `n3', `nmh', `seed', `mult', `gain'))
	capture mata: mata drop __nwsaom_ml_Gs __nwsaom_ml_Mb0 __nwsaom_ml_Bw0
	local KP = `K' + `NR'
	local ok = scalar(__saom_ml_okinfo)
	matrix `bb' = J(1, `K', 0)
	matrix `VV' = J(`K', `K', 0)
	matrix `rr' = J(3, `NR', 0)
	forvalues k = 1/`K' {
		matrix `bb'[1, `k'] = `out'[`k', 1]
		forvalues l = 1/`K' {
			matrix `VV'[`k', `l'] = cond(missing(`out'[`k', 2 + `l']), 0, `out'[`k', 2 + `l'])
		}
	}
	forvalues p = 1/`NR' {
		matrix `rr'[1, `p'] = `out'[`K' + `p', 1]
		matrix `rr'[2, `p'] = sqrt(`out'[`K' + `p', 2 + `K' + `p'])
		matrix `rr'[3, `p'] = `out'[`K' + `p', 2]
	}
	matrix colnames `bb' = `names'
	matrix colnames `VV' = `names'
	matrix rownames `VV' = `names'
	local rcn ""
	local rcnb ""
	forvalues p = 1/`nper' {
		local rcn `rcn' period`p'
		local rcnb `rcnb' period`p'
	}
	matrix rownames `rr' = rate se tconv
	tempname tc sc
	matrix `tc' = `out'[1..`KP', 2]'
	matrix `sc' = `out'[1..`KP', 3 + `KP']'
	local tmax = 0
	forvalues k = 1/`KP' {
		if abs(`tc'[1, `k']) > `tmax' local tmax = abs(`tc'[1, `k'])
	}
	ereturn repost b = `bb' V = `VV'
	ereturn local title "Stochastic actor-oriented model (Maximum likelihood)"
	ereturn local estimator "ml"
	ereturn scalar tconv_max_ml = `tmax'
	ereturn scalar ml_cov_ok = `ok'
	ereturn scalar ml_seconds = scalar(__saom_ml_secs)
	ereturn matrix ml_score = `sc'
	tempname r2 r3
	matrix `r2' = `rr'[1..3, 1..`nper']
	matrix colnames `r2' = `rcn'
	ereturn matrix rates_ml = `r2'
	matrix `r2' = e(rates_ml)
	matrix `r3' = `r2'[1..2, 1..`nper']
	matrix rownames `r3' = rate se
	if `nper' > 1 ereturn matrix rates = `r3'
	else {
		ereturn scalar rate = el(`r3', 1, 1)
		ereturn scalar rate_se = el(`r3', 2, 1)
	}
	if `coev' {
		tempname rb
		matrix `rb' = `rr'[1..3, `nper' + 1..`NR']
		matrix colnames `rb' = `rcn'
		ereturn matrix rates_beh_ml = `rb'
		matrix `rb' = e(rates_beh_ml)
		matrix `r3' = `rb'[1..2, 1..`nper']
		matrix rownames `r3' = rate se
		if `nper' > 1 ereturn matrix rates_beh = `r3'
		else {
			ereturn scalar rate_beh = el(`r3', 1, 1)
			ereturn scalar rate_beh_se = el(`r3', 2, 1)
		}
	}
	if "`notable'" == "" {
		di
		di as txt "Maximum likelihood estimates (Robbins-Monro on the score of the augmented data)"
		ereturn display
		di as txt "Rate parameters (one per inter-wave period):"
		matrix list e(rates_ml), noheader format(%9.4f)
		if `coev' {
			di as txt "Behavior rate parameters:"
			matrix list e(rates_beh_ml), noheader format(%9.4f)
		}
		di as txt "Overall maximum t-ratio of the scores: " as res %5.3f `tmax' as txt cond(`tmax' < 0.1, " (good; below 0.1)", cond(`tmax' < 0.25, " (acceptable)", " (poor: run longer, e.g. n3() and nstart2())"))
		if !`ok' di as txt "(the information matrix was not positive definite: the standard errors are those of the complete-data information, too small)"
	}
end
