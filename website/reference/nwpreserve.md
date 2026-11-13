---
title: "nwpreserve"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Preserve and restore network data"
---

# `nwpreserve`

Preserve and restore network data

## Syntax

```stata
Preserve network data
nwpreserve
    Restore network data
nwrestore
```

## Description

`nwpreserve` preserves network data by temporarily saving the current network dataset (including all normal Stata variables) in the working directory. Calling `nwpreserve` again before `nwrestore` exits with an error ("Already preserved"), as Stata's own `preserve` does.

`nwrestore` restores network data previously preserved (including all Stata variables).

## Examples

Preserve a network, drop it, then restore it:

```stata
. nwclear
. nwrandom 5, prob(.4) name(mynet)
. nwpreserve
. nwdrop mynet
. nwset
. nwrestore
. nwset
```

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
