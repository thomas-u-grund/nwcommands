---
title: "nwexport"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Export network as Pajek, Ucinet, GML or edge list file"
---

# `nwexport`

Export network as Pajek, Ucinet, GML or edge list file

## Syntax

```stata
nwexport 
[netname],
type(exp_type)
[, fname(filename)
replace]
```

| | |
|---|---|
| `fname(filename)` | filename of the exported network: default = *netname* |
| `replace` | overwrite exported file |

## Description

Exports a network to 1) Pajek .NET, 2) Ucinet .DL, 3) GML or 4) plain-text edge list file format. Only exports one network and no node level attributes. By default, the new network file is saved in the working directory. When no `fname` is specified, the program calls the new file *netname.dl* (Ucinet), *netname.net* (Pajek), *netname.gml* (GML) or *netname.txt* (edge list).

## Examples

This example loads the [Florentine marriage data](netexample) and exports to both .DL and .NET format.

```stata
. nwwebuse florentine, nwclear
. nwexport flomarriage, type(ucinet)
. nwexport flobusiness, type(pajek)
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: yes - Pajek gets the bipartite form (first line `*Vertices n n1`, the first mode first); UCINET a rectangular matrix with row and column labels; the edge list five columns (ego, alter, value, mode of the ego, mode of the alter); GML the node attribute `nwmode`. [nwimport](nwimport) reads each of the four back as a two-mode network.

## See also

- [nwimport](nwimport), [nwuse](nwuse), [nwsave](nwsave)

- last certified : 24 Aug 2026
