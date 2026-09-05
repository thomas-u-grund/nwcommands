---
title: "nw2degree"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Two-mode (bipartite) degree centrality"
---

# `nw2degree`

Two-mode (bipartite) degree centrality

## Syntax

```stata
nw2degree
[netlist]
[,
generate(newvarname)
replace
silent
alpha(#)]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores two-mode degree centrality |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |
| `alpha(#)` | Weighted (tie-strength-aware) degree/strength blend, Opsahl et al. (2010); default = *0* (plain unweighted degree, identical to omitting the option) |

## Description

`nw2degree` calculates degree centrality for a two-mode (bipartite) network, using the normalization of Borgatti and Everett (1997). A node's ordinary (raw) degree can only ever reach as high as the size of the *other* mode - a mode-1 node can tie to at most every mode-2 node, never to another mode-1 node - so [nwdegree](nwdegree.md)'s usual *n - 1* normalization does not apply here. Instead, each node's raw degree is divided by the size of the mode it does *not* belong to:

*C'D(i) = degree(i) / n_other*, where *n_other* is the number of nodes in the other mode

so that a mode-1 node tied to every mode-2 node (or vice versa) scores exactly 1, matching ordinary degree centrality's own [0,1] range and interpretation.

`generate()` is required and names the new variable that holds this value for every node, regardless of which mode it belongs to (mode membership itself is available via [nw2set](nw2set.md)'s own mode-id variable, not duplicated here).

`alpha(#)` generalizes the plain tie-count formula above to a weighted (tie-strength-aware) variant, using the same Opsahl, Agneessens and Skvoretz (2010) blend [nwdegree](nwdegree.md)'s own `alpha()` already uses for one-mode degree:

*degree_alpha(i) = k_i * (s_i/k_i)^alpha*, then normalized by *n_other* exactly as above

where *k_i* is node *i*'s plain tie count and *s_i* is its tie-*value* sum (its "strength"). `alpha(0)` (the default) reduces this exactly to plain tie-count degree - the two formulas agree bit-for-bit, so leaving `alpha()` unspecified never changes existing results. `alpha(1)` gives pure normalized strength (tie-value sum / other-mode size), ignoring tie count entirely. Values between 0 and 1 blend the two; values above 1 emphasize a few strong ties over many weak ones, and negative values do the reverse. On a binary (unweighted) network every tie already has value 1, so *s_i = k_i*, `alpha()` has no effect at any value, and the plain formula always applies.

## Examples

```stata
. nwclear
. mata: net = (1,1\1,0\0,1)
. nw2set, mat(net) name(mynet)
. nw2degree mynet, generate(_2degree)
```
- Weighted (strength-aware) variant, on a valued two-mode network:

```stata
. nwclear
. clear
. input str10 person str10 org value
. "A" "X" 2
. "A" "Y" 4
. "B" "Z" 6
. end
. nwset person org value, twomode name(affil)
. nw2degree affil, generate(strength) alpha(1)
```

## Supported network types

Binary: yes. Directed: not applicable - two-mode ties in this package's storage are inherently undirected (a tie either connects a mode-1 node to a mode-2 node or it does not). Weighted: **W1**, native - `alpha()` generalizes the plain tie-count formula to a tie-strength-aware blend (Opsahl et al. 2010), the same convention [nwdegree](nwdegree.md)'s own `alpha()` uses for one-mode degree; `alpha(0)`, the default, is bit-for-bit identical to the original unweighted formula. Signed: not checked - a negative tie value would distort the strength sum `alpha()` relies on, not handled distinctly from "no tie". Two-mode: this command requires a two-mode network and errors clearly on a one-mode one, the opposite convention of most other commands in this package.

## References

Borgatti, S.P., Everett, M.G. (1997). Network analysis of 2-mode data. *Social Networks* 19(3), 243-269.

Opsahl, T., Agneessens, F., Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. *Social Networks* 32(3), 245-251.

## See also

- [nwdegree](nwdegree.md), [nw2set](nw2set.md), [nw2project](nw2project.md), [nw2clustering](nw2clustering.md)

- last certified : 02 Sep 2026
