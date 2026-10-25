---
title: "nwcommunity"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Detect communities via the Louvain method or label propagation"
---

# `nwcommunity`

Detect communities via the Louvain method or label propagation

## Syntax

```stata
nwcommunity
[netlist]
[,
generate(newvarname)
replace
measure(string)
SYMmetrize
resolution(real)
algorithm(louvain|labelprop)
seed(int)
silent
listall]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores community membership |
| `replace` | Replace existing variable |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `symmetrize` | Symmetrize a directed network before detecting communities (required for directed networks) |
| `resolution(real)` | Resolution parameter (Reichardt-Bornholdt); must be > 0; only affects **algorithm(louvain)**'s own search, though it always affects the reported **r(modularity)** regardless of algorithm; default = 1 |
| `algorithm(louvain\|labelprop)` | Community-detection algorithm; default = *louvain* |
| `seed(int)` | Set the random-number seed before detecting communities (for reproducibility with **algorithm(labelprop)**, which uses randomized sweep order and tie-breaking) |
| `silent` | Suppress display of results |
| `listall` | Print the full table of communities; by default at most the first 30 rows are printed, with a note. Results in `r()` are unchanged |
| `onemode` | Two-mode network: the modularity of Newman for the bipartite graph read as a one-mode graph, instead of the bipartite modularity of Barber (the default for a two-mode network) |
| `starts(#)` | Two-mode network: the number of starting orders of the search for the partition with the largest bipartite modularity; default = *30*; the first starts in the order of the nodes, the others in random order (`seed()`) |

## Description

`nwcommunity` detects communities in the network(s) in [netlist](netlist) using one of two algorithms (`algorithm()`): the Louvain method (Blondel et al 2008, the default), a greedy algorithm that repeatedly moves nodes between communities and aggregates communities into a coarser network, in order to maximize Newman's modularity *Q*; or label propagation (Raghavan, Albert & Kumar 2007), a much cheaper algorithm with no modularity optimization at all - each node simply, repeatedly adopts whichever community its neighbors' total edge weight favors most, until no node wants to move. Label propagation does not optimize any global objective the way Louvain does, so its partitions are typically lower-modularity and less consistent run to run, but it scales far better to very large networks. All calculations are performed on the undirected network; directed networks require **symmetrize**.

**algorithm(labelprop)** uses genuinely randomized sweep order and tie-breaking (unlike Louvain's own fixed, reproducible sweep order) - this is a deliberate, load-bearing part of the algorithm, not an incidental implementation detail: a fixed visiting order with deterministic tie-breaking was tried first and found to be not merely non-standard but actively wrong, systematically collapsing even simple, cleanly-separated community structure into one giant community (see [Algorithm](nwcommunity) below). Use `seed()` for reproducible results.

On dense networks **algorithm(labelprop)** can collapse to a single community; compare the reported modularity with that of **algorithm(louvain)** before relying on it. Louvain is deterministic and ignores `seed()`.

`generate()` is required and names the new variable that stores, for each node, the id of the community it was assigned to.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcommunity flomarriage, generate(_community)
. nwcommunity flomarriage, algorithm(labelprop) seed(12345) generate(_community) replace
```

## Supported network types

Binary: yes. Directed: requires `symmetrize` - community detection as implemented here is not defined for a directed network. Weighted: yes, via `measure(binary|valued)`; default = *valued* for a valued network, *binary* otherwise (affects both which partition is searched for and the reported **r(modularity)**). Signed: not checked. Two-mode: yes - Louvain-type search for the partition with the largest bipartite modularity of Barber (2007), the null model of `bipartite::computeModules`; `onemode` gives the modularity of Newman for the bipartite graph read as a one-mode graph (`igraph::cluster_louvain`); `starts()` sets the number of starting orders.

## Stored results

**Scalars**

- **r(communities)** number of communities
- **r(modularity)** modularity Q of the detected partition

**Matrices**

- **r(comm_sizeid)** distribution over communities

## References

Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in large networks. *Journal of Statistical Mechanics: Theory and Experiment*, 2008(10), P10008.

Newman, M.E.J. (2006). Modularity and community structure in networks. *PNAS* 103(23), 8577-8582.

Raghavan, U.N., Albert, R., Kumar, S. (2007). Near linear time algorithm to detect community structures in large-scale networks. *Physical Review E* 76(3), 036106.

## See also

- [nwmodularity](nwmodularity), [nwcomponents](nwcomponents), [nwclustering](nwclustering)

---

*nwcommands version 3.6.0, 26 October 2026* ([check your installed version](nwversion))
