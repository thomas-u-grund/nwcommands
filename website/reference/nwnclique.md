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
generate(newvarname)
replace
minsize(int)
maxcliques(#)
maxtime(#)
countonly
nomatrix
silent]
```

| | |
|---|---|
| `n(int)` | Maximum geodesic distance allowed between any two members; default = 2 |
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's largest maximal-n-clique membership size |
| `replace` | Replace existing variable |
| `minsize(int)` | Smallest n-clique size to report; default = 3 |
| `maxcliques(#)` | Stop with an error when more than this many maximal n-cliques of at least `minsize()` members are found (the result matrix needs sets x nodes numbers); default = 100,000 |
| `maxtime(#)` | Stop with an error when the search has run for this many seconds without finishing; default = 60 |
| `countonly` | Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; `generate(newvarname)` is then not needed |
| `nomatrix` | Do not build the sets-by-nodes matrix; the `generate(newvarname)` variable and the count are still returned |
| `silent` | Suppress display of results |

## Description

`nwnclique` enumerates every maximal n-clique in the network(s) in [netlist](netlist) - a generalization of an ordinary clique (Luce 1950) where every pair of members need only be within geodesic distance `n(int)` of *each other in the network as a whole*, rather than directly tied. A plain clique is the special case `n(int)`=1 (distance-1 "neighbors" are exactly direct ties) - [nwclique](nwclique) already handles that case with a cheaper, purpose-built algorithm, so `nwnclique` requires `n(int)` >= 2.

Because n-clique membership is judged by whole-network distance, a pair of members can qualify even though the shortest path between them runs through a node that is not itself part of the n-clique - a well-known limitation of the concept (Alba 1973): an n-clique's own members are not guaranteed to be reachable from one another *while staying inside the group*. [nwnclan](nwnclan) adds exactly that extra requirement.

Like cliques, n-cliques genuinely overlap - a node can belong to several at once - so `nwnclique` follows [nwclique](nwclique)'s own output shape: a single per-node "largest maximal n-clique membership size" summary variable (`generate(newvarname)`, required), plus the complete overlapping structure in **r(nclique_matrix)** (an n-cliques-by-nodes 0/1 membership matrix) and **r(ncliques)** (count). `minsize(int)` filters out n-cliques smaller than the given size before generating and returning results, matching [nwclique](nwclique)'s own default of 3 (a dyad or an isolated node is technically a maximal n-clique too, but rarely what "n-clique" is meant to convey). A node that belongs to no n-clique meeting `minsize(int)` gets a missing value in the generated variable, not a spurious 0.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwnclique flomarriage, generate(_ncliquenum)
. nwnclique flomarriage, n(3) generate(_ncliquenum) replace
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (an n-clique's own definition has no directed generalization, the same reasoning [nwclique](nwclique)/[nwkplex](nwkplex) already apply). Weighted: not used for membership - `n(int)` counts hops, not tie strength, though the underlying distance calculation ([nwgeodesic](nwgeodesic)'s own unweighted, `alpha(0)`-equivalent convention) is unaffected by weight either way. Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation). Maximal n-clique enumeration inherits [nwclique](nwclique)'s own worst-case exponential behaviour (a mathematical property of maximal-clique-family problems in general).

## Stored results

**Scalars**

- **r(ncliques)** number of maximal n-cliques found meeting `minsize(int)`
- **r(maxsize)** size of the largest set (with `countonly` or `nomatrix`)

**Matrices**

- **r(size_table)** (with `countonly` or `nomatrix`) sizes and the number of sets of each size
- **r(nclique_matrix)** n-cliques-by-nodes 0/1 membership matrix, one row per maximal n-clique (not with `countonly` or `nomatrix`)

## References

Luce, R.D. (1950). Connectivity and generalized cliques in sociometric group structure. *Psychometrika* 15(2), 169-190.

Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. *Journal of Mathematical Sociology* 3(1), 113-126.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwnclan](nwnclan), [nwclique](nwclique), [nwkplex](nwkplex), [nwkcomponents](nwkcomponents), [nwgeodesic](nwgeodesic), [nwkcore](nwkcore)

- last certified : 24 Aug 2026

---

*nwcommands version 3.6.0, 26 October 2026* ([check your installed version](nwversion))
