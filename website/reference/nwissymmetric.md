---
title: "nwissymmetric"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Check whether a network is symmetric"
---

# `nwissymmetric`

Check whether a network is symmetric

## Syntax

```stata
nwissymmetric 
[netname]
```

## Description

`nwissymmetric` simply checks if the underlying adjacency matrix of network [netname](netname) is symmetric, regardless of whether the network is assigned to be directed or undirected (see [nwname](nwname)). An adjacency matrix *M* is symmetric when *M_ij == M_ji*. Returns *r(issymmetric)* in the return vector.

This command can be useful for programming, when one wants to detect if a network should be undirected.

For example, [nwimport](nwimport) automatically checks if a network (e.g. Ucinet fullmatrix) is symmetric and if yes, imports the network as undirected.

## Examples

```stata
. nwwebuse florentine
. nwissymmetric flomarriage
. return list

scalars:
```
- **r(issymmetric) = 1**

Note: **r(issymmetric)** is a plain numeric 0/1 scalar - unlike the **true**/**false** string macros most other boolean-flag results in this group use (e.g. [nwname](nwname)'s **r(directed)**), since it is a computed test result rather than a stored network property.

## See also

- [nwsym](nwsym), [nwname](nwname)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
