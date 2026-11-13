---
title: "nwspectral"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
,
gen:erate(newvarname)
[bipartition
measure(string)
replace
silent
force
one:mode]
```

| | |
|---|---|
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own Fiedler-vector entry |
| `bipartition` | Also generate a two-way spectral partition (variable *generate()***sign**) from the sign of the Fiedler vector |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `replace` | Replace existing variable(s) |
| `silent` | Suppress display of results |
| `force` | Run the complete decomposition of a network with more than 6,000 nodes |
| `one:mode` | Two-mode network: read the bipartite graph as a one-mode graph (a two-mode network is refused without it, error 6088) |

## Description

`nwspectral` computes the graph Laplacian **L = D - W** (D the diagonal weighted-degree matrix, W the adjacency/weight matrix) of a single network and its eigendecomposition - the standard starting point for spectral graph analysis. Always computed on the undirected, symmetrized network (no **symmetrize** option needed - a directed network is symmetrized automatically, the same convention [nwcommunity](nwcommunity) / [nwkcomponents](nwkcomponents) already use, since the classical Laplacian spectrum results below assume a symmetric matrix).

Three classical results are reported directly:

- **Connected components** --- The MULTIPLICITY of eigenvalue 0 in the Laplacian spectrum exactly equals the number of connected components - **r(components)** counts eigenvalues within **1e-8** of 0, cross-checkable directly against [nwcomponents](nwcomponents).
- **Algebraic connectivity** --- The second-smallest eigenvalue (the "Fiedler value", **r(algebraic_connectivity)**) - 0 for a disconnected network (matching the component-count result above), and otherwise a genuine measure of how well-connected the network is overall: larger values indicate a more robustly connected structure, harder to disconnect by removing few edges.
- **Spectral bipartition** --- The eigenvector belonging to the Fiedler value (the "Fiedler vector") - stored per node via `generate(newvarname)` (required) - is a classical continuous relaxation of graph bisection: nodes with similar Fiedler-vector values tend to be well-connected to each other. `bipartition` additionally generates a discrete two-way split from its sign (variable *generate()***sign**, e.g. *_fiedlersign* for `generate(_fiedler)`).

For a network with more than one connected component, the Fiedler value is 0 and its own eigenvector is not uniquely defined (any vector constant on each component, summing to zero overall, is an equally valid choice) - `nwspectral` still reports whatever eigenvector the underlying decomposition happens to return in that case, but `bipartition`'s resulting split should not be interpreted as meaningful when **r(algebraic_connectivity)** is (near) 0; use [nwcomponents](nwcomponents) directly instead for a disconnected network's own true partition.

## Network types

**Directed:** symmetrized. **Valued:** the tie values are used by default (`measure(valued)`); `measure(binary)` uses only the presence of ties. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first); `onemode` gives the spectrum of the bipartite graph. **Signed:** with negative values the Laplacian is not positive semi-definite and the results are not meaningful. See [nwnetworktypes](nwnetworktypes).

## Limits

The complete eigendecomposition of the dense Laplacian is needed for the Fiedler vector and for the eigenvalues that are returned, so the work grows with the cube of the number of nodes and the memory with its square. Measured in Stata/BE, random undirected network with 10 ties per node: 1,000 nodes 1.5 seconds, 2,000 nodes 14 seconds, 3,000 nodes 50 seconds, 5,000 nodes more than 180 seconds, 10,000 nodes more than 300 seconds (and about 3 GB). Above 2,000 nodes the command prints a note; above 6,000 nodes it stops with r(484) unless `force` is given. There is no exact shortcut for the returned spectrum: only the Fiedler vector could be had from a sparse iteration, which this command does not offer.

Only a single network is accepted: the Fiedler vector of each network is a full per-node eigenvector.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwspectral flomarriage, generate(_fiedler)
. nwspectral flomarriage, bipartition generate(_fiedler) replace
```

## Stored results

- **Scalars**
- **r(algebraic_connectivity)** --- second-smallest Laplacian eigenvalue (the Fiedler value)
- **r(components)** --- number of Laplacian eigenvalues within 1e-8 of 0

- **Matrices**
- **r(eigenvalues)** --- all Laplacian eigenvalues, sorted ascending

## References

Fiedler, M. (1973). Algebraic connectivity of graphs. *Czechoslovak Mathematical Journal* 23(2), 298-305.

von Luxburg, U. (2007). A tutorial on spectral clustering. *Statistics and Computing* 17(4), 395-416.

## See also

- [nwevcent](nwevcent), [nwcommunity](nwcommunity), [nwcomponents](nwcomponents), [nwkcomponents](nwkcomponents)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
