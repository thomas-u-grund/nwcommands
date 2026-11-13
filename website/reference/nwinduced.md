---
title: "nwinduced"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Induced, endogenous and exogenous centrality"
---

# `nwinduced`

Induced, endogenous and exogenous centrality

## Syntax

```stata
nwinduced
[netname]
,
measure(string)
[gen:erate(stub)
replace
silent
bin:ary]
```

| | |
|---|---|
| `measure(string)` | Underlying centrality measure: one of **degree**, **betweenness**, **closeness**, **evcent** |
| `gen:erate(stub)` | **Required.** Prefix for the three output variables (*stub***_endog**, *stub***_induced**, *stub***_exog**) |
| `replace` | Replace existing variables |
| `silent` | Suppress display of results |
| `bin:ary` | Ignore the tie values of a valued network (by default they are used) |

## Description

`nwinduced` computes Everett and Borgatti's (2010) three-part decomposition of node centrality, built on top of any of this package's own existing per-node centrality measures rather than being a single new formula of its own. Given a chosen measure *C* (e.g. degree, betweenness) and network *G*:

**Endogenous centrality** of node *v*: *C_G(v)* itself - the node's ordinary centrality score, exactly as [nwdegree](nwdegree) / [nwbetween](nwbetween) / [nwcloseness](nwcloseness) / [nwevcent](nwevcent) would already report it. Not a new computation; the existing measure, relabeled under this framework.

**Induced centrality** of node *v*: *sum_i C_G(i) - sum_i C_(G-v)(i)* - the total drop in EVERYONE's summed *C*-score when *v* is removed from the network (*G-v*: the network with *v* and its own ties deleted). Combines both *v*'s own direct contribution (its score, which vanishes on removal) and every indirect ripple effect on everyone else's score.

**Exogenous centrality** of node *v*: *Induced(v) - Endogenous(v)* - the purely indirect part: how much *v*'s presence props up OTHER nodes' centrality, isolated from *v*'s own standing.

A useful free sanity check, not specific to any one network: with `measure(degree)`, induced centrality reduces to EXACTLY twice plain degree, and exogenous centrality reduces to exactly plain degree again, for *any* undirected network - because removing a node removes exactly its own degree's worth of edges, each of which contributed 2 to the total degree sum. This holds as an identity, not merely on a hand-picked example (see [Examples](nwinduced) below).

The real computational cost is the leave-one-out reconstruction: computing induced centrality for every node requires recomputing *C* on *n* separate *n-1*-node subgraphs, one per removed node. For a cheap measure (**degree**) this is trivial; for an expensive one (**betweenness**, on a large network) this means *n* full recomputations of an already-expensive measure - worth being aware of before running this against a large network with `measure(betweenness)`.

## Network types

**Directed:** `betweenness`, `closeness` and `evcent` use directions; `measure(degree)` stops with an error. **Valued:** `betweenness`, `closeness` and `evcent` use the tie values, as the commands do; `degree` counts ties; `binary` ignores the values. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first). **Signed:** as in the chosen measure. See [nwnetworktypes](nwnetworktypes).

## Limits

**measure(degree)** has a closed form - removing a node takes away its own degree and one tie from each neighbour - so the induced value is twice the node's number of ties, computed without any loop (300 / 1,000 / 5,000 nodes: 0.02 / 0.03 / 0.09 seconds). The other measures have no such shortcut: the measure is recomputed on the network without each node in turn, so the time is the number of nodes times the time of the measure itself. Measured in Stata/BE on a random network with 10 ties drawn per node: **betweenness** 1.2 / 2.1 / 4.8 seconds at 50 / 100 / 200 nodes, **closeness** 2.8 / 20 / 8 seconds (the time of [nwcloseness](nwcloseness) depends on the network), **evcent** 6 seconds at 50 and 26 seconds at 100 nodes; plan for minutes at a few hundred nodes.

## Examples

```stata
. nwclear
. nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
. nwinduced starnet, measure(degree) generate(_induced)
```
- A hub (A, degree 3) and three leaves (B/C/D, degree 1) - endogenous exactly reproduces plain
- degree; induced is exactly twice that (6 for A, 2 for each leaf); exogenous equals endogenous
- again (3 for A, 1 for each leaf) - the free identity described above, verified here on a concrete
- example.

```stata
. nwwebuse florentine, nwclear
. nwinduced flobusiness, measure(betweenness) generate(bw)
```
- Which Florentine family props up OTHERS' betweenness the most, independent of its own
- standing? - the **bw_exog** column answers that, distinct from **bw_endog** (the family's own
- plain betweenness score).

## Stored results

- **Macros**
- **r(measure)** --- the underlying measure used
- **r(name)** --- name of the network
- **r(endogenous)** --- name of the endogenous-centrality variable
- **r(induced)** --- name of the induced-centrality variable
- **r(exogenous)** --- name of the exogenous-centrality variable

## References

Everett, M.G., Borgatti, S.P. (2010). Induced, endogenous and exogenous centrality. *Social* *Networks* 32(4), 339-344.

## See also

- [nwdegree](nwdegree), [nwbetween](nwbetween), [nwcloseness](nwcloseness), [nwevcent](nwevcent), [nwneighbor](nwneighbor)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
