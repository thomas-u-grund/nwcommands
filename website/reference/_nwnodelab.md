---
title: "_nwnodelab"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Returns the nodelab of a node given its nodeid"
---

# `_nwnodelab`

Returns the nodelab of a node given its nodeid

## Syntax

```stata
_nwnodelab 
[netname],
nodeid(int)
[detail]
```

| | |
|---|---|
| `nodeid(nodeid)` | nodeid of network node i |
| `detail` | displays the [nodeid](nodeid.md) and [nodelab](nodeid.md) of node i |

## Description

Returns the [nodelab](nodeid.md) of a node given its [nodeid](nodeid.md). Results are also stored in the return vector. When no node with the specified id is found in network *netname* and error is thrown. This command is mostly used for programming with networks.

## Examples

```stata
. nwwebuse florentine
. _nwnodelab flomarriage, nodeid(9)
```
- Network: flomarriage
- hline 15
- Nodeid: 9
- Nodelab: medici

- . return list

- scalars:
- r(nodeid) = 9

- macros:
- r(netname) : "flomarriage"
- r(nodelab) : "medici"

## Stored results

**Scalars**

- **r(nodeid)** nodeid of node

- Macros:
- **r(netname)** name of the networks
- **r(nodelab)** node label of the node

## See also

- [_nwnodeid](_nwnodeid.md), [nodelab](nodeid.md), [nodeid](nodeid.md)
