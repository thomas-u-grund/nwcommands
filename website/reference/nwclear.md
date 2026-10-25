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

## Supported network types

Not applicable - clears all networks and Stata variables from memory unconditionally, independent of any network's own properties.

## See also

- [nwdrop](nwdrop), `clear`
- last certified : 24 Aug 2026

---

*nwcommands version 3.6.0, 26 October 2026* ([check your installed version](nwversion))
