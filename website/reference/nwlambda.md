---
title: "nwlambda"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Edge (line) connectivity matrix between all node pairs"
---

# `nwlambda`

Edge (line) connectivity matrix between all node pairs

## Syntax

```stata
nwlambda
[netname]
[,
name(newnetname)
xvars
replace]
```

| | |
|---|---|
| `name(newnetname)` | Name of the new connectivity network; default = *lambda* |
| `xvars` | Generate Stata variables for the new network |
| `replace` | Replace an existing network of the same name |

## Description

`nwlambda` computes the EDGE (or "line") connectivity between every pair of nodes - *lambda_ij*, the maximum number of edge-disjoint paths connecting *i* and *j*, equivalently (by Menger's theorem's edge version) the size of the smallest set of ties whose removal would disconnect them - and stores the result as a new, valued, undirected network [newnetname](newnetname) (default: *lambda*). This is Borgatti, Everett & Shirey's (1990) own foundation for **lambda sets** (also called LS sets): a maximal subset of nodes where every pair inside has HIGHER edge connectivity with each other than either one has with any node outside the set - a classical cohesive-subgroup concept, and the edge-connectivity sibling of [nwkcomponents](nwkcomponents)'s own VERTEX-connectivity-based k-components.

Computed via a direct max-flow (Edmonds-Karp) between every pair of nodes on the network's own symmetrized, binarized adjacency matrix - always undirected and binary, matching every other classical cohesive-subgroup command in this package ([nwclique](nwclique), [nwkplex](nwkplex), [nwnclique](nwnclique), [nwkcomponents](nwkcomponents) all make the identical choice, since none of these concepts has a standard directed/valued generalization in the literature). *lambda_ii* (self-comparison) is undefined and stored as missing.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwlambda flomarriage
. nwsummarize lambda, matonly
```

## Supported network types

Binary: yes (only) - similarity is computed from binary edge-connectivity; tie values are ignored. Directed: yes - automatically symmetrized first (edge connectivity has no standard directed generalization in the classical cohesive-subgroup literature, the same choice [nwclique](nwclique), [nwkplex](nwkplex), [nwnclique](nwnclique), [nwkcomponents](nwkcomponents) already make). Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## Stored results

**Scalars**

- **r(nodes)** number of nodes

**Macros**

- **r(netname)** name of the new connectivity network

## References

Borgatti, S.P., Everett, M.G., Shirey, P.R. (1990). LS sets, lambda sets and other cohesive subsets. *Social Networks* 12(4), 337-357.

Menger, K. (1927). Zur allgemeinen Kurventheorie. *Fundamenta Mathematicae* 10, 96-115.

## See also

- [nwkcomponents](nwkcomponents), [nwcohesion](nwcohesion), [nwhierarchy](nwhierarchy), [nwclique](nwclique), [nwkplex](nwkplex)

- last certified : 31 Aug 2026
