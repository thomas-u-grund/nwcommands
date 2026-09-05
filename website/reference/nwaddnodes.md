---
title: "nwaddnodes"
parent: "Command reference"
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
| `nodenames`(*n1, n2, ...*) | Node identifiers separated by comma |
| `mode(numlist)` | Two-mode (bipartite) networks only: the mode (1 or 2) each new node belongs to. Either a SINGLE value (applied to every new node) or one value per node listed in `nodenames()`, in the same order. Required when [netname](netname) is two-mode and omitted only for a one-mode network, where it would be meaningless |
| `generate`(*[newnetname](newnetname)*) | Save as new network |
| `xvars` | Generate Stata variables for the network |

## Description

Add isolate nodes to an existing networks. By default, [netname](netname) is replaced, unless **generate()** is specified.

An isolate node added this way has no ties to any existing node - this is the ONLY way to represent an isolate in a network that was built from an edgelist ([nwset](nwset), [nwfromedge](nwfromedge), [nw2fromedge](nw2fromedge)): an edgelist can only ever record nodes that appear in at least one tie, so a node with zero ties is never created from edgelist input alone, silently, with no error or note - see [nwset](nwset)'s and [nwfromedge](nwfromedge)'s own "Supported network types" sections. Call `nwaddnodes` afterward to add any isolates the source data itself could not represent.

## Examples

This example adds three new nodes (isolates) to a random network with 5 nodes.

```stata
. nwclear
. nwrandom 5, prob(.1)
. nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte)
```
This example adds two isolate nodes to a two-mode network - one to each mode (a mode-1 "person" with no memberships, and a mode-2 "institution" with no members):

```stata
. nw2fromedge person institution, name(mynet)
. nwaddnodes mynet, nodenames(New Person, New Institution) mode(1 2)
```
- last certified : 29 Aug 2026

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a purely structural operation, existing ties and their values are untouched. Two-mode: yes - `mode()` is REQUIRED on a two-mode network (no default is silently assumed) to say which of the two node sets each new isolate belongs to; omitting it on a two-mode network is an error, not a silent mode-1 default.
