---
title: "nwdropnodes"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
| `nodes`(*`nodeid1...`*) | `numlist` of [nodeid's](nodeid) to be dropped |
| `nodes`(*[nodelab1...](nodeid)*) | List of [nodelab's](nodeid) to be dropped |
| `keepmat`(*matamatrix*) | Mata *nodes* x 1 matrix; 0 = drop, 1 = keep; a matrix of another size is an error |
| `attributes(varlist)` | Attribute variables that are included in the drop |
| `generate(newnetname)` | Generates a new network and does not overwrite the original network |
| `netonly` | Only drops the network, but keeps all Stata variables |
| `xvars` | Generate Stata variables for the network |

## Description

Drops nodes from a network. The nodes that are to be dropped can be either specifified by their [nodeid](nodeid) or by their [nodelab](nodeid) in option **nodes()**. Alternatively, one can also drop nodes based on a mata matrix.

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
Everything this command does can also be achieved with [nwdrop](nwdrop) using the **if** condition. For example, the following command also drops the first three nodes:

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwdrop flomarriage if _n <= 3
```
Note the opposite default polarity between the two interfaces: [nwdrop](nwdrop) leaves Stata dataset rows alone unless **clean** is specified, while `nwdropnodes` rebuilds the Stata dataset by default unless **netonly** is specified.

## Network types

**Directed:**, **Valued:**, **Signed:** the ties and their values among the remaining nodes are kept. **Two-mode:** yes - the flag, the modes of the remaining nodes and the level labels are kept; if all nodes of one mode are dropped the network stays two-mode with an empty level. **Temporal:** the events, times and intervals among the remaining nodes are kept (those of a dropped node are dropped with it). See [nwnetworktypes](nwnetworktypes).

## Limits

A network held as stored ties stays so: the ties between the remaining nodes are the new network. Measured in Stata/BE, random directed network with 10 ties per node: 5,000 nodes 0.6 seconds, 20,000 nodes 0.9 seconds and 0.3 GB. The node labels of the remaining network are passed on in Mata.

## See also

- [nwkeepnodes](nwkeepnodes), [nwdrop](nwdrop), [nwclear](nwclear), [nwkeep](nwkeep)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
