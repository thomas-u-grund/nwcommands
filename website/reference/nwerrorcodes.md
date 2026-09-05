---
title: "nwerrorcodes"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "What this package's own custom return codes mean"
---

# `nwerrorcodes`

What this package's own custom return codes mean

## Description

Most errors raised by `nw*` commands are Stata's own standard return codes, used for their usual meaning (e.g. **198** invalid syntax, **99** a Stata variable already exists). A number of recurring, network-specific situations do not have a natural existing Stata code, so this package defines its own small set of custom codes instead of inventing a new number per command. This page documents every one of them - if you catch one of these programmatically (e.g. `capture ...` / `if _rc == 482`), this is the authoritative list of what it means and which commands can raise it.

These codes are also available as named local macros from `unw_defs.ado` (used internally by this package's own commands) - e.g. ````errNWsNotFound``'` instead of the bare number **482**.

## Examples

Catch a package-specific error code programmatically:

```stata
. nwclear
. capture nwname doesnotexist
. display _rc
. if _rc == 482 {
.     display "network not found"
. }
```

## See also

- [nwcommands](nwcommands), [nwtopical](nwtopical)
