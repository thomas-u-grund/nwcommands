---
title: "nwsave"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Save network data in a file"
---

# `nwsave`

Save network data in a file

## Syntax

```stata
nwsave
filename
[,
replace
old]
```

| | |
|---|---|
| ` replace` | overwrite existing dataset |
| `old` | save in a Stata-version-backward-compatible format (uses `saveold` internally instead of `save`) |

## Description

**nwsave** saves all networks (and Stata variables) currently in memory on disk. The command saves data in its own file format **.nwdta**. Network data saved in this way can be loaded with [nwuse](nwuse). Notice that the command `save` does not save network data.

## Examples

This example creates 5 new random networks and [saves](nwsave) them as *mynets*. A new dataset called *mynets.nwdta* is created in the working directory.

```stata
. nwclear
. nwrandom 20, ntimes(5) prob(.2)
. nwsave mynets
```
After this, one can easily load these 5 networks in a new Stata session just as if one would load a normal Stata dataset.

```stata
. nwuse mynets
```

## See also

- [nwuse](nwuse), [nwwebuse](nwwebuse), `save`

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
