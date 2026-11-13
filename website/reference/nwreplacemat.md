---
title: "nwreplacemat"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Replace network with Stata or Mata matrix"
---

# `nwreplacemat`

Replace network with Stata or Mata matrix

## Syntax

```stata
nwreplacemat 
[netname]
,
newmat(matname)
[nosync
netonly
xvars
labs(lab1 lab2 ...)]
```

| | |
|---|---|
| `newmat`(*matname*) | name of a Stata or Mata matrix |
| `nosync` | do not sync Stata variables; by default Stata variables are synced (see [nwsync](nwsync)) |
| `netonly` | only update the network, do not touch the Stata dataset at all |
| `xvars` | also load the updated network as Stata variables (see [nwload](nwload)) |
| `labs`(*lab1 lab2 ...*) | new node labels to use when *matname* requires resizing the network; default = **1**, **2**, ... |
| `vars`(*string*) | accepted for compatibility; has no effect (use `labs()` for the node labels) |

## Description

`nwreplacemat` changes a network by replacing the adjacency matrix of the network with an existing Mata matrix.

The command checks if the Stata/Mata matrix *matname* has the correct dimensions.

By default, the command also checks if the new adjacency matrix is symmetric and if yes, it alters the meta-information of the network (directed => undirected). In case, one still wants to assign a perfectly symmetric matrix to a directed network, one can use:

`nwname` [*[netname](netname)*]`, directed(true)`

to overwrite the automatic setting afterwards.

## Examples

This example generates a ring lattice first (*mynet*), but then replaces the adjacency matrix of this network with a new Mata matrix **J(5,5,99)**.

```stata
. nwring 5, k(1) name(mynet)
. mata: net = J(5,5,99)
. nwreplacemat mynet, newmat(net)
. nwsummarize mynet, matonly

     1   2   3   4   5
  +-------------------------+
1 |  0                      |
2 |  99   0                 |
3 |  99   99   0            |
4 |  99   99   99   0       |
5 |  99   99   99   99   0  |
  +-------------------------+
```

## Stored results

- **Scalars**
- **r(directed)** --- 1 if the new matrix is not symmetric (the network is then directed), 0 if it is symmetric (the network is then set to undirected)

## See also

- [nwreplace](nwreplace)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
