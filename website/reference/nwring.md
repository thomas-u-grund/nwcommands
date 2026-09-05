---
title: "nwring"
parent: "Command reference"
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
labs(lab1 lab2 ...)
xvars
ntimes(int)]
```

| | |
|---|---|
| *`nodes`* | number of nodes |
| `k(int)` | number of neighhbors on ring-lattice on each side |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `undirected` | generate an undirected network; default = directed |
| `name(newnetname)` | name of the new network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |
| `xvars` | generate Stata variables for the network |
| `ntimes(int)` | number of networks to be generated; default = 1 |
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

## Supported network types

Binary: yes (only structural tie placement - see Weighted). Directed: yes, via `undirected` (default is directed). Weighted: yes, via `weights()`, independent of the ring/shortcut placement mechanism itself. Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

## Stored results

- **nwring** stores the following in **r()**:

**Macros**

- **r(netlist)** list of new networks

## See also

- [nwpref](nwpref.md), [nwrandom](nwrandom.md), [nwlattice](nwlattice.md), [nwsmall](nwsmall.md)

- last certified : 24 Aug 2026
