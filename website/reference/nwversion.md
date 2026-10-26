---
title: "nwversion"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Version of nwcommands and of the installed model packages"
---

# `nwversion`

Version of nwcommands and of the installed model packages

## Syntax

```stata
nwversion
```

## Description

`nwversion` shows the version and release date of the `nwcommands` core package and, for each of the four model packages `nwsaom`, `nwergm`, `nwdynam` and `nwrem`, whether it is installed and in which version. The model packages are installed separately (`nwinstall, models`, see [help nwinstall](nwinstall)); each has its own `version` subcommand, for example `nwsaom version`.

Versions follow semantic versioning (MAJOR.MINOR.PATCH). A given release can be installed by its tag, for example `net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.0.0/") replace`.

## Stored results

- `nwversion` stores `r(version)` (for example `3.0.0`) and `r(date)` (for example `24oct2026`) in `r()`.

---

*nwcommands version 3.9.0, 26 October 2026* ([check your installed version](nwversion))
