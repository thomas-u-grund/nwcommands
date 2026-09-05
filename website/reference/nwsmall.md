---
title: "nwsmall"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Generate a small-world network"
---

# `nwsmall`

Generate a small-world network

## Syntax

```stata
nwsmall 
nodes
,
k(int) 
prob(float) 
[weights(p1, p2,...)
undirected
ntimes(int)
name(newnetname)
labs(lab1 lab2 ...)
xvars]
nwsmall 
nodes
,
k(int) 
shortcuts(integer) 
[weights(p1, p2,...)
undirected
ntimes(int)
name(newnetname)
labs(lab1 lab2 ...)
xvars]
```

| | |
|---|---|
| *`nodes`* | number of nodes |
| `k(int)` | number of neighhbors on ring-lattice on each side |
| `prob(float)` | probability for a tie to rewire |
| `shortcuts(int)` | exact number of ties to rewire |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `undirected` | generate an undirected network; default = directed |
| `ntimes(int)` | number of small-world networks to be generated; default = 1 |
| `name`(*[newnetname](newnetname)*) | name of the new network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |
| `xvars` | generate Stata variables for the network |
| `noreplace` | reserved; currently a no-op - the create/replace collision guard on `name()` already applies regardless |

## Description

`nwsmall` generates a (un-)directed, (un-)weighted small-world network using the original Watts-Strogatz model (see Watts and Strogatz 1998). The algorithm starts with a ring-lattice where each node has *k* neighbors on each side. Next, the ties of the ring-lattice are rewired in one of two ways:

1) When option **prob()** is specified, each tie of the ring-lattice has a certain probability to get rewired. All non-existent ties are valid as rewirings (including the ones produced through previous rewirings).

2) When option **shortcuts()** is specified, an exact number of ties of the ring-lattice gets rewired. In this algorithm, only ties that had not been in the original ring-lattice are valid rewirings.

Either option **prob()** or **shortcuts()** needs to be specified.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized. For example, the following produces a small-world network with 20 nodes. Furthermore, each one of these sampled ties gets assigned a tie weight because of option **weights()**. In this case, **weights(0.0, 0.3,0.7)** indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with probability 0.3 and tie weight 3 with probability 0.7.

- cmd. nwsmall 20, k(2) prob(.2) weights(0.0, 0.3, 0.7)

## Examples

In the first example, each tie on the ring-lattice has a probability to get rewired.

```stata
. nwclear
. nwsmall 20, k(2) prob(.2)
. nwplot, layout(circle)
```
In the second example, there are exactly three shortcuts.

```stata
. nwsmall 30, k(2) shortcuts(3) undirected
. nwplot, layout(circle)
```

## Supported network types

Binary: yes (only structural tie placement - see Weighted). Directed: yes, via `undirected` (default is directed). Weighted: yes, via `weights()`, independent of the small-world rewiring mechanism itself. Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

## Stored results

- **nwsmall** stores the following in **r()**:

**Macros**

- **r(netlist)** list of new networks

## References

Watts, D. J., Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature* 393(6684), 440-442.

## See also

- [nwpref](nwpref), [nwrandom](nwrandom), [nwlattice](nwlattice), [nwring](nwring)
