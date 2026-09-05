---
title: "nwnode"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Checks if node exists in a network"
---

# `nwnode`

Checks if node exists in a network

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

## Examples

```stata
. nwwebuse florentine
. nwnode flobusiness, ego(medici)
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - a pure node-existence/lookup check; does not read tie values or depend on directed/valued/two-mode status.

## See also

- [nwvalue](nwvalue.md)
- last certified : 24 Aug 2026
