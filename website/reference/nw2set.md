---
title: "nw2set"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Declare data to be two-mode network data"
---

# `nw2set`

Declare data to be two-mode network data

## Syntax

```stata
Declare data to be two-mode network data
nw2set varlist [, options ]
nw2set
,
mat(matamatrix)
[ options ]
```

| | |
|---|---|
| `edgelist` | declare data in edgelist format |
| `name`(*[newnetname](newnetname.md)*) | name of the new network; default = *network* |
| `labs`(*lab1 lab2...*) | new node labels that are used for the network |
| `rownames(varname)` | names of nodes on level 2 |
| `xvars` | generate Stata variables for the network |
| `vars(namelist)` | Stata variable names to store the network as (one per node, level 1 then level 2); default = auto-generated |
| `clear` | drop all existing networks (but not the Stata dataset) before declaring this one |
| `nwclear` | same as `clear` |

## Description

This command declares data to be two-mode network data. A two-mode network consists of two sets of units (e. g. people and events) and relations connect the two sets, e. g. participation of people in social events. Some examples are:

- Membership in institutions - people, institutions, is a member, e.g. directors and commissioners on the boards of corporations.

- Voting for suggestions - polititians, suggestions, votes for.

- Citation network, where first set consists of authors, the second set consists of articles/papers, connection is a relation author cites a paper.

- Co-autorship networks - authors, papers, is a (co)author.

A corresponding graph is called bipartite graph – lines connect only vertices from one to vertices from another set – inside sets there are no connections.

Setting two-mode networks is very similar to setting normal networks with [nwset](nwset.md). With M nodes on level 1 and N nodes on level 2, the command internally generates a (M+N) x (M+N) matrix, which stores the network data. Furthermore, it generates a variable *_mode*, which has the value 1 for nodes on level 1 (e.g. persons: Peter, Tim, Thomas, Michael, Mathilde) and value 2 for nodes on level 2 (e.g institutions: LiU, UCD, Oxford, ETH).

When a network is set as two-mode, this meta-information is stored with the network. Other nwcommands automatically recognize that the network is two-mode and deal with it accordingly (e.g. [nwplot](nwplot.md)).

There are three ways to explicitly declare data to be two-mode network data:

**ul:1. Declare adjacency matrix from variables**

Declare the variables in `varlist` to represent the adjacency matrix of the two-mode network. In this case a `varlist` (var_1, var_2,..., var_z) needs to be given. Each variable stands for a node on level 1 (e.g. organisations). Each row in the dataset stands for a node on level 2 (e.g. persons).

In this dummy example we create 5 observations and 3 new variables v1-v3. After that we set a two-mode network from this data. This creates an empty network with 5 nodes on level 1 and 3 nodes on level 2.

```stata
. nwclear
. set obs 5
. forvalues i = 1/3{
gen v = 0
}
. nw2set v*
```
By default, the nodes on level 1 are named after the variables v1, v2 and v3. If option **rownames(varname)** is specified, the nodes on level 2 are named afther the values found in variable **varname**.

**ul:2. Declare edgelist from variables**

In this case, the command interprets the variables `varlist` as egdelist (see [nw2fromedge](nw2fromedge.md)).

An edgelist or arclist is a set of two (or three in the case of a valued network) variables representing relations. Nodes are identified by entries in the cells.  For example, imagine the following kind of data:

- hline 18c -
- c | fromid toid c |
- hline 18c -
- 1. c | Peter LiU c |
- 2. c | Andreas UCD c |
- 3. c | Thomas UCD c |
- hline 18c -

We can declare this data as a two-mode network like this:

```stata
. nw2set fromid toid, egdelist
```
This commands generates a network with 5 nodes in total; 3 nodes on level 1 (Peter, Andreas, Thomas) and 2 nodes on level 2 (LiU, UCD).

**ul:2. Declare adjacency matrix from Mata matrix**

Set a network from a *M x N* Mata matrix that holds the adjacency matrix of the new network with N nodes on level 1 and M nodes on level 2. The option **mat()** is specified with the name of an existing Mata matrix.

For example, this generates a Mata matrix and sets a two-mode network with 6 nodes (4 nodes in level 1 and 2 nodes on level 2):

```stata
. nwclear
. mata: net = (0,1\1,0\1,1\1,1)
. nw2set, mat(net) name(network)
```

## Remarks

By default, two-mode networks are undirected.

By default, network generators (including `nw2set` itself) only produce a network object - they do NOT load a network as Stata variables (see [nwload](nwload.md)). Many network generators allow the option **xvars**, which ADDITIONALLY loads the new network as Stata variables right away (equivalent to following the generator with a separate [nwload](nwload.md) call). Leaving **xvars** unspecified keeps Stata's own variable budget free when one deals with many or large networks - all commands that require a [netname](netname.md) still work even when no Stata variables for that network exist at all, or after ** drop _all**. This also means that one can still deal with larger networks even when using **Small Stata**.

Each node in a network also has a node label. This is a unique name for each node. This meta-information can be set with option **labs()**. As before, there need to be as many entries as there are nodes in the network. When not specified, the program automatically labels nodes according the variables that have been set.

Whenever a network is set with **nw2set**, it is also made the [current network](nwcurrent.md). The current network is always the network that has been most recently loaded or generated. Many nwcommands allow that a [netname](netname.md) or a [netlist](netlist.md) is optional. In case no network is given, all nwcommands generally refer to the current network.

Programmers can use **nw2set** to write their own import routines  (see also [nwimport](nwimport.md)) for different network file formats that are not natively supported by the nwcommands. All you need to do is transform your data either in an adjacency list or an edgelist represented by Stata variables.

From a two-mode network one can also produce a one-mode projection (see [nw2project](nw2project.md)). This basically, collapses the network to use only nodes from either level 1 or level 2.

## Supported network types

Two-mode: **T1**, native - this command's entire purpose is declaring a two-mode (bipartite) network from a rectangular incidence matrix or a variable list. Binary: yes. Directed: not applicable - two-mode ties are inherently undirected affiliations. Weighted: yes, tie values are accepted and stored as-is. Signed: not checked.

## See also

- [nwset](nwset.md) (whose own `twomode`/`bipartite` options can also declare a two-mode network directly), [nw2fromedge](nw2fromedge.md), [nwload](nwload.md), [nw2project](nw2project.md) ([nwproject](nwproject.md))

- last certified : 28 Aug 2026
