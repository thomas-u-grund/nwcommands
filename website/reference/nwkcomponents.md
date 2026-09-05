---
title: "nwkcomponents"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Maximal k-component enumeration"
---

# `nwkcomponents`

Maximal k-component enumeration

## Syntax

```stata
nwkcomponents
[netlist]
[,
k(int)
generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `k(int)` | Minimum vertex connectivity required; default = 2 |
| `generate(newvarname)` | Name of the Stata variable that stores each node's largest qualifying k-component size; default = *_kcompnum* |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwkcomponents` enumerates every maximal k-component (Kanevsky 1993) in the network(s) in [netlist](netlist.md) - a subgraph with *vertex connectivity* of at least `k(int)`, meaning at least `k(int)` nodes would have to be removed from it to disconnect it (or reduce it to a single node). A k-component is a genuine strengthening of an ordinary connected component (which is just the `k(int)`=1 case - [nwcomponents](nwcomponents.md) already implements that, more cheaply, via a simple reachability search rather than a connectivity computation): `k(int)`=2 excludes single cut-vertices/bridges that would fracture the group, `k(int)`=3 additionally excludes any 2-node cutset, and so on. This directly formalizes the intuition that a group connected only by a single "weak link" is less cohesive than one where *several independent* paths connect every pair of members.

`k(int)` defaults to 2 - the smallest level that is a genuine refinement of [nwcomponents](nwcomponents.md)' own plain connectivity - and must be at least 1 ([nwcomponents](nwcomponents.md) already covers that trivial case directly). Vertex connectivity is computed via the standard node-splitting reduction to max-flow (Even 1979) combined with Menger's theorem (the minimum vertex set separating any two non-adjacent nodes equals the maximum flow between them in the split graph); the network's own overall k-components are then found by the standard recursive decomposition also underlying Moody and White's (2003) cohesive blocking - see [Algorithm](nwkcomponents.md) below for the one respect in which this command deliberately does less than the full Moody-White procedure.

Like cliques/k-plexes/n-cliques/n-clans, k-components can genuinely overlap - the nodes whose removal disconnects a graph (a cutset) remain shared members of every resulting sub-block their removal reveals, not assigned to just one side - so `nwkcomponents` follows the same output shape as [nwclique](nwclique.md)/[nwkplex](nwkplex.md)/[nwnclique](nwnclique.md): a single per-node "largest qualifying k-component size" summary variable (`generate(newvarname)`, default *_kcompnum*), plus the complete overlapping structure in **r(kcomp_matrix)** (a k-components-by-nodes 0/1 membership matrix) and **r(kcomponents)** (count). Unlike those commands there is no `minsize()` - a k-component's own minimum possible size is already `k(int)`+1 (a smaller set cannot reach connectivity `k(int)` at all, since the maximum possible connectivity of an s-node graph is s-1), so there is no equivalent "trivial small case" to filter out separately.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkcomponents flomarriage
. nwkcomponents flomarriage, k(3) replace
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity in the classical Moody-White sense has no directed generalization here, the same reasoning [nwclique](nwclique.md)/ [nwkplex](nwkplex.md)/[nwnclique](nwnclique.md) already apply). Weighted: not used - only tie presence/absence affects connectivity. Signed: not checked. Two-mode: not checked. Vertex-connectivity computation via max-flow is polynomial per pair, but `nwkcomponents` computes it between *every* non-adjacent pair (a deliberately simple, definitely-correct brute-force rather than the smaller reference-vertex subset a more optimized algorithm would use - see [nwclique](nwclique.md)'s own "Supported network types" section for the same trade-off philosophy applied there), and the overall recursive decomposition can call this repeatedly - fine for the moderate network sizes typical of SNA datasets, not recommended for very large or very dense networks.

## Stored results

**Scalars**

- **r(kcomponents)** number of maximal k-components found

**Matrices**

- **r(kcomp_matrix)** k-components-by-nodes 0/1 membership matrix, one row per maximal k-component

## References

Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. *Networks* 23(6), 533-541.

Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of social groups. *American Sociological Review* 68(1), 103-127.

Even, S. (1979). *Graph Algorithms*. Computer Science Press. (the vertex-splitting max-flow reduction for vertex connectivity)

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (k-components and structural cohesion)

## See also

- [nwcomponents](nwcomponents.md), [nwclique](nwclique.md), [nwkplex](nwkplex.md), [nwnclique](nwnclique.md), [nwnclan](nwnclan.md), [nwkcore](nwkcore.md)

- last certified : 24 Aug 2026
