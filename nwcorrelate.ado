
capture program drop nwcorrelate
program nwcorrelate
	syntax [anything] [, attribute(string) * ]

//(string) attribute(string) name(string) permutations(integer 100) save(string) ]

	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `nw_syntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message.
	unw_defs
	capture nw_syntax `anything', min(1) max(2)
	if _rc != 0 {
		di "{err}One or more of the specified networks could not be found."
		error `errNWsNotFound'
	}

	if "`attribute'"!= "" {
		local netname : word 1 of `netname'
		nwcorrelate_nets `netname', attribute(`attribute') `options'
	}
	if `networks' == 2 {
		nwcorrelate_nets `netname' , `options' 
	}
	if `networks' == 1 & "`attribute'" == ""{
		nwcorrelate_nodes `netname', `options'
	}
end

capture program drop nwcorrelate_nodes
program nwcorrelate_nodes
	syntax [anything(name=netname)] [, name(string) context(string)]
	nw_syntax `netname'
	if "`context'" == "" {
		local context = "outgoing"
	}
	_opts_oneof "outgoing incoming both" "context" "`context'" 6556
	
	if "`name'" == "" {
		local name = "_corr"
	}
	
	capture nwdrop `name'

	if "`context'" == "outgoing" {
		local neighborhood = 1
	}
	if "`context'" == "incoming" {
		local neighborhood = 2
	}
	if "`context'" == "both" {
		local neighborhood = 3
	}

	nw_syntax `netname'
	local origname "`netname'"
	
	nwset, mat(`netobj'->correlate_nodes(`neighborhood')) name("`name'")	
	nw_syntax
	
	mata: st_rclear()
	mata: st_numscalar("r(avg_corr)", ( sum(*`netobj'->get_matrix()) / sum((*`netobj'->get_matrix()):!=.)))
	
	mata: st_global("r(name)", "`origname'")
	mata: st_global("r(corrname)", "`netname'")
	mata: st_global("r(context)", "`context'")
	di 
	di "{txt}  Network name: {res}`r(name)'"
	di "{txt}  Correlation network: {res}`r(corrname)'"
	di "{hline 40}"
	di "{txt}    Context definition: {res}`r(context)'"
	di "{txt}    Average correlation between nodes: {res}`=round(`r(avg_corr)',0.001)'"
end


capture program drop nwcorrelate_nets	
program nwcorrelate_nets
syntax [anything(name=netnames)] [, ifcond(string) keepexpand context(string) mode(string) ATTRibute(string) PERMutations(integer 1) SAVe(string asis) *]
unw_defs
	
	if "`mode'" == "" {
		local mode = "same"
	}
	
	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `nw_syntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message - a very plausible everyday typo.
	capture nw_syntax `netnames', max(2) min(1)
	if _rc != 0 {
		di "{err}One or more of the specified networks could not be found."
		error `errNWsNotFound'
	}
	local netname1 : word 1 of `netname'
	local netname2 : word 2 of `netname'
	
	_nwdatasync `netname1'
	
	nw_syntax `netname1'
	local netnodes1 `nodes'
	local netobj1 `netobj'
	
	if "`attribute'" != "" {
		confirm variable `attribute'
		capture nwdrop `mode'_`attribute'
		nwexpand `attribute', nodes(`netnodes1') network(`netname1') mode(`mode') name(`mode'_`attribute')
		local netname2 = "`mode'_`attribute'"
	}
	
	nw_syntax `netname2'
	local netnodes2 `nodes'
	local netobj2 `netobj'
	
	if `netnodes1' != `netnodes2' {
		// Error-code coherence pass: `errNWsSizeMismatch' (6056,
		// unw_defs.ado) already names this exact situation for several
		// sibling commands (nwplot/nwqap/nwturnover) - consolidated
		// onto it instead of this file's own separate, undocumented
		// `100'.
		di "{err}Networks of different size.{txt}"
		error `errNWsSizeMismatch'
	}
	
	
	local bandwidth `= 1 / `netnodes1''

	// Return the names and id's of the networks that are correlated with each other.
	mata: st_rclear()
	mata: st_global("r(name_2)", "`netname2'")
	mata: st_global("r(name_1)", "`netname1'")
	
	// Calculate correlation of two networks.
	mata: st_numscalar("r(corr)",correlate_nets((*`netobj1'->get_matrix()), (*`netobj2'->get_matrix()))	)
	local corr `r(corr)'
	// BUGFIX: an undefined observed correlation (e.g. one of the two
	// networks/attribute-expanded networks has zero variance - exactly
	// the case this command's own .sthlp already warns about for the
	// default mode(same) on a continuous/all-distinct attribute) used
	// to crash the permutation branch several lines below with a
	// confusing, low-level Mata syntax error ("unexpected end of line
	// <istmt> incomplete", r3000) - `corr' ends up genuinely empty
	// (not even a "." missing token), so `if `corr' > 0' expands to an
	// operand-less comparison. Caught here with a clear message instead.
	if "`corr'" == "" | "`corr'" == "." {
		di "{err}Correlation is undefined (one of the two networks has zero variance); cannot run a QAP permutation test."
		error 198
	}
	
	// Calculate correlations of network2 with permutations of network1
	if (`permutations' > 1) {
		mata: corr_reps = correlate_nets_rep(`permutations', (*`netobj1'->get_matrix()), (*`netobj2'->get_matrix()))
		capture _return drop _all
		tempname myr
		_return hold `myr'
		
		preserve
		drop _all
		
		getmata correlation = corr_reps
		capture mata: mata drop corr_reps
		
		gen observed = r(corr)
		if "`save'"!= "" {
			di "QAP results saved as: `c(pwd)'/nwcorrelationqap.dta" 
			save "`save'", replace
		}
	
		qui count
		local count_total `r(N)'

		if `corr' > 0 {
			qui count if correlation >= `corr'
		}
		else {
			qui count if correlation <= `corr'	
		}
		local count_out `r(N)'
		
		mata: _pvalue = `count_out' / `count_total'
		
		_pctile correlation, percentiles(2.5 97.5)
		mata: _lb = `r(r1)'
		mata: _ub = `r(r2)'
		
		qui sum correlation
		local xmin = r(min)
		local xmax = r(max)
		
		if `corr' < `xmin' {
			local xmin = `corr'
		}
		if `corr' > `xmax' {
			local xmax = `corr'
		}
		
		kdensity correlation, xscale(range(`xmin' `xmax')) bwidth(`bandwidth') title("Corr(`netname1', `netname2')") ytitle("density") xline(`corr',lpattern(dash)) xlabel(#5) note(`"based on `permutations' QAP permutations of network `net1'"') `options'	

		restore
		_return restore `myr'
	
		mata: st_numscalar("r(lb)", _lb)
		mata: st_numscalar("r(ub)", _ub)
		mata: st_numscalar("r(pvalue)", _pvalue)
		capture mata: mata drop _lb _ub _pvalue
	}
	capture mata: mata drop ifmata
	
	di "{hline 40}"
	di "{txt}  Network1 name: {res}`r(name_1)'"
	di "{txt}  Network2 name: {res}`r(name_2)'"
	
	di "{hline 40}"
	di "{txt}    Correlation: {res}`=round(`r(corr)',0.001)'"
	if "`r(pvalue)'" != "" {
		di "{txt}    P-value: {res}`=round(`r(pvalue)',0.001)'"
	}
	_return hold r1
	if "`attribute'" != "" {
		if "`keepexpand'" == "" {
			capture nwdrop `netname2'
		}
	}
	_return restore r1
end





