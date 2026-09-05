{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwconcor {hline 2}}CONCOR structural-equivalence blockmodel{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwconcor}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opth splits(int)}
{opt measure(string)}
{opth maxiter(int)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores block membership; default = {it:_concor}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth splits(int)}}Number of recursive bisections; final number of blocks is up to 2^{it:splits}; default = 1{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opth maxiter(int)}}Maximum number of correlation iterations per split before giving up on convergence; default = 25{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwconcor} partitions the nodes of a network into structurally equivalent blocks using CONCOR
(CONvergence of iterated CORrelations - Breiger, Boorman and Arabie 1975). Each node's tie profile
(its outgoing ties stacked on its incoming ties, excluding the tie to itself) is correlated against
every other node's profile; this correlation matrix is then repeatedly re-correlated with itself.
For well-separated block structure this process converges to a matrix of exactly +1/-1 entries, from
which nodes are split into two groups based on the sign of their correlation with a reference node.
Unlike methods that require an undirected network (e.g. {help nwcommunity}), CONCOR is defined
directly for directed data, since a node's profile already keeps its outgoing and incoming ties
separate.

{pstd}
With {opt splits(1)} (the default) {cmd:nwconcor} performs a single bisection, producing 2 blocks.
With {opt splits(k)}, each resulting block from the previous level is independently re-split using
only the ties among its own members, producing up to 2^{it:k} blocks in total - this is the
classical recursive CONCOR procedure, not merely applying a single bisection {it:k} times to the
whole network. A block that cannot be split further (all of its members end up on the same side of
its own bisection, or all of its members only tie to nodes {it:outside} the block, leaving no
internal structure to split on) simply stays as one block rather than being forced apart -
{cmd:nwconcor} may therefore return fewer than 2^{it:splits} blocks; {bf:r(blocks)} always reports
the actual number found.

{pstd}
By default, {cmd:nwconcor} generates a new variable {it:_concor} which stores, for each node, the id
of the block it was assigned to.

{pstd}
A node with no ties at all (in any direction) has no tie profile to compare against anyone else's,
so {cmd:nwconcor} requires every node to have at least one tie; remove isolates first (see
{help nwdropnodes}) if your network has any.

{title:Stored results}

	Scalars
	  {bf:r(blocks)}		number of blocks actually found (up to 2^{it:splits})

	Matrices
	  {bf:r(block_sizeid)}		distribution over blocks

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. * pucci is an isolate in this network - CONCOR requires every node to have a tie}
	{cmd:. nwdropnodes flomarriage, nodes(pucci) generate(flomarriage2)}
	{cmd:. nwconcor flomarriage2}

	{cmd:. nwconcor flomarriage2, splits(2) replace}


{title:References}

{pstd}
Breiger, R.L., Boorman, S.A., Arabie, P. (1975). An algorithm for clustering relational data with
applications to social network analysis and comparison with multidimensional scaling. {it:Journal of Mathematical Psychology} 12(3), 328-383.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - CONCOR is defined directly for directed data (a node's profile stacks
its outgoing and incoming ties separately), unlike {help nwcommunity}, which requires
{bf:symmetrize} for a directed network. Weighted: {opt measure(valued)} uses tie weights directly in
the profile; {opt measure(binary)} uses presence/absence only; default follows the network's own
weighted-ness, matching {help nwcommunity}'s convention. Signed: not checked - a negative tie
weight participates in the profile and correlation arithmetic like any other value, but no dedicated
signed-network semantics exist. Two-mode: not checked - operates on the network's own square
adjacency matrix. Isolates (nodes with no tie in any direction) are rejected explicitly with a clear
error, not silently mishandled - see Description.

{title:See also}

	{help nwsimilar}, {help nwdissimilar}, {help nwhierarchy}, {help nwcommunity}

