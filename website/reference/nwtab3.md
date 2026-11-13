---
title: "nwtabulate"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Two-way table of network and node-attribute"
---

# `nwtabulate`

Two-way table of network and node-attribute

## Syntax

```stata
nwtab:ulate 
netname
,
attribute(varname)
[permutations(integer)
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
| `attribute(varname)` | Node-level attribute |
| `plot` | Make a tabplot |
| `eiplot` | Make a plot for significance of E-I-index |
| `permutations(integer)` | QAP permutations for significance of E-I-index; default = 100 |
| `unvalued` | accepted; the table counts ties already, whatever their values |
| `save(filename)` | save the E-I indices of the permutations (variables **EI_simulated**, **EI_observed**) as a Stata data set |

## Description

When one network and one attribute is given in option `attribute()`, the command produces a two-way table that indicates the number of ties between network nodes with certain attributes (tie values are not considered). This can be used to detect homophily in a network (the tendency for ties to exist between similar nodes).

The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio is a social network measure of the relative density of internal connections within a social group compared to the number of connections that group has to the external world.

- *E-I-index = (E - I) / (E + I)*

where I (internal) is the number of ties within a social group G and E is the number of ties to the external world (outside of group G). The E-I-index ranges between -1 (only within-group ties exist) and 1 (only between-group ties exist).

More intuitively, the E-I-index simply calculates the number of ties off the diagonal (in the table produced by the command) by the total number of ties. By default, the command runs 100 QAP permutations of the network (see [nwqap](nwqap)) to obtain a p-value for the E-I-index. Basically, the network is randomly permuted and the E-I-index is calculated again to obtain a distribution for the E-I-index under the condition that the network and the attribute are unrelated.

## Stored results

- **Scalars**
- **r(EI_index)** --- E-I index
- **r(EI_pvalue)** --- p-value of the E-I index from the permutations (with `permutations()` > 1)

- **Macros**
- **r(netname)** --- name of the network
- **r(attribute)** --- name of the attribute

- **Matrices**
- **r(table)** --- the cell frequencies of the table
- **r(row)** --- the attribute values of the sender (rows)
- **r(col)** --- the attribute values of the receiver (columns)

## See also

- [one-way nwtabulate](nwtab1), [two-way nwtabulate network](nwtab2), [nwcorrelate](nwcorrelate), [nwqap](nwqap), `tabulate`

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
