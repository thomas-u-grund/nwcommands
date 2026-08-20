/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwaltergen {hline 2} Generate a variable from alter/neighbor attributes}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwaltergen} {it:newvar} {cmd:=} {it:stat}{cmd:(alter.}{it:srcvar}{cmd:)}
[{cmd:,}
{opth net(netname)}
{opt replace}]

{p 8 17 2}
{it:stat} is one of {bf:mean}, {bf:sum}, {bf:min}, {bf:max}, {bf:sd}, {bf:count}.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth net(netname)}}Network to use; default = the current network{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwaltergen} generates a new Stata variable that summarizes, for each node ({it:ego}), a
Stata variable's values among its network neighbors ({it:alters}) - e.g. "the average smoking
status among a person's contacts" ({cmd:mean(alter.smoking)}) or "the number of contacts who
already adopted" ({cmd:count(alter.adopted)}). This is the standard "network exposure" /
alter-aggregation primitive used throughout social influence, diffusion, and peer-effects
research (see e.g. Valente 2005 on exposure models).

{pstd}
{it:srcvar} must already exist in the dataset and be indexed the same way as every other
per-node result in {cmd:nwcommands}: observation {it:i} holds the value for node {it:i}.

{pstd}
For directed networks, {it:alter} means {it:out}-neighbors only - the nodes ego has a tie {it:to}
- since exposure/influence is inherently about tie direction, not just structural adjacency (contrast
this with, e.g., {help nwkcore}, where an undirected structural question uses the union of
in- and out-neighbors instead). For undirected networks the distinction does not arise.

{pstd}
Missing values of {it:srcvar} among a node's alters are dropped before the statistic is computed
(so a node with 3 alters, one of whom has a missing {it:srcvar}, is summarized over the 2
non-missing values) - never silently propagated into the result. A node with zero alters (after
dropping missing values, if applicable) returns missing for {bf:mean}/{bf:min}/{bf:max}/{bf:sd},
and 0 for {bf:sum}/{bf:count}. {bf:sd} additionally requires at least 2 non-missing alter values
(it is undefined for a single value) and returns missing otherwise.

{pstd}
{cmd:nwgen} recognizes the same {cmd:mean(alter.}{it:x}{cmd:)}-style syntax as a shortcut and
dispatches to {cmd:nwaltergen} automatically - {cmd:nwgen exposure = mean(alter.smoking)} and
{cmd:nwaltergen exposure = mean(alter.smoking)} are equivalent.

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwaltergen richavg = mean(alter.wealth)}
	{cmd:. nwgen richavg2 = mean(alter.wealth), replace}


{title:References}

{pstd}
Valente, T.W. (2005). Network models and methods for studying the diffusion of innovations. In
{it:Models and Methods in Social Network Analysis}, Cambridge University Press.

{title:See also}

	{help nwgen}, {help nwneighbor}, {help nwdegree}

***/

capture program drop nwaltergen
program nwaltergen
	version 12

	local 0 = trim("`0'")
	gettoken expr options : 0, parse(",") bind
	if "`options'" != "" {
		local 0 `options'
		syntax [, net(string) replace]
	}
	local expr = subinstr("`expr'", " ", "", .)

	if !regexm("`expr'", "^([A-Za-z_][A-Za-z0-9_]*)=(mean|sum|min|max|sd|count)\(alter\.([A-Za-z_][A-Za-z0-9_]*)\)$") {
		di as err "syntax should be: {it:newvar} = {it:stat}(alter.{it:srcvar}), {it:stat} one of mean|sum|min|max|sd|count"
		error 198
	}
	local newvarname = regexs(1)
	local stat = regexs(2)
	local srcvar = regexs(3)

	confirm variable `srcvar'

	capture confirm new variable `newvarname'
	if _rc & "`replace'" == "" {
		di as err "{err}Variable {bf:`newvarname'} already exists; specify {bf:replace}"
		error 110
	}

	nw_syntax `net'

	if _N < `nodes' {
		di as err "dataset has fewer observations (`=_N') than the network has nodes (`nodes')"
		error 4
	}

	tempname __nw_srcvar __nw_alterstat
	mata: `__nw_srcvar' = st_data(1::`nodes', "`srcvar'")
	mata: `__nw_alterstat' = `netobj'->calculate_alterstat(`__nw_srcvar', "`stat'")

	capture drop `newvarname'
	qui gen `newvarname' = .
	mata: st_store((1::`nodes'), "`newvarname'", `__nw_alterstat')
	mata: mata drop `__nw_srcvar' `__nw_alterstat'

	label variable `newvarname' "`stat' of alter.`srcvar'"
end
