/***
{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwclustering {hline 2}}Clustering coefficient (transitivity) of a network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwclustering}
[{it:{help netname}}]
[{cmd:,}
{opt measure(string)}
{opt SYMmetrize}
{opth generate(newvarname)}
{opt replace}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt measure(binary|arithmetic|geometric|maximum|minimum)}}How to combine the two tie
values in a potential triple for a weighted network; {it:binary} ignores tie values and only checks
presence/absence; {it:arithmetic}/{it:geometric}/{it:maximum}/{it:minimum} combine the two tie
values via that function; default = {it:arithmetic} for a valued undirected network, {it:binary}
otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before calculating (required for any
weighted {opt measure()} on a directed network - see Supported network types below){p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's own
clustering coefficient; default = {it:_clustering}{p_end}
{synopt:{opt replace}}Overwrite an existing {opth generate(newvarname)} variable; required if it already exists{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwclustering} calculates the clustering coefficient (also known as transitivity) of a
network: for each node {it:i}, the proportion of {it:i}'s own potential triples - pairs of {it:i}'s
neighbors - that are themselves actually tied to each other ("the friends of my friends are
themselves friends"). A node with fewer than 2 neighbors has no potential triples and its own
clustering coefficient is reported as missing.

{pstd}
{cmd:nwclustering} generates a new variable (default {it:_clustering}) holding each node's own
clustering coefficient, and returns both the network-level average ({bf:r(cluster_avg)}, the mean
of the per-node values) and the network-level global clustering coefficient ({bf:r(cluster_global)},
the ratio of the total count of closed triples to the total count of potential triples across the
whole network - not the same quantity as the average of per-node ratios, since it weights every
potential triple equally rather than every node equally).

{pstd}
If the network is a two-mode (bipartite) network, {cmd:nwclustering} automatically switches to
{help nw2clustering} instead (an ordinary clustering coefficient is not meaningful on a bipartite
network's own inherently triangle-free structure), forwarding {opt measure()} and {opt generate()}.

{title:Supported network types}

{pstd}
Binary: yes (the default {opt measure(binary)} case). Directed: yes for {opt measure(binary)}
(each node's own potential triples are formed from one in-neighbor paired with one out-neighbor,
matching the directed two-path a -> i -> b convention used elsewhere in this package); a weighted
{opt measure()} is not defined for a directed network - either choose {opt measure(binary)} or
{opt symmetrize} the network first. Weighted: yes, via {opt measure(arithmetic|geometric|maximum|
minimum)}, each combining the two tie values of a potential triple's own pair of ties before testing
closure; undirected networks only (see above). Signed: not checked; negative tie values are not
validated or rejected. Two-mode: automatically delegated to {help nw2clustering} (see Description).

{title:Stored results}

	Scalars
	  {bf:r(cluster_avg)}		mean of the per-node clustering coefficients
	  {bf:r(cluster_global)}	network-level global clustering coefficient

	Macros
	  {bf:r(measure)}		the {opt measure()} actually used
	  {bf:r(symmetrized)}		{it:false}, only returned when {opt symmetrize} was specified

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwclustering flomarriage}
	{cmd:. sum _clustering}

{title:References}

{pstd}
Watts, D.J., Strogatz, S.H. (1998). Collective dynamics of 'small-world' networks. {it:Nature}
393, 440-442.

{title:See also}

	{help nw2clustering}, {help nwtriads}, {help nwbrokerage}

***/
capture program drop nwclustering
program nwclustering
	version 9
	syntax [anything(name=netname)][, measure(string) SYMmetrize GENerate(string) replace silent]
	set more off

	unw_defs

	nw_syntax `netname', max(1)
	nw_datasync `netname'
	local original "`netname'"

	tempname symnet
	local symnet_created = 0
	if "`symmetrize'" != ""  {
		nwsym `netname', generate(`symnet') mode(max)
		nw_syntax
		local symnet_created = 1
	}

	// Auto-detect from the network's own stored valued/unvalued state
	// rather than always defaulting to "binary" regardless - matching
	// the netmeasure auto-detection convention already established in
	// nwcommunity.ado/nwconcor.ado/nwcoreperiphery.ado/nwmodularity.ado/
	// nwspectral.ado. Previously, a valued network would silently get
	// dichotomized (measure(binary)) unless the caller explicitly asked
	// for a weighted formula - not wrong exactly (binary is a
	// legitimate, still-available choice), but surprising: the same
	// network's clustering coefficient would otherwise ignore tie
	// strength entirely by default with no indication anything was
	// being discarded.
	// A weighted measure is only meaningful for an undirected network
	// (see the "not defined for networks that are both weighted and
	// directed" guard just below) - auto-defaulting to "arithmetic" for
	// a directed+valued network would turn a previously-working call
	// (silently dichotomized, matching the pre-existing default) into
	// a hard error by default, which is a regression, not a fix.
	if "`measure'" == "" {
		if "`valued'" == "true" & "`directed'" != "true" {
			local measure "arithmetic"
		}
		else {
			local measure "binary"
		}
	}

	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "`measure'" 6556

	if "`is2mode'" == "true" {
		di "{err}{pstd}Network is a two-mode network. Automatically, switched to command {bf:nw2clustering}."
		nw2clustering `netname', measure(`measure') generate(`generate')
		exit
	}

	if ("`directed'" == "true" & "`measure'" != "binary") {
		di "{err}{pstd}Clustering coefficient not defined for networks that are both weighted and directed."
		di "{err}Either choose {bf:measure(binary)} or symmetrize the network."
		// BUGFIX: was a bare `exit' (no error code), so _rc reported 0
		// (success) even though the printed message says the command
		// failed and no generate() variable was ever created - a
		// silent-success bug that would fool any caller checking _rc.
		exit 198
	}

	if "`generate'" == "" {
		local generate = "_clustering"
	}

	// Consistency (moderate-severity pass, positions_equivalence group):
	// every sibling command with a generate() option (nwconcor/
	// nwcoreperiphery/nwburt/nwbrokerage) already requires an explicit
	// replace before overwriting an existing variable; nwclustering had
	// no such guard at all and silently clobbered any pre-existing
	// variable of the target name.
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}
	capture drop `generate'
	qui gen `generate' = .

	nw_syntax `netname'
	nw_datasync `netname'

	// PERFORMANCE FIX (this unit): this command used to implement its own
	// independent Stata-level pipeline here - nwtoedge, three separate
	// reshape wide/long round-trips, and two merge m:m string-keyed joins -
	// to enumerate every length-2 path in the graph via dataset operations.
	// calculate_clustering() in unw_core.do already implements the exact
	// same computation natively in Mata using sparse neighbor enumeration
	// (has_edge()/edge_weight(), no dense N-by-N matrix), but nothing ever
	// called it - confirmed empirically that this reshape/merge pipeline
	// took 459 SECONDS on a 10,000-node network (docs/PERFORMANCE_
	// BENCHMARKS.md), against a small fraction of a second for the Mata
	// equivalent. Mode order below matches calculate_clustering()'s own
	// documented convention exactly (0=binary/unvalued union-of-neighbors,
	// 1=arithmetic, 2=geometric, 3=maximum, 4=minimum).
	if "`measure'" == "binary" local __mode 0
	else if "`measure'" == "arithmetic" local __mode 1
	else if "`measure'" == "geometric" local __mode 2
	else if "`measure'" == "maximum" local __mode 3
	else local __mode 4

	qui if _N < `nodes' {
		set obs `nodes'
	}
	nw_syntax `netname'

	tempname __nw_clust
	mata: `__nw_clust' = `netobj'->calculate_clustering(`__mode')
	mata: st_store((1::`nodes'), "`generate'", `__nw_clust'[.,1])
	mata: st_numscalar("clust_global", sum(`__nw_clust'[.,2]) / sum(`__nw_clust'[.,3]))
	mata: mata drop `__nw_clust'

	local cluster_global = clust_global
	capture scalar drop clust_global

	qui summarize `generate'
	local C_avg = r(mean)

	mata: st_rclear()
	mata: st_numscalar("r(cluster_global)", `cluster_global')
	mata: st_global("r(measure)", "`measure'")
	mata: st_numscalar("r(cluster_avg)", `C_avg')

	if "`symmetrize'" != "" {
		local netname "`original'"
	}

	// Consistency: nwconcor/nwcoreperiphery/nwburt/nwbrokerage/nwsimindex
	// all already offer `silent' to suppress this same display block;
	// nwclustering had no such option at all.
	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname'"
		if "`symmetrize'" != "" {
			noi di "{txt}  Symmetrized: {res}true"
		}
		noi di "{hline 40}"
		noi di "{txt}    Measure: {res}`measure'"
		noi di "{txt}    Average clustering coefficient: {res}`=round(`r(cluster_avg)',0.001)'"
		noi di "{txt}    Global clustering coefficient: {res}`=round(`r(cluster_global)',0.001)'"
		noi di " "
	}
	if "`symmetrize'" != "" {
		mata: st_global("r(symmetrized)", "false")
	}
	_return hold rcluster
	// BUGFIX: `symnet' is only ever actually created (tempname just
	// reserves a name, it doesn't create anything) when `symmetrize' was
	// given - the overwhelming common case (a plain "nwclustering
	// netname, generate(x)" call, no symmetrize) never creates it at
	// all, so this "capture nwdrop `symnet'" legitimately failed
	// ("network not found") on every single ordinary call. `capture'
	// swallows the failure, but "_return restore" (a low-level command
	// for restoring held r()-class results, not an ordinary Stata
	// command) does not itself reset `_rc' the way a normal successful
	// command would - so the stale nonzero `_rc' from the failed nwdrop
	// silently leaked out as this command's own return code on every
	// plain call. Confirmed directly: "nwclustering mynet, generate(x)"
	// on an already-undirected network returned _rc==482 despite
	// completing correctly and printing its own results - the exact
	// same bug class (a `capture'd cleanup on a conditionally-created
	// temp object, nothing afterward resetting `_rc') already found and
	// fixed repeatedly elsewhere this session. Fixed by only attempting
	// the drop when `symnet' was actually created, guarded by the same
	// condition that created it - not just wrapping it more, since that
	// would still print the correct results while returning a
	// misleading nonzero code to any caller that checks `_rc'.
	if `symnet_created' {
		capture nwdrop `symnet'
	}
	_return restore rcluster
end

