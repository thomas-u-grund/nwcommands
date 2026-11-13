---
title: "nw2clustering"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Clustering coefficient (transitivity) of a two-mode network"
---

# `nw2clustering`

Clustering coefficient (transitivity) of a two-mode network

## Syntax

```stata
nw2clustering
[netname]
[,
measure(string)
level(int)
generate(newvarname)
replace
ra]
```

| | |
|---|---|
| `measure(binary\|arithmetic\|geometric\|maximum\|minimum)` | How to combine a 4-path's own four tie values; *binary* dichotomizes every tie to presence/absence first; *arithmetic*/*geometric*/*maximum*/*minimum* combine the four raw tie values via that function; default = *arithmetic* for a valued network, *binary* otherwise |
| `level(int)` | Which mode (1 or 2) to compute clustering scores for; default = 1 |
| `generate(newvarname)` | **Required** unless `ra` is given. Name of the Stata variable that stores each `level()`-mode node's own clustering coefficient |
| `replace` | Overwrite an existing `generate(newvarname)` variable; required if it already exists |
| `ra` | The global clustering coefficient of Robins and Alexander (2004), 4 C4 / L3 (C4 the number of four-cycles, L3 the number of paths of length three) of the binary network; `generate()` is then optional; results in `r(ra)`, `r(C4)`, `r(L3)` |

## Description

`nw2clustering` is the form of [nwclustering](nwclustering) for a two-mode network: `nwclustering` uses it by default on a two-mode network (and `onemode` forces the one-mode coefficient). The two names give the same result with the same options.

`nw2clustering` calculates the two-mode (bipartite) analogue of the ordinary clustering coefficient (see [nwclustering](nwclustering)) using the 4-path / 6-cycle definition of Opsahl (2013) and Robins & Alexander (2004): an ordinary triangle cannot exist in a two-mode network (a tie only ever connects the two different modes), so "closure" is instead measured on paths of length 4 - two `level()`-mode nodes connected via two distinct intermediate opposite-mode alters - and a path is *closed* when its two ends are ALSO both tied to some further common alter, forming a 6-cycle. This deliberately excludes shorter 4-cycles (reusing one of the same two alters) as a form of closure, matching the cited reference's own distinction between mere shared-affiliation redundancy and genuine triadic-style closure.

Only nodes of the requested `level()` receive a value; nodes of the other mode are left missing. A node with too few alters, or whose own connected component has fewer than 3 same-mode nodes, has no possible 4-path and its own coefficient is reported missing (not spuriously 0).

[nwclustering](nwclustering) automatically switches to this computation whenever it is called on a two-mode network (unless `onemode` is given), with the same options `measure()`, `level()`, `generate()`, `replace` and `ra`.

## Examples

```stata
. nwset ego alter, twomode name(bip)
. nw2clustering bip, generate(_clustering2_lev1)
. sum _clustering2_lev1
```

## Stored results

- **Scalars**
- **r(C_avg)** --- mean of the per-node clustering coefficients (the requested `level()` only)
- **r(C_global)** --- network-level global clustering coefficient (ratio of total closed to total potential 4-paths)
- **r(ra)** --- Robins-Alexander coefficient 4 C4 / L3 (only with `ra`)
- **r(C4)** --- number of four-cycles (only with `ra`)
- **r(L3)** --- number of paths of length three (only with `ra`)

- **Macros**
- **r(measure)** --- the `measure()` actually used (only with `generate()`)

## References

Opsahl, T. (2013). Triadic closure in two-mode networks: Redefining the global and local clustering coefficients. *Social Networks* 35(2), 159-167.

Robins, G., Alexander, M. (2004). Small worlds among interlocking directors: Network structure and distance in bipartite graphs. *Computational & Mathematical Organization Theory* 10(1), 69-94.

## See also

- [nwclustering](nwclustering), [nw2project](nw2project), [nw2degree](nw2degree)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
