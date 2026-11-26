---
title: "nwspectral"
parent: "Core command reference"
grand_parent: "Packages and reference"
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
sym
silent
force
one:mode
plot
emb:edding
name(string)
saving(filename)
export(filename[, options])]
```

| | |
|---|---|
| `sym` | On a directed network, analyse the symmetrized network (a tie counts in both directions, with the larger of its two values); without it a directed network with unreciprocated ties is refused (error 198) |
| `gen:erate(newvarname)` | **Required.** Name of the Stata variable that stores each node's own Fiedler-vector entry |
| `bipartition` | Also generate a two-way spectral partition (variable *generate()***sign**) from the sign of the Fiedler vector |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `replace` | Replace existing variable(s) |
| `silent` | Suppress display of results |
| `force` | Run the complete decomposition of a network with more than 6,000 nodes |
| `one:mode` | Two-mode network: read the bipartite graph as a one-mode graph (a two-mode network is refused without it, error 6088) |
| `plot` | Draw the scree plot of the Laplacian eigenvalues, with the algebraic connectivity marked |
| `emb:edding` | With `plot`: a second panel with the second and third eigenvector as a scatter, the marker showing the sign of the second (the bipartition) |
| `name(string)` | Name for the graph created by `plot`; default = **spectral** |
| `sav:ing(filename)` | Save the graph to a `.gph` file; an existing file is replaced |
| `exp:ort(filename[, options])` | Write the graph with `graph export`; the file extension sets the format |

## Description

`nwspectral` computes the graph Laplacian **L = D - W** (D the diagonal weighted-degree matrix, W the adjacency/weight matrix) of a single network and its eigendecomposition - the standard starting point for spectral graph analysis. The classical Laplacian spectrum results below assume a symmetric matrix, so a directed network with unreciprocated ties is refused (error 198) unless option `sym` asks for the symmetrized network (the same convention as [nwcommunity](nwcommunity) and [nwkcomponents](nwkcomponents)); the output says which was done.

Three classical results are reported directly:

- **Connected components** --- The MULTIPLICITY of eigenvalue 0 in the Laplacian spectrum exactly equals the number of connected components - **r(components)** counts eigenvalues within **1e-8** of 0, cross-checkable directly against [nwcomponents](nwcomponents).
- **Algebraic connectivity** --- The second-smallest eigenvalue (the "Fiedler value", **r(algebraic_connectivity)**) - 0 for a disconnected network (matching the component-count result above), and otherwise a genuine measure of how well-connected the network is overall: larger values indicate a more robustly connected structure, harder to disconnect by removing few edges.
- **Spectral bipartition** --- The eigenvector belonging to the Fiedler value (the "Fiedler vector") - stored per node via `generate(newvarname)` (required) - is a classical continuous relaxation of graph bisection: nodes with similar Fiedler-vector values tend to be well-connected to each other. `bipartition` additionally generates a discrete two-way split from its sign (variable *generate()***sign**, e.g. *_fiedlersign* for `generate(_fiedler)`).

For a network with more than one connected component, the Fiedler value is 0 and its own eigenvector is not uniquely defined (any vector constant on each component, summing to zero overall, is an equally valid choice) - `nwspectral` still reports whatever eigenvector the underlying decomposition happens to return in that case, but `bipartition`'s resulting split should not be interpreted as meaningful when **r(algebraic_connectivity)** is (near) 0; use [nwcomponents](nwcomponents) directly instead for a disconnected network's own true partition.

## Network types

**Directed:** refused (error 198) when some ties are not reciprocated, because the measure is defined for an undirected network; option `sym` analyses the symmetrized network (a tie counts in both directions, with the larger of its two values) and the output says so. A directed network whose ties are all reciprocated is the same as an undirected one and is analysed as such (the output says so). **Valued:** the tie values are used by default (`measure(valued)`); `measure(binary)` uses only the presence of ties. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first); `onemode` gives the spectrum of the bipartite graph. **Signed:** with negative values the Laplacian is not positive semi-definite and the results are not meaningful. See [nwnetworktypes](nwnetworktypes).

## Limits

The complete eigendecomposition of the dense Laplacian is needed for the Fiedler vector and for the eigenvalues that are returned, so the work grows with the cube of the number of nodes and the memory with its square. At 10,000 nodes it needs about 3 GB. Above 2,000 nodes the command prints a note; above 6,000 nodes it stops with r(484) unless `force` is given. There is no exact shortcut for the returned spectrum: only the Fiedler vector could be had from a sparse iteration, which this command does not offer.

Only a single network is accepted: the Fiedler vector of each network is a full per-node eigenvector.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwspectral flomarriage, generate(_fiedler)
. nwspectral flomarriage, bipartition generate(_fiedler) replace
```

## Drawing the spectrum

`plot` draws the Laplacian eigenvalues in ascending order, the values of **r(eigenvalues)**; the second one, the algebraic connectivity, is marked. A gap after the first eigenvalues points to few well separated groups, and the number of eigenvalues at 0 is the number of components. `embedding` adds a second panel with the second and third eigenvectors, one marker per node. `name()` names the graph in memory, `saving()` writes a `.gph` file and `export()` writes it with `graph export`. Other options go to `twoway` (`graph combine` with `embedding`) and come last; without `plot` they give an error. `plot` stops with error 198 for a two-mode network; a directed network follows the rule for `sym` above.

- `. nwspectral flomarriage, generate(_fiedler) replace plot embedding export(spectrum.png, width(1100))`

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

*nwcommands version 3.38.0, 26 November 2026* ([check your installed version](nwversion))
