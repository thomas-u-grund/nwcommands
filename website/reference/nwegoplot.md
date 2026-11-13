---
title: "nwegoplot"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Draw the ego network of one node, ego in the center"
---

# `nwegoplot`

Draw the ego network of one node, ego in the center

## Syntax

```stata
nwegoplot [netname], ego(node) [hop(1|2) sort:by(varname)
gen:erate(xvar yvar) replace edgec:olor(...) nwplot_options]
```

| | |
|---|---|
| `ego(node)` | the focal node: its name (as in **_nwnode**) or its number; required |
| `hop(1\|2)` | `1` (default) draws ego and its alters; `2` adds the contacts of the alters on an outer circle |
| `sort:by(varname)` | place alters with the same value of *varname* next to each other |
| `gen:erate(xvar yvar)` | keep the coordinates in two new variables (missing outside the ego network) |
| `replace` | overwrite the variables of `generate()` |
| `edgec:olor(...)` | color the ties by another network, as in [nwplot](nwplot); replaces the default coloring of the ties |
| `size(...)` | node size, as in [nwplot](nwplot); replaces the default, ego drawn twice as large as the alters |
| `aspect:ratio(#)` | as in [nwplot](nwplot); by default the proportions of the coordinates, so that the circles stay round |
| *nwplot_options* | any other option of [nwplot](nwplot), such as `label()`, `color()`, `symbol()`, `size()`, `scheme()`, `lineopt()`, `arrowfactor()` |

## Description

`nwegoplot` draws the ego network of one node: ego in the center, its alters (the nodes it sends ties to or receives ties from) evenly on a circle around it, and all ties among these nodes. Ego's own ties (the spokes) are drawn in light gray and the ties among the alters in dark gray, so that the density of the ego network, the ties among the alters, is what stands out. Ego is drawn twice as large as the other nodes.

The alters are ordered around the circle so that ties among them stay short: alters who are connected with each other (directly or through other alters) are placed together, the largest such group first and alters without ties to other alters last, and inside each group the nodes follow the spectral order of the group (the Fiedler vector of its Laplacian). With `sortby()` the alters are first grouped by the variable, then ordered in the same way inside each value.

With `hop(2)` the nodes at distance two from ego are placed on an outer circle, each near the direction of the alters it is tied to.

The plot is drawn by [nwplot](nwplot) with `nodexy()` and `if`, so all options of `nwplot` apply; `nwegoplot` itself changes no network and no variable (except those of `generate()`). [nwego](nwego) computes the size and density of every ego network, [nwaltergen](nwaltergen) the composition.

## Examples

- `. nwwebuse lazega, nwclear`
- `. nwegoplot lazega_adv, ego(n41) label(_nwnode) color(officenum) symbol(partner)`
- `. nwegoplot lazega_adv, ego(n41) sortby(officenum) color(officenum) arrowfactor(0)`

- `. nwwebuse glasgow, nwclear`
- `. nwegoplot glasgow1, ego(n2) hop(2)`

## Also see

- psee
- [nwplot](nwplot), [nwego](nwego), [nwaltergen](nwaltergen), [nwcontext](nwcontext)

## Stored results

`nwegoplot` stores the following in `r()`:

- **Scalars**
- **`r(alters)`** --- number of nodes drawn besides ego
- **Macros**
- **`r(ego)`** --- name of ego

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
