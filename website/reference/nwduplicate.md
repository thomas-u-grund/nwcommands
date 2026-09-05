---
title: "nwduplicate"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Duplicate a network"
---

# `nwduplicate`

Duplicate a network

## Syntax

```stata
nwduplicate
[netname]
[,
name(newnetname)
replace]
```

| | |
|---|---|
| `name`(*[newnetname](newnetname)*) | name of the new network |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway (see [nwset](nwset) for the same convention) |

## Description

`nwduplicate` simply duplicates an existing network *netname*. By default, the duplicated network is called *netname_copy*. It also duplicates the node labels of the original network.

For example:

- **. nwwebuse florentine, nwclear**
- **. nwduplicate flomarriage**
- **. nwname flomarriage_copy**
- **. return list**

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a full, generic copy of the network object (adjacency matrix, node labels, directed/valued/two-mode status, and mode assignments), independent of any of these properties.

## See also

- [nwgenerate](nwgenerate), [nwsubset](nwsubset)

- last certified : 24 Aug 2026
