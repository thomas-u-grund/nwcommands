---
title: "Tutorial 9: Paths & Ego Networks"
parent: "nwcommands (core)"
nav_order: 10
description: "Geodesics, reachability, and ego-network extraction."
---

# Tutorial 9: Paths & Ego Networks

Beyond a single shortest path between two named nodes (covered in
[Visualization](../05-visualization) via `nwpath`), this tutorial covers three ways of
characterizing a network's overall path structure and each node's own local neighborhood.

## Geodesics

`nwgeodesic` computes the shortest-path distance between *every* pair of nodes at once, saving
the result as a new network:

```stata
. nwwebuse florentine, nwclear

. nwgeodesic flomarriage, name(flodist) generate(ecc)
----------------------------------------
  Network name: flomarriage
  Network of shortest paths: flodist
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

Average shortest path length, diameter, and radius all come back undefined here because
`flomarriage` has an isolated node (`pucci`, met already in
[Manipulating Networks](../07-manipulating-networks)) with no path to anyone. `nwsummarize` on the
new distance network shows every pairwise distance directly:

```stata
. nwsummarize flodist, mat
--------------------------------------------------
   Network name:  flodist
   Network id:  3
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 16
   Selfloop: false
   Edges: 105
   Minimum value:  1
   Maximum value:  5
   Density:  2.49
   Temporal: false
[symmetric]
         1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
     +---------------------------------------------------------------------------------+
   1 |   .                                                                             |
   2 |   2    .                                                                        |
   3 |   2    2    .                                                                   |
   4 |   4    2    3    .                                                              |
   5 |   3    3    1    2    .                                                         |
   6 |   3    1    3    3    4    .                                                    |
   7 |   3    1    3    1    3    2    .                                               |
   8 |   4    2    4    2    4    3    1    .                                          |
   9 |   1    1    1    3    2    2    2    3    .                                     |
  10 |   3    3    3    5    4    4    4    5    2    .                                |
  11 |   4    3    2    1    1    4    2    3    3    5    .                           |
  12 |   .    .    .    .    .    .    .    .    .    .    .    .                      |
  13 |   2    2    2    2    2    3    2    3    1    3    2    .    .                 |
  14 |   2    2    2    4    3    3    3    4    1    1    4    .    2    .            |
  15 |   3    3    2    1    1    4    2    3    2    4    1    .    1    3    .       |
  16 |   2    2    2    2    3    3    1    2    1    3    3    .    1    2    2    .  |
     +---------------------------------------------------------------------------------+
```

Row/column 12 (`pucci`) is entirely missing, confirming it's unreachable from everyone else.
`generate()` (optional here — `nwgeodesic`'s main output is the distance network itself) adds each
node's *eccentricity*: the length of its own single longest shortest path.

```stata
. gsort -ecc _nwnode

. list _nwnode ecc in 1/5

     +--------------------+
     |      _nwnode   ecc |
     |--------------------|
  1. |     bischeri     5 |
  2. | lamberteschi     5 |
  3. |        pazzi     5 |
  4. |      peruzzi     5 |
  5. |   acciaiuoli     4 |
     +--------------------+
```

On a valued network `nwgeodesic` and `nwpath` use the tie values as distances by default; the
option `binary` gives the number of steps instead (see [valued networks](/nwcommands/valued-networks/)).
Which network types each command accepts is tabulated on the page
[network types](/nwcommands/network-types/).

## Reachability

Sometimes the exact distance doesn't matter — only whether a path exists *at all*. `nwreach`
collapses the geodesic calculation down to a plain 0/1 network:

```stata
. nwreach flomarriage, sym name(floreach)

. nwsummarize floreach, mat
--------------------------------------------------
   Network name:  floreach
   Network id:  4
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 16
   Selfloop: false
   Edges: 105
   Minimum value:  0
   Maximum value:  1
   Density:  .875
   Temporal: false
[symmetric]
         1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
     +---------------------------------------------------------------------------------+
   1 |   .                                                                             |
   2 |   1    .                                                                        |
   3 |   1    1    .                                                                   |
   4 |   1    1    1    .                                                              |
   5 |   1    1    1    1    .                                                         |
   6 |   1    1    1    1    1    .                                                    |
   7 |   1    1    1    1    1    1    .                                               |
   8 |   1    1    1    1    1    1    1    .                                          |
   9 |   1    1    1    1    1    1    1    1    .                                     |
  10 |   1    1    1    1    1    1    1    1    1    .                                |
  11 |   1    1    1    1    1    1    1    1    1    1    .                           |
  12 |   0    0    0    0    0    0    0    0    0    0    0    .                      |
  13 |   1    1    1    1    1    1    1    1    1    1    1    0    .                 |
  14 |   1    1    1    1    1    1    1    1    1    1    1    0    1    .            |
  15 |   1    1    1    1    1    1    1    1    1    1    1    0    1    1    .       |
  16 |   1    1    1    1    1    1    1    1    1    1    1    0    1    1    1    .  |
     +---------------------------------------------------------------------------------+
```

Node 12 (`pucci`) is the one row/column of all zeros — the reachability network makes an isolated
node visually obvious even in a network too large to eyeball directly for connectivity.

## Ego networks

`nwego` looks at each node's own local neighborhood in isolation: how many alters does it have
(`sizevar()`), and how interconnected are those alters with *each other*, independent of their
(by definition, universal) ties back to the node itself (`densvar()`). `nwego` matches its results
to the nodes by name, so it does not matter that the `gsort` above changed the order of the
observations:

```stata
. nwego flomarriage, sizevar(egosize) densvar(egodensity)
----------------------------------------
  Network name: flomarriage

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
     egosize |         16         2.5    1.505545          0          6
  egodensity |         11    .2181818    .2192734          0   .6666667

. gsort -egosize _nwnode

. list _nwnode egosize egodensity in 1/8

     +---------------------------------+
     |    _nwnode   egosize   egoden~y |
     |---------------------------------|
  1. |     medici         6   .0666667 |
  2. |   guadagni         4          0 |
  3. |    strozzi         4   .3333333 |
  4. |    albizzi         3          0 |
  5. |   bischeri         3   .3333333 |
     |---------------------------------|
  6. | castellani         3   .3333333 |
  7. |    peruzzi         3   .6666667 |
  8. |    ridolfi         3   .3333333 |
     +---------------------------------+
```

`medici` has by far the largest ego network (6 alters) but one of the *lowest* densities among
them (0.067 — its alters barely know each other) — the same brokerage pattern already visible in
[Centrality](../08-centrality)'s betweenness results, now visible directly as a size/density
trade-off. `peruzzi`, by contrast, has a smaller ego network (3 alters) that's densely
interconnected (0.667) — its contacts mostly already know each other, leaving less room for
`peruzzi` itself to broker between them.
