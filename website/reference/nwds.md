---
title: "nwds"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "List the networks in memory (like ds)"
---

# `nwds`

List the networks in memory (like ds)

## Syntax

```stata
nwds
[netlist]
[,
alpha
not
ds_options]
```

| | |
|---|---|
| `alpha` | List network names in alphabetical order (the default is creation order) |
| `not` | Invert the selection - list every *other* loaded network instead of the ones named in *netlist* |
| *ds_options* | Any other option is forwarded to Stata's own `ds` (e.g. `varwidth`, which controls the display's own column width) |

## Description

`nwds` lists the networks currently loaded in memory, reusing Stata's own `ds` command for the display (network names are shown the way `ds` shows variable names). With no *netlist*, every loaded network is listed. **r(netlist)** always returns the exact list of network names shown.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwds
. nwds, alpha
```

## Stored results

- **Macros**
- **r(netlist)** --- the exact list of network names shown

## See also

- `ds`, [nwcurrent](nwcurrent), [nwclear](nwclear)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
