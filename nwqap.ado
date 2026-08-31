
capture program drop nwqap
program nwqap, eclass
syntax [anything (name=formula)] [, detail type(string) typeoptions(string) mode(string) PERMutations(integer 500) save(string) predict(string) plot name(string) qapspp]
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
	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `nw_syntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message.
	unw_defs
	capture nw_syntax `net', max(1)
	if _rc != 0 {
		di "{err}Network {bf:`net'} not found."
		error `errNWsNotFound'
	}
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
			// BUGFIX: without network(`net'), nwexpand falls back to its
			// own default node names ("n1".."nK"), which do not match
			// `net''s own node names (e.g. "g1".."g54") already loaded in
			// the active dataset. nwexpand's own internal nwload(,xvars)
			// call then tries to sync the active dataset to this
			// mismatched-node-name network via nw_datasync's merge -
			// which, on a 0% name match, appends every node as an
			// unmatched observation instead of merging in place, silently
			// doubling the dataset and leaving every OTHER variable
			// (including a second IV's own attribute column, if this
			// formula has more than one) reading back as entirely
			// missing on the next attempt. Passing network(`net') makes
			// nwexpand reuse `net''s own real node names, so the merge is
			// a genuine one-to-one match instead of a wholesale miss -
			// confirmed directly: two nwexpand calls in the same session
			// only corrupt each other's data when network() is omitted.
			nwexpand `entry', name(_tempexpand) mode("``t''") nodes(`nodes') network(`net')
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
	// BUGFIX: this call was never captured (and, without `detail', ran
	// `quietly' too - suppressing even Stata's own native error text),
	// so if the REAL (non-permuted) data can't be fit by `type' (e.g.
	// perfect prediction/separation - a real possibility on a small or
	// highly structured network, unlike the permutation loop above,
	// which already retries a degenerate permutation draw rather than
	// failing outright), nwqap aborted completely silently after
	// already spending the full `permutations' budget - only a bare
	// "r(2000);" printed, no diagnostic text at all. Captured and given
	// a clear message instead.
	if "`detail'" != "" {
		capture noisily `type' `formula'
	}
	else {
		capture quietly `type' `formula'
	}
	if _rc != 0 {
		di "{err}The observed-data model could not be fit ({bf:`type' `formula'} failed, error `=_rc') - this can happen with perfect prediction/separation, a fully degenerate dependent network, or a misspecified model. Try {bf:detail} to see the underlying regression command's own error text."
		error _rc
	}
	mat reg_results = e(b)

	// predict(): captured HERE, not after the eclass ereturn post further
	// down - this is the one point in the whole program where the
	// dyad-level long-format dataset is still the active dataset AND
	// `type''s own live estimation results (e(sample) etc.) genuinely
	// correspond to it, so `type''s own native predict (whatever default
	// statistic it reports - Pr(y=1) for logit/probit, the fitted mean
	// for regress, etc.) is meaningful. Every later step (`restore' back
	// to the original node-level dataset, this program's own `ereturn
	// post' of QAP-permutation-based e(V)) intentionally does not touch
	// Stata's native estimation-sample bookkeeping, so a plain postestimation
	// `predict' typed by the user after nwqap returns would not work -
	// this is why the previous version of this file explicitly did not
	// offer one; genuine dyad-level fitted values are captured directly,
	// on demand, instead.
	if "`predict'" != "" {
		tempvar __nw_fittedvar
		qui predict `__nw_fittedvar'
		mata: fitted_long = st_data(., "`__nw_fittedvar'")
	}

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
	// plot(): one histogram-plus-reference-line panel per coefficient,
	// each built the SAME way R's sna::plot.qaptest() draws a single
	// coefficient's own permutation null - a dashed line at the
	// observed (real-data) coefficient against a histogram of its
	// `permutations' QAP-permutation draws (the `entry' variable
	// already loaded into the active dataset by `use `results'' above).
	// Built INSIDE this same loop (not a second pass over `formula')
	// since `orig_result' is already computed here for the p-value
	// calculation immediately below - reusing it rather than
	// recomputing the same `entry'-to-column mapping a second time.
	// Grayscale by design, matching every other plot this package
	// produces (Stata Journal figures must stay legible in black and
	// white).
	// BUGFIX: panel titles used the raw `entry' loop token (a literal
	// word from the typed formula() - the dependent variable's own
	// name, or a bare nodal-attribute name like "smoke1") rather than
	// the actual fitted coefficient name it corresponds to. The
	// dependent-variable token's own iteration (`entry'=="`net'")
	// computes results for the CONSTANT (reg_results[1,`vars'], the
	// last column) - correct data, but a panel titled "glasgow2" for
	// what is really the model's own constant is misleading, not
	// merely stylistic; likewise a bare nodal attribute like "smoke1"
	// is fit as "same_smoke1" (mode()'s own dyadic expansion) and
	// should say so.
	//
	// `reg_results' (== e(b) from the internal `type' `formula'' call,
	// captured above) is NOT a source for these names - its columns
	// are named after the literal formula() tokens (e.g. plain
	// "smoke1"), since that is what was actually regressed; the
	// "same_"/mode()-prefixed display name is cosmetic, applied only
	// to the matrices `nwqap' hands back to the user afterwards
	// (`ivnames', built from `prefix' below). `prefix' itself is
	// already fully built by this point (populated token-by-token in
	// the formula-processing loop above, one token per formula()
	// word including `net' itself in first position) and is exactly
	// what the results table two hundred lines down uses for the same
	// purpose (``k'' there, after `tokenize "`prefix'"') - reused here
	// via `: word' instead, since tokenizing `prefix' this early would
	// clobber the positional locals this loop and the rest of the
	// program still rely on.
	local __combine_list ""
	local k = 1
	qui foreach entry in `formula' {
		if ("`entry'" == "`net'") {
			local orig_result = reg_results[1,`vars']
			local __coefname "_cons"
		}
		else {
			local orig_result = reg_results[1,`k']
			local __coefname : word `=`k'+1' of `prefix'
		}

		if "`plot'" != "" {
			tempname __g
			// See nwcug.ado's own plot block for why the reference
			// line is a foreground plot layer (hidden fixed-0/1
			// second y-axis) rather than xline() - xline() draws
			// behind the histogram's solid fcolor() bars, hiding the
			// line wherever a bar covers it.
			twoway (histogram `entry', fcolor(gs14) lcolor(gs8)) ///
				(scatteri 0 `orig_result' 1 `orig_result', recast(line) ///
					lcolor(black) lwidth(thick) lpattern(dash) yaxis(2)), ///
				yscale(off axis(2) range(0 1)) ///
				title("`__coefname'", size(small)) ///
				xtitle("") ytitle("") ///
				legend(off) nodraw name(`__g', replace)
			local __combine_list `"`__combine_list' `__g'"'
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
	if "`plot'" != "" {
		if "`name'" == "" {
			local name "qap"
		}
		graph combine `__combine_list', cols(2) ///
			title("QAP permutation null distributions", size(medium)) ///
			name(`name', replace)
		foreach __g of local __combine_list {
			capture graph drop `__g'
		}
	}

	// qapspp: double semi-partialling (Dekker, Krackhardt & Snijders
	// 2007) - see this file's own {help nwqap##qapspp:qapspp} doc
	// section for the full account. Overwrites pvalues[1,k]/permvar[1,k]
	// for each independent-variable column only (k=1..`vars'-1) - the
	// constant's own p-value (column `vars', already set above) is left
	// as the plain single-permutation result; DSP is not defined for it.
	// Runs entirely off `datalong' (already in Mata, unaffected by the
	// `restore' below - real OLS residualization/refitting, not a call
	// through `type'/`typeoptions', matching Dekker et al.'s own
	// procedure directly: semi-partialling is always OLS, independent
	// of which model the real coefficients were fit with).
	if "`qapspp'" != "" {
		forvalues k = 1/`=`vars'-1' {
			mata: dsp_res = _nwqap_dsp_pvalue(datalong, `nodes', `k', `permutations', st_matrix("reg_results")[1,`k'])
			mata: st_local("__dsp_p", strofreal(dsp_res[1,1]))
			mata: st_local("__dsp_var", strofreal(dsp_res[1,2]))
			mat pvalues[1,`k'] = `__dsp_p'
			mat permvar[1,`k'] = `__dsp_var'
		}
	}

	restore
	if "`plot'" != "" {
		di as txt "(plot saved as {bf:`name'}; each panel is one coefficient's histogram of `permutations' QAP-permutation draws, dashed line marks the observed coefficient)"
	}

	// predict(): reshape the dyad-level fitted values captured earlier
	// back into an n x n matrix (transformOutOfLong() - the exact inverse
	// of transformIntoLong()'s own column-major convention) and materialize
	// them as a new network via nwset. The diagonal is forced to a clean 0
	// rather than left holding whatever Stata's own predict returned for
	// the diagonal's fully-missing predictors (always missing, since every
	// network/attribute IV column has its own diagonal set missing before
	// estimation - see the `_diag(onenet, ...)' calls above).
	//
	// BUGFIX: `predict()' is a derived-output slot (like nwpermute's own
	// generate(), not the caller's primary network identity the way
	// nwset's/nwgenerate's own name() is) - repeating the same predict()
	// name across calls is expected to auto-rename, not error (see
	// cscripts/test_nwqap.do's own explicit collision-handling case). This
	// used to work because nwset's own name() collision auto-renamed
	// unconditionally; once nwset.ado's own guard was tightened
	// (harmonisation unit 116: an explicit name() collision now errors
	// unless replace is given, since name() there IS the caller's primary
	// network identity) an explicit predict(`predict') collision started
	// raising an uncaught r(6099) instead of the auto-rename this option
	// has always been documented to do. Resolved the same way as
	// nwuse.ado's own identical `nwappend, force' case: pre-resolve the
	// actual (possibly auto-incremented) target name via nwvalidate before
	// calling nwset, so nwset is only ever asked to create under a name
	// already confirmed free.
	if "`predict'" != "" {
		nwvalidate `predict'
		local predict = r(validname)
		mata: fitted_mat = transformOutOfLong(fitted_long, `nodes')
		mata: _diag(fitted_mat, J(`nodes', 1, 0))
		if "`directed'" == "true" {
			qui nwset, mat(fitted_mat) name(`predict') directed labs(`labs')
		}
		else {
			qui nwset, mat(fitted_mat) name(`predict') undirected labs(`labs')
		}
		mata: mata drop fitted_long fitted_mat
	}

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
	local constant = round(reg_results[1,`=`vars''], 0.001)

	forvalues k=2/`vars'{
		local coeff = `=round(float(reg_results[1,`=`k'-1']), 0.001)'
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
	// QAP permutation testing exists in the first place. Fitted dyad-level
	// values (predict()) are captured separately, earlier in this program
	// (see that block's own header comment) - a native postestimation
	// predict cannot work after THIS ereturn post, since it runs against
	// the current (node-level) dataset, not the transient dyad-level one
	// type()'s own estimation actually ran against.
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
capture mata mata drop transformOutOfLong()
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

/*
	Inverse of transformIntoLong() above: reshapes a dyad-indexed long
	column vector back into an n x n matrix, using the identical
	column-major indexing convention (column j occupies long-format rows
	(j-1)*n+1 .. j*n) - used by predict()'s own fitted-value network
	reconstruction below.
*/
real matrix transformOutOfLong(real matrix veclong, real scalar size){
	real matrix mymat
	real scalar j, startindex, endindex

	mymat = J(size, size, 0)
	for (j = 1; j <= size; j++) {
		startindex = ((j-1) * size) + 1
		endindex = (j * size)
		mymat[,j] = veclong[|startindex,1\endindex,1|]
	}
	return(mymat)
}
end

// qapspp (Dekker, Krackhardt & Snijders 2007 double semi-partialling) -
// see nwqap.ado's own {help nwqap##qapspp:qapspp} doc section for the
// full account of what/why. `_nwqap_ols_resid_full()`/`_nwqap_ols_coef()`
// are small, deliberately generic OLS helpers (no missing-data handling
// of their own beyond the explicit `mask' argument) - this package's own
// diagonal-is-missing convention (`_diag(onenet, J(rows(onenet),1,.))`,
// set once per network before it ever reaches `datalong') is the ONLY
// source of missingness anywhere in this data by construction, so a
// fixed, data-independent "which long-format positions are the
// diagonal" mask (built once from `nodes' alone) is used throughout
// rather than re-deriving it from `missing()' each time - correct
// specifically because that invariant holds, not a general-purpose
// missing-data routine.
capture mata mata drop _nwqap_diagmask()
capture mata mata drop _nwqap_ols_resid_full()
capture mata mata drop _nwqap_ols_coef()
capture mata mata drop _nwqap_dsp_pvalue()
mata:
real colvector _nwqap_diagmask(real scalar nodes) {
	real colvector offdiag
	real scalar j
	offdiag = J(nodes*nodes, 1, 1)
	for (j=1; j<=nodes; j++) offdiag[(j-1)*nodes+j, 1] = 0
	return(offdiag)
}

// OLS of y on X (intercept added internally) using only `mask'==1 rows;
// returns a FULL-length residual vector, with 0 (a placeholder, never
// used - always re-masked before any later computation reads it) at
// the masked-out (diagonal) positions. X may have zero columns (the
// single-independent-variable case, nothing left to partial out) - the
// intercept-only design matrix that reduces to is still valid.
real colvector _nwqap_ols_resid_full(real colvector y, real matrix X, real colvector mask) {
	real colvector ys, resid_full
	real matrix Xs, Xd, b

	ys = select(y, mask)
	if (cols(X) > 0) Xs = select(X, mask)
	else Xs = J(rows(ys), 0, .)
	Xd = (J(rows(Xs),1,1), Xs)
	b = invsym(cross(Xd,Xd)) * cross(Xd,ys)
	resid_full = J(rows(y), 1, 0)
	resid_full[selectindex(mask), .] = ys - Xd*b
	return(resid_full)
}

// Bivariate OLS slope of y on x (intercept added internally) - both
// already masked/filtered to only the rows that matter (unlike
// _nwqap_ols_resid_full() above, which takes the mask itself and
// returns a full-length vector - this one is deliberately simpler,
// called once per permutation draw inside the loop below).
real scalar _nwqap_ols_coef(real colvector y, real colvector x) {
	real matrix Xd, b
	Xd = (J(rows(x),1,1), x)
	b = invsym(cross(Xd,Xd)) * cross(Xd,y)
	return(b[2,1])
}

// Full DSP procedure for one independent-variable column (k, 1-indexed
// among the `vars'-1 independent variables - datalong's own column for
// it is k+1, since column 1 is always the dependent network). Returns
// (p, permutation-variance) - the same two quantities the plain
// single-Y-permutation loop in nwqap.ado's own program body computes,
// via the identical two-tailed empirical-p-value convention (so the two
// procedures' own output is directly comparable), just derived from
// this residualized-and-permuted null distribution instead.
real rowvector _nwqap_dsp_pvalue(real matrix datalong, real scalar nodes,
		real scalar k, real scalar permutations, real scalar origcoef)
{
	real scalar vars, xk_col, j, i, mean_null, var_null, diff, upper_mark, lower_mark, outer, p
	real colvector offdiag, Y, Xk, Yresid_full, Xkresid_full, nulldist
	real matrix Xother, Xk_perm_mat
	real colvector Xk_perm_full

	vars = cols(datalong)
	xk_col = k + 1
	offdiag = _nwqap_diagmask(nodes)

	Y = datalong[.,1]
	Xk = datalong[.,xk_col]
	Xother = J(rows(datalong), 0, .)
	for (j=2; j<=vars; j++) {
		if (j != xk_col) Xother = Xother, datalong[.,j]
	}

	Yresid_full = _nwqap_ols_resid_full(Y, Xother, offdiag)
	Xkresid_full = _nwqap_ols_resid_full(Xk, Xother, offdiag)

	nulldist = J(permutations, 1, .)
	for (i=1; i<=permutations; i++) {
		Xk_perm_mat = permute_net(transformOutOfLong(Xkresid_full, nodes))
		Xk_perm_full = transformIntoLong(Xk_perm_mat)
		nulldist[i,1] = _nwqap_ols_coef(select(Yresid_full, offdiag), select(Xk_perm_full, offdiag))
	}

	mean_null = mean(nulldist)
	var_null = variance(nulldist)
	diff = abs(mean_null - origcoef)
	upper_mark = mean_null + diff
	lower_mark = mean_null - diff
	outer = sum(nulldist :> upper_mark) + sum(nulldist :< lower_mark)
	p = outer / permutations

	return((p, var_null))
}
end
	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
