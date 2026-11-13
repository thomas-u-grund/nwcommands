---
title: "nwrestore"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Restore network data previously preserved"
---

# `nwrestore`

Restore network data previously preserved

## Syntax

```stata
nwrestore
```

## Description

`nwrestore` restores network data (including all normal Stata variables) previously saved by [nwpreserve](nwpreserve) - the network-aware counterpart of Stata's own `preserve` / `restore` pair. If nothing was preserved (or it was already restored once), `nwrestore` reports "Nothing to restore" and does nothing further.

The temporary file `nwrestore` reads from is deleted once restored, so a given [nwpreserve](nwpreserve) call can only be restored once - exactly like Stata's own `preserve` / `restore`.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

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

## Also see

- [nwpreserve](nwpreserve), `restore`, `preserve`

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
