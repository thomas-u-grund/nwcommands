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
save(filename[, replace])
silent
]
```

| | |
|---|---|
| `mat` | Display adjacency matrix of the network |
| `matonly` | Only display adjacency matrix of the network |
| `detail` | Calculate additional network measures: reciprocity, transitivity and the centralization measures (their `r()` results are only filled with `detail`); reciprocity is displayed as n/a for an undirected network (the stored `r(reciprocity)` is unchanged) |
| `save(`*filename*[`, replace`]`)` | Save the network measures in a Stata data set, one observation per network; an existing file is replaced (with or without `replace`) |
| `silent` | Compute and return results without displaying anything |

## Description

`nwsummarize` calculates and displays a variety of network summary statistics. If no netlist is specified, summary statistics are calculated for the current network.

**Missing ties.** To test whether a network has missing ties, do not test **r(missing_edges)** > 0: the count includes the diagonal cells of a network without self-loops, so it equals the number of nodes for a network without any missing tie. Use **r(missing_edges)** - **r(nodes)** > 0 for a one-mode network without self-loops (see the stored results).

## Network types

**Directed:**, **Valued:** the summaries reflect direction and tie values. **Two-mode:** yes - shows the two levels with sizes and labels; the density is the ties over the pairs from different modes. **Signed:** negative values are not treated specially. The output says that edges and density count every tie with a non-zero value on a valued network, and how many missing ties there are: they are not counted as ties and not as pairs in the density (the measures of `detail` treat them as 0). See [nwnetworktypes](nwnetworktypes).

## Limits

Counts, minimum, maximum and density of a network held as stored ties are read from the ties: 20,000 nodes 0.02 seconds and 0.2 GB in Stata/BE.

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
- **r(missing_edges)** --- number of cells of the adjacency matrix without a value (missing), including the *n* diagonal cells of a network without self-loops (**r(selfloop)** is **false**) and the pairs within a mode of a two-mode network; it is therefore *n* and not 0 for a network without any missing tie. In an undirected network a missing tie fills two cells. The number of missing off-diagonal cells of a one-mode network without self-loops is **r(missing_edges)** - **r(nodes)**
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

*nwcommands version 3.34.0, 21 November 2026* ([check your installed version](nwversion))
