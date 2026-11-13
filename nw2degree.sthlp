{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nw2degree {hline 2}}Two-mode (bipartite) degree centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw2degree}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}
{opt alpha(#)}
{opt binary}
{opt raw}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores two-mode degree centrality{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt alpha(#)}}Weighted (tie-strength-aware) degree/strength blend, Opsahl et al. (2010); default = {it:1} (strength) for a valued network and {it:0} (number of ties) otherwise{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt raw}}The degree itself, not divided by the size of the other mode ({cmd:tnet::degree_tm}, {cmd:igraph::degree}){p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nw2degree} is the form of {help nwdegree} for a two-mode network: {cmd:nwdegree} uses it by default on a two-mode network (and {opt onemode} forces the one-mode degree). The two names give the
same result with the same options.

{pstd}
{cmd:nw2degree} calculates degree centrality for a two-mode (bipartite) network, using the
normalization of Borgatti and Everett (1997). A node's ordinary (raw) degree can only ever reach as
high as the size of the {it:other} mode - a mode-1 node can tie to at most every mode-2 node, never
to another mode-1 node - so {help nwdegree}'s usual {it:n - 1} normalization does not apply here.
Instead, each node's raw degree is divided by the size of the mode it does {it:not} belong to:

{pmore}
{it:C'D(i) = degree(i) / n_other}, where {it:n_other} is the number of nodes in the other mode

{pstd}
so that a mode-1 node tied to every mode-2 node (or vice versa) scores exactly 1, matching ordinary
degree centrality's own [0,1] range and interpretation.

{pstd}
{opt generate()} is required and names the new variable that holds this value for every
node, regardless of which mode it belongs to (mode membership itself is available via
{help nw2set}'s own mode-id variable, not duplicated here). With more than one network in the
{it:netlist}, the variables are named {it:newvarname}{bf:1}, {it:newvarname}{bf:2}, and so on.

{pstd}
{opt alpha(#)} generalizes the plain tie-count formula above to a weighted (tie-strength-aware)
variant, using the same Opsahl, Agneessens and Skvoretz (2010) blend {help nwdegree}'s own
{opt alpha()} already uses for one-mode degree:

{pmore}
{it:degree_alpha(i) = k_i * (s_i/k_i)^alpha}, then normalized by {it:n_other} exactly as above

{pstd}
where {it:k_i} is node {it:i}'s plain tie count and {it:s_i} is its tie-{it:value} sum (its
"strength"). {opt alpha(0)} (the default for a binary network) reduces this exactly to plain tie-count degree - the two
formulas agree bit-for-bit.
{opt alpha(1)} (the default for a valued network) gives pure normalized strength (tie-value sum / other-mode size), ignoring tie count
entirely. Values between 0 and 1 blend the two; values above 1 emphasize a few strong ties over many
weak ones, and negative values do the reverse. On a binary (unweighted) network every tie already
has value 1, so {it:s_i = k_i}, {opt alpha()} has no effect at any value, and the plain formula
always applies.


{title:Network types}

{pstd}
{bf:Directed:} not applicable. {bf:Valued:} the default is the strength divided by the size of the other mode;
{opt binary} or {cmd:alpha(0)} counts the ties, {opt alpha()} blends ties and values (Opsahl et al. 2010).
{bf:Two-mode:} yes - a node's degree divided by the size of the other mode (Borgatti and Everett 1997); {opt raw}
gives the count or strength itself. {bf:Signed:} negative values are not handled. See {help nwnetworktypes}.{p_end}


{title:Examples}

	{cmd:. nwclear}
	{cmd:. mata: net = (1,1\1,0\0,1)}
	{cmd:. nw2set, mat(net) name(mynet)}
	{cmd:. nw2degree mynet, generate(_2degree)}

{pstd}Weighted (strength-aware) variant, on a valued two-mode network:{p_end}

	{cmd:. nwclear}
	{cmd:. clear}
	{cmd:. input str10 person str10 org value}
	{cmd:. "A" "X" 2}
	{cmd:. "A" "Y" 4}
	{cmd:. "B" "Z" 6}
	{cmd:. end}
	{cmd:. nwset person org value, twomode name(affil)}
	{cmd:. nw2degree affil, generate(strength) alpha(1)}


{title:References}

{pstd}
Borgatti, S.P., Everett, M.G. (1997). Network analysis of 2-mode data. {it:Social Networks} 19(3),
243-269.

{pstd}
Opsahl, T., Agneessens, F., Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing
degree and shortest paths. {it:Social Networks} 32(3), 245-251.


{title:See also}

	{help nwdegree}, {help nw2set}, {help nw2project}, {help nw2clustering}

{hline}
{pstd}{it:nwcommands version 3.22.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
