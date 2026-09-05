---
title: "_nwnodeid"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Returns the nodeid of a node given its node label"
---

# `_nwnodeid`

Returns the nodeid of a node given its node label

## Syntax

```stata
_nwnodeid 
[netname],
nodelab(nodelab)
[detail]
```

| | |
|---|---|
| `nodelab`([nodelab](nodeid)) | nodelab of network node i |
| `detail` | displays the [nodeid](nodeid) and [nodelab](nodeid) of node i |

## Description

Returns the [nodeid](nodeid) of a node given its node label specified in *nodelab*. Results are stored in the return vector. When no node with the specified label is found in network *netname* and error is thrown. This command is mostly used for programming with networks.

## Examples

```stata
. nwwebuse florentine
. _nwnodeid flomarriage, nodelab(medici)
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

- [_nwnodelab](_nwnodelab), [nodeid](nodeid)
