/***
{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwmixing {hline 2}}E-I index and mixing table for a categorical node attribute{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmixing}
[{it:{help netname}}]
{cmd:,}
{opth attribute(varname)}
[{opt eiplot}
{opt eiplotoptions(string)}
{opt plot}
{opt plotoptions(string)}
{opth permutations(int)}
{opth save(filename)}
{it:tab_options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth attribute(varname)}}Categorical (string or numeric) node attribute to cross-tabulate
ties by{p_end}
{synopt:{opt eiplot}}Plot the null (QAP-permutation) distribution of the E-I index, with the observed
value marked{p_end}
{synopt:{opt eiplotoptions(string)}}Additional options forwarded to the {opt eiplot}'s own
{help kdensity}{p_end}
{synopt:{opt plot}}Plot the ego/alter mixing table via {help tabplot}{p_end}
{synopt:{opt plotoptions(string)}}Additional options forwarded to {opt plot}'s own {help tabplot}{p_end}
{synopt:{opth permutations(int)}}Number of QAP permutations for the E-I index's own null
distribution and p-value; default = 100. Set to 1 to skip the permutation test entirely (only the
observed table/index are reported){p_end}
{synopt:{opth save(filename)}}Save the QAP permutation draws (variable {it:EI_simulated}) and the
observed value (variable {it:EI_observed}) to a new dataset{p_end}
{synopt:{it:tab_options}}Any other option is forwarded to the underlying {help tabulate twoway:tab}
call that builds the mixing table (e.g. {opt row}, {opt column}, {opt cell}){p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwmixing} cross-tabulates every tie in the network by the {opt attribute()} value of its ego
and alter (a "mixing table" or "mixing matrix"), and computes Krackhardt & Stern's (1988) E-I index:
the number of ties {it:external} to an attribute category minus the number {it:internal} to it,
divided by their sum. The index ranges from -1 (every tie stays within its own category - maximal
homophily/segregation) to +1 (every tie crosses categories - maximal heterophily/integration); 0
indicates ties are split between internal and external exactly as the network's overall tie count
would suggest.

{pstd}
Ties are treated as unvalued (presence/absence only) throughout - tie strength does not affect the
mixing table or the E-I index.

{pstd}
With {opt permutations()} greater than 1 (the default, 100), {cmd:nwmixing} also runs a QAP
permutation test: the attribute assignment is held fixed while the network itself is repeatedly
randomly permuted, building a null distribution of the E-I index under "no association between this
attribute and tie placement", and reports a two-sided p-value.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - ego/alter mixing is directional for a directed network (an
{it:attribute}{cmd:_ego}/{it:attribute}{cmd:_alter} pair is not symmetric); an undirected network's
own mixing table instead shows each edge counted from both endpoints, noted explicitly in the
output. Weighted: not applicable - see Description (ties are always treated as unvalued). Signed:
not checked. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(EI_index)}		the observed E-I index
	  {bf:r(EI_pvalue)}		two-sided QAP permutation p-value (only when {opt permutations()} > 1)

	Macros
	  {bf:r(netname)}		the network name
	  {bf:r(attribute)}		the {opt attribute()} variable name

	Matrices
	  {bf:r(table)}			the mixing table's own tie counts
	  {bf:r(col)}			the mixing table's column category values
	  {bf:r(row)}			the mixing table's row category values

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwmixing flomarriage, attribute(priorates)}

{title:References}

{pstd}
Krackhardt, D., Stern, R.N. (1988). Informal networks and organizational crises: An experimental
simulation. {it:Social Psychology Quarterly} 51(2), 123-140.

{title:See also}

	{help nwassortativity}, {help nwqap}, {help nwcorrelate}

***/
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
	nw_syntax `netname', max(1)
	// BUGFIX: this stored the STRING "0" or "1" (both non-empty), not a
	// genuine boolean - so the later `if "`undirected''" != ""' display
	// guard was unconditionally true regardless of the network's actual
	// directedness, printing "The network is undirected." even for a
	// directed network. Matches the boolean-local convention used
	// elsewhere in this package (`directed'/`valued' etc: the string
	// "true" or empty).
	local undirected = cond("`directed'" == "false", "true", "")
	nw_datasync `netname'
	
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
