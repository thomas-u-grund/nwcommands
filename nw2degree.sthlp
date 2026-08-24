{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nw2degree {hline 2}}Two-mode (bipartite) degree centrality{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nw2degree}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores two-mode degree centrality; default = {it:_2degree}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nw2degree} calculates degree centrality for a two-mode (bipartite) network, using the
normalization of Borgatti and Everett (1997). A node's ordinary (raw) degree can only ever reach as
high as the size of the {it:other} mode - a mode-1 node can tie to at most every mode-2 node, never
to another mode-1 node - so {help nwdegree}'s usual {it:n - 1} normalization does not apply here.
Instead, each node's raw degree is divided by the size of the mode it does {it:not} belong to:

{pmore}
{it:C'D(i) = degree(i) / n_other}, where {it:n_other} is the number of nodes in the other mode

{pstd}
so that a mode-1 node tied to every mode-2 node (or vice versa) scores exactly 1, matching ordinary
degree centrality's own [0,1] range and interpretation.

{pstd}
By default, {cmd:nw2degree} generates a new variable {it:_2degree} holding this value for every
node, regardless of which mode it belongs to (mode membership itself is available via
{help nw2set}'s own mode-id variable, not duplicated here).

{title:Examples}

	{cmd:. nwclear}
	{cmd:. mata: net = (1,1\1,0\0,1)}
	{cmd:. nw2set, mat(net) name(mynet)}
	{cmd:. nw2degree mynet}


{title:References}

{pstd}
Borgatti, S.P., Everett, M.G. (1997). Network analysis of 2-mode data. {it:Social Networks} 19(3),
243-269.


{title:Supported network types}

{pstd}
Binary: yes. Directed: not applicable - two-mode ties in this package's storage are inherently
undirected (a tie either connects a mode-1 node to a mode-2 node or it does not). Weighted: not
used - only presence/absence of a tie determines raw degree; tie strength does not affect this
measure (a weighted two-mode degree/strength variant is not implemented). Signed: not checked.
Two-mode: this command requires a two-mode network and errors clearly on a one-mode one, the
opposite convention of most other commands in this package.

{title:See also}

	{help nwdegree}, {help nw2set}, {help nw2project}, {help nw2clustering}

last certified : 24 Aug 2026
