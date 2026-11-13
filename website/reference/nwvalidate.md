---
title: "nwvalidate"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
```

## Description

Checks if a network *[netname](netname)* already exists. In case it does, the command makes a suggestion for an alternative name. Normally, the command returns *netname_1*. If that also exists, the commands returns *netname_2*.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Examples

```stata
. nwclear
. nwwebuse florentine
. nwvalidate flobusiness
. return list
```

## Stored results

- **r(exists)** --- "true" when network name already exists, "false" otherwise
- **r(tryname)** --- network name that is validated
- **r(validname)** --- valid name in case the tryname already exists (otherwise the tryname)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
