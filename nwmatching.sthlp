{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwmatching {hline 2}}Maximum-cardinality bipartite matching{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmatching}
[{it:{help netname}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}
{opt binary}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each mode-1 node's own matched mode-2 partner's node id (0 if unmatched){p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}

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
{opth generate(newvarname)} is populated only on the MODE-1 side: a mode-1 node's own value is its
matched mode-2 partner's node id (0 if left unmatched by the optimal solution - this can happen
whenever the two sides have unequal size, or the bipartite graph's own structure has no perfect
matching); every mode-2 node's own value is always 0 - read the match off the mode-1 side only,
matching {help nw2project}'s own established "one side owns the report" convention for a two-mode
result.

{title:Valued networks}

{pstd}
A network is valued when it was created with tie values ({help nwfromedge} with a value variable, an import or a matrix with values, {cmd:nwset, valued}); the flag is shown by {help nwsummarize} and explained in {help nwnetworktypes}. On a valued network the matching is the one of largest total tie value ({it:igraph::max_bipartite_match} with its weight attribute), which can have fewer pairs than the largest matching; {cmd:r(weight)} is the total value. {opt binary} finds the matching with the most pairs.
On a network that is not valued the result is the same as in earlier releases and {opt binary} has no effect.

{title:Two-mode networks}

{pstd}
Two-mode: yes - the command needs a two-mode network and finds the largest matching between the two modes ({cmd:igraph::max_bipartite_match}).

{title:Supported network types}

{pstd}
Binary: yes (only) - matching is a presence/absence structure; tie values are ignored. Directed:
not applicable (a two-mode affiliation tie has no meaningful direction). Weighted: not applicable -
see {help nwmaxflow} directly if a WEIGHTED assignment problem (maximum total value, not maximum
count) is actually what is needed; that is a different, harder problem (not this command). Signed:
not checked. Two-mode: yes - the command needs a two-mode network and finds the largest matching between the two modes ({cmd:igraph::max_bipartite_match}).

{title:Stored results}

	Scalars
	  {bf:r(matched)}	number of matched pairs found
	  {bf:r(weight)}	total tie value of the matching (valued network, not with {opt binary})

	Macros
	  {bf:r(matchvar)}	name of the generated match variable

{title:Examples}

	{cmd:. nwset person org, twomode name(assign)}
	{cmd:. nwmatching assign, generate(_match)}
	{cmd:. list person _match if _match > 0}

{title:References}

{pstd}
Hopcroft, J.E., Karp, R.M. (1973). An n^2.5 algorithm for maximum matchings in bipartite graphs.
{it:SIAM Journal on Computing} 2(4), 225-231.

{title:Limits}

{pstd}
The maximum matching is computed on the sparse network (Edmonds-Karp with the same augmenting-path order as before, so
the same matching comes out) by a kernel of the native plugin; a platform whose plugin has not been rebuilt yet keeps
the older Mata code, which builds two (n+2)-by-(n+2) matrices. Measured in Stata/BE, random two-mode network with 5,000
mode-1 and 2,500 mode-2 nodes and 10 ties per mode-1 node: 0.7 seconds with the plugin kernel (the older code did not
finish in 180 seconds and used 4 GB).

{pstd}
The matching of largest total tie value (valued networks) is computed by the Hungarian method in a kernel of the native plugin, with the same
result as the Mata routine (the same matching also when several matchings have the same total value, up to 1,500 nodes in the larger
mode; beyond that a matching of the same total value). Measured: two modes of 300 nodes 0.013 seconds (Mata 0.33 seconds); 455 and 5,092 nodes
0.2 seconds, which the Mata routine cannot do (it needs a dense matrix of the larger mode squared).

{title:See also}

	{help nwmaxflow}, {help nw2project}, {help nw2set}, {help nw2fromedge}

last certified : 31 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.7.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
