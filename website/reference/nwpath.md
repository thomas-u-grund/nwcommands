---
title: "nwpath"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Paths between nodes"
---

# `nwpath`

Paths between nodes

## Syntax

```stata
nwpath 
[netname],
ego(nodename) | egoid(nodeid)
alter(nodename) | alterid(nodeid)
[generate(newnetnamestub)
sym
nwreplace
nopaths
bin:ary
alpha(real)]
```

**Main**

| | |
|---|---|
| `ego(nodename)` | Name of start node |
| `alter(nodename)` | Name of destination node |
| `egoid(nodeid)` | Nodeid of start node |
| `alterid(nodeid)` | Nodeid of destination node |
| `generate(newnetnamestub)` | Save paths as networks beginning with *newnetnamestub* |
| `sym` | Symmetrize network for calculation; cannot be combined with `generate()` |
| `nwreplace` | Overwrite networks with *newnetnamestub* |
| `nopaths` | Do not print the list of paths; the results in `r()` are still returned |
| `bin:ary` | Ignore the tie values of a valued network (by default they are used) |
| `alpha(real)` | Cost of a step along a tie of value w: 1/w^alpha (default 1 on a valued network; accepted on any network) |

## Description

` nwpath` calculates the shortest paths between node *ego* and node *alter*, i.e. ways how the nodes are connected with each other. When *ego* and *alter* are the same node, the path is the node itself, of length 0 (as in igraph).

With option `generate(newnetname)` the command produces one new network for each valid path that is found. For example, if three paths are found between nodes *ego* and *alter*, the networks *newnetnamestub_1, newnetnamestub_2, newnetnamestub_3* are produced. On an undirected network each tie of a path network is undirected (stored in both directions).

Errors: a node that does not exist, or an id out of range, stops the command with **r(485)**; a path network that already exists without `nwreplace` with **r(483)**; a missing or invalid option with **r(198)** (see [nwerrorcodes](nwerrorcodes)).

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

## Network types

**Directed:** used as directed; `sym` symmetrizes the network first. **Valued:** tie values are used by default: the path of least cost, a tie of value w costing 1/w^alpha (`alpha(1)` by default, `alpha(-1)`: values are lengths; `r(path_cost)`, `r(path_length)` = steps); `binary` finds the fewest steps. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The paths are enumerated from the stored ties and `generate()` writes each path as a network of its ties; neither builds a matrix. 20,000 nodes 0.25 seconds in Stata/BE for two nodes at 4 steps. The number of walks examined grows with the degree to the power of the path length.

## Examples

```stata
. nwwebuse florentine
. nwpath flobusiness, ego(medici) alter(peruzzi)

----------------------------------------
  Network: flobusiness
----------------------------------------
    Ego                  : medici
    Alter                : peruzzi
    Shortest path length : 3
----------------------------------------

  Path 1:  medici => barbadori => castellani => peruzzi
  Path 2:  medici => ridolfi => strozzi => peruzzi
```

## Stored results

- **Scalars**
- **r(paths)** --- number of shortest paths found (0 if *ego* and *alter* are not connected)
- **r(path_length)** --- length of the shortest path (-1 if not connected)
- **r(path_shortest)** --- same as **r(path_length)**; this command currently only ever finds shortest paths, there is no **length()** option to select a longer one
- **r(path_cost)** --- cost of the path on a valued network (sum of 1/value^alpha)
- **r(ego)** --- nodeid of ego
- **r(alter)** --- nodeid of alter

- **Matrices**
- **r(paths_matrix)** --- one row per path found, node ids along the path; only set when **r(paths)** > 0

## Also see

- [nwgeodesic](nwgeodesic)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
