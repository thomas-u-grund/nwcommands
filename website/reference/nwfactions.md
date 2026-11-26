---
title: "nwfactions"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Partition nodes into a specified number of cohesive factions"
---

# `nwfactions`

Partition nodes into a specified number of cohesive factions

## Syntax

```stata
nwfactions
[netname]
,
gen:erate(newvarname)
[groups(int)
replace
measure(binary|valued)
maxiter(int)
sym
silent]
```

| | |
|---|---|
| `sym` | On a directed network, analyse the symmetrized network (a tie counts in both directions, with the larger of its two values); without it a directed network with unreciprocated ties is refused (error 198) |
| `groups(int)` | Number of factions to partition nodes into; must be between 2 and the number of nodes; default = 2 |
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's faction membership (1..`groups()`) |
| `replace` | Replace existing variable |
| `measure(binary\|valued)` | Whether tie VALUES enter the fitness calculation, or only tie presence/absence; default follows whether the network itself is valued |
| `maxiter(int)` | Maximum number of full local-search sweeps; default 100 |
| `silent` | Suppress display of results |

## Description

`nwfactions` implements UCINET's own classical "factions" technique: partition the nodes into exactly `groups()` groups so as to MAXIMIZE the correlation between the observed tie matrix and the ideal "factions" block pattern (every pair of nodes in the SAME group is tied; every pair in DIFFERENT groups is not). This is the assortative-block-model sibling of [nwcoreperiphery](nwcoreperiphery) - the same fitness-correlation idea, generalized from a fixed 2-group core/periphery split (where the ideal pattern is "at least one endpoint is core") to an arbitrary number of symmetric, equally-treated groups (where the ideal pattern is "both endpoints share a group").

Optimized via greedy local search, the same general shape [nwcommunity](nwcommunity)'s own Louvain algorithm and [nwcoreperiphery](nwcoreperiphery) both already use: seed by sorting nodes by degree (descending) and assigning them to groups round-robin (spreading high- and low-degree nodes evenly across every group, rather than an arbitrary block split), then repeatedly try moving each node (fixed 1..n order, for reproducibility) to every OTHER group, keeping whichever single move most improves the fitness correlation, until a full sweep produces no further improvement or `maxiter()` sweeps are reached. This is a greedy local optimum, not a guaranteed global one - the discrete factions problem is combinatorial, the same character of problem Louvain's own greedy search already accepts for modularity.

**Starting partition.** Nodes with the same degree are taken in the order of their node number, so the same call always gives the same partition. The fitness of a candidate move is computed from the total tie weight inside the groups and the number of same-group pairs, which takes time proportional to the node's degree plus the number of groups, not to the square of the number of nodes; `r(fitness)` agrees with a direct computation of the correlation to rounding error (about 1e-15).

## Network types

**Directed:** refused (error 198) when some ties are not reciprocated, because the measure is defined for an undirected network; option `sym` analyses the symmetrized network (a tie counts in both directions, with the larger of its two values) and the output says so. A directed network whose ties are all reciprocated is the same as an undirected one and is analysed as such (the output says so). **Valued:** the tie values are used by default (`measure(valued)`); `measure(binary)` uses only the presence of ties. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first). **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

The memory needed is proportional to the number of ties; no N-by-N matrix is built.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwfactions flomarriage, groups(3) generate(_faction)
. tab _faction
```
- The adjacency matrix with the nodes ordered by faction, the factions as blocks ([nwplotmatrix](nwplotmatrix)):

```stata
. nwplotmatrix flomarriage, sortby(_faction) group(_faction)
```

## Stored results

- **Scalars**
- **r(fitness)** --- correlation between the observed network and the ideal factions block pattern (1 = perfect fit)
- **r(groups)** --- number of groups requested

- **Macros**
- **r(netgenerate)** --- name of the generated faction-membership variable

## References

Borgatti, S.P., Everett, M.G., Freeman, L.C. (2002). *UCINET for Windows: Software for Social Network Analysis*. Analytic Technologies. (Factions routine)

## See also

- [nwcoreperiphery](nwcoreperiphery), [nwcommunity](nwcommunity), [nwconcor](nwconcor), [nwlambda](nwlambda)

---

*nwcommands version 3.38.0, 26 November 2026* ([check your installed version](nwversion))
