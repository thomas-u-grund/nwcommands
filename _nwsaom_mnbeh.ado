*! _nwsaom_mnbeh - translates the behavior effect lists beheff1() / beheff2() of nwsaom multinet that name covariates, shape effects or further network effects
*! (family:variable, shape[:#]) into the effect tokens of the behavior model, and registers the covariates
capture program drop _nwsaom_mnbeh
program define _nwsaom_mnbeh, rclass
	version 14
	syntax , NODES(integer) [ EFF1(string) EFF2(string) ]
	local bxfam "avxinalt totxinalt avxrecalt totxrecalt avsamexinalt totsamexinalt avsamexrecalt totsamexrecalt avaltsamex totaltsamex avrecaltsamex totrecaltsamex avaltaltx avsimaltx totsimaltx minxalt maxxalt degabscontrx degposcontrx degnegcontrx avxaltdist2 totxaltdist2 avtxaltdist2 totaxaltdist2 avxinaltdist2 totxinaltdist2 avtxinaltdist2 totaxinaltdist2 avsimegox totsimegox avaltegox totaltegox"
	local xfam "from avxalt avsamexalt totxalt totsamexalt"
	local xpre "effcov avxalt avsamexalt totxalt totsamexalt"
	local shfam "quad_cc quad_nc constant threshold simallnear simallfar avgroup totgroup"
	local bufam "indegavgroup indegtotgroup avaltcc totaltcc avinaltdist2nc totinaltdist2nc avtinaltdist2nc totainaltdist2nc avinsimdist2 totinsimdist2 totgwdspffalt totgwdspfbalt totgwdspffaltnc totgwdspfbaltnc varalt avsimvaralt behdensetriads simdensetriads"
	capture mata: mata drop __saom_behcov __saom_behcovnames __saom_behcovoff __saom_behcovper __saom_behcov_pd __saom_behcovmean __saom_behcovdyn
	// pass 1: the covariates, in order of appearance
	local covs ""
	forvalues k = 1/2 {
		foreach t of local eff`k' {
			gettoken f vv : t, parse(":")
			local vv = subinstr("`vv'", ":", "", 1)
			if `: list posof "`f'" in bxfam' | `: list posof "`f'" in xfam' {
				if "`vv'" == "" {
					di "{err}beheff`k'(): `t' needs a covariate, e.g. {bf:`f':varname}."
					error 198
				}
				local covs "`covs' `vv'"
			}
		}
	}
	local covs : list uniq covs
	if `: word count `covs'' > 8 {
		di "{err}beheff1()/beheff2(): at most 8 different covariates."
		error 198
	}
	// pass 2: the tokens
	forvalues k = 1/2 {
		local out`k' ""
		foreach t of local eff`k' {
			gettoken f vv : t, parse(":")
			local vv = subinstr("`vv'", ":", "", 1)
			if `: list posof "`f'" in xfam' {
				local slot : list posof "`vv'" in covs
				local fi : list posof "`f'" in xfam
				local pre : word `fi' of `xpre'
				local out`k' "`out`k'' `pre'`slot'"
			}
			else if `: list posof "`f'" in bxfam' {
				local slot : list posof "`vv'" in covs
				local fi : list posof "`f'" in bxfam
				local out`k' "`out`k'' bs`=`fi'-1'_`slot'"
			}
			else if `: list posof "`f'" in shfam' {
				local fi : list posof "`f'" in shfam
				if "`vv'" == "" {
					// RSiena's default parameters: simAllNear 2, simAllFar 4, avGroup / totGroup 1; the threshold has none
					if `fi' == 4 {
						di "{err}beheff`k'(): threshold needs the threshold, e.g. {bf:threshold:3}."
						error 198
					}
					else if `fi' == 5 local vv 2
					else if `fi' == 6 local vv 4
					else if inlist(`fi', 7, 8) local vv 1
					else local vv 0
				}
				else if !inlist(`fi', 4, 5, 6, 7, 8) {
					di "{err}beheff`k'(): `f' takes no parameter."
					error 198
				}
				capture confirm integer number `vv'
				if _rc | real("`vv'") < 0 | real("`vv'") > 99 {
					di "{err}beheff`k'(): the parameter of `f' must be an integer from 0 to 99."
					error 198
				}
				local out`k' "`out`k'' sh`=`fi'-1'_`vv'"
			}
			else if `: list posof "`f'" in bufam' {
				local fi : list posof "`f'" in bufam
				if "`vv'" == "" {
					if inlist(`fi', 1, 2) local vv 1
					else if `fi' >= 17 local vv 5
					else if `fi' >= 15 local vv 0
					else if `fi' >= 11 local vv 69
					else local vv 0
				}
				capture confirm integer number `vv'
				if _rc | real("`vv'") < 0 | real("`vv'") > 99 {
					di "{err}beheff`k'(): the parameter of `f' must be an integer from 0 to 99."
					error 198
				}
				local out`k' "`out`k'' bu`=`fi'-1'_`vv'"
			}
			else if "`vv'" != "" {
				di "{err}beheff`k'(): `t' is not an effect; covariate effects: `xfam' `bxfam'; shape effects: `shfam'; network effects: `bufam'."
				error 198
			}
			else local out`k' "`out`k'' `f'"
		}
	}
	if "`covs'" != "" {
		mata: SaomBehCovInit()
		foreach v of local covs {
			capture confirm numeric variable `v'
			if _rc {
				di "{err}beheff1()/beheff2(): `v' is not a numeric variable."
				error 198
			}
			mata: SaomBehCovAdd("`v'", "`v'", 1)
		}
	}
	return local eff1 `out1'
	return local eff2 `out2'
	return local covs `covs'
end
