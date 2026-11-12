{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_paths:[NW-2.6.6] Paths, flows and ego networks}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwrandomwalk {hline 2}}Mean random-walk hitting time to a target node{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwrandomwalk}
[{it:{help netname}}]
{cmd:,}
{opt target(nodename)}
{opth gen:erate(newvarname)}
[{opt replace}
{opt silent}
{opt bin:ary}
{opt one:mode}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt target(nodename)}}The node every hitting time is measured TO{p_end}
{synopt:{opth gen:erate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's own mean hitting time to {opt target()}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt bin:ary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt one:mode}}Two-mode network: read the bipartite graph as a one-mode graph (a two-mode network is refused without it, error 6088){p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwrandomwalk} computes the mean hitting time from every node to {opt target()}: the EXPECTED
number of steps a simple random walk (at each step, move to a uniformly-random NEIGHBOR of the
current node) starting at that node takes to first reach {opt target()}. {opt target()} itself
always gets 0.

{pstd}
A classical random-walk characterization of network structure, closely related to effective
resistance/commute time in the electrical-network analogy of a graph, and genuinely different from
ordinary geodesic distance ({help nwgeodesic}): an unweighted random walk routinely takes far more
steps than the shortest path, especially through a low-degree "bottleneck" node it is unlikely to
choose directly - the whole reason hitting time is its own separate, informative quantity rather
than just a scaled version of geodesic distance.

{pstd}
Solved EXACTLY via the standard linear system this quantity satisfies (not simulated, and not
subject to any Monte Carlo noise): for every node i other than the target, its own hitting time
equals 1 plus the average of its own neighbors' hitting times; the target's own hitting time is
fixed at 0. The same "solve directly, do not simulate" discipline {help nwkatz}'s own walk-counting
Katz centrality already established for an analogous exact random-walk quantity.


{title:Network types}

{pstd}
{bf:Directed:} the network is symmetrized. {bf:Valued:} the walk steps with probability w_ij / s_i by default;
{opt binary} ignores the values. {bf:Two-mode:} not supported (error 6088); {opt onemode} uses the bipartite graph
read as a one-mode network. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Up to 1,500 nodes the hitting times come from the dense linear system (LU decomposition). Above that the system, which is
symmetric and positive definite for the walk on the symmetrized network, is solved by conjugate gradients on the stored ties
(relative residual 1e-13; the result agrees with the dense solution to better than 1e-13 relative, and the dense route
is still the fallback if the iteration does not converge). Measured in Stata/BE, random directed network with 10 ties per
node: 10,000 nodes 0.15 seconds and 0.2 GB (65 seconds and 4 GB with the dense solution).


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwrandomwalk flomarriage, target(medici) generate(_hitting)}
	{cmd:. gsort _hitting}
	{cmd:. list _name _hitting in 1/5}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(target)}}the target node requested{p_end}
{synopt:{bf:r(generate)}}name of the generated hitting-time variable{p_end}


{title:References}

{pstd}
Lovasz, L. (1993). Random walks on graphs: A survey. {it:Combinatorics, Paul Erdos is Eighty} 2(1), 1-46.


{title:See also}

	{help nwpagerank}, {help nwgeodesic}, {help nwkatz}, {help nwmaxflow}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
