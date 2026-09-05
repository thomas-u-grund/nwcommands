---
title: "nwunab"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Unabbreviate network list"
---

# `nwunab`

Unabbreviate network list

## Syntax

```stata
Expand and unabbreviate network lists
nwunab lmacname : netlist [,
        min(#) max(#)]
```

## Description

This is the network version of `unab`. `nwunab` expands and unabbreviates a [netlist](netlist.md) of existing networks, placing the results in the local macro *lmacname*.  `nwunab` is a low-level parsing command and works in exactly the same way as `unab`.  One can also use [nwds](nwds.md) to unabbreviate network lists. The `nw_syntax` command is a high-level parsing command that, among other things, also unabbreviates network lists; see `nw_syntax`.

## Options

- `min(`*#*`)` specifies the minimum number of networks
- allowed. The default is hi:min(1).

- `max(`*#*`)` specifies the maximum number of networks
- allowed. The system maximum is 9999.

## Examples

```stata
. nwwebuse glasgow, nwclear
. nwunab nets : glasg*
. di `nets'
```
- glasgow1 glasgow2 glasgow3

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - resolves/expands a network name list only; does not read or depend on any network's own directed/valued/two-mode status or tie values.

## See also

- `unab`, [nwds](nwds.md), `nw_syntax`
