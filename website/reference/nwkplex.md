---
title: "nwkplex"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Maximal k-plex enumeration"
---

# `nwkplex`

Maximal k-plex enumeration

## Syntax

```stata
nwkplex
[netlist]
[,
k(int)
gen:erate(newvarname)
replace
minsize(int)
maxp:lexes(#)
maxt:ime(#)
count:only
nom:atrix
silent]
```

| | |
|---|---|
| `k(int)` | How many ties each member may miss; default = 2 |
| `gen:erate(newvarname)` | Name of the Stata variable that stores each node's largest maximal-k-plex membership size; default = *_kplexnum*; with several networks the variables are numbered (*newvarname***1**, *newvarname***2**, ...) |
| `replace` | Replace existing variable |
| `minsize(int)` | Smallest k-plex size to report; default = *k*+1 |
| `maxp:lexes(#)` | Stop with an error when more than this many maximal k-plexes of at least `minsize()` members are found (the result matrix needs sets x nodes numbers); default = 100,000 |
| `maxt:ime(#)` | Stop with an error when the search has run for this many seconds without finishing; default = 60 |
| `count:only` | Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; `gen:erate(newvarname)` is then not needed |
| `nom:atrix` | Do not build the sets-by-nodes matrix; the `gen:erate(newvarname)` variable and the count are still returned |
| `silent` | Suppress display of results |

## Description

`nwkplex` enumerates every maximal k-plex in the network(s) in [netlist](netlist) - a "relaxed clique": a set of nodes in which every member is tied to all but at most `k(int)` - 1 of the *other* members (a plain clique is the special case `k`=1, where nobody may miss any tie - [nwclique](nwclique) already handles that case with a cheaper, purpose-built algorithm, so `nwkplex` requires `k(int)` >= 2). A k-plex is *maximal* if no further node could be added to it without breaking that property. Enumeration uses the same Bron and Kerbosch (1973)-style recursive backtracking [nwclique](nwclique) uses, generalized to the k-plex membership rule (Seidman and Foster 1978).

Like cliques, k-plexes genuinely overlap - a node can belong to several at once - so there is no single per-node k-plex-membership variable the way there is a single component or community id. `nwkplex` generates a variable holding, for each node, the size of the *largest* maximal k-plex it belongs to - a single, well-defined per-node summary - and returns the full k-plex list (as a k-plexes-by-nodes 0/1 membership matrix) in **r(kplex_matrix)** for anyone who needs the complete overlapping structure.

`minsize(int)` filters out k-plexes smaller than the given size before generating and returning results. This matters more for k-plexes than for cliques: by the formal definition above, *any* set of `k(int)` or fewer nodes is trivially a valid k-plex regardless of whether its members are tied at all (with `k(int)`=2, for example, any two nodes - tied or not - miss at most 1 of their 1 possible tie, satisfying the rule) - such tiny, structurally-uninteresting sets are usually not what "k-plex" is meant to capture. The default of *k*+1 is the smallest size at which the constraint can actually rule anything out, so it excludes every automatically-valid, uninformative case while still reporting the smallest *genuinely* constrained k-plexes. A node that belongs to no k-plex meeting `minsize(int)` gets a missing value in the generated variable, not a spurious 0.

## Network types

**Directed:** symmetrized. **Valued:** tie values are ignored and a note is printed. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

**Feasible sizes.** The search runs in compiled code on bitset adjacency. It is limited by the number of maximal k-plexes, which can be enormous (any set of `k` or fewer nodes is a k-plex, and large sparse networks have very many bigger ones), and by the sets-by-nodes matrix **r(kplex_matrix)**, which needs sets x nodes numbers. Measured in Stata/BE on a random network with 10 ties drawn per node, `k(2)`, `minsize(3)`: 100 nodes have 10,141 maximal 2-plexes (0.2 s), 300 nodes 31,081 (2.1 s, nearly all of it building the 31,081 x 300 matrix; 0.04 s with `nomatrix`), 1,000 nodes 148,070 (0.2 s with `nomatrix`), 5,000 nodes (2.9 s with `nomatrix`; 1.9 s with `countonly`). For `k(3)`, 300 nodes have 3,968,148 maximal 3-plexes, counted in 0.5 s.

**Guards.** The command stops with r(484) and a message that names the option to raise when it has found more than `maxplexes()` maximal k-plexes (default 100,000), when the result matrix would be too large to build (more than 50 million numbers; use `nomatrix`), or when the search has run for `maxtime()` seconds (default 60) without finishing. `countonly` does not store the sets and is not limited by memory; `nomatrix` keeps the per-node variable and the counts but not the matrix.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkplex flomarriage
. nwkplex flomarriage, k(3) replace
```

## Stored results

- **Scalars**
- **r(kplexes)** --- number of maximal k-plexes found meeting `minsize(int)`
- **r(maxsize)** --- size of the largest set (with `countonly` or `nomatrix`)

- **Matrices**
- **r(size_table)** --- (with `countonly` or `nomatrix`) sizes and the number of sets of each size
- **r(kplex_matrix)** --- k-plexes-by-nodes 0/1 membership matrix, one row per maximal k-plex (not with `countonly` or `nomatrix`)

## References

Seidman, S.B., Foster, B.L. (1978). A graph-theoretic generalization of the clique concept. *Journal of Mathematical Sociology* 6(1), 139-154.

Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph. *Communications of the ACM* 16(9), 575-577.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwclique](nwclique), [nwnclique](nwnclique), [nwnclan](nwnclan), [nwkcomponents](nwkcomponents), [nwkcore](nwkcore), [nwcomponents](nwcomponents), [nwcommunity](nwcommunity), [nwconcor](nwconcor)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
