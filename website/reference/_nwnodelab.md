---
title: "_nwnodelab"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
| `detail` | displays the [nodeid](nodeid) and [nodelab](nodeid) of node i |

## Description

Returns the [nodelab](nodeid) of a node given its [nodeid](nodeid). Results are also stored in the return vector. When *nodeid* is smaller than 1 or larger than the number of nodes in network *netname* an error is thrown. This command is mostly used for programming with networks.

## Examples

```stata
. nwwebuse florentine
. _nwnodelab flomarriage, nodeid(9) detail

        ----------------------------------------
          Network: flomarriage
        ----------------------------------------
            Nodeid: 9
            Nodelab: medici

. return list

scalars:
```
- **r(nodeid) =** --- 9

```stata
macros:
```
- **r(netname) : "flomarriage"**
- **r(nodelab) : "medici"**

## Stored results

- **Scalars**
- **r(nodeid)** --- nodeid of node

- **Macros**
- **r(netname)** --- name of the networks
- **r(nodelab)** --- node label of the node

## See also

- [_nwnodeid](_nwnodeid), [nodelab](nodeid), [nodeid](nodeid)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
