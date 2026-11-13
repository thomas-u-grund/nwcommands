---
title: "nwkatz"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Katz-style distance-decay centrality"
---

# `nwkatz`

Katz-style distance-decay centrality

## Syntax

```stata
nwkatz 
[netname]
[,
alpha(real)
walks
gen:erate(varname)
replace
nosym
geodesic_options
force
bin:ary]
```

| | |
|---|---|
| `alpha(real)` | penalization factor for calculation of weights; default = 1 (distance-decay mode) or **0.9/rho** (walk-counting mode, `walks`) |
| `walks` | switch to the literature's own genuine walk-counting Katz/Bonacich centrality, *(I - alpha*A)^-1 * 1*, instead of this command's own default distance-decay formula (see Description) |
| `gen:erate`(*`varname`*) | **Required.** Variable name for Katz centrality scores; for a directed network the variables *varname***_out** and *varname***_in** are generated |
| `replace` | Replace existing variable |
| `nosym` | Distance-decay form: keep the direction of the ties of a directed network (by default the network is symmetrized); not used with `walks` |
| *[geodesic_options](nwgeodesic)* | options for calculating distances (forwarded to the internal [nwgeodesic](nwgeodesic) call); not used when `walks` is specified |
| `force` | Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise) |
| `bin:ary` | With `walks`: ignore the tie values of a valued network (by default the walks are weighted by them); the distance-decay form always counts steps |

## Description

Calculates a distance-decay centrality measure, inspired by Katz's (1953) attenuation idea, for each node *i* in a network and saves the result as a variable. It is an extension of degree centrality (see [nwdegree](nwdegree)): degree centrality counts each node's direct neighbors; this measure counts all other reachable nodes, but penalizes ones that are further away.

Formally, this command computes:

*nwkatz(i) = sum(alpha ^ dist(i,j)), over all j reachable from i*

where *dist(i,j)* is the [geodesic (shortest-path) distance](nwgeodesic) between nodes *i* and *j*, and unreachable pairs contribute 0.

**The DEFAULT formula (without `walks`) is not the same as the Katz centrality defined in** **the literature.** Katz's (1953) original measure counts the total number of *walks* of every length between two nodes, attenuated by *alpha* raised to the walk length, and is computed as *(I - alpha*A)^-1 * 1* (a matrix-inverse, eigenvector-family measure closely related to Bonacich power centrality) - not as a sum over *shortest-path distances* the way this command's own default formula does. The two measures are related in spirit (both attenuate a node's reach by distance/length) but are mathematically different and will generally give different node rankings, especially on networks with many alternate paths between the same pair of nodes, since true Katz centrality credits every walk, not just the shortest one. This note makes the choice of default formula, and its relationship to the cited reference, explicit rather than implied by the command name and citation alone.

`walks` switches to the genuine, literature-standard walk-counting Katz/Bonacich formula instead: *x = (I - alpha*A)^-1 * 1*, solved via a linear solve (not an explicit matrix inverse). `alpha()` must then satisfy *|alpha| * rho < 1* (rho = the network's own spectral radius) or the implied infinite walk sum diverges - `nwkatz` checks this and errors with the valid range if violated. Default `alpha()` in this mode is **0.9/rho**, a conventional "safely inside the convergent range" choice; on a network with rho = 0 (no cycles, so every walk is finite and every `alpha()` is valid) the default is 1. Directed networks get separate in/out-walk variants, the same convention the default distance-decay formula already uses.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkatz flomarriage, generate(_katz)
. sum _katz
```

## References

Katz, L. (1953). A New Status Index Derived from Sociometric Index. *Psychometrika*, 39-43.

## See also

- [nwcloseness](nwcloseness), [nwbetween](nwbetween), [nwdegree](nwdegree), [nwcloseness](nwcloseness), [nwevcent](nwevcent)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
