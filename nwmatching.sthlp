{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_paths:[NW-2.6.6] Paths, flows and ego networks}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwmatching {hline 2}}Maximum-cardinality bipartite matching{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwmatching}
[{it:{help netname}}]
[{cmd:,}
{opth gen:erate(newvarname)}
{opt replace}
{opt silent}
{opt bin:ary}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth gen:erate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each mode-1 node's own matched mode-2 partner's node id (0 if unmatched){p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt bin:ary}}Ignore the tie values of a valued network (by default they are used){p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwmatching} finds a maximum-CARDINALITY matching on a two-mode network - the largest possible
set of ties such that no node (on either side) appears in more than one selected tie. Computed via
the standard reduction to maximum flow: a virtual source with a capacity-1 arc to every mode-1 node,
a virtual sink with a capacity-1 arc from every mode-2 node, capacity 1 on every existing tie, then
one max-flow call from source to sink (the same {help nwmaxflow} machinery this command builds on
internally) - the classical integrality theorem for unit-capacity flow networks guarantees this
finds an OPTIMAL (maximum-cardinality) matching directly, not merely a good one.

{pstd}
Requires a genuine two-mode network ({opt twomode}/{opt bipartite} in {help nwset}, or
{help nw2set}, {help nw2fromedge}) - the mode assignment already tells this command which side of
the bipartition each node is on, so no separate bipartiteness detection is needed (and a general,
non-bipartite graph's own maximum matching - Edmonds' 1965 blossom algorithm - is a materially
harder problem, not attempted here).

{pstd}
{opth gen:erate(newvarname)} is populated only on the MODE-1 side: a mode-1 node's own value is its
matched mode-2 partner's node id (0 if left unmatched by the optimal solution - this can happen
whenever the two sides have unequal size, or the bipartite graph's own structure has no perfect
matching); every mode-2 node's own value is always 0 - read the match off the mode-1 side only,
matching {help nw2project}'s own established "one side owns the report" convention for a two-mode
result.


{title:Network types}

{pstd}
{bf:Directed:} not applicable. {bf:Valued:} the matching of largest total tie value ({cmd:r(weight)}), which can have
fewer pairs; {opt binary} finds the matching with the most pairs. {bf:Two-mode:} yes - the command needs a two-mode
network and finds the largest matching between the modes. {bf:Signed:} negative values are not treated specially. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The maximum matching is computed on the sparse network (Edmonds-Karp with the same augmenting-path order as the Mata code, so
the same matching comes out) by a kernel of the native plugin; a platform without the plugin uses
the Mata code, which builds two (n+2)-by-(n+2) matrices. Measured in Stata/BE, random two-mode network with 5,000
mode-1 and 2,500 mode-2 nodes and 10 ties per mode-1 node: 0.7 seconds with the plugin kernel (the Mata code did not
finish in 180 seconds and used 4 GB).

{pstd}
The matching of largest total tie value (valued networks) is computed by the Hungarian method in a kernel of the native plugin, with the same
result as the Mata routine (the same matching also when several matchings have the same total value, up to 1,500 nodes in the larger
mode; beyond that a matching of the same total value). Measured: two modes of 300 nodes 0.013 seconds (Mata 0.33 seconds); 455 and 5,092 nodes
0.2 seconds, which the Mata routine cannot do (it needs a dense matrix of the larger mode squared).


{title:Examples}

	{cmd:. nwset person org, twomode name(assign)}
	{cmd:. nwmatching assign, generate(_match)}
	{cmd:. list person _match if _match > 0}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(matched)}}number of matched pairs found{p_end}
{synopt:{bf:r(weight)}}total tie value of the matching (valued network, not with {opt binary}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(matchvar)}}name of the generated match variable{p_end}


{title:References}

{pstd}
Hopcroft, J.E., Karp, R.M. (1973). An n^2.5 algorithm for maximum matchings in bipartite graphs.
{it:SIAM Journal on Computing} 2(4), 225-231.


{title:See also}

	{help nwmaxflow}, {help nw2project}, {help nw2set}, {help nw2fromedge}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
