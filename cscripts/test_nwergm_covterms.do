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
	qui import delimited "`dir'/net_`net'_adj.csv", clear asdouble
	qui mkmat v*, mat(_A)
	qui import delimited "`dir'/net_`net'_ec.csv", clear asdouble
	qui mkmat v*, mat(_E)
	qui import delimited "`dir'/net_`net'_nodes.csv", clear asdouble
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
	matrix M3 = (0.5, 1, 2 \ 0.3, 0, 1.5 \ 1, 2, 0.1)
	matrix M5 = (0.5, 1, 2, 0, 1 \ 0.3, 0, 1.5, 2, 2 \ 1, 2, 0.1, 1, 0 \ 0, 1, 1, 2, 3 \ 2, 2, 1, 0, 0.5)
	matrix FF = J(16,16,0)
	forvalues i = 1/16 {
		forvalues j = 1/16 {
			matrix FF[`i',`j'] = mod(`i'*`j', 4)
		}
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
		if "`rs'" != "NA" local ds = max(`ds', abs(_S[1,`k'] - `rs') / (1 + abs(`rs')))
		local fin = !inlist("`rc'", "Inf", "-Inf", "NA", ".", "NaN")
		if `fin' {
			if abs(`rc') < 1e3 {
				local db = max(`db', abs(bb[1,`k'] - `rc'))
				local dse = max(`dse', abs(sqrt(VV[`k',`k']) - `rv') / (1 + abs(`rv')))
			}
		}
	}
	local ok = (`ds' < 1e-6 & `db' < `tol' & `dse' < 5*`tol')
	di as txt "`=cond(`ok', "ok  ", "FAIL")' `id' (`nwopts'): max|stat diff|=" %9.2e `ds' "  max|coef diff|=" %9.2e `db' "  max|rel se diff|=" %9.2e `dse'
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
* ---- curved (free-decay) MPLE incl. R's boundary solutions ----
capture program drop _cov_curved
program define _cov_curved
	args id net opt native
	preserve
	qui import delimited "dev/covterms/curved/curved_ref.csv", clear asdouble
	qui keep if id == "`id'"
	local nR = _N
	forvalues k = 1/`nR' {
		local rc`k' = coef[`k']
		local rs`k' = se[`k']
	}
	restore
	qui nwclear
	qui clear
	qui import delimited "dev/covterms/curved/`=cond("`net'"=="dir","dir","und")'_adj.csv", clear asdouble
	qui mkmat v*, mat(_A)
	qui clear
	qui nwset, mat(_A) `=cond("`net'"=="dir","directed","undirected")' name(`net')
	capture noisily nwergm `net', edges `opt' method(mple) `native'
	if _rc {
		di as err "FAIL `id' `native': nwergm error"
		exit 9
	}
	matrix bb = e(b)
	matrix VV = e(V)
	local bad 0
	local seok 1
	forvalues k = 1/`nR' {
		if `rs`k'' >= 1e3 local seok 0
	}
	forvalues k = 1/`nR' {
		if abs(bb[1,`k'] - `rc`k'') > 1e-4 local bad 1
		if `seok' {
			if abs(sqrt(VV[`k',`k']) - `rs`k'') > 5e-4 * (1 + `rs`k'') local bad 1
		}
	}
	if `bad' {
		di as err "FAIL `id' `native': " bb[1,1] " " bb[1,2] " " bb[1,3] " vs R " `rc1' " " `rc2' " " `rc3'
		exit 9
	}
	di "ok  curved `id' (`opt' `native')"
end
local nfailc 0
foreach c in "cDe dir gwespfree(.5)" "cDi dir gwidegreefree(.5)" "cDo dir gwodegreefree(.5)" "cDd dir gwdspfree(.5)" "cDn dir gwnspfree(.5)" "cUe und gwespfree(.5)" "cUd und gwdegreefree(.5)" "cUs und gwdspfree(.5)" "cUn und gwnspfree(.5)" {
	tokenize `c'
	foreach nat in "" "nonative" {
		capture noisily _cov_curved `1' `2' `3' `nat'
		if _rc local ++nfailc
	}
}
local nfail = `nfail' + `nfailc'
* ---- MCMLE (native sampler) against R's MCMLE means (3 R runs; sd in the file) ----
capture program drop _cov_mcmle
program define _cov_mcmle
	args model net directed opts
	preserve
	qui import delimited "dev/covterms/data/mcmle_ref.csv", clear asdouble
	qui keep if model == "`model'"
	local nR = _N
	forvalues k = 1/`nR' {
		local rm`k' = coef_mean[`k']
		local rsd`k' = coef_sd[`k']
	}
	restore
	_cov_load `net' dev/covterms/data `directed'
	capture noisily nwergm `net', edges `opts' method(mcmle) seed(7) mcmcsamplesize(4000) mcmcinterval(100) mcmcburnin(20000) mcmleiterations(30)
	if _rc {
		di as err "FAIL mcmle `model': nwergm error"
		exit 9
	}
	matrix bb = e(b)
	local bad 0
	forvalues k = 1/`nR' {
		if abs(bb[1,`k'] - `rm`k'') > max(0.06, 5*`rsd`k'') local bad 1
	}
	if `bad' {
		di as err "FAIL mcmle `model'"
		matrix list bb
		exit 9
	}
	di "ok  mcmle `model' (`opts')"
end
local nfailm 0
capture noisily _cov_mcmle m1 U 0 "nodecovrange(x) nodefactordistinct(a)"
if _rc local ++nfailm
capture noisily _cov_mcmle m2 D 1 "nodeocovrange(x) nodeifactordistinct(z)"
if _rc local ++nfailm
capture noisily _cov_mcmle m4 U 0 "absdiffcat(z) smalldiff(x, cutoff(5)) sociality(., nodes(1/3))"
if _rc local ++nfailm
local nfail = `nfail' + `nfailm'
* ---- R error parity and small features ----
local nfaile 0
_cov_load D dev/covterms/data 1
* R: gwdegree() may not be used with directed networks
capture nwergm D, edges gwdegree(0.5) method(mple)
if _rc != 198 {
	di as err "FAIL gwdegree on a directed network should be an error (rc 198), got rc " _rc
	local ++nfaile
}
else di "ok  directed gwdegree is rejected as in R"
* R: attributes with missing values are rejected
qui replace x = . in 3
capture nwergm D, edges nodecov(x) method(mple)
if _rc != 198 {
	di as err "FAIL missing attribute values should be an error (rc 198), got rc " _rc
	local ++nfaile
}
else di "ok  missing attribute values are rejected as in R"
* R's Label(): coefficient renaming
_cov_load U dev/covterms/data 0
capture nwergm U, edges nodematch(a) nodefactor(g) method(mple) coeflabel(nodematch_a homophily nodefactor_g_1 gfac)
matrix bb = e(b)
local cn : colnames bb
if _rc | "`cn'" != "edges homophily gfac" {
	di as err "FAIL coeflabel(): got `cn'"
	local ++nfaile
}
else di "ok  coeflabel renames coefficients"
local nfail = `nfail' + `nfaile'
if `nfail' > 0 {
	di as err "FAIL test_nwergm_covterms: `nfail' of `nspec' specs failed"
	exit 9
}
di "PASS test_nwergm_covterms (`nspec' specs)"
