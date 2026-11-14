---
title: "nwtriads"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
name(string)]
```

| | |
|---|---|
| `plot` | Draw the 16 triad types as small pictures with their counts |
| `name(string)` | Name for the graph created by `plot`; default = **triads** |

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

The census is counted in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both give the same counts. It follows Batagelj and Mrvar (2001, *Social Networks* 23: 237-243): triads with at least two ties are enumerated from the neighbours of each node, the empty triads **_003** are obtained by subtraction. Measured in Stata/BE, random directed network with 10 ties per node: 5,000 nodes 0.08 seconds, 20,000 nodes 0.2 seconds, 100,000 nodes 1 second (the Mata route needs 3.4, 13 and 73 seconds). A network with self-loops always takes the Mata route. The count of empty triads **r(_003)** is an exact integer.

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

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
