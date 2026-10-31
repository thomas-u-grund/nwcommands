---
title: "Tutorial 8: Centrality"
parent: "nwcommands (core)"
nav_order: 9
description: "Degree, betweenness, closeness, eigenvector, PageRank, and Katz centrality."
---

# Tutorial 8: Centrality

"How central is this node?" has more than one answer — each of nwcommands' six centrality
commands captures a different notion of importance. This tutorial runs all six on the same
network, the Florentine marriage network, so the different rankings can be compared directly.

## Degree

`nwdegree` counts a node's direct ties:

```stata
. nwwebuse florentine, nwclear

. nwdegree flomarriage, generate(deg)
----------------------------------------
  Network name: flomarriage
----------------------------------------
    Degree distribution

        deg |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          1        6.25        6.25
          1 |          4       25.00       31.25
          2 |          2       12.50       43.75
          3 |          6       37.50       81.25
          4 |          2       12.50       93.75
          6 |          1        6.25      100.00
------------+-----------------------------------
      Total |         16      100.00

   Degree centralization: .267
```

## Betweenness

`nwbetween` counts how often a node sits on the shortest path between two other nodes — a
measure of "brokerage" rather than direct connectivity:

```stata
. nwbetween flomarriage, generate(btw)
----------------------------------------
  Network name: flomarriage
----------------------------------------
    Betweenness centrality

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         btw |         16        9.75    12.30056          0       47.5
```

## Closeness

`nwcloseness` measures how short a node's paths are to everyone else in the network:

```stata
. nwcloseness flomarriage, generate(clo far near)
Warning: network flomarriage is not connected; closeness uses only the nodes each node can
>  reach (as igraph). Specify unconnected() to give missing paths a length.
----------------------------------------
  Network name: flomarriage
----------------------------------------
    Closeness centrality

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         clo |         15    .4150955    .0748436   .2857143        .56
         far |         16      32.625    10.73235          0         49
        near |         15    .0296497     .005346   .0204082        .04
```

`clo` has one fewer observation than `far` - the isolated node (`pucci`, with degree 0 above)
has no path to anyone, so closeness is undefined for it even though farness (`.` for an
unreachable pair contributes nothing) still computes.

The Florentine marriage network is not connected, and the warning says what the program then
does: as `igraph` does, `nwcloseness` computes each node's closeness from the nodes it can
reach, instead of giving every node outside its component an infinite distance. Add
`unconnected()` to give the missing paths a length instead (`legacy` gives the formula of earlier releases). A valued network is a second case:
`nwcloseness` then uses the tie values as path lengths by default, and the option `binary` gives
the result for the bare ties (see [valued networks](/nwcommands/valued-networks/)).

## Eigenvector

`nwevcent` scores a node higher when its neighbors are themselves well-connected, not just by
raw neighbor count:

```stata
. nwevcent flomarriage, generate(evc)
----------------------------------------
  Network name: flomarriage
----------------------------------------
    Eigenvector centrality
   (calculated on symmetrized network)

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         evc |         16    .2189135    .1246942   1.90e-34   .4303081
```

## PageRank

`nwpagerank` is the stationary distribution of a random surfer who follows outgoing ties (with
probability `damping()`, default 0.85) or jumps to a uniformly random node otherwise. Unlike
eigenvector centrality, it works natively on directed networks and always produces a unique,
well-defined score even where eigenvector centrality would refuse:

```stata
. nwpagerank flomarriage, generate(pgr)
----------------------------------------
  Network: flomarriage
  Damping: .85
----------------------------------------

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         pgr |         16       .0625    .0322572    .009901   .1443735
```

## Katz

`nwkatz` extends degree centrality by also counting nodes reachable at distance 2, 3, ... away,
penalizing each by how far away it is:

```stata
. nwkatz flomarriage, generate(ktz)
----------------------------------------
  Katz centrality (shortest-path distance-decay)
  Network name: flomarriage
       Network has been symmetrized for calculation.
----------------------------------------
       Alpha: 1

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         ktz |         16      13.125         3.5          0         14
```

## The measures don't always agree

Sort by betweenness, and `medici` comes out clearly on top - well ahead of the next node, and by
a wider margin than its degree alone would suggest:

```stata
. gsort -btw

. list _nwnode deg btw in 1/5

     +---------------------------+
     |  _nwnode   deg        btw |
     |---------------------------|
  1. |   medici     6       47.5 |
  2. | guadagni     4   23.16667 |
  3. |  albizzi     3   19.33333 |
  4. | salviati     2         13 |
  5. |  ridolfi     3   10.33333 |
     +---------------------------+
```

`medici` does have the highest degree here too, but the *gap* to second place is far larger for
betweenness (47.5 vs. 23.2, roughly double) than for degree (6 vs. 4) - consistent with the
historical account of the Medici as brokers sitting between otherwise-separate factions, not
merely the family with the most marriage ties. Looking at every measure for `medici` at once:

```stata
. format clo evc pgr ktz %6.3f

. list _nwnode deg btw clo evc pgr ktz if _nwnode == "medici"

     +-------------------------------------------------------+
     | _nwnode   deg    btw     clo     evc     pgr      ktz |
     |-------------------------------------------------------|
  1. |  medici     6   47.5   0.560   0.430   0.144   14.000 |
     +-------------------------------------------------------+
```

`medici` tops every measure here - but that won't always be true for every node in every
network. Which measure is "right" depends entirely on what kind of influence you're actually
asking about: direct access (degree), control over information flow between others
(betweenness), efficiency of reach (closeness), prestige-by-association (eigenvector, PageRank),
or penalized total reach (Katz).

On a valued network, degree (as strength), betweenness and closeness use the tie values by
default and the option `binary` gives the result for the bare ties; the [network types](/nwcommands/network-types/)
page lists, for every command, what it does with valued, two-mode and directed networks.
