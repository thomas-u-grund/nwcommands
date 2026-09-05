---
title: "nwsummarize"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Summarize a network"
---

# `nwsummarize`

Summarize a network

## Syntax

```stata
nwsummarize 
[netlist]
[,
mat
matonly
detail
save(filename)
silent
]
```

| | |
|---|---|
| `mat` | Display adjacency matrix of the network |
| `matonly` | Only display adjacency matrix of the network |
| `detail` | Calculate additional network measures, e.g. centralization, transitivity |
| `save(filename)` | Save network measures in file |
| `silent` | Compute and return results without displaying anything |

## Description

`nwsummarize` calculates and displays a variety of network summary statistics. If no netlist is specified, summary statistics are calculated for the current network.

## Examples

```stata
. nwwebuse florentine
```
- cmd. nwsummarize flomarriage
- hline 50
- Network name: flomarriage
- Network id: 2
- Nodes: 16
- Directed: false
- Valued: false
- Two-mode: false
- Selfloop: false
- Edges: 20
- Minimum value: 0
- Maximum value: 1
- Density: .1666666666666667

- . nwclear
- . nwrandom 5, prob(.2) name(mynet)
- . nwsummarize mynet, mat
- hline 50
- Network name: mynet
- Network id: 1
- Nodes: 5
- Directed: true
- Valued: false
- Two-mode: false
- Selfloop: false
- Arcs: 5
- Minimum value: 0
- Maximum value: 1
- Density: .25

- 1 2 3 4 5
- hline 21
- 1 c | 0 0 0 0 1 c |
- 2 c | 0 0 0 0 0 c |
- 3 c | 0 0 0 0 1 c |
- 4 c | 0 0 0 0 0 c |
- 5 c | 1 1 0 1 0 c |
- hline 21

## Supported network types

Binary: yes. Directed: yes. Weighted: yes, dyad/triad/degree summaries reflect tie values where applicable. Signed: not checked. Two-mode: not checked.

## Stored results

- **nwsummarize** stores the following in **r()**:

**Scalars**

- **r(id)** internal ID of the network
- **r(nodes)** number of nodes in the network
- **r(minval)** minimum of tie values
- **r(maxval)** maximum of tie values
- **r(edges)** number of edges (undirected network)
- **r(arcs)** number of arcs (directed network)
- **r(edges_sum)** sum of edge values (undirected network)
- **r(arcs_value)** sum of arc values (directed network)
- **r(density)** network density
- **r(reciprocity)** network reciprocity
- **r(transitivity)** network transitivity
- **r(missing_edges)** number of missing (undefined) dyads
- **r(selfloops)** number of self-loops
- **r(nodes1)** number of mode-1 nodes (two-mode networks only)
- **r(nodes2)** number of mode-2 nodes (two-mode networks only)

**Macros**

- **r(directed)** if network is directed or not (undirected)
- **r(valued)** if network is declared as valued or not
- **r(mode2)** if network two-mode or not
- **r(name)** name of the network (alias: **r(netname)**)
- **r(labs)** comma-separated node labels
- **r(vars)** Stata variable names used to represent the network
- **r(selfloop)** if the network permits self-loops
- **r(provenance)** provenance/source note, if set (see [nwname](nwname))
- **r(temporal)** if the network is temporal
- **r(temporaltype)** temporal storage type, if **r(temporal)** is true
- **r(mode1_desc)** description of mode 1 (two-mode networks only)
- **r(mode2_desc)** description of mode 2 (two-mode networks only)

The full set above is inherited unchanged from the internal [nwname](nwname) call this command makes on your behalf - see [nwname](nwname)'s own **Stored results** section for the authoritative, complete list (this command does not add or remove any of it).

## See also

- [nwname](nwname), [nwdyads](nwdyads), [nwtriads](nwtriads)
- last certified : 24 Aug 2026
