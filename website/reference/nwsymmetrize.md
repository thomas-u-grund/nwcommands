---
title: "nwsymmetrize"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Symmetrize a network (alias for nwsym)"
---

# `nwsymmetrize`

Symmetrize a network (alias for nwsym)

## Syntax

```stata
nwsymmetrize
[netname]
[,
mode(mode)
check
generate(newnetname)
replace]
```

## Description

`nwsymmetrize` is an exact alias for [nwsym](nwsym) - it forwards every argument and option unchanged and returns the identical stored results. It exists only so the verb `symmetrize` is directly discoverable by name, matching the package's spelled-out-verb naming convention used elsewhere (e.g. [nwcollapse](nwcollapse), [nwexpand](nwexpand), [nwrecode](nwrecode)). [nwsym](nwsym) itself is fully supported - see its own help file for the complete option reference, mode() details, and worked examples.

## Network types

As [nwsym](nwsym). See [nwnetworktypes](nwnetworktypes).

## Examples

This loads the Glasgow data and symmetrizes the network *glasgow1*, identically to `nwsym glasgow1`.

```stata
. nwwebuse glasgow, nwclear
. nwsymmetrize glasgow1
```

## Stored results

See [nwsym](nwsym).

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
