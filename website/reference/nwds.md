---
title: "nwds"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "List loaded networks, in the style of Stata's own `ds`"
---

# `nwds`

List loaded networks, in the style of Stata's own `ds`

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
| `not` | Invert the selection - list every *other* loaded network instead of the ones
named in *netlist* |
| *ds_options* | Any other option is forwarded to Stata's own `ds` (e.g. `varwidth`,
which controls the display's own column width) |

## Description

`nwds` lists the networks currently loaded in memory, reusing Stata's own `ds` command for the display (network names are shown the way `ds` shows variable names). With no *netlist*, every loaded network is listed. **r(netlist)** always returns the exact list of network names shown.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwds
. nwds, alpha
```

## Supported network types

Not applicable - a pure network-listing utility (in the style of Stata's own `ds`); does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

## Stored results

**Macros**

- **r(netlist)** the exact list of network names shown

## See also

- `ds`, [nwcurrent](nwcurrent), [nwclear](nwclear)

- last certified : 24 Aug 2026
