---
title: "nwinduced"
parent: "Command reference"
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
[generate(stub)
replace
silent]
```

| | |
|---|---|
| `measure(string)` | Underlying centrality measure: one of **degree**, **betweenness**, **closeness**, **evcent** |
| `generate(stub)` | **Required.** Prefix for the three output variables (*stub***_endog**, *stub***_induced**, *stub***_exog**) |
| `replace` | Replace existing variables |
| `silent` | Suppress display of results |

## Description

`nwinduced` computes Everett and Borgatti's (2010) three-part decomposition of node centrality, built on top of any of this package's own existing per-node centrality measures rather than being a single new formula of its own. Given a chosen measure *C* (e.g. degree, betweenness) and network *G*:

**Endogenous centrality** of node *v*: *C_G(v)* itself - the node's ordinary centrality score, exactly as [nwdegree](nwdegree)/[nwbetween](nwbetween)/[nwcloseness](nwcloseness)/[nwevcent](nwevcent) would already report it. Not a new computation; the existing measure, relabeled under this framework.

**Induced centrality** of node *v*: *sum_i C_G(i) - sum_i C_(G-v)(i)* - the total drop in EVERYONE's summed *C*-score when *v* is removed from the network (*G-v*: the network with *v* and its own ties deleted). Combines both *v*'s own direct contribution (its score, which vanishes on removal) and every indirect ripple effect on everyone else's score.

**Exogenous centrality** of node *v*: *Induced(v) - Endogenous(v)* - the purely indirect part: how much *v*'s presence props up OTHER nodes' centrality, isolated from *v*'s own standing.

A useful free sanity check, not specific to any one network: with `measure(degree)`, induced centrality reduces to EXACTLY twice plain degree, and exogenous centrality reduces to exactly plain degree again, for *any* undirected network - because removing a node removes exactly its own degree's worth of edges, each of which contributed 2 to the total degree sum. This holds as an identity, not merely on a hand-picked example (see [Examples](nwinduced) below).

The real computational cost is the leave-one-out reconstruction: computing induced centrality for every node requires recomputing *C* on *n* separate *n-1*-node subgraphs, one per removed node. For a cheap measure (**degree**) this is trivial; for an expensive one (**betweenness**, on a large network) this means *n* full recomputations of an already-expensive measure - worth being aware of before running this against a large network with `measure(betweenness)`.

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

## Supported network types

Binary: yes. Directed: **measure(betweenness/closeness/evcent)** support directed networks directly (each already produces exactly one clean per-node output variable regardless of directedness); **measure(degree)** does not - [nwdegree](nwdegree) itself splits into separate **_outdegree**/**_indegree** variables on a directed network, so induced degree would need a choice between them with no single obviously-right answer, disclosed as a v1 scope limit (a clear error) rather than guessed at. Weighted/Signed: entirely inherited from whichever `measure()` is chosen - `nwinduced` itself does not read tie values directly. Two-mode: not supported - operates on the network's own one-mode adjacency directly; a bipartite-aware variant is not attempted here.

## Stored results

- Macros:
- **r(measure)** the underlying measure used
- **r(name)** name of the network
- **r(endogenous)** name of the endogenous-centrality variable
- **r(induced)** name of the induced-centrality variable
- **r(exogenous)** name of the exogenous-centrality variable

## References

Everett, M.G., Borgatti, S.P. (2010). Induced, endogenous and exogenous centrality. *Social Networks* 32(4), 339-344.

## See also

- [nwdegree](nwdegree), [nwbetween](nwbetween), [nwcloseness](nwcloseness), [nwevcent](nwevcent), [nwneighbor](nwneighbor)
