{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nw2clustering {hline 2}}Clustering coefficient (transitivity) of a two-mode network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nw2clustering}
[{it:{help netname}}]
[{cmd:,}
{opt measure(string)}
{opth level(int)}
{opth generate(newvarname)}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt measure(binary|arithmetic|geometric|maximum|minimum)}}How to combine a 4-path's own
four tie values; {it:binary} dichotomizes every tie to presence/absence first;
{it:arithmetic}/{it:geometric}/{it:maximum}/{it:minimum} combine the four raw tie values via that
function; default = {it:arithmetic} for a valued network, {it:binary} otherwise{p_end}
{synopt:{opth level(int)}}Which mode (1 or 2) to compute clustering scores for; default = 1{p_end}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each {opt level()}-mode
node's own clustering coefficient{p_end}
{synopt:{opt replace}}Overwrite an existing {opth generate(newvarname)} variable; required if it already exists{p_end}
{synopt:{opt ra}}The global clustering coefficient of Robins and Alexander (2004), 4 C4 / L3 (C4 the number of four-cycles, L3 the number of paths of length three) of the binary network; {opt generate()} is then optional; results in {cmd:r(ra)}, {cmd:r(C4)}, {cmd:r(L3)}{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nw2clustering} calculates the two-mode (bipartite) analogue of the ordinary clustering
coefficient (see {help nwclustering}) using the 4-path / 6-cycle definition of Opsahl (2013) and
Robins & Alexander (2004): an ordinary triangle cannot exist in a two-mode network (a tie only ever
connects the two different modes), so "closure" is instead measured on paths of length 4 - two
{opt level()}-mode nodes connected via two distinct intermediate opposite-mode alters - and a path is
{it:closed} when its two ends are ALSO both tied to some further common alter, forming a 6-cycle.
This deliberately excludes shorter 4-cycles (reusing one of the same two alters) as a form of closure,
matching the cited reference's own distinction between mere shared-affiliation redundancy and genuine
triadic-style closure.

{pstd}
Only nodes of the requested {opt level()} receive a value; nodes of the other mode are left missing.
A node with too few alters, or whose own connected component has fewer than 3 same-mode nodes, has no
possible 4-path and its own coefficient is reported missing (not spuriously 0).

{pstd}
{help nwclustering} automatically switches to this command whenever it is called on a two-mode network,
forwarding {opt measure()} and {opt generate()} (always at the default {opt level(1)} in that case) -
call {cmd:nw2clustering} directly to choose {opt level(2)} or a non-default {opt measure()}.

{title:Two-mode networks}

{pstd}
Two-mode: yes - the clustering coefficient of Opsahl (2013), four-paths closed by a fifth tie (as {cmd:tnet::clustering_tm}); {opt ra} adds the global coefficient of Robins and Alexander (2004), 4 C4 / L3.

{title:Supported network types}

{pstd}
Binary: yes (the default {opt measure(binary)} case). Directed: not checked - a two-mode network's
ties are treated as undirected. Weighted: yes, via {opt measure(arithmetic|geometric|maximum|minimum)}, each combining the 4-path's own four tie values before testing closure. Signed: not
checked; negative tie values are not validated or rejected. Two-mode: yes - the clustering coefficient of Opsahl (2013), four-paths closed by a fifth tie (as {cmd:tnet::clustering_tm}); {opt ra} adds the global coefficient of Robins and Alexander (2004), 4 C4 / L3.

{title:Limits}

{pstd}
The 4-paths around each node are enumerated in compiled code and the closing 6-cycle is tested with a marker array
instead of a copy of the neighbour list per path; the sums are accumulated in the same order as before, so results
agree with the previous implementation exactly (up to the last bit of the geometric mean). The work grows with, for
each node, the square of its number of alters times the squares of their numbers of other egos. Measured in Stata/BE on a
random two-mode network with N mode-1 nodes, N/2 mode-2 nodes and 10 ties drawn per mode-1 node: N = 300 / 1,000 /
5,000 take 0.09 / 0.25 / 1.4 seconds (before: 58 seconds at 300, more than 60 seconds at 1,000). Memory is
proportional to the number of ties.

{title:Stored results}

	Scalars
	  {bf:r(C_avg)}		mean of the per-node clustering coefficients (the requested {opt level()} only)
	  {bf:r(C_global)}	network-level global clustering coefficient (ratio of total closed to total
	                        potential 4-paths)

	Macros
	  {bf:r(measure)}		the {opt measure()} actually used

{title:Examples}

	{cmd:. nwset ego alter, twomode name(bip)}
	{cmd:. nw2clustering bip, generate(_clustering2_lev1)}
	{cmd:. sum _clustering2_lev1}

{title:References}

{pstd}
Opsahl, T. (2013). Triadic closure in two-mode networks: Redefining the global and local clustering
coefficients. {it:Social Networks} 35(2), 159-167.

{pstd}
Robins, G., Alexander, M. (2004). Small worlds among interlocking directors: Network structure and
distance in bipartite graphs. {it:Computational & Mathematical Organization Theory} 10(1), 69-94.

{title:See also}

	{help nwclustering}, {help nw2project}, {help nw2degree}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.5.0, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
