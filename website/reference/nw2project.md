---
title: "nw2project"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "One-mode projection of a two-mode network"
---

# `nw2project`

One-mode projection of a two-mode network

## Syntax

```stata
nw2project
[netname]
,
project(1|2)
[name(newnetname)
stat(string)
xvars
replace]
```

| | |
|---|---|
| `project(1\|2)` | Mode/level to collapse to |
| `name(newnetname)` | Name of the new one-mode network; default = *project* |
| `stat(min\|max\|minmax\|sum\|mean\|count\|binary\|jaccard\|cosine)` | How to combine tie values (or, for the last 4, how to score shared-neighbor structure directly); default = *minmax* |
| `xvars` | Generate Stata variables for the new network |
| `replace` | Replace an existing network of the same name |

## Description

Sometimes one wants to collapse a two-mode network to a one-mode network. This is called a one-mode projection. Such a projection is a simplification of the network to nodes of one level only. The level to which one wants to collapse is specified in option **project()**.

For example, this loads a two-mode network and projects it onto level 1:

```stata
. nw2project mynet, project(1) name(myproject1)
```
By default, a one-mode projection on one level generates ties between nodes (on this level) when they have at least one network neighbor on the other level in common.

When the source network is **unvalued**, the tie value in the projection is simply the number of shared neighbors on the other level (e.g. the number of institutions two people share).

When the source network is **valued**, option **stat()** controls how the tie values of the two original ties (ego-to-shared-neighbor and alter-to-shared-neighbor) are combined, for every shared neighbor, into a single projected tie value:

- **stat(min)**
- the overall minimum across all ego/alter-to-shared-neighbor tie values
- **stat(max)**
- the overall maximum across all ego/alter-to-shared-neighbor tie values
- **stat(sum)**
- the sum across all ego/alter-to-shared-neighbor tie values
- **stat(mean)**
- the mean across all ego/alter-to-shared-neighbor tie values
- **stat(minmax)** (default)
- for each shared neighbor, take the minimum of the ego/alter tie values to that
- neighbor, then take the maximum of those minima across all shared neighbors -
- substantively, the strongest shared bond

The remaining four options score the **shared-neighbor structure itself** rather than combining tie values - they are defined the same way regardless of whether the source network is valued, and are available for a valued source network too (unlike the five above, which require one):

- **stat(count)**
- the number of shared neighbors - identical to the default behaviour on an
- unvalued source network, but now requestable explicitly on a valued one too, ignoring
- tie strength entirely
- **stat(binary)**
- 1 whenever at least one shared neighbor exists, 0 (no tie) otherwise - a
- plain co-affiliation indicator
- **stat(jaccard)**
- the Jaccard similarity of the two nodes' neighbor sets: shared neighbors
- divided by the size of the union of their neighbor sets
- **stat(cosine)**
- the cosine similarity of the two nodes' neighbor sets: shared neighbors
- divided by the geometric mean of their two degrees

For example, suppose Peter and Thomas are both affiliated with Oxford (Peter: 7 years, Thomas: 5 years) and LiU (Peter: 1 year, Thomas: 1 year). Then:

- hline 12c -hline 8
- c | stat c | value c |
- hline 12c -hline 8
- c | min c | 1 c |
- c | max c | 7 c |
- c | sum c | 14 c |
- c | mean c | 3.5 c |
- c | minmax c | 5 c |
- hline 12c -hline 8

The projected network's provenance (which network and mode it was projected from, and with which `stat()`) is recorded on the new network itself, not just printed - see **r(provenance)** via [nwname](netname), and [nwsummarize](nwsummarize), which displays it.

## Supported network types

Binary: yes. Directed: not checked - the source two-mode network's ties are treated as undirected affiliations. Weighted: **W1**, native - an unvalued source network projects to a shared-neighbor *count* (the standard bipartite-projection tie weight); a valued source network projects using `stat()`'s explicit choice of combination rule (see above) - tie strength is never silently discarded or reinterpreted as a distance. Signed: not checked. Two-mode: **T3** - this command's entire purpose is projecting a two-mode network down to one mode, so the projection is always explicit and user-requested (via `project()`), never a silent side effect of some other operation - the canonical, correct way to project in this package.

## Stored results

**Scalars**

- **r(nodes)** number of nodes in the projected network
- **r(ties)** number of ties in the projected network

## See also

- [nwproject](nwproject) (an exact alias for this command), [nw2set](nw2set), [nw2fromedge](nw2fromedge), [nw2toedge](nw2toedge), [nw2clustering](nw2clustering)

- last certified : 28 Aug 2026
