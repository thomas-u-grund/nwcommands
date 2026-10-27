---
title: "nw2fromedge"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Import two-mode network data from edgelist"
---

# `nw2fromedge`

Import two-mode network data from edgelist

## Syntax

```stata
nw2fromedge 
level1
level2
[tievalue]
[if]
[,
nwfromedge_options
]
```

## Description

`nw2fromedge` imports a two-mode network from a dataset in edgelist format. It is very similar to [nwfromedge](nwfromedge).

A two-mode network consists of two sets of units (e. g. people and events) and relations connect the two sets, e. g. participation of people in social events. Some examples are:

- Membership in institutions - people, institutions, is a member, e.g. directors and commissioners on the boards of corporations.

- Voting for suggestions - polititians, suggestions, votes for.

- Citation network, where first set consists of authors, the second set consists of articles/papers, connection is a relation author cites a paper.

- Co-autorship networks - authors, papers, is a (co)author. A corresponding graph is called bipartite graph – lines connect only vertices from one to vertices from another set – inside sets there are no connections.

An edgelist is a set of two (or three in the case of a valued network) variables representing relations. Nodes are identified by entries in the cells.  For example, the data

```stata
. use "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/data/institutions.dta", clear
. list _all

    +------------------------------+
    |   person   institu~n   years |
    |------------------------------|
 1. |   Thomas      Oxford       5 |
 2. |    Peter      Oxford       7 |
 3. |      Tim      Oxford       4 |
 4. |    Peter         LiU       1 |
 5. |      Tim         LiU       1 |
    |------------------------------|
 6. |   Thomas         LiU       1 |
 7. | Mathilde        UdeM       5 |
 8. |   Thomas        UdeM       1 |
 9. |  Michael         ETH       3 |
10. |  Michael   Groningen       5 |
    |------------------------------|
11. |   Thomas         ETH       1 |
    +------------------------------+
```
stores information about the affiliation of individual researchers.

The following command declares such data as two-mode network data:

```stata
. nw2fromedge person institution, name(mynet)
```
Besides setting the network, this also creates a new variable *_nwmode*, which has the value 1 for persons (Peter, Tim, Thomas, Michael, Mathilde) and value 2 for institutions (LiU, UdeM, Oxford, ETH, Groningen).

[nwplot](nwplot) has no bipartite-specific logic of its own, so nodes are **not** colored by mode automatically; pass the *_nwmode* variable this command creates to `color()` (or `symbol()`) explicitly to tell the two node sets apart at a glance:

```stata
. nwplot mynet, color(_nwmode)
```

## Supported network types

Two-mode: yes - builds the two-mode network from two columns of ids; the two column names become the level labels. A value of 0 declares the node without a tie. Binary: yes. Directed: not applicable - two-mode ties are inherently undirected affiliations. Weighted: yes, via a third edge-list column. Signed: not checked. A node with zero ties (an isolate) is never created - an edgelist has no way to record one - use [nwaddnodes](nwaddnodes)'s own **mode()** option afterward to add any isolates the source data could not represent.

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
