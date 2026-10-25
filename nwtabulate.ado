
capture program drop nwtabulate
program nwtabulate
	syntax [anything(name=netname)] [, attribute(varname) *]
	_nwsyntax `netname', max(2)
	local __vndone 0
	forvalues __vi = 1/2 {
		local __vn : word `__vi' of `netname'
		if `__vndone' == 0 & (`__vi' == 1 | "`__vn'" != "") {
			_nwvaluednote `__vn'
			if r(shown) == 1 {
				noi di `"`r(msg)'"'
				local __vndone 1
			}
		}
	}

	if `networks' == 1 & "`attribute'" == "" {
		nwtab1 `netname', `options'
	}
	if `networks' == 2 {
		nwtab2 `netname', `options'
	}
	if "`attribute'" != "" {
		_nwsyntax `netname', max(1)
		nwtab3 `netname', attribute(`attribute') `options'
	}
	if `networks' > 2 {
		di "{err}Maximum two networks allowed.{txt}"
		exit
	}
end


capture program drop nwtab1
program nwtab1
	
	syntax [anything] , [selfloop *]
	preserve
	
	_nwsyntax `anything'
	if "`directed'" == "false" {
		local upper = "upper"
	}
	_nwedgelabs `anything'
	local edgelabs r(edgelabs)
	
	// the distinct tie values and their dyad counts (zeros counted, not
	// listed), tabulated with frequency weights: the table of listing all
	// N x N dyads without the N x N rows
	_nwsyntax `netname'
	drop _all
	tempvar freq
	mata: `netobj'->value_counts_to_vars(("`directed'" == "false"), "`netname'", "`freq'", 0)
	qui compress `netname'
	qui summarize `freq', meanonly
	local ndyads = r(sum)
	
	local ident = length("`netname'") + 20
	di
	di "{txt}   Network:  {res}`netname'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"
	capture label def elab `edgelabs'
	capture label val `netname' elab
	if `ndyads' > 2147483647 {
		// more dyads than Stata's frequency weights hold (2,147,483,647): the same table written out here
		tempvar pct cum
		qui gen double `pct' = 100 * `freq' / `ndyads'
		qui gen double `cum' = sum(`pct')
		local vl : value label `netname'
		di
		di "{txt}{ralign 12:`netname'} {c |}{ralign 16:Freq.}{ralign 10:Percent}{ralign 10:Cum.}"
		di "{hline 13}{c +}{hline 36}"
		forvalues r = 1/`=_N' {
			local v = `netname'[`r']
			local vs = string(`v', "%12.0g")
			if "`vl'" != "" {
				local lab : label `vl' `v', strict
				if `"`lab'"' != "" local vs `"`lab'"'
			}
			di "{txt}{ralign 12:`vs'} {c |}{res}{ralign 16:" string(`freq'[`r'], "%16.0fc") "}{ralign 10:" string(`pct'[`r'], "%9.2f") "}{ralign 10:" string(`cum'[`r'], "%9.2f") "}"
		}
		di "{txt}{hline 13}{c +}{hline 36}"
		di "{txt}{ralign 12:Total} {c |}{res}{ralign 16:" string(`ndyads', "%16.0fc") "}{ralign 10:100.00}"
	}
	else {
		tab `netname' [fweight = `freq'], `options'
	}
	restore
end


capture program drop nwtab2
program nwtab2
	syntax anything(name=netname) [, eiplot eiplotoptions(string) unvalued plot plotoptions(string) permutations(integer 100) *]
		
	
	local netname0 `netname'
	_nwsyntax `netname', max(2) min(2)
	local upper = "upper"
	foreach net in `netname' {
		_nwsyntax `net'
		if "`directed'" == "true" {
			local upper = ""
		}
	}
	
	preserve
	nwtoedge `netname0', `upper'
	
	local net1: word 1 of `netname0'
	_nwedgelabs `net1'
	capture label def elab1 `r(edgelabs)'
	capture label val `net1' elab1
	
	local net2: word 2 of `netname0'
	_nwedgelabs `net2'
	capture label def elab2 `r(edgelabs)'
	capture label val `net2' elab2

	local ident = length("`netname'") + 20
	di
	_nwsyntax `net1'
	local netobj1 `netobj'
	di "{txt}   Network1:  {res}`net1'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"
	_nwsyntax `net2'
	local netobj2 `netobj'
	di "{txt}   Network2:  {res}`net2'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"

	tempname tableres tablecol tablerow
	tabulate `netname0', matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	
	capture qui matrix list `tableres'
	if _rc != 0 {
		exit
	}
	
	if "`plot'" != "" {
		_nwtabplot `net1' `net2', horizontal plotregion(margin(b = 0)) `plotoptions'
	}
	
	tempname __nwtable __nwcol __nwrow __nwinternal __nwexternal __nwei_index 
	mata: `__nwtable' = st_matrix("`tableres'")
	mata: `__nwcol' = st_matrix("`tablecol'")
	mata: `__nwrow' = st_matrix("`tablerow'")
	mata: `__nwinternal' = sum(diagonal(`__nwtable'))
	mata: `__nwexternal' = sum(`__nwtable') - `__nwinternal'
	mata: `__nwei_index' = (`__nwexternal' - `__nwinternal') / (`__nwexternal' + `__nwinternal')
	
	mata: st_global("r(netname1)", "`net1'")
	mata: st_global("r(netname2)", "`net2'")
	mata: st_numscalar("r(EI_index)", floatround(`__nwei_index'))
	mata: st_matrix("r(table)", `__nwtable')
	mata: st_matrix("r(col)", `__nwcol')
	mata: st_matrix("r(row)", `__nwrow')
	
    mata: mata drop `__nwtable' `__nwcol' `__nwrow' `__nwinternal' `__nwexternal' `__nwei_index' 
	
	local EI_index = `r(EI_index)'

	tempname EI_qap out pvalue
	capture _return drop res1
	_return hold res1
	
	qui if `permutations' > 1  {

		mata: `EI_qap' = rep_EInet(`permutations', `netobj1'->get_matrix_copy(), `netobj2'->get_matrix_copy())
		if `EI_index' > 0 {
			mata: `out' = sum(`EI_qap' :>= `EI_index')
		}
		else {
			mata: `out' = sum(`EI_qap' :<= `EI_index')	
		}
		mata: `pvalue' = `out' / `permutations'
		mata: mata drop `out'
		
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
	capture mata: st_numscalar("r(EI_pvalue)", floatround(`pvalue'))

    capture mata: mata drop `EI_out' `pvalue'  `EI_qap'
	di "{txt}   E-I Index: {res}" _continue
	di round(float(`r(EI_index)'),0.001) _continue
	di "{txt}   p-value: {res}" _continue
	di round(float(`r(EI_pvalue)'),0.001)

	restore

end



capture program drop nwtab3
program nwtab3
	syntax anything(name=netname), attribute(varname) [, eiplot eiplotoptions(string) unvalued plot plotoptions(string) permutations(integer 100) *]
		
	
	_nwsyntax `netname', max(1) min(1)
	
	local upper = "upper"
	foreach net in `netname' {
		_nwsyntax `net'
		if "`directed'" == "true" {
			local upper = ""
		}
	}
	
	preserve	
	
	local ident = length("`netname'") + 20
	di ""
	di "{txt}   Network:  {res}`netname'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"

	di "{txt}   Attribute:  {res}`attribute'{txt}"
	
	// compress: only the ties are listed (the table below counts ties only), not all N x N dyads
	nwtoedge `netname', egovars(`attribute') altervars(`attribute') full compress

	unw_defs
	_nwsyntax `netname'
	
	qui keep if `netname' != 0 & `netname' != .
	tempname tableres tablecol tablerow
	if "`directed'" == "true" {
		tabulate `attribute'`nw_ego' `attribute'`nw_alter'  , matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	}
	else {	
		qui gen _temp = mod(_n,2)
		tabulate `attribute'`nw_ego' `attribute'`nw_alter' if _temp == 0. , matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	}
	
	if "`plot'" != "" {
		_nwtabplot `attribute'`nw_ego' `attribute'`nw_alter', horizontal plotregion(margin(b = 0)) `plotoptions'
	}
	
	tempname __nwtable __nwcol __nwrow __nwinternal __nwexternal __nwei_index 
	mata: `__nwtable' = st_matrix("`tableres'")
	mata: `__nwcol' = st_matrix("`tablecol'")
	mata: `__nwrow' = st_matrix("`tablerow'")
	mata: `__nwinternal' = sum(diagonal(`__nwtable'))
	mata: `__nwexternal' = sum(`__nwtable') - `__nwinternal'
	mata: `__nwei_index' = (`__nwexternal' - `__nwinternal') / (`__nwexternal' + `__nwinternal')
	
	// BUGFIX: was `r(netname1)'/`r(netname2)' set from `net1'/`net2' -
	// copy-pasted verbatim from nwtab2 (the network+network branch
	// above), but this program (nwtab3, the network+attribute branch)
	// has only one network and one attribute, and never defines `net1'/
	// `net2' anywhere in its own scope - both always came back missing
	// (.), silently, since `capture'-free `mata:' calls referencing an
	// undefined local just interpolate an empty string rather than
	// erroring. Replaced with this program's own actual identifiers.
	mata: st_global("r(netname)", "`netname'")
	mata: st_global("r(attribute)", "`attribute'")
	mata: st_numscalar("r(EI_index)", floatround(`__nwei_index'))
	mata: st_matrix("r(table)", `__nwtable')
	mata: st_matrix("r(col)", `__nwcol')
	mata: st_matrix("r(row)", `__nwrow')

	capture mata: mata drop `__nwtable' `__nwcol' `__nwrow' `__nwinternal' `__nwexternal' `__nwei_index' 
	
	local EI_index = `r(EI_index)'

	tempname EI_qap out pvalue
	capture _return drop res1
	_return hold res1
	
	restore
	preserve
	
	_nwdatasync `netname'
	
	tempvar group
	egen `group' = group(`attribute')
	
	qui if `permutations' > 1  {
		_nwsyntax `netname'
		mata: `EI_qap' = rep_EIattr_net(`permutations', `netobj', st_data((1::`nodes'),"`group'"))
		if `EI_index' > 0 {
			mata: `out' = sum(`EI_qap' :>= `EI_index')
		}
		else {
			mata: `out' = sum(`EI_qap' :<= `EI_index')	
		}
		mata: `pvalue' = `out' / `permutations'
		mata: mata drop `out'
		
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

	restore
	
	_return restore res1
	
	capture mata: st_numscalar("r(EI_pvalue)", floatround(`pvalue'))
	capture mata: mata drop `EI_out' `pvalue'  `EI_qap'
		
	
	di "{txt}   E-I Index: {res}" _continue
	di round(float(`r(EI_index)'),0.001) _continue
	di "{txt}   p-value: {res}" _continue
	di round(float(`r(EI_pvalue)'),0.001)
	di ""


end



capture mata : mata drop rep_EInet()
capture mata : mata drop rep_EIattr()

mata:
// see rep_EIvar_net() in nwmixing.ado: the permutations act on the stored ties of a large network
real matrix rep_EIattr_net(real scalar reps, pointer(class nw_def scalar) scalar p, real matrix attr)
{
	real matrix el
	real colvector perm, inv, A, intern, extern
	real scalar n, i, total

	if (!nw_ties_only(p)) return(rep_EIattr(reps, p->get_matrix_copy(), attr))
	n = p->get_nodes()
	el = p->edgelist()
	total = rows(el)
	intern = J(reps, 1, 0)
	inv = J(n, 1, .)
	for (i = 1; i <= reps; i++) {
		perm = unorder(n)
		inv[perm] = (1::n)
		A = attr[inv]
		intern[i] = sum(A[el[., 1]] :== A[el[., 2]])
	}
	extern = J(reps, 1, total) :- intern
	return((extern :- intern) :/ (extern :+ intern))
}

real matrix rep_EInet(real scalar reps, real matrix net1, real matrix net2) {
	real scalar nsize, total, EI, i
	real matrix intern, extern, permutationVec, perm_net
	
	net1 = (net1:!=0 :& net1 !=.)
	nsize = cols(net1)
	
	total = nsize * (nsize - 1)
	intern = J(reps, 1, 0)
	extern = J(reps, 1, 0)
	
	for (i = 1; i <= reps; i ++) {
		permutationVec = unorder(nsize)
		perm_net = net1[permutationVec, permutationVec]
		intern[i] = sum(perm_net :== net2)
	}
	extern = total :- intern
	EI = (extern :- intern) :/ (extern :+ intern)
	return(EI)
}

real matrix rep_EIattr(real scalar reps, real matrix net1, real matrix attr) {
	real scalar nsize, total, EI, i
	real matrix intern, extern, permutationVec, perm_net, attr1, attr2
	
	// BUGFIX: this read `net1 != .' (no colon: ONE comparison of the whole matrix, true whenever any cell
	// differs from missing), so the missing diagonal counted as a tie in every cell, total and internal count
	// alike, which shifted the whole simulated E-I distribution and biased the permutation p-value (the same
	// defect nwmixing had until 2026-09-30).  Elementwise now.
	net1 = (net1:!=0 :& net1 :!= .)
	nsize = cols(net1)
	total = sum(net1)
	
	intern = J(reps, 1, 0)
	extern = J(reps, 1, 0)
	
	attr1 = J(1,nsize,attr)
	attr2 = J(nsize,1,attr')
	
	for (i = 1; i <= reps; i ++) {
		permutationVec = unorder(nsize)
		perm_net = net1[permutationVec, permutationVec]
		intern[i] = sum(perm_net :* (attr1:== attr2))
	}
	extern = total :- intern
	EI = (extern :- intern) :/ (extern :+ intern)
	return(EI)
}
end

