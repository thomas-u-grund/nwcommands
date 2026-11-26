---
title: "nwvalidate"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Validate a network name"
---

# `nwvalidate`

Validate a network name

## Syntax

```stata
nwvalidate 
netname
[,
self(netname)]
```

| | |
|---|---|
| `self(netname)` | if the checked name equals this name (for example the current name of the network that is renamed), it counts as free: **r(validname)** is the name itself and **r(exists)** is "false" |

## Description

Checks if a network *[netname](netname)* already exists. In case it does, the command makes a suggestion for an alternative name. Normally, the command returns *netname_1*. If that also exists, the commands returns *netname_2*.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Examples

```stata
. nwclear
. nwwebuse florentine, nwclear
. nwvalidate flobusiness
. return list
```

## Stored results

- **r(exists)** --- "true" when network name already exists, "false" otherwise
- **r(tryname)** --- network name that is validated
- **r(validname)** --- valid name in case the tryname already exists (otherwise the tryname)

---

*nwcommands version 3.39.0, 26 November 2026* ([check your installed version](nwversion))
