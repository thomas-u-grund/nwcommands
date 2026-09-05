---
title: "nwkeepnodes"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Keep nodes of a network"
---

# `nwkeepnodes`

Keep nodes of a network

## Syntax

```stata
nwkeepnodes
[netname],
nodes(nodeid1... or nodelab1...)
[
attributes(varlist)
generate(newnetname)
netonly
xvars]
nwkeepnodes
[netname],
keepmat(matamatrix)
[
attributes(varlist)
generate(newnetname)
netonly
xvars]
```

| | |
|---|---|
| `nodes`(*`nodeid1...`*) | `numlist` of [nodeid's](nodeid) to be kept |
| `nodes`(*[nodelab1...](nodeid)*) | List of [nodelab's](nodeid) to be kept |
| `keepmat`(*matamatrix*) | Mata *nodes* x 1 matrix; 0 = drop, 1 = keep |
| `attributes(varlist)` | Attribute variables that are included in the drop |
| `generate(newnetname)` | Generates a new network and does not overwrite the original network |
| `netonly` | Only update the network, but keep the Stata variables as they were |
| `xvars` | Generate Stata variables for the network |

## Description

Keeps nodes of a network. The nodes that are to be kept can be either specifified by their [nodeid](nodeid) or by their [nodelab](nodeid) in option **nodes()**. Alternatively, one can also keep nodes based on a mata matrix.

By default, the command overwrites the original network. This cannot be undone. Hence, it is recommended to specify option **generate()**, which generates a new network instead and keeps the original network as it was.

The command mirrors [nwdropnodes](nwdropnodes).

Keep the first seven nodes of network *flomarriage* and save it as network *flomarriage_reduced*:

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwkeepnodes flomarriage, nodes(1/7) generate(flomarriage_reduced)
```
Keep the nodes "medici" and "pucci":

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwkeepnodes flomarriage, nodes(medici pucci)
```
Alternatively, one can also keep nodes based on a mata matrix. This drops the first node:

```stata
. nwwebuse florentine, nwclear
```
```stata
. mata: k = (0\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1)
```
```stata
. nwkeepnodes flomarriage, keepmat(k)
```
Everything this command does can also be achieved with [nwkeep](nwkeep) using the **if** condition. For example, the following command also keeps the first seven nodes:

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwkeep flomarriage if _n <= 7
```
Note the opposite default polarity between the two interfaces: [nwkeep](nwkeep) leaves Stata dataset rows alone unless **clean** is specified, while `nwkeepnodes` rebuilds the Stata dataset by default unless **netonly** is specified.

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a purely structural operation, existing ties and their values are untouched for surviving nodes. Two-mode: mode assignments are preserved for surviving nodes.

## See also

- [nwdropnodes](nwdropnodes), [nwkeep](nwkeep), [nwdrop](nwdrop), [nwclear](nwclear)
