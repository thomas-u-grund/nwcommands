{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwfactions {hline 2}}Partition nodes into a specified number of cohesive factions{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwfactions}
[{it:{help netname}}]
[{cmd:,}
{opt groups(int)}
{opth generate(newvarname)}
{opt replace}
{opt measure(binary|valued)}
{opt maxiter(int)}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt groups(int)}}Number of factions to partition nodes into; must be between 2 and the number of nodes; default = 2{p_end}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's faction membership (1..{opt groups()}){p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether tie VALUES enter the fitness calculation, or only tie presence/absence; default follows whether the network itself is valued{p_end}
{synopt:{opt maxiter(int)}}Maximum number of full local-search sweeps; default 100{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwfactions} implements UCINET's own classical "factions" technique: partition the nodes into
exactly {opt groups()} groups so as to MAXIMIZE the correlation between the observed tie matrix and
the ideal "factions" block pattern (every pair of nodes in the SAME group is tied; every pair in
DIFFERENT groups is not). This is the assortative-block-model sibling of {help nwcoreperiphery} -
the same fitness-correlation idea, generalized from a fixed 2-group core/periphery split (where the
ideal pattern is "at least one endpoint is core") to an arbitrary number of symmetric,
equally-treated groups (where the ideal pattern is "both endpoints share a group").

{pstd}
Optimized via greedy local search, the same general shape {help nwcommunity}'s own Louvain
algorithm and {help nwcoreperiphery} both already use: seed by sorting nodes by degree (descending)
and assigning them to groups round-robin (spreading high- and low-degree nodes evenly across every
group, rather than an arbitrary block split), then repeatedly try moving each node (fixed 1..n
order, for reproducibility) to every OTHER group, keeping whichever single move most improves the
fitness correlation, until a full sweep produces no further improvement or {opt maxiter()} sweeps
are reached. This is a greedy local optimum, not a guaranteed global one - the discrete factions
problem is combinatorial, the same character of problem Louvain's own greedy search already accepts
for modularity.

{pstd}
{bf:Starting partition.} Nodes with the same degree are taken in the order of their node number, so the same call
always gives the same partition. (Earlier versions sorted with ties broken at random, which made the result differ
from run to run on any network with equal degrees.) The fitness of a candidate move is computed from the total tie
weight inside the groups and the number of same-group pairs, which takes time proportional to the node's degree plus
the number of groups, not to the square of the number of nodes; {cmd:r(fitness)} agrees with a direct computation of
the correlation to rounding error (about 1e-15).

{title:Two-mode networks}

{pstd}
Two-mode: not supported - error 6088; the factions of the square matrix would mix the two modes; make a one-mode network of one mode first with {help nwproject}.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (the classical factions definition does not
distinguish in-ties from out-ties, the same choice {help nwcoreperiphery} already makes). Weighted:
yes, via {opt measure(valued)} - tie VALUES then enter the fitness correlation directly rather than
just their presence/absence. Signed: not checked. Two-mode: not supported - error 6088; the factions of the square matrix would mix the two modes; make a one-mode network of one mode first with {help nwproject}.

{title:Limits}

{pstd}
Measured in Stata/BE on a random network with 10 ties drawn per node: 300 / 1,000 / 5,000 nodes with
{opt groups(3)} take 0.014 / 0.019 / 0.05 seconds (the previous version: 38 seconds at 300 nodes, more than 60
seconds at 1,000). The memory needed is proportional to the number of ties; no N-by-N matrix is built.

{title:Stored results}

	Scalars
	  {bf:r(fitness)}	correlation between the observed network and the ideal factions block pattern (1 = perfect fit)
	  {bf:r(groups)}	number of groups requested

	Macros
	  {bf:r(netgenerate)}	name of the generated faction-membership variable

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwfactions flomarriage, groups(3) generate(_faction)}
	{cmd:. tab _faction}

{title:References}

{pstd}
Borgatti, S.P., Everett, M.G., Freeman, L.C. (2002). {it:UCINET for Windows: Software for Social Network Analysis}. Analytic Technologies. (Factions routine)

{title:See also}

	{help nwcoreperiphery}, {help nwcommunity}, {help nwconcor}, {help nwlambda}

last certified : 31 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.10.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
