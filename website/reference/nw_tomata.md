---
title: "nw_tomata"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Return adjacency matrix of network"
---

# `nw_tomata`

Return adjacency matrix of network

## Syntax

```stata
nw_tomata
[netname] 
, 
[mat(matamatrix)]
```

| | |
|---|---|
| `mat(matamatrix)` | name of the new Mata matrix |

## Description

This command allows interaction with the underlying adjacency matrix in Mata  of a network. You do not need to know Mata to use any of the nwcommands, but sometimes you might want to obtain the adjacency matrix, for example, when programming your own network commands.

`nw_tomata` returns a link to the [Mata network object](nw_programming.md) and saves it in **r(netobj)**. Furthermore, it returns a direct link to the underlying Mata adjacency matrix of the network object and saves it in **r(adj)**.

Keep in mind that when you make alterations to **r(adj)** in Mata you change a network. This should only be done by advanced programmers.

When the option `mat()` is specified, the command obtains a copy of the adjacency matrix and saves it as a new Mata matrix *matamatrix*. When you make alterations to this *matamtrix* you do not change the network.

## See also

- [Programming own network commands](nw_programming.md)

- last certified : 21 Aug 2026
