---
title: "nwtabulate"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Two-way table of two networks"
---

# `nwtabulate`

Two-way table of two networks

## Syntax

```stata
nwtab:ulate 
netname1
netname2
[,
permutations(integer)
plot
plotoptions(tabplot_options)
eiplot
eiplotoptions(kdensity_options)
tabulate2_options]
```

| | |
|---|---|
| `plot` | Make a tabplot |
| `eiplot` | Make a plot for significance of E-I-index |
| `permutations(integer)` | QAP permutations for significance of E-I-index |

## Description

Teh command produces the network version of `tabulate twoway` for two networks. It shows the overlap of ties for two networks that share the same nodes (see [nodeid](nodeid)) on the dyadic level. The command essentially transforms *netname1* and *netname2* in edgelist format (see [nwtoedge](nwtoedge)) and runs a normal `tabulate twoway`, hence, all `tabulate2_options` can be used as well.

When at least one of the networks *netname1* or *netname2* is directed, the command produces a full edgelist for the networks with two entries for the node pair (i,j).

The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio is a social network measure of the relative density of internal connections within a social group compared to the number of connections that group has to the external world. Applied to two networks the number of internal connections refers to the number of times that the tie value for the pair (i,j) is the same in *netname1* and *netname2*.

- *E-I-index = (E - I) / (E + I)*

where I (internal) is the number of ties within a social group G and E is the number of ties to the external world (outside of group G). The E-I-index ranges between -1 (only within-group ties exist) and 1 (only between-group ties exist).

More intuitively, the E-I-index simply calculates the number of ties off the diagonal (in the table produced by the command) by the total number of ties. By default, the command runs 100 QAP permutations of the network (see [nwqap](nwqap)) to obtain a p-value for the E-I-index. Basically, the network is randomly permuted and the E-I-index is calculated again to obtain a distribution for the E-I-index under the condition that the network and the attribute are unrelated.

## See also

- [one-way nwtabulate](nwtab1), [two-way nwtabulate attribute](nwtab3), [nwcorrelate](nwcorrelate), [nwqap](nwqap), `tabulate`

- version: 2.0.0
- certified: 12 Jul 2016, 18:18:51
