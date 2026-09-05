{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

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
[{opth generate(newvarname)}
{opt replace}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt target(nodename)}}The node every hitting time is measured TO{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's own mean hitting time to {opt target()}; default = {it:_hitting}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

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

{title:Supported network types}

{pstd}
Binary: yes. Directed: not supported (a directed random walk's own hitting time is a well-defined
but materially different quantity - not attempted here; networks are treated as undirected).
Weighted: not checked - tie values are ignored (a random walker moves to each neighbor with EQUAL
probability). Signed: not checked. Two-mode: not checked. Requires every node to have at least one
tie - an isolate has no well-defined hitting time (there is no walk to take at all), and a
disconnected network component containing {opt target()} would give some nodes an undefined
(infinite) hitting time; both are rejected with a clear error rather than a silently wrong number.

{title:Stored results}

	Macros
	  {bf:r(target)}	the target node requested
	  {bf:r(generate)}	name of the generated hitting-time variable

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwrandomwalk flomarriage, target(medici)}
	{cmd:. gsort _hitting}
	{cmd:. list _name _hitting in 1/5}

{title:References}

{pstd}
Lovasz, L. (1993). Random walks on graphs: A survey. {it:Combinatorics, Paul Erdos is Eighty} 2(1), 1-46.

{title:See also}

	{help nwpagerank}, {help nwgeodesic}, {help nwkatz}, {help nwmaxflow}

last certified : 31 Aug 2026
