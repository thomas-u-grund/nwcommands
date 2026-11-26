---
title: "nwassortativity"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Newman's assortativity coefficient"
---

# `nwassortativity`

Newman's assortativity coefficient

## Syntax

```stata
nwassortativity
[netname]
[,
attribute(varname)
weighted
silent
binary
sym]
```

| | |
|---|---|
| `attribute(varname)` | Numeric node attribute to correlate across ties; default = each node's own degree (its strength on a valued network unless `binary` is given) |
| `weighted` | Weight the correlation by each tie's own strength (Leung and Chau 2007), instead of every tie counting equally |
| `silent` | Suppress display of results |
| `binary` | Ignore the tie values of a valued network (by default they are used) |
| `sym` | On a directed network, symmetrize first (the larger of the two directions of a tie) and compute the undirected coefficient |

## Description

`nwassortativity` computes Newman's (2002) assortativity coefficient: the Pearson correlation, across every tie in the network, between the value of some quantity at one end of the tie and its value at the other end. By default that quantity is each node's own degree ("degree assortativity"), the most commonly reported form and the one Newman's own paper introduces the measure with; passing `attribute()` instead correlates any other numeric node attribute across ties ("attribute assortativity" - e.g. wealth, age, a status score).

A positive coefficient means nodes tend to be tied to others with a similar value (e.g. high-degree nodes tend to connect to other high-degree nodes) - the network is "assortative". A negative coefficient means the opposite: nodes tend to be tied to others with a dissimilar value (e.g. high-degree "hubs" connecting mostly to low-degree nodes) - the network is "disassortative". A coefficient near zero means no such pattern.

Formally, for every tie *(i,j)*, *x* is the attribute value at *i* and *y* the value at *j*; the coefficient is the ordinary Pearson correlation of *x* and *y* across the ties. On an undirected network every tie is counted in both directions (so the result does not depend on which end of a tie is labeled *i* vs *j*), which is Newman's (2002) *r*. On a directed network every tie is one pair, *x* taken at the sender and *y* at the receiver (Newman 2003, the directed *r* of `igraph::assortativity(directed = TRUE)`): by default the degree of the sender is its out-degree and the degree of the receiver is its in-degree (out-strength and in-strength on a valued network), and with `attribute()` the same attribute is read at both ends. Option `sym` gives the undirected coefficient of the symmetrized network instead (a tie counts in both directions with the larger of its two values). The output says whether the network was analysed as directed, undirected or symmetrized.

Social networks are frequently found to be assortative by degree (popular people know other popular people); many biological and technological networks (e.g. the internet's own router-level topology) are disassortative instead (a few high-degree hubs connect to many low-degree peripheral nodes).

`weighted` computes Leung and Chau's (2007) weighted extension instead: the same *(x,y)* pairs above, but correlated with each pair *weighted by its own tie's strength*, so a strong tie contributes more to the coefficient than a weak one - not a different pair construction, only a different (weighted Pearson) correlation of the identical pairs the unweighted case already builds. On a binary (unweighted) network every present tie has weight 1, so `weighted` gives exactly the same coefficient as omitting it - not an approximation.

A network with fewer than 2 ties, or one where the attribute (degree, by default) is constant across every tied pair, has an undefined (zero-variance) correlation and returns **r(assortativity)** as missing rather than a spurious value.

## Network types

**Directed:** analysed as it is (sender against receiver); `sym` symmetrizes first, and the output says which. **Valued:** without `attribute()` the node attribute is the strength instead of the degree (`binary` uses the degree); `weighted` also weights each tie by its value (Leung and Chau 2007). **Two-mode:** same as for the bipartite graph read as a one-mode network (the degree assortativity is negative by construction). **Signed:** negative values would distort the weighted correlation. See [nwnetworktypes](nwnetworktypes).

## Examples

```stata
. nwwebuse glasgow, nwclear
. nwassortativity glasgow1

. nwassortativity glasgow1, attribute(sport1)

. nwassortativity glasgow1, weighted
```

## Stored results

- **Scalars**
- **r(assortativity)** --- the coefficient itself, in *[-1,1]*
- **r(ties)** --- number of ties the coefficient was computed over (arcs of a directed network, unordered pairs of an undirected or symmetrized network)

- **Macros**
- **r(name)** --- name of the network
- **r(attribute)** --- attribute used (or "degree" or "strength" for the default)
- **r(directed)** --- **"true"** for a directed network analysed as it is, **"symmetrized"** with `sym`, **"false"** for an undirected network
- **r(weighted)** --- **"true"** if `weighted` was specified, **"false"** otherwise

## References

Newman, M. E. J. (2002). Assortative mixing in networks. *Physical Review Letters*, 89(20), 208701.

Leung, C.C., Chau, H.F. (2007). Weighted assortative and disassortative networks model. *Physica* *A* 378(2), 591-602. (`weighted`'s own extension)

## See also

- [nwdegree](nwdegree), [nwclustering](nwclustering), [nwmixing](nwmixing), [nwcorrelate](nwcorrelate)

---

*nwcommands version 3.39.0, 26 November 2026* ([check your installed version](nwversion))
