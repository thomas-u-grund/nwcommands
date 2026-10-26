{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwclique {hline 2}}Maximal clique enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwclique}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opth minsize(int)}
{opt nomatrix}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's largest maximal-clique membership size{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest clique size to report; default = 3{p_end}
{synopt:{opt nomatrix}}Do not store {bf:r(clique_matrix)}; the {opth generate(newvarname)} variable and {bf:r(cliques)} are still returned{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwclique} enumerates every maximal clique in the network(s) in {help netlist} - a clique is a
set of nodes in which every pair is mutually tied; a clique is {it:maximal} if no further node
could be added to it without breaking that property. Enumeration uses the classical Bron and
Kerbosch (1973) recursive algorithm.

{pstd}
Cliques are fundamentally different from the partitions {help nwcomponents}/{help nwcommunity}/
{help nwconcor} generate: a node can belong to {it:several} overlapping maximal cliques at once (as
in the classic example of two triangles sharing an edge), so there is no single clique-membership
variable to generate the way there is a single component or community id. Instead, {cmd:nwclique}
generates a variable holding, for each node, the size of the {it:largest} maximal clique it belongs
to (its "clique number") - a single, well-defined per-node summary - and returns the full clique
list (as a cliques-by-nodes 0/1 membership matrix) in {bf:r(clique_matrix)} for anyone who needs the
complete overlapping structure rather than just this summary.

{pstd}
{opth minsize(int)} filters out cliques smaller than the given size before generating and
returning results (a dyad - two mutually tied nodes with no further extension - is technically a
maximal clique of size 2, and an isolated node with no ties at all is technically one of size 1; the
default of 3 excludes both, matching the common convention that a "clique" worth reporting has at
least three members). A node that belongs to no clique meeting {opth minsize(int)} gets a missing
value in the generated variable, not a spurious 0.

{title:Stored results}

	Scalars
	  {bf:r(cliques)}		number of maximal cliques found meeting {opth minsize(int)}

	Matrices
	  {bf:r(clique_matrix)}	cliques-by-nodes 0/1 membership matrix, one row per maximal clique (not with {opt nomatrix})

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwclique flomarriage, generate(_cliquenum)}


{title:References}

{pstd}
Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph.
{it:Communications of the ACM} 16(9), 575-577.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Two-mode networks}

{pstd}
Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); cliques of three or more nodes cannot exist in a bipartite graph.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (a clique's own definition - every pair
mutually tied - has no directed generalization, the same reasoning {help nwcoreperiphery} already
applies). Weighted: not used - only presence/absence of a tie matters; tie strength does not affect
clique membership. Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); cliques of three or more nodes cannot exist in a bipartite graph. Maximal clique enumeration is worst-case exponential in the number of
maximal cliques a graph can have (a mathematical property of the problem itself, true of any correct
algorithm) - fine for the moderate network sizes typical of SNA datasets, but a very dense, large
network could take a long time. {help nwnclique}, {help nwnclan} and {help nwkplex} have the options {opt maxcliques()} / {opt maxplexes()}, {opt maxtime()}, {opt countonly} and {opt nomatrix} for such searches; {cmd:nwclique} has none.

{title:Limits}

{pstd}
Only the maximal cliques of at least {opt minsize()} nodes are stored (the maximal cliques of one or two nodes of a sparse network
are as many as its ties and were the bulk of the work). The search (Bron and Kerbosch with pivoting) runs in the compiled graph plugin
(the native kernel of {cmd:nwcommands}) when the plugin of your platform has it, and in Mata otherwise; both find the same cliques in the
same order. Measured in Stata/BE on a random undirected network with 10 ties drawn per node and {opt minsize(3)}: 5,000 nodes 0.1 seconds,
20,000 nodes 1.0 second (the Mata route needs 0.35 and 3.3 seconds). From about 40,000 nodes on, most of the time is spent in Stata itself,
which needs time growing with the square of the number of columns to store the clique matrix {cmd:r(clique_matrix)} (one row per clique,
one column per node): 100,000 nodes take about one minute, of which the search is 0.6 seconds. A network with many cliques also needs a lot
of memory for that matrix. With option {opt nomatrix} the matrix is not built or stored: the variable and {cmd:r(cliques)} are the same, and
100,000 nodes take about a quarter of a second.
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}

	{help nwkplex}, {help nwnclique}, {help nwnclan}, {help nwkcomponents}, {help nwkcore}, {help nwcomponents}, {help nwcommunity}, {help nwconcor}

last certified : 21 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.9.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
