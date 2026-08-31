{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_centrality:[NW-2.6.1] Centrality}

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
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's PageRank score; default = {it:_pagerank}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt damping(real)}}Probability of following a tie rather than jumping to a uniformly-random node; must be strictly between 0 and 1; default = 0.85 (Page and Brin's own original value){p_end}
{synopt:{opt maxiter(int)}}Maximum power-iteration sweeps; default 1000{p_end}
{synopt:{opt tol(real)}}Convergence tolerance; default 1e-10{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

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

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - the natural case (a random surfer follows ties in their own real
direction); an undirected network is handled identically, since its own symmetric tie matrix
already represents "can move either way" directly. Weighted: not checked - tie values are ignored
(a random surfer moves to each out-neighbor with EQUAL probability, matching the classical
definition; a value-weighted variant is not implemented). Signed: not checked. Two-mode: not
checked.

{title:Stored results}

	Macros
	  {bf:r(generate)}	name of the generated PageRank variable

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwpagerank flomarriage}
	{cmd:. gsort -_pagerank}
	{cmd:. list _name _pagerank in 1/5}

{title:References}

{pstd}
Page, L., Brin, S., Motwani, R., Winograd, T. (1998). The PageRank Citation Ranking: Bringing Order to the Web. Stanford InfoLab Technical Report.

{title:See also}

	{help nwevcent}, {help nwrandomwalk}, {help nwbetween}, {help nwcloseness}

last certified : 31 Aug 2026
