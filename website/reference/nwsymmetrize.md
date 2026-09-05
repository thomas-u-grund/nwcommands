---
title: "nwsymmetrize"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Symmetrize network (alias for [nwsym](nwsym))"
---

# `nwsymmetrize`

Symmetrize network (alias for [nwsym](nwsym))

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

`nwsymmetrize` is an exact alias for [nwsym](nwsym) - it forwards every argument and option unchanged and returns the identical stored results. It exists only so the verb `symmetrize` is directly discoverable by name, matching the package's spelled-out-verb naming convention used elsewhere (e.g. [nwcollapse](nwcollapse), [nwexpand](nwexpand), [nwrecode](nwrecode)). [nwsym](nwsym) itself is unaffected and remains fully supported - see its own help file for the complete option reference, mode() details, and worked examples.

## Examples

This loads the Glasgow data and symmetrizes the network *glasgow1*, identically to `nwsym glasgow1`.

```stata
. nwwebuse glasgow, nwclear
. nwsymmetrize glasgow1
```

## Supported network types

Identical to [nwsym](nwsym) - see that command's help file.

## Stored results

See [nwsym](nwsym).

- last certified : 28 Aug 2026
