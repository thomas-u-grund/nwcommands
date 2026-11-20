{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_community:[NW-2.6.3] Communities}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcommunity {hline 2}}Detect communities: Louvain, Leiden, Infomap, label propagation{p_end}
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
{opt algorithm(louvain|leiden|infomap|labelprop|dirtlpa)}
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
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); must be > 0; only affects {bf:algorithm(louvain)}'s own search, though it always affects the reported {bf:r(modularity)}
regardless of algorithm; default = 1{p_end}
{synopt:{opt algorithm(louvain|leiden|infomap|labelprop|dirtlpa)}}Community-detection algorithm; default = {it:louvain}; {it:leiden} and {it:infomap} are described below; {it:dirtlpa} (two-mode networks only) is the label propagation of Beckett (2016) for the
bipartite modularity of Barber{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before detecting communities (for reproducibility with {bf:algorithm(labelprop)}, which uses randomized sweep order and tie-breaking){p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt listall}}Print the full table of communities; by default at most the first 30 rows are printed, with a note. Results in {cmd:r()} are unchanged{p_end}
{synopt:{opt onemode}}Two-mode network: the modularity of Newman for the bipartite graph read as a one-mode graph, instead of the bipartite modularity of Barber (the default for a two-mode
network){p_end}
{synopt:{opt starts(#)}}Two-mode network: the number of starting orders of the search for the partition with the largest bipartite modularity; default = {it:30}; the first starts in the order of the
nodes, the others in random order ({opt seed()}){p_end}
{synopt:{opt reps(#)}}{bf:algorithm(dirtlpa)}: the number of repeated runs of the label propagation for every number of starting modules (the {bf:reps} of {cmd:bipartite::DIRT_LPA_wb_plus}); default =
{it:10}{p_end}
{synopt:{opt minmodules(#)}}{bf:algorithm(dirtlpa)}: the smallest number of starting modules of the repeated runs (the {bf:mini} of {cmd:bipartite::DIRT_LPA_wb_plus}); default = {it:4}{p_end}
{synopt:{opt beta(#)}}{bf:algorithm(leiden)}: randomness of the refinement step (the {bf:beta} of {cmd:igraph::cluster_leiden}); must be > 0; default = {it:0.01}{p_end}
{synopt:{opt iterations(#)}}{bf:algorithm(leiden)}: number of passes of the algorithm, each starting from the partition of the last; a negative number repeats until the partition no longer changes (at most 100
passes); default = {it:2} (as {bf:n_iterations} of {cmd:igraph::cluster_leiden}){p_end}
{synopt:{opt trials(#)}}{bf:algorithm(leiden)} and {bf:algorithm(infomap)}: number of independent runs; the partition with the highest modularity (Leiden) or the shortest codelength (Infomap) is kept; default = {it:10}{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwcommunity} detects communities in the network(s) in {help netlist} using one of several algorithms
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
an incidental implementation detail: a fixed visiting order with deterministic tie-breaking
systematically collapses even simple, cleanly-separated community structure into one giant community (see
{help nwcommunity##algorithm:Algorithm} below). Use {opt seed()} for reproducible results.

{pstd}
On dense networks {bf:algorithm(labelprop)} can collapse to a single community; compare the reported modularity with that of {bf:algorithm(louvain)} before relying on it. Louvain is deterministic and
ignores {opt seed()}. The two-mode search draws its random starting orders from the seed: the same {opt seed()} (or {cmd:set seed}) gives the same communities, whatever the platform; the search runs
in the native plugin, about 25 times faster than the Mata code that is used on a platform without it, and the two reach the same modularity up to the luck of the random starts (Southern
women: identical, 0.3455).

{pstd}
{opt generate()} is required and names the new variable that stores, for each node, the
id of the community it was assigned to. With more than one network in the {it:netlist}, a number is appended to the
name ({it:newvarname}{bf:1}, {it:newvarname}{bf:2}, ...) and the stored results are those of the last network.


{marker algorithm}{...}
{pstd}
{bf:algorithm(leiden)} is the Leiden algorithm (Traag, Waltman and van Eck 2019): fast local moving with a queue, a refinement
step that splits each community into well-connected parts (randomised with the parameter {opt beta()}), and aggregation of the
refined parts. It maximises the same modularity as Louvain, with {opt resolution()}, and guarantees connected communities.
It takes the tie values of a valued network as weights. The best of {opt trials()} independent runs is kept.

{pstd}
{bf:algorithm(infomap)} is the two-level map equation (Rosvall and Bergstrom 2008) for an undirected network: the
partition that gives the shortest description of a random walk, found by a greedy core loop with node moves and aggregation,
followed by fine tuning; the best of {opt trials()} runs is kept. The number of communities is found by the method, and a
network without clear structure gives one community. {opt resolution()} does not apply. The code length (bits) is returned in
{bf:r(codelength)}. It differs from the code length of {cmd:igraph::cluster_infomap}, which lets the walker teleport also on an
undirected network; the partitions agree where the structure is clear.

{title:Algorithm}

{pstd}
{bf:algorithm(labelprop)}'s randomization is required for correctness, not just textbook fidelity:
with a fixed 1..n sweep order and "prefer the lowest-indexed tied community" tie-breaking (mirroring
{bf:algorithm(louvain)}'s own reproducible convention), the simplest possible test case -
two triangles joined by a single bridge edge - collapses all six nodes into one single
community instead of splitting cleanly at the bridge. The bridge nodes' own decision is a genuine
tie between their own triangle and the other side; a fixed check order means whichever community
is examined first always wins ties, so it keeps absorbing neighbors and cascades into a single
dominant community - the exact failure mode true label propagation's randomization exists to
prevent. {bf:algorithm(louvain)}'s own fixed sweep order has no comparable bias, since its search
is driven by an actual modularity-gain comparison, not a plain vote count.


{pstd}
{bf:algorithm(dirtlpa)} searches the same modularity with
the label propagation {bf:LPAwb+} of Beckett (2016) in its repeated form {bf:DIRT_LPA+} (R: {cmd:bipartite::DIRT_LPA_wb_plus}, {cmd:bipartite::computeModules(method = "Beckett")}): it needs the native
plugin (a clear message asks for an update otherwise), is reproducible with {opt seed()}, takes the weights of a valued network, does not use {opt resolution()} or {opt starts()} (it uses {opt reps()}
and {opt minmodules()}), and is much slower than the Louvain search because of the repeated runs (the Southern women find the best known modularity 0.3455 with both; on the 5,092 directors and 455
boards of {cmd:ftdirectors_se} {bf:dirtlpa} reaches 0.95110 in 12 seconds with the default {opt reps()}, 30 starts of the Louvain search 0.95101 in 0.2 seconds). The merge step evaluates Barber's
modularity of the labels exactly; the R function evaluates it with a trace in which the modules of the two sides are matched by position, which agrees with the exact value whenever the two sets of
labels appear in the same order.


{title:Network types}

{pstd}
{bf:Directed:} refused unless {opt symmetrize} is given. {bf:Valued:} tie values are used by default
({opt measure(valued)}); {opt measure(binary)} ignores them. {bf:Two-mode:} yes - the bipartite modularity of Barber
(2007) is maximised; {opt onemode} gives the modularity of Newman of the graph read as one-mode; {bf:algorithm(dirtlpa)}
is for two-mode networks only. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Louvain runs in a kernel of the native plugin on the stored ties (a platform without the plugin uses
the Mata code, which gives the same communities, on the dense matrix). Measured in Stata/BE, random undirected network with
10 ties drawn per node: 1,000 nodes 0.08 seconds, 3,000 nodes 0.08 seconds (14 communities, modularity 0.18), 10,000
nodes 0.24 seconds (0.2 GB). Above 1,000 communities (a sparse network of a few thousand nodes) the table of community sizes is not
printed; the sizes are in {bf:r(comm_sizeid)}, ordered by size and then by community number.

{pstd}
Label propagation runs on the stored ties too (the same partitions for the same {opt seed()}).
Measured in Stata/BE, random undirected network with 10 ties drawn per node: 20,000 nodes
1.9 seconds and 0.3 GB.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcommunity flomarriage, generate(_community)}
	{cmd:. nwcommunity flomarriage, algorithm(labelprop) seed(12345) generate(_community) replace}
	{cmd:. nwcommunity flomarriage, algorithm(leiden) seed(1) generate(_community) replace}
	{cmd:. nwcommunity flomarriage, algorithm(infomap) trials(20) seed(1) generate(_community) replace}

{pstd}
Leiden and Infomap run in Mata on the stored ties and are meant for networks of up to a few thousand nodes. Measured in
Stata/BE with the default {opt trials(10)}: 1,000 nodes 0.9 seconds (Leiden) and 2 seconds (Infomap); 5,000 nodes with
33,000 ties 3.7 and 9.5 seconds (Louvain: 0.15 seconds). Both need a one-mode network: a two-mode network requires
{opt onemode}, a directed network {opt symmetrize}. Infomap is the undirected two-level map equation only: there is no
directed map equation, no hierarchical (multilevel) partition and no coarse tuning. Leiden optimises modularity only (no
constant Potts model). On the Zachary karate club, planted-partition networks and the three Lazega law-firm networks the
partitions of both algorithms agree with those of igraph (adjusted Rand index 1 where the structure is clear), and the
modularity of Leiden equals the best of 30 igraph runs; on a network with weak structure the landscape is rugged and a
single run can end in a different partition: raise {opt trials()}.


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(communities)}}number of communities{p_end}
{synopt:{bf:r(modularity)}}modularity Q of the detected partition{p_end}
{synopt:{bf:r(codelength)}}{bf:algorithm(infomap)}: code length of the map equation in bits{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(modularity_type)}}{bf:newman}, or {bf:barber} for the bipartite modularity of a two-mode network{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(comm_sizeid)}}distribution over communities: one row per community with the columns size, compid (community id) and share{p_end}


{title:References}

{pstd}
Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in
large networks. {it:Journal of Statistical Mechanics: Theory and Experiment}, 2008(10), P10008.

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.

{pstd}
Beckett, S.J. (2016). Improved community detection in weighted bipartite networks. {it:Royal Society Open Science} 3(1), 140536. doi:10.1098/rsos.140536.

{pstd}
Traag, V.A., Waltman, L., van Eck, N.J. (2019). From Louvain to Leiden: guaranteeing well-connected communities.
{it:Scientific Reports} 9, 5233.

{pstd}
Rosvall, M., Bergstrom, C.T. (2008). Maps of random walks on complex networks reveal community structure.
{it:PNAS} 105(4), 1118-1123.

{pstd}
Raghavan, U.N., Albert, R., Kumar, S. (2007). Near linear time algorithm to detect community
structures in large-scale networks. {it:Physical Review E} 76(3), 036106.


{title:See also}

	{help nwmodularity}, {help nwcomponents}, {help nwclustering}

{hline}
{pstd}{it:nwcommands version 3.29.0, 20 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
