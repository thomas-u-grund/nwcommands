---
title: "Manipulating Networks"
parent: Tutorials
grand_parent: "nwcommands (core)"
nav_order: 6
description: "Subsetting, collapsing, symmetrizing, recoding, and dichotomizing."
---

# Manipulating Networks

Once a network is loaded, you'll often need to reshape it before analysis: pull out a subset of
nodes, merge nodes together, drop directionality, or remap tie values. This tutorial covers the
five most common transformations.

## Subsetting

`nwsubset` keeps only the nodes for which an `if` condition on an attribute is true — here, only
the wealthiest Florentine families:

```stata
. nwwebuse florentine, nwclear

. nwsummarize flomarriage
--------------------------------------------------
   Network name:  flomarriage
   Network id:  2
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 16
   Selfloop: false
   Edges: 20
   Minimum value:  0
   Maximum value:  1
   Density:  .167
   Temporal: false

. nwsubset flomarriage if wealth > 50

. nwsummarize flomarriage_sub
--------------------------------------------------
   Network name:  flomarriage_sub
   Network id:  3
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Edges: 1
   Minimum value:  0
   Maximum value:  1
   Density:  .333
   Temporal: false
```

By default the result is named `netname_sub` — 16 nodes down to 3. Unlike the similar-looking
`nwgen flo_sub = flomarriage if wealth > 50`, `nwsubset` also copies over the original network's
node labels.

## Collapsing

`nwcollapse` merges nodes together — the merged node inherits every tie either of the original
nodes had. `by()` specifies which nodes get merged, and the new node is named after that
variable's value:

```stata
. nwrandom 8, prob(.3) name(mynet)

. nwsummarize mynet
--------------------------------------------------
   Network name:  mynet
   Network id:  4
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 8
   Selfloop: false
   Arcs: 24
   Minimum value:  0
   Maximum value:  1
   Density:  .429
   Temporal: false

. gen att = _n

. replace att = 1 in 2
(1 real change made)

. nwcollapse mynet, by(att) generate(mynet_collapsed)
(16 real changes made, 16 to missing)
(2 real changes made)
(8 real changes made)

. nwsummarize mynet_collapsed
--------------------------------------------------
   Network name:  mynet_collapsed
   Network id:  6
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 7
   Selfloop: false
   Arcs: 23
   Minimum value:  0
   Maximum value:  1
   Density:  .548
   Temporal: false
```

Nodes 1 and 2 collapse into one, taking `mynet` from 8 nodes down to 7.

## Symmetrizing

`nwsymmetrize` (an alias for `nwsym`) turns a directed network into an undirected one. By
default (`mode(max)`), a tie exists in either direction if it existed in *either* direction
before:

```stata
. nwwebuse glasgow, nwclear

. nwsummarize glasgow1
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

. nwsymmetrize glasgow1, generate(glasgow1_sym)

. nwsummarize glasgow1_sym
--------------------------------------------------
   Network name:  glasgow1_sym
   Network id:  4
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 50
   Selfloop: false
   Edges: 74
   Minimum value:  0
   Maximum value:  1
   Density:  .06
   Temporal: false

. nwsym glasgow1_sym, check
--------------------------------------------------
   Network name:  glasgow1_sym
   Directed: false
   Symmetric: true
```

113 directed arcs become 74 undirected edges — reciprocated pairs collapse into a single tie.
`mode(min)` instead requires a tie in *both* directions before keeping it, which typically keeps
far fewer ties.

## Recoding

`nwrecode` remaps dyad values according to arbitrary rules — think `recode`, but for tie values
instead of a Stata variable:

```stata
. mata: M = (0,1,3 \ 2,0,1 \ 0,2,0)

. nwset, mat(M) name(scores) directed labs(A,B,C)

. nwsummarize scores, mat
--------------------------------------------------
   Network name:  scores
   Network id:  5
   Directed: true
   Valued: true
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Arcs: 5
   Minimum value:  0
   Maximum value:  3
   Density:  .833
   Temporal: false
       1   2   3
    +-------------+
  1 |  .   1   3  |
  2 |  2   .   1  |
  3 |  0   2   .  |
    +-------------+

. nwrecode scores (1=10) (2=20) (3=30), generate(scores_recoded)
(3 real changes made)
(5 changes made to scores)

. nwsummarize scores_recoded, mat
--------------------------------------------------
   Network name:  scores_recoded
   Network id:  6
   Directed: true
   Valued: true
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Arcs: 5
   Minimum value:  0
   Maximum value:  30
   Density:  .833
   Temporal: false
        1    2    3
    +----------------+
  1 |   .   10   30  |
  2 |  20    .   10  |
  3 |   0   20    .  |
    +----------------+
```

Rules can also cover ranges (`1/5=1`) and handle missing/other values (`missing=9`, `else=44`) —
see [nwrecode](../../reference/nwrecode) for the full rule syntax.

## Dichotomizing

Turning a valued network binary at a single cutoff is common enough to have its own thin
wrapper around `nwrecode`: `nwdichotomize`. Dyads at or above the threshold become 1, everything
else becomes 0:

```stata
. mata: M = (0,150,40 \ 90,0,220 \ 60,30,0)

. nwset, mat(M) name(trade) directed labs(A,B,C)

. nwsummarize trade, mat
--------------------------------------------------
   Network name:  trade
   Network id:  7
   Directed: true
   Valued: true
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Arcs: 6
   Minimum value:  30
   Maximum value:  220
   Density:  1
   Temporal: false
         1     2     3
    +-------------------+
  1 |    .   150    40  |
  2 |   90     .   220  |
  3 |   60    30     .  |
    +-------------------+

. nwdichotomize trade, threshold(100) generate(trade_binary)
(3 real changes made)
(6 changes made to trade)

. nwsummarize trade_binary, mat
--------------------------------------------------
   Network name:  trade_binary
   Network id:  8
   Directed: true
   Valued: true
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Arcs: 2
   Minimum value:  0
   Maximum value:  1
   Density:  .333
   Temporal: false
       1   2   3
    +-------------+
  1 |  .   1   0  |
  2 |  0   .   1  |
  3 |  0   0   .  |
    +-------------+
```

Only the two ties of value ≥ 100 (A→B at 150, B→C at 220) survive as 1; everything else,
including the two below-threshold ties, becomes 0.
