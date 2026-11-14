---
title: "nwtranspose"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
| `generate`(*[newnetname](newnetname)*) | Save transpose as new network (alias: `name()`, matching the rest of this group) |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway |

## Description

Simply transposes a network, i.e. a directed tie from node *i* to node *j* is transformed in a directed tie from node *j* to node *i*. By default, `nwtranspose` replaces a network, but you can specify that it should create a new network instead with **generate()**.

## Network types

**Directed:** the command transposes the matrix (no change for an undirected network). **Valued:** the tie values are transposed with the ties. **Two-mode:** yes - the flag, the modes and the level labels are kept (the matrix of a two-mode network is symmetric). **Signed:** values are kept as they are. See [nwnetworktypes](nwnetworktypes).

## Limits

A network held as stored ties is transposed tie by tie. Measured in Stata/BE on a random directed network with 10 ties per node: 20,000 nodes 0.2 seconds.

## Examples

```stata
. nwclear
. nwrandom 5, prob(.3) name(net)
. nwsummarize net, matonly

     1   2   3   4   5
  +---------------------+
1 |  0   0   1   0   0  |
2 |  1   0   0   0   0  |
3 |  0   0   0   1   0  |
4 |  1   1   0   0   1  |
5 |  0   0   1   0   0  |
  +---------------------+

. nwtranspose net, generate(net_transp)
. nwsummarize net_transp, matonly

     1   2   3   4   5
  +---------------------+
1 |  0   1   0   1   0  |
2 |  0   0   0   1   0  |
3 |  1   0   0   0   1  |
4 |  0   0   1   0   0  |
5 |  0   0   0   1   0  |
  +---------------------+
```

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
