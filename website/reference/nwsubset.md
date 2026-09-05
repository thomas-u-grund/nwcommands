---
title: "nwsubset"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Subset the nodes of a network"
---

# `nwsubset`

Subset the nodes of a network

## Syntax

```stata
nwsubset 
[netname]
[if]
[,
name(newnetname)
replace]
```

| | |
|---|---|
| `name`(*[newnetname](newnetname.md)*) | name of the new network |
| `replace` | replace existing network |

## Description

`nwsubset` simply subsets an existing network *netname*. By default, the subset network is called *netname_sub*. It consists of all the nodes of the original network *netname* for which the **if** condition is true. When no `if` condition is specified, the command simply generates a duplicate.

For example, this generates a new network from the **flomarriage** network that consists of only the nodes with **wealth > 50**.

- **. nwwebuse florentine, nwclear**
- **. nwsubset flomarriage if wealth > 50**

By default, this generates a new network called *flomarriage_sub*. Notice that something similar could be achieved with [nwgen](nwgen.md):

- **. nwgen flo_sub = flomarriage if wealth > 50**

However, the last command does not copy the node labels of network *flomarriage*. This is because the `if` condition in [nwgen](nwgen.md) applies to a whole [network expression](netexp.md). Because network expressions can be very complicated, no labels are copied.

## Supported network types

Binary: yes. Directed: yes. Weighted: yes, tie values are preserved in the extracted subset. Signed: yes, values including negative are preserved. Two-mode: not checked.

## See also

- [nwgenerate](nwgenerate.md), [nwduplicate](nwduplicate.md)
