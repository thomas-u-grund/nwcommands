---
title: "nwcurrent"
parent: "Command reference"
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
| `id(int)` | Originl network ID of the the network that should be made the current network |

## Description

Almost all nwcommands allow that a [netname](netname) or [netlist](netlist) is optional. When no network is specified in such a case, by default, the nwcommands apply the command to the *current network*.

The *current network* is simply the last network that has been [set](nwset), [imported](nwtopical) or [generated](nwtopical). This is a convenient way to way access the latest network one worked with.

`nwcurrent` changes the *current network*. Typically, it can be used with a [netname](netname). When used with **id()**, the network ID refers to the original order the networks were generated in. The command also returns some information about the *current network* in the r() vector.

## Examples

- . nwwebuse florentine
- . nwcurrent
- hline 40
- Current network: flomarriage
- Number of nodes: 16
- hline 40

- . nwcurrent flobusiness
- hline 40
- Current network: flobusiness
- Number of nodes: 16
- hline 40

## Supported network types

Not applicable - reports or sets which network is the "current" one; does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

## Stored results

- Scalars:
- r(networks) number of networks

- Macros:
- r(current) name of current network
