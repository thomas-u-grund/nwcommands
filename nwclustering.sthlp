{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_clustering:[NW-2.6.5] Clustering, mixing and balance}

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
{opt silent}
{opt level(#)}
{opt ra}
{opt onemode}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt measure(binary|arithmetic|geometric|maximum|minimum)}}How to combine the two tie
values in a potential triple for a weighted network; {it:binary} ignores tie values and only checks
presence/absence; {it:arithmetic}/{it:geometric}/{it:maximum}/{it:minimum} combine the two tie
values via that function; default = {it:arithmetic} for a valued undirected network, {it:binary}
otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before calculating (required for any
weighted {opt measure()} on a directed network - see {bf:Network types} below){p_end}
{synopt:{opth generate(newvarname)}}Name of a new variable that stores each node's own
clustering coefficient; for a one-mode network it may be left out, and the coefficients are then computed in a temporary variable (a two-mode network needs it, unless {opt ra} is given){p_end}
{synopt:{opt replace}}Overwrite an existing {opth generate(newvarname)} variable; required if it already exists{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt level(#)}}Two-mode network: the mode (1 or 2) whose nodes get a coefficient; default = {it:1}{p_end}
{synopt:{opt ra}}Two-mode network: the global coefficient of Robins and Alexander (2004), 4 C4 / L3, as {cmd:r(ra)}; {opt generate()} is then optional{p_end}
{synopt:{opt onemode}}Two-mode network: the one-mode coefficient of the bipartite graph (always 0, the graph has no triangles) instead of the two-mode coefficient of Opsahl (2013), the default{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwclustering} calculates the clustering coefficient (also known as transitivity) of a
network: for each node {it:i}, the proportion of {it:i}'s own potential triples - pairs of {it:i}'s
neighbors - that are themselves actually tied to each other ("the friends of my friends are
themselves friends"). A node with fewer than 2 neighbors has no potential triples and its own
clustering coefficient is reported as missing.

{pstd}
{opt generate()} names the new variable that holds each node's own
clustering coefficient (without it only the returned results are kept), and the command returns both the network-level average ({bf:r(cluster_avg)}, the mean
of the per-node values) and the network-level global clustering coefficient ({bf:r(cluster_global)},
the ratio of the total count of closed triples to the total count of potential triples across the
whole network - not the same quantity as the average of per-node ratios, since it weights every
potential triple equally rather than every node equally).

{pstd}
If the network is a two-mode (bipartite) network, {cmd:nwclustering} uses the two-mode form by default: the
coefficient of Opsahl (2013) (the share of four-paths that a fifth tie closes, {cmd:tnet::clustering_tm}), and with
{opt ra} the global coefficient of Robins and Alexander (2004). An ordinary clustering coefficient is not meaningful on a
bipartite network's own inherently triangle-free structure; {opt onemode} computes it anyway. {help nw2clustering} is the
same command under another name and takes the same options.


{title:Network types}

{pstd}
{bf:Directed:} {opt measure(binary)} only; use {opt symmetrize} for a weighted measure. {bf:Valued:}
{opt measure(arithmetic)} by default on an undirected valued network ({opt measure(binary)} ignores the values).
{bf:Two-mode:} two-mode form by default (option {opt onemode} for the one-mode computation) - Opsahl (2013), {opt ra}:
Robins and Alexander (2004). {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
For {opt measure(binary)} the closed and potential triples are counted in the compiled graph plugin (the native kernel of
{cmd:nwcommands}) when the plugin of your platform has it, and in Mata otherwise; both give identical coefficients.
The work grows with the sum of the squared degrees. Measured in Stata/BE, random undirected network with 10 ties per node:
5,000 nodes 0.06 seconds, 20,000 nodes 0.2 seconds, 100,000 nodes 0.7 seconds (the Mata route needs 1.1, 4.9 and 26 seconds).
The weighted measures (arithmetic, geometric, maximum, minimum) still run in Mata.{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwclustering flomarriage, generate(_clustering)}
	{cmd:. sum _clustering}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(cluster_avg)}}mean of the per-node clustering coefficients{p_end}
{synopt:{bf:r(cluster_global)}}network-level global clustering coefficient{p_end}
{synopt:{bf:r(C_avg)}}two-mode network: mean of the per-node coefficients of the {opt level()} mode (instead of {bf:r(cluster_avg)}){p_end}
{synopt:{bf:r(C_global)}}two-mode network: global coefficient of Opsahl (2013) (instead of {bf:r(cluster_global)}){p_end}
{synopt:{bf:r(ra)}}two-mode network with {opt ra}: Robins-Alexander coefficient 4 C4 / L3{p_end}
{synopt:{bf:r(C4)}}two-mode network with {opt ra}: number of four-cycles{p_end}
{synopt:{bf:r(L3)}}two-mode network with {opt ra}: number of paths of length three{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(measure)}}the {opt measure()} actually used{p_end}
{synopt:{bf:r(symmetrized)}}{it:true}, only returned when {opt symmetrize} was specified (one-mode network){p_end}


{title:References}

{pstd}
Watts, D.J., Strogatz, S.H. (1998). Collective dynamics of 'small-world' networks. {it:Nature}
393, 440-442.


{title:See also}

	{help nw2clustering}, {help nwtriads}, {help nwbrokerage}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
