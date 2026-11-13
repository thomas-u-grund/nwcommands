---
title: "nodeid"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Identification of nodes"
---

# `nodeid`

Identification of nodes

## nodeid

A [nodeid](_nwnodeid) is an integer number used to identify nodes in a network. Every node in a network is automatically assigned a *nodeid*. The range of these numbers goes from 1 to *size of the network*, where every integer number identifies exactly one node. When a node is deleted, the *nodeid*'s of all other nodes are automatically changed, so that all consecutive numbers from 1 to *size of the network* correspond to one node. When attributes (saved as Stata variables) are used, the variable value of row *i* corresponds to the attribute of the node with *nodeid i*. Nodeid's cannot be changed by the user other than when nodes are deleted.

## nodelab

A [nodelab](_nwnodelab) is more flexibile than a *nodeid* and attaches a unique `word` to each node for identification. Node labels can be changed with [nwname, newlabsfromvar(varname)](nwname). Node labels uniquely identify nodes in a network.

## Finding the nodeid and nodelab

Both nodeid and nodelab of nodes can be found out easily. The most simple way is probably to use [nwload](nwload). This generates the variable *_nwnode*, which holds the node labels in the order of the nodeids.

If one wants to know the nodelab that corresponds to a nodeid one can use [_nwnodelab](_nwnodelab). The other way around, when one knows a nodelab and wants to know the nodeid of a node, one can use [_nwnodeid](_nwnodeid).

- For example,

```stata
. _nwnodelab, nodeid(9) detail

----------------------------------------
  Network: flomarriage
----------------------------------------
    Nodeid: 9
    Nodelab: medici
```

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
