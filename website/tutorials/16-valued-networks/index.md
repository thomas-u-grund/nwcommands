---
title: "Tutorial 16: Valued Networks"
parent: "nwcommands (core)"
nav_order: 17
description: "Networks whose ties carry numbers: how a network becomes valued, how degree, clustering and betweenness use the values by default, the binary option, and dichotomizing at a cutoff."
---

# Tutorial 16: Valued Networks

Ties often come with a number: how many e-mails two people exchanged, how strongly a friendship is rated, how
much two countries trade. A network whose ties carry such numbers is **valued**. This tutorial shows how to make
one, how the analysis commands use the values, and how to get back to a plain present/absent network. The full rules,
command by command, are on the reference page [valued networks](../../nwcommands/valued-networks/); the script of
this tutorial is [`example.do`](example.do) and the complete output [`example.log`](example.log).

## Making a valued network

nwcommands keeps a **valued flag** with every network, set when the network is created and not worked out again
from the numbers. Give `nwfromedge` a third variable, the tie value, and the network is valued:

```stata
. input str5 ego str5 alter int mails
. nwfromedge ego alter mails, name(mailnet) directed

. nwsummarize mailnet
--------------------------------------------------
   Network name:  mailnet
   Network id:  6
   Directed: true
   Valued: true
   Two-mode: false
   Nodes: 4
   Selfloop: false
   Arcs: 5
   Minimum value:  0
   Maximum value:  12
   Density:  .417
   Temporal: false
```

(The five rows are Ann → Bob 12, Ann → Cy 1, Bob → Cy 5, Cy → Dee 2 and Dee → Ann 7; the full input is in the
script.) Without the third variable the same edge list gives `Valued: false`. Networks that come with the core can
be valued too: the liking ranks of Sampson's monks, symmetrized, give a valued undirected network with the
values 0 (no tie) to 3:

```stata
. nwwebuse sampson, nwclear

. nwsymmetrize samplike, generate(likes)

. nwsummarize likes
--------------------------------------------------
   Network name:  likes
   Network id:  5
   Directed: false
   Valued: true
   Two-mode: false
   Nodes: 18
   Selfloop: false
   Edges: 60
   Minimum value:  0
   Maximum value:  3
   Density:  .392
   Temporal: false
```

## Commands that use the values

For a measure that has a weighted form in R, the command uses the tie values **by default** and says so in its
output. Degree becomes **strength**, the sum of the tie values of a node:

```stata
. nwdegree likes, generate(strength)
----------------------------------------
  Network name: likes
----------------------------------------
  (valued network: degree is the strength, the sum of the tie values; binary gives the number of ties)
    Degree distribution

   strength |      Freq.     Percent        Cum.
------------+-----------------------------------
          9 |          1        5.56        5.56
         10 |          3       16.67       22.22
         11 |          2       11.11       33.33
         12 |          1        5.56       38.89
         13 |          6       33.33       72.22
         14 |          2       11.11       83.33
         18 |          1        5.56       88.89
         22 |          1        5.56       94.44
         23 |          1        5.56      100.00
------------+-----------------------------------
      Total |         18      100.00
  Mean number of ties (out): 6.667   mean strength (out): 13.44

   Degree centralization: .632
```

The option `binary` ignores the values and counts ties; it is the same option in all commands that use values:

```stata
. nwdegree likes, generate(ties) binary
----------------------------------------
  Network name: likes
----------------------------------------
  (valued network, tie values not used: degree is the number of ties)
    Degree distribution

       ties |      Freq.     Percent        Cum.
------------+-----------------------------------
          4 |          1        5.56        5.56
          5 |          4       22.22       27.78
          6 |          5       27.78       55.56
          7 |          3       16.67       72.22
          8 |          3       16.67       88.89
         10 |          1        5.56       94.44
         11 |          1        5.56      100.00
------------+-----------------------------------
      Total |         18      100.00
  Mean number of ties (out): 6.667   mean strength (out): 13.44

   Degree centralization: .287
```

The two answers are not the same: the monks have 4 to 11 ties and strengths from 9 to 23, and the
centralization is .63 with strength but .29 with the number of ties. Which one is right depends on the question
(is a person who has a few strong ties as central as one with many weak ones?). `alpha()` in `nwdegree` sets how
much to weigh the strength against the number of ties (Opsahl et al. 2010); `alpha(0)` is the same as `binary`.

Distance-based measures read a larger value as a *stronger* tie, hence a shorter step: a step along a tie of
value *w* costs 1/*w*^alpha. `nwbetween` prints this in its heading:

```stata
. nwbetween likes, generate(wbtw) silent
----------------------------------------
  Network name: likes
----------------------------------------
    Betweenness centrality
    (shortest paths weighted by tie values: step cost 1/value^alpha, alpha = 1)

. nwbetween likes, generate(bbtw) binary silent

. correlate wbtw bbtw
(obs=18)

             |     wbtw     bbtw
-------------+------------------
        wbtw |   1.0000
        bbtw |   0.7912   1.0000
```

Weighted and binary betweenness are correlated at .79: they rank many monks alike but not all. (Other
conventions treat weights as distances; `alpha(-1)` reads the values that way and reproduces the igraph result.)
Measures with their own option, such as `nwclustering` (`measure(binary)`), follow the same logic:

```stata
. nwclustering likes, generate(wclu) silent

. nwclustering likes, generate(bclu) measure(binary) silent

. summarize wclu bclu

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
        wclu |         18    .5075819    .1789176       .225   .8888889
        bclu |         18    .4925926      .17616         .2   .8333333
```

A measure that has *no* weighted form (cliques, components, k-cores, mixing, dyad and triad censuses and others)
treats every tie as present and prints `(note: tie values are ignored; this measure is binary)` once. You have
seen the note in [Tutorial 10](../10-cohesion-subgroups/) and [Tutorial 12](../12-triads-motifs/).

## Back to a binary network: `nwdichotomize`

To apply the binary measures to the strong ties only, dichotomize at a threshold of your choosing: values at or
above it become 1, all others 0. With `generate()` the original remains:

```stata
. nwdichotomize likes, threshold(2) generate(likes2)
(120 changes made to likes)

. nwsummarize likes2
--------------------------------------------------
   Network name:  likes2
   Network id:  6
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 18
   Selfloop: false
   Edges: 37
   Minimum value:  0
   Maximum value:  1
   Density:  .242
   Temporal: false
```

Of the 60 ties, 37 have a value of at least 2; the new network is no longer valued. Keep the
threshold in the write-up, because results can depend on it, and compare a few cutoffs.

## Which approach when?

| You want | Do |
|---|---|
| Strengths to count (weighted degree, distance, clustering) | do nothing: valued networks use the values by default |
| Presence only, for a command that has a weighted form | add `binary` (or `measure(binary)` where the command has one) |
| A measure with no weighted form on the strong ties only | `nwdichotomize ..., threshold()` first |
| A binary matrix that should count as valued, or the reverse | `nwset, valued` / `unvalued`, or `nwname netname, newvalued(true)` |
