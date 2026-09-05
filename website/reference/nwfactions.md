---
title: "nwfactions"
parent: "Command reference"
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
[,
groups(int)
generate(newvarname)
replace
measure(binary|valued)
maxiter(int)
silent]
```

| | |
|---|---|
| `groups(int)` | Number of factions to partition nodes into; must be between 2 and the number of nodes; default = 2 |
| `generate(newvarname)` | Name of the Stata variable that stores each node's faction membership (1..`groups()`); default = *_faction* |
| `replace` | Replace existing variable |
| `measure(binary\|valued)` | Whether tie VALUES enter the fitness calculation, or only tie presence/absence; default follows whether the network itself is valued |
| `maxiter(int)` | Maximum number of full local-search sweeps; default 100 |
| `silent` | Suppress display of results |

## Description

`nwfactions` implements UCINET's own classical "factions" technique: partition the nodes into exactly `groups()` groups so as to MAXIMIZE the correlation between the observed tie matrix and the ideal "factions" block pattern (every pair of nodes in the SAME group is tied; every pair in DIFFERENT groups is not). This is the assortative-block-model sibling of [nwcoreperiphery](nwcoreperiphery.md) - the same fitness-correlation idea, generalized from a fixed 2-group core/periphery split (where the ideal pattern is "at least one endpoint is core") to an arbitrary number of symmetric, equally-treated groups (where the ideal pattern is "both endpoints share a group").

Optimized via greedy local search, the same general shape [nwcommunity](nwcommunity.md)'s own Louvain algorithm and [nwcoreperiphery](nwcoreperiphery.md) both already use: seed by sorting nodes by degree (descending) and assigning them to groups round-robin (spreading high- and low-degree nodes evenly across every group, rather than an arbitrary block split), then repeatedly try moving each node (fixed 1..n order, for reproducibility) to every OTHER group, keeping whichever single move most improves the fitness correlation, until a full sweep produces no further improvement or `maxiter()` sweeps are reached. This is a greedy local optimum, not a guaranteed global one - the discrete factions problem is combinatorial, the same character of problem Louvain's own greedy search already accepts for modularity. A real, disclosed v1 scope choice: unlike [nwcoreperiphery](nwcoreperiphery.md)'s own later performance pass (an O(n) incremental fitness update for its 2-group case), each candidate move here recomputes the full fitness correlation directly - fine for the moderate network sizes typical of SNA datasets, not yet optimized for very large ones.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwfactions flomarriage, groups(3)
. tab _faction
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (the classical factions definition does not distinguish in-ties from out-ties, the same choice [nwcoreperiphery](nwcoreperiphery.md) already makes). Weighted: yes, via `measure(valued)` - tie VALUES then enter the fitness correlation directly rather than just their presence/absence. Signed: not checked. Two-mode: not checked.

## Stored results

**Scalars**

- **r(fitness)** correlation between the observed network and the ideal factions block pattern (1 = perfect fit)
- **r(groups)** number of groups requested

**Macros**

- **r(netgenerate)** name of the generated faction-membership variable

## References

Borgatti, S.P., Everett, M.G., Freeman, L.C. (2002). *UCINET for Windows: Software for Social Network Analysis*. Analytic Technologies. (Factions routine)

## See also

- [nwcoreperiphery](nwcoreperiphery.md), [nwcommunity](nwcommunity.md), [nwconcor](nwconcor.md), [nwlambda](nwlambda.md)

- last certified : 31 Aug 2026
