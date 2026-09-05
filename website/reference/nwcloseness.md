---
title: "nwcloseness"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate closeness centrality"
---

# `nwcloseness`

Calculate closeness centrality

## Syntax

```stata
nwcloseness 
[netlist]
[,
unconnected(int)
generate(var1 var2 var3)
nosym
replace]
```

| | |
|---|---|
| `unconnected(int)` | defines the length of the (non-existent) path between two unconnected nodes |
| `generate`(*`var1 var2 var3`*) | variables names to save closeness, farness and nearness scores; default:
*var1 = _closeness, var2 = _farness, var3 = _nearness* - must be exactly 3 names, or omitted entirely |
| `nosym` | do not symmetrize network before calculation of shortest paths |
| `replace` | overwrite existing *var1, var2, var3* (or *_closeness, _farness, _nearness*); required if they already exist |

## Description

Calculates the closeness centrality (and farness and nearness score) for each node *i* in a network or network list and saves the result as Stata variables.

The closeness centrality for node *i* is defined in the following way:

- *farness_i = sum(dist_ik), over all k*

- *nearness_i = 1 / farness_i*

- *closeness_i = nearness_i * (nodes - 1)*

with: *dist_ik* being the length of the shortest path from node *i* to node *k* (see [nwgeodesic](nwgeodesic.md))

Closeness centrality is not defined when the network is unconnected. However, scores can still be obtained when option **unconnected()** is specified. Any integer value can be choosen; **unconnected(max)** assigns non-existent paths a length based on the longest shortest path length observed in the network (plus one) (see [nwgeodesic](nwgeodesic.md)).

Existing Stata variables *var1, var2, var3* require option **replace** to be overwritten. In case, closeness centrality is calculated for *z* networks at the same time (e.g. ** nwcloseness glasgow1 glasgow2**), the command generates the variables *var1_z, var2_z, var3_z* for each network.

## Examples

```stata
. nwwebuse gang, nwclear
. nwcloseness gang
. sum _closeness _farness _nearness
```

## Supported network types

Binary: yes. Directed: yes - symmetrized by default (the same "no-prefix trap" `nosym` convention as [nwkatz](nwkatz.md)/[nwevcent](nwevcent.md)), `nosym` available. Weighted: inherited entirely from whatever [nwgeodesic](nwgeodesic.md) options are passed through (this command has no `weighted`/`alpha()` of its own). Signed: not checked. Two-mode: not checked.

## See also

- [nwgeodesic](nwgeodesic.md), [nwpath](nwpath.md), [nwgeodesic](nwgeodesic.md), [nwbetween](nwbetween.md), [nwdegree](nwdegree.md), [nwevcent](nwevcent.md), [nwkatz](nwkatz.md)

- last certified : 24 Aug 2026
