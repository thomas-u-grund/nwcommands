---
title: "Tutorial 12: Triads, Dyads & Motifs"
parent: "nwcommands (core)"
nav_order: 12
description: "The building blocks of network structure: the dyad census and reciprocity, the 16-type triad census, clustering and transitivity, four-node motifs and structural balance in signed networks."
---

# Tutorial 12: Triads, Dyads & Motifs

Many questions about network structure are questions about small pieces: are ties returned (pairs of nodes)? Do
friends of friends become friends (triples)? Which small patterns occur more often than expected (motifs)?
Counting the patterns of two, three and four nodes gives a compact description of a network, and it is the
raw material of the model-based tutorials: reciprocity and transitivity are the first effects of an
[nwsaom](../../nwsaom/) or [nwergm](../../nwergm/) model.

This tutorial uses the "likes" network of Sampson's monks (`samplike`, 18 monks, directed). The script is
[`example.do`](example.do), the complete output [`example.log`](example.log).

## Dyads: the dyad census and reciprocity

A **dyad** is a pair of nodes. In a directed network every dyad is in one of three states: **mutual** (both
nodes name each other), **asymmetric** (only one does) or **null** (neither does). `nwdyads` counts them:

```stata
. nwwebuse sampson, nwclear

. nwdyads samplike
(note: tie values are ignored; this measure is binary)

    Dyad census:  samplike

    Mutual |      Asym |      Null
-----------+-----------+-----------
        28 |        32 |        93
 
    Reciprocity: .467
```

The 18 monks form 153 dyads: 28 mutual, 32 asymmetric, 93 null. The **reciprocity** of .47 is the share of
connected dyads that are mutual, i.e. 28 of 60. Whether that is a lot depends on density; the test for it is a
CUG test as in [Tutorial 18](../18-testing/), or the reciprocity effect of a model.

## Triads: the triad census

A **triad** is a set of three nodes. In a directed network there are 16 ways in which the three possible dyads
can be in the states mutual, asymmetric or null (the "MAN" notation: the number of mutual, asymmetric and null
dyads, plus a letter when the same counts can be arranged in more than one way). `nwtriads` counts all 16 types and
the clustering measures:

```stata
. nwtriads samplike
(note: tie values are ignored; this measure is binary)
----------------------------------------
  Network name: samplike
----------------------------------------
    Measure: binary
    Average clustering coefficient: .44
    Global clustering coefficient: .407
 

    Triad census:  samplike

       003 |       012 |      021D |      021U |
-----------+-----------+-----------+-----------+
       167 |       205 |        12 |        24 |

      021C |      030T |      030C |       102 |
-----------+-----------+-----------+-----------+
        24 |         5 |         0 |       190 |

      120D |      120U |      120C |      111D |
-----------+-----------+-----------+-----------+
        15 |         6 |         5 |        68 |

      111U |       201 |       210 |       300 |
-----------+-----------+-----------+-----------+
        34 |        35 |        18 |         8 |

     Transitivity: .407
```

The 16 counts add up to all 816 triples of 18 monks. A few types to know:

* `003` has no ties, `012` has a single arc: these two are most frequent in sparse networks.
* `030T` is the **transitive triad** (a → b → c and a → c), the typical result of "a friend of a friend is a
  friend"; `030C` is the **cycle** (a → b → c → a), which a hierarchy avoids. The monks have 5 transitive triads
  and no cyclic one.
* `300` is the complete triad, with all three dyads mutual (8 of them): the cliques of mutual friends.

The two clustering coefficients that `nwtriads` reports summarize closure in one number:

* The **global clustering coefficient** (transitivity, .41) is the share of connected triples (a node and two
  of its contacts) that are closed.
* The **average clustering coefficient** (.44) is the mean of the node-level coefficients: for each node, the
  share of pairs of its contacts that are tied.

The node-level values can be saved with `nwclustering`:

```stata
. nwclustering samplike, generate(clu)
----------------------------------------
  Network name: samplike
----------------------------------------
    Measure: binary
    Average clustering coefficient: .44
    Global clustering coefficient: .407
 

. summarize clu

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         clu |         18    .4400548    .2156577   .1666667          1
```

Monks differ a lot: from a clustering of .17 (their contacts hardly know each other) to 1 (all their contacts
are tied). As with density, the question is whether this closure is more than chance would give. For that use
`nwcug` with `stat(nwtriads ##net##)` and `rname(transitivity)`, shown in
[Tutorial 18](../18-testing/).

## Motifs: four-node patterns

A **motif** is a small connected pattern; counting how often each occurs describes a network more finely than
the triad census. `nwmotifs` counts the seven patterns of four nodes:

```stata
. nwmotifs samplike
(note: tie values are ignored; this measure is binary)
Note: samplike is directed - the 4-node motif census below
treats every tie as undirected (a directed 4-node census has 218
distinct isomorphism classes and is not attempted here); see
nwtriads for a genuinely directed 3-node census.

    4-node motif census: samplike

          path |          star |         cycle |           paw |
---------------+---------------+---------------+---------------+
           444 |           126 |            53 |           298 |

       diamond |            k4 |      disconn. |
---------------+---------------+---------------+
            91 |            24 |          2024 |
```

The command says it plainly: for a directed network the census treats ties as undirected. The monks'
network is dense and clustered: 24 complete four-node groups (`k4`) and 91 diamonds (a `k4` minus one tie),
against 126 stars (one node linked to three others who do not know each other). These counts are not
comparable between networks of different size or density without a null model: `nwmotifs` has a `normalise`
option, and `nwcug` with `stat(nwmotifs ##net##, silent)` tests a motif count against random networks.

## Signed networks and structural balance

If ties can be positive (friendship) or negative (enmity), a triad is **balanced** if the product of its three
signs is positive: "the friend of my friend is my friend", "the enemy of my friend is my enemy", "the enemy of my
enemy is my friend". `nwbalance` counts the closed triads and how many are balanced. Take four nodes A to D, in
which D is disliked by A and B and liked by C:

```stata
. nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) undirected labs(A,B,C,D) name(signed)

. nwbalance signed
----------------------------------------
  Network name: signed
----------------------------------------
    Closed triad: 4
    Balanced triad: 2
    Unbalanced triad: 2
```

Of the four triangles, ABC (all positive) and ABD (one positive, two negative signs) have a positive
product and are balanced; ACD and BCD (one negative sign each) are unbalanced.

## Which command when?

| Question | Command |
|---|---|
| How many mutual, asymmetric and null pairs? How reciprocal is the network? | `nwdyads` |
| Which of the 16 triad types occur? Transitive or cyclic? | `nwtriads` |
| How clustered is each node, and the network? | `nwclustering` |
| Which four-node patterns occur? | `nwmotifs` |
| Are the triads of a signed network balanced? | `nwbalance` |
| Is any of this unusual for the network's size and density? | `nwcug` ([Tutorial 18](../18-testing/)) |
