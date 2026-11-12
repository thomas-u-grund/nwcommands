---
title: "nwclustering"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
silent
level(#)
ra
onemode]
```

| | |
|---|---|
| `measure(binary\|arithmetic\|geometric\|maximum\|minimum)` | How to combine the two tie values in a potential triple for a weighted network; *binary* ignores tie values and only checks presence/absence; *arithmetic*/*geometric*/*maximum*/*minimum* combine the two tie values via that function; default = *arithmetic* for a valued undirected network, *binary* otherwise |
| `symmetrize` | Symmetrize a directed network before calculating (required for any weighted `measure()` on a directed network - see **Network types** below) |
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own clustering coefficient |
| `replace` | Overwrite an existing `generate(newvarname)` variable; required if it already exists |
| `silent` | Suppress display of results |
| `level(#)` | Two-mode network: the mode (1 or 2) whose nodes get a coefficient; default = *1* |
| `ra` | Two-mode network: the global coefficient of Robins and Alexander (2004), 4 C4 / L3, as `r(ra)`; `generate()` is then optional |
| `onemode` | Two-mode network: the one-mode coefficient of the bipartite graph (always 0, the graph has no triangles) instead of the two-mode coefficient of Opsahl (2013), the default |

## Description

`nwclustering` calculates the clustering coefficient (also known as transitivity) of a network: for each node *i*, the proportion of *i*'s own potential triples - pairs of *i*'s neighbors - that are themselves actually tied to each other ("the friends of my friends are themselves friends"). A node with fewer than 2 neighbors has no potential triples and its own clustering coefficient is reported as missing.

`generate()` is required and names the new variable that holds each node's own clustering coefficient, and returns both the network-level average (**r(cluster_avg)**, the mean of the per-node values) and the network-level global clustering coefficient (**r(cluster_global)**, the ratio of the total count of closed triples to the total count of potential triples across the whole network - not the same quantity as the average of per-node ratios, since it weights every potential triple equally rather than every node equally).

If the network is a two-mode (bipartite) network, `nwclustering` uses the two-mode form by default: the coefficient of Opsahl (2013) (the share of four-paths that a fifth tie closes, `tnet::clustering_tm`), and with `ra` the global coefficient of Robins and Alexander (2004). An ordinary clustering coefficient is not meaningful on a bipartite network's own inherently triangle-free structure; `onemode` computes it anyway. [nw2clustering](nw2clustering) is the same command under another name and takes the same options.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwclustering flomarriage, generate(_clustering)
. sum _clustering
```

## Stored results

- **Scalars**
- **r(cluster_avg)** --- mean of the per-node clustering coefficients
- **r(cluster_global)** --- network-level global clustering coefficient
- **r(C_avg)** --- two-mode network: mean of the per-node coefficients of the `level()` mode (instead of **r(cluster_avg)**)
- **r(C_global)** --- two-mode network: global coefficient of Opsahl (2013) (instead of **r(cluster_global)**)
- **r(ra)** --- two-mode network with `ra`: Robins-Alexander coefficient 4 C4 / L3
- **r(C4)** --- two-mode network with `ra`: number of four-cycles
- **r(L3)** --- two-mode network with `ra`: number of paths of length three

- **Macros**
- **r(measure)** --- the `measure()` actually used
- **r(symmetrized)** --- *false*, only returned when `symmetrize` was specified

## References

Watts, D.J., Strogatz, S.H. (1998). Collective dynamics of 'small-world' networks. *Nature* 393, 440-442.

## See also

- [nw2clustering](nw2clustering), [nwtriads](nwtriads), [nwbrokerage](nwbrokerage)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
