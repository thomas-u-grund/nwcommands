---
title: "nwkeep"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Keep a network (or only certain nodes)"
---

# `nwkeep`

Keep a network (or only certain nodes)

## Syntax

```stata
nwkeep 
[netlist]
nwkeep 
[netname]
ifin
[,
clean]
```

| | |
|---|---|
| `clean` | Drop node observations |

## Description

Keeps a network or a list of networks. The command is the network version of `keep` and mirrors [nwdrop](nwdrop).

It can also be used together with `if` or `in`. In this case, the command operates on the node-level and keeps only certain nodes of a network.

## Examples

Load two networks and keep only one of them by name:

```stata
. nwclear
. nwrandom 5, prob(.4) name(net1)
. nwrandom 5, prob(.4) name(net2)
. nwkeep net2
. nwset
```
Keep only certain nodes of a network, using `if`:

```stata
. nwclear
. nwrandom 6, prob(.4) name(net3)
. nwkeep net3 if _n <= 3
. nwsummarize net3
```
