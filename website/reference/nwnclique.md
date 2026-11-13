---
title: "nwnclique"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Maximal n-clique enumeration"
---

# `nwnclique`

Maximal n-clique enumeration

## Syntax

```stata
nwnclique
[netlist]
[,
n(int)
gen:erate(newvarname)
replace
minsize(int)
max:cliques(#)
maxt:ime(#)
count:only
nom:atrix
silent]
```

| | |
|---|---|
| `n(int)` | Maximum geodesic distance allowed between any two members; default = 2 |
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's largest maximal-n-clique membership size; with several networks the variables are numbered (*newvarname***1**, *newvarname***2**, ...) |
| `replace` | Replace existing variable |
| `minsize(int)` | Smallest n-clique size to report; default = 3 |
| `max:cliques(#)` | Stop with an error when more than this many maximal n-cliques of at least `minsize()` members are found (the result matrix needs sets x nodes numbers); default = 100,000 |
| `maxt:ime(#)` | Stop with an error when the search has run for this many seconds without finishing; default = 60 |
| `count:only` | Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; `gen:erate(newvarname)` is then not needed |
| `nom:atrix` | Do not build the sets-by-nodes matrix; the `gen:erate(newvarname)` variable and the count are still returned |
| `silent` | Suppress display of results |

## Description

`nwnclique` enumerates every maximal n-clique in the network(s) in [netlist](netlist) - a generalization of an ordinary clique (Luce 1950) where every pair of members need only be within geodesic distance `n(int)` of *each other in the network as a whole*, rather than directly tied. A plain clique is the special case `n(int)`=1 (distance-1 "neighbors" are exactly direct ties) - [nwclique](nwclique) already handles that case with a cheaper, purpose-built algorithm, so `nwnclique` requires `n(int)` >= 2.

Because n-clique membership is judged by whole-network distance, a pair of members can qualify even though the shortest path between them runs through a node that is not itself part of the n-clique - a well-known limitation of the concept (Alba 1973): an n-clique's own members are not guaranteed to be reachable from one another *while staying inside the group*. [nwnclan](nwnclan) adds exactly that extra requirement.

Like cliques, n-cliques genuinely overlap - a node can belong to several at once - so `nwnclique` follows [nwclique](nwclique)'s own output shape: a single per-node "largest maximal n-clique membership size" summary variable (`gen:erate(newvarname)`, required), plus the complete overlapping structure in **r(nclique_matrix)** (an n-cliques-by-nodes 0/1 membership matrix) and **r(ncliques)** (count). `minsize(int)` filters out n-cliques smaller than the given size before generating and returning results, matching [nwclique](nwclique)'s own default of 3 (a dyad or an isolated node is technically a maximal n-clique too, but rarely what "n-clique" is meant to convey). A node that belongs to no n-clique meeting `minsize(int)` gets a missing value in the generated variable, not a spurious 0.

## Network types

**Directed:** symmetrized. **Valued:** tie values are ignored (the command prints a note on a valued network); `n()` counts steps. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

**Feasible sizes.** The graph "distance at most *n*" is built as bitsets by a breadth-first search from every node and searched with the same pivoting Bron-Kerbosch rule, in compiled code. What limits the command is the number of maximal n-cliques, not the size of the network: with `n(2)` almost every node reaches almost every other within two steps, the "distance at most 2" graph is dense, and its maximal cliques are very many. Measured in Stata/BE on a random network with 10 ties drawn per node and `n(2)`: 100 nodes already have 46,580,136 maximal 2-cliques of at least 3 nodes (up to 64 nodes each; counting them with `countonly` takes 33 seconds, and the result matrix would need 37 GB), so the output of the command, not its running time, is out of reach from about 100 nodes on. Sparser or smaller networks, a larger `minsize()` and path-like networks (long distances, few short cycles) are fine.

**Guards.** The command stops at once with r(484) and a message that names the option to raise when it has found more than `maxcliques()` maximal n-cliques (default 100,000), when the result matrix would be too large to build (more than 50 million numbers; use `nomatrix`), or when the search has run for `maxtime()` seconds (default 60). `countonly` counts and tabulates the sets by size without storing them.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## Examples

```stata
. nwwebuse florentine, nwclear
. nwnclique flomarriage, generate(_ncliquenum)
. nwnclique flomarriage, n(3) generate(_ncliquenum) replace
```

## Stored results

- **Scalars**
- **r(ncliques)** --- number of maximal n-cliques found meeting `minsize(int)`
- **r(maxsize)** --- size of the largest set (with `countonly` or `nomatrix`)

- **Matrices**
- **r(size_table)** --- (with `countonly` or `nomatrix`) sizes and the number of sets of each size
- **r(nclique_matrix)** --- n-cliques-by-nodes 0/1 membership matrix, one row per maximal n-clique (not with `countonly` or `nomatrix`)

## References

Luce, R.D. (1950). Connectivity and generalized cliques in sociometric group structure. *Psychometrika* 15(2), 169-190.

Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. *Journal of Mathematical Sociology* 3(1), 113-126.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwnclan](nwnclan), [nwclique](nwclique), [nwkplex](nwkplex), [nwkcomponents](nwkcomponents), [nwgeodesic](nwgeodesic), [nwkcore](nwkcore)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
