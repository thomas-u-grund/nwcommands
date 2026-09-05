---
title: "nwassortativity"
parent: "Command reference"
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
silent]
```

| | |
|---|---|
| `attribute(varname)` | Numeric node attribute to correlate across ties; default = each node's own degree |
| `weighted` | Weight the correlation by each tie's own strength (Leung and Chau 2007), instead of every tie counting equally |
| `silent` | Suppress display of results |

## Description

`nwassortativity` computes Newman's (2002) assortativity coefficient: the Pearson correlation, across every tie in the network, between the value of some quantity at one end of the tie and its value at the other end. By default that quantity is each node's own degree ("degree assortativity"), the most commonly reported form and the one Newman's own paper introduces the measure with; passing `attribute()` instead correlates any other numeric node attribute across ties ("attribute assortativity" - e.g. wealth, age, a status score).

A positive coefficient means nodes tend to be tied to others with a similar value (e.g. high-degree nodes tend to connect to other high-degree nodes) - the network is "assortative". A negative coefficient means the opposite: nodes tend to be tied to others with a dissimilar value (e.g. high-degree "hubs" connecting mostly to low-degree nodes) - the network is "disassortative". A coefficient near zero means no such pattern.

Formally, for every tie *(i,j)*, *x* is the attribute value at *i* and *y* the value at *j*; the coefficient is the ordinary Pearson correlation of *x* and *y* across every tie, counted in both directions (so the result does not depend on which end of a tie is labeled *i* vs *j*). This is exactly Newman's (2002) own *r* for the undirected case, and is computed here the same symmetrized way for directed input too - a tie assortativity measure has no natural directed generalization the same way ordinary clustering/clique measures do not (see [nwclustering](nwclustering.md)'s own identical reasoning), so a directed network's ties are treated as connections in either direction, matching this package's own established convention elsewhere (e.g. [nwtriads](nwtriads.md), [nwclique](nwclique.md)).

Social networks are frequently found to be assortative by degree (popular people know other popular people); many biological and technological networks (e.g. the internet's own router-level topology) are disassortative instead (a few high-degree hubs connect to many low-degree peripheral nodes).

`weighted` computes Leung and Chau's (2007) weighted extension instead: the same *(x,y)* pairs above, but correlated with each pair *weighted by its own tie's strength*, so a strong tie contributes more to the coefficient than a weak one - not a different pair construction, only a different (weighted Pearson) correlation of the identical pairs the unweighted case already builds. On a binary (unweighted) network every present tie has weight 1, so `weighted` gives exactly the same coefficient as omitting it - not an approximation.

## Examples

```stata
. nwwebuse glasgow, nwclear
. nwassortativity glasgow1
```
```stata
. nwassortativity glasgow1, attribute(sport1)
```
```stata
. nwassortativity glasgow1, weighted
```

## Supported network types

Binary: yes. Directed: yes, symmetrized (treated as connected in either direction - see above, same reasoning as [nwclustering](nwclustering.md)/[nwclique](nwclique.md)). Weighted: **W2** (added 2026-09-02, closing a self-flagged "not used" gap) - the default correlates presence/absence pairs only, matching Newman's own original definition; `weighted` (Leung and Chau 2007) is an explicit opt-in that weights the same pairs by tie strength instead. Signed: not checked - a negative tie weight would distort the weighted correlation's own denominators, not handled distinctly. Two-mode: not checked - operates on the network's own stored ties directly.

A network with fewer than 2 ties, or one where the attribute (degree, by default) is constant across every tied pair, has an undefined (zero-variance) correlation and returns **r(assortativity)** as missing rather than a spurious value - the same convention this package uses elsewhere for degree-undefined cases (e.g. [nwclustering](nwclustering.md)).

## Stored results

- Scalars:
- **r(assortativity)** the coefficient itself, in *[-1,1]*
- **r(ties)** number of ties the coefficient was computed over (undirected count)

- Macros:
- **r(name)** name of the network
- **r(attribute)** attribute used (or "degree" for the default)
- **r(weighted)** **"true"** if `weighted` was specified, **"false"** otherwise

## References

Newman, M. E. J. (2002). Assortative mixing in networks. *Physical Review Letters*, 89(20), 208701.

Leung, C.C., Chau, H.F. (2007). Weighted assortative and disassortative networks model. *Physica A* 378(2), 591-602. (`weighted`'s own extension)

## See also

- [nwdegree](nwdegree.md), [nwclustering](nwclustering.md), [nwmixing](nwmixing.md), [nwcorrelate](nwcorrelate.md)
