*! nwcoefplot: coefficient plot of nwergm, nwsaom, nwdynam, nwrem, nwalaam, nwlsm and other estimation results (3.28.0)
capture program drop nwcoefplot
program nwcoefplot, rclass
	version 15
	syntax [anything(name=names)] [, Level(cilevel) KEEP(string) DROP(string) EForm BYEq MIXeq noCONStant COMMON ///
		SKIPmissing TItle(string asis) NAME(string asis) SAVING(string asis) EXPort(string asis) *]

	if "`byeq'" != "" & "`mixeq'" != "" {
		di as err "byeq and mixeq cannot be combined"
		exit 198
	}
	if "`level'" == "" local level = c(level)

	// the models to plot: stored names, a period for the active results, nothing for the active results
	if "`names'" == "" local names "."
	local nm_models : word count `names'
	if `nm_models' > 8 {
		di as err "at most 8 models can be plotted together"
		exit 198
	}

	tempname cur
	capture quietly _estimates hold `cur', copy nullok
	local hascur = (_rc == 0)

	tempname B V
	tempfile pf
	capture erase `"`pf'"'
	postfile __nwcp_h int mod str80 eq str80 nm double(b se df) byte efok using `"`pf'"'
	local mlabs ""
	local cmds ""
	local mi = 0
	local nposted = 0
	// the active results are read first: restoring a stored model replaces them
	local acmd "`e(cmd)'"
	local afam "`e(family)'"
	local adf = e(df_r)
	tempname Ba Va
	capture matrix `Ba' = e(b)
	local arcb = _rc
	capture matrix `Va' = e(V)
	local arcv = _rc
	foreach nmod of local names {
		if "`nmod'" == "." {
			if "`acmd'" == "" {
				postclose __nwcp_h
				if `hascur' capture _estimates unhold `cur'
				di as err "There are no active estimation results."
				exit 301
			}
			local lab "active"
			local cmd "`acmd'"
			local fam "`afam'"
			local dfr = `adf'
			local rcb = `arcb'
			local rcv = `arcv'
			if !`rcb' & !`rcv' {
				matrix `B' = `Ba'
				matrix `V' = `Va'
			}
		}
		else {
			capture quietly estimates restore `nmod'
			if _rc {
				postclose __nwcp_h
				if `hascur' capture _estimates unhold `cur'
				di as err "Stored estimation results {bf:`nmod'} not found."
				exit 111
			}
			local lab "`nmod'"
			local cmd "`e(cmd)'"
			local fam "`e(family)'"
			local dfr = e(df_r)
			capture matrix `B' = e(b)
			local rcb = _rc
			capture matrix `V' = e(V)
			local rcv = _rc
		}
		if `rcb' | `rcv' {
			if "`skipmissing'" != "" {
				di as txt "Note: `lab' has no coefficient vector and covariance matrix; it is left out."
				continue
			}
			postclose __nwcp_h
			if `hascur' capture _estimates unhold `cur'
			di as err "The estimation results `lab' contain no e(b) and e(V); nwcoefplot needs a coefficient vector with its covariance matrix."
			exit 321
		}
		local ++mi
		// exponentiation: where it is meaningful
		local efok = 1
		if inlist("`cmd'", "nwsaom", "nwsbm") local efok = 0
		if "`cmd'" == "nwlsm" & !inlist("`fam'", "bernoulli", "binomial", "poisson") local efok = 0
		local mlabs `"`mlabs' `lab'"'
		local cmds `cmds' `cmd'
		local cn : colnames `B'
		local ce : coleq `B'
		local kk = colsof(`B')
		forvalues j = 1/`kk' {
			local cj : word `j' of `cn'
			local ej : word `j' of `ce'
			if "`ej'" == "_" local ej ""
			local bj = `B'[1, `j']
			local vj = `V'[`j', `j']
			if missing(`bj') | missing(`vj') | `vj' <= 0 continue
			local ef1 = `efok'
			if "`cmd'" == "nwlsm" & "`ej'" == "outcome" local ef1 = 0
			post __nwcp_h (`mi') ("`ej'") ("`cj'") (`bj') (`=sqrt(`vj')') (`dfr') (`ef1')
			local ++nposted
		}
	}
	postclose __nwcp_h
	if `hascur' capture _estimates unhold `cur'
	if `mi' == 0 {
		di as err "No estimation results with a coefficient vector were found."
		exit 321
	}
	if `nposted' == 0 {
		di as err "The estimation results contain no estimated coefficients."
		exit 322
	}

	preserve
	quietly use `"`pf'"', clear
	quietly gen long ord0 = _n
	if "`constant'" != "" quietly drop if nm == "_cons"
	// keep() and drop(): patterns for the coefficient name or for eq:name (* and ? allowed)
	quietly gen str160 full = cond(eq == "", nm, eq + ":" + nm)
	if `"`keep'"' != "" {
		quietly gen long korder = .
		local ip = 0
		foreach pat of local keep {
			local ++ip
			quietly replace korder = `ip' if korder == . & (strmatch(nm, "`pat'") | strmatch(full, "`pat'"))
		}
		quietly drop if korder == .
	}
	else quietly gen long korder = 1
	if `"`drop'"' != "" {
		foreach pat of local drop {
			quietly drop if strmatch(nm, "`pat'") | strmatch(full, "`pat'")
		}
	}
	if _N == 0 {
		restore
		di as err "No coefficients are left after keep(), drop() and noconstant."
		exit 198
	}
	// only coefficients that all models share
	if "`common'" != "" {
		quietly bysort full: gen int __nm = _N
		quietly drop if __nm < `mi'
		drop __nm
		if _N == 0 {
			restore
			di as err "The models share no coefficient."
			exit 198
		}
	}
	// equations: one panel each unless mixeq
	quietly levelsof eq, local(eqlist) clean
	local neq : word count `eqlist'
	if "`mixeq'" != "" {
		quietly replace nm = full
		quietly replace eq = ""
		local neq = 1
	}
	quietly bysort eq (ord0): gen long eqord = ord0[1]
	quietly bysort eq nm (korder ord0): gen long firstord = ord0[1]
	quietly bysort eq nm: egen long korder2 = min(korder)
	sort eqord korder2 firstord nm mod
	quietly gen byte tag = (nm != nm[_n-1] | eq != eq[_n-1])
	quietly by eqord: gen int k = sum(tag)
	quietly by eqord: egen int nk = max(k)
	quietly gen double ypos = nk - k + 1
	if `mi' > 1 quietly replace ypos = ypos + ((`mi' + 1) / 2 - mod) * 0.7 / `mi'

	// intervals
	quietly gen double crit = cond(df < ., invttail(df, (1 - `level' / 100) / 2), invnormal(1 - (1 - `level' / 100) / 2))
	quietly gen double lo = b - crit * se
	quietly gen double hi = b + crit * se
	quietly gen byte isef = 0
	if "`eform'" != "" {
		quietly count if efok
		if r(N) == 0 {
			restore
			di as err "eform is not meaningful for these estimation results (nwsaom and nwsbm parameters, or the outcome equation of a latent space model, are not log odds or log rates)."
			exit 198
		}
		quietly bysort eq: egen byte __anyef = max(efok)
		quietly bysort eq: egen byte __allef = min(efok)
		if "`mixeq'" != "" {
			quietly count if efok == 0
			if r(N) > 0 {
				restore
				di as err "eform with mixeq needs equations that can all be exponentiated; drop mixeq to plot one panel per equation."
				exit 198
			}
		}
		quietly replace isef = efok
		quietly replace b = exp(b) if isef
		quietly replace lo = exp(lo) if isef
		quietly replace hi = exp(hi) if isef
	}

	// the axis title
	local c1 : word 1 of `cmds'
	local xt "Coefficient"
	if "`eform'" != "" {
		local xt "Exponentiated coefficient"
		local uc : list uniq cmds
		local nuc : word count `uc'
		if `nuc' == 1 & inlist("`c1'", "nwergm", "nwalaam") local xt "Odds ratio"
		if `nuc' == 1 & inlist("`c1'", "nwdynam", "nwrem") local xt "Rate ratio"
		if `nuc' == 1 & "`c1'" == "nwlsm" {
			local fam1 "`e(family)'"
			local xt "Odds ratio"
		}
	}
	local xt0 "Coefficient (`level'% CI)"
	local xt "`xt' (`level'% CI)"

	local nopt ""
	if `"`name'"' != "" local nopt `"name(`name')"'
	local sopt ""
	if `"`saving'"' != "" local sopt `"saving(`saving')"'
	quietly levelsof eqord, local(eqords0)
	local nep : word count `eqords0'
	local drawopt "`nopt' `sopt'"
	local cols `" "navy" "maroon" "forest_green" "dkorange" "purple" "teal" "cranberry" "gs8" "'
	local panels ""
	local ip = 0
	local totrows = 0
	quietly levelsof eqord, local(eqords)
	foreach eo of local eqords {
		local ++ip
		quietly summarize nk if eqord == `eo', meanonly
		local nk = r(max)
		local totrows = `totrows' + `nk'
		quietly levelsof eq if eqord == `eo', local(eqname) clean
		// y labels
		local yl ""
		forvalues kk = 1/`nk' {
			quietly levelsof nm if eqord == `eo' & k == `kk', local(lab) clean
			local lab = subinstr(`"`lab'"', `"""', "'", .)
			local yl `"`yl' `=`nk' - `kk' + 1' "`lab'""'
		}
		quietly summarize isef if eqord == `eo', meanonly
		local isef = (r(max) == 1)
		local plots ""
		local leg ""
		forvalues m = 1/`mi' {
			local col : word `m' of `cols'
			local plots `plots' (rcap lo hi ypos if eqord == `eo' & mod == `m', horizontal lcolor(`col') msize(*.5)) (scatter ypos b if eqord == `eo' & mod == `m', mcolor(`col') msymbol(O) msize(medsmall))
			local ml : word `m' of `mlabs'
			local leg `"`leg' `=2*`m'' "`ml'""'
		}
		local legopt "legend(off)"
		if `mi' > 1 local legopt `"legend(order(`leg') rows(1) position(6) size(small))"'
		local xl "xline(0, lcolor(gs10) lpattern(dash))"
		local xs ""
		local xtp "`xt0'"
		if `isef' {
			local xtp "`xt'"
			local xl "xline(1, lcolor(gs10) lpattern(dash))"
			local xs "xscale(log)"
		}
		// the axis range always contains the intervals and the reference line, with a margin
		quietly summarize lo if eqord == `eo', meanonly
		local rlo = r(min)
		quietly summarize hi if eqord == `eo', meanonly
		local rhi = r(max)
		quietly summarize b if eqord == `eo', meanonly
		local rlo = min(`rlo', r(min))
		local rhi = max(`rhi', r(max))
		local xr ""
		if `isef' {
			local rlo = ln(min(`rlo', 1))
			local rhi = ln(max(`rhi', 1))
			local mar = max(0.08 * (`rhi' - `rlo'), 0.05)
			local alo = exp(`rlo' - `mar')
			local ahi = exp(`rhi' + `mar')
			local xlab ""
			foreach set in "1 1.25 1.5 2 2.5 3 4 5 6 8" "1 2 3 5" "1 2 5" "1" {
				local cand ""
				local nc = 0
				forvalues ex = -6/6 {
					foreach mm of local set {
						local v = `mm' * 10^`ex'
						if `v' >= `alo' & `v' <= `ahi' {
							local cand "`cand' `=trim(strofreal(`v', "%9.4g"))'"
							local ++nc
						}
					}
				}
				if `nc' >= 3 & `nc' <= 9 & "`xlab'" == "" local xlab "`cand'"
			}
			if "`xlab'" == "" local xlab "1"
			if !`:list posof "1" in xlab' local xlab "`xlab' 1"
			local xr "xscale(range(`alo' `ahi')) xlabel(`xlab')"
		}
		else {
			local rlo = min(`rlo', 0)
			local rhi = max(`rhi', 0)
			if `rhi' - `rlo' <= 0 {
				local rlo = -1
				local rhi = 1
			}
			local mar = 0.08 * (`rhi' - `rlo')
			local alo = `rlo' - `mar'
			local ahi = `rhi' + `mar'
			quietly _natscale `alo' `ahi' 6
			local xr "xscale(range(`=r(min)' `=r(max)')) xlabel(`=r(min)'(`=r(delta)')`=r(max)')"
		}
		local ptitle ""
		if `neq' > 1 local ptitle `"title("`eqname'", size(medsmall))"'
		else if `"`title'"' != "" local ptitle `"title(`title')"'
		tempname g`ip'
		if `nep' > 1 local drawopt "nodraw name(`g`ip'', replace)"
		local ysz = min(max(2.5, 0.26 * `nk' * (1 + 0.15 * (`mi' - 1)) + 1.4), 14)
		twoway `plots', `xl' `xs' `xr' ylabel(`yl', angle(0) noticks nogrid labsize(small)) yscale(range(0.4 `=`nk' + 0.6') noline) ///
			ytitle("") xtitle("`xtp'") `legopt' `ptitle' graphregion(color(white)) plotregion(margin(small)) ///
			ysize(`ysz') `drawopt' `options'
		if `nep' > 1 local panels `panels' `g`ip''
	}
	if `nep' > 1 {
		local ctitle ""
		if `"`title'"' != "" local ctitle `"title(`title')"'
		graph combine `panels', cols(1) `ctitle' `nopt' `sopt' graphregion(color(white)) ysize(`=min(max(3, 0.32 * `totrows' + 1.4 * `nep'), 20)')
	}
	if `nep' > 1 {
		foreach g of local panels {
			capture graph drop `g'
		}
	}
	if `"`export'"' != "" {
		gettoken efile eopts : export, parse(",")
		local eopts = subinstr(`"`eopts'"', ",", "", 1)
		graph export `efile', replace `eopts'
	}
	return scalar level = `level'
	return scalar n_coef = _N
	return scalar n_panels = `nep'
	return scalar n_models = `mi'
	return local models "`mlabs'"
	restore
end
