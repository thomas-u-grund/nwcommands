---
title: "nwconcor"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "CONCOR structural-equivalence blockmodel"
---

# `nwconcor`

CONCOR structural-equivalence blockmodel

## Syntax

```stata
nwconcor
[netlist]
[,
generate(newvarname)
replace
splits(int)
measure(string)
maxiter(int)
silent
force]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores block membership |
| `replace` | Replace existing variable |
| `splits(int)` | Number of recursive bisections; final number of blocks is up to 2^*splits*; default = 1 |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `maxiter(int)` | Maximum number of correlation iterations per split before giving up on convergence; default = 25 |
| `silent` | Suppress display of results |
| `force` | Run a network with more than 6,000 nodes |

## Description

`nwconcor` partitions the nodes of a network into structurally equivalent blocks using CONCOR (CONvergence of iterated CORrelations - Breiger, Boorman and Arabie 1975). Each node's tie profile (its outgoing ties stacked on its incoming ties, excluding the tie to itself) is correlated against every other node's profile; this correlation matrix is then repeatedly re-correlated with itself. For well-separated block structure this process converges to a matrix of exactly +1/-1 entries, from which nodes are split into two groups based on the sign of their correlation with a reference node. Unlike methods that require an undirected network (e.g. [nwcommunity](nwcommunity)), CONCOR is defined directly for directed data, since a node's profile already keeps its outgoing and incoming ties separate.

With `splits(1)` (the default) `nwconcor` performs a single bisection, producing 2 blocks. With `splits(k)`, each resulting block from the previous level is independently re-split using only the ties among its own members, producing up to 2^*k* blocks in total - this is the classical recursive CONCOR procedure, not merely applying a single bisection *k* times to the whole network. A block that cannot be split further (all of its members end up on the same side of its own bisection, or all of its members only tie to nodes *outside* the block, leaving no internal structure to split on) simply stays as one block rather than being forced apart - `nwconcor` may therefore return fewer than 2^*splits* blocks; **r(blocks)** always reports the actual number found.

`generate()` is required and names the new variable that stores, for each node, the id of the block it was assigned to. With more than one network in the *netlist*, a number is appended to the name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

A node with no ties at all (in any direction) has no tie profile to compare against anyone else's, so `nwconcor` requires every node to have at least one tie; remove isolates first (see [nwdropnodes](nwdropnodes)) if your network has any.

## Examples

```stata
. nwwebuse florentine, nwclear
. * pucci is an isolate in this network - CONCOR requires every node to have a tie
. nwdropnodes flomarriage, nodes(pucci) generate(flomarriage2)
. nwconcor flomarriage2, generate(_concor)

. nwconcor flomarriage2, splits(2) generate(_concor) replace
```

## Stored results

- **Scalars**
- **r(blocks)** --- number of blocks actually found (up to 2^*splits*)

- **Matrices**
- **r(block_sizeid)** --- distribution over blocks: one row per block with the columns size, blockid and share

## References

Breiger, R.L., Boorman, S.A., Arabie, P. (1975). An algorithm for clustering relational data with applications to social network analysis and comparison with multidimensional scaling. *Journal of Mathematical Psychology* 12(3), 328-383.

## See also

- [nwsimilar](nwsimilar), [nwdissimilar](nwdissimilar), [nwhierarchy](nwhierarchy), [nwcommunity](nwcommunity)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
