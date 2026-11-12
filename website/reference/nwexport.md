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

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
