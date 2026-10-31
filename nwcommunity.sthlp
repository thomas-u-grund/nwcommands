{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_community:[NW-2.6.3] Community Detection}

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
{opt algorithm(louvain|labelprop|dirtlpa)}
{opt seed(int)}
{opt silent}
{opt listall}
{opt onemode}
{opt starts(#)}
{opt reps(#)}
{opt minmodules(#)}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores community membership{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before detecting communities (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); must be > 0; only affects {bf:algorithm(louvain)}'s own search, though it always affects the reported {bf:r(modularity)} regardless of algorithm; default = 1{p_end}
{synopt:{opt algorithm(louvain|labelprop|dirtlpa)}}Community-detection algorithm; default = {it:louvain}; {it:dirtlpa} (two-mode networks only) is the label propagation of Beckett (2016) for the bipartite modularity of Barber{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before detecting communities (for reproducibility with {bf:algorithm(labelprop)}, which uses randomized sweep order and tie-breaking){p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt listall}}Print the full table of communities; by default at most the first 30 rows are printed, with a note. Results in {cmd:r()} are unchanged{p_end}
{synopt:{opt onemode}}Two-mode network: the modularity of Newman for the bipartite graph read as a one-mode graph, instead of the bipartite modularity of Barber (the default for a two-mode network){p_end}
{synopt:{opt starts(#)}}Two-mode network: the number of starting orders of the search for the partition with the largest bipartite modularity; default = {it:30}; the first starts in the order of the nodes, the others in random order ({opt seed()}){p_end}
{synopt:{opt reps(#)}}{bf:algorithm(dirtlpa)}: the number of repeated runs of the label propagation for every number of starting modules (the {bf:reps} of {cmd:bipartite::DIRT_LPA_wb_plus}); default = {it:10}{p_end}
{synopt:{opt minmodules(#)}}{bf:algorithm(dirtlpa)}: the smallest number of starting modules of the repeated runs (the {bf:mini} of {cmd:bipartite::DIRT_LPA_wb_plus}); default = {it:4}{p_end}

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
On dense networks {bf:algorithm(labelprop)} can collapse to a single community; compare the reported modularity with that of {bf:algorithm(louvain)} before relying on it. Louvain is deterministic and ignores {opt seed()}. The two-mode search draws its random starting orders from the seed: the same {opt seed()} (or {cmd:set seed}) gives the same communities, whatever the platform; with a plugin of the current generation the search is about 25 times faster than the older Mata search (the Mata code is used when the plugin is older), and the two reach the same modularity up to the luck of the random starts (Southern women: identical, 0.3455).

{pstd}
{opt generate()} is required and names the new variable that stores, for each node, the
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


{title:Two-mode networks}

{pstd}
Two-mode: yes - Louvain-type search for the partition with the largest bipartite modularity of Barber (2007), the null model of {cmd:bipartite::computeModules}; {opt onemode} gives the modularity of Newman for the bipartite graph read as a one-mode graph ({cmd:igraph::cluster_louvain}); {opt starts()} sets the number of starting orders. {bf:algorithm(dirtlpa)} searches the same modularity with the label propagation {bf:LPAwb+} of Beckett (2016) in its repeated form {bf:DIRT_LPA+} (R: {cmd:bipartite::DIRT_LPA_wb_plus}, {cmd:bipartite::computeModules(method = "Beckett")}): it needs the native plugin of nwcommands 3.10.0 or later (a clear message asks for the update otherwise), is reproducible with {opt seed()}, takes the weights of a valued network, does not use {opt resolution()} or {opt starts()} (it uses {opt reps()} and {opt minmodules()}), and is much slower than the Louvain search because of the repeated runs (the Southern women find the best known modularity 0.3455 with both; on the 5,092 directors and 455 boards of {cmd:ftdirectors_se} {bf:dirtlpa} reaches 0.95110 in 12 seconds with the default {opt reps()}, 30 starts of the Louvain search 0.95101 in 0.2 seconds). The merge step evaluates Barber's modularity of the labels exactly; the R function evaluates it with a trace in which the modules of the two sides are matched by position, which agrees with the exact value whenever the two sets of labels appear in the same order.

{title:Supported network types}

{pstd}
Binary: yes. Directed: requires {opt symmetrize} - community detection as implemented here is not defined for a directed network. Weighted: yes, via {opt measure(binary|valued)}; default = {it:valued} for a valued network, {it:binary} otherwise (affects both which partition is searched for and the reported {bf:r(modularity)}). Signed: not checked. Two-mode: yes - Louvain-type search for the partition with the largest bipartite modularity of Barber (2007), the null model of {cmd:bipartite::computeModules}; {opt onemode} gives the modularity of Newman for the bipartite graph read as a one-mode graph ({cmd:igraph::cluster_louvain}); {opt starts()} sets the number of starting orders.

{title:Stored results}

	Scalars
	  {bf:r(communities)}		number of communities
	  {bf:r(modularity)}		modularity Q of the detected partition

	Matrices
	  {bf:r(comm_sizeid)}		distribution over communities


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcommunity flomarriage, generate(_community)}
	{cmd:. nwcommunity flomarriage, algorithm(labelprop) seed(12345) generate(_community) replace}


{title:References}

{pstd}
Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in
large networks. {it:Journal of Statistical Mechanics: Theory and Experiment}, 2008(10), P10008.

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.

{pstd}
Beckett, S.J. (2016). Improved community detection in weighted bipartite networks. {it:Royal Society Open Science} 3(1), 140536. doi:10.1098/rsos.140536.

{pstd}
Raghavan, U.N., Albert, R., Kumar, S. (2007). Near linear time algorithm to detect community
structures in large-scale networks. {it:Physical Review E} 76(3), 036106.


{title:Limits}

{pstd}
Louvain runs in a kernel of the native plugin on the stored ties (a platform whose plugin has not been rebuilt yet keeps
the Mata code, which gives the same communities, on the dense matrix). Measured in Stata/BE, random undirected network with
10 ties drawn per node: 1,000 nodes 0.08 seconds, 3,000 nodes 0.08 seconds (14 communities, modularity 0.18), 10,000
nodes 0.24 seconds (0.2 GB; 3.8 seconds and 3 GB before). Label propagation works on the dense matrix: 10,000 nodes 17
seconds and 1.7 GB. Above 1,000 communities (a sparse network of a few thousand nodes) the table of community sizes is not
printed; the sizes are in {bf:r(comm_sizeid)}, ordered by size and then by community number.

{pstd}
Version note: before this version the second and later aggregation levels of Louvain could not merge communities (a
super-node counted its own loop as a tie to its own community), so the communities of every network that needed a
second level were too many and too small; on 40 random networks of 30 to 430 nodes the modularity rose by 0.018 to
0.12 (mean 0.064), and above about 1,500 nodes it had collapsed (3,000 nodes: 1,311 communities, modularity 0.07).
Partitions found with earlier versions are not reproduced.

{pstd}
Label propagation runs on the stored ties too (the same partitions for the same {opt seed()}; the old version summed the weights to a
community over all n nodes for every neighbour community and relabelled the communities by searching the whole list for every node).
Measured in Stata/BE, random undirected network with 10 ties drawn per node: 10,000 nodes 17 seconds and 1.7 GB before; 20,000 nodes
1.9 seconds and 0.3 GB (93 seconds and 6.4 GB before).

{title:See also}

	{help nwmodularity}, {help nwcomponents}, {help nwclustering}

{hline}
{pstd}{it:nwcommands version 3.12.2, 31 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
