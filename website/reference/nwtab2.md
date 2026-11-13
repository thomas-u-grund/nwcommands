---
title: "nwtabulate"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
unvalued
save(filename)
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
| `permutations(integer)` | QAP permutations for significance of E-I-index; default = 100 |
| `unvalued` | count every tie as 1, whatever its value, in the table and in the E-I index |
| `save(filename)` | save the E-I indices of the permutations (variables **EI_simulated**, **EI_observed**) as a Stata data set |

## Description

The command produces the network version of `tabulate twoway` for two networks. It shows the overlap of ties for two networks that share the same nodes (see [nodeid](nodeid)) on the dyadic level. The command essentially transforms *netname1* and *netname2* in edgelist format (see [nwtoedge](nwtoedge)) and runs a normal `tabulate twoway`, hence, all `tabulate2_options` can be used as well.

When at least one of the networks *netname1* or *netname2* is directed, the command produces a full edgelist for the networks with two entries for the node pair (i,j).

The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio is a social network measure of the relative density of internal connections within a social group compared to the number of connections that group has to the external world. Applied to two networks the number of internal connections refers to the number of times that the tie value for the pair (i,j) is the same in *netname1* and *netname2*.

- *E-I-index = (E - I) / (E + I)*

where I (internal) is the number of ties within a social group G and E is the number of ties to the external world (outside of group G). The E-I-index ranges between -1 (only within-group ties exist) and 1 (only between-group ties exist).

More intuitively, the E-I-index simply calculates the number of ties off the diagonal (in the table produced by the command) by the total number of ties. By default, the command runs 100 QAP permutations of the network (see [nwqap](nwqap)) to obtain a p-value for the E-I-index. Basically, the network is randomly permuted and the E-I-index is calculated again to obtain a distribution for the E-I-index under the condition that the network and the attribute are unrelated.

## Remarks on plot

The `plot` option draws the table with a built-in bar plot (the same plot the user-written `tabplot` draws; `tabplot` itself is not needed, and is not used even if it is installed). Any further options in `plotoptions()` are passed to `twoway`. The built-in plot follows the idea and the look of Nick Cox's `tabplot` (SSC); thanks to N. J. Cox.

## Example

This loads the Florentine [data](netexample) and shows the overlap between the networks *flomarriage* and *flobusiness*. Both have the same nodes, i.e. 16 Florentine families.

```stata
. nwwebuse florentine, nwclear
. nwtabulate flomarriage flobusiness

Network1:  flomarriage     Directed : false
                           Selfloops: false
Network2:  flobusiness     Directed : false
                           Selfloops: false
```
- flomarriag c | flobusiness
- e c | 0 1 c | Total

```stata
-----------+----------------------+----------
         0 |        93          7 |       100
         1 |        12          8 |        20
-----------+----------------------+----------
     Total |       105         15 |       120

   E-I Index: -.683 p-value: 0
```
There are 120 possible (undirected) ties between Florentine families that can overlap in the two networks. There are 8 undirected ties where families have both a marriage and a business relationship. In contrast, there are 7 undirected pairs of families with a business, but not with a marriage relationship.

## Stored results

- **Scalars**
- **r(EI_index)** --- E-I index
- **r(EI_pvalue)** --- p-value of the E-I index from the QAP permutations (with `permutations()` > 1)

- **Macros**
- **r(netname1)** --- name of the first network
- **r(netname2)** --- name of the second network

- **Matrices**
- **r(table)** --- the cell frequencies of the table
- **r(row)** --- the tie values of *netname1* (rows)
- **r(col)** --- the tie values of *netname2* (columns)

## See also

- [one-way nwtabulate](nwtab1), [two-way nwtabulate attribute](nwtab3), [nwcorrelate](nwcorrelate), [nwqap](nwqap), `tabulate`

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
