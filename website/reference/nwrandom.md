---
title: "nwrandom"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
[p:rob(#)
d:ensity(#)
c:ensus(mutual [asym [null]])
deg:ree(numlist|varname)
out:degree(numlist|varname) in:degree(numlist|varname)
swaps(#)
weights(p1, p2,...)
undirected
directed
ntimes(int)
name(newnetname)
labs(lab1, lab2, ...)
selfloop
xvars]
```

| | |
|---|---|
| *`nodes`* | number of nodes |
| `p:rob(#)` | probability for a tie |
| `d:ensity(#)` | exact density of the new network |
| `c:ensus`([*mutual*](nwdyads) [*asym* [*null*]]) | dyad census of the new network: numbers of mutual and asymmetric dyads (default 0); a third number is ignored |
| `deg:ree`(*numlist*\|varname) | degree of every node of a new undirected network: a list of *nodes* numbers, or a variable (its first *nodes* observations) |
| `out:degree()` `in:degree()` | out-degree and in-degree of every node of a new directed network; both are needed |
| `swaps(#)` | with degrees: the number of attempted tie swaps that randomize the network; default = 10 times the number of ties |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `undirected` | generate an undirected network; default = directed |
| `directed` | generate a directed network; this is the default, so the option changes nothing (it cannot be combined with `undirected`) |
| `ntimes(int)` | number of random networks to be generated; default = 1 |
| `name`(*[newnetname](newnetname)*) | name of the new random network; default = *random* |
| `labs`(*lab1, lab2, ...*) | overwrite node labels |
| `selfloop` | allow self-loops (a node tied to itself) in the generated network; default = no self-loops |
| `xvars` | generate Stata variables for the network |
| `noreplace` | reserved; currently a no-op - the create/replace collision guard on `name()` already applies regardless |

## Description

`nwrandom` generates a (un-)directed, (un-)weighted Erdos-Renyi network. Each potential tie in the network has the same probability to exist, which is defined by **prob()**. Option **prob()** generates ties based on probabilities, which means that the exact number of ties can vary.

Alternatively, the overall density of the network can be specified with **density()**. This option always generates the same number of ties (*density* times the number of possible ties, rounded down), where each tie has the same probability to exist.

Lastly, one can also generate a random network that has a specific [dyad census](nwdyads) using `census()` (see [nwdyads](nwdyads)).

A random network with given degrees is drawn with `degree()` (undirected) or with `outdegree()` and `indegree()` (directed); see *Networks with given degrees* below.

Either **prob()**, **density()**, **census()** or the degrees need to be specified.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized. For example, the following produces a random network with 10 nodes, where each tie has the probability 0.5 to exist. Furthermore, each one of these randomly sampled ties gets assigned a tie weight because of option **weights()**. In this case, **weights(0.0, 0.3,0.7)** indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with probability 0.3 and tie weight 3 with probability 0.7.

```stata
. nwrandom 10, prob(.5) weights(0.0, 0.3, 0.7)
```
The command can also be used to generate many random networks at the same time. For example, the following command produces 100 random networks, where ties have the probability 0.1 to exist.

**. nwrandom 50, prob(.1) ntimes(100)**

By default, directed networks are generated, option **undirected** generates undiretced networks instead.

The command can also be used to generate both complete (**prob(1)**) and empty networks (**prob(0)**).

## Networks with given degrees

`degree()` draws an undirected network in which every node has exactly the degree given, with no self-loop and no pair of nodes tied twice; `outdegree()` and `indegree()` do the same for the out-degrees and in-degrees of a directed network. The degrees are a list of whole numbers, one for each node, or a numeric variable whose first *nodes* observations hold them, for example the degrees of an observed network from [nwdegree](nwdegree). Use a variable for long lists. All networks with these degrees are about equally likely: a network with the degrees is first built (Havel-Hakimi; directed: Kleitman-Wang) and then randomized by `swaps()` random tie swaps, which exchange the partners of two ties (a-b and c-d become a-d and c-b) whenever that makes no self-loop and no repeated tie, so the degrees never change. This is the method `edge.switching.simple` of R's `igraph::sample_degseq()`. The network is unweighted. A random network with the degrees of an observed one is the usual baseline for asking whether a pattern (clustering, reciprocity, segregation) goes beyond what the degrees alone produce; [nwcug](nwcug) with `condition(degrees)` runs such a test and [nwpermute](nwpermute) with `swap` rewires a copy of the observed network itself.

Not every list of degrees can be the degrees of a network: their sum must be even (directed: the out-degrees and the in-degrees must have the same sum), no node can have more than *nodes* - 1 ties, and more conditions follow from these (Erdos and Gallai 1960). `nwrandom` stops with error 198 when no network has the degrees. For example, three nodes cannot all have degree 1, and in `degree(3 3 1 1)` the two nodes of degree 3 would give every other node at least degree 2. `degree()` cannot be combined with `prob()`, `density()`, `census()`, `weights()` or `selfloop`. The draws use the native plugin.

```stata
. nwrandom 8, degree(3 3 2 2 2 2 1 1)
. nwuse glasgow, nwclear
. nwdegree glasgow1, generate(od id)
. nwrandom 50, outdegree(od) indegree(id) name(glasgow_null)
```

## Network types

Generates a one-mode network. **Directed:** directed by default, `undirected` for undirected; `degree()` draws an undirected, `outdegree()` / `indegree()` a directed network. **Valued:** `weights()` sets the tie values. **Two-mode:** not applicable. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

`prob()` above 2,000 nodes draws the ties as a list from the same random numbers as the matrix version (the same seed gives the same network). `density()` above 5,000 nodes draws the positions of the ties directly instead of shuffling all *n*^2 cells: a different random-number stream (and the same distribution); with 5,000 nodes or fewer the shuffle is used. `weights()` and `census()` work on the matrix. Measured in Stata/BE, density 0.0001: 5,000 nodes 11 seconds (shuffle), 10,000 nodes 0.1 seconds, 20,000 nodes 0.2 seconds (`density(.0002)`); `prob(.0002)` at 20,000 nodes 2.8 seconds.

## Examples

```stata
. nwclear
. nwrandom 50, prob(.1)
. nwrandom 15, density(0.5)
. nwrandom 20, prob(.3) ntimes(5)
. nwrandom 10, prob(.2) undirected
. nwrandom 200, census(100 2000)
. nwrandom 10, density(.2) weights(0.1, 0.3, 0.6)
. nwrandom 8, degree(3 3 2 2 2 2 1 1)
```

## Stored results

- **nwrandom** stores the following in **r()**:

- **Macros**
- **r(netlist)** --- list of new networks

## See also

- [nwsmall](nwsmall), [nwpref](nwpref), [nwlattice](nwlattice), [nwring](nwring), [nwcug](nwcug), [nwpermute](nwpermute)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
