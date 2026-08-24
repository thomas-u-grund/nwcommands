{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwshared {hline 2}}Calculate number of shared neighbors between nodes and saves information in network{p_end}
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
{synopt:{opt replace}}if a network named {it:newnetname} already exists, drop it and use this name anyway (alias: {opt nwreplace}, kept for backward compatibility - most sibling generators in this package instead spell this {opt replace}){p_end}

{title:Description}

{pstd}
This command calculates for each connected pair of nodes (i,j) the number of nodes k that both i and j
have as shared neighbors.  


{title:Supported network types}

{pstd}
Binary: yes (only) - shared-tie/exposure counting is a structural property, tie values are ignored (via {help nwsym}'s own binarizing {cmd:generate()} path). Directed: requires {opt undirected} to symmetrize first, else an explicit error. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

{title:Example}

		{cmd:. nwwebuse florentine, nwclear}
		{cmd:. nwshared flomarriage, name(shared)}
		{cmd:. nwplot flomarriage, edgecolor(shared) edgesize(shared) edgefactor(3)}

{title:See also}
	{help nwsimmelian}
	
last certified : 24 Aug 2026
