---
title: "nwclear"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Clear all networks and variables from memory"
---

# `nwclear`

Clear all networks and variables from memory

## Syntax

```stata
nwclear
```

## Description

Clears all networks and variables from memory. This is the network extension of `clear`. One can also just drop some or all networks using [nwdrop](nwdrop).

Note that Stata's own `clear` (or `clear all`) does not remove the networks held by nwcommands; only `nwclear` does (or [nwdrop](nwdrop) for chosen networks).

This example loads network data and clears everything afterwards.

```stata
. nwwebuse glasgow
. nwclear
```
Alternatively, one can also just drop networks. This does not delete the Stata variables that are not associated with networks. For more information see [nwdrop](nwdrop).

```stata
. nwdrop _all
```

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## See also

- [nwdrop](nwdrop), `clear`

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
