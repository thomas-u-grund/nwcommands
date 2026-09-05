---
title: "nwclustering"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Clustering coefficient (transitivity) of a network"
---

# `nwclustering`

Clustering coefficient (transitivity) of a network

## Syntax

```stata
nwclustering
[netname]
[,
measure(string)
SYMmetrize
generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `measure(binary\|arithmetic\|geometric\|maximum\|minimum)` | How to combine the two tie
values in a potential triple for a weighted network; *binary* ignores tie values and only checks
presence/absence; *arithmetic*/*geometric*/*maximum*/*minimum* combine the two tie
values via that function; default = *arithmetic* for a valued undirected network, *binary*
otherwise |
| `symmetrize` | Symmetrize a directed network before calculating (required for any
weighted `measure()` on a directed network - see Supported network types below) |
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own
clustering coefficient |
| `replace` | Overwrite an existing `generate(newvarname)` variable; required if it already exists |
| `silent` | Suppress display of results |

## Description

`nwclustering` calculates the clustering coefficient (also known as transitivity) of a network: for each node *i*, the proportion of *i*'s own potential triples - pairs of *i*'s neighbors - that are themselves actually tied to each other ("the friends of my friends are themselves friends"). A node with fewer than 2 neighbors has no potential triples and its own clustering coefficient is reported as missing.

`generate()` is required and names the new variable that holds each node's own clustering coefficient, and `nwclustering` returns both the network-level average (**r(cluster_avg)**, the mean of the per-node values) and the network-level global clustering coefficient (**r(cluster_global)**, the ratio of the total count of closed triples to the total count of potential triples across the whole network - not the same quantity as the average of per-node ratios, since it weights every potential triple equally rather than every node equally).

If the network is a two-mode (bipartite) network, `nwclustering` automatically switches to [nw2clustering](nw2clustering.md) instead (an ordinary clustering coefficient is not meaningful on a bipartite network's own inherently triangle-free structure), forwarding `measure()` and `generate()`.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwclustering flomarriage, generate(_clustering)
. sum _clustering
```

## Supported network types

Binary: yes (the default `measure(binary)` case). Directed: yes for `measure(binary)` (each node's own potential triples are formed from one in-neighbor paired with one out-neighbor, matching the directed two-path a -> i -> b convention used elsewhere in this package); a weighted `measure()` is not defined for a directed network - either choose `measure(binary)` or `symmetrize` the network first. Weighted: yes, via `measure(arithmetic|geometric|maximum|minimum)`, each combining the two tie values of a potential triple's own pair of ties before testing closure; undirected networks only (see above). Signed: not checked; negative tie values are not validated or rejected. Two-mode: automatically delegated to [nw2clustering](nw2clustering.md) (see Description).

## Stored results

**Scalars**

- **r(cluster_avg)** mean of the per-node clustering coefficients
- **r(cluster_global)** network-level global clustering coefficient

**Macros**

- **r(measure)** the `measure()` actually used
- **r(symmetrized)** *false*, only returned when `symmetrize` was specified

## References

Watts, D.J., Strogatz, S.H. (1998). Collective dynamics of 'small-world' networks. *Nature* 393, 440-442.

## See also

- [nw2clustering](nw2clustering.md), [nwtriads](nwtriads.md), [nwbrokerage](nwbrokerage.md)

- last certified : 24 Aug 2026
