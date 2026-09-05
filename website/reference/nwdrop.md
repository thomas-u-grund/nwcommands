---
title: "nwdrop"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Drop networks or network nodes"
---

# `nwdrop`

Drop networks or network nodes

## Syntax

```stata
nwdrop 
[netlist]
nwdrop 
[netname]
ifin
[,
clean]
```

| | |
|---|---|
| `clean` | Drop node observations |

## Description

Drops a network or a list of networks. The command is the network version of `drop` and mirrors [nwkeep](nwkeep).

It can also be used with `if` or `in`. Then it only drops certain nodes from a network. This updates the Stata variable **_nwinclude**, which indicates if a node is included in a network.

## Examples

Load two networks and drop one of them by name:

```stata
. nwclear
. nwrandom 5, prob(.4) name(net1)
. nwrandom 5, prob(.4) name(net2)
. nwdrop net1
. nwset
```
Drop only certain nodes from a network, using `if`:

```stata
. nwclear
. nwrandom 6, prob(.4) name(net3)
. nwdrop net3 if _n > 3
. nwsummarize net3
```
