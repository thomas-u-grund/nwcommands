---
title: "nwdyads"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Dyad census"
---

# `nwdyads`

Dyad census

## Syntax

```stata
nwdyads 
[netname]
```

## Description

Returns the dyad census of a network (or a list of networks). This is a way to characterize a network based on its dyads.

In directed networks, each dyad (pair of nodes *i* and *j*) can be one of the following:

1) M: mutually connected: *M_ij = M_ji = 1*

2) A: asymmetrically connected: *M_ij = 1*, but *M_ji = 0*

3) N: not connected at all: *M_ij = M_ji = 1*

In undirected network, each dyad (pair of nodes *i* and *j*) can be one of the following:

1) M: connected: *M_ij = M_ji = 1*

2) N: unconnected:  *M_ij = M_ji = 0*

The command also returns the reciprocity of the network.

*reciprocity = M / (M + A)*

## Examples

```stata
. nwwebuse florentine
```
- . nwdyads flomarriage
- Dyad census: flomarriage

- Mutualc |Null
- hline 11c +hline 11
- 20c |100

- . nwwebuse glasgow
- . nwdyads glasgow3
- Dyad census: glasgow3

- Mutualc |Asymc |Null
- hline 11c +hline 11c +hline 11
- 45c |32c |1148

## Supported network types

Binary: yes (only) - the dyad census (mutual/asymmetric/null) is inherently a presence/absence classification. Directed: yes - a directed network gets the full M/A/N census; an undirected network collapses to M/N only (every tie is definitionally mutual). Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## Stored results

- Scalars:
- **r(_100)** mutual dyads
- **r(_010)** asymmetric dyads
- **r(_001)** null dyads
- **r(reciprocity)** M / (M + A)

- Macros:
- **r(name)** name of network

## See also

- [nwtriads](nwtriads)

- last certified : 24 Aug 2026
