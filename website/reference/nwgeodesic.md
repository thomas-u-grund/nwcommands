---
title: "nwgeodesic"
parent: "Command reference"
nav_exclude: true
search_exclude: false
---

# `nwgeodesic`

## Syntax

```stata
nwgeodesic 
[netname]
[,
unconnected(int)
alpha(real)
sym
symopt(options)
name(string)
nwreplace
generate(newvarname)
xvars
force]
```

| | |
|---|---|
| `unconnected(int)` | Define the length of the path between two unconnected nodes |
| `alpha(real)` | Deal with valued networks |
| `sym` | Calculate distances from symmetrized network |
| `symopt(options)` | Options controlling the symmetrization when `sym` is specified (see [nwsym](nwsym.md)) |
| `name`(*[newnetname](newnetname.md)*) | Name of the new distance network; default = *_geodesic* |
| `nwreplace` | Overwrite existing network *newnetname* |
| `generate(newvarname)` | Name of the Stata variable that stores each node's eccentricity; if omitted, eccentricity is not computed as a Stata variable at all (it is still available via **r(radius)**, the network-wide minimum) |
| `xvars` | Generate Stata variables for the network |
| `force` | force distance calculation on a valued network exceeding 100 nodes (potentially slow; not required otherwise) |

## Description

`nwgeodesic` calculates the shortest paths (also known as geodesic distances) between all nodes *i* and *j*, the average shortest path length and the diameter of the (un-)weighted network [netname](netname.md) according to Opsahl et al. (2010). The matrix of distances is saved as a new network called [newnetname](newnetname.md) (default: *geodesic*).

With option `sym` the distances are calculated from the symmetrized network. Option `symopt()` allows control over the symmetrization (see options in [nwsym](nwsym.md)).

`nwgeodesic`'s primary output is the distance network itself (`name()`); the network's *radius* (the smallest node eccentricity across the whole network) is always returned as **r(radius)**, regardless of `generate()`. If `generate()` is also given, `nwgeodesic` additionally stores each node's own *eccentricity* - the length of the longest shortest path from that node to any other node - as a Stata variable under that name; omit `generate()` to skip this per-node variable entirely (unlike most other nwcommands `generate()` options, there is no default name - eccentricity is a secondary, opt-in output here, not this command's main purpose). Like the diameter, both **r(radius)** and a node's eccentricity are undefined (**r(radius) = -1**; missing for the node) when the network has unconnected pairs and **unconnected()** was not specified. An existing *generate()* variable is overwritten when **nwreplace** is specified (there is no separate **replace** option for just the variable).

By default, the distance between two unconnected nodes *i* and *j*, i.e. there is no path that connects node *i* with node *j*, is set to missing. Non-existent paths are excluded from the calculation of the average shortest path length (unless option **unconnected()** is specified).

The option **unconnected(max)** sets the distance of non-connected nodes to the maximum distance observed in the network plus 1.

Following Opsahl et al. (2010) the shortest path between node *i* and node *j* for a given *alpha* is defined as:

*d_w_alpha(i,j) = min (1 / w_ih^alpha + ... + 1 / w_hj^alpha )*

where *w_ih* is the weight (value) of the tie between node *i* and node *h*. When ***alpha* = 1** this formula reduces to:

*d_w_alpha(i,j) = min (1 / w_ih + ... + 1 / w_hj)*

which is essentially what Newman (2001) and Brandes (2001) suggested. This simply equates the distance between two nodes with the inverse of the weight of the tie that connects them. Such a solution for dealing with valued networks, however, does not explicitly account for the number of steps that need to be taken to connect to nodes. In contrast, Opsahl et al. (2010) allows giving different weight to longer and shorter paths. When ***alpha* = 0** the formula above ignores tie weights.

## Supported network types

Binary: yes. Directed: yes - symmetrized by default (matching [nwcloseness](nwcloseness.md)/[nwkatz](nwkatz.md)'s own identical convention), `sym`/`nosym` control it explicitly. Weighted: yes, via `alpha()` - tie strength is inverted into a path cost via the Opsahl et al. formulation (higher tie value = shorter effective distance), not used directly as distance. Signed: not checked. Two-mode: not checked.

## Stored results

**Scalars**

- **r(nodes)** number of nodes
- **r(numpaths)** number of shortest paths
- **r(diameter)** network diameter
- **r(radius)** network radius (minimum node eccentricity)
- **r(avgpath)** average shortest path length

**Macros**

- **r(symmetrized)** calculated on symmetrized network
- **r(netname)** name of the original network
- **r(netname)** name of the new distance network

## References

Brandes, U. (2001). A faster algorithm for betweenness centrality. *Journal of Mathematical Sociology* 25, 163–177.

Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. *Social Networks* 32 (3), 245-251.

Newman, M. E.J. (2001). Scientific collaboration networks. II. Shortest paths, weighted networks, and centrality. *Physical Review E* 64, 016132.

## See also

- [nwcloseness](nwcloseness.md), [nwreach](nwreach.md), [nwpath](nwpath.md), [nwcomponents](nwcomponents.md)

- last certified : 24 Aug 2026
