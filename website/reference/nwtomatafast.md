---
title: "nwtomatafast"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Return link to adjacency matrix of network"
---

# `nwtomatafast`

Return link to adjacency matrix of network

## Syntax

```stata
nwtomatafast
[netname]
```

## Description

Internally, networks are saved as adjacency matrices in Mata. This command returns the name of the Mata matrix where a network is stored in the return vector. It differs from [nwtomata](nwtomata) in the following way. It only returns a link to the adjacency matrix and does not produce a copy of the adjacency matrix.

- This can be useful, when you want to directly interact with the underlying adjacency matrix. But I only recommend this for advanced programmers.
- Caution is advised because the relevant meta-information is not updated when changing the adjacency matrix of a network.

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - returns a live pointer to the network's own internal matrix (not a copy), independent of any of these properties; changes made through it directly alter the network.

## See also

- [nwtomata](nwtomata), [nwload](nwload), [nwsummarize](nwsummarize)
