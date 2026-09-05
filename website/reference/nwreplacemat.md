---
title: "nwreplacemat"
parent: "Command reference"
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
vars(newvarlist)
labs(lab1 lab2 ...)]
```

| | |
|---|---|
| `newmat`(*matname*) | name of a Stata or Mata matrix |
| `nosync` | do not sync Stata variables; by default Stata variables are synced (see [nwsync](nwsync)) |
| `netonly` | only update the network, do not touch the Stata dataset at all |
| `xvars` | also load the updated network as Stata variables (see [nwload](nwload)) |
| `vars`(*`newvarlist`*) | Stata variable names to use when *matname* requires resizing the network; default = auto-generated |
| `labs`(*lab1 lab2 ...*) | new node labels to use when *matname* requires resizing the network; default = **1**, **2**, ... |

## Description

`nwreplacemat` changes a network by replacing the adjacency matrix of the network with an existing Mata matrix.

The command checks if the Stata/Mata matrix *matname* has the correct dimensions.

By default, the command also checks if the new adjacency matrix is symmetric and if yes, it alters the meta-information of the network (directed => undirected). In case, one still wants to assign a perfectly symmetric matrix to a directed network, one can use:

`nwname` [*[netname](netname)*]`, directed(true)`

to overwrite the automatic setting afterwards.

## Examples

This example generates a ring lattice first (*mynet*), but then replaces the adjacency matrix of this network with a new Mata matrix **J(5,5,99)**.

- . nwring 5, k(1), name(mynet)
- . mata: net = J(5,5,99)
- . nwreplacemat mynet, newmat(net)
- . nwsummarize mynet, matonly

- 1 2 3 4 5
- hline 25
- 1 c | 0 c |
- 2 c | 99 0 c |
- 3 c | 99 99 0 c |
- 4 c | 99 99 99 0 c |
- 5 c | 99 99 99 99 0 c |
- hline 25

## Supported network types

Binary: yes. Directed: yes - this command's entire purpose is writing an arbitrary matrix in as the network's own adjacency matrix, whatever directed/symmetric shape it has. Weighted: yes, natively. Signed: yes, any value including negative can be written in. Two-mode: not checked.

## See also

- [nwreplace](nwreplace)
