*! _nwergm_coeflabel: rename coefficients (R's Label() operator)
capture program drop _nwergm_coeflabel
program _nwergm_coeflabel
	version 14
	local n : word count `0'
	if mod(`n', 2) {
		di "{err}option {bf:coeflabel()} needs oldname/newname pairs; got an odd number of words."
		error 198
	}
	forvalues k = 1(2)`n' {
		local old : word `k' of `0'
		local new : word `=`k'+1' of `0'
		capture confirm name `new'
		if _rc {
			di "{err}option {bf:coeflabel()}: {bf:`new'} is not a valid coefficient name."
			error 198
		}
		mata: st_local("__pos", strofreal(__nwergm_last_M.findcoef("`old'")))
		if `__pos' == 0 {
			di "{err}option {bf:coeflabel()}: `old' is not a coefficient name in this model."
			error 198
		}
		mata: __nwergm_last_M.coefnames[`__pos'] = "`new'"
	}
end

