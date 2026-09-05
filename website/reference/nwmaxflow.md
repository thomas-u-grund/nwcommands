---
title: "nwmaxflow"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Maximum flow and minimum cut between two nodes"
---

# `nwmaxflow`

Maximum flow and minimum cut between two nodes

## Syntax

```stata
nwmaxflow
[netname]
,
source(nodename)
sink(nodename)
[weighted
generate(newvarname)
replace]
```

| | |
|---|---|
| `source(nodename)` | The flow's own origin node |
| `sink(nodename)` | The flow's own destination node |
| `weighted` | Use tie VALUES as edge capacities instead of a uniform capacity of 1 per tie |
| `generate(newvarname)` | Save a 0/1 variable marking which nodes are on the SOURCE side of the minimum cut |
| `replace` | Replace an existing variable of the same name |

## Description

`nwmaxflow` computes the maximum flow (and, by the max-flow/min-cut theorem, the minimum edge cut) between `source()` and `sink()` via the standard Edmonds-Karp augmenting-path algorithm - the same generic max-flow primitive this package's own [nwlambda](nwlambda) (pairwise edge connectivity) and [nwkcomponents](nwkcomponents) (vertex connectivity, via a node-splitting reduction) already build on internally. By default every existing tie has capacity 1, regardless of its own tie value (so max-flow reduces to counting edge-disjoint paths - the same quantity [nwlambda](nwlambda) computes for every pair at once). With `weighted`, tie VALUES are used as capacities instead - useful when a network's own tie strength genuinely represents a throughput/capacity (e.g. trade volume, bandwidth, transaction size).

`generate(newvarname)` marks which nodes remain reachable from `source()` in the FINAL residual graph once the flow has converged - the standard max-flow/min-cut construction. Every existing tie from a marked (1) node to an unmarked (0) node is one of the edges in the minimum cut; `r(cutedges)` reports how many such edges exist, without requiring `generate()` to be given just to see the count.

For a DIRECTED network, capacities are directional (a tie A->B only lets flow move A to B, matching the underlying idea that a directed relation only "carries" one way); an undirected network's own symmetric tie matrix already represents capacity in both directions naturally, needing no special handling.

## Examples

```stata
. nwset, mat((0,2,1,0\0,0,1,1\0,0,0,2\0,0,0,0)) name(flownet) directed valued labs(A,B,C,D)
. nwmaxflow flownet, source(A) sink(D) weighted generate(cutside)
. nwmaxflow flownet, source(A) sink(D)
```

## Supported network types

Binary: yes (capacity 1 per tie, the default). Directed: yes - respects the network's own actual directedness (unlike [nwlambda](nwlambda), which always symmetrizes first; a flow network is inherently a directed concept). Weighted: yes, via `weighted`. Signed: not checked - a negative capacity has no meaning here. Two-mode: not checked (see [nwmatching](nwmatching) for the two-mode/bipartite analog - maximum matching, not maximum flow).

## Stored results

**Scalars**

- **r(maxflow)** the maximum flow value
- **r(cutedges)** number of edges in the minimum cut

**Macros**

- **r(source)** the source node requested
- **r(sink)** the sink node requested

## References

Ford, L.R., Fulkerson, D.R. (1956). Maximal flow through a network. *Canadian Journal of Mathematics* 8, 399-404.

Edmonds, J., Karp, R.M. (1972). Theoretical improvements in algorithmic efficiency for network flow problems. *Journal of the ACM* 19(2), 248-264.

## See also

- [nwmatching](nwmatching), [nwlambda](nwlambda), [nwkcomponents](nwkcomponents), [nwbridges](nwbridges)

- last certified : 31 Aug 2026
