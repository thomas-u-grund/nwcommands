---
title: "nwpermute"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate a permutation of a network"
---

# `nwpermute`

Generate a permutation of a network

## Syntax

```stata
nwpermute 
[netname]
[,
generate(newnetname)
replace
nwreplace
xvars
swap
swaps(#)]
```

| | |
|---|---|
| `generate(newnetname)` | Save permutation as new network; one of `generate()` or `replace` is required |
| `replace` | Replace existing network with permutation; with `generate()`: overwrite the network named there if it already exists |
| `nwreplace` | Overwrite the network named in `generate()` if it already exists; without it the command stops with an error |
| `xvars` | Generate Stata variables for the network |
| `swap` | exchange the partners of two ties at random (Maslov and Sneppen) instead of permuting the labels; keeps every node's degree (directed: out-degree and in-degree; two-mode: both degree sequences) and the tie values |
| `swaps(#)` | the number of attempted exchanges; implies `swap`; default = ten times the number of ties |

## Description

Produces a random permutation of the network [netname](netname). In such a permutation, the nodes are randomly reshuffled, while the overall structure of the network remains the same. Either option **replace** or **generate** needs to be specified.

With `swap`, the ties are rewired instead: two ties a-b and c-d, picked at random, become a-d and c-b (in an undirected network, a-d and c-b or a-c and b-d, at random), unless that would make a self-loop or tie a pair that is tied already. Every node keeps its degree (in a directed network its out-degree and its in-degree), a tie keeps its value, and everything else about the network is randomized. `swaps()` sets the number of attempted exchanges (some are refused). This is the rewiring of R's `igraph::rewire(g, keeping_degseq())`: a random network with the degrees of the observed one, the usual baseline for a pattern that may follow from the degrees alone (see [nwcug](nwcug) with `condition(degrees)`, and [nwrandom](nwrandom) with `degree()` for a network drawn from a list of degrees). Self-loops and ties with a missing value stay where they are. For a one-mode network, `swap` uses the native plugin; the exchanges are drawn from the seed (`set seed`).

```stata
. nwuse glasgow, nwclear
. nwpermute glasgow1, swap generate(glasgow1_swapped)
```
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

## See also

- [nwqap](nwqap), [nwcorrelate](nwcorrelate)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
