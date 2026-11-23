{smcl}
{* *! version 1.1.0  21nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, roles and similarity}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcoreperiphery {hline 2}}Discrete core-periphery detection{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwcoreperiphery}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt measure(string)}
{opth maxiter(int)}
{opt rest:arts(#)}
{opt seed(#)}
{opt sym}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sym}}On a directed network, analyse the symmetrized network (a tie counts in both directions, with the larger of its two values); without it a directed network with unreciprocated ties is refused (error 198){p_end}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores core membership{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opth maxiter(int)}}Maximum number of local-search sweeps before giving up on convergence; default = 100{p_end}
{synopt:{opt rest:arts(#)}}Number of starts of the local search; default = 1 (the degree-based start only); with more, further searches begin from random partitions and the partition with the highest fitness is kept{p_end}
{synopt:{opt seed(#)}}Random-number seed for the random starts; needs {opt restarts()} of 2 or more{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwcoreperiphery} partitions the nodes of a network into a "core" and a "periphery" using the
discrete core-periphery model (Borgatti and Everett 1999). The core-periphery model assumes ties are
expected between any pair of nodes where at least one is a core member (core-core and core-periphery
ties are both structurally expected), while periphery-periphery ties are not expected at all.
{cmd:nwcoreperiphery} searches for the 0/1 assignment (0 = periphery, 1 = core) whose implied pattern
correlates as highly as possible with the network actually observed, starting from a degree-based
seed and then repeatedly trying to flip each node's status in turn, keeping any flip that improves
the correlation, until a full sweep produces no further improvement. This is a greedy local search,
not an exhaustive search over all 2^n possible partitions, so it can settle on a good but not
necessarily globally optimal partition (a different starting partition can give a better core) - the same character of algorithm {help nwcommunity} already
uses for modularity maximization. The search is local: it starts from the degree-based partition and the result depends on that start. With
{opt restarts(#)} of 2 or more, the same local search is run from further random starting partitions (every node is in the core with probability
one half) and the partition with the highest fitness over all starts is kept, never lower than that of the degree-based start; the number of starts
that reached the best fitness is shown and stored in {bf:r(nbest)}. Without {opt restarts()} the output and the random-number state are unchanged.
{opt restarts()} is available for networks of up to 2,000 nodes.

{pstd}
{opt generate()} is required and names the new variable which stores, for each node, 1
if it was assigned to the core and 0 if it was assigned to the periphery. With more than one network in the
{it:netlist}, a number is appended to the name ({it:newvarname}{bf:1}, {it:newvarname}{bf:2}, ...) and the stored results
are those of the last network.

{pstd}
The classical model does not distinguish
incoming from outgoing ties, so it is defined for an undirected network: a directed network with unreciprocated ties is refused (error 198)
unless option {opt sym} asks for the symmetrized network (as {help nwcommunity} does); the output says which was done.


{title:Network types}

{pstd}
{bf:Directed:} refused (error 198) when some ties are not reciprocated, because the measure is defined for an undirected network; option {opt sym} analyses the symmetrized network (a tie counts in both directions, with the larger of its
two values) and the output says so. A directed network whose ties are all reciprocated is the same as an undirected one and is analysed as such (the output says so). {bf:Valued:} tie values are used by default ({opt measure(valued)});
{opt measure(binary)} ignores them. {bf:Two-mode:} not supported (error 6088; use {help nwproject} first). {bf:Signed:}
not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Above 2,000 nodes the search runs on the stored ties (the sums of the correlation with the ideal pattern are taken from the ties;
the cores found are those of the matrix version, the fitness equal up to rounding in the last digits). Measured in Stata/BE on a
random undirected network with 10 ties drawn per node: 10,000 nodes 0.3 seconds and 0.2 GB,
20,000 nodes 0.6 seconds.

{pstd}
A network with no ties at all is rejected (there is no structure to fit a core-periphery pattern to); an isolate is assigned
to the periphery.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcoreperiphery flomarriage, generate(_core)}

{pstd}The best of 50 searches (the degree-based start and 49 random starts):{p_end}
	{cmd:. nwcoreperiphery flomarriage, generate(_core) replace restarts(50) seed(1)}

{pstd}The adjacency matrix with the core nodes first and the periphery last ({help nwplotmatrix}):{p_end}
	{cmd:. nwplotmatrix flomarriage, sortby(_core) group(_core)}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(fitness)}}correlation between the observed network and the ideal pattern implied by the found partition (-1 to 1; 1 = a perfect discrete core-periphery structure){p_end}
{synopt:{bf:r(core)}}number of nodes assigned to the core{p_end}
{synopt:{bf:r(restarts)}}number of starts of the local search (1 = the degree-based start only){p_end}
{synopt:{bf:r(beststart)}}the first start that reached the best fitness (1 = the degree-based start){p_end}
{synopt:{bf:r(nbest)}}number of starts that reached the best fitness{p_end}


{title:References}

{pstd}
Borgatti, S.P., Everett, M.G. (1999). Models of core/periphery structures. {it:Social Networks}
21(4), 375-395.


{title:See also}

	{help nwconcor}, {help nwcommunity}, {help nwconstraint}

{hline}
{pstd}{it:nwcommands version 3.36.1, 23 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
