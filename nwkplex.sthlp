{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, components and subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwkplex {hline 2}}Maximal k-plex enumeration{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwkplex}
[{it:{help netlist}}]
[{cmd:,}
{opth k(int)}
{opth gen:erate(newvarname)}
{opt replace}
{opth minsize(int)}
{opt maxp:lexes(#)}
{opt maxt:ime(#)}
{opt count:only}
{opt nom:atrix}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth k(int)}}How many ties each member may miss; default = 2{p_end}
{synopt:{opth gen:erate(newvarname)}}Name of the Stata variable that stores each node's largest maximal-k-plex membership size; default = {it:_kplexnum}; with several networks the variables are
numbered ({it:newvarname}{bf:1}, {it:newvarname}{bf:2}, ...){p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest k-plex size to report; default = {it:k}+1{p_end}
{synopt:{opt maxp:lexes(#)}}Stop with an error when more than this many maximal k-plexes of at least {opt minsize()} members are found (the result matrix needs sets x nodes numbers); default =
100,000{p_end}
{synopt:{opt maxt:ime(#)}}Stop with an error when the search has run for this many seconds without finishing; default = 60{p_end}
{synopt:{opt count:only}}Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; {opth gen:erate(newvarname)} is then not needed{p_end}
{synopt:{opt nom:atrix}}Do not build the sets-by-nodes matrix; the {opth gen:erate(newvarname)} variable and the count are still returned{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwkplex} enumerates every maximal k-plex in the network(s) in {help netlist} - a "relaxed
clique": a set of nodes in which every member is tied to all but at most {opth k(int)} - 1 of the
{it:other} members (a plain clique is the special case {opt k}=1, where nobody may miss any tie -
{help nwclique} already handles that case with a cheaper, purpose-built algorithm, so {cmd:nwkplex}
requires {opth k(int)} >= 2). A k-plex is {it:maximal} if no further node could be added to it
without breaking that property. Enumeration uses the same Bron and Kerbosch (1973)-style recursive
backtracking {help nwclique} uses, generalized to the k-plex membership rule (Seidman and Foster
1978).

{pstd}
Like cliques, k-plexes genuinely overlap - a node can belong to several at once - so there is no
single per-node k-plex-membership variable the way there is a single component or community id.
{cmd:nwkplex} generates a variable holding, for each node, the size of the {it:largest} maximal
k-plex it belongs to - a single, well-defined per-node summary - and returns the full k-plex list
(as a k-plexes-by-nodes 0/1 membership matrix) in {bf:r(kplex_matrix)} for anyone who needs the
complete overlapping structure.

{pstd}
{opth minsize(int)} filters out k-plexes smaller than the given size before generating and
returning results. This matters more for k-plexes than for cliques: by the formal definition above,
{it:any} set of {opth k(int)} or fewer nodes is trivially a valid k-plex regardless of whether its
members are tied at all (with {opth k(int)}=2, for example, any two nodes - tied or not - miss at
most 1 of their 1 possible tie, satisfying the rule) - such tiny, structurally-uninteresting sets
are usually not what "k-plex" is meant to capture. The default of {it:k}+1 is the smallest size at
which the constraint can actually rule anything out, so it excludes every automatically-valid,
uninformative case while still reporting the smallest {it:genuinely} constrained k-plexes. A node
that belongs to no k-plex meeting {opth minsize(int)} gets a missing value in the generated
variable, not a spurious 0.


{title:Network types}

{pstd}
{bf:Directed:} symmetrized. {bf:Valued:} tie values are ignored and a note is printed. {bf:Two-mode:} same as for the
bipartite graph read as a one-mode network. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
{bf:Feasible sizes.} The search runs in compiled code on bitset adjacency.
It is limited by the number of maximal k-plexes, which can be enormous (any set of {opt k} or fewer
nodes is a k-plex, and large sparse networks have very many bigger ones), and by the sets-by-nodes matrix
{bf:r(kplex_matrix)}, which needs sets x nodes numbers. Measured in Stata/BE on a random network with 10 ties drawn
per node, {opt k(2)}, {opt minsize(3)}: 100 nodes have 10,141 maximal 2-plexes (0.2 s), 300 nodes 31,081 (2.1 s, nearly
all of it building the 31,081 x 300 matrix; 0.04 s with {opt nomatrix}), 1,000 nodes 148,070 (0.2 s with
{opt nomatrix}), 5,000 nodes (2.9 s with {opt nomatrix}; 1.9 s with {opt countonly}). For {opt k(3)}, 300 nodes have
3,968,148 maximal 3-plexes, counted in 0.5 s.

{pstd}
{bf:Guards.} The command stops with r(484) and a message that names the option to raise when it has found more than
{opt maxplexes()} maximal k-plexes (default 100,000), when the result matrix would be too large to build (more than
50 million numbers; use {opt nomatrix}), or when the search has run for {opt maxtime()} seconds (default 60) without
finishing. {opt countonly} does not store the sets and is not limited by memory; {opt nomatrix} keeps the per-node
variable and the counts but not the matrix.

{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkplex flomarriage}
	{cmd:. nwkplex flomarriage, k(3) replace}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(kplexes)}}number of maximal k-plexes found meeting {opth minsize(int)}{p_end}
{synopt:{bf:r(maxsize)}}size of the largest set (with {opt countonly} or {opt nomatrix}){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(size_table)}}(with {opt countonly} or {opt nomatrix}) sizes and the number of sets of each size{p_end}
{synopt:{bf:r(kplex_matrix)}}k-plexes-by-nodes 0/1 membership matrix, one row per maximal k-plex (not with {opt countonly} or {opt nomatrix}){p_end}


{title:References}

{pstd}
Seidman, S.B., Foster, B.L. (1978). A graph-theoretic generalization of the clique concept.
{it:Journal of Mathematical Sociology} 6(1), 139-154.

{pstd}
Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph.
{it:Communications of the ACM} 16(9), 575-577.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:See also}

{p 4 4 2}{help nwclique}, {help nwnclique}, {help nwnclan}, {help nwkcomponents}, {help nwkcore}, {help nwcomponents}, {help nwcommunity}, {help nwconcor}{p_end}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
