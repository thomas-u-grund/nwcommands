{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
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
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's own highest cohesion level{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

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


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity has no directed
generalization here, matching {help nwkcomponents}). Weighted: not used. Signed: not checked.
Two-mode: not checked. Computationally more expensive than a single {help nwkcomponents} call, since
each block found is itself recursively re-decomposed - fine for the moderate network sizes typical
of SNA datasets.

{title:See also}

	{help nwkcomponents}, {help nwcomponents}, {help nwclique}, {help nwkplex}

last certified : 22 Aug 2026
