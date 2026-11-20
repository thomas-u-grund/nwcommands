*! nwcompare: table of the fit statistics stored by nwergm, nwsaom, nwlsm, nwsbm, nwalaam and other estimation commands (3.28.0)
capture program drop nwcompare
program nwcompare, rclass
	version 15
	syntax [anything(name=names)] [, SORT(string) GRAPH COEFOPTs(string asis)]

	if "`sort'" != "" {
		local sort = lower("`sort'")
		_opts_oneof "aic bic icl ll" "sort" "`sort'"
	}

	// the stored estimation results to compare
	if "`names'" == "" {
		quietly estimates dir
		local names `r(names)'
		if "`names'" == "" {
			di "{err}No estimation results are stored. Store them with {bf:estimates store} {it:name} after each fit."
			exit 198
		}
	}

	// the active estimation results are kept (also those of a command that cannot be stored, such as nwsbm)
	tempname cur
	capture quietly _estimates hold `cur', copy nullok
	local hascur = (_rc == 0)
	// the name . stands for the active estimation results: read them first
	capture _nwcompare_row
	local c_ok = (_rc == 0)
	if `c_ok' {
		local c_N = r(N)
		local c_ll = r(ll)
		local c_k = r(k)
		local c_aic = r(aic)
		local c_bic = r(bic)
		local c_icl = r(icl)
		local c_cmd "`r(cmd)'"
		local c_net "`r(net)'"
		local c_src "`r(src)'"
	}

	local ns : word count `names'
	tempname T
	matrix `T' = J(`ns', 6, .)
	matrix colnames `T' = N ll k aic bic icl
	local rown ""
	local cmds ""
	local lls ""
	local nets ""
	local i = 0
	foreach nm of local names {
		local ++i
		if "`nm'" == "." {
			if !`c_ok' {
				if `hascur' capture _estimates unhold `cur'
				di "{err}There are no active estimation results."
				exit 301
			}
			matrix `T'[`i', 1] = `c_N'
			matrix `T'[`i', 2] = `c_ll'
			matrix `T'[`i', 3] = `c_k'
			matrix `T'[`i', 4] = `c_aic'
			matrix `T'[`i', 5] = `c_bic'
			matrix `T'[`i', 6] = `c_icl'
			local rown `rown' (active)
			local cmds `cmds' `c_cmd'
			local nets `nets' `c_net'
			local lls `"`lls' "`c_src'""'
			continue
		}
		capture quietly estimates restore `nm'
		if _rc {
			if `hascur' capture _estimates unhold `cur'
			di "{err}Stored estimation results {bf:`nm'} not found."
			exit 111
		}
		_nwcompare_row
		matrix `T'[`i', 1] = r(N)
		matrix `T'[`i', 2] = r(ll)
		matrix `T'[`i', 3] = r(k)
		matrix `T'[`i', 4] = r(aic)
		matrix `T'[`i', 5] = r(bic)
		matrix `T'[`i', 6] = r(icl)
		local rown `rown' `nm'
		local cmds `cmds' `r(cmd)'
		local nets `nets' `r(net)'
		local lls `"`lls' "`r(src)'""'
	}
	if `hascur' capture _estimates unhold `cur'
	matrix rownames `T' = `rown'

	// order
	if "`sort'" != "" {
		local col = cond("`sort'" == "ll", 2, cond("`sort'" == "aic", 4, cond("`sort'" == "bic", 5, 6)))
		tempname idx
		mata: st_matrix("`idx'", order(st_matrix("`T'")[., `col'] :* (`=("`sort'" == "ll") * -2 + 1'), 1))
		local order ""
		forvalues r = 1/`ns' {
			local order `order' `=`idx'[`r', 1]'
		}
	}
	else {
		local order ""
		forvalues r = 1/`ns' {
			local order `order' `r'
		}
	}

	di
	di as txt "Fit statistics of stored estimation results" _c
	if "`sort'" != "" di as txt " (sorted by `sort')" _c
	di
	di as txt "{hline 78}"
	di as txt _col(1) "Model" _col(13) "Command" _col(22) "Network" _col(37) "N" _col(41) "k" _col(44) "log lik." _col(57) "AIC" _col(66) "BIC" _col(75) "ICL"
	di as txt "{hline 78}"
	local cols "32 39 43 52 61 70"
	local wid "6 3 8 8 8 8"
	local fmt "%6.0f %3.0f %8.1f %8.1f %8.1f %8.1f"
	foreach r of local order {
		local nm : word `r' of `rown'
		local cmd : word `r' of `cmds'
		local net : word `r' of `nets'
		di as res _col(1) abbrev("`nm'", 11) _col(13) abbrev("`cmd'", 8) _col(22) abbrev("`net'", 9) _c
		local mc "1 3 2 4 5 6"
		forvalues c = 1/6 {
			local mcol : word `c' of `mc'
			local pos : word `c' of `cols'
			local w : word `c' of `wid'
			local f : word `c' of `fmt'
			local v = `T'[`r', `mcol']
			if missing(`v') di as txt _col(`=`pos' + `w' - 1') "." _c
			else di as res _col(`pos') `f' `v' _c
		}
		di
	}
	di as txt "{hline 78}"

	// what the numbers are
	local hdr = 0
	forvalues r = 1/`ns' {
		local nm : word `r' of `rown'
		local cmd : word `r' of `cmds'
		local src : word `r' of `lls'
		if "`cmd'" == "nwlsm" di as txt "{p 0 2 2}`nm': log likelihood is the posterior mean over the draws; no AIC or BIC (Bayesian fit); N is the number of dyads.{p_end}"
		if "`cmd'" == "nwsbm" di as txt "{p 0 2 2}`nm': log likelihood is the expected complete-data log likelihood PL (the memberships are part of the data); ICL is the criterion of the block model; N is the number of actors.{p_end}"
		if inlist("`cmd'", "nwsaom", "nwalaam") di as txt "{p 0 2 2}`nm': `cmd' stores no likelihood (method of moments or Monte Carlo estimates), so no criteria are shown.{p_end}"
		if "`cmd'" == "nwergm" & "`src'" != "ll" & "`src'" != "exact" di as txt "{p 0 2 2}`nm': the log likelihood of this ERGM is obtained by `src'.{p_end}"
	}
	// models of different data
	mata: st_local("nd", strofreal(rows(uniqrows(st_matrix("`T'")[., 1])) > 1))
	local nnets : list uniq nets
	local nnn : word count `nnets'
	if `nd' | `nnn' > 1 {
		di as txt "{p 0 2 2}Note: the models differ in the number of observations or in the network. Criteria are comparable only between models of the same data and the same kind of likelihood; {bf:AIC} and {bf:BIC} only between models of one family.{p_end}"
	}
	else di as txt "{p 0 2 2}Criteria of different model families (ERGM, latent space, block model) are not always comparable: they are built on different likelihoods and different observation counts. Compare within a family first.{p_end}"

	// the coefficients of the models side by side (the models that share coefficient names)
	if "`graph'" != "" {
		local plist ""
		foreach nm of local rown {
			local plist `plist' `=cond("`nm'" == "(active)", ".", "`nm'")'
		}
		capture noisily nwcoefplot `plist', common skipmissing `coefopts'
		if _rc di as txt "Note: the coefficient graph was not drawn (r(" _rc "))."
	}
	return matrix table = `T'
	return local names "`rown'"
	return local commands "`cmds'"
end

// the statistics of the active estimation results
capture program drop _nwcompare_row
program _nwcompare_row, rclass
	local cmd "`e(cmd)'"
	if "`cmd'" == "" exit 301
	local N = e(N)
	// log likelihood: the one stored as e(ll); for nwlsm the posterior mean of the log likelihood; for nwsbm the expected complete-data
	// log likelihood PL (not the likelihood of the data)
	local ll = e(ll)
	local src "ll"
	if missing(`ll') & "`cmd'" == "nwlsm" {
		local ll = e(ll_mean)
		local src "posterior mean"
	}
	if missing(`ll') & "`cmd'" == "nwsbm" {
		local ll = e(PL)
		local src "expected complete-data"
	}
	if "`cmd'" == "nwergm" & "`e(ll_method)'" != "" local src "`e(ll_method)'"
	// number of parameters
	local k = .
	if !missing(e(rank)) local k = e(rank)
	else if !missing(e(df_m)) local k = e(df_m)
	else if !missing(e(npar)) local k = e(npar)
	else {
		capture local k = colsof(e(b))
		if _rc local k = .
	}
	local aic = e(aic)
	local bic = e(bic)
	local icl = e(ICL)
	// AIC and BIC from the log likelihood when the command did not store them, for a likelihood proper only
	if missing(`aic') & !missing(`ll') & !missing(`k') & "`src'" == "ll" {
		local aic = -2 * `ll' + 2 * `k'
		if !missing(`N') local bic = -2 * `ll' + ln(`N') * `k'
	}
	return scalar N = `N'
	return scalar ll = `ll'
	return scalar k = `k'
	return scalar aic = `aic'
	return scalar bic = `bic'
	return scalar icl = `icl'
	return local cmd "`cmd'"
	local net "`e(network)'"
	if "`net'" == "" local net "`e(depvar)'"
	if "`net'" == "" local net "-"
	return local net "`net'"
	return local src "`src'"
end
