{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

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
{it:_balance _baltriad _clotriad}{p_end}

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

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - a pair of nodes counts as tied for the purposes of triad closure when
{bf:either} direction has a tie; if both directions are tied (a mutual dyad), the value used for the
balance product is whichever direction is checked first ({it:i->j} before {it:j->i}), which matters
only when the two directions carry different signs. Weighted: yes - only the sign of each tie value is
used (see Description); magnitude does not affect the closed/balanced classification. Signed: this is
the command's whole purpose - see Description. Two-mode: not checked; structural balance is not a
meaningful concept for a bipartite network's own inherently unclosable triads.

{title:Stored results}

	Scalars
	  {bf:r(closed_triad)}		number of closed triads
	  {bf:r(balanced_triad)}	number of balanced closed triads
	  {bf:r(unbalanced_triad)}	number of unbalanced closed triads
	  {bf:r(balance)}		{it:balanced_triad} / {it:closed_triad}


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


{title:References}

{pstd}
Cartwright, D., Harary, F. (1956). Structural balance: a generalization of Heider's theory.
{it:Psychological Review} 63(5), 277-293.

{title:See also}

	{help nwtriads}, {help nwvalue}

last certified : 24 Aug 2026
