{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwkcomponents {hline 2}}Maximal k-component enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkcomponents}
[{it:{help netlist}}]
[{cmd:,}
{opth k(int)}
{opth generate(newvarname)}
{opt replace}
{opt nomatrix}
{opt silent}
{opt force}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth k(int)}}Minimum vertex connectivity required; default = 2{p_end}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's largest qualifying k-component size{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt nomatrix}}Do not store {bf:r(kcomp_matrix)}; the {opth generate(newvarname)} variable and {bf:r(kcomponents)} are still returned{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt force}}Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise){p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwkcomponents} enumerates every maximal k-component (Kanevsky 1993) in the network(s) in
{help netlist} - a subgraph with {it:vertex connectivity} of at least {opth k(int)}, meaning at least
{opth k(int)} nodes would have to be removed from it to disconnect it (or reduce it to a single
node). A k-component is a genuine strengthening of an ordinary connected component (which is just
the {opth k(int)}=1 case - {help nwcomponents} already implements that, more cheaply, via a simple
reachability search rather than a connectivity computation): {opth k(int)}=2 excludes single
cut-vertices/bridges that would fracture the group, {opth k(int)}=3 additionally excludes any
2-node cutset, and so on. This directly formalizes the intuition that a group connected only by a
single "weak link" is less cohesive than one where {it:several independent} paths connect every
pair of members.

{pstd}
{opth k(int)} defaults to 2 - the smallest level that is a genuine refinement of
{help nwcomponents}' own plain connectivity - and must be at least 1 ({help nwcomponents} already
covers that trivial case directly). Vertex connectivity is computed via the standard node-splitting
reduction to max-flow (Even 1979) combined with Menger's theorem (the minimum vertex set separating
any two non-adjacent nodes equals the maximum flow between them in the split graph); the network's
own overall k-components are then found by the standard recursive decomposition also underlying
Moody and White's (2003) cohesive blocking - see {help nwkcomponents##algorithm:Algorithm} below for
the one respect in which this command deliberately does less than the full Moody-White procedure.

{pstd}
Like cliques/k-plexes/n-cliques/n-clans, k-components can genuinely overlap - the nodes whose
removal disconnects a graph (a cutset) remain shared members of every resulting sub-block their
removal reveals, not assigned to just one side - so {cmd:nwkcomponents} follows the same output
shape as {help nwclique}/{help nwkplex}/{help nwnclique}: a single per-node "largest qualifying
k-component size" summary variable ({opth generate(newvarname)}, required), plus the
complete overlapping structure in {bf:r(kcomp_matrix)} (a k-components-by-nodes 0/1 membership
matrix) and {bf:r(kcomponents)} (count). Unlike those commands there is no {opt minsize()} - a
k-component's own minimum possible size is already {opth k(int)}+1 (a smaller set cannot reach
connectivity {opth k(int)} at all, since the maximum possible connectivity of an s-node graph is
s-1), so there is no equivalent "trivial small case" to filter out separately.

{marker algorithm}{...}
{title:Algorithm}

{pstd}
{cmd:nwkcomponents} computes k-components for exactly the single level {opth k(int)} requested, not
the full Moody-White hierarchy (which recursively re-applies this same procedure at every
increasing connectivity level found, building a complete nested tree from the whole network down to
its most cohesive core). Computing just one target level directly is both simpler to verify by hand
and matches how {help nwkplex}/{help nwnclique} already expose their own single-parameter cohesion
concepts in this package - a full recursive multi-level hierarchy, if wanted later, would be a
natural, separate follow-on built on the same {opth k(int)}-level primitive this command already
provides, not a reason to withhold the single-level version now.

{title:Stored results}

	Scalars
	  {bf:r(kcomponents)}	number of maximal k-components found

	Matrices
	  {bf:r(kcomp_matrix)}	k-components-by-nodes 0/1 membership matrix, one row per maximal k-component (not with {opt nomatrix})

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkcomponents flomarriage, generate(_kcompnum)}
	{cmd:. nwkcomponents flomarriage, k(3) generate(_kcompnum) replace}


{title:References}

{pstd}
Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. {it:Networks}
23(6), 533-541.

{pstd}
Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of
social groups. {it:American Sociological Review} 68(1), 103-127.

{pstd}
Even, S. (1979). {it:Graph Algorithms}. Computer Science Press. (the vertex-splitting max-flow
reduction for vertex connectivity)

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (k-components and structural cohesion)


{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity in the classical
Moody-White sense has no directed generalization here, the same reasoning {help nwclique}/
{help nwkplex}/{help nwnclique} already apply). Weighted: not used - only tie presence/absence
affects connectivity. Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation). Vertex-connectivity computation
via max-flow is polynomial per pair, but {cmd:nwkcomponents} computes it between {it:every}
non-adjacent pair (a deliberately simple and definitely correct method rather than the smaller
reference-vertex subset a more optimized algorithm would use), and the overall
recursive decomposition can call this repeatedly. For k = 2 the plugin answers the connectivity queries in blocks
(see {bf:Limits}); for k of 3 and higher, very large or very dense networks are not recommended.

{title:Limits}

{pstd}
The search for vertex cuts runs in compiled code and the network is not turned into a matrix. For k(2), the default, the search needs a
single pass over the ties (the blocks of the network, one depth-first search) instead of one max-flow computation per node; for k(3) and
higher it is still one max-flow computation per node and per level. Measured in Stata/BE on a random undirected network with 10 ties drawn
per node and k(2): 1,000 / 5,000 / 20,000 nodes in 0.02 / 0.1 / 1.0 seconds (before: 0.04 / 1.8 / 67 seconds). Both routes give the same
components in the same order. Without the compiled plugin for the platform the Mata code is used and is much slower. For large k or many
cuts the time is longer.

{pstd}
Every level of the recursion looks for a vertex cut, so the time grows with the number of cuts. From about 40,000 nodes on, most of the time
is spent in Stata itself, which needs time growing with the square of the number of columns to store the matrix {cmd:r(kcomp_matrix)}
(one row per component, one column per node): 100,000 nodes take about one minute. Option {opt nomatrix} leaves the matrix out; the variable and {cmd:r(kcomponents)} are the same. When the estimated time is more than 2 minutes (about 31,000 nodes, an estimate made
for the slower route) the command stops at once with r(484) and a message; option {opt force}
runs it anyway. For components use {help nwcomponents}, for cores {help nwkcore}.
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}

	{help nwcomponents}, {help nwclique}, {help nwkplex}, {help nwnclique}, {help nwnclan}, {help nwkcore}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.6.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
