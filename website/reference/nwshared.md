---
title: "nwshared"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Number of shared neighbors of all pairs of nodes, as a network"
---

# `nwshared`

Number of shared neighbors of all pairs of nodes, as a network

## Syntax

```stata
nwshared 
[netname]
[,
name(newnetname)
undirected
replace]
```

| | |
|---|---|
| `name(newnetname)` | Save as new network; default *_shared* |
| `undirected` | Treat all ties as undirected for calculation |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway (alias: `nwreplace`) |

## Description

This command calculates for each connected pair of nodes (i,j) the number of nodes k that both i and j have as shared neighbors.

## See also

- [nwsimmelian](nwsimmelian)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
