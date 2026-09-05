---
title: "nwsimilar"
parent: "Command reference"
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
,
[type(type)
context(context)
name(newnetname)
xvars]
```

| | |
|---|---|
| `type`(*[type](nwsimilar)*) | Type of similarity between two nodes; default = pearson |
| `context`(*[context](nwsimilar)*) | Context definition for similarity calculation; default = both (alias: `mode()`, kept for backward compatibility - [nwdissimilar](nwdissimilar), this command's own sibling, uses `context()` for the identical concept) |
| `name`(*[newnetname](newnetname)*) | Name of the new similarity network; default = *_similar* |
| `xvars` | Generate Stata variables for the network |

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

*D_ij = (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)) / 2 * (n - 1)*

**Cross-product similarity:**

Calculates the cross-product of the tie vectors of nodes ** and *j*

*D_ij = (sum(i_outvec :* j_outvec) + sum(i_invec :* j_invec))*

## Supported network types

Binary: yes. Directed: yes (**mode()** lets you restrict the comparison to incoming or outgoing ties only). Weighted: **pearson** (via [nwcorrelate](nwcorrelate)) and **crossproduct** use tie weights directly; **hamming**/**jaccard**/**matches** binarize each tie before comparing, so tie strength does not affect these three. Signed: not checked. Two-mode: not supported - operates on the network's own square adjacency matrix. The similarity network itself always carries a genuine (non-missing) diagonal (a node is maximally similar to itself) and inherits its source network's own node labels, so it can be compared directly against the source network node-for-node.

## See also

- [nwdissimilar](nwdissimilar), [nwcorrelate](nwcorrelate), [nwhierarchy](nwhierarchy)
