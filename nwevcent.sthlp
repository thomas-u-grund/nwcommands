{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwevcent {hline 2}}Eigenvector centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwevcent}
[{it:{help netname}}]
[{cmd:,}
{opt gen:erate}({it:{help varname}})
{opt nosym}
{opt weighted}
{opt replace}
{opt bin:ary}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt gen:erate}({it:{help varname}})}{bf:Required.} Variable name for eigenvector centrality scores{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation{p_end}
{synopt:{opt weighted}}use the tie values of a valued network; redundant, this is the default (kept for compatibility){p_end}
{synopt:{opt replace}}replace existing {it:generate()} variable{p_end}
{synopt:{opt bin:ary}}Ignore the tie values of a valued network (by default they are used){p_end}


{title:Description}

{pstd}
Calculates eigenvector centrality for each node {it:i} in a netwwork and
saves the result as a Stata variable. It assigns relative scores to all nodes in the network
based on the concept that connections to high-scoring nodes contribute more to the score of
the node in question than equal connections to low-scoring nodes.

{pstd}
By default, a valued network is calculated on the tie values themselves, so that stronger ties
contribute proportionally more, matching the standard weighted generalization of eigenvector
centrality (Newman 2004, Bonacich power centrality). Option {bf:binary} instead dichotomizes the
network before calculation (any nonzero, non-missing tie value counts as a tie, regardless of
magnitude). {bf:weighted} is redundant and has no effect on an unvalued network (there is nothing
to weight by).

{pstd}
Eigenvector centrality is only defined for connected networks.


{title:Network types}

{pstd}
{bf:Directed:} symmetrized by default; {opt nosym} uses outgoing ties (igraph uses incoming ties). {bf:Valued:} the
tie values are used by default ({opt weighted} is redundant); {opt binary} ignores them. {bf:Two-mode:} same as for
the bipartite graph read as a one-mode network. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The power iteration runs in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your platform has it,
and in Mata otherwise; both give the same result (they differ by less than 1e-10 relative).
Measured in Stata/BE, random undirected network with 10 ties per node: 5,000 nodes 0.05 seconds, 20,000 nodes 0.1 seconds,
100,000 nodes 0.5 seconds (the Mata route needs 0.6, 2.6 and 14 seconds).{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}


{title:Examples}

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwevcent gang, generate(_evcent)}
	{cmd:. sum _evcent}
	{cmd:. nwevcent gang, generate(_evcent_w) weighted}


{title:References}

{pstd}
Newman, M.E.J. (2004). Analysis of weighted networks. {it:Physical Review E} 70, 056131.

{pstd}
Bonacich, P. (1972). Factoring and weighting approaches to status scores and clique identification.
{it:Journal of Mathematical Sociology} 2(1), 113-120.


{title:See also}

	{help nwcloseness}, {help nwbetween}, {help nwdegree}, {help nwcloseness}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
