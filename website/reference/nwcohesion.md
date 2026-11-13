---
title: "nwcohesion"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Moody-White structural cohesion hierarchy"
---

# `nwcohesion`

Moody-White structural cohesion hierarchy

## Syntax

```stata
nwcohesion
[netlist]
[,
generate(newvarname)
replace
silent
force]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own highest cohesion level |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |
| `force` | Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise) |

## Description

`nwcohesion` computes the full, multi-level Moody and White (2003) cohesive-blocking hierarchy: starting from the whole network, it recursively finds ever-more-cohesive nested sub-blocks, using [nwkcomponents](nwkcomponents)' own single-level k-component primitive (vertex connectivity via node-splitting max-flow, Menger's theorem) applied repeatedly at increasing connectivity levels. Where [nwkcomponents](nwkcomponents) answers "which nodes form a block of at least connectivity `k(int)`?" for one chosen `k(int)`, `nwcohesion` answers the fuller question: "what is the complete nested structure, from the whole network down to its most cohesive cores, and how cohesive is each level?" - with no `k(int)` to choose, since every level actually present in the network is found and reported.

Each block's own connectivity level is its network's ACTUAL vertex connectivity (not merely the level searched for) - a disconnected network's own top block is reported at level 0, a network joined only by a single cut vertex at level 1, and so on. Levels found deeper in the hierarchy can skip values (e.g. a level-1 block can have level-3 children directly, with no level-2 block ever appearing) - a well-documented real property of structural cohesion, not a limitation of this implementation.

Like [nwkcomponents](nwkcomponents), blocks can genuinely overlap (a cutset remains a shared member of every sub-block its removal reveals) and nest (a child block's own node set is always a strict subset of its parent's), so the complete structure is returned via **r(cohesion_matrix)** (a blocks-by-nodes 0/1 membership matrix, one row per block found at ANY level of the hierarchy) and **r(cohesion_levels)** (a parallel column vector giving each row's own connectivity level). `generate(newvarname)` (required) stores, per node, the HIGHEST level of any block that node belongs to - the standard node-level structural-cohesion summary statistic - and is always well-defined for every node (even an isolate gets its own top-block level, typically 0), unlike [nwkcomponents](nwkcomponents)' own *_kcompnum*, which is missing for nodes that don't qualify for the one requested `k(int)`.

With more than one network in the *netlist*, a number is appended to the variable name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

## Network types

**Directed:** symmetrized. **Valued:** tie values are ignored (the command prints a note on a valued network). **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

The search runs in compiled code on the list of ties, never on an N-by-N matrix. It is more expensive than a single [nwkcomponents](nwkcomponents) call, since every block found is searched again at the next connectivity level; the time grows with the number of nodes squared times the connectivity level of the deepest block. Measured in Stata/BE on a random network with 10 ties drawn per node (about 20 per node once symmetrized): 300 / 1,000 / 5,000 nodes take 0.02 / 0.09 / 1.4 seconds. `r(cohesion_matrix)` has one row per block and one column per node. On a platform whose plugin file has not been built yet, a Mata routine runs instead (same results, about 20 seconds at 300 nodes).

Measured in Stata/BE on a random undirected network with 10 ties drawn per node: 10,000 nodes 6 seconds, 20,000 nodes 27 seconds and 2.9 GB. When the estimated time is more than 2 minutes (about 40,000 nodes) the command stops at once with r(484) and a message; option `force` runs it anyway.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcohesion flomarriage, generate(_cohesion)
```

## Stored results

- **Scalars**
- **r(blocks)** --- number of cohesive blocks found across the whole hierarchy

- **Matrices**
- **r(cohesion_matrix)** --- blocks-by-nodes 0/1 membership matrix, one row per block at any level
- **r(cohesion_levels)** --- blocks-by-1 column vector of each row's own connectivity level

## References

Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of social groups. *American Sociological Review* 68(1), 103-127.

Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. *Networks* 23(6), 533-541.

Even, S. (1979). *Graph Algorithms*. Computer Science Press. (the vertex-splitting max-flow reduction for vertex connectivity)

## See also

- [nwkcomponents](nwkcomponents), [nwcomponents](nwcomponents), [nwclique](nwclique), [nwkplex](nwkplex)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
