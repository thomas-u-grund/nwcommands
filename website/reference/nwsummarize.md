---
title: "nwsummarize"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
| `detail` | Calculate additional network measures: reciprocity, transitivity and the centralization measures (their `r()` results are only filled with `detail`); reciprocity is displayed as n/a for an undirected network (the stored `r(reciprocity)` is unchanged) |
| `save(filename)` | Save network measures in file |
| `silent` | Compute and return results without displaying anything |

## Description

`nwsummarize` calculates and displays a variety of network summary statistics. If no netlist is specified, summary statistics are calculated for the current network.

## Examples

```stata
. nwwebuse florentine
. nwsummarize flomarriage
--------------------------------------------------
   Network name:  flomarriage
   Network id:  2
   Nodes: 16
   Directed: false
   Valued:  false
   Two-mode: false
   Selfloop: false
   Edges: 20
   Minimum value:  0
   Maximum value:  1
   Density:  .167
   Mean degree:  2.50

. nwclear
. nwrandom 5, prob(.2) name(mynet)
. nwsummarize mynet, mat
--------------------------------------------------
   Network name:  mynet
   Network id:  1
   Nodes: 5
   Directed: true
   Valued:  false
   Two-mode: false
   Selfloop: false
   Arcs: 5
   Minimum value:  0
   Maximum value:  1
   Density:  .25
   Mean outdegree:  1.00

     1   2   3   4   5
  +---------------------+
1 |  0   0   0   0   1  |
2 |  0   0   0   0   0  |
3 |  0   0   0   0   1  |
4 |  0   0   0   0   0  |
5 |  1   1   0   1   0  |
  +---------------------+
```

## Stored results

- **nwsummarize** stores the following in **r()**:

- **Scalars**
- **r(id)** --- internal ID of the network
- **r(nodes)** --- number of nodes in the network
- **r(minval)** --- minimum of tie values
- **r(maxval)** --- maximum of tie values
- **r(edges)** --- number of edges (undirected network)
- **r(arcs)** --- number of arcs (directed network)
- **r(edges_sum)** --- sum of edge values (undirected network)
- **r(arcs_value)** --- sum of arc values (directed network)
- **r(density)** --- network density (two-mode network: ties over the pairs between the two modes)
- **r(meandegree)** --- mean degree: twice the edges per node (undirected network) or arcs per node, the mean outdegree, which equals the mean indegree (directed network); not for two-mode networks
- **r(reciprocity)** --- network reciprocity
- **r(transitivity)** --- network transitivity
- **r(dg_central)** --- degree centralization (undirected network, with `detail`)
- **r(indg_central)** --- indegree centralization (directed network, with `detail`)
- **r(outdg_central)** --- outdegree centralization (directed network, with `detail`)
- **r(missing_edges)** --- number of missing (undefined) dyads
- **r(selfloops)** --- number of self-loops
- **r(nodes1)** --- number of mode-1 nodes (two-mode networks only)
- **r(nodes2)** --- number of mode-2 nodes (two-mode networks only)

- **Macros**
- **r(directed)** --- if network is directed or not (undirected)
- **r(valued)** --- if network is declared as valued or not
- **r(mode2)** --- if network two-mode or not
- **r(name)** --- name of the network (alias: **r(netname)**)
- **r(labs)** --- comma-separated node labels
- **r(vars)** --- Stata variable names used to represent the network
- **r(selfloop)** --- if the network permits self-loops
- **r(provenance)** --- provenance/source note, if set (see [nwname](nwname))
- **r(temporal)** --- if the network is temporal
- **r(temporaltype)** --- temporal storage type, if **r(temporal)** is true
- **r(mode1_desc)** --- description of mode 1 (two-mode networks only)
- **r(mode2_desc)** --- description of mode 2 (two-mode networks only)

With a *netlist*, the results are those of the last network. The other results of [nwname](nwname) (for example **r(title)**, **r(modes)**, **r(mode1desc)**) are also left in **r()**; see its **Stored results**.

## See also

- [nwname](nwname), [nwdyads](nwdyads), [nwtriads](nwtriads)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
