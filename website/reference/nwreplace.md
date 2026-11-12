---
title: "nwreplace"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Replace a network"
---

# `nwreplace`

Replace a network

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

## Stored results

- **Scalars**
- **r(symmetric)** --- 1 if the network's updated adjacency matrix is symmetric, 0 otherwise
- **r(valued)** --- 1 if the network is valued, 0 otherwise

## See also

- [nwreplacemat](nwreplacemat), [nwsync](nwsync), [nwload](nwload)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
