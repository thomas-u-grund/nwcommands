{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwpagerank {hline 2}}PageRank centrality{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwpagerank}
[{it:{help netname}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt damping(real)}
{opt maxiter(int)}
{opt tol(real)}
{opt silent}
{opt binary}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's PageRank score{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt damping(real)}}Probability of following a tie rather than jumping to a uniformly-random node; must be strictly between 0 and 1; default = 0.85 (Page and Brin's own original value){p_end}
{synopt:{opt maxiter(int)}}Maximum power-iteration sweeps; default 1000{p_end}
{synopt:{opt tol(real)}}Convergence tolerance; default 1e-10{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwpagerank} computes Page and Brin's (1998) PageRank centrality: the stationary distribution
of a "random surfer" who, at each step, either follows a uniformly-random OUTGOING tie from the
current node (with probability {opt damping()}) or jumps to a uniformly-random node anywhere in the
network (with probability 1 - {opt damping()}). Every node's own score is the long-run PROPORTION
of time the surfer spends there - the {opt generate()} variable always sums to exactly 1 across all
nodes.

{pstd}
Genuinely different from {help nwevcent} (this package's own existing eigenvector centrality):
PageRank works directly on DIRECTED networks with no symmetrization, has no scale ambiguity (the
damping term guarantees a unique stationary distribution even on a network eigenvector centrality
would otherwise reject as not strongly connected - see that command's own documented limitation),
and explicitly handles "dangling" nodes (zero out-degree): a real random surfer stranded there
cannot follow any tie, so PageRank's own construction redistributes that node's own probability
mass UNIFORMLY across every node in the network on the next step (Page and Brin's own original
fix, not an approximation) - {opt generate()}'s own values still sum to exactly 1 even when such
nodes exist.

{pstd}
Computed via sparse power iteration - no dense n x n matrix is ever materialized, matching the same
scalability discipline this package's own sparse-backend commands ({help nwkcore},
{help nwevcent}) already follow.

{title:Valued networks}

{pstd}
A network is valued when it was created with tie values ({help nwfromedge} with a value variable, an import or a matrix with values, {cmd:nwset, valued}); the flag is shown by {help nwsummarize} and explained in {help nwnetworktypes}. On a valued network the random surfer follows the tie from i to j with probability w_ij / s_i, s_i the out-strength ({it:igraph::page_rank} with its weight attribute); {opt binary} follows a uniformly chosen tie. Both walks run in the native kernel when your platform's plugin has it.
On a network that is not valued the result is the same as in earlier releases and {opt binary} has no effect.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - the natural case (a random surfer follows ties in their own real
direction); an undirected network is handled identically, since its own symmetric tie matrix
already represents "can move either way" directly. Weighted: not checked - tie values are ignored
(a random surfer moves to each out-neighbor with EQUAL probability, matching the classical
definition; a value-weighted variant is not implemented). Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation).

{title:Limits}

{pstd}
The power iteration runs in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your platform has it,
and in Mata otherwise; both give the same scores (to the last digits). The work is the number of ties times the number of iterations.
Measured in Stata/BE, random directed network with 10 ties per node: 5,000 nodes 0.03 seconds, 20,000 nodes 0.1 seconds, 100,000 nodes
0.3 seconds (the Mata route needs 0.12, 0.43 and 1.9 seconds). The weighted walk is about twice as fast as its Mata route (10,000 nodes with 30,000 ties: 0.05 against 0.09 seconds).
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:Stored results}

	Macros
	  {bf:r(generate)}	name of the generated PageRank variable

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwpagerank flomarriage, generate(_pagerank)}
	{cmd:. gsort -_pagerank}
	{cmd:. list _name _pagerank in 1/5}

{title:References}

{pstd}
Page, L., Brin, S., Motwani, R., Winograd, T. (1998). The PageRank Citation Ranking: Bringing Order to the Web. Stanford InfoLab Technical Report.

{title:See also}

	{help nwevcent}, {help nwrandomwalk}, {help nwbetween}, {help nwcloseness}

last certified : 31 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.9.2, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
