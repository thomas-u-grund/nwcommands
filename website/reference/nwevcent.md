---
title: "nwevcent"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Eigenvector centrality"
---

# `nwevcent`

Eigenvector centrality

## Syntax

```stata
nwevcent
[netname]
[,
gen:erate(varname)
nosym
weighted
replace
bin:ary]
```

| | |
|---|---|
| `gen:erate`(*`varname`*) | **Required.** Variable name for eigenvector centrality scores |
| `nosym` | do not symmetrize network before calculation |
| `weighted` | use the tie values of a valued network; redundant, this is the default (kept for compatibility) |
| `replace` | replace existing *generate()* variable |
| `bin:ary` | Ignore the tie values of a valued network (by default they are used) |

## Description

Calculates eigenvector centrality for each node *i* in a netwwork and saves the result as a Stata variable. It assigns relative scores to all nodes in the network based on the concept that connections to high-scoring nodes contribute more to the score of the node in question than equal connections to low-scoring nodes.

By default, a valued network is calculated on the tie values themselves, so that stronger ties contribute proportionally more, matching the standard weighted generalization of eigenvector centrality (Newman 2004, Bonacich power centrality). Option **binary** instead dichotomizes the network before calculation (any nonzero, non-missing tie value counts as a tie, regardless of magnitude). **weighted** is redundant and has no effect on an unvalued network (there is nothing to weight by).

Eigenvector centrality is only defined for connected networks.

## Network types

**Directed:** symmetrized by default; `nosym` uses outgoing ties (igraph uses incoming ties). **Valued:** the tie values are used by default (`weighted` is redundant); `binary` ignores them. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The power iteration runs in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both give the same result (they differ by less than 1e-10 relative). Measured in Stata/BE, random undirected network with 10 ties per node: 5,000 nodes 0.05 seconds, 20,000 nodes 0.1 seconds, 100,000 nodes 0.5 seconds (the Mata route needs 0.6, 2.6 and 14 seconds).

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## Examples

```stata
. nwwebuse gang, nwclear
. nwevcent gang, generate(_evcent)
. sum _evcent
. nwevcent gang, generate(_evcent_w) weighted
```

## References

Newman, M.E.J. (2004). Analysis of weighted networks. *Physical Review E* 70, 056131.

Bonacich, P. (1972). Factoring and weighting approaches to status scores and clique identification. *Journal of Mathematical Sociology* 2(1), 113-120.

## See also

- [nwcloseness](nwcloseness), [nwbetween](nwbetween), [nwdegree](nwdegree), [nwcloseness](nwcloseness)

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
