---
title: "nwtomatafast"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Return a link to the adjacency matrix of a network"
---

# `nwtomatafast`

Return a link to the adjacency matrix of a network

## Syntax

```stata
nwtomatafast
[netname]
```

## Description

Internally, networks are saved as adjacency matrices in Mata. This command returns the name of the Mata matrix where a network is stored in the return vector. It differs from [nwtomata](nwtomata) in the following way. It only returns a link to the adjacency matrix and does not produce a copy of the adjacency matrix.

This can be useful, when you want to directly interact with the underlying adjacency matrix. But I only recommend this for advanced programmers. Caution is advised because the relevant meta-information is not updated when changing the adjacency matrix of a network.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Example

```stata
. nwrandom 5, density(.2) name(net)
. nwtomatafast net
. return list
```

## Stored results

- **Macros**
- **r(mata)** --- Mata expression that refers to the network's own adjacency matrix

## See also

- [nwtomata](nwtomata), [nwload](nwload), [nwsummarize](nwsummarize)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
