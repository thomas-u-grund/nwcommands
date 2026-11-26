---
title: "nwtriads"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Triad census of a network"
---

# `nwtriads`

Triad census of a network

## Syntax

```stata
nwtriads
[netname]
[,
plot
expected
name(string)
saving(filename)
export(filename[, options])
twoway_options]
```

| | |
|---|---|
| `plot` | Draw the 16 triad types as small pictures with their counts |
| `expected` | With `plot`: the expected count of every type under random dyad types (dyad census fixed) under the count |
| `name(string)` | Name for the graph created by `plot`; default = **triads** |
| `sav:ing(filename)` | Save the graph to a `.gph` file; an existing file is replaced |
| `exp:ort(filename[, options])` | Write the graph with `graph export`; the file extension sets the format |
| *twoway_options* | Other options of `twoway`, applied last; without `plot`, `saving()`, `export()` and these options give an error |

## Description

Returns the triad census of the network. This is a way to characterize a network based on its triads.

Each unique triad (triple of nodes *i*, *j*, and *k*) in a directed network can be one of the following:

- 003 = i,j,k, empty triad.
- 012 = i->j, k, triad with a single directed edge.
- 102 = i<->j, k, triad with a reciprocated tie between two vertices.
- 021D = i<-j->k, triadic out-star.
- 021U = i->j<-k triadic in-star.
- 021C = i->j->k, directed line.
- 111D = i<->j<-k
- 111U = i<->j->k.
- 030T = i->j<-k, i->k.
- 030C = i<-j<-k, i->k.
- 201 = i<->j<->k.
- 120D = i<-j->k, i<->k.
- 120U = i->j<-k, i<->k.
- 120C = i->j->k, i<->k.
- 210 = i->j<->k, i<->k.
- 300 = i<->j<->k, i<->k, complete triad.

This is the so called MAN notation. As in [nwdyads](nwdyads) it characterized a triad by the number of 1) mutual dyads, 2) asymmetric dyads and 3) null dyads. For example, MAN = 102 means that there is one mutual dyad and two null dyads.

`plot` draws each of the 16 triad types as a small picture of three nodes and their ties, with the MAN code and the number of triads of that type underneath. On an undirected network it draws the four types an undirected network can have (003, 102, 201, 300). [nwdyads](nwdyads) has the same option for the dyad census.

## Network types

**Directed:** the census is defined for directed networks; on an undirected one only **_003**, **_102**, **_201** and **_300** can be non-zero (with a note). **Valued:** tie values are ignored (with a note). **Two-mode:** same as for the bipartite graph read as a one-mode network (no triangles; transitivity 0; use [nwclustering](nwclustering)). **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

The census is counted in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both give the same counts. It follows Batagelj and Mrvar (2001, *Social Networks* 23: 237-243): triads with at least two ties are enumerated from the neighbours of each node, the empty triads **_003** are obtained by subtraction. A network with self-loops always takes the Mata route. The count of empty triads **r(_003)** is an exact integer.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## Examples

```stata
. nwwebuse glasgow, nwclear

. nwtriads glasgow3

    Triad census:  glasgow3

       003 |       012 |      021D |      021U |
-----------+-----------+-----------+-----------+
     16086 |      1401 |         4 |         8 |

      021C |      030T |      030C |       102 |
-----------+-----------+-----------+-----------+
         7 |         1 |         0 |      1969 |

      120D |      120U |      120C |      111D |
-----------+-----------+-----------+-----------+
         3 |        28 |        33 |         4 |

      111U |       201 |       210 |       300 |
-----------+-----------+-----------+-----------+
         1 |        17 |        26 |        12 |

     Transitivity: .4830508474576271
```
This example shows, e.g. that in the *glasgow3* network, there are 12 triads where all nodes *i*, *j* and *k* are directely connected with each other.

## Saving and exporting the graph

`name()` names the graph in memory, `saving()` writes it to a `.gph` file and `export()` writes it with `graph export`: the file extension sets the format, and `width()` and the other `graph export` options follow a comma. A graph or file of the same name is replaced; a trailing `, replace` is accepted and ignored. Other options go to `twoway` and come last, so they replace the defaults.

```stata
. nwwebuse florentine, nwclear
. nwtriads flomarriage, plot export(triads.png, width(1200))
```

## Expected counts

`expected` adds, under every count of the `plot`, the number of triads of that type expected when the three kinds of dyad (mutual, asymmetric, null) are placed at random on the node pairs with the dyad census of the network fixed, and an asymmetric tie points either way with probability 1/2. This is the uniform distribution over the networks with the same dyad census (Holland, P. W., and S. Leinhardt. 1976. Local structure in social networks. *Sociological Methodology* 7: 1-45), the null model of [nwcug](nwcug) with `condition(census)` and of [nwrandom](nwrandom) with `census()`. With D = n(n-1)/2 dyads, M mutual, A asymmetric and N null ones, a type with m mutual, a asymmetric and k null dyads (the digits of its name) and w labelled forms (1, 6, 3, 3, 3, 6, 6, 6, 6, 2, 3, 3, 3, 6, 6, 1 in the order of the table above) has the expected count C(n,3) w (M)m (A)a (N)k / (2^a (D)3), where (x)j = x(x-1)...(x-j+1). The formula is exact, not an approximation by simulation. [nwcug](nwcug) compares one statistic at a time with a null distribution; `expected` shows all types at once, without simulation. A two-mode and a valued network stop with error 198 ([nwdichotomize](nwdichotomize) first). `expected` needs `plot`.

```stata
. nwwebuse florentine, nwclear
. nwtriads flomarriage, plot expected export(triads_expected.png, width(1100))
```

## Stored results

- **Scalars**
- **r(_003)** --- number of empty triads
- ****r(_012)**, **r(_102)**, ...** --- number of triads of each of the other MAN types listed above (**r(_021D)**, **r(_021U)**, **r(_021C)**, **r(_111D)**, **r(_111U)**, **r(_030T)**, **r(_030C)**, **r(_201)**, **r(_120D)**, **r(_120U)**, **r(_120C)**, **r(_210)**)
- **r(_300)** --- number of complete triads
- **r(transitivity)** --- transitivity (global clustering coefficient, see [nwclustering](nwclustering)); 0 for a two-mode network

- **Macros**
- **r(name)** --- name of the network (alias: **r(netname)**)

## See also

- [nwdyads](nwdyads)

---

*nwcommands version 3.39.0, 26 November 2026* ([check your installed version](nwversion))
