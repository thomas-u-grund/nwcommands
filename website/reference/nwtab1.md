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

## Example

```stata
. nwwebuse gang
. nwtabulate gang

Network:  gang      Directed: false
```
- gang c | Freq. Percent Cum.

```stata
------------+-----------------------------------
          0 |      1,116       77.99       77.99
          1 |        182       12.72       90.71
          2 |         92        6.43       97.13
          3 |         25        1.75       98.88
          4 |         16        1.12      100.00
------------+-----------------------------------
      Total |      1,431      100.00
```
- In the *gang* network, 1116 potential (undirected) co-offending ties are not realized, 182 ties have the value 1,
- 92 ties have the value 2 and so on.

## See also

- [two-way nwtabulate](nwtab2), `tabulate`

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
