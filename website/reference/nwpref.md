---
title: "nwpref"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate a preferential-attachment network"
---

# `nwpref`

Generate a preferential-attachment network

## Syntax

```stata
nwpref 
nodes
[,
m0(int) 
m(int) 
prob(float) 
weights(p1, p2,...)
undirected
name(newnetname)
labs(lab1, lab2, ...)
xvars
ntimes(int)]
```

| | |
|---|---|
| *nodes* | number of nodes |
| `m0(int)` | number of connected nodes at start; default = 2 |
| `m(int)` | number of connections each new node forms; default = 2 |
| `prob(float)` | probability that new node connects to existing nodes uniformly at random; default = 0 |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `undirected` | generate an undirected network; default = directed |
| `name`(*[newnetname](newnetname)*) | name of the new network |
| `labs`(*lab1, lab2, ...*) | overwrite node labels |
| `xvars` | generate Stata variables for the network |
| `ntimes(int)` | number of preferential-attachment networks to be generated (named *name*_1, *name*_2, ...); default = 1 |
| `noreplace` | reserved; currently a no-op - the create/replace collision guard on `name()` already applies regardless |

## Description

`nwpref` generates a (un-)directed, (un-)weighted preferential-attachment network using the Barabasi-Albert (1999) model. The network begins with an initial connected network of *m_0* nodes. One new node is added to the network at each time *t*. The preferential attachment process is stated as follows:

With a probability *0 <= prob <= 1*, this new node connects to *m <= m_0* nodes uniformly at random.

With a probability *1 - prob*, this new node connects to *m* existing nodes with a probability proportional to their current (in-)degree.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized. For example, the following assigns a tie weight to each tie because of option **weights()**. In this case, **weights(0.0, 0.3,0.7)** indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with probability 0.3 and tie weight 3 with probability 0.7.

```stata
. nwpref 20, prob(1) undirected weights(0.0, 0.3, 0.7)
```

## Examples

```stata
. nwclear
. nwpref 20, undirected
. nwplot, layout(circle)

. nwpref 20, prob(1) undirected
. nwplot, layout(circle)
```

## Stored results

- **nwpref** stores the following in **r()**:

- **Macros**
- **r(netlist)** --- list of new networks

## References

Barabasi, A-L., Albert, R. (1999). Emergence of scaling in random networks. *Science* 286(54439), 509-512.

## See also

- [nwsmall](nwsmall), [nwrandom](nwrandom), [nwlattice](nwlattice), [nwring](nwring)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
