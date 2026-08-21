{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwkplex {hline 2} Maximal k-plex enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkplex}
[{it:{help netlist}}]
[{cmd:,}
{opth k(int)}
{opth generate(newvarname)}
{opt replace}
{opth minsize(int)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth k(int)}}How many ties each member may miss; default = 2{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's largest maximal-k-plex membership size; default = {it:_kplexnum}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest k-plex size to report; default = {it:k}+1{p_end}
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

{title:Stored results}

	Scalars
	  {bf:r(kplexes)}		number of maximal k-plexes found meeting {opth minsize(int)}

	Matrices
	  {bf:r(kplex_matrix)}	k-plexes-by-nodes 0/1 membership matrix, one row per maximal k-plex

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkplex flomarriage}
	{cmd:. nwkplex flomarriage, k(3)}


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


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (a k-plex's own definition - a bound on each
member's own missing-tie count - has no natural directed generalization, the same reasoning
{help nwclique} already applies). Weighted: not used - only presence/absence of a tie matters.
Signed: not checked. Two-mode: not checked - operates on the network's own square adjacency matrix.
Maximal k-plex enumeration is worst-case exponential (a mathematical property of the problem
itself, true of any correct algorithm) and, for a fixed network, generally slower than
{help nwclique}'s own clique enumeration for the same reason its own "Supported network types"
section already notes for cliques, compounded further here since checking whether a candidate can
still be added requires examining the whole candidate set's own induced structure, not just a
simple neighbor lookup - fine for the moderate network sizes typical of SNA datasets, not
specially guarded against here beyond this note.

{title:See also}

	{help nwclique}, {help nwnclique}, {help nwnclan}, {help nwkcomponents}, {help nwkcore}, {help nwcomponents}, {help nwcommunity}, {help nwconcor}

last certified : 21 Aug 2026
