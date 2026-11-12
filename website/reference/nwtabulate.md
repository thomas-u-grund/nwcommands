---
title: "nwtabulate"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "One-way table of dyads"
---

# `nwtabulate`

One-way table of dyads

## Syntax

```stata
nwtab:ulate 
[netname]
[,
tabulate1_options]
```

## Description

The one-way nwtabulate simply tabulates all ties in the network and shows the distribution of tie values. It works just as `tabulate`, but on the level of network ties. The command recognizes when a network is undirected or selflooped.

For example, for a directed network with 5 nodes, the commands displays the distribution of a total of 5 * 4 = 20 tie values. For an undirected network with 5 nodes, the commands displays the distribution of a total of (5 * 4)/2 = 10 tie values.

The command makes use of the normal `tabulate` command, hence, all *`tabulate1_options`* can be applied. This can be useful to extract the distribution of tie values for further calculation.

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

- [two-way nwtabulate](nwtab2), `tabulate`

- * *! 12jul2016: Thomas Grund

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
