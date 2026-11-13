---
title: "nwunab"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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

This is the network version of `unab`. `nwunab` expands and unabbreviates a [netlist](netlist) of existing networks, placing the results in the local macro *lmacname*.  `nwunab` is a low-level parsing command and works in exactly the same way as `unab`.  One can also use [nwds](nwds) to unabbreviate network lists. The [_nwsyntax](nwprogramming) command is a high-level parsing command that, among other things, also unabbreviates network lists; see [_nwsyntax](nwprogramming).

## Options

- `min(`*#*`)` specifies the minimum number of networks
- allowed. The default is hi:min(1).

- `max(`*#*`)` specifies the maximum number of networks
- allowed. By default the limit of `unab` applies.

## Examples

```stata
. nwwebuse glasgow, nwclear
. nwunab nets : glasg*
. di `nets'
glasgow1 glasgow2 glasgow3
```

## Stored results

- **Macros**
- **r(netlist)** --- the expanded list of networks
- **r(networks)** --- number of networks in the list

## See also

- `unab`, [nwds](nwds), [_nwsyntax](nwprogramming)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
