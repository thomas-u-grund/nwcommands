---
title: "nwcompressobs"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Drop observations that no network needs"
---

# `nwcompressobs`

Drop observations that no network needs

## Syntax

```stata
nwcompressobs
```

## Description

Compresses the observations in Stata. Deletes every observation in which all variables are missing (an empty string or the system missing value), such as the extra observations that are not needed to represent the largest network. An observation that holds a node name or any other non-missing value is kept.

## Examples

```stata
. nwclear
. nwrandom 20, prob(.2)
. set obs 50
. nwcompressobs
```

## See also

- [nwdrop](nwdrop), `clear`

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
