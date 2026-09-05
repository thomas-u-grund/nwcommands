---
title: "nwbetween"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate betweenness centrality"
---

# `nwbetween`

Calculate betweenness centrality

## Syntax

```stata
nwbetween
[netlist]
[,
generate(newvarlist)
replace
nosym
standardize
silent
weighted
alpha(real)]
```

| | |
|---|---|
| `generate`(*`newvarlist`*) | **Required.** Variable name for betweenness centrality |
| `replace` | allow overwriting an existing variable of the same name |
| `nosym` | do not symmetrize network before calculation of shortest paths |
| `standardize` | standardize centrality scores |
| `silent` | suppress the summary table of the generated variable |
| `weighted` | calculate on weighted (Dijkstra) shortest paths instead of dichotomizing |
| `alpha(real)` | weight-to-distance exponent used with `weighted`; default = 1 |

## Description

Calculates the betweenness centrality for each node *i* in a [network](netname) or [network list](netlist) and saves the result as a Stata variable. By default the command uses the dichotomized network (any tie with weight > 0 counts as an edge, tie strength ignored); pass `weighted` to compute genuinely weighted betweenness on Dijkstra shortest paths instead, using `alpha()` to control the weight-to-distance conversion. This follows Opsahl, Agneessens and Skvoretz (2010) - the same generalization [nwgeodesic](nwgeodesic)'s own `alpha()` already implements for weighted distances - where edge cost is *(1/weight)^alpha*: a STRONGER tie is a SHORTER effective distance, not a longer one. `alpha(1)`, the default, uses the reciprocal of the raw tie weight directly as distance/cost; `alpha(0)` reduces to the unweighted case (every positive tie costs exactly 1, ignoring its strength). See the References section below for the full citation.

The betweenness centrality for node *i* is equal to the number of shortest paths from all vertices to all others that pass through node *i*. A node with high betweenness centrality has a large influence on the transfer of items through the network, under the assumption that item transfer follows the shortest paths.

When there is more than one shortest path from node *k* to node *l*, the betweenness scores of all nodes *i* on these paths increases proportionally.

Formally, betweenness centrality of node *i* on graph *g* is defined as:

*Between_i(g) = sum ( sigma_st(i) / sigma_st )*

where, *sigma_st* is the total number of shortest paths from node *s* to node *t* and sigma_st(i) is the number of those paths that pass through node i.

For the standardized betweenness centrality:

Directed network: *Between_i_std(g) = Between_i(g) / ((N-1)*(N-2))*

Undirected network: *Between_i_std(g) = Between_i(g) / ((N-1)*(N-2)/2)*

`generate()` is required and names the Stata variable to hold the result (pass `replace` to allow overwriting an existing variable of that name). When betweenness centrality is calculated for more than one network at the same time (e.g. **nwbetween glasgow1 glasgow2, generate(bw)**), the command generates one variable per network, named *varname_netname* (e.g. *bw_glasgow1*, *bw_glasgow2*).

## Examples

```stata
. nwwebuse gang, nwclear
. nwbetween gang, generate(_between)
. sum _between
```

## Performance

The default (unweighted) mode of `nwbetween` transparently uses a compiled native (C) implementation of the same algorithm when one is available for the current platform (currently: macOS), falling back to an identical, fully-supported Mata implementation everywhere else - there is nothing to configure and no difference in the result, only in how fast it is computed (a native run at 10,000 nodes was measured faster than the Mata implementation at just 1,000). `weighted` still always uses the Mata implementation.

## Supported network types

Binary: yes, native. Directed: yes for the standardization normalizer (see the formulas above), but by default the network is symmetrized before computing betweenness at all - pass `nosym` to compute genuinely directed betweenness on the network as given; without `nosym` the reported scores reflect the symmetrized structure, not the original directed one (this applies identically whether or not `weighted` is used - symmetrization, via [nwsym](nwsym)'s default `max` mode, correctly combines rather than discards tie weights). Weighted: **W2** - the default remains **W3** (explicit binary-only: any tie with weight strictly greater than zero is dichotomized to an edge, tie strength otherwise ignored), but `weighted` now computes genuine Dijkstra-based betweenness using tie strength directly as distance/cost via `alpha()` - never silently implied, always an explicit opt-in. Signed: ties with weight less than or equal to zero, including negative ties, are treated as no tie at all in both the default and `weighted` cases - a negative (e.g. antagonistic) tie is not distinguished from an absent one, and `weighted`'s *weight^alpha* cost is undefined for a negative base in general, so signed networks are not natively supported by either mode. Two-mode: not checked.

## References

Brandes, U. (2001). A faster algorithm for betweenness centrality. *Journal of Mathematical Sociology* 25, 163-177.

Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. *Social Networks* 32 (3), 245-251.

## See also

- [nwpath](nwpath), [nwgeodesic](nwgeodesic), [nwcloseness](nwcloseness), [nwkatz](nwkatz), [nwdegree](nwdegree), [nwcloseness](nwcloseness), [nwevcent](nwevcent)

- last certified : 23 Aug 2026
