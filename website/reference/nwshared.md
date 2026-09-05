---
title: "nwshared"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate number of shared neighbors between nodes and saves information in network"
---

# `nwshared`

Calculate number of shared neighbors between nodes and saves information in network

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
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway (alias: `nwreplace`, kept for backward compatibility - most sibling generators in this package instead spell this `replace`) |

## Description

This command calculates for each connected pair of nodes (i,j) the number of nodes k that both i and j have as shared neighbors.

## Supported network types

Binary: yes (only) - shared-tie/exposure counting is a structural property, tie values are ignored (via [nwsym](nwsym)'s own binarizing `generate()` path). Directed: requires `undirected` to symmetrize first, else an explicit error. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## See also

- [nwsimmelian](nwsimmelian)

- last certified : 24 Aug 2026
