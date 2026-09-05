---
title: "nwkcore"
parent: "Command reference"
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
generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `generate(newvarname)` | Name of the Stata variable that stores each node's coreness; default = *_kcore* |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwkcore` computes the k-core decomposition (Seidman 1983) of a network or a list of networks. A node's *coreness* is the largest *k* such that the node belongs to a *k-core*: a maximal subgraph in which every node has degree at least *k* within that subgraph. Nodes with high coreness sit in the network's densely interconnected "core"; nodes with low coreness (e.g. degree-1 pendants) sit on the periphery. Coreness is a common building block for identifying cohesive subgroups and for network visualization (e.g. sizing/coloring nodes by coreness, or restricting a plot to the k-core for some threshold *k*).

All calculations are performed on the undirected version of the network: for directed networks, a node's neighbor set is the union of its out- and in-neighbors, matching how [nwcomponents](nwcomponents.md) treats directed networks for the same kind of undirected-sense structural question.

By default, `nwkcore` generates a new variable *_kcore* which stores each node's coreness.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkcore flomarriage
. tab _kcore
```

## Supported network types

Binary: yes (only) - coreness is a structural property, tie values are ignored. Directed: yes - each node's neighbor set is the union of its out- and in-neighbors (matching [nwcomponents](nwcomponents.md)'s own weak-connectivity convention and [nwsimindex](nwsimindex.md)'s identical choice), not symmetrized distances. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## Stored results

**Scalars**

- **r(maxcore)** maximum coreness found (the network's degeneracy)

**Matrices**

- **r(core_sizeid)** distribution over coreness levels

## References

Seidman, S.B. (1983). Network structure and minimum degree. *Social Networks* 5(3), 269-287.

Batagelj, V., Zaversnik, M. (2003). An O(m) Algorithm for Cores Decomposition of Networks. arXiv:cs/0310049.

## See also

- [nwcomponents](nwcomponents.md), [nwcommunity](nwcommunity.md), [nwdegree](nwdegree.md)

- last certified : 24 Aug 2026
