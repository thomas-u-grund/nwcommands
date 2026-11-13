---
title: "nwring"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate a ring-lattice network"
---

# `nwring`

Generate a ring-lattice network

## Syntax

```stata
nwring 
nodes
,
k(int) 
[weights(p1, p2,...)
undirected
name(newnetname)
labs(lab1,lab2,...)
xvars
ntimes(int)]
```

| | |
|---|---|
| *`nodes`* | number of nodes |
| `k(int)` | number of neighbors on ring-lattice on each side |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `undirected` | generate an undirected network; default = directed |
| `name(newnetname)` | name of the new network; default = *ring* |
| `labs`(*lab1,lab2,...*) | overwrite node labels (separated by commas) |
| `xvars` | generate Stata variables for the network |
| `ntimes(int)` | number of networks to be generated (named *name*_1, *name*_2, ...); default = 1 |
| `noreplace` | reserved; currently a no-op - the create/replace collision guard on `name()` already applies regardless |

## Description

`nwring` generates a (un-)directed, (un-)weighted ring-lattice network. Each node is connected to *k* nodes on each side. Basically, each node has 2 * *k* neighbors in a ring structure.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized. For example, the following produces a ring-lattice network with 20 nodes, where each node is connected to two neighbors on each side. Furthermore, each one of these sampled ties gets assigned a tie weight because of option **weights()**. In this case, **weights(0.0, 0.3,0.7)** indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with probability 0.3 and tie weight 3 with probability 0.7.

```stata
. nwring 20, k(2) weights(0.0,0.3,0.7)
```

## Examples

```stata
. nwclear
. nwring 20, k(2) undirected
```

## Stored results

- **nwring** stores the following in **r()**:

- **Macros**
- **r(netlist)** --- list of new networks

## See also

- [nwpref](nwpref), [nwrandom](nwrandom), [nwlattice](nwlattice), [nwsmall](nwsmall)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
