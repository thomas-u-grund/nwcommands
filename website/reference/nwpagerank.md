---
title: "nwpagerank"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
gen:erate(newvarname)
replace
damp:ing(real)
maxiter(int)
tol(real)
silent
bin:ary]
```

| | |
|---|---|
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's PageRank score |
| `replace` | Replace existing variable |
| `damp:ing(real)` | Probability of following a tie rather than jumping to a uniformly-random node; must be strictly between 0 and 1; default = 0.85 (Page and Brin's own original value) |
| `maxiter(int)` | Maximum power-iteration sweeps; default 1000 |
| `tol(real)` | Convergence tolerance; default 1e-10 |
| `silent` | Suppress display of results |
| `bin:ary` | Ignore the tie values of a valued network (by default they are used) |

## Description

`nwpagerank` computes Page and Brin's (1998) PageRank centrality: the stationary distribution of a "random surfer" who, at each step, either follows a uniformly-random OUTGOING tie from the current node (with probability `damping()`) or jumps to a uniformly-random node anywhere in the network (with probability 1 - `damping()`). Every node's own score is the long-run PROPORTION of time the surfer spends there - the `generate()` variable always sums to exactly 1 across all nodes.

Genuinely different from [nwevcent](nwevcent) (this package's own existing eigenvector centrality): PageRank works directly on DIRECTED networks with no symmetrization, has no scale ambiguity (the damping term guarantees a unique stationary distribution even on a network eigenvector centrality would otherwise reject as not strongly connected - see that command's own documented limitation), and explicitly handles "dangling" nodes (zero out-degree): a real random surfer stranded there cannot follow any tie, so PageRank's own construction redistributes that node's own probability mass UNIFORMLY across every node in the network on the next step (Page and Brin's own original fix, not an approximation) - `generate()`'s own values still sum to exactly 1 even when such nodes exist.

Computed via sparse power iteration - no dense n x n matrix is ever materialized, matching the same scalability discipline this package's own sparse-backend commands ([nwkcore](nwkcore), [nwevcent](nwevcent)) already follow.

## Network types

**Directed:** ties are followed in their direction. **Valued:** the surfer follows a tie with probability w_ij / s_i by default; `binary` ignores the values. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The power iteration runs in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both give the same scores (to the last digits). The work is the number of ties times the number of iterations. Measured in Stata/BE, random directed network with 10 ties per node: 5,000 nodes 0.03 seconds, 20,000 nodes 0.1 seconds, 100,000 nodes 0.3 seconds (the Mata route needs 0.12, 0.43 and 1.9 seconds). The weighted walk is about twice as fast as its Mata route (10,000 nodes with 30,000 ties: 0.05 against 0.09 seconds).

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## Examples

```stata
. nwwebuse florentine, nwclear
. nwpagerank flomarriage, generate(_pagerank)
. gsort -_pagerank
. list _name _pagerank in 1/5
```

## Stored results

- **Macros**
- **r(generate)** --- name of the generated PageRank variable

## References

Page, L., Brin, S., Motwani, R., Winograd, T. (1998). The PageRank Citation Ranking: Bringing Order to the Web. Stanford InfoLab Technical Report.

## See also

- [nwevcent](nwevcent), [nwrandomwalk](nwrandomwalk), [nwbetween](nwbetween), [nwcloseness](nwcloseness)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
