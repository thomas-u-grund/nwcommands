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
replace]
```

| | |
|---|---|
| `type`(*[exp_type](nwexport)*) | **Required.** file format: `pajek`, `ucinet`, `gml` or `edgelist` |
| `fn:ame(filename)` | filename of the exported network without the file ending: default = *netname* |
| `replace` | overwrite exported file |

## Description

Exports a network to 1) Pajek .NET, 2) Ucinet .DL, 3) GML or 4) plain-text edge list file format. Only exports one network and no node level attributes. By default, the new network file is saved in the working directory. When no `fname` is specified, the program calls the new file *netname.dl* (Ucinet), *netname.net* (Pajek), *netname.gml* (GML) or *netname.txt* (edge list).

## Network types

**Directed:** yes. **Valued:** the tie values of a valued network are written; a binary (unvalued) network is written without tie values (ego and alter only, in GML without `value`), so that [nwimport](nwimport) reads it back as binary (a two-mode network keeps its form). In UCINET DL a label that contains a blank or a comma is written in double quotes. **Two-mode:** yes - Pajek bipartite form, UCINET rectangular matrix, edge list with the modes of both nodes, GML attribute `nwmode`; level labels are kept except in UCINET DL. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

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

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
