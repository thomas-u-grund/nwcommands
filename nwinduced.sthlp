{smcl}
{* *! version 1.0.0  02sep2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwinduced {hline 2}}Induced, endogenous and exogenous centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwinduced}
[{it:{help netname}}]
{cmd:,}
{opt measure(string)}
[{opth gen:erate(stub)}
{opt replace}
{opt silent}
{opt bin:ary}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt measure(string)}}Underlying centrality measure: one of {bf:degree}, {bf:betweenness}, {bf:closeness}, {bf:evcent}{p_end}
{synopt:{opth gen:erate(stub)}}{bf:Required.} Prefix for the three output variables ({it:stub}{bf:_endog}, {it:stub}{bf:_induced}, {it:stub}{bf:_exog}){p_end}
{synopt:{opt replace}}Replace existing variables{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt bin:ary}}Ignore the tie values of a valued network (by default they are used){p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwinduced} computes Everett and Borgatti's (2010) three-part decomposition of node centrality,
built on top of any of this package's own existing per-node centrality measures rather than being a
single new formula of its own. Given a chosen measure {it:C} (e.g. degree, betweenness) and network
{it:G}:

{phang2}
{bf:Endogenous centrality} of node {it:v}: {it:C_G(v)} itself - the node's ordinary centrality
score, exactly as {help nwdegree} / {help nwbetween} / {help nwcloseness} / {help nwevcent} would already
report it. Not a new computation; the existing measure, relabeled under this framework.{p_end}

{phang2}
{bf:Induced centrality} of node {it:v}: {it:sum_i C_G(i) - sum_i C_(G-v)(i)} - the total drop in
EVERYONE's summed {it:C}-score when {it:v} is removed from the network ({it:G-v}: the network with
{it:v} and its own ties deleted). Combines both {it:v}'s own direct contribution (its score, which
vanishes on removal) and every indirect ripple effect on everyone else's score.{p_end}

{phang2}
{bf:Exogenous centrality} of node {it:v}: {it:Induced(v) - Endogenous(v)} - the purely indirect
part: how much {it:v}'s presence props up OTHER nodes' centrality, isolated from {it:v}'s own
standing.{p_end}

{pstd}
A useful free sanity check, not specific to any one network: with {opt measure(degree)}, induced
centrality reduces to EXACTLY twice plain degree, and exogenous centrality reduces to exactly plain
degree again, for {it:any} undirected network - because removing a node removes exactly its own
degree's worth of edges, each of which contributed 2 to the total degree sum. This holds as an
identity, not merely on a hand-picked example (see {help nwinduced##example:Examples} below).

{pstd}
The real computational cost is the leave-one-out reconstruction: computing induced centrality for
every node requires recomputing {it:C} on {it:n} separate {it:n-1}-node subgraphs, one per removed
node. For a cheap measure ({bf:degree}) this is trivial; for an expensive one ({bf:betweenness}, on
a large network) this means {it:n} full recomputations of an already-expensive measure - worth
being aware of before running this against a large network with {opt measure(betweenness)}.


{title:Network types}

{pstd}
{bf:Directed:} {opt betweenness}, {opt closeness} and {opt evcent} use directions; {cmd:measure(degree)} stops with an
error. {bf:Valued:} {opt betweenness}, {opt closeness} and {opt evcent} use the tie values, as the commands do;
{opt degree} counts ties; {opt binary} ignores the values. {bf:Two-mode:} not supported (error 6088; use
{help nwproject} first). {bf:Signed:} as in the chosen measure. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
{bf:measure(degree)} has a closed form - removing a node takes away its own degree and one tie from each neighbour -
so the induced value is twice the node's number of ties, computed without any loop (300 / 1,000 / 5,000 nodes:
0.02 / 0.03 / 0.09 seconds). The other measures have
no such shortcut: the measure is recomputed on the network without each node in turn, so the time is the number
of nodes times the time of the measure itself. Measured in Stata/BE on a random network with 10 ties drawn per node:
{bf:betweenness} 1.2 / 2.1 / 4.8 seconds at 50 / 100 / 200 nodes, {bf:closeness} 2.8 / 20 / 8 seconds (the time of
{help nwcloseness} depends on the network), {bf:evcent} 6 seconds at 50 and 26 seconds at 100 nodes; plan for
minutes at a few hundred nodes.


{marker example}{...}
{title:Examples}

	{cmd:. nwclear}
	{cmd:. nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)}
	{cmd:. nwinduced starnet, measure(degree) generate(_induced)}

{pstd}A hub (A, degree 3) and three leaves (B/C/D, degree 1) - endogenous exactly reproduces plain
degree; induced is exactly twice that (6 for A, 2 for each leaf); exogenous equals endogenous
again (3 for A, 1 for each leaf) - the free identity described above, verified here on a concrete
example.{p_end}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwinduced flobusiness, measure(betweenness) generate(bw)}

{pstd}Which Florentine family props up OTHERS' betweenness the most, independent of its own
standing? - the {bf:bw_exog} column answers that, distinct from {bf:bw_endog} (the family's own
plain betweenness score).{p_end}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(measure)}}the underlying measure used{p_end}
{synopt:{bf:r(name)}}name of the network{p_end}
{synopt:{bf:r(endogenous)}}name of the endogenous-centrality variable{p_end}
{synopt:{bf:r(induced)}}name of the induced-centrality variable{p_end}
{synopt:{bf:r(exogenous)}}name of the exogenous-centrality variable{p_end}


{title:References}

{pstd}
Everett, M.G., Borgatti, S.P. (2010). Induced, endogenous and exogenous centrality. {it:Social}
{it:Networks} 32(4), 339-344.


{title:See also}

	{help nwdegree}, {help nwbetween}, {help nwcloseness}, {help nwevcent}, {help nwneighbor}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
