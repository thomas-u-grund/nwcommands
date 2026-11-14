---
title: "nwlambda"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
replace
force]
```

| | |
|---|---|
| `name(newnetname)` | Name of the new connectivity network; default = *lambda* |
| `xvars` | Generate Stata variables for the new network |
| `replace` | Replace an existing network of the same name |
| `force` | Run the command although its matrices would not fit in memory (it stops with r(484) above 12 GB otherwise) |

## Description

`nwlambda` computes the EDGE (or "line") connectivity between every pair of nodes - *lambda_ij*, the maximum number of edge-disjoint paths connecting *i* and *j*, equivalently (by Menger's theorem's edge version) the size of the smallest set of ties whose removal would disconnect them - and stores the result as a new, valued, undirected network [newnetname](newnetname) (default: *lambda*). This is Borgatti, Everett & Shirey's (1990) own foundation for **lambda sets** (also called LS sets): a maximal subset of nodes where every pair inside has HIGHER edge connectivity with each other than either one has with any node outside the set - a classical cohesive-subgroup concept, and the edge-connectivity sibling of [nwkcomponents](nwkcomponents)'s own VERTEX-connectivity-based k-components.

Computed via a direct max-flow (Edmonds-Karp) between every pair of nodes on the network's own symmetrized, binarized adjacency matrix - always undirected and binary, matching every other classical cohesive-subgroup command in this package ([nwclique](nwclique), [nwkplex](nwkplex), [nwnclique](nwnclique), [nwkcomponents](nwkcomponents) all make the identical choice, since none of these concepts has a standard directed/valued generalization in the literature). *lambda_ii* (self-comparison) is undefined and stored as missing.

## Extracting lambda sets

`nwlambda` itself reports the raw connectivity matrix, not a discrete partition into lambda sets - deliberately, since the extraction step is already exactly what [nwhierarchy](nwhierarchy) does: lambda sets are recoverable as SINGLE-LINKAGE hierarchical clustering on the lambda matrix (a real graph-theoretic fact, not a heuristic: the Gomory-Hu tree of a graph represents every pairwise min-cut/edge-connectivity value as a single tree, and cutting that tree at successive thresholds is exactly single-linkage clustering on the full pairwise matrix). [nwhierarchy](nwhierarchy) already accepts an arbitrary dissimilarity network via its own `disnet()` option, so no new clustering code is needed - only a similarity-to-dissimilarity flip (lambda is a SIMILARITY: higher means MORE connected) and restoring a proper zero diagonal (a fresh network defaults to a missing, not zero, diagonal - `set_selfloop(1)` is needed before writing a real 0 there):

- Worked example - two triangles **A,B,C**/**D,E,F** joined by a single bridge tie **C-D**:

```stata
. nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(bridge) labs(A,B,C,D,E,F)
. nwlambda bridge, name(lam)
. _nwsyntax lam
. mata: __maxlam = max(*`netobj'->get_matrix())
. mata: __dissim = __maxlam :- *`netobj'->get_matrix()
. mata: _diag(__dissim, 0)
. mata: `netobj'->set_selfloop(1)
. mata: `netobj'->set_edge(__dissim)
. mata: mata drop __maxlam __dissim
. nwhierarchy, disnet(lam) linkage(singlelinkage) groups(2) generate(lamgroup)
```
recovers exactly the two intuitive lambda sets, **A,B,C** and **D,E,F**.

## Network types

**Directed:** symmetrized. **Valued:** tie values are ignored. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Limits

The edge connectivity of every pair is read from an equivalent-flow tree (Gusfield 1990): *n*-1 maximum flows on the sparse network instead of *n*(*n*-1)/2, each stopped as soon as it reaches the smaller degree of the two ends. The result is a dense *n*-by-*n* valued network, which is what takes the memory: it is held twice while the network is registered (20,000 nodes: 30 seconds and 6.5 GB). Measured on a random network with 10 ties drawn per node: 300 / 1,000 / 5,000 nodes take 0.02 / 0.09 / 2.2 seconds.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwlambda flomarriage
. nwsummarize lambda, matonly
```

## Stored results

- **Scalars**
- **r(nodes)** --- number of nodes

- **Macros**
- **r(netname)** --- name of the new connectivity network

## References

Borgatti, S.P., Everett, M.G., Shirey, P.R. (1990). LS sets, lambda sets and other cohesive subsets. *Social Networks* 12(4), 337-357.

Menger, K. (1927). Zur allgemeinen Kurventheorie. *Fundamenta Mathematicae* 10, 96-115.

The result is an *n*-by-*n* network and two matrices are held at once: above about 27,000 nodes (12 GB) the command stops at once with r(484), and `force` runs it anyway.

## See also

- [nwkcomponents](nwkcomponents), [nwcohesion](nwcohesion), [nwhierarchy](nwhierarchy), [nwclique](nwclique), [nwkplex](nwkplex)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
