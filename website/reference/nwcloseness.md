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
| `generate`(*`var1 var2 var3`*) | **Required.** Exactly 3 variable names to save closeness, farness and nearness scores, in that order |
| `nosym` | do not symmetrize network before calculation of shortest paths |
| `replace` | overwrite existing *var1, var2, var3* (or *_closeness, _farness, _nearness*); required if they already exist |

## Description

Calculates the closeness centrality (and farness and nearness score) for each node *i* in a network or network list and saves the result as Stata variables.

The closeness centrality for node *i* is defined in the following way:

- *farness_i = sum(dist_ik), over all k*

- *nearness_i = 1 / farness_i*

- *closeness_i = nearness_i * (nodes - 1)*

with: *dist_ik* being the length of the shortest path from node *i* to node *k* (see [nwgeodesic](nwgeodesic))

Closeness centrality is not defined when the network is unconnected. However, scores can still be obtained when option **unconnected()** is specified. Any integer value can be choosen; **unconnected(max)** assigns non-existent paths a length based on the longest shortest path length observed in the network (plus one) (see [nwgeodesic](nwgeodesic)).

`generate()` is required and must always give exactly 3 names (*var1 var2 var3*, for closeness, farness and nearness respectively). Existing Stata variables *var1, var2, var3* require option **replace** to be overwritten. In case, closeness centrality is calculated for *z* networks at the same time (e.g. ** nwcloseness glasgow1 glasgow2, generate(clo far near)**), the command generates the variables *var1_z, var2_z, var3_z* for each network.

## Examples

```stata
. nwwebuse gang, nwclear
. nwcloseness gang, generate(_closeness _farness _nearness)
. sum _closeness _farness _nearness
```

## Supported network types

Binary: yes. Directed: yes - symmetrized by default (the same "no-prefix trap" `nosym` convention as [nwkatz](nwkatz)/[nwevcent](nwevcent)), `nosym` available. Weighted: inherited entirely from whatever [nwgeodesic](nwgeodesic) options are passed through (this command has no `weighted`/`alpha()` of its own). Signed: not checked. Two-mode: not checked.

## See also

- [nwgeodesic](nwgeodesic), [nwpath](nwpath), [nwgeodesic](nwgeodesic), [nwbetween](nwbetween), [nwdegree](nwdegree), [nwevcent](nwevcent), [nwkatz](nwkatz)

- last certified : 24 Aug 2026
