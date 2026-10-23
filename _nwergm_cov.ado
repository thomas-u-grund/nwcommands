*! _nwergm_cov: covariate-term registration helper for nwergm (R ergm's nodemix, ...)
capture program drop _nwergm_cov
program _nwergm_cov, rclass
	version 14
	syntax anything(name=term), SPEC(string) NODES(integer) DIRECTED(string) [TWOMODE(string)]
	if "`twomode'" == "true" {
		di "{err}{bf:`term'()} is not available for two-mode networks."
		error 198
	}
	local isdir = ("`directed'" == "true")
	local 0 `"`spec'"'
	syntax anything(name=vars) [, LEVels(numlist) LEVELValues(numlist) BASE(numlist) LEVELS2(numlist)]
	local temps ""
	foreach v of local vars {
		_nwergm_covattr `v', term(`term') nodes(`nodes')
		local av "`r(var)'"
		local vn "`r(name)'"
		tempname td
		mata: `td' = ErgmTermData()
		mata: `td'.attr = st_data(1::`nodes', "`av'")
		if "`term'" == "nodemix" {
			mata: _ergm_nodemix_setup(`td', `isdir', "`levels'", "`levelvalues'", "`base'", "`levels2'", "`vn'", "__ergm_cn", "__ergm_nc")
			if `__ergm_nc' > 0 {
				if `isdir' {
					mata: __nwergm_last_M.addterm("nodemixd", `__ergm_nc', &stat_nodemixd(), &change_nodemixd(), `td', tokens("`__ergm_cn'"))
				}
				else {
					mata: __nwergm_last_M.addterm("nodemix", `__ergm_nc', &stat_nodemix(), &change_nodemix(), `td', tokens("`__ergm_cn'"))
				}
			}
		}
		local temps "`temps' `td'"
	}
	return local temps "`temps'"
end

capture program drop _nwergm_covattr
program _nwergm_covattr, rclass
	syntax anything(name=v), TERM(string) NODES(integer)
	capture confirm variable `v'
	if _rc {
		tempvar t
		capture quietly generate double `t' = `v' in 1/`nodes'
		if _rc {
			di "{err}{bf:`term'(`v')}: `v' is neither a variable nor a valid expression."
			error 111
		}
		local nm = subinstr(subinstr(subinstr(subinstr("`v'","(","_",.),")","",.)," ","",.),"^","p",.)
		local v "`t'"
	}
	else {
		local nm "`v'"
	}
	capture confirm numeric variable `v'
	if _rc {
		di "{err}{bf:`term'(`nm')}: {bf:`nm'} is a string variable; nwergm needs a numeric attribute."
		di "{err}Encode it first, e.g. {bf:encode `nm', generate(`nm'_n)}, and specify {bf:`term'(`nm'_n)}."
		error 109
	}
	quietly count if missing(`v') in 1/`nodes'
	if r(N) > 0 {
		di "{err}In term {bf:`term'}: attribute {bf:`nm'} has missing data, which is not currently supported."
		error 198
	}
	return local var "`v'"
	return local name "`nm'"
end
