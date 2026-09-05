---
title: "nwrandomwalk"
parent: "Command reference"
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
[generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `target(nodename)` | The node every hitting time is measured TO |
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own mean hitting time to `target()` |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwrandomwalk` computes the mean hitting time from every node to `target()`: the EXPECTED number of steps a simple random walk (at each step, move to a uniformly-random NEIGHBOR of the current node) starting at that node takes to first reach `target()`. `target()` itself always gets 0.

A classical random-walk characterization of network structure, closely related to effective resistance/commute time in the electrical-network analogy of a graph, and genuinely different from ordinary geodesic distance ([nwgeodesic](nwgeodesic)): an unweighted random walk routinely takes far more steps than the shortest path, especially through a low-degree "bottleneck" node it is unlikely to choose directly - the whole reason hitting time is its own separate, informative quantity rather than just a scaled version of geodesic distance.

Solved EXACTLY via the standard linear system this quantity satisfies (not simulated, and not subject to any Monte Carlo noise): for every node i other than the target, its own hitting time equals 1 plus the average of its own neighbors' hitting times; the target's own hitting time is fixed at 0. The same "solve directly, do not simulate" discipline [nwkatz](nwkatz)'s own walk-counting Katz centrality already established for an analogous exact random-walk quantity.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwrandomwalk flomarriage, target(medici) generate(_hitting)
. gsort _hitting
. list _name _hitting in 1/5
```

## Supported network types

Binary: yes. Directed: not supported (a directed random walk's own hitting time is a well-defined but materially different quantity - not attempted here; networks are treated as undirected). Weighted: not checked - tie values are ignored (a random walker moves to each neighbor with EQUAL probability). Signed: not checked. Two-mode: not checked. Requires every node to have at least one tie - an isolate has no well-defined hitting time (there is no walk to take at all), and a disconnected network component containing `target()` would give some nodes an undefined (infinite) hitting time; both are rejected with a clear error rather than a silently wrong number.

## Stored results

**Macros**

- **r(target)** the target node requested
- **r(generate)** name of the generated hitting-time variable

## References

Lovasz, L. (1993). Random walks on graphs: A survey. *Combinatorics, Paul Erdos is Eighty* 2(1), 1-46.

## See also

- [nwpagerank](nwpagerank), [nwgeodesic](nwgeodesic), [nwkatz](nwkatz), [nwmaxflow](nwmaxflow)

- last certified : 31 Aug 2026
