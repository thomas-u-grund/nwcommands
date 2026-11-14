---
title: "netexp"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Network expression and function"
---

# `netexp`

Network expression and function

## Assigment expression

A network expression is similar to a normal expression in Stata or Mata, except that it works on the element-by-element level of the underlying adjacency matrices of the involved networks.

Network expressions accept [netnames](netname), `varnames` and almost all operators that one knows from Stata or Mata. Here, the network expression consists of the simple network *flomarriage* and is assigned it to *mynet1*.

```stata
. nwwebuse florentine
. nwgen mynet1 = flomarriage
```
But one can also include other elements in a network expression, e.g.:

```stata
. nwgen mynet2 = 2 * flomarriage
. nwgen mynet3 = exp(flomarriage)
```
In more complicated network expressions, all operators are performed on an element-by-element basis. The next expression returns the overlap of two networks.

```stata
. nwgen overlap1 = flobusiness * flomarriage
```
Practically, a network expression deals with the underlying Mata matrices of the networks and transforms simple operators (such as +, -, *, /) in ` Mata colon-operators`. But essentially, everything that can be done in a Mata expression can be done in a network expression as well.

Network expressions basically provide easy access to the underlying adjacency matrices of networks without having to deal with Mata.

## Conditional expression

Network expressions can also be used in `if` conditions (see e.g. [nwreplace](nwreplace)). In this case, a network expression is again evaluated on an element-by-element basis and operations are only performed for the dyads for which the expression is true. For example:

```stata
. nwwebuse florentine
. nwgen overlap2 = flobusiness
. nwreplace overlap2 = flomarriage if flobusiness == 1
```
This code generates the network *overlap2* as a copy of *flobusiness*. And then it replaces the dyads in this new network with the values of the dyads in network *flomarriage*, but only for the dyads where *flobusiness* == 1. Ultimately, this also generates the overlap between the two networks *flomarriage* and *flobusiness*.

## Advanced programming with network expression

When writing own network programs one can also include network expressions using **_nwevalnetexp**. The syntax for this command is:

- **_nwevalnetexp** *netexp* % *matamatrix*

This evaluates whatever is in *netexp* and generates a new mata matrix *matatrix* with the result of the network expression.

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
