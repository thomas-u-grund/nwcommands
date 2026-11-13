---
title: "nwdyads"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
[,
plot
name(string)]
```

| | |
|---|---|
| `plot` | Draw the dyad types as small pictures with their counts |
| `name(string)` | Name for the graph created by `plot`; default = **dyads** |

## Description

Returns the dyad census of a network (or a list of networks). This is a way to characterize a network based on its dyads.

In directed networks, each dyad (pair of nodes *i* and *j*) can be one of the following:

1) M: mutually connected: *M_ij = M_ji = 1*

2) A: asymmetrically connected: *M_ij = 1*, but *M_ji = 0*

3) N: not connected at all: *M_ij = M_ji = 0*

In undirected network, each dyad (pair of nodes *i* and *j*) can be one of the following:

1) M: connected: *M_ij = M_ji = 1*

2) N: unconnected:  *M_ij = M_ji = 0*

The command also returns the reciprocity of the network.

*reciprocity = M / (M + A)*

## Network types

**Directed:** mutual, asymmetric and null dyads; an undirected network has mutual and null dyads only. **Valued:** tie values are ignored (every tie counts as present; the command prints a note). **Two-mode:** yes - the null dyads are counted over the pairs of nodes from different modes; reciprocity is shown as n/a. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Limits

A network held as stored ties is counted from its ties (each tie is matched with its reverse): 20,000 nodes 0.08 seconds and 0.2 GB in Stata/BE.

## Examples

```stata
. nwwebuse florentine
. nwdyads flomarriage

    Dyad census:  flomarriage

    Mutual |      Null
-----------+-----------
        20 |       100

. nwdyads flomarriage, plot

. nwwebuse glasgow
. nwdyads glasgow3

    Dyad census:  glasgow3

    Mutual |      Asym |      Null
-----------+-----------+-----------
        45 |        32 |      1148
```

## Stored results

- **Scalars**
- **r(_100)** --- mutual dyads
- **r(_010)** --- asymmetric dyads
- **r(_001)** --- null dyads
- **r(reciprocity)** --- M / (M + A)

- **Macros**
- **r(name)** --- name of network
- **r(netname)** --- name of network (same as **r(name)**)

## See also

- [nwtriads](nwtriads)

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
