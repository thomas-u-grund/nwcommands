---
title: "nwdyadprob"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
| `mat`(*matrix*) | Mata matrix (or Mata expression) with tie probabilities |
| `density(float)` | density of the new network |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `name(netname)` | name of the new random network |
| `xvars` | generate Stata variables for the network |
| `undirected` | generate undirected network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |

## Description

`nwdyadprob` generates a (un-)directed random network where each tie *x_ij* has the probability *p_ij* to exist. The values for *p_ij* are derived either 1) from the tie values of network [netname](netname) or 2) from a Mata matrix (or Mata expression) specified in **mat()**. When both are given, *netname* is used. The command can be used to create all sorts of networks.

Let *e_ij* be the tie values of network [netname](netname). When all of them lie between 0 and 1, *p_ij = e_ij*. Otherwise they are transformed to probabilities first: *p_ij* = invlogit(*e_ij*). The values in **mat()** are used as they are.

When no **density()** is given, each tie *x_ij* is drawn independently with probability *p_ij*.

With **density(***d***)**, exactly *n*(*n*-1)*d* ties (half as many with `undirected`) are drawn without replacement, with inclusion probabilities proportional to *p_ij*. The command stops with an error when fewer dyads have a non-zero *p_ij* than ties are requested.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized.

## Remarks

The program needs no additional packages: the weighted sampling of ties is built in (it gives the same sample as the user-written **gsample**, for the same random-number seed). Nothing is downloaded or installed.

## See also

- [nwhomophily](nwhomophily), [nwgen](nwgen), [nwexpand](nwexpand)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
