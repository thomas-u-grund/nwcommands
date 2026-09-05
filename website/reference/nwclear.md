---
title: "nwclear"
parent: "Command reference"
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

Clears all networks and variables from memory. This is the network extension of `clear`. One can also just drop some or all networks using [nwdrop](nwdrop.md).

This example loads network data and clears everything afterwards.

```stata
. nwwebuse glasgow
. nwclear
```
Alternatively, one can also just drop networks. This does not delete the Stata variables that are not associated with networks. For more information see [nwdrop](nwdrop.md).

```stata
. nwdrop _all
```

## Supported network types

Not applicable - clears all networks and Stata variables from memory unconditionally, independent of any network's own properties.

## See also

- [nwdrop](nwdrop.md), `clear`
- last certified : 24 Aug 2026
