---
title: "nwreplace"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Replace network"
---

# `nwreplace`

Replace network

## Syntax

```stata
nwreplace 
netname[subnet]
=netexp
[ifego]
[ifalter]
[if]
```

## Description

Replaces a whole network, a subnetwork or specific tie values with a network expression. This command is the network version of `replace`. A [network expression](netexp) is very similar to a normal `expression` in Stata, but it also accepts [netnames](netname).

One can also replace tie values in networks by 1) loading a network as Stata variables (see [nwload](nwload)), 2) changing the Stata variables (see `replace`) and 3) syncing Stata variables and network afterwards (see [nwsync](nwsync)). However, replacing the networks directly (as shown below) is the faster and preferred method.

One can also change the entire adjaceny matrix of a network with an existing Mata matrix using [nwreplacemat](nwreplacemat).

## Supported network types

Binary: yes. Directed: yes - a replaced value is written to the exact (ego,alter) cell addressed, respecting direction. Weighted: yes, natively - this command's entire purpose is writing arbitrary tie values via an expression. Signed: yes, any value including negative can be assigned. Two-mode: not checked, but not expected to need any - a direct cell/subset write by node identity.

**Undirected networks - important**: a bracket write such as **nwreplace mynet[2,1] = 55** addresses EXACTLY the (2,1) cell - it does NOT also write the mirror (1,2) cell, even though *mynet* is declared undirected. Writing only one side of a pair can leave the network's own stored matrix genuinely asymmetric while it still reports **directed: false** (this is deliberate - [nwreplace](nwreplace) never forces symmetry on your behalf, the same way [nwreplacemat](nwreplacemat)'s own underlying **set_edge()** never does either). If you want a symmetric edit, write both cells explicitly (**nwreplace mynet[2,1] = 55** then **nwreplace mynet[1,2] = 55**), or use [nwreplacemat](nwreplacemat)/[nwsym](nwsym) to replace or symmetrize the whole matrix at once. Most analysis commands read an undirected network through an accessor that symmetrizes on the fly (taking the max of both directions) and so never notice a one-sided asymmetry left this way - but any command working directly off the network's own stored ties (rather than through that accessor) will see the asymmetry exactly as written.

## Stored results

**Scalars**

- **r(symmetric)** 1 if the network's updated adjacency matrix is symmetric, 0 otherwise
- **r(valued)** 1 if the network is valued, 0 otherwise

## See also

- [nwreplacemat](nwreplacemat), [nwsync](nwsync), [nwload](nwload)
