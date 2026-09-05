---
title: "nw2fromedge"
parent: "Command reference"
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

`nw2fromedge` imports a two-mode network from a dataset in edgelist format. It is very similar to [nwfromedge](nwfromedge.md).

A two-mode network consists of two sets of units (e. g. people and events) and relations connect the two sets, e. g. participation of people in social events. Some examples are:

- Membership in institutions - people, institutions, is a member, e.g. directors and commissioners on the boards of corporations.

- Voting for suggestions - polititians, suggestions, votes for.

- Citation network, where first set consists of authors, the second set consists of articles/papers, connection is a relation author cites a paper.

- Co-autorship networks - authors, papers, is a (co)author. A corresponding graph is called bipartite graph – lines connect only vertices from one to vertices from another set – inside sets there are no connections.

An edgelist is a set of two (or three in the case of a valued network) variables representing relations. Nodes are identified by entries in the cells.  For example, the data

- . use "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/institutions.dta", clear
- . list _all
- hline 10c -hline 11c -hline 7
- c | person institu~n years c |
- hline 10c -hline 11c -hline 7
- 1. c | Thomas Oxford 5 c |
- 2. c | Peter Oxford 7 c |
- 3. c | Tim Oxford 4 c |
- 4. c | Peter LiU 1 c |
- 5. c | Tim LiU 1 c |
- hline 10c -hline 11c -hline 7
- 6. c | Thomas LiU 1 c |
- 7. c | Mathilde UdeM 5 c |
- 8. c | Thomas UdeM 1 c |
- 9. c | Michael ETH 3 c |
- 10. c | Michael Groningen 5 c |
- hline 10c -hline 11c -hline 7
- 11. c | Thomas ETH 1 c |
- hline 10c -hline 11c -hline 7

stores information about the affiliation of individual researchers.

The following command declares such data as two-mode network data:

```stata
. nw2fromedge person institution, name(mynet)
```
Besides setting the network, this also creates a new variable *_nwmode*, which has the value 1 for persons (Peter, Tim, Thomas, Michael, Mathilde) and value 2 for institutions (LiU, UdeM, Oxford, ETH, Groningen).

[nwplot](nwplot.md) has no bipartite-specific logic of its own, so nodes are **not** colored by mode automatically; pass the *_nwmode* variable this command creates to `color()` (or `symbol()`) explicitly to tell the two node sets apart at a glance:

```stata
. nwplot mynet, color(_nwmode)
```

## Supported network types

Two-mode: **T1**, native - this command's entire purpose is building a two-mode network directly from an edge list (ego/alter columns drawn from two distinct node sets). Binary: yes. Directed: not applicable - two-mode ties are inherently undirected affiliations. Weighted: yes, via a third edge-list column. Signed: not checked. A node with zero ties (an isolate) is never created - an edgelist has no way to record one - use [nwaddnodes](nwaddnodes.md)'s own **mode()** option afterward to add any isolates the source data could not represent.
