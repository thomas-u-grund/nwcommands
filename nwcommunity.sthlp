{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_community:[NW-2.6.3] Community Detection}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcommunity {hline 2}}Detect communities via the Louvain method or label propagation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcommunity}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt measure(string)}
{opt SYMmetrize}
{opth resolution(real)}
{opt algorithm(louvain|labelprop)}
{opt seed(int)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores community membership; default = {it:_community}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before detecting communities (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); only affects {bf:algorithm(louvain)}'s own search, though it always affects the reported {bf:r(modularity)} regardless of algorithm; default = 1{p_end}
{synopt:{opt algorithm(louvain|labelprop)}}Community-detection algorithm; default = {it:louvain}{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before detecting communities (for reproducibility with {bf:algorithm(labelprop)}, which uses randomized sweep order and tie-breaking){p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcommunity} detects communities in the network(s) in {help netlist} using one of two algorithms
({opt algorithm()}): the Louvain method (Blondel et al 2008, the default), a greedy algorithm that
repeatedly moves nodes between communities and aggregates communities into a coarser network, in
order to maximize Newman's modularity {it:Q}; or label propagation (Raghavan, Albert & Kumar 2007),
a much cheaper algorithm with no modularity optimization at all - each node simply, repeatedly
adopts whichever community its neighbors' total edge weight favors most, until no node wants to
move. Label propagation does not optimize any global objective the way Louvain does, so its
partitions are typically lower-modularity and less consistent run to run, but it scales far better
to very large networks. All calculations are performed on the undirected network; directed networks
require {bf:symmetrize}.

{pstd}
{bf:algorithm(labelprop)} uses genuinely randomized sweep order and tie-breaking (unlike Louvain's
own fixed, reproducible sweep order) - this is a deliberate, load-bearing part of the algorithm, not
an incidental implementation detail: a fixed visiting order with deterministic tie-breaking was
tried first and found to be not merely non-standard but actively wrong, systematically collapsing
even simple, cleanly-separated community structure into one giant community (see
{help nwcommunity##algorithm:Algorithm} below). Use {opt seed()} for reproducible results.

{pstd}
By default, {cmd:nwcommunity} generates a new variable {it:_community} which stores, for each node, the
id of the community it was assigned to.

{marker algorithm}{...}
{title:Algorithm}

{pstd}
{bf:algorithm(labelprop)}'s randomization is required for correctness, not just textbook fidelity -
confirmed directly rather than assumed: an earlier version of this algorithm used a fixed 1..n
sweep order with "prefer the lowest-indexed tied community" tie-breaking (mirroring
{bf:algorithm(louvain)}'s own reproducible convention), and on the simplest possible test case -
two triangles joined by a single bridge edge - it collapsed all six nodes into one single
community instead of splitting cleanly at the bridge. The bridge nodes' own decision is a genuine
tie between their own triangle and the other side; a fixed check order means whichever community
is examined first always wins ties, so it keeps absorbing neighbors and cascades into a single
dominant community - the exact failure mode true label propagation's randomization exists to
prevent. {bf:algorithm(louvain)}'s own fixed sweep order has no comparable bias, since its search
is driven by an actual modularity-gain comparison, not a plain vote count, so it was left
unchanged.


{title:Supported network types}

{pstd}
Binary: yes. Directed: requires {opt symmetrize} - community detection as implemented here is not defined for a directed network. Weighted: yes, via {opt measure(binary|valued)}; default = {it:valued} for a valued network, {it:binary} otherwise (affects both which partition is searched for and the reported {bf:r(modularity)}). Signed: not checked. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(communities)}		number of communities
	  {bf:r(modularity)}		modularity Q of the detected partition

	Matrices
	  {bf:r(comm_sizeid)}		distribution over communities


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcommunity flomarriage}
	{cmd:. nwcommunity flomarriage, algorithm(labelprop) seed(12345)}


{title:References}

{pstd}
Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in
large networks. {it:Journal of Statistical Mechanics: Theory and Experiment}, 2008(10), P10008.

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.

{pstd}
Raghavan, U.N., Albert, R., Kumar, S. (2007). Near linear time algorithm to detect community
structures in large-scale networks. {it:Physical Review E} 76(3), 036106.


{title:See also}

	{help nwmodularity}, {help nwcomponents}, {help nwclustering}

