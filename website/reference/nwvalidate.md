---
title: "nwvalidate"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Validate network name"
---

# `nwvalidate`

Validate network name

## Syntax

```stata
nwvalidate 
netname
```

## Description

Checks if a network *[netname](netname)* already exists. In case it does, the command makes a suggestion for an alternative name. Normally, the command returns *netname_1*. If that also exists, the commands returns *netname_2*.

## Examples

```stata
. nwclear
. nwwebuse florentine
. nwvalidate flobusiness
. return list
```

## Supported network types

Not applicable - a pure Stata-variable/network-name-collision check; does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

## Stored results

- **r(exists)** "true" when network name already exists, "false" otherwise
- **r(tryname)** network name that is validated
- **r(validname)** valid name in case the tryname already exists
- last certified : 25 Aug 2026
