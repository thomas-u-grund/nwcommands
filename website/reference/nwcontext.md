---
title: "nwcontext"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Create a context variable"
---

# `nwcontext`

Create a context variable

## Syntax

```stata
nwcontext 
[netname]
,
attribute(varname)
[stat(statistic)
mode(context)
generate(newvarname)
mat(string)
noweight
replace]
```

| | |
|---|---|
| `attribute(varname)` | Attribute variable |
| `stat`(*[statistic](nwcontext)*) | Statistic that is used to calculate context variable for node i from attributes of network neighbors |
| `mode`(*[context](nwcontext)*) | Define network neighbors of node i as either nodes j who receive ties from i, send ties to j or both |
| `generate(newvarname)` | **Required.** Name of the context variable to be generated |
| `mat(string)` | Store the result in a Mata matrix of this name instead of generating a Stata variable |
| `noweight` | Ignore valued ties and treats all as binary |
| `replace` | Replace `generate()`'s target variable if it already exists |

## Description

`nwcontext` generates a context variable, which holds information about the *attribute values* of a node's network neighbors.

For each node the set of network neighbors is specified in `mode()`, by default *context* = **outgoing**. This means that the new context variable *newvarname*[i] is calculated based on an all values *varname*[j], for which there is a tie from node *i* to node *j*. A network neighborhood of node *i* can be either 1) all nodes *j* to whom i has outgoing ties (default), 2) all nodes *j* from whom *i* receives incoming ties, or 3) both. In the case of valued ties *varname*[j] is weighted accordingly.

After that a *statistic* defined in `stat()` is calculated from all weigthed *varname*[j]. By default, the mean is calculated. More formally:

*newvarname*[i] = *stat*(*varname*[j]), for all *j* with *y_ij* > 0

When used with the defaults, the command calculates for each node *i* the mean score of its network neighbors on `varname`. Valid statistics are: the** mean**, the **max**, the **min**, the **sum** and the **sd** of `varname`.

Sometimes, however, one might want to calculate statistics including the attribute of ego. One can achieve this by using the ego-extended version of each statistic (**meanego**,  **maxego**,  **minego**,  **sumego** and **sdego**), which are calculated in this way:

*newvarname*[i] = *stat*(*varname*[j]), for all *j* with *y_ij* > 0 or j == i

## Remarks

In the case of undirected networks, no * mode* option needs to be specified.

By default, nodes with missing attributes are excluded from the calculation.

## Examples

This example loads the Florentine marriage data. The variable *wealth* indicates how rich each family is. ** nwcontext** generates different variables: *w_avg* = average wealth of network neighbors,  *w_min* = wealth of poorest network neighbor, *w_min* = wealth of richest network neighbor, *w_sd* = standard deviation of wealth over network neighbors.

- . nwwebuse florentine
- . nwcontext flomarriage, attribute(wealth) generate(w_avg)
- . nwcontext flomarriage, attribute(wealth) generate(w_min) stat(min)
- . nwcontext flomarriage, attribute(wealth) generate(w_max) stat(max)
- . nwcontext flomarriage, attribute(wealth) generate(w_sd) stat(sd)

- . list w*
- hline 8c -hline 10c -hline 10c -hline 10c -hline 10
- c | wealth w_avg w_min w_max w_sd c |
- hline 8c -hline 10c -hline 10c -hline 10c -hline 10
- 1. c | 10 103 103 103 0 c |
- 2. c | 36 47.66667 8 103 40.33471 c |
- 3. c | 55 61.5 20 103 41.5 c |
- 4. c | 44 67.66666 8 146 57.86382 c |
- 5. c | 20 83.33334 49 146 44.37968 c |
- hline 8c -hline 10c -hline 10c -hline 10c -hline 10
- 6. c | 32 36 36 36 0 c |
- 7. c | 8 42.5 36 48 4.330127 c |
- 8. c | 42 8 8 8 0 c |
- 9. c | 103 31 10 55 17.26268 c |
- 10. c | 48 10 10 10 0 c |
- hline 8c -hline 10c -hline 10c -hline 10c -hline 10
- 11. c | 49 70 20 146 54.626 c |
- 12. c | 3 . . . . c |
- 13. c | 27 99 48 146 40.10819 c |
- 14. c | 10 75.5 48 103 27.5 c |
- 15. c | 146 35 20 49 11.89538 c |
- hline 8c -hline 10c -hline 10c -hline 10c -hline 10
- 16. c | 48 46 8 103 41.04469 c |
- hline 8c -hline 10c -hline 10c -hline 10c -hline 10

You can plot the florentine marriage network with *wealth* as node label to better understand how these values come about:

```stata
. nwplot flomarriage, label(wealth)
```

## Supported network types

Binary: yes. Directed: yes, via `mode(outgoing|incoming|both|either)`. Weighted: yes by default (neighbor attribute values weighted by tie strength); `noweight` treats all ties as binary. Signed: not checked. Two-mode: not checked.

## See also

- [nwneighbor](nwneighbor)

- last certified : 24 Aug 2026
