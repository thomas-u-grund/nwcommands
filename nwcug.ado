/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcug {hline 2}}Conditional Uniform Graph (CUG) test{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcug}
[{it:{help netname}}]
{cmd:,}
{opt stat(command)}
{opt rname(string)}
[{opth reps(int)}
{opt seed(int)}
{opt tail(both|upper|lower)}
{opt condition(density|census)}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt stat(command)}}Command template used to compute the test statistic; must contain the literal token {bf:##net##} where the network name belongs{p_end}
{synopt:{opt rname(string)}}Name of the {it:stat}'s {bf:r()} scalar to use as the test statistic{p_end}
{synopt:{opth reps(int)}}Number of conditioned random networks to draw; default = 1000{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before drawing (for reproducibility){p_end}
{synopt:{opt tail(both|upper|lower)}}Which tail(s) to report a p-value for; default = {it:both}{p_end}
{synopt:{opt condition(density|census)}}Null model to condition random draws on; default = {it:density}{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcug} performs a Conditional Uniform Graph (CUG) test (Anderson, Butts and Carley 1999): it
compares an observed network statistic against the distribution of that same statistic computed on
{bf:reps} random networks drawn uniformly from the set of all networks with the same number of nodes
and the same density as {help netname} (using {help nwrandom}'s {bf:density()} conditioning). This
answers "is my observed statistic unusual, given only the size and density of the network?" - a
standard baseline null model in network analysis, since many statistics (e.g. transitivity, number of
components) are mechanically related to density alone, and a CUG test controls for that before
attributing a finding to genuine structure.

{pstd}
{bf:stat()} is a full command template (any {cmd:nw*} command plus whatever options it needs) that
returns a scalar in {bf:r()}; use the literal token {bf:##net##} wherever the network name belongs -
{cmd:nwcug} substitutes it with the observed network's name once, and with a freshly-drawn random
network's name {bf:reps()} times. {bf:rname()} names the returned scalar (without the surrounding
{cmd:r(...)}). Passing whatever {bf:replace}-style option the command needs (as part of the template)
is the caller's responsibility, since the same command runs once per random draw. For example, to
test whether the Florentine marriage network's component count is unusual for its size and density:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcug flomarriage, stat(nwcomponents ##net##, replace) rname(components) reps(1000) seed(12345)}

{pstd}
{opt condition(density|census)} chooses what property of {help netname} the random draws must
share, via {help nwrandom}'s own {bf:density()} (the default) or {bf:census()} conditioning.
{bf:condition(density)} draws uniformly from every network with the same node count and density -
the standard baseline used above. {bf:condition(census)} instead draws uniformly from every
network with the {it:same dyad census} (identical mutual/asymmetric/null tie counts, via
{help nwdyads}) as {help netname} - a stricter, reciprocity-aware null model: two directed networks
can share the same overall density while differing sharply in how many ties are reciprocated, so a
statistic that is unremarkable once density alone is held fixed can still be unusual once
reciprocity is held fixed too (or vice versa). {bf:condition(census)} requires a directed network -
mutual/asymmetric/null dyad types have no meaning for undirected ties, where every dyad is simply
tied or not.

{pstd}
{bf:tail()} controls which p-value(s) are reported: {bf:upper} is the proportion of random draws with
a statistic at least as large as observed (evidence the observed value is unusually {it:high});
{bf:lower} is the proportion at least as small (unusually {it:low}); {bf:both} (the default) reports
both, plus a two-sided p-value ({bf:r(p)}, twice the smaller one-sided p-value, capped at 1).

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes (required for {opt condition(census)}). Weighted: depends entirely on
{bf:stat()} - {cmd:nwcug} itself only draws random comparison networks and calls whatever command
{bf:stat()} names, so it inherits that command's own support. Signed: same as weighted, depends on
{bf:stat()}. Two-mode: no - {help nwrandom}'s density/census conditioning used to draw comparison
networks does not support two-mode networks.

{title:Stored results}

	Scalars
	  {bf:r(obs)}		observed statistic
	  {bf:r(reps)}		number of random draws
	  {bf:r(mean_null)}	mean of the statistic across random draws
	  {bf:r(sd_null)}	standard deviation of the statistic across random draws
	  {bf:r(p_greater)}	proportion of random draws >= observed (upper-tail p-value)
	  {bf:r(p_less)}	proportion of random draws <= observed (lower-tail p-value)
	  {bf:r(p)}		two-sided p-value (2 * min(p_greater, p_less), capped at 1)

{title:References}

{pstd}
Anderson, B.S., Butts, C., Carley, K. (1999). The interaction of size and density with graph-level
indices. {it:Social Networks} 21(3), 239-267.

{title:See also}

	{help nwrandom}, {help nwdyads}, {help nwpermute}, {help nwqap}

***/

capture program drop nwcug
program nwcug, rclass
	version 12
	syntax [anything(name=netname)], STAT(string) RNAME(string) [reps(integer 1000) seed(integer -1) tail(string) condition(string) silent]

	local tail = lower("`tail'")
	if "`tail'" == "" {
		local tail "both"
	}
	_opts_oneof "both upper lower" "tail" "`tail'" 6556

	local condition = lower("`condition'")
	if "`condition'" == "" {
		local condition "density"
	}
	_opts_oneof "density census" "condition" "`condition'" 6556

	if `seed' != -1 {
		set seed `seed'
	}

	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `nw_syntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message.
	unw_defs
	capture nw_syntax `netname'
	if _rc != 0 {
		di "{err}Network {bf:`netname'} not found."
		error `errNWsNotFound'
	}
	local origname "`netname'"

	if "`condition'" == "census" & "`directed'" != "true" {
		di "{err}condition(census) requires a directed network - mutual/asymmetric/null dyad types only exist for directed ties; use condition(density) (the default) for an undirected network."
		error 198
	}

	tempname __nw_dens
	mata: st_numscalar("obsdensity", `netobj'->get_density())
	local obsdensity = obsdensity

	// BUGFIX: a 1-node network has 0 possible dyads, so its own density
	// is undefined (missing) - previously passed straight through to
	// nwrandom's own density() option, which never terminates when
	// asked to hit a missing target density (confirmed directly: hangs
	// indefinitely at 100% CPU, no error, no timeout). Only relevant to
	// the default condition(density) path - condition(census) doesn't
	// use obsdensity at all.
	if "`condition'" != "census" & `nodes' < 2 {
		di "{err}nwcug needs at least 2 nodes for a condition(density) draw (network `origname' has `nodes')."
		error 198
	}

	if "`condition'" == "census" {
		qui nwdyads `origname'
		local obsmutual = r(_100)
		local obsasym = r(_010)
	}

	local obscmd = subinstr("`stat'", "##net##", "`origname'", .)
	qui `obscmd'
	// r(anything-undefined) silently evaluates to missing rather than
	// erroring (confirmed via an isolated repro) - an empty-string check
	// alone does not catch a bad rname(), so check for missing too.
	local obsval = r(`rname')
	if "`obsval'" == "" | "`obsval'" == "." {
		di "{err}stat() did not return a real r(`rname') for network `origname'"
		error 111
	}

	local drawopt "undirected"
	if "`directed'" == "true" {
		local drawopt ""
	}

	mata: nwcug_nullvals = J(`reps', 1, .)
	local base "_nwcug_draw"
	local drawcmd = subinstr("`stat'", "##net##", "`base'", .)
	forvalues i = 1/`reps' {
		capture nwdrop `base'
		if "`condition'" == "census" {
			qui nwrandom `nodes', census(`obsmutual' `obsasym') name(`base')
		}
		else {
			qui nwrandom `nodes', density(`obsdensity') name(`base') `drawopt'
		}
		qui `drawcmd'
		local v = r(`rname')
		mata: nwcug_nullvals[`i'] = `v'
	}
	capture nwdrop `base'

	mata: st_numscalar("meannull", mean(nwcug_nullvals))
	mata: st_numscalar("sdnull", sqrt(variance(nwcug_nullvals)))
	mata: st_numscalar("pgreater", mean(nwcug_nullvals :>= `obsval'))
	mata: st_numscalar("pless", mean(nwcug_nullvals :<= `obsval'))
	mata: mata drop nwcug_nullvals

	local ptwo = min(2*min(pgreater,pless), 1)

	return scalar obs = `obsval'
	return scalar reps = `reps'
	return scalar mean_null = meannull
	return scalar sd_null = sdnull
	return scalar p_greater = pgreater
	return scalar p_less = pless
	return scalar p = `ptwo'

	// Display from the locals/scalars computed above, not from r(), which
	// is only published to the caller once this program exits - a real
	// bug found (and fixed the same way) in nw2project.ado earlier this
	// session: r(x) reads as missing from inside the same program body
	// that just called "return scalar x = ...".
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`origname'"
		di "{txt}  Statistic: {res}`stat'/r(`rname')"
		di "{txt}  Observed: {res}`obsval'"
		di "{txt}  Null mean (sd): {res}`=meannull' (`=sdnull')"
		di "{txt}  Reps: {res}`reps'"
		if "`tail'" == "upper" | "`tail'" == "both" {
			di "{txt}  p (upper tail): {res}`=pgreater'"
		}
		if "`tail'" == "lower" | "`tail'" == "both" {
			di "{txt}  p (lower tail): {res}`=pless'"
		}
		if "`tail'" == "both" {
			di "{txt}  p (two-sided): {res}`ptwo'"
		}
		di "{hline 40}"
	}
end
