---
title: "nwtriads"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Triad census of the network"
---

# `nwtriads`

Triad census of the network

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
| `plot` | Draw a bar chart of the 16 MAN-category counts |
| `name(string)` | Name for the graph created by `plot`; default = **triads** |

## Description

Returns the triad census of the network (or a list of networks). This is a way to characertize a network based on its triads.

Each unique triad (triple of nodes *i*, *j*, and *k*) in a directed network can be one of the following:

- 003 = i,j,k, empty triad.
- 012 = i->j, k, triad with a single directed edge.
- 102 = i<->j, k, triad with a reciprocated connection between two vertices.
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

`plot` draws a bar chart of the 16 category counts, in the same fixed MAN order the text table above already uses (not sorted by count), via this package's own established preserve/rebuild-a-plotting-dataset/restore convention - the same one [nwcug](nwcug)'s own `plot` option uses for its null-distribution histogram. Grayscale by design, matching every other plot this package produces.

## Examples

- . nwwebuse glasgow, nwclear
- . nwtriads glasgow3
- Triad census: glasgow3

- 003c |012c |021Dc |021Uc |
- hline 11c +hline 11c +hline 11c +hline 11c +
- 16086c |1401c |4c |8c |

- 021Cc |030Tc |030Cc |102c |
- hline 11c +hline 11c +hline 11c +hline 11c +
- 7c |1c |0c |1969c |

- 120Dc |120Uc |120Cc |111Dc |
- hline 11c +hline 11c +hline 11c +hline 11c +
- 3c |28c |33c |4c |

- 111Uc |201c |210c |300c |
- hline 11c +hline 11c +hline 11c +hline 11c +
- 1c |17c |26c |12c |

- Transitivity: .4830508474576271

This example shows, e.g. that in the *glasgow3* network, there are 12 triads where all nodes *i*, *j* and *k* are directely connected with each other.

## Supported network types

Binary: yes. Directed: yes - this is the command's native case; the full 16-type MAN classification requires a genuine directed/asymmetric-dyad distinction. Undirected: the command still runs, but 12 of the 16 categories (everything except **_003**/**_102**/**_201**/**_300**) are not meaningful for undirected data and reliably return 0, since an undirected network has no asymmetric ties by construction - `nwtriads` prints a note to this effect when called on an undirected network. Weighted: not applicable (a triad census is inherently a binary/dichotomous count). Signed: not checked. Two-mode: not checked.

## See also

- [nwdyads](nwdyads)

- last certified : 24 Aug 2026
