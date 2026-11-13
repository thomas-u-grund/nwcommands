{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwbetween  {hline 2}}Betweenness centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwbetween}
[{it:{help netlist}}]
[{cmd:,}
{opt generate}({it:{help newvarlist}})
{opt replace}
{opt nosym}
{opt standardize}
{opt silent}
{opt weighted}
{opt alpha(real)}
{opt force}
{opt binary}
{opt twomode}
{opt onemode}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help newvarlist}})}{bf:Required.} Variable name for betweenness centrality{p_end}
{synopt:{opt replace}}allow overwriting an existing variable of the same name{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation of shortest paths{p_end}
{synopt:{opt standardize}}standardize centrality scores{p_end}
{synopt:{opt silent}}suppress the summary table of the generated variable{p_end}
{synopt:{opt weighted}}use the tie values in the shortest paths; redundant on a valued network, where this is the default (kept for compatibility){p_end}
{synopt:{opt alpha(real)}}weight-to-distance exponent used with {opt weighted}; default = 1{p_end}
{synopt:{opt force}}Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise){p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt twomode}}Two-mode network: the default; accepted as a synonym of the default (betweenness divided by the largest value a node of its mode can reach, Borgatti and Everett 1997;
{opt standardize} is this standardisation on a two-mode network){p_end}
{synopt:{opt onemode}}Two-mode network: the betweenness of the bipartite graph read as a one-mode graph, not divided by the largest possible value ({opt standardize} then divides as for any
graph){p_end}


{title:Description}

{pstd}
Calculates the betweenness centrality for each node {it:i} in a {help netname:network} or {help netlist:network list} and
saves the result as a Stata variable. On an unvalued network every tie counts as one step. On a valued
network the command by default computes weighted betweenness on Dijkstra shortest paths ({opt binary}
ignores the tie values instead), using {opt alpha()} to control the weight-to-distance conversion. This follows Opsahl, Agneessens and Skvoretz (2010) - the same
generalization {help nwgeodesic}'s own {opt alpha()} already implements for weighted distances - where
edge cost is {it:(1/weight)^alpha}: a STRONGER tie is a SHORTER effective distance, not a longer one.
{opt alpha(1)}, the default, uses the reciprocal of the raw tie weight directly as distance/cost;
{opt alpha(0)} reduces to the unweighted case (every positive tie costs exactly 1, ignoring its
strength). See the References section below for the full citation.

{pstd}
The betweenness centrality for node {it:i} is equal to the number of shortest paths from all vertices to all 
others that pass through node {it:i}. A node with high betweenness centrality has a large influence on the 
transfer of items through the network, under the assumption that item transfer follows the shortest paths. 

{pstd}
When there is more than one shortest path from node {it:k} to node {it:l}, the betweenness scores of all nodes {it:i}
on these paths increases proportionally.  

{pstd}
Formally, betweenness centrality of node {it:i} on graph {it:g} is defined as:

{pmore}
{it:Between_i(g) = sum ( sigma_st(i) / sigma_st )}

{pstd}
where, {it:sigma_st} is the total number of shortest paths from node {it:s} to node {it:t} and {it:sigma_st(i)} is the number of those 
paths that pass through node {it:i}.

{pstd}
For the standardized betweenness centrality:

{pmore}
Directed network: {it:Between_i_std(g) = Between_i(g) / ((N-1)*(N-2))}

{pmore}
Undirected network: {it:Between_i_std(g) = Between_i(g) / ((N-1)*(N-2)/2)}

{pstd}
The stored result {bf:r(bw_central)} is Freeman's betweenness centralization, computed from the raw scores whether or not {opt standardize} is given: sum(max - Between_i) / ((N-1)^2*(N-2)) for a
directed network (raw scores count ordered pairs) and sum(max - Between_i) / ((N-1)^2*(N-2)/2) for an undirected network (raw scores count unordered pairs). It equals 1 for a star and agrees with R's
sna::centralization(, betweenness). Without {opt nosym} the network is symmetrized first, so the undirected formula applies.

{pstd}
{opt generate()} is required and names the Stata variable to hold the result (pass {opt replace}
to allow overwriting an existing variable of that name). When betweenness centrality is calculated
for more than one network at the same time (e.g. {bf:nwbetween glasgow1 glasgow2, generate(bw)}), the command
generates one variable per network, named {it:varname_netname} (e.g. {it:bw_glasgow1},
{it:bw_glasgow2}).


{title:Performance}

{pstd}
The default (unweighted) mode of {cmd:nwbetween} transparently uses a compiled native (C)
implementation of the same algorithm when one is available for the current platform (currently:
macOS), falling back to an identical, fully-supported Mata implementation everywhere else -
there is nothing to configure and no difference in the result, only in how fast it is computed
(a native run at 10,000 nodes was measured faster than the Mata implementation at
just 1,000). The weighted mode (valued networks) has its own native kernel (Dijkstra's search inside Brandes' algorithm) with the same
result as the Mata routine: 1,000 nodes with 3,000 valued ties take 0.13 seconds (Mata: 111 seconds), 10,000 nodes 15 seconds; the Mata routine
needs a dense work space of n x n cells for every node and is not usable above a few hundred nodes.


{title:Network types}

{pstd}
{bf:Directed:} symmetrized by default; {opt nosym} computes directed betweenness. {bf:Valued:} used by default (paths of
least cost 1/w^alpha, {opt alpha(1)} by default); {opt binary} counts steps; {opt weighted} is redundant. {bf:Two-mode:}
two-mode form by default (option {opt onemode} for the one-mode computation). {bf:Signed:} ties of value zero or less,
including negative ties, count as absent. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Betweenness needs one shortest-path search from every node, so the time grows with the number of nodes times the number of ties. Measured in Stata/BE on a random directed network with 10 ties per
node: 10,000 nodes 7.6 seconds, 20,000 nodes 29 seconds, 100,000 nodes about 15 minutes (estimated). When the estimated time is more than 2 minutes (about 36,000 nodes with 10 ties per node) the
command stops at once with r(484) and a message; option {opt force} runs it anyway.


{title:Examples}

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwbetween gang, generate(_between)}
	{cmd:. sum _between}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(bw_central)}}Freeman's betweenness centralization (of the last network in a {help netlist}){p_end}
{p2colreset}{...}


{title:References}

{pstd}
Brandes, U. (2001). A faster algorithm for betweenness centrality. {it:Journal of Mathematical Sociology} 25, 163-177.

{pstd}
Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks:
Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.


{title:See also}

{p 4 4 2}{help nwpath}, {help nwgeodesic}, {help nwcloseness}, {help nwkatz}, {help nwdegree}, {help nwcloseness}, {help nwevcent}{p_end}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
