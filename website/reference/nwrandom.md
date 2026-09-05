---
title: "nwrandom"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Generate a random network"
---

# `nwrandom`

Generate a random network

## Syntax

```stata
nwrandom 
nodes
,
[prob(float)
density(float)
census(mutual asym [null])
weights(p1, p2,...)
undirected
ntimes(int)
name(newnetname)
labs(lab1, lab2, ...)
selfloop
xvars]
```

| | |
|---|---|
| *`nodes`* | number of nodes |
| `prob(float)` | probability for a tie |
| `density(float)` | exact density of the new network |
| `census`([*mutual* [*asym null*]](nwdyads.md)) | dyad census of the new network |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `undirected` | generate an undirected network; default = directed |
| `ntimes(int)` | number of random networks to be generated; default = 1 |
| `name`(*[newnetname](newnetname.md)*) | name of the new random network; default = *random* |
| `labs`(*lab1, lab2, ...*) | overwrite node labels |
| `selfloop` | allow self-loops (a node tied to itself) in the generated network; default = no self-loops |
| `xvars` | generate Stata variables for the network |
| `noreplace` | reserved; currently a no-op - the create/replace collision guard on `name()` already applies regardless |

## Description

`nwrandom` generates a (un-)directed, (un-)weighted Erdos-Renyi network. Each potential tie in the network has the same probability to exist, which is defined by **prob()**. Option **prob()** generates ties based on probabilities, which means that the exact number of ties can vary.

Alternatively, the overall density of the network can be specified with **density()**. This option always generates the same number of ties ( = *density * nodes*), where each tie has the same probability to exist.

Lastly, one can also generate a random network that has a specific [dyad census](nwdyads.md) using `census()` (see [nwdyads](nwdyads.md)).

Either **prob()**, **density()** or **census()** needs to be specified.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized. For example, the following produces a random network with 10 nodes, where each tie has the probability 0.5 to exist. Furthermore, each one of these randomly sampled ties gets assigned a tie weight because of option **weights()**. In this case, **weights(0.0, 0.3,0.7)** indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with probability 0.3 and tie weight 3 with probability 0.7.

- cmd. nwrandom 10, prob(.5) weights(0.0, 0.3, 0.7)

The command can also be used to generate many random networks at the same time. For example, the following command produces 100 random networks, where ties have the probability 0.1 to exist.

**. nwrandom 50, prob(.1) ntimes(100)**

By default, directed networks are generated, option **undirected** generates undiretced networks instead.

The command can also be used to generate both complete (**prob(1)**) and empty networks (**prob(0)**).

## Examples

```stata
. nwclear
. nwrandom 50, prob(.1)
. nwrandom 15, density(0.5)
. nwrandom 20, prob(.3) ntimes(5)
. nwrandom 10, prob(.2) undirected
. nwrandom 200, census(100 2000)
. nwrandom 10, density(.2) weights(0.1, 0.3, 0.6)
```

## Supported network types

Binary: yes (only structural tie placement - see Weighted). Directed: yes, via `undirected` (default is directed). Weighted: yes, via `weights()` - a Stata expression assigning each placed tie's value, independent of the placement mechanism itself (`density()`/`prob()`/`census()`). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

## Stored results

- **nwrandom** stores the following in **r()**:

**Macros**

- **r(netlist)** list of new networks

## See also

- [nwsmall](nwsmall.md), [nwpref](nwpref.md), [nwpref](nwpref.md), [nwlattice](nwlattice.md), [nwring](nwring.md)

- last certified : 24 Aug 2026
