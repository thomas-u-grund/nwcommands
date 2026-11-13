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

Cliques are fundamentally different from the partitions [nwcomponents](nwcomponents) / [nwcommunity](nwcommunity) / [nwconcor](nwconcor) generate: a node can belong to *several* overlapping maximal cliques at once (as in the classic example of two triangles sharing an edge), so there is no single clique-membership variable to generate the way there is a single component or community id. Instead, `nwclique` generates a variable holding, for each node, the size of the *largest* maximal clique it belongs to (its "clique number") - a single, well-defined per-node summary - and returns the full clique list (as a cliques-by-nodes 0/1 membership matrix) in **r(clique_matrix)** for anyone who needs the complete overlapping structure rather than just this summary.

`minsize(int)` filters out cliques smaller than the given size before generating and returning results (a dyad - two mutually tied nodes with no further extension - is technically a maximal clique of size 2, and an isolated node with no ties at all is technically one of size 1; the default of 3 excludes both, matching the common convention that a "clique" worth reporting has at least three members). A node that belongs to no clique meeting `minsize(int)` gets a missing value in the generated variable, not a spurious 0.

With more than one network in the *netlist*, a number is appended to the variable name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

## Network types

**Directed:** symmetrized. **Valued:** tie values are ignored (the command prints a note on a valued network). **Two-mode:** same as for the bipartite graph read as a one-mode network (it has no cliques of three or more nodes). **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

Only the maximal cliques of at least `minsize()` nodes are stored (the maximal cliques of one or two nodes of a sparse network are as many as its ties and would be the bulk of the work). The search (Bron and Kerbosch with pivoting) runs in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both find the same cliques in the same order. Measured in Stata/BE on a random undirected network with 10 ties drawn per node and `minsize(3)`: 5,000 nodes 0.1 seconds, 20,000 nodes 1.0 second (the Mata route needs 0.35 and 3.3 seconds). From about 40,000 nodes on, most of the time is spent in Stata itself, which needs time growing with the square of the number of columns to store the clique matrix `r(clique_matrix)` (one row per clique, one column per node): 100,000 nodes take about one minute, of which the search is 0.6 seconds. A network with many cliques also needs a lot of memory for that matrix. With option `nomatrix` the matrix is not built or stored: the variable and `r(cliques)` are the same, and 100,000 nodes take about a quarter of a second.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

The number of maximal cliques can grow exponentially with the size of a network (true of any algorithm), so a very dense, large network can take a long time; `nwclique` has no `maxcliques()` or `maxtime()` guard as [nwnclique](nwnclique) has.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwclique flomarriage, generate(_cliquenum)
```

## Stored results

- **Scalars**
- **r(cliques)** --- number of maximal cliques found meeting `minsize(int)`

- **Matrices**
- **r(clique_matrix)** --- cliques-by-nodes 0/1 membership matrix, one row per maximal clique (not with `nomatrix`)

## References

Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph. *Communications of the ACM* 16(9), 575-577.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwkplex](nwkplex), [nwnclique](nwnclique), [nwnclan](nwnclan), [nwkcomponents](nwkcomponents), [nwkcore](nwkcore), [nwcomponents](nwcomponents), [nwcommunity](nwcommunity), [nwconcor](nwconcor)

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
