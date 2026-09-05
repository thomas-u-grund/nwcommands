---
title: "nwexport"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Export network as Pajek or Ucinet file"
---

# `nwexport`

Export network as Pajek or Ucinet file

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

Exports a network to either 1) Pajek .NET or 2) Ucinet .DL file format. Only exports one network and no node level attributes. By default, the new network file is saved in the working directory. When no `fname` is specified, the program calls the new file *netname.dl* (Ucinet) or *netname.net* (Pajek).

## Examples

This example loads the [Florentine marriage data](netexample.md) and exports to both .DL and .NET format.

```stata
. nwwebuse florentine, nwclear
. nwexport flomarriage, type(ucinet)
. nwexport flobusiness, type(pajek)
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: not checked - exports the network to Pajek/UCINET format largely as stored; consult the target format's own documentation for what it can represent.

## See also

- [nwimport](nwimport.md), [nwuse](nwuse.md), [nwsave](nwsave.md)

- last certified : 24 Aug 2026
