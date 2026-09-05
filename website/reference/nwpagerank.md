---
title: "nwpagerank"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "PageRank centrality"
---

# `nwpagerank`

PageRank centrality

## Syntax

```stata
nwpagerank
[netname]
[,
generate(newvarname)
replace
damping(real)
maxiter(int)
tol(real)
silent]
```

| | |
|---|---|
| `generate(newvarname)` | Name of the Stata variable that stores each node's PageRank score; default = *_pagerank* |
| `replace` | Replace existing variable |
| `damping(real)` | Probability of following a tie rather than jumping to a uniformly-random node; must be strictly between 0 and 1; default = 0.85 (Page and Brin's own original value) |
| `maxiter(int)` | Maximum power-iteration sweeps; default 1000 |
| `tol(real)` | Convergence tolerance; default 1e-10 |
| `silent` | Suppress display of results |

## Description

`nwpagerank` computes Page and Brin's (1998) PageRank centrality: the stationary distribution of a "random surfer" who, at each step, either follows a uniformly-random OUTGOING tie from the current node (with probability `damping()`) or jumps to a uniformly-random node anywhere in the network (with probability 1 - `damping()`). Every node's own score is the long-run PROPORTION of time the surfer spends there - the `generate()` variable always sums to exactly 1 across all nodes.

Genuinely different from [nwevcent](nwevcent.md) (this package's own existing eigenvector centrality): PageRank works directly on DIRECTED networks with no symmetrization, has no scale ambiguity (the damping term guarantees a unique stationary distribution even on a network eigenvector centrality would otherwise reject as not strongly connected - see that command's own documented limitation), and explicitly handles "dangling" nodes (zero out-degree): a real random surfer stranded there cannot follow any tie, so PageRank's own construction redistributes that node's own probability mass UNIFORMLY across every node in the network on the next step (Page and Brin's own original fix, not an approximation) - `generate()`'s own values still sum to exactly 1 even when such nodes exist.

Computed via sparse power iteration - no dense n x n matrix is ever materialized, matching the same scalability discipline this package's own sparse-backend commands ([nwkcore](nwkcore.md), [nwevcent](nwevcent.md)) already follow.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwpagerank flomarriage
. gsort -_pagerank
. list _name _pagerank in 1/5
```

## Supported network types

Binary: yes. Directed: yes - the natural case (a random surfer follows ties in their own real direction); an undirected network is handled identically, since its own symmetric tie matrix already represents "can move either way" directly. Weighted: not checked - tie values are ignored (a random surfer moves to each out-neighbor with EQUAL probability, matching the classical definition; a value-weighted variant is not implemented). Signed: not checked. Two-mode: not checked.

## Stored results

**Macros**

- **r(generate)** name of the generated PageRank variable

## References

Page, L., Brin, S., Motwani, R., Winograd, T. (1998). The PageRank Citation Ranking: Bringing Order to the Web. Stanford InfoLab Technical Report.

## See also

- [nwevcent](nwevcent.md), [nwrandomwalk](nwrandomwalk.md), [nwbetween](nwbetween.md), [nwcloseness](nwcloseness.md)

- last certified : 31 Aug 2026
