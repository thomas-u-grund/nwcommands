---
title: "nwsimilar"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate node similarities"
---

# `nwsimilar`

Generate node similarities

## Syntax

```stata
nwsimilar 
[netname]
[,
type(type)
context(context)
name(newnetname)
xvars
force]
```

| | |
|---|---|
| `type`(*[type](nwsimilar)*) | Type of similarity between two nodes; default = pearson |
| `context`(*[context](nwsimilar)*) | Context definition for similarity calculation; default = both (alias: `mode()`, kept for backward compatibility - [nwdissimilar](nwdissimilar), this command's own sibling, uses `context()` for the identical concept) |
| `name`(*[newnetname](newnetname)*) | Name of the new similarity network; default = *_similar* |
| `xvars` | Generate Stata variables for the network |
| `force` | Run the command although its matrices would not fit in memory (it stops with r(484) above about 12,900 nodes otherwise) |

## Description

This command calculates the similarities between all nodes *i* and *j* and saves the result in a new network. The similarity between two nodes reflects how similar these nodes are regarding the ties they have to other nodes (tie vectors).

By default, the similarity is calculated based on both incoming and outgoing ties (**mode(both)**). With **mode(incoming)** the similarity between two nodes *i* and *j* is calculated only based on the ties they receive (columns). Option **mode(outgoing)** only considers outgoing ties (rows) when calculating the similarity between nodes. Practially, option **mode(both)** stacks the vector of outgoing and incoming ties.

**Pearson similarity:**

This measure calculates the Pearson correlation coefficient for two tie vectors of nodes *i* and *j*. See [here for more information](nwcorrelate) on this (see also [nwcorrelate](nwcorrelate).

**Hamming similarity:**

The Hamming similarity is the number of entries in the tie vectors of nodes *i* and *j* that are identical. Notice that the Hamming similarity treats joint absence as similarity as well.

*D_ij = sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)*

**Jaccard similarity:**

The Jaccard similarity (or Jaccard index) of two tie vectors A and B is the the number of ties that exist in both A and B divided by the total number of ties that exist either in A or in B. When the tie profiles of nodes *i* and *j* are exactly the same the Jaccard index equals 1. In contrast to the Hamming similarity, the Jaccard similarity does not consider non-ties.

*D_ij = sum(A :!= 0 and B :!= 0) / sum(A :!= 0 or B :!= 0)*

**Matches similarity:**

Simply gives the percentage of dyads (tie or non-tie) that nodes *i* and *j* have in common with the same alters. Notice that *i* and *j* are excluded from from these alters.

*D_ij = (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)) / (2 * (n - 2))*, the sums over the alters other than *i* and *j*

**Cross-product similarity:**

Calculates the cross-product of the tie vectors of nodes *i* and *j*

*D_ij = (sum(i_outvec :* j_outvec) + sum(i_invec :* j_invec))*

The similarity network has a non-missing diagonal (a node is maximally similar to itself) and the node labels of its source network, so it can be compared with the source network node for node.

## Network types

**Directed:** `mode()` restricts the comparison to incoming or outgoing ties. **Valued:** `pearson` and `crossproduct` use the tie values; `hamming`, `jaccard` and `matches` use only the presence of ties. **Two-mode:** yes - a node is compared with the nodes of its own mode over the other mode; pairs from different modes are missing. **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

When the native plugin of your platform has this kernel, the cells are formed from the stored ties and not from dense matrix products: 5,000 nodes of the same network take 0.4 seconds for every type (1.0 to 1.2 seconds with the Mata code, 3.2 seconds for `type(pearson)`). The results are those of the Mata code (differences below 1e-13). A network with missing tie values, and a platform whose plugin lacks this kernel, use the Mata code.

The result is a dense *n*-by-*n* valued network. Measured in Stata/BE, random directed network with 10 ties per node: 5,000 nodes 1.1 seconds and 1.9 GB, 10,000 nodes 4 seconds and 7 GB. About 9 matrices of that size are held at once: above about 12,900 nodes the command stops at once with r(484) and a message with the memory needed (28.8 GB at 20,000 nodes); option `force` runs it anyway. The node labels of the new network are the labels of the source network at any size.

## Example

```stata
. nwwebuse florentine
. nwsimilar flomarriage

. nwsimilar flomarriage, type(hamming) mode(outgoing)
```

## See also

- [nwdissimilar](nwdissimilar), [nwcorrelate](nwcorrelate), [nwhierarchy](nwhierarchy), [nwregular](nwregular)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
