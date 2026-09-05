---
title: "nwutility"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate utility scores according to Jackson and Wollinsky (1996)"
---

# `nwutility`

Calculate utility scores according to Jackson and Wollinsky (1996)

## Syntax

```stata
nwutility
[netname]
,
[benefit(real)
cost(real)
intrvalue(netname)
intrcost(netname)
geodesic_options]
```

| | |
|---|---|
| `benefit(real)` | benefit from connected node; default = 1 |
| `cost(real)` | cost of connection; default = 1 |
| `intrvalue(netname)` | intrinsic value w_ij a node i gives to a connection with node j; default = 1 for every tied pair |
| `intrcost(netname)` | per-dyad cost y_ij, replacing the constant *cost* for direct connections; default = *cost* for every tied pair |

## Description

`nwutility` calculates node-level utility scores according to the connections model in Jackson and Wollinsky (1996). The command generates the variables _benefit, _cost and _util. In this model of strategic network formation, each node i is assigned a utility score, which is calculated as:

U(i) = w_ii + sum_j[benefit^(d_ij) * w_ij] - sum_j_in_N(i)[cost * y_ij]

*benefit* essentially defines the decay of benefit from non-direct (but connected) network neighbors. When benefit = 1, a node i gains as much benefit from a directly connected node as from an indirectly connected node.

*cost* defines the cost of node i for maintaining a network link (hence, only direct connections are considered).

The command can also be used in more complicated ways using the intrinsic value w_ij a node i gives to a connection with node j, via `intrvalue()`, and/or a per-dyad cost y_ij (in place of the constant *cost*), via `intrcost()`. Both must be networks of the same size as the network being analyzed. For example, one could imagine that nodes only get benefit from nodes who have the same attribute. To do that one would first generate a new network that holds information on whether two nodes have the same value on an attribute (see [nwexpand](nwexpand)).

```stata
. nwclear
. nwrandom 20, prob(.2)
. gen attr = round(uniform())
. nwexpand attr, mode(same) name(same)
```
Then one can use `intrvalue()` in `nwutility`:

```stata
. nwutility network, benefit(.5) cost(.3) intrvalue(same)
```
**Important**: the w_ii term (a node's intrinsic self-value) is read from `intrvalue()`'s own network diagonal. [nwset](nwset) treats the diagonal as "no self-tie" (missing) by default for any network, `intrvalue()` included - a network built without the `selfloop` option will have a missing diagonal, and `nwutility` will report *_benefit*/*_util* as missing rather than silently substituting a wrong number. To supply real w_ii values, build the `intrvalue()` network with [nwset](nwset)'s own `selfloop` option so the diagonal is preserved.

## Remarks

When not specified otherwise, benefit = 1, cost = 1, w_ij = 1 (for i != j), y_ij = *cost*, and w_ii = 0 (i.e. `intrvalue()` is not given).

## Supported network types

Binary: yes. Directed: not checked (the connections model as implemented here assumes an undirected notion of reachability via [nwgeodesic](nwgeodesic)). Weighted: **W1**, native - the network under analysis only needs to be binary for the underlying geodesic-distance calculation, but `intrvalue()`/`intrcost()` let tie strength (as a full per-dyad value, not the analyzed network's own weight) enter the utility formula directly, not as a distance. Signed: not checked. Two-mode: not checked.
