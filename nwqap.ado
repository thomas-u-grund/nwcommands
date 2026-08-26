/***
{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwqap  {hline 2}}Multivariate QAP regression{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwqap} 
{it:{help netname:depnet}}
[{it:{help nwqap##independentvariables:indepvars}}]
, 
{opth permutations(int)}
{opt mode}({it:{help nwexpand##expand_mode:mode}})
{opt type(regcmd)}
{opt typeoptions(regoptions)}
{opt detail}
{opt save}({it:{help filename}})
{opth predict(newnetname)}



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth permutations(int)}}number of QAP permutations; default = 500{p_end}
{synopt:{opt mode}({it:{help nwexpand##expand_mode:mode}})}modes for expanding variables to networks{p_end}
{synopt:{opt type}({it:{help nwqap##regcmd:regcmd}})}regression command to be used for dyad dataset; default = {it:logit}{p_end}
{synopt:{opt typeoptions(regoptions)}}options to be passed on to the regression command{p_end}
{synopt:{opt detail}}display details of regression results{p_end}
{synopt:{opt save}({it:{help filename}})}save coefficients from permutations in file{p_end}
{synopt:{opth predict(newnetname)}}store the fitted dyad-level values (from {bf:type()}'s own default prediction, e.g. Pr(y=1) for {bf:logit}/{bf:probit}, the fitted mean for {bf:regress}) as a new valued network{p_end}


{title:Description}

{pstd}
MR-QAP is a multiple regression procedure used to assess the impact of independent variables 
upon a dependent variable. In standard regression techniques, the typical "unit of analysis" 
is an individual observation. In MR-QAP analysis, the unit of analysis is a dyad, a pair of individuals 
who may or may not have some sort of relation connecting them to one another.

{pstd}
{cmd:nwqap} reshapes a network to a dataset of edges/arcs. For example, a directed network with 10 nodes is 
transformed in a dataset with 90 dyads (selfloops are not permitted).

{pstd}
The dependent variable is {it:y_ij}, indicating the network relationship between nodes
{it:i} and {it:j}.{p_end} 
{marker independentvariables}{...}
{pstd}Independent variables can be other {help netname:networks} or normal {help varname:variables}.  
Normal variables are expanded to networks of the same size as the dependent network using 
{help nwexpand}. The default {bf:mode} is {bf:"same"} (see {help nwexpand##mode:here} for other modes.
When more than one {help varname} is specified as independent variable, different modes can be 
selected for each variable, e.g. {bf:mode(same dist invdist)} chooses mode {bf:"dist"} for the 
second {help varname} that appears as independent variable.{p_end}   
{marker regcmd}{...}
{pstd}
{cmd:nwqap} performs the regression specified in {bf:type()}, by default {help logit} regression
is choosen. But notice that any other type of regression can be used (e.g. {help probit}, {help xtmixed}).
Furthermore, options are passed on to the selected regression command with {bf:typeoptions()}.
This gives a lot of flexibility to perform dyad-level regression. For example instead of logistic 
regression one can use probit regression with option {it:asis}:

	{bf:nwqap glasgow2 glasgow1, type(probit) typeoptions(asis)} 

{pstd}
The raw output of this dyad-level regression is displayed with option {bf:detail}.

{pstd}
{opth predict(newnetname)} stores {bf:type()}'s own fitted dyad-level values - whatever statistic
that regression command's own default {help predict} reports (predicted probability for
{bf:logit}/{bf:probit}/{bf:cloglog}, the fitted linear mean for {bf:regress}, etc.) - as a new
valued network, e.g. for comparing predicted tie probabilities against the observed network as a
goodness-of-fit check. Captured from the one real (non-permuted), observed-data regression this
command already runs internally to obtain {bf:type()}'s own coefficients - not from any of the
{opth permutations(int)} null-model draws. The diagonal (excluded from estimation, like every
self-tie in this command's dyadic reshaping) is set to 0 in the resulting network. A name collision
with an existing network is handled the same non-destructive way every other network-creating
command in this package handles it (auto-renamed with a warning, unless {it:newnetname} is free).

{pstd}
Once a dataset is assembled and a regression is carried out, the resulting coefficients indicate 
the direction of the effect of independent variables upon the dependent variable. However, calculating 
the standard error of these coefficients has been shown to lead to biased results when autocorrelation 
exists - which occurs, for instance, when interpersonal relations determine individual behavior 
(Krackhardt 1988). 

{pstd}
Since this method is employed to test hypotheses that suggest interpersonal relations 
matter, a different significance test is needed. The second step of QAP regression, therefore, is to repeatedly permute rows and columns of the matrix representing the dependent variable and after each permutation to re-compute
regression coefficients. Indicators of statistical significance report the proportion of results from randomly altered matrices with 
regression coefficients as high as those from the unaltered dependent variable matrix (Krackhardt 1987).

{pstd}
In this second step, {cmd:nwqap} randomly permutes rows and columns (together) of the dependent 
matrix (dependent network) and recomputes the regression, storing all coefficients. By default this step 
is repeated 500 times. The number of permutations can be changed with the option {bf:permutations}.
The coefficients of all these permutations are saved with {opth save(filename)}. Based one the distribution
of coefficients, {cmd:nwqap} calculates adjusted p-values and saves them in {it:e(pvalues)}.


{pstd}
{it:References}

{pmore}
Grund, T. and Densley, J. (2012). "Ethnic Heterogeneity in the Activity and Structure of a Black Street Gang." European Journal of Criminology, Vol. 9, Issue 3, pp. 388-406.

{pmore}
Krackhardt, David. (1987). "QAP Partialling as a Test of Spuriousness." Social Networks 9: 171-186.

{pmore}
Krackhardt, David. (1988). "Predicting with Networks: Nonparametric Multiple Regression Analysis of Dyadic Data." Social Networks 10: 359-381.


{title:Examples}
	
	{cmd:. nwwebuse glasgow}
	{cmd:. nwqap glasgow2 glasgow1 smoke1 sport1}
	{cmd:. nwqap glasgow2 glasgow1 smoke1 sport1, predict(glasgow2_fitted)}


	{txt}Multiple Regression Quadratic Assignment Procedure

	{txt}  Estimation{col 25}={res}  QAP
	{txt}  Regression{col 25}={res}  logit
	{txt}  Permutations{col 25}={res}  500
	{txt}  Number of vertices{col 25}=  {res}50
	{txt}  Number of arcs{col 25}=  {res}116

{txt}{hline 23}{c TT}{hline 25}
{col 2}{ralign 21:glasgow2}{col 24}{c |}{col 31}Coef.{col 40}P-value
{hline 23}{c +}{hline 25}
{txt}{col 2}{ralign 21:glasgow1}{col 24}{c |}{col 25}{ralign 11:{res}3.652579}{col 40}{ralign 5:0}
{txt}{txt}{col 2}{ralign 21:same_smoke1}{col 24}{c |}{col 25}{ralign 11:{res}.514058}{col 40}{ralign 5:.018}
{txt}{txt}{col 2}{ralign 21:same_sport1}{col 24}{c |}{col 25}{ralign 11:{res}.217359}{col 40}{ralign 5:.394}
{txt}{col 2}{ralign 21:_cons}{col 24}{c |}{col 25}{ralign 11:{res}-4.125208}
{txt}{hline 23}{c BT}{hline 25}
	
{pstd}
This example shows that two individuals are more likely to be friends at time2 (glasgow2) 
when they already were friends at time1 (glasgow1). Furthermore two individuals {it:i} and
{it:j} are more likely to be friends at time2 when they both scored the same on smoking at
time1 (smoke1). There is no effect for both having scored the same on sport1. 


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, and undirected networks are not collapsed to unique dyads - both
{it:(i,j)} and {it:(j,i)} appear as separate observations in the dyad-level dataset (for an
undirected network they carry the same value, so this does not bias point estimates, but it does
mean the reported "Number of obs" and any raw regression standard errors reflect double-counted
dyads; QAP's own permutation-based p-values, not these raw standard errors, are what {cmd:nwqap}
actually reports). Weighted: {bf:W3}, explicit binary-only for the dependent network under the
default (and any other binary-outcome) {opt type()} - {help logit}, {help probit}, {help cloglog},
and {help scobit} all treat any nonzero value as a positive outcome (this is those commands' own
documented behavior, not something {cmd:nwqap} does intentionally) - so a valued/weighted
dependent network's tie strength is silently discarded by the chosen regression command unless a
continuous-outcome {opt type()} (e.g. {opt type(regress)}) is used instead; {cmd:nwqap} now warns
explicitly when this combination is detected, rather than leaving it silent. Independent networks
and variables are not affected - their values enter the regression directly, weighted or not.
Signed: not checked. Two-mode: not checked. A full weighted-QAP alternative (rather than a warning)
remains on the roadmap as a larger follow-on (see {browse "docs/CERTIFICATION.md":CERTIFICATION.md}).


{title:Stored results}

{pstd}
{cmd:nwqap} is an {bf:eclass} command: results are posted with {help ereturn:ereturn}, so
{help estimates store}, {help estimates table}, and other standard postestimation commands
that only need {it:e(b)}/{it:e(V)} (e.g. {help test}, {help lincom}) work as usual. {it:e(V)}
is a diagonal matrix built from each coefficient's own QAP-permutation variance, not a
classical OLS/logit covariance matrix - dyadic network data violates the independent-
observations assumption those classical formulas require, which is the entire reason QAP
permutation testing exists in the first place. A native postestimation {help predict} does not
work after {cmd:nwqap} returns (see {help nwqap##independentvariables:Description} above for why -
the dyad-level dataset {bf:type()} actually fits is a transient internal detail, not the current
dataset once {cmd:nwqap} exits); use {opth predict(newnetname)} instead to capture fitted dyad-level
values directly, at the one point internally where they are genuinely meaningful.

	Scalars
	  {bf:e(N)}		number of dyad-level observations
	  {bf:e(permutations)}	number of QAP permutations

	Macros
	  {bf:e(cmd)}		{bf:nwqap}
	  {bf:e(title)}		title of estimation
	  {bf:e(depvar)}	name of dependent network
	  {bf:e(qap_regcmd)}	regression command used ({bf:type()})

	Matrices
	  {bf:e(b)}		coefficient vector
	  {bf:e(V)}		diagonal matrix of QAP-permutation coefficient variances
	  {bf:e(pvalues)}	matrix with QAP p-values, in the same column order as {bf:e(b)}

{title:See also}

	{help nwergm}, {help nwpermute}

***/

capture program drop nwqap
program nwqap, eclass
syntax [anything (name=formula)] [, detail type(string) typeoptions(string) mode(string) PERMutations(integer 500) save(string) predict(string) plot name(string) ]
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
	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
