{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwnclique {hline 2}}Maximal n-clique enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnclique}
[{it:{help netlist}}]
[{cmd:,}
{opth n(int)}
{opth generate(newvarname)}
{opt replace}
{opth minsize(int)}
{opt maxcliques(#)}
{opt maxtime(#)}
{opt countonly}
{opt nomatrix}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth n(int)}}Maximum geodesic distance allowed between any two members; default = 2{p_end}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's largest maximal-n-clique membership size{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest n-clique size to report; default = 3{p_end}
{synopt:{opt maxcliques(#)}}Stop with an error when more than this many maximal n-cliques of at least {opt minsize()} members are found (the result matrix needs sets x nodes numbers); default = 100,000{p_end}
{synopt:{opt maxtime(#)}}Stop with an error when the search has run for this many seconds without finishing; default = 60{p_end}
{synopt:{opt countonly}}Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; {opth generate(newvarname)} is then not needed{p_end}
{synopt:{opt nomatrix}}Do not build the sets-by-nodes matrix; the {opth generate(newvarname)} variable and the count are still returned{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwnclique} enumerates every maximal n-clique in the network(s) in {help netlist} - a
generalization of an ordinary clique (Luce 1950) where every pair of members need only be within
geodesic distance {opth n(int)} of {it:each other in the network as a whole}, rather than directly
tied. A plain clique is the special case {opth n(int)}=1 (distance-1 "neighbors" are exactly direct
ties) - {help nwclique} already handles that case with a cheaper, purpose-built algorithm, so
{cmd:nwnclique} requires {opth n(int)} >= 2.

{pstd}
Because n-clique membership is judged by whole-network distance, a pair of members can qualify even
though the shortest path between them runs through a node that is not itself part of the n-clique -
a well-known limitation of the concept (Alba 1973): an n-clique's own members are not guaranteed to
be reachable from one another {it:while staying inside the group}. {help nwnclan} adds exactly that
extra requirement.

{pstd}
Like cliques, n-cliques genuinely overlap - a node can belong to several at once - so {cmd:nwnclique}
follows {help nwclique}'s own output shape: a single per-node "largest maximal n-clique membership
size" summary variable ({opth generate(newvarname)}, required), plus the complete
overlapping structure in {bf:r(nclique_matrix)} (an n-cliques-by-nodes 0/1 membership matrix) and
{bf:r(ncliques)} (count). {opth minsize(int)} filters out n-cliques smaller than the given size
before generating and returning results, matching {help nwclique}'s own default of 3 (a dyad or an
isolated node is technically a maximal n-clique too, but rarely what "n-clique" is meant to convey).
A node that belongs to no n-clique meeting {opth minsize(int)} gets a missing value in the generated
variable, not a spurious 0.

{title:Stored results}

	Scalars
	  {bf:r(ncliques)}		number of maximal n-cliques found meeting {opth minsize(int)}
	  {bf:r(maxsize)}	size of the largest set (with {opt countonly} or {opt nomatrix})

	Matrices
	  {bf:r(size_table)}	(with {opt countonly} or {opt nomatrix}) sizes and the number of sets of each size
	  {bf:r(nclique_matrix)}	n-cliques-by-nodes 0/1 membership matrix, one row per maximal n-clique (not with {opt countonly} or {opt nomatrix})

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwnclique flomarriage, generate(_ncliquenum)}
	{cmd:. nwnclique flomarriage, n(3) generate(_ncliquenum) replace}


{title:References}

{pstd}
Luce, R.D. (1950). Connectivity and generalized cliques in sociometric group structure.
{it:Psychometrika} 15(2), 169-190.

{pstd}
Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. {it:Journal of Mathematical Sociology} 3(1), 113-126.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (an n-clique's own definition has no directed
generalization, the same reasoning {help nwclique}/{help nwkplex} already apply). Weighted: not
used for membership - {opth n(int)} counts hops, not tie strength, though the underlying distance
calculation ({help nwgeodesic}'s own unweighted, {cmd:alpha(0)}-equivalent convention) is unaffected
by weight either way. Signed: not checked. Two-mode: not checked - operates on the network's own
square adjacency matrix. Maximal n-clique enumeration inherits {help nwclique}'s own worst-case
exponential behaviour (a mathematical property of maximal-clique-family problems in general).

{title:Limits}

{pstd}
{bf:Feasible sizes.} The graph "distance at most {it:n}" is built as bitsets by a breadth-first search from every
node and searched with the same pivoting Bron-Kerbosch rule, in compiled code, in the same order as the Mata version.
What limits the command is the number of maximal n-cliques, not the size of the network: with {opt n(2)} almost every
node reaches almost every other within two steps, the "distance at most 2" graph is dense, and its maximal cliques
are very many. Measured in Stata/BE on a random network with 10 ties drawn per node and {opt n(2)}: 100 nodes already
have 46,580,136 maximal 2-cliques of at least 3 nodes (up to 64 nodes each; counting them with {opt countonly} takes
33 seconds, and the result matrix would need 37 GB), so the output of the command, not its running time, is out of
reach from about 100 nodes on. The previous Mata version used 5.3 GB and did not finish in 60 seconds at 100 nodes.
Sparser or smaller networks, a larger {opt minsize()} and path-like networks (long distances, few short cycles) are
fine.

{pstd}
{bf:Guards.} The command stops at once with r(484) and a message that names the option to raise when it has found
more than {opt maxcliques()} maximal n-cliques (default 100,000), when the result matrix would be too large to build
(more than 50 million numbers; use {opt nomatrix}), or when the search has run for {opt maxtime()} seconds (default 60).
{opt countonly} counts and tabulates the sets by size without storing them.

{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}

	{help nwnclan}, {help nwclique}, {help nwkplex}, {help nwkcomponents}, {help nwgeodesic}, {help nwkcore}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.5.0, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
