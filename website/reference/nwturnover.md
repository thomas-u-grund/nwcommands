---
title: "nwturnover"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Tie turnover/stability between two waves of the same network"
---

# `nwturnover`

Tie turnover/stability between two waves of the same network

## Syntax

```stata
nwturnover
net1 net2
[,
generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own local stability |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwturnover` compares two networks on the SAME node set representing two waves of observation of the same relationship (e.g. a panel/longitudinal network study, *net1* at time *t* and *net2* at time *t+1*) and reports how much the tie structure changed between them: how many ties were **stable** (present at both waves), **formed** (absent at *net1*, present at *net2*), or **dissolved** (present at *net1*, absent at *net2*). Only tie presence/absence is compared (not tie weight) - [nwcorrelate](nwcorrelate.md), which correlates tie *values* between two networks, answers a related but different question.

**r(jaccard)** is the standard "Jaccard index of network change" used in longitudinal SNA (e.g. Snijders et al.'s SIENA methodology) to gauge whether enough change occurred between waves to be worth modeling at all: **stable / (stable + formed + dissolved)** - 1 when the two networks are identical, 0 when they share no tie in common whatsoever. **r(persistence)** is a related but distinct question - of the ties that existed at *net1*, what fraction survived to *net2*: **stable / (stable + dissolved)**, undefined (missing) if *net1* has no ties at all.

`generate()` is required and names the per-node variable that gives each node's OWN local Jaccard stability - computed the same way as **r(jaccard)**, but restricted to that one node's own ties across the two waves, rather than the whole network's.

*net1* and *net2* must have the same number of nodes and the same directedness (both directed or both undirected) - comparing a directed network to an undirected one, or two networks of different size, is rejected explicitly rather than silently doing something arithmetically possible but conceptually meaningless.

For an **undirected** pair of networks, **r(stable)**, **r(formed)**, and **r(dissolved)** each count both *(i,j)* and *(j,i)* for the same tie, so all three are exactly double the number of actual undirected ties involved (the same convention [nwmixing](nwmixing.md) uses for its own mixing table). **r(jaccard)** and **r(persistence)** are unaffected, since the doubling cancels in both ratios.

## Examples

```stata
. nwset, mat((0,1,1\1,0,0\1,0,0)) name(wave1)
. nwset, mat((0,1,0\1,0,1\0,1,0)) name(wave2)
. nwturnover wave1 wave2, generate(_turnover)
```

## Supported network types

Binary: yes. Directed: yes (each ordered pair compared independently, both networks must share the same directedness). Weighted: not used - only tie presence/absence is compared. Signed: not checked. Two-mode: not checked - operates on each network's own square adjacency matrix.

## Stored results

**Scalars**

- **r(stable)** number of ties present in both networks
- **r(formed)** number of ties present only in *net2*
- **r(dissolved)** number of ties present only in *net1*
- **r(jaccard)** stable / (stable + formed + dissolved)
- **r(persistence)** stable / (stable + dissolved); missing if *net1* has no ties

## References

Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic actor-based models for network dynamics. *Social Networks* 32(1), 44-60. (the Jaccard index of network change, used as a standard diagnostic for whether panel-wave data is suitable for dynamic modeling)

## See also

- [nwcorrelate](nwcorrelate.md), [nwcomponents](nwcomponents.md), [nwqap](nwqap.md)

- last certified : 22 Aug 2026
