---
title: "nw2motifs"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Bipartite motifs of a two-mode network"
---

# `nw2motifs`

Bipartite motifs of a two-mode network

## Syntax

```stata
nw2motifs [netname] [, six:node gen:erate(stub) replace mat:rix(name) norm:alise posn:orm(type) silent]
```

| | |
|---|---|
| `six:node` | count the motifs of six nodes too: 44 motifs and 148 node positions instead of 17 and 46 |
| `gen:erate(stub)` | store the node position counts in the variables *stub*1, *stub*2, ... (one per position, one row per node) |
| `replace` | replace existing variables |
| `mat:rix(name)` | store the node position counts in a Stata matrix (one row per node, columns np1, np2, ...); only if the network has no more nodes than a matrix may have rows |
| `norm:alise` | add the four normalised frequencies of `bmotif::mcount` to the motif table |
| `posn:orm(type)` | normalise the node position counts as `bmotif::node_positions`: `none` (default), `sum`, `position`, `sizeclass`, `sizeclass_plus1`, `sizeclass_NAzero`, `levelsize`, `levelsize_plus1`, `levelsize_NAzero`, `motif`, `motif_plus1`, `motif_NAzero` |
| `silent` | suppress the output |

## Description

`nw2motifs` is the form of [nwmotifs](nwmotifs) for a two-mode network: `nwmotifs` uses it by default on a two-mode network (and `onemode` forces the 4-node census of the bipartite graph). The two names give the same result with the same options.

`nw2motifs` counts the bipartite motifs of a two-mode network: the small connected patterns of ties between two sets of nodes that make up the building blocks of species-by-site, plant-pollinator and membership networks (Baker et al. 2015; Simmons et al. 2019, *Methods in Ecology and Evolution*). There are 17 motifs of two to five nodes and 27 more of six nodes (44 in all), and each motif has one or more *positions* (46 for the five-node set, 148 with six nodes): the nodes of a motif that are not equivalent, such as the end and the middle of a path. The command gives two things.

- 1. The **motif table**, the number of times each motif occurs in the network (what `bmotif::mcount` returns), shown on screen and returned in `r(motifs)`.
- 2. The **node position counts**, for every node the number of times it holds each position (what `bmotif::node_positions` returns), stored in variables with `generate()` or in a
- matrix with `matrix()`. They quantify the structural role of a node, for example in a plant-pollinator network.

A motif occurrence is a set of nodes whose subgraph, with *all* the ties between them, is connected and has the shape of the motif; an occurrence is counted once however many ways it can be read (the motifs are induced subgraphs, so a path of two rows and two columns and a four-cycle are two different motifs, and a set of four nodes is exactly one of them). The first mode of the network (mode 1) forms the *rows* of the biadjacency matrix of `bmotif` and the second mode the *columns*; the numbering of the motifs and of the positions is the one of `bmotif` (Simmons et al.), listed in the table below. The motif table equals `bmotif::mcount` and the position counts `bmotif::node_positions` (bmotif 2.0.2) exactly, on a toy network, the Southern women, the Swedish directors, a subsample of them and 34 random networks.

The counting runs in the compiled plugin of nwcommands and needs no matrices of the size of the network: the 5,092 directors and 455 firms of `ftdirectors_se` (5,669 ties) take 0.04 seconds for the motifs and positions up to five nodes, and 0.05 seconds with `sixnode`; a random network of 1,000 and 150 nodes with 14,800 ties takes 0.05 and 0.9 seconds. (The R function takes about a minute for the five-node set on the directors.) The time with `sixnode` grows quickly with the density and the number of nodes of the smaller mode. Counts are held as doubles, so they are exact up to 9 x 10^15. The command stops with a message when the plugin of the installed copy is older than the command or missing for the platform: update the installation (`net install nwcommands, replace`) and restart Stata.

The node position counts of a node that is in no motif (an isolate) are zero. In the variables and the matrix the nodes are in the order of the network, the rows of the matrix of `bmotif` being the nodes of mode 1 in that order and its columns those of mode 2; the position ids *np1* to *np148* are those of `bmotif` (*stub*1 holds position 1).

## Options

`sixnode` counts the motifs of six nodes (motifs 18 to 44, positions 47 to 148) as well. Without it only the motifs up to five nodes are counted (17 motifs, 46 positions), as `bmotif` does by default.

`generate(stub)` stores the counts of the positions in double variables *stub*1 to *stub*46 (*stub*148 with `sixnode`), one row per node of the network in the order of the nodes. The data set is aligned with the network first, as in the other node-level commands. Existing variables stop the command unless `replace` is given.

`matrix(name)` stores the same table as a Stata matrix with one row per node and the columns np1, np2, ... The matrix is limited by the largest matrix Stata allows (800 rows in Stata BE); for larger networks use `generate()`.

`normalise` adds to `r(motifs)` (and to the display) the four normalisations of `bmotif::mcount`: `normalise_sum` (the frequency as a share of all motifs counted), `normalise_sizeclass` (as a share of the motifs with the same number of nodes), `normalise_levelsize` (as a share of the motifs with the same number of rows and columns; motifs that are alone in their class always give 1) and `normalise_nodesets` (as a share of the number of node sets that could form the motif, choose(rows, a) times choose(columns, b)). A share whose denominator is zero is missing.

`posnorm(type)` divides the node position counts (in the variables and the matrix) as `bmotif::node_positions(normalisation = )` does: `sum` by the number of times the node holds any position (row sums); `position` by the number of times any node holds the position (column sums); `sizeclass` by the node's count in the positions of motifs with the same number of nodes; `levelsize` by its count in the positions of motifs with the same number of rows and columns; `motif` by its count in the positions of the same motif. The suffix `_plus1` adds one to all counts first (so that nodes outside a class are not missing); the suffix `_NAzero` replaces the missing values of a node that holds none of the positions of the class by 0. Without them such values are missing. It needs `generate()` or `matrix()`; the table `r(motifs)` is not affected.

`silent` suppresses the output.

## The motifs and their node positions

The numbering is that of `bmotif` (the figure of its vignette "bmotif-dictionary"). *r1*, *r2*, ... are the rows (nodes of mode 1) and *c1*, *c2*, ... the columns (nodes of mode 2) of an occurrence; "r1:12" means that row r1 is tied to columns c1 and c2. The last column lists the position id of each row node, then (after the bar) of each column node, in the order r1, r2, ... | c1, c2, ...; nodes with the same id play the same role. The positions of motif *m* are the consecutive ids from the smallest to the largest listed. Every row-column pair that is not listed is not tied.

- motifnodesr x ctiespositions (rows | columns)

```stata
---------------------------------------------------------------------------
  1     2     1 x 1   r1:1                          2 | 1
  2     3     1 x 2   r1:12                         4 | 3 3
  3     3     2 x 1   r1:1 r2:1                     6 6 | 5
  4     4     3 x 1   r1:1 r2:1 r3:1                8 8 8 | 7
  5     4     2 x 2   r1:12 r2:1                    12 11 | 10 9
  6     4     2 x 2   r1:12 r2:12                   14 14 | 13 13
  7     4     1 x 3   r1:123                        16 | 15 15 15
  8     5     4 x 1   r1:1 r2:1 r3:1 r4:1           18 18 18 18 | 17
  9     5     3 x 2   r1:12 r2:1 r3:1               22 21 21 | 20 19
  10    5     3 x 2   r1:12 r2:2 r3:1               25 24 24 | 23 23
  11    5     3 x 2   r1:12 r2:12 r3:1              29 29 28 | 27 26
  12    5     3 x 2   r1:12 r2:12 r3:12             31 31 31 | 30 30
  13    5     2 x 3   r1:123 r2:1                   35 34 | 33 32 32
  14    5     2 x 3   r1:13 r2:12                   38 38 | 37 36 36
  15    5     2 x 3   r1:123 r2:12                  42 41 | 40 40 39
  16    5     2 x 3   r1:123 r2:123                 44 44 | 43 43 43
  17    5     1 x 4   r1:1234                       46 | 45 45 45 45
  18    6     5 x 1   r1:1 r2:1 r3:1 r4:1 r5:1      48 48 48 48 48 | 47
  19    6     4 x 2   r1:12 r2:1 r3:1 r4:1          52 51 51 51 | 50 49
  20    6     4 x 2   r1:12 r2:2 r3:1 r4:1          57 55 56 56 | 54 53
  21    6     4 x 2   r1:12 r2:12 r3:1 r4:1         61 61 60 60 | 59 58
  22    6     4 x 2   r1:12 r2:12 r3:2 r4:1         64 64 63 63 | 62 62
  23    6     4 x 2   r1:12 r2:12 r3:12 r4:1        68 68 68 67 | 66 65
  24    6     4 x 2   r1:12 r2:12 r3:12 r4:12       70 70 70 70 | 69 69
  25    6     3 x 3   r1:123 r2:1 r3:1              74 73 73 | 72 71 71
  26    6     3 x 3   r1:123 r2:2 r3:1              77 78 78 | 75 75 76
  27    6     3 x 3   r1:13 r2:12 r3:1              81 81 82 | 79 80 80
  28    6     3 x 3   r1:23 r2:12 r3:1              87 88 86 | 84 85 83
  29    6     3 x 3   r1:123 r2:12 r3:1             94 93 92 | 91 90 89
  30    6     3 x 3   r1:13 r2:12 r3:12             98 99 99 | 97 96 95
  31    6     3 x 3   r1:123 r2:12 r3:12            103 102 102 | 101 101 100
  32    6     3 x 3   r1:123 r2:23 r3:1             108 107 106 | 104 105 105
  33    6     3 x 3   r1:123 r2:123 r3:1            112 112 111 | 110 109 109
  34    6     3 x 3   r1:23 r2:13 r3:12             114 114 114 | 113 113 113
  35    6     3 x 3   r1:123 r2:13 r3:12            118 117 117 | 116 115 115
  36    6     3 x 3   r1:123 r2:123 r3:12           122 122 121 | 120 120 119
  37    6     3 x 3   r1:123 r2:123 r3:123          124 124 124 | 123 123 123
  38    6     2 x 4   r1:1234 r2:1                  128 127 | 126 125 125 125
  39    6     2 x 4   r1:134 r2:12                  133 132 | 131 129 130 130
  40    6     2 x 4   r1:1234 r2:12                 137 136 | 135 135 134 134
  41    6     2 x 4   r1:124 r2:123                 140 140 | 139 139 138 138
  42    6     2 x 4   r1:1234 r2:123                144 143 | 142 142 142 141
  43    6     2 x 4   r1:1234 r2:1234               146 146 | 145 145 145 145
  44    6     1 x 5   r1:12345                      148 | 147 147 147 147 147
---------------------------------------------------------------------------
```
Examples: motif 1 is a single tie (positions 2 for the row and 1 for the column); motifs 2 and 3 are the two-ties stars (one row with two columns, two rows with one column); motif 5 is the path of two rows and two columns and motif 6 the four-cycle; motif 7 and motif 4 are the stars with three columns and three rows. Positions 1 to 2 are those of the two-node motif, 3 to 6 of the three-node motifs, 7 to 16 of the four-node motifs, 17 to 46 of the five-node motifs and 47 to 148 of the six-node motifs.

## Network types

**Directed:** not applicable. **Valued:** a tie counts when its value is above zero; the values are ignored (the command prints a note) and the weighted measures of `bmotif` are not offered. **Two-mode:** yes - the command needs a two-mode network (one-mode networks: error 198, use [nwmotifs](nwmotifs)); mode 1 = rows. **Signed:** negative ties count as absent. See [nwnetworktypes](nwnetworktypes).

## Examples

- A toy network of 6 persons (mode 1, the rows) and 4 groups (mode 2, the columns):

- `. clear`
- `. input str3 p str3 g`
- `. "p1" "g1"`
- `. "p1" "g2"`
- `. "p2" "g1"`
- `. "p2" "g2"`
- `. "p2" "g3"`
- `. "p3" "g2"`
- `. "p3" "g3"`
- `. "p4" "g3"`
- `. "p4" "g4"`
- `. "p5" "g4"`
- `. "p6" "g4"`
- `. "p6" "g1"`
- `. end`
- `. nw2fromedge p g, name(toy)`
- `. nw2motifs toy, normalise`

- Node positions of the Southern women and events, with the shares of each woman's positions among the positions of motifs of the same size:

- `. nwuse davis, nwclear`
- `. nw2motifs davis, generate(np) posnorm(sizeclass) silent`
- `. summarize np1-np6`

- All 44 motifs of the toy network, with the position counts in a matrix:

- `. nw2motifs toy, sixnode matrix(P) silent`
- `. matrix list r(motifs)`

## Stored results

`nw2motifs` stores in `r()`:

- **Scalars**
- **`r(sixnode)`** --- 1 if the motifs of six nodes were counted
- **`r(n_mode1)`** --- number of nodes of mode 1 (rows)
- **`r(n_mode2)`** --- number of nodes of mode 2 (columns)

- **Matrices**
- **`r(motifs)`** --- 17 x 3 (44 x 3 with `sixnode`): motif, nodes, frequency; 17 x 7 (44 x 7) with `normalise`, with the columns normalise_sum, normalise_sizeclass, normalise_levelsize and normalise_nodesets added

- **Macros**
- **`r(netname)`** --- name of the network
- **`r(posnorm)`** --- the normalisation of the node position counts

## References

Baker, N., R. Kaartinen, T. Roslin, and D. B. Stouffer. 2015. Species' roles in food webs show fidelity across a highly variable oak forest. *Ecography* 38: 130-139.

Simmons, B. I., M. J. M. Sweering, M. Schillinger, L. V. Dicks, W. J. Sutherland, and R. Di Clemente. 2019. bmotif: A package for motif analyses of bipartite networks. *Methods in Ecology and Evolution* 10: 695-701.

Stouffer, D. B., M. Sales-Pardo, M. I. Sirer, and J. Bascompte. 2012. Evolutionary conservation of species' roles in food webs. *Science* 335: 1489-1492.

## Also see

- psee
- [nwmotifs](nwmotifs), [nw2set](nw2set), [nw2nested](nw2nested), [nw2clustering](nw2clustering), [nw2degree](nw2degree), [nwnetworktypes](nwnetworktypes)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
