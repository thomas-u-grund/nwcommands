---
title: "nwtabulate"
parent: "Command reference"
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

## Supported network types

Binary: yes. Directed: yes. Weighted: not applicable - tabulates tie presence/attribute crossings, not tie values. Signed: not applicable. Two-mode: not checked.

- * *! 12jul2016: Thomas Grund

## See also

- [two-way nwtabulate](nwtab2.md), `tabulate`

- * *! 12jul2016: Thomas Grund
