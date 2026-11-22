---
title: "nwrandomwalk"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Mean random-walk hitting time to a target node"
---

# `nwrandomwalk`

Mean random-walk hitting time to a target node

## Syntax

```stata
nwrandomwalk
[netname]
,
target(nodename)
gen:erate(newvarname)
[replace
silent
bin:ary
one:mode
sym:metrize]
```

| | |
|---|---|
| `target(nodename)` | The node every hitting time is measured TO |
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own mean hitting time to `target()` |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |
| `bin:ary` | Ignore the tie values of a valued network (by default they are used) |
| `sym:metrize` | On a directed network, walk on the symmetrized network (the larger of the two directions of a tie) instead of along the direction of the ties |
| `one:mode` | Two-mode network: read the bipartite graph as a one-mode graph (a two-mode network is refused without it, error 6088) |

## Description

`nwrandomwalk` computes the mean hitting time from every node to `target()`: the EXPECTED number of steps a simple random walk (at each step, move to a uniformly-random NEIGHBOR of the current node) starting at that node takes to first reach `target()`. `target()` itself always gets 0.

A classical random-walk characterization of network structure, closely related to effective resistance/commute time in the electrical-network analogy of a graph, and genuinely different from ordinary geodesic distance ([nwgeodesic](nwgeodesic)): an unweighted random walk routinely takes far more steps than the shortest path, especially through a low-degree "bottleneck" node it is unlikely to choose directly - the whole reason hitting time is its own separate, informative quantity rather than just a scaled version of geodesic distance.

Solved EXACTLY via the standard linear system this quantity satisfies (not simulated, and not subject to any Monte Carlo noise): for every node i other than the target, its own hitting time equals 1 plus the average of its own neighbors' hitting times; the target's own hitting time is fixed at 0. The same "solve directly, do not simulate" discipline [nwkatz](nwkatz)'s own walk-counting Katz centrality already established for an analogous exact random-walk quantity.

## Network types

**Directed:** the walk follows the direction of the ties, as `igraph::random_walk(mode = "out")` does; the hitting time is missing for a node from which the target is not reached with certainty (it can run into a node without outgoing ties or into a part of the network from which the target cannot be reached), and the network must fit into a dense matrix (above that, error 484; `sym` is solved on the stored ties); `sym` symmetrizes first; the output says which was done. **Valued:** the walk steps with probability w_ij / s_i by default; `binary` ignores the values. **Two-mode:** not supported (error 6088); `onemode` uses the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

Up to 1,500 nodes the hitting times come from the dense linear system (LU decomposition). Above that the system, which is symmetric and positive definite for the walk on an undirected or symmetrized network, is solved by conjugate gradients on the stored ties (relative residual 1e-13; the result agrees with the dense solution to better than 1e-13 relative, and the dense route is still the fallback if the iteration does not converge). Measured in Stata/BE, random directed network with 10 ties per node: 10,000 nodes 0.15 seconds and 0.2 GB (65 seconds and 4 GB with the dense solution).

## Examples

```stata
. nwwebuse florentine, nwclear
. nwrandomwalk flomarriage, target(medici) generate(_hitting)
. gsort _hitting
. list _name _hitting in 1/5
```

## Stored results

- **Macros**
- **r(target)** --- the target node requested
- **r(generate)** --- name of the generated hitting-time variable
- **r(directed)** --- **"true"** (directed network walked as it is), **"symmetrized"** (with `symmetrize`) or **"false"** (undirected)

## References

Lovasz, L. (1993). Random walks on graphs: A survey. *Combinatorics, Paul Erdos is Eighty* 2(1), 1-46.

## See also

- [nwpagerank](nwpagerank), [nwgeodesic](nwgeodesic), [nwkatz](nwkatz), [nwmaxflow](nwmaxflow)

---

*nwcommands version 3.34.0, 21 November 2026* ([check your installed version](nwversion))
