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
	syntax [, NPREWARM(integer 50) NWARM(integer 50) NMAIN(integer 250) NRUNMH(integer 20) NIMPROVEMH(integer 100) MHGEOM(real 0) MULT(real 5) TARGETMH(real 0.25) ///
		NMH(integer 0) NSAMPCONST(integer 1) NSAMPRATES(integer 0) THETA0(numlist) RATE0(numlist >0) FIXRATES ///
		SEED(integer -1) PRIORMEANETA(numlist) PRIORSIGETA(numlist >0) RATEPRIORMEAN(numlist) RATEPRIORSD(real 1) GIBBSRATES PRIORRATE(numlist min=2 max=2 >=0) ///
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
	if e(twomode) == 1 | `"`e(symtype)'"' != "" | `"`e(ratecov)'"' != "" {
		di as err "nwsaom bayes covers one directed one-mode network with at most one co-evolving behavior, without two-mode data, non-directed models or rate covariates."
		exit 198
	}
	mata: st_numscalar("__nwsaom_by_bad", any(_SaomGofExt("__nwsaom_last_fntype", J(1, 0, 0)) :!= 0) | rows(_SaomGofExt("__nwsaom_last_present", J(0, 1, 0))) > 0 | rows(_SaomGofExt("__nwsaom_last_struct", J(0, 0, 0))) > 0)
	if scalar(__nwsaom_by_bad) == 1 {
		di as err "nwsaom bayes does not cover endowment/creation effects, present()/joinat()/leaveat(), structural() or missing-data options."
		exit 198
	}
	if `nprewarm' < 0 | `nwarm' < 0 | `nmain' < 1 | `nrunmh' < 1 | `nsampconst' < 0 | `nsamprates' < 0 | `nmh' < 0 | `nimprovemh' < 0 | `mult' <= 0 {
		di as err "nprewarm(), nwarm(), nimprovemh() must be >= 0 and nmain(), nrunmh(), nsampconst(), mult() positive."
		exit 198
	}
	local nwaves = e(nwaves)
	local nper = `nwaves' - 1
	tempname b V rt Vp
	matrix `b' = e(b)
	matrix `V' = e(V)
	local names : colnames `b'
	local K = colsof(`b')
	local coev = (e(has_behavior) == 1)
	local pnet = e(p_net)
	local nvar = 1 + `coev'
	local NR = `nper' * `nvar'
	_nwsaom_getrates `nper' `coev'
	matrix `rt' = r(rt)
	tempname rse
	matrix `rse' = r(se)
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
		if `: word count `rate0'' != `NR' {
			di as err "rate0() takes one value per period and dependent variable (`NR')."
			exit 198
		}
		forvalues pd = 1/`NR' {
			matrix `rt'[1, `pd'] = `: word `pd' of `rate0''
		}
	}
	if `seed' < 0 local seed = floor(runiform() * 1e9) + 1

	// priors as multi_siena: the effects have a flat prior unless priormeaneta()/priorsigeta() (a variance) give a normal prior; the rates have
	// a normal prior with mean the initial rate estimate and variance 1 (multi_siena's one-group value; ratepriorsd(0): flat), sampled by a
	// Metropolis step; gibbsrates draws them from the gamma full conditional instead (priorrate(shape rate), default flat)
	local pm ""
	local ps ""
	local nm : word count `priormeaneta'
	local ns : word count `priorsigeta'
	if `nm' != 0 & `nm' != 1 & `nm' != `K' {
		di as err "priormeaneta() takes one value or one value per effect (`K')."
		exit 198
	}
	if `ns' != 0 & `ns' != 1 & `ns' != `K' {
		di as err "priorsigeta() takes one value or one value per effect (`K')."
		exit 198
	}
	forvalues k = 1/`K' {
		local m = 0
		if `nm' == 1 local m : word 1 of `priormeaneta'
		else if `nm' == `K' local m : word `k' of `priormeaneta'
		local s = 0
		if `ns' == 1 local s = sqrt(`: word 1 of `priorsigeta'')
		else if `ns' == `K' local s = sqrt(`: word `k' of `priorsigeta'')
		local pm `pm' `m'
		local ps `ps' `s'
	}
	local ratemode = 0
	if "`gibbsrates'" != "" | "`priorrate'" != "" local ratemode = 1
	if "`fixrates'" != "" local ratemode = 2
	local pshape 1
	local prate 0
	if "`priorrate'" != "" {
		local pshape : word 1 of `priorrate'
		local prate : word 2 of `priorrate'
	}
	local rpm ""
	local rps ""
	local rsdl ""
	forvalues pd = 1/`NR' {
		local m = `rt'[1, `pd']
		if "`ratepriormean'" != "" local m : word `pd' of `ratepriormean'
		local rpm `rpm' `m'
		local rps `rps' `ratepriorsd'
		local sdp = `rse'[1, `pd']
		if missing(`sdp') | `sdp' <= 0 local sdp = 0.15 * `rt'[1, `pd']
		local rsdl `rsdl' `sdp'
	}
	if "`frame'" == "" local frame nwsaom_bayes_draws

	// the random-walk proposal starts at the fit's covariance matrix (the scale factor 2.38^2/K is applied by the sampler), or 0.01 * I when that is unusable
	matrix `Vp' = `V'
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
	if `coev' {
		forvalues pd = 1/`nper' {
			local vn `vn' brate`pd'
		}
	}
	local vn `vn' nchain loglik
	if `coev' local mbs "__nwsaom_last_Mbeh, __nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval"
	else {
		capture mata: mata drop __nwsaom_by_Mb0 __nwsaom_by_Bw0
		mata: __nwsaom_by_Mb0 = SaomBehaviorModel()
		mata: __nwsaom_by_Bw0 = J(1, 0, NULL)
		local mbs "__nwsaom_by_Mb0, __nwsaom_by_Bw0, 0, 0"
	}
	mata: __nwsaom_by_Gs = (`gs')
	mata: __nwsaom_by_names = tokens("`vn'")
	mata: __nwsaom_by_th = st_matrix("`b'")
	mata: __nwsaom_by_V = st_matrix("`Vp'")
	mata: __nwsaom_by_rho = st_matrix("`rt'")
	mata: __nwsaom_by_pm = strtoreal(tokens("`pm'"))
	mata: __nwsaom_by_ps = strtoreal(tokens("`ps'"))
	mata: __nwsaom_by_rpm = strtoreal(tokens("`rpm'"))
	mata: __nwsaom_by_rps = strtoreal(tokens("`rps'"))
	mata: __nwsaom_by_rsd = strtoreal(tokens("`rsdl'"))
	di as txt "Sampling: `nprewarm' pre-warming + `nwarm' warming + `nmain' main iterations of `nrunmh' batches ..."
	mata: st_numscalar("__nwsaom_by_n", SaomBayesRun(__nwsaom_by_Gs, `nper', __nwsaom_last_M, `coev', `mbs', __nwsaom_by_th, __nwsaom_by_V, __nwsaom_by_rho, __nwsaom_by_pm, __nwsaom_by_ps, __nwsaom_by_rpm, __nwsaom_by_rps, `pshape', `prate', __nwsaom_by_rsd, `nprewarm', `nwarm', `nmain', `nrunmh', `nimprovemh', `nmh', `nsampconst', `nsamprates', `seed', `mult', `targetmh', `ratemode', `mhgeom', "`frame'", __nwsaom_by_names))
	capture mata: mata drop __nwsaom_by_Mb0 __nwsaom_by_Bw0 __nwsaom_by_Gs __nwsaom_by_names __nwsaom_by_th __nwsaom_by_V __nwsaom_by_rho __nwsaom_by_pm __nwsaom_by_ps __nwsaom_by_rpm __nwsaom_by_rps __nwsaom_by_rsd
	local ndraw = scalar(__nwsaom_by_n)
	local acc_th = scalar(__saom_bayes_acc_theta)
	local acc_dg = scalar(__saom_bayes_acc_diag)
	local acc_pe = scalar(__saom_bayes_acc_permute)
	local acc_ip = scalar(__saom_bayes_acc_insperm)
	local acc_dp = scalar(__saom_bayes_acc_delperm)
	local acc_ra = scalar(__saom_bayes_acc_rates)
	local meanR = scalar(__saom_bayes_meanR)
	local secs = scalar(__saom_bayes_secs)
	if `ndraw' < 2 {
		di as err "too few draws saved."
		exit 498
	}
	local Kp = `K' + `NR'
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
	tempname rrb
	matrix `rr' = `mean'[1, `K'+1..`K'+`nper'] \ `sd'[1, `K'+1..`K'+`nper']
	local rcn ""
	forvalues pd = 1/`nper' {
		local rcn `rcn' rate_period`pd'
	}
	matrix colnames `rr' = `rcn'
	matrix rownames `rr' = mean sd
	if `coev' {
		matrix `rrb' = `mean'[1, `K'+`nper'+1..`Kp'] \ `sd'[1, `K'+`nper'+1..`Kp']
		matrix colnames `rrb' = `rcn'
		matrix rownames `rrb' = mean sd
	}
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
	ereturn scalar has_behavior = `coev'
	ereturn scalar p_net = `pnet'
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
	ereturn scalar accept_rates = `acc_ra'
	ereturn scalar accept_permute = `acc_pe'
	ereturn scalar accept_insperm = `acc_ip'
	ereturn scalar accept_delperm = `acc_dp'
	ereturn scalar scale_effects = scalar(__saom_bayes_scale_eta)
	ereturn scalar scale_rates = scalar(__saom_bayes_scale_rate)
	ereturn scalar mean_chain_length = `meanR'
	ereturn scalar seconds = `secs'
	ereturn matrix rates = `rr'
	if `coev' ereturn matrix rates_beh = `rrb'
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
			di as txt "Acceptance: effects " as res %5.3f `acc_th' as txt ", rates " as res %5.3f `acc_ra' as txt "; chain steps: diagonal " as res %5.3f `acc_dg' as txt ", permute " as res %5.3f `acc_pe' as txt ", insert-permute " as res %5.3f `acc_ip' as txt ", delete-permute " as res %5.3f `acc_dp'
		}
		di as txt "{hline 13}{c TT}{hline 63}"
		di as txt %12s "Effect" " {c |}" %10s "Post. mean" %10s "Post. sd" %12s "[`level'% interval]" _col(58) %10s "Median" %9s "ESS"
		di as txt "{hline 13}{c +}{hline 63}"
		forvalues k = 1/`Kp' {
			if `k' <= `K' local nmk : word `k' of `names'
			else if `k' <= `K' + `nper' local nmk "rate_period`=`k'-`K''"
			else local nmk "brate_period`=`k'-`K'-`nper''"
			local nmk = abbrev("`nmk'", 12)
			di as txt %12s "`nmk'" " {c |}" as res %10.4f `mean'[1, `k'] %10.4f `sd'[1, `k'] %10.4f `QQ'[1, `k'] %10.4f `QQ'[3, `k'] %10.4f `QQ'[2, `k'] %9.0f `EQ'[1, `k']
		}
		di as txt "{hline 13}{c BT}{hline 63}"
		di as txt "Draws (one per main iteration) are in frame {bf:`frame'} (b1..b`K' effects, rate1..rate`nper'`=cond(`coev', ", brate1..brate`nper'", "")', nchain, loglik); flat priors unless priormean()/priorsd()/priorrate() are given."
	}
	mata: st_numscalar("__nwsaom_by_dummy", 0)
	capture scalar drop __nwsaom_by_dummy __nwsaom_by_bad __nwsaom_by_n
end
