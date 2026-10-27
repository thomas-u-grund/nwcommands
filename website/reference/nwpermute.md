---
title: "nwpermute"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate permutation of a network"
---

# `nwpermute`

Generate permutation of a network

## Syntax

```stata
nwpermute 
[netname]
[,
generate(newnetname)
replace
nwreplace
xvars]
```

| | |
|---|---|
| `generate(newnetname)` | Save permutation as new network |
| `replace` | Replace existing network with permutation |
| `nwreplace` | Overwrite the network named in `generate()` if it already exists; without it the command stops with an error |
| `xvars` | Generate Stata variables for the network |
| `swap` | Two-mode network: exchange the partners of two ties at random (Maslov and Sneppen); keeps both degree sequences and the tie values; without it the labels are permuted within the modes |
| `swaps(#)` | Two-mode network: the number of attempted exchanges with `swap`; default = ten times the number of ties |

## Description

Produces a random permutation of the network [netname](netname). In such a permutation, the nodes are randomly reshuffled, while the overall structure of the network remains the same. Either option **replace** or **generate** needs to be specfied.

A simple example illustrates what the command does. First, we generate a regular lattice network.

```stata
. nwclear
. nwlattice 3 3
. nwsummarize lattice, matonly

     1   2   3   4   5   6   7   8   9
  +-------------------------------------+
1 |  0                                  |
2 |  1   0                              |
3 |  0   1   0                          |
4 |  1   0   0   0                      |
5 |  0   1   0   1   0                  |
6 |  0   0   1   0   1   0              |
7 |  0   0   0   1   0   0   0          |
8 |  0   0   0   0   1   0   1   0      |
9 |  0   0   0   0   0   1   0   1   0  |
  +-------------------------------------+
```
Now, let us permute the network *lattice*.

```stata
. nwpermute lattice, replace
. nwsummarize lattice, matonly

     1   2   3   4   5   6   7   8   9
  +-------------------------------------+
1 |  0                                  |
2 |  1   0                              |
3 |  0   0   0                          |
4 |  0   0   1   0                      |
5 |  1   0   0   0   0                  |
6 |  0   1   0   1   0   0              |
7 |  0   0   0   0   1   0   0          |
8 |  0   0   1   0   0   0   1   0      |
9 |  0   1   0   1   1   0   0   1   0  |
  +-------------------------------------+
```
The structure of the network remains exactly the same, however, the nodes have a different order. Often, such a permutation is desired to recalculate network statistics (and derive standard errors and confidence intervals for these statistics) while keeping the overall structure of the network constant (see more [nwqap](nwqap), [nwcorrelate](nwcorrelate)).

## Supported network types

Binary: yes. Directed: yes. Weighted: yes - tie values move with their ties under the random relabeling (a pure permutation of the existing adjacency matrix). Signed: yes, values including negative are preserved. Two-mode: yes - the labels are permuted within the modes, so that no tie ever joins two nodes of the same mode (`tnet::rg_reshuffling_tm`); `swap` exchanges the partners of two ties at random and keeps both degree sequences (`bipartite::swap.web`).

## See also

- [nwqap](nwqap), [nwcorrelate](nwcorrelate)

- last certified : 24 Aug 2026

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
