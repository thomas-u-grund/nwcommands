*! version 0.1.0 23oct2026 nwcommands: Bayesian estimation of a SAOM (data augmentation, Metropolis-Hastings) after nwsaom
/*
	nwsaom bayes -- Bayesian estimation of the model of the last nwsaom fit. The unobserved sequence of ministeps between each pair
	of waves is a parameter of the sampler (Koskinen & Snijders 2007; Snijders, Koskinen & Schweinberger 2010); given it, the effects
	are updated by a random-walk Metropolis step and the rate of each period from its gamma full conditional. The sampler is
	implemented in the plugin (BAYESRUN), the Mata wrapper and the summaries are SaomBayesRun()/SaomBayesSummary() in unw_saom.do.
*/
capture program drop nwsaom_bayes
program nwsaom_bayes, eclass
	version 14
	syntax [, NPREWARM(integer 50) NWARM(integer 50) NMAIN(integer 250) NRUNMH(integer 20) NIMPROVEMH(integer 100) MULT(real 5) TARGETMH(real 0.25) NMH(integer 0) NSAMPCONST(integer 1) THETA0(numlist) RATE0(numlist >0) FIXRATES WINDOW(integer 10) ///
		SEED(integer -1) PRIORMEAN(numlist) PRIORSD(numlist >0) PRIORRATE(numlist min=2 max=2 >=0) ///
		FRAME(name) LEVEL(cilevel) NOTABLE NOHEADER]

	if !inlist(`"`e(cmd)'"', "nwsaom", "nwsaom_bayes") {
		di as err "nwsaom bayes works on the model of the last nwsaom fit; run nwsaom first."
		exit 301
	}
	capture mata: __nwsaom_last_M.nparam()
	if _rc {
		di as err "no fitted nwsaom model available - re-run nwsaom before nwsaom bayes."
		exit 498
	}
	if e(has_behavior) == 1 | e(twomode) == 1 | `"`e(symtype)'"' != "" | `"`e(ratecov)'"' != "" {
		di as err "nwsaom bayes covers one directed one-mode network without a co-evolving behavior, two-mode data, non-directed models or rate covariates."
		exit 198
	}
	mata: st_numscalar("__nwsaom_by_bad", any(_SaomGofExt("__nwsaom_last_fntype", J(1, 0, 0)) :!= 0) | rows(_SaomGofExt("__nwsaom_last_present", J(0, 1, 0))) > 0 | rows(_SaomGofExt("__nwsaom_last_struct", J(0, 0, 0))) > 0)
	if scalar(__nwsaom_by_bad) == 1 {
		di as err "nwsaom bayes does not cover endowment/creation effects, present()/joinat()/leaveat(), structural() or missing-data options."
		exit 198
	}
	if `nprewarm' < 0 | `nwarm' < 0 | `nmain' < 1 | `nrunmh' < 1 | `nsampconst' < 0 | `window' < 1 | `nmh' < 0 | `nimprovemh' < 0 | `mult' <= 0 {
		di as err "nprewarm(), nwarm(), nimprovemh() must be >= 0 and nmain(), nrunmh(), window(), mult() positive."
		exit 198
	}
	local nwaves = e(nwaves)
	local nper = `nwaves' - 1
	tempname b V rt Vp
	matrix `b' = e(b)
	matrix `V' = e(V)
	local names : colnames `b'
	local K = colsof(`b')
	capture confirm matrix e(rates)
	if !_rc {
		matrix `rt' = e(rates)
		matrix `rt' = `rt'[1, 1..`nper']
	}
	else {
		matrix `rt' = J(1, `nper', e(rate))
	}
	if "`theta0'" != "" {
		if `: word count `theta0'' != `K' {
			di as err "theta0() takes one value per effect (`K')."
			exit 198
		}
		forvalues k = 1/`K' {
			matrix `b'[1, `k'] = `: word `k' of `theta0''
		}
	}
	if "`rate0'" != "" {
		if `: word count `rate0'' != `nper' {
			di as err "rate0() takes one value per period (`nper')."
			exit 198
		}
		forvalues pd = 1/`nper' {
			matrix `rt'[1, `pd'] = `: word `pd' of `rate0''
		}
	}
	if `seed' < 0 local seed = floor(runiform() * 1e9) + 1

	// priors: flat for the effects (as multiSiena's default for effects that do not vary between groups) unless priormean()/priorsd()
	// give a normal prior; gamma(shape, rate) for the rate of every period (default flat: shape 1, rate 0)
	local pm ""
	local ps ""
	local nm : word count `priormean'
	local ns : word count `priorsd'
	if `nm' != 0 & `nm' != 1 & `nm' != `K' {
		di as err "priormean() takes one value or one value per effect (`K')."
		exit 198
	}
	if `ns' != 0 & `ns' != 1 & `ns' != `K' {
		di as err "priorsd() takes one value or one value per effect (`K')."
		exit 198
	}
	forvalues k = 1/`K' {
		local m = 0
		if `nm' == 1 local m : word 1 of `priormean'
		else if `nm' == `K' local m : word `k' of `priormean'
		local s = 0
		if `ns' == 1 local s : word 1 of `priorsd'
		else if `ns' == `K' local s : word `k' of `priorsd'
		local pm `pm' `m'
		local ps `ps' `s'
	}
	local pshape = cond("`fixrates'" != "", -1, 1)
	local prate 0
	if "`priorrate'" != "" {
		if "`fixrates'" == "" local pshape : word 1 of `priorrate'
		local prate : word 2 of `priorrate'
	}
	if "`frame'" == "" local frame nwsaom_bayes_draws

	// the random-walk proposal starts at the fit's covariance matrix (scaled), or 0.01 * I when that is unusable
	matrix `Vp' = `V' * (2.38^2 / `K')
	local badV = 0
	forvalues i = 1/`K' {
		forvalues j = 1/`K' {
			if missing(`Vp'[`i', `j']) local badV = 1
		}
		if `Vp'[`i', `i'] <= 0 local badV = 1
	}
	if `badV' matrix `Vp' = I(`K') * 0.01
	local gs ""
	forvalues pd = 1/`nwaves' {
		local gs `gs'`=cond(`pd' > 1, ", ", "")'&__nwsaom_last_G`pd'
	}
	local vn ""
	forvalues k = 1/`K' {
		local vn `vn' b`k'
	}
	forvalues pd = 1/`nper' {
		local vn `vn' rate`pd'
	}
	local vn `vn' nchain loglik
	mata: __nwsaom_by_Gs = (`gs')
	mata: __nwsaom_by_names = tokens("`vn'")
	mata: __nwsaom_by_th = st_matrix("`b'")
	mata: __nwsaom_by_V = st_matrix("`Vp'")
	mata: __nwsaom_by_rho = st_matrix("`rt'")
	mata: __nwsaom_by_pm = strtoreal(tokens("`pm'"))
	mata: __nwsaom_by_ps = strtoreal(tokens("`ps'"))
	di as txt "Sampling: `nprewarm' pre-warming + `nwarm' warming + `nmain' main iterations of `nrunmh' batches ..."
	mata: st_numscalar("__nwsaom_by_n", SaomBayesRun(__nwsaom_by_Gs, `nper', __nwsaom_last_M, __nwsaom_by_th, __nwsaom_by_V, __nwsaom_by_rho, __nwsaom_by_pm, __nwsaom_by_ps, `pshape', `prate', `nprewarm', `nwarm', `nmain', `nrunmh', `nimprovemh', `nmh', `nsampconst', `window', `seed', `mult', `targetmh', "`frame'", __nwsaom_by_names))
	capture mata: mata drop __nwsaom_by_Gs __nwsaom_by_names __nwsaom_by_th __nwsaom_by_V __nwsaom_by_rho __nwsaom_by_pm __nwsaom_by_ps
	local ndraw = scalar(__nwsaom_by_n)
	local acc_th = scalar(__saom_bayes_acc_theta)
	local acc_dg = scalar(__saom_bayes_acc_diag)
	local acc_pr = scalar(__saom_bayes_acc_pair)
	local acc_sw = scalar(__saom_bayes_acc_swap)
	local meanR = scalar(__saom_bayes_meanR)
	local secs = scalar(__saom_bayes_secs)
	if `ndraw' < 2 {
		di as err "too few draws saved."
		exit 498
	}
	local Kp = `K' + `nper'
	mata: SaomBayesSummary("`frame'", `K', `Kp', `level')
	// label the draws
	forvalues k = 1/`K' {
		local nmk : word `k' of `names'
		frame `frame': label variable b`k' "`nmk'"
	}

	tempname mean sd Vb Q ess bb rr
	matrix `mean' = __nwsaom_bayes_mean
	matrix `sd' = __nwsaom_bayes_sd
	matrix `Q' = __nwsaom_bayes_q
	matrix `ess' = __nwsaom_bayes_ess
	matrix `Vb' = __nwsaom_bayes_V
	matrix `bb' = `mean'[1, 1..`K']
	matrix colnames `bb' = `names'
	matrix colnames `Vb' = `names'
	matrix rownames `Vb' = `names'
	matrix `rr' = `mean'[1, `K'+1..`Kp'] \ `sd'[1, `K'+1..`Kp']
	local rcn ""
	forvalues pd = 1/`nper' {
		local rcn `rcn' rate_period`pd'
	}
	matrix colnames `rr' = `rcn'
	matrix rownames `rr' = mean sd
	local nobs_keep = e(nodes)
	local nodes_keep = e(nodes)
	local waves_keep `"`e(waves)'"'
	local tm_keep = e(twomode)
	local cent_keep = e(centered)
	ereturn post `bb' `Vb', obs(`nodes_keep')
	ereturn local cmd "nwsaom_bayes"
	ereturn local title "Stochastic actor-oriented model (Bayesian: data augmentation, Metropolis-Hastings)"
	ereturn local waves `"`waves_keep'"'
	ereturn local post_frame "`frame'"
	ereturn local priors "effects: flat or normal(priormean, priorsd); rates: gamma(shape, rate), flat by default"
	ereturn scalar nodes = `nodes_keep'
	ereturn scalar nwaves = `nwaves'
	ereturn scalar has_behavior = 0
	ereturn scalar twomode = 0
	ereturn scalar centered = `cent_keep'
	ereturn scalar nwarm = `nwarm'
	ereturn scalar nmain = `nmain'
	ereturn scalar nprewarm = `nprewarm'
	ereturn scalar nrunmh = `nrunmh'
	ereturn scalar ndraws = `ndraw'
	ereturn scalar seed = `seed'
	ereturn scalar accept_effects = `acc_th'
	ereturn scalar accept_diag = `acc_dg'
	ereturn scalar accept_pair = `acc_pr'
	ereturn scalar accept_swap = `acc_sw'
	ereturn scalar mean_chain_length = `meanR'
	ereturn scalar seconds = `secs'
	ereturn matrix rates = `rr'
	ereturn matrix ess = `ess'
	ereturn matrix interval = `Q'

	if "`notable'" == "" {
		tempname EQ ES QQ
		matrix `EQ' = e(ess)
		matrix `QQ' = e(interval)
		di
		if "`noheader'" == "" {
			di as txt "Bayesian SAOM (data augmentation)" _col(50) "Number of actors  = " as res %8.0f e(nodes)
			di as txt "Waves: `waves_keep'" _col(50) "Saved draws       = " as res %8.0f e(ndraws)
			di as txt "Pre-warm `nprewarm', warm `nwarm', main `nmain' x `nrunmh'" _col(50) "Mean chain length = " as res %8.1f e(mean_chain_length)
			di as txt "Acceptance: effects " as res %5.3f `acc_th' as txt ", ministep insert/delete " as res %5.3f `acc_dg' as txt " (diagonal) " as res %5.3f `acc_pr' as txt " (pair), swap " as res %5.3f `acc_sw'
		}
		di as txt "{hline 13}{c TT}{hline 63}"
		di as txt %12s "Effect" " {c |}" %10s "Post. mean" %10s "Post. sd" %12s "[`level'% interval]" _col(58) %10s "Median" %9s "ESS"
		di as txt "{hline 13}{c +}{hline 63}"
		forvalues k = 1/`Kp' {
			if `k' <= `K' local nmk : word `k' of `names'
			else local nmk "rate_period`=`k'-`K''"
			local nmk = abbrev("`nmk'", 12)
			di as txt %12s "`nmk'" " {c |}" as res %10.4f `mean'[1, `k'] %10.4f `sd'[1, `k'] %10.4f `QQ'[1, `k'] %10.4f `QQ'[3, `k'] %10.4f `QQ'[2, `k'] %9.0f `EQ'[1, `k']
		}
		di as txt "{hline 13}{c BT}{hline 63}"
		di as txt "Draws (one per main iteration) are in frame {bf:`frame'} (b1..b`K' effects, rate1..rate`nper', nchain, loglik); flat priors unless priormean()/priorsd()/priorrate() are given."
	}
	mata: st_numscalar("__nwsaom_by_dummy", 0)
	capture scalar drop __nwsaom_by_dummy __nwsaom_by_bad __nwsaom_by_n
end
