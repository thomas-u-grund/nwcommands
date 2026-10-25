
capture program drop nwcorrelate
program nwcorrelate
	syntax [anything] [, attribute(string) * ]

//(string) attribute(string) name(string) permutations(integer 100) save(string) ]

	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `_nwsyntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message.
	unw_defs
	capture _nwsyntax `anything', min(1) max(2)
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
	syntax [anything(name=netname)] [, name(string) context(string) UNDirected DIRected]
	// _nwsyntax exports a local named directed: keep the options under other names
	local _ud_opts `undirected' `directed'
	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwcorrelate)
	// the node-by-node correlations are computed with about 25 dense n x n matrices at once (5,000 nodes: 10 s and
	// 5.1 GB; 10,000 nodes: more than 12 GB), so a larger network is refused before any of them is allocated
	if `nodes' > 7000 {
		di "{err}nwcorrelate of the nodes of network {bf:`netname'} needs about 25 dense `nodes' x `nodes' matrices (about `=round(`nodes'^2*205/1e9, .1)' GB) and is refused above 7,000 nodes."
		error 484
	}
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

	_nwsyntax `netname'
	local origname "`netname'"
	
	nwset, mat(`netobj'->correlate_nodes(`neighborhood')) name("`name'") `_ud_opts'	
	_nwsyntax
	
	mata: st_rclear()
	mata: st_numscalar("r(avg_corr)", ( sum(*`netobj'->get_matrix()) / (rows(*`netobj'->get_matrix()) * cols(*`netobj'->get_matrix()) - missing(*`netobj'->get_matrix()))))
	
	mata: st_global("r(name)", "`origname'")
	mata: st_global("r(corrname)", "`netname'")
	mata: st_global("r(context)", "`context'")
	di 
	di "{txt}  Network name: {res}`r(name)'"
	di "{txt}  Correlation network: {res}`r(corrname)'"
	di "{hline 40}"
	di "{txt}    Context definition: {res}`r(context)'"
	di "{txt}    Average correlation between nodes: {res}`=strtrim(string(round((`r(avg_corr)')*1000)/1000,"%9.0g"))'"
end


capture program drop nwcorrelate_nets	
program nwcorrelate_nets
syntax [anything(name=netnames)] [, ifcond(string) keepexpand context(string) mode(string) ATTRibute(string) PERMutations(integer 1) SAVe(string asis) force *]
unw_defs
	
	if "`mode'" == "" {
		local mode = "same"
	}
	
	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `_nwsyntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message - a very plausible everyday typo.
	capture _nwsyntax `netnames', max(2) min(1)
	if _rc != 0 {
		di "{err}One or more of the specified networks could not be found."
		error `errNWsNotFound'
	}
	local netname1 : word 1 of `netname'
	local netname2 : word 2 of `netname'
	
	_nwdatasync `netname1'
	
	_nwsyntax `netname1'
	local netnodes1 `nodes'
	_nwdenseguard, command(nwcorrelate) nodes(`nodes') copies(9) alternative(The correlation of two networks is taken over all pairs of nodes. Use a part of the network (nwsubset, nwego).) `force'
	local netobj1 `netobj'
	
	if "`attribute'" != "" {
		confirm variable `attribute'
		capture nwdrop `mode'_`attribute'
		nwexpand `attribute', nodes(`netnodes1') network(`netname1') mode(`mode') name(`mode'_`attribute')
		local netname2 = "`mode'_`attribute'"
	}
	
	_nwsyntax `netname2'
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
		
		qui gen observed = `corr'
		if `"`save'"' != "" {
			// save(): quoted or unquoted file name, paths with spaces allowed
			local savefile `save'
			if !regexm(`"`savefile'"', "\.dta$") local savefile `"`savefile'.dta"'
			qui save `"`savefile'"', replace
			// print the real location (a relative name is saved in the working directory)
			local savefull `"`savefile'"'
			if substr(`"`savefile'"', 1, 1) != "/" & substr(`"`savefile'"', 2, 1) != ":" & substr(`"`savefile'"', 1, 1) != "~" {
				local savefull `"`c(pwd)'/`savefile'"'
			}
			di `"{txt}QAP results saved as: {res}`savefull'"'
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
		
		kdensity correlation, xscale(range(`xmin' `xmax')) bwidth(`bandwidth') title("Corr(`netname1', `netname2')") ytitle("density") xline(`corr',lpattern(dash)) xlabel(#5) note(`"based on `permutations' QAP permutations of networks `netname1' and `netname2'"') `options'	

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
	di "{txt}    Correlation: {res}`=strtrim(string(round((`r(corr)')*1000)/1000,"%9.0g"))'"
	if "`r(pvalue)'" != "" {
		di "{txt}    P-value: {res}`=strtrim(string(round((`r(pvalue)')*1000)/1000,"%9.0g"))'"
	}
	_return hold r1
	if "`attribute'" != "" {
		if "`keepexpand'" == "" {
			capture nwdrop `netname2'
		}
	}
	_return restore r1
end





