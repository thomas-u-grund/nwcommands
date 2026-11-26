---
title: "nwuse"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Load a Stata network dataset"
---

# `nwuse`

Load a Stata network dataset

## Syntax

```stata
nwuse
filename
[,
nwclear
nwappend
force
clear]
nwwebuse
netexample
[,
nwclear]
```

| | |
|---|---|
| `nwclear` | clear memory before loading dataset |
| `nwappend` | append to existing data |
| `clear` | load even though the data in memory have changed and were not saved; without `clear`, `nwclear` or `nwappend` the command stops |
| `force` | when combined with `nwappend`, if the incoming data contains a network with the same name as one already in memory, auto-renumber the incoming network to a fresh name instead of erroring - unlike `replace` elsewhere in this group (e.g. [nwset](nwset)), which overwrites the existing network in place under the same name, `force` leaves the existing network untouched |

## Description

**nwuse** loads a Stata network dataset previously saved with [nwsave](nwsave). This includes all networks and Stata variables. If *`filename`* is specified without an extension, **.nwdta** is assumed. If your *filename* contains embedded spaces, remember to enclose it in double quotes.

The data in memory are replaced by those of the file (with `nwappend`, added to them). They then belong to no data file: `c(filename)` is empty, so that `save, replace` cannot write over the network file; use [nwsave](nwsave) to save networks, or `save` with a file name. When the command fails, for example because the file does not exist or is not a complete network file, the data, the networks and the current network stay as they were, also with `nwclear`.

With `nwappend` no observation and no variable is lost. Observations are matched by the node name in *_nwnode*; observations in memory without a match (also all of them, when the data have no *_nwnode*) and observations of the file without a match are kept as separate observations. Where a node has a value of the same variable both in memory and in the file, the value in memory stays and a note names the variable; missing values are filled from the file. When a variable is a string variable in one and numeric in the other, the one from the file is added under a new name, for example *age_2*. A variable that [nwload](nwload) created to show a network gives way to a variable of the same name in the file. A plain Stata dataset (without networks) cannot be appended.

Every network comes back as it was saved: a network saved as directed stays directed even when its ties happen to be symmetric, and a two-mode network keeps the node order it was saved in.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)); files of two-mode networks that list every pair of nodes also load. A temporal network (event, snapshot or interval network, see [nwset](nwset)) comes back with its times, and with its type and the names of its time variables, exactly as [nwsave](nwsave) wrote them; a file that holds no times loads as a network that is not temporal.

## Limits

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

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
. nwuse mynets, nwclear
```
This load the Florentine dataset from the internet and appends it to the existing data.

```stata
. nwwebuse florentine, nwappend
```

## See also

- [nwwebuse](nwwebuse), [nwsave](nwsave), `use`, [nwappend](nwappend)

---

*nwcommands version 3.38.0, 26 November 2026* ([check your installed version](nwversion))
