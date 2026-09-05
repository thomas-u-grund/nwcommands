---
title: "nwsync"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Sync network with Stata variables"
---

# `nwsync`

Sync network with Stata variables

## Syntax

```stata
nwsync
[netname]
[,
label
fromstata]
```

| | |
|---|---|
| `label` | Sync the node labels |
| `fromstata` | Change the direction of the sync |

## Description

Networks ultimately exist as Mata objects. However, one can also load them as Stata variables that represent the adjacency matrix of a network (see [nwload](nwload)). Normally, when a network is changed through another [nwcommand](nwcommands) the Stata variables (if they exist) are automatically synced. But one can also invoke such a sync explicitly. Furthermore, [nwsync](nwsync) can be used to sync the other way around, i.e. one can change the values of the Stata variables that represent the network and sync the network (that lives in Mata).

## Options

`fromstata` Change the direction of the sync, i.e. the network is updated based on the Stata variables that represent the network.

`label` Run an additional [_nwdatasync](_nwdatasync) alignment pass (matching node identity against **_nwnode**) before the normal variable sync below. There is no separate node-label concept or **_nodelab** variable in this package - a node's name (see [nwnoderename](nwnoderename)) is its only label, and this option does not sync it; the name once documented here was inaccurate and has been corrected.

## Remarks

One can use [nwload](nwload) and [ nwsync, fromstata](nwsync) to replace tie values in a network. For example,

```stata
. nwwebuse florentine, nwclear
. nwload flomarriage
. replace acciaiuoli = 99 in 2
. nwsync flomarriage, fromstata
```
However, the preferred method to change the same tie value would be using [nwreplace](nwreplace) instead:

```stata
. nwwebuse florentine, nwclear
. nwreplace flomarriage[2,1] = 99
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - syncs node labels/dataset state only; does not read or depend on any network's own directed/valued/two-mode status or tie values.

## See also

- [nwload](nwload), [nwreplace](nwreplace), [nwname](nwname)
