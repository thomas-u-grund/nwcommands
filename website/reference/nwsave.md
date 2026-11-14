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

## Network types

**Directed:**, **Valued:**, **Signed:** stored as they are. **Two-mode:** yes - the file holds the ties between the modes only, the mode of every node and the node attributes (5,000 + 500 nodes take about a megabyte). See [nwnetworktypes](nwnetworktypes).

**Temporal:** yes. A network declared with `time()`, `interval()` or `eventtime()` in [nwset](nwset) is saved with its times: every event of an event network (sender, receiver, time and value, in the order they were given), every observation of a tie of a snapshot network (a tie can come and go), every interval of an interval network, the temporal type and the names of the time variables. [nwuse](nwuse) brings back exactly these data. The file also holds the ties of such a network aggregated over all times, as for every network, so that an earlier version of nwcommands loads the aggregated network without times. A file that holds no temporal network has none of the time columns.

## Limits

A network is stored as its list of ties, so the file of a large network is small (a two-mode network of 5,092 + 455 nodes and 5,669 ties takes 1.2 MB).

Networks of different sizes can be saved in one file and come back with their own sizes. The node attributes (the Stata variables) are one table for the whole file, one row per node, so they belong to the networks only if the networks have the same nodes; keep attributes of different groups in separate files.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

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

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
