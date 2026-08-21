{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nw2project {hline 2} One-mode projection of a two-mode network}
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
{synopt:{opt stat(min|max|minmax|sum|mean)}}How to combine tie values on a valued two-mode network; default = {it:minmax}{p_end}
{synopt:{opt xvars}}Do not generate Stata variables for the new network{p_end}
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

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes in the projected network
	  {bf:r(ties)}		number of ties in the projected network


{title:See also}

	{help nw2set}, {help nw2fromedge}, {help nw2toedge}, {help nw2clustering}

last certified : 21 Aug 2026
