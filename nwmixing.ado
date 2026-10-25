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
	// BUGFIX (2026-09-30): nwtoedge lists an undirected edge only once, so
	// the table counted each edge in one arbitrary stored orientation: it
	// was asymmetric, could drop a category entirely (on faux.mesa.high,
	// the "Other" row vanished), and contradicted the "two entries for
	// each edge" header printed below. Ask for both orientations. The E-I
	// index is unchanged (internal and external counts both double).
	local __nwmix_full = cond("`undirected'" != "", "full", "")
	// compress: only the ties are listed (the table below counts ties only), not all N x N dyads
	nwtoedge `netname', egovars(`egosrc') altervars(`egosrc') `__nwmix_full' compress
	local egoname "`egosrc'_ego"
	local altername "`egosrc'_alter"
	// a string attribute was encoded into a temporary variable: give the
	// ego/alter columns readable names so the table header shows
	// attribute_ego | attribute_alter instead of __000000_ego
	if "`egosrc'" != "`attribute'" {
		capture rename `egoname' `attribute'_ego
		if _rc == 0 {
			capture rename `altername' `attribute'_alter
			if _rc == 0 {
				local egoname "`attribute'_ego"
				local altername "`attribute'_alter"
			}
			else {
				rename `attribute'_ego `egoname'
			}
		}
	}
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
	// tab cuts value labels at 9 characters, so with no tab options the table is printed by hand below
	if `"`options'"' == "" {
		qui tab `egoname' `altername' if `netname' != 0 & `netname' != ., matcell(`tableres') matcol(`tablecol') matrow(`tablerow')
		_nwmixing_print, cell(`tableres') col(`tablecol') row(`tablerow') egovar(`egoname') altervar(`altername')
	}
	else {
		tab `egoname' `altername' if `netname' != 0 & `netname' != ., matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	}

	if "`plot'" != "" {
		_nwtabplot `egoname' `altername' if `netname' != 0 & `netname' != ., horizontal plotregion(margin(b = 0)) `plotoptions'
	}
	
	tempname __nwtable __nwcol __nwrow __nwinternal __nwexternal __nwei_index 
	mata: `__nwtable' = st_matrix("`tableres'")
	mata: `__nwcol' = st_matrix("`tablecol'")
	mata: `__nwrow' = st_matrix("`tablerow'")
	// BUGFIX (2026-09-30): internal ties were summed from diagonal(), which
	// assumes the table's rows and columns list the same categories in the
	// same order. When a category appears only as ego or only as alter,
	// the table is not square and the diagonal pairs different categories
	// (faux.mesa.high race: E-I .025 instead of the correct -.015). Match
	// row and column VALUES instead of positions.
	mata: `__nwinternal' = sum(`__nwtable' :* ((`__nwrow' * J(1, cols(`__nwcol'), 1)) :== (J(rows(`__nwrow'), 1, 1) * `__nwcol')))
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
	
		mata: `EI_qap' = rep_EIvar_net(`permutations', `netobj', `attmat')
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
			kdensity EI_simulated, xscale(range(`xmin' `xmax')) title("") bwidth(`bandwidth') ytitle("Density") xtitle("E-I Index") xline(`EI_index',lpattern(dash)) xlabel(#5) note(`"based on `permutations' QAP permutations of network `netname'"') `eiplotoptions'	
		}		
	}
	_return restore res1
	capture mata: st_numscalar("r(EI_pvalue)", `pvalue')
	
	capture mata: mata drop `EI_out' `pvalue' `out'
	capture mata: mata drop `attmat'
	
	if "`r(EI_pvalue)'" == "" {
		// permutations(1) or less: no simulation was run, so there is no p-value to print
		di "{txt}   E-I Index: {res}`=strtrim(string(round((`r(EI_index)')*1000)/1000,"%9.0g"))'"
	}
	else {
		di "{txt}   E-I Index: {res}`=strtrim(string(round((`r(EI_index)')*1000)/1000,"%9.0g"))'{txt}   p-value: {res}`=strtrim(string(round((`r(EI_pvalue)')*1000)/1000,"%9.0g"))'"
	}

	restore
end	

capture mata : mata drop rep_EIvar()
capture mata : mata drop rep_EIvar_net()

mata:
// QAP permutations of the E-I index.  A network held as stored ties is permuted tie by tie: the tie (u,v) of the
// original lands in the cell (inv[u], inv[v]) of the permuted matrix, so it counts as internal when the two
// attribute values at those positions are equal (the same number as the sum over the permuted n x n matrix, with
// the same random permutations, but O(ties) per draw and no n x n matrix).
real matrix rep_EIvar_net(real scalar reps, pointer(class nw_def scalar) scalar p, real matrix attr)
{
	real matrix el
	real colvector perm, inv, A, intern, extern
	real scalar n, i, total

	if (!nw_ties_only(p)) return(rep_EIvar(reps, *p->get_matrix(), attr))
	n = p->get_nodes()
	el = p->edgelist()
	el = select(el, el[., 1] :!= el[., 2])
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
	return((extern - intern) :/ (extern + intern))
}

real matrix rep_EIvar(real scalar reps, real matrix net0, real matrix attr){
	real scalar nsize, total, EI, i
	real matrix intern, extern, same, attrMat, attrMatTr, permutationVec, perm_net, net1

	nsize = cols(net0)
	attrMat = J(nsize, nsize,1) :* attr
	attrMatTr = attrMat'
	same = (attrMat:== attrMatTr)
	// BUGFIX: this assigned to its argument, which Mata passes by reference: the network's own matrix was
	// overwritten with its 0/1 pattern after every nwmixing call with permutations (values of a valued network lost)
	net1 = (net0:!=0)
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

capture program drop _nwmixing_print
program _nwmixing_print
	syntax , cell(name) col(name) row(name) egovar(string) altervar(string)
	local nr = rowsof(`cell')
	local nc = colsof(`cell')
	local elab : value label `egovar'
	local alab : value label `altervar'
	local w1 = max(8, length("`egovar'"))
	local w2 = 8
	forvalues i = 1/`nr' {
		local v = `row'[`i',1]
		// `: label' must not be expanded when there is no label (cond() and
		// a one-line if both expand it first and print "N invalid name")
		local l = string(`v')
		if "`elab'" != "" {
			local l : label `elab' `v'
		}
		local rl`i' = substr("`l'", 1, 30)
		local w1 = max(`w1', length("`rl`i''"))
	}
	forvalues j = 1/`nc' {
		local v = `col'[1,`j']
		local l = string(`v')
		if "`alab'" != "" {
			local l : label `alab' `v'
		}
		local cl`j' = substr("`l'", 1, 30)
		local w2 = max(`w2', length("`cl`j''"))
	}
	local w2 = `w2' + 1
	di
	di "{txt}{ralign `w1':`egovar'} {c |} `altervar'"
	local hdr "{txt}{space `w1'} {c |}"
	forvalues j = 1/`nc' {
		local hdr "`hdr'{ralign `w2':`cl`j''}"
	}
	local hdr "`hdr'{ralign `=`w2'+1':Total}"
	di "`hdr'"
	di "{hline `=`w1'+1'}{c +}{hline `=(`nc'+1)*`w2'+1'}"
	forvalues i = 1/`nr' {
		local ln "{res}{lalign `w1':`rl`i''} {txt}{c |}{res}"
		local tot 0
		forvalues j = 1/`nc' {
			local x = `cell'[`i',`j']
			local tot = `tot' + `x'
			local ln "`ln'{ralign `w2':`x'}"
		}
		local ln "`ln'{ralign `=`w2'+1':`tot'}"
		di "`ln'"
	}
	di "{hline `=`w1'+1'}{c +}{hline `=(`nc'+1)*`w2'+1'}"
	local ln "{txt}{lalign `w1':Total} {c |}{res}"
	local gt 0
	forvalues j = 1/`nc' {
		local cs 0
		forvalues i = 1/`nr' {
			local cs = `cs' + `cell'[`i',`j']
		}
		local gt = `gt' + `cs'
		local ln "`ln'{ralign `w2':`cs'}"
	}
	local ln "`ln'{ralign `=`w2'+1':`gt'}"
	di "`ln'"
	di
end
