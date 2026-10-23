*! _nwsaom_rates: helpers of nwsaom for the covariate, structural and diffusion rate effects of models with a behavior (kept out of nwsaom.ado, whose size is at Stata's limit)
*   parse   expands ratecov(): tvcov() names and the name of the behavior stay, other names are variables
*   check   the combinations that are not available
*   prep    registers the changing covariates, the behavior as a rate covariate of the network and the rate effects of the behavior (behratecov(), behrate()) for the plugin
*   fit     the estimation (co-evolution with waves())
*   post    the coefficients of the covariate rate effects: display and e()
* behratecov(list): constant covariates, changing covariates named in tvcov(), the name of the behavior (its current value)
* behrate(list): outrate inrate reciprate avexposure totexposure susceptavin infectin infectout infectdeg avtinexposuredist2 totinexposuredist2
*   totainexposuredist2 anyinexposuredist2 susceptavcovar(var) infectcovar(var); an effect can be followed by =# (a threshold), e.g. avexposure=2
capture program drop _nwsaom_rates
program define _nwsaom_rates, rclass
	version 14
	gettoken sub 0 : 0
	_nwsaom_rates_`sub' `0'
	return add
end

capture program drop _nwsaom_rates_parse
program define _nwsaom_rates_parse, rclass
	syntax , COEV(integer) [ RATECOV(string) TVCOV(string) BEHAVIOR(string) ]
	local stems ""
	if `"`tvcov'"' != "" {
		local rest `"`tvcov'"'
		while `"`rest'"' != "" {
			local bar = strpos(`"`rest'"', "|")
			if `bar' > 0 {
				local grp = strtrim(substr(`"`rest'"', 1, `bar' - 1))
				local rest = strtrim(substr(`"`rest'"', `bar' + 1, .))
			}
			else {
				local grp = strtrim(`"`rest'"')
				local rest ""
			}
			local fv : word 1 of `grp'
			local stem = ustrregexra("`fv'", "[0-9]+$", "")
			if "`stem'" == "" local stem "tv`=wordcount("`stems'")+1'"
			local stems "`stems' `stem'"
		}
	}
	local behstem ""
	if `coev' {
		local behstem : word 1 of `behavior'
		local behstem = ustrregexra("`behstem'", "[0-9]+$", "")
	}
	local out ""
	foreach t of local ratecov {
		if `: list t in stems' | ("`t'" == "`behstem'" & `coev') local out "`out' `t'"
		else {
			unab u : `t'
			local out "`out' `u'"
		}
	}
	return local ratecov = strtrim("`out'")
	return local behstem "`behstem'"
end

capture program drop _nwsaom_rates_check
program define _nwsaom_rates_check
	syntax , HASRATECOV(integer) HASBR(integer) COEV(integer) MULTI(integer) MB(integer) HASPRESENT(integer) TM(integer) HASTIMED(integer) HASMISS(integer) NSR(integer)
	if `hasbr' & !`coev' {
		di "{err}{bf:behratecov()} and {bf:behrate()} are rate effects of the behavior and need {bf:behavior()}."
		error 198
	}
	if (`hasratecov' | `hasbr') & `coev' {
		if !`multi' | `mb' {
			di "{err}the rate effects of a model with a behavior need {bf:waves()} and a single behavior."
			error 198
		}
		if (`haspresent' & !`tm') | `hastimed' | `hasmiss' {
			di "{err}the rate effects of a model with a behavior cannot yet be combined with {bf:present()}, {bf:joinat()}/{bf:leaveat()}, {bf:missnet()} or {bf:missbeh()}."
			error 198
		}
		if `nsr' > 0 {
			di "{err}the structural rate effects of the network (outrate, ...) cannot yet be combined with {bf:behavior()}; the behavior's own rate effects are {bf:behrate()}."
			error 198
		}
		if `tm' & `hasbr' {
			di "{err}{bf:behratecov()} and {bf:behrate()} are not available for a two-mode network."
			error 198
		}
	}
end

capture program drop _nwsaom_rates_prep
program define _nwsaom_rates_prep, rclass
	syntax , NODES(integer) NWAVES(integer) CENTER(integer) TM(integer) COEV(integer) HASRATECOV(integer) HASBR(integer) NRATECOV(integer) ///
		[ RATECOV(string) RATECOVCOEF(string) BEHAVIOR(string) BEHRATECOV(string) BEHRATE(string) BEHRATECOEF(string) TVNAMES(string) BEHSTEM(string) SYMMETRIC(integer 0) SYMTYPE(integer 0) ]
	local nper = `nwaves' - 1
	if `coev' & inlist(`symtype', 1, 2, 3) & (`hasratecov' | `hasbr') {
		di "{err}rate effects with a behavior are available for the non-directed model types forcing and confirmation (symtype()), not for the pairwise types joint, force and agree."
		error 198
	}
	if `coev' & "`behstem'" == "" {
		local behstem : word 1 of `behavior'
		local behstem = ustrregexra("`behstem'", "[0-9]+$", "")
	}
	// the variables behind the ratecov() columns; the changing covariates and the behavior as a covariate of the network's rate are registered for the plugin
	local rcvars "`ratecov'"
	if `hasratecov' & "`ratecov'" != "" {
		local rcvars ""
		local ci 0
		foreach t of local ratecov {
			local ++ci
			if `: list t in tvnames' {
				local v1 : word 1 of ${NWSAOM_TVV_`t'}
				local rcvars "`rcvars' `v1'"
				mata: SaomRateTVAdd(`ci', "${NWSAOM_TVV_`t'}", `nodes', `nper', `center'`=cond(`tm', ", __nwsaom_tm_actidx", "")')
			}
			else if "`t'" == "`behstem'" & `coev' {
				local v1 : word 1 of `behavior'
				local rcvars "`rcvars' `v1'"
				mata: SaomBRNetBeh(`ci')
			}
			else local rcvars "`rcvars' `t'"
		}
		local rcvars = strtrim("`rcvars'")
	}
	return local rcvars "`rcvars'"
	// the rate effects of the behavior
	local brnames ""
	local brstart ""
	local n 0
	if `hasbr' {
		foreach t of local behratecov {
			if "`t'" == "`behstem'" {
				mata: SaomBRAdd(1, 0, 0)
			}
			else if `: list t in tvnames' {
				mata: st_local("idx", strofreal(SaomBRDataTV("${NWSAOM_TVV_`t'}", `nodes', `nper', `center')))
				mata: SaomBRAdd(0, `idx', 0)
			}
			else {
				capture confirm numeric variable `t'
				if _rc {
					di "{err}behratecov(): {bf:`t'} is not a numeric variable, a changing covariate of tvcov(), or the behavior."
					exit 198
				}
				mata: st_local("idx", strofreal(SaomBRDataConst("`t'", `nodes', `center')))
				mata: SaomBRAdd(0, `idx', 0)
			}
			local ++n
			local brnames "`brnames' `t'"
		}
		local effs "outrate 2 inrate 3 reciprate 4 avexposure 10 totexposure 11 susceptavin 12 infectin 13 infectout 14 infectdeg 15 avtinexposuredist2 16 totinexposuredist2 17 totainexposuredist2 18 anyinexposuredist2 19 susceptavcovar 20 infectcovar 21"
		local rest = strlower(`"`behrate'"')
		while `"`rest'"' != "" {
			gettoken tok rest : rest
			local cov ""
			local par 0
			local eq = strpos("`tok'", "=")
			if `eq' > 0 {
				local par = real(substr("`tok'", `eq' + 1, .))
				local tok = substr("`tok'", 1, `eq' - 1)
				if `par' >= . {
					di "{err}behrate(): the parameter after = must be a number."
					exit 198
				}
			}
			local lp = strpos("`tok'", "(")
			if `lp' > 0 {
				local cov = substr("`tok'", `lp' + 1, strlen("`tok'") - `lp' - 1)
				local tok = substr("`tok'", 1, `lp' - 1)
			}
			local type 0
			forvalues i = 1(2)`=wordcount("`effs'")' {
				if "`tok'" == word("`effs'", `i') local type = real(word("`effs'", `i' + 1))
			}
			if `type' == 0 {
				di "{err}behrate(): unknown effect {bf:`tok'}."
				exit 198
			}
			if `symmetric' & !inlist(`type', 2, 10, 11, 15, 20, 21) {
				di "{err}behrate(): {bf:`tok'} is not available for a non-directed network (available: outrate, avexposure, totexposure, infectdeg, susceptavcovar(), infectcovar())."
				exit 198
			}
			if !`symmetric' & `type' == 15 {
				di "{err}behrate(): {bf:infectdeg} is an effect of a non-directed network; for a directed network use infectin or infectout."
				exit 198
			}
			if inlist(`type', 20, 21) & "`cov'" == "" {
				di "{err}behrate(): {bf:`tok'} needs the covariate, e.g. {bf:`tok'(smoke)}."
				exit 198
			}
			if !inlist(`type', 20, 21) & "`cov'" != "" {
				di "{err}behrate(): {bf:`tok'} takes no covariate."
				exit 198
			}
			local col 0
			local nm "`tok'"
			if "`cov'" != "" {
				if `: list cov in tvnames' {
					mata: st_local("col", strofreal(SaomBRDataTV("${NWSAOM_TVV_`cov'}", `nodes', `nper', `center')))
				}
				else {
					capture confirm numeric variable `cov'
					if _rc {
						di "{err}behrate(): {bf:`cov'} is not a numeric variable or a changing covariate of tvcov()."
						exit 198
					}
					mata: st_local("col", strofreal(SaomBRDataConst("`cov'", `nodes', `center')))
				}
				local nm "`tok'_`cov'"
			}
			mata: SaomBRAdd(`type', `col', `par')
			local ++n
			local brnames "`brnames' `nm'"
		}
		if `n' > 16 {
			di "{err}at most 16 rate effects of the behavior."
			exit 198
		}
		if "`behratecoef'" == "" local behratecoef "0"
		capture numlist "`behratecoef'"
		if _rc {
			di "{err}{bf:behratecoef()} must be a list of numbers (starting values of the rate-effect coefficients of the behavior)."
			exit 198
		}
		local bl "`r(numlist)'"
		local nb : word count `bl'
		if `nb' != 1 & `nb' != `n' {
			di "{err}{bf:behratecoef()} must give one starting value, or one per rate effect of the behavior (`n')."
			exit 198
		}
		forvalues i = 1/`n' {
			local v : word `=cond(`nb' == 1, 1, `i')' of `bl'
			local brstart "`brstart' `v'"
		}
	}
	return local brnames = strtrim("`brnames'")
	// starting values of all the covariate rate coefficients (the network's, then the behavior's) and the names for the convergence statistics
	local rc0 "0"
	local tn ""
	if `coev' & (`hasratecov' | `hasbr') {
		local rc0 ""
		if `hasratecov' {
			local x : subinstr local ratecovcoef "(" "", all
			local x : subinstr local x ")" "", all
			local x : subinstr local x "," " ", all
			local nx : word count `x'
			forvalues i = 1/`nratecov' {
				local xv : word `=cond(`nx' == 1, 1, `i')' of `x'
				local rc0 "`rc0' `xv'"
			}
			foreach t of local ratecov {
				local tn "`tn' ratecoef_`t'"
			}
		}
		if `hasbr' {
			local rc0 "`rc0' `brstart'"
			foreach t of local brnames {
				local tn "`tn' behratecoef_`t'"
			}
		}
		local rc0 = itrim(strtrim("`rc0'"))
		local rc0 : subinstr local rc0 " " ",", all
	}
	return local rc0 "`rc0'"
	return local tn "`tn'"
end

capture program drop _nwsaom_rates_fit
program define _nwsaom_rates_fit
	syntax , NODES(integer) NWAVES(integer) K0(integer) K3(integer) FIRSTG(real) CENTER(integer) CNSYM(integer) HASPRESENT(integer) HASRATECOV(integer) TM(integer) RC0(string) [ RCVARS(string) ]
	if !`haspresent' {
		capture mata: mata drop __nwsaom_presentmat
		mata: __nwsaom_presentmat = J(`nodes', `nwaves', 1)
	}
	mata: __nwsaom_cn_mnp = J(1, 0, NULL)
	mata: __nwsaom_cn_mbp = J(1, 0, NULL)
	if `hasratecov' mata: __nwsaom_cn_rcattr = SaomRateAttr(`nodes', "`rcvars'", `center', 0`=cond(`tm', ", __nwsaom_tm_actidx", "")')
	else mata: __nwsaom_cn_rcattr = J(0, 0, 0)
	mata: __nwsaom_fit_coevmulti = SaomEstimateRMCoevMulti(__nwsaom_last_Gwaves, __nwsaom_last_M, ///
		__nwsaom_last_Behwaves, __nwsaom_beh_minval, __nwsaom_beh_maxval, __nwsaom_last_Mbeh, ///
		__nwsaom_theta0, __nwsaom_theta0beh, `k0', `k3', `firstg', __nwsaom_presentmat, ///
		__nwsaom_cn_mnp, __nwsaom_cn_mbp, __nwsaom_last_fntype, `cnsym', __nwsaom_cn_rcattr, (`rc0'))
end

capture program drop _nwsaom_rates_post
program define _nwsaom_rates_post, eclass
	syntax , HASRATECOV(integer) HASBR(integer) [ RATECOV(string) BRNAMES(string) BEHRATECOV(string) BEHRATE(string) ]
	local n1 = cond(`hasratecov', wordcount("`ratecov'"), 0)
	local n2 = cond(`hasbr', wordcount("`brnames'"), 0)
	tempname r1 r1se r1tr r2 r2se r2tr rct
	mata: st_matrix("`rct'", __nwsaom_fit_coevmulti.rateCovTarget)
	local rcnames "`=cond(`hasratecov', "`ratecov'", "")' `=cond(`hasbr', "`brnames'", "")'"
	matrix colnames `rct' = `rcnames'
	ereturn matrix rc_target = `rct'
	if `n1' > 0 {
		mata: st_matrix("`r1'", __nwsaom_fit_coevmulti.rateCov[1..`n1'])
		mata: st_matrix("`r1se'", __nwsaom_fit_coevmulti.rateCovSE[1..`n1'])
		mata: st_matrix("`r1tr'", __nwsaom_fit_coevmulti.rateCovTratio[1..`n1'])
		foreach m in r1 r1se r1tr {
			matrix colnames ``m'' = `ratecov'
		}
		local k 0
		foreach v of local ratecov {
			local ++k
			di as text "Covariate-rate coefficient of the network (" as result "`v'" as text "): " as result %9.4f `r1'[1,`k'] as text " (se " as result %6.4f `r1se'[1,`k'] as text ")"
		}
		if `n1' == 1 {
			ereturn scalar ratecoef = `r1'[1,1]
			ereturn scalar ratecoef_se = `r1se'[1,1]
			ereturn scalar ratecoef_tratio = `r1tr'[1,1]
		}
		ereturn local ratecov "`ratecov'"
		ereturn matrix ratecoefs = `r1', copy
		ereturn matrix ratecoefs_se = `r1se', copy
		ereturn matrix ratecoefs_tratio = `r1tr', copy
	}
	if `n2' > 0 {
		mata: st_matrix("`r2'", __nwsaom_fit_coevmulti.rateCov[`=`n1'+1'..`=`n1'+`n2''])
		mata: st_matrix("`r2se'", __nwsaom_fit_coevmulti.rateCovSE[`=`n1'+1'..`=`n1'+`n2''])
		mata: st_matrix("`r2tr'", __nwsaom_fit_coevmulti.rateCovTratio[`=`n1'+1'..`=`n1'+`n2''])
		foreach m in r2 r2se r2tr {
			matrix colnames ``m'' = `brnames'
		}
		local k 0
		foreach v of local brnames {
			local ++k
			di as text "Rate effect of the behavior (" as result "`v'" as text "): " as result %9.4f `r2'[1,`k'] as text " (se " as result %6.4f `r2se'[1,`k'] as text ")"
		}
		if `n2' == 1 {
			ereturn scalar behratecoef = `r2'[1,1]
			ereturn scalar behratecoef_se = `r2se'[1,1]
			ereturn scalar behratecoef_tratio = `r2tr'[1,1]
		}
		ereturn local behratecov "`behratecov'"
		ereturn local behrate "`behrate'"
		ereturn matrix behratecoefs = `r2', copy
		ereturn matrix behratecoefs_se = `r2se', copy
		ereturn matrix behratecoefs_tratio = `r2tr', copy
	}
end
