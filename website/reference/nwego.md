---
title: "nwego"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Ego-network size and density"
---

# `nwego`

Ego-network size and density

## Syntax

```stata
nwego
[netlist]
[,
sizevar(newvarname)
densvar(newvarname)
replace
silent]
```

| | |
|---|---|
| `sizevar(newvarname)` | **Required.** Name of the Stata variable that stores ego-network size |
| `densvar(newvarname)` | **Required.** Name of the Stata variable that stores ego-network density |
| `replace` | Replace existing variables |
| `silent` | Suppress display of results |

## Description

`nwego` calculates, for every node, the size and density of its ego network. A node's alters are every other node it has any tie with - for a directed network, the union of its incoming and outgoing ties (the standard "who is in ego's network at all" question; this is distinct from [nwaltergen](nwaltergen.md)'s own alter-aggregation convention, which deliberately keeps incoming and outgoing ties separate for a different purpose).

**Ego-network size** is simply the number of alters (equivalent to [nwdegree](nwdegree.md) for an undirected network; for a directed network it is the count of *distinct* nodes tied in either direction, not the sum of in- and out-degree, which could double-count a reciprocated tie).

**Ego-network density** is the proportion of possible ties actually present *among the alters themselves* - ego itself is excluded, the standard convention for reporting how interconnected an ego's contacts are with each other, independent of their (by definition, complete) ties to ego. For a directed network, ordered alter-alter pairs are counted (an alter set of size *k* has *k(k-1)* possible ties); for an undirected network, unordered pairs are counted (*k(k-1)/2* possible ties). An ego with fewer than 2 alters has no pair to assess - density is reported missing for it, not spuriously 0 or 1.

`sizevar()` and `densvar()` are both required and name the Stata variables that store ego-network size and density, respectively.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwego flomarriage, sizevar(_egosize) densvar(_egodensity)
```

## Supported network types

Binary: yes. Directed: yes - alters are the union of in- and out-neighbors; alter-alter density counts ordered pairs. Weighted: not used - only presence/absence of a tie determines ego-network membership and alter-alter density; tie strength does not affect these measures. Signed: not checked. Two-mode: not checked - operates on the network's own square adjacency matrix.

## References

Burt, R.S. (1992). *Structural Holes: The Social Structure of Competition*. Harvard University Press. (ego-network density as used in structural holes analysis - see also [nwconstraint](nwconstraint.md), [nwburt](nwburt.md))

## See also

- [nwdegree](nwdegree.md), [nwaltergen](nwaltergen.md), [nwconstraint](nwconstraint.md), [nwburt](nwburt.md)

- last certified : 21 Aug 2026
