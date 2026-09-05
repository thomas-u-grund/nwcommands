---
title: "Core Concepts"
parent: Tutorials
nav_order: 2
description: "What a network is in nwcommands: the current-network model, netname/netlist, and working alongside ordinary Stata variables."
---

# Core Concepts

Ordinary Stata holds one dataset in memory at a time. nwcommands adds a second kind of object
alongside it — a **network** — and, unlike a dataset, you can have several networks loaded at
once. This tutorial covers the model that makes that work: netnames, the current network, and
how networks and your ordinary Stata variables share the same session without getting in each
other's way.

## Multiple networks, one current network

Loading a network doesn't clear anything — some datasets even declare more than one network at
once. The Florentine families data (a classic small-network teaching example) ships with two:
a marriage-tie network and a business-tie network.

```stata
. nwwebuse florentine

. nwset
(2 networks)
--------------------
      flobusiness
      flomarriage
```

Every command that takes a network defaults to whichever one you touched most recently — the
**current network**. `nwcurrent` reports it, and switches it when given a name:

```stata
. nwcurrent
----------------------------------------
   Current network:  flomarriage
   Number of nodes:  16
----------------------------------------

. nwcurrent flobusiness
----------------------------------------
   Current network:  flobusiness
   Number of nodes:  16
----------------------------------------

. nwcurrent
----------------------------------------
   Current network:  flobusiness
   Number of nodes:  16
----------------------------------------
```

That last call takes no argument — it's just asking "which one is current now" — and correctly
still reports `flobusiness`, since nothing has changed it since the previous call.

## netlist: referring to several networks at once

A **netname** is just what a network is called (`flomarriage`, `glasgow1`, whatever you name it).
A **netlist** extends that to *patterns* — useful once a dataset has more than a couple of
networks. `glasgow` is a three-wave friendship network among the same 50 pupils, loaded as three
separate networks:

```stata
. nwwebuse glasgow, nwclear

. nwset
(3 networks)
--------------------
      glasgow1
      glasgow2
      glasgow3
```

The following four calls are all equivalent — an explicit list, a `first-last` range, a `*`
wildcard, and the `_all` keyword:

```stata
. nwsummarize glasgow1 glasgow2 glasgow3
--------------------------------------------------
   Network name:  glasgow1
   Network id:  1
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 50
   Selfloop: false
   Arcs: 113
   Minimum value:  0
   Maximum value:  1
   Density:  .046
   Temporal: false
--------------------------------------------------
   Network name:  glasgow2
   Network id:  2
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 50
   Selfloop: false
   Arcs: 116
   Minimum value:  0
   Maximum value:  1
   Density:  .047
   Temporal: false
--------------------------------------------------
   Network name:  glasgow3
   Network id:  3
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 50
   Selfloop: false
   Arcs: 122
   Minimum value:  0
   Maximum value:  1
   Density:  .05
   Temporal: false
```

```stata
. nwsummarize glasgow1-glasgow3
```
```stata
. nwsummarize glasg*
```
```stata
. nwsummarize _all
```

Each of those three produces the exact same three-network listing shown above — see
[netlist](../../reference/netlist) for the full pattern syntax (`*`, `?`, `~`, ranges).

## Networks coexist with ordinary Stata variables

A loaded network is a separate object — it doesn't touch your dataset's variables at all, and
your dataset's variables don't touch it. You can `gen` a new variable while a network is loaded,
and it just sits there as an ordinary column, right alongside whatever node-level variables the
dataset already had:

```stata
. nwclear

. nwwebuse florentine

. gen note = "wealthiest families"

. describe

Contains data from https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/florentine.nwdta
 Observations:            16                  
    Variables:             6                  16 May 2019 17:02
------------------------------------------------------------------------------------------------------------------
Variable      Storage   Display    Value
    name         type    format    label      Variable label
------------------------------------------------------------------------------------------------------------------
_nwnode         str12   %12s                  
_nwinclude      float   %9.0g                 
wealth          float   %9.0g                 
priorates       float   %9.0g                 
seat            float   %9.0g                 
note            str19   %19s                  
------------------------------------------------------------------------------------------------------------------
Sorted by: 
     Note: Dataset has changed since last saved.

. list note in 1

     +---------------------+
     |                note |
     |---------------------|
  1. | wealthiest families |
     +---------------------+
```

`_nwnode` (the node label for each row) and `_nwinclude` came with the dataset; `wealth`,
`priorates`, and `seat` are real node-level attributes from the original study; `note` is the
one we just added. The network itself (`flomarriage`/`flobusiness`, still loaded) isn't
represented as columns at all — it lives as its own object, which is exactly why building or
analyzing a large network never has to spend Stata's own variable budget unless you deliberately
load it as variables (see [nwload](../../reference/nwload)).
