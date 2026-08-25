{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

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
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores core membership; default = {it:_core}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opth maxiter(int)}}Maximum number of local-search sweeps before giving up on convergence; default = 100{p_end}
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
necessarily globally optimal partition - the same character of algorithm {help nwcommunity} already
uses for modularity maximization.

{pstd}
By default, {cmd:nwcoreperiphery} generates a new variable {it:_core} which stores, for each node, 1
if it was assigned to the core and 0 if it was assigned to the periphery.

{pstd}
Always operates on the undirected version of the network (the classical model does not distinguish
incoming from outgoing ties); a directed network is symmetrized automatically, matching
{help nwcommunity}'s own convention - no separate {bf:symmetrize} option is needed or offered.

{title:Stored results}

	Scalars
	  {bf:r(fitness)}		correlation between the observed network and the ideal pattern implied by the found partition (-1 to 1; 1 = a perfect discrete core-periphery structure)
	  {bf:r(core)}		number of nodes assigned to the core

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcoreperiphery flomarriage}


{title:References}

{pstd}
Borgatti, S.P., Everett, M.G. (1999). Models of core/periphery structures. {it:Social Networks}
21(4), 375-395.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (no explicit {bf:symmetrize} option, unlike
{help nwcommunity} - the model itself does not distinguish direction). Weighted:
{opt measure(valued)} uses tie weights directly when computing the fitness correlation;
{opt measure(binary)} uses presence/absence only; default follows the network's own weighted-ness,
matching {help nwcommunity}'s convention. Signed: not checked. Two-mode: not checked - operates on
the network's own square adjacency matrix. A network with no ties at all is rejected explicitly
(there is no structure to fit a core-periphery pattern to); a node with no ties of its own (an
isolate) is handled without error and is simply assigned to the periphery.

{title:See also}

	{help nwconcor}, {help nwcommunity}, {help nwconstraint}

last certified : 21 Aug 2026
