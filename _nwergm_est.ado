*! _nwergm_est.ado -- estimation-method helpers for nwergm (MPLE variants, starting values, control options)
capture program drop _nwergm_est
program _nwergm_est
	gettoken __sub 0 : 0
	_nwergm_est_`__sub' `0'
end

capture program drop _nwergm_est_opts
program _nwergm_est_opts, sclass
	syntax [, estimate(string) method(string) mainmethod(string) mpletype(string) mplecovariance(string) mcmletermination(string) mplecheck(string)]
	sreturn clear
	if "`estimate'" != "" {
		local estimate = lower("`estimate'")
		_opts_oneof "mle mple cd" "estimate" "`estimate'" 198
		if "`method'" != "" & !("`estimate'" == "mle" & "`method'" == "mcmle") & "`estimate'" != "`method'" {
			di "{err}options {bf:estimate()} and {bf:method()} contradict each other; use one of them."
			exit 198
		}
		if "`estimate'" == "mple" local method "mple"
		if "`estimate'" == "cd" local method "cd"
		if "`estimate'" == "mle" & "`method'" == "" local method ""
	}
	if "`method'" != "" {
		local method = lower("`method'")
		_opts_oneof "mple mcmle cd" "method" "`method'" 198
	}
	if "`mainmethod'" == "" local mainmethod "mcmle"
	local mainmethod = lower("`mainmethod'")
	if inlist("`mainmethod'", "stochastic-approximation", "stochastic", "sa") local mainmethod "sa"
	_opts_oneof "mcmle sa" "mainmethod" "`mainmethod'" 198
	if "`mpletype'" == "" local mpletype "glm"
	local mpletype = lower("`mpletype'")
	_opts_oneof "glm penalized" "mpletype" "`mpletype'" 198
	if "`mplecovariance'" == "" local mplecovariance "invhess"
	local mplecovariance = lower("`mplecovariance'")
	_opts_oneof "invhess godambe" "mplecovariance" "`mplecovariance'" 198
	if "`mcmletermination'" == "" local mcmletermination "confidence"
	local mcmletermination = lower("`mcmletermination'")
	_opts_oneof "confidence hummel hotelling none" "mcmletermination" "`mcmletermination'" 198
	if "`mplecheck'" == "" local mplecheck "on"
	local mplecheck = lower("`mplecheck'")
	_opts_oneof "on off" "mplecheck" "`mplecheck'" 198
	sreturn local mplecheck "`mplecheck'"
	sreturn local method "`method'"
	sreturn local mainmethod "`mainmethod'"
	sreturn local mpletype "`mpletype'"
	sreturn local mplecovariance "`mplecovariance'"
	sreturn local mcmletermination "`mcmletermination'"
end

capture program drop _nwergm_est_init
program _nwergm_est_init, rclass
	// parses init(): one value per coefficient, "." or NA = not given.
	// Offset coefficients take their value from init() (as in R); other given values are
	// starting values for the MCMLE (held fixed during the pseudolikelihood step that finds the rest).
	args init method
	local n : word count `init'
	mata: st_local("p", strofreal(__nwergm_last_M.nparam()))
	if `n' != `p' {
		di "{err}option {bf:init()} needs one value per coefficient (`p' here, `n' given); use . or NA for a value to be estimated."
		exit 198
	}
	mata: __e7_init = J(1, `p', .)
	local k 0
	foreach tok of local init {
		local ++k
		if inlist(upper("`tok'"), "NA", ".") continue
		capture confirm number `tok'
		if _rc {
			di "{err}option {bf:init()}: `tok' is not a number (use . or NA for a value to be estimated)."
			exit 198
		}
		mata: __e7_init[`k'] = `tok'
	}
	// offsets: init() value overrides the offset() value
	mata: __e7_ov = selectindex(__nwergm_last_M.isfixed :& (__e7_init :< .))
	mata: __e7_fv = __nwergm_last_M.fixedvalue
	mata: __e7_fv[__e7_ov] = __e7_init[__e7_ov]
	mata: __nwergm_last_M.fixedvalue = __e7_fv
	mata: mata drop __e7_fv
	mata: mata drop __e7_ov
	mata: st_local("nstart", strofreal(sum((!__nwergm_last_M.isfixed) :& (__e7_init :< .))))
	mata: st_local("nfreeall", strofreal(sum(!__nwergm_last_M.isfixed)))
	local mode 0
	if `nstart' > 0 & "`method'" != "mple" {
		local mode = cond(`nstart' == `nfreeall', 2, 1)
		if `mode' == 1 {
			// fix the given starting values during the pseudolikelihood step
			mata: __e7_tmpfix = selectindex((1 :- __nwergm_last_M.isfixed) :& (__e7_init :< .)); for (k=1; k<=cols(__e7_tmpfix); k++) __nwergm_last_M.mark_fixed(__e7_tmpfix[k], __e7_init[__e7_tmpfix[k]])
		}
	}
	return scalar mode = `mode'
end

capture program drop _nwergm_est_mple
program _nwergm_est_mple, rclass
	// Firth-penalised MPLE (MPLE.type="penalized") and the MPLE existence check (MPLE.check).
	// Posts bname/Vname (free coefficients only) and returns r(special)=1 when it fitted the model itself.
	args dname bname vname mpletype nocheck hasoffset method
	local special 0
	local ok 1
	mata: __e7_p = cols(`dname') - 1
	mata: st_local("allsame", strofreal(sum(`dname'[., __e7_p+1]) == 0 | sum(`dname'[., __e7_p+1]) == rows(`dname')))
	if `allsame' {
		mata: mata drop __e7_p
		return scalar special = 0
		return scalar exists = 1
		exit
	}
	mata: __e7_fidx = __nwergm_last_M.freeidx()
	mata: __e7_Df = `dname'[., (__e7_fidx, __e7_p + 1)]
	mata: __e7_off = `dname'[., 1..__e7_p] * (__nwergm_last_M.isfixed :* __nwergm_last_M.fixedvalue)'
	if "`mpletype'" == "penalized" {
		if `hasoffset' {
			di "{err}option {bf:mpletype(penalized)} cannot be combined with {bf:offset()}."
			mata: mata drop __e7_p __e7_fidx __e7_Df __e7_off
			exit 198
		}
		mata: st_local("it", strofreal(ergm_pen_glm(__e7_Df, "`bname'", "`vname'")))
		local special 1
	}
	else {
		if "`nocheck'" == "on" mata: st_local("ok", strofreal(ergm_mple_exists(__e7_Df)))
		if !`ok' di "{err}Warning: The MPLE does not exist!"
		// as a starting value for MCMLE the pseudolikelihood fit is left to logit, which drops perfectly predicted terms
		if (!`ok' & "`method'" == "mple") | "`nocheck'" == "off" {
			mata: st_local("cv", strofreal(ergm_glm_irls(__e7_Df, "`bname'", "`vname'", __e7_off)))
			local special 1
		}
	}
	mata: mata drop __e7_p __e7_fidx __e7_Df __e7_off
	return scalar special = `special'
	return scalar exists = `ok'
end

capture program drop _nwergm_est_ctl
program _nwergm_est_ctl
	// passes the MCMLE control settings (control.ergm MCMLE.*) to the Mata fitting routine
	syntax , termination(string) confidence(real) steplength(real) margin(real) effsize(real)
	local tcode = cond("`termination'" == "confidence", 1, cond("`termination'" == "hummel", 2, cond("`termination'" == "hotelling", 3, 4)))
	if `confidence' <= 0 | `confidence' >= 1 {
		di "{err}option {bf:mcmleconfidence()} must be strictly between 0 and 1."
		exit 198
	}
	if `tcode' == 2 & (`margin' >= . | `steplength' != 1) {
		di "{err}Hummel termination requires a non-missing {bf:mcmlestepmargin()} and {bf:mcmlesteplength(1)}."
		exit 198
	}
	if `effsize' < 0 local effsize .
	mata: ergm_ctl = (`tcode', `confidence', `steplength', `margin', `effsize', 0.5)
end
