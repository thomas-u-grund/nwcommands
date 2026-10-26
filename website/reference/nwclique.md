---
title: "nwclique"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Maximal clique enumeration"
---

# `nwclique`

Maximal clique enumeration

## Syntax

```stata
nwclique
[netlist]
[,
generate(newvarname)
replace
minsize(int)
nomatrix
silent]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's largest maximal-clique membership size |
| `replace` | Replace existing variable |
| `minsize(int)` | Smallest clique size to report; default = 3 |
| `nomatrix` | Do not store **r(clique_matrix)**; the `generate(newvarname)` variable and **r(cliques)** are still returned |
| `silent` | Suppress display of results |

## Description

`nwclique` enumerates every maximal clique in the network(s) in [netlist](netlist) - a clique is a set of nodes in which every pair is mutually tied; a clique is *maximal* if no further node could be added to it without breaking that property. Enumeration uses the classical Bron and Kerbosch (1973) recursive algorithm.

Cliques are fundamentally different from the partitions [nwcomponents](nwcomponents)/[nwcommunity](nwcommunity)/ [nwconcor](nwconcor) generate: a node can belong to *several* overlapping maximal cliques at once (as in the classic example of two triangles sharing an edge), so there is no single clique-membership variable to generate the way there is a single component or community id. Instead, `nwclique` generates a variable holding, for each node, the size of the *largest* maximal clique it belongs to (its "clique number") - a single, well-defined per-node summary - and returns the full clique list (as a cliques-by-nodes 0/1 membership matrix) in **r(clique_matrix)** for anyone who needs the complete overlapping structure rather than just this summary.

`minsize(int)` filters out cliques smaller than the given size before generating and returning results (a dyad - two mutually tied nodes with no further extension - is technically a maximal clique of size 2, and an isolated node with no ties at all is technically one of size 1; the default of 3 excludes both, matching the common convention that a "clique" worth reporting has at least three members). A node that belongs to no clique meeting `minsize(int)` gets a missing value in the generated variable, not a spurious 0.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwclique flomarriage, generate(_cliquenum)
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (a clique's own definition - every pair mutually tied - has no directed generalization, the same reasoning [nwcoreperiphery](nwcoreperiphery) already applies). Weighted: not used - only presence/absence of a tie matters; tie strength does not affect clique membership. Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); cliques of three or more nodes cannot exist in a bipartite graph. Maximal clique enumeration is worst-case exponential in the number of maximal cliques a graph can have (a mathematical property of the problem itself, true of any correct algorithm) - fine for the moderate network sizes typical of SNA datasets, but a very dense, large network could take a long time. [nwnclique](nwnclique), [nwnclan](nwnclan) and [nwkplex](nwkplex) have the options `maxcliques()` / `maxplexes()`, `maxtime()`, `countonly` and `nomatrix` for such searches; `nwclique` has none.

## Stored results

**Scalars**

- **r(cliques)** number of maximal cliques found meeting `minsize(int)`

**Matrices**

- **r(clique_matrix)** cliques-by-nodes 0/1 membership matrix, one row per maximal clique (not with `nomatrix`)

## References

Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph. *Communications of the ACM* 16(9), 575-577.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwkplex](nwkplex), [nwnclique](nwnclique), [nwnclan](nwnclan), [nwkcomponents](nwkcomponents), [nwkcore](nwkcore), [nwcomponents](nwcomponents), [nwcommunity](nwcommunity), [nwconcor](nwconcor)

- last certified : 21 Aug 2026

---

*nwcommands version 3.7.0, 26 October 2026* ([check your installed version](nwversion))
