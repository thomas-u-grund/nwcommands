---
title: "nwcurrent"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Report and set current network"
---

# `nwcurrent`

Report and set current network

## Syntax

```stata
nwcurrent 
[netname]
[,
id(int)]
```

| | |
|---|---|
| `id(int)` | Original network ID of the network that should be made the current network |

## Description

Almost all nwcommands allow that a [netname](netname) or [netlist](netlist) is optional. When no network is specified in such a case, by default, the nwcommands apply the command to the *current network*.

The *current network* is simply the last network that has been [set](nwset), [imported](nwtopical) or [generated](nwtopical). This is a convenient way to way access the latest network one worked with.

`nwcurrent` changes the *current network*. Typically, it can be used with a [netname](netname). When used with **id()**, the network ID refers to the original order the networks were generated in. The command also returns some information about the *current network* in the r() vector.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Examples

```stata
. nwwebuse florentine
. nwcurrent
----------------------------------------
   Current network:  flomarriage
   Number of nodes:  16
----------------------------------------

. nwcurrent flobusiness
----------------------------------------
   Current network:  flobusiness
   Number of nodes:  16
----------------------------------------
```

## Stored results

- **Scalars**
- **r(networks)** --- number of networks
- **r(nodes)** --- number of nodes of the current network

- **Macros**
- **r(current)** --- name of current network

## Also see

- [nwname](nwname), [nwload](nwload), [nwset](nwset)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
