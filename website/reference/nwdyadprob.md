---
title: "nwdyadprob"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Generate a network based on tie probabilities"
---

# `nwdyadprob`

Generate a network based on tie probabilities

## Syntax

```stata
nwdyadprob 
[netname]
[,
mat(matamatrix)
density(float)
weights(p1, p2,...)
name(netname)
xvars
undirected
labs(lab1 lab2 ...)]
```

| | |
|---|---|
| `mat`(*matrix*) | Stata or Mata matrix with tie probabilities |
| `density(float)` | density of the new network |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `name(netname)` | name of the new random network |
| `xvars` | generate Stata variables for the network |
| `undirected` | generate undirected network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |

## Description

`nwdyadprob` generates a (un-)directed random network where each tie *x_ij* has the probability *p_ij* to exist. The values for *p_ij* are derived either 1) from the edge values in network [netname](netname) and the *density* (if given) or 2) from a Stata/Mata matrix specified in **mat()**. The command can be used to create all sorts of networks.

Let *e_ij* be the edge values of network [netname](netname).

Then, the probability for a tie *x_ij* to exist in the newly created network is *p_ij*:

*p_ij = ((e_ij) / sum(e_kl)) * density * 100*

When no **density()** is given, the probability is simply:

*p_ij = e_ij*

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized.

## Remarks

The program requires some additional programs (**gsample, moremata**) that it automatically installs from the internet.

## Supported network types

Binary: yes (only structural tie placement - see Weighted). Directed: yes, via `undirected` (default is directed). Weighted: yes, via `weights()` (a per-dyad tie-value expression, independent of `density()`'s own probability-of-placement role) - though `weights()` is currently only implemented for the `mat()`-based path, not the `density()`-based path (an explicit, honest error is raised if both are combined; see the command's own Description). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

## See also

- [nwhomophily](nwhomophily), [nwgen](nwgen), [nwexpand](nwexpand)

- last certified : 24 Aug 2026
