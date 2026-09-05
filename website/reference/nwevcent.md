---
title: "nwevcent"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate eigenvector centrality"
---

# `nwevcent`

Calculate eigenvector centrality

## Syntax

```stata
nwevcent
[netname]
[,
generate(varname)
nosym
weighted
replace]
```

| | |
|---|---|
| `generate`(*`varname`*) | **Required.** Variable name for eigenvector centrality scores |
| `nosym` | do not symmetrize network before calculation |
| `weighted` | calculate on tie values instead of dichotomizing a valued network |
| `replace` | replace existing *generate()* variable |

## Description

Calculates eigenvector centrality for each node *i* in a netwwork and saves the result as a Stata variable. It assigns relative scores to all nodes in the network based on the concept that connections to high-scoring nodes contribute more to the score of the node in question than equal connections to low-scoring nodes.

By default, a valued network is dichotomized before calculation (any nonzero, non-missing tie value counts as a tie, regardless of magnitude) - the historical, still-default behavior of this command. Option **weighted** instead calculates on the tie values themselves, so that stronger ties contribute proportionally more, matching the standard weighted generalization of eigenvector centrality (Newman 2004, Bonacich power centrality). **weighted** has no effect on an unvalued network (there is nothing to weight by).

Eigenvector centrality is only defined for connected networks.

## Examples

```stata
. nwwebuse gang, nwclear
. nwevcent gang, generate(_evcent)
. sum _evcent
. nwevcent gang, generate(_evcent_w) weighted
```

## Supported network types

Binary: yes. Directed: yes - symmetrized by default (same "no-prefix trap" `nosym` convention as [nwcloseness](nwcloseness.md)/[nwkatz](nwkatz.md)), `nosym` available. Weighted: not by default - `weighted` switches to the tie-value-weighted generalization (Newman 2004, Bonacich power centrality); has no effect on an unvalued network. Signed: not checked. Two-mode: not applicable (one-mode only).

## References

Newman, M.E.J. (2004). Analysis of weighted networks. *Physical Review E* 70, 056131.

Bonacich, P. (1972). Factoring and weighting approaches to status scores and clique identification. *Journal of Mathematical Sociology* 2(1), 113-120.

## See also

- [nwcloseness](nwcloseness.md), [nwbetween](nwbetween.md), [nwdegree](nwdegree.md), [nwcloseness](nwcloseness.md)

- last certified : 24 Aug 2026
