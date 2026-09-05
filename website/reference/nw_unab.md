---
title: "nw_unab"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Unabbreviate network list"
---

# `nw_unab`

Unabbreviate network list

## Syntax

```stata
Expand and unabbreviate network lists
nw_unab lmacname : netlist [,
        min(#) max(#)]
```

## Description

This is the network version of `unab`. `nwunab` expands and unabbreviates a [netlist](netlist.md) of existing networks, placing the results in the local macro *lmacname*.  `nwunab` is a low-level parsing command and works in exactly the same way as `unab`.  One can also use [nwds](nwds.md) to unabbreviate network lists. The `nw_syntax` command is a high-level parsing command that, among other things, also unabbreviates network lists; see `nw_syntax`.

## Options

- `min(`*#*`)` specifies the minimum number of networks
- allowed. The default is hi:min(1).

- `max(`*#*`)` specifies the maximum number of networks
- allowed.

## Examples

```stata
. nwwebuse florentine, nwclear
. nw_unab nets : flo*
. di "`nets'"
```
- flobsuiness flomarriage

## See also

- `unab`, [nwds](nwds.md), `nw_syntax`

- last certified : 21 Aug 2026
