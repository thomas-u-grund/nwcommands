---
title: "nwspectral"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Graph Laplacian spectral analysis"
---

# `nwspectral`

Graph Laplacian spectral analysis

## Syntax

```stata
nwspectral
[netname]
[,
generate(newvarname)
bipartition
measure(string)
replace
silent]
```

| | |
|---|---|
| `generate(newvarname)` | Name of the Stata variable that stores each node's own Fiedler-vector entry; default = *_fiedler* |
| `bipartition` | Also generate a two-way spectral partition (*_fiedlersign*, or *generate()***sign**) from the sign of the Fiedler vector |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `replace` | Replace existing variable(s) |
| `silent` | Suppress display of results |

## Description

`nwspectral` computes the graph Laplacian **L = D - W** (D the diagonal weighted-degree matrix, W the adjacency/weight matrix) of a single network and its eigendecomposition - the standard starting point for spectral graph analysis. Always computed on the undirected, symmetrized network (no **symmetrize** option needed - a directed network is symmetrized automatically, the same convention [nwcommunity](nwcommunity.md)/[nwkcomponents](nwkcomponents.md) already use, since the classical Laplacian spectrum results below assume a symmetric matrix).

Three classical results are reported directly:

- ****Connected components**** --- The MULTIPLICITY of eigenvalue 0 in the Laplacian spectrum exactly equals the number of connected components - **r(components)** counts eigenvalues within **1e-8** of 0, cross-checkable directly against [nwcomponents](nwcomponents.md).
- ****Algebraic connectivity**** --- The second-smallest eigenvalue (the "Fiedler value", **r(algebraic_connectivity)**) - 0 for a disconnected network (matching the component-count result above), and otherwise a genuine measure of how well-connected the network is overall: larger values indicate a more robustly connected structure, harder to disconnect by removing few edges.
- ****Spectral bipartition**** --- The eigenvector belonging to the Fiedler value (the "Fiedler vector") - stored per node via `generate(newvarname)` (default *_fiedler*) - is a classical continuous relaxation of graph bisection: nodes with similar Fiedler-vector values tend to be well-connected to each other. `bipartition` additionally generates a discrete two-way split from its sign (*_fiedlersign*, or *generate()***sign** when `generate()` is given).

For a network with more than one connected component, the Fiedler value is 0 and its own eigenvector is not uniquely defined (any vector constant on each component, summing to zero overall, is an equally valid choice) - `nwspectral` still reports whatever eigenvector the underlying decomposition happens to return in that case, but `bipartition`'s resulting split should not be interpreted as meaningful when **r(algebraic_connectivity)** is (near) 0; use [nwcomponents](nwcomponents.md) directly instead for a disconnected network's own true partition.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwspectral flomarriage
. nwspectral flomarriage, bipartition replace
```

## Supported network types

Binary: yes. Directed: yes, automatically symmetrized (the classical Laplacian spectrum results this command reports assume a symmetric matrix, the same reasoning [nwcommunity](nwcommunity.md)/ [nwkcomponents](nwkcomponents.md) already apply). Weighted: yes, via `measure(valued)` (default for a valued network) - the Laplacian is built from tie weights directly rather than dichotomized presence/absence. Signed: not checked - a Laplacian built from mixed-sign weights is not guaranteed positive semi-definite, so results are not meaningful for a signed network. Two-mode: not checked - operates on the network's own square adjacency matrix. Only a single network is accepted (unlike most other commands in this package, which accept a full [netlist](netlist.md)) - each network's own Fiedler vector is a full per-node eigenvector, not a simple per-network scalar or per-node aggregate that stacks cleanly across multiple networks the way [nwcomponents](nwcomponents.md)'s component id does.

## Stored results

**Scalars**

- **r(algebraic_connectivity)** second-smallest Laplacian eigenvalue (the Fiedler value)
- **r(components)** number of Laplacian eigenvalues within 1e-8 of 0

**Matrices**

- **r(eigenvalues)** all Laplacian eigenvalues, sorted ascending

## References

Fiedler, M. (1973). Algebraic connectivity of graphs. *Czechoslovak Mathematical Journal* 23(2), 298-305.

von Luxburg, U. (2007). A tutorial on spectral clustering. *Statistics and Computing* 17(4), 395-416.

## See also

- [nwevcent](nwevcent.md), [nwcommunity](nwcommunity.md), [nwcomponents](nwcomponents.md), [nwkcomponents](nwkcomponents.md)

- last certified : 24 Aug 2026
