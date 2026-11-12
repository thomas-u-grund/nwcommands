---
title: "nwtomata"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Return the adjacency matrix of a network"
---

# `nwtomata`

Return the adjacency matrix of a network

## Syntax

```stata
nwtomata
[netname] 
, 
mat(matamatrix)
```

| | |
|---|---|
| `mat(matamatrix)` | name of the new Mata matrix |

## Description

This creates a Mata matrix with name *matamatrix* holding a copy of the adjacency matrix of a network.

You do not need to know Mata to use any of the nwcommands, but sometimes you might want to obtain the adjacency matrix, for example, when programming your own network commands.

When you make alterations to a Mata matrix derived from **nwtomata** you do not change the underlying network. It simply gives you a copy of the underlying matrix used to store the network. To make changes to this network use  [nwreplace](nwreplace) or [nwreplacemat](nwreplacemat).

The adjacency matrix of a network can also be displayed with:

```stata
. nwsummarize, mat
```
Advanced programmers who might want to directly interact with the adjacency matrix of a network and not with a copy of it, see [advanced network programming](nwprogramming).

## Stored results

- **Macros**
- **r(netname)** --- name of the network
- **r(adj_copy)** --- name of the new Mata matrix
- **r(adj)** --- Mata expression for the network's own matrix (see [nwtomatafast](nwtomatafast))
- **r(netobj)** --- name of the Mata network object

## See also

- [nwtomatafast](nwtomatafast), [nwload](nwload), [nwsummarize](nwsummarize)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
