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

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
