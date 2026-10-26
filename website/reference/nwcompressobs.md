---
title: "nwcompressobs"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Compresses observations in Stata"
---

# `nwcompressobs`

Compresses observations in Stata

## Syntax

```stata
nwcompressobs
```

## Description

Comresses the observations in Stata. Deletes all unnecessary cases that are not needed to represent the largest network. When the dataset also contains an attribute variable with non-missing data, these cases are not deleted.

## Examples

```stata
. nwclear
. nwrandom 20, prob(.2)
. set obs 50
. nwcompressobs
```

## Supported network types

Not applicable - trims trailing empty (all-missing) Stata observations from the dataset; does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

## See also

- [nwdrop](nwdrop), `clear`

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
