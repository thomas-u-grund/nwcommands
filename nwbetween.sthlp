{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwbetween  {hline 2}}Calculate betweenness centrality{p_end}
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
{opt binary}]

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
{synopt:{opt twomode}}Two-mode network: betweenness divided by the largest value a node of its mode can reach (Borgatti and Everett 1997){p_end}


{title:Description}

{pstd}
Calculates the betweenness centrality for each node {it:i} in a {help netname:network} or {help netlist:network list} and
saves the result as a Stata variable. By default the command uses the dichotomized network (any tie
with weight > 0 counts as an edge, tie strength ignored); pass {opt weighted} to compute genuinely
weighted betweenness on Dijkstra shortest paths instead, using {opt alpha()} to control the
weight-to-distance conversion. This follows Opsahl, Agneessens and Skvoretz (2010) - the same
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
where, {it:sigma_st} is the total number of shortest paths from node {it:s} to node {it:t} and {sigma_st(i)} is the number of those 
paths that pass through node {i}.

{pstd}
For the standardized betweenness centrality:

{pmore}
Directed network: {it:Between_i_std(g) = Between_i(g) / ((N-1)*(N-2))}

{pmore}
Undirected network: {it:Between_i_std(g) = Between_i(g) / ((N-1)*(N-2)/2)}

{pstd}
The stored result {bf:r(bw_central)} is Freeman's betweenness centralization, computed from the raw scores whether or not {opt standardize} is given: sum(max - Between_i) / ((N-1)^2*(N-2)) for a directed network (raw scores count ordered pairs) and sum(max - Between_i) / ((N-1)^2*(N-2)/2) for an undirected network (raw scores count unordered pairs). It equals 1 for a star and agrees with R's sna::centralization(, betweenness). Without {opt nosym} the network is symmetrized first, so the undirected formula applies. Before the correction of this formula the value stored for an undirected network was half of Freeman's.

{pstd}
{opt generate()} is required and names the Stata variable to hold the result (pass {opt replace}
to allow overwriting an existing variable of that name). When betweenness centrality is calculated
for more than one network at the same time (e.g. {bf:nwbetween glasgow1 glasgow2, generate(bw)}), the command
generates one variable per network, named {it:varname_netname} (e.g. {it:bw_glasgow1},
{it:bw_glasgow2}).


{title:Examples}

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwbetween gang, generate(_between)}
	{cmd:. sum _between}


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


{title:Valued networks}

{pstd}
A network is valued when it was created with tie values ({help nwfromedge} with a value variable, an import or a matrix with values, {cmd:nwset, valued}); the flag is shown by {help nwsummarize} and explained in {help nwnetworktypes}. On a valued network the shortest paths are those of least cost 1/w^alpha ({cmd:alpha(1)} by default; {it:igraph::betweenness} with weights 1/w, {it:tnet::betweenness_w}); paths of equal cost are recognised with a relative tolerance of 1e-10. {opt binary} counts steps. The option {opt weighted} is accepted for compatibility; it is redundant on a valued network.
On a network that is not valued the result is the same as in earlier releases and {opt binary} has no effect.

{title:Two-mode networks}

{pstd}
Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); the option {opt twomode} divides by the largest betweenness a node of its mode can reach in a two-mode network (Borgatti and Everett 1997).

{title:Supported network types}

{pstd}
Binary: yes, native. Directed: yes for the standardization normalizer (see the formulas above), but
by default the network is symmetrized before computing betweenness at all - pass {opt nosym} to
compute genuinely directed betweenness on the network as given; without {opt nosym} the reported
scores reflect the symmetrized structure, not the original directed one (this applies identically
whether or not {opt weighted} is used - symmetrization, via {help nwsym}'s default {cmd:max} mode,
correctly combines rather than discards tie weights). Weighted: {bf:W2} - the default remains
{bf:W3} (explicit binary-only: any tie with weight strictly greater than zero is dichotomized to an
edge, tie strength otherwise ignored), but {opt weighted} now computes genuine Dijkstra-based
betweenness using tie strength directly as distance/cost via {opt alpha()} - never silently
implied, always an explicit opt-in. Signed: ties with weight less than or equal to zero, including
negative ties, are treated as no tie at all in both the default and {opt weighted} cases - a
negative (e.g. antagonistic) tie is not distinguished from an absent one, and {opt weighted}'s
{it:weight^alpha} cost is undefined for a negative base in general, so signed networks are not
natively supported by either mode. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); the option {opt twomode} divides by the largest betweenness a node of its mode can reach in a two-mode network (Borgatti and Everett 1997).


{title:References}

{pstd}
Brandes, U. (2001). A faster algorithm for betweenness centrality. {it:Journal of Mathematical Sociology} 25, 163-177.

{pstd}
Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks:
Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.


{title:Limits}

{pstd}
Betweenness needs one shortest-path search from every node, so the time grows with the number of nodes times the number of ties. Measured in Stata/BE on a random directed network with 10 ties per node: 10,000 nodes 7.6 seconds, 20,000 nodes 29 seconds, 100,000 nodes about 15 minutes (estimated). When the estimated time is more than 2 minutes (about 36,000 nodes with 10 ties per node) the command stops at once with r(484) and a message; option {opt force} runs it anyway.

{title:See also}

	{help nwpath}, {help nwgeodesic}, {help nwcloseness}, {help nwkatz}, {help nwdegree}, {help nwcloseness}, {help nwevcent}

last certified : 23 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.7.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
