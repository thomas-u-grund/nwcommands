---
title: "nwcloseness"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
replace
silent
force
binary
twomode
onemode
legacy]
```

| | |
|---|---|
| `unconnected(int)` | defines the length of the (non-existent) path between two unconnected nodes |
| `legacy` | on an unconnected network, use (nodes - 1) / farness as in earlier releases instead of the number of reachable nodes / farness |
| `generate`(*`var1 var2 var3`*) | **Required.** Exactly 3 variable names to save closeness, farness and nearness scores, in that order |
| `nosym` | do not symmetrize network before calculation of shortest paths |
| `replace` | overwrite existing *var1, var2, var3* (or *_closeness, _farness, _nearness*); required if they already exist |
| `silent` | Do not display the summary of the new variables |
| `force` | Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise); also passed on to [nwgeodesic](nwgeodesic) |
| `binary` | Ignore the tie values of a valued network (by default they are used) |
| `twomode` | Two-mode network: the default; accepted as a synonym of the default (closeness is the smallest possible farness of a node of its mode divided by its farness, Borgatti and Everett 1997) |
| `onemode` | Two-mode network: the closeness of the bipartite graph read as a one-mode graph, without the normalisation of Borgatti and Everett (the result of earlier releases) |

## Description

Calculates the closeness centrality (and farness and nearness score) for each node *i* in a network or network list and saves the result as Stata variables.

The closeness centrality for node *i* is defined in the following way:

- *farness_i = sum(dist_ik), over all k*

- *nearness_i = 1 / farness_i*

- *closeness_i = nearness_i * (nodes - 1)*

with: *dist_ik* being the length of the shortest path from node *i* to node *k* (see [nwgeodesic](nwgeodesic))

Closeness as defined above ((nodes - 1) / farness) is only defined for a connected network. When the network is unconnected (or, for a directed network, not strongly connected) the command prints a warning and, as in R's igraph, takes the sum of the distances over the nodes that *i* can reach and divides the *number of those nodes* by it: *closeness_i = reach_i / farness_i*. This equals the formula above for a connected network and never exceeds 1. Farness and nearness are the plain sum of finite distances and its inverse. A node that reaches no other node gets a missing closeness. Option **legacy** returns the (nodes - 1) / farness of releases before this correction, which can exceed 1 on an unconnected network. Scores based on all (nodes - 1) other nodes can also be obtained when option **unconnected()** is specified. Any integer value can be choosen; **unconnected(max)** assigns non-existent paths a length based on the longest shortest path length observed in the network (plus one) (see [nwgeodesic](nwgeodesic)).

`generate()` is required and must always give exactly 3 names (*var1 var2 var3*, for closeness, farness and nearness respectively). Existing Stata variables *var1, var2, var3* require option **replace** to be overwritten. In case, closeness centrality is calculated for *z* networks at the same time (e.g. ** nwcloseness glasgow1 glasgow2, generate(clo far near)**), the command generates the variables *var1_z, var2_z, var3_z* for each network.

## Examples

```stata
. nwwebuse gang, nwclear
. nwcloseness gang, generate(_closeness _farness _nearness)
. sum _closeness _farness _nearness
```

## Supported network types

Binary: yes. Directed: yes - symmetrized by default (the same "no-prefix trap" `nosym` convention as [nwkatz](nwkatz)/[nwevcent](nwevcent)), `nosym` available. Weighted: inherited entirely from whatever [nwgeodesic](nwgeodesic) options are passed through (this command has no `weighted`/`alpha()` of its own). Signed: not checked. Two-mode: two-mode form by default - the smallest possible farness of a node of its mode divided by its farness (Borgatti and Everett 1997; `twomode` is accepted as a synonym); `onemode` forces the one-mode closeness of the bipartite graph.

## See also

- [nwgeodesic](nwgeodesic), [nwpath](nwpath), [nwgeodesic](nwgeodesic), [nwbetween](nwbetween), [nwdegree](nwdegree), [nwevcent](nwevcent), [nwkatz](nwkatz)

- last certified : 24 Aug 2026

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
