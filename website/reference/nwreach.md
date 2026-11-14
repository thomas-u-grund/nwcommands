---
title: "nwreach"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Reachability network"
---

# `nwreach`

Reachability network

## Syntax

```stata
nwreach 
[netname]
[,
sym
name(newnetname)
xvars
nwreplace
force]
```

| | |
|---|---|
| `sym` | Symmetrize network before calculation of reachability |
| `name(newnetname)` | Name of the new network; default = *_reach* |
| `xvars` | Generate Stata variables for the network |
| `nwreplace` | if a network named *newnetname* already exists, drop it and use this name anyway - required, not silent (see [nwgeodesic](nwgeodesic) for the same convention) |
| `force` | Run the command although its matrices would not fit in memory (it stops with r(484) above 12 GB otherwise) |

## Description

`nwreach` calculates the reachability network. The dyads *x_ij* in the reachibility network take value 1 when there is at least one path between *nodes i* and *j* in the original network [netname](netname), and 0 if there is no such path.

## Network types

**Directed:** reachability follows the direction of the ties; `sym` symmetrizes. **Valued:** tie values are ignored and a note is printed. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Limits

The reachability network is one n-by-n matrix, made from the distances in place. Measured in Stata/BE, random directed network with 10 ties per node: 10,000 nodes 3 seconds, 20,000 nodes 11 seconds and 6.4 GB.

Reachability of all pairs of nodes is an *n*-by-*n* matrix; two matrices are held at once. Above about 27,000 nodes (12 GB) the command stops at once with r(484), and `force` runs it anyway. For connectedness use [nwcomponents](nwcomponents), for one pair [nwpath](nwpath).

## Examples

```stata
. nwclear
. nwrandom 10, prob(.1)
. nwreach random, sym
. nwsummarize _reach, matonly

      1    2    3    4    5    6    7    8    9   10
   +---------------------------------------------------+
 1 |   0                                               |
 2 |   1    0                                          |
 3 |   1    1    0                                     |
 4 |   1    1    1    0                                |
 5 |   1    1    1    1    0                           |
 6 |   1    1    1    1    1    0                      |
 7 |   1    1    1    1    1    1    0                 |
 8 |   0    0    0    0    0    0    0    0            |
 9 |   1    1    1    1    1    1    1    0    0       |
10 |   1    1    1    1    1    1    1    0    1    0  |
   +---------------------------------------------------+
```
In this example, there is basically one isolate node (node 8) who is unconnected from everybody else.

## See also

- [nwgeodesic](nwgeodesic), [nwpath](nwpath)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
