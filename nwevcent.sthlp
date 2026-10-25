{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwevcent {hline 2}}Calculate eigenvector centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwevcent}
[{it:{help netname}}]
[{cmd:,}
{opt generate}({it:{help varname}})
{opt nosym}
{opt weighted}
{opt replace}
{opt binary}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help varname}})}{bf:Required.} Variable name for eigenvector centrality scores{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation{p_end}
{synopt:{opt weighted}}use the tie values of a valued network; redundant, this is the default (kept for compatibility){p_end}
{synopt:{opt replace}}replace existing {it:generate()} variable{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}


{title:Description}

{pstd}
Calculates eigenvector centrality for each node {it:i} in a netwwork and
saves the result as a Stata variable. It assigns relative scores to all nodes in the network
based on the concept that connections to high-scoring nodes contribute more to the score of
the node in question than equal connections to low-scoring nodes.

{pstd}
By default, a valued network is dichotomized before calculation (any nonzero, non-missing tie value
counts as a tie, regardless of magnitude) - the historical, still-default behavior of this command.
Option {bf:weighted} instead calculates on the tie values themselves, so that stronger ties
contribute proportionally more, matching the standard weighted generalization of eigenvector
centrality (Newman 2004, Bonacich power centrality). {bf:weighted} has no effect on an unvalued
network (there is nothing to weight by).

{pstd}
Eigenvector centrality is only defined for connected networks.


{title:Valued networks}

{pstd}
A network is valued when it was created with tie values ({help nwfromedge} with a value variable, an import or a matrix with values, {cmd:nwset, valued}); the flag is shown by {help nwsummarize} and explained in {help nwnetworktypes}. On a valued network the eigenvector centrality is that of the matrix of tie values ({it:igraph::eigen_centrality}; scaled to unit length, igraph scales to maximum 1). {opt binary} uses presence only. The option {opt weighted} is accepted for compatibility; it is redundant on a valued network. For a directed network with {opt nosym} outgoing ties are used (igraph uses incoming ties).
On a network that is not valued the result is the same as in earlier releases and {opt binary} has no effect.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - symmetrized by default (same "no-prefix trap" {opt nosym} convention as {help nwcloseness}/{help nwkatz}), {opt nosym} available. Weighted: not by default - {opt weighted} switches to the tie-value-weighted generalization (Newman 2004, Bonacich power centrality); has no effect on an unvalued network. Signed: not checked. Two-mode: not applicable (one-mode only).

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


{title:Limits}

{pstd}
The power iteration runs in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your platform has it,
and in Mata otherwise; both give the same result (they differ by less than 1e-10 relative).
Measured in Stata/BE, random undirected network with 10 ties per node: 5,000 nodes 0.05 seconds, 20,000 nodes 0.1 seconds,
100,000 nodes 0.5 seconds (the Mata route needs 0.6, 2.6 and 14 seconds).
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}

	{help nwcloseness}, {help nwbetween}, {help nwdegree}, {help nwcloseness}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.5.0, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
