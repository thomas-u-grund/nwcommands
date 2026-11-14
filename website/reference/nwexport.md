---
title: "nwexport"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Export a network as a Pajek, UCINET, GML or edge list file"
---

# `nwexport`

Export a network as a Pajek, UCINET, GML or edge list file

## Syntax

```stata
nwexport 
[netname],
type(exp_type)
[fn:ame(filename)
replace
agg:regate]
```

| | |
|---|---|
| `type`(*[exp_type](nwexport)*) | **Required.** file format: `pajek`, `ucinet`, `gml` or `edgelist` |
| `fn:ame(filename)` | filename of the exported network without the file ending: default = *netname* |
| `replace` | overwrite exported file |
| `agg:regate` | temporal network: export the ties aggregated over all times (see [Temporal networks](nwexport)) |

## Description

Exports a network to 1) Pajek .NET, 2) Ucinet .DL, 3) GML or 4) plain-text edge list file format. Only exports one network and no node level attributes. By default, the new network file is saved in the working directory. When no `fname` is specified, the program calls the new file *netname.dl* (Ucinet), *netname.net* (Pajek), *netname.gml* (GML) or *netname.txt* (edge list).

## Network types

**Directed:** yes. **Valued:** the tie values of a valued network are written; a binary (unvalued) network is written without tie values (ego and alter only, in GML without `value`), so that [nwimport](nwimport) reads it back as binary (a two-mode network keeps its form). In UCINET DL a label that contains a blank or a comma is written in double quotes. **Two-mode:** yes - Pajek bipartite form, UCINET rectangular matrix, edge list with the modes of both nodes, GML attribute `nwmode`; level labels are kept except in UCINET DL. **Signed:** not checked. **Temporal:** see below. See [nwnetworktypes](nwnetworktypes).

## Temporal networks

A network declared with `time()`, `interval()` or `eventtime()` in [nwset](nwset) has times that only the edge list can hold. `type(edgelist)` writes one row per event (per observation of a tie of a snapshot network, per interval of an interval network) with the times in the last column(s), tab-delimited and without a header: *ego alter* [*value*] *time* for event and snapshot networks, *ego alter* [*value*] *start end* for interval networks. The value column is there for a valued network. [nwimport](nwimport) reads such a file back with the type option `eventtime`, `time` or `interval`, and every event, time and value comes back exactly. The file does not say whether a network is directed; state `directed` or `undirected` when importing it.

The formats `pajek`, `ucinet` and `gml`, and the edge list of a two-mode network, cannot hold times: for a temporal network the command stops with error 198 and writes nothing. Specify `aggregate` to write the ties of the network aggregated over all times (a tie that is present at any time), as a network that is not temporal; with `type(edgelist)`, `aggregate` writes the aggregated tie list instead of the times. [nwsave](nwsave) keeps the temporal network as it is.

## Limits

Every format is written from the ties only and in blocks. Measured in Stata/BE, random directed network with 10 ties per node: 1,000 / 5,000 / 20,000 nodes in 0.1 / 0.3 / 1.4 seconds (edge list, Pajek, UCINET). Within a Pajek, UCINET or GML file the ties are ordered by the label of the alter, then of the ego.

## Examples

This example loads the [Florentine marriage data](netexample) and exports to both .DL and .NET format.

```stata
. nwwebuse florentine, nwclear
. nwexport flomarriage, type(ucinet)
. nwexport flobusiness, type(pajek)
```

## See also

- [nwimport](nwimport), [nwuse](nwuse), [nwsave](nwsave)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
