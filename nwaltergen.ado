/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwaltergen {hline 2}}Generate a variable from alter/neighbor attributes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwaltergen} {it:newvar} {cmd:=} {it:stat}{cmd:(alter.}{it:srcvar}{cmd:)}
[{cmd:,}
{opth net(netname)}
{opt replace}
{opth hop(int)}]

{p 8 17 2}
{cmd:nwaltergen} {it:newvar} {cmd:= proportion(alter.}{it:srcvar}{cmd:}{it:{help nwaltergen##propop:op}}{it:value}{cmd:)}
[{cmd:,}
{opth net(netname)}
{opt replace}
{opth hop(int)}]

{p 8 17 2}
{it:stat} is one of {bf:mean}, {bf:sum}, {bf:min}, {bf:max}, {bf:sd}, {bf:count}, {bf:diversity}.

{marker propop}{...}
{p 8 17 2}
{it:op} is {bf:==} or {bf:!=}; {it:value} must be numeric.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth net(netname)}}Network to use; default = the current network{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth hop(int)}}Aggregate over nodes exactly this many (unweighted) steps away, instead of direct neighbors; default = 1{p_end}

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
dropping missing values, if applicable) returns missing for {bf:mean}/{bf:min}/{bf:max}/{bf:sd}/
{bf:diversity}, and 0 for {bf:sum}/{bf:count}. {bf:sd} additionally requires at least 2 non-missing
alter values (it is undefined for a single value) and returns missing otherwise.

{pstd}
{bf:proportion(alter.}{it:srcvar}{bf:==}{it:value}{bf:)} (or {bf:!=}) gives the proportion of
ego's alters whose {it:srcvar} equals (or does not equal) a specific numeric category - e.g. "the
proportion of a person's contacts who work in sector 3" ({cmd:proportion(alter.sector==3)}). For an
already-binary (0/1) {it:srcvar}, {cmd:mean(alter.}{it:srcvar}{cmd:)} already gives exactly "the
proportion with {it:srcvar}==1", so a bare {cmd:proportion(alter.}{it:srcvar}{cmd:)} with no
comparison is not offered as a separate synonym for it - {bf:proportion()}'s own value is for
picking out one category of a variable with more than two categories, without first having to
{cmd:generate} a 0/1 indicator by hand. Missing {it:srcvar} values are still dropped before the
proportion is computed, exactly as for every other {it:stat} - a missing value is never silently
read as "not in this category".

{pstd}
{bf:diversity(alter.}{it:srcvar}{bf:)} gives Blau's (1977) index of heterogeneity among ego's
alters' {it:srcvar} values - {bf:1 - sum(p_k^2)}, where {it:p_k} is the proportion of alters
falling in category {it:k} of {it:srcvar} (treated as a categorical/discrete-coded variable, e.g.
sector or ethnicity) - the standard "ego-network composition" measure: 0 when every alter shares
the same category (no diversity), approaching 1 as alters spread evenly across many categories.
This is the composition/diversity capability {help nwego}'s own "Supported network types" note
originally left open - unlike ego-network size/density, it needs per-alter attribute {it:values},
not just structural connectivity, so it belongs here alongside {help nwaltergen}'s other alter-
attribute aggregations rather than in {help nwego} itself. Missing {it:srcvar} values are dropped
before computing the index, exactly as for every other {it:stat}; an ego with zero alters (after
dropping missing values) returns missing, not spuriously 0 (mirroring {bf:mean}/{bf:min}/{bf:max}/
{bf:sd}'s own convention, not {bf:sum}/{bf:count}'s - diversity, like a mean, is undefined with no
data to summarize, not naturally zero).

{pstd}
{opth hop(int)} aggregates over nodes exactly that many (unweighted) steps away instead of direct
(one-hop) neighbors - e.g. {cmd:mean(alter.smoking), hop(2)} is "the average smoking status among
the contacts of a person's contacts" (excluding the person's own direct contacts, unless a network
happens to reach them again by a different, exactly-2-step path). This is the standard multi-hop /
lagged exposure question in diffusion research: does influence propagate beyond a node's immediate
neighborhood? A node with no alters at exactly the requested hop distance (including one smaller
than the network's diameter from it, or simply unreachable) is treated the same as a node with no
direct alters: missing for {bf:mean}/{bf:min}/{bf:max}/{bf:sd}, 0 for {bf:sum}/{bf:count}. For a
directed network, distance follows tie direction (out-going steps), matching {it:alter}'s own
one-hop convention above; {opth hop(int)} works with {bf:proportion()} too.

{pstd}
{cmd:nwgen} recognizes the same {cmd:mean(alter.}{it:x}{cmd:)}-style syntax (including
{cmd:proportion(alter.}{it:x}{cmd:==}{it:value}{cmd:)} and {opth hop(int)}) as a shortcut and
dispatches to {cmd:nwaltergen} automatically - {cmd:nwgen exposure = mean(alter.smoking)} and
{cmd:nwaltergen exposure = mean(alter.smoking)} are equivalent.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - {it:alter} means out-neighbors only, since exposure/influence follows
tie direction (see above). Weighted: no - only structural adjacency (and, with {opt hop()},
unweighted step distance) determines who counts as an alter; tie strength itself does not enter any
statistic. Signed: not checked. Two-mode: no - {it:srcvar} is read per node under the one-mode
{it:_nwnode} indexing convention, with no mode-specific handling.

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwaltergen richavg = mean(alter.wealth)}
	{cmd:. nwgen richavg2 = mean(alter.wealth), replace}
	{cmd:. nwaltergen priorsector = proportion(alter.sector==3)}
	{cmd:. nwaltergen richavg2hop = mean(alter.wealth), hop(2)}
	{cmd:. nwaltergen sectordiv = diversity(alter.sector)}


{title:References}

{pstd}
Valente, T.W. (2005). Network models and methods for studying the diffusion of innovations. In
{it:Models and Methods in Social Network Analysis}, Cambridge University Press.

{pstd}
Blau, P.M. (1977). {it:Inequality and Heterogeneity: A Primitive Theory of Social Structure}. Free
Press. ({bf:diversity()}'s own index of heterogeneity)

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
		syntax [, net(string) replace hop(int 1)]
	}
	if "`hop'" == "" {
		local hop = 1
	}
	if `hop' < 1 {
		di as err "{err}hop() must be a positive integer."
		error 198
	}
	local expr = subinstr("`expr'", " ", "", .)

	// proportion(alter.srcvar==value) / proportion(alter.srcvar!=value):
	// the proportion of ego's alters whose srcvar equals (or does not
	// equal) a specific category - the genuinely new capability;
	// mean(alter.x) already covers "proportion with x==1" for an
	// already-binary x, so a bare proportion(alter.x) (no comparison)
	// is deliberately not offered as a separate synonym for mean() -
	// one unambiguous way to ask for it. Only a numeric comparison
	// value is supported (the common case: an integer-coded category) -
	// checked explicitly with confirm number below rather than left to
	// fail confusingly deep inside the Mata call. Implemented by
	// building the 0/1 comparison indicator in Stata first, then
	// reusing calculate_alterstat()'s existing, already-certified
	// mean path on it - no unw_core.do changes needed at all.
	local isproportion = 0
	if regexm("`expr'", "^([A-Za-z_][A-Za-z0-9_]*)=proportion\(alter\.([A-Za-z_][A-Za-z0-9_]*)(==|!=)(.+)\)$") {
		local isproportion = 1
		local newvarname = regexs(1)
		local srcvar = regexs(2)
		local propop = regexs(3)
		local propval = regexs(4)
		local stat = "mean"

		// Mata's bare == / != test whole-matrix identity (one scalar),
		// not an elementwise comparison - the elementwise operators are
		// :== / :!= . Confirmed directly: a first attempt using the
		// bare operator silently collapsed the comparison to a single
		// scalar 0/1 instead of a per-alter vector, caught only by a
		// downstream conformability error, not by any warning at the
		// point of the mistake itself.
		local matapropop = cond("`propop'" == "==", ":==", ":!=")

		capture confirm number `propval'
		if _rc {
			di as err "{err}proportion()'s comparison value must be numeric; got {bf:`propval'}."
			error 198
		}
	}
	else if !regexm("`expr'", "^([A-Za-z_][A-Za-z0-9_]*)=(mean|sum|min|max|sd|count|diversity)\(alter\.([A-Za-z_][A-Za-z0-9_]*)\)$") {
		di as err "syntax should be: {it:newvar} = {it:stat}(alter.{it:srcvar}), {it:stat} one of mean|sum|min|max|sd|count|diversity|proportion(alter.srcvar==value)"
		error 198
	}
	else {
		local newvarname = regexs(1)
		local stat = regexs(2)
		local srcvar = regexs(3)
	}

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
	if `isproportion' {
		// preserves missingness through the comparison rather than
		// letting a missing srcvar silently read as "not in category"
		// (Mata's :== treats missing as an ordinary comparable value,
		// not as "unknown" - a missing alter must still be *excluded*
		// by calculate_alterstat()'s own downstream missing-dropping
		// logic, exactly as it already is for every other stat).
		mata: `__nw_srcvar' = (`__nw_srcvar' `matapropop' `propval')
		mata: `__nw_srcvar'[selectindex(st_data(1::`nodes',"`srcvar'"):==.)] = J(sum(st_data(1::`nodes',"`srcvar'"):==.), 1, .)
	}
	if `hop' == 1 {
		mata: `__nw_alterstat' = `netobj'->calculate_alterstat(`__nw_srcvar', "`stat'")
	}
	else {
		// hop(k>1): aggregate over nodes at exactly k (unweighted)
		// steps away instead of direct neighbors - see
		// calculate_alterstat_hop()'s own header comment in
		// unw_core.do. hop(1) deliberately still calls
		// calculate_alterstat() directly above rather than
		// calculate_alterstat_hop(...,1) - confirmed the two give
		// bit-identical results, but keeping the well-established,
		// unmodified 1-hop code path as the default minimizes any
		// risk of this option regressing existing behavior.
		mata: `__nw_alterstat' = `netobj'->calculate_alterstat_hop(`__nw_srcvar', "`stat'", `hop')
	}

	capture drop `newvarname'
	qui gen `newvarname' = .
	mata: st_store((1::`nodes'), "`newvarname'", `__nw_alterstat')
	mata: mata drop `__nw_srcvar' `__nw_alterstat'

	local hopsuffix ""
	if `hop' > 1 {
		local hopsuffix " (hop `hop')"
	}
	if `isproportion' {
		label variable `newvarname' "proportion of alter.`srcvar' `propop' `propval'`hopsuffix'"
	}
	else {
		label variable `newvarname' "`stat' of alter.`srcvar'`hopsuffix'"
	}

	// _rc is left stale (111, "variable not found") from the earlier
	// "capture drop `newvarname'" line above - a plain, expected no-op
	// on a variable that doesn't exist yet, but quietly-prefixed and
	// inherently silent commands (confirm, mata:, local, label
	// variable) do NOT refresh _rc even when they succeed (see
	// nwbrokerage.ado's own header comment for the full explanation and
	// how this was first found) - reset explicitly and silently here so
	// a caller checking _rc right after this command sees this
	// command's own actual outcome. Pre-existing in this file even for
	// the original mean/sum/... path, not introduced by proportion() -
	// fixed for both while already here.
	capture confirm variable `newvarname', exact
end
