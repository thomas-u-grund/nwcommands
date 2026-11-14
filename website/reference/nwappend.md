---
title: "nwappend"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Append a network dataset"
---

# `nwappend`

Append a network dataset

## Syntax

```stata
nwappend using filename [, force]
You may enclose filename in double quotes and must do so if
filename contains blanks or other special characters.
```

| | |
|---|---|
| `force` | if a network in *using dataset* has the same name as one already loaded, auto-renumber the incoming network to a fresh name instead of erroring (see [nwvalidate](nwvalidate)) - leaves the existing network untouched, unlike `replace` elsewhere in this group (e.g. [nwset](nwset)), which overwrites in place |

## Description

This command appends a Stata-format network dataset (*using dataset*) to the currently loaded network data (*master dataset*). If a *`filename`* is specified without an extension, `.nwdta` is assumed.

## Remarks

The command stops with an error when the same network names appear in the master and in the using dataset unless option **force** is used. This option changes the network names of the *using data* (see [nwvalidate](nwvalidate)).

Node attributes are merged together. When the same nodes appear in both the *master* and the *using dataset* with the same node attribute, the node attribute of the *using dataset* is used.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## See also

- [nwuse](nwuse), [nwwebuse](nwwebuse), [nwsave](nwsave), `append`

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
