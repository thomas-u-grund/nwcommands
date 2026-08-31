{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwmaxflow {hline 2}}Maximum flow and minimum cut between two nodes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmaxflow}
[{it:{help netname}}]
{cmd:,}
{opt source(nodename)}
{opt sink(nodename)}
[{opt weighted}
{opth generate(newvarname)}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt source(nodename)}}The flow's own origin node{p_end}
{synopt:{opt sink(nodename)}}The flow's own destination node{p_end}
{synopt:{opt weighted}}Use tie VALUES as edge capacities instead of a uniform capacity of 1 per tie{p_end}
{synopt:{opth generate(newvarname)}}Save a 0/1 variable marking which nodes are on the SOURCE side of the minimum cut{p_end}
{synopt:{opt replace}}Replace an existing variable of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwmaxflow} computes the maximum flow (and, by the max-flow/min-cut theorem, the minimum edge
cut) between {opt source()} and {opt sink()} via the standard Edmonds-Karp augmenting-path
algorithm - the same generic max-flow primitive this package's own {help nwlambda} (pairwise edge
connectivity) and {help nwkcomponents} (vertex connectivity, via a node-splitting reduction) already
build on internally. By default every existing tie has capacity 1, regardless of its own tie value
(so max-flow reduces to counting edge-disjoint paths - the same quantity {help nwlambda} computes
for every pair at once). With {opt weighted}, tie VALUES are used as capacities instead - useful
when a network's own tie strength genuinely represents a throughput/capacity (e.g. trade volume,
bandwidth, transaction size).

{pstd}
{opth generate(newvarname)} marks which nodes remain reachable from {opt source()} in the FINAL
residual graph once the flow has converged - the standard max-flow/min-cut construction. Every
existing tie from a marked (1) node to an unmarked (0) node is one of the edges in the minimum cut;
{cmd:r(cutedges)} reports how many such edges exist, without requiring {opt generate()} to be given
just to see the count.

{pstd}
For a DIRECTED network, capacities are directional (a tie A->B only lets flow move A to B, matching
the underlying idea that a directed relation only "carries" one way); an undirected network's own
symmetric tie matrix already represents capacity in both directions naturally, needing no special
handling.

{title:Supported network types}

{pstd}
Binary: yes (capacity 1 per tie, the default). Directed: yes - respects the network's own actual
directedness (unlike {help nwlambda}, which always symmetrizes first; a flow network is inherently
a directed concept). Weighted: yes, via {opt weighted}. Signed: not checked - a negative capacity
has no meaning here. Two-mode: not checked (see {help nwmatching} for the two-mode/bipartite
analog - maximum matching, not maximum flow).

{title:Stored results}

	Scalars
	  {bf:r(maxflow)}	the maximum flow value
	  {bf:r(cutedges)}	number of edges in the minimum cut

	Macros
	  {bf:r(source)}	the source node requested
	  {bf:r(sink)}		the sink node requested

{title:Examples}

	{cmd:. nwset, mat((0,2,1,0\0,0,1,1\0,0,0,2\0,0,0,0)) name(flownet) directed valued labs(A,B,C,D)}
	{cmd:. nwmaxflow flownet, source(A) sink(D) weighted generate(cutside)}
	{cmd:. nwmaxflow flownet, source(A) sink(D)}

{title:References}

{pstd}
Ford, L.R., Fulkerson, D.R. (1956). Maximal flow through a network. {it:Canadian Journal of Mathematics} 8, 399-404.

{pstd}
Edmonds, J., Karp, R.M. (1972). Theoretical improvements in algorithmic efficiency for network flow
problems. {it:Journal of the ACM} 19(2), 248-264.

{title:See also}

	{help nwmatching}, {help nwlambda}, {help nwkcomponents}, {help nwbridges}

last certified : 31 Aug 2026
