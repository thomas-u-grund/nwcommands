---
title: "nwpermute"
parent: "Command reference"
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
xvars]
```

| | |
|---|---|
| `generate(newnetname)` | Save permutation as new network |
| `replace` | Replace existing network with permutation |
| `xvars` | Generate Stata variables for the network |

## Description

Produces a random permutation of the network [netname](netname). In such a permutation, the nodes are randomly reshuffled, while the overall structure of the network remains the same. Either option **replace** or **generate** needs to be specfied.

A simple example illustrates what the command does. First, we generate a regular lattice network.

- . nwclear
- . nwlattice 3 3
- . nwsummarize lattice, matonly

- 1 2 3 4 5 6 7 8 9
- hline 37
- 1 c | 0 c |
- 2 c | 1 0 c |
- 3 c | 0 1 0 c |
- 4 c | 1 0 0 0 c |
- 5 c | 0 1 0 1 0 c |
- 6 c | 0 0 1 0 1 0 c |
- 7 c | 0 0 0 1 0 0 0 c |
- 8 c | 0 0 0 0 1 0 1 0 c |
- 9 c | 0 0 0 0 0 1 0 1 0 c |
- hline 37

Now, let us permute the network *lattice*.

- . nwpermute lattice, replace
- . nwsummarize lattice, matonly

- 1 2 3 4 5 6 7 8 9
- hline 37
- 1 c | 0 c |
- 2 c | 1 0 c |
- 3 c | 0 0 0 c |
- 4 c | 0 0 1 0 c |
- 5 c | 1 0 0 0 0 c |
- 6 c | 0 1 0 1 0 0 c |
- 7 c | 0 0 0 0 1 0 0 c |
- 8 c | 0 0 1 0 0 0 1 0 c |
- 9 c | 0 1 0 1 1 0 0 1 0 c |
- hline 37

The structure of the network remains exactly the same, however, the nodes have a different order. Often, such a permutation is desired to recalculate network statistics (and derive standard errors and confidence intervals for these statistics) while keeping the overall structure of the network constant (see more [nwqap](nwqap), [nwcorrelate](nwcorrelate)).

## Supported network types

Binary: yes. Directed: yes. Weighted: yes - tie values move with their ties under the random relabeling (a pure permutation of the existing adjacency matrix). Signed: yes, values including negative are preserved. Two-mode: not checked.

## See also

- [nwqap](nwqap), [nwcorrelate](nwcorrelate)

- last certified : 24 Aug 2026
