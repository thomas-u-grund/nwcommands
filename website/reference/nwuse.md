---
title: "nwuse"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Load Stata network dataset"
---

# `nwuse`

Load Stata network dataset

## Syntax

```stata
nwuse
filename
[,
nwclear
nwappend
force]
nwwebuse
netexample
[,
nwclear]
```

| | |
|---|---|
| `nwclear` | clear memory before loading dataset |
| `nwappend` | append to existing data |
| `force` | when combined with `nwappend`, if the incoming data contains a network with the same name as one already in memory, auto-renumber the incoming network to a fresh name instead of erroring - unlike `replace` elsewhere in this group (e.g. [nwset](nwset)), which overwrites the existing network in place under the same name, `force` leaves the existing network untouched |

## Description

**nwuse** loads a Stata network dataset previously saved with [nwsave](nwsave). This includes all networks and Stata variables. If *`filename`* is specified without an extension, **.nwdta** is assumed. If your *filename* contains embedded spaces, remember to enclose it in double quotes.

## Examples

This example creates 5 new random networks and [saves](nwsave) them as *mynets*.A new dataset called *mynets.nwdta* is created in the working directory with the networks and all Stata variables.

```stata
. nwclear
. nwrandom 20, ntimes(5) prob(.2)
. nwsave mynets
. nwclear
```
One can bring the data back with:

```stata
. nwuse mynets
```
This load the Florentine dataset from the internet and appends it to the existing data.

```stata
. nwwebuse florentine, nwappend
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - loads a network exactly as it was saved, independent of any of these properties.

## See also

- [nwwebuse](nwwebuse), [nwsave](nwsave), `use`, [nwappend](nwappend)
