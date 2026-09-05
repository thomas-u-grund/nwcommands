---
title: "nwdissimilar"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Generate node dissimilarities"
---

# `nwdissimilar`

Generate node dissimilarities

## Syntax

```stata
nwdissimilar 
[netname]
,
[type(type)
context(context)
name(newnetname)
xvars
labs(lab1 lab2 ...)
vars(newvarlist)]
```

| | |
|---|---|
| `type`(*[type](nwdissimilar)*) | Type of dissimilarity between two nodes; default = euclidean |
| `context`(*[context](nwdissimilar)*) | Context definition for dissimilarity calculation; default = both |
| `name`(*[newnetname](newnetname)*) | Name of the new dissimilarity network; default = *_dissimilar* |
| `xvars` | Generate Stata variables for the network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels; default = the source network's own labels |
| `vars`(*`newvarlist`*) | new variables that are used for the network |

## Description

This command calculates the dissimilarities between all nodes *i* and *j* and saves the result in a new network. The dissimilarity between two nodes reflects how dissimilar these nodes are regarding the ties they have to other nodes (tie vectors).

By default, the dissimilarity is calculated based on both incoming and outgoing ties (**context(both)**). With **context(incoming)** the dissimilarity between two nodes *i* and *j* is calculated only based on the ties they receive (columns). Option **context(outgoing)** only considers outgoing ties (rows) when calculating the dissimilarity between nodes. Practially, option **context(both)** stacks the vector of outgoing and incoming ties.

**Euclidean distance:**

The Euclidean distance between two tie vectors is equal to the square root of the sum of the squared differences between them.  That is, the strength of actor A's tie to C is subtracted from the strength of actor B's tie to C, and the difference is squared.  This is then repeated across all the other actors (D, E, F, etc.), and summed.  The square root of the sum is then taken.

*D_ij = sqrt(sum((i_outvec :- j_outvec):^2) + sum((i_invec :- j_invec):^2))*

**Manhatten distance:**

This distance is simply the sum of the absolute difference between the actor's ties to each alter, summed across the alters.

*D_ij = sum(abs(i_outvec :- j_outvec)) + sum(abs(i_invec :- j_invec))*

**Hamming distance:**

The Hamming distance is the number of entries in the tie vector for one actor that would need to be changed in order to make it identical to the tie vector of the other actor.  These differences could be either adding or dropping a tie, so the Hamming distance treats joint absence as similarity.

*D_ij = sum(i_outvec :!= j_outvec) + sum(i_invec :!= j_invec)*

**Jaccard distance:**

The Jaccard distance is simply: 1 - Jaccard index. The Jaccard index of two tie vectors A and B is the the number of ties that exist in both A and B divided by the total number of ties that exist either in A or in B. When the tie profiles of nodes *i* and *j* are exactly the same the Jaccard index equals 1.

*D_ij = 1 - sum(A :!= 0 and B :!= 0) / sum(A :!= 0 or B :!= 0)*

**Nonmatches distance:**

Simply gives the percentage of dyads (tie or non-tie) that nodes *i* and *j* have in NOT common with the same alters. Notice that *i* and *j* are excluded from from these alters.

*D_ij = 1 - (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)) / 2 * (n - 1)*

## Supported network types

Binary: yes. Directed: yes (**context()** lets you restrict the comparison to incoming or outgoing ties only, which only matters for a directed network - an undirected network's in-ties and out-ties are identical, so all three **context()** values agree). Weighted: **euclidean**/**manhatten** use tie weights directly in their distance formula (a genuinely weighted-aware comparison); **hamming**/**jaccard**/**nonmatches** binarize each tie (*present vs. absent*) before comparing, so tie strength does not affect these three - not checked for automatic behavior beyond this, choose **type()** to match whether tie strength should matter. Signed: not checked - a negative tie weight participates in **euclidean**/ **manhatten**'s arithmetic like any other value, and in the binarizing types' ` != 0` test like any nonzero value, but no dedicated signed-network semantics exist. Two-mode: not supported - operates on the network's own square adjacency matrix; a genuinely two-mode (non-square, disjoint node-set) input is not checked and not expected to behave sensibly. The dissimilarity network itself always carries a genuine (non-missing) diagonal of 0 (a node is never dissimilar from itself) and inherits its source network's own node labels by default, so it can be compared directly against the source network node-for-node.

## See also

- [nwsimilar](nwsimilar), [nwcorrelate](nwcorrelate), [nwhierarchy](nwhierarchy)
