---
title: "nwappend"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Append network dataset"
---

# `nwappend`

Append network dataset

## Syntax

```stata
nwappend using filename [, force]
You may enclose filename in double quotes and must do so if
filename contains blanks or other special characters.
```

| | |
|---|---|
| `force` | if a network in *using dataset* has the same name as one already loaded, auto-renumber the incoming network to a fresh name instead of erroring (see help:nwvalidate) - leaves the existing network untouched, unlike `replace` elsewhere in this group (e.g. [nwset](nwset)), which overwrites in place |

## Description

This command appends a Stata-format network dataset (*using dataset*) to the currently loaded network data (*master dataset*). If a *`filename`* is specified without an extension, `.nwdta` is assumed.

## Remarks

The command stops with an error when the same network names appear in the master and in the using dataset unless option **force** is used. This option causes changes the network names of the *using data* (see help:nwvalidate).

Node attributes are merged together. When the same nodes appear in both the *master* and the *using dataset* with the same node attribute, the node attribute of the *using dataset* is used.

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - appends node-level Stata data from another dataset, independent of any of these properties.

## See also

- [nwuse](nwuse), [nwwebuse](nwwebuse), [nwsave](nwsave), `append`

- last certified : 24 Aug 2026
