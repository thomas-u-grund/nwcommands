{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, components and subgroups}

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
Cliques are fundamentally different from the partitions {help nwcomponents} / {help nwcommunity} /
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

{pstd}
With more than one network in the {it:netlist}, a number is appended to the variable name ({it:newvarname}{bf:1},
{it:newvarname}{bf:2}, ...) and the stored results are those of the last network.


{title:Network types}

{pstd}
{bf:Directed:} symmetrized. {bf:Valued:} tie values are ignored (the command prints a note on a valued network).
{bf:Two-mode:} same as for the bipartite graph read as a one-mode network (it has no cliques of three or more nodes).
{bf:Signed:} negative values are not treated specially. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Only the maximal cliques of at least {opt minsize()} nodes are stored (the maximal cliques of one or two nodes of a sparse network
are as many as its ties and would be the bulk of the work). The search (Bron and Kerbosch with pivoting) runs in the compiled graph plugin
(the native kernel of {cmd:nwcommands}) when the plugin of your platform has it, and in Mata otherwise; both find the same cliques in the
same order. Measured in Stata/BE on a random undirected network with 10 ties drawn per node and {opt minsize(3)}: 5,000 nodes 0.1 seconds,
20,000 nodes 1.0 second (the Mata route needs 0.35 and 3.3 seconds). From about 40,000 nodes on, most of the time is spent in Stata itself,
which needs time growing with the square of the number of columns to store the clique matrix {cmd:r(clique_matrix)} (one row per clique,
one column per node): 100,000 nodes take about one minute, of which the search is 0.6 seconds. A network with many cliques also needs a lot
of memory for that matrix. With option {opt nomatrix} the matrix is not built or stored: the variable and {cmd:r(cliques)} are the same, and
100,000 nodes take about a quarter of a second.{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{pstd}
The number of maximal cliques can grow exponentially with the size of a network (true of any algorithm), so a very dense,
large network can take a long time; {cmd:nwclique} has no {opt maxcliques()} or {opt maxtime()} guard as {help nwnclique} has.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwclique flomarriage, generate(_cliquenum)}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(cliques)}}number of maximal cliques found meeting {opth minsize(int)}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(clique_matrix)}}cliques-by-nodes 0/1 membership matrix, one row per maximal clique (not with {opt nomatrix}){p_end}


{title:References}

{pstd}
Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph.
{it:Communications of the ACM} 16(9), 575-577.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:See also}

{p 4 4 2}{help nwkplex}, {help nwnclique}, {help nwnclan}, {help nwkcomponents}, {help nwkcore}, {help nwcomponents}, {help nwcommunity}, {help nwconcor}{p_end}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
