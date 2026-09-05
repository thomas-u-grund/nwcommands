---
title: "nwnclan"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Maximal n-clan enumeration"
---

# `nwnclan`

Maximal n-clan enumeration

## Syntax

```stata
nwnclan
[netlist]
[,
n(int)
generate(newvarname)
replace
minsize(int)
silent]
```

| | |
|---|---|
| `n(int)` | Maximum geodesic distance allowed between any two members; default = 2 |
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's largest maximal-n-clan membership size |
| `replace` | Replace existing variable |
| `minsize(int)` | Smallest n-clan size to report; default = 3 |
| `silent` | Suppress display of results |

## Description

`nwnclan` enumerates every maximal n-clan (Mokken 1979) in the network(s) in [netlist](netlist.md) - an [n-clique](nwnclique.md) (see that command for the base concept and `n(int)`) that additionally requires every pair of its own members to be reachable from one another *while staying inside the group*, within `n(int)` steps. An ordinary n-clique only guarantees each pair's shortest path in the *whole* network is within `n(int)` - that path may run through a node that is not itself one of the n-clique's own members, a known limitation of the plain n-clique concept (Alba 1973). n-clans fix exactly that: every member must be able to reach every other member using only paths that never leave the group.

`nwnclan` works by first enumerating every maximal n-clique (the same computation [nwnclique](nwnclique.md) itself performs) and then keeping only the ones whose own induced subgraph - built from the *original* network, restricted to just that n-clique's members - has every pair of members within `n(int)` steps of *each other, using only ties between members*. This matches the standard treatment of n-clans in the literature: a maximal n-clique that fails this check is simply not reported as a clan at all, rather than being replaced with some smaller, clan-qualifying subset of itself - a genuine, deliberate limitation of the concept, not a shortcut taken here. Every n-clan is therefore also an n-clique, but not every n-clique is an n-clan; on a network with no "shortcut" structure (e.g. a network where every node's shortest paths to everyone else already stay within whatever locally-dense region it belongs to) the two coincide exactly.

Like n-cliques, n-clans genuinely overlap, so `nwnclan` follows [nwnclique](nwnclique.md)'s own output shape: a single per-node "largest maximal n-clan membership size" summary variable (`generate(newvarname)`, required), plus the complete overlapping structure in **r(nclan_matrix)** and **r(nclans)**. `minsize(int)` defaults to 3, matching [nwclique](nwclique.md)/[nwnclique](nwnclique.md).

## Examples

```stata
. nwwebuse florentine, nwclear
. nwnclan flomarriage, generate(_nclannum)
. nwnclan flomarriage, n(3) generate(_nclannum) replace
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (same reasoning [nwnclique](nwnclique.md) already applies). Weighted: not used for membership. Signed: not checked. Two-mode: not checked. Inherits [nwnclique](nwnclique.md)'s own worst-case exponential enumeration cost, plus an additional per-candidate induced-subgraph diameter check - fine for the moderate network sizes typical of SNA datasets.

## Stored results

**Scalars**

- **r(nclans)** number of maximal n-clans found meeting `minsize(int)`

**Matrices**

- **r(nclan_matrix)** n-clans-by-nodes 0/1 membership matrix, one row per maximal n-clan

## References

Mokken, R.J. (1979). Cliques, clubs and clans. *Quality and Quantity* 13(2), 161-173.

Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. *Journal of Mathematical Sociology* 3(1), 113-126.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwnclique](nwnclique.md), [nwclique](nwclique.md), [nwkplex](nwkplex.md), [nwkcomponents](nwkcomponents.md), [nwgeodesic](nwgeodesic.md), [nwkcore](nwkcore.md)

- last certified : 24 Aug 2026
