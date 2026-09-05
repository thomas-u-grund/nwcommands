{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nw2project {hline 2}}One-mode projection of a two-mode network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nw2project}
[{it:{help netname}}]
{cmd:,}
{opt project(1|2)}
[{opth name(newnetname)}
{opt stat(string)}
{opt xvars}
{opt replace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt project(1|2)}}Mode/level to collapse to{p_end}
{synopt:{opth name(newnetname)}}Name of the new one-mode network; default = {it:project}{p_end}
{synopt:{opt stat(min|max|minmax|sum|mean|count|binary|jaccard|cosine)}}How to combine tie values (or, for the last 4, how to score shared-neighbor structure directly); default = {it:minmax}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the new network{p_end}
{synopt:{opt replace}}Replace an existing network of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
Sometimes one wants to collapse a two-mode network to a one-mode network. This is called a one-mode
projection. Such a projection is a simplification of the network to nodes of one level only. The level
to which one wants to collapse is specified in option {bf:project()}.

{pstd}
For example, this loads a two-mode network and projects it onto level 1:

	{cmd:. nw2project mynet, project(1) name(myproject1)}

{pstd}
By default, a one-mode projection on one level generates ties between nodes (on this level) when they
have at least one network neighbor on the other level in common.

{pstd}
When the source network is {bf:unvalued}, the tie value in the projection is simply the number of
shared neighbors on the other level (e.g. the number of institutions two people share).

{pstd}
When the source network is {bf:valued}, option {bf:stat()} controls how the tie values of the two
original ties (ego-to-shared-neighbor and alter-to-shared-neighbor) are combined, for every shared
neighbor, into a single projected tie value:

{p 8 12 2}{bf:stat(min)}{p_end}
{p 12 12 2}the overall minimum across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(max)}{p_end}
{p 12 12 2}the overall maximum across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(sum)}{p_end}
{p 12 12 2}the sum across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(mean)}{p_end}
{p 12 12 2}the mean across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(minmax)} (default){p_end}
{p 12 12 2}for each shared neighbor, take the minimum of the ego/alter tie values to that
neighbor, then take the maximum of those minima across all shared neighbors -
substantively, the strongest shared bond{p_end}

{pstd}
The remaining four options score the {bf:shared-neighbor structure itself} rather than
combining tie values - they are defined the same way regardless of whether the source
network is valued, and are available for a valued source network too (unlike the five
above, which require one):

{p 8 12 2}{bf:stat(count)}{p_end}
{p 12 12 2}the number of shared neighbors - identical to the default behaviour on an
unvalued source network, but now requestable explicitly on a valued one too, ignoring
tie strength entirely{p_end}
{p 8 12 2}{bf:stat(binary)}{p_end}
{p 12 12 2}1 whenever at least one shared neighbor exists, 0 (no tie) otherwise - a
plain co-affiliation indicator{p_end}
{p 8 12 2}{bf:stat(jaccard)}{p_end}
{p 12 12 2}the Jaccard similarity of the two nodes' neighbor sets: shared neighbors
divided by the size of the union of their neighbor sets{p_end}
{p 8 12 2}{bf:stat(cosine)}{p_end}
{p 12 12 2}the cosine similarity of the two nodes' neighbor sets: shared neighbors
divided by the geometric mean of their two degrees{p_end}

{pstd}
For example, suppose Peter and Thomas are both affiliated with Oxford (Peter: 7 years, Thomas: 5
years) and LiU (Peter: 1 year, Thomas: 1 year). Then:

		{c TLC}{hline 12}{c -}{hline 8}{c TRC}
		{c |} stat      {c |} value  {c |}
		{c LT}{hline 12}{c -}{hline 8}{c RT}
		{c |} min       {c |}   1    {c |}
		{c |} max       {c |}   7    {c |}
		{c |} sum       {c |}  14    {c |}
		{c |} mean      {c |} 3.5    {c |}
		{c |} minmax    {c |}   5    {c |}
		{c BLC}{hline 12}{c -}{hline 8}{c BRC}

{pstd}
The projected network's provenance (which network and mode it was projected from, and with
which {opt stat()}) is recorded on the new network itself, not just printed - see
{bf:r(provenance)} via {help netname:nwname}, and {help nwsummarize}, which displays it.

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes in the projected network
	  {bf:r(ties)}		number of ties in the projected network


{title:Supported network types}

{pstd}
Binary: yes. Directed: not checked - the source two-mode network's ties are treated as undirected
affiliations. Weighted: {bf:W1}, native - an unvalued source network projects to a shared-neighbor
{it:count} (the standard bipartite-projection tie weight); a valued source network projects using
{opt stat()}'s explicit choice of combination rule (see above) - tie strength is never silently
discarded or reinterpreted as a distance. Signed: not checked. Two-mode: {bf:T3} - this command's
entire purpose is projecting a two-mode network down to one mode, so the projection is always
explicit and user-requested (via {opt project()}), never a silent side effect of some other
operation - the canonical, correct way to project in this package.


{title:See also}

	{help nwproject} (an exact alias for this command), {help nw2set}, {help nw2fromedge}, {help nw2toedge}, {help nw2clustering}

last certified : 28 Aug 2026
