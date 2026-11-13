---
title: "nwstack"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Stack several networks into one block-diagonal network"
---

# `nwstack`

Stack several networks into one block-diagonal network

## Syntax

```stata
nwstack
netlist,
n:ame(newnetname)
[gr:oup(newvar)
replace]
```

| | |
|---|---|
| `n:ame`(*newnetname*) | name of the stacked network (required) |
| `gr:oup`(*newvar*) | variable that numbers the networks of *netlist* 1, 2, ... for the nodes of each |
| `replace` | replace an existing network of that name |

## Description

`nwstack` places the networks of *netlist* side by side in one network. The nodes of the first network come first, then those of the second, and so on; there are no ties between nodes of different networks, so the result is the block-diagonal matrix of the networks. This is the data structure that `nwsaom` uses for several groups (its option `groups()`), where each group is a separate set of actors, such as a school class, observed with the same instrument.

The networks must be one-mode (a two-mode network stops with error 6088) and agree in direction. With `group()` the command creates a variable that holds the position of the network in *netlist*, for every node of the stacked network. If there are no data in memory, the command creates the observations; if there are data, they must already have one observation per node, in the order of the stacked network.

## Example

Two waves of three school classes are stacked into one network per wave, with a class variable:

- **. nwstack class1_w1 class2_w1 class3_w1, name(w1) group(class)**
- **. nwstack class1_w2 class2_w2 class3_w2, name(w2)**
- **. nwsaom, waves(w1 w2) groups(class) outdegree reciprocity**

## Stored results

`nwstack` stores in `r()`: `r(k)`, the number of networks stacked, and `r(N)`, the number of nodes of the stacked network.

## Author

Thomas U. Grund, RWTH Aachen University, thomas.u.grund@gmail.com

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
