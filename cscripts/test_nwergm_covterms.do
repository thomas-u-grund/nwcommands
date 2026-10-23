cscript

quietly do unw_core.do
quietly do unw_ergm.do

* Covariate-term certification against R ergm 4.12.0 (agent E4).
* References: dev/covterms/ref.R (generator), dev/covterms/data/ref.csv (R
* summary() statistics and MPLE coefficients/SEs), dev/covterms/spec.csv
* (id, network, nwergm option string, R term string).  For every spec:
* (a) the observed statistic of nwergm equals R's summary(), (b) the MPLE
* coefficients and standard errors equal R's ergm(estimate="MPLE") to 1e-4.
* Prerequisite: unw_core.do and unw_ergm.do loaded, nwergm on the adopath.

capture program drop _cov_load
program define _cov_load
	args net dir directed
	qui nwclear
	qui clear
	qui import delimited "`dir'/net_`net'_adj.csv", clear
	qui mkmat v*, mat(_A)
	qui import delimited "`dir'/net_`net'_ec.csv", clear
	qui mkmat v*, mat(_E)
	qui import delimited "`dir'/net_`net'_nodes.csv", clear
	qui ds
	local vn `r(varlist)'
	mata: _Nm = st_data(., .)
	qui clear
	if "`directed'" == "1" {
		qui nwset, mat(_A) directed name(`net')
		qui nwset, mat(_E) directed name(`net'ec)
	}
	else {
		qui nwset, mat(_A) undirected name(`net')
		qui nwset, mat(_E) undirected name(`net'ec)
	}
	foreach v of local vn {
		qui gen double `v' = .
	}
	mata: st_store(1::rows(_Nm), tokens("`vn'"), _Nm)
end

capture program drop _cov_check
program define _cov_check, rclass
	args id net nwopts dir tol
	local directed = inlist("`net'", "D", "S")
	_cov_load `net' `dir' `directed'
	preserve
	qui import delimited "`dir'/ref.csv", clear
	qui keep if id == "`id'"
	local nR = _N
	local rstat ""
	local rcoef ""
	local rse ""
	forvalues k = 1/`nR' {
		local rstat "`rstat' `=stat[`k']'"
		local rcoef "`rcoef' `=coef[`k']'"
		local rse "`rse' `=se[`k']'"
	}
	local rname1 = rname[1]
	restore
	if "`rname1'" == "ERROR" {
		capture noisily nwergm `net', edges `nwopts' method(mple)
		if _rc == 0 {
			di as err "FAIL `id': R errors but nwergm accepted the model"
			exit 9
		}
		di "ok  `id': both R and nwergm reject (rc=" _rc ")"
		exit
	}
	capture noisily nwergm `net', edges `nwopts' method(mple)
	if _rc {
		di as err "FAIL `id': nwergm error " _rc
		exit 9
	}
	matrix bb = e(b)
	matrix VV = e(V)
	local nS = colsof(bb)
	if `nS' != `nR' {
		di as err "FAIL `id': coefficient count nwergm=`nS' R=`nR'"
		exit 9
	}
	matrix _S = e(obs_stats)
	local ds 0
	local db 0
	local dse 0
	forvalues k = 1/`nR' {
		local rs : word `k' of `rstat'
		local rc : word `k' of `rcoef'
		local rv : word `k' of `rse'
		if "`rs'" != "NA" local ds = max(`ds', abs(_S[1,`k'] - `rs'))
		local fin = !inlist("`rc'", "Inf", "-Inf", "NA", ".", "NaN")
		if `fin' {
			if abs(`rc') < 1e3 {
				local db = max(`db', abs(bb[1,`k'] - `rc'))
				local dse = max(`dse', abs(sqrt(VV[`k',`k']) - `rv'))
			}
		}
	}
	local ok = (`ds' < 1e-6 & `db' < `tol' & `dse' < `tol')
	di as txt "`=cond(`ok', "ok  ", "FAIL")' `id' (`nwopts'): max|stat diff|=" %9.2e `ds' "  max|coef diff|=" %9.2e `db' "  max|se diff|=" %9.2e `dse'
	if !`ok' exit 9
end

local dir "dev/covterms/data"
qui import delimited "`dir'/spec.csv", clear stringcols(_all) varnames(1)
local nspec = _N
forvalues i = 1/`nspec' {
	local sid_`i' = id[`i']
	local snet_`i' = net[`i']
	local snw_`i' = nw[`i']
}
local nfail 0
forvalues i = 1/`nspec' {
	capture noisily _cov_check `sid_`i'' `snet_`i'' `"`snw_`i''"' `dir' 1e-4
	if _rc local ++nfail
}
if `nfail' > 0 {
	di as err "FAIL test_nwergm_covterms: `nfail' of `nspec' specs failed"
	exit 9
}
di "PASS test_nwergm_covterms (`nspec' specs)"
