---
title: "nwaddnodes"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Add nodes to network"
---

# `nwaddnodes`

Add nodes to network

## Syntax

```stata
nwaddnodes
[netname],
nodenames(n1, n2, ...)
[mode(numlist)
generate(newnetname)
xvars]
```

| | |
|---|---|
| `nodenames`(*n1, n2, ...*) | Node identifiers separated by commas or spaces; a node identifier cannot contain a space |
| `mode(numlist)` | Two-mode (bipartite) networks only: the mode (1 or 2) each new node belongs to. Either a SINGLE value (applied to every new node) or one value per node listed in `nodenames()`, in the same order. Required when [netname](netname) is two-mode and omitted only for a one-mode network, where it would be meaningless |
| `generate`(*[newnetname](newnetname)*) | Save as new network |
| `xvars` | Generate Stata variables for the network |

## Description

Add isolate nodes to an existing networks. By default, [netname](netname) is replaced, unless **generate()** is specified.

An isolate node added this way has no ties to any existing node. A network built from an edgelist ([nwset](nwset), [nwfromedge](nwfromedge), [nw2fromedge](nw2fromedge)) only has the nodes that appear in the edgelist (an isolate needs a row of its own with the other identifier missing, see [nwfromedge](nwfromedge)). Call `nwaddnodes` afterward to add any isolates the source data itself did not hold.

## Examples

This example adds three new nodes (isolates) to a random network with 5 nodes.

```stata
. nwclear
. nwrandom 5, prob(.1)
. nwaddnodes, nodenames(Thomas, Peter, Mathilde)
```
This example adds two isolate nodes to a two-mode network - one to each mode (a mode-1 "person" with no memberships, and a mode-2 "institution" with no members):

```stata
. nw2fromedge person institution, name(mynet)
. nwaddnodes mynet, nodenames(NewPerson, NewInstitution) mode(1 2)
```

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
