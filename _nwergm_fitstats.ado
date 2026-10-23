*! _nwergm_fitstats: log-likelihood, deviance, AIC/BIC of an nwergm fit (R: logLik.ergm, summary.ergm)
capture program drop _nwergm_fitstats
program _nwergm_fitstats, eclass
	version 14
	capture confirm number 0
	syntax , DMAT(string) METHOD(string) [PROPFN(string) NOLOGLIK BRIDGESTEPS(integer 16) BRIDGESAMPLESIZE(integer 0) ///
		BRIDGEINTERVAL(integer 0) MCMCBURNIN(integer 3000) MCMCINTERVAL(integer 50) MCMCSAMPLESIZE(integer 3000) ///
		INTERVALFINAL(integer 0) CURVED(integer 0) DIND(integer 1) QUIET]
	tempname b ll se
	matrix `b' = e(b)
	local N = e(N)
	mata: st_numscalar("`ll'", .)
	mata: st_numscalar("`se'", 0)
	mata: __ergm_fs_b = st_matrix("`b'")
	if `curved' mata: __ergm_fs_b = __nwergm_last_M.theta_to_eta(__ergm_fs_b)
	local how "pseudolikelihood"
	if "`method'" == "mple" {
		mata: st_numscalar("`ll'", ergm_mple_ll(`dmat', __ergm_fs_b))
		if `dind' local how "exact"
	}
	else if "`nologlik'" == "" & !`curved' {
		if `bridgesamplesize' <= 0 local bridgesamplesize = `mcmcsamplesize'
		if `bridgeinterval' <= 0 {
			local bi = `mcmcinterval'
			if `intervalfinal' > 0 local bi = `intervalfinal'
			local bridgeinterval = max(1, ceil(`bi'/`bridgesteps'))
		}
		local between = max(ceil(`mcmcburnin'/sqrt(`bridgesteps')), `mcmcinterval'*16)
		di as txt "Evaluating log-likelihood at the estimate (bridge sampling with `bridgesteps' bridges) ..."
		mata: __ergm_fs_d = ergm_dind_submodel(__nwergm_last_M, `dmat')
		mata: __ergm_fs_r = ergm_bridge_llr(__nwergm_last_M, __nwergm_last_G, __ergm_fs_b, __ergm_fs_d[2..cols(__ergm_fs_d)], ///
			__ergm_obsstat, `bridgesteps', `mcmcburnin', `between', `bridgeinterval', `bridgesamplesize', `propfn')
		mata: st_numscalar("`ll'", __ergm_fs_d[1] + __ergm_fs_r[1])
		mata: st_numscalar("`se'", sqrt(__ergm_fs_r[2]))
		mata: mata drop __ergm_fs_d __ergm_fs_r
		local how "bridge sampling"
	}
	mata: mata drop __ergm_fs_b
	if missing(scalar(`ll')) {
		exit
	}
	mata: st_local("nfix", strofreal(sum(__nwergm_last_M.isfixed)))
	local k = colsof(`b') - `nfix'
	if `curved' local k = colsof(`b')
	tempname ll0
	scalar `ll0' = `N' * ln(0.5)
	ereturn scalar ll = scalar(`ll')
	ereturn scalar ll_0 = scalar(`ll0')
	ereturn scalar ll_se = scalar(`se')
	ereturn scalar df_m = `k'
	ereturn scalar rank = `k'
	ereturn scalar df_resid = `N' - `k'
	ereturn scalar deviance = -2 * scalar(`ll')
	ereturn scalar deviance_0 = -2 * scalar(`ll0')
	ereturn scalar aic = -2 * scalar(`ll') + 2 * `k'
	ereturn scalar bic = -2 * scalar(`ll') + ln(`N') * `k'
	ereturn local ll_method "`how'"
	ereturn local predict "nwergm_p"
	if "`quiet'" == "" {
		di
		local pd = cond("`how'" == "pseudolikelihood", "Pseudo-", "")
		local pdl = cond("`pd'" == "", "", "d")
		di as txt %28s "Null `pd'`=cond("`pd'"=="","D","d")'eviance: " as res %9.1f e(deviance_0) as txt "  on " as res `N' as txt " degrees of freedom"
		di as txt %28s "Residual `pd'`=cond("`pd'"=="","D","d")'eviance: " as res %9.1f e(deviance) as txt "  on " as res `N' - `k' as txt " degrees of freedom"
		di
		di as txt "Log-likelihood: " as res %10.4f e(ll) as txt " (df = `k')   AIC: " as res %9.1f e(aic) as txt "   BIC: " as res %9.1f e(bic) ///
			as txt "   (MC std. err. = " as res %7.5g e(ll_se) as txt ")"
		if "`method'" == "mple" & "`how'" != "exact" {
			di as txt "(For a dyad-dependent model fitted by MPLE this is the pseudolikelihood, as in R.)"
		}
	}
end
