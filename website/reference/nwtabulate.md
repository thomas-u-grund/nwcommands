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

## Tables of networks

**See**

[nwtabulate oneway](nwtab1) for one-way table of network ties

[nwtabulate twoway](nwtab2) for two-way table of networks

[nwtabulate twoway](nwtab3) for two-way table of network and node attribute

## Network types

**Directed:** yes. **Valued:** the one-way table and the table of two networks show the tie values; the table by `attribute()` counts ties only; for it, a valued network gets a note. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

- * *! 12jul2016: Thomas Grund

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

## Limits

The table of one network counts the dyads of each value without listing them, so the time depends on the number of ties, not on the square of the number of nodes. Measured in Stata/BE, random directed network with 10 ties per node: 1,000 / 5,000 / 20,000 nodes in 0.01 / 0.01 / 0.03 seconds. The tabulation of a network by an attribute lists the ties only; the permutation test (`permutations()`, default 100) permutes the attribute on the dense matrix and takes most of the time: 10,000 nodes with 100 permutations 47 seconds and 4.8 GB. The tabulation of two networks uses the dyad list and the full matrix.

With `attribute()` the permutation test acts on the stored ties of a network that is held that way (20,000 nodes with the default 100 permutations: 1.6 seconds). The test of two networks works on the matrices.

Frequency weights of Stata stop at 2,147,483,647: a directed network of more than about 46,000 nodes (an undirected one of 65,000) has more dyads than that. The table is then written by `nwtabulate` itself (value, frequency, percent, cumulative percent; the options of `tabulate` are ignored). A network of 100,000 nodes takes 0.1 seconds.

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

## Remarks on plot

The `plot` option draws the table with a built-in bar plot (the same plot the user-written `tabplot` draws; `tabplot` itself is not needed, and is not used even if it is installed). Any further options in `plotoptions()` are passed to `twoway`. The built-in plot follows the idea and the look of Nick Cox's `tabplot` (SSC); thanks to N. J. Cox.

## Remarks on plot

The `plot` option draws the table with a built-in bar plot (the same plot the user-written `tabplot` draws; `tabplot` itself is not needed, and is not used even if it is installed). Any further options in `plotoptions()` are passed to `twoway`. The built-in plot follows the idea and the look of Nick Cox's `tabplot` (SSC); thanks to N. J. Cox.

## See also

- [two-way nwtabulate](nwtab2), `tabulate`

- * *! 12jul2016: Thomas Grund

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
