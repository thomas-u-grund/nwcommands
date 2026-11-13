---
title: "nwdyadprob"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate a network based on tie probabilities"
---

# `nwdyadprob`

Generate a network based on tie probabilities

## Syntax

```stata
nwdyadprob 
[netname]
[,
mat(matamatrix)
density(float)
weights(p1, p2,...)
name(netname)
xvars
undirected
labs(lab1 lab2 ...)]
```

| | |
|---|---|
| `mat`(*matrix*) | Mata matrix (or Mata expression) with tie probabilities |
| `density(float)` | density of the new network |
| `weights(p1, p2,...)` | probabilities p_k for tie weights k |
| `name(netname)` | name of the new random network |
| `xvars` | generate Stata variables for the network |
| `undirected` | generate undirected network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |

## Description

`nwdyadprob` generates a (un-)directed random network where each tie *x_ij* has the probability *p_ij* to exist. The values for *p_ij* are derived either 1) from the tie values of network [netname](netname) or 2) from a Mata matrix (or Mata expression) specified in **mat()**. When both are given, *netname* is used. The command can be used to create all sorts of networks.

When no **density()** is given, each tie *x_ij* is drawn independently with probability *p_ij*. Let *e_ij* be the tie values of network [netname](netname). When all of them lie between 0 and 1, *p_ij = e_ij*. Otherwise they are transformed to probabilities first: *p_ij* = invlogit(*e_ij*). The values in **mat()** are used as they are.

With **density(***d***)**, exactly *n*(*n*-1)*d* ties (half as many with `undirected`) are drawn without replacement, with inclusion probabilities proportional to the tie values *e_ij* of [netname](netname) (or to the values in **mat()**). The values are relative weights and are used as they are, also when they are larger than 1; they cannot be negative. The command stops with an error when fewer dyads have a non-zero weight than ties are requested.

With option **weights(***p1, p2,...***)** the command generates a weighted network. Here, *p_k* stands for the probability to sample tie weight *k*. The probabilities *p1, p2..., pn* do not necessarily have to sum up to one; they are standardized.

## Remarks

The program needs no additional packages: the weighted sampling of ties is built in (it gives the same sample as the user-written **gsample**, for the same random-number seed). Nothing is downloaded or installed.

## Network types

**Directed:** directed by default; `undirected` gives an undirected network. **Valued:** `weights()` draws tie values, only without `density()` (with `density()` it stops with an error). **Two-mode:** not applicable - the command always creates a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

With `mat()` the probabilities are an *n*-by-*n* matrix held by you plus three copies in the command: 20,000 nodes 3.1 seconds. `density()` weights all dyads and is refused above 7,071 nodes.

## Example

The following example generates a network where ties are more likely to exist between nodes with similar *gender* and different *race*.

First, we generate two variables *gender* and *race*.

```stata
. nwclear
. set obs 10
. gen gender = (_n > 5) + 2
. gen race = int(0.5 + uniform())
```
Next, we generate two expanded networks for each of the two variables (see [nwexpand](nwexpand)). Basically, we generate for each variable a matrix *M* where *M_ij* = 1 when nodes *i* and *j* have the same score on an attribute. And these matrices *M* are used to generate new networks.

```stata
. nwexpand gender
. nwexpand race
```
This creates the following networks.

```stata
. nwset
(2 networks)
--------------------
        same_gender
        same_race
```
Having a closer look at the new network *same_gender*, shows the network that [nwexpand](nwexpand) created.

```stata
. nwsummarize same_gender, matonly

       1    2    3    4    5    6    7    8    9   10
   +---------------------------------------------------+
 1 |   0                                               |
 2 |   1    0                                          |
 3 |   1    1    0                                     |
 4 |   1    1    1    0                                |
 5 |   1    1    1    1    0                           |
 6 |   0    0    0    0    0    0                      |
 7 |   0    0    0    0    0    1    0                 |
 8 |   0    0    0    0    0    1    1    0            |
 9 |   0    0    0    0    0    1    1    1    0       |
10 |   0    0    0    0    0    1    1    1    1    0  |
   +---------------------------------------------------+
```
In the next step, we generate a network *dyadweight* on the basis of *same_gender* and *same_race*.

As an example, we want that in the final network 1) ties between nodes with the same gender are overrepresented and 2) ties between nodes with the same race are underrepresented. This generates tie probabilitities according to this request.

```stata
. nwgen dyadweight = exp(5 * same_gender) * exp((-5) * same_race)
```
Check out the tie values created in this way:

```stata
. nwsummarize dyadweight, matonly
```
Finally, we create a new network based on tie probabilities defined in network *dyadweight*.

```stata
. nwdyadprob dyadweight, density(0.1)
```
The result can be nicely plotted in the following way:

```stata
. nwplot, color(gender) layout(circle) title("gender, homophily = exp(5)")
. graph save g4, replace
. nwplot, color(race) layout(circle) title("race, homophily = exp(-5)")
. graph save g5, replace
. graph combine g4.gph g5.gph
```

## See also

- [nwhomophily](nwhomophily), [nwgen](nwgen), [nwexpand](nwexpand)

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
