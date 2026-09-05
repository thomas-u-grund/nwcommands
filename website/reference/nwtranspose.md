---
title: "nwtranspose"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Transpose a network"
---

# `nwtranspose`

Transpose a network

## Syntax

```stata
nwtranspose 
[netname]
[,
generate(newnetname)
name(newnetname)
replace]
```

| | |
|---|---|
| `generate`(*[newnetname](newnetname.md)*) | Save transpose as new network (alias: `name()`, matching the rest of this group) |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway |

## Description

Simply transposes a network, i.e. a directed tie from node *i* to node *j* is transformed in a directed tie from node *j* to node *i*. By default, `nwtranspose` replaces a network, but you can specify that it should create a new network instead with **generate()**.

## Examples

- . nwclear
- . nwrandom 5, prob(.3) name(net)
- . nwsummarize net, matonly

- 1 2 3 4 5
- hline 21
- 1 c | 0 0 1 0 0 c |
- 2 c | 1 0 0 0 0 c |
- 3 c | 0 0 0 1 0 c |
- 4 c | 1 1 0 0 1 c |
- 5 c | 0 0 1 0 0 c |
- hline 21

- . nwtranspose net, generate(net_transp)
- . nwsummarize net_transp, matonly

- 1 2 3 4 5
- hline 21
- 1 c | 0 1 0 1 0 c |
- 2 c | 0 0 0 1 0 c |
- 3 c | 1 0 0 0 1 c |
- 4 c | 0 0 1 0 0 c |
- 5 c | 0 0 0 1 0 c |
- hline 21

- last certified : 24 Aug 2026

## Supported network types

Binary: yes. Directed: yes - this command's entire purpose is transposing a network's adjacency matrix (a no-op for a genuinely symmetric undirected network). Weighted: yes, tie values are transposed along with tie presence. Signed: yes, values (including negative) are preserved as-is. Two-mode: not applicable - transposing a bipartite incidence structure would swap its two modes, which is exactly what [nw2project](nw2project.md) and the [nw2toedge](nw2toedge.md)/[nw2fromedge](nw2fromedge.md) family are for instead.
