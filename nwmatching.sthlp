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
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each mode-1 node's own matched mode-2 partner's node id (0 if unmatched){p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

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

{title:Supported network types}

{pstd}
Binary: yes (only) - matching is a presence/absence structure; tie values are ignored. Directed:
not applicable (a two-mode affiliation tie has no meaningful direction). Weighted: not applicable -
see {help nwmaxflow} directly if a WEIGHTED assignment problem (maximum total value, not maximum
count) is actually what is needed; that is a different, harder problem (not this command). Signed:
not checked. Two-mode: required.

{title:Stored results}

	Scalars
	  {bf:r(matched)}	number of matched pairs found

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

{title:See also}

	{help nwmaxflow}, {help nw2project}, {help nw2set}, {help nw2fromedge}

last certified : 31 Aug 2026
