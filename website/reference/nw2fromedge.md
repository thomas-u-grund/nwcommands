---
title: "nw2fromedge"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Import two-mode network data from an edge list"
---

# `nw2fromedge`

Import two-mode network data from an edge list

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

The two id variables must name different nodes. When both are numeric and their ranges overlap, the ids in *level2* are shifted by the largest id in *level1*; when both are string variables and share a value, the prefixes **m1_** and **m2_** are added to the ids of *level1* and *level2*. Both changes apply to the node names of the network only; the id variables themselves are not changed.

A two-mode network consists of two sets of units (e. g. people and events) and relations connect the two sets, e. g. participation of people in social events. Some examples are:

- Membership in institutions - people, institutions, is a member, e.g. directors and commissioners on the boards of corporations.

- Voting for suggestions - polititians, suggestions, votes for.

- Citation network, where first set consists of authors, the second set consists of articles/papers, connection is a relation author cites a paper.

- Co-autorship networks - authors, papers, is a (co)author. A corresponding graph is called bipartite graph – lines connect only vertices from one to vertices from another set – inside sets there are no connections.

An edgelist is a set of two (or three in the case of a valued network) variables representing relations. Nodes are identified by entries in the cells.  For example, the data

```stata
. use "https://nwcommands.org/examples/institutions.dta", clear
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

## One-mode projection

Sometimes one wants to collapse a two-mode network to a one-mode network (see [nw2project](nw2project)). This is called a one-mode projection. Such a projection is a simplification of the network to nodes of one level only. For example, in our example one can either collapse to the level of persons or to the level of institutions. The level to which one wants to collapse is specified in option **project()**.

For example, this loads the data above as a one-mode projection on level 1 (persons):

```stata
nw2project mynet, project(1) name(myproject1)
```
This generates a network *myproject1* with five unique actors (Peter, Tim, Thomas, Michael and Mathilde). By default, a one-mode projection on one level generates ties between nodes (on this level) when they have at least one network neighbor on the other level in common. In our case, projecting to the level of persons creates ties between persons when they share at least one institution. By default, such a one-mode projection is a valued network, where the tie values indicate how many institutions individuals share. To illustrate this, let us consider the relationship between Peter and Thomas. In this example, they share two institutions: Oxford and LiU.

Thomas - LiU

Peter  - LiU

Thomas - Oxford

Peter  - Oxford

A one-mode projection to the level of persons generates a tie between Thomas and Peter with value 2, because they share two institutions. A one-mode projection to the level of institutions would generate a tie with value 2 between the institutions Oxford and LiU, because they share two persons (Peter and Thomas).

When ties in the original network are valued there are several ways how the value of projected ties is generated. Option `stat()` can be one of the following: **min, max, minmax, sum, mean**. To illustrate what each one of them calculates tie values for the projection, let us consider the relationship between Peter and Thomas. They share two institutions: Oxford and LiU.

Thomas - LiU    - 1 year

Peter  - LiU    - 1 year

Thomas - Oxford - 5 years

Peter  - Oxford - 7 years

The option **stat(min)** takes the overall minimum from all these ties and generates the projection:

Peter - Thomas  - 1 year

The option **stat(max)** takes the overall maximum from all these ties and generates the projection:

Peter - Thomas  - 7 years

The option **stat(sum)** takes the sum over all these ties and generates the projection:

Peter - Thomas  - 14 years

The option **stat(mean)** takes the mean over all these ties and generates the projection:

Peter - Thomas  - 3.5 years

The option **stat(minmax)** takes for each institution Peter and Thomas share the minimum (Oxford = 5, LiU = 1) and and takes the maximum out of these scores as tie value. Substantially, this corresponds to the longest time that Peter and Thomas were at the same institution. This is the default option.

Peter - Thomas  - 5 years

## Network types

**Directed:** not applicable (two-mode ties are undirected). **Valued:** tie values from an optional third column. **Two-mode:** yes - builds the two-mode network from two columns of ids, whose names become the level labels; a row with value 0 declares a node without a tie. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

Above 20,000 nodes in both modes together the command stops at once with r(484). A network of 20,000 nodes (13,333 + 6,667) takes 11 seconds and 3.4 GB; [nw2degree](nw2degree), [nw2clustering](nw2clustering), [nwmatching](nwmatching), [nwproject](nwproject) and [nw2project](nw2project) then take 1.7 to 12 seconds at that size.

## Also see

- [nwfromedge](nwfromedge) (whose own `twomode` option is an exact alias for this command), [nw2project](nw2project) ([nwproject](nwproject)), [nw2set](nw2set)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
