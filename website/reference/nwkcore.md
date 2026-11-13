---
title: "nwkcore"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "k-core decomposition"
---

# `nwkcore`

k-core decomposition

## Syntax

```stata
nwkcore
[netlist]
[,
gen:erate(newvarname)
replace
silent]
```

| | |
|---|---|
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's coreness |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwkcore` computes the k-core decomposition (Seidman 1983) of a network or a list of networks. A node's *coreness* is the largest *k* such that the node belongs to a *k-core*: a maximal subgraph in which every node has degree at least *k* within that subgraph. Nodes with high coreness sit in the network's densely interconnected "core"; nodes with low coreness (e.g. degree-1 pendants) sit on the periphery. Coreness is a common building block for identifying cohesive subgroups and for network visualization (e.g. sizing/coloring nodes by coreness, or restricting a plot to the k-core for some threshold *k*).

All calculations are performed on the undirected version of the network: for directed networks, a node's neighbor set is the union of its out- and in-neighbors, matching how [nwcomponents](nwcomponents) treats directed networks for the same kind of undirected-sense structural question.

`generate()` is required and names the new variable which stores each node's coreness. With a list of several networks the variables are numbered by network (*newvarname***1**, *newvarname***2**, ...), and the stored results are those of the last network.

## Network types

**Directed:** a node's neighbours are its out- and in-neighbours together. **Valued:** tie values are ignored (the command prints a note on a valued network). **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkcore flomarriage, generate(_kcore)
. tab _kcore
```

## Stored results

- **Scalars**
- **r(maxcore)** --- maximum coreness found (the network's degeneracy)

- **Matrices**
- **r(core_sizeid)** --- distribution over coreness levels: one row per level, columns **size** (number of nodes), **coreid** (coreness) and **share** (share of nodes), sorted by size

## References

Seidman, S.B. (1983). Network structure and minimum degree. *Social Networks* 5(3), 269-287.

Batagelj, V., Zaversnik, M. (2003). An O(m) Algorithm for Cores Decomposition of Networks. arXiv:cs/0310049.

## See also

- [nwcomponents](nwcomponents), [nwcommunity](nwcommunity), [nwdegree](nwdegree)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
