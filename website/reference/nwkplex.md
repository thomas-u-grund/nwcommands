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
generate(newvarname)
replace
minsize(int)
maxplexes(#)
maxtime(#)
countonly
nomatrix
silent]
```

| | |
|---|---|
| `k(int)` | How many ties each member may miss; default = 2 |
| `generate(newvarname)` | Name of the Stata variable that stores each node's largest maximal-k-plex membership size; default = *_kplexnum* |
| `replace` | Replace existing variable |
| `minsize(int)` | Smallest k-plex size to report; default = *k*+1 |
| `maxplexes(#)` | Stop with an error when more than this many maximal k-plexes of at least `minsize()` members are found (the result matrix needs sets x nodes numbers); default = 100,000 |
| `maxtime(#)` | Stop with an error when the search has run for this many seconds without finishing; default = 60 |
| `countonly` | Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; `generate(newvarname)` is then not needed |
| `nomatrix` | Do not build the sets-by-nodes matrix; the `generate(newvarname)` variable and the count are still returned |
| `silent` | Suppress display of results |

## Description

`nwkplex` enumerates every maximal k-plex in the network(s) in [netlist](netlist) - a "relaxed clique": a set of nodes in which every member is tied to all but at most `k(int)` - 1 of the *other* members (a plain clique is the special case `k`=1, where nobody may miss any tie - [nwclique](nwclique) already handles that case with a cheaper, purpose-built algorithm, so `nwkplex` requires `k(int)` >= 2). A k-plex is *maximal* if no further node could be added to it without breaking that property. Enumeration uses the same Bron and Kerbosch (1973)-style recursive backtracking [nwclique](nwclique) uses, generalized to the k-plex membership rule (Seidman and Foster 1978).

Like cliques, k-plexes genuinely overlap - a node can belong to several at once - so there is no single per-node k-plex-membership variable the way there is a single component or community id. `nwkplex` generates a variable holding, for each node, the size of the *largest* maximal k-plex it belongs to - a single, well-defined per-node summary - and returns the full k-plex list (as a k-plexes-by-nodes 0/1 membership matrix) in **r(kplex_matrix)** for anyone who needs the complete overlapping structure.

`minsize(int)` filters out k-plexes smaller than the given size before generating and returning results. This matters more for k-plexes than for cliques: by the formal definition above, *any* set of `k(int)` or fewer nodes is trivially a valid k-plex regardless of whether its members are tied at all (with `k(int)`=2, for example, any two nodes - tied or not - miss at most 1 of their 1 possible tie, satisfying the rule) - such tiny, structurally-uninteresting sets are usually not what "k-plex" is meant to capture. The default of *k*+1 is the smallest size at which the constraint can actually rule anything out, so it excludes every automatically-valid, uninformative case while still reporting the smallest *genuinely* constrained k-plexes. A node that belongs to no k-plex meeting `minsize(int)` gets a missing value in the generated variable, not a spurious 0.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkplex flomarriage
. nwkplex flomarriage, k(3) replace
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (a k-plex's own definition - a bound on each member's own missing-tie count - has no natural directed generalization, the same reasoning [nwclique](nwclique) already applies). Weighted: not used - only presence/absence of a tie matters. Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation). Maximal k-plex enumeration is worst-case exponential (a mathematical property of the problem itself, true of any correct algorithm) and, for a fixed network, generally slower than [nwclique](nwclique)'s own clique enumeration for the same reason its own "Supported network types" section already notes for cliques, compounded further here since checking whether a candidate can still be added requires examining the whole candidate set's own induced structure, not just a simple neighbor lookup. The number of maximal k-plexes is what limits this command, not the size of the network; see **Limits** below.

## Stored results

**Scalars**

- **r(kplexes)** number of maximal k-plexes found meeting `minsize(int)`
- **r(maxsize)** size of the largest set (with `countonly` or `nomatrix`)

**Matrices**

- **r(size_table)** (with `countonly` or `nomatrix`) sizes and the number of sets of each size
- **r(kplex_matrix)** k-plexes-by-nodes 0/1 membership matrix, one row per maximal k-plex (not with `countonly` or `nomatrix`)

## References

Seidman, S.B., Foster, B.L. (1978). A graph-theoretic generalization of the clique concept. *Journal of Mathematical Sociology* 6(1), 139-154.

Bron, C., Kerbosch, J. (1973). Algorithm 457: finding all cliques of an undirected graph. *Communications of the ACM* 16(9), 575-577.

Wasserman, S., Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press. (cliques and cohesive subgroups)

## See also

- [nwclique](nwclique), [nwnclique](nwnclique), [nwnclan](nwnclan), [nwkcomponents](nwkcomponents), [nwkcore](nwkcore), [nwcomponents](nwcomponents), [nwcommunity](nwcommunity), [nwconcor](nwconcor)

- last certified : 24 Aug 2026

---

*nwcommands version 3.8.0, 26 October 2026* ([check your installed version](nwversion))
