---
title: "nwgeodesic"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Calculate shortest paths between nodes"
---

# `nwgeodesic`

Calculate shortest paths between nodes

## Syntax

```stata
nwgeodesic 
[netlist]
[,
unconnected(int)
alpha(real)
sym
symopt(options)
name(string)
nwreplace
noreplace
generate(newvarname)
xvars
force
bin:ary
plot
average
gname(string)
saving(filename)
export(filename[, options])
save(filename[, replace])]
```

| | |
|---|---|
| `unconnected(int)` | Define the length of the path between two unconnected nodes |
| `alpha(real)` | Cost of a step along a tie of value w: 1/w^alpha; default 1 on a valued network, 0 (every tie is one step) otherwise |
| `sym` | Calculate distances from symmetrized network |
| `symopt(options)` | Options controlling the symmetrization when `sym` is specified (see [nwsym](nwsym)) |
| `name`(*[newnetname](newnetname)*) | Name of the new distance network; default = *_geodesic* |
| `nwreplace` | Overwrite existing network *newnetname*; the default *_geodesic* is overwritten without it |
| `noreplace` | Do not overwrite the default network *_geodesic* either: stop with an error if it exists |
| `generate(newvarname)` | Name of the Stata variable that stores each node's eccentricity; if omitted, eccentricity is not computed as a Stata variable at all (it is still available via **r(radius)**, the network-wide minimum) |
| `xvars` | Generate Stata variables for the network |
| `force` | the least-cost distances of a valued network are computed natively at any size and `force` is not needed; on a platform without the plugin a valued network of more than 100 nodes stops with r(198) unless `force` (slow Mata routine) or `binary` (count steps) is given; also runs the command although its two n x n matrices would not fit in 12 GB (above about 27,000 nodes) |
| `bin:ary` | Ignore the tie values of a valued network (by default they are used) |
| `plot` | Draw a histogram of the finite geodesic distances (number of pairs at each whole distance); unconnected pairs are counted in a note, not drawn |
| `average` | With `plot`: a dashed line at the mean distance of the connected pairs |
| `gname(string)` | Name for the graph created by `plot`; default = **geodesic** (`name()` names the distance network) |
| `sav:ing(filename)` | Save the graph to a `.gph` file; an existing file is replaced |
| `exp:ort(filename[, options])` | Write the graph with `graph export`; the file extension sets the format |
| `save(`*filename*[`, replace`]`)` | Save the results in a Stata data set, one observation per network; an existing file is replaced (with or without `replace`); see **A list of networks** |

## Description

`nwgeodesic` calculates the shortest paths (also known as geodesic distances) between all nodes *i* and *j*, the average shortest path length and the diameter of the (un-)weighted network [netname](netname) according to Opsahl et al. (2010). The matrix of distances is saved as a new network called [newnetname](newnetname) (default: *_geodesic*).

With option `sym` the distances are calculated from the symmetrized network. Option `symopt()` allows control over the symmetrization (see options in [nwsym](nwsym)).

`nwgeodesic`'s primary output is the distance network itself (`name()`); the network's *radius* (the smallest node eccentricity across the whole network) is always returned as **r(radius)**, regardless of `generate()`. If `generate()` is also given, `nwgeodesic` additionally stores each node's own *eccentricity* - the length of the longest shortest path from that node to any other node - as a Stata variable under that name; omit `generate()` to skip this per-node variable entirely (unlike most other nwcommands `generate()` options, there is no default name - eccentricity is a secondary, opt-in output here, not this command's main purpose). Like the diameter, **r(radius)** is undefined (**r(radius) = -1**) when the network has unconnected pairs and **unconnected()** was not specified; a node's eccentricity is then the longest distance to the nodes it can reach. An existing `generate()` variable is overwritten when **nwreplace** is specified (there is no separate **replace** option for just the variable).

By default, the distance between two unconnected nodes *i* and *j*, i.e. there is no path that connects node *i* with node *j*, is set to missing. The average shortest path length, the diameter and the radius over all pairs are then not defined; the output says so and gives instead the share of pairs that are connected and the average and longest distance over the connected pairs (unless option **unconnected()** is specified).

The option **unconnected(max)** sets the distance of non-connected nodes to the maximum distance observed in the network plus 1.

Following Opsahl et al. (2010) the shortest path between node *i* and node *j* for a given *alpha* is defined as:

*d_w_alpha(i,j) = min (1 / w_ih^alpha + ... + 1 / w_hj^alpha )*

where *w_ih* is the weight (value) of the tie between node *i* and node *h*. When ***alpha* = 1** this formula reduces to:

*d_w_alpha(i,j) = min (1 / w_ih + ... + 1 / w_hj)*

which is essentially what Newman (2001) and Brandes (2001) suggested. This simply equates the distance between two nodes with the inverse of the weight of the tie that connects them. Such a solution for dealing with valued networks, however, does not explicitly account for the number of steps that need to be taken to connect to nodes. In contrast, Opsahl et al. (2010) allows giving different weight to longer and shorter paths. When ***alpha* = 0** the formula above ignores tie weights.

## A list of networks

`nwgeodesic` takes one network or a list of networks (*netlist*; wildcards such as **draw_*** work as in [nwsummarize](nwsummarize)). With a list, every network is analysed with the same options and a table with one row per network is printed (nodes, average path length, diameter, radius, share of connected pairs and the average distance over the connected pairs); one line says how the networks were read (directed networks: distances follow the direction of the ties, or the symmetrized network with `sym`; undirected networks). **r()** holds the results of the last network of the list, exactly as a call for that network alone. The options that make a variable, a network or a graph for one network (`generate()`, `name()`, `xvars`, `plot` with `gname()`, `saving()` and `export()`) are error 198 with a list; call the command once per network for them. The distance network *_geodesic* afterwards holds the distances of the last network.

`save()` writes a Stata data set with one observation per network (also for one network), in the order of the list, with the variables **name** (network name), **directed** and **valued** (0 or 1), **nodes**, **numpaths**, **unconnected** (the number of unconnected pairs), **avgpath**, **diameter**, **radius**, **alpha**, **connected** (the share of pairs that are connected), **avgpath_connected** and **diameter_connected** (over the connected pairs). **avgpath**, **diameter** and **radius** are missing for a network in which not every pair is connected (the single call stores -1 in **r()**); **avgpath_connected** and **diameter_connected** are missing when `unconnected()` replaced the distances of the unconnected pairs. All numeric variables are stored as `double`.

- `. nwrandom 30, prob(.12) undirected name(draw) ntimes(20)`
- `. nwgeodesic draw_*, save(draws)`
- `. use draws, clear`

## Network types

**Directed:** used as directed; `sym` symmetrizes the network first. **Valued:** tie values are used by default: a step along a tie of value w costs 1/w^alpha (`alpha(1)` by default, `alpha(-1)` reads the values as lengths); `binary` (or `alpha(0)`) counts steps. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The breadth-first searches run in the plugin, 128 sources per call (the ties are read once per call). Measured in Stata/BE, random directed network with 10 ties per node: 10,000 nodes 2.7 seconds, 20,000 nodes 10 seconds and 6.4 GB; the result is a dense *n*-by-*n* network. For the sums of the distances alone use [nwcloseness](nwcloseness) or [nwkatz](nwkatz), which do not build the matrix.

The distances of all pairs of nodes are an *n*-by-*n* matrix; two matrices are held at once. Above about 27,000 nodes (12 GB) the command stops at once with r(484), names [nwcloseness](nwcloseness), [nwkatz](nwkatz), [nwcomponents](nwcomponents) and [nwpath](nwpath) as the alternatives for sums of distances, connectedness and single pairs, and `force` runs it anyway.

Weighted distances are computed at any size by the native plugin; on a platform without it a valued network of more than 100 nodes stops with an error unless `force` (slow Mata routine) or `binary` is given.

## Example

```stata
. nwwebuse florentine, nwclear
. nwgeodesic flomarriage

----------------------------------------
  Network name: flomarriage
  Network of shortest paths: _geodesic
----------------------------------------
    Nodes: 16
    Symmetrized : (already undirected)
    ------------------------------------
    Paths: 120
    Unconnected paths:  15
    Average shortest path length:  (not defined)
    Diameter:  (not defined)
    Radius:  (not defined)
```
In this first example, the average shortest path length is not defined because there are 15 non-existent paths. There is one isolate node who cannot connect to any of the other 15 nodes. The next example, makes use of the option **unconnected()** to assign these non-existent paths a certain length. Here, the option **unconnected(max)** assigns them the length 6.

```stata
. nwgeodesic flomarriage, unconnected(max) nwreplace

----------------------------------------
  Network name: flomarriage
  Network of shortest paths: _geodesic
----------------------------------------
    Nodes: 16
    Symmetrized : (already undirected)
    ------------------------------------
    Paths: 120
    Unconnected paths:  15
    Unconnected paths replaced with:  6
    Average shortest path length:  2.925
    Diameter:  6
```
(`nwgeodesic` also reports the network *radius* - the minimum node eccentricity - as an additional line here, and, if `generate()` is specified, stores each node's own *eccentricity* under that name; not reproduced above since it depends on live data.)

## Drawing the distances

`plot` draws, for the pairs of distinct nodes, how many are at distance 1, 2, 3, ... steps (the whole numbers are on the x axis). In an undirected network each pair counts once, in a directed network each ordered pair. Pairs without a path are not distances: their number is in a note under the graph, and `unconnected()` does not enter the histogram. `average` adds the mean distance of the connected pairs, the same number as **r(avgpath)** (or **r(avgpath_connected)** when pairs are unconnected). The network of distances and the displayed table are the same as without `plot`. `gname()` names the graph in memory (`name()` is the distance network), `saving()` writes a `.gph` file and `export()` writes it with `graph export`. Other options go to `twoway` and come last; without `plot` they give an error. `plot` stops with error 198 for a two-mode network and for a valued network whose distances are sums of 1/value^alpha, not step counts (`binary` or `alpha(0)` count steps).

- `. nwgeodesic flomarriage, plot average export(distances.png, width(1000))`

## Stored results

- **Scalars**
- **r(nodes)** --- number of nodes
- **r(numpaths)** --- number of shortest paths
- **r(diameter)** --- network diameter
- **r(radius)** --- network radius (minimum node eccentricity)
- **r(avgpath)** --- average shortest path length (-1 if some pairs are unconnected)
- **r(unconnected)** --- number of unconnected pairs
- **r(alpha)** --- value of *alpha* used (1 on an unvalued network)
- **r(connected)** --- share of pairs connected (only if some are not)
- **r(avgpath_connected)** --- average distance over connected pairs (only if some are not)
- **r(diameter_connected)** --- longest distance over connected pairs (only if some are not)

- **Macros**
- **r(symmetrized)** --- calculated on symmetrized network
- **r(netname)** --- name of the original network
- **r(geodesic)** --- name of the new distance network

## References

Brandes, U. (2001). A faster algorithm for betweenness centrality. *Journal of Mathematical Sociology* 25, 163–177.

Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. *Social Networks* 32 (3), 245-251.

Newman, M. E.J. (2001). Scientific collaboration networks. II. Shortest paths, weighted networks, and centrality. *Physical Review E* 64, 016132.

## See also

- [nwcloseness](nwcloseness), [nwreach](nwreach), [nwpath](nwpath), [nwcomponents](nwcomponents)

---

*nwcommands version 3.35.0, 22 November 2026* ([check your installed version](nwversion))
