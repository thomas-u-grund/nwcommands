---
title: "nwcommunity"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Detect communities: Louvain, Leiden, Infomap, label propagation"
---

# `nwcommunity`

Detect communities: Louvain, Leiden, Infomap, label propagation

## Syntax

```stata
nwcommunity
[netlist]
,
generate(newvarname)
[replace
measure(string)
SYMmetrize
resolution(real)
algorithm(louvain|leiden|infomap|labelprop|dirtlpa)
seed(int)
silent
listall
onemode
starts(#)
reps(#)
minmodules(#)]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores community membership |
| `replace` | Replace existing variable |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `symmetrize` | Symmetrize a directed network before detecting communities (required for directed networks) |
| `resolution(real)` | Resolution parameter (Reichardt-Bornholdt); must be > 0; only affects **algorithm(louvain)**'s own search, though it always affects the reported **r(modularity)** regardless of algorithm; default = 1 |
| `algorithm(louvain\|leiden\|infomap\|labelprop\|dirtlpa)` | Community-detection algorithm; default = *louvain*; *leiden* and *infomap* are described below; *dirtlpa* (two-mode networks only) is the label propagation of Beckett (2016) for the bipartite modularity of Barber |
| `seed(int)` | Set the random-number seed before detecting communities (for reproducibility with **algorithm(labelprop)**, which uses randomized sweep order and tie-breaking) |
| `silent` | Suppress display of results |
| `listall` | Print the full table of communities; by default at most the first 30 rows are printed, with a note. Results in `r()` are unchanged |
| `onemode` | Two-mode network: the modularity of Newman for the bipartite graph read as a one-mode graph, instead of the bipartite modularity of Barber (the default for a two-mode network) |
| `starts(#)` | Two-mode network: the number of starting orders of the search for the partition with the largest bipartite modularity; default = *30*; the first starts in the order of the nodes, the others in random order (`seed()`) |
| `reps(#)` | **algorithm(dirtlpa)**: the number of repeated runs of the label propagation for every number of starting modules (the **reps** of `bipartite::DIRT_LPA_wb_plus`); default = *10* |
| `minmodules(#)` | **algorithm(dirtlpa)**: the smallest number of starting modules of the repeated runs (the **mini** of `bipartite::DIRT_LPA_wb_plus`); default = *4* |
| `beta(#)` | **algorithm(leiden)**: randomness of the refinement step (the **beta** of `igraph::cluster_leiden`); must be > 0; default = *0.01* |
| `iterations(#)` | **algorithm(leiden)**: number of passes of the algorithm, each starting from the partition of the last; a negative number repeats until the partition no longer changes (at most 100 passes); default = *2* (as **n_iterations** of `igraph::cluster_leiden`) |
| `trials(#)` | **algorithm(leiden)** and **algorithm(infomap)**: number of independent runs; the partition with the highest modularity (Leiden) or the shortest codelength (Infomap) is kept; default = *10* |

## Description

`nwcommunity` detects communities in the network(s) in [netlist](netlist) using one of several algorithms (`algorithm()`): the Louvain method (Blondel et al 2008, the default), a greedy algorithm that repeatedly moves nodes between communities and aggregates communities into a coarser network, in order to maximize Newman's modularity *Q*; or label propagation (Raghavan, Albert & Kumar 2007), a much cheaper algorithm with no modularity optimization at all - each node simply, repeatedly adopts whichever community its neighbors' total edge weight favors most, until no node wants to move. Label propagation does not optimize any global objective the way Louvain does, so its partitions are typically lower-modularity and less consistent run to run, but it scales far better to very large networks. All calculations are performed on the undirected network; directed networks require **symmetrize**, which keeps a tie between two nodes if either direction has one (the union, with the larger of the two tie values; not only mutual ties).

**algorithm(labelprop)** uses genuinely randomized sweep order and tie-breaking (unlike Louvain's own fixed, reproducible sweep order) - this is a deliberate, load-bearing part of the algorithm, not an incidental implementation detail: a fixed visiting order with deterministic tie-breaking systematically collapses even simple, cleanly-separated community structure into one giant community (see [Algorithm](nwcommunity) below). Use `seed()` for reproducible results.

On dense networks **algorithm(labelprop)** can collapse to a single community; compare the reported modularity with that of **algorithm(louvain)** before relying on it. Louvain is deterministic and ignores `seed()`. The two-mode search draws its random starting orders from the seed: the same `seed()` (or `set seed`) gives the same communities, whatever the platform; the search runs in the native plugin (a platform without it uses Mata code), and the two reach the same modularity up to the luck of the random starts (Southern women: identical, 0.3455).

`generate()` is required and names the new variable that stores, for each node, the id of the community it was assigned to. With more than one network in the *netlist*, a number is appended to the name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

**algorithm(leiden)** is the Leiden algorithm (Traag, Waltman and van Eck 2019): fast local moving with a queue, a refinement step that splits each community into well-connected parts (randomised with the parameter `beta()`), and aggregation of the refined parts. It maximises the same modularity as Louvain, with `resolution()`, and guarantees connected communities. It takes the tie values of a valued network as weights. The best of `trials()` independent runs is kept.

**algorithm(infomap)** is the two-level map equation (Rosvall and Bergstrom 2008) for an undirected network: the partition that gives the shortest description of a random walk, found by a greedy core loop with node moves and aggregation, followed by fine tuning; the best of `trials()` runs is kept. The number of communities is found by the method, and a network without clear structure gives one community. `resolution()` does not apply. The code length (bits) is returned in **r(codelength)**. It differs from the code length of `igraph::cluster_infomap`, which lets the walker teleport also on an undirected network; the partitions agree where the structure is clear.

## Algorithm

**algorithm(labelprop)**'s randomization is required for correctness, not just textbook fidelity: with a fixed 1..n sweep order and "prefer the lowest-indexed tied community" tie-breaking (mirroring **algorithm(louvain)**'s own reproducible convention), the simplest possible test case - two triangles joined by a single bridge edge - collapses all six nodes into one single community instead of splitting cleanly at the bridge. The bridge nodes' own decision is a genuine tie between their own triangle and the other side; a fixed check order means whichever community is examined first always wins ties, so it keeps absorbing neighbors and cascades into a single dominant community - the exact failure mode true label propagation's randomization exists to prevent. **algorithm(louvain)**'s own fixed sweep order has no comparable bias, since its search is driven by an actual modularity-gain comparison, not a plain vote count.

**algorithm(dirtlpa)** searches the same modularity with the label propagation **LPAwb+** of Beckett (2016) in its repeated form **DIRT_LPA+** (R: `bipartite::DIRT_LPA_wb_plus`, `bipartite::computeModules(method = "Beckett")`): it needs the native plugin (a clear message asks for an update otherwise), is reproducible with `seed()`, takes the weights of a valued network, does not use `resolution()` or `starts()` (it uses `reps()` and `minmodules()`), and is much slower than the Louvain search because of the repeated runs (the Southern women find the best known modularity 0.3455 with both; on the 5,092 directors and 455 boards of `ftdirectors_se` **dirtlpa** reaches 0.95110 with the default `reps()`, 30 starts of the Louvain search 0.95101). The merge step evaluates Barber's modularity of the labels exactly; the R function evaluates it with a trace in which the modules of the two sides are matched by position, which agrees with the exact value whenever the two sets of labels appear in the same order.

## Network types

**Directed:** refused unless `symmetrize` is given. **Valued:** tie values are used by default (`measure(valued)`); `measure(binary)` ignores them. **Two-mode:** yes - the bipartite modularity of Barber (2007) is maximised; `onemode` gives the modularity of Newman of the graph read as one-mode; **algorithm(dirtlpa)** is for two-mode networks only. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

Louvain runs in a kernel of the native plugin on the stored ties (a platform without the plugin uses the Mata code, which gives the same communities, on the dense matrix). With 10 ties drawn per node, 10,000 nodes need about 0.2 GB. Above 1,000 communities (a sparse network of a few thousand nodes) the table of community sizes is not printed; the sizes are in **r(comm_sizeid)**, ordered by size and then by community number.

Label propagation runs on the stored ties too (the same partitions for the same `seed()`). With 10 ties drawn per node, 20,000 nodes need about 0.3 GB.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcommunity flomarriage, generate(_community)
. nwcommunity flomarriage, algorithm(labelprop) seed(12345) generate(_community) replace
. nwcommunity flomarriage, algorithm(leiden) seed(1) generate(_community) replace
. nwcommunity flomarriage, algorithm(infomap) trials(20) seed(1) generate(_community) replace
```
Leiden and Infomap run in Mata on the stored ties and are meant for networks of up to a few thousand nodes. They are much slower than Louvain. Both need a one-mode network: a two-mode network requires `onemode`, a directed network `symmetrize`. Infomap is the undirected two-level map equation only: there is no directed map equation, no hierarchical (multilevel) partition and no coarse tuning. Leiden optimises modularity only (no constant Potts model). On the Zachary karate club, planted-partition networks and the three Lazega law-firm networks the partitions of both algorithms agree with those of igraph (adjusted Rand index 1 where the structure is clear), and the modularity of Leiden equals the best of 30 igraph runs; on a network with weak structure the landscape is rugged and a single run can end in a different partition: raise `trials()`.

## Stored results

- **Scalars**
- **r(communities)** --- number of communities
- **r(modularity)** --- modularity Q of the detected partition
- **r(codelength)** --- **algorithm(infomap)**: code length of the map equation in bits

- **Macros**
- **r(modularity_type)** --- **newman**, or **barber** for the bipartite modularity of a two-mode network

- **Matrices**
- **r(comm_sizeid)** --- distribution over communities: one row per community with the columns size, compid (community id) and share

## References

Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in large networks. *Journal of Statistical Mechanics: Theory and Experiment*, 2008(10), P10008.

Newman, M.E.J. (2006). Modularity and community structure in networks. *PNAS* 103(23), 8577-8582.

Beckett, S.J. (2016). Improved community detection in weighted bipartite networks. *Royal Society Open Science* 3(1), 140536. doi:10.1098/rsos.140536.

Traag, V.A., Waltman, L., van Eck, N.J. (2019). From Louvain to Leiden: guaranteeing well-connected communities. *Scientific Reports* 9, 5233.

Rosvall, M., Bergstrom, C.T. (2008). Maps of random walks on complex networks reveal community structure. *PNAS* 105(4), 1118-1123.

Raghavan, U.N., Albert, R., Kumar, S. (2007). Near linear time algorithm to detect community structures in large-scale networks. *Physical Review E* 76(3), 036106.

## See also

- [nwmodularity](nwmodularity), [nwcomponents](nwcomponents), [nwclustering](nwclustering)

---

*nwcommands version 3.37.2, 26 November 2026* ([check your installed version](nwversion))
