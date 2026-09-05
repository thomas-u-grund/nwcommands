---
title: "nwrestore"
parent: "Command reference"
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

`nwrestore` restores network data (including all normal Stata variables) previously saved by [nwpreserve](nwpreserve.md) - the network-aware counterpart of Stata's own `preserve`/ `restore` pair. If nothing was preserved (or it was already restored once), `nwrestore` reports "Nothing to restore" and does nothing further.

The temporary file `nwrestore` reads from is deleted once restored, so a given [nwpreserve](nwpreserve.md) call can only be restored once - exactly like Stata's own `preserve`/`restore`.

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

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - restores the full working state saved by [nwpreserve](nwpreserve.md), independent of any of these properties.
