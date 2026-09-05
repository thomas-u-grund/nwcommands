---
title: "nwdropnodes"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Drop nodes from a network"
---

# `nwdropnodes`

Drop nodes from a network

## Syntax

```stata
nwdropnodes
[netname],
[
nodes(nodeid1... or nodelab1...)
keepmat(matamatrix)
attributes(varlist)
generate(newnetname)
netonly
xvars]
```

| | |
|---|---|
| `nodes`(*`nodeid1...`*) | `numlist` of [nodeid's](nodeid.md) to be dropped |
| `nodes`(*[nodelab1...](nodeid.md)*) | List of [nodelab's](nodeid.md) to be dropped |
| `keepmat`(*matamatrix*) | Mata *nodes* x 1 matrix; 0 = drop, 1 = keep |
| `attributes(varlist)` | Attribute variables that are included in the drop |
| `generate(newnetname)` | Generates a new network and does not overwrite the original network |
| `netonly` | Only drops the network, but keeps all Stata variables |
| `xvars` | Generate Stata variables for the network |

## Description

Drops nodes from a network. The nodes that are to be dropped can be either specifified by their [nodeid](nodeid.md) or by their [nodelab](nodeid.md) in option **nodes()**. Alternatively, one can also drop nodes based on a mata matrix.

By default, the command overwrites the original network. This cannot be undone. Hence, it is recommended to specify option **generate()**, which generates a new network instead and keeps the original network as it was.

Drop the first three nodes of network *flomarriage* and save it as network *flomarriage_reduced*:

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwdropnodes flomarriage, nodes(1/3) generate(flomarriage_reduced)
```
Drop the nodes "medici" and "pucci":

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwdropnodes flomarriage, nodes(medici pucci)
```
Alternatively, one can also drop nodes based on a mata matrix. This drops the first node:

```stata
. nwwebuse florentine, nwclear
```
```stata
. mata: k = (0\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1)
```
```stata
. nwdropnodes flomarriage, keepmat(k)
```
Everything this command does can also be achieved with [nwdrop](nwdrop.md) using the **if** condition. For example, the following command also drops the first three nodes:

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwdrop flomarriage if _n <= 3
```
Note the opposite default polarity between the two interfaces: [nwdrop](nwdrop.md) leaves Stata dataset rows alone unless **clean** is specified, while `nwdropnodes` rebuilds the Stata dataset by default unless **netonly** is specified.

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a purely structural operation, existing ties and their values are untouched for surviving nodes. Two-mode: mode assignments are preserved for surviving nodes.

## See also

- [nwkeepnodes](nwkeepnodes.md), [nwdrop](nwdrop.md), [nwclear](nwclear.md), [nwkeep](nwkeep.md)
