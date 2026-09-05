---
title: "nwkatz"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate a Katz-inspired distance-decay centrality"
---

# `nwkatz`

Calculate a Katz-inspired distance-decay centrality

## Syntax

```stata
nwkatz 
[netname]
[,
alpha(real)
walks
generate(varname)
replace
geodesic_options]
```

| | |
|---|---|
| `alpha(real)` | penalization factor for calculation of weights; default = 1 (distance-decay mode) or **0.9/rho** (walk-counting mode, `walks`) |
| `walks` | switch to the literature's own genuine walk-counting Katz/Bonacich centrality, *(I - alpha*A)^-1 * 1*, instead of this command's own default distance-decay formula (see Description) |
| `generate`(*`varname`*) | **Required.** Variable name for Katz centrality scores |
| `replace` | Replace existing variable |
| *[geodesic_options](nwgeodesic.md)* | options for calculating distances (forwarded to
the internal [nwgeodesic](nwgeodesic.md) call); not used when `walks` is specified |

## Description

Calculates a distance-decay centrality measure, inspired by Katz's (1953) attenuation idea, for each node *i* in a network and saves the result as a variable. It is an extension of degree centrality (see [nwdegree](nwdegree.md)): degree centrality counts each node's direct neighbors; this measure counts all other reachable nodes, but penalizes ones that are further away.

Formally, this command computes:

*nwkatz(i) = sum(alpha ^ dist(i,j)), over all j reachable from i*

where *dist(i,j)* is the [geodesic (shortest-path) distance](nwgeodesic.md) between nodes *i* and *j*, and unreachable pairs contribute 0.

**The DEFAULT formula (without `walks`) is not the same as the Katz centrality defined in the literature.** Katz's (1953) original measure counts the total number of *walks* of every length between two nodes, attenuated by *alpha* raised to the walk length, and is computed as *(I - alpha*A)^-1 * 1* (a matrix-inverse, eigenvector-family measure closely related to Bonacich power centrality) - not as a sum over *shortest-path distances* the way this command's own default formula does. The two measures are related in spirit (both attenuate a node's reach by distance/length) but are mathematically different and will generally give different node rankings, especially on networks with many alternate paths between the same pair of nodes, since true Katz centrality credits every walk, not just the shortest one. The default formula's own results are unchanged from prior versions (preserving backwards compatibility for anyone already relying on this specific distance-decay measure) - this note exists so the choice of default formula, and its relationship to the cited reference, is explicit rather than implied by the command name and citation alone.

`walks` switches to the genuine, literature-standard walk-counting Katz/Bonacich formula instead: *x = (I - alpha*A)^-1 * 1*, solved via a linear solve (not an explicit matrix inverse). `alpha()` must then satisfy *|alpha| * rho < 1* (rho = the network's own spectral radius) or the implied infinite walk sum diverges - `nwkatz` checks this and errors with the valid range if violated. Default `alpha()` in this mode is **0.9/rho**, a conventional "safely inside the convergent range" choice. Directed networks get separate in/out-walk variants, the same convention the default distance-decay formula already uses.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwkatz flomarriage, generate(_katz)
. sum _katz
```

## Supported network types

Binary: yes. Directed: yes - generates separate *_in*/*_out* variables automatically when the network is directed (the network is otherwise symmetrized for the underlying distance calculation unless [geodesic_options](nwgeodesic.md) specifies `nosym`). Weighted: distances come from [nwgeodesic](nwgeodesic.md), which supports valued networks via its own `alpha()`/weighting options, forwarded through this command's *geodesic_options*; weight meaning follows whatever [nwgeodesic](nwgeodesic.md) uses (tie strength inverted into a path cost via the Opsahl et al. formulation - see [nwgeodesic](nwgeodesic.md) for detail), not tie strength directly. Signed: not checked; negative tie values are not validated or rejected. Two-mode: not checked.

## References

Katz, L. (1953). A New Status Index Derived from Sociometric Index. *Psychometrika*, 39-43.

## See also

- [nwcloseness](nwcloseness.md), [nwbetween](nwbetween.md), [nwdegree](nwdegree.md), [nwcloseness](nwcloseness.md), [nwevcent](nwevcent.md)

- last certified : 24 Aug 2026
