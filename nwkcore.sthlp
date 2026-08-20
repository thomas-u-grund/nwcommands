{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwkcore {hline 2} k-core decomposition}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkcore}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's coreness; default = {it:_kcore}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwkcore} computes the k-core decomposition (Seidman 1983) of a network or a list of networks. A
node's {it:coreness} is the largest {it:k} such that the node belongs to a {it:k-core}: a maximal
subgraph in which every node has degree at least {it:k} within that subgraph. Nodes with high
coreness sit in the network's densely interconnected "core"; nodes with low coreness (e.g. degree-1
pendants) sit on the periphery. Coreness is a common building block for identifying cohesive
subgroups and for network visualization (e.g. sizing/coloring nodes by coreness, or restricting a
plot to the k-core for some threshold {it:k}).

{pstd}
All calculations are performed on the undirected version of the network: for directed networks, a
node's neighbor set is the union of its out- and in-neighbors, matching how {help nwcomponents}
treats directed networks for the same kind of undirected-sense structural question.

{pstd}
By default, {cmd:nwkcore} generates a new variable {it:_kcore} which stores each node's coreness.

{title:Stored results}

	Scalars
	  {bf:r(maxcore)}		maximum coreness found (the network's degeneracy)

	Matrices
	  {bf:r(core_sizeid)}		distribution over coreness levels


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkcore flomarriage}
	{cmd:. tab _kcore}


{title:References}

{pstd}
Seidman, S.B. (1983). Network structure and minimum degree. {it:Social Networks} 5(3), 269-287.

{pstd}
Batagelj, V., Zaversnik, M. (2003). An O(m) Algorithm for Cores Decomposition of Networks.
arXiv:cs/0310049.

{title:See also}

	{help nwcomponents}, {help nwcommunity}, {help nwdegree}

last certified : 21 Aug 2026
