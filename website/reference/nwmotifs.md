---
title: "nwmotifs"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "4-node undirected motif/graphlet census"
---

# `nwmotifs`

4-node undirected motif/graphlet census

## Syntax

```stata
nwmotifs
[netname]
[,
silent
plot
name(string)]
```

| | |
|---|---|
| `silent` | Suppress display of results |
| `plot` | Draw a bar chart of the 7 category counts |
| `name(string)` | Name for the graph created by `plot`; default = **motifs** |

## Description

`nwmotifs` classifies every induced 4-node subgraph of the network into one of 6 "motif" shapes (Milo et al. 2002's own term for a small, recurring, structurally-distinct connectivity pattern), plus a residual bucket for the other, disconnected 4-node cases - the same "every case exhaustively accounted for" census convention [nwtriads](nwtriads)'s own 3-node MAN census already established one dimension down, generalized here to 4 nodes.

The 6 connected shapes, by increasing edge count:

- path = a-b-c-d, an open 3-edge chain (degrees 1,2,2,1)
- star = a tied to b, c, and d, with b/c/d mutually untied (degrees 3,1,1,1)
- cycle = a-b-c-d-a, a closed 4-edge square (degrees 2,2,2,2)
- paw = a triangle plus one pendant tie (degrees 3,2,2,1)
- diamond = the complete graph on 4 nodes minus one edge (degrees 3,3,2,2)
- k4 = the complete graph on 4 nodes (degrees 3,3,3,3)

Every other 4-node induced subgraph (empty, a single tie, either of the two 2-edge shapes, or a triangle plus an isolated 4th node) is disconnected and is reported under **disconnected** instead - none of these is a meaningful connected structural pattern in the motif sense. **path**+**star**+**cycle**+**paw**+**diamond**+**k4**+**disconnected** always sums to exactly the total number of 4-node combinations in the network.

Classified by (edge count, sorted degree sequence) alone - a COMPLETE invariant for 4-node graphs (every one of the 11 non-isomorphic 4-vertex graphs has its own unique combination of the two), so no general graph-isomorphism check is needed.

`nwmotifs` reports a plain census with no significance test of its own - it needs none: because every count is published as an ordinary `r()` scalar, [nwcug](nwcug)'s existing `stat()`/`rname()` template machinery already works against it unmodified, the same "compose with existing infrastructure" pattern [nwlambda](nwlambda) uses with [nwhierarchy](nwhierarchy). To test whether a shape is over- or under-represented relative to a random graph of the same size and density:

- `. nwcug mynet, stat(nwmotifs ##net##, silent) rname(cycle) condition(density)`

substituting **path**/**star**/**cycle**/**paw**/**diamond**/**k4** for whichever shape's prevalence is of interest, and `condition(census)` for a directed network to hold the mutual/asymmetric/null dyad counts fixed instead of just density (see [nwcug](nwcug) for the full set of conditioning/tail/reps options this test supports).

`plot` draws a bar chart of the 7 category counts, via this package's own established preserve/rebuild-a-plotting-dataset/restore convention - the same one [nwcug](nwcug)'s own `plot` option and [nwtriads](nwtriads)'s own `plot` option (its 3-node analogue) use. Grayscale by design, matching every other plot this package produces.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwmotifs flomarriage
. nwcug flomarriage, stat(nwmotifs ##net##, silent) rname(cycle) condition(density)
```

## Supported network types

Binary: yes. Directed: the command still runs, but every tie is treated as undirected (a directed 4-node census has 218 distinct isomorphism classes and is not attempted here); a note is printed to this effect. Weighted: not applicable (a motif census is inherently a binary count). Signed: not checked. Two-mode: not checked. Requires at least 4 nodes.

`nwmotifs` enumerates every 4-node combination explicitly (O(n^4)) - fine for the moderate network sizes typical of SNA datasets, but not specially guarded against for very large networks, the same disclosed scaling limitation [nwclique](nwclique)'s own maximal-clique enumeration and [nwfactions](nwfactions)'s own combinatorial search already carry.

## Stored results

**Scalars**

- **r(path)** count of 4-node path (P4) subgraphs
- **r(star)** count of 4-node star (K1,3) subgraphs
- **r(cycle)** count of 4-node cycle (C4/square) subgraphs
- **r(paw)** count of paw (triangle + pendant) subgraphs
- **r(diamond)** count of diamond (K4 minus one edge) subgraphs
- **r(k4)** count of complete-graph (K4) subgraphs
- **r(disconnected)** count of every other, disconnected 4-node case

**Macros**

- **r(netname)** name of the network

## References

Milo, R., Shen-Orr, S., Itzkovitz, S., Kashtan, N., Chklovskii, D., Alon, U. (2002). Network Motifs: Simple Building Blocks of Complex Networks. *Science* 298(5594), 824-827.

## See also

- [nwtriads](nwtriads), [nwcug](nwcug), [nwclustering](nwclustering)

- last certified : 31 Aug 2026
