capture program drop nwqap
program nwqap, eclass
syntax [anything (name=formula)] [, detail type(string) typeoptions(string) mode(string) PERMutations(integer 500) save(string) ]
    set more off

	mata: st_rclear()
	
	if "`type'" == "" {
		local type = "logit"
	}
	
	// Get general information.
	local vars = wordcount("`formula'")
	if (`vars' < 1) {
		di "{err}Formula wrongly specified."
		error 6057
	}
	
	local net = word("`formula'", 1)
	nw_syntax `net', max(1)
	nwtomata `net', mat(dvnet)

	// Binary-outcome regression commands (logit is this command's own
	// default) treat any nonzero dependent-variable value as a positive
	// outcome, per Stata's own documented semantics for these commands -
	// so a valued/weighted dependent network's tie strength is silently
	// collapsed to "tie present vs. absent" by the regression command
	// itself, not by any code in this .ado. Warned explicitly here
	// rather than left silent, per this package's harmonisation
	// standard; a genuine weighted-QAP alternative is a separate,
	// larger roadmap item (see docs/CERTIFICATION.md), not implemented
	// by this warning.
	if "`valued'" == "true" & inlist("`type'", "logit", "probit", "cloglog", "scobit") {
		di "{txt}Note: {bf:`net'} is a valued/weighted network, but {bf:`type'} treats any"
		di "{txt}nonzero tie value as a positive outcome - tie {it:strength} is not used."
		di "{txt}Pass {bf:type()} with a regression command appropriate for a continuous"
		di "{txt}outcome (e.g. {bf:type(regress)}) to model tie strength itself."
	}

	// Generate dataset in long format.
	mata: datalong = J((`nodes' * `nodes'),`vars', 0)
	
	local i = 1
	local t = 1
	
	local prefix ""
	
	foreach entry in `formula' {
		nwvalidate `entry'
		// DV or IV is network
		if (r(exists) == "true") {
			nwname `entry'
			local nextname "`r(netname)'"
			if r(nodes) != `nodes' {
				di "{err}Networks of different size."
				error 6056
			}
			nwtomata `entry', mat(onenet)
			mata: _diag(onenet, J(rows(onenet), 1, .))
			mata: temp = transformIntoLong(onenet)
			mata: datalong[,`i'] = temp
			local i = `i' + 1
			local prefix "`prefix' `nextname'"
		}
		// Assume IV to be a variable.
		else {
			confirm variable `entry'
			// Make network out of IV.
			tokenize `mode'
			nwexpand `entry', name(_tempexpand) mode("``t''") nodes(`nodes')
			nwtomata _tempexpand, mat(onenet)
			mata: _diag(onenet, J(rows(onenet), 1, .))
			mata: temp = transformIntoLong(onenet)
			mata: datalong[,`i'] = temp
			local i = `i' + 1
			nwdrop _tempexpand
			if "``t''" == "" {
				local prefix "`prefix' same_`entry'"
			}
			else {
				local prefix "`prefix' ``t''_`entry'"
			}
			local t = `t' + 1
		}
	}
		
	preserve
	drop _all
	local obs = `nodes' * `nodes'
	qui set obs `obs'
	qui foreach entry in `formula' {
		gen `entry' = .
	}
	mata: st_store(.,.,datalong)
		
	tempname memhold
    tempfile results
	
	qui gen `net'_original = `net'
	qui replace `net' = .
	
	quietly postfile `memhold' `formula' using `results', replace
	
	// Run regression on permutations.
	set more off
	di 
	local perm_running 1
	qui forvalues j = 1/`permutations' {
		if `j' == 1 {
			noisily di "{txt}Permutation: 1 out of `permutations'"
		}
		if `j' / 50 >= `perm_running' {
			noisily di "{txt}Permutation: `=`perm_running'*50' out of `permutations'"
			local perm_running = `perm_running' + 1
		}
		// A permutation can, by chance, produce a fully degenerate
		// (no-variation) dependent network - the chosen regression
		// command then can't fit it (e.g. logit's "outcome does not
		// vary") and previously aborted the entire nwqap call rather
		// than just that one permutation. Retried with a fresh draw
		// instead, up to a generous attempt cap; only a pathologically
		// small/structured network should ever exhaust it.
		local permattempts = 0
		local permok = 0
		while `permok' == 0 {
			local permattempts = `permattempts' + 1
			mata: perm_net = permute_net(dvnet)
			mata: net_long = transformIntoLong(perm_net)
			mata: st_store(., "`net'", net_long)
			capture `type' `formula', `typeoptions'
			if _rc == 0 {
				local permok = 1
			}
			else if `permattempts' >= 20 {
				noi di "{err}Permutation `j' produced a degenerate dependent network (no variation) on 20 consecutive draws; aborting."
				error _rc
			}
		}

		mat temp_coeff = e(b)
		local post_txt = ""
		local varsminus = `vars' - 1
		forvalues i = 1/`varsminus' {
			local post_txt = "`post_txt' (`=round(temp_coeff[1,`i'], 0.0001)')"
		}
		local post_txt ="(`=round(_b[_cons], 0.0001)') `post_txt'"
		post `memhold' `post_txt'
	}
	postclose `memhold'
	
	// Run regression with original data.
	qui replace `net' = `net'_original
	if "`detail'" != "" {
		`type' `formula'
	}
	else {
		quietly `type' `formula'
	}
	mat reg_results = e(b)
	
	// Calculate p-values.
	use `results', clear
	if "`save'" != "" {
		save "`save'", replace
	}	
	matrix pvalues = J(1, `vars', .)
	// QAP-based variance of each coefficient, from its own permutation
	// distribution - not a classical OLS/logit variance (which is
	// exactly what QAP permutation testing exists to avoid trusting:
	// dyadic network data violates the independent-observations
	// assumption those classical formulas need). Used below to post a
	// genuinely valid e(V) for eclass/postestimation support, rather
	// than either fabricating an invalid classical one or leaving
	// postestimation commands like `test'/`lincom' unusable.
	matrix permvar = J(1, `vars', .)
	local k = 1
	qui foreach entry in `formula' {
		if ("`entry'" == "`net'") {
			local orig_result = reg_results[1,`vars']
		}
		else {
			local orig_result = reg_results[1,`k']
		}

		local novariation = "false"
		sum `entry'
		// captured immediately - the count calls below are also
		// r-class and would otherwise overwrite r(Var)/r(mean) before
		// this loop iteration gets to use them
		local entryvar = r(Var)
		if (`r(sd)' == 0) {
			local novariation = "true"
			di "`novariation'"
		}
		local diff = abs(r(mean) - `orig_result')
		local upper_mark = r(mean) + `diff'
		local lower_mark = r(mean) - `diff'
		count if `entry' > `upper_mark'
		local upper = r(N)
		count if `entry' < `lower_mark'
		local lower = r(N)
		local outer = `upper' + `lower'
		count
		local total = r(N)
		local p = `outer' / `total'
		if "`novariation'" == "true" {
			local p = "."
		}
		if ("`entry'" == "`net'") {
			mat pvalues[1,`vars'] = `p'
			mat permvar[1,`vars'] = `entryvar'
		}
		else {
			mat pvalues[1,`k'] = `p'
			mat permvar[1,`k'] = `entryvar'
			local k = `k' + 1
		}
	}
	restore
	
	//  Display results.
	local max_l = 0
	tokenize "`prefix'"
	if `max_l' < 20 {
		local max_l = 20
	}
	di 
	di 
	qui nwsummarize `net'
	local dyads = `r(nodes)' * `r(nodes)' - `r(nodes)' 
	di "{txt}Multiple Regression Quadratic Assignment Procedure"
	di
	di "{txt}  Estimation{col 25}={res}  QAP" 
	di "{txt}  Regression{col 25}={res}  `type'"
	di "{txt}  Permutations{col 25}={res}  `permutations'"  
	di "{txt}  Number of vertices{col 25}=  {res}`r(nodes)'" 
	if r(directed) == "true" {
		di "{txt}  Number of arcs{col 25}=  {res}`r(arcs)'" 
	}
	if r(directed) == "false" {
		di "{txt}  Number of edges{col 25}=  {res}`r(edges)'"
	}
	//di "{txt}  Number of dyads{col 25}=  {res}`dyads'"
	di 
	di "{txt}{hline `=`max_l' + 3'}{c TT}{hline 25}"
	di "{col 2}{ralign `=`max_l'+1':`net'}{col `=`max_l' + 4'}{c |}{col `=`max_l' + 11'}Coef.{col `=`max_l' + 20'}P-value"
	di "{hline `=`max_l' + 3'}{c +}{hline 25}"
	local constant = round(reg_results[1,`=`vars''], 0.000001)
	
	forvalues k=2/`vars'{
		local coeff = `=round(float(reg_results[1,`=`k'-1']), 0.000001)'
		local pvalue = `=round(float(pvalues[1,`=`k'-1']),0.001)'
		di as text "{txt}{col 2}{ralign `=`max_l'+1':``k''}{col `=`max_l' + 4'}{c |}{col `=`max_l' + 5'}{ralign 11:{res}`coeff'}{col `=`max_l' + 20'}{ralign 5:`pvalue'}"
	}
	di "{txt}{col 2}{ralign `=`max_l'+1':_cons}{col `=`max_l' + 4'}{c |}{col `=`max_l' + 5'}{ralign 11:{res}`constant'}"
	di "{txt}{hline `=`max_l' + 3'}{c BT}{hline 25}"
	di "{error}`message'"

	// eclass integration: e(b)/e(V) are posted properly (via
	// ereturn post, using the already-tokenized IV names from the
	// display loop above) rather than left as bare st_matrix writes,
	// so estimates store/estimates table/ereturn list all work as
	// expected for an estimation command. e(V) is a diagonal matrix
	// built from each coefficient's own QAP-permutation variance
	// (computed above, alongside the p-values) - not the classical
	// OLS/logit covariance, which would be actively misleading here:
	// dyadic network data violates the independent-observations
	// assumption those formulas require, which is the entire reason
	// QAP permutation testing exists in the first place. No predict
	// subroutine is implemented (QAP prediction is not as well
	// established a concept as for standard regression, and it's a
	// separate concern from getting e(b)/e(V)/postestimation-storage
	// support in place) - see docs/CERTIFICATION.md's Pending table.
	local ivnames ""
	forvalues k=2/`vars' {
		local ivnames "`ivnames' ``k''"
	}
	tempname b V
	matrix `b' = reg_results
	matrix `V' = diag(permvar)
	// Some regression commands (e.g. logit) attach their own equation
	// name (their depvar) to e(b)'s column stripe, while regress does
	// not - a bare "matrix colnames" call preserves any equation name
	// already on the stripe rather than clearing it (per Stata's own
	// documented behaviour), so `b' and `V' could end up with mismatched
	// stripes (one eq-qualified, one not) depending on `type''s own
	// convention. Blanked explicitly first so the two always match,
	// regardless of the regression command used.
	matrix coleq `b' = _
	matrix coleq `V' = _
	matrix roweq `V' = _
	matrix colnames `b' = `ivnames' _cons
	matrix colnames `V' = `ivnames' _cons
	matrix rownames `V' = `ivnames' _cons
	ereturn post `b' `V', depname(`net') obs(`dyads')
	ereturn local cmd "nwqap"
	ereturn local title "Multivariate regression quadratic assignment procedure (QAP)"
	ereturn local depvar "`net'"
	ereturn local qap_regcmd "`type'"
	ereturn scalar permutations = `permutations'
	ereturn matrix pvalues pvalues
	mata: mata drop datalong net_long perm_net onenet dvnet

end

capture mata mata drop transformIntoLong()
capture mata mata drop permute_net()
mata:	
real matrix transformIntoLong(real matrix mymat){ 
	size = rows(mymat)
	mymatlong = J((size * size), 1, 0)
	for (j = 1 ; j <= size; j++) {
		startindex = ((j-1) * size) + 1
		endindex = (j*size) 
		mymatlong[|startindex,1\endindex,1|] = mymat[,j]
	}
	return(mymatlong)
}

real matrix permute_net(real matrix nwadj) {
	nsize = rows(nwadj)
	permutationVec = unorder(nsize)
	return (nwadj[permutationVec, permutationVec])
}
end
	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
