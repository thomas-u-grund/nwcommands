capture program drop nwmixing
program nwmixing
	// BUGFIX: `unvalued' was declared but never referenced anywhere in
	// the program body (confirmed: passing it produced byte-identical
	// output to omitting it) - the command already always treats ties
	// as unvalued/binary throughout (the observed mixing table is a
	// `tab' count of ties, and rep_EIvar()'s own permutation test
	// explicitly binarizes via `net1 = (net1:!=0)'), so there was no
	// "valued" mode for the option to ever have toggled away from.
	// Dropped rather than wired up: a genuine weighted E-I index would
	// need its own new formula (e.g. sum of tie weights in place of
	// tie counts) - a real feature addition, not a bug fix, and out of
	// scope for this pass.
	syntax [anything(name=netname)] , attribute(varname) [eiplot eiplotoptions(string) plot plotoptions(string) permutations(integer 100) save(string) * ]
	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Stata error ("variable not found") from inside
	// `_nwsyntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message.
	unw_defs
	capture _nwsyntax `netname', max(1)
	if _rc != 0 {
		di "{err}Network {bf:`netname'} not found."
		error `errNWsNotFound'
	}
	// BUGFIX: this stored the STRING "0" or "1" (both non-empty), not a
	// genuine boolean - so the later `if "`undirected''" != ""' display
	// guard was unconditionally true regardless of the network's actual
	// directedness, printing "The network is undirected." even for a
	// directed network. Matches the boolean-local convention used
	// elsewhere in this package (`directed'/`valued' etc: the string
	// "true" or empty).
	local undirected = cond("`directed'" == "false", "true", "")
	_nwdatasync `netname'
	
	tempvar att
	tempname attmat
	capture encode `attribute', generate(`att')
	if _rc != 0 {
		gen `att' = `attribute'
	}
	mata: `attmat' = st_data((1,`nodes'), "`att'")

	// A string attribute() must go through the already-encoded numeric
	// copy (`att') rather than the raw string variable, since Stata's
	// own `tab ..., matcol() matrow()' (used further down to build the
	// mixing table) does not allow those options on a string variable
	// - confirmed directly (r198, "option matcol() not allowed").
	// Numeric attributes keep using the original variable name (nicer
	// `x_ego'/`x_alter' column names, matching this command's own
	// pre-existing convention) rather than switching to a temp name
	// unconditionally. `attrlab' correspondingly needs to be `egosrc''s
	// own value label (auto-created by `encode' above for the string
	// case) - a numeric `attribute' has no reason to share a label name
	// with `att''s auto-generated one otherwise.
	capture confirm string variable `attribute'
	local egosrc = cond(_rc == 0, "`att'", "`attribute'")
	local attrlab : value label `egosrc'

	preserve
	nwtoedge `netname', egovars(`egosrc') altervars(`egosrc')
	local egoname "`egosrc'_ego"
	local altername "`egosrc'_alter"
	capture label val `egoname' `attrlab'
	capture label val `altername' `attrlab'

	di
	local ident = max(length("`netname'"), length("`attribute'")) + 20
	di "{txt}   Network:  {res}`netname'{txt}{col `ident'}Directed: {res}`directed'{txt}"
	di "{txt}   Attribute:  {res}`attribute'{txt}"

	if "`undirected'" != "" {
		di
		di"{txt}       The network is undirected."
		di"{txt}       The table shows two entries for each edge."
	}
	tempname tableres tablecol tablerow
	tab `egoname' `altername' if `netname' != 0 & `netname' != ., matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'

	if "`plot'" != "" {
		tabplot `egoname' `altername' if `netname' != 0 & `netname' != ., horizontal plotregion(margin(b = 0)) `plotoptions'
	}
	
	tempname __nwtable __nwcol __nwrow __nwinternal __nwexternal __nwei_index 
	mata: `__nwtable' = st_matrix("`tableres'")
	mata: `__nwcol' = st_matrix("`tablecol'")
	mata: `__nwrow' = st_matrix("`tablerow'")
	mata: `__nwinternal' = sum(diagonal(`__nwtable'))
	mata: `__nwexternal' = sum(`__nwtable') - `__nwinternal'
	mata: `__nwei_index' = (`__nwexternal' - `__nwinternal') / (`__nwexternal' + `__nwinternal')
	
	mata: st_global("r(netname)", "`netname'")
	mata: st_global("r(attribute)", "`attribute'")
	mata: st_numscalar("r(EI_index)", `__nwei_index')
	mata: st_matrix("r(table)", `__nwtable')
	mata: st_matrix("r(col)", `__nwcol')
	mata: st_matrix("r(row)", `__nwrow')
	
	capture mata: mata drop `__nwtable', `__nwcol', `__nwrow', `__nwinternal', `__nwexternal', `__nwei_index' 

	local EI_index = `r(EI_index)'

	tempname EI_qap out pvalue
	capture _return drop res1
	_return hold res1
	
	qui if `permutations' > 1  {
	
		mata: `EI_qap' = rep_EIvar(`permutations', *`netobj'->get_matrix(), `attmat')
		// BUGFIX: the one-sided direction used to be chosen from the SIGN
		// of the OBSERVED E-I index itself (`EI_index' > 0), not from
		// where the observed value actually falls relative to the null
		// distribution's own center - wrong whenever that center isn't
		// near zero, which happens for any attribute with meaningfully
		// unequal group sizes (a larger group mechanically produces more
		// same-group dyads than a naive 50/50 split assumes, so the QAP
		// null itself skews positive). Confirmed directly on a real case:
		// unequal Birthplace groups gave a null mean around +0.41, so an
		// observed E-I of +0.05 - four SDs below that null mean, i.e.
		// strong evidence of homophily - was being compared against the
		// wrong (>=) tail and reported as p~=0.93 instead of p~=0.
		// Replaced with a standard, direction-agnostic two-sided
		// permutation p-value (twice the smaller tail, capped at 1),
		// which needs no assumption about which side of the null the
		// observed value should fall on.
		mata: `pvalue' = 2 * min((sum(`EI_qap' :>= `EI_index'), sum(`EI_qap' :<= `EI_index'))) / `permutations'
		mata: `pvalue' = min((`pvalue', 1))
		
		drop _all
		getmata EI_simulated = `EI_qap'
		gen EI_observed = `EI_index'
		if "`save'"!= "" {
			di "QAP results saved as: `save'" 
			save "`save'", replace
		}
		
		qui sum EI_simulated
		local xmin = min(`EI_index',r(min))
		local xmax = max(`EI_index',r(max))
		local bandwidth `= 1 / `nodes''
		if "`eiplot'" != "" {
			kdensity EI_simulated, xscale(range(`xmin' `xmax')) title("") bwidth(`bandwidth') ytitle("Density") xtitle("E-I Index") xline(`EI_index',lpattern(dash)) xlabel(#5) note(`"based on `permutations' QAP permutations of network `net1'"') `eiplotoptions'	
		}		
	}
	_return restore res1
	capture mata: st_numscalar("r(EI_pvalue)", `pvalue')
	
	capture mata: mata drop `EI_out' `pvalue' `out'
	capture mata: mata drop `attmat'
	
	di "{txt}   E-I Index: {res}`=round(`r(EI_index)',0.001)'{txt}   p-value: {res}`=round(`r(EI_pvalue)',0.001)'"

	restore
end	

capture mata : mata drop rep_EIvar()

mata:
real matrix rep_EIvar(real scalar reps, real matrix net1, real matrix attr){
	real scalar nsize, total, EI, i
	real matrix intern, extern, same, attrMat, attrMatTr, permutationVec, perm_net

	nsize = cols(net1)
	attrMat = J(nsize, nsize,1) :* attr
	attrMatTr = attrMat'
	same = (attrMat:== attrMatTr)
	net1 = (net1:!=0)
	// BUGFIX: the network's own diagonal is missing (no self-ties), not
	// 0, and Mata's `:!=0' treats missing as not-equal-to-zero - so
	// before this fix, every one of the `nsize' diagonal cells silently
	// counted as a tie, and since attr[i]==attr[i] always, every one of
	// them counted as an INTERNAL tie too. That inflated both the
	// simulated total and internal counts by the same fixed `nsize'
	// amount on every single permutation draw, systematically biasing
	// the whole null distribution - confirmed directly: this dropped a
	// real network's simulated internal-tie count from 180 to the
	// correct 126 (63 real internal ties, each counted twice for an
	// undirected network - exactly matching this command's own printed
	// mixing table).
	_diag(net1, 0)
	
	total = J(reps, 1, sum(net1))
	intern = J(reps, 1, 0)
	extern = J(reps, 1, 0)
	
	for (i = 1; i <= reps; i ++) {
		permutationVec = unorder(nsize)
		perm_net = net1[permutationVec, permutationVec]
		intern[i] = sum(perm_net :* same)
	}
	extern = total :- intern
	EI = (extern - intern) :/ (extern + intern)
	return(EI)
}
end
