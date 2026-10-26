---
title: "nw2nested"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Nestedness of a two-mode network: NODF and C-score"
---

# `nw2nested`

Nestedness of a two-mode network: NODF and C-score

## Syntax

```stata
nw2nested [netname] [, lev:el(#) silent]
```

| | |
|---|---|
| `lev:el(#)` | the mode whose pairs of nodes enter the C-score, 1 or 2; default `level(2)` (the columns of the matrix, as in `bipartite::C.score`) |
| `silent` | suppress the output |

## Description

`nw2nested` measures how nested a two-mode network is, the question asked of the species-by-site and plant-pollinator matrices of ecology and of any membership matrix in which the small groups are subsets of the large ones. **NODF** is the nestedness metric based on overlap and decreasing fill of Almeida-Neto et al. (2008): for every pair of nodes of one mode with different degrees it takes the percentage of the ties of the node with the smaller degree that the other node has too (0 for equal degrees), and averages over all pairs of both modes (NODF) or over the pairs of one mode. The **C-score** of Stone and Roberts (1990) counts the checkerboard units, the pairs of nodes that each have a partner the other lacks, and averages over all pairs of nodes of one mode; the normalised form divides each count by its largest possible value for the two degrees (the form of `bipartite::C.score(normalise = TRUE)`). The result does not depend on the order of the nodes.

Ties are read as present or absent; tie values are ignored. A pair with an empty or full node has no normalised C-score and is left out of its mean.

## Options

`level(#)` chooses the mode whose pairs of nodes enter the C-score. The default 2 uses the nodes of the second mode (the columns of the matrix with the first mode as rows). NODF always uses both modes.

## Supported network types

Binary: yes. Directed: not applicable (a two-mode network is undirected). Valued: tie values are ignored (presence of a tie). Two-mode: yes - the command needs a two-mode network and uses the biadjacency matrix of the two modes (`bipartite::nested`, `vegan::nestednodf`, `bipartite::C.score`).

## Stored results

`nw2nested` stores in `r()`:

- **Scalars**

- synopt:`r(nodf)`NODF, percent
- synopt:`r(nodf_mode1)`NODF among the nodes of mode 1, percent
- synopt:`r(nodf_mode2)`NODF among the nodes of mode 2, percent
- synopt:`r(cscore)`mean number of checkerboard units per pair
- synopt:`r(cscore_norm)`mean normalised C-score, 0 to 1 (`bipartite` reports it times 100)
- synopt:`r(cscore_pairs)`number of pairs in the normalised mean
- synopt:`r(level)`mode of the C-score pairs

## References

Almeida-Neto, M., P. Guimaraes, P. R. Guimaraes, R. D. Loyola, and W. Ulrich. 2008. A consistent metric for nestedness analysis in ecological systems. *Oikos* 117: 1227-1239.

Stone, L., and A. Roberts. 1990. The checkerboard score and species distributions. *Oecologia* 85: 74-79.

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
