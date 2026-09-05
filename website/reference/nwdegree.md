---
title: "nwdegree"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Degree centrality and distribution"
---

# `nwdegree`

Degree centrality and distribution

## Syntax

```stata
nwdegree 
[netname]
[,
alpha(real)
generate(varlist)
replace
silent
isolates
standardize
in(tabulate_opt)
out(tabulate_opt)
tabulate_opt
outputoff
]
```

| | |
|---|---|
| `alpha` | Tuning parameter for valued networks; default = 0 |
| `generate`(*`varlist`*) | **Required.** Variable name(s) for degree (undirected) or outdegree/indegree (directed) - and, if `isolates` is also given, an extra name for the isolate indicator |
| `replace` | Overwrite existing variables *varlist* |
| `silent` | Surpress output |
| `outputoff` | Reserved/internal - has no effect on a one-mode network's own output; use `silent` instead. Only meaningful when [netname](netname.md) turns out to be two-mode (where it is named, along with any other one-mode-only option, in the note explaining which options have no bipartite equivalent and were ignored when redirecting to [nw2degree](nw2degree.md)) |
| `isolates` | Generate variable for network isolates |
| `standardize` | Divide degree or strength by N - 1 |
| `in`(*`tabulate_opt`*) | Options for tabulating *indegree* |
| `out`(*`tabulate_opt`*) | Options for tabulating *outdegree* |
| *`tabulate_opt`* | Options for tabulating *degree* |

## Description

`nwdegree` calculates the generalized degree centrality of the nodes as outlined in Opsahl et al (2010) for the (un-)weighted, (un-directed) networks in [netlist](netlist.md). `generate()` is required: name one variable for an undirected network, or two (outdegree, indegree, in that order) for a directed one. It also tabulates the newly generated variable(s).

Following Opsahl et al. (2010) the degree centrality C_i of node i is defined as:

*C_i = k_i * ( s_i / k_i ) ^ alpha*

where *k_i* is the number of ties that node *i* is involved in (regardless of tie values) and *s_i* is the sum of the tie values of these ties. When *alpha = 0* (default), this generalized degree centrality gives the number of ties that a node has. When *alpha = 1*, it gives the node strength, i.e. the sum of the tie values that a node is involved in. For unvalued networks the value of *alpha* does not matter.

Option **isolates** adds one more name to `generate()` (after the degree name(s)) for a variable indicating whether a node is an isolate (not connected to any other node) - e.g. `generate(mydeg myisolate) isolates` on an undirected network, or `generate(myout myin myisolate) isolates` on a directed one.

Option **standardize** divides the centrality scores by N - 1, where N = number of nodes in a network.

`nwdegree` accepts a [netlist](netlist.md) (e.g. **nwdegree glasgow1 glasgow2, generate(deg)**), calculating degree centrality independently for each network in the list. When more than one network is given, `generate()`'s own name(s) get the network's own name appended (e.g. *deg_glasgow1*, *deg_glasgow2*); a single-network call is unaffected and keeps the plain name(s) exactly as given. **r()** results (e.g. **r(dg_central)**) reflect whichever network was processed last, matching this package's convention for other [netlist](netlist.md) commands.

## Examples

- This is the example used in Opsahl et al. (2010, Table 1):

- . nwclear
- . nwset, mat((.,4,4,0,0,0\
- 4,.,2,1,1,0\
- 4,2,.,0,0,0\
- 0,1,0,.,0,0\
- 0,1,0,0,.,7\
- 0,0,0,0,7,.)) undirected labs(A, B, C, D, E, F)
- . qui nwdegree, alpha(0) generate(deg0)
- . qui nwdegree, alpha(.5) generate(deg0_5)
- . qui nwdegree, alpha(1) generate(deg1)
- . qui nwdegree, alpha(1.5) generate(deg1_5)

- . list deg*
- hline 6c -hline 11c -hline 6c -hline 11
- c | deg0 deg0_5 deg1 deg1_5 c |
- hline 6c -hline 11c -hline 6c -hline 11
- 1. c | 2 4 8 16 c |
- 2. c | 4 5.6568542 8 11.313708 c |
- 3. c | 2 3.4641016 6 10.392304 c |
- 4. c | 1 1 1 1 c |
- 5. c | 2 4 8 16 c |
- hline 6c -hline 11c -hline 6c -hline 11
- 6. c | 1 2.6457512 7 18.52026 c |
- hline 6c -hline 11c -hline 6c -hline 11

In the following example, the degree distributions for in- and outdegree are saved in Stata matrices *matindeg* and *matoutdeg*:

```stata
. nwwebuse glasgow
. nwdegree glasgow1, generate(_outdegree _indegree) in(matcell(matindeg)) out(matcell(matoutdeg))
. mat list matindeg
```
The next example saves the out- and indegree centrality in the variables *myout* and *myin* and the information about isolates in *myisolate*.

```stata
. nwdegree glasgow1, generate(myout myin mysiolate) isolates
```

## Supported network types

Binary: yes. Directed: yes - generates separate *_indegree*/*_outdegree* (or *_instrength*/ *_outstrength* for a valued network) automatically. Weighted: **W1**, native - the Opsahl et al. (2010) generalized degree formula above is the command's default and only formulation, controlled by `alpha()`; weight meaning is tie strength, used directly (not a distance). Signed: not checked. Two-mode: **T1-via-redirect** - automatically redirects to [nw2degree](nw2degree.md) with a clear note when given a two-mode network, forwarding `alpha()` (nw2degree gained its own weighted two-mode degree/strength variant, the same Opsahl formula applied to bipartite normalization) and naming explicitly, not silently, any other one-mode-only option (`isolates`, `standardize`, `in()`, `out()`, `outputoff`) that has no bipartite equivalent and was ignored.

## References

Tore Opsahl, Filip Agneessens, John Skvoretz (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. *Social Networks* 32 (3), 245-251.

## See also

- [nwbetween](nwbetween.md), [nwcloseness](nwcloseness.md), [nwclustering](nwclustering.md), [nwevcent](nwevcent.md), [nwkatz](nwkatz.md)
- last certified : 24 Aug 2026
