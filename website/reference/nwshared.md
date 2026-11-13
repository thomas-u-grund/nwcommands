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

## Network types

**Directed:** needs `undirected` (symmetrizes first); without it the command stops with an error. **Valued:** tie values are ignored (the command prints a note on a valued network). **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Limits

The two-step paths i -> k -> j are listed from the stored ties (the sum over k of in-degree times out-degree) and counted on the ties; no matrix is built. 20,000 nodes 1.7 seconds in Stata/BE, random directed network with 10 ties per node.

## Example

```stata
. nwwebuse florentine, nwclear
. nwshared flomarriage, name(shared)
. nwplot flomarriage, edgecolor(shared) edgesize(shared) edgefactor(3)
```

## See also

- [nwsimmelian](nwsimmelian)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
