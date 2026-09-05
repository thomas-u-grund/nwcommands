---
title: "nwpreserve"
parent: "Command reference"
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

`nwpreserve` preserves network data by temporarily saving the current network dataset (including all normal Stata variables) in the working directory.

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

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - saves/restores the full working state (every loaded network and its own directed/valued/two-mode status, plus the Stata dataset), independent of any of these properties.
