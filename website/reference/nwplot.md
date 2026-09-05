---
title: "nwplot"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Plot a network"
---

# `nwplot`

Plot a network

## Syntax

```stata
nwplot
[netname] 
[if]
[, node_options
label_options
edge_options
arrow_options
layout_options
other_options
export_options
twoway_options]
```

| | |
|---|---|
| `size`(*`varname`* [,*[node_sub](nwplot.md)*]) | size of the nodes |
| `labelopt`(*`marker_label_options`*) | options for look of node labels (e.g. size, color) |

## Description

This command plots a network. It gives a lot of flexibility to control all elements in a network plot. Furthermore, it is compatible with **schemes()** and accepts all `twoway_options`.

This example generates a random network and plots it. Because no [netname](netname.md) is given, the command refers to the [current network](nwcurrent.md).

```stata
. nwclear
. nwrandom 20, prob(.2)
. nwplot
```
One can change the layout where nodes should be plotted:

```stata
. nwplot, layout(mds)
. nwplot, layout(circle)
. nwplot, layout(grid)
. nwplot, layout(grid, columns(20))
. nwplot, layout(kk)
. nwplot, layout(hierarchy)
. nwplot, layout(bipartite)
. nwplot, layout(bipartite, vertical)
```
Or obtain coordinates from layout and plot with coordinates. The option **nodexy** can be used to write your own network layout functions, return coordinates and plot a network with these coordinates. Because `generate()` and `nodexy()` are a matched pair - one exports the node coordinates a layout produced, the other forces a later plot to reuse them - this is also how to plot several different networks (e.g. the same set of people observed at several waves) at identical node positions, so the reader can compare panels directly instead of re-deriving a fresh, unrelated layout for each one:

```stata
. nwplot, gen(xcoord ycoord)
. replace xcoord = .2 if _n < 5
. nwplot, nodexy(xcoord ycoord)
```
```stata
. * fixed coordinates across two waves of the same network
. nwplot wave1, generate(x1 y1)
. nwplot wave2, nodexy(x1 y1)
```
`interactive` opens the plot in a browser alongside the usual static plot: drag nodes to reposition them, edit the color/shape legend (an edit applies to every node sharing that color/ shape key, not just one node - the same discrete legend model `color()`/`symbol()` already use), edit the edge color/pattern legend the same way, and adjust node-size/edge-width factors with two sliders. Two buttons in the browser save the edits as CSV files; feed them back with `importcoords()` (paired with `nodexy()`, same matched-pair idea as `generate()`/ `nodexy()` above) and `edgeimport()`:

```stata
. nwplot flomarriage, generate(x y) color(wealth) interactive
. * drag nodes / edit the legend in the browser, then save both CSVs, then:
. nwplot flomarriage, nodexy(x y) importcoords("nodes.csv") edgeimport("edges.csv") color(wealth)
```
`importcoords()`/`edgeimport()` must be run against the same network, same size, as the `interactive` view they came from (row order is how nwplot matches an edit back to a node/tie, the same way `nodexy()`/`label()` already do) - re-export from `interactive` rather than reusing an old CSV after the network or an `if`/`in` restriction changes. Node size is not yet individually editable in the interactive view; the size-factor slider maps onto `nodefactor()` instead.

Arrow heads are plotted when a network is directed. Furthermore, the command notices if a dyad is mutually or asymmetrically connected (see [nwdyads](nwdyads.md)). By default, asymmetrically connected dyads are represented as a straight line, whereas mutually connecetd dyads are represented as two curved lines. However, one can overwrite this and show all ties as curved lines.

```stata
. nwplot, arcstyle(automatic)
. nwplot, arcstyle(straight)
. nwplot, arcstyle(curved)
. nwplot, arcbend(0.3) arcsplines(20)
```
Almost all elements in a network plot can be easily made bigger or smaller using factors:

```stata
. nwplot, nodefactor(2)
. nwplot, edgefactor(2)
. nwplot, arrowfactor(4)
. nwplot, arrowbarbfactor(.2)
```
```stata
. nwplot, nodefactor(2) edgefactor(4) arrowfactor(2) arrowbarbfactor(.2)
```
Colors, symbols and size of nodes can be changed accoring to a `varname`. Furthermore, the palettes used for display can be changed as well.

```stata
. nwwebuse glasgow, nwclear
. nwplot glasgow1, color(smoke1)
. nwplot, color(smoke1, colorpalette(red yellow cyan))
```
```stata
. nwplot glasgow1, symbol(sport1)
. nwplot glasgow1, symbol(sport1, symbolpalette(T S))
```
```stata
. nwplot glasgow1, size(alcohol1)
. nwplot, size(alcohol1, forcekeys1(1 5 10 20))
```
```stata
. nwplot glasgow1, size(alcohol1) color(smoke1) symbol(sport1)
```
nwcommands ships three schemes purpose-built for network plots - s1network, s2network, and s3network - each giving node fill and edge line colors that are visually distinct by default (an ordinary Stata scheme such as the default **stcolor** typically does not, since a single data series' marker and connecting line usually should match - reasonable for an ordinary statistical graph, not for a network plot). `nwplot` defaults to **s1network** unless `scheme()` is specified explicitly.

```stata
. nwplot, scheme(s1network)
. nwplot, scheme(s2network)
. nwplot, scheme(s2mono)
```
```stata
. nwplot, size(alcohol3) color(smoke3) symbol(sport3) scheme(s1network)
```
```stata
. nwplot, size(alcohol3) color(smoke3) symbol(sport3) scheme(economist)
. set scheme s2network
```
This example calculates the shortest path between two nodes (medici and peruzzi) and uses this path to color the edges of the original network and change the size of the edges on this path.

```stata
. nwwebuse florentine, nwclear
. nwpath flomarriage, ego(medici) alter(peruzzi) generate(sp)
```
```stata
. nwplot flomarriage, edgecolor(sp_1, legendoff) edgesize(sp_1, legendoff) edgefactor(5)
```
Another example that changes the size and color of edges.

```stata
. nwwebuse gang, nwclear
. nwplot
. nwplot gang, edgesize(gang)
. nwgenerate blood = (gang==4)
. nwplot blood
. nwplot gang, edgesize(gang) edgecolor(blood)
```
This is how to control the legend of the plot. All options that can be used for twoway legends are valid.

```stata
. nwplot gang, size(Arrests, forcekeys(5 10 20)) legendopt(on pos(3) cols(1))
```
Because nwplot uses twoway plots one can  use all general twoway options to e.g. control the title of a plot.

```stata
. nwwebuse florentine, nwclear
```
```stata
. nwplot flomarriage, edgecolor(flobusiness) title("Florentine Marriages", color(red) size(huge))
```
Here, the nodes are plotted with the node labels saved with the network:

```stata
. nwplot flobusiness, lab
```
More generally, one can use any *varname* as node labels. The next example, does the same as the previous command, but shows how one could use node labels stored elsewhere:

```stata
. nwplot flobusiness, label(wealth)
```
The look and feel of node labels is changed with labelopt():

```stata
. nwplot flobusiness, label(wealth) labelopt(mlabsize(huge) mlabcolor(red))
```
The command draws on normal scatter plots to plot nodes. Once can send all sorts of options directly to these underlying scatter plots. Here, the color and symbol of nodes is overwritten.

```stata
. nwplot flomarriage, scatteropt(mfcolor(green) msymbol(D))
. nwplot flomarriage, lineopt(lwidth(10) lcolor(green))
```
The next example shows how to only plot the largest component of the network.

```stata
. nwwebuse glasgow, nwclear
. nwcomponents glasgow1, lgc generate(large)
. nwplot glasgow1 if large == 1
```
Alternative to display the largest component only:

```stata
. nwwebuse glasgow, nwclear
. nwplot glasgow1, layout(,lgc)
```
**Publication-quality vector export.** `export()` saves the plot directly to a file, inferring the format from the extension - exactly what a manual `graph export` call afterward would do, since `nwplot` produces an ordinary Stata graph and never replaces or bypasses it. SVG and PDF are both scalable vector formats: the plot stays crisp at any zoom level or print size, and both open cleanly in standard vector-graphics editors (e.g. Adobe Illustrator, Inkscape) for further touch-up - node/edge/label elements remain separate, editable objects rather than a fixed-resolution image.

```stata
. nwplot flomarriage, export("flomarriage.svg")
. nwplot flomarriage, export("flomarriage.pdf") replace
```
Raster formats (PNG, TIF, ...) are also supported the same way; `exportopt()` passes options straight through to the underlying `graph export` call, most commonly `width()`/`height()` to control resolution:

```stata
. nwplot flomarriage, export("flomarriage.png") exportopt(width(2000))
```
The graph itself is unaffected by `export()` - it remains the normal, currently active Stata graph afterward, so the Graph Editor, stata graph save, and a second `graph export` in a different format all continue to work exactly as they would without `export()`.

## Supported network types

Binary: yes. Weighted: yes (via `edgesize()`/`edgecolor()` - see the shortest-path example above). Directed: yes - this is the command's native case; arrows are drawn automatically, and reciprocated (mutual) dyads are curved apart from their asymmetric counterparts by default (`arcstyle(automatic)`) so both directions of a tie remain visible rather than overlapping. Undirected: yes, the default. Two-mode: the command plots a two-mode network's nodes and ties correctly (it has no bipartite-specific logic, but a bipartite network's ties are simply a subset of the same one-mode adjacency structure every other network uses) - the two modes are not visually distinguished automatically, though; pass the network's own `get_modes()`-derived mode variable to `color()` or `symbol()` to tell them apart at a glance (e.g. `nw2degree`'s own output, or any variable holding "1"/"2" per node). Self-loops: not rendered - a self-loop currently has no visible effect on the plot (a zero-length tie), a known limitation recorded in the package's own visualization roadmap rather than fixed here.

## Stored results

`nwplot` is `rclass`.

- Macros:
- **r(export)** filename actually passed to `export()`, if specified

## See also

- [nwplotmatrix](nwplotmatrix.md)
