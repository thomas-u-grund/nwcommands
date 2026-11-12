{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, roles and similarity}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwshared {hline 2}}Number of shared neighbors of all pairs of nodes, as a network{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab: nwshared} 
[{it:{help netname}}]
[{cmd:,}
{opth name(newnetname)}
{opt undirected}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}Save as new network; default {it:_shared}{p_end}
{synopt:{opt undirected}}Treat all ties as undirected for calculation{p_end}
{synopt:{opt replace}}if a network named {it:newnetname} already exists, drop it and use this name anyway (alias: {opt nwreplace}){p_end}


{title:Description}

{pstd}
This command calculates for each connected pair of nodes (i,j) the number of nodes k that both i and j
have as shared neighbors.  


{title:Network types}

{pstd}
{bf:Directed:} needs {opt undirected} (symmetrizes first); without it the command stops with an error. {bf:Valued:}
tie values are ignored (the command prints a note on a valued network). {bf:Two-mode:} same as for the bipartite graph
read as a one-mode network. {bf:Signed:} not applicable. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The two-step paths i -> k -> j are listed from the stored ties (the sum over k of in-degree times out-degree) and counted on the
ties; no matrix is built. 20,000 nodes 1.7 seconds in Stata/BE, random directed network with 10 ties per node.


{title:Example}

		{cmd:. nwwebuse florentine, nwclear}
		{cmd:. nwshared flomarriage, name(shared)}
		{cmd:. nwplot flomarriage, edgecolor(shared) edgesize(shared) edgefactor(3)}


{title:See also}
	{help nwsimmelian}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
