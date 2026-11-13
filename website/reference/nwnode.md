---
title: "nwnode"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Check whether a node exists in a network"
---

# `nwnode`

Check whether a node exists in a network

## Syntax

```stata
nwnode
[netname],
[ego(nodename)
egoid(nodeid)]
```

| | |
|---|---|
| `ego`(*nodename*) | Look up the node by name |
| `egoid`(*nodeid*) | Look up the node by id |

## Description

The command checks if node *nodename* exists in network *netname* and returns its *nodeid*. In case it does not exist, it returns -1. Either `ego()` or `egoid()` needs to be specified; if both are given, `egoid()` takes precedence and `ego()` is silently ignored.

## Stored values

- **`r(nodeid)`** --- nodeid of the node; -1 if it does not exist
- **`r(nodename)`** --- name of the node

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Examples

```stata
. nwwebuse florentine
. nwnode flobusiness, ego(medici)
```

## See also

- [nwvalue](nwvalue)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
