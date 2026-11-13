{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_clustering:[NW-2.6.5] Clustering, mixing and balance}

{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nwbalance {hline 2}}Structural balance of a signed network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwbalance}
[{it:{help netname}}]
[{cmd:,}
{opt generate(namelist)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate(namelist)}}Up to 3 names, for the per-node balance ratio, count of balanced
triads, and count of closed triads a node belongs to; default =
{it:_balance _baltriad _clotriad}; existing variables of these names are replaced{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwbalance} evaluates a {help netname:network}'s ties as signed (positive/negative) and tests
every closed triad against Cartwright and Harary's (1956) strong structural balance criterion: a
closed triad is {it:balanced} when the product of its three tie values is positive - equivalently,
when it contains an even number (0 or 2) of negative ties ("the friend of my friend is my friend";
"the enemy of my enemy is my friend"). A triad with an odd number (1 or 3) of negative ties is
{it:unbalanced}.

{pstd}
Ties do not need to be declared {help nwvalue:signed} in any special way - any tie with a negative
value is treated as negative, any positive value as positive.

{pstd}
For each node, {cmd:nwbalance} generates the number of closed triads it belongs to, the number of
those that are balanced, and the ratio of the two. Network-level counts and the overall balance
ratio are returned in {help return:r()}.


{title:Network types}

{pstd}
{bf:Directed:} a pair counts as tied when either direction has a tie; for a mutual dyad the sign of i->j is used.
{bf:Valued:} only the sign of each value is used. {bf:Two-mode:} same as for the bipartite graph read as a one-mode
network (no triangles: counts 0, balance missing). {bf:Signed:} the purpose of the command. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Closed triads are found from the stored ties (for every tied pair, the common neighbours), not by probing every pair of
nodes. The enumeration is a kernel of the native plugin; a platform whose plugin does not have it uses
Mata code, with the same results. Measured in Stata/BE, random valued network with 10 ties per
node: 5,000 nodes 0.03 seconds with the plugin kernel (71 seconds with the Mata code).


{title:Examples}

	{cmd:. nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) undirected labs(A,B,C,D)}
	{cmd:. nwbalance}

	{res}{hline 40}
	{txt}  Network name: {res}network
	{txt}{hline 40}
	{txt}    Closed triad: {res}4
	{txt}    Balanced triad: {res}2
	{txt}    Unbalanced triad: {res}2

{pstd}
Of the 4 triads in this network, {it:A-B-C} (all positive) and {it:A-B-D} (two negative ties) are
balanced; {it:A-C-D} and {it:B-C-D} (one negative tie each) are not.


{title:Stored results}

{synoptset 21 tabbed}{...}
{p2col 5 21 25 2: Scalars}{p_end}
{synopt:{bf:r(closed_triad)}}number of closed triads{p_end}
{synopt:{bf:r(balanced_triad)}}number of balanced closed triads{p_end}
{synopt:{bf:r(unbalanced_triad)}}number of unbalanced closed triads{p_end}
{synopt:{bf:r(balance)}}{it:balanced_triad} / {it:closed_triad}{p_end}


{title:References}

{pstd}
Cartwright, D., Harary, F. (1956). Structural balance: a generalization of Heider's theory.
{it:Psychological Review} 63(5), 277-293.


{title:See also}

	{help nwtriads}, {help nwvalue}

{hline}
{pstd}{it:nwcommands version 3.22.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
