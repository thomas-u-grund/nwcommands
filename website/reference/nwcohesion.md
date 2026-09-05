---
title: "nwcohesion"
parent: "Command reference"
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
silent]
```

| | |
|---|---|
| `generate(newvarname)` | Name of the Stata variable that stores each node's own highest cohesion level; default = *_cohesion* |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwcohesion` computes the full, multi-level Moody and White (2003) cohesive-blocking hierarchy: starting from the whole network, it recursively finds ever-more-cohesive nested sub-blocks, using [nwkcomponents](nwkcomponents.md)' own single-level k-component primitive (vertex connectivity via node-splitting max-flow, Menger's theorem) applied repeatedly at increasing connectivity levels. Where [nwkcomponents](nwkcomponents.md) answers "which nodes form a block of at least connectivity `k(int)`?" for one chosen `k(int)`, `nwcohesion` answers the fuller question: "what is the complete nested structure, from the whole network down to its most cohesive cores, and how cohesive is each level?" - with no `k(int)` to choose, since every level actually present in the network is found and reported.

Each block's own connectivity level is its network's ACTUAL vertex connectivity (not merely the level searched for) - a disconnected network's own top block is reported at level 0, a network joined only by a single cut vertex at level 1, and so on. Levels found deeper in the hierarchy can skip values (e.g. a level-1 block can have level-3 children directly, with no level-2 block ever appearing) - a well-documented real property of structural cohesion, not a limitation of this implementation.

Like [nwkcomponents](nwkcomponents.md), blocks can genuinely overlap (a cutset remains a shared member of every sub-block its removal reveals) and nest (a child block's own node set is always a strict subset of its parent's), so the complete structure is returned via **r(cohesion_matrix)** (a blocks-by-nodes 0/1 membership matrix, one row per block found at ANY level of the hierarchy) and **r(cohesion_levels)** (a parallel column vector giving each row's own connectivity level). `generate(newvarname)` (default *_cohesion*) stores, per node, the HIGHEST level of any block that node belongs to - the standard node-level structural-cohesion summary statistic - and is always well-defined for every node (even an isolate gets its own top-block level, typically 0), unlike [nwkcomponents](nwkcomponents.md)' own *_kcompnum*, which is missing for nodes that don't qualify for the one requested `k(int)`.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcohesion flomarriage
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity has no directed generalization here, matching [nwkcomponents](nwkcomponents.md)). Weighted: not used. Signed: not checked. Two-mode: not checked. Computationally more expensive than a single [nwkcomponents](nwkcomponents.md) call, since each block found is itself recursively re-decomposed - fine for the moderate network sizes typical of SNA datasets.

## Stored results

**Scalars**

- **r(blocks)** number of cohesive blocks found across the whole hierarchy

**Matrices**

- **r(cohesion_matrix)** blocks-by-nodes 0/1 membership matrix, one row per block at any level
- **r(cohesion_levels)** blocks-by-1 column vector of each row's own connectivity level

## References

Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of social groups. *American Sociological Review* 68(1), 103-127.

Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. *Networks* 23(6), 533-541.

Even, S. (1979). *Graph Algorithms*. Computer Science Press. (the vertex-splitting max-flow reduction for vertex connectivity)

## See also

- [nwkcomponents](nwkcomponents.md), [nwcomponents](nwcomponents.md), [nwclique](nwclique.md), [nwkplex](nwkplex.md)

- last certified : 22 Aug 2026
