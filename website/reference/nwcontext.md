---
title: "nwcontext"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
replace
force]
```

| | |
|---|---|
| `attribute(varname)` | Numeric attribute variable |
| `stat`(*[statistic](nwcontext)*) | Statistic that is used to calculate context variable for node i from attributes of network neighbors |
| `mode`(*[context](nwcontext)*) | Define network neighbors of node i as either nodes j who receive ties from i, send ties to j or both |
| `generate(newvarname)` | Name of the context variable to be generated; `generate()` or `mat()` is required |
| `mat(string)` | Store the result in a Mata matrix (a column vector) of this name; with `generate()` as well, both are created |
| `noweight` | Ignore valued ties and treats all as binary |
| `replace` | Replace `generate()`'s target variable if it already exists |
| `force` | Run the command although its matrices would not fit in memory (it stops with r(484) above 12 GB otherwise) |

## Description

`nwcontext` generates a context variable, which holds information about the *attribute values* of a node's network neighbors.

For each node the set of network neighbors is specified in `mode()`, by default *context* = **outgoing**. This means that the new context variable *newvarname*[i] is calculated based on an all values *varname*[j], for which there is a tie from node *i* to node *j*. A network neighborhood of node *i* can be either 1) all nodes *j* to whom i has outgoing ties (default), 2) all nodes *j* from whom *i* receives incoming ties, or 3) both. In the case of valued ties *varname*[j] is weighted accordingly: **mean** and **sum** are the weighted mean and the weighted sum of *varname*[j] with the tie values *y_ij* as weights; **max** and **min** are the largest and smallest product *y_ij* * *varname*[j], and **sd** is computed from the deviations of these products from the weighted mean (the root of the sum of their squares divided by the sum of the tie values). On a valued network max, min and sd are therefore in the units of tie value times attribute, not attribute values; `noweight` gives the statistics of the neighbors' attribute values themselves.

After that a *statistic* defined in `stat()` is calculated from all weigthed *varname*[j]. By default, the mean is calculated. More formally:

*newvarname*[i] = *stat*(*varname*[j]), for all *j* with *y_ij* > 0

When used with the defaults, the command calculates for each node *i* the mean score of its network neighbors on `varname`. Valid statistics are: the** mean**, the **max**, the **min**, the **sum** and the **sd** of `varname`.

Sometimes, however, one might want to calculate statistics including the attribute of ego. One can achieve this by using the ego-extended version of each statistic (**meanego**,  **maxego**,  **minego**,  **sumego** and **sdego**), which are calculated in this way:

*newvarname*[i] = *stat*(*varname*[j]), for all *j* with *y_ij* > 0 or j == i

## Scope

Directed and undirected, weighted and unweighted, one-mode and two-mode.

## Remarks

In the case of undirected networks, no * mode* option needs to be specified.

By default, nodes with missing attributes are excluded from the calculation.

## Network types

**Directed:** the neighbors follow `mode(outgoing|incoming|both|either)`. **Valued:** attribute values are weighted by tie values by default; `noweight` ignores them. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The statistics are computed on the dense network and three *n*-by-*n* matrices are held at once. Above about 22,000 nodes (12 GB) the command stops at once with r(484) and names [nwaltergen](nwaltergen) as the alternative: it computes the mean, sum, minimum, maximum and standard deviation of the attribute of the neighbors from the stored ties and works at 100,000 nodes and more. Option `force` runs the command anyway.

## Examples

This example loads the Florentine marriage data. The variable *wealth* indicates how rich each family is. ** nwcontext** generates different variables: *w_avg* = average wealth of network neighbors,  *w_min* = wealth of poorest network neighbor, *w_max* = wealth of richest network neighbor, *w_sd* = standard deviation of wealth over network neighbors.

```stata
. nwwebuse florentine
. nwcontext flomarriage, attribute(wealth) generate(w_avg)
. nwcontext flomarriage, attribute(wealth) generate(w_min) stat(min)
. nwcontext flomarriage, attribute(wealth) generate(w_max) stat(max)
. nwcontext flomarriage, attribute(wealth) generate(w_sd) stat(sd)

. list w*

    +----------------------------------------------------+
    | wealth      w_avg      w_min      w_max       w_sd |
    |----------------------------------------------------|
 1. |     10        103        103        103          0 |
 2. |     36   47.66667          8        103   40.33471 |
 3. |     55       61.5         20        103       41.5 |
 4. |     44   67.66666          8        146   57.86382 |
 5. |     20   83.33334         49        146   44.37968 |
    |----------------------------------------------------|
 6. |     32         36         36         36          0 |
 7. |      8       42.5         36         48   4.330127 |
 8. |     42          8          8          8          0 |
 9. |    103         31         10         55   17.26268 |
10. |     48         10         10         10          0 |
    |----------------------------------------------------|
11. |     49         70         20        146     54.626 |
12. |      3          .          .          .          . |
13. |     27         99         48        146   40.10819 |
14. |     10       75.5         48        103       27.5 |
15. |    146         35         20         49   11.89538 |
    |----------------------------------------------------|
16. |     48         46          8        103   41.04469 |
    +----------------------------------------------------+
```
You can plot the florentine marriage network with *wealth* as node label to better understand how these values come about:

```stata
. nwplot flomarriage, label(wealth)
```

## See also

- [nwneighbor](nwneighbor), [nwegoplot](nwegoplot)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
