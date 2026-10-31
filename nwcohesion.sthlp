{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcohesion {hline 2}}Moody-White structural cohesion hierarchy{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcohesion}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}
{opt force}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's own highest cohesion level{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt force}}Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise){p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcohesion} computes the full, multi-level Moody and White (2003) cohesive-blocking hierarchy:
starting from the whole network, it recursively finds ever-more-cohesive nested sub-blocks, using
{help nwkcomponents}' own single-level k-component primitive (vertex connectivity via node-splitting
max-flow, Menger's theorem) applied repeatedly at increasing connectivity levels. Where
{help nwkcomponents} answers "which nodes form a block of at least connectivity {opth k(int)}?" for
one chosen {opth k(int)}, {cmd:nwcohesion} answers the fuller question: "what is the complete nested
structure, from the whole network down to its most cohesive cores, and how cohesive is each level?" -
with no {opth k(int)} to choose, since every level actually present in the network is found and
reported.

{pstd}
Each block's own connectivity level is its network's ACTUAL vertex connectivity (not merely the
level searched for) - a disconnected network's own top block is reported at level 0, a network
joined only by a single cut vertex at level 1, and so on. Levels found deeper in the hierarchy can
skip values (e.g. a level-1 block can have level-3 children directly, with no level-2 block ever
appearing) - a well-documented real property of structural cohesion, not a limitation of this
implementation.

{pstd}
Like {help nwkcomponents}, blocks can genuinely overlap (a cutset remains a shared member of every
sub-block its removal reveals) and nest (a child block's own node set is always a strict subset of
its parent's), so the complete structure is returned via {bf:r(cohesion_matrix)} (a blocks-by-nodes
0/1 membership matrix, one row per block found at ANY level of the hierarchy) and
{bf:r(cohesion_levels)} (a parallel column vector giving each row's own connectivity level).
{opth generate(newvarname)} (required) stores, per node, the HIGHEST level of any
block that node belongs to - the standard node-level structural-cohesion summary statistic - and is
always well-defined for every node (even an isolate gets its own top-block level, typically 0),
unlike {help nwkcomponents}' own {it:_kcompnum}, which is missing for nodes that don't qualify for
the one requested {opth k(int)}.

{title:Stored results}

	Scalars
	  {bf:r(blocks)}	number of cohesive blocks found across the whole hierarchy

	Matrices
	  {bf:r(cohesion_matrix)}	blocks-by-nodes 0/1 membership matrix, one row per block at any level
	  {bf:r(cohesion_levels)}	blocks-by-1 column vector of each row's own connectivity level

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcohesion flomarriage, generate(_cohesion)}


{title:References}

{pstd}
Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of
social groups. {it:American Sociological Review} 68(1), 103-127.

{pstd}
Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. {it:Networks}
23(6), 533-541.

{pstd}
Even, S. (1979). {it:Graph Algorithms}. Computer Science Press. (the vertex-splitting max-flow
reduction for vertex connectivity)


{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity has no directed
generalization here, matching {help nwkcomponents}). Weighted: not used. Signed: not checked.
Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation).

{title:Limits}

{pstd}
The search runs in compiled code on the list of ties, never on an N-by-N matrix. It is more expensive than a single
{help nwkcomponents} call, since every block found is searched again at the next connectivity level; the time grows
with the number of nodes squared times the connectivity level of the deepest block. Measured in Stata/BE on a random
network with 10 ties drawn per node (about 20 per node once symmetrized): 300 / 1,000 / 5,000 nodes take 0.02 / 0.09 /
1.4 seconds. The previous Mata routine took 22 seconds at 300 nodes and did not finish in 60 seconds at 1,000.
{cmd:r(cohesion_matrix)} has one row per block and one column per node. On a platform whose plugin file has not been
built yet, the older Mata routine runs instead (same results, about 20 seconds at 300 nodes).

{pstd}
Measured in Stata/BE on a random undirected network with 10 ties drawn per node: 10,000 nodes 6 seconds, 20,000 nodes 27 seconds and 2.9 GB. When the estimated time is more than 2 minutes (about 40,000 nodes) the command stops at once with r(484) and a message; option {opt force} runs it anyway.

{title:See also}

	{help nwkcomponents}, {help nwcomponents}, {help nwclique}, {help nwkplex}

last certified : 22 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.12.2, 31 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
