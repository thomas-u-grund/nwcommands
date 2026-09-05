---
title: "nwtomata"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Return adjacency matrix of network"
---

# `nwtomata`

Return adjacency matrix of network

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

This creates a Mata matrix with name *matatamatrix* holding a copy of the adjacency matrix of a network.

You do not need to know Mata to use any of the nwcommands, but sometimes you might want to obtain the adjacency matrix, for example, when programming your own network commands.

When you make alterations to a Mata matrix derived from **nwtomata** you do not change the underlying network. It simply gives you a copy of the underlying matrix used to store the network. To make changes to this network use  [nwreplace](nwreplace) or [nwreplacemat](nwreplacemat).

The adjacency matrix of a network can also be displayed with:

```stata
. nwsummarize, mat
```
Advanced programmers who might want to directly interact with the adjacency matrix of a network and not with a copy of it, see [advanced network programming](nwprogramming).

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - returns a plain copy of the raw adjacency matrix exactly as stored, independent of any of these properties.

## See also

- [nwtomatafast](nwtomatafast), [nwload](nwload), [nwsummarize](nwsummarize)
