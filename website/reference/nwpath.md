---
title: "nwpath"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate paths between nodes"
---

# `nwpath`

Calculate paths between nodes

## Syntax

```stata
nwpath 
[netname],
[ego(nodename)
alter(nodename) | 
egoid(nodeid)
alterid(nodeid)]
generate(newnetnamestub)
sym
nwreplace]
```

**Main**

| | |
|---|---|
| `ego(nodename)` | Name of start node |
| `alter(nodename)` | Name of destination node |
| `egoid(nodeid)` | Nodeid of start node |
| `alterid(nodeid)` | Nodeid of destination node |
| `generate(newnetnamestub)` | Save paths as networks beginning with *newnetnamestub* |
| `sym` | Symmetrize network for calculation |
| `nwreplace` | Overwrite networks with *newnetnamestub* |

## Description

` nwpath` calculates the shortest paths between node *ego* and node *alter*, i.e. ways how the nodes are connected with each other.

With option `generate(newnetname)` the command produces one new network for each valid path that is found. For example, if three paths are found between nodes *ego* and *alter*, the networks *newnetnamestub_1, newnetnamestub_2, newnetnamestub_3* are produced.

## Options

- **`ego(nodename)`** --- Must be specified and indicates the startpoint of a path.

- **`alter(nodename)`** --- Must be specified and indicates the endpoint of a path.

- **`sym`** --- Calculates everything on the symmetrized network.

- **`generate(newnetnamestub)`** --- Save the paths as networks. This can be used to display paths using nwplot, see example.

## Remarks

It can be a good idea to save the paths between two nodes by specifying `generate(newnetname)` for plotting. For example,

```stata
. nwwebuse florentine, nwclear
. nwpath flobusiness, ego(medici) alter(peruzzi) generate(medici_peruzzi)
```
There is exactly one shortest path between *medici* and *peruzzi*, so a single network, *medici_peruzzi_1*, is generated (`generate()` is a stub - one network per shortest path found, numbered *_1*, *_2*, ... - so a pair of nodes with multiple shortest paths would instead produce *medici_peruzzi_1*, *medici_peruzzi_2*, and so on). One can now use this new network to represent the edgecolor when plotting the original network.

```stata
. nwplot flobusiness, edgecolor(medici_peruzzi_1) scheme(s2network)
```

## Examples

```stata
. nwwebuse florentine
. nwpath flobusiness, ego(medici) alter(peruzzi)
```
- hline 40
- Network: flobusiness
- hline 40
- Ego : medici
- Alter : peruzzi
- Shortest path length : 3
- hline 40

- Path 1: medici => barbadori => castellani => peruzzi
- Path 2: medici => ridolfi => strozzi => peruzzi

## Supported network types

Binary: yes. Directed: yes (`sym` to symmetrize first). Weighted: not applicable - any nonzero tie is treated as traversable regardless of its value; there is currently no shortest-*weighted* -path variant (see [nwgeodesic](nwgeodesic) for weighted distances). Signed: not checked. Two-mode: not checked.
